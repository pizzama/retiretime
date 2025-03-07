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
                }
        }
    }
}
