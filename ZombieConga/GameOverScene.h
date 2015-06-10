//
//  GameOverScene.h
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/10/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameOverScene : SKScene

@property (nonatomic) BOOL won;

// Desigated init
-(instancetype)initWithSize:(CGSize)size isWon:(BOOL)won;

@end
