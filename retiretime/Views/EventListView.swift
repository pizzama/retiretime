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
                // 当前事件头部
                currentEventHeader
                
                // 分类选择器
                categorySelector
                
                // 事件列表
                eventList
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
    
    // 当前事件头部视图
    private var currentEventHeader: some View {
        Group {
            if let currentEvent = eventStore.events.first {
                VStack(alignment: .center) {
                    HStack {
                        // 左侧照片
                        eventImage(for: currentEvent, size: 60)
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
                            Text("\(currentEvent.date, formatter: dateFormatter)")
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
        }
    }
    
    // 分类选择器视图
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(eventStore.categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .font(.system(size: 14, weight: selectedCategory == category ? .bold : .regular))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(selectedCategory == category ? .blue : .primary)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // 事件列表视图
    private var eventList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 获取分类
                let categories = eventStore.categoriesWithEvents(filter: selectedCategory)
                
                // 遍历分类
                ForEach(categories, id: \.self) { category in
                    // 事件网格
                    eventGrid(for: category)
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // 事件网格视图
    private func eventGrid(for category: String) -> some View {
        // 获取该分类下的事件
        let events = eventStore.eventsInCategory(category, filter: selectedCategory)
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(events) { event in
                NavigationLink(destination: EventDetailView(event: event, eventStore: eventStore)) {
                    eventCard(for: event)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
    
    // 事件卡片视图
    private func eventCard(for event: Event) -> some View {
        HStack {
            // 左侧照片/图标
            eventImage(for: event, size: 50)
            
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
                
                Text("\(event.date, formatter: dateFormatter)")
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
    
    // 事件图片视图
    private func eventImage(for event: Event, size: CGFloat) -> some View {
        ZStack {
            if let imageName = event.imageName, !imageName.isEmpty {
                // 从文档目录加载图片
                if let image = loadImageFromDocumentDirectory(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
                } else {
                    // 如果无法加载图片，显示默认图标
                    defaultEventIcon(for: event, size: size * 0.66)
                }
            } else {
                // 默认图标
                defaultEventIcon(for: event, size: size * 0.66)
            }
        }
        .frame(width: size, height: size)
    }
    
    // 默认事件图标视图
    private func defaultEventIcon(for event: Event, size: CGFloat) -> some View {
        Image(systemName: event.displayIcon)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(event.type.color)
            .padding(size * 0.25)
            .background(event.type.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
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
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    EventListView(eventStore: EventStore())
}
