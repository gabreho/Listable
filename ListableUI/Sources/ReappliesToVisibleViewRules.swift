//
//  ReappliesToVisibleViewRules.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 6/3/21.
//

import Foundation


public enum ReappliesToVisibleViewRules {
    
    case always
    case ifNotEquivalent(Set<ObjectIdentifier>? = nil)
    
    public static func ifNotEquivalent(_ references : AnyObject...) -> Self {
        .ifNotEquivalent(Set(references.map { ObjectIdentifier($0) }))
    }
}
