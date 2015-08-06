//
//  MonsterSuggestionCell.swift
//  PAD Friend Finder
//
//  Created by Alexander Chiou on 8/5/15.
//  Copyright (c) 2015 Alexander Chiou. All rights reserved.
//

import UIKit

class MonsterSuggestionCell: UITableViewCell
{
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    func configureCell(monsterName: String)
    {
        self.name.text = monsterName
        if let monsterInfo = MonsterMapper.sharedInstance.getMonsterInfo(monsterName)
        {
            self.picture.image = UIImage(named: monsterInfo.imageName)
        }
    }
}