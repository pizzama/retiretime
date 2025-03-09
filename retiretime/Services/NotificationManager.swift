//
//  NotificationManager.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import UserNotifications
import SwiftUI
// 导入包含ReminderOffset和NotificationSound的文件

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        // 设置通知中心代理
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - UNUserNotificationCenterDelegate 方法
    
    // 当应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 允许在前台显示通知
        print("前台收到通知: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    // 当用户点击通知时
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        print("用户点击了通知: \(identifier)")
        
        // 处理用户点击通知的逻辑
        if let eventId = response.notification.request.content.userInfo["eventId"] as? String {
            print("通知对应的事件ID: \(eventId)")
            // 这里可以添加打开对应事件详情的逻辑
        }
        
        // 重置应用图标上的通知徽章
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("用户点击通知后已重置应用图标通知徽章")
        }
        
        completionHandler()
    }
    
    // 检查通知授权状态
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // 更新授权状态，包括临时授权
                self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                
                // 详细记录通知设置状态
                print("========== 通知设置详情 ==========")
                print("通知授权状态: \(self.authStatusString(settings.authorizationStatus))")
                print("通知提醒设置: \(self.settingStatusString(settings.alertSetting))")
                print("通知声音设置: \(self.settingStatusString(settings.soundSetting))")
                print("通知徽章设置: \(self.settingStatusString(settings.badgeSetting))")
                print("通知横幅设置: \(self.alertStyleString(settings.alertStyle))")
                print("临时通知设置: \(settings.providesAppNotificationSettings)")
                print("锁屏通知设置: \(self.settingStatusString(settings.lockScreenSetting))")
                print("通知中心设置: \(self.settingStatusString(settings.notificationCenterSetting))")
                print("临时授权状态: \(settings.authorizationStatus == .provisional)")
                print("====================================")
            }
        }
    }
    
    // 辅助方法：转换授权状态为可读字符串
    private func authStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "已授权 (authorized)"
        case .denied: return "已拒绝 (denied)"
        case .notDetermined: return "未确定 (notDetermined)"
        case .provisional: return "临时授权 (provisional)"
        case .ephemeral: return "临时会话 (ephemeral)"
        @unknown default: return "未知状态 (\(status.rawValue))"
        }
    }
    
    // 辅助方法：转换设置状态为可读字符串
    private func settingStatusString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .enabled: return "已启用 (enabled)"
        case .disabled: return "已禁用 (disabled)"
        case .notSupported: return "不支持 (notSupported)"
        @unknown default: return "未知状态 (\(setting.rawValue))"
        }
    }
    
    // 辅助方法：转换提醒样式为可读字符串
    private func alertStyleString(_ style: UNAlertStyle) -> String {
        switch style {
        case .none: return "无 (none)"
        case .banner: return "横幅 (banner)"
        case .alert: return "提醒 (alert)"
        @unknown default: return "未知样式 (\(style.rawValue))"  
        }
    }
    
    // 请求通知权限
    func requestAuthorization() {
        print("开始请求通知权限")
        // 在iOS真机上，需要确保请求所有必要的通知权限
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
                
                // 注册远程通知（对于真机很重要）
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
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
        // 首先检查通知权限
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // 如果没有通知权限，记录并尝试请求
                if settings.authorizationStatus != .authorized {
                    print("⚠️ 警告：没有通知权限，无法创建通知。当前状态: \(settings.authorizationStatus.rawValue)")
                    self.requestAuthorization()
                    return
                }
                
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
                self.removeNotifications(for: event)
                
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
                
                // 设置震动和标识符（通过userInfo传递）
                content.userInfo = ["vibrate": event.vibrationEnabled, "eventId": event.id.uuidString]
                
                // 设置徽章数字
                content.badge = 1
                
                // 创建触发器 - 修改为使用日期组件而非完整日期
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                print("通知触发组件: 年=\(components.year ?? 0), 月=\(components.month ?? 0), 日=\(components.day ?? 0), 时=\(components.hour ?? 0), 分=\(components.minute ?? 0)")
                
                // 创建测试触发器（用于调试）
                let testDate = Date().addingTimeInterval(10) // 10秒后触发
                let testComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: testDate)
                
                // 根据是否为测试模式选择不同的触发器
                let isTestMode = false // 设置为false使用实际提醒日期
                let trigger: UNNotificationTrigger
                
                if isTestMode {
                    // 测试模式：使用10秒后触发的触发器
                    trigger = UNCalendarNotificationTrigger(dateMatching: testComponents, repeats: false)
                    print("⚠️ 测试模式：通知将在10秒后触发")
                } else {
                    // 正常模式：使用实际提醒日期的触发器
                    trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    print("正常模式：通知将在\(reminderDate)触发")
                }
                
                // 创建通知请求
                let identifier = "event-\(event.id.uuidString)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("⚠️ 添加通知失败: \(error.localizedDescription)")
                    } else {
                        print("✅ 成功为事件\(event.name)创建通知，ID=\(identifier)")
                        // 列出所有待处理的通知，确认添加成功
                        self.listPendingNotifications()
                    }
                }
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