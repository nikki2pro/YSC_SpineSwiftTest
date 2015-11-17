//
//  YSC_SpineBone.swift
//  YSC_Spine
//
//  Created by 최윤석 on 2015. 10. 30..
//  Copyright © 2015년 Yoonsuk Choi. All rights reserved.
//

import Foundation
import SpriteKit

class YSC_SpineBone: SKSpriteNode {
    
    var parentName:String?
    var length = CGFloat(0)
    var inheritRotation = true
    var inheritScale = true         // not currently avaliable
    var hasIKAction = false
    var ikTargetNode:SKNode!
    var ikRootNode:SKNode!
    var ikBendPositive = true
    
    var defaultPosition = CGPointZero
    var defaultScaleX = CGFloat(1)
    var defaultScaleY = CGFloat(1)
    var defaultRotation = CGFloat(0)
    var basePosition = CGPointZero
    var baseScaleX = CGFloat(1)
    var baseScaleY = CGFloat(1)
    var baseRotation = CGFloat(0)
    
    var SRTAction = Dictionary<String, SKAction>()  // animation name : SRTAction

    // MARK:- SETUP
    func spawn(boneJSON boneJSON:JSON) {
        
        self.name = boneJSON["name"].stringValue
        self.parentName = boneJSON["parent"].string         // nil if there's no parent
        // Setting its setup pose
        
        if let tempLength = boneJSON["length"].double {         // assue 0 if omitted
            self.length = CGFloat(tempLength)
            self.size.width = CGFloat(tempLength)
            
        }
        if let tempXPos = boneJSON["x"].double {                // assume 0 if ommitted
            self.position.x = CGFloat(tempXPos)
        }
        if let tempYPos = boneJSON["y"].double {                // assume 0 if omitted
            self.position.y = CGFloat(tempYPos)
        }
        if let tempScaleX = boneJSON["scaleX"].double {         // assume 1 if omited
            self.xScale = CGFloat(tempScaleX)
        }
        if let tempScaleY = boneJSON["scaleY"].double {         // assume 1 if omitted
            self.yScale = CGFloat(tempScaleY)
        }
        if let tempZRotation = boneJSON["rotation"].double {    // assume 0 if omitted
            self.zRotation = CGFloat(tempZRotation) * SPINE_DEGTORADFACTOR
        }
        if let tempInheritRotation = boneJSON["inheritRotation"].bool {     // assume true if omitted
            self.inheritRotation = tempInheritRotation
        }
        if let tempInheritScale = boneJSON["inheritScale"].bool {     // assume true if omitted
            self.inheritScale = tempInheritScale
        }

    }
    
    func setDefaultsAndBase() {
        self.defaultPosition = self.position
        self.defaultRotation = self.zRotation
        self.defaultScaleX = self.xScale
        self.defaultScaleY = self.yScale
        self.basePosition = self.position
        self.baseRotation = self.zRotation
        self.baseScaleX = self.xScale
        self.baseScaleY = self.yScale
    }
    
    func setToDefaults() {
        self.position = self.defaultPosition
        self.zRotation = self.defaultRotation
        self.xScale = self.defaultScaleX
        self.yScale = self.defaultScaleY
        self.basePosition = self.position
        self.baseRotation = self.zRotation
        self.baseScaleX = self.xScale
        self.baseScaleY = self.yScale
        
        // set to default attachment
        self.enumerateChildNodesWithName("*") { (node:SKNode, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            if let slot = node as? YSC_SpineSlot {
                slot.setToDefaultAttachment()
            }
        }
        
    }
    // MARK:- ANIMATION
    
    func createAnimations(animationName:String, SRTTimelines:JSON, longestDuration:NSTimeInterval) {
        
        var duration:NSTimeInterval = 0
        var elapsedTime:NSTimeInterval = 0
        var gabageTime:NSTimeInterval = 0
        var gabageAction = SKAction()
        
        let rotateTimelines = SRTTimelines["rotate"]
        let translateTimelines = SRTTimelines["translate"]
        let scaleTimelines = SRTTimelines["scale"]
        
        var rotateActionSequence = Array<SKAction>()
        var translateActionSequence = Array<SKAction>()
        var scaleActionSequence = Array<SKAction>()
        var noInheritRotSequence = Array<SKAction>()
        
        // Rotate Action
        var dAngle = CGFloat(0)
        var currentAngle = CGFloat(0)
        var action = SKAction()
        
        for (_, rotateTimeline):(String, JSON) in rotateTimelines {
            
            duration = NSTimeInterval(rotateTimeline["time"].doubleValue) - elapsedTime
            elapsedTime = NSTimeInterval(rotateTimeline["time"].doubleValue)
            
            dAngle = CGFloat(rotateTimeline["angle"].doubleValue)
            dAngle = dAngle % 360
            if dAngle < -180 {
                dAngle = dAngle + 360
            } else if dAngle >= 180 {
                dAngle = dAngle - 360
            }
            dAngle = dAngle * SPINE_DEGTORADFACTOR
            currentAngle = self.defaultRotation + dAngle
            
            action = SKAction.rotateToAngle(currentAngle, duration: duration)

            if rotateTimeline["curve"].isExists() {
                let curveInfo = rotateTimeline["curve"].rawValue
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
            rotateActionSequence.append(action)
            
        }
        gabageTime = longestDuration - elapsedTime
        gabageAction = SKAction.waitForDuration(gabageTime)
       
        rotateActionSequence.append(gabageAction)
        noInheritRotSequence.append(gabageAction)

        
        let rotateAction = SKAction.sequence(rotateActionSequence)
        let noInheritRotAction = SKAction.sequence(noInheritRotSequence)
        
        
        // Translate Action
        duration = 0
        elapsedTime = 0
        var dx = CGFloat(0)
        var currentX = CGFloat(0)
        var dy = CGFloat(0)
        var currentY = CGFloat(0)
        for (_, translateTimeline):(String, JSON) in translateTimelines {
            
            duration = NSTimeInterval(translateTimeline["time"].doubleValue) - elapsedTime
            elapsedTime = NSTimeInterval(translateTimeline["time"].doubleValue)
            
            dx = CGFloat(translateTimeline["x"].doubleValue)
            dy = CGFloat(translateTimeline["y"].doubleValue)
            currentX = self.defaultPosition.x + dx
            currentY = self.defaultPosition.y + dy
            
            let position = CGPoint(x: currentX, y: currentY)
            action = SKAction.moveTo(position, duration: duration)

            if translateTimeline["curve"].isExists() {
                let curveInfo = translateTimeline["curve"].rawValue
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
            translateActionSequence.append(action)
            
        }
        gabageTime = longestDuration - elapsedTime
        gabageAction = SKAction.waitForDuration(gabageTime)
        translateActionSequence.append(gabageAction)
        let translateAction = SKAction.sequence(translateActionSequence)
        
        // Scale Action
        duration = 0
        elapsedTime = 0
        for (_, scaleTimeline):(String, JSON) in scaleTimelines {
            duration = NSTimeInterval(scaleTimeline["time"].doubleValue) - elapsedTime
            elapsedTime = NSTimeInterval(scaleTimeline["time"].doubleValue)
            
            let scaleX = CGFloat(scaleTimeline["x"].doubleValue)
            let scaleY = CGFloat(scaleTimeline["y"].doubleValue)
            action = SKAction.scaleXTo(scaleX, y: scaleY, duration: duration)

            if scaleTimeline["curve"].isExists() {
                let curveInfo = scaleTimeline["curve"].rawValue
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
            
            scaleActionSequence.append(action)
        }
        gabageTime = longestDuration - elapsedTime
        gabageAction = SKAction.waitForDuration(gabageTime)
        scaleActionSequence.append(gabageAction)
        let scaleAction = SKAction.sequence(scaleActionSequence)
        
        
        let SRTActionGroup = [rotateAction, translateAction, scaleAction, noInheritRotAction]
        let finalActionSequence = [SKAction.unhide(), SKAction.group(SRTActionGroup)]
        
        self.SRTAction[animationName] = SKAction.sequence(finalActionSequence)
    }
    
    func runAnimation(animationName:String, count:Int) {
        
        self.removeAllActions()     // reset all actions first
        self.setToDefaults()
        
        let SRTAction = self.SRTAction[animationName]!
        if count <= -1 {
            let actionForever = SKAction.repeatActionForever(SRTAction)
            self.runAction(actionForever, withKey: animationName)
        } else {
            let repeatedAction = SKAction.repeatAction(SRTAction, count: count)
            self.runAction(repeatedAction, withKey: animationName)
        }
    }
    
    func runAnimationUsingQueue(animationName:String, count:Int, interval:NSTimeInterval, queuedAnimationName:String) {
        self.removeAllActions()     // reset all actions first
        self.setToDefaults()
        
        let SRTAction = self.SRTAction[animationName]!
        let repeatingAction = SKAction.repeatAction(SRTAction, count: count)
        if count <= -1 {
            let actionForever = SKAction.repeatActionForever(SRTAction)
            self.runAction(actionForever, withKey: animationName)
        } else  {
            self.runAction(repeatingAction, completion: { () -> Void in
                let actionSequence:Array<SKAction> = [
                    SKAction.runBlock({ () -> Void in
                        self.setToDefaults()
                    }),
                    SKAction.waitForDuration(interval),
                    SKAction.repeatActionForever(self.SRTAction[queuedAnimationName]!)
                    ]
                self.runAction(SKAction.sequence(actionSequence), withKey: animationName)
            })
        }
    }
    
    func stopAnimation() {
        self.removeAllActions()
    }
    
}















