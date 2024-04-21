/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller to show the game summary.
*/

import UIKit

class SummaryViewController: UIViewController {

    @IBOutlet weak var speedValue: UILabel!
    @IBOutlet weak var angleValue: UILabel!
    @IBOutlet weak var scoreValue: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    private let gameManager = GameManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }

    private func updateUI() {
        let stats = gameManager.playerStats
        backgroundImage.image = gameManager.previewImage
        // Speed label attributed string
        let speedValueFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28.0, weight: .bold)]
        let speedValueText = NSMutableAttributedString(string: "\(round(stats.avgSpeed * 100) / 100)", attributes: speedValueFont)
        let speedUnitFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22.0, weight: .bold)]
        speedValueText.append(NSAttributedString(string: " MPH", attributes: speedUnitFont))

        // set attributed text on a UILabel
        speedValue.attributedText = speedValueText
        angleValue.text = "\(round(stats.avgReleaseAngle * 100) / 100)°"
        let score = NSMutableAttributedString(string: "\(stats.totalScore)", attributes: [.foregroundColor: UIColor.white])
        score.append(NSAttributedString(string: "/40", attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.65)]))
        scoreValue.attributedText = score
    }

}
