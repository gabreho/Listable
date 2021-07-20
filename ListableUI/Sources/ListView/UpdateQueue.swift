//
//  UpdateQueue.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 7/19/21.
//

import Foundation


final class UpdateQueue {
    
    private var queuedOperation : Operation? = nil
    
    var isPaused : Bool {
        false // TODO
    }
    
    func add(_ operation : Operation) {
        self.queuedOperation = operation
        self.runQueuedOperationIfNeeded()
    }
    
    private func runQueuedOperationIfNeeded() {
        guard self.isPaused == false else {
            return
        }
        
        guard let operation = queuedOperation else {
            return
        }
        
        self.queuedOperation = nil
        
        guard case .new(let new) = operation.state else {
            fatalError()
        }
        
        operation.state = .running(.init())
        
        let context = UpdateQueue.Operation.Context { [weak self] in
            self?.runQueuedOperationIfNeeded()
        }
        
        new.body(context)
    }
}


extension UpdateQueue {
    
    final class Operation {
        
        fileprivate(set) var state : State
        
        init(_ body : @escaping (Context) -> ()) {
            self.state = .new(.init(body: body))
        }
    }
}


extension UpdateQueue.Operation {
    
    enum State {
        case new(New)
        case running(Running)
        case done(Done)
        
        struct New {
            let body : (Context) -> ()
        }
        
        struct Running {}
        
        struct Done {}
    }
    
    final class Context {
        private var state : State
        
        init(_ completed : @escaping () -> ()) {
            self.state = .new(completed)
        }
        
        func setComplete() {
            guard case .new(let completed) = self.state else {
                fatalError()
            }
            
            self.state = .done
            
            completed()
        }
        
        private enum State {
            case new(() -> ())
            case done
        }
    }
}
