//
//  StateMachine.h
//  StateMachine
//
//  Created by Jens Schwarzer on 17/02/14.
//  Copyright (c) 2014 marchv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Machine : NSObject

- (id)initWithInitialStateClass:(Class)initialStateClass andExtendedState:(id)extendedState andTraces:(BOOL)tracesEnabled;

- (void)dispatchEvent:(SEL)event;
- (void)dispatchEvent:(SEL)event withObject:(id)object;

@end


@interface State : NSObject

@property (nonatomic, weak) Machine *machine; // referenced by state if access is needed to extended state

- (id)extendedState;

// used to make a state transition from current state to a new state
- (void)transitionToState:(Class)newState;
- (void)transitionToState:(Class)newState withTransitionAction:(void(^)())action;

// to be optionally implemented by state
- (Class)superstate;        // if state has a superstate return it here

- (Class)defaultTransition; // if state has a default transition return it here

- (void)entryAction;        // actions to be executed when entering state (no call to transitionToState!)
- (void)exitAction;         // actions to be executed when leaving state (no call to transitionToState!)

- (NSTimeInterval)after;    // if timer
- (void)timeout;            // this method is called on timeout; can have either actions or a transition

@end
