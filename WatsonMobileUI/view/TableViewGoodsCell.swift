//
//  TableViewGoodsCell.swift
//  WatsonMobileUI
//
//  Created by ibmuser on 16/7/6.
//  Copyright © 2016年. All rights reserved.
//

import UIKit

class TableViewGoodsCell: UITableViewCell {
    
    init(data:MessageItem, reuseIdentifier cellId:String)
    {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier:cellId)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // 让单元格宽度始终为屏幕宽
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame = newFrame
            frame.size.width = UIScreen.mainScreen().bounds.width
            super.frame = CGRectMake(frame.origin.x + 40,frame.origin.y,250,frame.height)
        }
    }
    
}
