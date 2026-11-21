import SwiftUI

struct BookCardView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: book.coverColorHex),
                                Color(hex: book.coverColorHex).opacity(0.62)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(String(book.title.prefix(1)))
                    .font(.system(size: 52, weight: .bold, design: .serif))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(14)

                if book.kind == .sample {
                    Text("示例")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.35), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            Text(book.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text(book.displayAuthor)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ProgressView(value: book.progressFraction)
                .tint(Color(hex: book.coverColorHex))
        }
    }
}
