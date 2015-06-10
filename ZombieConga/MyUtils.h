//
//  MyUtils.h
//  ZombieConga
//
//  Created by Dennis Nguyen on 6/6/15.
//  Copyright (c) 2015 dnwin. All rights reserved.
//

#ifndef ZombieConga_MyUtils_h
#define ZombieConga_MyUtils_h

#import <Foundation/Foundation.h>

static inline CGPoint CGPointAdd(const CGPoint a,
                                 const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointSubtract(const CGPoint a,
                                      const CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a,
                                            const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

//Hypotenuse
static inline CGFloat CGPointLength(const CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

//Unit vector
static inline CGPoint CGPointNormalize(const CGPoint a)
{
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

static inline CGFloat CGPointToAngle(const CGPoint a)
{
    return atan2f(a.y, a.x);
}

static inline CGFloat ScalarSign(CGFloat a)
{
    return a >= 0 ? 1 : -1;
}

// Returns shortest angle between two angles,
// between -M_PI and M_PI
static inline CGFloat ScalarShortestAngleBetween(
                                                 const CGFloat a, const CGFloat b)
{
    CGFloat difference = b - a;
    CGFloat angle = fmodf(difference, M_PI * 2);
    if (angle >= M_PI) {
        angle -= M_PI * 2;
    }
    return angle;
}

// Random value beteween 0 and 1
static inline CGFloat CGFloatRandom()
{
    float val = (float)(arc4random() % (unsigned)RAND_MAX + 1) / RAND_MAX;
    return (CGFloat)val;

}

// Returns a random value in the range
#define ARC4RANDOM_MAX      0x100000000
static inline CGFloat CGFloatRandomRange(CGFloat min, CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) *
                  (max - min) + min);
}

#endif
