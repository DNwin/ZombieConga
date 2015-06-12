//
//  GameScene.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/5/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "GameScene.h"
#import "MyUtils.h"
#import "GameOverScene.h"


static const CGFloat ZOMBIE_ROTATE_RADIANS_PER_SEC = 4.0 * M_PI;
#define DEFAULT_MOVE_POINTS_VALUE 480.0
static const CGFloat CAT_MOVE_POINTS_PER_SEC = DEFAULT_MOVE_POINTS_VALUE;
#define BACKGROUND_MOVE_POINTS_PER_SEC 200.0;

@interface GameScene()

@property (strong, nonatomic) AVAudioPlayer *backgroundMusicPlayer;
@property (strong, nonatomic) SKSpriteNode *zombieNode; // zombie node;
@property (strong, nonatomic) SKSpriteNode *backgroundLayer; // Layer containing sprites

@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic) NSTimeInterval dt; // Time per frame in ms
@property (nonatomic) CGFloat zombieMovePointsPerSec; // Desired pixels/sec
@property (nonatomic) CGFloat backgroundMovePointsPerSec; // Pixels/sec background
@property (nonatomic) CGPoint velocity; // Current velocity of the zombie
@property (nonatomic) CGRect playableRect; // Playable rectangle in terms of larger scene
@property (nonatomic) CGPoint lastTouchLocation; // Last location touched

@property (strong, nonatomic) SKAction *zombieAnimation; // Animation action
@property (strong, nonatomic) SKAction *catCollisionSound; // Sound of cat
@property (strong, nonatomic) SKAction *enemyCollisionSound; // Sound of enemy
@property (nonatomic, getter=isZombieInvincible) BOOL zombieInvincible;
@property (nonatomic) NSUInteger lives; // Player number of lives
@property (nonatomic, getter=isGameOver) BOOL gameOver;

@end;


@implementation GameScene


#pragma mark - Lifecycle

// Designated init
- (instancetype) initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        _zombieNode = [[SKSpriteNode alloc] initWithImageNamed:@"zombie1"];
        _backgroundLayer = [[SKSpriteNode alloc] init];
        
        _lastUpdateTime = 0;
        _dt = 0;
        _velocity = CGPointZero;
        _lastTouchLocation = CGPointZero;
        
        // playableRect
        CGFloat maxAspectRatio = 16.0/9.0;
        CGFloat playableHeight = self.size.width / maxAspectRatio;
        // Size of top and bottom margins
        CGFloat playableMargin = (self.size.height - playableHeight)/2.0;
        self.playableRect = CGRectMake(0, playableMargin,
                                       self.size.width, playableHeight);
        // zombieAnimation
        NSMutableArray *textures = [[NSMutableArray alloc] init];
        // Add zombie1..4 to array, then 3, 2 (Frames: 1,2,3,4,3,2)
        for (int i = 1; i <= 4; i++) {
            NSString *textureName = [[NSString alloc] initWithFormat:@"zombie%i",i];
            [textures addObject: [SKTexture textureWithImageNamed:textureName]];
        }
        [textures addObject:textures[2]];
        [textures addObject:textures[1]];
        _zombieAnimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
        
        // Sounds
        _catCollisionSound = [SKAction playSoundFileNamed:@"hitCat.wav" waitForCompletion:YES];
        _enemyCollisionSound = [SKAction playSoundFileNamed:@"hitCatLady.wav" waitForCompletion:YES];
        
        _zombieInvincible = NO;
        _lives = 5;
        _gameOver = NO;
    }
    return self;
}

// Did not use scene editor so this init is not required
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    @throw [NSException exceptionWithName:@"Wrong initiazlier"
                                   reason:@"initWithCoder has not been implemented"
                                 userInfo:nil];
}

- (void) didMoveToView:(SKView *)view {
    self.backgroundLayer.zPosition = -1;
    [self addChild:self.backgroundLayer];
    
    self.backgroundColor = [SKColor whiteColor];
    
    // Place two background nodes side by side;
    for (int i = 0; i <= 1; i++) {
        SKSpriteNode *background = [self backgroundNode];
        background.anchorPoint = CGPointZero;
        background.position = CGPointMake(background.size.width * (CGFloat)i, 0);
        background.name = @"background";
        [self.backgroundLayer addChild:background];
    }
    
    [self playBackgroundMusicWithFilname:@"backgroundMusic.mp3"];
    // DEBUG ** draws red rectangle around playable area
    [self debugDrawPlayableArea];

    // Setup and add zombie node
    self.zombieNode.zPosition = 100; // Zombie on top
    self.zombieNode.position = CGPointMake(400.0, 400.0);
    [self.backgroundLayer addChild:self.zombieNode];
    // [self.zombieNode runAction:[SKAction repeatActionForever:self.zombieAnimation]];
    
    // Run spawnenemy infinitely
    SKAction *sequence = [SKAction sequence:@[[SKAction performSelector:@selector(spawnEnemy) onTarget:self],
                                              [SKAction waitForDuration:4.0]]];
    [self runAction:[SKAction repeatActionForever:sequence]];
    
    // Spawn cats infinitely
    [self runAction:[SKAction repeatActionForever:
                     [SKAction sequence:@[[SKAction performSelector:@selector(spawnCat) onTarget:self],
                                          [SKAction waitForDuration:1.0]]]]];
}

- (void)update:(NSTimeInterval)currentTime {
    // Calculate the amount of time it takes per frame in ms (dt)
    if (self.lastUpdateTime > 0) {
        self.dt = currentTime - self.lastUpdateTime;
    } else {
        self.dt = 0;
    }
    self.lastUpdateTime = currentTime;
    // NSLog(@"%f milliseconds since last update", self.dt * 1000);
    
    [self moveSprite:self.zombieNode withVelocity:self.velocity];
    [self boundsCheckZombie];
    [self rotateSprite:self.zombieNode toFace:self.velocity rotationSpeed:ZOMBIE_ROTATE_RADIANS_PER_SEC];
    
    // Since background is scrolling, no need to stop movement animation
    // [self distanceBetweenTouchCheckZombie];
    
    [self moveTrain]; // Checks for train cats and follows
    
    // Check for lose condition
    if (self.lives <= 0 && !self.isGameOver) {
        self.gameOver = true;
        NSLog(@"You lose");
        [self presentGameOverScreenDidWin:NO];
    }
    
    // Background
    [self moveBackground];
}

// Executed after SKScene evals actions after update:
- (void)didEvaluateActions {
    [self checkCollisions];
}

#pragma mark - Custom Accessors


- (CGFloat)zombieMovePointsPerSec {
    if (!_zombieMovePointsPerSec) {
        _zombieMovePointsPerSec = DEFAULT_MOVE_POINTS_VALUE;
    }
    return _zombieMovePointsPerSec;
}

- (CGFloat)backgroundMovePointsPerSec {
    if (!_backgroundMovePointsPerSec) {
        _backgroundMovePointsPerSec = BACKGROUND_MOVE_POINTS_PER_SEC;
    }
    return _backgroundMovePointsPerSec;
}

// Returns a background consisting of multiple backgrounds

- (SKSpriteNode *)backgroundNode {
    SKSpriteNode *bn = [[SKSpriteNode alloc] init];
    
    // Make two backgrounds
    SKSpriteNode *background1 = [[SKSpriteNode alloc]
                                 initWithImageNamed:@"background1"];
    background1.anchorPoint = CGPointZero;
    background1.position = CGPointMake(0, 0);
    [bn addChild:background1];
    
    SKSpriteNode *background2 = [[SKSpriteNode alloc]
                                 initWithImageNamed:@"background2"];
    background2.anchorPoint = CGPointZero;
    background1.position = CGPointMake(self.size.width, 0);
    [bn addChild:background2];
    // Adjust size of bn to be 2x a reg node
    bn.size = CGSizeMake(background1.size.width +
                         background2.size.width, background1.size.height);
    
    return bn;
}
#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.backgroundLayer];
    [self sceneTouched:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.backgroundLayer];
    [self sceneTouched:touchLocation];
}

#pragma mark - Sprites and movement

// Spawns an enemy at random location and moves it across the screen
- (void)spawnEnemy {
    SKSpriteNode *enemy = [[SKSpriteNode alloc] initWithImageNamed:@"enemy"];
    enemy.name = @"enemy";
    // Randomly position y
    CGFloat randomFloatY = CGFloatRandomRange(CGRectGetMinY(self.playableRect) + enemy.size.height/2,
                                              CGRectGetMaxY(self.playableRect) - enemy.size.height/2);
    // Set enemy position in terms of bg layer
    CGPoint scenePos = CGPointMake(self.size.width + enemy.size.width/2, randomFloatY);
    enemy.position = [self.backgroundLayer convertPoint:scenePos fromNode:self];
    
    [self.backgroundLayer addChild:enemy];
    SKAction *actionMove = [SKAction moveByX:-self.size.width-enemy.size.width y:0 duration:2.0];
    // Remove node
    SKAction *actionRemove = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[actionMove, actionRemove]]];
    
}

// moveSprite: - Changes the current position of a sprite with a velocity vector-
- (void)moveSprite:(SKSpriteNode *)sprite withVelocity:(CGPoint)velocity {
    
    // Multiply intended velocity by time per frame to get distance
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.dt);
    
    //NSLog(@"Amount to move: %f", hypot(amountToMove.x, amountToMove.y));
    
    // Update position of sprite
    sprite.position = CGPointAdd(sprite.position, amountToMove);
}

// moveZombieTowards: - Takes in a location and sets the velocity property
- (void)moveZombieToward:(CGPoint)location {
    
    // Start animation
    [self startZombieAnimation];
    
    self.lastTouchLocation = location;
    
    CGPoint offsetVector = CGPointMake(location.x - self.zombieNode.position.x,
                                       location.y - self.zombieNode.position.y);
    // Get length of offset vector
    CGFloat offsetLength = hypot(offsetVector.x, offsetVector.y);
    // Convert offset vector to unit vector that points towards location
    CGPoint unitVector = CGPointMake(offsetVector.x/offsetLength,
                                     offsetVector.y/offsetLength);
    // Mult unit vector by default velocity value, set the velocity property
    self.velocity = CGPointMake(unitVector.x * self.zombieMovePointsPerSec,
                                unitVector.y * self.zombieMovePointsPerSec);
}

- (void)startZombieAnimation {
    if ([self.zombieNode actionForKey:@"animation"] == nil) {
        [self.zombieNode runAction:[SKAction repeatActionForever:self.zombieAnimation]
                           withKey:@"animation"];
         }
}

// Stop infinite animation loop by removing key
- (void)stopZombieAnimation {
    [self.zombieNode removeActionForKey:@"animation"];
}

- (void)spawnCat {
    SKSpriteNode *cat = [[SKSpriteNode alloc] initWithImageNamed:@"cat"];
    cat.name = @"cat";
    CGPoint scenePoint = CGPointMake(CGFloatRandomRange(CGRectGetMinX(self.playableRect),
                                                        CGRectGetMaxX(self.playableRect)),
                                     CGFloatRandomRange(CGRectGetMinY(self.playableRect),
                                                        CGRectGetMaxY(self.playableRect)));
    // Set position in terms of background layer
    cat.position = [self.backgroundLayer convertPoint:scenePoint fromNode:self];
    [cat setScale:0]; // Basically invisible
    [self.backgroundLayer addChild:cat];
    
    // Show cat
    SKAction *appear = [SKAction scaleTo:1.0 duration:0.5];
    
    // Cat wiggle for 10 seconds (0.5s / wiggle * 10)
    cat.zRotation = -M_PI / 16.0;
    SKAction *leftWiggle = [SKAction rotateByAngle:M_PI / 8 duration:0.5];
    SKAction *rightWiggle = [leftWiggle reversedAction];
    SKAction *fullWiggle = [SKAction sequence:@[leftWiggle, rightWiggle]]; // 1s

    // Slight scaling with siggle
    SKAction *scaleUp = [SKAction scaleBy:1.2 duration:0.25];
    SKAction *scaleDown = [scaleUp reversedAction];
    SKAction *fullScale = [SKAction sequence:
                           @[scaleUp, scaleDown, scaleUp, scaleDown]];
    
    SKAction *group = [SKAction group:@[fullWiggle, fullScale]]; // 1s
    SKAction *groupWait = [SKAction repeatAction:group count:10]; // 10s
    SKAction *dissapear = [SKAction scaleTo:0 duration:0.5]; // Hide after 10 seconds
    SKAction *removeFromParent = [SKAction removeFromParent]; // Rem node
    
    NSArray *actions = @[appear, groupWait, dissapear, removeFromParent];
    [cat runAction:[SKAction sequence:actions]];
}

// Moves the background layer continuously to the left every update:
- (void)moveBackground {
    // Move the background layer instead of individual sprites
    CGPoint backgroundVelocity =
        CGPointMake(-self.backgroundMovePointsPerSec, 0);
    CGPoint amountToMove = CGPointMultiplyScalar(backgroundVelocity, self.dt);
    self.backgroundLayer.position =
        CGPointAdd(self.backgroundLayer.position, amountToMove);
    
    //NSLog(@"%f", self.backgroundLayer.position.x);
    
    [self.backgroundLayer enumerateChildNodesWithName:@"background"
                                           usingBlock:^(SKNode *node, BOOL *stop)
    {
        SKSpriteNode *background = (SKSpriteNode *)node;
        // If a background moves off screen to left,
        // Move it to the right of the 2nd background
        CGPoint backgroundScreenPos = [self.backgroundLayer convertPoint:background.position toNode:self];
        if (backgroundScreenPos.x <= -background.size.width) {
            // Current position should be negative width
            background.position =
                CGPointMake(background.position.x + background.size.width * 2,
                                              background.position.y);
        }
    }];
}


#pragma mark Collision


// Check distance between last touch and position and stop moving when close
- (void)distanceBetweenTouchCheckZombie {
    CGPoint offset = CGPointSubtract(self.zombieNode.position, self.lastTouchLocation);
    if (CGPointLength(offset) <= self.zombieMovePointsPerSec*self.dt) {
        self.velocity = CGPointZero;
        // Stop animation
        [self stopZombieAnimation];
    }
}

// Enumerates through enemy/cat nodes for collision with zombie
- (void)checkCollisions {
    NSMutableArray *hitCats = [[NSMutableArray alloc] init];
    
    // Go through all cats and check intersection, add the cat to array
    [self.backgroundLayer enumerateChildNodesWithName:@"cat"
                           usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *cat = (SKSpriteNode *)node;
        if (CGRectIntersectsRect(cat.frame, self.zombieNode.frame)) {
            [hitCats addObject: cat];
        }
    }];
    
    for (SKSpriteNode *cat in hitCats) {
        [self zombieHitCat:cat];
    }
    
    // Do same for enemy collision
    if (!self.isZombieInvincible) {
        NSMutableArray *hitEnemies = [[NSMutableArray alloc] init];
        [self.backgroundLayer enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop) {
            SKSpriteNode *enemy = (SKSpriteNode *)node;
            if (CGRectIntersectsRect(CGRectInset(node.frame, 20, 20), self.zombieNode.frame)) {
            [hitEnemies addObject:enemy];
            }
        }];
    
        for (SKSpriteNode *enemy in hitEnemies) {
            [self zombieHitEnemy:enemy];
        }
    }
}

// Remove specific cat node from parent
- (void)zombieHitCat:(SKSpriteNode *)cat {
    [self runAction:self.catCollisionSound];
    // Make cat follow
    cat.name = @"train";
    // Remove wiggle and make cat normal
    [cat removeAllActions];
    cat.zRotation = 0;
    [cat setScale: 1];
    // turn cat Green
    SKAction *turnGreen = [SKAction colorizeWithColor:[UIColor greenColor] colorBlendFactor:1.0 duration:0.2];
    [cat runAction:turnGreen];
}

// Runs every update: to make cat follow the zombie
- (void)moveTrain {
    __block CGPoint targetPosition = self.zombieNode.position;
    __block NSUInteger trainCount = 0;
    [self.backgroundLayer enumerateChildNodesWithName:@"train"
                           usingBlock:^(SKNode *node, BOOL *stop) {
                               trainCount++;
                               if (![node hasActions]) {
                                   // Follow zombie over 0.3 s
                                   CGFloat actionDuration = 0.3;
                                   CGPoint offset = CGPointSubtract(targetPosition, node.position);
                                   CGPoint direction = CGPointNormalize(offset);
                                   CGPoint amountToMovePerSec = CGPointMultiplyScalar(direction, CAT_MOVE_POINTS_PER_SEC);
                                   CGPoint amountToMove = CGPointMultiplyScalar(amountToMovePerSec, actionDuration);
                                   SKAction *moveAction = [SKAction moveByX:amountToMove.x
                                                   y:amountToMove.y duration:actionDuration];
                                   [node runAction:moveAction];
                               }
        // Make new target position the latest cat added
        // Make latest node follow last node
        targetPosition = node.position;
                               
        // Check for win condition;
        if (trainCount >= 30 && !self.isGameOver) {
            self.gameOver = true;
            NSLog(@"You win");
            [self presentGameOverScreenDidWin:YES];
        }
    }];
}
// Remove current enemy from node
- (void)zombieHitEnemy:(SKSpriteNode *)enemy {
    [self runAction:self.enemyCollisionSound];
    // Lose 2 cats and a life
    [self loseCats];
    self.lives--;
    // Blink zombie after hit using hidden property
    self.zombieInvincible = YES;
    CGFloat duration = 3.0;
    CGFloat blinkTimes = 10.0;
    SKAction *blinkAction = [SKAction customActionWithDuration:duration actionBlock:^(SKNode *node, CGFloat elapsedTime) {
        CGFloat slice = duration / blinkTimes;
        CGFloat remainder = fmod(elapsedTime, slice);
        node.hidden = remainder > slice / 2;
    }];
    
    SKAction *sequence = [SKAction sequence:@[blinkAction, [SKAction runBlock:^{
        self.zombieNode.hidden = NO;
        self.zombieInvincible = NO;
        
    }]]];
    [self.zombieNode runAction:sequence];
}

// If zombie is hit, remove first two cats
- (void)loseCats {
    __block NSUInteger loseCount = 0;
    [self.backgroundLayer enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop) {
        CGPoint randomSpot = node.position;
        randomSpot.x += CGFloatRandomRange(-100.0, 100.0);
        randomSpot.y += CGFloatRandomRange(-100.0, 100.0);
        
        node.name = @"";
        // Rotate, move to random spot, scale to dissapear
        SKAction *group = [SKAction group:@[[SKAction rotateByAngle:M_PI*4 duration:1.0], [SKAction moveTo:randomSpot duration:1.0], [SKAction scaleTo:0 duration:1.0]]];
        [node runAction:[SKAction sequence:@[group, [SKAction removeFromParent]]]];
        loseCount++;
        
        if (loseCount >= 2) {
            *stop = YES;
        }
    }];
}

#pragma mark Private

// custom initializer for music player
- (void)playBackgroundMusicWithFilname:(NSString *)filename {
    NSURL *url = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
    if (url == nil) {
        NSLog(@"Could not find file");
        return;
    }
    
    NSError *error = [[NSError alloc] init];
    self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (self.backgroundMusicPlayer == nil) {
        NSLog(@"Could not create music player: %@", error);
        return;
    }
    
    self.backgroundMusicPlayer.numberOfLoops = -1;
    [self.backgroundMusicPlayer prepareToPlay];
    [self.backgroundMusicPlayer play];
    
}
- (void)debugDrawPlayableArea {
    SKShapeNode *shape = [[SKShapeNode alloc] init];
    // Configure path
    CGMutablePathRef path = CGPathCreateMutable();;
    CGPathAddRect(path, nil, self.playableRect);
    // Configure shape
    shape.path = path;
    shape.strokeColor = [SKColor redColor];
    shape.lineWidth = 4.0;
    [self addChild:shape];
}

// Checks the current position of zombie, reverses velocity if out of bounds
- (void)boundsCheckZombie {
    // Get points of playablerect in terms of backgroundLayer
    // Points should be increasing as background moves left
    CGPoint bottomLeft = [self.backgroundLayer
                          convertPoint:CGPointMake(0, CGRectGetMinY(self.playableRect))
                          fromNode:self];
    CGPoint topRight = [self.backgroundLayer
                        convertPoint:CGPointMake(CGRectGetWidth(self.playableRect),
                                                 CGRectGetMaxY(self.playableRect))
                        fromNode:self];
    
    CGPoint newPosition = self.zombieNode.position;
    CGPoint newVelocity = self.velocity;
    
    // Check x bounds
    if (newPosition.x <= bottomLeft.x) {
        newPosition.x = bottomLeft.x;
        newVelocity.x = -newVelocity.x;
    }
    if (newPosition.x >= topRight.x) {
        newPosition.x = topRight.x;
        newVelocity.x = -newVelocity.x;
    }
    if (newPosition.y <= bottomLeft.y) {
        newPosition.y = bottomLeft.y;
        newVelocity.y = -newVelocity.y;
    }
    if (newPosition.y >= topRight.y) {
        newPosition.y = topRight.y;
        newVelocity.y = -newVelocity.y;
    }
    
    self.zombieNode.position = newPosition;
    self.velocity = newVelocity;
}



// Rotates a sprite with a rotation speed towards a direction vector
- (void)rotateSprite:(SKSpriteNode *)sprite
              toFace:(CGPoint)direction
       rotationSpeed:(CGFloat)rotateRadiansPerSec {
    
    // Find shortest angle between zombie and direction
    CGFloat directionAngle = CGPointToAngle(direction);
    CGFloat shortestAngleInRad = ScalarShortestAngleBetween(sprite.zRotation, directionAngle);
    // Get rotation distance per frame using given rotation speed
    CGFloat amtToRotate = MIN(rotateRadiansPerSec * (CGFloat)self.dt, fabs(shortestAngleInRad));
    // If angle between is shorter than amount to rotate, stop
    sprite.zRotation += ScalarSign(shortestAngleInRad) * amtToRotate;
}

- (void)sceneTouched:(CGPoint)touchLocation {
    [self moveZombieToward:touchLocation];
}

#pragma mark Scene Transition
- (void)presentGameOverScreenDidWin:(BOOL)won
{
    [self.backgroundMusicPlayer stop];
    GameOverScene *gameOverScene = [[GameOverScene alloc]
                                    initWithSize:self.size isWon:won];
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
    gameOverScene.scaleMode = self.scaleMode;
    [self.view presentScene:gameOverScene transition:reveal];
}

@end
