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
    
    var id: String { self.rawValue }
    
    // 返回对应的边框颜色
    var borderColor: Color {
        switch self {
        case .classic: return .gray
        case .modern: return .blue
        case .vintage: return .brown
        case .colorful: return .purple
        case .minimal: return .black
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
        }
    }
}

struct EventDetailView: View {
    // 使用ID而不是直接存储event对象
    let eventId: UUID
    @ObservedObject var eventStore: EventStore
    @State private var showingEditSheet = false
    @State private var showingPhotosPicker = false
    @State private var showingFramePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedImageName: String?
    @State private var selectedFrameStyle: FrameStyle = .classic
    @Environment(\.presentationMode) var presentationMode
    
    // 计算属性，每次访问时都会从eventStore获取最新的event
    var event: Event {
        eventStore.events.first { $0.id == eventId }!
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
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 240, height: 240)
                                            .clipped()
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
                            .padding(.bottom, 30)
                            
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
                        .frame(width: 240, height: 320)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .rotationEffect(.degrees(2))
                        
                        // 根据选择的框样式添加装饰元素
                        if selectedFrameStyle != .minimal {
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
                        if event.type == .retirement && selectedFrameStyle != .minimal {
                            Image(systemName: "party.popper.fill")
                                .foregroundColor(selectedFrameStyle.borderColor.opacity(0.8))
                                .font(.system(size: 18))
                                .position(x: 130, y: 20)
                        }
                        
                        // 装饰元素 - 底部中间
                        if selectedFrameStyle != .minimal {
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
                        if selectedFrameStyle != .minimal {
                            Path { path in
                                path.move(to: CGPoint(x: 45, y: 20))
                                path.addLine(to: CGPoint(x: 225, y: 20))
                            }
                            .stroke(selectedFrameStyle.borderColor.opacity(0.4), lineWidth: 1)
                        }
                        
                        // 装饰线条 - 底部
                        if selectedFrameStyle != .minimal {
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
            FramePickerView(selectedFrameStyle: $selectedFrameStyle)
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
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FrameStyle.allCases) { style in
                    Button(action: {
                        selectedFrameStyle = style
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            // 预览框
                            RoundedRectangle(cornerRadius: 8)
                                .fill(style.backgroundGradient())
                                .frame(width: 60, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(style.borderColor.opacity(0.5), lineWidth: 2)
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

#Preview {
    NavigationView {
        EventDetailView(eventId: Event.samples[0].id, eventStore: EventStore())
    }
}
