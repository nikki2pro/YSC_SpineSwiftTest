//
//  YSC_SpineSlot.swift
//  YSC_Spine
//
//  Created by 최윤석 on 2015. 10. 30..
//  Copyright © 2015년 Yoonsuk Choi. All rights reserved.
//

import Foundation
import SpriteKit

class YSC_SpineSlot: SKNode {
    
    var parentName = String()
    
    var color:UIColor?
    
    var currentAttachmentName:String?
    var defaultAttachmentName:String?
    
    var colorAction = Dictionary<String, SKAction>()
    
    // MARK:- SETUP
    
    func spawn(slotJSON slotJSON:JSON, drawOrder:Int) {
        
        // Setting slot's attributes
        self.name = slotJSON["name"].stringValue
        self.parentName = slotJSON["bone"].stringValue   // no optional because it's a must
        if let color = slotJSON["color"].string {
            self.color = self.colorRGBAFromString(color)
        }
        
        // set currentAttachmentName
        self.defaultAttachmentName = slotJSON["attachment"].string
        self.zPosition = CGFloat(drawOrder) * 0.01
        
        // print(self)
    }
    
    func createAnimation(animationName:String, timelineTypes:JSON, longestDuration:NSTimeInterval) {
        
        let attachmentTimelines = timelineTypes["attachment"]
        
        // print(attachmentTimelines)
        
        // create attachment SKAction for all sprite children of the slot and store them in attachment instance
        self.enumerateChildNodesWithName("*") { (node:SKNode, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            //print(node.name)
            let attachment = node as! YSC_SpineAttachment
            attachment.createAnimation(animationName, attachmentTimelines: attachmentTimelines, longestDuration: longestDuration)
            
        }
        
        if timelineTypes["color"].isExists() {
            let colorTimelines = timelineTypes["color"]
            var duration:NSTimeInterval = 0
            var elapsedTime:NSTimeInterval = 0
            var actionSequenceForColor = Array<SKAction>()
            for (_, timeline):(String, JSON) in colorTimelines {
                duration = NSTimeInterval(timeline["time"].doubleValue) - elapsedTime
                elapsedTime = NSTimeInterval(timeline["time"].doubleValue)
                let colorString = timeline["color"].stringValue
                let color = self.colorRGBAFromString(colorString)
                
                let action = SKAction.colorizeWithColor(color, colorBlendFactor: 0.5, duration: duration)
                if timeline["curve"].isExists() {
                    let curveInfo = timeline["curve"].rawValue
                    if curveInfo.isKindOfClass(NSString) {
                        let curveString = curveInfo as! String
                        if curveString == "stepped" {
                            // stepped curve
                            action.timingMode = .EaseIn
                        }
                    } else if curveInfo.isKindOfClass(NSArray) {
                        // bezier curve
                        action.timingMode = .EaseInEaseOut
                    }
                } else {
                    // linear curve
                    action.timingMode = .Linear
                }
                actionSequenceForColor.append(action)
            }
            let gabageTime = longestDuration - elapsedTime
            let gabageAction = SKAction.waitForDuration(gabageTime)
            actionSequenceForColor.append(gabageAction)
            self.colorAction[animationName] = SKAction.sequence(actionSequenceForColor)
        }
        
        
    }

    // MARK:- ANIMATION
    func runAnimation(animationName:String, count:Int) {
        
        // cycle all child attachment to run action(the action is run by attachment)
        self.enumerateChildNodesWithName("*") { (node:SKNode, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            
            node.removeAllActions()         // reset all actions first
            let sprite = node as! YSC_SpineAttachment
            // Find the right action
            for (tempAnimationName, attachmentAction) in sprite.action {
                if tempAnimationName == animationName {
                    var actionGroup = Array<SKAction>()
                    actionGroup.append(attachmentAction)
                    
                    if let action = self.colorAction[animationName] {
                        actionGroup.append(action)
                    }
                    if count <= -1 {
                        let actionForever = SKAction.repeatActionForever(SKAction.group(actionGroup))
                        sprite.runAction(actionForever)
                    } else {
                        let repeatedAction = SKAction.repeatAction(SKAction.group(actionGroup), count: count)
                        sprite.runAction(repeatedAction)
                    }
                }
            }
        }
    }
    
    func runAnimationUsingQueue(animationName:String, count:Int, interval:NSTimeInterval, queuedAnimationName:String) {
        
        self.enumerateChildNodesWithName("*") { (node:SKNode, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            
            node.removeAllActions()         // reset all actions first
            let sprite = node as! YSC_SpineAttachment
            // Find the right action
            for (tempAnimationName, attachmentAction) in sprite.action {
                if tempAnimationName == animationName {
                    var actionGroup = Array<SKAction>()
                    actionGroup.append(attachmentAction)
                    
                    if let action = self.colorAction[animationName] {
                        actionGroup.append(action)
                    }
                    if count <= -1 {
                        let actionForever = SKAction.repeatActionForever(SKAction.group(actionGroup))
                        sprite.runAction(actionForever)
                    } else {
                        let repeatedAction = SKAction.repeatAction(SKAction.group(actionGroup), count: count)
                        var queuedActionGroup = Array<SKAction>()
                        if let action = sprite.action[queuedAnimationName] {
                            queuedActionGroup.append(action)
                        }
                        if let action = self.colorAction[queuedAnimationName]{
                            queuedActionGroup.append(action)
                        }
                        if queuedActionGroup.isEmpty == false {
                            sprite.runAction(repeatedAction, completion: { () -> Void in
                                let actionSequence = SKAction.sequence([
                                    SKAction.waitForDuration(interval),
                                    SKAction.repeatActionForever(SKAction.sequence(queuedActionGroup))
                                    ])
                                sprite.runAction(actionSequence)
                            })
                        } else {
                            sprite.runAction(SKAction.repeatAction(repeatedAction, count: count))
                        }
                    }
                }
            }
        }
    }

    
    func stopAnimation() {
        self.enumerateChildNodesWithName("*") { (node:SKNode, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            let sprite = node as! YSC_SpineAttachment
            sprite.removeAllActions()
        }
    }
    
    func setToDefaultAttachment() {
        self.enumerateChildNodesWithName("*") { (node:SKNode, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            if let sprite = node as? YSC_SpineAttachment {
                if self.defaultAttachmentName == sprite.name {
                    sprite.hidden = false
                } else {
                    sprite.hidden = true
                }
            }
        }
    }
    
    
    // MARK:- ETC
    func colorRGBAFromString(colorString:String) -> UIColor {
        let red = colorString[0...1]
        let green = colorString[2...3]
        let blue = colorString[4...5]
        let alpha = colorString[6...7]
        let redNum:CGFloat = CGFloat(UInt(red, radix: 16)!) / 255.0
        let greenNum:CGFloat = CGFloat(UInt(green, radix: 16)!) / 255.0
        let blueNum:CGFloat = CGFloat(UInt(blue, radix: 16)!) / 255.0
        let alphaNum:CGFloat = CGFloat(UInt(alpha, radix: 16)!) / 255.0
        return UIColor(red: redNum, green: greenNum, blue: blueNum, alpha: alphaNum)
    }
}

// MARK:- EXTENSTIONS

// need to extract RGBA from color string (ex) "abcde"[0...1] = "ab"  :  I got this code by googling.. forgot where...
extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}

// hexadecimal string to int http://stackoverflow.com/questions/27189338/swift-native-functions-to-have-numbers-as-hex-strings
extension UInt {
    init?(_ string: String, radix: UInt) {
        let digits = "0123456789abcdefghijklmnopqrstuvwxyz"
        var result = UInt(0)
        for digit in string.lowercaseString.characters {
            if let range = digits.rangeOfString(String(digit)) {
                let val = UInt(digits.startIndex.distanceTo(range.startIndex))
                if val >= radix {
                    return nil
                }
                result = result * radix + val
            } else {
                return nil
            }
        }
        self = result
    }
}
