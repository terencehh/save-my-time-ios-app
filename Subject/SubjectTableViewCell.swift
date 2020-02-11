//
//  SubjectTableViewCell.swift
//  SaveMyTime
//
//  Created by Terence Ng on 25/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

// this class represnets a single cell to display in a subject list - displays unit code and unit name
class SubjectTableViewCell: UITableViewCell {

    @IBOutlet weak var subjectCodeLabel: UILabel!
    @IBOutlet weak var subjectNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
