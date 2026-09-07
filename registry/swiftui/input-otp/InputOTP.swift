import SwiftUI

/// shadcn-swift component: input-otp
/// depends on: tokens
///
/// SwiftUI has no per-character-box text input, so this uses the standard
/// workaround: a real `TextField` captures keyboard input and drives
/// `code`, sitting at ~0 opacity (not literally 0 — a fully-zero-opacity
/// view can behave inconsistently for hit-testing/accessibility on some
/// OS versions) UNDER the visible digit boxes, which just render
/// substrings of `code` and never receive touches themselves
/// (`.allowsHitTesting(false)`) so a tap anywhere in the row reaches the
/// real field beneath it.
public extension UI {
    struct InputOTP: View {
        @Environment(\.uiTheme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        @FocusState private var isFocused: Bool

        @Binding private var code: String
        private let length: Int

        public init(length: Int = 6, code: Binding<String>) {
            self.length = length
            self._code = code
        }

        public var body: some View {
            ZStack {
                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isFocused)
                    .opacity(0.01)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: code) { _, newValue in
                        let filtered = String(newValue.filter(\.isNumber).prefix(length))
                        if filtered != newValue { code = filtered }
                    }

                HStack(spacing: theme.spacing.sm) {
                    ForEach(0..<length, id: \.self) { index in
                        digitBox(at: index)
                    }
                }
                .allowsHitTesting(false)
            }
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isEnabled ? 1 : 0.5)
        }

        // Real shadcn's slot is `h-9 w-9` (36×36, square) with `text-sm`
        // (14pt, regular weight) digits — this was 40×48 (a tall rectangle)
        // with 20pt bold monospaced digits, both fetched-and-verified
        // mismatches against `input-otp.tsx`'s `InputOTPSlot`.
        @ViewBuilder
        private func digitBox(at index: Int) -> some View {
            let characters = Array(code)
            let isActive = isFocused && index == characters.count

            RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                .strokeBorder(isActive ? theme.colors.ring : theme.colors.input, lineWidth: isActive ? 2 : 1)
                .background(theme.colors.background)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(index < characters.count ? String(characters[index]) : "")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.foreground)
                )
                .uiShadow(theme.shadow.xs)
        }
    }
}

#if DEBUG
private struct InputOTPPreview: View {
    @State private var code = "12"

    var body: some View {
        UI.InputOTP(length: 6, code: $code)
            .padding()
    }
}

#Preview("InputOTP") {
    InputOTPPreview()
}
#endif
