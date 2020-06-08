//
//  VisionViewController.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/2.
//  Copyright © 2020 Hanson. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class VisionViewController: UIViewController {

    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    private var faceDetectRequests = [VNDetectFaceRectanglesRequest]()
    private var trackingRequests = [VNTrackObjectRequest]()
    private lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var rootLayer: CALayer!
    var detectionOverlayLayer: CALayer!
    var detectedFaceRectangleShapeLayer: CAShapeLayer!
    var detectedFaceLandmarksShapeLayer: CAShapeLayer!
    
    var captureDeviceResolution: CGSize = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupVisionRequest()
        setupVisionDrawingLayers()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = cameraCaptureResolution.avCaptureSessionPreset
        
        // 获取输入设备
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("----无法获取摄像头")
            return
        }
        captureDevice = device
        do {
            // 创建输入对象
            let input = try AVCaptureDeviceInput(device: device)
            
            // 创建 VideoData 输出对象
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
            
            // 添加 Input 和 Output
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            // 创建预览图层
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            captureSession.startRunning()
            
        } catch {
            print("---AVCaptureDeviceInput Error: \(error.localizedDescription)")
        }
    }
    
    private func setupVisionRequest() {
        let faceDetectRequest = VNDetectFaceRectanglesRequest(completionHandler: faceRectanglesRequestCompleteAction)
        faceDetectRequests = [faceDetectRequest]
    }
    
    private func faceRectanglesRequestCompleteAction(request: VNRequest, error: Error?) {
        trackingRequests.removeAll()
        
        if let error = error {
            print("---VNDetectFaceRectanglesRequest Error: \(error.localizedDescription)")
            return
        }
        
        guard let faceDetectRequest = request as? VNDetectFaceRectanglesRequest
            , let results = faceDetectRequest.results as? [VNFaceObservation] else { return }
        
        // 添加检测结果到跟踪数组
        for observation in results {
            let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
            trackingRequests.append(faceTrackingRequest)
        }
    }
    
    private func performImageRequestHandler(requests: [VNImageBasedRequest],
                                            pixelBuffer: CVImageBuffer,
                                            orientation: CGImagePropertyOrientation,
                                            options: [VNImageOption : AnyObject]) {
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: options)
        
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print("---执行 ImageRequestHandler( 失败: \(error.localizedDescription)")
        }
    }
    
    private func createDetectFaceLandmarkRequest() -> VNDetectFaceLandmarksRequest {
        let faceLandmarkRequest = VNDetectFaceLandmarksRequest { (request, error) in
            if let error = error {
                print("---VNDetectFaceLandmarksRequest Error: \(error.localizedDescription)")
                return
            }
            guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest
                , let results = landmarksRequest.results as? [VNFaceObservation] else { return }
            
            DispatchQueue.main.async {
                self.drawFaceObservations(results)
            }
        }
        return faceLandmarkRequest
    }
    
    private func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
        CATransaction.begin()
        
        CATransaction.setDisableActions(true)
        
        let faceRectanglePath = CGMutablePath()
        let faceLandmarksPath = CGMutablePath()
        
        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               faceLandmarksPath: faceLandmarksPath,
                               for: faceObservation)
        }
        
        detectedFaceRectangleShapeLayer.path = faceRectanglePath
        detectedFaceLandmarksShapeLayer.path = faceLandmarksPath
        
        updateLayerGeometry()
        
        CATransaction.commit()
    }
}

// MARK: - VideoDataOutputSampleBufferDelegate
extension VisionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var requestHandlerOptions = [VNImageOption: AnyObject]()
        
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("---无法获取 PixelBuffer")
            return
        }
        
        let exifOrientation = UIDevice.current.orientation.imagePropertyOrientation
        
        if trackingRequests.isEmpty {
            performImageRequestHandler(requests: faceDetectRequests,
                                       pixelBuffer: pixelBuffer,
                                       orientation: exifOrientation,
                                       options: requestHandlerOptions)
            return
        }
        
        do {
            try sequenceRequestHandler.perform(trackingRequests, on: pixelBuffer, orientation: exifOrientation)
        } catch {
            print("----执行 Sequence trackObjectRequest 失败: \(error.localizedDescription)")
        }
        
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in trackingRequests {
            guard let results = trackingRequest.results else { return }
            guard let observation = results.first as? VNDetectedObjectObservation else { return }
            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        self.trackingRequests = newTrackingRequests
        
        guard newTrackingRequests.count > 0 else { return }
        
        var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()
        
        for trackingRequest in newTrackingRequests {
            
            let faceLandmarksRequest = createDetectFaceLandmarkRequest()
            
            guard let trackingResults = trackingRequest.results else { return }
            guard let observation = trackingResults.first as? VNDetectedObjectObservation else { return }
            let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
            
            faceLandmarksRequest.inputFaceObservations = [faceObservation]
            
            faceLandmarkRequests.append(faceLandmarksRequest)
            
            performImageRequestHandler(requests: faceLandmarkRequests,
                                       pixelBuffer: pixelBuffer,
                                       orientation: exifOrientation,
                                       options: requestHandlerOptions)
        }
        
    }
}
