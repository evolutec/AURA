import WidgetKit
import SwiftUI

/// Widget AURA — affiche les stats d'inférence en temps réel.
///
/// Types de widgets :
///   - AuraStatsWidget : tok/s, RAM, statut (petit)
///   - AuraQuickChatWidget : bouton pour ouvrir un nouveau chat (moyen)
@main
struct AuraWidgetBundle: WidgetBundle {
    var body: some Widget {
        AuraStatsWidget()
        AuraQuickChatWidget()
    }
}

// MARK: - Stats Widget (petit)

struct AuraStatsWidget: Widget {
    let kind: String = "AuraStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            AuraStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("AURA Stats")
        .description("Affiche les statistiques d'inférence AURA (tok/s, RAM).")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StatsEntry: TimelineEntry {
    let date: Date
    let tokPerSec: Double
    let ramMb: Int
    let model: String
    let isInferencing: Bool
}

struct StatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: Date(), tokPerSec: 0, ramMb: 0, model: "AURA", isInferencing: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        completion(loadStats())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        let entry = loadStats()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadStats() -> StatsEntry {
        let defaults = UserDefaults(suiteName: "group.com.aura.aura_app")
        return StatsEntry(
            date: Date(),
            tokPerSec: defaults?.double(forKey: "aura_tok_s") ?? 0,
            ramMb: defaults?.integer(forKey: "aura_ram_mb") ?? 0,
            model: defaults?.string(forKey: "aura_model") ?? "AURA",
            isInferencing: defaults?.bool(forKey: "aura_is_inferencing") ?? false
        )
    }
}

struct AuraStatsWidgetView: View {
    var entry: StatsProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: entry.isInferencing ? "brain.head.profile" : "moon.zzz")
                    .foregroundColor(.purple)
                Text("AURA")
                    .font(.caption.bold())
                Spacer()
                Circle()
                    .fill(entry.isInferencing ? .green : .gray)
                    .frame(width: 6, height: 6)
            }
            Text("\(String(format: "%.1f", entry.tokPerSec)) tok/s")
                .font(.system(.title3.bold(), design: .rounded))
            Text("RAM: \(entry.ramMb) MB")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Quick Chat Widget (moyen)

struct AuraQuickChatWidget: Widget {
    let kind: String = "AuraQuickChatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { entry in
            AuraQuickChatWidgetView()
        }
        .configurationDisplayName("AURA Quick Chat")
        .description("Ouvre rapidement un nouveau chat AURA.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: Date())], policy: .never))
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct AuraQuickChatWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AURA", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.purple)
            Text("Appuie pour discuter avec ton IA locale")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Link(destination: URL(string: "aura://chat")!) {
                Label("Nouveau chat", systemImage: "bubble.left.and.bubble.right")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(12)
        .containerBackground(for: .widget) { Color.clear }
    }
}