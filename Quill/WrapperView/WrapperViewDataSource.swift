//
//  WrapperViewDataSource.swift
//  WebContainer
//
//  Created by roy on 2019/11/25.
//  Copyright © 2019 royite. All rights reserved.
//

import UIKit
import WebKit.WKWebView

public protocol WrapperInnerScrollViewType: UIView {
	var scrollView: UIScrollView { get }
}

extension UIScrollView: WrapperInnerScrollViewType {
	public var scrollView: UIScrollView { self }
}

extension WKWebView: WrapperInnerScrollViewType {}

public protocol WrapperViewDataSource: class {
	var numberOfInnerViews: Int { get }
	
	func wrapperView(_ wrapperView: WrapperView, innerViewAt index: Int) -> UIView
}

public protocol WrapperViewDelegate: class {
	func wrapperView(_ wrapperView: WrapperView, heightForInnerViewAt index: Int) -> CGFloat
}

extension WrapperViewDelegate {
	public func wrapperView(_ wrapperView: WrapperView, heightForInnerViewAt index: Int) -> CGFloat {
		return 50
	}
}
