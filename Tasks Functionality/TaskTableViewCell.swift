//
//  TaskTableViewCell.swift
//  SaveMyTime
//
//  Created by Terence Ng on 26/5/19.
//  Copyright © 2019 Terence Ng. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dueDescriptionLabel: UILabel?
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var taskTitleLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
