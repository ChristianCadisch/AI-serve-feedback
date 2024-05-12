//
//  AICoach.swift
//  ActionAndVision
//
//  Created by Christian on 11.05.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Vision

class AICoach {
    
    // Function to calculate the angle between three joints
    static func calculateAngle(from joints: [VNHumanBodyPoseObservation.JointName: CGPoint], joint1: VNHumanBodyPoseObservation.JointName, joint2: VNHumanBodyPoseObservation.JointName, joint3: VNHumanBodyPoseObservation.JointName) -> CGFloat? {
        guard let point1 = joints[joint1],
              let point2 = joints[joint2],
              let point3 = joints[joint3] else {
            return nil
        }
        
        // Create vectors
        let v1 = CGVector(dx: point1.x - point2.x, dy: point1.y - point2.y)
        let v2 = CGVector(dx: point3.x - point2.x, dy: point3.y - point2.y)
        
        // Calculate the dot product of vectors v1 and v2
        let dotProduct = v1.dx * v2.dx + v1.dy * v2.dy
        
        // Calculate the magnitudes of vectors v1 and v2
        let magV1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let magV2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        
        // Calculate the cosine of the angle
        let cosineTheta = dotProduct / (magV1 * magV2)
        
        // Calculate the angle in radians
        let angleRadians = acos(min(max(cosineTheta, -1.0), 1.0))  // Clamped to avoid NaN results
        
        // Convert the angle to degrees
        let angleDegrees = angleRadians * 180 / .pi
        
        return angleDegrees
    }
    
    // Function to provide feedback based on joint positions
    static func provideFeedback(for joints: [VNHumanBodyPoseObservation.JointName: CGPoint], pose: String) {
        
        
        
        // ANALYZE TROPHY POSE FROM BEHIND
        if pose == "Trophy behind" {
            
            // Calculate knee angles
            guard let leftKneeAngle = calculateAngle(from: joints, joint1: .leftHip, joint2: .leftKnee, joint3: .leftAnkle),
                  let rightKneeAngle = calculateAngle(from: joints, joint1: .rightHip, joint2: .rightKnee, joint3: .rightAnkle) else {
                print("Could not calculate knee angles.")
                return
            }
            
            let averageKneeAngle = (180 - leftKneeAngle + 180 - rightKneeAngle) / 2
            let federerAverageAngle = 75.0
            
            // Feedback on knee angles
            if averageKneeAngle < federerAverageAngle {
                print("Compared to Roger Federer, your knees are bent \(federerAverageAngle - averageKneeAngle)° less. This gives your serve less power.")
            } else {
                print("Your knee bending is comparable to or better than Roger Federer's, which is good for power.")
            }
            
            // Calculate foot placement
            guard let leftAnkle = joints[.leftAnkle], let rightAnkle = joints[.rightAnkle] else {
                print("Could not find ankle positions.")
                return
            }
            
            let playerStanceDistance = abs(leftAnkle.x - rightAnkle.x)
            let federerStanceDistance = 112.0  // The reference distance for Federer's stance width
            
            // Feedback on foot placement
            if playerStanceDistance / federerStanceDistance < 0.9 {
                print("Federer's feet are \(1 / (playerStanceDistance / federerStanceDistance)) times more apart. This gives more stability.")
            } else {
                print("Your stance width is comparable to or wider than Federer's, which is good for stability.")
            }
            
        }else if pose == "Hit behind" {
            guard let leftWrist = joints[.leftWrist],
                  let rightWrist = joints[.rightWrist],
                  let leftShoulder = joints[.leftShoulder],
                  let rightShoulder = joints[.rightShoulder] else {
                print("Required joints are not available.")
                return
            }
            
            // Determine which wrist is higher and adjust the feedback accordingly
            let isLeftWristHigher = leftWrist.y < rightWrist.y
            let higherWristJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .leftWrist : .rightWrist
            let lowerWristJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .rightWrist : .leftWrist
            let higherShoulder = isLeftWristHigher ? leftShoulder : rightShoulder
            let lowerShoulder = isLeftWristHigher ? rightShoulder : leftShoulder
            
            // Calculate the angle of the arm to determine the direction of the hit
            if let armAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: higherWristJoint, joint3: lowerWristJoint) {
                if armAngle < 50.0 {
                    print("You are hitting the ball too far right from your body.")
                } else if armAngle > 100.0 {
                    print("You are hitting the ball too much on your left.")
                }
            }
            
            // Check if the arm is properly stretched
            let elbowJoint: VNHumanBodyPoseObservation.JointName = isLeftWristHigher ? .leftElbow : .rightElbow

            if let elbowAngle = calculateAngle(from: joints, joint1: .rightShoulder, joint2: elbowJoint, joint3: higherWristJoint) {
                if elbowAngle > 30.0 {
                    print("Keep your arm straight.")
                }
            }
            
            // Compare shoulder heights to ensure proper posture
            if lowerShoulder.y <= higherShoulder.y {
                print("Keep your lower shoulder lower than your higher shoulder for better form.")
            }
        }
    }
}
