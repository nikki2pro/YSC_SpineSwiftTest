# YSC_SpineSwiftSK

BEFORE YOU READ: I AM NOT A NATIVE ENGLISH SPEAKER! SO MY ENGLISH MIGHT BE LITTLE BROKEN! SORRY FOR THAT!

It makes Spine JSON file usable in Swift by using SpriteKit.

It is an unofficial runtime for Swift 2.1 to import JSON files created from Spine(software by esoteric software http://esotericsoftware.com).
I don't have any knowledge in official Spine runtime, nor any relationship with Spine.
I built this runtime without using their official runtime(Honestly I don't understand their offical runtime. It's an alien language to me).

I refered SGG_SKSpine,  https://github.com/mredig/SGG_SKSpineImport.
First I just wanted to modify SGG_SKSpine to make it fully functional. In doing so, I thought that I'd better make my own Swift runtime. I tried to use SpriteKit's versatility as much as possible. So this runtime is built in 100% swift 2.1. It's very compact, very readable, and easy to use. If you are familiar with Swift, I believe you can easily customize this runtime.

LISCENCE ISSUE
- This runtime uses SwiftyJSON: https://github.com/SwiftyJSON/SwiftyJSON (It made JSON import so much easier!!)
- The JSON files and atlas(alien.JSON, alien.atlas, hero.JSON, and hero.atlas) used here are the samples included in Spine software.
- You can use and modify this runtime for personal or internal purpose. But not for your commecial use.

WHAT IT SUPPORTS:
- Fully functional bone and slot animations (scale, rotate, translate, color, curve, and so on)
- Support IK (Inverse Kinematics), which is available in Spine Pro version
- Support Rotation inheritance off option

WHAT IT DOES NOT SUPPORT:
- Mesh sprite
- Scale inheritance option ( I didn't do it because i don't use it: but you can implement it if you want. the same     way I did the rotation inheritance)
- Event and Draw Order timeline
- some of attachment type: regionsequence and Boundingbox : those are supported in SpriteKit itself. (ex.         PhysicsBody)

WHAT YOU SHOULD KNOW:
- Not fully support curve attribute:
  + linear curve ==> linear.
  + stepped curve ==> SKAction timingMode EaseIn.
  + bezier curve (array of two points) ==> SKAction timingMode EaseInEaseOut.
  + I think this is sufficient. However, if you want fully customized bezier curve, you can do it by using SKAction's     timingFunction.

- Not fully support rotation inheritance:
  If you choose rotation inheritance off in Spine, the node will ignore its parent's rotation. But it will not rotate   by its own either. it will remain in its default pose rotation.

- Rotation Direction: 
  Sometimes the node can rotate to the direction you don't want. if it rotates more than 180 degree, the node will     rotate to the direction along the shortest path.

- Not fully support IK:
  + Mix option is not available: only 100% or 0% mix is possible.
  + Rotating angle is limited:
    * bendPositive off ==> -20 ~ -160 (in degree)
    * bendPositive on  ==> 20 ~ 160 (in degree)
    * This is just for good IK animation result. SpriteKit's IK action is different from Spine IK Action, so I made        some tuning for normal animations. You can change it in my code. refer SKReachConstraints. 

USAGE

- Copy YSC_SpineSwift folder to your project.
- Copy SwiftyJSON.swift to your project(You can download it from https://github.com/SwiftyJSON/SwiftyJSON ).
- Copy your JSON file and atlas folder to your project.
  + atlas created in Spine will not work. Atlas folder with all image files only.
  + atlas folder name should be like "something.atlas".
  + atlas folder should include all image files(image files used in Spine).
- IMPORTANT: In order to enable ikAction and Rotation inheritance option, put ikActionUpdate() in didFinishUpdate() of the scene(GameScene class or SKScene class)
~~~
    override func didFinishUpdate() {
        hero.ikActionUpdate()
    }
}
~~~
- Here's simple example: It's assuming your JSON file name is "hero.JSON" and your atlas folder name is "hero.atlas"
~~~
  let hero = YSC_Skeletion()
  hero.spawn(JSONName: "hero", atlasName:"hero", skinName: nil)
  hero.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMinY(self.frame) + 50)
  hero.xScale = 0.5
  hero.yScale = 0.5
  hero.queuedAnimation = "Idle"
  self.addChild(hero)
  hero.runQueue()
  hero.runAnimationUsingQueue("Attack", count: 1, interval: 0)
~~~

PROPERTY AND FUNCTIONS

- queuedAnimation
  + It's kinda default animation you can set
  + For example, you can set queuedAnimation to your idle animation. 

- spawn(JSONName JSONName:String, atlasName:String, skinName:String?)
  + Set up skeleton with JSON file and atlas file. if skinName is skipped, the default skin is set.

- runQueue()
  + Run queued animation, which will be repeated forever. if there's no queued animation, you'll get error message.

- runAnimation(animationName:String, count:Int)
  + This function will run the animation. if count is less than 0(like -1), it will be repeated forever.
  + Queued animation will not be followed!!!

- runAnimationUsingQueue(animationName:String, count:Int, interval:NSTimeInterval)
  + This function will run queued animation when the specified animation is finished.
  + Interval means the interval between the specified animation end time and the queued animation start time.

- findBone(boneName:String, inBonesArray:Array<YSC_SpineBone>) -> YSC_SpineBone?
  + It finds the bone instance with the given name and returns it.
  + You can use this function when you want to customize your bone. For example, giving it physicsbody.
- ikActionUpdate()
  + It should be in didFinishUpdate() in order to enable ikAction and rotation inheritance option.

ABOUT THE SAMPLE PROGRAM
- It animates hero and alien which I got from the samples in Spine software.
- If you click hero or alien, they will do some action and return to default action.
- hero action has IK action. You can find it work nicely.
- alien "death" action includes slot animation, which was tricky. It work nicely too.
