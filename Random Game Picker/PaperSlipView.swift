import SwiftUI

struct PaperSlipView: View {
    let text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .lineLimit(3)
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Color.black.opacity(0.25))
                    )
            }
            .padding(10)
        }
        .frame(width: 220, height: 90)
    }
}
