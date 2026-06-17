import SwiftUI
import UniformTypeIdentifiers

/// Renders all character illustrations (character × evolution × mood) to PNGs
/// and packages them into a ZIP archive for export.
@MainActor
final class CharacterIllustrationExporter {
    private(set) var isExporting = false
    private(set) var progress: Double = 0
    private(set) var currentOperation: String = ""
    private(set) var totalItems: Int = 0
    private(set) var completedItems: Int = 0

    /// All (character, evolution, mood) tuples that will be exported.
    static let allIllustrations: [(creature: CharacterCreature, evolution: EvolutionStage, mood: StressBuddyMood)] = {
        var items: [(creature: CharacterCreature, evolution: EvolutionStage, mood: StressBuddyMood)] = []
        for creature in CharacterCreature.allCharacters {
            for evolution in EvolutionStage.allCases {
                for mood in StressBuddyMood.allCases {
                    items.append((creature: creature, evolution: evolution, mood: mood))
                }
            }
        }
        return items
    }()

    /// Export size (point size for the character rendering canvas).
    var exportSize: CGFloat = 512

    /// Generate a filename slug for a given illustration.
    static func fileName(creature: CharacterCreature, evolution: EvolutionStage, mood: StressBuddyMood) -> String {
        "\(creature.id)_\(evolution.rawValue)_\(mood.rawValue).png"
    }

    /// Export all illustrations as a ZIP file. Returns the file/folder URL.
    func exportAll() async throws -> URL {
        guard !isExporting else {
            throw CharacterExportError.alreadyExporting
        }

        isExporting = true
        progress = 0
        currentOperation = "Preparing export…"
        totalItems = Self.allIllustrations.count
        completedItems = 0

        defer {
            isExporting = false
        }

        // Create temp directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        currentOperation = "Rendering illustrations…"

        // Render each illustration to PNG
        for item in Self.allIllustrations {
            await MainActor.run {
                currentOperation = "Rendering \(item.creature.displayName) (\(item.evolution.displayName), \(item.mood.displayName))…"
            }

            let pngData = renderIllustrationPNG(
                creature: item.creature,
                evolution: item.evolution,
                mood: item.mood,
                size: exportSize
            )

            let fileURL = tempDir.appendingPathComponent(
                Self.fileName(creature: item.creature, evolution: item.evolution, mood: item.mood)
            )
            try pngData.write(to: fileURL)

            completedItems += 1
            progress = Double(completedItems) / Double(totalItems)
        }

        // Create ZIP
        await MainActor.run {
            currentOperation = "Compressing archive…"
        }

        let zipURL = try createZip(fromDirectory: tempDir)

        // Cleanup rendered PNGs
        try? FileManager.default.removeItem(at: tempDir)

        return zipURL
    }

    // MARK: - Rendering

    private func renderIllustrationPNG(
        creature: CharacterCreature,
        evolution: EvolutionStage,
        mood: StressBuddyMood,
        size: CGFloat
    ) -> Data {
        let view = StressBuddyIllustration(
            characterId: creature.id,
            evolution: evolution,
            mood: mood,
            size: size
        )
        .frame(width: size, height: size)
        .background(creature.element.primaryColor.opacity(0.08))

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0

        guard let cgImage = renderer.cgImage else {
            return Data()
        }

        let uiImage = UIImage(cgImage: cgImage, scale: renderer.scale, orientation: .up)
        return uiImage.pngData() ?? Data()
    }

    // MARK: - ZIP Creation (minimal ZIP without third-party deps)

    private func createZip(fromDirectory directory: URL) throws -> URL {
        let zipURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("StressMonitor_Characters_\(Int(Date().timeIntervalSince1970)).zip")

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ).sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !contents.isEmpty else {
            throw CharacterExportError.noIllustrations
        }

        var zipData = Data()
        var localHeaders: [(offset: Int, name: String, crc32: UInt32, size: UInt32)] = []

        // Write local file headers + compressed data
        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            let fileData = try Data(contentsOf: fileURL)
            let dosTime = dosDateTime(from: Date())
            let crc = CRC32.crc32(of: fileData)

            let headerOffset = zipData.count

            // Local file header (30 bytes + filename)
            zipData.appendUInt32(0x04034B50)          // signature (little-endian)
            zipData.appendUInt16(20)                  // version needed
            zipData.appendUInt16(0)                   // flags
            zipData.appendUInt8(0)                    // compression: stored
            zipData.append(contentsOf: dosTime.encoded) // mod time + date (4 bytes)
            zipData.appendUInt32(crc)                 // crc-32
            zipData.appendUInt32(UInt32(fileData.count)) // uncompressed size
            zipData.appendUInt32(UInt32(fileData.count)) // compressed size (stored = uncompressed)
            zipData.appendUInt16(UInt16(fileName.utf8.count)) // filename length
            zipData.appendUInt16(0)                  // extra field length
            zipData.append(Data(fileName.utf8))      // filename
            zipData.append(fileData)                 // file data

            localHeaders.append((offset: headerOffset, name: fileName, crc32: crc, size: UInt32(fileData.count)))
        }

        // Central directory
        let centralDirStart = zipData.count

        for entry in localHeaders {
            let fileNameData = Data(entry.name.utf8)
            let dosTime = dosDateTime(from: Date())

            zipData.appendUInt32(0x02014B50)          // central dir signature
            zipData.appendUInt16(20)                 // version made by
            zipData.appendUInt16(20)                  // version needed
            zipData.appendUInt16(0)                   // flags
            zipData.appendUInt8(0)                    // compression
            zipData.append(contentsOf: dosTime.encoded) // mod time + date
            zipData.appendUInt32(entry.crc32)         // crc-32
            zipData.appendUInt32(entry.size)          // uncompressed size
            zipData.appendUInt32(entry.size)          // compressed size
            zipData.appendUInt16(UInt16(fileNameData.count)) // filename length
            zipData.appendUInt16(0)                  // extra field length
            zipData.appendUInt16(0)                  // comment length
            zipData.appendUInt16(0)                  // disk number
            zipData.appendUInt16(0)                  // internal attrs
            zipData.appendUInt32(0)                  // external attrs
            zipData.appendUInt32(UInt32(entry.offset)) // local header offset
            zipData.append(fileNameData)
        }

        let centralDirEnd = zipData.count

        // End of central directory
        zipData.appendUInt32(0x06054B50)              // EOCD signature
        zipData.appendUInt16(0)                       // disk number
        zipData.appendUInt16(0)                      // disk with central dir
        zipData.appendUInt16(UInt16(localHeaders.count)) // entries on disk
        zipData.appendUInt16(UInt16(localHeaders.count)) // total entries
        zipData.appendUInt32(UInt32(centralDirEnd - centralDirStart)) // central dir size
        zipData.appendUInt32(UInt32(centralDirStart)) // central dir offset
        zipData.appendUInt16(0)                      // comment length

        try zipData.write(to: zipURL)
        return zipURL
    }

    // MARK: - DOS Date/Time Helpers

    private struct DOSTime {
        /// 4 bytes: 2 bytes time (little-endian) + 2 bytes date (little-endian)
        let encoded: [UInt8]
    }

    private func dosDateTime(from date: Date) -> DOSTime {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        let year = (components.year ?? 2025) - 1980
        let month = components.month ?? 1
        let day = components.day ?? 1
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = (components.second ?? 0) / 2

        let dosTime = UInt16((hour << 11) | (minute << 5) | second)
        let dosDate = UInt16((year << 9) | (month << 5) | day)

        // Pack into 4 bytes little-endian
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes[0] = UInt8(truncatingIfNeeded: dosTime & 0xFF)
        bytes[1] = UInt8(truncatingIfNeeded: (dosTime >> 8) & 0xFF)
        bytes[2] = UInt8(truncatingIfNeeded: dosDate & 0xFF)
        bytes[3] = UInt8(truncatingIfNeeded: (dosDate >> 8) & 0xFF)

        return DOSTime(encoded: bytes)
    }
}

// MARK: - Data Byte Helpers

private extension Data {
    /// Append raw bytes for a UInt32 value in little-endian order.
    mutating func appendUInt32(_ value: UInt32) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 4))
    }

    /// Append raw bytes for a UInt16 value in little-endian order.
    mutating func appendUInt16(_ value: UInt16) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 2))
    }

    /// Append raw bytes for a UInt8 value.
    mutating func appendUInt8(_ value: UInt8) {
        append(value)
    }

    /// Append raw bytes from a fixed-width integer (handles UInt32, etc.)
    mutating func appendBytes(_ value: UInt32) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 4))
    }

}

// MARK: - CRC32

private enum CRC32 {
    private static let table: [UInt32] = {
        (0...255).map { i in
            var crc = UInt32(i)
            for _ in 0..<8 {
                if crc & 1 != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc >>= 1
                }
            }
            return crc
        }
    }()

    static func crc32(of data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xFFFFFFFF
    }
}

// MARK: - Errors

enum CharacterExportError: LocalizedError {
    case alreadyExporting
    case noIllustrations
    case renderingFailed(String)
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .alreadyExporting:
            return "An export is already in progress."
        case .noIllustrations:
            return "No illustrations to export."
        case .renderingFailed(let detail):
            return "Failed to render illustration: \(detail)"
        case .compressionFailed:
            return "Failed to compress illustrations."
        }
    }
}
