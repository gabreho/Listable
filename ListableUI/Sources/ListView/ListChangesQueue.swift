//
//  ListChangesQueue.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 7/19/21.
//

import Foundation


/// Used to queue updates into a list view.
/// Note: This type is only safe to use from the main thread.
final class ListChangesQueue {
        
    /// Adds a synchronous block to the queue, marked as done once the block exits.
    func addSync(_ block : @escaping () -> ()) {
        self.addAsync { context in
            block()
            context.setCompleted()
        }
    }
    
    /// Adds an async block to the queue, marked as done once the provided context is marked as complete.
    /// When using this method, you must call `Context.setCompleted()`, otherwise the queue will never proceed.
    func addAsync(_ block : @escaping (Context) -> ()) {
        self.waiting.append(.init(block))
        self.runIfNeeded()
    }
    
    /// Prevents processing other events in the queue.
    ///
    /// ### Note
    /// This is currently only used in one place; to stop processing during
    /// reorder events. If multiple places need to set this value, update to use a safer
    /// method to account for multiple stop points over a single bool; such as a counter-based
    /// method (`beginPausing`), or counter-based objects for each call site.
    var isPaused : Bool = false {
        didSet {
            if oldValue == self.isPaused { return }
            
            self.runIfNeeded()
        }
    }
    
    /// Operations waiting to execute.
    private(set) var waiting : [Operation] = []
    
    /// The current in-progress operation.
    private(set) var inProgress : Operation? = nil
    
    /// Invoked to continue processing queue events.
    private func runIfNeeded() {
        precondition(Thread.isMainThread)
        
        /// Nothing to do if we're currently paused!
        guard self.isPaused == false else {
            return
        }
        
        /// Nothing to do if there's an in-progress operation.
        guard self.inProgress == nil else {
            return
        }
        
        /// Nothing to do if we have no waiting operations at all!
        guard let next = self.waiting.popFirst() else {
            return
        }
        
        guard case .new(let new) = next.state else {
            fatalError("State of enqueued operation was wrong")
        }
        
        /// Ok, we have a runnable operation; let's make a context for it.
        
        let context = ListChangesQueue.Context { [weak self] in
            guard let self = self else { return }
            
            self.inProgress = nil
            self.runIfNeeded()
        }
        
        /// ...And then run it.
        
        self.inProgress = next
        
        next.state = .running
        
        new.body(context)
    }
}


extension ListChangesQueue {
    
    final class Operation {
        
        fileprivate(set) var state : State
        
        init(_ body : @escaping (Context) -> ()) {
            self.state = .new(.init(body: body))
        }
        
        enum State {
            case new(New)
            case running
            case done
            
            struct New {
                let body : (Context) -> ()
            }
        }
    }
}

extension ListChangesQueue {
    
    final class Context {
        
        private var state : State
        
        fileprivate init(_ onFinish : @escaping () -> ()) {
            self.state = .new(.init(onFinish: onFinish))
        }
        
        func setCompleted() {
            precondition(Thread.isMainThread)
            
            guard case let .new(new) = self.state else {
                fatalError()
            }
            
            self.state = .completed
            
            new.onFinish()
        }
        
        private enum State {
            case new(New)
            case completed
            
            struct New {
                let onFinish : () -> ()
            }
        }
    }
}


fileprivate extension Array {
    
    mutating func popFirst() -> Element? {
        guard self.isEmpty == false else {
            return nil
        }
        
        let first = self[0]
        
        self.remove(at: 0)
        
        return first
    }
}
