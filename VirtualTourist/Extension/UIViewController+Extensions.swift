//
//  UIViewController+Extensions.swift
//  VirtualTourist
//
//  Created by José Naves Moura Neto on 05/05/19.
//  Copyright © 2019 José Naves Moura Neto. All rights reserved.
//

import UIKit

extension UIViewController {

    func showAlertMessage(message: String) {
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertController.Style.alert)
            let alertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alertController.addAction(alertAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

