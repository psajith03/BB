import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var ball: SKSpriteNode!
    var paddle: SKSpriteNode!
    var background: SKSpriteNode!
    
    var gameOverLabel: SKLabelNode!
    var tryAgainButton: SKSpriteNode!


    var livesLabel: SKLabelNode!
    let initialLives = 3
    var ballFallsCounter = 0 {
        didSet {
            livesLabel.text = "Lives: \(initialLives - ballFallsCounter)"
        }
    }
    let ballCategory: UInt32 = 0x1 << 0
    let brickCategory: UInt32 = 0x1 << 1
    let paddleCategory: UInt32 = 0x1 << 2
    let borderCategory: UInt32 = 0x1 << 3

    let maxVelocity: CGFloat = 1200.0

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupScene()
        setupPhysics()
        createBricks()
        setupLivesLabel()
    }
    
    func setupLivesLabel() {
        livesLabel = SKLabelNode(fontNamed: "Arial")
        livesLabel.fontSize = 24
        livesLabel.fontColor = SKColor.white
        livesLabel.position = CGPoint(x: self.frame.minX + 70, y: self.frame.maxY - 50)
        livesLabel.text = "Lives: \(initialLives)"
        livesLabel.horizontalAlignmentMode = .left
        addChild(livesLabel)
    }

    func setupScene() {
        background = SKSpriteNode(color: .black, size: self.size)
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(background)

        paddle = SKSpriteNode(color: .white, size: CGSize(width: 100, height: 20))
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + 100)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = paddleCategory
        addChild(paddle)

        ball = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 20))
        ball.position = CGPoint(x: frame.midX, y: paddle.position.y + 50)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.friction = 0
        ball.physicsBody?.restitution = 1 // Perfectly elastic collision
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = paddleCategory | brickCategory
        ball.physicsBody?.collisionBitMask = borderCategory | paddleCategory | brickCategory
        ball.physicsBody?.velocity = CGVector(dx: maxVelocity / sqrt(2), dy: maxVelocity / sqrt(2))
        addChild(ball)
    }

    func setupPhysics() {
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 1
        border.categoryBitMask = borderCategory
        self.physicsBody = border
    }

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

        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == brickCategory {
            if let brickNode = secondBody.node as? SKSpriteNode {
                breakBrick(brick: brickNode)
            }
        } else if firstBody.categoryBitMask == brickCategory && secondBody.categoryBitMask == ballCategory {
            if let brickNode = firstBody.node as? SKSpriteNode {
                breakBrick(brick: brickNode)
            }
        }
    }

    func breakBrick(brick: SKSpriteNode) {
        brick.removeFromParent()
    }


    func adjustBallVelocity(ball: SKSpriteNode, paddle: SKSpriteNode) {
        let contactPoint = ball.position.x - paddle.position.x
        let normalizedContactPoint = contactPoint / (paddle.size.width / 2)

        if abs(normalizedContactPoint) > 0.8 {
            let direction: CGFloat = normalizedContactPoint > 0 ? 1 : -1
            let dx = maxVelocity / sqrt(2) * direction
            let dy = maxVelocity / sqrt(2)
            ball.physicsBody?.velocity = CGVector(dx: dx, dy: dy)
        } else {
            let currentSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
            if currentSpeed != maxVelocity {
                let multiplier = maxVelocity / currentSpeed
                ball.physicsBody?.velocity.dx *= multiplier
                ball.physicsBody?.velocity.dy *= multiplier
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            paddle.position.x = touchLocation.x
        }
    }
    
    func createBricks() {
        let brickWidth = CGFloat(30)
        let brickHeight = CGFloat(30)
        let numBricksPerRow = Int(20)
        let totalRows = 5
        let yOffset = frame.height - brickHeight - 900

        for row in 0..<totalRows {
            for col in 0..<numBricksPerRow {
                let brick = SKSpriteNode(color: .yellow, size: CGSize(width: brickWidth, height: brickHeight))
                let xPos = (CGFloat(col) * brickWidth + brickWidth / 2) - 300
                let yPos = yOffset - CGFloat(row) * brickHeight
                brick.position = CGPoint(x: xPos, y: yPos)
                brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
                brick.physicsBody?.isDynamic = false
                brick.physicsBody?.categoryBitMask = brickCategory
                brick.physicsBody?.collisionBitMask = 0
                brick.name = "brick"
                brick.zPosition = 1
                addChild(brick)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if ball.position.y < paddle.position.y - 50 {
            ballFallsCounter += 1
            resetBall()
            if ballFallsCounter >= initialLives {
                gameOver()
            }
        }
    }

        func resetBall() {
            ball.position = CGPoint(x: paddle.position.x, y: paddle.position.y + 50)
            ball.physicsBody?.velocity = CGVector(dx: 0, dy: maxVelocity / sqrt(2))
        }

    func gameOver() {
        showGameOverScreen()
    }


    func showGameOverScreen() {
        backgroundColor = .black
        
        gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY + 20)
        addChild(gameOverLabel)
        
        tryAgainButton = SKSpriteNode(color: .green, size: CGSize(width: 200, height: 60))
        tryAgainButton.position = CGPoint(x: frame.midX, y: frame.midY - 40)
        tryAgainButton.name = "tryAgainButton"
        let buttonText = SKLabelNode(fontNamed: "Arial")
        buttonText.text = "Try Again"
        buttonText.fontSize = 30
        buttonText.fontColor = .white
        buttonText.position = CGPoint.zero
        tryAgainButton.addChild(buttonText)
        addChild(tryAgainButton)
        
        ball.removeFromParent()
    }

    func resetGame() {
        ballFallsCounter = 0
        removeAllChildren()
        setupScene()
        setupPhysics()
        createBricks()
        setupLivesLabel()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        if nodesAtLocation.contains(where: { $0.name == "tryAgainButton" }) {
            resetGame()
        }
    }

}

