//
//  Event.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import Foundation
import SwiftUI

enum EventType: String, CaseIterable, Identifiable, Codable {
    case anniversary = "纪念日"
    case countdown = "倒计时"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .anniversary: return "calendar"
        case .countdown: return "timer"
        }
    }
    
    var color: Color {
        switch self {
        case .anniversary: return .green
        case .countdown: return .orange
        }
    }
}

struct Event: Identifiable, Codable {
    var id = UUID()
    var name: String
    var date: Date
    var type: EventType
    var notes: String = ""
    var reminderEnabled: Bool = false
    var reminderDate: Date?
    var category: String = "未分类"
    
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
}

// 示例数据
extension Event {
    static var samples: [Event] {
        let calendar = Calendar.current
        let today = Date()
        
        // 未来日期 - 倒计时
        let futureDate1 = calendar.date(byAdding: .day, value: 30, to: today)!
        let futureDate2 = calendar.date(byAdding: .day, value: 100, to: today)!
        
        // 过去日期 - 正计时
        let pastDate1 = calendar.date(byAdding: .day, value: -365, to: today)!
        let pastDate2 = calendar.date(byAdding: .day, value: -30, to: today)!
        
        return [
            Event(name: "退休日", date: futureDate1, type: .countdown, notes: "期待已久的退休日", category: "工作"),
            Event(name: "结婚纪念日", date: pastDate1, type: .anniversary, notes: "美好的一天", category: "家庭"),
            Event(name: "生日", date: futureDate2, type: .countdown, notes: "又要长一岁了", category: "个人"),
            Event(name: "入职日", date: pastDate2, type: .countdown, notes: "开始新工作的日子", category: "工作")
        ]
    }
}
