//
//  SceneDelegate.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let contentView = DJAppContentHolder()
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }
}

struct DJAppContentHolder: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        ZStack {
            DJColor.darkBackground.ignoresSafeArea()
            if authVM.isUnlocked {
                MainDJConsoleView(authVM: authVM)
            } else {
                AccessGateView(authVM: authVM)
            }
        }
        .preferredColorScheme(.dark)
    }
}
