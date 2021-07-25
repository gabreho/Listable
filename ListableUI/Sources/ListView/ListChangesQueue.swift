//
//  ListChangesQueue.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 7/19/21.
//

import Foundation


final class ListChangesQueue {
    
    private var waiting : [Operation] = []
    private var inProgress : Operation? = nil
        
    func add(_ block : @escaping () -> ()) {
        
        precondition(Thread.isMainThread)
        
        self.add { context in
            block()
            context.setCompleted()
        }
    }
    
    private func add(_ block : @escaping (Context) -> ()) {
                
        precondition(Thread.isMainThread)
        
        self.waiting.append(.init(block))
        
        self.runIfNeeded()
    }
    
    var isPaused : Bool = false {
        didSet {
            guard oldValue != self.isPaused else {
                return
            }
            
            if oldValue == true && self.isPaused == false {
                print("Unlocking queue...")
            }
            
            self.runIfNeeded()
        }
    }
    
    // TODO: Needs to be idempotent
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
    
    fileprivate final class Operation {
        
        var state : State
        
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
        
        init(_ onFinish : @escaping () -> ()) {
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
