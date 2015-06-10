//
//  GameOverScene.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/10/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import "GameOverScene.h"
#import "GameScene.h"

@implementation GameOverScene

-(instancetype)initWithSize:(CGSize)size isWon:(BOOL)won {
    self = [super initWithSize:size];
    _won = won;
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    @throw [NSException exceptionWithName:@"Wrong init"
                                   reason:@"not implemented" userInfo:nil];
}

-(void)didMoveToView:(SKView *)view {
    SKSpriteNode *background;
    
    if (self.won) {
        background = [[SKSpriteNode alloc] initWithImageNamed:@"YouWin"];
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.1], // wait for scene to transition
                                             [SKAction playSoundFileNamed:@"win.wav"
                                                        waitForCompletion:NO]]]];
    } else {
        background = [[SKSpriteNode alloc] initWithImageNamed:@"YouLose"];
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.1],
                                             [SKAction playSoundFileNamed:@"lose.wav"
                                                        waitForCompletion:NO]]]];
    }
    
    background.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:background];
    
    SKAction *wait = [SKAction waitForDuration:3.0];
    // Make new game
    SKAction *block = [SKAction runBlock:^{
        GameScene *myScene = [[GameScene alloc] initWithSize:self.size];
        myScene.scaleMode = self.scaleMode;
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:myScene transition:reveal];
    }];
    // Wait 3 seconds then present a new game
    [self runAction:[SKAction sequence:@[wait, block]]];
}

@end
