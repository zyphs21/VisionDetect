//
//  UIDeviceOrientation+Extension.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/2.
//  Copyright © 2020 Hanson. All rights reserved.
//

import UIKit

extension UIDeviceOrientation {
    var imagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .portraitUpsideDown:
            return .rightMirrored
        case .landscapeLeft:
            return .downMirrored
        case .landscapeRight:
            return .upMirrored
        default:
            return .leftMirrored
        }
    }
}
