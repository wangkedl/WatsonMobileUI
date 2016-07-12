//
//  TableViewItemCell.swift
//  WatsonMobileUI
//
//  Created by ibmuser on 16/7/8.
//  Copyright © 2016年 hangge.com. All rights reserved.
//

import UIKit

class TableViewItemCell: UITableViewCell {
    
    var msgItem:MessageItem!
    
    init(data:MessageItem, reuseIdentifier cellId:String)
    {
        self.msgItem = data
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier:cellId)
        rebuildUserInterface()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func rebuildUserInterface()
    {
        let cellView:UIView = self.msgItem.view!

        self.addSubview(cellView)
        self.layer.borderWidth = 1
        self.contentView.alpha = 0.6
        self.alpha = 0.3
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        
    }
    
    // 设定单元格高度宽度
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            super.frame = CGRectMake(newFrame.origin.x + 70, newFrame.origin.y,newFrame.width - 150, newFrame.height)
        }
    }
    
}
