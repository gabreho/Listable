//
//  ListView.Delegate.swift
//  ListableUI
//
//  Created by Kyle Van Essen on 11/19/19.
//


extension ListView
{
    final class Delegate : NSObject, UICollectionViewDelegate, CollectionViewLayoutDelegate
    {
        unowned var view : ListView?
        unowned var presentationState : PresentationState!
        unowned var layoutManager : LayoutManager!
        
        private let itemMeasurementCache = ReusableViewCache()
        private let headerFooterMeasurementCache = ReusableViewCache()
        
        private let headerFooterViewCache = ReusableViewCache()
        
        // MARK: UICollectionViewDelegate
        
        func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool
        {
            guard let view = self.view else { return false }
            
            guard view.behavior.selectionMode != .none else { return false }
            
            let item = self.presentationState.item(at: indexPath)
            
            return item.anyModel.selectionStyle.isSelectable
        }
        
        func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
        {
            guard let view = self.view else { return }
            
            let item = self.presentationState.item(at: indexPath)
            
            item.applyToVisibleCell(with: view.environment)
        }
        
        func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
        {
            guard let view = self.view else { return }
            
            let item = self.presentationState.item(at: indexPath)
            
            item.applyToVisibleCell(with: view.environment)
        }
        
        func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
        {
            guard let view = self.view else { return false }
            
            guard view.behavior.selectionMode != .none else { return false }
            
            let item = self.presentationState.item(at: indexPath)
            
            return item.anyModel.selectionStyle.isSelectable
        }
        
        func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool
        {
            return true
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
        {
            guard let view = self.view else { return }
            
            let item = self.presentationState.item(at: indexPath)
            
            item.set(isSelected: true, performCallbacks: true)
            item.applyToVisibleCell(with: view.environment)
            
            self.performOnSelectChanged()
            
            if item.anyModel.selectionStyle == .tappable {
                item.set(isSelected: false, performCallbacks: true)
                collectionView.deselectItem(at: indexPath, animated: true)
                item.applyToVisibleCell(with: view.environment)
                
                self.performOnSelectChanged()
            }
        }
        
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath)
        {
            guard let view = self.view else { return }
            
            let item = self.presentationState.item(at: indexPath)
            
            item.set(isSelected: false, performCallbacks: true)
            item.applyToVisibleCell(with: view.environment)
            
            self.performOnSelectChanged()
        }
        
        private var oldSelectedItems : Set<AnyIdentifier> = []
        
        private func performOnSelectChanged() {
            
            guard let view = self.view else { return }
            
            let old = self.oldSelectedItems
            
            let new = Set(self.presentationState.selectedItems.map(\.anyModel.anyIdentifier))
            
            guard old != new else {
                return
            }
            
            self.oldSelectedItems = new
            
            ListStateObserver.perform(view.stateObserver.onSelectionChanged, "Selection Changed", with: view) {
                ListStateObserver.SelectionChanged(
                    actions: $0,
                    positionInfo: view.scrollPositionInfo,
                    old: old,
                    new: new
                )
            }
        }
        
        private var displayedItems : [ObjectIdentifier:AnyPresentationItemState] = [:]
        
        func collectionView(
            _ collectionView: UICollectionView,
            willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
            )
        {
            let item = self.presentationState.item(at: indexPath)
            
            item.willDisplay(cell: cell, in: collectionView, for: indexPath)
            
            self.displayedItems[ObjectIdentifier(cell)] = item
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            didEndDisplaying cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
            )
        {
            guard let item = self.displayedItems.removeValue(forKey: ObjectIdentifier(cell)) else {
                return
            }
            
            item.didEndDisplay()
        }
        
        private var displayedSupplementaryItems : [ObjectIdentifier:PresentationState.HeaderFooterViewStatePair] = [:]
        
        func collectionView(
            _ collectionView: UICollectionView,
            willDisplaySupplementaryView anyView: UICollectionReusableView,
            forElementKind kindString: String,
            at indexPath: IndexPath
            )
        {
            guard let view = self.view else { return }
            
            let container = anyView as! SupplementaryContainerView
            let kind = SupplementaryKind(rawValue: kindString)!
            
            let headerFooter : PresentationState.HeaderFooterViewStatePair = {
                switch kind {
                case .listHeader: return self.presentationState.header
                case .listFooter: return self.presentationState.footer
                case .sectionHeader: return self.presentationState.sections[indexPath.section].header
                case .sectionFooter: return self.presentationState.sections[indexPath.section].footer
                case .overscrollFooter: return self.presentationState.overscrollFooter
                }
            }()
            
            headerFooter.willDisplay(view: container)
            
            self.displayedSupplementaryItems[ObjectIdentifier(view)] = headerFooter
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            didEndDisplayingSupplementaryView view: UICollectionReusableView,
            forElementOfKind elementKind: String,
            at indexPath: IndexPath
            )
        {
            guard let headerFooter = self.displayedSupplementaryItems.removeValue(forKey: ObjectIdentifier(view)) else {
                return
            }
            
            headerFooter.didEndDisplay()
        }
        
        func collectionView(
            _ collectionView: UICollectionView,
            targetIndexPathForMoveFromItemAt from: IndexPath,
            toProposedIndexPath to: IndexPath
        ) -> IndexPath
        {
            ///
            /// **Note**: We do not use either `from` or `to` index paths passed to this method to
            /// index into the `presentationState`'s content – it has not yet been updated
            /// to reflect the move, because the move has not yet been committed. The `from` parameter
            /// is instead reflecting the current `UICollectionViewLayout`'s state – which will not match
            /// the data source / `presentationState`.
            ///
            /// Instead, read the `stateForItem(at:)` off of the `layoutManager`. This will reflect
            /// the right index path.
            ///
            /// iOS 15 resolves this issue, by introducing
            /// ```
            /// func collectionView(
            ///     _ collectionView: UICollectionView,
            ///     targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
            ///     atCurrentIndexPath currentIndexPath: IndexPath,
            ///     toProposedIndexPath proposedIndexPath: IndexPath
            /// ) -> IndexPath
            /// ```
            /// Which passes the **original** index path, allowing a direct index into your data source.
            /// Alas, we do not yet support only iOS 15 and later, so, here we are.
            ///
            
            guard from != to else {
                return from
            }
            
            let item = self.layoutManager.stateForItem(at: from)
            
            // An item is not reorderable if it has no reordering config.
            guard let reordering = item.anyModel.reordering else {
                return from
            }
            
            // If we're moving the item back to its original position,
            // allow regardless of any other rules.
            if to == item.activeReorderEventInfo?.originalIndexPath {
                return to
            }
            
            // Finally, perform validation based on item and section validations.
            
            let fromSection = self.presentationState.sections[from.section]
            let toSection = self.presentationState.sections[to.section]
            
            return reordering.destination(
                from: from,
                fromSection: fromSection,
                to: to,
                toSection: toSection
            )
        }
        
        // MARK: CollectionViewLayoutDelegate
        
        func listViewLayoutUpdatedItemPositions()
        {
            guard let view = self.view else { return }
            
            /// During reordering; our index paths will not match the index paths of the collection view;
            /// our index paths are not updated until the move is committed.
            if self.layoutManager.collectionViewLayout.isReordering {
                return
            }
            
            view.setPresentationStateItemPositions()
        }
        
        func listLayoutContent(
            defaults: ListLayoutDefaults
        ) -> ListLayoutContent
        {
            guard let view = self.view else {
                fatalError("Was asked for content without a valid view.")
            }
            
            return self.presentationState.toListLayoutContent(
                defaults: defaults,
                environment: view.environment
            )
        }
        
        func listViewLayoutDidLayoutContents()
        {
            guard let view = self.view else { return }
            
            view.visibleContent.update(with: view)
        }
        
        func listViewShouldBeginQueueingEditsForReorder() {
            guard let view = self.view else { return }

            view.updateQueue.isPaused = true
        }
        
        func listViewShouldEndQueueingEditsForReorder() {
            guard let view = self.view else { return }

            view.updateQueue.isPaused = false
        }

        // MARK: UIScrollViewDelegate
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
        {
            guard let view = self.view else { return }
            
            view.liveCells.perform {
                $0.closeSwipeActions()
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
        {
            guard let view = self.view else { return }
            
            view.updatePresentationState(for: .didEndDecelerating)
        }
                
        func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool
        {
            guard let view = self.view else { return true }
            
            switch view.behavior.scrollsToTop {
            case .disabled: return false
            case .enabled: return true
            }
        }
        
        func scrollViewDidScrollToTop(_ scrollView: UIScrollView)
        {
            guard let view = self.view else { return }
            
            view.updatePresentationState(for: .scrolledToTop)
        }
        
        private var lastPosition : CGFloat = 0.0
        
        func scrollViewDidScroll(_ scrollView: UIScrollView)
        {
            guard let view = self.view else { return }
            guard scrollView.bounds.size.height > 0 else { return }
                        
            SignpostLogger.log(.begin, log: .scrollView, name: "scrollViewDidScroll", for: self.view)
            
            defer {
                SignpostLogger.log(.end, log: .scrollView, name: "scrollViewDidScroll", for: self.view)
            }
            
            // Updating Paged Content
            
            let scrollingDown = self.lastPosition < scrollView.contentOffset.y
            
            self.lastPosition = scrollView.contentOffset.y
            
            if scrollingDown {
                view.updatePresentationState(for: .scrolledDown)
            }
            
            ListStateObserver.perform(view.stateObserver.onDidScroll, "Did Scroll", with: view) {
                ListStateObserver.DidScroll(
                    actions: $0,
                    positionInfo: view.scrollPositionInfo
                )
            }
        }
    }
}
