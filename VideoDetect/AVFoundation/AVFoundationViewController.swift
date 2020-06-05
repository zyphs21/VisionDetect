//
//  AVFoundationViewController.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/1.
//  Copyright © 2020 Hanson. All rights reserved.
//

import UIKit
import AVFoundation

enum CameraCaptureResolution: Int {
    case high, medium, low
    
    var avCaptureSessionPreset: AVCaptureSession.Preset {
        switch self {
        case .high:
            return AVCaptureSession.Preset.high
        case .medium:
            return AVCaptureSession.Preset.medium
        case .low:
            return AVCaptureSession.Preset.low
        }
    }
}

var cameraCaptureResolution: CameraCaptureResolution = .medium

class AVFoundationViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var detectedViews = [UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = cameraCaptureResolution.avCaptureSessionPreset
        
        // 获取输入设备
        // AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: .back)
        // let device = AVCaptureDevice.default(for: AVMediaType.video)
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        
        do {
            // 创建输入对象
            let input = try AVCaptureDeviceInput(device: device!)
            captureSession.addInput(input)
            
            // 创建输出对象
            let metaOutput = AVCaptureMetadataOutput()
            metaOutput.rectOfInterest = view.bounds // 扫描区域
            // 注意不要在这里设置 metaOutput.metadataObjectTypes = [.face]
            // metaOutput.availableMetadataObjectTypes 此时是空的，因为没有把 input 和 output 添加到 session 中
            metaOutput.setMetadataObjectsDelegate(self, queue: .main)
            captureSession.addOutput(metaOutput)
            /*
             let videoOutput = AVCaptureVideoDataOutput()
             videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
             videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
             captureSession.addOutput(videoOutput)
             */
            
            // 配置识别人脸; 需在 addInput 和 addOutput 后调用
            metaOutput.metadataObjectTypes = [.face]
            
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
}

// MARK: - MetadataOutputObjectsDelegate
extension AVFoundationViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        detectedViews.forEach { $0.removeFromSuperview() }
        detectedViews.removeAll()
        
        for metaObject in metadataObjects {
            guard let transformedObject = previewLayer.transformedMetadataObject(for: metaObject) else { continue }
            let objectRect = transformedObject.bounds
            let detectedView = UIView(frame: objectRect)
            detectedView.layer.borderWidth = 2
            detectedView.layer.borderColor = UIColor.red.cgColor
            view.addSubview(detectedView)
            detectedViews.append(detectedView)
        }
    }
}
