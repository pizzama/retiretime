//
//  retiretimeApp.swift
//  retiretime
//
//  Created by pizzaman on 2025/3/5.
//

import SwiftUI

@main
struct retiretimeApp: App {
    // 创建EventStore实例
    @StateObject private var eventStore = EventStore()
    
    init() {
        // 请求通知权限
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventStore)
        }
    }
}
