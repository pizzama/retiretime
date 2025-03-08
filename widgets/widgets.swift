//
//  widgets.swift
//  widgets
//
//  Created by pizzaman on 2025/3/9.
//

import WidgetKit
import SwiftUI
import Intents
// 移除对SharedModels的导入，因为我们已经在本地创建了所需的文件

// 定义ConfigurationIntent类
class ConfigurationIntent: INIntent {
    // 这是一个空的Intent类，用于Widget配置
}

struct EventEntry: TimelineEntry {
    let date: Date
    let events: [Event]
    let configuration: ConfigurationIntent
}

struct Provider: IntentTimelineProvider {
    // 从App Group的UserDefaults获取事件数据
    func loadEvents() -> [Event] {
        let userDefaults = UserDefaults(suiteName: "group.com.fenghua.retiretime")
        if let data = userDefaults?.data(forKey: "savedEvents") {
            if let decoded = try? JSONDecoder().decode([Event].self, from: data) {
                // 按照剩余天数排序，优先显示即将到来的事件
                return decoded.sorted { abs($0.daysRemaining) < abs($1.daysRemaining) }
            }
        }
        return Event.samples
    }
    
    func placeholder(in context: Context) -> EventEntry {
        EventEntry(date: Date(), events: Event.samples, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (EventEntry) -> ()) {
        let entry = EventEntry(date: Date(), events: loadEvents(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<EventEntry>) -> ()) {
        var entries: [EventEntry] = []

        // 创建一个每小时更新一次的时间线
        let currentDate = Date()
        let events = loadEvents()
        
        // 生成未来24小时的时间线，每小时更新一次
        for hourOffset in 0 ..< 24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = EventEntry(date: entryDate, events: events, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct RetireTimeWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry
    
    // 根据Widget尺寸决定显示的事件数量
    var eventsToShow: [Event] {
        let events = entry.events
        switch widgetFamily {
        case .systemSmall:
            return Array(events.prefix(1))
        case .systemMedium:
            return Array(events.prefix(2))
        case .systemLarge:
            return Array(events.prefix(4))
        case .systemExtraLarge:
            return Array(events.prefix(6))
        case .accessoryRectangular, .accessoryCircular, .accessoryInline:
            return Array(events.prefix(1))
        @unknown default:
            return Array(events.prefix(1))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.blue)
                Text("退休时间")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, 4)
            
            if eventsToShow.isEmpty {
                Text("没有即将到来的事件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(eventsToShow) { event in
                    EventRow(event: event)
                }
            }
            
            Spacer()
            
            Text("更新于: \(entry.date, formatter: dateFormatter)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}

// 单个事件行视图
struct EventRow: View {
    let event: Event
    
    var body: some View {
        Link(destination: URL(string: "retiretime://event/\(event.id.uuidString)")!) {
            HStack {
                VStack(alignment: .leading) {
                    Text(event.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(event.formattedDays)
                        .font(.caption)
                        .foregroundColor(event.isCountdown ? .blue : .orange)
                }
                
                Spacer()
                
                Text(event.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct RetireTimeWidget: Widget {
    let kind: String = "RetireTimeWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RetireTimeWidgetEntryView(entry: entry)
                    .containerBackground(.background.tertiary, for: .widget)
            } else {
                RetireTimeWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(UIColor.systemBackground))
            }
        }
        .configurationDisplayName("退休时间")
        .description("显示最近的几个重要日子/事件信息")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
