//
//  MonsterFormController.swift
//  PAD Friend Finder
//
//  Created by Alexander Chiou on 7/31/15.
//  Copyright (c) 2015 Alexander Chiou. All rights reserved.
//

import Foundation
import JLToast

class MonsterFormController: UIViewController, monsterChoiceDelegate, UITextFieldDelegate, apiConsumerDelegate
{
    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var level: UITextField!
    @IBOutlet weak var awakenings: UITextField!
    @IBOutlet weak var plusEggs: UITextField!
    @IBOutlet weak var skillLevel: UITextField!
    @IBOutlet weak var hypermax: UIButton!
    @IBOutlet weak var minimum: UIButton!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var suggestions: UITableView!
    @IBOutlet weak var suggestionsHeight: NSLayoutConstraint!
    @IBOutlet weak var progress: UIActivityIndicatorView!
    
    var restClient = RestClient()
    var mode = Constants.SEARCH_MODE
    var monsterDelegate : MonsterACDelegate!
    var monsterChosen = false
    var monster : Monster!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        restClient.delegate = self
        setUpPage()
        
        // Round corners on buttons
        minimum.layer.cornerRadius = 5
        hypermax.layer.cornerRadius = 5
        submit.layer.cornerRadius = 5

        // Add on click listeners to buttons
        minimum.addTarget(self, action: "minimize:", forControlEvents: .TouchUpInside)
        hypermax.addTarget(self, action: "hypermax:", forControlEvents: .TouchUpInside)
        submit.addTarget(self, action: "submitMonster:", forControlEvents: .TouchUpInside)
        
        monsterDelegate = MonsterACDelegate(table: suggestions, height: suggestionsHeight, delegate: self)
        suggestions.dataSource = monsterDelegate
        suggestions.delegate = monsterDelegate
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "nameInputListener:",
            name: UITextFieldTextDidChangeNotification,
            object: nameInput)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        if mode == Constants.SEARCH_MODE
        {
            if monster != nil
            {
                level.becomeFirstResponder()
            }
            else
            {
                nameInput.becomeFirstResponder()
            }
        }
        if mode == Constants.ADD_MODE
        {
            nameInput.becomeFirstResponder()
        }
    }
    
    func setUpPage()
    {
        if mode == Constants.SEARCH_MODE
        {
            self.title = Constants.FIND_FRIENDS_LABEL
            if monster != nil
            {
                nameInput.text = monster.name
                picture.image = UIImage(named: monster.imageName)
            }
        }
        else if mode == Constants.ADD_MODE
        {
            self.title = Constants.ADD_MONSTER_LABEL
            self.nameInput.placeholder = Constants.HAVE_A_HINT
            setUpMonsterHints()
        }
        else if mode == Constants.UPDATE_MODE
        {
            self.title = Constants.UPDATE_MONSTER_LABEL
            self.picture.image = UIImage(named: monster.imageName)
            self.nameInput.text = monster.name
            self.nameInput.enabled = false
            self.level.text = String(monster.level)
            self.awakenings.text = String(monster.awakenings)
            self.plusEggs.text = String(monster.plusEggs)
            self.skillLevel.text = String(monster.skillLevel)
            setUpMonsterHints()
        }
    }
    
    func setUpMonsterHints()
    {
        level.placeholder = Constants.LEVEL_HINT
        awakenings.placeholder = Constants.AWAKENINGS_HINT
        plusEggs.placeholder = Constants.PLUS_EGGS_HINT
        skillLevel.placeholder = Constants.SKILL_LEVEL_HINT
    }
    
    func minimize(sender: AnyObject?)
    {
        level.text = String(1)
        awakenings.text = String(0)
        plusEggs.text = String(0)
        skillLevel.text = String(1)
    }
    
    func hypermax(sender: AnyObject?)
    {
        if let monsterInfo = MonsterMapper.sharedInstance.getMonsterInfo(nameInput.text)
        {
            level.text = String(monsterInfo.level)
            awakenings.text = String(monsterInfo.awakenings)
            plusEggs.text = String(Constants.MAX_PLUS_EGGS)
            skillLevel.text = String(monsterInfo.skillLevel)
        }
    }
    
    func submitMonster(sender: AnyObject?)
    {
        self.view.endEditing(true)
        if validateMonsterInput(nameInput.text, level.text, awakenings.text, plusEggs.text, skillLevel.text)
        {
            let monsterInfo = MonsterMapper.sharedInstance.getMonsterInfo(nameInput.text)!
            monster = Monster(level: level.text.toInt()!, skillLevel: skillLevel.text.toInt()!, awakenings: awakenings.text.toInt()!, imageName: monsterInfo.imageName)
            monster.name = nameInput.text
            monster.plusEggs = plusEggs.text.toInt()!
            
            if mode == Constants.ADD_MODE
            {
                if MonsterBoxManager.sharedInstance.isMonsterRedundant(nameInput.text)
                {
                    JLToast.makeText("Your monster box already has a " + nameInput.text + ".", duration: JLToastDelay.LongDelay).show()
                }
                else
                {
                    let body = createUpdateMonsterBody(name: monster.name, level: monster.level, awakenings: monster.awakenings, plusEggs: monster.plusEggs, skillLevel: monster.skillLevel)
                    progress.hidden = false
                    restClient.makeHttpPostRequest(Constants.UPDATE_KEY, body: body, action: Constants.ADD_MODE)
                }
            }
            else if mode == Constants.UPDATE_MODE
            {
                let body = createUpdateMonsterBody(name: monster.name, level: monster.level, awakenings: monster.awakenings, plusEggs: monster.plusEggs, skillLevel: monster.skillLevel)
                progress.hidden = false
                restClient.makeHttpPostRequest(Constants.UPDATE_KEY, body: body, action: Constants.UPDATE_MODE)
            }
            else if mode == Constants.SEARCH_MODE
            {
                performSegueWithIdentifier("loadFriendResults", sender: self)
                clearForm()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)
    {
        if segue.identifier == "loadFriendResults"
        {
            var friendResultsController = segue.destinationViewController as! FriendResultsController
            friendResultsController.monster = monster
        }
    }
    
    // Listener for monster input
    func nameInputListener(notification: NSNotification)
    {
        if let monsterInfo = MonsterMapper.sharedInstance.getMonsterInfo(nameInput.text)
        {
            monsterChosen = true
            picture.image = UIImage(named: monsterInfo.imageName)
        }
        else
        {
            monsterChosen = false
            monsterDelegate.updateWithPrefix(nameInput.text)
            picture.image = UIImage(named: Constants.UNKNOWN_MONSTER_PICTURE_NAME)
        }
    }
    
    // Shifted focus to input
    func textFieldDidBeginEditing(textField: UITextField)
    {
        if !monsterChosen
        {
            monsterDelegate.updateWithPrefix(nameInput.text)
        }
    }
    
    // They stopped entering in a monster
    func textFieldDidEndEditing(textField: UITextField)
    {
        suggestions.hidden = true
    }
    
    // They hit done
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        nameInput.resignFirstResponder()
        return true
    }
    
    func monsterChosen(monster: String)
    {
        monsterChosen = true
        nameInput.text = monster
        suggestions.hidden = true
        if let monsterInfo = MonsterMapper.sharedInstance.getMonsterInfo(nameInput.text)
        {
            picture.image = UIImage(named: monsterInfo.imageName)
        }
        nameInput.resignFirstResponder()
    }
    
    func clearForm()
    {
        monster = nil
        monsterChosen = false
        nameInput.text = ""
        level.text = ""
        awakenings.text = ""
        plusEggs.text = ""
        skillLevel.text = ""
        picture.image = UIImage(named: Constants.UNKNOWN_MONSTER_PICTURE_NAME)
    }
    
    func responseReceived(response: apiCallResponse)
    {
        // Hide Activity Indicator View
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.progress.hidden = true
        })
        if response.action == Constants.ADD_MODE
        {
            if response.httpStatus == 200
            {
                let monsterChangedNotification = NSNotification(name: Constants.MONSTER_UPDATE_KEY, object: monster)
                NSNotificationCenter.defaultCenter().postNotification(monsterChangedNotification)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.clearForm()
                })
                JLToast.makeText(Constants.MONSTER_ADD_SUCCESS_MESSAGE, duration: JLToastDelay.LongDelay).show()
            }
            else
            {
                JLToast.makeText(Constants.MONSTER_ADD_FAILED_MESSAGE, duration: JLToastDelay.LongDelay).show()
            }
        }
        else if response.action == Constants.UPDATE_MODE
        {
            if response.httpStatus == 200
            {
                let monsterChangedNotification = NSNotification(name: Constants.MONSTER_UPDATE_KEY, object: monster)
                NSNotificationCenter.defaultCenter().postNotification(monsterChangedNotification)
                JLToast.makeText(Constants.MONSTER_UPDATE_SUCCESS_MESSAGE, duration: JLToastDelay.LongDelay).show()
                
                // After the monster update succeeds, close the page
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }
            else
            {
                JLToast.makeText(Constants.MONSTER_UPDATE_FAILED_MESSAGE, duration: JLToastDelay.LongDelay).show()
            }
        }
    }
}