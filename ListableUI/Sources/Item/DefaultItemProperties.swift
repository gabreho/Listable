//
//  DefaultItemProperties.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 12/14/20.
//

import Foundation


/// Allows specifying default properties to apply to an item when it is initialized,
/// if those values are not provided to the initializer.
/// Only non-nil values are used – if you do not want to provide a default value,
/// simply leave the property nil.
///
/// The order of precedence used when assigning values is:
/// 1) The value passed to the initializer.
/// 2) The value from `defaultItemProperties` on the contained `ItemContent`, if non-nil.
/// 3) A standard, default value.
public struct DefaultItemProperties<Content:ItemContent>
{
    public var sizing : Sizing?
    public var layout : ItemLayout?
    
    public var selectionStyle : ItemSelectionStyle?
    
    public var insertAndRemoveAnimations : ItemInsertAndRemoveAnimations?
    
    public var swipeActions : SwipeActionsConfiguration?
    
    public init(
        sizing : Sizing? = nil,
        layout : ItemLayout? = nil,
        selectionStyle : ItemSelectionStyle? = nil,
        insertAndRemoveAnimations : ItemInsertAndRemoveAnimations? = nil,
        swipeActions : SwipeActionsConfiguration? = nil
    ) {
        self.sizing = sizing
        self.layout = layout
        self.selectionStyle = selectionStyle
        self.insertAndRemoveAnimations = insertAndRemoveAnimations
        self.swipeActions = swipeActions
    }
}