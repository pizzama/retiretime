//
//  EventFormView.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI

struct EventFormView: View {
    @ObservedObject var eventStore: EventStore
    @Environment(\.presentationMode) var presentationMode
    
    // 编辑模式时使用的事件
    var editingEvent: Event?
    
    // 表单状态
    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var type: EventType = .countdown
    @State private var calendarType: CalendarType = .gregorian // 添加日历类型状态
    @State private var notes: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var reminderOffset: ReminderOffset = .atTime
    @State private var notificationSound: NotificationSound = .default
    @State private var vibrationEnabled: Bool = true
    @State private var category: String = "未分类"
    @State private var repeatType: RepeatType = .none
    @State private var showingRepeatOptions: Bool = false
    
    // 退休日特有状态
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date() // 默认30岁
    @State private var gender: Gender = .male
    
    // 重复设置状态
    @State private var weekdaySelection: Int = Calendar.current.component(.weekday, from: Date())
    @State private var monthDaySelection: Int = Calendar.current.component(.day, from: Date())
    @State private var yearMonthSelection: Int = Calendar.current.component(.month, from: Date())
    @State private var yearDaySelection: Int = Calendar.current.component(.day, from: Date())
    @State private var repeatInterval: Int = 1
    @State private var showingIntervalPicker: Bool = false
    
    // 分类输入状态
    @State private var showingCategoryInput: Bool = false
    @State private var newCategory: String = ""
    
    // 自定义分类列表
    private var categories: [String] {
        var result = eventStore.categories
        if !result.contains("未分类") {
            result.append("未分类")
        }
        if !result.contains("新建分类") {
            result.append("新建分类")
        }
        return result
    }
    
    // 是否为编辑模式
    private var isEditMode: Bool {
        return editingEvent != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section(header: Text("基本信息")) {
                    TextField("事件名称", text: $name)
                    
                    Picker("类型", selection: $type) {
                        ForEach(EventType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    // 根据事件类型显示不同的日期选择器
                    if type == .retirement {
                        // 退休日特有的选项
                        Picker("性别", selection: $gender) {
                            ForEach(Gender.allCases) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        
                        DatePicker("出生日期", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(DefaultDatePickerStyle())
                            .onChange(of: birthDate) { _ in
                                // 当出生日期变化时，自动计算退休日期
                                calculateRetirementDate()
                            }
                            .onChange(of: gender) { _ in
                                // 当性别变化时，自动计算退休日期
                                calculateRetirementDate()
                            }
                        
                        // 显示计算出的退休日期（只读）
                        HStack {
                            Text("退休日期")
                            Spacer()
                            Text(date.formatted(.dateTime.year().month().day()))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // 普通事件的日期选择
                        DatePicker("日期", selection: $date, displayedComponents: .date)
                            .datePickerStyle(DefaultDatePickerStyle())
                    }
                    
                    Picker("日历类型", selection: $calendarType) {
                        ForEach(CalendarType.allCases) { calType in
                            HStack {
                                Image(systemName: calType.icon)
                                Text(calType.rawValue)
                            }
                            .tag(calType)
                        }
                    }
                }
                
                // 分类
                Section(header: Text("分类")) {
                    if showingCategoryInput {
                        HStack {
                            TextField("输入新分类名称", text: $newCategory)
                            
                            Button(action: {
                                if !newCategory.isEmpty {
                                    category = newCategory
                                    showingCategoryInput = false
                                    newCategory = ""
                                }
                            }) {
                                Text("确定")
                            }
                            
                            Button(action: {
                                showingCategoryInput = false
                                newCategory = ""
                            }) {
                                Text("取消")
                            }
                        }
                    } else {
                        Picker("选择分类", selection: $category) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .onChange(of: category) { newValue in
                            if newValue == "新建分类" {
                                category = "未分类" // 重置为默认值
                                showingCategoryInput = true
                            }
                        }
                    }
                }
                
                // 备注
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                // 重复设置
                Section(header: Text("重复")) {
                    Picker("重复类型", selection: $repeatType) {
                        ForEach(RepeatType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if repeatType != .none {
                        // 重复间隔选择
                        Picker("重复间隔", selection: $repeatInterval) {
                            ForEach(1...30, id: \.self) { interval in
                                Text("每\(interval)\(getIntervalUnit())").tag(interval)
                            }
                        }
                        
                        Button(action: {
                            showingRepeatOptions = true
                        }) {
                            // 移除了HStack部分
                        }
                        .actionSheet(isPresented: $showingRepeatOptions) {
                            getRepeatOptionsActionSheet()
                        }
                    }
                }
                
                // 提醒
                Section(header: Text("提醒")) {
                    Toggle("开启提醒", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        // 提醒时间偏移选择
                        Picker("提醒时间", selection: $reminderOffset) {
                            ForEach(ReminderOffset.allCases) { offset in
                                Text(offset.rawValue).tag(offset)
                            }
                        }
                        
                        // 自定义提醒时间
                        if reminderOffset == .atTime {
                            DatePicker("具体时间", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                        }
                        
                        // 通知声音选择
                        Picker("提醒声音", selection: $notificationSound) {
                            ForEach(NotificationSound.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        
                        // 震动开关
                        Toggle("震动提醒", isOn: $vibrationEnabled)
                    }
                }
            }
            .navigationBarTitle(isEditMode ? "编辑事件" : "创建事件", displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveEvent()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                // 如果是编辑模式，加载现有事件数据
                if let event = editingEvent {
                    name = event.name
                    date = event.date
                    type = event.type
                    calendarType = event.calendarType // 加载日历类型
                    notes = event.notes
                    reminderEnabled = event.reminderEnabled
                    reminderOffset = event.reminderOffset
                    notificationSound = event.notificationSound ?? .default
                    vibrationEnabled = event.vibrationEnabled
                    if let reminderDate = event.reminderDate {
                        self.reminderDate = reminderDate
                    }
                    category = event.category
                    repeatType = event.repeatType
                    
                    // 加载退休日特有属性
                    if let birthDate = event.birthDate {
                        self.birthDate = birthDate
                    }
                    if let gender = event.gender {
                        self.gender = gender
                    }
                    
//                    // 加载重复设置
//                    if let settings = event.repeatSettings {
//                        if let weekday = settings.weekday {
//                            weekdaySelection = weekday
//                        }
//                        if let monthDay = settings.monthDay {
//                            monthDaySelection = monthDay
//                        }
//                        if let month = settings.month {
//                            yearMonthSelection = month
//                        }
//                        if let yearDay = settings.yearDay {
//                            yearDaySelection = yearDay
//                        }
//                        repeatInterval = settings.interval
//                    }
                }
            }
        }
    }
    
    // 获取重复间隔单位
    private func getIntervalUnit() -> String {
        switch repeatType {
        case .daily:
            return "天"
        case .weekly:
            return "周"
        case .monthly:
            return "月"
        case .yearly:
            return "年"
        default:
            return ""
        }
    }
    
    // 获取重复设置描述
    private func getRepeatSettingDescription() -> String {
        let intervalStr = repeatInterval > 1 ? "每\(repeatInterval)" : "每"
        
        switch repeatType {
        case .daily:
            return "\(intervalStr)天"
        case .weekly:
            let weekdayNames = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            let index = (weekdaySelection - 1) % 7
            return "\(intervalStr)\(weekdayNames[index])"
        case .monthly:
            return "\(intervalStr)月\(monthDaySelection)日"
        case .yearly:
            let monthNames = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
            let monthIndex = (yearMonthSelection - 1) % 12
            return "\(intervalStr)年\(monthNames[monthIndex])\(yearDaySelection)日"
        default:
            return ""
        }
    }
    
    // 获取重复选项的ActionSheet
    private func getRepeatOptionsActionSheet() -> ActionSheet {
        switch repeatType {
        case .weekly:
            return ActionSheet(
                title: Text("选择重复的星期"),
                buttons: [
                    .default(Text("周日")) { weekdaySelection = 1 },
                    .default(Text("周一")) { weekdaySelection = 2 },
                    .default(Text("周二")) { weekdaySelection = 3 },
                    .default(Text("周三")) { weekdaySelection = 4 },
                    .default(Text("周四")) { weekdaySelection = 5 },
                    .default(Text("周五")) { weekdaySelection = 6 },
                    .default(Text("周六")) { weekdaySelection = 7 },
                    .cancel(Text("取消"))
                ]
            )
        case .monthly:
            // 简化版本，实际应用中可能需要更复杂的选择器
            let buttons: [ActionSheet.Button] = (1...31).map { day in
                .default(Text("\(day)日")) { monthDaySelection = day }
            } + [.cancel(Text("取消"))]
            
            return ActionSheet(
                title: Text("选择每月重复的日期"),
                buttons: buttons
            )
        case .yearly:
            // 简化版本，实际应用中可能需要更复杂的选择器
            let monthButtons: [ActionSheet.Button] = (1...12).map { month in
                let monthNames = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
                return .default(Text(monthNames[month-1])) { 
                    yearMonthSelection = month 
                    // 显示日期选择
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingRepeatOptions = true
                    }
                }
            } + [.cancel(Text("取消"))]
            
            return ActionSheet(
                title: Text("选择每年重复的月份和日期"),
                buttons: monthButtons
            )
        default:
            return ActionSheet(title: Text(""), buttons: [.cancel()])
        }
    }
    
    // 重复设置已移除
    
    // 计算退休日期
    private func calculateRetirementDate() {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let birthMonth = calendar.component(.month, from: birthDate)
        let birthDay = calendar.component(.day, from: birthDate)
        
        // 根据性别获取退休年龄
        let retirementAge = gender.retirementAge
        
        // 计算退休年份
        let retirementYear = birthYear + retirementAge
        
        // 创建退休日期
        var components = DateComponents()
        components.year = retirementYear
        components.month = birthMonth
        components.day = birthDay
        
        // 设置退休日期
        if let retirementDate = calendar.date(from: components) {
            date = retirementDate
        }
    }
    
    // 保存事件
    private func saveEvent() {
        // 创建新事件或更新现有事件
        let event: Event
        
        // 计算实际的提醒日期
        var finalReminderDate: Date? = nil
        if reminderEnabled {
            if reminderOffset == .atTime {
                finalReminderDate = reminderDate
            } else {
                finalReminderDate = NotificationManager.shared.calculateReminderDate(eventDate: date, offset: reminderOffset)
            }
        }
        
        if let editingEvent = editingEvent {
            // 更新现有事件
            event = Event(
                id: editingEvent.id,
                name: name,
                date: date,
                type: type,
                calendarType: calendarType,
                notes: notes,
                reminderEnabled: reminderEnabled,
                reminderDate: finalReminderDate,
                reminderOffset: reminderOffset,
                notificationSound: reminderEnabled ? notificationSound : nil,
                vibrationEnabled: vibrationEnabled,
                category: category,
                repeatType: repeatType,
                lastOccurrence: editingEvent.lastOccurrence,
                birthDate: type == .retirement ? birthDate : nil,
                gender: type == .retirement ? gender : nil
            )
            eventStore.updateEvent(event)
        } else {
            // 创建新事件
            event = Event(
                name: name,
                date: date,
                type: type,
                calendarType: calendarType,
                notes: notes,
                reminderEnabled: reminderEnabled,
                reminderDate: finalReminderDate,
                reminderOffset: reminderOffset,
                notificationSound: reminderEnabled ? notificationSound : nil,
                vibrationEnabled: vibrationEnabled,
                category: category,
                repeatType: repeatType,
                birthDate: type == .retirement ? birthDate : nil,
                gender: type == .retirement ? gender : nil
            )
            eventStore.addEvent(event)
        }
    }
}

#Preview {
    EventFormView(eventStore: EventStore())
}
