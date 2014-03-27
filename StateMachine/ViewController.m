//
//  ViewController.m
//  StateMachine
//
//  Created by Jens Schwarzer on 18/02/14.
//  Copyright (c) 2014 marchv. All rights reserved.
//

#import "ViewController.h"

// StateMachine 1; include framework
#import "StateMachine.h"

@interface ViewController ()

// StateMachine 2; add property
@property (nonatomic) Machine *machine;

// StateMachine 3; add possible extended state variables (has to be public)
@property (nonatomic) unsigned counter;

@end

// StateMachine 4; declare events
@protocol MyEvents
@optional
- (void)EventWithoutData;
- (void)EventWithNumber:(NSNumber *)number;
- (void)EventWithDictionary:(NSDictionary *)dictionary;
@end

// StateMachine 5; declare states (forward declarations needed as state definitions references to each other)
@interface MyStateA : State <MyEvents>
@end

@interface MyStateB : State <MyEvents>
@end

@interface   MyStateB1 : State <MyEvents>
@end

@interface   MyStateB2 : State <MyEvents>
@end

// StateMachine 6; define states
@implementation MyStateA
- (void)entryAction { NSLog(@"MyStateA entryAction"); }
- (void)exitAction { NSLog(@"MyStateA exitAction"); }
- (void)EventWithoutData { [self transitionToState:[MyStateB class]]; }
@end

@implementation MyStateB
- (Class)defaultTransition { return [MyStateB1 class]; }
@end

@implementation MyStateB1
- (Class)superstate { return [MyStateB class]; }
- (void)EventWithNumber:(NSNumber *)number { NSLog(@"%@", number); }
- (void)EventWithDictionary:(NSDictionary *)dictionary { NSLog(@"%@", dictionary); }
@end

@implementation MyStateB2
- (Class)superstate { return [MyStateB class]; }

- (NSTimeInterval)after { return 5.0f; }
- (void)timeout { [self transitionToState:[self class]]; } // self-transition on timeout

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // StateMachine 7; create instance of state machine with initial state and a reference to extended state
    _machine = [[Machine alloc] initWithInitialStateClass:[MyStateA class] andExtendedState:self andTraces:YES];
    
    [_machine dispatchEvent:@selector(EventWithoutData)];
    [_machine dispatchEvent:@selector(EventWithNumber:) withObject:@5];
    [_machine dispatchEvent:@selector(EventWithDictionary:) withObject:@{@"key": @4}];
}

@end
