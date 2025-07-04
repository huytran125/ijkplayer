//
//  IJKPlayerView.swift
//  TestIJKDemo
//
//  SwiftUI wrapper for IJK Player
//

import SwiftUI
import UIKit

class IJKPlayerCoordinator: NSObject, ObservableObject, IJKPlayerWrapperDelegate {
    @Published var isLoading = true
    @Published var isPlaying = false
    @Published var errorMessage: String?
    
    var wrapper: IJKPlayerWrapper?
    
    override init() {
        super.init()
        wrapper = IJKPlayerWrapper(delegate: self)
    }
    
    func setupPlayer(url: String) {
        wrapper?.setupPlayer(withURL: url)
    }
    
    func play() {
        wrapper?.play()
    }
    
    func pause() {
        wrapper?.pause()
    }
    
    func stop() {
        wrapper?.stop()
    }
    
    // MARK: - IJKPlayerWrapperDelegate
    
    func playerDidPrepare() {
        DispatchQueue.main.async {
            self.isLoading = false
            print("SwiftUI: Player prepared")
        }
    }
    
    func playerDidStart() {
        DispatchQueue.main.async {
            self.isPlaying = true
            print("SwiftUI: Player started")
        }
    }
    
    func playerDidFail(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isPlaying = false
            self.errorMessage = error.localizedDescription
            print("SwiftUI: Player failed: \(error.localizedDescription)")
        }
    }
    
    func playerLoadStateChanged(_ loadState: Int) {
        print("SwiftUI: Load state changed: \(loadState)")
    }
}

struct IJKPlayerView: UIViewRepresentable {
    let url: String
    @StateObject private var coordinator = IJKPlayerCoordinator()
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black
        
        coordinator.setupPlayer(url: url)
        
        if let playerView = coordinator.wrapper?.playerView {
            containerView.addSubview(playerView)
            playerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                playerView.topAnchor.constraint(equalTo: containerView.topAnchor),
                playerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                playerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates handled by coordinator
    }
    
    func makeCoordinator() -> IJKPlayerCoordinator {
        return coordinator
    }
} 