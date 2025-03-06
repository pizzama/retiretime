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
            return UNNotificationSound(named: UNNotificationSoundName("alert.caf"))
        case .bell:
            return UNNotificationSound(named: UNNotificationSoundName("bell.caf"))
        case .electronic:
            return UNNotificationSound(named: UNNotificationSoundName("electronic.caf"))
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
            }
        }
    }
    
    // 请求通知权限
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("通知授权请求错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 为事件调度通知
    func scheduleNotification(for event: Event) {
        // 如果没有启用提醒或没有提醒日期，则不创建通知
        guard event.reminderEnabled, let reminderDate = event.reminderDate else { return }
        
        // 如果提醒时间已过，则不创建通知
        if reminderDate < Date() {
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
        } else {
            content.sound = UNNotificationSound.default
        }
        
        // 设置震动（通过userInfo传递）
        content.userInfo = ["vibrate": event.vibrationEnabled]
        
        // 创建触发器
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "event-\(event.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        // 添加通知请求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 移除事件的通知
    func removeNotifications(for event: Event) {
        let identifier = "event-\(event.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // 移除所有通知
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // 计算提醒日期
    func calculateReminderDate(eventDate: Date, offset: ReminderOffset) -> Date {
        return eventDate.addingTimeInterval(offset.timeInterval)
    }
}