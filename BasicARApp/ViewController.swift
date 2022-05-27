//
//  ViewController.swift
//  BasicARApp
//
// Author: Hewitt Watkins
// Date: 5/26/2022
// Purpose: Make an AR app that puts a drill in 3D space.

import UIKit // for notifications on the screen
import RealityKit // for the model that is put into the AR world
import ARKit // provides the AR experience - does most of the heavy lifting (deals with all the lighting etc.)

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView! // this is the AR view - it starts the camera stream and manages the AR activities like identifying surfaces etc.
    
    // this is an overriden function that is called when the AR view is put on the screen - this is where we do our initialization
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self
        
        setupARView()
        
        // adding the gesture recognziers
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
       // arView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(recognizer:)))) - experimental code linked to the experimental function below
        
        // this code uses the UIKit to display the welcome pop-up message
        let alert = UIAlertController(title: "Welcome!", message: "Welcome to Hewitt's AR App. To place an AR Object, simply tap the screen. To interact with the object, use multitouch gestures to move, rotate, and scale. Enjoy!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Let's Go!", comment: "Default action"), style: .default, handler: { _ in
        NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    
    }

    
    // MARK: Setup Methods
    
    // Configures the AR view for plane detection and 3D assest rendering (shadows and lighting model)
    func setupARView() {
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
        
        
        
    }
    
    // MARK: Object Placement
    
    // Take user tap and find the closest surface in the scene corresponding to the tap. An anchor is then created on that surface at the intersection of the tap. If no surface is found, produce an error pop-up message to the user
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first {
            let anchor = ARAnchor(name: "Drill", transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
            
        } else {
            print("Object placement failed - couldn't find surface")
            let alert = UIAlertController(title: "Ut-oh", message: "Object placement failed - couldn't find surface", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Default action"), style: .default, handler: { _ in
            NSLog("The \"OK\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    // experimental code that allowed me to scale the object before I found a better way to do it
//    @objc
//    func handlePinch(recognizer: UIPinchGestureRecognizer) {
//        print("handle pinch")
//        if recognizer.state == .began {
//            print("began")
//        }   else if recognizer.state == .changed {
//            print("changed")
//        }   else if recognizer.state == .ended {
//            print("ended")
//        }
//        print(recognizer.scale)
//
//    }
    
    
    // Place an object at the position of the anchor (created in the function above)
    func placeObject(named entityName: String, for anchor: ARAnchor){
        let entity = try! ModelEntity.loadModel(named: entityName)
        
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: entity)
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
    }
}

// this function is responsible for managing objects placed in the AR view (it connects the anchor created by the tap and the object being placed at the anchor together)
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorName = anchor.name, anchorName == "Drill" {
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}
