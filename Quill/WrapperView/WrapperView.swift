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
	private var cachedViews = [CachedView]()
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
			switch $1 {
			case let .innerScroll(inner, _):
				return $0 + inner.scrollView.contentSize.height
			case .normal(let view):
				return $0 + view.bounds.height
			}
        })
    }
    
    private func layoutWrapperView() {
        updateContentViewLayout()
        
        guard !cachedViews.isEmpty else { return }
        
        var previousView: UIView?
        let offsetY = contentOffset.y
        let contentViewHeight = contentView.bounds.height
		
		cachedViews.enumerated().forEach { index, cachedView in
			switch cachedView {
			case .normal(let view):
				previousView = view
			case let .innerScroll(inner, scroll):
				let innerHeight = scroll.bounds.height
				let minY = previousView?.frame.maxY ?? 0
				let innerContentHeight = inner.scrollView.contentSize.height
				let innerScrollOffsetY = offsetY - minY
				
				switch innerScrollOffsetY {
				case let innerOffsetY where innerOffsetY < 0:
					if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
						top.constant = 0
					}
					
					// adjust inner scroll height
					if let heightConstraint = scroll.constraint(for: Constraint.InnerView.height.id(at: index)) {
						let height = max(contentViewHeight, contentViewHeight + innerOffsetY)
						heightConstraint.constant = min(height, innerContentHeight)
					}
					
					inner.scrollView.contentOffset.y = 0
				case let innerOffsetY where 0 <= innerOffsetY && innerOffsetY < innerContentHeight:
					let maxInnerOffsetY = innerContentHeight - innerHeight
					let y = min(innerOffsetY, maxInnerOffsetY)
					if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
						top.constant = y
					}
					
					inner.scrollView.contentOffset.y = y
				default:
					if let top = contentView.constraint(for: Constraint.InnerView.top.id(at: index)) {
						top.constant = max(0, innerContentHeight - contentViewHeight)
					}
					
					inner.scrollView.contentOffset.y = innerContentHeight - innerHeight
				}
				
				previousView = scroll
			}
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
			cachedViews = (0..<dataSource.numberOfInnerViews)
				.map {
					let innerView = dataSource.wrapperView(self, innerViewAt: $0)
					if let inner = innerView as? WrapperInnerScrollViewType {
						return .innerScroll(inner: inner, scroll: UIScrollView())
					} else {
						return .normal(innerView)
					}
			}
		}
        
		guard !cachedViews.isEmpty else { return }
		
        if enableSeparator {
            // TODO: <Roy> Separator reuse
            var withSeparatorsViews: [CachedView] = cachedViews.reduce([]) {
				return $0 + [$1, .normal(Separator(separatorColor))]
            }
            
            if separatorStyle == .withFirstTop {
                withSeparatorsViews.insert(.normal(Separator(separatorColor)), at: 0)
            }
            
            cachedViews = withSeparatorsViews
        }
        
		addContentView()
		
		var previousView: UIView?
		
		cachedViews.enumerated().forEach { index, cachedView in
			let addedView: UIView
			
			// leading & height
			var leadingConstant: CGFloat = 0
			let delegateIndex = getDelegateIndex(forCachedViewIndex: index)
			
			switch cachedView {
			case let .innerScroll(inner, scroll):
                (inner as UIView).added(to: scroll, layout: {
                    ($0.leading == $1.leading).identifier = Constraint.InnerScrollTypeView.leading.identifier
                    $0.top == $1.top
                    $0.size == $1.size
                })
				
				scroll.added(to: contentView, layout: {
					// trailing
					$0.trailing == $1.trailing
					
					// height
					let height = wrapperDelegate?.wrapperView(self, heightForInnerViewAt: delegateIndex) ?? 100
					let heightConstraint = $0.height == height
					heightConstraint.identifier = Constraint.InnerView.height.id(at: index)
				})
				
				scroll.backgroundColor = .purple
				
				inner.scrollView.isScrollEnabled = false
				inner.scrollView.showsVerticalScrollIndicator = false
				inner.scrollView.showsHorizontalScrollIndicator = false
				addObservation(forInnerScrollView: inner.scrollView, at: index)
				scroll.delegate = self
				scroll.tag = index
				addedView = scroll
			case .normal(let inner):
				inner.added(to: contentView, layout: {
					// trailing
					$0.trailing == $1.trailing
					
					// height
					if inner is Separator {
						leadingConstant = separatorLeadingInset
						$0.height == separatorHeight
					} else if let height = wrapperDelegate?.wrapperView(self, heightForInnerViewAt: index) {
						$0.height == height
					}
				})
				addedView = inner
			}
			
			addedView.rl.layout {
				// top
				let topConstraint: NSLayoutConstraint
				if let previous = previousView {
					topConstraint = $0.top == previous.rl.bottom
				} else {
					topConstraint = $0.top == contentView.rl.top
				}

                topConstraint.identifier = Constraint.InnerView.top.id(at: index)
				
				$0.leading == contentView.rl.leading + leadingConstant
			}

			previousView = addedView
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
	
	private func addObservation(forInnerScrollView scrollView: UIScrollView, at index: Int) {
        innerViewObservations.append(scrollView.observe(\.contentSize, options: .old) { [unowned self] (scrollView, value) in
            guard let oldSize = value.oldValue, scrollView.contentSize != oldSize else { return }
            self.updateContainerContentSize()
			
            if scrollView.isZooming {
                self.updateBackScrollContentSize(at: index)
            }
            
            self.log("inner scroll contentSize: \(scrollView.contentSize)")
            self.setNeedsLayout()
        })
    }
	
	private func log(_ s: String) {
		print("log -> \(s)")
	}

	private func updateBackScrollContentSize(at index: Int) {
		guard case let .innerScroll(inner, scroll) = cachedViews[index] else { return }
			
		scroll.contentSize.width = inner.scrollView.contentSize.width
	}
}

extension WrapperView: UIScrollViewDelegate {
	public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		guard
			case let .innerScroll(inner, scroll) = cachedViews[scrollView.tag],
			scroll === scrollView
			else {
				return
		}
		
		if inner.scrollView.contentOffset.x != scrollView.contentOffset.x {
			scrollView.contentOffset.x = inner.scrollView.contentOffset.x
		}
	}
	
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard
			case let .innerScroll(inner, scroll) = cachedViews[scrollView.tag],
			scroll === scrollView,
			let leadingConstraint = scroll.constraint(for: Constraint.InnerScrollTypeView.leading.identifier)
			else {
				return
		}
		
		let offsetX = scroll.contentOffset.x
		leadingConstraint.constant = offsetX
		inner.scrollView.contentOffset.x = offsetX
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
		
		enum InnerScrollTypeView: String, ConstraintIdentifierable {
			case leading
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
	
	enum CachedView {
		case normal(UIView)
		case innerScroll(inner: WrapperInnerScrollViewType, scroll: UIScrollView)
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
