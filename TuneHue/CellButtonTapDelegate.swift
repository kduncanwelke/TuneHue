//
//  CellButtonTapDelegate.swift
//  MusicHue
//
//  Created by Kate Duncan-Welke on 9/11/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation

// handle tap on cell
protocol CellButtonTapDelegate: class {
	func didTapButton(sender: ColorTableViewCell)
}
