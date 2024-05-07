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
    
    private let leftWristJointName = VNHumanBodyPoseObservation.JointName.leftWrist
    private let leftShoulderJointName = VNHumanBodyPoseObservation.JointName.leftShoulder
    private var trophyDetected = false

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
            
        // Define anatomical connections for right side
            let rightSideConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                (.rightShoulder, .rightElbow),
                (.rightShoulder, .rightHip),
                (.rightElbow, .rightWrist),
                (.rightHip, .rightKnee),
                (.rightKnee, .rightAnkle)
            ]

            // Draw joints and segments based on defined connections
            for (startJoint, endJoint) in rightSideConnections {
                if let startPoint = joints[startJoint], let endPoint = joints[endJoint] {
                    let startJointScaled = startPoint.applying(flipVertical).applying(scaleToBounds)
                    let endJointScaled = endPoint.applying(flipVertical).applying(scaleToBounds)

                    // Draw joint circles
                    let startJointPath = UIBezierPath(arcCenter: startJointScaled, radius: jointRadius,
                                                      startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
                    let endJointPath = UIBezierPath(arcCenter: endJointScaled, radius: jointRadius,
                                                    startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
                    jointPath.append(startJointPath)
                    jointPath.append(endJointPath)

                    // Draw lines between connected joints
                    jointSegmentPath.move(to: startJointScaled)
                    jointSegmentPath.addLine(to: endJointScaled)
                }
            }

        // serve detection
        if let rightWristJoint = joints[rightWristJointName], let rightShoulderJoint = joints[rightShoulderJointName] {
                    let yDifference = rightShoulderJoint.y - rightWristJoint.y
                    if yDifference < -0.1 {
                        if !serveDetected {
                            print("Tennis serve detected!")
                            print("Trophy variable: ", trophyDetected)
                            serveDetected = true
                            self.gameManager.stateMachine.enter(GameManager.ServeDetectedState.self)
                        }
                    } else {
                        serveDetected = false
                    }
            }
        
        
        // trophy pose detection - currently only works on first trophy pose?
        if let leftWristJoint = joints[leftWristJointName], let leftShoulderJoint = joints[leftShoulderJointName] {
                    let yDifference = leftShoulderJoint.y - leftWristJoint.y
                    if yDifference < -0.1 { // checking if the wrist is above the shoulder
                        if !trophyDetected {
                            print("Trophy pose detected!")
                            trophyDetected = true
                            self.gameManager.stateMachine.enter(GameManager.TrophyDetectedState.self)
                        }
                    } else {
                        trophyDetected = false
                    }
            }
        

        
            jointLayer.path = jointPath.cgPath
            jointSegmentLayer.path = jointSegmentPath.cgPath
        }
    
        
    
}

