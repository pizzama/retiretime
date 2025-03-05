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
    @State private var notes: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var category: String = "未分类"
    
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
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                        .datePickerStyle(DefaultDatePickerStyle())
                    
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
                
                // 提醒
                Section(header: Text("提醒")) {
                    Toggle("开启提醒", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker("提醒时间", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
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
                    notes = event.notes
                    reminderEnabled = event.reminderEnabled
                    if let reminderDate = event.reminderDate {
                        self.reminderDate = reminderDate
                    }
                    category = event.category
                }
            }
        }
    }
    
    // 保存事件
    private func saveEvent() {
        // 创建新事件或更新现有事件
        let event: Event
        
        if let editingEvent = editingEvent {
            // 更新现有事件
            event = Event(
                id: editingEvent.id,
                name: name,
                date: date,
                type: type,
                notes: notes,
                reminderEnabled: reminderEnabled,
                reminderDate: reminderEnabled ? reminderDate : nil,
                category: category
            )
            eventStore.updateEvent(event)
        } else {
            // 创建新事件
            event = Event(
                name: name,
                date: date,
                type: type,
                notes: notes,
                reminderEnabled: reminderEnabled,
                reminderDate: reminderEnabled ? reminderDate : nil,
                category: category
            )
            eventStore.addEvent(event)
        }
    }
}

#Preview {
    EventFormView(eventStore: EventStore())
}