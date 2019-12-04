//
//  ViewController.swift
//  Quill
//
//  Created by roy on 2019/11/28.
//  Copyright © 2019 royite. All rights reserved.
//

import UIKit
import RLayoutKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		addButton()
	}
	
	private func addButton() {
		let button = UIButton()
		button.addTarget(self, action: #selector(showEditor), for: .touchUpInside)
		button.setTitle("Editor", for: .normal)
//		button.setTitleColor(.black, for: .normal)
		
		button.rl.added(to: view) {
			$0.center == $1.center
			$0.size == CGSize(width: 100, height: 60)
		}
	}
}

extension ViewController {
	@objc
	private func showEditor() {
		let controller = EditorViewController(nibName: nil, bundle: nil)
		show(controller, sender: nil)
	}
}
