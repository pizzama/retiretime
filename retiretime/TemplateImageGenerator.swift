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
    
    // 添加缓存
    private var imageCache: [String: UIImage] = [:]
    private let cacheQueue = DispatchQueue(label: "com.retiretime.imageCacheQueue", attributes: .concurrent)
    
    private init() {}
    
    // 生成模板图像，支持缩放和偏移
    func generateTemplateImage(originalImage: UIImage, frameStyle: FrameStyle, scale: CGFloat = 1.0, offset: CGSize = .zero) -> UIImage? {
        // 创建缓存键
        let cacheKey = createCacheKey(originalImage: originalImage, frameStyle: frameStyle, scale: scale, offset: offset)
        
        // 检查缓存
        if let cachedImage = getCachedImage(for: cacheKey) {
            return cachedImage
        }
        
        // 根据框架样式选择处理方法
        var resultImage: UIImage?
        
        if let maskName = frameStyle.maskImageName {
            if maskName.contains("frame") {
                // 对于相框类型，直接传递缩放和偏移参数
                resultImage = generateFramedImage(originalImage: originalImage, frameName: maskName, scale: scale, offset: offset)
            } else {
                // 对于蒙版类型，先应用缩放和偏移
                let adjustedImage = applyScaleAndOffset(to: originalImage, scale: scale, offset: offset)
                resultImage = generateMaskedImage(originalImage: adjustedImage, maskName: maskName)
            }
        } else {
            // 如果没有特殊处理，应用缩放和偏移后返回
            resultImage = applyScaleAndOffset(to: originalImage, scale: scale, offset: offset)
        }
        
        // 缓存结果
        if let resultImage = resultImage {
            cacheImage(resultImage, for: cacheKey)
        }
        
        return resultImage
    }
    
    // 创建缓存键
    private func createCacheKey(originalImage: UIImage, frameStyle: FrameStyle, scale: CGFloat, offset: CGSize) -> String {
        // 使用图片的内存地址、尺寸、帧样式、缩放和偏移创建唯一键
        let imagePointer = Unmanaged.passUnretained(originalImage).toOpaque()
        return "\(imagePointer)_\(originalImage.size.width)x\(originalImage.size.height)_\(frameStyle.rawValue)_\(scale)_\(offset.width)x\(offset.height)"
    }
    
    // 获取缓存的图片
    private func getCachedImage(for key: String) -> UIImage? {
        var cachedImage: UIImage?
        cacheQueue.sync {
            cachedImage = imageCache[key]
        }
        return cachedImage
    }
    
    // 缓存图片
    private func cacheImage(_ image: UIImage, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.imageCache[key] = image
            
            // 如果缓存太大，清理一些旧条目
            if self.imageCache.count > 50 {
                // 简单策略：移除一半的缓存
                let keysToRemove = Array(self.imageCache.keys).prefix(self.imageCache.count / 2)
                for key in keysToRemove {
                    self.imageCache.removeValue(forKey: key)
                }
            }
        }
    }
    
    // 清除缓存
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.imageCache.removeAll()
        }
    }
    
    // 原有的 generateTemplateImage 方法，保持向后兼容
    func generateTemplateImage(originalImage: UIImage, frameStyle: FrameStyle) -> UIImage? {
        return generateTemplateImage(originalImage: originalImage, frameStyle: frameStyle, scale: 1.0, offset: .zero)
    }
    
    // 应用缩放和偏移到图像
    private func applyScaleAndOffset(to image: UIImage, scale: CGFloat, offset: CGSize) -> UIImage {
        // 如果没有缩放和偏移，直接返回原图
        if scale == 1.0 && offset == .zero {
            return image
        }
        
        // 创建一个与原始图片大小相同的上下文
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: size.width / 2 + offset.width, y: size.height / 2 + offset.height)
        context?.scaleBy(x: scale, y: scale)
        context?.translateBy(x: -size.width / 2, y: -size.height / 2)
        
        // 绘制图像
        image.draw(in: CGRect(origin: .zero, size: size))
        
        // 获取调整后的图像
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
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
    func generateFramedImage(originalImage: UIImage, frameName: String, scale: CGFloat = 1.0, offset: CGSize = .zero) -> UIImage? {
        // 首先尝试加载预定义的相框图片
        if let frameImage = UIImage(named: frameName) {
            // 尝试加载对应的蒙版图片
            let maskName = frameName + "_mask"
            let maskImage = UIImage(named: maskName)
            
            // 计算照片在相框中的位置和大小
            let photoRect = calculatePhotoRect(frameSize: frameImage.size, frameName: frameName, offset: offset)
            
            // 计算保持原始图片比例的绘制区域
            let imageAspect = originalImage.size.width / originalImage.size.height
            let rectAspect = photoRect.width / photoRect.height
            
            var drawRect = photoRect
            
            if imageAspect > rectAspect {
                // 图片比相框区域更宽，以高度为基准
                let newWidth = photoRect.height * imageAspect
                drawRect = CGRect(
                    x: photoRect.midX - newWidth / 2,
                    y: photoRect.origin.y,
                    width: newWidth,
                    height: photoRect.height
                )
            } else if imageAspect < rectAspect {
                // 图片比相框区域更高，以宽度为基准
                let newHeight = photoRect.width / imageAspect
                drawRect = CGRect(
                    x: photoRect.origin.x,
                    y: photoRect.midY - newHeight / 2,
                    width: photoRect.width,
                    height: newHeight
                )
            }
            
            // 应用用户设置的缩放和偏移
            if scale != 1.0 || offset != .zero {
                // 计算缩放后的绘制区域
                let scaledWidth = drawRect.width * scale
                let scaledHeight = drawRect.height * scale
                let scaledX = drawRect.midX - scaledWidth / 2 + offset.width
                let scaledY = drawRect.midY - scaledHeight / 2 + offset.height
                
                drawRect = CGRect(
                    x: scaledX,
                    y: scaledY,
                    width: scaledWidth,
                    height: scaledHeight
                )
            }
            
            // 使用UIGraphicsImageRenderer创建一个新的图像上下文
            let renderer = UIGraphicsImageRenderer(size: frameImage.size)
            
            return renderer.image { context in
                // 如果有蒙版图片，使用蒙版定义照片显示区域
                if let maskImage = maskImage, let cgMask = maskImage.cgImage {
                    // 创建一个临时上下文来绘制蒙版图片
                    let tempRenderer = UIGraphicsImageRenderer(size: frameImage.size)
                    let maskedPhoto = tempRenderer.image { tempContext in
                        // 绘制照片
                        originalImage.draw(in: drawRect)
                        
                        // 使用蒙版的alpha通道作为裁剪区域
                        // 这里使用destinationIn混合模式，只保留蒙版不透明部分下方的照片
                        maskImage.draw(in: CGRect(origin: .zero, size: frameImage.size), blendMode: .destinationIn, alpha: 1.0)
                    }
                    
                    // 绘制处理后的照片
                    maskedPhoto.draw(in: CGRect(origin: .zero, size: frameImage.size))
                    
                    // 绘制相框
                    frameImage.draw(in: CGRect(origin: .zero, size: frameImage.size))
                } else {
                    // 如果没有蒙版图片，使用默认方法
                    // 创建一个临时图像，将照片绘制到相框形状中
                    let tempRenderer = UIGraphicsImageRenderer(size: frameImage.size)
                    let maskedPhoto = tempRenderer.image { tempContext in
                        // 绘制照片
                        originalImage.draw(in: drawRect)
                        
                        // 使用相框的alpha通道作为蒙版
                        // 这里使用destinationOut混合模式，移除相框不透明部分下方的照片
                        frameImage.draw(in: CGRect(origin: .zero, size: frameImage.size), blendMode: .destinationOut, alpha: 1.0)
                    }
                    
                    // 绘制处理后的照片
                    maskedPhoto.draw(in: CGRect(origin: .zero, size: frameImage.size))
                    
                    // 绘制相框
                    frameImage.draw(in: CGRect(origin: .zero, size: frameImage.size))
                }
            }
        }
        
        // 如果没有预定义的相框图片，尝试从JSON生成
        return generateFrameFromJSON(originalImage: originalImage, jsonName: frameName, scale: scale, offset: offset)
    }
    
    // 从JSON生成相框图片
    private func generateFrameFromJSON(originalImage: UIImage, jsonName: String, scale: CGFloat = 1.0, offset: CGSize = .zero) -> UIImage? {
        guard let frameDescription = loadFrameDescription(jsonName: jsonName) else {
            return nil
        }
        
        // 创建一个与原始图片大小相同的上下文
        let size = CGSize(width: 500, height: 500) // 使用固定大小，可以根据需要调整
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制原始图片到中央，保持原始比例
        let photoSize = CGSize(width: size.width * 0.6, height: size.height * 0.6)
        let photoRect = CGRect(
            x: (size.width - photoSize.width) / 2,
            y: (size.height - photoSize.height) / 2,
            width: photoSize.width,
            height: photoSize.height
        )
        
        // 计算保持原始图片比例的绘制区域
        let imageAspect = originalImage.size.width / originalImage.size.height
        let rectAspect = photoRect.width / photoRect.height
        
        var drawRect = photoRect
        
        if imageAspect > rectAspect {
            // 图片比相框区域更宽，以高度为基准
            let newWidth = photoRect.height * imageAspect
            drawRect = CGRect(
                x: photoRect.midX - newWidth / 2,
                y: photoRect.origin.y,
                width: newWidth,
                height: photoRect.height
            )
        } else if imageAspect < rectAspect {
            // 图片比相框区域更高，以宽度为基准
            let newHeight = photoRect.width / imageAspect
            drawRect = CGRect(
                x: photoRect.origin.x,
                y: photoRect.midY - newHeight / 2,
                width: photoRect.width,
                height: newHeight
            )
        }
        
        // 应用用户设置的缩放和偏移
        if scale != 1.0 || offset != .zero {
            // 计算缩放后的绘制区域
            let scaledWidth = drawRect.width * scale
            let scaledHeight = drawRect.height * scale
            let scaledX = drawRect.midX - scaledWidth / 2 + offset.width
            let scaledY = drawRect.midY - scaledHeight / 2 + offset.height
            
            drawRect = CGRect(
                x: scaledX,
                y: scaledY,
                width: scaledWidth,
                height: scaledHeight
            )
        }
        
        // 绘制原始图片
        originalImage.draw(in: drawRect)
        
        // 绘制相框元素
        let context = UIGraphicsGetCurrentContext()!
        
        // 绘制路径
        for path in frameDescription.paths {
            drawPath(path: path, in: context, size: size)
        }
        
        // 返回最终图片
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // 加载JSON描述
    func loadFrameDescription(jsonName: String) -> FrameDescription? {
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
    func drawPath(path: PathDescription, in context: CGContext, size: CGSize) {
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
    func calculatePhotoRect(frameSize: CGSize, frameName: String, offset: CGSize = .zero) -> CGRect {
        // 根据不同的相框类型返回不同的照片区域
        var rect: CGRect
        
        // 默认情况，照片区域明显小于相框，确保照片在相框内部
        // 对于polaroid类型的相框，照片区域应该更小
        if frameName.contains("polaroid") {
            // Polaroid相框通常有较宽的白色边框，特别是底部
            let width = frameSize.width * 0.85  // 照片宽度为相框宽度的85%
            let height = frameSize.height * 0.75 // 照片高度为相框高度的75%
            let x = (frameSize.width - width) / 2
            let y = (frameSize.height - height) / 2 - frameSize.height * 0.05 // 向上偏移一点，因为底部边框更宽
            rect = CGRect(x: x, y: y, width: width, height: height)
        } else {
            // 其他类型的相框，照片区域也应该小于相框
            let width = frameSize.width * 0.9  // 照片宽度为相框宽度的90%
            let height = frameSize.height * 0.9 // 照片高度为相框高度的90%
            let x = (frameSize.width - width) / 2
            let y = (frameSize.height - height) / 2
            rect = CGRect(x: x, y: y, width: width, height: height)
        }
        
        // 应用偏移量
        if offset != .zero {
            rect.origin.x += offset.width
            rect.origin.y += offset.height
        }
        
        return rect
    }
    
    // 创建花朵路径
    func createFlowerPath(in size: CGSize) -> UIBezierPath? {
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
    func createHeartPath(in size: CGSize) -> UIBezierPath? {
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
    func createStarPath(in size: CGSize) -> UIBezierPath? {
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
    func drawSymbol(_ symbolName: String, at point: CGPoint, size: CGFloat, color: UIColor) {
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
