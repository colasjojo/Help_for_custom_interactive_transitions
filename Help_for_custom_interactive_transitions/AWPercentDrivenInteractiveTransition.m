//
//  AWPercentDrivenInteractiveTransition.m
//
//  Created by Alek Astrom on 2014-04-27.
//
// Copyright (c) 2014 Alek Åström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "AWPercentDrivenInteractiveTransition.h"

@interface AWPercentDrivenInteractiveTransition ()
@property (nonatomic, strong, readwrite) id<UIViewControllerContextTransitioning> transitionContext ;
@end

@implementation AWPercentDrivenInteractiveTransition {
    //__strong id<UIViewControllerContextTransitioning> _transitionContext;
    BOOL _isInteracting;
    CADisplayLink *_displayLink;
}

#pragma mark - Initialization
- (instancetype)initWithAnimator:(id<UIViewControllerAnimatedTransitioning>)animator {
    
    self = [super init];
    if (self) {
        [self _commonInit];
        _animator = animator;
    }
    return self;
}
- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}
- (void)_commonInit {
    _completionSpeed = 1;
}


- (void)setTransitionContext:(id<UIViewControllerContextTransitioning>)theTransitionContext
{
    _transitionContext = theTransitionContext ;
}

#pragma mark - Public methods
- (BOOL)isInteracting {
    return _isInteracting;
}
- (CGFloat)duration {
    return [_animator transitionDuration:self.transitionContext];
}
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    self.transitionContext = transitionContext;
    [self.transitionContext containerView].layer.speed = 0;
    
    [_animator animateTransition:self.transitionContext];
}
- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    self.percentComplete = fmaxf(fminf(percentComplete, 1), 0); // Input validation
}
- (void)cancelInteractiveTransition {
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_tickCancelAnimation)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                       forMode:NSRunLoopCommonModes];
    
    [self.transitionContext cancelInteractiveTransition];
}
- (void)finishInteractiveTransition {
    CALayer *layer = [self.transitionContext containerView].layer;
    
    layer.speed = [self completionSpeed];
    
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
    
    [self.transitionContext finishInteractiveTransition];
}

#pragma mark - Private methods
- (void)setPercentComplete:(CGFloat)percentComplete {
    
    NSLog(@"%% complete: %d", (int)(_percentComplete*100)) ;
    _percentComplete = percentComplete;
    
    [self _setTimeOffset:percentComplete*[self duration]];
    [self.transitionContext updateInteractiveTransition:percentComplete];
}
- (void)_setTimeOffset:(NSTimeInterval)timeOffset {
    
    /*
     WTF !!!!
     
     How is it possible that self.transitionContext is now nil !!!!!
     */
    [self.transitionContext containerView].layer.timeOffset = timeOffset;
}
- (void)_tickCancelAnimation {
    NSTimeInterval timeOffset = [self _timeOffset]-[_displayLink duration];
    if (timeOffset < 0) {
        [self _transitionFinishedCanceling];
    } else {
        [self _setTimeOffset:timeOffset];
    }
}
- (CFTimeInterval)_timeOffset {
    return [self.transitionContext containerView].layer.timeOffset;
}
- (void)_transitionFinishedCanceling {
    [_displayLink invalidate];
    
    CALayer *layer = [self.transitionContext containerView].layer;
    layer.speed = 1;
}

@end
