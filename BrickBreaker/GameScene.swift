import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Define game elements
    var ball: SKSpriteNode!
    var paddle: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var highScoreLabel: SKLabelNode!
    var gameOverLabel: SKLabelNode!
    var tryAgainButton: SKSpriteNode!
    var livesLabel: SKLabelNode!
    var isGameOver = false
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var highScore: Int {
        get {
            UserDefaults.standard.integer(forKey: "highScore")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "highScore")
        }
    }
    
    var initialLives = 3
    var ballFallsCounter = 0 {
        didSet {
            livesLabel.text = "Lives: \(initialLives - ballFallsCounter)"
            if ballFallsCounter >= initialLives {
                gameOver()
            }
        }
    }
    
    let ballCategory: UInt32 = 0x1 << 0
    let brickCategory: UInt32 = 0x1 << 1
    let paddleCategory: UInt32 = 0x1 << 2
    let borderCategory: UInt32 = 0x1 << 3
    
    let maxVelocity: CGFloat = 15.0 // Adjusted for more reasonable gameplay speed
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = SKColor.black
        setupScene()
        setupPhysics()
        createBricks()
        setupLabels()
        resetGame() // Use resetGame to initialize the game elements
    }
    
    func setupScene() {
        setupPaddle()
        setupBall()
    }
    
    func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.categoryBitMask = borderCategory
        self.physicsBody = border
    }
    
    func setupPaddle() {
        paddle = SKSpriteNode(color: .white, size: CGSize(width: 100, height: 20))
        paddle.position = CGPoint(x: frame.midX, y: frame.minY + 100)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.categoryBitMask = paddleCategory
        addChild(paddle)
    }
    
    func setupBall() {
        ball = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 20))
        ball.position = CGPoint(x: frame.midX, y: paddle.position.y + 30)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.friction = 0
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.collisionBitMask = paddleCategory | brickCategory | borderCategory
        ball.physicsBody?.contactTestBitMask = brickCategory | borderCategory
        addChild(ball)
        launchBall()
    }
    
    func createBricks() {
        let padding: CGFloat = 10.0
        let numberOfBricksInRow: Int = 10
        let numberOfRows: Int = 5
        let brickHeight: CGFloat = 15

        // Calculate the width of all bricks including padding
        let totalBricksWidth = frame.width * 0.8 // Use 80% of screen width for bricks
        let brickWidth = (totalBricksWidth - padding * CGFloat(numberOfBricksInRow - 1)) / CGFloat(numberOfBricksInRow)
        
        // Offset to center the bricks horizontally
        let offsetX = (frame.width - totalBricksWidth) / 2

        // Calculating topMargin to place bricks in the top 30% of the screen
        // Assuming the y=0 at the bottom of the screen, adjust if y=0 at the top
        let topMargin = frame.height * 0.7 // Starting from the bottom, leave 70% of the screen height below the bricks

        for row in 0..<numberOfRows {
            for col in 0..<numberOfBricksInRow {
                let brick = SKSpriteNode(color: .red, size: CGSize(width: brickWidth, height: brickHeight))
                
                // Calculate X and Y position for each brick
                let brickXPosition = offsetX + CGFloat(col) * (brickWidth + padding)
                // Adjust Y position to place bricks in the top 30% of the screen
                let brickYPosition = topMargin - CGFloat(row) * (brickHeight + padding)
                
                // Adjust for SpriteKit's coordinate system (origin at center)
                brick.position = CGPoint(x: brickXPosition - frame.width / 2, y: brickYPosition - frame.height / 2)
                
                brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
                brick.physicsBody?.isDynamic = false
                brick.physicsBody?.categoryBitMask = brickCategory
                brick.name = "brick"
                
                addChild(brick)
            }
        }
    }




    // Setup UI Elements
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -self.frame.size.width / 2 + 20, y: self.frame.size.height / 2 - 60)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
    }

    func setupLivesLabel() {
        livesLabel = SKLabelNode(fontNamed: "Arial")
        livesLabel.text = "Lives: \(initialLives)"
        livesLabel.fontSize = 24
        livesLabel.fontColor = .white
        livesLabel.position = CGPoint(x: self.frame.size.width / 2 - 100, y: self.frame.size.height / 2 - 60)
        livesLabel.horizontalAlignmentMode = .right
        addChild(livesLabel)
    }

    func setupHighScoreLabel() {
        highScoreLabel = SKLabelNode(fontNamed: "Arial")
        highScoreLabel.text = "High Score: \(highScore)"
        highScoreLabel.fontSize = 24
        highScoreLabel.fontColor = .yellow
        highScoreLabel.position = CGPoint(x: 0, y: self.frame.size.height / 2 - 30)
        highScoreLabel.horizontalAlignmentMode = .center
        addChild(highScoreLabel)
    }

    // Reset the Ball to Initial Position and Velocity
    func resetBall() {
        ball.position = CGPoint(x: frame.midX, y: paddle.position.y + 30)
        ball.physicsBody?.velocity = .zero
        ball.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -50...50), dy: maxVelocity))
    }

    // Game Over Logic

    func gameOver() {
        if score > highScore {
            highScore = score
            highScoreLabel.text = "High Score: \(highScore)"
        }
    
        isGameOver = true
        showGameOverScreen()
    }

    // Show Game Over UI
    func showGameOverScreen() {
        gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel)

        tryAgainButton = SKSpriteNode(color: .blue, size: CGSize(width: 200, height: 80))
        tryAgainButton.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        tryAgainButton.name = "tryAgainButton"
        let buttonText = SKLabelNode(fontNamed: "Arial")
        buttonText.text = "Try Again"
        buttonText.fontSize = 30
        buttonText.fontColor = .white
        tryAgainButton.addChild(buttonText)
        addChild(tryAgainButton)
    }

    func resetGame() {
        isGameOver = false
        ballFallsCounter = 0
        score = 0
        
        removeAllChildren()
        
        // Re-setup the scene
        setupScene()
        setupPhysics()
        createBricks()
        setupLabels() // This method should setup all labels including the score, lives, and high score
    }



    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)

        // Use 'name' property to detect the "Try Again" button press
        if node.name == "tryAgainButton" {
            resetGame()
        } else {
            // Handle other touches if necessary
        }
    }




    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        paddle.position.x = location.x
    }

    // Physics Contact Delegate Method
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == ballCategory | brickCategory {
            if contact.bodyA.categoryBitMask == brickCategory {
                contact.bodyA.node?.removeFromParent()
            } else if contact.bodyB.categoryBitMask == brickCategory {
                contact.bodyB.node?.removeFromParent()
            }
            score += 1
        }
    }

    // Adjust Ball Velocity Based on Where It Hits the Paddle
    func adjustBallVelocity(_ contact: SKPhysicsContact) {
        guard let ball = contact.bodyA.categoryBitMask == ballCategory ? contact.bodyA.node as? SKSpriteNode : contact.bodyB.node as? SKSpriteNode else { return }
        let hitPoint = contact.contactPoint
        let paddleCenter = paddle.position.x
        let offset = hitPoint.x - paddleCenter
        let maxOffset = paddle.size.width / 2
        let velocityMultiplier = offset / maxOffset
        ball.physicsBody?.velocity.dx += velocityMultiplier * 100 // Adjust this multiplier as needed
    }

    // Update Loop for Checking Game State
    override func update(_ currentTime: TimeInterval) {
        if (!isGameOver && ball.position.y < paddle.position.y - 50) {
            ballFallsCounter += 1
            if ballFallsCounter >= initialLives {
                gameOver()
            } else {
                resetBall()
            }
        }
    }

    func setupLabels() {
        setupScoreLabel()
        setupLivesLabel()
        setupHighScoreLabel()
    }
    
    func launchBall() {
        let dx = CGFloat.random(in: -maxVelocity...maxVelocity)
        let dy = maxVelocity
        ball.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }

    func breakBrick(brick: SKSpriteNode) {
        brick.removeFromParent()
        score += 1
        
        if children.filter({ $0.name == "brick" }).isEmpty {
            // All bricks are broken; player wins
            gameOver()
        }
    }
}
