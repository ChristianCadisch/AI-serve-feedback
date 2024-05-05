/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller responsible for the game flow.
     The game flow consists of the following tasks:
     - player detection
     - player action classification
     - release angle, release speed and score computation
*/

import UIKit
import AVFoundation
import Vision

class GameViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    //@IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var beanBags: [UIImageView]!
    @IBOutlet weak var gameStatusLabel: OverlayLabel!
    private let gameManager = GameManager.shared
    private let detectPlayerRequest = VNDetectHumanBodyPoseRequest()
    private var playerDetected = false
    private let playerBoundingBox = BoundingBoxView()
    private let jointSegmentView = JointSegmentView()
    private var noObservationFrameCount = 0
    private let bodyPoseDetectionMinConfidence: VNConfidence = 0.6
    private let bodyPoseRecognizedPointMinConfidence: VNConfidence = 0.1
    
    private let playButton = UIButton(type: .system)
    private let compareButton = UIButton(type: .system)
    private var proImageView: UIImageView?


    weak var delegate: GameViewControllerDelegate?
    
    //Variables - KPIs
    var lastThrowMetrics: ThrowMetrics {
        get {
            return gameManager.lastThrowMetrics
        }
        set {
            gameManager.lastThrowMetrics = newValue
        }
    }

    var playerStats: PlayerStats {
        get {
            return gameManager.playerStats
        }
        set {
            gameManager.playerStats = newValue
        }
    }

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
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        playButton.frame = CGRect(x: screenWidth - buttonWidth - 70, // 20 points margin from the right
                                  y: screenHeight/2, // 20 points margin from the bottom
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
        let safeAreaInsets = view.safeAreaInsets
        let buttonX = view.bounds.width - compareButtonWidth - safeAreaInsets.right - 20 // 20 points margin
        let buttonY = view.bounds.height - compareButtonHeight - safeAreaInsets.bottom - 70 // 20 points margin from the bottom

        compareButton.frame = CGRect(x: buttonX,
                                     y: buttonY,
                                     width: compareButtonWidth,
                                     height: compareButtonHeight)


        // Add the button to the view
        view.addSubview(compareButton)
        view.bringSubviewToFront(compareButton)
        compareButton.isHidden = true
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

        // Remove any old constraints that might be set
        NSLayoutConstraint.deactivate(imageView.constraints)
        
        // Activate new constraints
        NSLayoutConstraint.activate([
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), // Smaller margin for top
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // Smaller margin for bottom
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8) // Increased width to 80% of the parent view
        ])
        
        view.layoutIfNeeded() // Force the layout to update
    }






    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //gameStatusLabel.perform(transition: .fadeIn, duration: 0.25)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    /*
    func getScoreLabelAttributedStringForScore(_ score: Int) -> NSAttributedString {
        let totalScore = NSMutableAttributedString(string: "Total Score ", attributes: [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.65)])
        totalScore.append(NSAttributedString(string: "\(score)", attributes: [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]))
        totalScore.append(NSAttributedString(string: "/40", attributes: [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.65)]))
        return totalScore
    }
*/
    func setUIElements() {
        
        playerBoundingBox.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        playerBoundingBox.backgroundOpacity = 0
        playerBoundingBox.isHidden = true

        view.addSubview(playerBoundingBox)
        view.addSubview(jointSegmentView)
        //gameStatusLabel.text = "Waiting for player"
        //scoreLabel.attributedText = getScoreLabelAttributedStringForScore(0)
    }


    func updateKPILabels() {
        //scoreLabel.text = "Hits: \(playerStats.hits)"
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
        if gameManager.stateMachine.currentState is GameManager.TrackServeState {
            playerStats.storeObservation(observation)

        }
        return box
    }
}



extension GameViewController: GameStateChangeObserver {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?) {
        switch state {
        case is GameManager.DetectedPlayerState:
            playerDetected = true
            playerStats.reset()
            playerBoundingBox.perform(transition: .fadeOut, duration: 1.0)
            //roiBoundingBox.perform(transition: .fadeOut, duration: 1.0)
            
            self.gameManager.stateMachine.enter(GameManager.TrackServeState.self)
            /*
            gameStatusLabel.text = "Go"
            gameStatusLabel.perform(transitions: [.popUp, .popOut], durations: [0.25, 0.12], delayBetween: 1) {
                self.gameManager.stateMachine.enter(GameManager.TrackServeState.self)
            }*/
        case is GameManager.TrackServeState:
            print("track")
        case is GameManager.ServeDetectedState:
            print("Serve detected state is ooooon")
            self.playButton.isHidden = false
            self.compareButton.isHidden = false
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
