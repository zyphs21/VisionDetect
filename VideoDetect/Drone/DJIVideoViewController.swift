//
//  DJIVideoViewController.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/4.
//  Copyright © 2020 Hanson. All rights reserved.
//

import UIKit
import DJISDK
import DJIWidget
import Vision

class DJIVideoViewController: UIViewController {

    @IBOutlet weak var videoPreview: UIView!
    
    var faceDetectRequests = [VNDetectFaceRectanglesRequest]()
    var trackingRequests = [VNTrackObjectRequest]()
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var rootLayer: CALayer!
    var detectionOverlayLayer: CALayer!
    var detectedFaceRectangleShapeLayer: CAShapeLayer!
    var detectedFaceLandmarksShapeLayer: CAShapeLayer!
    var captureDeviceResolution: CGSize?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DJIVideoPreviewer.instance().setView(videoPreview)
        DJIVideoPreviewer.instance().enableHardwareDecode = true
        DJIVideoPreviewer.instance().enableFastUpload = true

        setPitchRangeExtensionEnabled()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscapeLeft, .landscapeRight]
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DJIVideoPreviewer.instance().type = .autoAdapt
        DJIVideoPreviewer.instance()?.registFrameProcessor(self)
        DJIVideoPreviewer.instance()?.start()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        DJIVideoPreviewer.instance().unSetView()
        DJIVideoPreviewer.instance().close()
    }
    
    private func setPitchRangeExtensionEnabled() {
        DJISDKManager.product()?.gimbal?.setPitchRangeExtensionEnabled(true, withCompletion: nil)
    }
    
    // 配置当前视频流的分辨率大小
    private func setupCaptureDeviceResolution(_ resolution: CGSize) {
        guard captureDeviceResolution == nil else { return }
        captureDeviceResolution = resolution
        
        DispatchQueue.main.async {
            self.setupVisionDrawingLayers()
        }
    }
    
    // 当前视频预览可视区域
    var previewAvailableRect: CGRect {
        let bounds = videoPreview.bounds
        guard let key = DJICameraKey(param: DJICameraParamPhotoAspectRatio),
            let value = DJISDKManager.keyManager()?.getValueFor(key),
            let aspectRatio = DJICameraPhotoAspectRatio(rawValue: value.unsignedIntegerValue) else {
                return bounds
        }
        switch aspectRatio {
        case .ratio16_9:
            let size = CGSize(width: 16.0 / 9.0 * bounds.height, height: bounds.height)
            let origin = CGPoint(x: (bounds.width - size.width) / 2.0, y: 0.0)
            return CGRect(origin: origin, size: size)
        case .ratio3_2:
            let size = CGSize(width: 3.0 / 2.0 * bounds.height, height: bounds.height)
            let origin = CGPoint(x: (bounds.width - size.width) / 2.0, y: 0.0)
            return CGRect(origin: origin, size: size)
        case .ratio4_3:
            let size = CGSize(width: 4.0 / 3.0 * bounds.height, height: bounds.height)
            let origin = CGPoint(x: (bounds.width - size.width) / 2.0, y: 0.0)
            return CGRect(origin: origin, size: size)
        case .ratioUnknown:
            return bounds
        @unknown default:
            return bounds
        }
    }
    
    func detectFace(pixelBuffer: CVPixelBuffer) {
        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFace)

        do {
            // 注意无人机图传中照片都是 downMirrored 的，即(0, 0)在左下角
            try sequenceRequestHandler.perform([detectFaceRequest], on: pixelBuffer, orientation: .downMirrored)
        } catch {
            print("----执行 sequenceRequestHandler 失败: \(error.localizedDescription)")
        }
    }
    
    func detectedFace(request: VNRequest, error: Error?) {
        if let error = error {
            print("---detectedFaceRequest Error: \(error.localizedDescription)")
            return
        }
        
        guard let results = request.results as? [VNFaceObservation] else { return }
        
        DispatchQueue.main.async {
            self.drawFaceObservations(results)
        }
    }
}

// MARK: - DJIVideoFeedListener
extension DJIVideoViewController: DJIVideoFeedListener {
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        let videoDataSize = videoData.count
        let videoBuffer = UnsafeMutablePointer<UInt8>(mutating: (videoData as NSData).bytes.bindMemory(to: UInt8.self, capacity: videoDataSize))
        
        DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoDataSize))
    }
}

// MARK: - VideoFrameProcessor
extension DJIVideoViewController: VideoFrameProcessor {
    
    func videoProcessorEnabled() -> Bool {
        return true
    }
    
    func videoProcessFrame(_ frame: UnsafeMutablePointer<VideoFrameYUV>!) {
        let resolution = CGSize(width: CGFloat(frame.pointee.width), height: CGFloat(frame.pointee.height))
        
        if frame.pointee.cv_pixelbuffer_fastupload != nil {
            // 把 cv_pixelbuffer_fastupload 转换成 CVPixelBuffer 对象
            let cvBuf = unsafeBitCast(frame.pointee.cv_pixelbuffer_fastupload, to: CVPixelBuffer.self)
            setupCaptureDeviceResolution(resolution)
            detectFace(pixelBuffer: cvBuf)
        } else {
            // 自行构建 CVPixelBuffer 对象
            let pixelBuffer = frame.pointee.createPixelBuffer()
            setupCaptureDeviceResolution(resolution)
            guard let cvBuf = pixelBuffer else { return }
            detectFace(pixelBuffer: cvBuf)
        }
    }
}
