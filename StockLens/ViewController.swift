//
//  ViewController.swift
//  StockLens
//
//  Created by Anirudh Naidu on 3/3/19.
//  Copyright © 2019 Anirudh Naidu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import FittedSheets

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var tapRecognizer: UITapGestureRecognizer!
    var image: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        setupTapRecognizer() // tap recognition
        
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
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    // handles setting up the tap functionality
    private func setupTapRecognizer() {
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer?.numberOfTapsRequired = 1
        tapRecognizer?.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapRecognizer!)
    }
    
    // when the user taps the screen, a picture is taken and the logo is detected
    @objc func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            image = sceneView.snapshot()
            print(image.size)
            
            let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
            
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.gray
            loadingIndicator.startAnimating();
            
            alert.view.addSubview(loadingIndicator)
            present(alert, animated: true, completion: nil)
            
            guard let resizedImage = resize(image: image, to: view.frame.size) else {
                fatalError("Error resizing image")
            }
            let controller = SheetController()
            let failController = FailSheetController()
            let limitController = LimitSheetController()
            
            detectLogo(for: resizedImage){ logo in
                if (logo != "Logo not found") {
                    controller.company = logo.capitalizingFirstLetter()
                    failController.company = logo.capitalizingFirstLetter()
                    print(logo)
                    self.getPricingInfo(for: logo) {price in
                        // updates UI on main thread through dispatch queue
                        DispatchQueue.main.async {
                            if (price![0] != "" && price![0] != "limit"){ // logo and pricing is found and limit is not reached
                                let sheetController = SheetViewController(controller: controller)
                                sheetController.extendBackgroundBehindHandle = true
                                sheetController.topCornersRadius = 20
                                controller.ticker = price![2]
                                controller.price = "$" + self.truncateValue(number: price![0])
                                controller.change = self.truncateValue(number: price![1]) + "%"
                                self.dismiss(animated: false, completion: nil)
                                self.present(sheetController, animated: false, completion: nil)
                            }
                            else if (price![0] == "limit"){ // limit on API is reached
                                let limitController = SheetViewController(controller: limitController)
                                limitController.extendBackgroundBehindHandle = true
                                limitController.topCornersRadius = 20
                                self.dismiss(animated: false, completion: nil)
                                self.present(limitController, animated: false, completion: nil)
                            }
                            else{ // logo was found, but compnay is not public
                                let failSheetController = SheetViewController(controller: failController)
                                failSheetController.extendBackgroundBehindHandle = true
                                failSheetController.topCornersRadius = 20
                                self.dismiss(animated: false, completion: nil)
                                self.present(failSheetController, animated: false, completion: nil)
                            }
                        }
                    }
                }
                else { // no logo was found
                    let controller = ErrorSheetController()
                    let errorSheetController = SheetViewController(controller: controller)
                    errorSheetController.extendBackgroundBehindHandle = true
                    errorSheetController.topCornersRadius = 20
                    self.dismiss(animated: false, completion: nil)
                    self.present(errorSheetController, animated: false, completion: nil)
                }
            }
        }
    }
    
    // function to get pricing info by building two URLs, one to get ticker, then use the ticker to get pricing info
    private func getPricingInfo(for logo: String, completion: @escaping(Array<String>?)->()) {
        var logoKeyWord = logo.lowercased()
        if logoKeyWord.contains("inc."){
            logoKeyWord = (logo.components(separatedBy: " ").first)!
        }
        let searchURL = StockDetection().buildBaseURL(name: logoKeyWord, param: "keywords", function: "SYMBOL_SEARCH").url
        StockDetection().nameToTicker(myURL: searchURL!){response in
            // response == "" is when ticker is not found
            if (response != nil && response != "" && response != "limit") {
                let quoteURL = StockDetection().buildBaseURL(name: response!, param: "symbol", function: "GLOBAL_QUOTE").url
                StockDetection().fetchPrice(myURL: quoteURL!) {pricing in
                    // when limit is reached with the fetchPrice call
                    if (pricing != ["limit"]){
                        completion(pricing!)
                    }
                    else{
                        completion(["limit"])
                    }
                }
            }
            else if (response == "limit") { // limit is reached with the nameToTicker call
                completion(["limit"])
            }
            else{ // no ticker was found
                completion(["",""])
            }
        }
    }
    
    // calls method to detect logo
    private func detectLogo(for image: UIImage, completion: @escaping(String)-> Void) {
        GoogleCloudDetection().detect(from: image) { logoResult in
            guard let logoResult = logoResult else {
                completion("Logo not found")
                return
            }
            let resultString = String(describing: logoResult.annotations[0]) // only gets the first logo in the JSON response
            let regex = try! NSRegularExpression(pattern:"\"(.*)\"")
            if let match = regex.firstMatch(
                in: resultString, range:NSMakeRange(0,resultString.utf16.count)) {
                let logoResult = (resultString as NSString).substring(with: match.range(at:1))
                completion(logoResult)
            }
        }
    }
    
    // function to resize image so it is an appropriate size for the Google Cloud Vision API
    private func resize(image: UIImage, to targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle.
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height + 1)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // truncates values to two decimal places and returns as string
    private func truncateValue(number: String) -> String{
        let removeLastChar = String(number.dropLast())
        let priceVal = Double(removeLastChar)
        return String(format:"%.2f", priceVal!)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
