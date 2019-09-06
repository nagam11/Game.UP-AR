//
//  ARModalViewController.swift
//  Game.UP
//
//  Created by Marla Nagasaki on 06.09.19.
//  Copyright © 2019 Marla Na. All rights reserved.
//

import UIKit

class ARModalViewController: UIViewController, HalfModalPresentable {
  
    @IBOutlet weak var buildingName: UILabel!
    @IBOutlet weak var buildingType: UILabel!
    @IBOutlet weak var buildingYear: UILabel!
    var bN = ""
    var bT = ""
    var bY = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.buildingName.text = bN
        self.buildingType.text = bT
        self.buildingYear.text = bY
    }
    
    @IBAction func maximizeButtonTapper(_ sender: UIBarButtonItem) {
        maximizeToFullScreen()
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        if let delegate = navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
                   delegate.interactiveDismiss = false
               }
               dismiss(animated: true, completion: nil)
    }
}
