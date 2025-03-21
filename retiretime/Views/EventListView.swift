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
    
    // 保留图片缓存
    @State private var imageCache: [String: UIImage] = [:]
    @State private var processedImageCache: [String: UIImage] = [:]
    
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
                // 刷新事件列表
                refreshEvents()
                
                // 添加通知观察者
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("EventUpdated"),
                    object: nil,
                    queue: .main
                ) { _ in
                    refreshEvents()
                }
                
                // 添加缓存清除通知观察者
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("ClearEventCache"),
                    object: nil,
                    queue: .main
                ) { _ in
                    // 刷新事件列表
                    print("收到缓存清除通知，刷新事件列表")
                    self.refreshEvents()
                }
                
                // 添加图片缓存刷新通知观察者
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("RefreshImageCache"),
                    object: nil,
                    queue: .main
                ) { _ in
                    // 刷新事件列表
                    print("收到图片缓存刷新通知，刷新事件列表")
                    self.refreshEvents()
                }
            }
            .onDisappear {
                // 移除通知观察者
                NotificationCenter.default.removeObserver(self, name: Notification.Name("EventUpdated"), object: nil)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("ClearEventCache"), object: nil)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("RefreshImageCache"), object: nil)
            }
        }
    }
    
    // 刷新事件列表
    private func refreshEvents() {
        // 强制刷新UI
        eventStore.objectWillChange.send()
        
        // 强制清除图片缓存
        eventStore.imageCache.clearCache()
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
                                if let imageName = currentEvent.imageName, !imageName.isEmpty {
                                    // 使用LazyImage组件
                                    LazyImage(event: currentEvent, eventStore: eventStore)
                                        .frame(width: 80, height: 80)
                                        // 添加id标识符，确保在imageName或frameStyleName更改时重新创建视图
                                        .id("\(currentEvent.id)-\(imageName)-\(currentEvent.frameStyleName ?? "none")-\(currentEvent.imageScale)-\(currentEvent.imageOffsetX)-\(currentEvent.imageOffsetY)")
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
    
    // 获取包含事件的分类
    private func getCategoriesWithEvents(filter category: String) -> [String] {
        return eventStore.categoriesWithEvents(filter: category)
    }
    
    // 所有事件的网格视图
    private var allEventsGrid: some View {
        // 获取所有事件（当选择"全部"分类时，直接从eventStore获取）
        let allEvents = eventStore.filteredEvents(by: selectedCategory)
        
        return VStack(alignment: .leading) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(allEvents) { event in
                    NavigationLink(destination: EventDetailView(eventStore: eventStore, event: event)) {
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
        // 获取该分类下的事件（直接从eventStore获取）
        let events = eventStore.eventsInCategory(category, filter: selectedCategory)
        
        return VStack(alignment: .leading) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(events) { event in
                    NavigationLink(destination: EventDetailView(eventStore: eventStore, event: event)) {
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
                    // 使用LazyImage组件延迟加载图片
                    LazyImage(event: event, eventStore: eventStore)
                        .frame(width: 100, height: 100)
                        // 添加id标识符，确保在imageName或frameStyleName更改时重新创建视图
                        .id("\(event.id)-\(imageName)-\(event.frameStyleName ?? "none")-\(event.imageScale)-\(event.imageOffsetX)-\(event.imageOffsetY)")
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
    
    // 懒加载图片组件
    struct LazyImage: View {
        let event: Event
        @ObservedObject var eventStore: EventStore
        
        @State private var image: UIImage?
        @State private var isLoading = false
        @State private var loadedImageID = "" // 存储已加载图片的ID，用于判断是否需要重新加载
        
        // 创建当前图片的唯一ID
        private var currentImageID: String {
            "\(event.id)-\(event.imageName ?? "")-\(event.frameStyleName ?? "")-\(event.imageScale)-\(event.imageOffsetX)-\(event.imageOffsetY)"
        }
        
        var body: some View {
            GeometryReader { geometry in
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // 加载中占位符
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: geometry.size.width, height: geometry.size.height)
                            
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: min(geometry.size.width, geometry.size.height) * 0.3))
                                    .foregroundColor(.gray)
                            }
                        }
                        .onAppear {
                            loadImage()
                        }
                    }
                }
                .onChange(of: currentImageID) { _ in
                    // 当图片标识符变化时，重新加载图片
                    if loadedImageID != currentImageID {
                        image = nil
                        loadImage()
                    }
                }
            }
        }
        
        private func loadImage() {
            guard let imageName = event.imageName, !isLoading else { return }
            
            // 如果已经加载过相同的图片，则不重复加载
            if loadedImageID == currentImageID {
                return
            }
            
            isLoading = true
            
            // 检查全局图片缓存
            if let cachedImage = eventStore.imageCache.getImage(for: imageName, with: event) {
                self.image = cachedImage
                self.isLoading = false
                self.loadedImageID = currentImageID
                return
            }
            
            // 在后台线程加载图片
            DispatchQueue.global(qos: .userInitiated).async {
                if let originalImage = loadImageFromDocumentDirectory(named: imageName) {
                    var processedImage: UIImage?
                    
                    // 处理图片
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
                        eventStore.imageCache.setImage(processedImage, for: imageName, with: event)
                        
                        // 在主线程更新UI
                        DispatchQueue.main.async {
                            self.image = processedImage
                            self.isLoading = false
                            self.loadedImageID = currentImageID
                            print("LazyImage: 加载完成 - \(imageName)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        print("LazyImage: 加载失败 - \(imageName)")
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
    }
}

#Preview {
    EventListView(eventStore: EventStore())
}
