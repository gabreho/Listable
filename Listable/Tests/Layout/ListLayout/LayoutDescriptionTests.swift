//
//  LayoutDescriptionTests.swift
//  Listable-Unit-Tests
//
//  Created by Kyle Van Essen on 6/17/20.
//

import XCTest
@testable import Listable


final class LayoutDescriptionTests : XCTest
{
    func test_createPopulatedLayout()
    {
        let listView = ListView()
        
        var describeCallCount : Int = 0
        
        let description = TestLayout.describe {
            describeCallCount += 1
            $0.anotherValue = "Hello"
        }
        
        let populated = description.configuration.createPopulatedLayout(
            appearance: listView.appearance,
            behavior: listView.behavior,
            delegate: listView.delegate,
            in: listView.collectionView
        )
        
        XCTAssertEqual(describeCallCount, 1)
        XCTAssertEqual((populated as! TestLayout).layoutAppearance.anotherValue, "Hello")
    }
    
    func test_shouldRebuild()
    {
        let listView = ListView()
        
        let layout = TestLayout(
            layoutAppearance: TestLayoutAppearance(anotherValue: "Hello 1"),
            appearance: Appearance(),
            behavior: Behavior(),
            delegate: listView.delegate,
            in: listView.collectionView
        )
        
        let description1 = TestLayout.describe {
            $0.anotherValue = "Hello 1"
        }
        
        let description2 = TestLayout.describe {
            $0.anotherValue = "Hello 2"
        }
        
        XCTAssertEqual(description1.configuration.shouldRebuild(layout: layout), false)
        XCTAssertEqual(description2.configuration.shouldRebuild(layout: layout), true)
    }
    
    func test_isSameLayoutType()
    {
        let description1 = DefaultListLayout.describe()
        let description2 = PagedListLayout.describe()
        
        XCTAssertEqual(description1.configuration.isSameLayoutType(as: description1.configuration), true)
        XCTAssertEqual(description1.configuration.isSameLayoutType(as: description2.configuration), false)
    }
}


private struct TestLayoutAppearance : ListLayoutAppearance
{
    static var `default`: TestLayoutAppearance {
        self.init(anotherValue: "")
    }
    
    var direction: LayoutDirection = .vertical
    
    var stickySectionHeaders: Bool = true
    
    var anotherValue : String
}

private final class TestLayout : ListLayout
{
    typealias LayoutAppearance = TestLayoutAppearance
    
    var layoutAppearance: TestLayoutAppearance
        
    var appearance: Appearance
    
    var behavior: Behavior
    
    var content: ListLayoutContent
    
    var scrollViewProperties: ListLayoutScrollViewProperties {
        .init(
            isPagingEnabled: false,
            contentInsetAdjustmentBehavior: .automatic,
            allowsBounceVertical: true,
            allowsBounceHorizontal: true,
            allowsVerticalScrollIndicator: true,
            allowsHorizontalScrollIndicator: true
        )
    }
    
    init()
    {
        self.layoutAppearance = .default
        
        self.appearance = Appearance()
        self.behavior = Behavior()
        self.content = ListLayoutContent(with: .vertical)
    }
    
    init(
        layoutAppearance: TestLayoutAppearance,
        appearance: Appearance,
        behavior: Behavior,
        delegate: CollectionViewLayoutDelegate,
        in collectionView: UICollectionView
    ) {
        self.layoutAppearance = layoutAppearance
        
        self.appearance = appearance
        self.behavior = behavior
        self.content = ListLayoutContent(delegate: delegate, direction: layoutAppearance.direction, in: collectionView)
    }
    
    func updateLayout(in collectionView: UICollectionView) -> Bool { true }
    
    func layout(delegate: CollectionViewLayoutDelegate, in collectionView: UICollectionView) -> Bool { true }
}