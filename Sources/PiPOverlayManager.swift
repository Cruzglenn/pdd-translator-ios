import Foundation
import UIKit
import AVKit
import SwiftUI

class PiPOverlayManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    static let shared = PiPOverlayManager()

    @Published var isPiPActive = false
    @Published var currentTranslation: String = "Waiting for Chinese text on screen..."
    @Published var isProcessing: Bool = false

    private var pipController: AVPictureInPictureController?
    private var sampleBufferLayer: AVSampleBufferDisplayLayer?
    private var timer: Timer?

    // Custom view for rendering PiP frames
    private lazy var renderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 480, height: 270))
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.95)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 16, y: 12, width: 448, height: 24))
        label.text = "🇨🇳 ➔ 🇬🇧 Pinduoduo Live Translator"
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.systemYellow
        return label
    }()

    private lazy var contentTextView: UITextView = {
        let tv = UITextView(frame: CGRect(x: 16, y: 40, width: 448, height: 215))
        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        tv.isEditable = false
        tv.isSelectable = false
        return tv
    }()

    override init() {
        super.init()
        setupRenderView()
        setupPiP()
    }

    private func setupRenderView() {
        renderView.addSubview(titleLabel)
        renderView.addSubview(contentTextView)
        contentTextView.text = currentTranslation
    }

    func setupPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            print("Picture in Picture is not supported on this device")
            return
        }

        // Configure audio session to allow background video playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }

        let displayLayer = AVSampleBufferDisplayLayer()
        displayLayer.frame = CGRect(x: 0, y: 0, width: 480, height: 270)
        displayLayer.videoGravity = .resizeAspectFill
        self.sampleBufferLayer = displayLayer

        if #available(iOS 15.0, *) {
            let contentSource = AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: displayLayer,
                playbackDelegate: self
            )
            self.pipController = AVPictureInPictureController(contentSource: contentSource)
            self.pipController?.delegate = self
            self.pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }

    func updateTranslation(text: String, isWorking: Bool = false) {
        DispatchQueue.main.async {
            self.currentTranslation = text
            self.isProcessing = isWorking
            self.contentTextView.text = text
            self.renderFrameToPiP()
        }
    }

    func startPiP() {
        guard let pip = pipController, !pip.isPictureInPictureActive else { return }
        pip.startPictureInPicture()
        isPiPActive = true
        renderFrameToPiP()
    }

    func stopPiP() {
        guard let pip = pipController, pip.isPictureInPictureActive else { return }
        pip.stopPictureInPicture()
        isPiPActive = false
    }

    private func renderFrameToPiP() {
        guard let layer = sampleBufferLayer else { return }

        // Render UIKit view into CMSampleBuffer
        UIGraphicsBeginImageContextWithOptions(renderView.bounds.size, true, 2.0)
        renderView.layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let cgImage = image.cgImage else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()

        if let sampleBuffer = createSampleBuffer(from: cgImage) {
            if layer.status == .failed {
                layer.flush()
            }
            layer.enqueue(sampleBuffer)
        }
    }

    private func createSampleBuffer(from cgImage: CGImage) -> CMSampleBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let width = cgImage.width
        let height = cgImage.height

        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        let pxData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: pxData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, [])
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])

        var videoInfo: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescriptionOut: &videoInfo
        )

        guard let formatDesc = videoInfo else { return nil }

        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: CMTimeValue(CACurrentMediaTime() * 1000), timescale: 1000),
            decodeTimeStamp: .invalid
        )

        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        return sampleBuffer
    }

    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = true }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async { self.isPiPActive = false }
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate
extension PiPOverlayManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: CMTime(value: 100000, timescale: 1))
    }
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool { false }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
