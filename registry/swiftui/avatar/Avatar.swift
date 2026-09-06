import SwiftUI

/// shadcn-swift component: avatar
/// depends on: tokens
public extension UI {
    struct Avatar: View {
        @Environment(\.uiTheme) private var theme

        private let name: String
        private let imageURL: URL?
        private let size: CGFloat

        public init(name: String, imageURL: URL? = nil, size: CGFloat = 40) {
            self.name = name
            self.imageURL = imageURL
            self.size = size
        }

        public var body: some View {
            ZStack {
                Circle().fill(theme.colors.secondary)

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
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(theme.colors.secondaryForeground)
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
