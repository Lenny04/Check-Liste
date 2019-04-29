//
//  ListItem.swift
//  Check Liste
//
//  Created by linoj ravindran on 13/08/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import Foundation
import UIKit

class ListItem {
    var itemDescription = "", keyID = ""
    var checked = false
    init(itemDescription: String, checked: Bool, keyID: String)
    {
        self.itemDescription = itemDescription
        self.checked = checked
        self.keyID = keyID
    }
    public func getItemDescription() -> String {
        return itemDescription
    }
    public func setItemDescription(a: String){
        itemDescription = a
    }
    public func getchecked() -> Bool {
        return checked
    }
    public func setChecked(b: Bool){
        checked = b
    }
    public func getKeyID() -> String {
        return keyID
    }
    public func setKeyID(c: String){
        keyID = c
    }
}
