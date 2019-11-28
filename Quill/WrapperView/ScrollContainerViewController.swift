//
//  ScrollContainerViewController.swift
//  WebContainer
//
//  Created by roy on 2019/11/25.
//  Copyright © 2019 xiaoman. All rights reserved.
//

import UIKit
import WebKit

class ScrollContainerViewController: UIViewController {
    private var webView = WKWebView(frame: .zero, configuration: .init())
	private var webView1 = WKWebView(frame: .zero, configuration: .init())
	private var tableView = UITableView()
    
    private let header = UIView()
	private let header1 = UIView()
	private let wrapper = WrapperView(frame: .zero)
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        constraintSubviews()
        
        let url = URL(string: "https://www.okki.com/zh-cn/")!
        webView.load(.init(url: url))
		
        let url1 = URL(string: "https://www.pgyer.com/ooUz")!
		webView1.load(.init(url: url1))
    }
    
    private func constraintSubviews() {
        header.heightAnchor.constraint(equalToConstant: 300).isActive = true
        header.backgroundColor = .systemBlue
		
		header1.heightAnchor.constraint(equalToConstant: 400).isActive = true
        header1.backgroundColor = .systemBlue
        
        tableView.dataSource = self
        tableView.rowHeight = 50
        tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
        
		wrapper.added(to: view, activateLayoutContraints: {
			let constraints = [
				$0.leadingAnchor.constraint(equalTo: $1.leadingAnchor),
				$0.trailingAnchor.constraint(equalTo: $1.trailingAnchor),
				$0.bottomAnchor.constraint(equalTo: $1.bottomAnchor)
			]
			
			let topConstraint: NSLayoutConstraint
			
			if #available(iOS 11.0, *) {
				topConstraint = $0.topAnchor.constraint(equalTo: $1.safeAreaLayoutGuide.topAnchor)
			} else {
				topConstraint = $0.topAnchor.constraint(equalTo: $1.topAnchor)
			}
			
			return constraints + [topConstraint]
		}, config: {
            $0.enableSeparator = true
            $0.separatorColor = .black
            $0.separatorHeight = 10
            $0.separatorStyle = .withFirstTop
			$0.dataSource = self
		})
    }
}

extension ScrollContainerViewController: WrapperViewDataSource {
	var numberOfInnerViews: Int {
		5
	}
	
	func wrapperView(_ wrapperView: WrapperView, innerViewAt index: Int) -> UIView {
		switch index {
		case 0:
			return header
		case 1:
			return webView1
        case 2:
            return tableView
		case 3:
			return header1
		default:
			return webView
		}
	}
}

extension ScrollContainerViewController: UITableViewDataSource {
    class Cell: UITableViewCell {
        private var count: Int = 0
        
        func config(_ text: String) {
            textLabel?.text = text + "  count: \(count)"
            count += 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 200
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! Cell
        cell.config("row: \(indexPath.row)")
        
        return cell
    }
}
