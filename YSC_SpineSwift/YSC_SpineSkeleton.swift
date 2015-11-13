//
//  YSC_SpineSkeleton.swift
//  YSC_SKSpine_New
//
//  Created by 최윤석 on 2015. 11. 5..
//  Copyright © 2015년 Yoonsuk Choi. All rights reserved.
//

import Foundation
import SpriteKit

let SPINE_DEGTORADFACTOR:CGFloat = 0.017453292519943295 // pi/180
let SPINE_RADTODEGFACTOR:CGFloat = 57.29577951308232 // 180/pi

class YSC_SpineSkeleton: SKNode {
    
    var spineVersion = String()
    var currentSkinName = "default"
    var originalSize = CGSizeZero
    
    var bones = Array<YSC_SpineBone>()
    var slots = Array<YSC_SpineSlot>()
    var animatingSlotNames = Dictionary<String, Array<String>>() // animation name: [slot name]
    var longestDurations = Dictionary<String, NSTimeInterval>()     // animation name:longestDuration
    
    var atlas = SKTextureAtlas()
    var animationNames = Array<String>()
    private var privateQueuedAnimation:String?
    var queuedAnimation:String? {
        
        get {
            if self.privateQueuedAnimation != nil {
                return self.privateQueuedAnimation!
            } else {
                print("no queued Animation!!!! Set it first!!")
            }
            return nil
        }

        set (aName){
            for animationName in animationNames {
                if aName == animationName {
                    self.privateQueuedAnimation = aName
                    break
                }
            }
            if self.privateQueuedAnimation == nil {
                print("It's not a valid animation name. CHeck it please!!")
            }
        }
    }
    
    
    // MARK:- SETUP
    
    func spawn(JSONName JSONName:String, atlasName:String, skinName:String?) {
        
        atlas = SKTextureAtlas(named: atlasName)
        
        // load JSON file
        let tool = YSC_SpineJSONTools()
        let json = tool.readJSONFile(JSONName)
        
        // Basic Skeleton info
        self.spineVersion = json["skeleton"]["spine"].stringValue
        self.originalSize.width = CGFloat(json["skeletion"]["width"].doubleValue)
        self.originalSize.height = CGFloat(json["skeletion"]["height"].doubleValue)
        
        // create all bone instances with its setup pose and build their relationship(parent-child)
        let bonesJSON = json["bones"]
        self.bones = self.createBones(bonesJSON: bonesJSON)
        
        
        
        
        // create all slot instances, find their parent bone instances, and store them in self.slots as array
        let slotsJSON = json["slots"]
        self.slots = self.createSlots(slotsJSON: slotsJSON)
        
        // create attachment instances, find their parent slot
        if skinName != nil {
            self.currentSkinName = skinName!
        }
        let skinJSON = json["skins"][currentSkinName]
        self.createSkin(skinJSON: skinJSON)
        
        
        // create animations
        let animationsJSON = json["animations"]
        self.createAnimations(animationJSON: animationsJSON)
        let ikJSON = json["ik"]
        self.setupForIKAction(ikJSON)
        
    }
    
    func createBones(bonesJSON bonesJSON:JSON) -> Array<YSC_SpineBone> {
        
        var tempBones = Array<YSC_SpineBone>()
        
        // create all bone instances with its setup pose
        for (_, boneJSON):(String, JSON) in bonesJSON {
            let aBone = YSC_SpineBone()
            aBone.spawn(boneJSON: boneJSON)
            aBone.setDefaultsAndBase()
            tempBones.append(aBone)
        }
        
        // cycle all bones to set parent-child relationship
        for aBone in tempBones {
            if aBone.parentName != nil {
                for parentBone in tempBones {
                    if parentBone.name == aBone.parentName {
                        parentBone.addChild(aBone)
                    }
                }
            } else {    // if there's no parent bone, it's a root bone. it should be the child of the skeleton
                self.addChild(aBone)
            }
 
        }
        
        // Consider the inheritance of rotation for each bone (if inheritance is false, remove all ancestor's rotation)
        var dAngle = CGFloat(0)
        var parent:SKNode?
        for aBone in tempBones {
            dAngle = 0
            if aBone.inheritRotation == false {
                parent = aBone.parent
                while let nextParent = parent {
                    if nextParent.isKindOfClass(YSC_SpineBone) {
                        dAngle = dAngle + nextParent.zRotation
                    }
                    parent = nextParent.parent
                }
            }
            aBone.zRotation = aBone.zRotation - dAngle
            aBone.setDefaultsAndBase()
        }

        return tempBones
    }
    
    func createSlots(slotsJSON slotsJSON:JSON) -> Array<YSC_SpineSlot> {
        
        // Initialize temporary array of slot instances
        var tempSlots = Array<YSC_SpineSlot>()
        
        // create all slot instances with its attributes setting
        for (index, slotJSON):(String, JSON) in slotsJSON {
            let aSlot = YSC_SpineSlot()
            aSlot.spawn(slotJSON: slotJSON, drawOrder: Int(index)!)
            
            // find slot instance's parent bone and set relation
            for aBone in self.bones {
                if aBone.name == aSlot.parentName {
                    aBone.addChild(aSlot)
                }
            }
            
            // add the slot instance to the array of slot instances
            tempSlots.append(aSlot)
        }
        
        return tempSlots
    }
    
    func createSkin(skinJSON skinJSON:JSON) {
        
        for (slotName, attachmentJSON):(String, JSON) in skinJSON {
            
            // Find the slot instance of the attachment
            var slot = YSC_SpineSlot()
            for aSlot in self.slots {
                if aSlot.name == slotName {
                    slot = aSlot
                }
            }
            
            // create all attachments with their attributes and build parent-child relationship
            for (attachmentName, attachmentDataJSON):(String, JSON) in attachmentJSON {
                
                let attachment = YSC_SpineAttachment(texture: atlas.textureNamed(attachmentName))
                attachment.spawn(attachmentName: attachmentName, attributes: attachmentDataJSON)
                if slot.color != nil {
                    attachment.color = slot.color!
                    attachment.colorBlendFactor = 0.5
                }
                if slot.defaultAttachmentName == attachment.name {  // set default attachment viewable
                    //print(attachment)
                    attachment.hidden = false
                    slot.currentAttachmentName = attachment.name
                }
                slot.addChild(attachment)
            }
        }
    }
    
    func createAnimations(animationJSON animationsJSON:JSON){
        
        for (animationName, animationData):(String, JSON) in animationsJSON {
            
            self.animationNames.append(animationName)           // store the name of animation for reference
            // print(self.animationNames)
            let longestDuration = self.findLongestDuration(animationData)       // need the longest duration to sync all actions
            self.longestDurations[animationName] = longestDuration
            // print(self.longestDurations)
            // print(animationName, longestDuration) // confirmed
            
            // slot animations
            let slotAnimations = animationData["slots"]
            var slotArray = Array<String>()
            for (slotName, timelineTypes):(String, JSON) in slotAnimations {
                for aSlot in self.slots {                       // Finding slots which have animation
                    if slotName == aSlot.name {
                        slotArray.append(slotName)
                        aSlot.createAnimation(animationName, timelineTypes: timelineTypes, longestDuration: longestDuration)
                    }
                }
                
                // remember bones that have slot animations
                self.animatingSlotNames[animationName] = slotArray
            }
            
            // bone Animations
            let boneAnimations = animationData["bones"]
            for aBone in self.bones {
                let SRTTimelines = boneAnimations[aBone.name!]
                aBone.createAnimations(animationName, SRTTimelines: SRTTimelines, longestDuration: longestDuration)
            }

            
        }
        //print(self.animatingSlotNames) // confirmed
    }
    
    func setupForIKAction(ikJSON:JSON) {
        for aBone in self.bones {
            
            for (_, ik):(String, JSON) in ikJSON {

                let lastIndex = ik["bones"].count - 1
                let ikBoneName = ik["bones"][lastIndex].stringValue
                let rootBoneName = ik["bones"][0].stringValue
                let targetBoneName = ik["target"].stringValue
                let bendPositive = ik["bendPositive"].bool
                if aBone.name == ikBoneName && ik["mix"].double == nil {
                    aBone.hasIKAction = true
                    if bendPositive == false {
                        aBone.ikBendPositive = false
                        aBone.reachConstraints = SKReachConstraints(lowerAngleLimit: -160 * SPINE_DEGTORADFACTOR, upperAngleLimit: -20 * SPINE_DEGTORADFACTOR)
                    } else {
                        aBone.reachConstraints = SKReachConstraints(lowerAngleLimit: 20 * SPINE_DEGTORADFACTOR, upperAngleLimit: 160 * SPINE_DEGTORADFACTOR)
                    }
                    let ikRootNode = self.findBone(rootBoneName, inBonesArray: self.bones)
                    aBone.ikRootNode = ikRootNode
                    let ikTargetNode = self.findBone(targetBoneName, inBonesArray: self.bones)
                    aBone.ikTargetNode = ikTargetNode
                    let endPoint = SKNode()
                    endPoint.name = "endPoint"
                    endPoint.position.x = aBone.length
                    aBone.addChild(endPoint)      // setting endpoint for inverse kinematics
                }
            }
        }
    }
    
    // MARK:- ANIMATION
    func runAnimation(animationName:String, count:Int) {
        
        if let animatingSlotNameArray = self.animatingSlotNames[animationName] {
            // Find the slot intances which have action
            for slotName in animatingSlotNameArray {
                for aSlot in self.slots {
                    if aSlot.name == slotName {
                        aSlot.runAnimation(animationName, count: count)
                    }
                }
            }
        }
        for aBone in self.bones {
            aBone.runAnimation(animationName, count: count)
        }
    }
    
    func runAnimationUsingQueue(animationName:String, count:Int, interval:NSTimeInterval) {
        
        if let queuedAnimationName = self.privateQueuedAnimation {
            
            // slot animation
            if let animatingSlotNameArray = self.animatingSlotNames[animationName] {
                // Find the slot intances which have action
                for slotName in animatingSlotNameArray {
                    for aSlot in self.slots {
                        if aSlot.name == slotName {
                            aSlot.runAnimationUsingQueue(animationName, count: count, interval: interval, queuedAnimationName: queuedAnimationName)
                        }
                    }
                }
            }
            // bone animation
            for aBone in self.bones {
                
                aBone.runAnimationUsingQueue(animationName, count: count, interval: interval, queuedAnimationName: queuedAnimationName)
            }
        } else {
            print("No queued animation. Set queue animation first!!!")
        }
        
    }
    
    func runQueue() {
        if self.privateQueuedAnimation == nil {
            print("No queued animation!!! Set it first!!")
        } else {
            self.runAnimation(self.privateQueuedAnimation!, count: -1)
        }
    }
    
    func stopAnimation() {
        for aBone in self.bones {
            aBone.stopAnimation()
        }
        for aSlot in self.slots {
            aSlot.stopAnimation()
        }
    }
    // This function should be in the didFinishUpdate function of the scene
    func ikActionUpdate() {
        for aBone in self.bones {
            
            if aBone.inheritRotation == false {
                aBone.zRotation = aBone.defaultRotation
            }
            
            if aBone.hasIKAction == true {
                let position = self.scene!.convertPoint(aBone.ikTargetNode.position, fromNode: aBone.ikTargetNode.parent!)
                //print(aBone.ikTargetNode.name, position)
                let action = SKAction.reachTo(position, rootNode: aBone.ikRootNode, duration: 0)
                let ikAction = SKAction.runAction(action, onChildWithName: "endPoint")
                aBone.runAction(ikAction)
            }
        }
    }
    
    // MARK:- ETC
    
    func findLongestDuration(animationData:JSON) -> NSTimeInterval {
        
        var longestDuration = NSTimeInterval(0)
        for (_, json1):(String, JSON) in animationData{
            for (_,json2):(String, JSON) in json1 {
                for (_, json3):(String, JSON) in json2 {
                    for(_,json4):(String, JSON) in json3 {
                        let currentDuration = json4["time"].doubleValue
                        if longestDuration < currentDuration {
                            longestDuration = currentDuration
                        }
                    }
                }
            }
        }
        return longestDuration
    }
    
    func findBone(boneName:String, inBonesArray:Array<YSC_SpineBone>) -> YSC_SpineBone? {
        for aBone in self.bones {
            if aBone.name == boneName {
                return aBone
            }
        }
        return nil
    }
    

    
}


































