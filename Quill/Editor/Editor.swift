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
import PromiseKit

func DLOG(f: String = #function, line: Int = #line, message: @autoclosure () -> Any) {
	print("Editor f: \(f), at line: \(line) msg: \(message())")
}

class Editor: UIView, WrapperInnerScrollViewType {
	var scrollView: UIScrollView { webView.scrollView }
	
	/// content
	private let webView: WKWebView
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
		webView.setKeyboardRequiresUserInteraction(false)
		
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
			let htmlUrl = coreBundle.url(forResource: "okki", withExtension: "html", subdirectory: "examples")
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

extension Editor {
	enum EvaluateJavaScriptError: Error {
		case error(Error)
		case formateResultType
		case noneResult
	}

	typealias JSResult<T> = Swift.Result<T, EvaluateJavaScriptError>
	typealias EvalJSCompletion<T> = (JSResult<T>) -> Void
	private func evaJS<T>(_ js: String, _ completion: @escaping EvalJSCompletion<T> = { _ in }) {
		print("evaluateJavaScript: \(js)")
		webView.evaluateJavaScript(js) {
			guard T.self != Void.self else { return }
			
			if let error = $1 {
				completion(.failure(.error(error)))
				return
			}
			
			guard let value = $0 else {
				completion(.failure(.noneResult))
				return
			}
			
			guard let result = value as? T else {
				completion(.failure(.formateResultType))
				return
			}
			
			completion(.success(result))
		}
	}
	
	private func evaJSVoid(_ js: String, _ completion: EvalJSCompletion<Void>? = nil) {
		if let closure = completion {
			evaJS(js, closure)
		} else {
			let v: EvalJSCompletion<Void> = { _ in }
			evaJS(js, v)
		}
	}
	
	private func js(_ s: String = #function) -> String {
		s + ";"
	}
	
	// Void
	func focus() {
		evaJSVoid(js())
	}
	
	func setText() {
		evaJSVoid(js())
	}
	
	// Bool
	func hasFocus() -> Guarantee<Bool> {
		.init { seal in
			self.evaJS(js()) { (r: JSResult<Bool>) in
				switch r {
				case .success(let value):
					seal(value)
				case .failure(let error):
					DLOG(message: error)
					seal(false)
				}
			}
		}
	}
}
