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
                    ZStack {
                        // 背景
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.gray.opacity(0.05))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        HStack(spacing: 15) {
                            // 左侧照片
                            ZStack {
                                if let imageName = currentEvent.imageName, !imageName.isEmpty,
                                   let image = loadImageFromDocumentDirectory(named: imageName) {
                                    
                                    // 如果有相框样式
                                    if let frameStyleName = currentEvent.frameStyleName,
                                       let frameStyle = FrameStyle(rawValue: frameStyleName),
                                       frameStyle.usesMaskOrFrame,
                                       let processedImage = TemplateImageGenerator.shared.generateTemplateImage(
                                           originalImage: image,
                                           frameStyle: frameStyle,
                                           scale: currentEvent.imageScale,
                                           offset: CGSize(width: currentEvent.imageOffsetX, height: currentEvent.imageOffsetY)
                                       ) {
                                        Image(uiImage: processedImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 80)
                                    } else {
                                        // 使用普通样式
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .scaleEffect(currentEvent.imageScale)
                                            .offset(CGSize(width: currentEvent.imageOffsetX, height: currentEvent.imageOffsetY))
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                } else {
                                    // 显示默认图标背景
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(currentEvent.type.color.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: currentEvent.type.icon)
                                        .font(.system(size: 30))
                                        .foregroundColor(currentEvent.type.color)
                                }
                            }
                            .frame(width: 80, height: 80)
                            
                            // 中间事件信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentEvent.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                
                                Text(currentEvent.daysRemaining == 0 ? "今天" : 
                                     (currentEvent.isCountdown ? "还有\(abs(currentEvent.daysRemaining))天" : "已过\(abs(currentEvent.daysRemaining))天"))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(currentEvent.isCountdown ? .green : .orange)
                                
                                Text(currentEvent.formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                    .frame(height: 110)
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
        
        return VStack(alignment: .leading) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
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
        }
        .padding(.horizontal)
    }
    
    // 事件卡片视图
    private func eventCard(for event: Event) -> some View {
        VStack(alignment: .leading) {
            // 图片部分
            ZStack {
                if let imageName = event.imageName, !imageName.isEmpty,
                   let image = loadImageFromDocumentDirectory(named: imageName) {
                    
                    // 如果有相框样式
                    if let frameStyleName = event.frameStyleName,
                       let frameStyle = FrameStyle(rawValue: frameStyleName),
                       frameStyle.usesMaskOrFrame,
                       let processedImage = TemplateImageGenerator.shared.generateTemplateImage(
                           originalImage: image,
                           frameStyle: frameStyle,
                           scale: event.imageScale,
                           offset: CGSize(width: event.imageOffsetX, height: event.imageOffsetY)
                       ) {
                        Image(uiImage: processedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                    } else {
                        // 使用普通样式
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(event.imageScale)
                            .offset(CGSize(width: event.imageOffsetX, height: event.imageOffsetY))
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    // 显示默认图标背景
                    RoundedRectangle(cornerRadius: 8)
                        .fill(event.type.color.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: event.type.icon)
                        .font(.system(size: 40))
                        .foregroundColor(event.type.color)
                }
            }
            .frame(width: 120, height: 120)
            .padding(.bottom, 8)
            
            // 事件信息
            Text(event.name)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(1)
                .padding(.horizontal, 4)
            
            Text(event.daysRemaining == 0 ? "今天" : 
                 (event.isCountdown ? "还有\(abs(event.daysRemaining))天" : "已过\(abs(event.daysRemaining))天"))
                .font(.system(size: 13))
                .foregroundColor(event.isCountdown ? .green : .orange)
                .padding(.horizontal, 4)
            
            Text(event.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
        }
        .frame(width: 120, height: 200)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

#Preview {
    EventListView(eventStore: EventStore())
}
