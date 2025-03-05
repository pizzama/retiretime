//
//  EventDetailView.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    let eventStore: EventStore
    @State private var showingEditSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                // 顶部图标
                Image(systemName: event.type.icon)
                    .font(.system(size: 60))
                    .foregroundColor(event.type.color)
                    .frame(width: 100, height: 100)
                    .background(event.type.color.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.top, 20)
                
                // 事件名称
                Text(event.name)
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                
                // 日期信息
                Text(event.formattedDate)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                
                // 剩余/已过天数
                VStack(spacing: 8) {
                    Text(event.daysRemaining == 0 ? "今天" : (event.isCountdown ? "倒计时" : "已过"))
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text(event.daysRemaining == 0 ? "今天" : "\(abs(event.daysRemaining))天")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(event.isCountdown ? .orange : .green)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 详细信息区域
                VStack(alignment: .leading, spacing: 16) {
                    // 类型
                    DetailRow(title: "类型", value: event.type.rawValue, icon: "tag")
                    
                    // 分类
                    DetailRow(title: "分类", value: event.category, icon: "folder")
                    
                    // 备注
                    if !event.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.secondary)
                                Text("备注")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(event.notes)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(.leading, 26)
                        }
                    }
                    
                    // 提醒
                    if event.reminderEnabled {
                        DetailRow(
                            title: "提醒",
                            value: event.reminderDate != nil ? formatReminderDate(event.reminderDate!) : "已开启",
                            icon: "bell"
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                showingEditSheet = true
            }) {
                Text("编辑")
            }
        )
        .sheet(isPresented: $showingEditSheet) {
            EventFormView(eventStore: eventStore, editingEvent: event)
        }
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// 详情行组件
struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationView {
        EventDetailView(event: Event.samples[0], eventStore: EventStore())
    }
}