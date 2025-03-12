//
//  EventListView.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI

struct EventListView: View {
    @ObservedObject var eventStore: EventStore
    @State private var selectedCategory = "全部"
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 添加事件详细信息视图
                if let currentEvent = eventStore.events.first {
                    VStack(alignment: .center) {
                        HStack {
                            // 左侧照片
                            ZStack {
                                if let imageName = currentEvent.imageName, !imageName.isEmpty {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    // 默认图标
                                    Image(systemName: currentEvent.displayIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(currentEvent.type.color)
                                        .padding(10)
                                        .background(currentEvent.type.color.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .frame(width: 60, height: 60)
                            .padding(.trailing, 10)
                            
                            // 中间事件信息
                            VStack(alignment: .leading) {
                                Text(currentEvent.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text(currentEvent.daysRemaining == 0 ? "今天" : 
                                     (currentEvent.isCountdown ? "剩余 \(abs(currentEvent.daysRemaining)) 天" : "已过 \(abs(currentEvent.daysRemaining)) 天"))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(currentEvent.isCountdown ? .green : .orange)
                                Text("目标日: \(currentEvent.date, formatter: DateFormatter.customShortDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                
                // 分类选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(eventStore.categories, id: \.self) { category in
                            CategoryButton(title: category, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // 事件列表
                List {
                    ForEach(eventStore.filteredEvents(by: selectedCategory)) { event in
                        NavigationLink(destination: EventDetailView(eventId: event.id, eventStore: eventStore)) {
                            EventRow(event: event)
                        }
                    }
                    .onDelete { indexSet in
                        let eventsToDelete = indexSet.map { eventStore.filteredEvents(by: selectedCategory)[$0] }
                        for event in eventsToDelete {
                            eventStore.deleteEvent(event)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("退休倒计时")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddEvent = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                }
            )
            .sheet(isPresented: $showingAddEvent) {
                EventFormView(eventStore: eventStore)
            }
        }
    }
}

// 分类按钮组件
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
        }
    }
}

// 事件行组件
struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: event.type.icon)
                .font(.system(size: 24))
                .foregroundColor(event.type.color)
                .frame(width: 40, height: 40)
                .background(event.type.color.opacity(0.1))
                .cornerRadius(8)
            
            // 事件信息
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(event.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 剩余/已过天数
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.daysRemaining == 0 ? "今天" : (event.isCountdown ? "剩余" : "已过"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text(event.daysRemaining == 0 ? "0天" : "\(abs(event.daysRemaining))天")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(event.isCountdown ? .green : .orange )
            }
        }
        .padding(.vertical, 8)
    }
}

// 添加自定义日期格式化器
extension DateFormatter {
    static var customShortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    EventListView(eventStore: EventStore())
}
