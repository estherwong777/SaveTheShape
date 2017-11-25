//
//  GameScene.swift
//  SaveTheShape
//
//  Created by Esther Wong on 3/8/2016.
//  Copyright (c) 2016 MYK777. All rights reserved.
//

import SpriteKit
import AVFoundation

enum GameSceneState {
    case Title, Active, GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var circle: SKNode!
    var startingXOfCircle : CGFloat = 0
    var gameState: GameSceneState = .Title
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var scrollSpeed: CGFloat = 100
    let sunsetScrollSpeed: CGFloat = 30
    var blockScrollSpeed: CGFloat = 160
    var startingBlocksScroll: SKNode!
    var myView: SKView?
    var buttonRestart: MSButtonNode!
    var scoreLabel: SKLabelNode!
    var points = 0
    var distancePoints: Double = 0
    var spawnTimer: CFTimeInterval = 0
    var spawnTimerCoin: CFTimeInterval = 0
    var coinLayer: SKNode!
    var sunsetScroll: SKNode!
    var fireballLayer: SKNode!
    var scrollLayer: SKNode!
    var buttonStart: MSButtonNode!
    var highScoreNumber = 0
    var highScoreLabel: SKLabelNode!
    var theLabel: SKLabelNode!
    var saveLabel: SKLabelNode!
    var shapeLabel: SKLabelNode!
    
    
    
    var player: AVAudioPlayer?
    
//    func playSound() {
//        let url = Bundle.main.url(forResource: "gameMusic", withExtension: "mp3")!
//        
//        do {
//            self.player = try AVAudioPlayer(contentsOf: url)
//            guard let player = player else { return }
//            self.player?.volume = 0.5
//            self.player?.prepareToPlay()
//            self.player?.play()
//        } catch let error as NSError {
//            print(error.description)
//        }
//        
//    }
    
    
    
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        circle = self.childNode(withName: "//circle")
        scrollLayer = self.childNode(withName: "scrollLayer")
        startingBlocksScroll = self.childNode(withName: "startingBlocksScroll")
        myView = view
        startingXOfCircle = circle.position.x
        circle.constraints = [SKConstraint.positionX(SKRange(constantValue: 0.0))]
        physicsWorld.contactDelegate = self
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        fireballLayer = self.childNode(withName: "fireballLayer")
        coinLayer = self.childNode(withName: "coinLayer")
        buttonStart = self.childNode(withName: "buttonStart") as! MSButtonNode
        sunsetScroll = self.childNode(withName: "sunsetScroll")
        highScoreLabel = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        theLabel = self.childNode(withName: "the") as! SKLabelNode
        saveLabel = self.childNode(withName: "save") as! SKLabelNode
        shapeLabel = self.childNode(withName: "shape") as! SKLabelNode
        
        
        buttonStart.state = .Active
        
        
        buttonStart.selectedHandler = {
            self.playButtonSFX() {
                self.gameState =  .Active
                self.playSound()
                
            }
        }
        /* Hide restart button */

        buttonRestart.state = .Hidden
        
        buttonRestart.selectedHandler = {
            self.restartGame()
            
        }
        
        let highScoreNumber = UserDefaults().integer(forKey: "highScore")
        highScoreLabel.text = String(highScoreNumber)
    }
    
    
//    func playButtonSFX(completion block: @escaping () -> Void) {
//        let buttonSFX = SKAction.playSoundFileNamed("sfx_button", waitForCompletion: false)
//        self.run(buttonSFX){
//            block()
//        }
//    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did circl pass through the coin? */
        if nodeA.name == "coin" || nodeB.name == "coin" {
            points += 5
            if nodeA.name == "coin" {
                
                nodeA.removeFromParent()
                
            } else {
                nodeB.removeFromParent()
            }
            
//            /* Play goal SFX */
//            let goalSFX = SKAction.playSoundFileNamed("sfx_goal", waitForCompletion: false)
//            self.run(goalSFX)
//            //            let plusFiveScene:SKAction = SKAction.init(named: "plusFive")!
//            
         
            return
            
        } else if nodeA.name == "startingBlocks" || nodeB.name == "startingBlocks" || nodeA.name == "block" || nodeB.name == "block" {
            
            
            return
            
        }  else if nodeA.name == "fireball" || nodeB.name == "fireball" {
            let explodeScene:SKAction = SKAction.init(named: "explode")!
            
            if nodeA.name == "fireball" {
                let explodeSFX = SKAction.playSoundFileNamed("sfx_explode", waitForCompletion: false)
                self.run(explodeSFX)
                nodeA.run(explodeScene) {
                    
                    nodeA.removeFromParent()
                }
                
            } else {
                nodeB.run(explodeScene) {
                    nodeB.removeFromParent()
                }
            }
            
        }
        
        
        
        /* Circle touches anything, game over */
        
        /* Change game state to game over */
        gameState = .GameOver
        /* Stop music */
        player?.stop()
        
        
        let heroDeath = SKAction.run({
            
            /* Stop hero from colliding with anything else */
            self.circle.physicsBody?.collisionBitMask = 0
        })
        
        /* Run action */
        circle.run(heroDeath)
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            
            /* Apply effect each ground node */
            node.run(shakeScene)
        }
        
        /* Show restart button */
        
        buttonRestart.state = .Active
        let highScoreNumber = UserDefaults().integer(forKey: "highScore")
        let totalPoints = self.points + Int(distancePoints)
        if totalPoints > highScoreNumber {
            UserDefaults().set(totalPoints, forKey: "highScore")
            highScoreLabel.text = "\(totalPoints)"
            
        }
    }
    
    
    func updateFireball() {
        /* Update fireballs */
        
        fireballLayer.position.x -= scrollSpeed * CGFloat(fixedDelta) + 2
        
        /* Loop through fireball layer nodes */
        for fireball in fireballLayer.children as! [SKReferenceNode] {
            
            /* Get fireball node position, convert node position to scene space */
            let fireballPosition = fireballLayer.convert(fireball.position, to: self)
            
            /* Check if fireball has left the scene */
            if fireballPosition.x <= -50 {
                
                /* Remove fireball node from obstacle layer */
                fireball.removeFromParent()
            }
            
        }
        
        /* Time to add a new fireball? */
        if spawnTimer >= 4 {
            
            /* Create a new fireball reference object using our fireball resource */
            let resourcePath = Bundle.main.path(forResource: "fireball", ofType: "sks")
            let newFireball = SKReferenceNode (url: NSURL (fileURLWithPath: resourcePath!) as URL)
            fireballLayer.addChild(newFireball)
            
            /* Generate new fireball position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 520, y: CGFloat.random(min: 35, max: 285))
            
            /* Convert new node position back to fireball layer space */
            newFireball.position = self.convert(randomPosition, to: fireballLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
        
        
    }
    
    func updateCoin() {
        /* Update coin */
        
        coinLayer.position.x -= blockScrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through coin layer nodes */
        for coin in coinLayer.children as! [SKReferenceNode] {
            
            /* Get coin node position, convert node position to scene space */
            let coinPosition = coinLayer.convert(coin.position, to: self)
            
            /* Check if coin has left the scene */
            if coinPosition.x <= -200 {
                
                /* Remove coin node from coin layer */
                coin.removeFromParent()
            }
            
        }
        
        /* Time to add a new coin? */
        if spawnTimerCoin >= 3 {
            
            /* Create a new coin reference object using our coin resource */
            let resourcePath = Bundle.main.path(forResource: "coin", ofType: "sks")
            let newCoin = SKReferenceNode (url: NSURL (fileURLWithPath: resourcePath!) as URL)
            coinLayer.addChild(newCoin)
            
            /* Generate new coin position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 520, y: CGFloat.random(min: 40, max: 275))
            /* Convert new node position back to coin layer space */
            newCoin.position = self.convert(randomPosition, to: coinLayer)
            
            // Reset spawn timer
            spawnTimerCoin = 0
        }
        
        
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Creates a line of blocks */
        if let touch = touches.first {
            addBlock(blockPosition: touch.location(in: startingBlocksScroll))
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Creates one block at touch position */
        if let touch = touches.first {
            addBlock(blockPosition: touch.location(in: startingBlocksScroll))
            
        }
    }
    
    func addBlock(blockPosition: CGPoint) {
        
        let resourcePath = Bundle.main.path(forResource: "block", ofType: "sks")
        let newObstacle = SKReferenceNode (url: NSURL (fileURLWithPath: resourcePath!) as URL)
        startingBlocksScroll.addChild(newObstacle)
        
        /* Convert new node position back to obstacle layer space */
        newObstacle.position = blockPosition
        
    }
    
    
    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if gameState == .Active {
            spawnTimer += fixedDelta
            spawnTimerCoin += fixedDelta
            distancePoints += 0.1
            scoreLabel.text = String(Int(distancePoints) + points)
            scrollWorld()
            sunsetScroller()
            scrollSpeed += 0.09
            updateStartingBlocks()
            updateFireball()
            updateCoin()
            circle.physicsBody?.velocity.dx = scrollSpeed * CGFloat(fixedDelta)
            buttonStart.state = .Hidden
            buttonRestart.state = .Hidden
            
            if theLabel.alpha > 0 {
                /* fading out title */
                theLabel.alpha -= 0.01
                saveLabel.alpha -= 0.01
                shapeLabel.alpha -= 0.01
            }
        }
    }
    
    func scrollWorld() {
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            /* Get ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (groundPosition.x + ground.size.width * 2), y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func sunsetScroller() {
        
        sunsetScroll.position.x -= CGFloat(fixedDelta) * sunsetScrollSpeed
        
        for sunset in sunsetScroll.children as! [SKSpriteNode] {
            let sunsetPosition = sunsetScroll.convert(sunset.position, to: self)
            
            if sunsetPosition.x <= -sunset.size.width / 2 {
                let newPosition = CGPoint(x: (sunsetPosition.x + sunset.size.width * 2), y: sunsetPosition.y)
                
                sunset.position = self.convert(newPosition, to: sunsetScroll)
            }
        }
    }
    

    
    func updateStartingBlocks() {
        /* Update Obstacles */
        
        startingBlocksScroll.position.x -= blockScrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for blocks in startingBlocksScroll.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let blocksPosition = startingBlocksScroll.convert(blocks.position, to: self)
            
            /* Check if obstacle has left the scene */
            if blocksPosition.x <= -500 {
                
                /* Remove obstacle node from obstacle layer */
                blocks.removeFromParent()
                
            }
        }
    }
    
    func restartGame() {
        
        
        let skView = self.view as SKView!
        
        /* Load Game scene */
        let scene = GameScene(fileNamed:"GameScene") as GameScene!
        
        /* Ensure correct aspect mode */
        scene?.scaleMode = .aspectFill
        
        /* Restart game scene */
        skView?.presentScene(scene)
        
        scene?.gameState = .Active
        scene?.playButtonSFX() {
            scene?.playSound()
        }
        
        scene?.theLabel.alpha = 0
        scene?.saveLabel.alpha = 0
        scene?.shapeLabel.alpha = 0
    }
    
    
    
}
