//
//  NotificationManager.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import UserNotifications
import SwiftUI

// 提醒时间偏移枚举
enum ReminderOffset: String, CaseIterable, Identifiable, Codable {
    case atTime = "当天提醒"
    case oneHourBefore = "提前1小时"
    case threehoursBefore = "提前3小时"
    case oneDayBefore = "提前1天"
    case twoDaysBefore = "提前2天"
    case oneWeekBefore = "提前1周"
    
    var id: String { self.rawValue }
    
    // 获取偏移的秒数
    var timeInterval: TimeInterval {
        switch self {
        case .atTime:
            return 0
        case .oneHourBefore:
            return -3600 // 1小时 = 3600秒
        case .threehoursBefore:
            return -10800 // 3小时 = 10800秒
        case .oneDayBefore:
            return -86400 // 1天 = 86400秒
        case .twoDaysBefore:
            return -172800 // 2天 = 172800秒
        case .oneWeekBefore:
            return -604800 // 1周 = 604800秒
        }
    }
}

// 通知声音选项
enum NotificationSound: String, CaseIterable, Identifiable, Codable {
    case `default` = "默认"
    case alert = "提示音"
    case bell = "铃声"
    case electronic = "电子音"
    case none = "无声音"
    
    var id: String { self.rawValue }
    
    // 获取对应的UNNotificationSound
    var sound: UNNotificationSound? {
        switch self {
        case .default:
            return UNNotificationSound.default
        case .alert:
            // 使用系统声音而非自定义声音文件
            return UNNotificationSound.defaultCritical
        case .bell:
            // 使用系统声音而非自定义声音文件
            return UNNotificationSound.defaultRingtone
        case .electronic:
            // 使用系统声音而非自定义声音文件
            return UNNotificationSound.default
        case .none:
            return nil
        }
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // 检查通知授权状态
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                print("通知授权状态: \(settings.authorizationStatus.rawValue)")
                print("通知提醒设置: \(settings.alertSetting.rawValue)")
                print("通知声音设置: \(settings.soundSetting.rawValue)")
                print("通知徽章设置: \(settings.badgeSetting.rawValue)")
            }
        }
    }
    
    // 请求通知权限
    func requestAuthorization() {
        print("开始请求通知权限")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                print("通知权限请求结果: \(granted ? "已授权" : "未授权")")
                if let error = error {
                    print("通知授权请求错误: \(error.localizedDescription)")
                }
                
                // 获取当前的通知设置
                self.checkAuthorizationStatus()
                
                // 列出所有待处理的通知
                self.listPendingNotifications()
            }
        }
    }
    
    // 列出所有待处理的通知
    func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("当前待处理通知数量: \(requests.count)")
            for request in requests {
                print("通知ID: \(request.identifier)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    let components = trigger.dateComponents
                    print("  触发时间: \(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0) \(components.hour ?? 0):\(components.minute ?? 0)")
                    print("  是否重复: \(trigger.repeats)")
                }
            }
        }
    }
    
    // 为事件调度通知
    func scheduleNotification(for event: Event) {
        // 如果没有启用提醒或没有提醒日期，则不创建通知
        guard event.reminderEnabled, let reminderDate = event.reminderDate else {
            print("未为事件\(event.name)创建通知: 提醒未启用或提醒日期为空")
            return
        }
        
        // 如果提醒时间已过，则不创建通知
        if reminderDate < Date() {
            print("未为事件\(event.name)创建通知: 提醒时间已过 (\(reminderDate))")
            return
        }
        
        // 移除该事件的现有通知
        removeNotifications(for: event)
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = event.name
        
        // 设置通知正文
        if event.isCountdown {
            content.body = "倒计时：还有\(abs(event.daysRemaining))天"
        } else {
            content.body = "已过\(abs(event.daysRemaining))天"
        }
        
        // 添加备注信息（如果有）
        if !event.notes.isEmpty {
            content.subtitle = event.notes
        }
        
        // 设置声音
        if let soundSetting = event.notificationSound {
            content.sound = soundSetting.sound
            print("为事件\(event.name)设置通知声音: \(soundSetting.rawValue)")
        } else {
            content.sound = UNNotificationSound.default
            print("为事件\(event.name)设置默认通知声音")
        }
        
        // 设置通知类别（对于iOS真机通知显示很重要）
        content.categoryIdentifier = "EVENT_REMINDER"
        
        // 设置震动（通过userInfo传递）
        content.userInfo = ["vibrate": event.vibrationEnabled, "eventId": event.id.uuidString]
        
        // 创建触发器 - 修改为使用日期组件而非完整日期
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        print("通知触发组件: 年=\(components.year ?? 0), 月=\(components.month ?? 0), 日=\(components.day ?? 0), 时=\(components.hour ?? 0), 分=\(components.minute ?? 0)")
        
        // 创建日历触发器，不包含秒以提高触发可靠性
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 创建请求
        let identifier = "event-\(event.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        print("准备添加通知: ID=\(identifier), 事件=\(event.name), 提醒时间=\(reminderDate)")
        print("触发时间组件: \(components)")
        print("下次触发时间: \(trigger.nextTriggerDate() ?? Date())")
        
        // 添加通知请求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            } else {
                print("成功添加通知: ID=\(identifier), 事件=\(event.name)")
                // 列出所有待处理的通知，确认添加成功
                self.listPendingNotifications()
                
                // 检查通知权限状态
                self.checkAuthorizationStatus()
            }
        }
    }
    
    // 移除事件的通知
    func removeNotifications(for event: Event) {
        let identifier = "event-\(event.id.uuidString)"
        print("移除事件通知: ID=\(identifier), 事件=\(event.name)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // 移除所有通知
    func removeAllNotifications() {
        print("移除所有通知")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // 计算提醒日期
    func calculateReminderDate(eventDate: Date, offset: ReminderOffset) -> Date {
        let result = eventDate.addingTimeInterval(offset.timeInterval)
        print("计算提醒日期: 事件日期=\(eventDate), 偏移=\(offset.rawValue), 结果=\(result)")
        return result
    }
}