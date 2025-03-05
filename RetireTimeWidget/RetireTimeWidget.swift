//
//  RetireTimeWidget.swift
//  RetireTimeWidget
//
//  Created by Trae AI on 2025/3/5.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), events: Event.samples.prefix(3).map { EventPreview(id: $0.id, name: $0.name, daysRemaining: $0.daysRemaining, isCountdown: $0.isCountdown) })
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let eventStore = EventStore()
        let upcomingEvents = eventStore.upcomingEvents(limit: 3)
        let eventPreviews = upcomingEvents.map { EventPreview(id: $0.id, name: $0.name, daysRemaining: $0.daysRemaining, isCountdown: $0.isCountdown) }
        let entry = SimpleEntry(date: Date(), events: eventPreviews)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let eventStore = EventStore()
        let upcomingEvents = eventStore.upcomingEvents(limit: 3)
        let eventPreviews = upcomingEvents.map { EventPreview(id: $0.id, name: $0.name, daysRemaining: $0.daysRemaining, isCountdown: $0.isCountdown) }
        
        // 创建一个更新时间点，每天午夜更新一次
        var components = DateComponents()
        components.hour = 0
        components.minute = 0
        components.second = 0
        let calendar = Calendar.current
        let midnight = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime)!
        
        let entry = SimpleEntry(date: Date(), events: eventPreviews)
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// 用于Widget显示的简化事件数据结构
struct EventPreview: Identifiable {
    let id: UUID
    let name: String
    let daysRemaining: Int
    let isCountdown: Bool
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let events: [EventPreview]
}

struct RetireTimeWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                Text("退休倒计时")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .padding(.bottom, 4)
            
            if entry.events.isEmpty {
                Spacer()
                Text("暂无倒计时事件")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ForEach(entry.events) { event in
                    WidgetEventRow(event: event)
                }
                Spacer()
            }
        }
        .padding()
    }
}

struct WidgetEventRow: View {
    let event: EventPreview
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text(event.daysRemaining == 0 ? "今天" : (event.isCountdown ? "还有\(abs(event.daysRemaining))天" : "已过\(abs(event.daysRemaining))天"))
                    .font(.system(size: 12))
                    .foregroundColor(event.isCountdown ? .green : .orange )
            }
            
            Spacer()
            
            Text("\(abs(event.daysRemaining))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(event.isCountdown ? .green : .orange)
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct RetireTimeWidget: Widget {
    let kind: String = "RetireTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RetireTimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("退休倒计时")
        .description("显示最近的退休倒计时事件")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RetireTimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        RetireTimeWidgetEntryView(entry: SimpleEntry(date: Date(), events: Event.samples.prefix(3).map { EventPreview(id: $0.id, name: $0.name, daysRemaining: $0.daysRemaining, isCountdown: $0.isCountdown) }))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}