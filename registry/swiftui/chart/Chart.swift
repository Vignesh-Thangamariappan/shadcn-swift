import SwiftUI
import Charts

/// shadcn-swift component: chart
/// depends on: tokens
///
/// DELIBERATE EXCEPTION to this registry's "SwiftUI/Foundation only"
/// import rule (see README): `import Charts` is Apple's own first-party
/// Swift Charts framework, ships with the SDK, and needs no separate
/// package added to a consumer's project — it doesn't reintroduce the
/// "this is a dependency now" problem the rule exists to prevent, the same
/// way `import Foundation` doesn't. A THIRD-PARTY charting package would
/// still violate the rule; a system framework with zero added dependency
/// footprint does not. Requires iOS 16+ (Charts' own minimum).
///
/// Same enclosing-scope shadowing rule as UI.Calendar/Foundation.Calendar:
/// this type is `UI.Chart`, and Charts' own view is `Charts.Chart` — every
/// reference below is qualified `Charts.Chart` for the same reason.
/// Verified: dropping the qualifier here fails differently than Calendar's
/// case did (Swift tries to resolve the call against `UI.Chart`'s own
/// two-argument init instead) — `error: extra trailing closure passed in
/// call` — but it's the same story: a loud compile failure, not a silent
/// wrong-behavior bug.
///
/// Scope: one flexible bar/line chart over a single labeled series, not
/// full parity with shadcn's Recharts-backed chart family (multi-series,
/// area, pie, tooltips). Built when something needs a chart, not
/// speculatively — extend `ChartStyle` here rather than adding new
/// registry components per chart type.
///
/// Series color is a hardcoded `#8EC5FF` — real shadcn's default theme has
/// a DEDICATED chart palette (`--chart-1` through `--chart-5`, all shades of
/// blue in the stock theme), separate from `--primary`; this is `--chart-1`
/// converted from its real value (`oklch(80.9% 0.105 251.813)`, i.e.
/// Tailwind's `blue-300`, fetched live from `tailwindcss`'s own theme.css).
/// An earlier version used `theme.colors.primary` here, which real shadcn
/// never does for chart series. Hardcoded rather than added to `Colors`
/// because this pass doesn't own `Tokens.swift` — a proper `chartPalette`
/// (5-step) token is the right long-term fix once `UI.Chart` supports
/// multiple series; recommended, not built here.
///
/// Axis labels are `theme.typography.caption` (real: chart container is
/// `text-xs`) at `mutedForeground` (real: `fill-muted-foreground`) — font
/// size wasn't set explicitly before. Grid lines are `theme.colors.border`
/// at 50% opacity (real: `stroke-border/50`) — was full opacity before.
public extension UI {
    enum ChartStyle {
        case bar, line
    }

    struct ChartPoint: Identifiable {
        public let id = UUID()
        public let label: String
        public let value: Double

        public init(_ label: String, value: Double) {
            self.label = label
            self.value = value
        }
    }

    struct Chart: View {
        @Environment(\.uiTheme) private var theme

        private let data: [ChartPoint]
        private let style: ChartStyle

        public init(data: [ChartPoint], style: ChartStyle = .bar) {
            self.data = data
            self.style = style
        }

        /// Real shadcn's `--chart-1` (see type-level doc comment for the
        /// verified OKLCH → sRGB conversion).
        private let seriesColor = Color(red: 0.5566, green: 0.7732, blue: 1.0)

        public var body: some View {
            Charts.Chart(data) { point in
                switch style {
                case .bar:
                    BarMark(x: .value("Label", point.label), y: .value("Value", point.value))
                        .foregroundStyle(seriesColor)
                case .line:
                    LineMark(x: .value("Label", point.label), y: .value("Value", point.value))
                        .foregroundStyle(seriesColor)
                    PointMark(x: .value("Label", point.label), y: .value("Value", point.value))
                        .foregroundStyle(seriesColor)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(theme.colors.border.opacity(0.5))
                    AxisValueLabel().font(theme.typography.caption).foregroundStyle(theme.colors.mutedForeground)
                }
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel().font(theme.typography.caption).foregroundStyle(theme.colors.mutedForeground)
                }
            }
        }
    }
}

#if DEBUG
private struct ChartPreview: View {
    private let data = [
        UI.ChartPoint("Mon", value: 12),
        UI.ChartPoint("Tue", value: 18),
        UI.ChartPoint("Wed", value: 9),
        UI.ChartPoint("Thu", value: 24),
        UI.ChartPoint("Fri", value: 16)
    ]

    var body: some View {
        VStack(spacing: 24) {
            UI.Chart(data: data, style: .bar)
                .frame(height: 160)
            UI.Chart(data: data, style: .line)
                .frame(height: 160)
        }
        .padding()
    }
}

#Preview("Chart") {
    ChartPreview()
}
#endif
