import SwiftUI
import WidgetKit

/// The face of both widgets.
///
/// My Wishlist and the Shopping List are the same shape — a counted list of gifts — so they share
/// one view and `GiftListKind` supplies what differs.
struct GiftListWidgetView: View {

    @Environment(\.widgetFamily) private var family

    let kind: GiftListKind
    let entry: GiftListEntry

    var body: some View {
        Group {
            if family == .systemSmall {
                summary
            } else if entry.gifts.isEmpty {
                empty
            } else {
                list
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(kind.url)
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }

    // MARK: - Small

    /// The count is the headline on the small family — a glance should answer "how much is left?"
    /// before it answers "what exactly?".
    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            symbol
            Spacer(minLength: 4)
            if entry.gifts.isEmpty {
                Text(kind.emptyMessage)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text(entry.gifts.count, format: .number)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .contentTransition(.numericText())
                Text(kind.countLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.totalPrice, format: currencyFormat)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: - Medium and large

    private var list: some View {
        VStack(alignment: .leading, spacing: 6) {
            header

            ForEach(entry.gifts.prefix(rowLimit)) { gift in
                GiftWidgetRow(gift: gift, isTickable: kind.allowsMarkingAcquired)
            }

            if family != .systemMedium, overflow > 0 {
                Text("\(overflow) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 6) {
            symbol
            Text(kind.title)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 4)
            Text(entry.gifts.count, format: .number)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
    }

    private var empty: some View {
        VStack(spacing: 6) {
            symbol
                .font(.title2)
            Text(kind.emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The one element that takes the tint in accented and tinted renderings; the rows stay legible
    /// in the default group.
    private var symbol: some View {
        Image(systemName: kind.symbolName)
            .symbolVariant(.fill)
            .font(.subheadline)
            .foregroundStyle(.tint)
            .widgetAccentable()
    }

    private var rowLimit: Int {
        family == .systemMedium ? 3 : 6
    }

    private var overflow: Int {
        max(0, entry.gifts.count - rowLimit)
    }

    private var currencyFormat: FloatingPointFormatStyle<Double>.Currency {
        .currency(code: Locale.current.currencyID).precision(.fractionLength(0))
    }

}

/// One gift on a widget: what it is, who it is for, and — on the Shopping List — a way to tick it
/// off from the Home Screen.
struct GiftWidgetRow: View {

    let gift: GiftSnapshot
    let isTickable: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isTickable {
                Button(intent: MarkGiftAcquiredIntent(gift: gift)) {
                    Image(systemName: "circle")
                        .font(.body)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(gift.title) acquired")
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(gift.title)
                    .font(.subheadline)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Text(gift.price, format: .currency(code: Locale.current.currencyID).precision(.fractionLength(0)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    /// Who it is for, and — for a birthday — how long there is left. A wishlist gift is for the
    /// user, which the widget's own title already says, so it carries no subtitle.
    private var subtitle: String? {
        guard let recipientName = gift.recipientName else { return nil }
        guard let days = gift.daysUntilBirthday else { return "For \(recipientName)" }
        return "For \(recipientName) in \(days) days"
    }

}
