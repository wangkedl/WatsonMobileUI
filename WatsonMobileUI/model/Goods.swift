//
//  Goods.swift
//  WatsonMobileUI
//
//  Created by ibmuser on 16/7/12.
//  Copyright © 2016年 hangge.com. All rights reserved.
//

import Foundation

class Goods: NSObject {
    
    var id:String = ""
    var name:String = ""
    var price:String = ""
    var details:String = ""
    var imgurl:String = ""
    
    
    init(id:String, name:String, price:String, details:String, imgurl:String)
    {
        self.id = id
        self.name = name
        self.price = price
        self.details = details
        self.imgurl = imgurl
    }

}
