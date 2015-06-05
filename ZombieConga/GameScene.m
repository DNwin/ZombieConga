//
//  GameScene.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/5/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene

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
    
    
    // Add zombie node
    SKSpriteNode *zombieNode = [[SKSpriteNode alloc] initWithImageNamed:@"zombie1"];
    zombieNode.position = CGPointMake(400.0, 400.0);
    // Scale the node 2x
    [zombieNode setScale:2.0];
    [self addChild:zombieNode];

}


@end
