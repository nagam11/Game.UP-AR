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
    
    // Device Variable for updating the ESP32 board via BLE
    var device: BTDevice? {
        didSet {
            device?.delegate = self
        }
    }
    
    // MARK: - IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var informationTextView: UITextView!
    @IBOutlet weak var stopFilteringButton: UIButton!
    
    // MARK: - AR Variables
    // Only one building can be selected at one time or no building
    var selectedBuilding: Int?
    // Static information regarding buildings
    var buildingsInformation = [["Residential", "Pre-2010"],["Office", "Post-2010"],["Residential", "Post-2010"],["Residential", "Post-2010"],["Office", "Post-2010"],["Office", "Post-2010"],["Residential", "Post-2010"], ["Residential", "Pre-2010"]]
    var cubeSize = (0.076, 0.030, 0.068)
    // Store the coordinates of the marker for adding objects.
    var modelCoordinate = simd_float4x4.init()
    var wantsAR = false
    var addMode = true
    // Variables for demo
    var entryPopUpShown = true
    var selectOtherBuildingShown = false
    var filterBuildingsShown = false
    var markerScanned = false
    var numberOfSelectedBuildings = 0
    var navigationVC: UINavigationController?
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // Keep track of the digital buildings of the three different buildings
    var b3_node = SCNNode()
    var b5_node = SCNNode()
    var b7_node = SCNNode()
    var b3_size = (CGFloat(0.0),CGFloat(0.0))
    var b5_size = (CGFloat(0.0),CGFloat(0.0))
    var b7_size = (CGFloat(0.0),CGFloat(0.0))
     // Users can add a max of 5 floors.
    /*var b3_floors = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    var b3_boxes = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    
    var b5_floors = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    var b5_boxes = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    
    var b7_floors = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    var b7_boxes = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]*/
    
    // Hide status bar
    override var prefersStatusBarHidden : Bool { return true }
    
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
      
        self.stopFilteringButton.isHidden = true
        self.informationTextView.isHidden = true
        self.informationTextView.layer.opacity = 0.7
        self.informationTextView.layer.cornerRadius = 12
        self.informationTextView.layer.borderWidth = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        // let configuration = ARWorldTrackingConfiguration()
        let configuration = ARImageTrackingConfiguration()
        
        // Create a session configuration
        //configuration.detectionImages = refImages
        configuration.trackingImages = refImages
        configuration.maximumNumberOfTrackedImages = 3
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Show entry pop up
        if (!entryPopUpShown){
            let alert = UIAlertController(title: "Select one building", message: "Select one building by simply touching on the physical model", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            //self.present(alert, animated: true)
            self.entryPopUpShown = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    // MARK: - IBActions
    /// This method handles requests for resetting the controller
    /// - Parameter sender: Reset button
    @IBAction func resetController(_ sender: UIButton) {
        // TODO: check this
        self.viewWillAppear(false)
        self.viewDidLoad()
        self.turnOffAllBuilding()
    }
    
    /// This method handles requests for stopping filtering of buildings.
    /// - Parameter sender: Stop filtering button
    @IBAction func stopFilteringClicked(_ sender: UIButton) {
        if (sender.titleLabel!.text == "Done"){
            
        } else {
            self.turnOffAllBuilding()
            self.selectedBuilding = nil
            self.informationTextView.isHidden = true
            self.stopFilteringButton.isHidden = true
        }
    }
    
    /// This method handles requests for adding of deleting buildings.
    /// - Parameter sender: Manage button
    @IBAction func manageClicked(_ sender: UIButton) {
        self.stopFilteringButton.setTitle("Done", for: .normal)
        self.stopFilteringButton.isHidden = false
        let alert = UIAlertController(title: "Do you want to add or delete", message: "Choose if you want to add or delete floors or buildings", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: {action in
            print("Add selected")
            self.informationTextView.isHidden = false
            self.informationTextView.text = "Add Mode"
            self.addMode = true
            self.markerScanned = true
            self.wantsAR = true
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {action in
            print("Delete selected")
            self.informationTextView.isHidden = false
            self.informationTextView.text = "Delete Mode"
            self.addMode = false
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
            print("Cancel selected")
        }))
        self.present(alert, animated: true)
    }
    
    /// This method handles requests for filtering buildings by role and age.
    /// - Parameter sender: Filter button
    @IBAction func filterButtonClicked(_ sender: UIButton) {
        if (self.selectedBuilding != nil){
            let alert = UIAlertController(title: "How do you want to filter", message: "Choose how you want to filter other buildings based on the selected one.", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Role", style: .default, handler: {action in
                print("Role filtering selected")
                self.turnOffAllBuilding()
                self.informationTextView.isHidden = false
                self.stopFilteringButton.isHidden = false
                self.informationTextView.text = "Filtering by role:  \(self.buildingsInformation[self.selectedBuilding!][0])"
                // Light up buildings with the same role including myself
                for (index, building) in self.buildingsInformation.enumerated(){
                    if (building.count != 0){
                        if(building[0] == self.buildingsInformation[self.selectedBuilding!][0]){
                            self.lightUpBuilding(color: 1, building: index)
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Age", style: .default, handler: {action in
                print("Age filtering selected")
                self.turnOffAllBuilding()
                self.informationTextView.isHidden = false
                self.stopFilteringButton.isHidden = false
                self.informationTextView.text = "Filtering by age:  \(self.buildingsInformation[self.selectedBuilding!][1])"
                // TODO: implement Dates and not Strings for age
                // Light up buildings with the same age including myself
                for (index, building) in self.buildingsInformation.enumerated(){
                    if (building.count != 0){
                        if(building[1] == self.buildingsInformation[self.selectedBuilding!][1]){
                            self.lightUpBuilding(color: 2, building: index)
                        }                        
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
                print("Cancel selected")
            }))
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Please select a building first", message: "Select a building in order to filter other buildings around it.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - ARNode Interaction
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
        
        //TODO: handle all clicks
        /*let clickedNode = self.b7_node.childNodes[2].childNodes[0]
        if clickedNode == result.node {
            print("second floor of B7 clicked")
            clickedNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            for i in 1...self.b7_node.childNodes.count-1 {
                    let box = self.b7_node.childNodes[i].childNodes[0]
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                }
            }
            device?.b7_led = 1
            self.informationTextView.isHidden = false */
        }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node = SCNNode()
        //if(self.wantsAR){
        // Marker has been detected
        if let imageAnchor = anchor as? ARImageAnchor {
            print("Marker " + imageAnchor.referenceImage.name! + " detected.")
            // Check which marker are we looking at right now
            let current_marker = imageAnchor.referenceImage.name!
            switch current_marker {
            case "Code1":
                //node = b3_node
                //node.addChildNode(b3_node)
                //print(b3_node.childNodes.count)
                b3_node = node
                b3_size.0 = imageAnchor.referenceImage.physicalSize.width
                b3_size.1 = imageAnchor.referenceImage.physicalSize.height
            case "Code2":
                //node = b5_node
                //node.addChildNode(b5_node)
                b5_node = node
                b5_size.0 = imageAnchor.referenceImage.physicalSize.width
                b5_size.1 = imageAnchor.referenceImage.physicalSize.height
            case "Code3":
               // node = b7_node
                //node.addChildNode(b7_node)
                b7_node = node
                b7_size.0 = imageAnchor.referenceImage.physicalSize.width
                b7_size.1 = imageAnchor.referenceImage.physicalSize.height
            default:
                node = SCNNode()
            }
            // Show a white plane on top of every marker to indicate it has been detected
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.insertChildNode(planeNode, at: 0)
        }
        //}
        return node
    }
}
// MARK: - BLE Commands to ESP32
extension ARViewController {
    
    /// This functions light up in blue only the selected building if there is any selected. It turns off all other selections. It also initates the demo alerts.
    func showSelectedBuilding(){
        //Make sure to turn off all other LEDs
        self.navigationVC = storyboard?.instantiateViewController(withIdentifier: "ARNavigationVC") as! ARNavigationController
        let modalVC = self.navigationVC?.viewControllers.first as! ARModalViewController
        if let selectedBuilding = self.selectedBuilding {
            numberOfSelectedBuildings += 1
            modalVC.bN = "Building \(selectedBuilding + 1)"
            self.turnOffAllBuilding()
            switch selectedBuilding {
            case 0:
                device?.b1_led = 3
                modalVC.pImage = UIImage(named: "6")
            case 1:
                device?.b2_led = 3
                modalVC.pImage = UIImage(named: "2")
            case 2:
                if self.b3_node.childNodes.count > 1 {
                    for i in 1...self.b3_node.childNodes.count-1 {
                        let box = self.b3_node.childNodes[i].childNodes[0]
                        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                }
                modalVC.pImage = UIImage(named: "3")
            case 3:
                device?.b4_led = 3
                modalVC.pImage = UIImage(named: "4")
                
                if self.b7_node.childNodes.count > 1 {
                    for i in 1...self.b7_node.childNodes.count-1 {
                        let box = self.b7_node.childNodes[i].childNodes[0]
                        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                }
            case 4:
                if self.b5_node.childNodes.count > 1 {
                    for i in 1...self.b5_node.childNodes.count-1 {
                        let box = self.b5_node.childNodes[i].childNodes[0]
                        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                }
                modalVC.pImage = UIImage(named: "5")
            case 5:
                device?.b6_led = 3
                modalVC.pImage = UIImage(named: "1")
            case 6:
                device?.b7_led = 3
                modalVC.pImage = UIImage(named: "7")
            case 7:
                device?.b8_led = 3
                modalVC.pImage = UIImage(named: "2")
            default:
                print("Invalid building to light up")
                return
            }
            modalVC.bT = self.buildingsInformation[selectedBuilding][0]
            modalVC.bY = self.buildingsInformation[selectedBuilding][1]
            self.navigationVC?.modalPresentationStyle = .custom
            
            self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: self.navigationVC!)
            
            
            self.navigationVC!.transitioningDelegate = self.halfModalTransitioningDelegate
            self.present(self.navigationVC!, animated: true, completion: nil)
            // TODO: fix half modal
            //show(navigationVC!, sender: self)
        }
    }
    
    /// This functions turns off all LEDs for all buildings.
    func turnOffAllBuilding(){
        device?.b1_led = 0
        device?.b2_led = 0
        device?.b4_led = 0
        device?.b6_led = 0
        device?.b7_led = 0
        device?.b8_led = 0
    }
    
    ///  This functions shows a popup for selecting another building and for filtering buildings. Part of demo
    func showSelectNextBuildingPopUp(){
        if(!self.selectOtherBuildingShown){
            let alert = UIAlertController(title: "Select another building", message: "Select another building or click on the same building to deselect.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            //self.present(alert, animated: true)
            self.selectOtherBuildingShown = true
        } else if (self.numberOfSelectedBuildings > 4 && !self.filterBuildingsShown){
            print(self.numberOfSelectedBuildings)
            let alert = UIAlertController(title: "Filter buildings", message: "Click on the filter button below to filter buildings by age or role.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
          // self.present(alert, animated: true)
            self.filterBuildingsShown = true
        }
    }
}

// MARK: - BTDeviceDelegate
extension ARViewController: BTDeviceDelegate {
    
    ///  Lights up a given bulding with specific color. If buildings is a plate, it lights up the digital levels in case they exist.
    /// - Parameters:
    ///   - color: Color to be shown
    ///   - building:  Building index
       func lightUpBuilding(color : Int, building: Int){
           switch building {
           case 0:
               device?.b1_led = color
           case 1:
               device?.b2_led = color
           case 2:
               if self.b3_node.childNodes.count > 1 {
               for i in 1...self.b3_node.childNodes.count-1 {
                   let box = self.b3_node.childNodes[i].childNodes[0]
                       if (color == 1){
                           box.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                       } else if (color == 2){
                           box.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                       } else if (color == 0 ){
                           box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                       }
                   }
               }
           case 3:
               device?.b4_led = color
           case 4:
               if self.b5_node.childNodes.count > 1 {
               for i in 1...self.b5_node.childNodes.count-1 {
                   let box = self.b5_node.childNodes[i].childNodes[0]
                       if (color == 1){
                           box.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                       } else if (color == 2){
                           box.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                       } else if (color == 0 ){
                           box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                       }
                   }
               }
           case 5:
               device?.b6_led = color
           case 6:
                device?.b7_led = color
                if self.b7_node.childNodes.count > 1 {
                for i in 1...self.b7_node.childNodes.count-1 {
                    let box = self.b7_node.childNodes[i].childNodes[0]
                        if (color == 1){
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        } else if (color == 2){
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                        } else if (color == 0 ){
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                        }
                   }
                }
           case 7:
                device?.b8_led = color
           default:
               print("Invalid building to light up")
               return
           }
       }
    
    /// This method handles long touch notification for building 3.
    /// - Parameter value: The added level/story
    func deviceLongTouchB3Changed(value: Int) {
        if(self.markerScanned){
            if(self.addMode){
                switch value {
                case 1:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b3_size.0, height:CGFloat(self.cubeSize.1), length: b3_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    
                    let storyDivider = SCNBox(width: b3_size.0, height: 0.005, length: b3_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b3_node.insertChildNode(full_story, at: 1)
                case 2:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b3_size.0, height:CGFloat(self.cubeSize.1), length: b3_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.035
                    
                    let storyDivider = SCNBox(width: b3_size.0, height: 0.005, length: b3_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b3_node.insertChildNode(full_story, at: 2)
                case 3:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b3_size.0, height:CGFloat(self.cubeSize.1), length: b3_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.07
                   
                    let storyDivider = SCNBox(width: b3_size.0, height: 0.005, length: b3_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                   full_story.insertChildNode(storyNode, at: 0)
                   full_story.insertChildNode(storyDividerNode, at: 1)
                   self.b3_node.insertChildNode(full_story, at: 3)
                case 4:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b3_size.0, height:CGFloat(self.cubeSize.1), length: b3_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.105
                    
                    let storyDivider = SCNBox(width: b3_size.0, height: 0.005, length: b3_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b3_node.insertChildNode(full_story, at: 4)
                    let alert = UIAlertController(title: "Delete buildings", message: "Try deleting buildings by selecting delete on the bottom.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
                   //self.present(alert, animated: true)
                default:
                    return;
                }
            }
            if(!self.addMode){
              self.b3_node.childNodes.last?.removeFromParentNode()
            }}
        
    }
    
    /// This method handles long touch notification for building 5.
    /// - Parameter value: The added level/story
    func deviceLongTouchB5Changed(value: Int) {
        if(self.markerScanned){
            if(self.addMode){
                switch value {
                case 1:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b5_size.0, height:CGFloat(self.cubeSize.1), length: b5_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                   
                    let storyDivider = SCNBox(width: b5_size.0, height: 0.005, length: b5_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b5_node.insertChildNode(full_story, at: 1)
                case 2:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b5_size.0, height:CGFloat(self.cubeSize.1), length: b5_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.035
                   
                    let storyDivider = SCNBox(width: b5_size.0, height: 0.005, length: b5_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b5_node.insertChildNode(full_story, at: 2)
                case 3:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b5_size.0, height:CGFloat(self.cubeSize.1), length: b5_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.07
                    
                    let storyDivider = SCNBox(width: b5_size.0, height: 0.005, length: b5_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                   storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                   full_story.insertChildNode(storyNode, at: 0)
                   full_story.insertChildNode(storyDividerNode, at: 1)
                   self.b5_node.insertChildNode(full_story, at: 3)
                case 4:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b5_size.0, height:CGFloat(self.cubeSize.1), length: b5_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.105
                    
                    let storyDivider = SCNBox(width: b5_size.0, height: 0.005, length: b5_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b5_node.insertChildNode(full_story, at: 4)
                    
                    let alert = UIAlertController(title: "Delete buildings", message: "Try deleting buildings by selecting delete on the bottom.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
                    //self.present(alert, animated: true)
                default:
                    return;
                }
            }
            if(!self.addMode){
                self.b5_node.childNodes.last?.removeFromParentNode()
            }
        }
    }
    
    /// This method handles long touch notification for building 7.
    /// - Parameter value: The added level/value
    func deviceLongTouchB7Changed(value: Int) {
        if(self.markerScanned){
            if(self.addMode){
                switch value {
                case 1:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b7_size.0, height:CGFloat(self.cubeSize.1), length: b7_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    
                    let storyDivider = SCNBox(width: b7_size.0, height: 0.005, length: b7_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b7_node.insertChildNode(full_story, at: 1)
                case 2:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b7_size.0, height:CGFloat(self.cubeSize.1), length: b7_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.035
                    
                    let storyDivider = SCNBox(width: b7_size.0, height: 0.005, length: b7_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                   full_story.insertChildNode(storyNode, at: 0)
                   full_story.insertChildNode(storyDividerNode, at: 1)
                   self.b7_node.insertChildNode(full_story, at: 2)
                case 3:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b7_size.0, height:CGFloat(self.cubeSize.1), length: b7_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.07
                   
                    let storyDivider = SCNBox(width: b7_size.0, height: 0.005, length: b7_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b7_node.insertChildNode(full_story, at: 3)
                case 4:
                    let full_story = SCNNode()
                    let story = SCNBox(width: b7_size.0, height:CGFloat(self.cubeSize.1), length: b7_size.1, chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.eulerAngles.x = .pi
                    storyNode.position.y = storyNode.position.y + 0.105
                    
                    let storyDivider = SCNBox(width: b7_size.0, height: 0.005, length: b7_size.1, chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.eulerAngles.x = .pi
                    storyDividerNode.position.y = storyNode.position.y + 0.0175
                    full_story.insertChildNode(storyNode, at: 0)
                    full_story.insertChildNode(storyDividerNode, at: 1)
                    self.b7_node.insertChildNode(full_story, at: 4)
                    
                    let alert = UIAlertController(title: "Delete buildings", message: "Try deleting buildings by selecting delete on the bottom.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
                   // self.present(alert, animated: true)
                default:
                    return;
                }
            }
            if(!self.addMode){
                self.b7_node.childNodes.last?.removeFromParentNode()
            }}
    }
    
    /// This method receives the values according to the building touched (single touch)
    /// - Parameter value: The building index
    func deviceTouchChanged(value: Int) {
        self.navigationVC?.dismiss(animated: true, completion: nil)
        print("B\(value + 1) selected.")
        if let selectedBuilding = self.selectedBuilding{
            if (selectedBuilding == value){
                self.selectedBuilding = nil
                self.turnOffAllBuilding()
                switch selectedBuilding {
                case 0:
                    device?.b1_led = 0
                case 1:
                    device?.b2_led = 0
                case 3:
                    device?.b4_led = 0
                case 5:
                    device?.b6_led = 0
                case 6:
                    device?.b7_led = 0
                case 7:
                    device?.b8_led = 0
                default:
                    print("Invalid building to light off")
                    return
                }
            } else {
                turnOffAllBuilding()
                self.selectedBuilding = value
                showSelectedBuilding()}
            
        } else {
            turnOffAllBuilding()
            self.selectedBuilding = value
            showSelectedBuilding()}
    }
}
