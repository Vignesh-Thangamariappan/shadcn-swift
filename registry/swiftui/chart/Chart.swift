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

        public var body: some View {
            Charts.Chart(data) { point in
                switch style {
                case .bar:
                    BarMark(x: .value("Label", point.label), y: .value("Value", point.value))
                        .foregroundStyle(theme.colors.primary)
                case .line:
                    LineMark(x: .value("Label", point.label), y: .value("Value", point.value))
                        .foregroundStyle(theme.colors.primary)
                    PointMark(x: .value("Label", point.label), y: .value("Value", point.value))
                        .foregroundStyle(theme.colors.primary)
                }
            }
            .chartYAxis {
                AxisMarks {
                    AxisGridLine().foregroundStyle(theme.colors.border)
                    AxisValueLabel().foregroundStyle(theme.colors.mutedForeground)
                }
            }
            .chartXAxis {
                AxisMarks {
                    AxisValueLabel().foregroundStyle(theme.colors.mutedForeground)
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
