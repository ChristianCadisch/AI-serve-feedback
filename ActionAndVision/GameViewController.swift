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
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var beanBags: [UIImageView]!
    @IBOutlet weak var gameStatusLabel: OverlayLabel!
    private let gameManager = GameManager.shared
    private let detectPlayerRequest = VNDetectHumanBodyPoseRequest()
    private var playerDetected = false
    private let playerBoundingBox = BoundingBoxView()
    private let jointSegmentView = JointSegmentView()
    private var noObservationFrameCount = 0
    private var showSummaryGesture: UITapGestureRecognizer!
    private let bodyPoseDetectionMinConfidence: VNConfidence = 0.6
    private let bodyPoseRecognizedPointMinConfidence: VNConfidence = 0.1

    //@IBOutlet weak var continueButton: UIButton!
    
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
        jointSegmentView.delegate = self
        showSummaryGesture = UITapGestureRecognizer(target: self, action: #selector(handleShowSummaryGesture(_:)))
        showSummaryGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(showSummaryGesture)
        //continueButton.isHidden = true
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameStatusLabel.perform(transition: .fadeIn, duration: 0.25)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func getScoreLabelAttributedStringForScore(_ score: Int) -> NSAttributedString {
        let totalScore = NSMutableAttributedString(string: "Total Score ", attributes: [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.65)])
        totalScore.append(NSAttributedString(string: "\(score)", attributes: [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]))
        totalScore.append(NSAttributedString(string: "/40", attributes: [.foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.65)]))
        return totalScore
    }

    func setUIElements() {
        
        playerBoundingBox.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        playerBoundingBox.backgroundOpacity = 0
        playerBoundingBox.isHidden = true

        view.addSubview(playerBoundingBox)
        view.addSubview(jointSegmentView)
        gameStatusLabel.text = "Waiting for player"
        scoreLabel.attributedText = getScoreLabelAttributedStringForScore(0)
    }


    func updateKPILabels() {
        scoreLabel.text = "Hits: \(playerStats.hits)"
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
        // Store the body pose observation in playerStats when the game is in TrackThrowsState.
        // We will use these observations for action classification once the throw is complete.
        if gameManager.stateMachine.currentState is GameManager.TrackThrowsState {
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
            gameStatusLabel.text = "Go"
            gameStatusLabel.perform(transitions: [.popUp, .popOut], durations: [0.25, 0.12], delayBetween: 1) {
                self.gameManager.stateMachine.enter(GameManager.TrackThrowsState.self)
            }
        case is GameManager.TrackThrowsState:
            print("letss goooo")
        case is GameManager.ServeDetectedState:
            print("Serve detected state is ooooon")
            //continueButton.isHidden = false
            
            
        case is GameManager.ThrowCompletedState:
            print("ThrowCompletedState")
             playerStats.adjustMetrics(score: lastThrowMetrics.score, speed: lastThrowMetrics.releaseSpeed,
                                      releaseAngle: lastThrowMetrics.releaseAngle, throwType: lastThrowMetrics.throwType)
            playerStats.resetObservations()
            self.updateKPILabels()
            
            gameStatusLabel.text = lastThrowMetrics.score.rawValue > 0 ? "+\(lastThrowMetrics.score.rawValue)" : ""
            gameStatusLabel.perform(transitions: [.popUp, .popOut], durations: [0.25, 0.12], delayBetween: 1) {
                if self.playerStats.throwCount == GameConstants.maxThrows {
                    self.gameManager.stateMachine.enter(GameManager.ShowSummaryState.self)
                } else {
                    self.gameManager.stateMachine.enter(GameManager.TrackThrowsState.self)
                }
            }
        default:
            break
        }
    }
}

extension GameViewController: CameraViewControllerOutputDelegate {
    func cameraViewController(_ controller: CameraViewController, didReceiveBuffer buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        if gameManager.stateMachine.currentState is GameManager.TrackThrowsState {
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
                        self.gameStatusLabel.alpha = 0
                        //self.resetTrajectoryRegions()
                        self.gameManager.stateMachine.enter(GameManager.DetectedPlayerState.self)
                    }
                }
            }
        } catch {
            AppError.display(error, inViewController: self)
        }
        
    }
}

extension GameViewController {
    @objc
    func handleShowSummaryGesture(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            self.gameManager.stateMachine.enter(GameManager.ShowSummaryState.self)
        }
    }
}


extension GameViewController: JointSegmentViewDelegate {
    func jointSegmentViewDidDetectServe(_ jointSegmentView: JointSegmentView) {
       
        playerStats.hits += 1
        scoreLabel.text = "Hits: \(playerStats.hits)"
        self.gameManager.stateMachine.enter(GameManager.ServeDetectedState.self)
    }
}
