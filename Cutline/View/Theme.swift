//
//  Theme.swift
//  Cutline
//
//  Created by John on 2/19/17.
//  Copyright © 2017 Bruce32. All rights reserved.
//

import UIKit


/// Theme contains all properties that define
/// a UI theme for the application. Theme.swift
/// contains a number of extensions for common UIKit
/// types that set view properties using the current theme.
class Theme: NSObject {
	
	var backgroundColor: UIColor!
	var altBackgroundColor: UIColor!
	var textColor: UIColor!
	var accentColor: UIColor!
	var barStyle: UIBarStyle!
	var isNight = false
	var keyboard: UIKeyboardAppearance!
}

extension UIViewController {
	
	/// Gets the current theme and sets
	/// the properties on the controller's view.
	/// Note: Since extensions cannot override
	/// functions, view controllers need to
	/// manually call setTheme() during their setup.
	func setTheme() {
		setTheme(view.theme())
	}
	
	func setTheme(_ theme: Theme) {
		view.setTheme(theme)
	}
}

extension UIView {
	
	func setTheme() {
		setTheme(theme())
	}
	
	func setTheme(_ theme: Theme) {
		backgroundColor = theme.backgroundColor
	}
	
	func theme() -> Theme {
		
		let theme = Theme()
		
		if appGroupDefaults.bool(forKey: PrefKey.nightMode) {
			
			theme.isNight = true
			theme.backgroundColor = .black
			theme.altBackgroundColor = UIColor(colorLiteralRed: 25.0 / 255.0, green: 25.0 / 225.0, blue: 25.0 / 225.0, alpha: 1.0)
			theme.textColor = tintColor
			theme.accentColor = .white
			theme.barStyle = .black
			theme.keyboard = .dark
		} else {
			
			theme.isNight = false
			theme.backgroundColor = .white
			theme.altBackgroundColor = UIColor(colorLiteralRed: 239.0 / 255.0, green: 239.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
			theme.textColor = .black
			theme.accentColor = .blue
			theme.barStyle = .default
			theme.keyboard = .default
		}
		
		return theme
	}
}

extension UITabBar {
	
	override func setTheme(_ theme: Theme) {
		barStyle = theme.barStyle
	}
}

extension UINavigationBar {
	
	override func setTheme(_ theme: Theme) {
		barStyle = theme.barStyle
	}
}

extension UIToolbar {
	
	override func setTheme(_ theme: Theme) {
		barStyle = theme.barStyle
	}
}

extension UITableViewCell {
	
	override func setTheme(_ theme: Theme) {
		super.setTheme(theme)
		
		textLabel?.textColor = theme.textColor
		
		let selectedView = UIView()
		selectedView.backgroundColor = theme.altBackgroundColor
		
		selectedBackgroundView = selectedView
	}
}
