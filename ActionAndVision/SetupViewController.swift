/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller responsible for the setup state of the game.
     The setup consists of the following tasks:
     - board detection
     - board placement check
     - board contours analysis
     - scene stability check
*/

import UIKit
import AVFoundation
import Vision

class SetupViewController: UIViewController {

    @IBOutlet var statusLabel: OverlayLabel!
 
    private let gameManager = GameManager.shared

    
    enum SceneSetupStage {
        case detectingSceneStability
        case setupComplete
    }

    private var setupStage = SceneSetupStage.detectingSceneStability
    
    enum SceneStabilityResult {
        case unknown
        case stable
        case unstable
    }
    
    private let sceneStabilityRequestHandler = VNSequenceRequestHandler()
    private let sceneStabilityRequiredHistoryLength = 15
    private var sceneStabilityHistoryPoints = [CGPoint]()
    private var previousSampleBuffer: CMSampleBuffer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateSetupState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            // Create Vision request based on CoreML model
            let model = try VNCoreMLModel(for: GameBoardDetector(configuration: MLModelConfiguration()).model)
            //boardDetectionRequest = VNCoreMLRequest(model: model)
            // Since board is close to the side of a landscape image,
            // we need to set crop and scale option to scaleFit.
            // By default vision request will run on centerCrop.
            //boardDetectionRequest.imageCropAndScaleOption = .scaleFit
        } catch {
            let error = AppError.createRequestError(reason: "Could not create Vision request for board detector")
            AppError.display(error, inViewController: self)
        }
    }
    
    func updateBoundingBox(_ boundingBox: BoundingBoxView, withViewRect rect: CGRect?, visionRect: CGRect) {
        DispatchQueue.main.async {
            boundingBox.frame = rect ?? .zero
            boundingBox.visionRect = visionRect
            if rect == nil {
                boundingBox.perform(transition: .fadeOut, duration: 0.1)
            } else {
                boundingBox.perform(transition: .fadeIn, duration: 0.1)
            }
        }
    }
    
    func updateSetupState() {
        //let boardBox = boardBoundingBox
        DispatchQueue.main.async {
            switch self.setupStage {
            
            case .detectingSceneStability:
                switch self.sceneStability {
                case .unknown:
                    break
                case .unstable:
                    self.previousSampleBuffer = nil
                    self.sceneStabilityHistoryPoints.removeAll()
                    //self.setupStage = .detectingBoardPlacement
                case .stable:
                    self.setupStage = .setupComplete
                }
            default:
                break
            }
        }
    }
    
    var sceneStability: SceneStabilityResult {
        return .stable //this direct return statement skips the stability checks
        // Determine if we have enough evidence of stability.
        guard sceneStabilityHistoryPoints.count > sceneStabilityRequiredHistoryLength else {
            return .unknown
        }
        
        // Calculate the moving average by adding up values of stored points
        // returned by VNTranslationalImageRegistrationRequest for both axis
        var movingAverage = CGPoint.zero
        movingAverage.x = sceneStabilityHistoryPoints.map { $0.x }.reduce(.zero, +)
        movingAverage.y = sceneStabilityHistoryPoints.map { $0.y }.reduce(.zero, +)
        // Get the moving distance by adding absolute moving average values of individual axis
        let distance = abs(movingAverage.x) + abs(movingAverage.y)
        // If the distance is not significant enough to affect the game analysis (less that 10 points),
        // we declare the scene being stable
        return (distance < 10 ? .stable : .unstable)
    }
}

extension SetupViewController: CameraViewControllerOutputDelegate {
    func cameraViewController(_ controller: CameraViewController, didReceiveBuffer buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        do {
            switch setupStage {
            case .setupComplete:
                // Setup is complete - no reason to run vision requests.
                return
            case .detectingSceneStability:
                try checkSceneStability(controller, buffer, orientation)
            }
            updateSetupState()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    private func checkSceneStability(_ controller: CameraViewController, _ buffer: CMSampleBuffer, _ orientation: CGImagePropertyOrientation) throws {
        guard let previousBuffer = self.previousSampleBuffer else {
            self.previousSampleBuffer = buffer
            return
        }
        let registrationRequest = VNTranslationalImageRegistrationRequest(targetedCMSampleBuffer: buffer)
        try sceneStabilityRequestHandler.perform([registrationRequest], on: previousBuffer, orientation: orientation)
        self.previousSampleBuffer = buffer
        if let alignmentObservation = registrationRequest.results?.first as? VNImageTranslationAlignmentObservation {
            let transform = alignmentObservation.alignmentTransform
            sceneStabilityHistoryPoints.append(CGPoint(x: transform.tx, y: transform.ty))
        }
    }
}
    
