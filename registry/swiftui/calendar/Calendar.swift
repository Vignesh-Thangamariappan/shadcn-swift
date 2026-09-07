import SwiftUI

/// shadcn-swift component: calendar
/// depends on: tokens
///
/// LOAD-BEARING GOTCHA, worse here than anywhere else in this registry:
/// `UI.Calendar` is a View, but its own implementation needs Foundation's
/// `Calendar` (month math, weekday symbols, date arithmetic) constantly —
/// nearly every private helper below touches it. Because `UI.Calendar` and
/// `Foundation.Calendar` share a name, an unqualified `Calendar` anywhere
/// inside THIS type's own members resolves to the enclosing `UI.Calendar`
/// (the same enclosing-scope-wins rule that makes `SwiftUI.Button`
/// necessary inside `UI.Button`), not to Foundation's type. Every reference
/// below is written `Foundation.Calendar` — do not "clean up" that
/// qualification, it is not decoration. Verified this actually bites:
/// dropping one `Foundation.` qualifier produces `error: type 'UI.Calendar'
/// has no member 'current'` — at least it fails loudly at compile time
/// here, rather than silently resolving to the wrong type the way a bare
/// `Button`/`Toggle` reference would elsewhere in this registry.
///
/// Scope: single-date selection only (`Binding<Date?>`). shadcn's Calendar
/// (via react-day-picker) also supports multiple/range selection modes;
/// those aren't built here — this is the common case, not full parity.
///
/// Day cells use `theme.radius.md`, not `Circle()`: real shadcn's
/// `CalendarDayButton` is literally `<Button variant="ghost" size="icon">`
/// (verified against the live `calendar.tsx`/`button.tsx` source), i.e. a
/// rounded SQUARE selection highlight, same radius as every other icon
/// button — not a circular one. An earlier version used `Circle()` here.
public extension UI {
    struct Calendar: View {
        @Environment(\.uiTheme) private var theme
        @State private var displayedMonth: Date
        @Binding private var selection: Date?
        private let isDateDisabled: (Date) -> Bool

        public init(
            selection: Binding<Date?>,
            isDateDisabled: @escaping (Date) -> Bool = { _ in false }
        ) {
            self._selection = selection
            self.isDateDisabled = isDateDisabled
            self._displayedMonth = State(initialValue: selection.wrappedValue ?? Date())
        }

        public var body: some View {
            VStack(spacing: theme.spacing.sm) {
                header
                weekdayHeader
                dayGrid
            }
            .padding(theme.spacing.md)
            // real shadcn's Calendar root is `bg-background`, not a card
            // surface — was `theme.colors.card` before.
            .background(theme.colors.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
        }

        private var header: some View {
            HStack {
                // real shadcn's nav buttons are `size-(--cell-size)` where
                // `--cell-size: --spacing(8)` = 32px, ghost variant (no
                // fill/border) — was an unsized plain-style image before.
                navButton(systemImage: "chevron.left") { changeMonth(by: -1) }

                Spacer()

                Text(monthTitle)
                    .font(theme.typography.label)

                Spacer()

                navButton(systemImage: "chevron.right") { changeMonth(by: 1) }
            }
            .foregroundStyle(theme.colors.foreground)
        }

        private func navButton(systemImage: String, action: @escaping () -> Void) -> some View {
            SwiftUI.Button(action: action) {
                Image(systemName: systemImage)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }

        private var weekdayHeader: some View {
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        // real shadcn's weekday cell is `text-[0.8rem]
                        // font-normal` (~12px, regular) — `.caption` is
                        // `.medium` by default, overridden to `.regular`
                        // here rather than adding a new typography tier.
                        .font(theme.typography.caption)
                        .fontWeight(.regular)
                        .foregroundStyle(theme.colors.mutedForeground)
                        .frame(maxWidth: .infinity)
                }
            }
        }

        private var dayGrid: some View {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            return LazyVGrid(columns: columns, spacing: theme.spacing.xs) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }

        @ViewBuilder
        private func dayCell(_ date: Date) -> some View {
            let cal = Foundation.Calendar.current
            let isSelected = selection.map { cal.isDate($0, inSameDayAs: date) } ?? false
            let isToday = cal.isDateInToday(date)
            let isDisabled = isDateDisabled(date)

            SwiftUI.Button {
                selection = date
            } label: {
                Text("\(cal.component(.day, from: date))")
                    .font(theme.typography.body)
                    .frame(width: 32, height: 32)
                    .background(dayBackground(isSelected: isSelected, isToday: isToday))
                    .foregroundStyle(dayForeground(isSelected: isSelected, isToday: isToday, isDisabled: isDisabled))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }

        // real shadcn's `today` cell is `bg-accent text-accent-foreground`
        // (a filled highlight), not a stroked ring — was previously a
        // `theme.colors.primary` outline here.
        private func dayBackground(isSelected: Bool, isToday: Bool) -> Color {
            if isSelected { return theme.colors.primary }
            if isToday { return theme.colors.accent }
            return .clear
        }

        private func dayForeground(isSelected: Bool, isToday: Bool, isDisabled: Bool) -> Color {
            if isSelected { return theme.colors.primaryForeground }
            // real shadcn: `disabled` is `opacity-50`, was 0.4.
            if isDisabled { return theme.colors.mutedForeground.opacity(0.5) }
            if isToday { return theme.colors.accentForeground }
            return theme.colors.foreground
        }

        private func changeMonth(by value: Int) {
            if let newMonth = Foundation.Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
                displayedMonth = newMonth
            }
        }

        private var monthTitle: String {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
            return formatter.string(from: displayedMonth)
        }

        /// Sunday-indexed weekday symbols, rotated to start on the
        /// calendar's actual `firstWeekday` (locale-dependent).
        private var weekdaySymbols: [String] {
            let cal = Foundation.Calendar.current
            let symbols = cal.veryShortStandaloneWeekdaySymbols
            let offset = cal.firstWeekday - 1
            return Array(symbols[offset...] + symbols[..<offset])
        }

        /// One entry per grid cell: `nil` for the leading/trailing blanks
        /// that pad the first and last week rows to a full 7 columns.
        private var monthDays: [Date?] {
            let cal = Foundation.Calendar.current
            guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth) else { return [] }

            let firstOfMonth = monthInterval.start
            let weekday = cal.component(.weekday, from: firstOfMonth)
            let leadingCount = ((weekday - cal.firstWeekday) % 7 + 7) % 7
            let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30

            var days: [Date?] = Array(repeating: nil, count: leadingCount)
            for dayOffset in 0..<daysInMonth {
                days.append(cal.date(byAdding: .day, value: dayOffset, to: firstOfMonth))
            }
            while days.count % 7 != 0 {
                days.append(nil)
            }
            return days
        }
    }
}

#if DEBUG
private struct CalendarPreview: View {
    @State private var selection: Date? = Date()

    var body: some View {
        UI.Calendar(selection: $selection) { date in
            Foundation.Calendar.current.isDateInWeekend(date)
        }
        .padding()
    }
}

#Preview("Calendar") {
    CalendarPreview()
}
#endif
