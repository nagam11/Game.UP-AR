//
//  ViewController.swift
//  Game.UP
//
//  Created by Marla Nagasaki on 28.05.19.
//  Copyright © 2019 Marla Na. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var cubeSize = (0.1, 0.1, 0.1)
    var greenNode : SCNNode? = nil
    var yellowNode : SCNNode? = nil
    
    var clientPath = "http://192.168.2.106:80"
    var address = ""
    var command = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        self.createCube(color: UIColor.green, nextMaterial: false, multiplier: 0)
        self.createCube(color: UIColor.yellow, nextMaterial: false, multiplier: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Get first touch
        guard let touch = touches.first else {
            return
        }
        // Get location in the scene
        let location = touch.location(in: self.sceneView)
      
        guard let result = self.sceneView.hitTest(location, options: nil).first else {
            return
        }
        if let planeNode = greenNode, planeNode == result.node {
            print("GREEN BOX CLICKED")
            if  (planeNode.geometry?.firstMaterial?.diffuse.contents as! UIColor == UIColor.green){
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                command += "/Go"
                self.sendHTTPMessage(command: command)
            } else {
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                command += "/G"
                self.sendHTTPMessage(command: command)
            }
        }
        if let planeNode = yellowNode, planeNode == result.node {
            print("YELLOW BOX CLICKED")
            if  (planeNode.geometry?.firstMaterial?.diffuse.contents as! UIColor == UIColor.yellow){
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                command += "/Yo"
                self.sendHTTPMessage(command: command)
            } else {
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                command += "/Y"
                self.sendHTTPMessage(command: command)
            }
        }
    }
}
// MARK: - Shapes
extension ARViewController {
    
    // This method creates a cube object and adds it to the scene.
    func createCube(color: UIColor, nextMaterial: Bool, multiplier: Double) {
        let box = SCNBox(width: CGFloat(self.cubeSize.0 + multiplier), height: CGFloat(self.cubeSize.1 + multiplier), length: CGFloat(self.cubeSize.2 + multiplier), chamferRadius: 0.0)
            box.firstMaterial?.diffuse.contents = UIColor.white
        if (color == UIColor.green){
            self.greenNode = SCNNode(geometry: box)
            self.greenNode?.position = SCNVector3Make(0, 0, -0.6)
            self.sceneView.scene.rootNode.addChildNode(self.greenNode!)
        }else if (color == UIColor.yellow){
            self.yellowNode = SCNNode(geometry: box)
            self.yellowNode?.position = SCNVector3Make(0.2, 0, -0.6)
            self.sceneView.scene.rootNode.addChildNode(self.yellowNode!)
        }
    }
}
// MARK: - Server
extension ARViewController {
    
    func sendHTTPMessage(command: String){
        let url = URL(string: "\(self.clientPath)\(command)")
        print(url?.absoluteString as! String)
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            guard error == nil else {
                print("ERROR : \(error!)")
                return
            }
            do {print("Message: \(command) was sent")}
        }
        task.resume()
        self.address = ""
        self.command = ""
    }
}


