//
//  CheckListCell.swift
//  Check Liste
//
//  Created by linoj ravindran on 13/08/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import Foundation
import UIKit
import M13Checkbox
class CheckListCell: UITableViewCell {
    @IBOutlet var checkBoxtext: UILabel!
    var checkBox = M13Checkbox(frame: CGRect(x: 15.0, y: 5.0, width: 35.0, height: 35.0))
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
