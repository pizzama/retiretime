//
//  WidgetPromptManager.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI
import WidgetKit

class WidgetPromptManager: ObservableObject {
    static let shared = WidgetPromptManager()
    
    // 用于控制提示弹窗的显示状态
    @Published var showWidgetPrompt = false
    
    // UserDefaults键
    private let hasPromptedWidgetKey = "hasPromptedWidget"
    private let doNotShowWidgetPromptKey = "doNotShowWidgetPrompt"
    
    private init() {}
    
    // 检查是否应该显示Widget提示
    func checkAndShowWidgetPrompt() {
        // 如果用户选择了不再提示，则不显示
        if UserDefaults.standard.bool(forKey: doNotShowWidgetPromptKey) {
            return
        }
        
        // 如果已经提示过，但没有选择不再提示，则在一周后再次提示
        if let lastPromptDate = UserDefaults.standard.object(forKey: hasPromptedWidgetKey) as? Date {
            let calendar = Calendar.current
            if let oneWeekLater = calendar.date(byAdding: .day, value: 7, to: lastPromptDate),
               Date() < oneWeekLater {
                return
            }
        }
        
        // 检查是否已安装Widget
        if !isWidgetInstalled() {
            // 更新最后提示时间
            UserDefaults.standard.set(Date(), forKey: hasPromptedWidgetKey)
            
            // 显示提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.showWidgetPrompt = true
            }
        }
    }
    
    // 检查Widget是否已安装（通过WidgetCenter API无法直接检查，这里使用一个模拟方法）
    private func isWidgetInstalled() -> Bool {
        // 由于iOS不提供直接检查Widget是否已安装的API，
        // 我们可以通过UserDefaults存储一个标志来模拟用户是否已添加Widget
        return UserDefaults.standard.bool(forKey: "widgetInstalled")
    }
    
    // 用户确认已安装Widget
    func markWidgetAsInstalled() {
        UserDefaults.standard.set(true, forKey: "widgetInstalled")
        showWidgetPrompt = false
    }
    
    // 用户选择不再提示
    func doNotShowAgain() {
        UserDefaults.standard.set(true, forKey: doNotShowWidgetPromptKey)
        showWidgetPrompt = false
    }
    
    // 用户选择稍后提示
    func remindLater() {
        // 设置24小时后再次提示
        UserDefaults.standard.set(Date(), forKey: hasPromptedWidgetKey)
        showWidgetPrompt = false
        
        print("用户选择稍后提示，将在24小时后再次显示提示")
    }
}

// Widget提示弹窗视图
struct WidgetPromptView: View {
    @ObservedObject private var promptManager = WidgetPromptManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("添加退休时间小组件")
                .font(.headline)
                .padding(.top)
            
            // 图标
            Image(systemName: "square.grid.2x2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
                .padding()
            
            // 说明文字
            Text("将退休时间小组件添加到主屏幕，随时查看重要日期倒计时！")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 安装步骤
            VStack(alignment: .leading, spacing: 10) {
                Text("安装步骤：")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                HStack(alignment: .top) {
                    Text("1.")
                    Text("长按主屏幕空白处或任意应用图标")
                }
                
                HStack(alignment: .top) {
                    Text("2.")
                    Text("点击左上角的\"+\"号")
                }
                
                HStack(alignment: .top) {
                    Text("3.")
                    Text("搜索\"退休时间\"并添加小组件")
                }
            }
            .padding(.horizontal)
            
            // 按钮区域
            HStack(spacing: 15) {
                Button(action: {
                    promptManager.doNotShowAgain()
                }) {
                    Text("不再提示")
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    promptManager.remindLater()
                }) {
                    Text("稍后提示")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    promptManager.markWidgetAsInstalled()
                }) {
                    Text("已添加")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom)
        }
        .frame(width: 300)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

// 用于在ContentView中显示Widget提示的修饰器
struct WidgetPromptModifier: ViewModifier {
    @ObservedObject private var promptManager = WidgetPromptManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if promptManager.showWidgetPrompt {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // 点击背景关闭提示
                        promptManager.remindLater()
                    }
                
                WidgetPromptView()
                    .transition(.scale)
            }
        }
        .animation(.easeInOut, value: promptManager.showWidgetPrompt)
    }
}

// 扩展View以便于使用Widget提示修饰器
extension View {
    func withWidgetPrompt() -> some View {
        self.modifier(WidgetPromptModifier())
    }
}