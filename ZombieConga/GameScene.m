//
//  GameScene.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/5/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import "GameScene.h"

@interface GameScene()

@property (strong, nonatomic) SKSpriteNode *zombieNode; // zombie node;
@property (nonatomic) NSTimeInterval lastUpdateTime;
@property (nonatomic) NSTimeInterval dt; // Difference in time per frame
@property (nonatomic) CGFloat zombieMovePointsPerSec;
@property (nonatomic) CGPoint velocity;

@end;


@implementation GameScene


#pragma mark - Lifecycle
- (instancetype) initWithSize:(CGSize)size {
    self = [super initWithSize:size];
    if (self) {
        _zombieNode = [[SKSpriteNode alloc] initWithImageNamed:@"zombie1"];
        _lastUpdateTime = 0;
        _dt = 0;
        _velocity = CGPointZero;
    }
    return self;
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

}

- (void)update:(NSTimeInterval)currentTime
{
    // Calculate the amount of time it takes per frame in ms (dt)
    if (self.lastUpdateTime > 0) {
        self.dt = currentTime - self.lastUpdateTime;
    } else {
        self.dt = 0;
    }
    self.lastUpdateTime = currentTime;
    // NSLog(@"%f milliseconds since last update", self.dt * 1000);
    
    [self moveSprite:self.zombieNode withVelocity:self.velocity];
}

#pragma mark - Custom Accessors

#define DEFAULT_MOVE_POINTS_VALUE 480.0
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

// moveSprite: - Changes the current position of a sprite with a velocity vector-
- (void)moveSprite:(SKSpriteNode *)sprite withVelocity:(CGPoint)velocity;
{

    // Multiply intended velocity by time per frame to get distance
    CGPoint amountToMove = CGPointMake(velocity.x * (CGFloat)self.dt,
                                       velocity.y * (CGFloat)self.dt);
    NSLog(@"Amount to move: %f", hypot(amountToMove.x, amountToMove.y));
    
    // Update position of sprite
    sprite.position = CGPointMake(sprite.position.x + amountToMove.x,
                                  sprite.position.y + amountToMove.y);
}

- (void)sceneTouched:(CGPoint)touchLocation
{
    [self moveZombieToward:touchLocation];
}

// moveZombieTowards: - Takes in a location and sets the velocity property
- (void)moveZombieToward:(CGPoint)location {
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
