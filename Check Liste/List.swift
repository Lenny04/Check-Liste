//
//  List.swift
//  Check Liste
//
//  Created by linoj ravindran on 15/08/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import Foundation
import UIKit

class List {
    var listName = "", keyID = ""
    init(listName: String, keyID: String)
    {
        self.listName = listName
        self.keyID = keyID
    }
    public func getListName() -> String {
        return listName
    }
    public func setListName(a: String){
        listName = a
    }
    public func getKeyID() -> String {
        return keyID
    }
    public func setKeyID(c: String){
        keyID = c
    }
}
