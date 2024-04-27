/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View that displays a joint segment.
*/

import UIKit
import Vision

class JointSegmentView: UIView, AnimatedTransitioning {
    
    private let gameManager = GameManager.shared
    
    var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:] {
        didSet {
            updatePathLayer()
        }
    }
    
    private let rightWristJointName = VNHumanBodyPoseObservation.JointName.rightWrist
    private let rightShoulderJointName = VNHumanBodyPoseObservation.JointName.rightShoulder
    private var serveDetected = false
    //weak var delegate: JointSegmentViewDelegate?


    private let jointRadius: CGFloat = 3.0
    private let jointLayer = CAShapeLayer()
    private var jointPath = UIBezierPath()

    private let jointSegmentWidth: CGFloat = 2.0
    private let jointSegmentLayer = CAShapeLayer()
    private var jointSegmentPath = UIBezierPath()
    

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    func resetView() {
        jointLayer.path = nil
        jointSegmentLayer.path = nil
    }

    private func setupLayer() {
        jointSegmentLayer.lineCap = .round
        jointSegmentLayer.lineWidth = jointSegmentWidth
        jointSegmentLayer.fillColor = UIColor.clear.cgColor
        jointSegmentLayer.strokeColor = #colorLiteral(red: 0.6078431373, green: 0.9882352941, blue: 0, alpha: 1).cgColor
        layer.addSublayer(jointSegmentLayer)
        let jointColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        jointLayer.strokeColor = jointColor
        jointLayer.fillColor = jointColor
        layer.addSublayer(jointLayer)
    }

    private func updatePathLayer() {
            let flipVertical = CGAffineTransform.verticalFlip
            let scaleToBounds = CGAffineTransform(scaleX: bounds.width, y: bounds.height)
            
            jointPath.removeAllPoints()
            jointSegmentPath.removeAllPoints()
            
            for index in 0 ..< jointsOfInterest.count {
                if let nextJoint = joints[jointsOfInterest[index]] {
                    let nextJointScaled = nextJoint.applying(flipVertical).applying(scaleToBounds)
                    let nextJointPath = UIBezierPath(arcCenter: nextJointScaled, radius: jointRadius,
                                                     startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
                    jointPath.append(nextJointPath)
                    
                    if jointSegmentPath.isEmpty {
                        jointSegmentPath.move(to: nextJointScaled)
                    } else {
                        jointSegmentPath.addLine(to: nextJointScaled)
                    }
                }
            }
          /*
        if let rightWristJoint = joints[rightWristJointName], let rightShoulderJoint = joints[rightShoulderJointName] {
            let yDifference = rightShoulderJoint.y - rightWristJoint.y
            print("Difference between right shoulder and right wrist y-coordinates: \(yDifference)")
        }*/
        
        if let rightWristJoint = joints[rightWristJointName], let rightShoulderJoint = joints[rightShoulderJointName] {
                    let yDifference = rightShoulderJoint.y - rightWristJoint.y
                    if yDifference < -0.1 {
                        if !serveDetected {
                            print("Tennis serve detected!")
                            serveDetected = true
                            //delegate?.jointSegmentViewDidDetectServe(self)
                            //NotificationCenter.default.post(name: .serveDetected, object: nil)
                            self.gameManager.stateMachine.enter(GameManager.ServeDetectedState.self)
                        }
                    } else {
                        serveDetected = false
                    }
                }
            jointLayer.path = jointPath.cgPath
            jointSegmentLayer.path = jointSegmentPath.cgPath
        }
    
    
}

/*
protocol JointSegmentViewDelegate: AnyObject {
    func jointSegmentViewDidDetectServe(_ jointSegmentView: JointSegmentView)
}
*/
/*
extension Notification.Name {
    static let serveDetected = Notification.Name("serveDetected")
}
*/
