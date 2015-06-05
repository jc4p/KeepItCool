//
//  KRCollectionViewItem.swift
//  KeepItCool
//
//  Created by Kasra Rahjerdi on 5/31/15.
//  Copyright (c) 2015 Kasra Rahjerdi. All rights reserved.
//

import UIKit

class KRCollectionViewItem: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    func setText(text: String) {
        textLabel.text = text;
    }
}