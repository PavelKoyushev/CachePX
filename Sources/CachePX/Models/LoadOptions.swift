import Foundation

/// Options for controlling how an image should be loaded and optionally downsampled.
/// Use `LoadOptions` to configure image loading operations.
/// For example, you can provide a preferred target size to downsample
/// large images during loading, reducing memory usage and improving performance.
public struct LoadOptions: Sendable {
    
    /// Creates a new set of load options.
    public init(downSample: PreferredImageSize?) {
        self.downSample = downSample
    }
    
    /// The target image size to downsample to, or `nil` if no downsampling is required.
    public let downSample: PreferredImageSize?
    
    /// A preferred target size for image downsampling.
    /// Use this to specify the maximum width, height, and quality for
    /// images that should be resized before use.
    public struct PreferredImageSize: Sendable {
        
        /// The target width in pixels.
        public let width: Int
        
        /// The target height in pixels.
        public let height: Int
        
        /// The preferred output quality.
        /// - For JPEG/WebP: a value from 0 (lowest) to 100 (highest).
        /// - For PNG: a value from 0 (no compression) to 10 (maximum).
        public let quality: Int
        
        /// Creates a new preferred image size configuration.
        /// - Parameters:
        ///   - width: The target width in pixels.
        ///   - height: The target height in pixels.
        ///   - quality: The preferred output quality (0–100).
        public init(width: Int, height: Int, quality: Int) {
            self.width = width
            self.height = height
            self.quality = quality
        }
    }
}
