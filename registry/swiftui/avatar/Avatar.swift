import SwiftUI

/// shadcn-swift component: avatar
/// depends on: tokens
public extension UI {
    struct Avatar: View {
        @Environment(\.uiTheme) private var theme

        private let name: String
        private let imageURL: URL?
        private let size: CGFloat

        // Default matches real shadcn's `size-8` (32pt) default avatar size,
        // not the previous 40 (which is actually real shadcn's "lg" tier,
        // `size-10`).
        public init(name: String, imageURL: URL? = nil, size: CGFloat = 32) {
            self.name = name
            self.imageURL = imageURL
            self.size = size
        }

        public var body: some View {
            ZStack {
                // Real shadcn's AvatarFallback is `bg-muted`/`text-muted-foreground`,
                // not `secondary` — a real fetched mismatch, not a stylistic choice.
                Circle().fill(theme.colors.muted)

                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            initials
                        }
                    }
                } else {
                    initials
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }

        private var initials: some View {
            Text(Self.initials(from: name))
                // Real shadcn's AvatarFallback text is fixed at `text-sm`(14),
                // dropping to `text-xs`(12) only at the `sm` size tier
                // (`size-6`=24pt) — not a continuous proportional scale like
                // the previous `size * 0.4` here, which matched neither.
                .font(.system(size: size <= 24 ? 12 : 14, weight: .medium))
                .foregroundStyle(theme.colors.mutedForeground)
        }

        private static func initials(from name: String) -> String {
            let letters = name.split(separator: " ").prefix(2).compactMap(\.first)
            return String(letters).uppercased()
        }
    }
}

#if DEBUG
private struct AvatarPreview: View {
    var body: some View {
        HStack(spacing: 12) {
            UI.Avatar(name: "Ada Lovelace", size: 32)
            UI.Avatar(name: "Ada Lovelace", size: 40)
            UI.Avatar(name: "Grace Hopper", size: 56)
        }
        .padding()
    }
}

#Preview("Avatar") {
    AvatarPreview()
}
#endif
