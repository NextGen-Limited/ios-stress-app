import SwiftUI

/// Radio-style CSV / JSON format selector for the data export flow.
///
/// Tapping a row selects that format and shows a checkmark; the other row
/// dims. Designed to drop into a `Form` Section.
struct FormatPickerRow: View {
    @Binding var format: ExportFormat

    var body: some View {
        VStack(spacing: 0) {
            row(.csv)
            divider
            row(.json)
        }
        .accessibilityElement(children: .contain)
    }

    private func row(_ option: ExportFormat) -> some View {
        Button {
            format = option
            HapticManager.shared.buttonPress()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: option == .csv ? "tablecells" : "curlybraces")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primaryBlue)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue.uppercased())
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                    Text(option.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                }
                Spacer()
                Image(systemName: format == option ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(format == option ? Color.primaryGreen : Color.Wellness.adaptiveSecondaryText.opacity(0.4))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.rawValue) format")
        .accessibilityAddTraits(format == option ? .isSelected : [])
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.14))
            .frame(height: 0.5)
            .padding(.leading, 38)
            .accessibilityHidden(true)
    }
}

private extension ExportFormat {
    var description: String {
        switch self {
        case .csv:  return "Comma-separated, opens in Excel or Numbers"
        case .json: return "Structured data, ideal for backups and devs"
        }
    }
}

#Preview {
    @Previewable @State var format: ExportFormat = .csv
    return Form {
        Section("Format") {
            FormatPickerRow(format: $format)
        }
    }
}
