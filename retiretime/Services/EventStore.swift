//
//  EventStore.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import Combine
import WidgetKit

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    private let saveKey = "savedEvents"
    
    init() {
        loadEvents()
    }
    
    // 加载保存的事件
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Event].self, from: data) {
                self.events = decoded
                return
            }
        }
        
        // 如果没有保存的数据或解码失败，使用示例数据
        self.events = Event.samples
    }
    
    // 保存事件到UserDefaults
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // 添加新事件
    func addEvent(_ event: Event) {
        events.append(event)
        saveEvents()
        WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
        
        // 如果启用了提醒，则调度通知
        if event.reminderEnabled {
            NotificationManager.shared.scheduleNotification(for: event)
        }
    }
    
    // 更新事件
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            // 移除旧事件的通知
            if events[index].reminderEnabled {
                NotificationManager.shared.removeNotifications(for: events[index])
            }
            
            events[index] = event
            saveEvents()
            WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
            
            // 如果启用了提醒，则调度新通知
            if event.reminderEnabled {
                NotificationManager.shared.scheduleNotification(for: event)
            }
            
            // 如果是重复事件且已经过期，生成下一次事件
            if event.repeatType != .none && event.daysRemaining < 0 {
                generateNextOccurrence(for: event)
            }
        }
    }
    
    // 删除事件
    func deleteEvent(_ event: Event) {
        // 移除事件的通知
        if event.reminderEnabled {
            NotificationManager.shared.removeNotifications(for: event)
        }
        
        events.removeAll { $0.id == event.id }
        saveEvents()
        WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
    }
    
    // 获取所有分类
    var categories: [String] {
        var categories = Set(events.map { $0.category })
        categories.insert("全部")
        return Array(categories).sorted()
    }
    
    // 按分类筛选事件
    func filteredEvents(by category: String) -> [Event] {
        if category == "全部" {
            return events
        }
        return events.filter { $0.category == category }
    }
    
    // 按类型筛选事件
    func filteredEvents(by type: EventType?) -> [Event] {
        guard let type = type else { return events }
        return events.filter { $0.type == type }
    }
    
    // 获取即将到来的事件（用于Widget显示）
    func upcomingEvents(limit: Int = 5) -> [Event] {
        // 检查是否有需要更新的重复事件
        checkAndUpdateRepeatingEvents()
        
        let upcoming = events.filter { $0.daysRemaining >= 0 }
            .sorted { $0.daysRemaining < $1.daysRemaining }
        return Array(upcoming.prefix(limit))
    }
    
    // 检查并更新重复事件
    private func checkAndUpdateRepeatingEvents() {
        let today = Date()
        let calendar = Calendar.current
        
        for event in events where event.repeatType != .none {
            // 如果事件已过期且需要重复
            if event.daysRemaining < 0 {
                generateNextOccurrence(for: event)
            }
        }
    }
    
    // 生成下一次重复事件
    private func generateNextOccurrence(for event: Event) {
        let calendar = Calendar.current
        var nextDate = event.date
        let baseDate = event.lastOccurrence ?? event.date
        
        // 根据重复类型计算下一次日期
        switch event.repeatType {
        case .daily:
            if let settings = event.repeatSettings {
                // 使用重复间隔
                let interval = settings.interval
                nextDate = calendar.date(byAdding: .day, value: interval, to: baseDate)!
            } else {
                // 没有具体设置，默认加一天
                nextDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
            }
            
        case .weekly:
            if let settings = event.repeatSettings, let weekday = settings.weekday {
                // 如果有指定星期几，则找到下一个该星期几的日期
                var components = calendar.dateComponents([.year, .month, .day, .weekday], from: baseDate)
                
                // 计算当前日期的星期几与目标星期几的差距
                let currentWeekday = components.weekday ?? 1
                let daysToAdd = (weekday - currentWeekday + 7) % 7
                
                // 如果今天就是目标星期几，则加7天
                let daysToAddFinal = daysToAdd == 0 ? 7 : daysToAdd
                
                // 考虑重复间隔
                let interval = settings.interval
                if interval > 1 && daysToAdd == 0 {
                    // 如果是同一天且间隔大于1，则需要乘以间隔
                    nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: baseDate)!
                } else {
                    nextDate = calendar.date(byAdding: .day, value: daysToAddFinal, to: baseDate)!
                    
                    // 如果间隔大于1，且不是同一天，则需要额外加上(间隔-1)周
                    if interval > 1 {
                        nextDate = calendar.date(byAdding: .weekOfYear, value: interval - 1, to: nextDate)!
                    }
                }
            } else {
                // 没有具体设置，默认加一周乘以间隔
                let interval = event.repeatSettings?.interval ?? 1
                nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: baseDate)!
            }
            
        case .monthly:
            if let settings = event.repeatSettings, let monthDay = settings.monthDay {
                // 如果有指定每月几号，则找到下个月的该日期
                var components = calendar.dateComponents([.year, .month], from: baseDate)
                let interval = settings.interval
                components.month = (components.month ?? 1) + interval // 下个月乘以间隔
                components.day = monthDay
                
                // 确保日期有效（例如，2月没有30日）
                if let date = calendar.date(from: components) {
                    nextDate = date
                } else {
                    // 如果日期无效，则使用月末日期
                    components.month = (components.month ?? 1) - interval // 回到当前月
                    components.day = 1 // 设置为下个月1号
                    if let firstOfNextMonth = calendar.date(from: components) {
                        components.month = (components.month ?? 1) + interval // 再次设为下个月
                        // 减去一天得到当前月最后一天
                        nextDate = calendar.date(byAdding: .day, value: -1, to: firstOfNextMonth)!
                    } else {
                        // 默认加一个月乘以间隔
                        nextDate = calendar.date(byAdding: .month, value: interval, to: baseDate)!
                    }
                }
            } else {
                // 没有具体设置，默认加一个月乘以间隔
                let interval = event.repeatSettings?.interval ?? 1
                nextDate = calendar.date(byAdding: .month, value: interval, to: baseDate)!
            }
            
        case .yearly:
            if let settings = event.repeatSettings, let month = settings.month, let yearDay = settings.yearDay {
                // 如果有指定每年几月几日，则找到下一年的该日期
                var components = calendar.dateComponents([.year], from: baseDate)
                let interval = settings.interval
                components.year = (components.year ?? 1) + interval // 下一年乘以间隔
                components.month = month
                components.day = yearDay
                
                // 确保日期有效
                if let date = calendar.date(from: components) {
                    nextDate = date
                } else {
                    // 如果日期无效（例如2月29日在非闰年），则使用月末
                    components.day = 1 // 设置为该月1号
                    if let firstOfMonth = calendar.date(from: components) {
                        components.month = (components.month ?? 1) + 1 // 下个月
                        if let firstOfNextMonth = calendar.date(from: components) {
                            // 减去一天得到当前月最后一天
                            nextDate = calendar.date(byAdding: .day, value: -1, to: firstOfNextMonth)!
                        } else {
                            // 默认加一年乘以间隔
                            nextDate = calendar.date(byAdding: .year, value: interval, to: baseDate)!
                        }
                    } else {
                        // 默认加一年乘以间隔
                        nextDate = calendar.date(byAdding: .year, value: interval, to: baseDate)!
                    }
                }
            } else {
                // 没有具体设置，默认加一年乘以间隔
                let interval = event.repeatSettings?.interval ?? 1
                nextDate = calendar.date(byAdding: .year, value: interval, to: baseDate)!
            }
            
        case .none:
            return
        }
        
        // 更新事件
        var updatedEvent = event
        updatedEvent.date = nextDate
        updatedEvent.lastOccurrence = baseDate
        
        // 如果有提醒，也相应更新提醒时间
        if let reminderDate = event.reminderDate {
            let timeInterval = reminderDate.timeIntervalSince(event.date)
            updatedEvent.reminderDate = nextDate.addingTimeInterval(timeInterval)
        }
        
        // 更新事件
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = updatedEvent
            saveEvents()
        }
    }
}