//
//  ViewController.swift
//  Game.UP
//
//  Created by Marla Nagasaki on 28.05.19.
//  Copyright © 2019 Marla Na. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import SceneKit.ModelIO

class ViewController: UIViewController {
    
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var modelView: SCNView!
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = SCNScene()
        
        // Set the scene to the view
        modelView.scene = scene
        
        // Create Model node
        let node = SCNNode(named: "art.scnassets/Model/OBuildings.scn")
        node.rotation = SCNVector4Make(1, 0, 0, Float(Double.pi / 4))
        node.scale = SCNVector3(x: 1, y: 1, z: 1)
        scene.rootNode.addChildNode(node)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
        
        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
    }
    
}
extension SCNNode {
    
    convenience init(named name: String) {
        self.init()
        
        guard let scene = SCNScene(named: name) else {
            return
        }
        
        for childNode in scene.rootNode.childNodes {
            addChildNode(childNode)
        }
    }
    
}
