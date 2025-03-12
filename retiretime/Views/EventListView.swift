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
                                    // 从文档目录加载图片
                                    if let image = loadImageFromDocumentDirectory(named: imageName) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        // 如果无法加载图片，显示默认图标
                                        Image(systemName: currentEvent.displayIcon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(currentEvent.type.color)
                                            .padding(10)
                                            .background(currentEvent.type.color.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
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
                                Text("\(currentEvent.date, formatter: DateFormatter.customShortDate)")
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
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 按分类分组显示事件
                        ForEach(eventStore.categoriesWithEvents(filter: selectedCategory), id: \.self) { category in
                            // 事件网格
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(eventStore.eventsInCategory(category, filter: selectedCategory)) { event in
                                    NavigationLink(destination: EventDetailView(eventId: event.id, eventStore: eventStore)) {
                                        EventCard(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 16)
                }
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
    
    // 从文档目录加载图片
    private func loadImageFromDocumentDirectory(named: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(named)
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("加载图片失败: \(error)")
            return nil
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

// 事件卡片组件
struct EventCard: View {
    let event: Event
    
    var body: some View {
        HStack {
            // 左侧照片/图标
            ZStack {
                if let imageName = event.imageName, !imageName.isEmpty {
                    // 从文档目录加载图片
                    if let image = loadImageFromDocumentDirectory(named: imageName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // 如果无法加载图片，显示默认图标
                        Image(systemName: event.displayIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(event.type.color)
                            .padding(8)
                            .background(event.type.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    // 默认图标
                    Image(systemName: event.displayIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(event.type.color)
                        .padding(8)
                        .background(event.type.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(width: 50, height: 50)
            
            // 右侧事件信息
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(event.daysRemaining == 0 ? "今天" : 
                     (event.isCountdown ? "剩余 \(abs(event.daysRemaining)) 天" : "已过 \(abs(event.daysRemaining)) 天"))
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(event.isCountdown ? .green : .orange)
                
                Text("\(event.date, formatter: DateFormatter.customShortDate)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 4)
            
            Spacer()
        }
        .padding(10)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // 从文档目录加载图片
    private func loadImageFromDocumentDirectory(named: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(named)
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("加载图片失败: \(error)")
            return nil
        }
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
