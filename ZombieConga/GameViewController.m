//
//  GameViewController.m
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/5/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"

@implementation SKScene (Unarchive)



@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Init a gamescene with hardcoded size 2048x1536
    GameScene *scene = [[GameScene alloc] initWithSize:CGSizeMake(2048, 1536)];
    // Get current view and configure it
    SKView *skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.ignoresSiblingOrder = YES;
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the GameScene;
    [skView presentScene:scene];
}

// Hides the status bar
- (BOOL)prefersStatusBarHidden {
    return YES;
}


@end
