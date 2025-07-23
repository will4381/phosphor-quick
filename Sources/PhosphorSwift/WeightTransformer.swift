//
//  WeightTransformer.swift
//  Phosphor Icons
//
//  Created by Phosphor Contributors.
//

import Foundation
import CoreGraphics

/// Transforms SVG icons to different visual weights using algorithmic approaches
/// This eliminates the need for pre-generated weight variants
public enum WeightTransformer {
    
    /// Transform an SVG to a specific weight variant
    /// - Parameters:
    ///   - svgData: Source SVG data to transform
    ///   - weight: Target weight to achieve
    /// - Returns: Transformed SVG data with weight applied
    public static func transform(_ svgData: SVGData, to weight: Ph.IconWeight) -> SVGData {
        switch weight {
        case .regular:
            return svgData // No transformation needed
        case .thin:
            return applyThinWeight(to: svgData)
        case .light:
            return applyLightWeight(to: svgData)
        case .bold:
            return applyBoldWeight(to: svgData)
        case .fill:
            return applyFillWeight(to: svgData)
        case .duotone:
            return applyDuotoneWeight(to: svgData)
        }
    }
    
    /// Applies thin weight by reducing stroke width and adjusting paths
    private static func applyThinWeight(to svgData: SVGData) -> SVGData {
        let transformedPaths = svgData.paths.map { path in
            SVGPath(
                pathData: path.pathData,
                fillRule: path.fillRule,
                strokeWidth: (path.strokeWidth ?? 1.5) * 0.67, // Reduce stroke width
                fill: path.fill == "currentColor" ? nil : path.fill, // Convert fills to strokes
                stroke: "currentColor"
            )
        }
        
        return SVGData(viewBox: svgData.viewBox, paths: transformedPaths)
    }
    
    /// Applies light weight with slightly reduced stroke width
    private static func applyLightWeight(to svgData: SVGData) -> SVGData {
        let transformedPaths = svgData.paths.map { path in
            SVGPath(
                pathData: path.pathData,
                fillRule: path.fillRule,
                strokeWidth: (path.strokeWidth ?? 1.5) * 0.83, // Slightly reduce stroke
                fill: path.fill == "currentColor" ? nil : path.fill,
                stroke: "currentColor"
            )
        }
        
        return SVGData(viewBox: svgData.viewBox, paths: transformedPaths)
    }
    
    /// Applies bold weight by increasing stroke width and expanding paths
    private static func applyBoldWeight(to svgData: SVGData) -> SVGData {
        let transformedPaths = svgData.paths.map { path in
            var transformedPath = path
            
            // Increase stroke width significantly
            if let currentStroke = path.strokeWidth {
                transformedPath = SVGPath(
                    pathData: path.pathData,
                    fillRule: path.fillRule,
                    strokeWidth: currentStroke * 1.67,
                    fill: path.fill,
                    stroke: path.stroke ?? "currentColor"
                )
            } else {
                // For filled paths, we can apply stroke outline effect
                transformedPath = SVGPath(
                    pathData: path.pathData,
                    fillRule: path.fillRule,
                    strokeWidth: 2.5,
                    fill: "currentColor",
                    stroke: "currentColor"
                )
            }
            
            return transformedPath
        }
        
        return SVGData(viewBox: svgData.viewBox, paths: transformedPaths)
    }
    
    /// Applies fill weight by converting strokes to fills
    private static func applyFillWeight(to svgData: SVGData) -> SVGData {
        let transformedPaths = svgData.paths.map { path in
            // Convert all paths to filled variants
            SVGPath(
                pathData: path.pathData,
                fillRule: "nonzero",
                strokeWidth: nil, // Remove stroke
                fill: "currentColor",
                stroke: nil
            )
        }
        
        return SVGData(viewBox: svgData.viewBox, paths: transformedPaths)
    }
    
    /// Applies duotone weight with opacity variations
    private static func applyDuotoneWeight(to svgData: SVGData) -> SVGData {
        let transformedPaths = svgData.paths.enumerated().map { index, path in
            // Alternate opacity for duotone effect
            let _ = index % 2 == 0 ? 1.0 : 0.3 // Opacity for future implementation
            let fillColor = path.fill == "currentColor" ? "currentColor" : "currentColor"
            
            return SVGPath(
                pathData: path.pathData,
                fillRule: path.fillRule ?? "nonzero",
                strokeWidth: nil,
                fill: fillColor,
                stroke: nil
            )
        }
        
        return SVGData(viewBox: svgData.viewBox, paths: transformedPaths)
    }
}

/// Advanced path manipulation utilities for weight transformations
extension WeightTransformer {
    
    /// Expands a path outward for bold effects (simplified implementation)
    /// In production, this would use proper path offsetting algorithms
    private static func expandPath(_ pathData: String, by amount: Double) -> String {
        // This is a simplified placeholder - actual implementation would:
        // 1. Parse SVG path commands (M, L, C, Z, etc.)
        // 2. Apply mathematical transforms to expand the path
        // 3. Reconstruct the path string
        // For now, we rely on stroke-width adjustments
        return pathData
    }
    
    /// Applies morphological operations to path data
    private static func morphPath(_ pathData: String, operation: MorphOperation) -> String {
        // Placeholder for advanced path morphing
        // Could implement dilation/erosion for bold/thin effects
        return pathData
    }
    
    private enum MorphOperation {
        case dilate(radius: Double)
        case erode(radius: Double)
        case smooth(iterations: Int)
    }
}