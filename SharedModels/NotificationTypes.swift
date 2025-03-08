//
//  NotificationTypes.swift
//  SharedModels
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import UserNotifications
import SwiftUI

// 提醒时间偏移枚举
public enum ReminderOffset: String, CaseIterable, Identifiable, Codable {
    case atTime = "当天提醒"
    case oneHourBefore = "提前1小时"
    case threehoursBefore = "提前3小时"
    case oneDayBefore = "提前1天"
    case twoDaysBefore = "提前2天"
    case oneWeekBefore = "提前1周"
    
    public var id: String { self.rawValue }
    
    // 获取偏移的秒数
    public var timeInterval: TimeInterval {
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
public enum NotificationSound: String, CaseIterable, Identifiable, Codable {
    case `default` = "默认"
    case alert = "提示音"
    case bell = "铃声"
    case electronic = "电子音"
    case none = "无声音"
    
    public var id: String { self.rawValue }
    
    // 获取对应的UNNotificationSound
    public var sound: UNNotificationSound? {
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