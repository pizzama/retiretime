//
//  EventDetailView.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI
import PhotosUI

// 定义头像框样式枚举
enum FrameStyle: String, CaseIterable, Identifiable {
    case template = "无"
    case frame_style1 = "frame_style1"
    case frame_polaroid = "frame_polaroid"
    case frame_style2 = "frame_style2"
    case frame_style3 = "frame_style3"
    case frame_style4 = "frame_style4"
    case frame_style5 = "frame_style5"
    
    var id: String { self.rawValue }
    
    // 返回对应的边框颜色
    var borderColor: Color {
        switch self {
        case .template: return .green
        case .frame_style1: return .orange
        case .frame_polaroid: return .pink
        case .frame_style2: return .red
        case .frame_style3: return .pink
        case .frame_style4: return .pink
        case .frame_style5: return .yellow
        }
    }
    
    // 返回对应的装饰元素
    var decorationSymbols: [String] {
        switch self {
        case .template: return ["sparkles", "wand.and.stars", "gift", "party.popper"]
        case .frame_style1: return ["person.crop.circle", "person.crop.square", "heart", "star"]
        case .frame_polaroid: return ["photo.on.rectangle", "photo.artframe", "photo.stack", "photo.tv"]
        case .frame_style2: return ["circle", "circle.fill", "circle.dotted", "circle.dashed"]
        case .frame_style3: return ["heart", "heart.fill", "heart.circle", "heart.square"]
        case .frame_style4: return ["leaf", "leaf.fill", "leaf.circle", "leaf.arrow.triangle.circlepath"]
        case .frame_style5: return ["star", "star.fill", "star.circle", "star.square"]
        }
    }
    
    // 返回对应的背景渐变色
    func backgroundGradient() -> LinearGradient {
        switch self {
        case .template:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frame_style1:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frame_polaroid:
            return LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frame_style2:
            return LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.1), Color.orange.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frame_style3:
            return LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.red.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frame_style4:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.6).opacity(0.1), Color(red: 1.0, green: 0.8, blue: 0.8).opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .frame_style5:
            return LinearGradient(
                gradient: Gradient(colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // 返回蒙版或相框的名称
    var maskImageName: String? {
        switch self {
        case .frame_style1:
            return "frame_style1"
        case .frame_polaroid:
            return "frame_polaroid"
        case .frame_style2:
            return "frame_style2"
        case .frame_style3:
            return "frame_style3"
        case .frame_style4:
            return "frame_style4"
        case .frame_style5:
            return "frame_style5"
        default:
            return nil
        }
    }
    
    // 判断是否使用蒙版或相框
    var usesMaskOrFrame: Bool {
        return self == .frame_style1 || self == .frame_polaroid || self == .frame_style2 || self == .frame_style3 || self == .frame_style4 || self == .frame_style5
    }
}

struct EventDetailView: View {
    let event: Event
    @State private var currentEvent: Event
    @State private var selectedFrameStyle: FrameStyle = .template
    @State private var selectedTemplateType: DecorationType = .polaroid
    @State private var showingEditSheet = false
    @State private var showingPhotosPicker = false
    @State private var showingFramePicker = false
    @State private var showingChildEventForm = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageName: String? = nil
    let eventStore: EventStore
    @State private var childEvents: [Event] = []
    @State private var showingPreview = false
    @State private var activeSheet: ActiveSheet? = nil
    
    // 添加照片刷新相关状态变量
    @State private var displayImage: UIImage? = nil
    @State private var isImageLoading = false
    @State private var needsImageRefresh = true
    
    enum ActiveSheet: Identifiable {
        case photosPicker
        case framePicker
        case editSheet
        case childEventForm
        case preview
        
        var id: Int {
            switch self {
            case .photosPicker: return 1
            case .framePicker: return 2
            case .editSheet: return 3
            case .childEventForm: return 4
            case .preview: return 5
            }
        }
    }
    
    init(event: Event, eventStore: EventStore) {
        self.event = event
        self.eventStore = eventStore
        
        // 初始化currentEvent
        _currentEvent = State(initialValue: event)
        
        // 根据event中保存的frameStyleName设置初始框样式
        if let frameStyleName = event.frameStyleName, let style = FrameStyle(rawValue: frameStyleName) {
            _selectedFrameStyle = State(initialValue: style)
        } else {
            _selectedFrameStyle = State(initialValue: .template)
        }
        
        // 获取子事件
        _childEvents = State(initialValue: eventStore.childEvents(for: event))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                // 拍立得风格的照片
                VStack(alignment: .center) {
                    // 相框效果 - 使用辅助方法简化代码
                    frameView
                    
                    // 日期信息
                    Text(currentEvent.formattedDate)
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .rotationEffect(.degrees(-3))
                        .padding(.trailing, 20)
                    
                    // 按钮行
                    HStack(spacing: 16) {
                        // 照片选择按钮
                        Button(action: {
                            activeSheet = .photosPicker
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                Text("更换照片")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                        
                        // 头像框选择按钮
                        Button(action: {
                            activeSheet = .framePicker
                        }) {
                            HStack {
                                Image(systemName: "square.on.square")
                                    .font(.system(size: 14))
                                Text("更换相框")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 12)
                }
                
                // 详细信息区域
                VStack(alignment: .leading, spacing: 16) {
                    // 类型
                    DetailRow(title: "类型", value: currentEvent.type.rawValue, icon: "tag")
                    
                    // 分类
                    DetailRow(title: "分类", value: currentEvent.category, icon: "folder")
                    
                    // 提醒
                    if currentEvent.reminderEnabled {
                        DetailRow(
                            title: "提醒",
                            value: currentEvent.reminderDate != nil ? formatReminderDate(currentEvent.reminderDate!) : "已开启",
                            icon: "bell"
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // 添加子事件按钮
                Button(action: {
                    activeSheet = .childEventForm
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("添加子事件")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .padding(.top, 20)
                
                // 子事件列表
                if !childEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("子事件")
                            .font(.headline)
                            .padding(.leading, 8)
                            .padding(.top, 16)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(childEvents) { childEvent in
                                NavigationLink(destination: ChildEventDetailView(event: childEvent, eventStore: eventStore)) {
                                    ChildEventCard(event: childEvent)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                activeSheet = .editSheet
            }) {
                Text("编辑")
            }
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .photosPicker:
                PhotoPicker(
                    selectedImage: $selectedImage,
                    selectedImageName: $selectedImageName,
                    showingPreview: $showingPreview,
                    event: currentEvent,
                    eventStore: eventStore,
                    frameStyle: selectedFrameStyle
                ) { imageName in
                    if let imageName = imageName {
                        // 更新事件的照片
                        var updatedEvent = currentEvent
                        updatedEvent.imageName = imageName
                        eventStore.updateEvent(updatedEvent)
                        
                        // 更新当前视图使用的事件数据
                        self.currentEvent = updatedEvent
                        
                        // 发送通知，让所有使用此事件的视图都能刷新
                        NotificationCenter.default.post(
                            name: Notification.Name("EventUpdated"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                    }
                    activeSheet = nil
                }
            case .framePicker:
                FramePickerView(selectedFrameStyle: $selectedFrameStyle, event: currentEvent, eventStore: eventStore)
                    .onDisappear {
                        // 刷新当前事件，以防在帧选择器中已经更新了事件
                        if let updatedEvent = eventStore.getEvent(by: currentEvent.id) {
                            self.currentEvent = updatedEvent
                        }
                        activeSheet = nil
                    }
            case .editSheet:
                ChildEventEditView(eventStore: eventStore, childEvent: currentEvent)
                    .onDisappear {
                        activeSheet = nil
                    }
            case .childEventForm:
                ChildEventFormView(parentEvent: currentEvent, eventStore: eventStore)
                    .onDisappear {
                        // 表单关闭时刷新子事件列表
                        childEvents = eventStore.childEvents(for: currentEvent)
                        activeSheet = nil
                    }
            case .preview:
                if let image = selectedImage {
                    PhotoPreviewView(
                        image: image,
                        event: currentEvent,
                        eventStore: eventStore,
                        frameStyle: selectedFrameStyle
                    )
                    .onDisappear {
                        // 清除预览状态
                        showingPreview = false
                        // 刷新当前事件，以防在预览视图中已经更新了事件
                        if let updatedEvent = eventStore.getEvent(by: currentEvent.id) {
                            self.currentEvent = updatedEvent
                        }
                        activeSheet = nil
                    }
                } else {
                    // 如果图片为空，显示错误信息
                    VStack {
                        Text("错误：无法加载图片")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("关闭") {
                            showingPreview = false
                            activeSheet = nil
                        }
                        .padding()
                    }
                }
            }
        }
        .onChange(of: showingPreview) { newValue in
            if newValue {
                print("showingPreview 变为 true，设置 activeSheet = .preview")
                activeSheet = .preview
            }
        }
        .onAppear {
            // 刷新当前事件的数据
            if let updatedEvent = eventStore.getEvent(by: event.id) {
                self.currentEvent = updatedEvent
            }
            
            // 刷新子事件列表
            childEvents = eventStore.childEvents(for: currentEvent)
            
            // 当视图出现时加载图片
            if needsImageRefresh {
                loadAndProcessImage()
            }
            
            // 添加通知观察者，用于刷新图片缓存
            NotificationCenter.default.addObserver(forName: Notification.Name("RefreshImageCache"), object: nil, queue: .main) { notification in
                // 检查通知中的事件ID是否与当前事件ID匹配
                if let notificationEventId = notification.userInfo?["eventId"] as? UUID,
                   notificationEventId == currentEvent.id {
                    // 清除当前图片，触发重新加载
                    self.displayImage = nil
                    self.needsImageRefresh = true
                    self.loadAndProcessImage()
                }
            }
            
            // 添加通知监听，以便在事件数据更新时刷新UI
            NotificationCenter.default.addObserver(
                forName: Notification.Name("EventUpdated"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let eventId = userInfo["eventId"] as? UUID,
                   eventId == event.id,
                   let updatedEvent = eventStore.getEvent(by: eventId) {
                    print("事件详情页面：收到事件更新通知，事件ID: \(eventId)")
                    self.currentEvent = updatedEvent
                    self.needsImageRefresh = true
                    self.loadAndProcessImage()
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: Notification.Name("RefreshImageCache"), object: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name("EventUpdated"), object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 当应用从后台回到前台时刷新子事件列表和当前事件数据
            if let updatedEvent = eventStore.getEvent(by: event.id) {
                self.currentEvent = updatedEvent
            }
            childEvents = eventStore.childEvents(for: currentEvent)
        }
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // 相框视图辅助方法
    private var frameView: some View {
        ZStack {
            // 相框背景 - 使用渐变色
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedFrameStyle.backgroundGradient())
                .frame(width: 270, height: 350)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 相框边框
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedFrameStyle.borderColor.opacity(0.3), lineWidth: 2)
                .frame(width: 270, height: 350)
            
            // 拍立得照片容器
            polaroidContainer
            
            // 装饰元素部分
            frameDecorations
        }
        .padding(.top, 20)
    }
    
    // 拍立得照片容器视图
    private var polaroidContainer: some View {
        ZStack(alignment: .bottom) {
            // 照片部分
            photoView
                .frame(width: 240, height: 240)
                .padding(.bottom, 80)
            
            // 拍立得白底部分
            VStack(spacing: 4) {
                // 事件名称
                Text(currentEvent.name)
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.top, 16)
                    .foregroundColor(.black)
                
                // 备注（如果有）
                if !currentEvent.notes.isEmpty {
                    Text(currentEvent.notes)
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                }
                
                // 剩余/已过天数 - 使用手写风格标签
                Text(currentEvent.daysRemaining == 0 ? "今天" : 
                     (currentEvent.isCountdown ? "还有\(abs(currentEvent.daysRemaining))天" : "已过\(abs(currentEvent.daysRemaining))天"))
                    .font(.custom("Noteworthy", size: 14))
                    .foregroundColor(currentEvent.isCountdown ? .green : .orange)
                    .padding(.top, 2)
                    .rotationEffect(.degrees(-2))
            }
            .frame(width: 240, height: 80)
            .background(Color.white)
        }
        .frame(width: 240, height: 360)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .rotationEffect(.degrees(2))
    }
    
    // 相框装饰元素
    private var frameDecorations: some View {
        Group {
            // 根据选择的框样式添加装饰元素
            if selectedFrameStyle != .template && !selectedFrameStyle.usesMaskOrFrame {
                // 装饰元素 - 左上角
                if selectedFrameStyle.decorationSymbols.count > 0 {
                    Image(systemName: selectedFrameStyle.decorationSymbols[0])
                        .foregroundColor(selectedFrameStyle.borderColor)
                        .font(.system(size: 20))
                        .position(x: 35, y: 35)
                }
                
                // 装饰元素 - 右上角
                if selectedFrameStyle.decorationSymbols.count > 1 {
                    Image(systemName: selectedFrameStyle.decorationSymbols[1])
                        .foregroundColor(selectedFrameStyle.borderColor.opacity(0.7))
                        .font(.system(size: 18))
                        .position(x: 235, y: 35)
                }
                
                // 装饰元素 - 右下角
                if selectedFrameStyle.decorationSymbols.count > 2 {
                    Image(systemName: selectedFrameStyle.decorationSymbols[2])
                        .foregroundColor(selectedFrameStyle.borderColor.opacity(0.8))
                        .font(.system(size: 16))
                        .position(x: 235, y: 315)
                }
                
                // 装饰元素 - 左下角
                if selectedFrameStyle.decorationSymbols.count > 3 {
                    Image(systemName: selectedFrameStyle.decorationSymbols[3])
                        .foregroundColor(selectedFrameStyle.borderColor.opacity(0.6))
                        .font(.system(size: 16))
                        .position(x: 35, y: 315)
                }
                
                // 装饰元素 - 顶部中间
                if currentEvent.type == .retirement {
                    Image(systemName: "party.popper.fill")
                        .foregroundColor(selectedFrameStyle.borderColor.opacity(0.8))
                        .font(.system(size: 18))
                        .position(x: 130, y: 20)
                }
                
                // 装饰元素 - 底部中间
                if currentEvent.isCountdown {
                    Image(systemName: "hourglass")
                        .foregroundColor(selectedFrameStyle.borderColor.opacity(0.7))
                        .font(.system(size: 16))
                        .position(x: 130, y: 310)
                } else {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(selectedFrameStyle.borderColor.opacity(0.7))
                        .font(.system(size: 16))
                        .position(x: 130, y: 310)
                }
                
                // 装饰线条 - 顶部
                Path { path in
                    path.move(to: CGPoint(x: 45, y: 20))
                    path.addLine(to: CGPoint(x: 225, y: 20))
                }
                .stroke(selectedFrameStyle.borderColor.opacity(0.4), lineWidth: 1)
                
                // 装饰线条 - 底部
                Path { path in
                    path.move(to: CGPoint(x: 45, y: 330))
                    path.addLine(to: CGPoint(x: 225, y: 330))
                }
                .stroke(selectedFrameStyle.borderColor.opacity(0.4), lineWidth: 1)
            }
        }
    }
    
    // 照片视图辅助方法 - 使用currentEvent而不是event
    private var photoView: some View {
        ZStack {
            if let imageName = currentEvent.imageName, !imageName.isEmpty {
                if let image = displayImage {
                    // 如果有处理后的图片，直接显示
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                } else if isImageLoading {
                    // 显示加载中
                    ProgressView()
                        .frame(width: 240, height: 240)
                } else {
                    // 显示占位图标并触发加载
                    Rectangle()
                        .fill(currentEvent.type.color.opacity(0.1))
                        .frame(width: 240, height: 240)
                    
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(currentEvent.type.color)
                        .onAppear {
                            loadAndProcessImage()
                        }
                }
            } else {
                // 默认图标背景
                Rectangle()
                    .fill(currentEvent.type.color.opacity(0.1))
                    .frame(width: 240, height: 240)
                
                Image(systemName: currentEvent.type.icon)
                    .font(.system(size: 80))
                    .foregroundColor(currentEvent.type.color)
            }
        }
    }
    
    // 加载和处理图片的方法
    private func loadAndProcessImage() {
        guard let imageName = currentEvent.imageName, !imageName.isEmpty else { return }
        
        isImageLoading = true
        
        // 使用后台线程加载图片
        DispatchQueue.global().async {
            // 从文档目录加载图片
            if let image = self.loadImageFromDocumentDirectory(named: imageName) {
                // 检查是否应用相框样式
                var finalImage: UIImage? = nil
                
                if let frameStyleName = self.currentEvent.frameStyleName,
                   let frameStyle = FrameStyle(rawValue: frameStyleName),
                   frameStyle.usesMaskOrFrame {
                    finalImage = TemplateImageGenerator.shared.generateTemplateImage(
                        originalImage: image,
                        frameStyle: frameStyle, 
                        scale: self.currentEvent.imageScale,
                        offset: CGSize(width: self.currentEvent.imageOffsetX, height: self.currentEvent.imageOffsetY)
                    )
                } else {
                    // 使用原始图片
                    finalImage = image
                }
                
                // 切换回主线程更新UI
                DispatchQueue.main.async {
                    self.displayImage = finalImage
                    self.isImageLoading = false
                    self.needsImageRefresh = false
                }
            } else {
                // 处理加载失败的情况
                DispatchQueue.main.async {
                    self.isImageLoading = false
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

// 照片预览视图
struct PhotoPreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var imageScale: CGFloat = 1.0
    @State private var lastImageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var showingSaveAlert = false
    @State private var debugMessage: String = ""
    
    let image: UIImage
    let event: Event
    let eventStore: EventStore
    let frameStyle: FrameStyle
    
    var body: some View {
        NavigationView {
            VStack {
                // 调试信息
                if !debugMessage.isEmpty {
                    Text(debugMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // 预览区域
                GeometryReader { geometry in
                    ZStack {
                        // 背景 - 使用与详情页相同的背景
                        RoundedRectangle(cornerRadius: 12)
                            .fill(frameStyle.backgroundGradient())
                            .frame(width: 270, height: 350)
                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // 相框边框
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(frameStyle.borderColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 270, height: 350)
                        
                        // 拍立得照片
                        ZStack(alignment: .bottom) {
                            // 照片部分
                            ZStack {
                                // 显示照片，应用缩放和偏移
                                if frameStyle.usesMaskOrFrame {
                                    // 使用蒙版或相框样式的预览
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .scaleEffect(imageScale)
                                        .offset(imageOffset)
                                        .frame(width: 240, height: 240)
                                        .clipped()
                                        .overlay(
                                            // 显示相框或蒙版的轮廓
                                            Group {
                                                if let maskName = frameStyle.maskImageName {
                                                    Image(maskName)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .opacity(0.85)
                                                }
                                            }
                                        )
                                } else {
                                    // 普通样式预览
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .scaleEffect(imageScale)
                                        .offset(imageOffset)
                                        .frame(width: 240, height: 240)
                                        .clipped()
                                }
                            }
                            .frame(width: 240, height: 240)
                            .padding(.bottom, 80)
                            
                            // 拍立得白底部分
                            VStack(spacing: 4) {
                                // 事件名称
                                Text(event.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 16)
                                    .foregroundColor(.black)
                                
                                // 备注（如果有）
                                if !event.notes.isEmpty {
                                    Text(event.notes)
                                        .font(.system(size: 12))
                                        .italic()
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .padding(.horizontal, 10)
                                }
                                
                                // 剩余/已过天数
                                Text(event.daysRemaining == 0 ? "今天" : 
                                     (event.isCountdown ? "还有\(abs(event.daysRemaining))天" : "已过\(abs(event.daysRemaining))天"))
                                    .font(.custom("Noteworthy", size: 14))
                                    .foregroundColor(event.isCountdown ? .green : .orange)
                                    .padding(.top, 2)
                                    .rotationEffect(.degrees(-2))
                            }
                            .frame(width: 240, height: 80)
                            .background(Color.white)
                        }
                        .frame(width: 240, height: 360)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .rotationEffect(.degrees(2))
                        // 将手势移到这里，应用于整个拍立得照片区域
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastImageScale
                                    lastImageScale = value
                                    imageScale = min(max(imageScale * delta, 0.5), 3.0)
                                }
                                .onEnded { _ in
                                    lastImageScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    imageOffset = CGSize(
                                        width: lastImageOffset.width + value.translation.width,
                                        height: lastImageOffset.height + value.translation.height
                                    )
                                    // 设置拖动状态为true，减少视图更新
                                    isDragging = true
                                }
                                .onEnded { _ in
                                    lastImageOffset = imageOffset
                                    // 拖动结束后恢复状态
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isDragging = false
                                    }
                                }
                        )
                        
                        // 根据选择的框样式添加装饰元素
                        if frameStyle != .template && !frameStyle.usesMaskOrFrame {
                            // 装饰元素 - 左上角
                            if frameStyle.decorationSymbols.count > 0 {
                                Image(systemName: frameStyle.decorationSymbols[0])
                                    .foregroundColor(frameStyle.borderColor)
                                    .font(.system(size: 20))
                                    .position(x: 35, y: 35)
                            }
                            
                            // 装饰元素 - 右上角
                            if frameStyle.decorationSymbols.count > 1 {
                                Image(systemName: frameStyle.decorationSymbols[1])
                                    .foregroundColor(frameStyle.borderColor.opacity(0.7))
                                    .font(.system(size: 18))
                                    .position(x: 235, y: 35)
                            }
                            
                            // 装饰元素 - 右下角
                            if frameStyle.decorationSymbols.count > 2 {
                                Image(systemName: frameStyle.decorationSymbols[2])
                                    .foregroundColor(frameStyle.borderColor.opacity(0.8))
                                    .font(.system(size: 16))
                                    .position(x: 235, y: 315)
                            }
                            
                            // 装饰元素 - 左下角
                            if frameStyle.decorationSymbols.count > 3 {
                                Image(systemName: frameStyle.decorationSymbols[3])
                                    .foregroundColor(frameStyle.borderColor.opacity(0.6))
                                    .font(.system(size: 16))
                                    .position(x: 35, y: 315)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 调整信息
                // 只在非拖动状态下显示调整信息，减少视图更新频率
                if !isDragging {
                    Text("缩放: \(String(format: "%.1f", imageScale))x  位置: (\(String(format: "%.0f", imageOffset.width)), \(String(format: "%.0f", imageOffset.height)))")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                
                // 控制按钮
                HStack(spacing: 20) {
                    Button(action: {
                        // 重置缩放和位置
                        withAnimation {
                            imageScale = 1.0
                            imageOffset = .zero
                            lastImageScale = 1.0
                            lastImageOffset = .zero
                        }
                    }) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                    
                    Button(action: {
                        showingSaveAlert = true
                    }) {
                        Label("保存", systemImage: "checkmark")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(20)
                    }
                }
                .padding()
            }
            .navigationTitle("调整照片")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingSaveAlert) {
                Alert(
                    title: Text("保存照片"),
                    message: Text("确定要保存这张照片吗？"),
                    primaryButton: .default(Text("保存")) {
                        // 保存照片和调整信息
                        if let imageName = saveImageWithAdjustments() {
                            var updatedEvent = event
                            updatedEvent.imageName = imageName
                            // 保存缩放和位置信息
                            updatedEvent.imageScale = imageScale
                            updatedEvent.imageOffsetX = imageOffset.width
                            updatedEvent.imageOffsetY = imageOffset.height
                            eventStore.updateEvent(updatedEvent)
                            
                            // 发送通知，让所有使用此事件的视图都能刷新
                            NotificationCenter.default.post(
                                name: Notification.Name("EventUpdated"),
                                object: nil,
                                userInfo: ["eventId": event.id]
                            )
                            
                            presentationMode.wrappedValue.dismiss()
                        }
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
            .onAppear {
                // 初始化缩放和位置
                imageScale = event.imageScale > 0 ? event.imageScale : 1.0
                imageOffset = CGSize(width: event.imageOffsetX, height: event.imageOffsetY)
                lastImageOffset = imageOffset
                
                // 检查图片是否有效
                if image.size.width == 0 || image.size.height == 0 {
                    debugMessage = "警告: 图片尺寸为零"
                }
            }
        }
    }
    
    // 保存图片和调整信息
    private func saveImageWithAdjustments() -> String? {
        let imageName = "event_image_\(UUID().uuidString).jpg"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            debugMessage = "保存失败: 无法获取文档目录或转换图片数据"
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(imageName)
        
        do {
            try imageData.write(to: fileURL)
            print("成功保存图片: \(imageName), 缩放: \(imageScale), 偏移: \(imageOffset)")
            return imageName
        } catch {
            debugMessage = "保存图片失败: \(error.localizedDescription)"
            print("保存图片失败: \(error)")
            return nil
        }
    }
}

// 修改PhotoPicker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageName: String?
    @Binding var showingPreview: Bool
    var event: Event
    var eventStore: EventStore
    var frameStyle: FrameStyle
    var onSelect: (String?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                parent.onSelect(nil)
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let error = error {
                    print("加载图片错误: \(error.localizedDescription)")
                }
                
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        print("成功加载图片，尺寸: \(image.size.width) x \(image.size.height)")
                        self.parent.selectedImage = image
                        
                        // 确保图片已经设置后再显示预览
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.parent.showingPreview = true
                        }
                    }
                } else {
                    print("无法加载图片对象")
                    self.parent.onSelect(nil)
                }
            }
        }
    }
}

// 头像框选择视图
struct FramePickerView: View {
    @Binding var selectedFrameStyle: FrameStyle
    @Environment(\.presentationMode) var presentationMode
    var event: Event
    var eventStore: EventStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FrameStyle.allCases) { style in
                    Button(action: {
                        selectedFrameStyle = style
                        
                        // 更新Event对象和保存
                        var updatedEvent = event
                        updatedEvent.frameStyleName = style.rawValue
                        eventStore.updateEvent(updatedEvent)
                        
                        // 发送通知，通知EventListView刷新图片缓存
                        NotificationCenter.default.post(
                            name: Notification.Name("RefreshImageCache"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                        
                        // 发送通知，让所有使用此事件的视图都能刷新
                        NotificationCenter.default.post(
                            name: Notification.Name("EventUpdated"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                        
                        print("已发送刷新图片缓存通知，事件ID: \(event.id)，相框样式: \(style.rawValue)")
                        
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            // 预览框
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(style.backgroundGradient())
                                    .frame(width: 60, height: 60)
                                
                                // 如果是蒙版或相框样式，显示实际相框图片
                                if style.usesMaskOrFrame, let frameName = style.maskImageName {
                                    // 添加示例照片背景
                                    ZStack {
                                        // 示例照片背景（灰色矩形）
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white.opacity(0.7))
                                            )
                                        
                                        // 相框图片
                                        Image(frameName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    }
                                } else {
                                    // 对于无相框样式，显示装饰元素
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(style.borderColor.opacity(0.5), lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                    
                                    // 显示装饰元素
                                    if style.decorationSymbols.count > 0 {
                                        Image(systemName: style.decorationSymbols[0])
                                            .font(.system(size: 20))
                                            .foregroundColor(style.borderColor)
                                            .position(x: 20, y: 20)
                                    }
                                    
                                    if style.decorationSymbols.count > 1 {
                                        Image(systemName: style.decorationSymbols[1])
                                            .font(.system(size: 16))
                                            .foregroundColor(style.borderColor.opacity(0.7))
                                            .position(x: 40, y: 20)
                                    }
                                    
                                    if style.decorationSymbols.count > 2 {
                                        Image(systemName: style.decorationSymbols[2])
                                            .font(.system(size: 16))
                                            .foregroundColor(style.borderColor.opacity(0.8))
                                            .position(x: 40, y: 40)
                                    }
                                    
                                    if style.decorationSymbols.count > 3 {
                                        Image(systemName: style.decorationSymbols[3])
                                            .font(.system(size: 16))
                                            .foregroundColor(style.borderColor.opacity(0.6))
                                            .position(x: 20, y: 40)
                                    }
                                }
                            }
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(style.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                
                                // 添加简短描述
                                Text(style.usesMaskOrFrame ? "相框样式" : "装饰样式")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            if selectedFrameStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            selectedFrameStyle == style ?
                                RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                : nil
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("选择相框样式")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 装饰类型枚举
enum DecorationType: String, CaseIterable, Identifiable {
    case none = "无装饰"
    case polaroid = "拍立得"
    
    var id: String { self.rawValue }
}

// 子事件创建表单
struct ChildEventFormView: View {
    @Environment(\.presentationMode) var presentationMode
    let parentEvent: Event
    let eventStore: EventStore
    
    @State private var name: String = ""
    @State private var date: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("子事件信息")) {
                    TextField("名称", text: $name)
                    DatePicker("日期", selection: $date, displayedComponents: [.date])
                }
                
                Section {
                    Button("创建子事件") {
                        if !name.isEmpty {
                            // 创建子事件
                            _ = eventStore.createChildEvent(for: parentEvent, name: name, date: date)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("添加子事件")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 子事件详情视图
struct ChildEventDetailView: View {
    let event: Event
    @State private var currentEvent: Event
    @State private var selectedFrameStyle: FrameStyle = .template
    @State private var showingPhotosPicker = false
    @State private var showingFramePicker = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageName: String? = nil
    @State private var showingPreview = false
    @State private var activeSheet: ActiveSheet? = nil
    let eventStore: EventStore
    @Environment(\.presentationMode) var presentationMode
    
    // 添加照片刷新相关状态变量
    @State private var displayImage: UIImage? = nil
    @State private var isImageLoading = false
    @State private var needsImageRefresh = true
    
    enum ActiveSheet: Identifiable {
        case photosPicker
        case framePicker
        case editSheet
        case preview
        
        var id: Int {
            switch self {
            case .photosPicker: return 1
            case .framePicker: return 2
            case .editSheet: return 3
            case .preview: return 4
            }
        }
    }
    
    init(event: Event, eventStore: EventStore) {
        self.event = event
        self.eventStore = eventStore
        
        // 初始化currentEvent
        _currentEvent = State(initialValue: event)
        
        // 根据event中保存的frameStyleName设置初始框样式
        if let frameStyleName = event.frameStyleName, let style = FrameStyle(rawValue: frameStyleName) {
            _selectedFrameStyle = State(initialValue: style)
        } else {
            _selectedFrameStyle = State(initialValue: .template)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                // 拍立得风格的照片
                VStack(alignment: .center) {
                    // 相框效果 - 使用辅助方法简化代码
                    frameView
                    
                    // 日期信息
                    Text(currentEvent.formattedDate)
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .rotationEffect(.degrees(-3))
                        .padding(.trailing, 20)
                    
                    // 按钮行
                    HStack(spacing: 16) {
                        // 照片选择按钮
                        Button(action: {
                            activeSheet = .photosPicker
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                Text("更换照片")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                        }
                        
                        // 头像框选择按钮
                        Button(action: {
                            activeSheet = .framePicker
                        }) {
                            HStack {
                                Image(systemName: "square.on.square")
                                    .font(.system(size: 14))
                                Text("更换相框")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .padding()
        }
        .navigationTitle(currentEvent.name)
        .navigationBarItems(
            trailing: Button(action: {
                activeSheet = .editSheet
            }) {
                Text("编辑")
            }
        )
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .photosPicker:
                PhotoPicker(
                    selectedImage: $selectedImage,
                    selectedImageName: $selectedImageName,
                    showingPreview: $showingPreview,
                    event: currentEvent,
                    eventStore: eventStore,
                    frameStyle: selectedFrameStyle
                ) { imageName in
                    if let imageName = imageName {
                        // 更新事件的照片
                        var updatedEvent = currentEvent
                        updatedEvent.imageName = imageName
                        eventStore.updateEvent(updatedEvent)
                        
                        // 更新当前视图使用的事件数据
                        self.currentEvent = updatedEvent
                        
                        // 发送通知，让所有使用此事件的视图都能刷新
                        NotificationCenter.default.post(
                            name: Notification.Name("EventUpdated"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                    }
                    activeSheet = nil
                }
            case .framePicker:
                FramePickerView(selectedFrameStyle: $selectedFrameStyle, event: currentEvent, eventStore: eventStore)
                    .onDisappear {
                        // 刷新当前事件，以防在帧选择器中已经更新了事件
                        if let updatedEvent = eventStore.getEvent(by: currentEvent.id) {
                            self.currentEvent = updatedEvent
                        }
                        activeSheet = nil
                    }
            case .editSheet:
                ChildEventEditView(eventStore: eventStore, childEvent: currentEvent)
                    .onDisappear {
                        activeSheet = nil
                    }
            case .preview:
                if let image = selectedImage {
                    PhotoPreviewView(
                        image: image,
                        event: currentEvent,
                        eventStore: eventStore,
                        frameStyle: selectedFrameStyle
                    )
                    .onDisappear {
                        // 清除预览状态
                        showingPreview = false
                        // 刷新当前事件，以防在预览视图中已经更新了事件
                        if let updatedEvent = eventStore.getEvent(by: currentEvent.id) {
                            self.currentEvent = updatedEvent
                        }
                        activeSheet = nil
                    }
                } else {
                    // 如果图片为空，显示错误信息
                    VStack {
                        Text("错误：无法加载图片")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("关闭") {
                            showingPreview = false
                            activeSheet = nil
                        }
                        .padding()
                    }
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("删除子事件"),
                message: Text("确定要删除这个子事件吗？此操作无法撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    eventStore.deleteChildEvent(event)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("删除子事件")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onChange(of: showingPreview) { newValue in
            if newValue {
                print("showingPreview 变为 true，设置 activeSheet = .preview")
                activeSheet = .preview
            }
        }
        .onAppear {
            // 当视图出现时加载图片
            if needsImageRefresh {
                loadAndProcessImage()
            }
            
            // 添加通知观察者，用于刷新图片缓存
            NotificationCenter.default.addObserver(forName: Notification.Name("RefreshImageCache"), object: nil, queue: .main) { notification in
                // 检查通知中的事件ID是否与当前事件ID匹配
                if let notificationEventId = notification.userInfo?["eventId"] as? UUID,
                   notificationEventId == currentEvent.id {
                    // 清除当前图片，触发重新加载
                    self.displayImage = nil
                    self.needsImageRefresh = true
                    self.loadAndProcessImage()
                }
            }
            
            // 添加事件更新通知观察者
            NotificationCenter.default.addObserver(forName: Notification.Name("EventUpdated"), object: nil, queue: .main) { notification in
                // 检查通知中的事件ID是否与当前事件ID匹配
                if let notificationEventId = notification.userInfo?["eventId"] as? UUID,
                   notificationEventId == event.id {
                    // 刷新当前事件数据
                    if let updatedEvent = eventStore.getEvent(by: event.id) {
                        self.currentEvent = updatedEvent
                        self.needsImageRefresh = true
                        self.loadAndProcessImage()
                    }
                }
            }
        }
        .onDisappear {
            // 清除通知观察者
            NotificationCenter.default.removeObserver(self, name: Notification.Name("RefreshImageCache"), object: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name("EventUpdated"), object: nil)
        }
    }
    
    // 相框视图辅助方法
    private var frameView: some View {
        ZStack {
            // 相框背景 - 使用渐变色
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedFrameStyle.backgroundGradient())
                .frame(width: 270, height: 350)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 相框边框
            RoundedRectangle(cornerRadius: 12)
                .stroke(selectedFrameStyle.borderColor.opacity(0.3), lineWidth: 2)
                .frame(width: 270, height: 350)
            
            // 拍立得照片容器
            polaroidContainer
        }
        .padding(.top, 20)
    }
    
    // 拍立得照片容器视图
    private var polaroidContainer: some View {
        ZStack(alignment: .bottom) {
            // 照片部分
            photoView
                .frame(width: 240, height: 240)
                .padding(.bottom, 80)
            
            // 拍立得白底部分
            VStack(spacing: 4) {
                // 事件名称
                Text(currentEvent.name)
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.top, 16)
                    .foregroundColor(.black)
                
                // 备注（如果有）
                if !currentEvent.notes.isEmpty {
                    Text(currentEvent.notes)
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                }
                
                // 剩余/已过天数 - 使用手写风格标签
                Text(currentEvent.daysRemaining == 0 ? "今天" : 
                     (currentEvent.isCountdown ? "还有\(abs(currentEvent.daysRemaining))天" : "已过\(abs(currentEvent.daysRemaining))天"))
                    .font(.custom("Noteworthy", size: 14))
                    .foregroundColor(currentEvent.isCountdown ? .green : .orange)
                    .padding(.top, 2)
                    .rotationEffect(.degrees(-2))
            }
            .frame(width: 240, height: 80)
            .background(Color.white)
        }
        .frame(width: 240, height: 360)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .rotationEffect(.degrees(2))
    }
    
    // 照片视图辅助方法 - 使用currentEvent而不是event
    private var photoView: some View {
        ZStack {
            if let imageName = currentEvent.imageName, !imageName.isEmpty {
                if let image = displayImage {
                    // 如果有处理后的图片，直接显示
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                } else if isImageLoading {
                    // 显示加载中
                    ProgressView()
                        .frame(width: 240, height: 240)
                } else {
                    // 显示占位图标并触发加载
                    Rectangle()
                        .fill(currentEvent.type.color.opacity(0.1))
                        .frame(width: 240, height: 240)
                    
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(currentEvent.type.color)
                        .onAppear {
                            loadAndProcessImage()
                        }
                }
            } else {
                // 默认图标背景
                Rectangle()
                    .fill(currentEvent.type.color.opacity(0.1))
                    .frame(width: 240, height: 240)
                
                Image(systemName: currentEvent.type.icon)
                    .font(.system(size: 80))
                    .foregroundColor(currentEvent.type.color)
            }
        }
    }
    
    // 加载和处理图片的方法
    private func loadAndProcessImage() {
        guard let imageName = currentEvent.imageName, !imageName.isEmpty else { return }
        
        isImageLoading = true
        
        // 使用后台线程加载图片
        DispatchQueue.global().async {
            // 从文档目录加载图片
            if let image = self.loadImageFromDocumentDirectory(named: imageName) {
                // 检查是否应用相框样式
                var finalImage: UIImage? = nil
                
                if let frameStyleName = self.currentEvent.frameStyleName,
                   let frameStyle = FrameStyle(rawValue: frameStyleName),
                   frameStyle.usesMaskOrFrame {
                    finalImage = TemplateImageGenerator.shared.generateTemplateImage(
                        originalImage: image,
                        frameStyle: frameStyle, 
                        scale: self.currentEvent.imageScale,
                        offset: CGSize(width: self.currentEvent.imageOffsetX, height: self.currentEvent.imageOffsetY)
                    )
                } else {
                    // 使用原始图片
                    finalImage = image
                }
                
                // 切换回主线程更新UI
                DispatchQueue.main.async {
                    self.displayImage = finalImage
                    self.isImageLoading = false
                    self.needsImageRefresh = false
                }
            } else {
                // 处理加载失败的情况
                DispatchQueue.main.async {
                    self.isImageLoading = false
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

// 子事件卡片组件
struct ChildEventCard: View {
    let event: Event
    
    var body: some View {
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
                            .frame(width: 120, height: 120)
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
            
            Text(event.formattedDays)
                .font(.system(size: 13))
                .foregroundColor(event.isCountdown ? .green : .orange)
                .padding(.horizontal, 4)
            
            Text(event.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
        }
        .frame(width: 160, height: 200)
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

// 子事件编辑视图
struct ChildEventEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var date: Date
    @State private var notes: String
    
    let eventStore: EventStore
    let childEvent: Event
    
    init(eventStore: EventStore, childEvent: Event) {
        self.eventStore = eventStore
        self.childEvent = childEvent
        
        // 初始化状态变量
        _name = State(initialValue: childEvent.name)
        _date = State(initialValue: childEvent.date)
        _notes = State(initialValue: childEvent.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                    DatePicker("日期", selection: $date, displayedComponents: [.date])
                    
                    VStack(alignment: .leading) {
                        Text("备注")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Section {
                    Button("保存修改") {
                        if !name.isEmpty {
                            // 更新子事件
                            var updatedEvent = childEvent
                            updatedEvent.name = name
                            updatedEvent.date = date
                            updatedEvent.notes = notes
                            
                            eventStore.updateEvent(updatedEvent)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("编辑子事件")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    NavigationView {
        EventDetailView(event: Event.samples[0], eventStore: EventStore())
    }
}
