//
//  Helper.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/5.
//  Copyright © 2020 Hanson. All rights reserved.
//

import UIKit

class Helper {
    
    /// 弹信息框
    static func showAlert(title: String = "", message: String = "", on viewController: UIViewController? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        if let viewController = viewController {
            viewController.present(alert, animated: true, completion: nil)
        } else {
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    /// 角度转弧度
    static func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }.first?.windows
            .filter { $0.isKeyWindow }.first
    }
}
