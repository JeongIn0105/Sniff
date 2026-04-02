//
//  SceneDelegate.swift
//  Sniff
//
//  Created by 이정인 on 4/2/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // 윈도우 : 앱에 반드시 한 개는 필요한 가장 근본이 되는 뷰. 이 위에 뷰가 쌓이기 시작.
    var window: UIWindow?

    // 앱을 시작할 때 세팅해줄 코드들을 작성해주는 곳.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // UIWindowScene 객체 생성.
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        // 윈도우에게 루트 뷰 컨트롤러 지정.
        window.rootViewController = UINavigationController(rootViewController: MainViewController())
        
        // 이 메서드를 반드시 작성해줘야만 윈도우가 활성화가 됨.
        window.makeKeyAndVisible()
        
        self.window = window

    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

