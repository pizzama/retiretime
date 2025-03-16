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
    
    // 生成模板图像，支持缩放和偏移
    func generateTemplateImage(originalImage: UIImage, frameStyle: FrameStyle, scale: CGFloat = 1.0, offset: CGSize = .zero) -> UIImage? {
        // 根据框架样式选择处理方法
        if let maskName = frameStyle.maskImageName {
            if maskName.contains("frame") {
                // 对于相框类型，直接传递缩放和偏移参数
                return generateFramedImage(originalImage: originalImage, frameName: maskName, scale: scale, offset: offset)
            } else {
                // 对于蒙版类型，先应用缩放和偏移
                let adjustedImage = applyScaleAndOffset(to: originalImage, scale: scale, offset: offset)
                return generateMaskedImage(originalImage: adjustedImage, maskName: maskName)
            }
        }
        
        // 如果没有特殊处理，应用缩放和偏移后返回
        return applyScaleAndOffset(to: originalImage, scale: scale, offset: offset)
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
            print("加载相框图片: \(frameName), 尺寸: \(frameImage.size), 缩放: \(scale), 偏移: \(offset)")
            
            // 计算照片在相框中的位置和大小
            let photoRect = calculatePhotoRect(frameSize: frameImage.size, frameName: frameName, offset: offset)
            print("照片区域: \(photoRect), 偏移量: \(offset)")
            
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
                // 创建一个临时上下文来获取相框的alpha数据
                let width = Int(frameImage.size.width)
                let height = Int(frameImage.size.height)
                let bytesPerRow = width * 4
                var pixelData = [UInt8](repeating: 0, count: width * height * 4)
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                guard let tempContext = CGContext(data: &pixelData,
                                             width: width,
                                             height: height,
                                             bitsPerComponent: 8,
                                             bytesPerRow: bytesPerRow,
                                             space: colorSpace,
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
                      let frameImageCGImage = frameImage.cgImage else {
                    // 如果无法创建上下文或获取CGImage，直接绘制相框和照片
                    originalImage.draw(in: drawRect)
                    frameImage.draw(in: CGRect(origin: .zero, size: frameImage.size))
                    return
                }
                
                // 在临时上下文中绘制相框图像
                tempContext.draw(frameImageCGImage, in: CGRect(origin: .zero, size: frameImage.size))
                
                // 第一步：先绘制照片，但只在相框透明区域显示
                context.cgContext.saveGState()
                
                // 创建一个路径来表示alpha为0的区域（透明区域）
                let clipPath = CGMutablePath()
                
                // 遍历每个像素，找出alpha为0的区域（完全透明的区域）
                for y in 0..<height {
                    for x in 0..<width {
                        let pixelIndex = (width * y + x) * 4
                        let alpha = pixelData[pixelIndex + 3] // Alpha通道值
                        
                        // 如果alpha为0，则将该像素添加到裁剪路径中
                        if alpha == 0 {
                            clipPath.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                        }
                    }
                }
                
                // 应用裁剪路径，这样只有在alpha为0的区域内才会显示照片
                context.cgContext.addPath(clipPath)
                context.cgContext.clip()
                
                // 在裁剪区域内绘制照片
                originalImage.draw(in: drawRect)
                
                // 恢复图形状态
                context.cgContext.restoreGState()
                
                // 第二步：绘制相框的不透明部分
                for y in 0..<height {
                    for x in 0..<width {
                        let pixelIndex = (width * y + x) * 4
                        let alpha = pixelData[pixelIndex + 3] // Alpha通道值
                        
                        // 如果alpha大于0，则在该位置绘制相框像素
                        if alpha > 0 {
                            // 获取相框像素的颜色
                            let red = CGFloat(pixelData[pixelIndex]) / 255.0
                            let green = CGFloat(pixelData[pixelIndex + 1]) / 255.0
                            let blue = CGFloat(pixelData[pixelIndex + 2]) / 255.0
                            let alphaValue = CGFloat(alpha) / 255.0
                            
                            // 在最终上下文中绘制该像素，使用源覆盖模式确保完全覆盖底层
                            context.cgContext.setFillColor(red: red, green: green, blue: blue, alpha: alphaValue)
                            context.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                        }
                    }
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
