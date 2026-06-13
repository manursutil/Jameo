import AppKit
import CoreGraphics
import ScreenCaptureKit

enum ScreenContextCaptureError: LocalizedError {
    case permissionDenied
    case imageUnavailable
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            String(localized: "Screen Recording permission is required to include screen context.")
        case .imageUnavailable:
            String(localized: "Could not capture the current screen.")
        case .encodingFailed:
            String(localized: "Could not prepare the screen image.")
        }
    }
}

struct ScreenContextCaptureService {
    private let maximumLongEdge: CGFloat = 1600

    func captureDisplay(containing screen: NSScreen?) async throws -> Data {
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            throw ScreenContextCaptureError.permissionDenied
        }

        let displayID = screen?.displayID ?? CGMainDisplayID()
        let content = try await SCShareableContent.current
        guard let display = content.displays.first(where: { $0.displayID == displayID }) ?? content.displays.first else {
            throw ScreenContextCaptureError.imageUnavailable
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        let targetSize = downscaledSize(width: CGFloat(display.width), height: CGFloat(display.height))
        configuration.width = Int(targetSize.width.rounded())
        configuration.height = Int(targetSize.height.rounded())
        configuration.showsCursor = true

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        return try encodeDownscaledPNG(from: image)
    }

    private func downscaledSize(width: CGFloat, height: CGFloat) -> CGSize {
        let longEdge = max(width, height)
        let scale = min(1, maximumLongEdge / longEdge)

        return CGSize(width: width * scale, height: height * scale)
    }

    private func encodeDownscaledPNG(from image: CGImage) throws -> Data {
        let originalSize = CGSize(width: image.width, height: image.height)
        let targetSize = downscaledSize(width: originalSize.width, height: originalSize.height)

        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width.rounded()),
            pixelsHigh: Int(targetSize.height.rounded()),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let bitmap else {
            throw ScreenContextCaptureError.encodingFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSImage(cgImage: image, size: originalSize).draw(
            in: CGRect(origin: .zero, size: targetSize),
            from: CGRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenContextCaptureError.encodingFailed
        }

        return data
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID
    }
}
