//
//  CarPlaySceneDelegate.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import UIKit
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        let templateManager = CarPlayTemplateManager.shared
        templateManager.setInterfaceController(interfaceController)
        
        let rootTemplate = templateManager.createRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)
        
        print("[CarPlay] Araç konsolu başarıyla bağlandı ve root template yüklendi.")
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        print("[CarPlay] Araç konsolu bağlantısı kesildi.")
    }
}
