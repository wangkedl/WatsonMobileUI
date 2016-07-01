import UIKit

class ViewController: UIViewController, ChatDataSource,UITextFieldDelegate {
    
    var Chats:NSMutableArray!
    var tableView:TableView!
    var me:UserInfo!
    var Watson:UserInfo!
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
        
        sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        sendView.layer.cornerRadius = 6.0
        
        txtMsg = UITextField(frame:CGRectMake(42,10,screenWidth - 95,36))
        txtMsg.backgroundColor = UIColor.whiteColor()
        txtMsg.textColor = UIColor.blackColor()
        txtMsg.font = UIFont.boldSystemFontOfSize(12)
        txtMsg.clearButtonMode = UITextFieldViewMode.WhileEditing
        txtMsg.keyboardType = UIKeyboardType.ASCIICapable
        txtMsg.layer.cornerRadius = 10.0
        txtMsg.returnKeyType = UIReturnKeyType.Send
        txtMsg.delegate = self
        sendView.addSubview(txtMsg)
        self.view.addSubview(sendView)
        
        let mircoButton = UIButton(frame:CGRectMake(5,10,40,35))
        mircoButton.addTarget(self, action:#selector(ViewController.sendMessage) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        mircoButton.setImage(UIImage(named:"mirco"),forState:UIControlState.Normal)
        sendView.addSubview(mircoButton)
        
        let addButton = UIButton(frame:CGRectMake(screenWidth - 45,12,33,30))
        addButton.addTarget(self, action:#selector(ViewController.sendMessage) ,
                             forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"add1"),forState:UIControlState.Normal)
        sendView.addSubview(addButton)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool
    {
        let text:String = txtMsg.text!
     
        if(text.isEmpty){
            let alert = UIAlertView();
            alert.message = String("Please input something.");
            alert.addButtonWithTitle("OK");
            alert.show();
            return false;
        }
        
        sendMessage()
        return true
    }
    
    func sendMessage()
    {
        let sender = txtMsg
        let thisChat =  MessageItem(body:sender.text!, user:me, date:NSDate(), mtype:ChatType.Mine)
        
        Chats.addObject(thisChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
        sender.resignFirstResponder()
        sender.text = ""
        
        let url = "http://watsonserver.mybluemix.net/sample"
        requestUrl(url)
        
    }
    
    func setupChatTable()
    {
        self.tableView = TableView(frame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 75), style: .Plain)
        
        // 创建一个重用的单元格
        self.tableView!.registerClass(TableViewCell.self, forCellReuseIdentifier: "ChatCell")
        me = UserInfo(name:"Xiaoming" ,logo:("xiaohua.png"))
        Watson  = UserInfo(name:"Xiaohua", logo:("earth.png"))
        
        let zero =  MessageItem(body:"Hi Dear,What can I do for you!", user:Watson,  date:NSDate(timeIntervalSinceNow:0), mtype:ChatType.Someone)
        
        Chats = NSMutableArray()
        Chats.addObjectsFromArray([zero])
        self.tableView.chatDataSource = self
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
    
    func requestUrl(urlString:String) ->  Void {
        let URL = NSURL(string:urlString)
        let urlRequest = NSURLRequest(URL: URL!)
        NSURLConnection.sendAsynchronousRequest(urlRequest,queue:NSOperationQueue.mainQueue(),completionHandler:{
            (response,data,error)-> Void in
            if error == nil && data?.length > 0{
                let datastring = String(data:data!, encoding: NSUTF8StringEncoding)
                    let thatChat =  MessageItem(body:"\(datastring!)", user:self.Watson, date:NSDate(), mtype:ChatType.Someone)
                self.Chats.addObject(thatChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()

            }else{
             print(error)
            }
        })
    }
    
    
}