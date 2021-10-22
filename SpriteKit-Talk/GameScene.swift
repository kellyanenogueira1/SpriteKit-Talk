//
//  GameScene.swift
//  SpriteKit-Talk
//
//  Created by Kellyane Nogueira on 21/10/21.
//

import SpriteKit

class GameScene: SKScene {
    
    struct PhysicsCategory {
      static let none      : UInt32 = 0
      static let all       : UInt32 = UInt32.max
      static let emoji   : UInt32 = 0b1
      static let projectile: UInt32 = 0b10
    }
    let player = SKSpriteNode(imageNamed: "anjo")
    var monstersDestroyed = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.white //Modificar
        addPlayer(position: CGPoint(x: size.width * 0.1, y: size.height * 0.5))
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        addEmojisEveryTime()
        
    }
    
    func addPlayer(position: CGPoint) {
        player.position = position
        addChild(player)
    }
    
    func addEmojisEveryTime() {
        run(SKAction.repeatForever(
          SKAction.sequence([
            SKAction.run(addEmoji),
            SKAction.wait(forDuration: 1.0)
            ])
        ))
    }
    
    func random() -> CGFloat {
      return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
      return random() * (max - min) + min
    }
    
    func addEmoji() {
        let emoji = SKSpriteNode(imageNamed: "emojiBad")
        
        emoji.physicsBody = SKPhysicsBody(rectangleOf: emoji.size)
        emoji.physicsBody?.isDynamic = true // 2
        emoji.physicsBody?.categoryBitMask = PhysicsCategory.emoji
        emoji.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        emoji.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        movimentEmoji(emoji)
        
        addChild(emoji)
    }
    
    func movimentEmoji(_ emoji: SKSpriteNode) {
        let actualY = random(min: emoji.size.height/2, max: size.height - emoji.size.height/2)
        emoji.position = CGPoint(x: size.width + emoji.size.width/2, y: actualY)
        
        // Speed
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: -emoji.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        let loseAction = SKAction.run() { [weak self] in
          guard let `self` = self else { return }
          let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
          let gameOverScene = GameOverScene(size: self.size, won: false)
          self.view?.presentScene(gameOverScene, transition: reveal)
        }
        emoji.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let arrow = SKSpriteNode(imageNamed: "Flecha")
        arrow.position = player.position
        
        arrow.physicsBody = SKPhysicsBody(circleOfRadius: arrow.size.width/2)
        arrow.physicsBody?.isDynamic = true
        arrow.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        arrow.physicsBody?.contactTestBitMask = PhysicsCategory.emoji
        arrow.physicsBody?.collisionBitMask = PhysicsCategory.none
        arrow.physicsBody?.usesPreciseCollisionDetection = true
        
        let offset = touchLocation - arrow.position
        if offset.x < 0 { return }
        addChild(arrow)
        
        let direction = offset.normalized()
        let shootAmount = direction * 1000
        let realDest = shootAmount + arrow.position
      
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        arrow.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed += 1
        if monstersDestroyed > 30 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
      var firstBody: SKPhysicsBody
      var secondBody: SKPhysicsBody
      if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
        firstBody = contact.bodyA
        secondBody = contact.bodyB
      } else {
        firstBody = contact.bodyB
        secondBody = contact.bodyA
      }
      
      if ((firstBody.categoryBitMask & PhysicsCategory.emoji != 0) &&
        (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
        if let emoji = firstBody.node as? SKSpriteNode,
          let arrow = secondBody.node as? SKSpriteNode {
          projectileDidCollideWithMonster(projectile: arrow, monster: emoji)
        }
      }
    }
}
