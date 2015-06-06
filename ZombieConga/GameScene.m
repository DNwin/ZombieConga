//
//  GameScene.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/5/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import "GameScene.h"
#import "MyUtils.h"


static const CGFloat ZOMBIE_ROTATE_RADIANS_PER_SEC = 4.0 * M_PI;
#define DEFAULT_MOVE_POINTS_VALUE 480.0

@interface GameScene()

@property (strong, nonatomic) SKSpriteNode *zombieNode; // zombie node;
@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic) NSTimeInterval dt; // Time per frame in ms
@property (nonatomic) CGFloat zombieMovePointsPerSec; // Desired pixels/sec
@property (nonatomic) CGPoint velocity; // Current velocity of the zombie
@property (nonatomic) CGRect playableRect; // Playable rectangle
@property (nonatomic) CGPoint lastTouchLocation; // Last location touched

@end;


@implementation GameScene


#pragma mark - Lifecycle

// Designated init
- (instancetype) initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        _zombieNode = [[SKSpriteNode alloc] initWithImageNamed:@"zombie1"];
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
    self.backgroundColor = [SKColor whiteColor];
    
    // Make background sprite node
    SKSpriteNode *background = [[SKSpriteNode alloc] initWithImageNamed:@"background1"];
    
    // Set background position using the size of the view
    // X, Y positions in Sprite Kit start in bottom left
    // Default anchor point is middle of picture CGPoint 0.5, 0.5
    background.position = CGPointMake(self.size.width/2, self.size.height/2);
    background.anchorPoint = CGPointMake(0.5, 0.5);
    // Set z position to prevent nodes from spawning under background
    background.zPosition = -1;

    
    //  ** Change anchor to bottom left
    // background.anchorPoint = CGPointZero;
    // background.position = CGPointZero;
    
    // ** Rotation about z axis around anchor points
    // background.zRotation = M_PI/8;

    // Add sprite node as a child
    [self addChild:background];
    
    // Setup and add zombie node
    self.zombieNode.position = CGPointMake(400.0, 400.0);
    [self addChild:self.zombieNode];
    
    [self debugDrawPlayableArea];
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
    [self distanceBetweenTouchCheckZombie];
    

}

#pragma mark - Custom Accessors


- (CGFloat)zombieMovePointsPerSec {
    if (!_zombieMovePointsPerSec) {
        _zombieMovePointsPerSec = DEFAULT_MOVE_POINTS_VALUE;
    }
    return _zombieMovePointsPerSec;
}
#pragma mark - Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self sceneTouched:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self];
    [self sceneTouched:touchLocation];
}

#pragma mark - Private

// Check distance between last touch and position and stop moving when close
- (void)distanceBetweenTouchCheckZombie
{
    CGPoint offset = CGPointSubtract(self.zombieNode.position, self.lastTouchLocation);
    if (CGPointLength(offset) <= self.zombieMovePointsPerSec*self.dt) {
        self.velocity = CGPointZero;
    }
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
    // Set points to playable rect
    CGPoint bottomLeft = CGPointMake(0, CGRectGetMinY(self.playableRect));
    CGPoint topRight = CGPointMake(CGRectGetWidth(self.playableRect),
                                   CGRectGetMaxY(self.playableRect));
    
    CGPoint newPosition = self.zombieNode.position;
    CGPoint newVelociy = self.velocity;
    
    // Check x bounds
    if (self.zombieNode.position.x <= bottomLeft.x) {
        newVelociy.x = -newVelociy.x;
    }
    if (self.zombieNode.position.x >= topRight.x) {
        newVelociy.x = -newVelociy.x;
    }
    // Check Y bounds
    if (self.zombieNode.position.y <= bottomLeft.y) {
        newVelociy.y = -newVelociy.y;
    }
    if (self.zombieNode.position.y >= topRight.y) {
        newVelociy.y = -newVelociy.y;
    }
    
    self.zombieNode.position = newPosition;
    self.velocity = newVelociy;
}

// moveSprite: - Changes the current position of a sprite with a velocity vector-
- (void)moveSprite:(SKSpriteNode *)sprite withVelocity:(CGPoint)velocity;
{

    // Multiply intended velocity by time per frame to get distance
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.dt);
    
    //NSLog(@"Amount to move: %f", hypot(amountToMove.x, amountToMove.y));
    
    // Update position of sprite
    sprite.position = CGPointAdd(sprite.position, amountToMove);
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

- (void)sceneTouched:(CGPoint)touchLocation
{
    [self moveZombieToward:touchLocation];
}

// moveZombieTowards: - Takes in a location and sets the velocity property
- (void)moveZombieToward:(CGPoint)location {
    
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



@end
