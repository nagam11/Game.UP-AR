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
import UserNotifications
import Vision

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    var visionRequests = [VNRequest]()
    
    var device: BTDevice? {
        didSet {
            device?.delegate = self
        }
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var textOverlay: UITextField!
    
    var cubeSize = (0.1, 0.1, 0.1)
    var greenNode : SCNNode? = nil
    var yellowNode : SCNNode? = nil
    var green_active = false
    var yellow_active = false
    var delayForNextGesture = 2000
    var lastGesture = 0
    
    
    var clientPath = "http://192.168.2.106:80"
    var address = ""
    var command = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- ARKit ---
        
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
        
        // --- ML & VISION ---
        
        // Setup Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: example_5s0_hand_model().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project. Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
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
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: false, completion: nil)
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
                //self.sendHTTPMessage(command: command)
                device?.green = false
            } else {
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                command += "/G"
                device?.green = true
                //self.sendHTTPMessage(command: command)
            }
        }
        if let planeNode = yellowNode, planeNode == result.node {
            print("YELLOW BOX CLICKED")
            if  (planeNode.geometry?.firstMaterial?.diffuse.contents as! UIColor == UIColor.yellow){
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                command += "/Yo"
                device?.yellow = false
                //self.sendHTTPMessage(command: command)
            } else {
                planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                command += "/Y"
                device?.yellow = true
                //self.sendHTTPMessage(command: command)
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    // MARK: - MACHINE LEARNING
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
    }
    
    func updateCoreML() {
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Run Vision Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...2] // top 3 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:" : %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        // Render Classifications
        DispatchQueue.main.async {
  
            // Display Top Symbol
            var symbol = "❎"
            let topPrediction = classifications.components(separatedBy: "\n")[0]
            let topPredictionName = topPrediction.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
            // Only display a prediction if confidence is above 1%
            let topPredictionScore:Float? = Float(topPrediction.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces))
            if (topPredictionScore != nil && topPredictionScore! > 0.01) {
                if (topPredictionName == "fist-UB-RHand") { symbol = "👊" }
                if (topPredictionName == "FIVE-UB-RHand") { symbol = "🖐" }
            }
            self.textOverlay.text = symbol
            
            let currentTime = Int(round(NSDate().timeIntervalSince1970*1000))
            if (topPredictionName == "fist-UB-RHand") {
                let  delay = currentTime - self.lastGesture
                if(self.green_active && delay > self.delayForNextGesture){
                    /*self.greenNode?.geometry!.firstMaterial?.diffuse.contents = UIColor.white
                    self.green_active = false
                    self.device?.green = false
                    self.lastGesture = currentTime*/
                } else if (!self.green_active && delay > self.delayForNextGesture) {
                    /*self.greenNode?.geometry!.firstMaterial?.diffuse.contents = UIColor.green
                    self.green_active = true
                    //self.device?.green = true
                    self.lastGesture = currentTime*/
                }
            }
        }
    }
    
    // MARK: - HIDE STATUS BAR
    override var prefersStatusBarHidden : Bool { return true }
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
extension ARViewController: BTDeviceDelegate {
    func deviceSerialChanged(value: String) {
        
    }
    
    func deviceYellowChanged(value: Bool) {
        if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "ESP Blinky"
            content.body = value ? "Now blinking" : "Not blinking anymore"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("DeviceVC: failed to deliver notification \(error)")
                }
            }
        }
    }
    
    func deviceTouchChanged(value: Int) {
        if(value == 0){
            if(green_active){
                self.greenNode?.geometry!.firstMaterial?.diffuse.contents = UIColor.white
                self.green_active = false
            } else {
                self.greenNode?.geometry!.firstMaterial?.diffuse.contents = UIColor.green
                self.green_active = true
            }
        } else if (value == 1){
            if(yellow_active){
                self.yellowNode?.geometry!.firstMaterial?.diffuse.contents = UIColor.white
                self.yellow_active = false
            } else {
                self.yellowNode?.geometry!.firstMaterial?.diffuse.contents = UIColor.yellow
                self.yellow_active = true
            }
        }
    }
    
    func deviceConnected() {
    }
    
    func deviceDisconnected() {
    }
    
    func deviceReady() {
    }
    
    func deviceGreenChanged(value: Bool) {
        
        if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "ESP Blinky"
            content.body = value ? "Now blinking" : "Not blinking anymore"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("DeviceVC: failed to deliver notification \(error)")
                }
            }
        }
    }
}


