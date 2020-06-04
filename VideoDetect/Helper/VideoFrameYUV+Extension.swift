//
//  VideoFrameYUV+Extension.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/4.
//  Copyright © 2020 Hanson. All rights reserved.
//

import DJIWidget

extension VideoFrameYUV {
    func createPixelBuffer() -> CVPixelBuffer? {
        var initialPixelBuffer: CVPixelBuffer?
        print("---creatPixel: \(self.width), \(self.height)")
        let _: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.width), Int(self.height), kCVPixelFormatType_420YpCbCr8Planar, nil, &initialPixelBuffer)
        
        guard let pixelBuffer = initialPixelBuffer,
            CVPixelBufferLockBaseAddress(pixelBuffer, []) == kCVReturnSuccess
            else {
                return nil
        }
        
        let yPlaneWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let yPlaneHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        
        let uPlaneWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let uPlaneHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        
        let vPlaneWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 2)
        let vPlaneHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 2)
        
        let yDestination = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        memcpy(yDestination, self.luma, yPlaneWidth * yPlaneHeight)
        
        let uDestination = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
        memcpy(uDestination, self.chromaB, uPlaneWidth * uPlaneHeight)
        
        let vDestination = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2)
        memcpy(vDestination, self.chromaR, vPlaneWidth * vPlaneHeight)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        return pixelBuffer
    }
}
