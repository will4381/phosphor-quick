//
//  SVGRenderer.swift
//  Phosphor Icons
//
//  Created by Phosphor Contributors.
//

import SwiftUI
import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// High-performance SVG renderer that generates icon weights dynamically
/// Replaces the massive bundle approach with on-demand rendering
public final class SVGRenderer {
    
    /// Thread-safe singleton instance for optimal performance
    public static let shared = SVGRenderer()
    
    /// Cache for parsed SVG data to avoid redundant XML parsing
    private let svgCache = NSCache<NSString, SVGData>()
    
    /// Cache for rendered images to avoid redundant drawing operations
    private let imageCache = NSCache<NSString, CGImage>()
    
    /// Concurrent queue for background SVG parsing and rendering
    private let renderQueue = DispatchQueue(label: "com.phosphor.svg-renderer", 
                                          qos: .userInitiated, 
                                          attributes: .concurrent)
    
    private init() {
        // Configure caches for optimal memory usage
        svgCache.countLimit = 200  // Reasonable limit for base SVGs
        imageCache.countLimit = 1000  // More generous for rendered variants
        
        // Clear caches on memory pressure
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearCaches()
        }
        #endif
    }
    
    /// Renders an icon with specified weight and size
    /// - Parameters:
    ///   - iconName: Base icon name (without weight suffix)
    ///   - weight: Visual weight to apply
    ///   - size: Target size for rendering
    ///   - color: Icon color (default: label color)
    /// - Returns: SwiftUI Image ready for display
    public func renderIcon(
        _ iconName: String,
        weight: Ph.IconWeight = .regular,
        size: CGSize = CGSize(width: 24, height: 24),
        color: Color = .primary
    ) -> Image {
        
        let cacheKey = "\(iconName)-\(weight.rawValue)-\(size.width)x\(size.height)" as NSString
        
        // Check for cached rendered image
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return Image(cachedImage, scale: 1.0, label: Text(iconName))
        }
        
        // Load and parse SVG data
        guard let svgData = loadSVGData(for: iconName) else {
            // Create a simple fallback image using a question mark path
            let fallbackSVG = SVGData(
                viewBox: CGRect(x: 0, y: 0, width: 256, height: 256),
                paths: [SVGPath(pathData: "M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Z")]
            )
            guard let fallbackImage = renderSVGToImage(fallbackSVG, size: size) else {
                return Image("questionmark", bundle: .main) // Final fallback
            }
            return Image(fallbackImage, scale: 1.0, label: Text("fallback"))
        }
        
        // Apply weight transformation and render
        let transformedSVG = applyWeightTransformation(to: svgData, weight: weight)
        
        guard let renderedImage = renderSVGToImage(transformedSVG, size: size) else {
            return Image("questionmark", bundle: .main) // Fallback
        }
        
        // Cache the rendered result
        imageCache.setObject(renderedImage, forKey: cacheKey)
        
        return Image(renderedImage, scale: 1.0, label: Text(iconName))
    }
    
    /// Loads and parses SVG data from bundle, with caching
    private func loadSVGData(for iconName: String) -> SVGData? {
        let cacheKey = iconName as NSString
        
        // Check cache first
        if let cachedData = svgCache.object(forKey: cacheKey) {
            return cachedData
        }
        
        // Load from bundle (from BaseSVGs directory)
        guard let svgURL = Bundle.module.url(forResource: iconName, withExtension: "svg", subdirectory: "BaseSVGs"),
              let svgString = try? String(contentsOf: svgURL) else {
            return nil
        }
        
        // Parse SVG
        guard let svgData = SVGParser.parse(svgString) else {
            return nil
        }
        
        // Cache parsed data
        svgCache.setObject(svgData, forKey: cacheKey)
        return svgData
    }
    
    /// Applies weight transformation to SVG data
    private func applyWeightTransformation(to svgData: SVGData, weight: Ph.IconWeight) -> SVGData {
        return WeightTransformer.transform(svgData, to: weight)
    }
    
    /// Renders transformed SVG to CGImage
    private func renderSVGToImage(_ svgData: SVGData, size: CGSize) -> CGImage? {
        return SVGRasterizer.rasterize(svgData, to: size)
    }
    
    /// Clears all caches to free memory
    public func clearCaches() {
        svgCache.removeAllObjects()
        imageCache.removeAllObjects()
    }
}

/// Represents parsed SVG data with path information
public class SVGData {
    let viewBox: CGRect
    let paths: [SVGPath]
    
    public init(viewBox: CGRect, paths: [SVGPath]) {
        self.viewBox = viewBox
        self.paths = paths
    }
}

/// Represents an SVG path with styling information
public struct SVGPath {
    let pathData: String
    let fillRule: String?
    let strokeWidth: Double?
    let fill: String?
    let stroke: String?
    
    public init(pathData: String, fillRule: String? = nil, strokeWidth: Double? = nil, 
                fill: String? = nil, stroke: String? = nil) {
        self.pathData = pathData
        self.fillRule = fillRule
        self.strokeWidth = strokeWidth
        self.fill = fill
        self.stroke = stroke
    }
}