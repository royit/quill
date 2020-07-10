//
//  EditorViewController.swift
//  Quill
//
//  Created by roy on 2019/11/28.
//  Copyright © 2019 royite. All rights reserved.
//

import UIKit
import RLayoutKit
import WebKit

class EditorViewController: UIViewController {
	private let editor = Editor(frame: .zero)
	private let wrapper = WrapperView(frame: .zero)
	private let header = UIView(frame: .zero)
	private let footer = UIView(frame: .zero)
	private var webView = WKWebView(frame: .zero, configuration: .init())
	private var webView1 = WKWebView(frame: .zero, configuration: .init())
	private var tableView = UITableView()
	private let header1 = UIView()
	
	
    override func viewDidLoad() {
        super.viewDidLoad()

        constructViewHierarchyAndConstraint()
		let url = URL(string: "https://www.okki.com/zh-cn/")!
        webView.load(.init(url: url))
		
        let url1 = URL(string: "https://www.pgyer.com/ooUz")!
		webView1.load(.init(url: url1))
    }
	
	private func constructViewHierarchyAndConstraint() {
		wrapper.rl.added(to: view)  {
			$0.edges == $1.safeAreaEdges
		}
		
		wrapper.enableSeparator = true
		wrapper.separatorColor = .black
		wrapper.separatorHeight = 1
		wrapper.separatorStyle = .withFirstTop
		wrapper.dataSource = self
		wrapper.wrapperDelegate = self
		wrapper.keyboardDismissMode = .onDrag
		
		header.backgroundColor = .systemBlue
		footer.backgroundColor = .systemBlue

        header.heightAnchor.constraint(equalToConstant: 300).isActive = true
        header.backgroundColor = .systemBlue
		
		header1.heightAnchor.constraint(equalToConstant: 400).isActive = true
        header1.backgroundColor = .systemBlue
        
        tableView.dataSource = self
		tableView.delegate = self
        tableView.rowHeight = 50
        tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
    }
}

extension EditorViewController: WrapperViewDelegate {
	func wrapperView(_ wrapperView: WrapperView, heightForInnerViewAt index: Int) -> CGFloat {
		switch index {
		case 0, 2:
			return 100
		default:
			return 200
		}
	}
}

extension EditorViewController: WrapperViewDataSource {
	var numberOfInnerViews: Int {
		3
	}
	
	func wrapperView(_ wrapperView: WrapperView, innerViewAt index: Int) -> UIView {

		switch index {
		case 0:
			return header
		case 1:
			return editor
		case 2:
			return tableView
		case 3:
			return webView1
		case 4:
			return webView
		case 5:
			return footer
		default:
			return header1
		}
	}
}

extension EditorViewController: UITableViewDataSource {
    class Cell: UITableViewCell {
        private var count: Int = 0
        
        func config(_ text: String) {
            textLabel?.text = text + "  count: \(count)"
            count += 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! Cell
        cell.config("row: \(indexPath.row)")
        
        return cell
    }
}

extension EditorViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch indexPath.row {
		case 0:
			editor.focus()
		case 1:
			editor.hasFocus().done {
				print("has focus: \($0)")
			}
		case 2:
			editor.setText()
		default:
			break
		}
	}
}
