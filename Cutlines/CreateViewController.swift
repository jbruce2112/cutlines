//
//  CreateViewController.swift
//  Cutlines
//
//  Created by John Bruce on 1/31/17.
//  Copyright © 2017 Bruce32. All rights reserved.
//

import UIKit

class CreateViewController: UIViewController {
	
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var captionView: UITextView!
	
	@IBAction func save() {
		
	}
	
	@IBAction func cancel() {
		
		dismiss(animated: true)
	}
}

extension CreateViewController: UIBarPositioningDelegate {
	
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		return .topAttached
	}
}
