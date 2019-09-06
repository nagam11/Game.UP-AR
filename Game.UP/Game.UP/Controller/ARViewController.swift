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

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    var device: BTDevice? {
        didSet {
            device?.delegate = self
        }
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var textOverlay: UITextField!
    
    @IBOutlet weak var segmentAddMode: UISegmentedControl!
    @IBOutlet weak var segmentType: UISegmentedControl!
    @IBOutlet weak var informationTextView: UITextView!
    //Only one building can be selected at one time or no building
    var selectedBuilding: Int?
    
    //var cubeSize = (0.038, 0.015, 0.034)
    var cubeSize = (0.076, 0.030, 0.068)
    var greenNode : SCNNode? = nil
    var yellowNode : SCNNode? = nil
    var green_active = false
    var yellow_active = false
    var delayForNextGesture = 2000
    var lastGesture = 0
    var clientPath = "http://192.168.2.106:80"
    var address = ""
    var command = ""
    //Store the coordinates of the marker for adding objects.
    var modelCoordinate = simd_float4x4.init()
    var addMode = true
    var enoughFeature = false
    var entryPopUpShown = false
    var selectOtherBuildingShown = false
    
    //Info nodes
    var boxNode = SCNNode()
    
    var b1_info_Node = SCNNode()
    var b2_info_Node = SCNNode()
    var b4_info_Node = SCNNode()
    var b5_info_Node = SCNNode()
    var b6_info_Node = SCNNode()
    
    //Floor nodes
    var b5_first_floor = SCNNode()
    var b5_second_floor: SCNNode? = nil
    var b5_third_floor = SCNNode()
    var b5_first_box: SCNNode? = nil
    var b5_second_box: SCNNode? = nil
    var b5_third_box: SCNNode? = nil
    var b5_forth_box: SCNNode? = nil
    var b5_forth_floor = SCNNode()
    var b4_third_floor = SCNNode()
    var b4_forth_floor = SCNNode()
    var b4_fifth_floor = SCNNode()
    var b4_third_box: SCNNode? = nil
    var b4_forth_box: SCNNode? = nil
    var b4_fifth_box: SCNNode? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- ARKit ---
        
        // Set the view's delegate
        sceneView.delegate = self
        
        self.sceneView.showsStatistics = true
        
        // Enable environment-based lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        self.b5_second_floor = SCNNode()
        self.b5_first_box = SCNNode()
        self.b5_second_box = SCNNode()
        self.b5_third_box = SCNNode()
        self.b4_third_box = SCNNode()
        self.b4_forth_box = SCNNode()
        self.b4_fifth_box = SCNNode()
        
        self.informationTextView.isHidden = true
        self.informationTextView.layer.opacity = 0.7
        self.informationTextView.layer.cornerRadius = 12
        self.informationTextView.layer.borderWidth = 0
        self.segmentType.layer.cornerRadius = 9
        self.segmentAddMode.layer.cornerRadius = 9
        self.segmentAddMode.layer.opacity = 0.8
        self.segmentType.layer.opacity = 0.8
        
        self.segmentType.layer.borderWidth = 0.0
        
        //self.segmentAddMode.layer.borderColor = UIColor.white.cgColor
        self.segmentAddMode.layer.borderWidth = 0.0
        
        // self.segmentType.layer.masksToBounds = true
        //self.segmentAddMode.layer.masksToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Show entry pop up
        if (!entryPopUpShown){
            let alert = UIAlertController(title: "Select one building", message: "Select one building by simply touching on the physical model", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            self.present(alert, animated: true)
            self.entryPopUpShown = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Create a session configuration
        configuration.detectionImages = refImages
        configuration.maximumNumberOfTrackedImages = 1
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func createTextNode(title: String, size: CGFloat, x: Float, y: Float){
        let text = SCNText(string: title, extrusionDepth: 0)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.font = UIFont(name: "Avenir Next", size: size)
        let textNode = SCNNode(geometry: text)
        textNode.position.x = boxNode.position.x - x
        textNode.position.y = boxNode.position.y - y
        textNode.position.z = boxNode.position.z
        self.sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    @IBAction func resetController(_ sender: UIButton) {
    }
    
    @IBAction func didChangeAdding(_ sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0){
            print("ADDING")
            self.addMode = true
            self.informationTextView.isHidden = false
            self.informationTextView.text = "You are in add mode."
            
        } else if (sender.selectedSegmentIndex == 1){
            print("DELETING")
            self.addMode = false
            self.informationTextView.isHidden = false
            self.informationTextView.text = "You are in delete mode."
        }
    }
    @IBAction func testButton(_ sender: UIButton) {
        self.deviceTouchChanged(value: 1)
    }
    
    @IBAction func didChangeType(_ sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0){
            print("RESIDENTIAL")
            //device?.b6_led = false
            device?.b4_led = 0
            
        } else if (sender.selectedSegmentIndex == 1){
            print("AGE")
            //device?.b6_led = false
            device?.b4_led = 0
            device?.b4_led = 2
            self.informationTextView.isHidden = false
            self.informationTextView.text = "All buldings older than 50 years shown."
            
        }
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
        if let clickedNode = self.b5_second_box, clickedNode == result.node {
            print("second floor of B5 clicked")
            clickedNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.b5_first_box?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.b5_second_box?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.b4_third_box?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.b4_forth_box?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.b4_fifth_box?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            //device?.b6_led = true
            device?.b4_led = 1
            self.informationTextView.isHidden = false
            self.informationTextView.text = "Residential buildings have been selected."
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            
            
            //1. Update The Tracking Status
            //print(self.sceneView.session.sessionStatus())
            let currentFrame = self.sceneView.session.currentFrame
            let featurePointCount = currentFrame?.rawFeaturePoints?.points.count
            // print("Number Of Feature Points In Current Session = \(featurePointCount)")
            if (featurePointCount ?? 0 > 100){
                self.enoughFeature = true
            } else {
                self.enoughFeature = false
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if anchor is ARImageAnchor {
            //self.modelCoordinate = anchor.transform
            let anchor = anchor as! ARImageAnchor
            let name = anchor.referenceImage.name!
            sceneView.session.setWorldOrigin(relativeTransform: anchor.transform)
            print("MARKER DETECTED")
            
            //print(frame?.camera.trackingState)
            /*var box = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
             box.firstMaterial?.diffuse.contents = UIColor.blue
             let node = SCNNode(geometry: box)
             node.position = SCNVector3(self.modelCoordinate.columns.3.x,self.modelCoordinate.columns.3.y + 0.1,self.modelCoordinate.columns.3.z)
             let rotationAction = SCNAction.rotateBy(x: 0, y: 0.5, z: 0, duration: 1)
             let inifiniteAction = SCNAction.repeatForever(rotationAction)
             node.runAction(inifiniteAction)
             self.sceneView.scene.rootNode.addChildNode(node)*/
            
            /* //create a transparent gray layer
             let box_2 = SCNBox(width: 0.3, height: 0.3, length: 0.005, chamferRadius: 0)
             box_2.firstMaterial?.diffuse.contents = UIColor.gray
             boxNode = SCNNode(geometry: box_2)
             boxNode.opacity = 0.4
             boxNode.position = SCNVector3(self.modelCoordinate.columns.3.x,self.modelCoordinate.columns.3.y + 0.4,self.modelCoordinate.columns.3.z)
             self.sceneView.scene.rootNode.addChildNode(boxNode)
             */
            //if ( self.enoughFeature){
            let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
            story.firstMaterial?.diffuse.contents = UIColor.gray
            let storyNode = SCNNode(geometry: story)
            storyNode.opacity = 0.8
            //storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.03 ,self.modelCoordinate.columns.3.z - 0.03)
            storyNode.position = SCNVector3Make(-0.02, 0.055, -0.12)
            //storyNode.position = SCNVector3Make(-0.05, -0.09, -0.2)
            //storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y ,self.modelCoordinate.columns.3.z - 0.03)
            self.b5_first_floor.addChildNode(storyNode)
            self.sceneView.scene.rootNode.addChildNode(self.b5_first_floor)
            //}
            
            /*let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
             storyDivider.firstMaterial?.diffuse.contents = UIColor.black
             let storyDividerNode = SCNNode(geometry: storyDivider)
             storyDividerNode.opacity = 1
             // storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.15,self.modelCoordinate.columns.3.y + 0.015,self.modelCoordinate.columns.3.z)
             storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x ,self.modelCoordinate.columns.3.y + 0.01,self.modelCoordinate.columns.3.z - 0.03)
             self.b5_first_floor.addChildNode(storyDividerNode)
             self.sceneView.scene.rootNode.addChildNode(self.b5_first_floor)
             /*==============================================================*/
             let story_2 = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
             story_2.firstMaterial?.diffuse.contents = UIColor.gray
             let storyNode_2 = SCNNode(geometry: story_2)
             storyNode_2.opacity = 0.8
             storyNode_2.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.02 ,self.modelCoordinate.columns.3.z - 0.03)
             self.b5_second_floor!.addChildNode(storyNode_2)
             
             let storyDivider_2 = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
             storyDivider_2.firstMaterial?.diffuse.contents = UIColor.black
             let storyDividerNode_2 = SCNNode(geometry: storyDivider_2)
             storyDividerNode_2.opacity = 1
             storyDividerNode_2.position = SCNVector3(self.modelCoordinate.columns.3.x ,self.modelCoordinate.columns.3.y + 0.03,self.modelCoordinate.columns.3.z - 0.03)
             self.b5_second_floor!.addChildNode(storyDividerNode_2)
             self.sceneView.scene.rootNode.addChildNode(self.b5_second_floor!)
             */
        }
    }
    
    // MARK: - HIDE STATUS BAR
    override var prefersStatusBarHidden : Bool { return true }
}
// MARK: - Shapes
extension ARViewController {
    
    /**
     This functions light up in blue only  the selected building if there is any selected. It turns off all other selections.
     */
    func showSelectedBuilding(){
        //Make sure to turn off all other LEDs
        self.turnOffAllBuilding()
        let navigationVC = storyboard?.instantiateViewController(withIdentifier: "ARNavigationVC") as! ARNavigationController
        let modalVC = navigationVC.viewControllers.first as! ARModalViewController
        if let selectedBuilding = self.selectedBuilding {
            switch selectedBuilding {
            case 0:
                device?.b1_led = 3
                modalVC.bN = "B1"
                modalVC.bT = "Residential"
                modalVC.bY = "1996"
                navigationVC.modalPresentationStyle = .currentContext
                self.present(navigationVC, animated: true, completion: nil)
            // TODO: fix half modal
            case 1:
                device?.b2_led = 3
                modalVC.bN = "B2"
                modalVC.bT = "Office"
                modalVC.bY = "2010"
            case 3:
                device?.b4_led = 3
                modalVC.bN = "B4"
                modalVC.bT = "Residential"
                modalVC.bY = "2001"
            case 5:
                device?.b6_led = 3
                modalVC.bN = "B6"
                modalVC.bT = "Office"
                modalVC.bY = "2013"
            default:
                print("Invalid building to light up")
                return
            }
            show(navigationVC, sender: self)
        }
    }
    
    /**
    This functions shows a popup for selecting another building. Part of demo
    */
    func showSelectNextBuildingPopUp(){
        if(!self.selectOtherBuildingShown){
            let alert = UIAlertController(title: "Select another building", message: "Select another building or click the same building to deselect.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            self.present(alert, animated: true)
            self.selectOtherBuildingShown = true
        }
    }
    
    /**
     This functions turns off all LEDs for all buildings.
     */
    func turnOffAllBuilding(){
        device?.b1_led = 0
        device?.b2_led = 0
        device?.b4_led = 0
        device?.b6_led = 0
    }
    
    // This method creates a cube object and adds it to the scene.
    func createCube(color: UIColor, nextMaterial: Bool, multiplier: Double) {
        let box = SCNBox(width: CGFloat(self.cubeSize.0 + multiplier), height: CGFloat(self.cubeSize.1 + multiplier), length: CGFloat(self.cubeSize.2 + multiplier), chamferRadius: 0.0)
        box.firstMaterial?.diffuse.contents = UIColor.white
        if (color == UIColor.green){
            self.greenNode = SCNNode(geometry: box)
            self.greenNode?.position = SCNVector3Make(0.2, 0, -0.6)
            self.sceneView.scene.rootNode.addChildNode(self.greenNode!)
        }else if (color == UIColor.yellow){
            self.yellowNode = SCNNode(geometry: box)
            self.yellowNode?.position = SCNVector3Make(0, 0, -0.6)
            self.sceneView.scene.rootNode.addChildNode(self.yellowNode!)
        }else {
            box.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: box)
            node.position = SCNVector3Make(Float(0.2 + multiplier), 0, -0.6)
            self.sceneView.scene.rootNode.addChildNode(node)
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
    func deviceB4Changed(value: Int) {
        print("B4 clicked")
        self.informationTextView.isHidden = false
        self.informationTextView.text = "Residential buildings have been selected."
        return
    }
    
    func deviceB6Changed(value: Int) {
        return
    }
    
    func deviceLongTouchB4Changed(value: Int) {
        if(self.addMode){
            switch value {
            case 1:
                let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode = SCNNode(geometry: story)
                storyNode.opacity = 0.8
                storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.04 ,self.modelCoordinate.columns.3.y + 0.04,self.modelCoordinate.columns.3.z - 0.03)
                //storyNode.position = SCNVector3Make(0.038, 0, -0.3)
                self.b4_third_floor.addChildNode(storyNode)
                self.b4_third_box = storyNode
                
                let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode = SCNNode(geometry: storyDivider)
                storyDividerNode.opacity = 1
                storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.04 ,self.modelCoordinate.columns.3.y + 0.05,self.modelCoordinate.columns.3.z - 0.03)
                //storyDividerNode.position = SCNVector3Make(0.038, 0.01, -0.3)
                self.b4_third_floor.addChildNode(storyDividerNode)
                self.sceneView.scene.rootNode.addChildNode(self.b4_third_floor)
            case 2:
                let story_2 = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story_2.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode_2 = SCNNode(geometry: story_2)
                storyNode_2.opacity = 0.8
                storyNode_2.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.04,self.modelCoordinate.columns.3.y + 0.06,self.modelCoordinate.columns.3.z - 0.03)
                self.b4_forth_floor.addChildNode(storyNode_2)
                self.b4_forth_box = storyNode_2
                
                let storyDivider_2 = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider_2.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode_2 = SCNNode(geometry: storyDivider_2)
                storyDividerNode_2.opacity = 1
                storyDividerNode_2.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.04 ,self.modelCoordinate.columns.3.y + 0.07,self.modelCoordinate.columns.3.z - 0.03)
                self.b4_forth_floor.addChildNode(storyDividerNode_2)
                self.sceneView.scene.rootNode.addChildNode(self.b4_forth_floor)
            case 3:
                let story_2 = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story_2.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode_2 = SCNNode(geometry: story_2)
                storyNode_2.opacity = 0.8
                storyNode_2.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.04,self.modelCoordinate.columns.3.y + 0.08,self.modelCoordinate.columns.3.z - 0.03)
                self.b4_fifth_floor.addChildNode(storyNode_2)
                self.b4_fifth_box = storyNode_2
                
                let storyDivider_2 = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider_2.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode_2 = SCNNode(geometry: storyDivider_2)
                storyDividerNode_2.opacity = 1
                storyDividerNode_2.position = SCNVector3(self.modelCoordinate.columns.3.x + 0.04,self.modelCoordinate.columns.3.y + 0.09,self.modelCoordinate.columns.3.z - 0.03)
                self.b4_fifth_floor.addChildNode(storyDividerNode_2)
                self.sceneView.scene.rootNode.addChildNode(self.b4_fifth_floor)
            default:
                return;
            }
        }
        if(!self.addMode){
            
            switch value {
            case 1:
                self.b4_fifth_floor.removeFromParentNode()
            case 2:
                self.b4_forth_floor.removeFromParentNode()
            case 3:
                self.b4_third_floor.removeFromParentNode()
            default:
                return;
            }
            
        }
    }
    
    func deviceLongTouchB5Changed(value: Int) {
        if(self.addMode){
            switch value {
            case 1:
                let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode = SCNNode(geometry: story)
                storyNode.opacity = 0.8
                storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y ,self.modelCoordinate.columns.3.z - 0.03)
                //storyNode.position = SCNVector3Make(0, -0.1, -0.3)
                self.b5_first_floor.addChildNode(storyNode)
                self.b5_first_box = storyNode
                
                let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode = SCNNode(geometry: storyDivider)
                storyDividerNode.opacity = 1
                storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x ,self.modelCoordinate.columns.3.y + 0.01,self.modelCoordinate.columns.3.z - 0.03)
                //storyDividerNode.position = SCNVector3Make(0, -0.090, -0.3)
                self.b5_first_floor.addChildNode(storyDividerNode)
                self.sceneView.scene.rootNode.addChildNode(self.b5_first_floor)
            case 2:
                let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode = SCNNode(geometry: story)
                storyNode.opacity = 0.8
                storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.02 ,self.modelCoordinate.columns.3.z - 0.03)
                // storyNode.position = SCNVector3Make(0, -0.08, -0.3)
                self.b5_second_floor!.addChildNode(storyNode)
                self.b5_second_box = storyNode
                
                let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode = SCNNode(geometry: storyDivider)
                storyDividerNode.opacity = 1
                storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x ,self.modelCoordinate.columns.3.y + 0.03,self.modelCoordinate.columns.3.z - 0.03)
                //storyDividerNode.position = SCNVector3Make(0, -0.07, -0.3)
                self.b5_second_floor?.addChildNode(storyDividerNode)
                self.sceneView.scene.rootNode.addChildNode(self.b5_second_floor!)
            case 3:
                
                let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode = SCNNode(geometry: story)
                storyNode.opacity = 0.8
                storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.04 ,self.modelCoordinate.columns.3.z - 0.03)
                //storyNode.position = SCNVector3Make(0, -0.06, -0.3)
                self.b5_third_floor.addChildNode(storyNode)
                self.b5_third_box = storyNode
                
                let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode = SCNNode(geometry: storyDivider)
                storyDividerNode.opacity = 1
                storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x ,self.modelCoordinate.columns.3.y + 0.05,self.modelCoordinate.columns.3.z - 0.03)
                //storyDividerNode.position = SCNVector3Make(0, -0.050, -0.3)
                self.b5_third_floor.addChildNode(storyDividerNode)
                self.sceneView.scene.rootNode.addChildNode(self.b5_third_floor)
            case 4:
                let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                story.firstMaterial?.diffuse.contents = UIColor.gray
                let storyNode = SCNNode(geometry: story)
                storyNode.opacity = 0.8
                storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.06 ,self.modelCoordinate.columns.3.z - 0.03)
                //storyNode.position = SCNVector3Make(0, -0.06, -0.3)
                self.b5_forth_floor.addChildNode(storyNode)
                self.b5_forth_box = storyNode
                
                let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                let storyDividerNode = SCNNode(geometry: storyDivider)
                storyDividerNode.opacity = 1
                storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x ,self.modelCoordinate.columns.3.y + 0.07,self.modelCoordinate.columns.3.z - 0.03)
                //storyDividerNode.position = SCNVector3Make(0, -0.050, -0.3)
                self.b5_forth_floor.addChildNode(storyDividerNode)
                self.sceneView.scene.rootNode.addChildNode(self.b5_forth_floor)
            default:
                return;
            }
        }
        if(!self.addMode){
            
            switch value {
            case 1:
                self.b5_forth_floor.removeFromParentNode()
            case 2:
                self.b5_third_floor.removeFromParentNode()
            case 3:
                self.b5_second_floor!.removeFromParentNode()
            case 4:
                self.b5_first_floor.removeFromParentNode()
            default:
                return;
            }
            
        }
    }
    
    func deviceSerialChanged(value: String) {
        return
    }
    
    func deviceB2Changed(value: Int) {
        return
    }
    
    // Send value according to the building touched (single touch)
    func deviceTouchChanged(value: Int) {
        print("B\(value + 1) selected.")
        if let selectedBuilding = self.selectedBuilding{
            // If user has clicked on the same building, deselect that building and turn off everything.
            if (selectedBuilding == value){
                self.selectedBuilding = nil
                self.turnOffAllBuilding()
            } else {
                self.selectedBuilding = value
                showSelectedBuilding()
            }
        }
    }
    
    func deviceConnected() {
    }
    
    func deviceDisconnected() {
    }
    
    func deviceReady() {
    }
    
    func deviceB1Changed(value: Int) {
        return
    }
}
//------------------------------------------------
//MARK: ARSession Extension To Log Tracking States
//------------------------------------------------

extension ARSession{
    
    /// Returns The Status Of The Current ARSession
    ///
    /// - Returns: String
    func sessionStatus() -> String? {
        
        //1. Get The Current Frame
        guard let frame = self.currentFrame else { return nil }
        
        var status = "Preparing Device.."
        
        //1. Return The Current Tracking State & Lighting Conditions
        switch frame.camera.trackingState {
            
        case .normal:                                                   status = "Normal"
        case .notAvailable:                                             status = "Tracking Unavailable"
        case .limited(.excessiveMotion):                                status = "Please Slow Your Movement"
        case .limited(.insufficientFeatures):                           status = "Try To Point At A Flat Surface"
        case .limited(.initializing):                                   status = "Initializing"
        case .limited(.relocalizing):                                   status = "Relocalizing"
            
        }
        
        guard let lightEstimate = frame.lightEstimate?.ambientIntensity else { return nil }
        
        if lightEstimate < 100 { status = "Lighting Is Too Dark" }
        
        return status
        
    }
    
}


