//
//  EventDetailView.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI
import PhotosUI

struct EventDetailView: View {
    // 使用ID而不是直接存储event对象
    let eventId: UUID
    @ObservedObject var eventStore: EventStore
    @State private var showingEditSheet = false
    @State private var showingPhotosPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedImageName: String?
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
                            
                            // 倒计时日期 - 左下角
                            VStack {
                                Spacer()
                                HStack {
                                    Text(event.daysRemaining == 0 ? "今天" : "\(abs(event.daysRemaining))天")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(event.isCountdown ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                                        .cornerRadius(8)
                                        .padding(12)
                                    Spacer()
                                }
                            }
                        }
                        .frame(width: 240, height: 240)
                        
                        // 拍立得白底部分
                        VStack(spacing: 4) {
                            // 事件名称
                            Text(event.name)
                                .font(.system(size: 20, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 10)
                                .padding(.top, 8)
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
                            
//                            Spacer()
                            // 剩余/已过天数
                            HStack(spacing: 8) {
                                Text(event.daysRemaining == 0 ? "今天" : (event.isCountdown ? "倒计时" : "已过"))
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                        
                                Text(event.daysRemaining == 0 ? "今天" : "\(abs(event.daysRemaining))天")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(event.isCountdown ? .green : .orange)
                            }
                        }
                        .frame(width: 240, height: 70)
                        .background(Color.white)

                    }
                    .frame(width: 240, height: 310)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.top, 20)
                    
                    // 日期信息
                    Text(event.formattedDate)
                        .font(.custom("Noteworthy", size: 16)) // 使用手写风格字体
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.trailing, 20) // 向左偏移一点，增强手写感
                    
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

#Preview {
    NavigationView {
        EventDetailView(eventId: Event.samples[0].id, eventStore: EventStore())
    }
}
