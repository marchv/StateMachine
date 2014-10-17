//
//  StateMachine.m
//  StateMachine
//
//  Created by Jens Schwarzer on 17/02/14.
//  Copyright (c) 2014 marchv. All rights reserved.
//

#define TRACE_MACHINE(str, ...) if (self.traces)         NSLog(str, ##__VA_ARGS__)
#define TRACE_STATE(str, ...)   if (self.machine.traces) NSLog(str, ##__VA_ARGS__)

#import "StateMachine.h"

@interface Machine ()
{
    NSMutableDictionary *_states;  // all instantiated states
    State __weak        *_current; // current state
}

// public to State class
@property (nonatomic, weak) State *source;
@property (nonatomic)       BOOL eventRejected;
@property (nonatomic, weak) id extendedState;
@property (nonatomic)       BOOL traces;

- (void)transitionToState:(Class)newState withTransitionAction:(void(^)())action;

@end


@interface State ()
{
    NSTimer *_timer; // a state can have one after-timeout
}

// public to Machine class
@property (nonatomic, weak) State *superstatevar;
@property (nonatomic)       int   level; // hierachy level of the state

- (void)enterState;
- (void)exitState;

@end


@implementation Machine
@synthesize traces;

- (State *)getObjectOfStateClass:(Class)stateClass
{
    if (stateClass == Nil) return nil; // no object for topstate
    
    id key = [stateClass class];       // key used in dictionary
    
    State *state = _states[key];       // check if object is already in dictionary
    
    // if first time create object including its superstates
    if (state == nil)
    {
        state = [[stateClass alloc] init];
        state.machine = self;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        state.superstatevar = [self getObjectOfStateClass:[state performSelector:NSSelectorFromString(@"superstate")]];
#pragma clang diagnostic pop
        if (state.superstatevar) state.level = state.superstatevar.level + 1; // compute the hierarchy level
        _states[key] = state; // store new object in dictionary
    }
    
    return state;
}

- (id)initWithInitialStateClass:(Class)initialStateClass andExtendedState:(id)extendedState andTraces:(BOOL)tracesEnabled
{
    self = [super init];
    if (self) {
        self.traces = tracesEnabled;
        TRACE_MACHINE(@"Starting machine: %@", NSStringFromClass([self class]));
        
        _extendedState = extendedState;
        _states = [[NSMutableDictionary alloc] init];
        _current = [self getObjectOfStateClass:initialStateClass];
        
        if (_current.superstatevar != nil)
        {
            TRACE_MACHINE(@"HSM runtime error: initial state shall be at topstate level!");
            return nil;
        }
        
        TRACE_MACHINE(@"  Initial transition started:  • -> %@", NSStringFromClass([_current class]));
        [_current enterState];
        [self defaultTransition];
        TRACE_MACHINE(@"  Initial transition completed");
        
        TRACE_MACHINE(@"Machine started");
    }
    return self;
}

- (void)dispatchEvent:(SEL)event
{
    [self dispatchEvent:event withObject:nil];
}

- (void)dispatchEvent:(SEL)event withObject:(id)object
{
    _source = _current;
    
    do
    {
        if ([_source respondsToSelector:event])
        {
            _eventRejected = NO;
            TRACE_MACHINE(@"%@ with object %@ catched by %@", NSStringFromSelector(event), object, NSStringFromClass([_source class]));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [_source performSelector:event withObject:object];
#pragma clang diagnostic pop
            if (_eventRejected) {
                TRACE_MACHINE(@"%@ with object %@ rejected by %@", NSStringFromSelector(event), object, NSStringFromClass([_source class]));
            } else {
                _source = nil;
            }
        }
        if (_source)
        {
            //TRACE_MACHINE(@"%@ ignored by %@", NSStringFromSelector(event), NSStringFromClass([_source class]));
            _source = _source.superstatevar;
        }
    }
    while (_source);
}

- (void)leastCommonAnchestorBetweenSource:(State *)source andTarget:(State *)target andTransitionAction:(void (^)())action
{
    int delta = source.level - target.level;
    
    if (delta > 0) // source state above target state
    {
        [source exitState];
        [self leastCommonAnchestorBetweenSource:source.superstatevar andTarget:target andTransitionAction:action];
    }
    else if (delta < 0) // source state below target state
    {
        [self leastCommonAnchestorBetweenSource:source andTarget:target.superstatevar andTransitionAction:action];
        [target enterState];
    }
    else if (source != target) // superstates at the same level but not the common
    {
        [source exitState];
        [self leastCommonAnchestorBetweenSource:source.superstatevar andTarget:target.superstatevar andTransitionAction:action];
        [target enterState];
    }
    else if (action) // common superstate found - execute possible transition action
    {
        TRACE_MACHINE(@"  Transition action started");
        action(); // transition action
        TRACE_MACHINE(@"  Transition action completed");
    }
}

- (void)transitionToState:(Class)state withTransitionAction:(void (^)())action
{
    // if transition is not triggered by current state then exit down to the
    // triggering superstate (source of transition). This is the case when the triggering state makes a self-transition
    while (_source != _current)
    {
        [_current exitState];
        _current = _current.superstatevar;
    }
    
    if ([[_current class] isSubclassOfClass:state]) // self-transition
    {
        TRACE_MACHINE(@"  Self-transition started: %@", NSStringFromClass([_current class]));
        [_current exitState];
        if (action)
        {
            TRACE_MACHINE(@"  Transition action started");
            action(); // transition action
            TRACE_MACHINE(@"  Transition action completed");
        }
        [_current enterState];
    }
    else
    {
        State *target = [self getObjectOfStateClass:[state class]];
        TRACE_MACHINE(@"  Transition started: %@ -> %@", NSStringFromClass([_current class]), NSStringFromClass([state class]));
        [self leastCommonAnchestorBetweenSource:_current andTarget:target andTransitionAction:action];
        _current = target; // update current state
    }
    
    [self defaultTransition];
    
    TRACE_MACHINE(@"  Transition completed");
}

- (void)defaultTransition
{
    // Make default transitions if it exists
    while ([_current defaultTransition] != Nil)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        Class defaultTransitionToStateClass = [_current defaultTransition];
#pragma clang diagnostic pop
        TRACE_MACHINE(@"  Default transition: %@ -> %@", NSStringFromClass([_current class]), NSStringFromClass([defaultTransitionToStateClass class]));
        State *target = [self getObjectOfStateClass:[defaultTransitionToStateClass class]];
        
        [self leastCommonAnchestorBetweenSource:_current andTarget:target andTransitionAction:nil];
        _current = target; // update current state
    }
}

@end


@implementation State

- (id)extendedState
{
    return _machine.extendedState;
}

- (void)transitionToState:(Class)newState
{
    [_machine transitionToState:newState withTransitionAction:nil];
}

- (void)transitionToState:(Class)newState withTransitionAction:(void(^)())action
{
    [_machine transitionToState:newState withTransitionAction:action];
}

- (void)rejectEvent {
    _machine.eventRejected = YES;
}

- (Class)superstate { return Nil; }

- (Class)defaultTransition { return Nil; }

- (void)entryAction { }

- (void)exitAction { }

- (NSTimeInterval)after { return 0.0; }

- (void)timeout { }

- (void)enterState
{
    TRACE_STATE(@"    %@ entered", NSStringFromClass([self class]));
    NSTimeInterval timeinterval = [self after];
    if (timeinterval > 0.0)
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeinterval target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
    [self entryAction];
}

- (void)exitState
{
    [_timer invalidate];
    [self exitAction];
    TRACE_STATE(@"    %@ exited", NSStringFromClass([self class]));
}

- (void)timerFired:(NSTimer *)timer
{
    TRACE_STATE(@"Timer fired at %@ after %.1f s", NSStringFromClass([self class]), [self after]);
    [_timer invalidate];
    _machine.source = self;
    [self timeout];
    TRACE_STATE(@"Timer handling completed");
}

@end
