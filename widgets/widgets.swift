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

struct EventEntry: TimelineEntry {
    let date: Date
    let events: [Event]
    let configuration: ConfigurationIntent
}

struct Provider: IntentTimelineProvider {
    // 从App Group的UserDefaults获取事件数据
    func loadEvents() -> [Event] {
        let timestamp = Date().timeIntervalSince1970
        print("[\(timestamp)] Widget正在尝试加载事件数据...")
        
        // 记录当前Bundle ID和App Group信息，用于调试
        let bundleID = Bundle.main.bundleIdentifier ?? "未知"
        print("[\(timestamp)] 当前Widget Bundle ID: \(bundleID)")
        print("[\(timestamp)] 尝试访问App Group: group.com.fenghua.retiretime")
        
        // 尝试访问App Group的UserDefaults
        guard let userDefaults = UserDefaults(suiteName: "group.com.fenghua.retiretime") else {
            print("[\(timestamp)] ⚠️ 严重错误：无法访问App Group的UserDefaults，请检查Entitlements配置")
            print("[\(timestamp)] ⚠️ 确认主应用和Widget扩展都添加了相同的App Group权限")
            print("[\(timestamp)] ⚠️ 检查widgetsExtension.entitlements文件是否包含正确的App Group权限")
            return Event.samples
        }
        
        // 列出UserDefaults中的所有键，帮助调试
        print("[\(timestamp)] UserDefaults中的所有键: \(userDefaults.dictionaryRepresentation().keys)")
        
        // 检查是否有保存的事件数据
        guard let data = userDefaults.data(forKey: "savedEvents") else {
            print("[\(timestamp)] ⚠️ UserDefaults中没有找到savedEvents数据，可能主应用尚未保存任何事件")
            print("[\(timestamp)] ⚠️ 请确认主应用中的EventStore正确保存了数据到App Group")
            print("[\(timestamp)] ⚠️ 检查主应用中的saveKey是否与Widget中使用的键名相同")
            return Event.samples
        }
        
        print("[\(timestamp)] ✅ 从UserDefaults获取到数据，大小: \(data.count) 字节")
        
        // 尝试解码数据
        do {
            let decoded = try JSONDecoder().decode([Event].self, from: data)
            print("[\(timestamp)] ✅ 成功解码事件数据，共 \(decoded.count) 个事件")
            // 按照剩余天数排序，优先显示即将到来的事件
            let sorted = decoded.sorted { abs($0.daysRemaining) < abs($1.daysRemaining) }
            print("[\(timestamp)] ✅ 事件已排序，准备返回数据")
            return sorted
        } catch {
            print("[\(timestamp)] ❌ 解码事件数据失败: \(error.localizedDescription)")
            print("[\(timestamp)] ❌ 错误详情: \(error)")
            print("[\(timestamp)] ⚠️ 可能是数据格式不兼容，请确保Widget和主应用使用相同的Event模型")
            print("[\(timestamp)] ⚠️ 检查Event、ReminderOffset和NotificationSound等模型是否在Widget和主应用中完全一致")
        }
        
        print("[\(timestamp)] ⚠️ 使用示例数据代替实际数据")
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

        // 使用更积极的刷新策略，确保Widget能够定期更新
        // .atEnd - 仅在最后一个条目显示完毕后刷新
        // .after(date) - 在指定日期后刷新
        // .never - 永不自动刷新，仅通过reloadAllTimelines()刷新
        
        // 设置为每小时刷新一次，并在主应用数据变化时通过reloadAllTimelines()强制刷新
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        
        print("Widget时间线已创建，条目数量: \(entries.count)，下次自动刷新时间: \(refreshDate)")
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
        #if os(iOS) // iOS 16+ 支持 extraLarge 尺寸
        case .systemExtraLarge:
            return Array(events.prefix(6))
        #endif
        #if os(iOS) // iOS 16+ 支持锁屏小组件
        case .accessoryRectangular, .accessoryCircular, .accessoryInline:
            return Array(events.prefix(1))
        #endif
        @unknown default:
            return Array(events.prefix(1))
        }
    }

    var body: some View {
        Group {
            switch widgetFamily {
            // 锁屏圆形小组件
            case .accessoryCircular:
                ZStack {
                    // 简单的圆形背景
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                    
                    if let event = eventsToShow.first {
                        VStack(spacing: 2) {
                            // 只显示天数
                            Text("\(abs(event.daysRemaining))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            // 显示单位
                            Text("天")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                }
                
            // 锁屏行内小组件
            case .accessoryInline:
                if let event = eventsToShow.first {
                    Label {
                        Text(event.name + ": " + event.formattedDays)
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                    }
                    .font(.caption)
                } else {
                    Label("没有事件", systemImage: "calendar")
                        .font(.caption)
                }
                
            // 锁屏矩形小组件
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text("退休时间")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    if let event = eventsToShow.first {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(event.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text(event.formattedDays)
                                    .font(.caption2)
                                    .foregroundColor(event.isCountdown ? .blue : .orange)
                            }
                            Spacer()
                        }
                    } else {
                        Text("没有即将到来的事件")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                
            // 常规主屏幕小组件
            default:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text("退休时间")
                            .font(.headline)
                            .foregroundColor(.primary) // 使用.primary确保在任何主题下都有良好的可见性
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    if eventsToShow.isEmpty {
                        Text("没有即将到来的事件")
                            .font(.subheadline)
                            .foregroundColor(.secondary) // 使用.secondary确保在任何主题下都有良好的可见性
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
                        .foregroundColor(.secondary) // 使用.secondary确保在任何主题下都有良好的可见性
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
            }
        }
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
                        .foregroundColor(.primary) // 使用.primary确保在任何主题下都有良好的可见性
                        .lineLimit(1)
                    
                    Text(event.formattedDays)
                        .font(.caption)
                        .foregroundColor(event.isCountdown ? .blue : .orange)
                }
                
                Spacer()
                
                Text(event.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary) // 使用.secondary确保在任何主题下都有良好的可见性
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
                    .containerBackground(.background, for: .widget)
            } else {
                RetireTimeWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(UIColor.systemBackground)) // 使用系统背景色以适应深色/浅色模式
            }
        }
        .configurationDisplayName("退休时间")
        .description("显示最近的几个重要日子/事件信息")
        // 支持所有可能的Widget尺寸，包括锁屏小组件
        .supportedFamilies([
            .systemSmall, 
            .systemMedium, 
            .systemLarge,
            // 启用锁屏小组件支持
            .accessoryCircular, 
            .accessoryRectangular, 
            .accessoryInline
        ])
        // 添加更多配置以确保Widget正常显示
        .contentMarginsDisabled()
    }
}
