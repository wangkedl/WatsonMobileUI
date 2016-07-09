import UIKit

enum ChatBubbleTypingType
{
    case Nobody
    case Me
    case Somebody
}

class TableView:UITableView,UITableViewDelegate, UITableViewDataSource
{
    
    var bubbleSection:NSMutableArray!
    var chatDataSource:ChatDataSource!
    
    var  snapInterval:NSTimeInterval!
    var  typingBubble:ChatBubbleTypingType!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        self.snapInterval = 60 * 60 * 24;
        self.typingBubble = ChatBubbleTypingType.Nobody
        self.bubbleSection = NSMutableArray()
        
        super.init(frame:frame, style:style)
        self.backgroundColor = UIColor.clearColor()
        self.separatorStyle = UITableViewCellSeparatorStyle.None
        self.delegate = self
        self.dataSource = self
    }
    
    // 重新刷新TableView
    override func reloadData()
    {
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        super.reloadData()
        
        // 滑向最后一部分
        let row = self.chatDataSource.rowsForChatTable(self) - 1
        let indexPath =  NSIndexPath(forRow: row, inSection: 0)
        self.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Bottom,animated:true)
    }
    
    func numberOfSectionsInTableView(tableView:UITableView)->Int
    {

        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {

        return self.chatDataSource.rowsForChatTable(self)

    }
    
    func tableView(tableView:UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat
    {
        
        let item:MessageItem = self.chatDataSource.chatTableView(self, dataForRow:indexPath.row)
        var height:CGFloat = 40
        if(item.mtype == ChatType.Mine ||  item.mtype == ChatType.Someone){
            height  = item.insets.top + max(item.view.frame.size.height, 52) + item.insets.bottom
        }
        return height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {

        let data:MessageItem = self.chatDataSource.chatTableView(self, dataForRow:indexPath.row)
        
        // 标准聊天Cell
        if(data.mtype == ChatType.Mine ||  data.mtype == ChatType.Someone){
            let cellId = "ChatCell"
            let cell = TableViewCell(data:data, reuseIdentifier:cellId)
            cell.backgroundColor = UIColor.clearColor()
            return cell
        }
        // 标准选择一览Cell
        else if(data.mtype == ChatType.ItemList){
            let cellId = "ItemCell"
            let cell = TableViewItemCell(data:data, reuseIdentifier: cellId)
            return cell
        }
         // 标准商品一览Cell
        else{
            let cellId = "ChatCell"
            let cell = TableViewGoodsCell(data:data, reuseIdentifier: cellId)
            cell.backgroundColor = UIColor.whiteColor()
            cell.layer.borderWidth = 1
            cell.contentView.alpha = 0.6
            cell.layer.borderColor = UIColor.lightGrayColor().CGColor
            cell.contentView.frame = CGRectMake(50, 50, 50, 30)
            cell.textLabel!.text = "tetst"
            cell.imageView?.image = UIImage(named: "pictures")
            return cell
        }
        
    }
}
