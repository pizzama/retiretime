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
    private let saveKey = "savedEvents" // 确保与Widget中使用的键名完全一致
    private let userDefaults: UserDefaults
    
    init() {
        // 使用App Group的UserDefaults实例，确保Widget和主应用可以共享数据
        if let groupUserDefaults = UserDefaults(suiteName: "group.com.fenghua.retiretime") {
            self.userDefaults = groupUserDefaults
            print("✅ 成功创建App Group的UserDefaults实例")
        } else {
            self.userDefaults = UserDefaults.standard
            print("⚠️ 警告：无法创建App Group的UserDefaults，将使用标准UserDefaults")
            print("⚠️ 这将导致Widget无法访问应用数据，请检查Entitlements配置")
        }
        loadEvents()
    }
    
    // 加载保存的事件
    private func loadEvents() {
        if let data = userDefaults.data(forKey: saveKey) {
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
        do {
            let encoded = try JSONEncoder().encode(events)
            userDefaults.set(encoded, forKey: saveKey)
            
            // 强制同步数据，确保立即写入到磁盘，这对Widget共享数据至关重要
            let success = userDefaults.synchronize()
            if !success {
                print("⚠️ 警告：UserDefaults同步可能未成功完成")
            }
            
            // 记录保存的数据大小和事件数量，便于调试
            print("✅ 已保存事件数据：\(events.count)个事件，数据大小约\(encoded.count)字节")
            print("✅ 保存位置：App Group 'group.com.fenghua.retiretime'")
            
            // 刷新所有Widget，确保数据更新
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ 已请求刷新所有Widget")
        } catch {
            print("❌ 错误：保存事件数据失败 - \(error.localizedDescription)")
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
            // 默认加一天
            nextDate = calendar.date(byAdding: .day, value: 1, to: baseDate)!
            
        case .weekly:
            // 默认加一周
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)!
            
        case .monthly:
            // 默认加一个月
            nextDate = calendar.date(byAdding: .month, value: 1, to: baseDate)!
            
        case .yearly:
            // 默认加一年
            nextDate = calendar.date(byAdding: .year, value: 1, to: baseDate)!
            
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