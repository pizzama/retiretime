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
    }
    
    // 更新事件
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
            WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
        }
    }
    
    // 删除事件
    func deleteEvent(_ event: Event) {
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
        let upcoming = events.filter { $0.daysRemaining >= 0 }
            .sorted { $0.daysRemaining < $1.daysRemaining }
        return Array(upcoming.prefix(limit))
    }
}