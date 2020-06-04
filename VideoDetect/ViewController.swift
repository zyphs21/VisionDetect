//
//  ViewController.swift
//  VideoDetect
//
//  Created by Hanson on 2020/5/31.
//  Copyright © 2020 Hanson. All rights reserved.
//

import UIKit
import DJISDK

class ViewController: UIViewController {

    @IBOutlet weak var activationStateLabel: UILabel!
    @IBOutlet weak var AircraftBindingStateLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DroneConnectionManger.shared.registerApp()
        DJISDKManager.appActivationManager().delegate = self
        activationStateLabel.text = DJISDKManager.appActivationManager().appActivationState.description
        AircraftBindingStateLabel.text = DJISDKManager.appActivationManager().aircraftBindingState.description
    }
    
    @IBAction func loginDJIAccount(_ sender: Any) {
        DJISDKManager.userAccountManager().logIntoDJIUserAccount(withAuthorizationRequired: true) { (userAccountState, error) in
            if let error = error {
                print("Login error: " + error.localizedDescription)
                UIApplication.showAlert(message: "Login error: " + error.localizedDescription)
            } else {
                print("Login Success")
            }
        }
    }
    
}


// MARK: - DJIAppActivationManagerDelegate
extension ViewController: DJIAppActivationManagerDelegate {
    
    func manager(_ manager: DJIAppActivationManager!, didUpdate appActivationState: DJIAppActivationState) {
        activationStateLabel.text = appActivationState.description
    }
    
    func manager(_ manager: DJIAppActivationManager!, didUpdate aircraftBindingState: DJIAppActivationAircraftBindingState) {
        AircraftBindingStateLabel.text = aircraftBindingState.description
    }
}

