import Foundation
import AVFoundation
import CoreImage
import UIKit
import ImageIO

final class VideoWatermarkProcessor {
  private let queue = DispatchQueue(label: "wm.video", qos: .userInitiated)

  private final class TaskState {
    var cancelled = false
    let request: ComposeVideoRequest
    let outputURL: URL
    init(request: ComposeVideoRequest, outputURL: URL) {
      self.request = request
      self.outputURL = outputURL
    }
  }

  private var tasks: [String: TaskState] = [:]

  func start(plugin: WatermarkKitPlugin,
             request: ComposeVideoRequest,
             callbacks: WatermarkCallbacks,
             taskId: String,
             onComplete: @escaping (ComposeVideoResult) -> Void,
             onError: @escaping (_ code: String, _ message: String) -> Void) {
    let outputPath: String
    if let out = request.outputVideoPath, !out.isEmpty {
      outputPath = out
    } else {
      let tmp = NSTemporaryDirectory()
      outputPath = (tmp as NSString).appendingPathComponent("wm_\(taskId).mp4")
    }
    let outputURL = URL(fileURLWithPath: outputPath)
    // Remove existing
    try? FileManager.default.removeItem(at: outputURL)

    let state = TaskState(request: request, outputURL: outputURL)
    tasks[taskId] = state

    queue.async { [weak self] in
      guard let self else { return }
      do {
        try self.process(plugin: plugin, state: state, callbacks: callbacks, taskId: taskId, onComplete: onComplete, onError: onError)
      } catch let err {
        DispatchQueue.main.async {
          callbacks.onVideoError(taskId: taskId, code: "compose_failed", message: err.localizedDescription) { _ in }
        }
        onError("compose_failed", err.localizedDescription)
        self.tasks[taskId] = nil
      }
    }
  }

  func cancel(taskId: String) {
    if let st = tasks[taskId] {
      st.cancelled = true
    }
  }

  private func process(plugin: WatermarkKitPlugin,
                       state: TaskState,
                       callbacks: WatermarkCallbacks,
                       taskId: String,
                       onComplete: @escaping (ComposeVideoResult) -> Void,
                       onError: @escaping (_ code: String, _ message: String) -> Void) throws {
    let request = state.request
    let asset = AVURLAsset(url: URL(fileURLWithPath: request.inputVideoPath))
    let duration = CMTimeGetSeconds(asset.duration)
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      throw NSError(domain: "wm", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track"])
    }

    let natural = videoTrack.naturalSize
    let t = videoTrack.preferredTransform
    let display = CGSize(width: abs(natural.applying(t).width), height: abs(natural.applying(t).height))

    // Determine output dimensions (for aspect ratio conversion)
    let outputSize: CGSize
    let videoScale: CGFloat
    let videoOffset: CGPoint
    
    if let outW = request.outputWidth, let outH = request.outputHeight, outW > 0, outH > 0 {
      // User specified output dimensions - calculate scale and offset to center video
      outputSize = CGSize(width: CGFloat(outW), height: CGFloat(outH))
      let scaleW = CGFloat(outW) / display.width
      let scaleH = CGFloat(outH) / display.height
      videoScale = min(scaleW, scaleH) // Fit video within output dimensions
      let scaledW = display.width * videoScale
      let scaledH = display.height * videoScale
      videoOffset = CGPoint(x: (CGFloat(outW) - scaledW) / 2, y: (CGFloat(outH) - scaledH) / 2)
    } else {
      // No output dimensions specified - use original display size
      outputSize = display
      videoScale = 1.0
      videoOffset = .zero
    }

    // Use natural size for rendering; transform will handle rotation
    let renderSize = natural
    
    // Prepare overlay for OUTPUT dimensions (where watermark should appear)
    let overlayCI: CIImage? = try Self.prepareOverlayCI(request: request, plugin: plugin, baseWidth: outputSize.width, baseHeight: outputSize.height, transform: CGAffineTransform.identity, naturalSize: outputSize, offsetX: request.offsetX, offsetY: request.offsetY, offsetUnit: request.offsetUnit)

    let reader = try AVAssetReader(asset: asset)
    let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ])
    videoReaderOutput.alwaysCopiesSampleData = false
    guard reader.canAdd(videoReaderOutput) else { throw NSError(domain: "wm", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add video reader output"]) }
    reader.add(videoReaderOutput)

    // Optional audio passthrough (best-effort)
    let audioTrack = asset.tracks(withMediaType: .audio).first
    var audioReaderOutput: AVAssetReaderOutput? = nil
    if let a = audioTrack {
      let out = AVAssetReaderTrackOutput(track: a, outputSettings: nil) // compressed pass-through
      if reader.canAdd(out) {
        reader.add(out)
        audioReaderOutput = out
      }
    }

    let writer = try AVAssetWriter(outputURL: state.outputURL, fileType: .mp4)
    // Video writer input
    let codec: AVVideoCodecType = (request.codec == .hevc) ? .hevc : .h264
    // Use output size for bitrate estimation (final output size)
    let defaultBitrate = Int64(Self.estimateBitrate(width: Int(outputSize.width), height: Int(outputSize.height), fps: Float(videoTrack.nominalFrameRate)))
    let bitrate64: Int64 = request.bitrateBps ?? defaultBitrate
    var compression: [String: Any] = [
      AVVideoAverageBitRateKey: NSNumber(value: bitrate64),
    ]
    if codec == .h264 {
      compression[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
    }
    // Use output size for video settings (final dimensions including letterbox/pillarbox)
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: codec,
      AVVideoWidthKey: Int(outputSize.width),
      AVVideoHeightKey: Int(outputSize.height),
      AVVideoCompressionPropertiesKey: compression,
    ]
    let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    videoInput.expectsMediaDataInRealTime = false
    videoInput.transform = CGAffineTransform.identity // No rotation - we handle it in composition
    guard writer.canAdd(videoInput) else { throw NSError(domain: "wm", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add video writer input"]) }
    writer.add(videoInput)
    // Use output size for pixel buffers
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: Int(outputSize.width),
      kCVPixelBufferHeightKey as String: Int(outputSize.height),
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ])

    // Optional audio writer input (pass-through)
    var audioInput: AVAssetWriterInput? = nil
    if audioReaderOutput != nil {
      let ain = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
      ain.expectsMediaDataInRealTime = false
      if writer.canAdd(ain) {
        writer.add(ain)
        audioInput = ain
      }
    }

    guard writer.startWriting() else { throw writer.error ?? NSError(domain: "wm", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to start writing"]) }
    let startTime = CMTime.zero
    writer.startSession(atSourceTime: startTime)
    guard reader.startReading() else { throw reader.error ?? NSError(domain: "wm", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to start reading"]) }

    let ciContext = plugin.sharedCIContext

    // Background color for letterbox/pillarbox
    let bgColorArgb = request.backgroundColorArgb ?? 0xFF000000 // Default to black
    let bgColor = Self.argbToCIColor(bgColorArgb)
    
    // Apply opacity to overlay (already positioned in output space)
    let preparedOverlay: CIImage? = {
      guard let ov = overlayCI else { return nil }
      // Apply opacity
      let alphaVec = CIVector(x: 0, y: 0, z: 0, w: CGFloat(request.opacity))
      return ov.applyingFilter("CIColorMatrix", parameters: ["inputAVector": alphaVec])
    }()

    // Processing loop
    var lastPTS = CMTime.zero
    var noMoreVideoFrames = false
    while reader.status == .reading && !state.cancelled && !noMoreVideoFrames {
      autoreleasepool {
        if videoInput.isReadyForMoreMediaData {
          if let sample = videoReaderOutput.copyNextSampleBuffer() {
            let pts = CMSampleBufferGetPresentationTimeStamp(sample)
            lastPTS = pts
            guard let pool = adaptor.pixelBufferPool else { return }
            var pb: CVPixelBuffer? = nil
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pb)
            guard let dst = pb else { return }

            // Create base CIImage from sample
            if let srcPB = CMSampleBufferGetImageBuffer(sample) {
              var videoFrame = CIImage(cvPixelBuffer: srcPB)
              
              // Apply transform to handle rotation
              videoFrame = videoFrame.transformed(by: t)
              
              // Scale and position video frame if aspect ratio conversion is enabled
              if videoScale != 1.0 || videoOffset != .zero {
                // Scale video
                let scaleTransform = CGAffineTransform(scaleX: videoScale, y: videoScale)
                videoFrame = videoFrame.transformed(by: scaleTransform)
                
                // Translate to center position
                let translateTransform = CGAffineTransform(translationX: videoOffset.x, y: videoOffset.y)
                videoFrame = videoFrame.transformed(by: translateTransform)
              }
              
              // Create background with specified color
              let background = CIImage(color: CIColor(red: bgColor.red, green: bgColor.green, blue: bgColor.blue, alpha: bgColor.alpha))
                .cropped(to: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
              
              // Composite video on background
              var output = videoFrame.composited(over: background)
              
              // Apply watermark overlay
              if let overlay = preparedOverlay {
                let filter = CIFilter(name: "CISourceOverCompositing")!
                filter.setValue(overlay, forKey: kCIInputImageKey)
                filter.setValue(output, forKey: kCIInputBackgroundImageKey)
                output = filter.outputImage ?? output
              }
              
              // Render using output size
              ciContext.render(output, to: dst, bounds: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height), colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
              _ = adaptor.append(dst, withPresentationTime: pts)
            }

            // Progress
            let p = max(0.0, min(1.0, CMTimeGetSeconds(pts) / max(0.001, duration)))
            // IMPORTANT: Pigeon callbacks MUST be called on main thread
            DispatchQueue.main.async {
              callbacks.onVideoProgress(taskId: taskId, progress: p, etaSec: max(0.0, duration - CMTimeGetSeconds(pts))) { _ in }
            }
          } else {
            // No more video frames available
            noMoreVideoFrames = true
          }
        } else {
          // Back off a little
          usleep(2000)
        }

        // Pump audio opportunistically
        if let aout = audioReaderOutput, let ain = audioInput, ain.isReadyForMoreMediaData {
          if let asample = aout.copyNextSampleBuffer() {
            ain.append(asample)
          }
        }
      }
    }

    if state.cancelled {
      reader.cancelReading()
      videoInput.markAsFinished()
      audioInput?.markAsFinished()
      writer.cancelWriting()
      try? FileManager.default.removeItem(at: state.outputURL)
      DispatchQueue.main.async {
        callbacks.onVideoError(taskId: taskId, code: "cancelled", message: "Cancelled") { _ in }
      }
      onError("cancelled", "Cancelled")
      tasks[taskId] = nil
      return
    }

    // Drain remaining audio
    if let aout = audioReaderOutput, let ain = audioInput {
      while reader.status == .reading || reader.status == .completed {
        if let asample = aout.copyNextSampleBuffer() {
          while !ain.isReadyForMoreMediaData { usleep(2000) }
          ain.append(asample)
        } else { break }
      }
    }

    videoInput.markAsFinished()
    audioInput?.markAsFinished()
    reader.cancelReading()
    
    // Dispatch to main queue to ensure completion handler is called
    DispatchQueue.main.async {
      writer.finishWriting { [weak self] in
        guard let self else { return }
        
        if writer.status == .completed {
          let res = ComposeVideoResult(taskId: taskId,
                                       outputVideoPath: state.outputURL.path,
                                       width: Int64(outputSize.width),
                                       height: Int64(outputSize.height),
                                       durationMs: Int64(duration * 1000.0),
                                       codec: request.codec)
          DispatchQueue.main.async {
            callbacks.onVideoCompleted(result: res) { _ in }
          }
          onComplete(res)
        } else {
          let msg = writer.error?.localizedDescription ?? "Unknown writer error"
          callbacks.onVideoError(taskId: taskId, code: "encode_failed", message: msg) { _ in }
          onError("encode_failed", msg)
        }
        self.tasks[taskId] = nil
      }
    }
  }
  
  private static func argbToCIColor(_ argb: Int64) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    let a = CGFloat((argb >> 24) & 0xFF) / 255.0
    let r = CGFloat((argb >> 16) & 0xFF) / 255.0
    let g = CGFloat((argb >> 8) & 0xFF) / 255.0
    let b = CGFloat(argb & 0xFF) / 255.0
    return (red: r, green: g, blue: b, alpha: a)
  }

  private static func estimateBitrate(width: Int, height: Int, fps: Float) -> Int {
    let bpp: Float = 0.08 // reasonable default for H.264 1080p
    let f = max(24.0, fps > 0 ? fps : 30.0)
    let br = bpp * Float(width * height) * f
    return max(500_000, Int(br))
  }

  private static func prepareOverlayCI(request: ComposeVideoRequest, plugin: WatermarkKitPlugin, baseWidth: CGFloat, baseHeight: CGFloat, transform: CGAffineTransform, naturalSize: CGSize, offsetX: Double, offsetY: Double, offsetUnit: MeasureUnit) throws -> CIImage? {
    // Prepare watermark at display dimensions (what user sees), then transform to natural space
    var overlayImage: CIImage?
    
    // Prefer watermarkImage; fallback to text
    if let data = request.watermarkImage?.data, !data.isEmpty {
      guard let src = decodeCIImage(from: data) else { return nil }
      // Scale by widthPercent of base width
      let targetW = max(1.0, baseWidth * CGFloat(request.widthPercent))
      let extent = src.extent
      let scale = targetW / max(1.0, extent.width)
      overlayImage = src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    } else if let text = request.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      let fontFamily = ".SFUI"
      let fontSizePt = 24.0
      let fontWeight = 600
      let colorArgb: UInt32 = 0xFFFFFFFF
      guard let cg = try WatermarkKitPlugin.renderTextCGImage(text: text, fontFamily: fontFamily, fontSizePt: fontSizePt, fontWeight: fontWeight, colorArgb: colorArgb) else {
        return nil
      }
      let png = WatermarkKitPlugin.encodePNG(cgImage: cg) ?? Data()
      guard let src = decodeCIImage(from: png) else { return nil }
      let targetW = max(1.0, baseWidth * CGFloat(request.widthPercent))
      let extent = src.extent
      let scale = targetW / max(1.0, extent.width)
      overlayImage = src.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    guard let overlay = overlayImage else { return nil }
    
    // Transform overlay from display space to natural space using inverse transform
    // This ensures watermark appears correctly positioned when video transform is applied
    return transformOverlayToNaturalSpace(overlay: overlay, transform: transform, displaySize: CGSize(width: baseWidth, height: baseHeight), naturalSize: naturalSize, anchor: request.anchor, margin: request.margin, marginUnit: request.marginUnit, offsetX: offsetX, offsetY: offsetY, offsetUnit: offsetUnit)
  }
  
  private static func transformOverlayToNaturalSpace(overlay: CIImage, transform: CGAffineTransform, displaySize: CGSize, naturalSize: CGSize, anchor: Anchor, margin: Double, marginUnit: MeasureUnit, offsetX: Double, offsetY: Double, offsetUnit: MeasureUnit) -> CIImage {
    // Get overlay extent
    let overlayExtent = overlay.extent
    
    // Calculate position in display space (where user expects it)
    let marginPx: CGFloat
    switch marginUnit {
    case .percent:
      marginPx = min(displaySize.width, displaySize.height) * CGFloat(margin)
    case .px:
      marginPx = CGFloat(margin)
    @unknown default:
      marginPx = CGFloat(margin)
    }
    
    var displayPos = positionRect(
      base: CGRect(origin: .zero, size: displaySize),
      overlay: overlayExtent,
      anchor: anchor,
      marginX: marginPx,
      marginY: marginPx
    )
    
    // Apply offsets in display space
    let dx = (offsetUnit == .percent) ? CGFloat(offsetX) * displaySize.width : CGFloat(offsetX)
    let dy = (offsetUnit == .percent) ? CGFloat(offsetY) * displaySize.height : CGFloat(offsetY)
    displayPos.x += dx
    displayPos.y += dy
    
    // Determine rotation from transform
    let rotation = atan2(transform.b, transform.a)
    let degrees = rotation * 180 / .pi
    
    // Transform overlay position and rotation to match natural space
    // Strategy: First rotate overlay, then position it correctly in natural coordinates
    var finalTransform = CGAffineTransform.identity
    var rotatedOverlay = overlay
    
    if abs(degrees - 90) < 1 {
      // 90° CCW: portrait video shot upright
      // Rotate overlay 90° CCW to match
      rotatedOverlay = overlay.transformed(by: CGAffineTransform(rotationAngle: .pi / 2))
      let rotatedExtent = rotatedOverlay.extent
      // Map display position to natural position
      let naturalX = displayPos.y
      let naturalY = naturalSize.height - displayPos.x - rotatedExtent.height
      finalTransform = CGAffineTransform(translationX: naturalX, y: naturalY)
    } else if abs(degrees + 90) < 1 {
      // -90° or 270° CW
      // Rotate overlay -90° (or 270°) to match
      rotatedOverlay = overlay.transformed(by: CGAffineTransform(rotationAngle: -.pi / 2))
      let rotatedExtent = rotatedOverlay.extent
      let naturalX = naturalSize.width - displayPos.y - rotatedExtent.width
      let naturalY = displayPos.x
      finalTransform = CGAffineTransform(translationX: naturalX, y: naturalY)
    } else if abs(abs(degrees) - 180) < 1 {
      // 180°: upside down
      rotatedOverlay = overlay.transformed(by: CGAffineTransform(rotationAngle: .pi))
      let rotatedExtent = rotatedOverlay.extent
      let naturalX = naturalSize.width - displayPos.x - rotatedExtent.width
      let naturalY = naturalSize.height - displayPos.y - rotatedExtent.height
      finalTransform = CGAffineTransform(translationX: naturalX, y: naturalY)
    } else {
      // 0° or no rotation - no need to rotate overlay
      finalTransform = CGAffineTransform(translationX: displayPos.x, y: displayPos.y)
    }
    
    return rotatedOverlay.transformed(by: finalTransform)
  }

  private static func decodeCIImage(from data: Data) -> CIImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let cg = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCache: true] as CFDictionary) else {
      return nil
    }
    return CIImage(cgImage: cg, options: [.applyOrientationProperty: true])
  }

  private static func positionRect(base: CGRect, overlay: CGRect, anchor: Anchor, marginX: CGFloat, marginY: CGFloat) -> CGPoint {
    let w = overlay.width
    let h = overlay.height
    switch anchor {
    case .topLeft:
      return CGPoint(x: base.minX + marginX, y: base.maxY - marginY - h)
    case .topRight:
      return CGPoint(x: base.maxX - marginX - w, y: base.maxY - marginY - h)
    case .bottomLeft:
      return CGPoint(x: base.minX + marginX, y: base.minY + marginY)
    case .center:
      return CGPoint(x: base.midX - w * 0.5, y: base.midY - h * 0.5)
    default: // bottomRight
      return CGPoint(x: base.maxX - marginX - w, y: base.minY + marginY)
    }
  }
}
