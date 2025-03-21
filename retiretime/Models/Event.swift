//
//  Event.swift
//  retiretime
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

// 重复设置结构体已移除

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
    public var calendarType: CalendarType = .gregorian
    public var repeatType: RepeatType = .none
    public var notes: String = ""
    public var createdAt: Date = Date()
    public var type: EventType
    public var category: String = "未分类"
    public var colorData: CodableColor? = nil // 编码后的颜色数据
    public var icon: String? = nil // 自定义图标
    public var imageName: String?
    public var imageData: Data?
    public var reminderEnabled: Bool = false
    public var reminderDate: Date?
    public var reminderOffset: ReminderOffset = .atTime // 提醒时间偏移
    public var notificationSound: NotificationSound? = .default // 通知声音
    public var vibrationEnabled: Bool = true // 是否启用震动
    public var parentId: UUID? = nil // 父事件ID，如果有的话
    
    // 添加相框相关属性
    public var frameStyleName: String?
    public var frameBackgroundName: String? // 添加背景板名称属性
    
    // 照片调整相关属性
    public var imageScale: CGFloat = 1.0
    public var imageOffsetX: CGFloat = 0.0
    public var imageOffsetY: CGFloat = 0.0
    
    // 退休日特有属性
    public var birthDate: Date? = nil // 出生日期
    public var gender: Gender? = nil // 性别
    public var lastOccurrence: Date? = nil // 上次发生日期，用于计算下次重复日期
    
    // 初始化方法
    public init(name: String, date: Date, notes: String = "", type: EventType, category: String = "未分类") {
        self.id = UUID()
        self.name = name
        self.date = date
        self.notes = notes
        self.type = type
        self.category = category
        self.createdAt = Date()
    }
    
    // 判断是否为子事件
    public var isChildEvent: Bool {
        return parentId != nil
    }
    
    // 计算剩余天数或已过天数
    public var daysRemaining: Int {
        let calendar = Calendar.current
        // 获取当前日期的零点时间，确保无论何时计算都基于当天的开始时间
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTargetDate = calendar.startOfDay(for: date)
        
        // 使用dateComponents计算天数差异，这比timeInterval更准确
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTargetDate)
        return components.day ?? 0
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
            return "还剩\(days)天"
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
    
    // 显示图标
    public var displayIcon: String {
        // 如果有自定义图标，则使用自定义图标
        if let customIcon = icon, !customIcon.isEmpty {
            return customIcon
        }
        // 否则使用事件类型的默认图标
        return type.icon
    }
    
    // 获取显示的颜色
    public var displayColor: Color {
        if let colorData = colorData {
            return colorData.color
        }
        return type.color
    }
    
    public var remainingDays: Int {
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents([.day], from: currentDate, to: date)
        return components.day ?? 0
    }
}

// 实现Equatable协议
extension Event: Equatable {
    public static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
}

// 实现Hashable协议
extension Event: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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

// 示例数据
public extension Event {
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
        let retirementAge = Gender.male.retirementAge(birthYear: currentYear - 30)
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
        
        var event1 = Event(name: "退休日", date: retirementDate, notes: "期待已久的退休日", type: .retirement, category: "个人")
        event1.birthDate = birthDate
        event1.gender = .male
        event1.frameStyleName = "花朵"
        
        var event2 = Event(name: "结婚纪念日", date: pastDate1, notes: "美好的一天", type: .countdown, category: "家庭")
        event2.frameStyleName = "心形"
        
        var event3 = Event(name: "生日", date: futureDate2, notes: "又要长一岁了", type: .countdown, category: "个人")
        event3.frameStyleName = "星形"
        
        var event4 = Event(name: "入职日", date: entryDate, notes: "开始新工作的日子", type: .countdown, category: "工作")
        event4.frameStyleName = "经典"
        
        return [event1, event2, event3, event4]
    }
}
