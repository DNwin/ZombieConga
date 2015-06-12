//
//  MainMenuScene.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/11/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import "MainMenuScene.h"
#import "GameScene.h"

@implementation MainMenuScene

- (void)didMoveToView:(SKView *)view {
    SKSpriteNode *background = [[SKSpriteNode alloc] initWithImageNamed:@"MainMenu"];
    background.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:background];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sceneTapped];
}

- (void)sceneTapped {
    GameScene *scene = [[GameScene alloc] initWithSize:self.size];
    scene.scaleMode = self.scaleMode;
    SKTransition *transition = [SKTransition doorwayWithDuration:0.5];

    [self.view presentScene:scene transition:transition];
}

@end
