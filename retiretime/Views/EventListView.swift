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
    
    // 缓存变量
    @State private var filteredEventsCache: [String: [Event]] = [:]
    @State private var categoriesWithEventsCache: [String: [String]] = [:]
    @State private var imageCache: [String: UIImage] = [:]
    @State private var processedImageCache: [String: UIImage] = [:]
    
    // 清除所有缓存
    private func clearCaches() {
        // 清除事件数据缓存
        filteredEventsCache = [:]
        categoriesWithEventsCache = [:]
        
        // 保留图片缓存，因为图片不会频繁变化
        // 如果内存压力大，可以考虑也清除图片缓存
        // imageCache = [:]
        // processedImageCache = [:]
    }
    
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
            .navigationTitle("退休倒计时 v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
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
            .onAppear {
                // 当视图出现时预加载数据
                preloadData()
            }
            .onChange(of: eventStore.events) { _ in
                // 当事件数据变化时清除缓存
                clearCaches()
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
                                        .fill(Color.clear)
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
                if selectedCategory == "全部" {
                    // 当选择"全部"时，显示所有事件在一个网格中
                    allEventsGrid
                } else {
                    // 获取分类（使用缓存）
                    let categories = getCategoriesWithEvents(filter: selectedCategory)
                    
                    // 遍历分类
                    ForEach(categories, id: \.self) { category in
                        // 事件网格
                        eventGrid(for: category)
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // 获取包含事件的分类（带缓存）
    private func getCategoriesWithEvents(filter category: String) -> [String] {
        // 检查缓存
        if let cachedCategories = categoriesWithEventsCache[category] {
            return cachedCategories
        }
        
        // 如果缓存中没有，则从eventStore获取
        let categories = eventStore.categoriesWithEvents(filter: category)
        
        // 更新缓存
        var updatedCache = categoriesWithEventsCache
        updatedCache[category] = categories
        categoriesWithEventsCache = updatedCache
        
        return categories
    }

// 获取过滤后的事件（带缓存）
private func getFilteredEvents(by category: String) -> [Event] {
    // 检查缓存
    if let cachedEvents = filteredEventsCache[category] {
        return cachedEvents
    }
    
    // 如果缓存中没有，则从eventStore获取
    let events = eventStore.filteredEvents(by: category)
    
    // 更新缓存
    var updatedCache = filteredEventsCache
    updatedCache[category] = events
    filteredEventsCache = updatedCache
    
    return events
}

// 获取分类中的事件（带缓存）
private func getEventsInCategory(_ category: String, filter filterCategory: String) -> [Event] {
    // 创建缓存键
    let cacheKey = "\(category)_\(filterCategory)"
    
    // 检查缓存
    if let cachedEvents = filteredEventsCache[cacheKey] {
        return cachedEvents
    }
    
    // 如果缓存中没有，则从eventStore获取
    let events = eventStore.eventsInCategory(category, filter: filterCategory)
    
    // 更新缓存
    var updatedCache = filteredEventsCache
    updatedCache[cacheKey] = events
    filteredEventsCache = updatedCache
    
    return events
}
    
    // 所有事件的网格视图
    private var allEventsGrid: some View {
        // 获取所有事件（当选择"全部"分类时，使用缓存）
        let allEvents = getFilteredEvents(by: selectedCategory)
        
        return VStack(alignment: .leading) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(allEvents) { event in
                    NavigationLink(destination: EventDetailView(event: event, eventStore: eventStore)) {
                        eventCard(for: event)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 事件网格视图
    private func eventGrid(for category: String) -> some View {
        // 获取该分类下的事件（使用缓存）
        let events = getEventsInCategory(category, filter: selectedCategory)
        
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
                if let imageName = event.imageName, !imageName.isEmpty {
                    // 尝试从缓存加载图片
                    if let processedImage = getProcessedImage(for: event) {
                        Image(uiImage: processedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    } else {
                        // 显示默认图标背景（加载中）
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 100, height: 100)
                        .onAppear {
                            // 异步加载图片
                            loadAndCacheImage(named: imageName, for: event)
                        }
                    }
                } else {
                    // 显示默认图标背景
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: event.type.icon)
                            .font(.system(size: 40))
                            .foregroundColor(event.type.color)
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .frame(width: 100, height: 100)
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
        .frame(width: 100, height: 200)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // 获取处理后的图片（从缓存或生成）
    private func getProcessedImage(for event: Event) -> UIImage? {
        guard let imageName = event.imageName else { return nil }
        
        // 创建缓存键，包含所有可能影响图片处理的参数
        let cacheKey = "\(imageName)_\(event.frameStyleName ?? "")_\(event.imageScale)_\(event.imageOffsetX)_\(event.imageOffsetY)"
        
        // 检查处理后的图片缓存
        if let cachedImage = processedImageCache[cacheKey] {
            return cachedImage
        }
        
        // 检查原始图片缓存
        guard let originalImage = imageCache[imageName] ?? loadImageFromDocumentDirectory(named: imageName) else {
            return nil
        }
        
        // 如果找到原始图片，缓存它
        if imageCache[imageName] == nil {
            var updatedImageCache = imageCache
            updatedImageCache[imageName] = originalImage
            imageCache = updatedImageCache
        }
        
        // 处理图片
        var processedImage: UIImage? = nil
        
        if let frameStyleName = event.frameStyleName,
           let frameStyle = FrameStyle(rawValue: frameStyleName),
           frameStyle.usesMaskOrFrame {
            // 使用模板生成器处理图片
            processedImage = TemplateImageGenerator.shared.generateTemplateImage(
                originalImage: originalImage,
                frameStyle: frameStyle,
                scale: event.imageScale,
                offset: CGSize(width: event.imageOffsetX, height: event.imageOffsetY)
            )
        } else {
            // 简单缩放和偏移处理
            processedImage = originalImage
        }
        
        // 缓存处理后的图片
        if let processedImage = processedImage {
            var updatedProcessedImageCache = processedImageCache
            updatedProcessedImageCache[cacheKey] = processedImage
            processedImageCache = updatedProcessedImageCache
        }
        
        return processedImage
    }
    
    // 异步加载并缓存图片
    private func loadAndCacheImage(named imageName: String, for event: Event) {
        // 检查是否已经在缓存中
        if imageCache[imageName] != nil {
            // 如果原始图片已缓存，尝试生成处理后的图片
            _ = getProcessedImage(for: event)
            return
        }
        
        // 在后台线程加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = loadImageFromDocumentDirectory(named: imageName) {
                // 在主线程更新缓存
                DispatchQueue.main.async {
                    // 缓存原始图片
                    var updatedImageCache = self.imageCache
                    updatedImageCache[imageName] = image
                    self.imageCache = updatedImageCache
                    
                    // 生成并缓存处理后的图片
                    _ = self.getProcessedImage(for: event)
                }
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
    
    // 预加载数据
    private func preloadData() {
        // 预加载所有分类的事件数据
        _ = getFilteredEvents(by: "全部")
        
        // 预加载所有分类
        let allCategories = eventStore.categories
        for category in allCategories {
            _ = getCategoriesWithEvents(filter: category)
            _ = getFilteredEvents(by: category)
        }
    }
}

#Preview {
    EventListView(eventStore: EventStore())
}
