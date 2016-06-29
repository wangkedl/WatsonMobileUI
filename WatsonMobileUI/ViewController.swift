import UIKit

class ViewController: UIViewController, ChatDataSource,UITextFieldDelegate {
    
    var Chats:NSMutableArray!
    var tableView:TableView!
    var me:UserInfo!
    var you:UserInfo!
    var txtMsg:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChatTable()
        setupSendPanel()
    }
    
    func setupSendPanel()
    {
        let screenWidth = UIScreen.mainScreen().bounds.width
        let sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 56,screenWidth,56))
        
        sendView.backgroundColor=UIColor.lightGrayColor()
        sendView.alpha=0.9
        
        txtMsg = UITextField(frame:CGRectMake(7,10,screenWidth - 95,36))
        txtMsg.backgroundColor = UIColor.whiteColor()
        txtMsg.textColor=UIColor.blackColor()
        txtMsg.font=UIFont.boldSystemFontOfSize(12)
        txtMsg.layer.cornerRadius = 10.0
        txtMsg.returnKeyType = UIReturnKeyType.Send
        
        //Set the delegate so you can respond to user input
        txtMsg.delegate=self
        sendView.addSubview(txtMsg)
        self.view.addSubview(sendView)
        
        let sendButton = UIButton(frame:CGRectMake(screenWidth - 80,10,72,36))
        sendButton.backgroundColor=UIColor(red: 0x37/255, green: 0xba/255, blue: 0x46/255, alpha: 1)
        sendButton.addTarget(self, action:#selector(ViewController.sendMessage) ,
                             forControlEvents:UIControlEvents.TouchUpInside)
        sendButton.layer.cornerRadius=6.0
        sendButton.setTitle("发送", forState:UIControlState.Normal)
        sendView.addSubview(sendButton)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool
    {
        sendMessage()
        return true
    }
    
    func sendMessage()
    {
        //composing=false
        let sender = txtMsg
        let thisChat =  MessageItem(body:sender.text!, user:me, date:NSDate(), mtype:ChatType.Mine)
        let thatChat =  MessageItem(body:"你说的是：\(sender.text!)", user:you, date:NSDate(), mtype:ChatType.Someone)
        
        Chats.addObject(thisChat)
        Chats.addObject(thatChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
        
        //self.showTableView()
        sender.resignFirstResponder()
        sender.text = ""
    }
    
    func setupChatTable()
    {
        self.tableView = TableView(frame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 76), style: .Plain)
        
        //创建一个重用的单元格
        self.tableView!.registerClass(TableViewCell.self, forCellReuseIdentifier: "ChatCell")
        me = UserInfo(name:"Xiaoming" ,logo:("xiaoming.png"))
        you  = UserInfo(name:"Xiaohua", logo:("xiaohua.png"))
        
        
        let first =  MessageItem(body:"嘿，这张照片咋样，我在泸沽湖拍的呢！", user:me,  date:NSDate(timeIntervalSinceNow:-600), mtype:ChatType.Mine)
        
        let second =  MessageItem(image:UIImage(named:"luguhu.jpeg")!,user:me, date:NSDate(timeIntervalSinceNow:-290), mtype:ChatType.Mine)
        
        let third =  MessageItem(body:"太赞了，我也想去那看看呢！",user:you, date:NSDate(timeIntervalSinceNow:-60), mtype:ChatType.Someone)
        
        let fouth =  MessageItem(body:"嗯，下次我们一起去吧！",user:me, date:NSDate(timeIntervalSinceNow:-20), mtype:ChatType.Mine)
        
        let fifth =  MessageItem(body:"好的，一定！",user:you, date:NSDate(timeIntervalSinceNow:0), mtype:ChatType.Someone)
        
        let zero =  MessageItem(body:"最近去哪玩了？", user:you,  date:NSDate(timeIntervalSinceNow:-96400), mtype:ChatType.Someone)
        
        let zero1 =  MessageItem(body:"去了趟云南，明天发照片给你哈？", user:me,  date:NSDate(timeIntervalSinceNow:-86400), mtype:ChatType.Mine)
        
        Chats = NSMutableArray()
        Chats.addObjectsFromArray([first,second, third, fouth, fifth, zero, zero1])
        
        //set the chatDataSource
        self.tableView.chatDataSource = self
        
        //call the reloadData, this is actually calling your override method
        self.tableView.reloadData()
        
        self.view.addSubview(self.tableView)
    }
    
    func rowsForChatTable(tableView:TableView) -> Int
    {
        return self.Chats.count
    }
    
    func chatTableView(tableView:TableView, dataForRow row:Int) -> MessageItem
    {
        return Chats[row] as! MessageItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}