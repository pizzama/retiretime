//
//  TemplateImageGenerator.swift
//  retiretime
//
//  Created by AI on 2025/3/13.
//

import UIKit
import SwiftUI

// 用于解析JSON的结构体
struct FrameDescription: Codable {
    let name: String
    let type: String
    let description: String
    let paths: [PathDescription]
}

struct PathDescription: Codable {
    let type: String
    let points: [PointDescription]?
    let center: PointDescription?
    let radius: CGFloat?
    let color: String
    let rotation: CGFloat?
}

struct PointDescription: Codable {
    let x: CGFloat
    let y: CGFloat
}

class TemplateImageGenerator {
    static let shared = TemplateImageGenerator()
    
    private init() {}
    
    // 使用蒙版生成图片
    func generateMaskedImage(originalImage: UIImage, maskName: String) -> UIImage? {
        guard let maskImage = UIImage(named: maskName) else {
            print("无法加载蒙版图片: \(maskName)")
            return nil
        }
        
        // 打印蒙版图片信息以便调试
        print("蒙版图片尺寸: \(maskImage.size), 比例: \(maskImage.scale)")
        
        // 创建一个与蒙版大小相同的上下文
        UIGraphicsBeginImageContextWithOptions(maskImage.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制原始图片，缩放以适应蒙版大小
        let rect = CGRect(origin: .zero, size: maskImage.size)
        originalImage.draw(in: rect)
        
        // 获取绘制的图片
        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        // 创建蒙版
        guard let maskRef = maskImage.cgImage,
              let drawnRef = drawnImage.cgImage,
              let mask = CGImage(
                maskWidth: maskRef.width,
                height: maskRef.height,
                bitsPerComponent: maskRef.bitsPerComponent,
                bitsPerPixel: maskRef.bitsPerPixel,
                bytesPerRow: maskRef.bytesPerRow,
                provider: maskRef.dataProvider!,
                decode: nil,
                shouldInterpolate: false) else {
            print("无法创建蒙版CGImage")
            return nil
        }
        
        // 应用蒙版
        guard let maskedRef = drawnRef.masking(mask) else {
            print("无法应用蒙版到图片")
            return nil
        }
        
        // 创建最终图片
        let maskedImage = UIImage(cgImage: maskedRef)
        
        // 如果是花朵或特殊形状，可以添加额外的装饰效果
        if maskName == "flower_frame" || maskName == "mask_heart" || maskName == "mask_star" {
            UIGraphicsBeginImageContextWithOptions(maskedImage.size, false, 0.0)
            defer { UIGraphicsEndImageContext() }
            
            // 绘制蒙版后的图片
            maskedImage.draw(in: rect)
            
            // 绘制原始蒙版图片作为边框
            maskImage.draw(in: rect, blendMode: .normal, alpha: 0.5)
            
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        
        return maskedImage
    }
    
    // 使用相框生成图片
    func generateFramedImage(originalImage: UIImage, frameName: String) -> UIImage? {
        // 首先尝试加载预定义的相框图片
        if let frameImage = UIImage(named: frameName) {
            print("加载相框图片: \(frameName), 尺寸: \(frameImage.size)")
            
            // 创建一个与相框大小相同的上下文
            UIGraphicsBeginImageContextWithOptions(frameImage.size, false, 0.0)
            defer { UIGraphicsEndImageContext() }
            
            // 计算照片在相框中的位置和大小
            let photoRect = calculatePhotoRect(frameSize: frameImage.size, frameName: frameName)
            print("照片区域: \(photoRect)")
            
            // 为特殊形状创建路径
            if frameName == "flower_frame" || frameName == "mask_heart" || frameName == "mask_star" {
                print("开始处理特殊形状相框: \(frameName)")
                
                // 对于花朵框架，确保显示整个框架
                if frameName == "flower_frame" {
                    // 首先绘制照片到计算好的区域（不裁剪）
                    originalImage.draw(in: photoRect, blendMode: .normal, alpha: 1.0)
                    
                    // 然后以原始尺寸叠加相框
                    let frameRect = CGRect(origin: .zero, size: frameImage.size)
                    frameImage.draw(in: frameRect, blendMode: .normal, alpha: 1.0)
                    
                    // 获取最终结果
                    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                    print("花朵相框处理完成")
                    return finalImage
                } else {
                    // 其他特殊形状的处理
                    // 首先绘制照片到整个区域（不裁剪）
                    originalImage.draw(in: photoRect, blendMode: .normal, alpha: 1.0)
                    
                    // 然后叠加相框
                    frameImage.draw(in: CGRect(origin: .zero, size: frameImage.size), blendMode: .normal, alpha: 1.0)
                    
                    // 获取最终结果
                    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                    print("特殊形状相框处理完成")
                    return finalImage
                }
            } else {
                // 普通相框处理
                // 绘制原始图片到相框中央的透明区域
                originalImage.draw(in: photoRect, blendMode: .normal, alpha: 1.0)
                
                // 绘制相框覆盖在照片上
                frameImage.draw(in: CGRect(origin: .zero, size: frameImage.size), blendMode: .normal, alpha: 1.0)
                
                // 获取最终图片
                return UIGraphicsGetImageFromCurrentImageContext()
            }
        }
        
        // 如果没有预定义的相框图片，尝试从JSON生成
        return generateFrameFromJSON(originalImage: originalImage, jsonName: frameName)
    }
    
    // 从JSON生成相框图片
    private func generateFrameFromJSON(originalImage: UIImage, jsonName: String) -> UIImage? {
        guard let frameDescription = loadFrameDescription(jsonName: jsonName) else {
            return nil
        }
        
        // 创建一个与原始图片大小相同的上下文
        let size = CGSize(width: 500, height: 500) // 使用固定大小，可以根据需要调整
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制原始图片到中央
        let photoSize = CGSize(width: size.width * 0.6, height: size.height * 0.6)
        let photoRect = CGRect(
            x: (size.width - photoSize.width) / 2,
            y: (size.height - photoSize.height) / 2,
            width: photoSize.width,
            height: photoSize.height
        )
        originalImage.draw(in: photoRect)
        
        // 绘制相框路径
        let context = UIGraphicsGetCurrentContext()
        
        for path in frameDescription.paths {
            drawPath(path: path, in: context!, size: size)
        }
        
        // 获取最终图片
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // 加载JSON描述
    private func loadFrameDescription(jsonName: String) -> FrameDescription? {
        guard let url = Bundle.main.url(forResource: jsonName, withExtension: "json") else {
            print("无法找到JSON文件: \(jsonName).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(FrameDescription.self, from: data)
        } catch {
            print("解析JSON文件失败: \(error)")
            return nil
        }
    }
    
    // 绘制路径
    private func drawPath(path: PathDescription, in context: CGContext, size: CGSize) {
        // 设置颜色
        let color = UIColor(hex: path.color) ?? .black
        context.setFillColor(color.cgColor)
        context.setStrokeColor(color.cgColor)
        
        // 根据路径类型绘制不同的形状
        switch path.type {
        case "circle":
            if let center = path.center, let radius = path.radius {
                let centerPoint = CGPoint(x: center.x * size.width, y: center.y * size.height)
                let radiusValue = radius * min(size.width, size.height)
                
                context.addArc(
                    center: centerPoint,
                    radius: radiusValue,
                    startAngle: 0,
                    endAngle: 2 * .pi,
                    clockwise: false
                )
                context.fillPath()
            }
            
        case "petal":
            if let points = path.points, points.count >= 3, let rotation = path.rotation {
                // 创建贝塞尔曲线
                let bezierPath = UIBezierPath()
                
                // 转换点坐标
                let transformedPoints = points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                
                // 移动到第一个点
                bezierPath.move(to: transformedPoints[0])
                
                // 添加曲线
                bezierPath.addQuadCurve(to: transformedPoints[2], controlPoint: transformedPoints[1])
                
                // 应用旋转变换
                let rotationTransform = CGAffineTransform(rotationAngle: rotation * .pi / 180)
                let translationTransform = CGAffineTransform(translationX: size.width / 2, y: size.height / 2)
                let reverseTranslationTransform = CGAffineTransform(translationX: -size.width / 2, y: -size.height / 2)
                
                bezierPath.apply(reverseTranslationTransform)
                bezierPath.apply(rotationTransform)
                bezierPath.apply(translationTransform)
                
                // 绘制路径
                context.addPath(bezierPath.cgPath)
                context.fillPath()
            }
            
        default:
            print("未知的路径类型: \(path.type)")
        }
    }
    
    // 计算照片在相框中的位置和大小
    private func calculatePhotoRect(frameSize: CGSize, frameName: String) -> CGRect {
        // 根据不同的相框类型返回不同的照片区域
        switch frameName {
        case "flower_frame":
            // 花朵相框中间的空白区域
            let diameter = min(frameSize.width, frameSize.height) * 0.6  // 调整为原来的0.6倍，让照片更小一些
            let x = (frameSize.width - diameter) / 2
            let y = (frameSize.height - diameter) / 2 + frameSize.height * 0.02  // 稍微向下偏移一点
            return CGRect(x: x, y: y, width: diameter, height: diameter)
            
        case "mask_heart":
            // 心形相框，照片区域为中央的心形
            let diameter = min(frameSize.width, frameSize.height) * 0.7
            let x = (frameSize.width - diameter) / 2
            let y = (frameSize.height - diameter) / 2
            return CGRect(x: x, y: y, width: diameter, height: diameter)
            
        case "mask_star":
            // 星形相框，照片区域为中央的星形
            let diameter = min(frameSize.width, frameSize.height) * 0.7
            let x = (frameSize.width - diameter) / 2
            let y = (frameSize.height - diameter) / 2
            return CGRect(x: x, y: y, width: diameter, height: diameter)
            
        case "frame_polaroid":
            // 拍立得相框，照片区域略小于相框，且位于上部
            let width = frameSize.width * 0.85
            let height = frameSize.height * 0.7
            let x = (frameSize.width - width) / 2
            let y = frameSize.height * 0.1
            return CGRect(x: x, y: y, width: width, height: height)
            
        case "frame_wooden":
            // 木质相框，照片区域略小于相框
            let width = frameSize.width * 0.8
            let height = frameSize.height * 0.8
            let x = (frameSize.width - width) / 2
            let y = (frameSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
            
        default:
            // 默认情况，照片区域略小于相框
            let width = frameSize.width * 0.88
            let height = frameSize.height * 0.88
            let x = (frameSize.width - width) / 2
            let y = (frameSize.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    // 创建花朵路径
    private func createFlowerPath(in size: CGSize) -> UIBezierPath? {
        let path = UIBezierPath()
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let petalCount = 8
        let innerRadius = min(size.width, size.height) * 0.15  // 更小的内圆半径，以匹配图片
        let outerRadius = min(size.width, size.height) * 0.5   // 外圆半径
        
        // 创建花瓣
        for i in 0..<petalCount {
            let startAngle = CGFloat(i) * 2 * .pi / CGFloat(petalCount)
            let endAngle = startAngle + .pi / CGFloat(petalCount)
            let midAngle = (startAngle + endAngle) / 2
            
            let innerPoint = CGPoint(
                x: center.x + innerRadius * cos(startAngle),
                y: center.y + innerRadius * sin(startAngle)
            )
            
            let outerPoint = CGPoint(
                x: center.x + outerRadius * cos(midAngle),
                y: center.y + outerRadius * sin(midAngle)
            )
            
            let endPoint = CGPoint(
                x: center.x + innerRadius * cos(endAngle),
                y: center.y + innerRadius * sin(endAngle)
            )
            
            if i == 0 {
                path.move(to: innerPoint)
            } else {
                path.addLine(to: innerPoint)
            }
            
            // 使用bezier曲线创建更圆润的花瓣
            path.addQuadCurve(to: endPoint, controlPoint: outerPoint)
        }
        
        path.close()
        return path
    }
    
    // 创建心形路径
    private func createHeartPath(in size: CGSize) -> UIBezierPath? {
        let path = UIBezierPath()
        let width = size.width
        let height = size.height
        
        // 移动到心形底部
        path.move(to: CGPoint(x: width / 2, y: height))
        
        // 左半部分
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            controlPoint1: CGPoint(x: width / 2 - width / 2, y: height * 3 / 4),
            controlPoint2: CGPoint(x: 0, y: height / 2)
        )
        
        // 左上部分
        path.addArc(
            withCenter: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        // 右上部分
        path.addArc(
            withCenter: CGPoint(x: width * 3 / 4, y: height / 4),
            radius: width / 4,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        
        // 右半部分
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            controlPoint1: CGPoint(x: width, y: height / 2),
            controlPoint2: CGPoint(x: width / 2 + width / 2, y: height * 3 / 4)
        )
        
        return path
    }
    
    // 创建星形路径
    private func createStarPath(in size: CGSize) -> UIBezierPath? {
        let path = UIBezierPath()
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let pointCount = 5
        let innerRadius = min(size.width, size.height) * 0.25  // 内圆半径
        let outerRadius = min(size.width, size.height) * 0.5   // 外圆半径
        
        // 创建星形
        for i in 0..<pointCount * 2 {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = CGFloat(i) * .pi / CGFloat(pointCount) - .pi / 2
            
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.close()
        return path
    }
    
    // 生成带边框的图片
    func generateBorderedImage(originalImage: UIImage, borderColor: UIColor, borderWidth: CGFloat) -> UIImage? {
        let imageSize = originalImage.size
        let scale = originalImage.scale
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        
        // 创建圆角矩形路径
        let rect = CGRect(origin: .zero, size: imageSize)
        let cornerRadius: CGFloat = 10.0
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        
        // 裁剪上下文
        context?.addPath(path)
        context?.clip()
        
        // 绘制原始图片
        originalImage.draw(in: rect)
        
        // 添加边框
        context?.setStrokeColor(borderColor.cgColor)
        context?.setLineWidth(borderWidth)
        context?.addPath(path)
        context?.strokePath()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // 生成带装饰元素的图片
    func generateDecoratedImage(originalImage: UIImage, decorations: [String], color: UIColor) -> UIImage? {
        let imageSize = originalImage.size
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制原始图片
        originalImage.draw(in: CGRect(origin: .zero, size: imageSize))
        
        // 添加装饰元素
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        // 设置绘制属性
        context?.setFillColor(color.cgColor)
        
        // 在四个角添加装饰元素
        if decorations.count > 0 {
            drawSymbol(decorations[0], at: CGPoint(x: 20, y: 20), size: 30, color: color)
        }
        
        if decorations.count > 1 {
            drawSymbol(decorations[1], at: CGPoint(x: imageSize.width - 20, y: 20), size: 30, color: color)
        }
        
        if decorations.count > 2 {
            drawSymbol(decorations[2], at: CGPoint(x: imageSize.width - 20, y: imageSize.height - 20), size: 30, color: color)
        }
        
        if decorations.count > 3 {
            drawSymbol(decorations[3], at: CGPoint(x: 20, y: imageSize.height - 20), size: 30, color: color)
        }
        
        context?.restoreGState()
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // 绘制SF Symbol
    private func drawSymbol(_ symbolName: String, at point: CGPoint, size: CGFloat, color: UIColor) {
        guard let symbolConfig = UIImage(systemName: symbolName)?.withTintColor(color, renderingMode: .alwaysOriginal) else {
            return
        }
        
        let symbolSize = CGSize(width: size, height: size)
        let symbolRect = CGRect(
            x: point.x - symbolSize.width / 2,
            y: point.y - symbolSize.height / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        
        symbolConfig.draw(in: symbolRect)
    }
    
    // 根据FrameStyle生成模板图片
    func generateTemplateImage(originalImage: UIImage, frameStyle: FrameStyle) -> UIImage? {
        print("开始生成模板图片，框架样式: \(frameStyle.rawValue)")
        
        // 如果框架样式使用蒙版或相框，使用相应的处理方法
        if frameStyle.usesMaskOrFrame {
            guard let maskName = frameStyle.maskImageName else {
                print("找不到蒙版或相框名称")
                return nil
            }
            
            print("尝试使用蒙版或相框: \(maskName)")
            
            // 首先尝试特殊框架处理方法
            if maskName == "flower_frame" {
                print("使用花朵框架特殊处理")
                if let framedImage = generateFramedImage(originalImage: originalImage, frameName: maskName) {
                    print("花朵框架处理成功")
                    return framedImage
                } else {
                    print("花朵框架处理失败")
                    return nil
                }
            }
            
            // 尝试应用蒙版
            if let maskedImage = generateMaskedImage(originalImage: originalImage, maskName: maskName) {
                print("应用蒙版成功")
                return maskedImage
            }
            
            // 尝试应用相框
            if let framedImage = generateFramedImage(originalImage: originalImage, frameName: maskName) {
                print("应用相框成功")
                return framedImage
            }
            
            print("所有处理方法都失败了")
            return nil
        }
        
        // 如果框架样式不使用蒙版，使用默认样式
        print("应用普通边框样式")
        // 应用边框
        if let borderedImage = generateBorderedImage(
            originalImage: originalImage,
            borderColor: UIColor(frameStyle.borderColor),
            borderWidth: 3.0
        ) {
            return borderedImage
        } else {
            print("应用边框失败")
            return nil
        }
    }
}

// 扩展UIColor，添加从十六进制字符串创建颜色的方法
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
} 
