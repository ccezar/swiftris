//
//  GameViewController.swift
//  Swiftris
//
//  Created by Stanley Idesis on 7/14/14.
//  Copyright (c) 2014 Bloc. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate {

    var scene: GameScene!
    var swiftris: Swiftris!
    var panPointReference: CGPoint?
    
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var levelLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.isMultipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        scene.tick = didTick
        scene.elevate = doElevation
        
        swiftris = Swiftris()
        swiftris.delegate = self
        swiftris.beginGame()
        
        // Present the scene.
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        swiftris.rotateShape()
    }
    
    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translation(in: self.view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocity(in: self.view).x > CGFloat(0) {
                    swiftris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    swiftris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(_ sender: UISwipeGestureRecognizer) {
        swiftris.dropShape()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
    
    func didTick() {
        swiftris.letShapeFall()
    }
    
    func doElevation() {
        if swiftris.elevateBlocks() == true {
            scene.elevateLines(blockArray: swiftris.blockArray)
            
            let shape = swiftris.newFullLine()
            scene.addNewLineBottom(shape) {
                
                var conectedBlocks = self.removeConectedBlocks()
                
                while conectedBlocks.count > 0 {
                    let fallenBlocks = self.swiftris.removeSpecificBlocks(listOfBlocks: conectedBlocks)
                    self.scene.animateCollapsingLines(conectedBlocks, fallenBlocks: fallenBlocks) { }
                    conectedBlocks = self.removeConectedBlocks()
                }                
            }
        }
    }
    
    func removeConectedBlocks() -> [[Block]] {
        var conectedBlocks = [[Block]]()
        
        for row in (0..<NumRows).reversed() {
            for column in (0..<NumColumns).reversed() {
                if let _ = self.swiftris.blockArray[column, row] {
                    self.swiftris.setConectedBlocksFrom(block: self.swiftris.blockArray[column, row]!)
                    
                    if let blocks = self.swiftris.getConectedBlocks() {
                        
                        var existingBlocks = false
                        for item in conectedBlocks {
                            if item.elementsEqual(blocks) {
                                existingBlocks = true
                            }
                        }
                        
                        if existingBlocks == false {
                            conectedBlocks.append(blocks)
                        }
                    }
                    
                    self.swiftris.dismarkAllBlocks()
                }
            }
        }
        
        return conectedBlocks
    }
    
    func nextShape() {
        let newShapes = swiftris.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        
        self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
        self.scene.movePreviewShape(fallingShape) {
            self.view.isUserInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    func gameDidBegin(_ swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        scoreLabel.text = "\(swiftris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        scene.elevationLengthMillis = ElevationLengthLevelOne
        
//        // The following is false when restarting a new game
//        if swiftris.nextShape != nil && swiftris.nextShape!.blocks[0].sprite == nil {
//            scene.addPreviewShapeToScene(swiftris.nextShape!) {
//                self.nextShape()
//            }
//        } else {
//            nextShape()
//        }
        
        scene.startElevating()
    }
    
    func gameDidEnd(_ swiftris: Swiftris) {
        view.isUserInteractionEnabled = false
        scene.stopTicking()
        scene.stopElevating()
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(swiftris.removeAllBlocks(), fallenBlocks: swiftris.removeAllBlocks()) {
            swiftris.beginGame()
        }
    }
    
    func gameDidLevelUp(_ swiftris: Swiftris) {
        levelLabel.text = "\(swiftris.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        
        if scene.elevationLengthMillis >= 700 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 300 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(_ swiftris: Swiftris) {
        scene.stopTicking()
        scene.stopElevating()
        scene.redrawShape(swiftris.fallingShape!) {
            swiftris.letShapeFall()
        }
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(_ swiftris: Swiftris) {
        scene.stopTicking()
        scene.stopElevating()
        self.view.isUserInteractionEnabled = false
        let removedLines = swiftris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(swiftris.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                self.gameShapeDidLand(swiftris)
            }
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(_ swiftris: Swiftris) {
        scene.redrawShape(swiftris.fallingShape!) {}
    }
}
