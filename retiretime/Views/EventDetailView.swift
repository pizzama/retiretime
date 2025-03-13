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
    case classic = "经典"
    case modern = "现代"
    case vintage = "复古"
    case colorful = "彩色"
    case minimal = "简约"
    case template = "模板"
    case mask = "蒙版"
    case imageFrame = "相框"
    case circleFrame = "圆形"
    case heartFrame = "心形"
    case flowerFrame = "花朵"
    case starFrame = "星形"
    
    var id: String { self.rawValue }
    
    // 返回对应的边框颜色
    var borderColor: Color {
        switch self {
        case .classic: return .gray
        case .modern: return .blue
        case .vintage: return .brown
        case .colorful: return .purple
        case .minimal: return .black
        case .template: return .green
        case .mask: return .orange
        case .imageFrame: return .pink
        case .circleFrame: return .red
        case .heartFrame: return .pink
        case .flowerFrame: return Color(red: 1.0, green: 0.6, blue: 0.6)
        case .starFrame: return .yellow
        }
    }
    
    // 返回对应的装饰元素
    var decorationSymbols: [String] {
        switch self {
        case .classic: return ["star.fill", "heart.fill", "moon.stars.fill", "leaf.fill"]
        case .modern: return ["circle.fill", "square.fill", "triangle.fill", "diamond.fill"]
        case .vintage: return ["camera.fill", "clock.fill", "book.fill", "seal.fill"]
        case .colorful: return ["sun.max.fill", "cloud.fill", "bolt.fill", "flame.fill"]
        case .minimal: return []
        case .template: return ["sparkles", "wand.and.stars", "gift", "party.popper"]
        case .mask: return ["person.crop.circle", "person.crop.square", "heart", "star"]
        case .imageFrame: return ["photo.on.rectangle", "photo.artframe", "photo.stack", "photo.tv"]
        case .circleFrame: return ["circle", "circle.fill", "circle.dotted", "circle.dashed"]
        case .heartFrame: return ["heart", "heart.fill", "heart.circle", "heart.square"]
        case .flowerFrame: return ["leaf", "leaf.fill", "leaf.circle", "leaf.arrow.triangle.circlepath"]
        case .starFrame: return ["star", "star.fill", "star.circle", "star.square"]
        }
    }
    
    // 返回对应的背景渐变色
    func backgroundGradient() -> LinearGradient {
        switch self {
        case .classic:
            return LinearGradient(
                gradient: Gradient(colors: [Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .modern:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .vintage:
            return LinearGradient(
                gradient: Gradient(colors: [Color.brown.opacity(0.1), Color.yellow.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .colorful:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimal:
            return LinearGradient(
                gradient: Gradient(colors: [Color.white]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .template:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mask:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .imageFrame:
            return LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .circleFrame:
            return LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.1), Color.orange.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .heartFrame:
            return LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.red.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .flowerFrame:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.6).opacity(0.1), Color(red: 1.0, green: 0.8, blue: 0.8).opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .starFrame:
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
        case .mask:
            return "mask_circle" // 圆形蒙版
        case .imageFrame:
            return "frame_polaroid" // 拍立得相框
        case .circleFrame:
            return "mask_circle" // 圆形蒙版
        case .heartFrame:
            return "mask_heart" // 心形蒙版
        case .flowerFrame:
            return "flower_frame" // 花朵相框
        case .starFrame:
            return "mask_star" // 星形蒙版
        default:
            return nil
        }
    }
    
    // 判断是否使用蒙版或相框
    var usesMaskOrFrame: Bool {
        return self == .mask || self == .imageFrame || self == .circleFrame || self == .heartFrame || self == .flowerFrame || self == .starFrame
    }
}

struct EventDetailView: View {
    let event: Event
    @State private var selectedFrameStyle: FrameStyle = .template
    @State private var selectedTemplateType: DecorationType = .polaroid
    @State private var showingEditSheet = false
    @State private var showingPhotosPicker = false
    @State private var showingFramePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageName: String? = nil
    let eventStore: EventStore
    
    init(event: Event, eventStore: EventStore) {
        self.event = event
        self.eventStore = eventStore
        
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
                    // 相框效果
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
                        
                        // 拍立得照片
                        ZStack(alignment: .bottom) {
                            // 照片部分
                            ZStack {
                                if let imageName = event.imageName, !imageName.isEmpty {
                                    // 从文档目录加载图片
                                    if let image = loadImageFromDocumentDirectory(named: imageName) {
                                        // 使用TemplateImageGenerator处理图片
                                        if selectedFrameStyle.usesMaskOrFrame {
                                            if let processedImage = TemplateImageGenerator.shared.generateTemplateImage(
                                                originalImage: image,
                                                frameStyle: selectedFrameStyle
                                            ) {
                                                Image(uiImage: processedImage)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 240, height: 240)
                                            } else {
                                                // 如果处理失败，显示原始图片
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 240, height: 240)
                                                    .clipped()
                                                    .overlay(
                                                        Text("相框处理失败")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.opacity(0.7))
                                                    )
                                            }
                                        } else {
                                            // 使用普通样式
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 240, height: 240)
                                                .clipped()
                                        }
                                    } else {
                                        // 如果无法加载图片，显示默认图标背景
                                        Rectangle()
                                            .fill(event.type.color.opacity(0.1))
                                            .frame(width: 240, height: 240)
                                        
                                        Image(systemName: event.type.icon)
                                            .font(.system(size: 80))
                                            .foregroundColor(event.type.color)
                                    }
                                } else {
                                    // 默认图标背景
                                    Rectangle()
                                        .fill(event.type.color.opacity(0.1))
                                        .frame(width: 240, height: 240)
                                    
                                    Image(systemName: event.type.icon)
                                        .font(.system(size: 80))
                                        .foregroundColor(event.type.color)
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
                                
                                // 剩余/已过天数 - 使用手写风格标签
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
                        
                        // 根据选择的框样式添加装饰元素
                        if selectedFrameStyle != .minimal && !selectedFrameStyle.usesMaskOrFrame {
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
                        }
                        
                        // 装饰元素 - 顶部中间
                        if event.type == .retirement && selectedFrameStyle != .minimal && !selectedFrameStyle.usesMaskOrFrame {
                            Image(systemName: "party.popper.fill")
                                .foregroundColor(selectedFrameStyle.borderColor.opacity(0.8))
                                .font(.system(size: 18))
                                .position(x: 130, y: 20)
                        }
                        
                        // 装饰元素 - 底部中间
                        if selectedFrameStyle != .minimal && !selectedFrameStyle.usesMaskOrFrame {
                            if event.isCountdown {
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
                        }
                        
                        // 装饰线条 - 顶部
                        if selectedFrameStyle != .minimal && !selectedFrameStyle.usesMaskOrFrame {
                            Path { path in
                                path.move(to: CGPoint(x: 45, y: 20))
                                path.addLine(to: CGPoint(x: 225, y: 20))
                            }
                            .stroke(selectedFrameStyle.borderColor.opacity(0.4), lineWidth: 1)
                        }
                        
                        // 装饰线条 - 底部
                        if selectedFrameStyle != .minimal && !selectedFrameStyle.usesMaskOrFrame {
                            Path { path in
                                path.move(to: CGPoint(x: 45, y: 330))
                                path.addLine(to: CGPoint(x: 225, y: 330))
                            }
                            .stroke(selectedFrameStyle.borderColor.opacity(0.4), lineWidth: 1)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 日期信息
                    Text(event.formattedDate)
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .rotationEffect(.degrees(-3))
                        .padding(.trailing, 20)
                    
                    // 按钮行
                    HStack(spacing: 16) {
                        // 照片选择按钮
                        Button(action: {
                            showingPhotosPicker = true
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
                            showingFramePicker = true
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
                    DetailRow(title: "类型", value: event.type.rawValue, icon: "tag")
                    
                    // 分类
                    DetailRow(title: "分类", value: event.category, icon: "folder")
                    
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
        .sheet(isPresented: $showingPhotosPicker) {
            PhotoPicker(selectedImage: $selectedImage, selectedImageName: $selectedImageName) { imageName in
                if let imageName = imageName {
                    // 更新事件的照片
                    var updatedEvent = event
                    updatedEvent.imageName = imageName
                    eventStore.updateEvent(updatedEvent)
                }
            }
        }
        .sheet(isPresented: $showingFramePicker) {
            FramePickerView(selectedFrameStyle: $selectedFrameStyle, event: event, eventStore: eventStore)
        }
    }
    
    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
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

// 照片选择器
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageName: String?
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
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                        
                        // 保存图片到应用文档目录
                        if let imageName = self.saveImage(image) {
                            self.parent.selectedImageName = imageName
                            self.parent.onSelect(imageName)
                        } else {
                            self.parent.onSelect(nil)
                        }
                    }
                } else {
                    self.parent.onSelect(nil)
                }
            }
        }
        
        private func saveImage(_ image: UIImage) -> String? {
            let imageName = "event_image_\(UUID().uuidString).jpg"
            
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
                  let imageData = image.jpegData(compressionQuality: 0.8) else {
                return nil
            }
            
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            
            do {
                try imageData.write(to: fileURL)
                return imageName
            } catch {
                print("保存图片失败: \(error)")
                return nil
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
                        try? eventStore.updateEvent(updatedEvent)
                        
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            // 预览框
                            RoundedRectangle(cornerRadius: 8)
                                .fill(style.backgroundGradient())
                                .frame(width: 60, height: 60)
                                .overlay(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(style.borderColor.opacity(0.5), lineWidth: 2)
                                        
                                        // 如果是蒙版或相框样式，显示预览图标
                                        if style.usesMaskOrFrame {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                                .foregroundColor(style.borderColor)
                                        }
                                    }
                                )
                            
                            Text(style.rawValue)
                                .font(.headline)
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            if selectedFrameStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
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
    case vintage = "复古"
    case modern = "现代"
    
    var id: String { self.rawValue }
}

#Preview {
    NavigationView {
        EventDetailView(event: Event.samples[0], eventStore: EventStore())
    }
}
