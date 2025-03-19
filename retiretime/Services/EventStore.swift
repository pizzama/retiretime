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
    
    // 缓存变量
    private var filteredEventsCache: [String: [Event]] = [:]
    private var categoriesWithEventsCache: [String: [String]] = [:]
    
    // 清除所有缓存
    private func clearCaches() {
        // 清除事件数据缓存
        filteredEventsCache = [:]
        categoriesWithEventsCache = [:]
        
        // 发送缓存清除通知
        NotificationCenter.default.post(
            name: Notification.Name("ClearEventCache"),
            object: nil
        )
    }
    
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
        
        // 更新缓存而不是全部清除
        updateCachesForNewEvent(event)
        
        WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
        
        // 如果启用了提醒，则调度通知
        if event.reminderEnabled {
            NotificationManager.shared.scheduleNotification(for: event)
        }
        
        // 发送事件更新通知
        NotificationCenter.default.post(
            name: Notification.Name("EventUpdated"),
            object: nil,
            userInfo: ["eventId": event.id]
        )
    }
    
    // 更新事件
    func updateEvent(_ event: Event) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            let oldEvent = events[index]
            
            // 移除旧事件的通知
            if oldEvent.reminderEnabled {
                NotificationManager.shared.removeNotifications(for: oldEvent)
            }
            
            events[index] = event
            saveEvents()
            
            // 更新缓存而不是全部清除
            updateCachesForUpdatedEvent(oldEvent, newEvent: event)
            
            WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
            
            // 如果启用了提醒，则调度新通知
            if event.reminderEnabled {
                NotificationManager.shared.scheduleNotification(for: event)
            }
            
            // 如果是重复事件且已经过期，生成下一次事件
            if event.repeatType != .none && event.daysRemaining < 0 {
                generateNextOccurrence(for: event)
            }
            
            // 发送事件更新通知
            NotificationCenter.default.post(
                name: Notification.Name("EventUpdated"),
                object: nil,
                userInfo: ["eventId": event.id]
            )
        }
    }
    
    // 新增方法 - 更新缓存以包含新事件
    private func updateCachesForNewEvent(_ newEvent: Event) {
        // 仅处理非子事件
        guard newEvent.parentId == nil else { 
            clearCaches()  // 子事件仍然清除所有缓存
            return 
        }
        
        // 更新按分类筛选的缓存
        let category = newEvent.category
        let allCategory = "全部"
        
        // 更新"全部"分类的缓存
        if var events = filteredEventsCache[allCategory] {
            events.append(newEvent)
            events.sort { $0.daysRemaining < $1.daysRemaining }
            filteredEventsCache[allCategory] = events
        }
        
        // 更新事件所属分类的缓存
        if var events = filteredEventsCache[category] {
            events.append(newEvent)
            events.sort { $0.daysRemaining < $1.daysRemaining }
            filteredEventsCache[category] = events
        }
        
        // 更新包含事件的分类缓存
        if var categories = categoriesWithEventsCache[allCategory] {
            if !categories.contains(category) {
                categories.append(category)
                categories.sort()
                categoriesWithEventsCache[allCategory] = categories
            }
        }
        
        // 更新分类内事件缓存
        let categoryFilterKey = "\(category)_\(category)"
        let allCategoryFilterKey = "\(category)_\(allCategory)"
        
        if var events = filteredEventsCache[categoryFilterKey] {
            events.append(newEvent)
            events.sort { $0.daysRemaining < $1.daysRemaining }
            filteredEventsCache[categoryFilterKey] = events
        }
        
        if var events = filteredEventsCache[allCategoryFilterKey] {
            events.append(newEvent)
            events.sort { $0.daysRemaining < $1.daysRemaining }
            filteredEventsCache[allCategoryFilterKey] = events
        }
    }
    
    // 新增方法 - 更新缓存以反映已更新的事件
    private func updateCachesForUpdatedEvent(_ oldEvent: Event, newEvent: Event) {
        // 仅处理非子事件
        guard oldEvent.parentId == nil && newEvent.parentId == nil else { 
            clearCaches()  // 子事件仍然清除所有缓存
            return 
        }
        
        let oldCategory = oldEvent.category
        let newCategory = newEvent.category
        let categoryChanged = oldCategory != newCategory
        
        // 如果分类发生变化，处理更复杂，清除相关缓存
        if categoryChanged {
            clearCaches()
            return
        }
        
        // 分类未变化，只需替换事件
        let category = newEvent.category
        let allCategory = "全部"
        
        // 更新"全部"分类的缓存
        if var events = filteredEventsCache[allCategory] {
            if let index = events.firstIndex(where: { $0.id == newEvent.id }) {
                events[index] = newEvent
                events.sort { $0.daysRemaining < $1.daysRemaining }
                filteredEventsCache[allCategory] = events
            }
        }
        
        // 更新事件所属分类的缓存
        if var events = filteredEventsCache[category] {
            if let index = events.firstIndex(where: { $0.id == newEvent.id }) {
                events[index] = newEvent
                events.sort { $0.daysRemaining < $1.daysRemaining }
                filteredEventsCache[category] = events
            }
        }
        
        // 更新分类内事件缓存
        let categoryFilterKey = "\(category)_\(category)"
        let allCategoryFilterKey = "\(category)_\(allCategory)"
        
        if var events = filteredEventsCache[categoryFilterKey] {
            if let index = events.firstIndex(where: { $0.id == newEvent.id }) {
                events[index] = newEvent
                events.sort { $0.daysRemaining < $1.daysRemaining }
                filteredEventsCache[categoryFilterKey] = events
            }
        }
        
        if var events = filteredEventsCache[allCategoryFilterKey] {
            if let index = events.firstIndex(where: { $0.id == newEvent.id }) {
                events[index] = newEvent
                events.sort { $0.daysRemaining < $1.daysRemaining }
                filteredEventsCache[allCategoryFilterKey] = events
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
        clearCaches() // 清除缓存
        WidgetCenter.shared.reloadAllTimelines() // 刷新所有 Widget
        
        // 发送缓存清除通知
        NotificationCenter.default.post(
            name: Notification.Name("ClearEventCache"),
            object: nil
        )
    }
    
    // 获取所有分类
    var categories: [String] {
        let allCategories = events.map { $0.category }
        let uniqueCategories = Array(Set(allCategories)).sorted()
        return ["全部"] + uniqueCategories
    }
    
    // 根据分类筛选事件 (带缓存)
    func filteredEvents(by category: String) -> [Event] {
        // 检查缓存
        if let cachedEvents = filteredEventsCache[category] {
            return cachedEvents
        }
        
        // 缓存未命中，计算结果
        var result: [Event]
        
        if category == "全部" {
            // 只返回非子事件
            result = events.filter { $0.parentId == nil }
                .sorted { $0.daysRemaining < $1.daysRemaining }
        } else {
            // 只返回指定分类的非子事件
            result = events.filter { $0.category == category && $0.parentId == nil }
                .sorted { $0.daysRemaining < $1.daysRemaining }
        }
        
        // 更新缓存
        filteredEventsCache[category] = result
        
        return result
    }
    
    // 获取包含事件的分类列表（带缓存）
    func categoriesWithEvents(filter category: String) -> [String] {
        // 检查缓存
        if let cachedCategories = categoriesWithEventsCache[category] {
            return cachedCategories
        }
        
        // 缓存未命中，计算结果
        var result: [String]
        
        if category == "全部" {
            // 获取所有包含非子事件的分类
            let eventCategories = events.filter { $0.parentId == nil }.map { $0.category }
            result = Array(Set(eventCategories)).sorted()
        } else {
            // 如果已经按分类筛选，则只返回该分类
            result = [category]
        }
        
        // 更新缓存
        categoriesWithEventsCache[category] = result
        
        return result
    }
    
    // 获取指定分类中的事件（带缓存）
    func eventsInCategory(_ category: String, filter filterCategory: String) -> [Event] {
        // 创建缓存键
        let cacheKey = "\(category)_\(filterCategory)"
        
        // 检查缓存
        if let cachedEvents = filteredEventsCache[cacheKey] {
            return cachedEvents
        }
        
        // 缓存未命中，计算结果
        var result: [Event]
        
        if filterCategory == "全部" {
            // 返回指定分类中的所有非子事件
            result = events.filter { $0.category == category && $0.parentId == nil }
                .sorted { $0.daysRemaining < $1.daysRemaining }
        } else if category == filterCategory {
            // 如果筛选分类与当前分类相同，返回该分类中的所有非子事件
            result = events.filter { $0.category == category && $0.parentId == nil }
                .sorted { $0.daysRemaining < $1.daysRemaining }
        } else {
            // 如果筛选分类与当前分类不同，返回空数组
            result = []
        }
        
        // 更新缓存
        filteredEventsCache[cacheKey] = result
        
        return result
    }
    
    // 按类型筛选事件
    func filteredEvents(by type: EventType?) -> [Event] {
        guard let type = type else { return events.filter { $0.parentId == nil } }
        return events.filter { $0.type == type && $0.parentId == nil }
    }
    
    // 获取即将到来的事件（用于Widget显示）
    func upcomingEvents(limit: Int = 5) -> [Event] {
        // 检查是否有需要更新的重复事件
        checkAndUpdateRepeatingEvents()
        
        // 仅考虑非子事件
        let upcoming = events.filter { $0.daysRemaining >= 0 && $0.parentId == nil }
            .sorted { $0.daysRemaining < $1.daysRemaining }
        return Array(upcoming.prefix(limit))
    }
    
    // 检查并更新重复事件
    private func checkAndUpdateRepeatingEvents() {
        _ = Date()
        _ = Calendar.current
        
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
    
    // 获取指定事件的所有子事件
    func childEvents(for parentEvent: Event) -> [Event] {
        return events.filter { $0.parentId == parentEvent.id }
            .sorted { $0.daysRemaining < $1.daysRemaining }
    }
    
    // 创建子事件
    func createChildEvent(for parentEvent: Event, name: String, date: Date) -> Event {
        // 创建一个新的子事件，继承父事件的一些属性
        var childEvent = Event(
            name: name,
            date: date,
            type: parentEvent.type,
            calendarType: parentEvent.calendarType,
            category: parentEvent.category
        )
        
        // 设置父事件ID
        childEvent.parentId = parentEvent.id
        
        // 添加新事件
        addEvent(childEvent)
        
        return childEvent
    }
    
    // 删除子事件
    func deleteChildEvent(_ childEvent: Event) {
        guard childEvent.parentId != nil else { return }
        
        // 删除该子事件
        deleteEvent(childEvent)
    }
    
    // 根据ID获取事件
    func getEvent(by id: UUID) -> Event? {
        return events.first { $0.id == id }
    }
}