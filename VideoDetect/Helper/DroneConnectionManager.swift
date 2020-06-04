//
//  DroneConnectionManager.swift
//  VideoDetect
//
//  Created by Hanson on 2020/6/3.
//  Copyright © 2020 Hanson. All rights reserved.
//

import Foundation
import DJISDK

class DroneConnectionManger: NSObject {
    static let shared = DroneConnectionManger()
    
    var enableBridgeMode = false
    let bridgeAppIP = "192.168.1.203"
    
    var activationState: DJIAppActivationState = .unknown
    var aircraftBindingState: DJIAppActivationAircraftBindingState = .unknown
    
    func registerApp() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        guard let appKeys = appKey, !appKeys.isEmpty else {
            UIApplication.showAlert(message: "Please enter your app key in the info.plist")
            return
        }
        DJISDKManager.registerApp(with: self)
    }
}

extension DroneConnectionManger: DJISDKManagerDelegate {

    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            UIApplication.showAlert(message: "SDK Registered with error \(error.localizedDescription)")
        } else {
            if enableBridgeMode {
                print("SDK Registered success,startConnectionToProduct with bridgeMode")
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            } else {
                print("SDK Registered success,startConnectionToProduct")
                DJISDKManager.startConnectionToProduct()
            }
        }
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        print("productConnected")
    }
    
    func productDisconnected() {
        UIApplication.showAlert(message: "productDisconnected")
    }
    
    func componentConnected(withKey key: String?, andIndex index: Int) {
        
    }
    
    func componentDisconnected(withKey key: String?, andIndex index: Int) {
        
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        
    }
    
}

extension DJIAppActivationState {
    var description: String {
        switch self {
        case .loginRequired:
            return "Login is required to activate."
        case .unknown:
            return "Unknown"
        case .activated:
            return "Activated"
        case .notSupported:
            return "App Activation is not supported"
        @unknown default:
            fatalError()
        }
    }
}

extension DJIAppActivationAircraftBindingState {
    var description: String {
        switch self {
        case .unboundButCannotSync:
            return "Unbound. Please connect Internet to update state. "
        case .unbound:
            return "Unbound. Use DJI GO to bind the aircraft. "
        case .unknown:
            return "Unknown"
        case .bound:
            return "Bound"
        case .initial:
            return "Initial"
        case .notRequired:
            return "Binding is not required. "
        case .notSupported:
            return "App Activation is not supported. "
        @unknown default:
            fatalError()
        }
    }
}

extension UIApplication {
    class func showAlert(title: String = "", message: String = "", on viewController: UIViewController? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        if let viewController = viewController {
            viewController.present(alert, animated: true, completion: nil)
        } else {
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
