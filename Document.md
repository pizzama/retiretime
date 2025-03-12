# RetireTime - 倒计时应用

## 项目概述

RetireTime是一款iOS倒计时应用，帮助用户记录和追踪重要的日子，如生日、纪念日、倒计时事件等。用户可以通过该应用清晰地了解距离重要日子还有多少天，从而更好地进行时间管理和生活规划。

## 功能特点

- **创建日子/事件**：用户可以自定义添加不同类型的日子或事件
- **多种日历支持**：支持公历、农历、伊斯兰教历、犹太教历、藏历、印度历等多种日历系统
- **重复设置**：支持不重复、每天、每周、每月、每年等多种重复模式
- **通知提醒**：支持在特定日期或提前一段时间进行提醒
- **小组件支持**：提供iOS小组件功能，方便用户在主屏幕查看倒计时
- **自定义显示**：允许用户自定义日子的显示样式

## 项目结构
```
retiretime/
├── Models/ # 数据模型
│ ├── Event.swift # 事件模型
│ └── NotificationTypes.swift # 通知类型定义
├── Views/ # 视图组件
│ ├── EventDetailView.swift # 事件详情视图
│ ├── EventFormView.swift # 事件表单视图
│ └── EventListView.swift # 事件列表视图
├── Services/ # 服务组件
│ ├── EventStore.swift # 事件存储服务
│ ├── NotificationManager.swift # 通知管理服务
│ └── WidgetPromptManager.swift # 小组件提示管理
├── Theme/ # 主题相关
├── Assets.xcassets/ # 资源文件
└── retiretimeApp.swift # 应用入口文件
widgets/ # 小组件功能
├── widgets.swift # 小组件实现
├── widgetsBundle.swift # 小组件包
└── Event.swift # 小组件使用的事件模型
```

## 技术特点

- 使用SwiftUI构建现代化的用户界面
- 采用MVVM架构模式
- 使用UserDefaults和App Group实现应用与小组件之间的数据共享
- 集成iOS通知系统，提供丰富的提醒功能
- 支持WidgetKit，提供主屏幕小组件功能

## 系统要求

- iOS 14.0或更高版本
- Xcode 12.0或更高版本
- Swift 5.3或更高版本

## 安装与使用

1. 克隆或下载项目代码
2. 使用Xcode打开`retiretime.xcodeproj`项目文件
3. 选择目标设备或模拟器
4. 构建并运行应用

## 开发者信息

- 开发者：孙彬
- 版本：1.0
- 创建日期：2025-03-05

## 许可证

[待添加许可证信息]
