import UIKit

class TableViewCell:UITableViewCell
{
    var customView:UIView!
    var bubbleImage:UIImageView!
    var avatarImage:UIImageView!
    var msgItem:MessageItem!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(data:MessageItem, reuseIdentifier cellId:String)
    {
        self.msgItem = data
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier:cellId)
        rebuildUserInterface()
    }
    
    func rebuildUserInterface()
    {
        self.selectionStyle = UITableViewCellSelectionStyle.None
        if (self.bubbleImage == nil)
        {
            self.bubbleImage = UIImageView()
            self.addSubview(self.bubbleImage)
        }
        
        let type =  self.msgItem.mtype
        let width =  self.msgItem.view.frame.size.width
        let height =  self.msgItem.view.frame.size.height
        print(height)
        
        var x =  (type == ChatType.Someone) ? 0 : self.frame.size.width - width - self.msgItem.insets.left - self.msgItem.insets.right
        var y:CGFloat =  0

        if (self.msgItem.user.username != "")
        {
            let thisUser =  self.msgItem.user
            self.avatarImage = UIImageView(image:UIImage(named:(thisUser.avatar != "" ? thisUser.avatar : "noAvatar.png")))
            self.avatarImage.layer.cornerRadius = 9.0
            self.avatarImage.layer.masksToBounds = true
            
            // calculate the x position
            let avatarX =  (type == ChatType.Someone) ? 2 : self.frame.size.width - 52
            
            // set the frame correctly
            self.avatarImage.frame = CGRectMake(avatarX, 0, 50, 50)
            print(self.avatarImage.frame )
            self.addSubview(self.avatarImage)
            
            let delta =  self.frame.size.height - (self.msgItem.insets.top + self.msgItem.insets.bottom + self.msgItem.view.frame.size.height)
            if (delta > 0)
            {
                y = delta
            }
            if (type == ChatType.Someone)
            {
                x += 54
            }
            if (type == ChatType.Mine)
            {
                x -= 54
            }
        }

        
        self.customView = self.msgItem.view
        self.customView.frame = CGRectMake(x + self.msgItem.insets.left, y + self.msgItem.insets.top, width, height)
        self.addSubview(self.customView)
        
        // depending on the ChatType a bubble image on the left or right
        if (type == ChatType.Someone)
        {
            self.bubbleImage.image = UIImage(named:("message_left.png"))!.stretchableImageWithLeftCapWidth(15,topCapHeight:20)
            
        }
        else {
            self.bubbleImage.image = UIImage(named:"message_right.png")!.stretchableImageWithLeftCapWidth(15, topCapHeight:14)
        }
        self.bubbleImage.frame = CGRectMake(x, y, width + self.msgItem.insets.left + self.msgItem.insets.right, height + self.msgItem.insets.top + self.msgItem.insets.bottom)
    }
    
    // 让单元格宽度始终为屏幕宽
    override var frame: CGRect {
        get {
            return super.frame
        }
        set (newFrame) {
            var frame = newFrame
            frame.size.width = UIScreen.mainScreen().bounds.width
            super.frame = frame
        }
    }
}
