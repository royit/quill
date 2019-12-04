//
//  WrapperView.swift
//  WebContainer
//
//  Created by roy on 2019/11/25.
//  Copyright © 2019 royite. All rights reserved.
//

import UIKit
import RLayoutKit

public final class WrapperView: UIScrollView {
    
	// separator
    public var enableSeparator = false
    public var separatorHeight: CGFloat = 0.5
    public var separatorLeadingInset: CGFloat = 16
    public var separatorColor: UIColor = .lightGray
    public var separatorStyle: SeparatorStyle = .normal
    
    // safe area bottom
    public var enabledSafeAreaBottomInset = false
    
    // content
    private var contentView = UIView()
	
    // container
	public weak var dataSource: WrapperViewDataSource?
	public weak var wrapperDelegate: WrapperViewDelegate?
    
    // inner view
    private var cachedViews = [UIView]()
	private var innerViewsHasAdded = false
    private var innerViewObservations = [NSKeyValueObservation]()
    
	public override init(frame: CGRect) {
        super.init(frame: .zero)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		innerViewObservations.forEach { $0.invalidate() }
	}
    
    // MARK: - Container
    private var containerContentHeightInset: CGFloat {
        if #available(iOS 11.0, *) {
            return safeAreaInsets.top + (enabledSafeAreaBottomInset ? safeAreaInsets.bottom : 0)
        } else {
            return 0
        }
    }
    
    public func reloadData() {
        func clean() {
            cachedViews.removeAll()
            innerViewObservations.forEach({ $0.invalidate() })
            innerViewObservations.removeAll()
            innerViewsHasAdded = false
        }
        
        clean()
        setNeedsLayout()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        constractInnerViewsHierarchy()
        layoutWrapperView()
    }

    private func updateContainerContentSize() {
        guard !cachedViews.isEmpty else { return }
        
        contentSize.height = cachedViews.reduce(0, {
            if let contentHeight = ($1 as? WrapperInnerScrollViewType)?.scrollView.contentSize.height {
                return $0 + contentHeight
            } else {
                return $0 + $1.bounds.height
            }
        })
    }
    
    private func layoutWrapperView() {
        updateContentViewLayout()
        
        guard !cachedViews.isEmpty else { return }
        
        var previousView: UIView?
        let offsetY = contentOffset.y
        let contentViewHeight = contentView.bounds.height
        
        cachedViews.enumerated().forEach { index, view in
            let innerHeight = view.bounds.height
            
            if let innerScrollView = (view as? WrapperInnerScrollViewType)?.scrollView {
                let minY = previousView?.frame.maxY ?? 0
                
                let innerContentHeight = innerScrollView.contentSize.height
                let innerScrollOffsetY = offsetY - minY
                
                switch innerScrollOffsetY {
                case let innerOffsetY where innerOffsetY < 0:
                    if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
                        top.constant = 0
                    }
                    
                    // adjust inner scroll height
                    if let heightConstraint = view.constraint(for: Constraint.InnerView.height.id(at: index)) {
						let height = max(contentViewHeight, contentViewHeight + innerOffsetY)
                        heightConstraint.constant = min(height, contentViewHeight)
                    }
                    
                    innerScrollView.contentOffset.y = 0
                case let innerOffsetY where 0 <= innerOffsetY && innerOffsetY < innerContentHeight:
                    let maxInnerOffsetY = innerContentHeight - innerHeight
                    let y = min(innerOffsetY, maxInnerOffsetY)
                    if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
                        top.constant = y
                    }
                    
                    innerScrollView.contentOffset.y = y
                default:
                    if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
                        top.constant = max(0, innerContentHeight - contentViewHeight)
                    }
                    
                    innerScrollView.contentOffset.y = innerContentHeight - innerHeight
                }
            } else {
                if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
                    top.constant = 0
                }
            }
            
            previousView = view
        }
    }
    
    // MARK: - Content View
    private func addContentView() {
		contentView.added(to: self, layout: {
			let topConstraint: NSLayoutConstraint
            let heightConstraint: NSLayoutConstraint
			
			if #available(iOS 11.0, *) {
				topConstraint = $0.top == $1.top + $1.base.safeAreaInsets.top
				heightConstraint = $0.height == $1.height - containerContentHeightInset
			} else {
				topConstraint = $0.top == $1.top
				heightConstraint = $0.height == $1.height
			}
			
			topConstraint.identifier = Constraint.Content.top.identifier
            heightConstraint.identifier = Constraint.Content.height.identifier
			
			$0.leading == $1.leading
			$0.trailing == $1.trailing
			$0.width == $1.width
		}, config: {
			$0.backgroundColor = .white
		})
    }
    
    private func updateContentViewLayout() {
        // top
        if let top = constraint(for: Constraint.Content.top.identifier) {
            if #available(iOS 11.0, *) {
                top.constant = contentOffset.y + safeAreaInsets.top
            } else {
                top.constant = contentOffset.y
            }
        }

        // height
        if #available(iOS 11.0, *), let height = constraint(for: Constraint.Content.height.identifier) {
            height.constant = -containerContentHeightInset
        }

        // content
        if #available(iOS 11.0, *) {
            contentView.bounds.origin.y = contentOffset.y + safeAreaInsets.top
        } else {
            contentView.bounds.origin.y = contentOffset.y
        }
    }

	// MARK: - Inner View
	private func constractInnerViewsHierarchy() {
		guard !innerViewsHasAdded, let dataSource = dataSource else { return }
		
		if cachedViews.isEmpty {
			cachedViews = (0..<dataSource.numberOfInnerViews).map {
				dataSource.wrapperView(self, innerViewAt: $0)
			}
		}
        
		guard !cachedViews.isEmpty else { return }
		
        if enableSeparator {
            // TODO: <Roy> Separator reuse
            var withSeparatorsViews: [UIView] = cachedViews.reduce([]) {
                return $0 + [$1, Separator(separatorColor)]
            }
            
            if separatorStyle == .withFirstTop {
                withSeparatorsViews.insert(Separator(separatorColor), at: 0)
            }
            
            cachedViews = withSeparatorsViews
        }
        
		addContentView()
		
		var previousView: UIView?
		
		cachedViews.enumerated().forEach { index, view in
			view.added(to: contentView, layout: {
				$0.trailing == $1.trailing
				
				// top
				let topConstraint: NSLayoutConstraint
				if let previous = previousView {
					topConstraint = $0.top == previous.rl.bottom
				} else {
					topConstraint = $0.top == $1.top
				}

                topConstraint.identifier = Constraint.InnerView.top.id(at: index)
				
				// leading & height
                var leadingConstant: CGFloat = 0
                let delegateIndex = getDelegateIndex(forCachedViewIndex: index)
				if view is WrapperInnerScrollViewType {
					let height = wrapperDelegate?.wrapperView(self, heightForInnerViewAt: delegateIndex) ?? 100
					let heightConstraint = $0.height == height
					// add identifier
					heightConstraint.identifier = Constraint.InnerView.height.id(at: index)
                } else if view is Separator {
                    leadingConstant = separatorLeadingInset
					$0.height == separatorHeight
                } else if let height = wrapperDelegate?.wrapperView(self, heightForInnerViewAt: index) {
					$0.height == height
				}
				
				$0.leading == $1.leading + leadingConstant
			}, config: {
				if let scrollView = ($0 as? WrapperInnerScrollViewType)?.scrollView {
					scrollView.isScrollEnabled = false
                    scrollView.showsVerticalScrollIndicator = false
                    scrollView.showsHorizontalScrollIndicator = false
					self.addObservation(forInnerScrollView: scrollView)
				}
			})

			previousView = view
		}
		
		innerViewsHasAdded = true
	}
    
    private func getDelegateIndex(forCachedViewIndex index: Int) -> Int {
        guard enableSeparator else { return index }
        
        switch separatorStyle {
        case .normal:
            return index / 2
        case .withFirstTop:
            return (index - 1) / 2
        }
    }
	
    private func addObservation(forInnerScrollView scrollView: UIScrollView) {
        innerViewObservations.append(scrollView.observe(\.contentSize, options: .old) { [unowned self] (scrollView, value) in
            guard let oldSize = value.oldValue, scrollView.contentSize != oldSize else { return }
            self.updateContainerContentSize()
            self.setNeedsLayout()
        })
    }
}

extension WrapperView {
	struct Constraint {
		enum Content: String, ConstraintIdentifierable {
			case height
			case top
		}
		
		enum InnerView: String, ConstraintIdentifierable {
			case height
			case top
			
			func id(at index: Int) -> String {
				return identifier + "\(index)"
			}
		}
	}
    
    public enum SeparatorStyle {
        /// at every view's bottom
        case normal
        
        /// at every view's bottom and first view's top
        case withFirstTop
    }
    
    class Separator: UIView {
        init(_ color: UIColor) {
            super.init(frame: .zero)
            backgroundColor = color
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

protocol ConstraintIdentifierable: RawRepresentable where RawValue == String {}

extension ConstraintIdentifierable {
	var identifier: String { "\(Self.self)-\(rawValue)" }
}

protocol ViewChainable {}

extension ViewChainable where Self: UIView {
	typealias ConfigClosure<T> = (T) -> Void
	typealias LayoutClusore<T, V> = (RLayoutKitWrapper<T>, RLayoutKitWrapper<V>) -> Void
	
	@discardableResult
	func added(to superview: UIView,
			   layout layoutClosure: LayoutClusore<Self, UIView>,
			   config: ConfigClosure<Self>? = nil) -> Self {
		rl.added(to: superview, andLayout: layoutClosure)
		config?(self)
		return self
	}
    
    func constraint(for id: String) -> NSLayoutConstraint? {
        return constraints.first { $0.identifier == id }
    }
}

extension UIView: ViewChainable {}
