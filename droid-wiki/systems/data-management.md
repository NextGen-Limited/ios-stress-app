# Data management

User-initiated export and deletion of stress data. Required by App Store privacy guidelines and exposed under Settings > Data Management. Covers CSV/JSON export, local wipe, and CloudKit reset.

## Key abstractions

| Type | File | Description |
| --- | --- | --- |
| `DataManagementService` | `StressMonitor/StressMonitor/Services/DataManagement/DataManagementService.swift` | Top-level coordinator invoked by `DataManagementViewModel`. |
| `DataExporter` | `StressMonitor/StressMonitor/Services/DataManagement/DataExporter.swift` | Protocol that dispatches to a generator by format. |
| `CSVGenerator` | `StressMonitor/StressMonitor/Services/DataManagement/CSVGenerator.swift` | Generates CSV from `[StressMeasurement]`. |
| `JSONGenerator` | `StressMonitor/StressMonitor/Services/DataManagement/JSONGenerator.swift` | Generates JSON from `[StressMeasurement]`. |
| `DataDeleter` | `StressMonitor/StressMonitor/Services/DataManagement/DataDeleter.swift` | Protocol for single-record and range deletion. |
| `DataDeleterService` | `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` | Local SwiftData deletion with date-range filtering. |
| `LocalDataWipeService` | `StressMonitor/StressMonitor/Services/DataManagement/LocalDataWipeService.swift` | Wipes the entire local SwiftData store and resets baseline. |
| `CloudKitResetService` | `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift` | Wipes CloudKit private database records. |
| `ExportModels` | `StressMonitor/StressMonitor/Models/ExportModels.swift` | Codable row models for CSV/JSON export. |
| `DataManagementUtilities` | `StressMonitor/StressMonitor/Services/DataManagement/DataManagementUtilities.swift` | Shared helpers (date formatting, file URLs). |

## Export

`DataExporter` accepts a format (`.csv` or `.json`) and a date range, fetches matching `StressMeasurement` rows through the repository, and writes a file to a temporary directory. The resulting file URL is passed to `UIActivityViewController` for sharing.

The CSV includes one row per measurement with columns for timestamp, stress level, category, HRV, resting HR, and per-factor component values when present. The JSON output uses `ExportModels` to produce a stable schema with metadata (export date, app version, baseline).

## Deletion

Three scopes:

1. **Single record**: delete one `StressMeasurement` by ID.
2. **Date range**: delete all records whose `timestamp` falls inside the supplied range.
3. **All local data**: `LocalDataWipeService` deletes every `StressMeasurement` and `CharacterUnlock`, resets the personal baseline in `UserDefaults`, and clears the demo mode cache.

Local deletion also marks the corresponding CloudKit record with `isDeleted = true` (soft delete) so the tombstone propagates through sync. Hard deletion in CloudKit happens through `CloudKitResetService`.

## CloudKit reset

`CloudKitResetService` walks the `StressMeasurement` record zone in the CloudKit private database and issues `CKModifyRecordsOperation` batches to permanently delete records. This is the only path that performs hard deletes; normal sync uses soft deletes for audit and cross-device propagation. The service exposes progress callbacks that `DataManagementViewModel` surfaces in the UI.

## Entry points for modification

- **Add a new export column**: extend `ExportModels` with the new field, add it to the CSV header in `CSVGenerator`, and include it in the JSON dictionary in `JSONGenerator`.
- **Add a new deletion scope**: extend `DataDeleterService` with the new predicate and surface it through `DataManagementViewModel`.
- **Change the wipe behavior**: edit `LocalDataWipeService`. Clear any additional `UserDefaults` keys or App Group snapshots you introduce.
