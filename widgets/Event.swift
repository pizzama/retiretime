//
//  Event.swift
//  widgets
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import SwiftUI

// 日历类型枚举
public enum CalendarType: String, CaseIterable, Identifiable, Codable {
    case gregorian = "公历"
    case lunar = "农历"
    case islamic = "伊斯兰教历"
    case hebrew = "犹太教历"
    case tibetan = "藏历"
    case indian = "印度历"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .gregorian: return "calendar"
        case .lunar: return "moon.stars"
        case .islamic: return "moon.circle"
        case .hebrew: return "star.square"
        case .tibetan: return "mountain.2"
        case .indian: return "sun.max"
        }
    }
}

// 重复类型枚举
public enum RepeatType: String, CaseIterable, Identifiable, Codable {
    case none = "不重复"
    case daily = "每天重复"
    case weekly = "每周重复"
    case monthly = "每月重复"
    case yearly = "每年重复"
    
    public var id: String { self.rawValue }
}

// 性别枚举
public enum Gender: String, CaseIterable, Identifiable, Codable {
    case male = "男"
    case female = "女"
    
    public var id: String { self.rawValue }
    
    // 获取退休年龄 - 2025年最新政策
    public func retirementAge(birthYear: Int) -> Int {
        switch self {
        case .male:
            // 男性退休年龄渐进式调整
            if birthYear < 1965 {
                return 60 // 1965年前出生的男性仍按60岁退休
            } else if birthYear < 1975 {
                return 61 // 1965-1974年出生的男性按61岁退休
            } else if birthYear < 1985 {
                return 62 // 1975-1984年出生的男性按62岁退休
            } else {
                return 63 // 1985年及以后出生的男性按63岁退休
            }
            
        case .female:
            // 女性退休年龄渐进式调整
            if birthYear < 1970 {
                return 55 // 1970年前出生的女性仍按55岁退休
            } else if birthYear < 1980 {
                return 56 // 1970-1979年出生的女性按56岁退休
            } else if birthYear < 1990 {
                return 57 // 1980-1989年出生的女性按57岁退休
            } else {
                return 58 // 1990年及以后出生的女性按58岁退休
            }
        }
    }
    
    // 兼容旧代码的计算属性
    public var retirementAge: Int {
        // 默认使用1980年作为默认出生年份
        return retirementAge(birthYear: 1980)
    }
}

public enum EventType: String, CaseIterable, Identifiable, Codable {
    case retirement = "退休日"
    case countdown = "倒计时"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .retirement: return "calendar.badge.clock"
        case .countdown: return "timer"
        }
    }
    
    public var color: Color {
        switch self {
        case .retirement: return .blue
        case .countdown: return .orange
        }
    }
}

public struct Event: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var date: Date
    public var type: EventType
    public var calendarType: CalendarType = .gregorian // 日历类型，默认为公历
    public var notes: String = ""
    public var reminderEnabled: Bool = false
    public var reminderDate: Date?
    public var reminderOffset: ReminderOffset = .atTime // 提醒时间偏移
    public var notificationSound: NotificationSound? = .default // 通知声音
    public var vibrationEnabled: Bool = true // 是否启用震动
    public var category: String = "未分类"
    public var colorData: CodableColor? = nil // 编码后的颜色数据
    public var icon: String? = nil // 自定义图标
    public var repeatType: RepeatType = .none // 重复类型
    public var lastOccurrence: Date? = nil // 上次发生日期，用于计算下次重复日期
    
    // 退休日特有属性
    public var birthDate: Date? = nil // 出生日期
    public var gender: Gender? = nil // 性别
    
    // 计算剩余天数或已过天数
    public var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTargetDate = calendar.startOfDay(for: date)
        
        // 使用timeIntervalSince方法计算日期差异，然后转换为天数
        let timeInterval = startOfTargetDate.timeIntervalSince(startOfToday)
        let days = Int(timeInterval / (60 * 60 * 24))
        return days
    }
    
    // 判断是倒计时还是正计时
    public var isCountdown: Bool {
        // 所有事件类型都返回true，表示都是倒计时
        return daysRemaining >= 0
    }
    
    // 格式化显示天数
    public var formattedDays: String {
        let days = abs(daysRemaining)
        if daysRemaining == 0 {
            return "今天"
        } else if isCountdown {
            return "还有\(days)天"
        } else {
            return "已过\(days)天"
        }
    }
    
    // 格式化日期显示
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // 获取显示的图标
    public var displayIcon: String {
        return icon ?? type.icon
    }
    
    // 获取显示的颜色
    public var displayColor: Color {
        return color ?? type.color
    }
    
    // 计算属性，用于访问和设置颜色
    public var color: Color? {
        get {
            colorData?.color
        }
        set {
            if let newValue = newValue {
                colorData = CodableColor(color: newValue)
            } else {
                colorData = nil
            }
        }
    }
    
    // 初始化方法
    public init(id: UUID = UUID(), name: String, date: Date, type: EventType) {
        self.id = id
        self.name = name
        self.date = date
        self.type = type
    }
    
    // 示例数据
    public static var samples: [Event] = [
        Event(name: "退休日", date: Calendar.current.date(byAdding: .year, value: 20, to: Date())!, type: .retirement),
        Event(name: "生日", date: Calendar.current.date(byAdding: .month, value: 2, to: Date())!, type: .countdown),
        Event(name: "结婚纪念日", date: Calendar.current.date(byAdding: .day, value: -100, to: Date())!, type: .countdown)
    ]
}

// 用于编码Color的辅助结构体
public struct CodableColor: Codable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let opacity: Double
    
    public init(color: Color) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        
        #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        #elseif os(macOS)
        NSColor(color).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        #endif
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.opacity = Double(opacity)
    }
    
    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}