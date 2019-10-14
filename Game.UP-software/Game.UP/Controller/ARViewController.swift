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
    var buildingsInformation = [["Residential", "Pre-2010"],["Office", "Post-2010"],[],["Residential", "Post-2010"],[],["Office", "Post-2010"],["Residential", "Post-2010"], ["Residential", "Pre-2010"]]
    var cubeSize = (0.076, 0.030, 0.068)
    // Store the coordinates of the marker for adding objects.
    var modelCoordinate = simd_float4x4.init()
    var wantsAR = false
    var addMode = true
    // Variables for demo
    var entryPopUpShown = false
    var selectOtherBuildingShown = false
    var filterBuildingsShown = false
    var markerScanned = false
    var numberOfSelectedBuildings = 0
    var navigationVC: UINavigationController?
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // Users can add a max of 5 floors.
    var b3_floors = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    var b3_boxes = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    
    var b5_floors = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    var b5_boxes = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    
    var b7_floors = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    var b7_boxes = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
    
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
            self.present(alert, animated: true)
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
        let clickedNode = self.b7_boxes[2]
        if clickedNode == result.node {
            print("second floor of B7 clicked")
            clickedNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            if b7_boxes.count > 0 {
                for box in b7_boxes {
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                }
            }
            device?.b7_led = 1
            self.informationTextView.isHidden = false
        }
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        print(wantsAR)
        //if(self.wantsAR){
        // Marker has been detected
        if let imageAnchor = anchor as? ARImageAnchor {
            print("MARKER DETECTED")
            self.markerScanned = true
            // register the location and add only if long touch or hide ?
            // Show a white plane on top of marker
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            
            /*let shipScene = SCNScene(named: "art.scnassets/ship.scn")!
            let shipNode = shipScene.rootNode.childNodes.first!
            shipNode.position = SCNVector3Zero
            shipNode.position.z = 0.15
            
            planeNode.addChildNode(shipNode)
            */
            
            let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
            story.firstMaterial?.diffuse.contents = UIColor.gray
            let storyNode = SCNNode(geometry: story)
            storyNode.opacity = 0.8
            storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.08,self.modelCoordinate.columns.3.z - 0.12)
            let b3_third_floor = SCNNode()
            b3_third_floor.addChildNode(storyNode)
            self.b3_floors[0] = b3_third_floor
            
            let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
            storyDivider.firstMaterial?.diffuse.contents = UIColor.black
            let storyDividerNode = SCNNode(geometry: storyDivider)
            storyDividerNode.opacity = 1
            storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.07,self.modelCoordinate.columns.3.z - 0.12)
            self.b3_floors[0].addChildNode(storyDividerNode)
            //self.sceneView.scene.rootNode.addChildNode(self.b5_floors[0])
            
            planeNode.addChildNode(self.b3_floors[0])
            node.addChildNode(planeNode)
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
        self.turnOffAllBuilding()
        self.navigationVC = storyboard?.instantiateViewController(withIdentifier: "ARNavigationVC") as! ARNavigationController
        let modalVC = self.navigationVC?.viewControllers.first as! ARModalViewController
        if let selectedBuilding = self.selectedBuilding {
            numberOfSelectedBuildings += 1
            modalVC.bN = "Building \(selectedBuilding + 1)"
            switch selectedBuilding {
            case 0:
                device?.b1_led = 3
                modalVC.pImage = UIImage(named: "3")
            case 1:
                device?.b2_led = 3
                modalVC.pImage = UIImage(named: "2")
            case 2:
                if b3_boxes.count > 0 {
                    for box in b3_boxes {
                        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                }
            case 3:
                device?.b4_led = 3
                modalVC.pImage = UIImage(named: "4")
                
                if b7_boxes.count > 0 {
                    for box in b7_boxes {
                        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                }
            case 4:
                if b5_boxes.count > 0 {
                    for box in b5_boxes {
                        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                }
            case 5:
                device?.b6_led = 3
                modalVC.pImage = UIImage(named: "1")
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
    }
    
    ///  This functions shows a popup for selecting another building and for filtering buildings. Part of demo
    func showSelectNextBuildingPopUp(){
        if(!self.selectOtherBuildingShown){
            let alert = UIAlertController(title: "Select another building", message: "Select another building or click on the same building to deselect.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            self.present(alert, animated: true)
            self.selectOtherBuildingShown = true
        } else if (self.numberOfSelectedBuildings > 4 && !self.filterBuildingsShown){
            print(self.numberOfSelectedBuildings)
            let alert = UIAlertController(title: "Filter buildings", message: "Click on the filter button below to filter buildings by age or role.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            self.present(alert, animated: true)
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
               if b3_boxes.count > 0 {
                   for box in b3_boxes {
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
               if b5_boxes.count > 0 {
                   for box in b5_boxes {
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
                if b7_boxes.count > 0 {
                    for box in b7_boxes {
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
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.08,self.modelCoordinate.columns.3.z - 0.15)
                    let b3_first_floor = SCNNode()
                    b3_first_floor.addChildNode(storyNode)
                    self.b3_floors[0] = b3_first_floor
                    self.b3_boxes[0] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.07,self.modelCoordinate.columns.3.z - 0.15)
                    self.b3_floors[0].addChildNode(storyDividerNode)
                    //self.sceneView.scene.rootNode.addChildNode(self.b3_floors[0])
                case 2:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.06,self.modelCoordinate.columns.3.z - 0.15)
                    let b3_second_floor = SCNNode()
                    b3_second_floor.addChildNode(storyNode)
                    self.b3_floors[1] = b3_second_floor
                    self.b3_boxes[1] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.05,self.modelCoordinate.columns.3.z - 0.15)
                    self.b3_floors[1].addChildNode(storyDividerNode)
                    //self.sceneView.scene.rootNode.addChildNode(self.b3_floors[1])
                case 3:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  - 0.05 ,self.modelCoordinate.columns.3.y - 0.04,self.modelCoordinate.columns.3.z - 0.15)
                    let b3_third_floor = SCNNode()
                    b3_third_floor.addChildNode(storyNode)
                    self.b3_floors[2] = b3_third_floor
                    self.b3_boxes[2] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.03,self.modelCoordinate.columns.3.z - 0.15)
                    self.b3_floors[2].addChildNode(storyDividerNode)
                   // self.sceneView.scene.rootNode.addChildNode(self.b3_floors[2])
                case 4:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.02,self.modelCoordinate.columns.3.z - 0.15)
                    let b3_forth_floor = SCNNode()
                    b3_forth_floor.addChildNode(storyNode)
                    self.b3_floors[3] = b3_forth_floor
                    self.b3_boxes[3] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x - 0.05 ,self.modelCoordinate.columns.3.y - 0.01,self.modelCoordinate.columns.3.z - 0.15)
                    self.b3_floors[3].addChildNode(storyDividerNode)
                    //self.sceneView.scene.rootNode.addChildNode(self.b3_floors[3])
                    let alert = UIAlertController(title: "Delete buildings", message: "Try deleting buildings by selecting delete on the bottom.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
                    self.present(alert, animated: true)
                default:
                    return;
                }
            }
            if(!self.addMode){
                switch value {
                case 1:
                    self.b3_floors[3].removeFromParentNode()
                case 2:
                    self.b3_floors[2].removeFromParentNode()
                case 3:
                    self.b3_floors[1].removeFromParentNode()
                case 4:
                    self.b3_floors[0].removeFromParentNode()
                default:
                    return;
                }
            }}
        
    }
    
    /// This method handles long touch notification for building 5.
    /// - Parameter value: The added level/story
    func deviceLongTouchB5Changed(value: Int) {
        if(self.markerScanned){
            if(self.addMode){
                switch value {
                case 1:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.08,self.modelCoordinate.columns.3.z - 0.12)
                    let b5_first_floor = SCNNode()
                    b5_first_floor.addChildNode(storyNode)
                    self.b5_floors[0] = b5_first_floor
                    self.b5_boxes[0] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.07,self.modelCoordinate.columns.3.z - 0.12)
                    self.b5_floors[0].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b5_floors[0])
                case 2:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.06,self.modelCoordinate.columns.3.z - 0.12)
                    let b5_first_floor = SCNNode()
                    b5_first_floor.addChildNode(storyNode)
                    self.b5_floors[1] = b5_first_floor
                    self.b5_boxes[1] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.05,self.modelCoordinate.columns.3.z - 0.12)
                    self.b5_floors[1].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b5_floors[1])
                case 3:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.04,self.modelCoordinate.columns.3.z - 0.12)
                    let b5_first_floor = SCNNode()
                    b5_first_floor.addChildNode(storyNode)
                    self.b5_floors[2] = b5_first_floor
                    self.b5_boxes[2] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.03,self.modelCoordinate.columns.3.z - 0.12)
                    self.b5_floors[2].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b5_floors[2])
                case 4:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.02,self.modelCoordinate.columns.3.z - 0.12)
                    let b5_first_floor = SCNNode()
                    b5_first_floor.addChildNode(storyNode)
                    self.b5_floors[3] = b5_first_floor
                    self.b5_boxes[3] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.01,self.modelCoordinate.columns.3.z - 0.12)
                    self.b5_floors[3].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b5_floors[3])
                    self.sceneView.scene.rootNode.addChildNode(self.b7_floors[3])
                    let alert = UIAlertController(title: "Delete buildings", message: "Try deleting buildings by selecting delete on the bottom.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
                    self.present(alert, animated: true)
                default:
                    return;
                }
            }
            if(!self.addMode){
                
                switch value {
                case 1:
                     self.b5_floors[3].removeFromParentNode()
                case 2:
                    self.b5_floors[2].removeFromParentNode()
                case 3:
                    self.b5_floors[1].removeFromParentNode()
                case 4:
                    self.b5_floors[0].removeFromParentNode()
                default:
                    return;
                }
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
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.04,self.modelCoordinate.columns.3.z - 0.15)
                    let b4_third_floor = SCNNode()
                    b4_third_floor.addChildNode(storyNode)
                    self.b7_floors[0] = b4_third_floor
                    self.b7_boxes[0] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.03,self.modelCoordinate.columns.3.z - 0.15)
                    self.b7_floors[0].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b7_floors[0])
                case 2:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.02,self.modelCoordinate.columns.3.z - 0.15)
                    let b4_forth_floor = SCNNode()
                    b4_forth_floor.addChildNode(storyNode)
                    self.b7_floors[1] = b4_forth_floor
                    self.b7_boxes[1] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.01,self.modelCoordinate.columns.3.z - 0.15)
                    self.b7_floors[1].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b7_floors[1])
                case 3:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y - 0.00,self.modelCoordinate.columns.3.z - 0.15)
                    let b4_fifth_floor = SCNNode()
                    b4_fifth_floor.addChildNode(storyNode)
                    self.b7_floors[2] = b4_fifth_floor
                    self.b7_boxes[2] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.01,self.modelCoordinate.columns.3.z - 0.15)
                    self.b7_floors[2].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b7_floors[2])
                case 4:
                    let story = SCNBox(width: CGFloat(self.cubeSize.0), height: CGFloat(self.cubeSize.1), length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    story.firstMaterial?.diffuse.contents = UIColor.gray
                    let storyNode = SCNNode(geometry: story)
                    storyNode.opacity = 0.8
                    storyNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.02,self.modelCoordinate.columns.3.z - 0.15)
                    let b4_six_floor = SCNNode()
                    b4_six_floor.addChildNode(storyNode)
                    self.b7_floors[3] = b4_six_floor
                    self.b7_boxes[3] = storyNode
                    
                    let storyDivider = SCNBox(width: CGFloat(self.cubeSize.0), height: 0.005, length: CGFloat(self.cubeSize.2), chamferRadius: 0.0)
                    storyDivider.firstMaterial?.diffuse.contents = UIColor.black
                    let storyDividerNode = SCNNode(geometry: storyDivider)
                    storyDividerNode.opacity = 1
                    storyDividerNode.position = SCNVector3(self.modelCoordinate.columns.3.x  ,self.modelCoordinate.columns.3.y + 0.03,self.modelCoordinate.columns.3.z - 0.15)
                    self.b7_floors[3].addChildNode(storyDividerNode)
                    self.sceneView.scene.rootNode.addChildNode(self.b7_floors[3])
                    let alert = UIAlertController(title: "Delete buildings", message: "Try deleting buildings by selecting delete on the bottom.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
                    self.present(alert, animated: true)
                default:
                    return;
                }
            }
            if(!self.addMode){
                switch value {
                case 1:
                    self.b7_floors[3].removeFromParentNode()
                case 2:
                    self.b7_floors[2].removeFromParentNode()
                case 3:
                    self.b7_floors[1].removeFromParentNode()
                case 4:
                    self.b7_floors[0].removeFromParentNode()
                default:
                    return;
                }
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
                self.selectedBuilding = value
                showSelectedBuilding()}
            
        } else {
            self.selectedBuilding = value
            showSelectedBuilding()}
    }
}
