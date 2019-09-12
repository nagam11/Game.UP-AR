//
//  ARNavigationController.swift
//  Game.UP
//
//  Created by Marla Nagasaki on 06.09.19.
//  Copyright © 2019 Marla Na. All rights reserved.
//

import UIKit

class ARNavigationController: UINavigationController, HalfModalPresentable {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isHalfModalMaximized() ? .default : .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            //Show Alert after transitioning
            let parentVC = self.presentingViewController as! ARViewController
            parentVC.showSelectNextBuildingPopUp()
        }
    }
}

