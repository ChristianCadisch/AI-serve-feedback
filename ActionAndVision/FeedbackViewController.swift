//
//  FeedbackViewController.swift
//  ActionAndVision
//
//  Created by Christian on 21.04.2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import UIKit

class FeedbackViewController: UIViewController {
    
    private let gameManager = GameManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.giveFeedback()
        
        // Create the button
        let playButton = UIButton(type: .system)
        // Set the title to a unicode play symbol
        playButton.setTitle("▶️", for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        
        // Set the action for the button
        playButton.addTarget(self, action: #selector(playButtonPressed(_:)), for: .touchUpInside)

        // Set the frame of the button, aligning it to the right end of the screen
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 60
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        playButton.frame = CGRect(x: screenWidth - buttonWidth - 20, // 20 points margin from the right
                                  y: screenHeight/2, // 20 points margin from the bottom
                                  width: buttonWidth,
                                  height: buttonHeight)

        // Add the button to the view
        view.addSubview(playButton)

        // Setup your view and any initial data here
    }
    
    private func giveFeedback() {
        //print("Feedback to be implemented")
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        print("Continue Video button pressed")
        
        if let rootViewController = self.parent as? RootViewController {
                    rootViewController.cameraViewController.resumeVideoPlayback()
                }
        gameManager.stateMachine.enter(GameManager.TrackServeState.self)

    }

}
