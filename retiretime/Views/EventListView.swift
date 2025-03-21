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
                
                // 强制清除图片缓存，确保显示最新的相框效果
                eventStore.imageCache.clearCache()
                
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
                                // 背景色
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(currentEvent.type.color.opacity(0.1))
                                
                                if let imageName = currentEvent.imageName, !imageName.isEmpty {
                                    if let image = eventStore.imageCache.getImage(for: imageName, with: currentEvent) {
                                        // 相框效果
                                        if let frameStyleName = currentEvent.frameStyleName, 
                                           let frameStyle = FrameStyle(rawValue: frameStyleName),
                                           frameStyle.usesMaskOrFrame {
                                            // 使用相框遮罩
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Group {
                                                        if let maskName = frameStyle.maskImageName {
                                                            Image(maskName)
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fit)
                                                                .opacity(0.85)
                                                        }
                                                    }
                                                )
                                                .cornerRadius(8)
                                        } else {
                                            // 普通显示
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                        }
                                    } else {
                                        Image(systemName: "photo")
                                            .font(.system(size: 30))
                                            .foregroundColor(currentEvent.type.color)
                                    }
                                    
                                    // 添加相框装饰元素
                                    if let frameStyleName = currentEvent.frameStyleName, 
                                       let frameStyle = FrameStyle(rawValue: frameStyleName),
                                       !frameStyle.usesMaskOrFrame && !frameStyle.decorationSymbols.isEmpty {
                                        
                                        // 左上角装饰
                                        if frameStyle.decorationSymbols.count > 0 {
                                            Image(systemName: frameStyle.decorationSymbols[0])
                                                .font(.system(size: 12))
                                                .foregroundColor(frameStyle.borderColor)
                                                .position(x: 16, y: 16)
                                        }
                                        
                                        // 右上角装饰
                                        if frameStyle.decorationSymbols.count > 1 {
                                            Image(systemName: frameStyle.decorationSymbols[1])
                                                .font(.system(size: 12))
                                                .foregroundColor(frameStyle.borderColor.opacity(0.7))
                                                .position(x: 64, y: 16)
                                        }
                                    }
                                } else {
                                    // 显示默认图标
                                    Image(systemName: currentEvent.type.icon)
                                        .font(.system(size: 30))
                                        .foregroundColor(currentEvent.type.color)
                                }
                            }
                            .frame(width: 80, height: 80)
                            
                            // 中间事件信息
                            VStack(alignment: .leading, spacing: 4) {
                                // 事件名称带背景板
                                ZStack(alignment: .center) {
                                    // 背景板
                                    if let backgroundName = currentEvent.frameBackgroundName, backgroundName != "无背景", 
                                       let frameBackground = FrameBackground(rawValue: backgroundName) {
                                        // 使用与详情页相同的背景图片
                                        Image(frameBackground.backgroundImageName ?? "")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 30)
                                            .overlay(
                                                // 装饰符号（如果有）
                                                Image(systemName: frameBackground.decorationSymbol)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                    .opacity(0.8)
                                                    .padding(.leading, -60),
                                                alignment: .center
                                            )
                                    } else {
                                        // 如果没有设置背景或设为"无背景"，则使用事件类型颜色
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(currentEvent.type.color.opacity(0.15))
                                            .frame(height: 30)
                                    }
                                    
                                    // 事件名称
                                    Text(currentEvent.name)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .foregroundColor(currentEvent.frameBackgroundName != nil && currentEvent.frameBackgroundName != "无背景" ? .white : currentEvent.type.color.opacity(0.8))
                                        .shadow(color: currentEvent.frameBackgroundName != nil && currentEvent.frameBackgroundName != "无背景" ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 1)
                                        .padding(.horizontal, 8)
                                }
                                
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
                    // 为每个导航链接添加ID，确保在事件更新时能正确刷新
                    .id("\(event.id)-\(event.imageName ?? "")-\(event.frameStyleName ?? "")-\(event.frameBackgroundName ?? "")")
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
                    // 为每个导航链接添加ID，确保在事件更新时能正确刷新
                    .id("\(event.id)-\(event.imageName ?? "")-\(event.frameStyleName ?? "")-\(event.frameBackgroundName ?? "")")
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 事件卡片视图
    @ViewBuilder
    func eventCard(for event: Event) -> some View {
        VStack(alignment: .center, spacing: 4) {
            // 显示图片部分
            ZStack {
                // 背景色
                RoundedRectangle(cornerRadius: 8)
                    .fill(event.type.color.opacity(0.1))
                
                // 事件类型图标或自定义图片
                if let imageName = event.imageName, !imageName.isEmpty {
                    if let image = eventStore.imageCache.getImage(for: imageName, with: event) {
                        // 相框效果
                        if let frameStyleName = event.frameStyleName, 
                           let frameStyle = FrameStyle(rawValue: frameStyleName),
                           frameStyle.usesMaskOrFrame {
                            // 使用相框遮罩
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Group {
                                        if let maskName = frameStyle.maskImageName {
                                            Image(maskName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .opacity(0.85)
                                        }
                                    }
                                )
                                .cornerRadius(8)
                        } else {
                            // 普通显示
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                        }
                    } else {
                        // 没有找到缓存的图片，显示占位符并尝试加载
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(event.type.color)
                            .onAppear {
                                loadImageForEvent(event)
                            }
                    }
                } else {
                    Image(systemName: event.type.icon)
                        .font(.system(size: 30))
                        .foregroundColor(event.type.color)
                }
                
                // 添加相框装饰元素
                if let frameStyleName = event.frameStyleName, 
                   let frameStyle = FrameStyle(rawValue: frameStyleName),
                   !frameStyle.usesMaskOrFrame && !frameStyle.decorationSymbols.isEmpty {
                    
                    // 左上角装饰
                    if frameStyle.decorationSymbols.count > 0 {
                        Image(systemName: frameStyle.decorationSymbols[0])
                            .font(.system(size: 12))
                            .foregroundColor(frameStyle.borderColor)
                            .position(x: 16, y: 16)
                    }
                    
                    // 右上角装饰
                    if frameStyle.decorationSymbols.count > 1 {
                        Image(systemName: frameStyle.decorationSymbols[1])
                            .font(.system(size: 12))
                            .foregroundColor(frameStyle.borderColor.opacity(0.7))
                            .position(x: 64, y: 16)
                    }
                }
            }
            .frame(width: 80, height: 80)
            .padding(.bottom, 4)
            .id("image-\(event.id)-\(event.imageName ?? "")-\(event.frameStyleName ?? "")")
            
            // 事件名称带背景板
            ZStack(alignment: .center) {
                // 背景板
                if let backgroundName = event.frameBackgroundName, backgroundName != "无背景", 
                   let frameBackground = FrameBackground(rawValue: backgroundName) {
                    // 使用与详情页相同的背景图片
                    Image(frameBackground.backgroundImageName ?? "")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                        .overlay(
                            // 装饰符号（如果有）
                            Image(systemName: frameBackground.decorationSymbol)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .padding(.leading, -45),
                            alignment: .center
                        )
                } else {
                    // 如果没有设置背景或设为"无背景"，则使用事件类型颜色
                    RoundedRectangle(cornerRadius: 4)
                        .fill(event.type.color.opacity(0.15))
                        .frame(height: 24)
                }
                
                // 事件名称
                Text(event.name)
                    .font(.system(size: 14))
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(event.frameBackgroundName != nil && event.frameBackgroundName != "无背景" ? .white : event.type.color.opacity(0.8))
                    .shadow(color: event.frameBackgroundName != nil && event.frameBackgroundName != "无背景" ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 6)
            }
            .id("background-\(event.id)-\(event.frameBackgroundName ?? "")")
            
            // 显示剩余天数
            Text(event.formattedDays)
                .font(.system(size: 13))
                .foregroundColor(event.isPassed ? .gray : (event.isCountdown ? .green : .orange))
            
            // 显示日期
            Text(event.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(width: 95, height: 140)
        .onAppear {
            // 在卡片出现时确保加载图片
            if let imageName = event.imageName, !imageName.isEmpty {
                if eventStore.imageCache.getImage(for: imageName, with: event) == nil {
                    loadImageForEvent(event)
                }
            }
        }
    }
    
    // 加载事件图片的辅助方法
    private func loadImageForEvent(_ event: Event) {
        guard let imageName = event.imageName, !imageName.isEmpty else { return }
        
        // 从文档目录加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            
            do {
                let imageData = try Data(contentsOf: fileURL)
                if let originalImage = UIImage(data: imageData) {
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
                        DispatchQueue.main.async {
                            // 在主线程中更新缓存和UI
                            self.eventStore.imageCache.setImage(processedImage, for: imageName, with: event)
                            // 强制视图刷新
                            self.eventStore.objectWillChange.send()
                        }
                    }
                }
            } catch {
                print("加载图片失败: \(error)")
            }
        }
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
