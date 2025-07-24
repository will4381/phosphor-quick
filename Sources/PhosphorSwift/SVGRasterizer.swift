//
//  SVGRasterizer.swift
//  Phosphor Icons
//
//  Created by Phosphor Contributors.
//

import Foundation
import CoreGraphics
import CoreText

/// Converts parsed SVG data into rasterized CGImage for display
/// Optimized for Phosphor icon characteristics and common use cases
public enum SVGRasterizer {
    
    /// Rasterize SVG data to a CGImage at specified size
    /// - Parameters:
    ///   - svgData: Parsed SVG data to render
    ///   - size: Target size for the output image
    /// - Returns: Rasterized CGImage or nil if rendering fails
    public static func rasterize(_ svgData: SVGData, to size: CGSize) -> CGImage? {
        
        // Create graphics context
        guard let context = createGraphicsContext(size: size) else {
            return nil
        }
        
        // Calculate scale transform from viewBox to target size
        let scaleX = size.width / svgData.viewBox.width
        let scaleY = size.height / svgData.viewBox.height
        let scale = min(scaleX, scaleY) // Maintain aspect ratio
        
        // Center the scaled content
        let scaledSize = CGSize(
            width: svgData.viewBox.width * scale,
            height: svgData.viewBox.height * scale
        )
        let offsetX = (size.width - scaledSize.width) / 2
        let offsetY = (size.height - scaledSize.height) / 2
        
        // Apply transforms
        context.translateBy(x: offsetX, y: size.height - offsetY)
        context.scaleBy(x: scale, y: -scale) // Flip Y-axis for SVG coordinate system
        context.translateBy(x: -svgData.viewBox.origin.x, y: -svgData.viewBox.origin.y)
        
        // Render each path
        for path in svgData.paths {
            renderPath(path, in: context)
        }
        
        return context.makeImage()
    }
    
    /// Create optimized graphics context for icon rendering
    private static func createGraphicsContext(size: CGSize) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        return CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }
    
    /// Render a single SVG path in the graphics context
    private static func renderPath(_ svgPath: SVGPath, in context: CGContext) {
        
        guard let cgPath = createCGPath(from: svgPath.pathData) else {
            return
        }
        
        context.addPath(cgPath)
        
        // Apply fill if specified
        if let fill = svgPath.fill, fill != "none" {
            context.setFillColor(colorFromString(fill))
            
            if let fillRule = svgPath.fillRule, fillRule == "evenodd" {
                context.fillPath(using: .evenOdd)
            } else {
                context.fillPath()
            }
        }
        
        // Apply stroke if specified
        if let stroke = svgPath.stroke, stroke != "none" {
            context.setStrokeColor(colorFromString(stroke))
            
            if let strokeWidth = svgPath.strokeWidth {
                context.setLineWidth(strokeWidth)
            } else {
                context.setLineWidth(1.5) // Default Phosphor stroke width
            }
            
            // Set default line attributes for clean rendering
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setMiterLimit(4.0)
            
            context.strokePath()
        }
    }
    
    /// Create CGPath from SVG path data string
    private static func createCGPath(from pathData: String) -> CGPath? {
        let path = CGMutablePath()
        let scanner = Scanner(string: pathData)
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
        
        var currentPoint = CGPoint.zero
        var lastControlPoint = CGPoint.zero // For smooth curve continuity
        
        while !scanner.isAtEnd {
            guard let command = scanner.scanCharacter() else { break }
            
            switch command {
            case "M": // Move to (absolute)
                if let point = scanPoint(scanner) {
                    path.move(to: point)
                    currentPoint = point
                    lastControlPoint = point
                }
                
            case "m": // Move to (relative)
                if let point = scanPoint(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x + point.x, y: currentPoint.y + point.y)
                    path.move(to: newPoint)
                    currentPoint = newPoint
                    lastControlPoint = newPoint
                }
                
            case "L": // Line to (absolute)
                if let point = scanPoint(scanner) {
                    path.addLine(to: point)
                    currentPoint = point
                    lastControlPoint = point
                }
                
            case "l": // Line to (relative)
                if let point = scanPoint(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x + point.x, y: currentPoint.y + point.y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                    lastControlPoint = newPoint
                }
                
            case "H": // Horizontal line (absolute)
                if let x = scanner.scanDouble() {
                    let newPoint = CGPoint(x: x, y: currentPoint.y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                    lastControlPoint = newPoint
                }
                
            case "h": // Horizontal line (relative)
                if let dx = scanner.scanDouble() {
                    let newPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                    lastControlPoint = newPoint
                }
                
            case "V": // Vertical line (absolute)
                if let y = scanner.scanDouble() {
                    let newPoint = CGPoint(x: currentPoint.x, y: y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                    lastControlPoint = newPoint
                }
                
            case "v": // Vertical line (relative)
                if let dy = scanner.scanDouble() {
                    let newPoint = CGPoint(x: currentPoint.x, y: currentPoint.y + dy)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                    lastControlPoint = newPoint
                }
                
            case "C": // Cubic Bézier (absolute)
                if let cp1 = scanPoint(scanner),
                   let cp2 = scanPoint(scanner),
                   let endPoint = scanPoint(scanner) {
                    path.addCurve(to: endPoint, control1: cp1, control2: cp2)
                    currentPoint = endPoint
                    lastControlPoint = cp2
                }
                
            case "c": // Cubic Bézier (relative)
                if let cp1 = scanPoint(scanner),
                   let cp2 = scanPoint(scanner),
                   let endPoint = scanPoint(scanner) {
                    let absoluteCP1 = CGPoint(x: currentPoint.x + cp1.x, y: currentPoint.y + cp1.y)
                    let absoluteCP2 = CGPoint(x: currentPoint.x + cp2.x, y: currentPoint.y + cp2.y)
                    let absoluteEnd = CGPoint(x: currentPoint.x + endPoint.x, y: currentPoint.y + endPoint.y)
                    
                    path.addCurve(to: absoluteEnd, control1: absoluteCP1, control2: absoluteCP2)
                    currentPoint = absoluteEnd
                    lastControlPoint = absoluteCP2
                }
                
            case "Z", "z": // Close path
                path.closeSubpath()
                
            default:
                // Skip unknown commands
                break
            }
        }
        
        return path.copy()
    }
    
    /// Scan a point (x,y coordinates) from the scanner
    private static func scanPoint(_ scanner: Scanner) -> CGPoint? {
        guard let x = scanner.scanDouble(),
              let y = scanner.scanDouble() else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }
    
    /// Convert color string to CGColor
    private static func colorFromString(_ colorString: String) -> CGColor {
        switch colorString.lowercased() {
        case "currentcolor", "currentColor":
            // Default to black for template rendering - will be recolored by SwiftUI
            return CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        case "none", "transparent":
            return CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        default:
            // For hex colors, RGB, etc. - simplified for Phosphor use case
            return CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
}
