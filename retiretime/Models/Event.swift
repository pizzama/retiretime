//
//  Event.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import SwiftUI

// 日历类型枚举
enum CalendarType: String, CaseIterable, Identifiable, Codable {
    case gregorian = "公历"
    case lunar = "农历"
    case islamic = "伊斯兰教历"
    case hebrew = "犹太教历"
    case tibetan = "藏历"
    case indian = "印度历"
    
    var id: String { self.rawValue }
    
    var icon: String {
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
enum RepeatType: String, CaseIterable, Identifiable, Codable {
    case none = "不重复"
    case daily = "每天重复"
    case weekly = "每周重复"
    case monthly = "每月重复"
    case yearly = "每年重复"
    
    var id: String { self.rawValue }
}

// 重复设置结构体已移除

// 性别枚举
enum Gender: String, CaseIterable, Identifiable, Codable {
    case male = "男"
    case female = "女"
    
    var id: String { self.rawValue }
    
    // 获取退休年龄
    var retirementAge: Int {
        switch self {
        case .male: return 60
        case .female: return 55
        }
    }
}

enum EventType: String, CaseIterable, Identifiable, Codable {
    case retirement = "退休日"
    case countdown = "倒计时"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .retirement: return "calendar.badge.clock"
        case .countdown: return "timer"
        }
    }
    
    var color: Color {
        switch self {
        case .retirement: return .blue
        case .countdown: return .orange
        }
    }
}

struct Event: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var type: EventType
    var calendarType: CalendarType = .gregorian // 日历类型，默认为公历
    var notes: String = ""
    var reminderEnabled: Bool = false
    var reminderDate: Date?
    var reminderOffset: ReminderOffset = .atTime // 提醒时间偏移
    var notificationSound: NotificationSound? = .default // 通知声音
    var vibrationEnabled: Bool = true // 是否启用震动
    var category: String = "未分类"
    var colorData: CodableColor? = nil // 编码后的颜色数据
    var icon: String? = nil // 自定义图标
    var repeatType: RepeatType = .none // 重复类型
    var lastOccurrence: Date? = nil // 上次发生日期，用于计算下次重复日期
    
    // 退休日特有属性
    var birthDate: Date? = nil // 出生日期
    var gender: Gender? = nil // 性别
    
    // 计算剩余天数或已过天数
    var daysRemaining: Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTargetDate = calendar.startOfDay(for: date)
        
        // 使用timeIntervalSince方法计算日期差异，然后转换为天数
        let timeInterval = startOfTargetDate.timeIntervalSince(startOfToday)
        let days = Int(timeInterval / (60 * 60 * 24))
        return days
    }
    
    // 判断是倒计时还是正计时
    var isCountdown: Bool {
        // 所有事件类型都返回true，表示都是倒计时
        return daysRemaining >= 0
    }
    
    // 格式化显示天数
    var formattedDays: String {
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
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // 获取显示的图标
    var displayIcon: String {
        return icon ?? type.icon
    }
    
    // 获取显示的颜色
    var displayColor: Color {
        return color ?? type.color
    }
    
    // 计算属性，用于访问和设置颜色
    var color: Color? {
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
}

// 用于编码Color的辅助结构体
struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
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
    
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

// 示例数据
extension Event {
    static var samples: [Event] {
        let calendar = Calendar.current
        let today = Date()
        
        // 创建出生日期 - 以当前年份减去30年作为示例
        let currentYear = calendar.component(.year, from: today)
        var birthDateComponents = DateComponents()
        birthDateComponents.year = currentYear - 30 // 假设30岁
        birthDateComponents.month = 5
        birthDateComponents.day = 7
        let birthDate = calendar.date(from: birthDateComponents)!
        
        // 计算退休日期 - 男性60岁退休
        let retirementAge = Gender.male.retirementAge
        var retirementDateComponents = DateComponents()
        retirementDateComponents.year = birthDateComponents.year! + retirementAge // 根据出生年份和退休年龄计算
        retirementDateComponents.month = birthDateComponents.month
        retirementDateComponents.day = birthDateComponents.day
        let retirementDate = calendar.date(from: retirementDateComponents)!
        
        // 其他示例日期
        let futureDate2 = calendar.date(byAdding: .day, value: 100, to: today)!
        let pastDate1 = calendar.date(byAdding: .day, value: -365, to: today)!
        
        // 设置入职日为固定日期，而不是相对于当前日期
        var entryDateComponents = DateComponents()
        entryDateComponents.year = currentYear - 2  // 两年前入职
        entryDateComponents.month = 7  // 7月
        entryDateComponents.day = 15   // 15日
        let entryDate = calendar.date(from: entryDateComponents)!
        let pastDate2 = calendar.date(byAdding: .day, value: -30, to: today)!
        
        return [
            Event(name: "退休日", date: retirementDate, type: .retirement, notes: "期待已久的退休日", category: "个人", birthDate: birthDate, gender: .male),
            Event(name: "结婚纪念日", date: pastDate1, type: .countdown, notes: "美好的一天", category: "家庭"),
            Event(name: "生日", date: futureDate2, type: .countdown, notes: "又要长一岁了", category: "个人"),
            Event(name: "入职日", date: entryDate, type: .countdown, notes: "开始新工作的日子", category: "工作")
        ]
    }
}
