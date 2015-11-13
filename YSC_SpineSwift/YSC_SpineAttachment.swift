//
//  YSC_SpineAttachment.swift
//  YSC_Spine
//
//  Created by 최윤석 on 2015. 10. 30..
//  Copyright © 2015년 Yoonsuk Choi. All rights reserved.
//

import Foundation
import SpriteKit

// Info: 1. Attachment type regionsequence and boundingbox(including vertices) are not supported
//       2. fps and mode are not supported
//       3.


class YSC_SpineAttachment: SKSpriteNode {
    
    
    var action = Dictionary<String, SKAction>()     // animation name : SKAction
    
    func spawn(attachmentName attachmentName:String, attributes:JSON) {

        self.name = attachmentName

        if let xPos = attributes["x"].double {              // assume 0 if omitted
            self.position.x = CGFloat(xPos)
        }
        if let yPos = attributes["y"].double {              // assume 0 if omitted
            self.position.y = CGFloat(yPos)
        }
        if let xScale = attributes["scaleX"].double {       // assume 1 if omitted
            self.xScale = CGFloat(xScale)
        }
        if let yScale = attributes["scaleY"].double {       // assume 1 if omitted by default
            self.yScale = CGFloat(yScale)
        }
        if let rotation = attributes["rotation"].double {   // assume 0 if omitted
            self.zRotation = CGFloat(rotation) * SPINE_DEGTORADFACTOR
        }
        self.size.width = CGFloat(attributes["width"].doubleValue)
        self.size.height = CGFloat(attributes["height"].doubleValue)
        self.hidden = true
        
    }
    
    func createAnimation(animationName:String, attachmentTimelines:JSON, longestDuration:NSTimeInterval) {
        var duration:NSTimeInterval = 0
        var elapsedTime:NSTimeInterval = 0
        var actionSequenceForAttachment = Array<SKAction>()
        
        for (_, timeline):(String, JSON) in attachmentTimelines {

            duration = NSTimeInterval(timeline["time"].doubleValue) - elapsedTime
            elapsedTime = NSTimeInterval(timeline["time"].doubleValue)
            actionSequenceForAttachment.append(SKAction.waitForDuration(duration))
            if self.name == timeline["name"].string {
                actionSequenceForAttachment.append(SKAction.unhide())
            } else {
                actionSequenceForAttachment.append(SKAction.hide())
            }
        }
        //print(self.parent?.name, actionSequenceForAttachment)
        // synch total animation time with other sprites
        let gabageTime = longestDuration - elapsedTime
        let gabageAction = SKAction.waitForDuration(gabageTime)
        actionSequenceForAttachment.append(gabageAction)
        

        self.action[animationName] = SKAction.sequence(actionSequenceForAttachment)
        // print(self.parent!.name, self.action)
        
    }
    
}



















