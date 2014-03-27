# StateMachine

`StateMachine` is a finite/hierarchical state machine framework written in Objective-C for iOS. The framework can be used to implement UML state diagrams.

The documentation/examples is currently insufficient - sorry. I have plans to make a demo where some button on the UI can be used to generate events.

## References

  * [Wikipedia](http://en.wikipedia.org/wiki/UML_state_machine)

## Features

The framework is developed based on my needs and currently I have identified the following supported and unsupported features:

### Supported

  * Events
  * States
  * Extended states (state variables)
  * Transitions
    * Regular
    * Default
    * Initial
    * Internal
    * Self
  * Actions
    * Entry
    * Exit
    * Transition
  * Guards
  * After (timeout)

### Unsupported

  * Orthogonal regions
  * External transitions
  * Deferred events
  * Deep history
  * Shallow history

## Traces

The framework has iOS traces that are written to the Xcode Target Output. Example:

     Starting machine: Machine
       Initial transition started:  • -> MyStateA
         MyStateA entered
     MyStateA entryAction
       Initial transition completed
     Machine started
     EventWithoutData with object (null) catched by MyStateA
       Transition started: MyStateA -> MyStateB
     MyStateA exitAction
         MyStateA exited
         MyStateB entered
       Default transition: MyStateB -> MyStateB1
         MyStateB1 entered
       Transition completed
     EventWithNumber: with object 5 catched by MyStateB1
     EventWithDictionary: with object { key = 4; } catched by MyStateB1


## Notes

The state hierarchy is solved lazily at run-time.

## History

The framework is based on a C-version I made in April 2005.