

import UIKit
import SwiftUI
import AVFoundation
import Vision

class GameViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let gameManager = GameManager.shared
    private let detectPlayerRequest = VNDetectHumanBodyPoseRequest()
    private var playerDetected = false
    private let playerBoundingBox = BoundingBoxView()
    private let jointSegmentView = JointSegmentView()
    private let bodyPoseDetectionMinConfidence: VNConfidence = 0.6
    private let bodyPoseRecognizedPointMinConfidence: VNConfidence = 0.1
    
    private let playButton = UIButton(type: .system)
    private let compareButton = UIButton(type: .system)
    private var proImageView: UIImageView?
    private let nextPlayerButton = UIButton(type: .system)
    private let feedbackLabel = UILabel()
    
    weak var delegate: GameViewControllerDelegate?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUIElements()
        
        
        // Create play button
        playButton.setTitle("▶️", for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        
        // Set the action for the button
        playButton.addTarget(self, action: #selector(playButtonPressed(_:)), for: .touchUpInside)
        
        // Set the frame of the button, aligning it to the right end of the screen
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 60
        playButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 70, // centered (roughly)
                                  y: UIScreen.main.bounds.height, // 150 points margin from the bottom
                                  width: buttonWidth,
                                  height: buttonHeight)
        
        // Add the button to the view
        view.addSubview(playButton)
        view.bringSubviewToFront(playButton)
        playButton.isHidden = true
        
        
        // Create compare button
        compareButton.setTitle("Compare", for: .normal)
        compareButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        
        // Set the action for the button
        compareButton.addTarget(self, action: #selector(compareButtonPressed(_:)), for: .touchUpInside)
        
        // Set the frame of the button, aligning it to the right end of the screen
        let compareButtonWidth: CGFloat = 150
        let compareButtonHeight: CGFloat = 50
        compareButton.frame = CGRect(x: UIScreen.main.bounds.width - 180,
                                     y: UIScreen.main.bounds.height,
                                     width: compareButtonWidth,
                                     height: compareButtonHeight)
        
        
        // Add the button to the view
        view.addSubview(compareButton)
        view.bringSubviewToFront(compareButton)
        //compareButton.isHidden = true
        
        setupNextPlayerButton()
        
        // Initialize and configure the text field
        feedbackLabel.text = GameManager.shared.playerStats.feedbackText
        feedbackLabel.numberOfLines = 0  // Allows label to have multiple lines
        feedbackLabel.textAlignment = .left
        feedbackLabel.font = UIFont.systemFont(ofSize: 16)
        feedbackLabel.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)  // Semi-transparent gray background
        feedbackLabel.frame = CGRect(x: 00, y: UIScreen.main.bounds.height - 150, width: UIScreen.main.bounds.width - 80, height: 150)

        view.addSubview(feedbackLabel)
        
        
    }
    // Add button setup in the `viewDidLoad` method
    private func setupNextPlayerButton() {
        nextPlayerButton.setTitle("Next", for: .normal)
        nextPlayerButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        nextPlayerButton.frame = CGRect(x: -30, // 20 points from the left margin
                                        y: UIScreen.main.bounds.height, // Adjusted to bottom
                                        width: 100,
                                        height: 50)
        nextPlayerButton.addTarget(self, action: #selector(nextPlayerButtonPressed(_:)), for: .touchUpInside)
        view.addSubview(nextPlayerButton)
        view.bringSubviewToFront(nextPlayerButton)
    }
    // Implement the action for the button
    @objc func nextPlayerButtonPressed(_ sender: UIButton) {
        // Assuming you have an array of player images or an image index to cycle through
        let playerImages = ["Federer", "Alcaraz"] // Example player images
        if let currentImage = proImageView?.image,
           let currentIndex = playerImages.firstIndex(where: { UIImage(named: $0) == currentImage }),
           currentIndex + 1 < playerImages.count {
            proImageView?.image = UIImage(named: playerImages[currentIndex + 1])
        } else {
            proImageView?.image = UIImage(named: playerImages.first!)
        }
        layoutImageView() // Re-layout if needed
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        print("GVC Continue Video button pressed")
        playButton.isHidden = true
        self.gameManager.stateMachine.enter(GameManager.ServeDetectedContinueState.self)
    }
    
    @IBAction func compareButtonPressed(_ sender: Any) {
        print("Compare button pressed")
        
        // Create the image view if it does not already exist
        if proImageView == nil {
            proImageView = UIImageView(frame: .zero)
            proImageView?.contentMode = .scaleAspectFit
            view.addSubview(proImageView!)
        }
        
        // Load the image from assets
        proImageView?.image = UIImage(named: "Federer")
        
        
        // Layout the image view on the right half of the screen
        layoutImageView()
    }
    // for the comparison image
    private func layoutImageView() {
        guard let imageView = proImageView else { return }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove the imageView from its current superview to clear any constraints
        imageView.removeFromSuperview()
        view.addSubview(imageView) // Re-add it to the view hierarchy
        
        // Debugging: Print existing constraints on imageView
        print("Active constraints on imageView: \(imageView.constraints)")
        
        // Manually deactivate all constraints on imageView
        NSLayoutConstraint.deactivate(imageView.constraints)
        
        // Constraint to align imageView to the right
        let rightConstraint = imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        rightConstraint.isActive = true
        
        // Constraint to manage the top alignment
        let topConstraint = imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
        topConstraint.isActive = true
        
        // Constraint for bottom alignment
        let bottomConstraint = imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        bottomConstraint.isActive = true
        
        // Constraint to control width
        let widthConstraint = imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        widthConstraint.isActive = true
        
        view.layoutIfNeeded() // Force the layout to update
    }
    
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    func setUIElements() {
        
        playerBoundingBox.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        playerBoundingBox.backgroundOpacity = 0
        playerBoundingBox.isHidden = true
        
        view.addSubview(playerBoundingBox)
        view.addSubview(jointSegmentView)
        
    }
    
    
    func updateKPILabels() {
    }
    
    func updateBoundingBox(_ boundingBox: BoundingBoxView, withRect rect: CGRect?) {
        // Update the frame for player bounding box
        boundingBox.frame = rect ?? .zero
        boundingBox.perform(transition: (rect == nil ? .fadeOut : .fadeIn), duration: 0.1)
    }
    
    func humanBoundingBox(for observation: VNHumanBodyPoseObservation) -> CGRect {
        var box = CGRect.zero
        var normalizedBoundingBox = CGRect.null
        // Process body points only if the confidence is high.
        guard observation.confidence > bodyPoseDetectionMinConfidence, let points = try? observation.recognizedPoints(forGroupKey: .all) else {
            return box
        }
        // Only use point if human pose joint was detected reliably.
        for (_, point) in points where point.confidence > bodyPoseRecognizedPointMinConfidence {
            normalizedBoundingBox = normalizedBoundingBox.union(CGRect(origin: point.location, size: .zero))
        }
        if !normalizedBoundingBox.isNull {
            box = normalizedBoundingBox
        }
        // Fetch body joints from the observation and overlay them on the player.
        let joints = getBodyJointsFor(observation: observation)
        DispatchQueue.main.async {
            self.jointSegmentView.joints = joints
        }
        // Store the body pose observation in playerStats when the game is in TrackServeState.
        // We will use these observations for action classification once the throw is complete.
        return box
    }
}



extension GameViewController: GameStateChangeObserver {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?) {
        switch state {
        case is GameManager.DetectedPlayerState:
            playerDetected = true
            playerBoundingBox.perform(transition: .fadeOut, duration: 1.0)
            self.gameManager.stateMachine.enter(GameManager.TrackServeState.self)
        case is GameManager.TrophyDetectedState:
            self.feedbackLabel.text = GameManager.shared.playerStats.feedbackText
            self.playButton.isHidden = false
            self.compareButton.isHidden = false
        case is GameManager.ServeDetectedState:
            self.feedbackLabel.text = GameManager.shared.playerStats.feedbackText
            self.playButton.isHidden = false
            self.compareButton.isHidden = false
            /*
        case is GameManager.ServeDetectedContinueState:
            self.feedbackLabel.text = GameManager.shared.playerStats.feedbackText
            self.playButton.isHidden = false
            self.compareButton.isHidden = false*/
        default:
            break
        }
    }
}

extension GameViewController: CameraViewControllerOutputDelegate {
    func cameraViewController(_ controller: CameraViewController, didReceiveBuffer buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        if gameManager.stateMachine.currentState is GameManager.TrackServeState {
            DispatchQueue.main.async {
                // Get the frame of rendered view
                let normalizedFrame = CGRect(x: 0, y: 0, width: 1, height: 1)
                self.jointSegmentView.frame = controller.viewRectForVisionRect(normalizedFrame)
            }
            
        }
        // Body pose request is performed on the same camera queue to ensure the highlighted joints are aligned with the player.
        // Run bodypose request for additional GameConstants.maxPostReleasePoseObservations frames after the first trajectory observation is detected.
        do {
            try visionHandler.perform([detectPlayerRequest])
            if let result = detectPlayerRequest.results?.first {
                let box = humanBoundingBox(for: result)
                let boxView = playerBoundingBox
                DispatchQueue.main.async {
                    let inset: CGFloat = -20.0
                    let viewRect = controller.viewRectForVisionRect(box).insetBy(dx: inset, dy: inset)
                    self.updateBoundingBox(boxView, withRect: viewRect)
                    if !self.playerDetected && !boxView.isHidden {
                        //self.gameStatusLabel.alpha = 0
                        self.gameManager.stateMachine.enter(GameManager.DetectedPlayerState.self)
                    }
                }
            }
        } catch {
            AppError.display(error, inViewController: self)
        }
        
    }
}



protocol GameViewControllerDelegate: AnyObject {
    func pauseVideoPlayback()
    func resumeVideoPlayback()
}
extension RootViewController: GameViewControllerDelegate {
    func pauseVideoPlayback() {
        self.cameraViewController.pauseVideoPlayback()
    }
    func resumeVideoPlayback() {
        self.cameraViewController.resumeVideoPlayback()
    }
}
