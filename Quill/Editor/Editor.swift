//
//  Editor.swift
//  Quill
//
//  Created by roy on 2019/11/12.
//  Copyright © 2019 royite. All rights reserved.
//

import UIKit
import WebKit
import RLayoutKit

class Editor: UIView, WrapperInnerScrollViewType {
	var scrollView: UIScrollView { webView.scrollView }
	
	/// content
	private var webView: WKWebView
	private var hasConstructWeb = false
	
	override init(frame: CGRect) {
		let config = WKWebViewConfiguration()
		config.preferences = .init()
//		config.preferences.javaEnabled = true
		config.preferences.javaScriptCanOpenWindowsAutomatically = true
//		config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
		config.processPool = .init()
		let userContentController = WKUserContentController()
		config.userContentController = userContentController
		
		webView = WKWebView(frame: .zero, configuration: config)
		super.init(frame: frame)
		
		constructViewHierarchyAndConstraint()
		try? loadQuill()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func constructViewHierarchyAndConstraint() {
		webView.rl.added(to: self, andLayout: {
			$0.edges == $1.edges
		})
	}
	
	private func loadQuill() throws {
		let coreBundleUrl = try coreBundleURL()
		
		guard
			let coreBundle = Bundle(url: coreBundleUrl)
		else {
			fatalError("load local bundle failure")
		}
		
		guard
			let htmlUrl = coreBundle.url(forResource: "snow", withExtension: "html", subdirectory: "examples")
		else {
			fatalError("load local localHTML failure")
		}
		
		let request = URLRequest(url: htmlUrl)
		webView.load(request)
	}
	
	private func coreBundleURL() throws -> URL {
		class LocalClass {}
		let bundle = Bundle(for: LocalClass.self)
		let coreBundleName = "core"
		
		guard
			let coreBundle = bundle.url(forResource: coreBundleName, withExtension: "bundle")
		else {
			fatalError("has not find url for bundle:\(coreBundleName)")
		}
		
		return coreBundle
	}
}
