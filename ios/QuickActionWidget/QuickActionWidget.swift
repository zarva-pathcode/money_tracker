import WidgetKit
import SwiftUI

struct QuickActionWidgetEntry: TimelineEntry {
    let date: Date
    let fav_cat_1: String
    let fav_cat_2: String
    let fav_cat_3: String
}

struct QuickActionWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickActionWidgetEntry {
        QuickActionWidgetEntry(date: Date(), fav_cat_1: "Makan", fav_cat_2: "Transport", fav_cat_3: "Belanja")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickActionWidgetEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.moneytracker.app")
        let entry = QuickActionWidgetEntry(
            date: Date(),
            fav_cat_1: userDefaults?.string(forKey: "fav_cat_1") ?? "Makan",
            fav_cat_2: userDefaults?.string(forKey: "fav_cat_2") ?? "Transport",
            fav_cat_3: userDefaults?.string(forKey: "fav_cat_3") ?? "Belanja"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionWidgetEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.moneytracker.app")
        let entry = QuickActionWidgetEntry(
            date: Date(),
            fav_cat_1: userDefaults?.string(forKey: "fav_cat_1") ?? "Makan",
            fav_cat_2: userDefaults?.string(forKey: "fav_cat_2") ?? "Transport",
            fav_cat_3: userDefaults?.string(forKey: "fav_cat_3") ?? "Belanja"
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct QuickActionWidgetEntryView : View {
    var entry: QuickActionWidgetProvider.Entry

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Button 1
                Link(destination: URL(string: "expenseTracker://add?category=\(entry.fav_cat_1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                    WidgetButton(label: entry.fav_cat_1, icon: "cart.fill", color: .blue)
                }
                
                // Button 2
                Link(destination: URL(string: "expenseTracker://add?category=\(entry.fav_cat_2.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                    WidgetButton(label: entry.fav_cat_2, icon: "car.fill", color: .blue)
                }
            }
            
            HStack(spacing: 12) {
                // Button 3
                Link(destination: URL(string: "expenseTracker://add?category=\(entry.fav_cat_3.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                    WidgetButton(label: entry.fav_cat_3, icon: "bag.fill", color: .blue)
                }
                
                // Button 4 (Add)
                Link(destination: URL(string: "expenseTracker://add?category=empty")!) {
                    WidgetButton(label: "Tambah", icon: "plus", color: .indigo, isAccent: true)
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.96))
    }
}

struct WidgetButton: View {
    let label: String
    let icon: String
    let color: Color
    var isAccent: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isAccent ? .white : color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isAccent ? .white : .primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isAccent ? Color(red: 26/255, green: 35/255, blue: 126/255) : .white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

@main
struct QuickActionWidget: Widget {
    let kind: String = "QuickActionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionWidgetProvider()) { entry in
            QuickActionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Action Widget")
        .description("Tambah pengeluaran dengan cepat.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
