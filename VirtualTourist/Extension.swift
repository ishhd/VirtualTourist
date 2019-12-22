//
//  Extension.swift
//  VirtualTourist
//
//  Created by Shahad on 18/04/1441 AH.
//  Copyright © 1441 Udacity. All rights reserved.
//

import Foundation
import MapKit

extension Pin {
    var coordinate : CLLocationCoordinate2D {
        set{
            latitiude = newValue.latitude
            longitude = newValue.longitude
        }
        get{
            return CLLocationCoordinate2D(latitude: latitiude , longitude: longitude)
        }
    }
    func compare(to coordinate : CLLocationCoordinate2D) -> Bool {
        return (latitiude == coordinate.latitude && longitude == coordinate.longitude)
    }
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}

extension Photo {
    
    func set(image : UIImage){
        self.image = image.pngData()
    }
    
    func get()-> UIImage? {
        return (image == nil) ? nil : UIImage(data: image!)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
}

extension UIViewController {
    func alert(title : String , message : String){
        let alert = UIAlertController (title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert,animated: true,completion: nil)
        }
    }
}
