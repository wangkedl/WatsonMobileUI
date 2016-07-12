import UIKit

enum ChatType
{
    case Mine
    case Someone
    case GoodsList
    case Wait
}

class MessageItem
{
    var user:UserInfo?
    var text:String?
    var mtype:ChatType
    var view:UIView?
    var insets:UIEdgeInsets?
    var goods:Goods?
    
    
    class func getTextInsetsMine() -> UIEdgeInsets
    {
        return UIEdgeInsets(top:5, left:10, bottom:11, right:17)
    }
    
    class func getTextInsetsItemList() -> UIEdgeInsets
    {
        return UIEdgeInsets(top:5, left:10, bottom:11, right:17)
    }
    
    class func getTextInsetsSomeone() -> UIEdgeInsets
    {
        return UIEdgeInsets(top:5, left:15, bottom:11, right:10)
    }
    class func getImageInsetsMine() -> UIEdgeInsets
    {
        return UIEdgeInsets(top:11, left:13, bottom:16, right:22)
    }
    class func getImageInsetsSomeone() -> UIEdgeInsets
    {
        return UIEdgeInsets(top:11, left:13, bottom:16, right:22)
    }
    
    init(user:UserInfo?, mtype:ChatType, view:UIView, insets:UIEdgeInsets, text:String?)
    {
        self.view = view
        self.user = user
        self.mtype = mtype
        self.insets = insets
        self.text = text
    }
    
    init(user:UserInfo?, mtype:ChatType, view:UIView, insets:UIEdgeInsets)
    {
        self.view = view
        self.user = user
        self.mtype = mtype
        self.insets = insets
    }

    
    init(goods:Goods?, mtype:ChatType)
    {
        self.goods = goods
        self.mtype = mtype
    }

    
    // 文字类型消息
    convenience init(body:NSString, user:UserInfo, date:NSDate, mtype:ChatType)
    {
        let font = UIFont.systemFontOfSize(16)
        let width = 200, height = 10000.0
        
        let atts = [NSFontAttributeName: font]
        let size = body.boundingRectWithSize(CGSizeMake(CGFloat(width), CGFloat(height)), options:NSStringDrawingOptions.UsesLineFragmentOrigin, attributes:atts, context:nil)
        let label = UILabel(frame:CGRectMake(0, 0, size.size.width, size.size.height))
        
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text = (body.length != 0 ? body as String : "")
        label.font = font
        label.backgroundColor = UIColor.clearColor()
        
        let insets:UIEdgeInsets =  (mtype == ChatType.Mine ? MessageItem.getTextInsetsMine() : MessageItem.getTextInsetsSomeone())
        self.init(user:user, mtype:mtype, view:label, insets:insets)
    }
    
    // 图片类型消息
    convenience init(image:UIImage, user:UserInfo,  date:NSDate, mtype:ChatType)
    {
        var size = image.size
        //等比缩放
        if (size.width > 180)
        {
            size.height /= (size.width / 180);
            size.width = 180;
        }
        let imageView = UIImageView(frame:CGRectMake(0, 0, size.width, size.height))
        imageView.image = image
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        
        let insets:UIEdgeInsets =  (mtype == ChatType.Mine ? MessageItem.getImageInsetsMine() : MessageItem.getImageInsetsSomeone())
        
        self.init(user:user, mtype:mtype, view:imageView, insets:insets, text:nil)
    }
    
    // 商品一览
//    convenience init(date:NSDate, mtype:ChatType)
//    {
//       
//    }
}