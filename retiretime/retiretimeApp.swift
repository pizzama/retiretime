//
//  retiretimeApp.swift
//  retiretime
//
//  Created by Trae AI on 2025/3/5.
//

import SwiftUI
import WidgetKit
import UserNotifications

@main
struct retiretimeApp: App {
    // 创建EventStore实例
    @StateObject private var eventStore = EventStore()
    
    init() {
        // 注册通知类别
        registerNotificationCategories()
        
        // 请求通知权限
        NotificationManager.shared.requestAuthorization()
        
        // 添加调试信息，检查通知权限状态
        print("初始化应用，检查通知权限状态")
        NotificationManager.shared.checkAuthorizationStatus()
        
        // 刷新所有Widget，确保应用启动时Widget数据同步
        WidgetCenter.shared.reloadAllTimelines()
        print("应用启动时刷新所有Widget")
        
        // 延迟检查权限状态，确保有足够时间处理授权请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("延迟检查通知权限状态: \(NotificationManager.shared.isAuthorized ? "已授权" : "未授权")")
            
            // 如果已授权，列出所有待处理的通知
            if NotificationManager.shared.isAuthorized {
                NotificationManager.shared.listPendingNotifications()
            } else {
                // 如果未授权，再次尝试请求权限
                print("通知未授权，再次尝试请求权限")
                NotificationManager.shared.requestAuthorization()
            }
        }
    }
    
    // 注册通知类别
    private func registerNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // 设置通知中心代理
        // NotificationManager已在其初始化方法中设置为代理
        
        // 创建通知动作
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "查看详情",
            options: .foreground
        )
        
        // 创建通知类别
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // 注册通知类别
        center.setNotificationCategories([eventCategory])
        print("已注册通知类别")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventStore)
                .withWidgetPrompt() // 添加Widget提示修饰器
                .onAppear {
                    // 应用每次出现时检查通知权限
                    NotificationManager.shared.checkAuthorizationStatus()
                    print("应用出现，通知权限状态: \(NotificationManager.shared.isAuthorized ? "已授权" : "未授权")")
                    
                    // 重置应用图标上的通知徽章
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    print("已重置应用图标通知徽章")
                    
                    // 如果已授权，列出所有待处理的通知
                    if NotificationManager.shared.isAuthorized {
                        NotificationManager.shared.listPendingNotifications()
                    }
                    
                    // 检查是否需要提示用户安装Widget
                    WidgetPromptManager.shared.checkAndShowWidgetPrompt()
                }
                .onOpenURL { url in
                    // 处理从Widget点击打开应用的URL
                    print("收到URL: \(url)")
                    
                    // 解析URL，格式为：retiretime://event/{eventId}
                    if url.scheme == "retiretime" && url.host == "event" {
                        let pathComponents = url.pathComponents
                        if pathComponents.count > 1 {
                            let eventIdString = pathComponents[1]
                            if let eventId = UUID(uuidString: eventIdString),
                               let event = eventStore.events.first(where: { $0.id == eventId }) {
                                // 这里可以添加导航到特定事件详情页的逻辑
                                print("准备打开事件详情: \(event.name)")
                                // 在实际应用中，你需要通过环境变量或其他方式通知ContentView打开特定事件
                            }
                        }
                    }
                }
        }
    }
}
