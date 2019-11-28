//
//  EditorViewController.swift
//  Quill
//
//  Created by roy on 2019/11/28.
//  Copyright © 2019 royite. All rights reserved.
//

import UIKit
import RLayoutKit

class EditorViewController: UIViewController {
	private let editor = Editor(frame: .zero)
	private let wrapper = WrapperView(frame: .zero)
	private let header = UIView(frame: .zero)
	private let footer = UIView(frame: .zero)
	
    override func viewDidLoad() {
        super.viewDidLoad()

        constructViewHierarchyAndConstraint()
    }
	
	private func constructViewHierarchyAndConstraint() {
		wrapper.rl.added(to: view)  {
			$0.edges == $1.edges
		}
		
		wrapper.dataSource = self
		wrapper.wrapperDelegate = self
		
		header.backgroundColor = .systemBlue
		footer.backgroundColor = .systemBlue
	}
}

extension EditorViewController: WrapperViewDataSource {
	var numberOfInnerViews: Int { 3 }
	
	func wrapperView(_ wrapperView: WrapperView, innerViewAt index: Int) -> UIView {
		switch index {
		case 0:
			return header
		case 1:
			return editor
		default:
			return footer
		}
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
