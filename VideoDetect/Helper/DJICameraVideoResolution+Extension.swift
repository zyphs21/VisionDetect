//
//  DJICameraVideoResolution+Extension.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/4.
//  Copyright © 2020 Hanson. All rights reserved.
//

import DJISDK

extension DJICameraVideoResolution {
    var size: CGSize {
        switch self {
        case .resolution336x256:
            return CGSize(width: 336, height: 256)
        case .resolution640x360:
            return CGSize(width: 640, height: 360)
        case .resolution640x480:
            return CGSize(width: 640, height: 480)
        case .resolution640x512:
            return CGSize(width: 640, height: 512)
        case .resolution1280x720:
            return CGSize(width: 1280, height: 720)
        case .resolution1920x1080:
            return CGSize(width: 1920, height: 1080)
        case .resolution2048x1080:
            return CGSize(width: 2048, height: 1080)
        case .resolution2688x1512:
            return CGSize(width: 2688, height: 1512)
        case .resolution2704x1520:
            return CGSize(width: 2704, height: 1520)
        case .resolution2720x1530:
            return CGSize(width: 2720, height: 1530)
        case .resolution3712x2088:
            return CGSize(width: 3712, height: 2088)
        case .resolution3840x1572:
            return CGSize(width: 3840, height: 1572)
        case .resolution3840x2160:
            return CGSize(width: 3840, height: 2160)
        case .resolution3944x2088:
            return CGSize(width: 3944, height: 2088)
        case .resolution4096x2160:
            return CGSize(width: 4096, height: 2160)
        case .resolution4608x2160:
            return CGSize(width: 4608, height: 2160)
        case .resolution4608x2592:
            return CGSize(width: 4608, height: 2592)
        case .resolution5280x2160:
            return CGSize(width: 5280, height: 2160)
        case .resolution5280x2972:
            return CGSize(width: 5280, height: 2972)
        case .resolution5760x3240:
            return CGSize(width: 5760, height: 3240)
        case .resolution6016x3200:
            return CGSize(width: 6016, height: 3200)
        case .resolutionMax:
            return .zero
        case .resolutionNoSSDVideo:
            return .zero
        case .resolutionUnknown:
            return .zero
        @unknown default:
            return .zero
        }
    }
}
