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

// 定义背景板样式枚举
enum FrameBackground: String, CaseIterable, Identifiable {
    case none = "无背景"
    case frame_bar1 = "frame_bar1"
    case frame_bar2 = "frame_bar2"
    case frame_bar3 = "frame_bar3"
    
    var id: String { self.rawValue }
    
    // 背景图片名称
    var backgroundImageName: String? {
        switch self {
        case .none: return nil
        default: return self.rawValue
        }
    }
    
    // 背景颜色
    var backgroundColor: Color {
        switch self {
        case .none: return Color.clear
        case .frame_bar1: return Color.blue.opacity(0.7)
        case .frame_bar2: return Color.pink.opacity(0.7)
        case .frame_bar3: return Color.green.opacity(0.7)
        }
    }
    
    // 装饰符号
    var decorationSymbol: String {
        switch self {
        case .none: return ""
        case .frame_bar1: return "star.fill"
        case .frame_bar2: return "heart.fill"
        case .frame_bar3: return "leaf.fill"
        }
    }
}

// 装饰类型枚举
enum DecorationType: String, CaseIterable, Identifiable {
    case none = "无装饰"
    case polaroid = "拍立得"
    
    var id: String { self.rawValue }
}

struct EventDetailView: View {
    let event: Event
    @ObservedObject var eventStore: EventStore
    @State private var selectedFrameStyle: FrameStyle = .template
    @State private var selectedTemplateType: DecorationType = .polaroid
    @State private var showingEditSheet = false
    @State private var showingPhotosPicker = false
    @State private var showingFramePicker = false
    @State private var showingChildEventForm = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageName: String? = nil
    @State private var showingPreview = false
    @State private var activeSheet: ActiveSheet? = nil
    @State private var eventId: UUID
    @State private var selectedFrameBackground: FrameBackground = .none
    @State private var showingBackgroundPicker = false
    
    // 添加照片刷新相关状态变量
    @State private var displayImage: UIImage? = nil
    @State private var isImageLoading = false
    @State private var needsImageRefresh = true
    
    // 始终从eventStore获取最新的事件数据
    var currentEvent: Event {
        eventStore.getEvent(by: eventId) ?? event
    }
    
    // 添加子事件的计算属性，实时从eventStore获取
    var childEvents: [Event] {
        eventStore.childEvents(for: currentEvent)
    }
    
    enum ActiveSheet: Identifiable {
        case photosPicker
        case framePicker
        case backgroundPicker
        case editSheet
        case preview
        case childEventForm
        
        var id: Int {
            switch self {
            case .photosPicker: return 1
            case .framePicker: return 2
            case .backgroundPicker: return 3
            case .editSheet: return 4
            case .preview: return 5
            case .childEventForm: return 6
            }
        }
    }
    
    init(eventStore: EventStore, event: Event) {
        self.event = event
        self.eventStore = eventStore
        self._eventId = State(initialValue: event.id)
        
        // 根据event中保存的frameStyleName设置初始框样式
        if let frameStyleName = event.frameStyleName, let style = FrameStyle(rawValue: frameStyleName) {
            _selectedFrameStyle = State(initialValue: style)
        } else {
            _selectedFrameStyle = State(initialValue: .template)
        }
        
        // 根据event中保存的frameBackgroundName设置初始背景板样式
        if let frameBackgroundName = event.frameBackgroundName, let background = FrameBackground(rawValue: frameBackgroundName) {
            _selectedFrameBackground = State(initialValue: background)
        } else {
            _selectedFrameBackground = State(initialValue: .none)
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
                        
                        // 背景板选择按钮
                        Button(action: {
                            activeSheet = .backgroundPicker
                        }) {
                            HStack {
                                Image(systemName: "rectangle.fill.on.rectangle.fill")
                                    .font(.system(size: 14))
                                Text("更换背景")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple)
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
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(childEvents.indices, id: \.self) { index in
                                let childEvent = childEvents[index]
                                NavigationLink(destination: ChildEventDetailView(eventStore: eventStore, event: childEvent)) {
                                    ChildEventCard(childEvent: childEvent, isFirstChild: index == 0, eventStore: eventStore)
                                }
                                // 为每个导航链接添加ID，确保在事件数据更新时视图能正确刷新
                                .id(generateChildEventId(for: childEvent))
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
                        
                        // 发送通知，让所有使用此事件的视图都能刷新
                        NotificationCenter.default.post(
                            name: Notification.Name("EventUpdated"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                    }
                    // 注意：这里不再直接设置activeSheet = nil
                    // 而是先重置showingPreview，让onChange事件处理activeSheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingPreview = false
                    }
                }
            case .framePicker:
                FramePickerView(event: currentEvent, selectedStyle: $selectedFrameStyle, eventStore: eventStore)
            case .backgroundPicker:
                BackgroundPickerView(event: currentEvent, selectedBackground: $selectedFrameBackground, eventStore: eventStore)
            case .editSheet:
                EventEditView(eventStore: eventStore, event: currentEvent)
            case .preview:
                PreviewView(
                    eventStore: eventStore,
                    event: currentEvent,
                    image: selectedImage,
                    frameStyle: selectedFrameStyle,
                    frameBackground: selectedFrameBackground,
                    onDismiss: {
                        // 重置showingPreview状态
                        showingPreview = false
                    }
                )
            case .childEventForm:
                ChildEventFormView(parentEvent: currentEvent, eventStore: eventStore)
            }
        }
        .onChange(of: showingPreview) { newValue in
            if newValue {
                print("showingPreview 变为 true，设置 activeSheet = .preview")
                activeSheet = .preview
            } else {
                // 当showingPreview变为false时，确保状态一致性
                print("showingPreview 变为 false，检查activeSheet状态")
                if activeSheet == .preview {
                    activeSheet = nil
                }
            }
        }
        .onAppear {
            // 加载最新的图片
            if needsImageRefresh {
                loadAndProcessImage()
            }
            
            // 添加通知观察者，用于刷新图片缓存
            NotificationCenter.default.addObserver(forName: Notification.Name("RefreshImageCache"), object: nil, queue: .main) { notification in
                // 检查通知中的事件ID是否与当前事件ID匹配
                if let notificationEventId = notification.userInfo?["eventId"] as? UUID,
                   notificationEventId == self.eventId {
                    print("收到图片缓存刷新通知，eventId: \(notificationEventId)")
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
                   notificationEventId == self.eventId {
                    print("收到事件更新通知，eventId: \(notificationEventId)，当前图片: \(self.currentEvent.imageName ?? "无")")
                    
                    // 由于currentEvent现在是计算属性，会自动从eventStore获取最新数据，无需手动更新
                    self.needsImageRefresh = true
                    self.displayImage = nil
                    
                    // 不需要手动刷新子事件列表，因为childEvents现在是计算属性
                    //self.childEvents = self.eventStore.childEvents(for: self.currentEvent)
                    
                    // 立即重新加载图片
                    DispatchQueue.main.async {
                        self.loadAndProcessImage()
                    }
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: Notification.Name("RefreshImageCache"), object: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name("EventUpdated"), object: nil)
            
            // 清除所有缓存并通知主页刷新
            eventStore.refreshAllCachesAndNotifyHome()
            
            print("详情页关闭，已清除缓存并通知刷新主页")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 当应用从后台回到前台时刷新事件数据
            // 不需要更新currentEvent和childEvents，因为它们是计算属性
            // 只需要刷新图片
            if currentEvent.imageName != nil {
                loadAndProcessImage()
            }
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
                // 事件名称和背景板
                ZStack(alignment: .center) {
                    // 背景板
                    if selectedFrameBackground != .none, let backgroundName = selectedFrameBackground.backgroundImageName {
                        Image(backgroundName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 40)
                            .overlay(
                                // 装饰符号（如果有）
                                Image(systemName: selectedFrameBackground.decorationSymbol)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                                    .padding(.trailing, 180),
                                alignment: .center
                            )
                    } else {
                        // 无背景时的占位视图
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 220, height: 40)
                    }
                    
                    // 事件名称
                    Text(currentEvent.name)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                        .foregroundColor(selectedFrameBackground == .none ? .black : .white)
                        .shadow(color: selectedFrameBackground == .none ? .clear : .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                .padding(.top, 5)
                
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
        // 添加id标识符，确保在事件属性更改时重新创建视图
        .id(generatePhotoViewId(for: currentEvent))
    }
    
    // 加载和处理图片的方法
    private func loadAndProcessImage() {
        // 每次都从eventStore获取最新数据
        let event = currentEvent
        guard let imageName = event.imageName, !imageName.isEmpty else { return }
        
        print("开始加载图片: \(imageName)，事件ID: \(event.id)")
        isImageLoading = true
        
        // 先检查缓存
        if let cachedImage = eventStore.imageCache.getImage(for: imageName, with: event) {
            print("从缓存加载图片: \(imageName)")
            DispatchQueue.main.async {
                self.displayImage = cachedImage
                self.isImageLoading = false
                self.needsImageRefresh = false
            }
            return
        }
        
        // 使用后台线程加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            // 从文档目录加载图片
            if let image = self.loadImageFromDocumentDirectory(named: imageName) {
                print("从文档目录加载图片: \(imageName)")
                
                // 获取最新的事件数据进行处理
                let currentEvent = self.currentEvent
                
                // 检查是否应用相框样式
                var finalImage: UIImage? = nil
                
                if let frameStyleName = currentEvent.frameStyleName,
                   let frameStyle = FrameStyle(rawValue: frameStyleName),
                   frameStyle.usesMaskOrFrame {
                    print("应用相框样式: \(frameStyleName)")
                    finalImage = TemplateImageGenerator.shared.generateTemplateImage(
                        originalImage: image,
                        frameStyle: frameStyle, 
                        scale: currentEvent.imageScale,
                        offset: CGSize(width: currentEvent.imageOffsetX, height: currentEvent.imageOffsetY)
                    )
                } else {
                    // 使用原始图片
                    finalImage = image
                }
                
                // 切换回主线程更新UI
                DispatchQueue.main.async {
                    if let finalImage = finalImage {
                        // 缓存处理后的图片
                        if let imageName = self.currentEvent.imageName {
                            self.eventStore.imageCache.setImage(finalImage, for: imageName, with: self.currentEvent)
                        }
                        self.displayImage = finalImage
                        print("成功加载并显示图片: \(imageName)")
                    }
                    self.isImageLoading = false
                    self.needsImageRefresh = false
                }
            } else {
                // 处理加载失败的情况
                DispatchQueue.main.async {
                    self.isImageLoading = false
                    print("加载图片失败: \(imageName)")
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
    
    // 子事件列表中使用的ID生成辅助方法
    private func generateChildEventId(for event: Event) -> String {
        let baseId = event.id.uuidString
        let nameId = event.name
        let imageId = event.imageName ?? "none"
        let frameId = event.frameStyleName ?? "none"
        let scaleId = String(format: "%.2f", event.imageScale)
        let offsetXId = String(format: "%.0f", event.imageOffsetX)
        let offsetYId = String(format: "%.0f", event.imageOffsetY)
        
        return "\(baseId)-\(nameId)-\(imageId)-\(frameId)-\(scaleId)-\(offsetXId)-\(offsetYId)"
    }
    
    // 照片视图使用的ID生成辅助方法
    private func generatePhotoViewId(for event: Event) -> String {
        let baseId = event.id.uuidString
        let imageId = event.imageName ?? "none"
        let frameId = event.frameStyleName ?? "none"
        let scaleId = String(format: "%.2f", event.imageScale)
        let offsetXId = String(format: "%.0f", event.imageOffsetX)
        let offsetYId = String(format: "%.0f", event.imageOffsetY)
        
        return "\(baseId)-\(imageId)-\(frameId)-\(scaleId)-\(offsetXId)-\(offsetYId)"
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
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        // 移除多余的NavigationView嵌套
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
            // 在取消按钮中调用onDismiss回调
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss?()
            }
        })
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("保存照片"),
                message: Text("确定要保存这张照片吗？"),
                primaryButton: .default(Text("保存")) {
                    // 保存照片和调整信息
                    if let imageName = saveImageWithAdjustments() {
                        print("成功保存图片: \(imageName), 缩放: \(imageScale), 偏移: \(imageOffset)")
                        
                        // 获取最新的事件数据再更新
                        if var updatedEvent = eventStore.getEvent(by: event.id) {
                        updatedEvent.imageName = imageName
                        updatedEvent.imageScale = imageScale
                        updatedEvent.imageOffsetX = imageOffset.width
                        updatedEvent.imageOffsetY = imageOffset.height
                            updatedEvent.frameStyleName = frameStyle.rawValue
                            
                            // 更新事件存储
                        eventStore.updateEvent(updatedEvent)
                            print("update event::\(updatedEvent.id)::\(updatedEvent.imageName ?? "无")")
                            
                            // 发送通知，让所有使用此事件的视图都能刷新
                            NotificationCenter.default.post(
                                name: Notification.Name("EventUpdated"),
                                object: nil,
                                userInfo: [
                                    "eventId": event.id,
                                    "imageName": imageName,
                                    "forceRefresh": true,
                                    "event": updatedEvent
                                ]
                            )
                            
                            // 发送图片缓存刷新通知
                            NotificationCenter.default.post(
                                name: Notification.Name("RefreshImageCache"),
                                object: nil,
                                userInfo: [
                                    "eventId": event.id,
                                    "imageName": imageName,
                                    "event": updatedEvent
                                ]
                            )
                            
                            print("发送事件更新和图片缓存刷新通知")
                            
                            // 强制刷新图片缓存
                            eventStore.imageCache.clearCache()
                        }
                        
                        // 关闭视图
                        presentationMode.wrappedValue.dismiss()
                        // 调用onDismiss回调
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss?()
                        }
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
                    DispatchQueue.main.async {
                        self.parent.onSelect(nil)
                    }
                    return
                }
                
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        print("成功加载图片，尺寸: \(image.size.width) x \(image.size.height)")
                        // 先复位状态变量
                        self.parent.showingPreview = false
                        // 设置图片
                        self.parent.selectedImage = image
                        
                        // 确保图片已经设置后再显示预览
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // 这会触发onChange事件，进而设置activeSheet
                            self.parent.showingPreview = true
                        }
                    }
                } else {
                    print("无法加载图片对象")
                    DispatchQueue.main.async {
                        self.parent.onSelect(nil)
                    }
                }
            }
        }
    }
}

// 头像框选择视图
struct FramePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    var event: Event
    @Binding var selectedStyle: FrameStyle
    @ObservedObject var eventStore: EventStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FrameStyle.allCases) { style in
                    Button(action: {
                        selectedStyle = style
                        
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
                            
                            if selectedStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            selectedStyle == style ?
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
                            _ = eventStore.createChildEvent(parentEvent: parentEvent, name: name, date: date)
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
    @ObservedObject var eventStore: EventStore
    @State private var selectedFrameStyle: FrameStyle = .template
    @State private var showingPhotosPicker = false
    @State private var showingFramePicker = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageName: String? = nil
    @State private var showingPreview = false
    @State private var activeSheet: ActiveSheet? = nil
    @Environment(\.presentationMode) var presentationMode
    @State private var eventId: UUID
    @State private var selectedFrameBackground: FrameBackground = .none
    @State private var showingBackgroundPicker = false
    
    // 添加照片刷新相关状态变量
    @State private var displayImage: UIImage? = nil
    @State private var isImageLoading = false
    @State private var needsImageRefresh = true
    
    // 始终从eventStore获取最新的事件数据
    var currentEvent: Event {
        eventStore.getEvent(by: eventId) ?? event
    }
    
    enum ActiveSheet: Identifiable {
        case photosPicker
        case framePicker
        case editSheet
        case preview
        case backgroundPicker
        case childEventForm
        
        var id: Int {
            switch self {
            case .photosPicker: return 1
            case .framePicker: return 2
            case .editSheet: return 3
            case .preview: return 4
            case .backgroundPicker: return 5
            case .childEventForm: return 6
            }
        }
    }
    
    init(eventStore: EventStore, event: Event) {
        self.event = event
        self.eventStore = eventStore
        self._eventId = State(initialValue: event.id)
        
        // 根据event中保存的frameStyleName设置初始框样式
        if let frameStyleName = event.frameStyleName, let style = FrameStyle(rawValue: frameStyleName) {
            _selectedFrameStyle = State(initialValue: style)
        } else {
            _selectedFrameStyle = State(initialValue: .template)
        }
        
        // 根据event中保存的frameBackgroundName设置初始背景板样式
        if let frameBackgroundName = event.frameBackgroundName, let background = FrameBackground(rawValue: frameBackgroundName) {
            _selectedFrameBackground = State(initialValue: background)
        } else {
            _selectedFrameBackground = State(initialValue: .none)
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
                        
                        // 背景板选择按钮
                        Button(action: {
                            activeSheet = .backgroundPicker
                        }) {
                            HStack {
                                Image(systemName: "rectangle.fill.on.rectangle.fill")
                                    .font(.system(size: 14))
                                Text("更换背景")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple)
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
                        
                        // 发送通知，让所有使用此事件的视图都能刷新
                        NotificationCenter.default.post(
                            name: Notification.Name("EventUpdated"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                    }
                    // 注意：这里不再直接设置activeSheet = nil
                    // 而是先重置showingPreview，让onChange事件处理activeSheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingPreview = false
                    }
                }
            case .framePicker:
                FramePickerView(event: currentEvent, selectedStyle: $selectedFrameStyle, eventStore: eventStore)
            case .backgroundPicker:
                BackgroundPickerView(event: currentEvent, selectedBackground: $selectedFrameBackground, eventStore: eventStore)
            case .editSheet:
                EventEditView(eventStore: eventStore, event: currentEvent)
            case .preview:
                PreviewView(
                    eventStore: eventStore,
                    event: currentEvent,
                    image: selectedImage,
                    frameStyle: selectedFrameStyle,
                    frameBackground: selectedFrameBackground,
                    onDismiss: {
                        // 重置showingPreview状态
                        showingPreview = false
                    }
                )
            case .childEventForm:
                ChildEventFormView(parentEvent: currentEvent, eventStore: eventStore)
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
            } else {
                // 当showingPreview变为false时，确保状态一致性
                print("showingPreview 变为 false，检查activeSheet状态")
                if activeSheet == .preview {
                    activeSheet = nil
                }
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
                    // 不需要手动更新currentEvent，因为它是计算属性
                    // 只需要刷新显示
                    self.needsImageRefresh = true
                    self.loadAndProcessImage()
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self, name: Notification.Name("RefreshImageCache"), object: nil)
            NotificationCenter.default.removeObserver(self, name: Notification.Name("EventUpdated"), object: nil)
            
            // 清除所有缓存并通知主页刷新
            eventStore.refreshAllCachesAndNotifyHome()
            
            print("详情页关闭，已清除缓存并通知刷新主页")
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
                // 事件名称和背景板
                ZStack(alignment: .center) {
                    // 背景板
                    if selectedFrameBackground != .none, let backgroundName = selectedFrameBackground.backgroundImageName {
                        Image(backgroundName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 40)
                            .overlay(
                                // 装饰符号（如果有）
                                Image(systemName: selectedFrameBackground.decorationSymbol)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                                    .padding(.trailing, 180),
                                alignment: .center
                            )
                    } else {
                        // 无背景时的占位视图
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 220, height: 40)
                    }
                    
                    // 事件名称
                    Text(currentEvent.name)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                        .foregroundColor(selectedFrameBackground == .none ? .black : .white)
                        .shadow(color: selectedFrameBackground == .none ? .clear : .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                .padding(.top, 5)
                
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
        // 添加id标识符，确保在事件属性更改时重新创建视图
        .id(generatePhotoViewId(for: currentEvent))
    }
    
    // 加载和处理图片的方法
    private func loadAndProcessImage() {
        // 每次都从eventStore获取最新数据
        let event = currentEvent
        guard let imageName = event.imageName, !imageName.isEmpty else { return }
        
        print("开始加载图片: \(imageName)，事件ID: \(event.id)")
        isImageLoading = true
        
        // 先检查缓存
        if let cachedImage = eventStore.imageCache.getImage(for: imageName, with: event) {
            print("从缓存加载图片: \(imageName)")
            DispatchQueue.main.async {
                self.displayImage = cachedImage
                self.isImageLoading = false
                self.needsImageRefresh = false
            }
            return
        }
        
        // 使用后台线程加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            // 从文档目录加载图片
            if let image = self.loadImageFromDocumentDirectory(named: imageName) {
                print("从文档目录加载图片: \(imageName)")
                
                // 获取最新的事件数据进行处理
                let currentEvent = self.currentEvent
                
                // 检查是否应用相框样式
                var finalImage: UIImage? = nil
                
                if let frameStyleName = currentEvent.frameStyleName,
                   let frameStyle = FrameStyle(rawValue: frameStyleName),
                   frameStyle.usesMaskOrFrame {
                    print("应用相框样式: \(frameStyleName)")
                    finalImage = TemplateImageGenerator.shared.generateTemplateImage(
                        originalImage: image,
                        frameStyle: frameStyle, 
                        scale: currentEvent.imageScale,
                        offset: CGSize(width: currentEvent.imageOffsetX, height: currentEvent.imageOffsetY)
                    )
                } else {
                    // 使用原始图片
                    finalImage = image
                }
                
                // 切换回主线程更新UI
                DispatchQueue.main.async {
                    if let finalImage = finalImage {
                        // 缓存处理后的图片
                        if let imageName = self.currentEvent.imageName {
                            self.eventStore.imageCache.setImage(finalImage, for: imageName, with: self.currentEvent)
                        }
                        self.displayImage = finalImage
                        print("成功加载并显示图片: \(imageName)")
                    }
                    self.isImageLoading = false
                    self.needsImageRefresh = false
                }
            } else {
                // 处理加载失败的情况
                DispatchQueue.main.async {
                    self.isImageLoading = false
                    print("加载图片失败: \(imageName)")
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
    
    // 照片视图使用的ID生成辅助方法
    private func generatePhotoViewId(for event: Event) -> String {
        let baseId = event.id.uuidString
        let imageId = event.imageName ?? "none"
        let frameId = event.frameStyleName ?? "none"
        let scaleId = String(format: "%.2f", event.imageScale)
        let offsetXId = String(format: "%.0f", event.imageOffsetX)
        let offsetYId = String(format: "%.0f", event.imageOffsetY)
        
        return "\(baseId)-\(imageId)-\(frameId)-\(scaleId)-\(offsetXId)-\(offsetYId)"
    }
}

// 子事件卡片组件
struct ChildEventCard: View {
    var childEvent: Event
    var isFirstChild: Bool = false
    @ObservedObject var eventStore: EventStore
    @State private var displayImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧竖线
            VStack {
                if isFirstChild {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 20)
                }
                Circle()
                    .fill(childEvent.isPassed ? Color.gray : childEvent.type.color)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            
            // 右侧事件内容
            VStack(alignment: .leading, spacing: 8) {
                // 显示照片或默认图标
                ZStack {
                    // 背景色
                    RoundedRectangle(cornerRadius: 8)
                        .fill(childEvent.type.color.opacity(0.1))
                        .frame(width: 140, height: 80)
                    
                    // 显示照片或图标
                    if let imageName = childEvent.imageName, !imageName.isEmpty {
                        if let image = displayImage {
                            // 相框效果
                            if let frameStyleName = childEvent.frameStyleName, 
                               let frameStyle = FrameStyle(rawValue: frameStyleName),
                               frameStyle.usesMaskOrFrame {
                                // 使用相框遮罩
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 80)
                            } else {
                                // 普通显示
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 80)
                                    .cornerRadius(8)
                            }
                        } else if isLoading {
                            // 加载中
                            ProgressView()
                                .frame(width: 140, height: 80)
                        } else {
                            // 默认占位符
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(childEvent.type.color)
                                .onAppear {
                                    loadImage(named: imageName)
                                }
                        }
                    } else {
                        // 显示默认图标
                        Image(systemName: childEvent.type.icon)
                            .font(.system(size: 30))
                            .foregroundColor(childEvent.type.color)
                    }
                    
                    // 添加相框装饰元素
                    if let frameStyleName = childEvent.frameStyleName, 
                       let frameStyle = FrameStyle(rawValue: frameStyleName),
                       !frameStyle.usesMaskOrFrame && !frameStyle.decorationSymbols.isEmpty {
                        
                        // 左上角装饰
                        if frameStyle.decorationSymbols.count > 0 {
                            Image(systemName: frameStyle.decorationSymbols[0])
                                .font(.system(size: 16))
                                .foregroundColor(frameStyle.borderColor)
                                .position(x: 25, y: 15)
                        }
                        
                        // 右上角装饰
                        if frameStyle.decorationSymbols.count > 1 {
                            Image(systemName: frameStyle.decorationSymbols[1])
                                .font(.system(size: 16))
                                .foregroundColor(frameStyle.borderColor.opacity(0.7))
                                .position(x: 115, y: 15)
                        }
                        
                        // 左下角装饰
                        if frameStyle.decorationSymbols.count > 2 {
                            Image(systemName: frameStyle.decorationSymbols[2])
                                .font(.system(size: 16))
                                .foregroundColor(frameStyle.borderColor.opacity(0.6))
                                .position(x: 25, y: 65)
                        }
                        
                        // 右下角装饰
                        if frameStyle.decorationSymbols.count > 3 {
                            Image(systemName: frameStyle.decorationSymbols[3])
                                .font(.system(size: 16))
                                .foregroundColor(frameStyle.borderColor.opacity(0.5))
                                .position(x: 115, y: 65)
                        }
                    }
                }
                .frame(width: 140, height: 80)
                .padding(.bottom, 8)
                
                // 事件名称带背景板
                ZStack(alignment: .center) {
                    // 背景板
                    if let backgroundName = childEvent.frameBackgroundName, backgroundName != "无背景", 
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
                                    .padding(.leading, -50),
                                alignment: .center
                            )
                    } else {
                        // 如果没有设置背景或设为"无背景"，则使用事件类型颜色
                        RoundedRectangle(cornerRadius: 4)
                            .fill(childEvent.type.color.opacity(0.15))
                            .frame(height: 30)
                    }
                    
                    // 事件名称
                    Text(childEvent.name)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(childEvent.frameBackgroundName != nil && childEvent.frameBackgroundName != "无背景" ? .white : childEvent.type.color.opacity(0.8))
                        .shadow(color: childEvent.frameBackgroundName != nil && childEvent.frameBackgroundName != "无背景" ? .black.opacity(0.5) : .clear, radius: 1, x: 0, y: 1)
                        .padding(.horizontal, 8)
                }
                .frame(width: 140)
                
                // 显示天数信息
                Text(childEvent.formattedDays)
                    .font(.system(size: 13))
                    .foregroundColor(childEvent.isCountdown ? .green : .orange)
                    .padding(.horizontal, 4)
                
                // 显示日期信息
                Text(childEvent.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .frame(width: 140)
        }
        .frame(height: 150)
        .onAppear {
            // 当子事件卡片出现时，加载图片
            if let imageName = childEvent.imageName {
                loadImage(named: imageName)
            }
        }
        // 监听缓存刷新通知
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("RefreshImageCache"))) { notification in
            // 处理直接针对此事件的通知
            if let eventId = notification.userInfo?["eventId"] as? UUID, eventId == childEvent.id {
                refreshCardImage()
            }
            // 处理全局缓存刷新
            else if notification.userInfo?["clearAllCache"] as? Bool == true {
                refreshCardImage()
            }
        }
        // 监听事件更新通知
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EventUpdated"))) { notification in
            if let eventId = notification.userInfo?["eventId"] as? UUID, eventId == childEvent.id {
                refreshCardImage()
            }
        }
    }
    
    // 刷新卡片图片的辅助方法
    private func refreshCardImage() {
        displayImage = nil
        if let imageName = childEvent.imageName {
            loadImage(named: imageName)
        }
    }
    
    // 加载图片
    private func loadImage(named imageName: String) {
        isLoading = true
        
        // 先检查缓存
        if let cachedImage = eventStore.imageCache.getImage(for: imageName, with: childEvent) {
            self.displayImage = cachedImage
            self.isLoading = false
            return
        }
        
        // 从文档目录加载图片
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = loadImageFromDocumentDirectory(named: imageName) {
                var processedImage: UIImage?
                
                // 处理图片
                if let frameStyleName = childEvent.frameStyleName,
                   let frameStyle = FrameStyle(rawValue: frameStyleName),
                   frameStyle.usesMaskOrFrame {
                    // 使用模板生成器处理图片
                    processedImage = TemplateImageGenerator.shared.generateTemplateImage(
                        originalImage: image,
                        frameStyle: frameStyle,
                        scale: childEvent.imageScale,
                        offset: CGSize(width: childEvent.imageOffsetX, height: childEvent.imageOffsetY)
                    )
                } else {
                    // 简单处理
                    processedImage = image
                }
                
                // 缓存处理后的图片
                if let processedImage = processedImage {
                    eventStore.imageCache.setImage(processedImage, for: imageName, with: childEvent)
                    
                    // 在主线程更新UI
                    DispatchQueue.main.async {
                        self.displayImage = processedImage
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

// 从文档目录加载图片的辅助函数
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

// 子事件编辑视图
struct ChildEventEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var date: Date
    @State private var notes: String
    @State private var showingDeleteAlert = false // 添加删除警告状态
    
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
                
                // 添加删除子事件的区域
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除子事件")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑子事件")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("删除子事件"),
                    message: Text("确定要删除这个子事件吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        // 删除子事件
                        eventStore.deleteChildEvent(childEvent)
                        // 发送通知通知其他视图已删除
                        NotificationCenter.default.post(
                            name: Notification.Name("EventDeleted"),
                            object: nil,
                            userInfo: ["eventId": childEvent.id]
                        )
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }
}

// 添加主事件编辑视图
// 主事件编辑视图
struct EventEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String
    @State private var date: Date
    @State private var notes: String
    @State private var category: String
    @State private var showingCategoryInput = false
    @State private var newCategory = ""
    @State private var reminderEnabled: Bool
    @State private var reminderDate: Date
    @State private var reminderOffset: ReminderOffset
    @State private var notificationSound: NotificationSound
    @State private var vibrationEnabled: Bool
    @State private var selectedType: EventType
    @State private var selectedCalendarType: CalendarType
    @State private var selectedRepeatType: RepeatType
    @State private var birthDate: Date?
    @State private var selectedGender: Gender?
    @State private var showingDeleteAlert = false // 添加删除警告状态
    
    let eventStore: EventStore
    let event: Event
    
    // 添加计算属性来获取所有分类
    private var categories: [String] {
        var result = eventStore.getAllCategories().sorted()
        // 确保"未分类"和"新建分类"存在
        if !result.contains("未分类") {
            result.append("未分类")
        }
        if !result.contains("新建分类") {
            result.append("新建分类")
        }
        return result
    }
    
    init(eventStore: EventStore, event: Event) {
        self.eventStore = eventStore
        self.event = event
        
        // 初始化状态变量
        _name = State(initialValue: event.name)
        _date = State(initialValue: event.date)
        _notes = State(initialValue: event.notes)
        _category = State(initialValue: event.category)
        _reminderEnabled = State(initialValue: event.reminderEnabled)
        _reminderDate = State(initialValue: event.reminderDate ?? Date())
        _reminderOffset = State(initialValue: event.reminderOffset)
        _notificationSound = State(initialValue: event.notificationSound ?? .default)
        _vibrationEnabled = State(initialValue: event.vibrationEnabled)
        _selectedType = State(initialValue: event.type)
        _selectedCalendarType = State(initialValue: event.calendarType ?? .gregorian)
        _selectedRepeatType = State(initialValue: event.repeatType)
        _birthDate = State(initialValue: event.birthDate)
        _selectedGender = State(initialValue: event.gender)
    }
    
    // 添加辅助方法计算提醒日期
    private func calculateReminderDate(for eventDate: Date, with offset: ReminderOffset, at specificTime: Date) -> Date? {
        if offset == .atTime {
            // 使用指定的时间
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: specificTime)
            let minute = calendar.component(.minute, from: specificTime)
            
            if var reminderDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: eventDate) {
                // 如果提醒日期已过，则设为第二天
                if reminderDate < Date() {
                    reminderDate = calendar.date(byAdding: .day, value: 1, to: reminderDate) ?? reminderDate
                }
                return reminderDate
            }
            return nil
        } else {
            // 使用偏移计算提醒时间
            return NotificationManager.shared.calculateReminderDate(eventDate: eventDate, offset: offset)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                    
                    Picker("事件类型", selection: $selectedType) {
                        ForEach(EventType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date])
                    
                    Picker("日历类型", selection: $selectedCalendarType) {
                        ForEach(CalendarType.allCases) { calendarType in
                            HStack {
                                Image(systemName: calendarType.icon)
                                Text(calendarType.rawValue)
                            }.tag(calendarType)
                        }
                    }
                    
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
                        Picker("分类", selection: $category) {
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
                
                // 重复部分移到提醒上方
                Section(header: Text("重复")) {
                    Picker("重复类型", selection: $selectedRepeatType) {
                        ForEach(RepeatType.allCases) { repeatType in
                            Text(repeatType.rawValue).tag(repeatType)
                        }
                    }
                }
                
                if selectedType == .retirement {
                    Section(header: Text("退休信息")) {
                        DatePicker("出生日期", selection: Binding(
                            get: { birthDate ?? Date() },
                            set: { birthDate = $0 }
                        ), displayedComponents: [.date])
                        
                        Picker("性别", selection: Binding(
                            get: { selectedGender ?? .male },
                            set: { selectedGender = $0 }
                        )) {
                            ForEach(Gender.allCases) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                    }
                }
                
                Section(header: Text("提醒")) {
                    Toggle("开启提醒", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        Picker("提醒时间", selection: $reminderOffset) {
                            ForEach(ReminderOffset.allCases) { offset in
                                Text(offset.rawValue).tag(offset)
                            }
                        }
                        
                        if reminderOffset == .atTime {
                            DatePicker("具体时间", selection: $reminderDate, displayedComponents: [.hourAndMinute])
                        }
                        
                        Picker("提醒声音", selection: $notificationSound) {
                            ForEach(NotificationSound.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        
                        Toggle("震动提醒", isOn: $vibrationEnabled)
                    }
                }
                
                Section {
                    Button("保存修改") {
                        if !name.isEmpty {
                            // 更新事件
                            var updatedEvent = event
                            updatedEvent.name = name
                            updatedEvent.date = date
                            updatedEvent.notes = notes
                            updatedEvent.category = category
                            updatedEvent.type = selectedType
                            updatedEvent.calendarType = selectedCalendarType
                            updatedEvent.repeatType = selectedRepeatType
                            updatedEvent.reminderEnabled = reminderEnabled
                            updatedEvent.reminderOffset = reminderOffset
                            updatedEvent.notificationSound = notificationSound
                            updatedEvent.vibrationEnabled = vibrationEnabled
                            
                            // 计算提醒日期
                            if reminderEnabled {
                                updatedEvent.reminderDate = calculateReminderDate(for: date, with: reminderOffset, at: reminderDate)
                            } else {
                                updatedEvent.reminderDate = nil
                            }
                            
                            if selectedType == .retirement {
                                updatedEvent.birthDate = birthDate
                                updatedEvent.gender = selectedGender
                            }
                            
                            eventStore.updateEvent(updatedEvent)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty)
                }
                
                // 添加删除事件的区域
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除事件")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑事件")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("删除事件"),
                    message: Text("确定要删除这个事件吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        // 删除事件
                        eventStore.deleteEvent(event)
                        // 发送通知通知其他视图已删除
                        NotificationCenter.default.post(
                            name: Notification.Name("EventDeleted"),
                            object: nil,
                            userInfo: ["eventId": event.id]
                        )
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }
}

// 背景板选择视图
struct BackgroundPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    var event: Event
    @Binding var selectedBackground: FrameBackground
    @ObservedObject var eventStore: EventStore
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FrameBackground.allCases) { background in
                    Button(action: {
                        selectedBackground = background
                        
                        // 更新Event对象和保存
                        var updatedEvent = event
                        updatedEvent.frameBackgroundName = background.rawValue
                        eventStore.updateEvent(updatedEvent)
                        
                        // 发送通知，通知需要刷新图片缓存
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
                        
                        print("已发送刷新图片缓存通知，事件ID: \(event.id)，背景板样式: \(background.rawValue)")
                        
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            // 预览框
                            ZStack {
                                // 背景色
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(background.backgroundColor)
                                    .frame(width: 100, height: 30)
                                
                                // 如果有背景图片，显示背景图片
                                if background != .none, let backgroundName = background.backgroundImageName {
                                    Image(backgroundName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 30)
                                }
                                
                                // 显示装饰符号
                                if background != .none && !background.decorationSymbol.isEmpty {
                                    Image(systemName: background.decorationSymbol)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .opacity(0.8)
                                        .position(x: 20, y: 15)
                                }
                                
                                // 示例文本
                                Text("示例名称")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(background == .none ? .black : .white)
                                    .shadow(color: background == .none ? .clear : .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            }
                            .frame(width: 100, height: 30)
                            .clipped()
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(background.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                
                                // 添加简短描述
                                Text(background == .none ? "无背景样式" : "背景面板样式")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            if selectedBackground == background {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(.vertical, 8)
                        .background(
                            selectedBackground == background ?
                                RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                : nil
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("选择背景板样式")
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// 添加预览视图
struct PreviewView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let eventStore: EventStore
    let event: Event
    let image: UIImage?
    let frameStyle: FrameStyle
    let frameBackground: FrameBackground
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            PhotoPreviewView(
                image: image ?? UIImage(),
                event: event,
                eventStore: eventStore,
                frameStyle: frameStyle,
                onDismiss: onDismiss
            )
        }
    }
}

#Preview {
    NavigationView {
        EventDetailView(eventStore: EventStore(), event: Event.samples[0])
    }
}

#Preview {
    NavigationView {
        ChildEventDetailView(eventStore: EventStore(), event: Event.samples[0])
    }
}
