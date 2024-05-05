/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This is a custom container view controller that is responsible for two things:
    1. Hosting the CameraViewController that presents video frames captured by camera or being read from video file
    2. Presentation and dismissal of overlay view controllers based on current game state
*/

import UIKit

class RootViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!

    @IBOutlet weak var continueButton: UIButton!
    
    var cameraViewController: CameraViewController!
    private var overlayParentView: UIView!
    private var overlayViewController: UIViewController!
    private let gameManager = GameManager.shared
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraViewController = CameraViewController()
        cameraViewController.view.frame = view.bounds
        addChild(cameraViewController)
        cameraViewController.beginAppearanceTransition(true, animated: true)
        view.addSubview(cameraViewController.view)
        cameraViewController.endAppearanceTransition()
        cameraViewController.didMove(toParent: self)
        
        
        
        
        overlayParentView = UIView(frame: view.bounds)
        overlayParentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayParentView)
        overlayParentView = UIView(frame: view.bounds)
        overlayParentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayParentView)
        NSLayoutConstraint.activate([
            overlayParentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0), // 40 points from the left edge
            overlayParentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            overlayParentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            overlayParentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

        
        
        startObservingStateChanges()
        // Make sure close button stays in front of other views.
        view.bringSubviewToFront(closeButton)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameManager.stateMachine.enter(GameManager.SetupCameraState.self)
    }
    
    private func presentOverlayViewController(_ newOverlayViewController: UIViewController?, completion: (() -> Void)?) {
        defer {
            completion?()
        }
        
        guard overlayViewController != newOverlayViewController else {
            return
        }
        
        if let currentOverlay = overlayViewController {
            currentOverlay.willMove(toParent: nil)
            currentOverlay.beginAppearanceTransition(false, animated: true)
            currentOverlay.view.removeFromSuperview()
            currentOverlay.endAppearanceTransition()
            currentOverlay.removeFromParent()
        }
        
        if let newOverlay = newOverlayViewController {
            newOverlay.view.frame = overlayParentView.bounds
            newOverlay.view.isUserInteractionEnabled = true // Add this line
            addChild(newOverlay)
            newOverlay.beginAppearanceTransition(true, animated: true)
            overlayParentView.addSubview(newOverlay.view)
            newOverlay.endAppearanceTransition()
            newOverlay.didMove(toParent: self)
        }
        
        overlayViewController = newOverlayViewController
    }
}

// MARK: - Handle states that require view controller transitions

extension RootViewController: GameStateChangeObserver {
    func gameManagerDidEnter(state: GameManager.State, from previousState: GameManager.State?) {
        var controllerToPresent: UIViewController? // Declare as optional to handle cases where no controller needs to be presented.
        switch state {
        case is GameManager.DetectingPlayerState:
            controllerToPresent = GameViewController()
            
        case is GameManager.ServeDetectedState:
            print("ServeFeedbackState entered, going through the transition")
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.cameraViewController.pauseVideoPlayback()
                }
        case is GameManager.ServeDetectedContinueState:
            print("continued tracking state entered")
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.cameraViewController.resumeVideoPlayback()
            }
            
        
            //controllerToPresent = FeedbackViewController()
        case is GameManager.ShowSummaryState:
            controllerToPresent = SummaryViewController() // Assuming direct instantiation works here.
        default:
            controllerToPresent = nil  // Explicitly handle the default case by setting to nil.
        }

        guard let viewControllerToPresent = controllerToPresent else {
            // No controller to present, so return immediately.
            return
        }

        // Proceed with presenting the view controller.
        // Remove existing overlay controller (if any) from game manager listeners
        if let currentListener = overlayViewController as? GameStateChangeObserverViewController {
            currentListener.stopObservingStateChanges()
        }
        
        presentOverlayViewController(viewControllerToPresent) {
            // Additional setup if needed post presentation.
            if let cameraVC = self.cameraViewController {
                let viewRect = cameraVC.view.frame
                let videoRect = cameraVC.viewRectForVisionRect(CGRect(x: 0, y: 0, width: 1, height: 1))
                let insets = viewControllerToPresent.view.safeAreaInsets
                let additionalInsets = UIEdgeInsets(
                    top: videoRect.minY - viewRect.minY - insets.top,
                    left: videoRect.minX - viewRect.minX - insets.left,
                    bottom: viewRect.maxY - videoRect.maxY - insets.bottom,
                    right: viewRect.maxX - videoRect.maxX - insets.right)
                viewControllerToPresent.additionalSafeAreaInsets = additionalInsets
            }

            // If the new overlay controller conforms to GameStateChangeObserverViewController, add it to the listeners.
            if let gameManagerListener = viewControllerToPresent as? GameStateChangeObserverViewController {
                gameManagerListener.startObservingStateChanges()
            }
            
            // If the new overlay controller conforms to CameraViewControllerOutputDelegate, set it as the camera's delegate.
            if let outputDelegate = viewControllerToPresent as? CameraViewControllerOutputDelegate {
                self.cameraViewController.outputDelegate = outputDelegate
            }
        }
    }
}

