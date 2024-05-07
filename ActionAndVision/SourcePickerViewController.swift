/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller allows to choose the video source used by the app.
     It can be either a camera or a prerecorded video file.
*/

import UIKit
import AVFoundation

class SourcePickerViewController: UIViewController {

    private let gameManager = GameManager.shared
    private var sourcePickerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        gameManager.stateMachine.enter(GameManager.InactiveState.self)
        setupSourcePickerButton()
    }

        private func setupSourcePickerButton() {
            sourcePickerButton = UIButton(type: .system)
            sourcePickerButton.setTitle("Choose from Library", for: .normal)
            sourcePickerButton.addTarget(self, action: #selector(handleSourcePickerButton), for: .touchUpInside)
            view.addSubview(sourcePickerButton)
            configureButtonConstraints()
        }

        private func configureButtonConstraints() {
            sourcePickerButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sourcePickerButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20), // 20 points from the right edge of the safe area
                sourcePickerButton.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Centered vertically in the view
                sourcePickerButton.widthAnchor.constraint(equalToConstant: 200), // Width of 200 points
                sourcePickerButton.heightAnchor.constraint(equalToConstant: 50) // Height of 50 points
            ])
        }


        @objc private func handleSourcePickerButton() {
            print("Opening picker view")
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.mediaTypes = ["public.movie"] // Configure to show only videos
            imagePickerController.delegate = self
            present(imagePickerController, animated: true, completion: nil)
        }
    
    @IBAction func handleUploadVideoButton(_ sender: Any) {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        docPicker.delegate = self
        present(docPicker, animated: true)
    }
    
    @IBAction func revertToSourcePicker(_ segue: UIStoryboardSegue) {
        // This is for unwinding to this controller in storyboard.
        gameManager.reset()
    }
    

}

extension SourcePickerViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        gameManager.recordedVideoSource = nil
    }
    
    func  documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        gameManager.recordedVideoSource = AVAsset(url: url)
        performSegue(withIdentifier: "ShowRootControllerSegue", sender: self)
    }
}

// Ensure your class declaration includes UIImagePickerControllerDelegate and UINavigationControllerDelegate
extension SourcePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let url = info[.mediaURL] as? URL {
            gameManager.recordedVideoSource = AVAsset(url: url)
            performSegue(withIdentifier: "ShowRootControllerSegue", sender: self)
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
