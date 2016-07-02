import UIKit

class ViewController: UIViewController, ChatDataSource,UITextFieldDelegate {
    
    var Chats:NSMutableArray!
    var tableView:TableView!
    var me:UserInfo!
    var Watson:UserInfo!
    var txtMsg:UITextField!
    var voiceButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChatTable()
        setupSendPanel()
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification:NSNotification){
        
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue()) != nil {
            let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue()
            let keyboardheight  = keyboardSize!.height as CGFloat
            
            let width = self.view.frame.size.width;
            let height = self.view.frame.size.height;
            let rect = CGRectMake(0.0, -keyboardheight,width,height);
            self.view.frame = rect
        }
    }
    
    func keyboardWillHide(notification:NSNotification){
        let width = self.view.frame.size.width;
        let height = self.view.frame.size.height;
        let rect = CGRectMake(0.0, 0,width,height);
        self.view.frame = rect
    }
    
    
    func setupSendPanel()
    {
        let MessageView = self.view.viewWithTag(101)
        MessageView?.removeFromSuperview()
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        let sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        
        sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        sendView.alpha = 0.5
        
        txtMsg = UITextField(frame:CGRectMake(44,7,screenWidth - 95,36))
        txtMsg.backgroundColor = UIColor.whiteColor()
        txtMsg.textColor = UIColor.blackColor()
        txtMsg.font = UIFont.boldSystemFontOfSize(12)
        txtMsg.clearButtonMode = UITextFieldViewMode.WhileEditing
        txtMsg.keyboardType = UIKeyboardType.ASCIICapable
        txtMsg.layer.cornerRadius = 5.0
        txtMsg.returnKeyType = UIReturnKeyType.Send
        txtMsg.delegate = self
        sendView.addSubview(txtMsg)
        sendView.tag = 100
        self.view.addSubview(sendView)
        
        let mircoButton = UIButton(frame:CGRectMake(5,8,40,35))
        mircoButton.addTarget(self, action:#selector(ViewController.changMessageViewToVoiceView) ,
                              forControlEvents:UIControlEvents.TouchUpInside)
        mircoButton.setImage(UIImage(named:"mirco2"),forState:UIControlState.Normal)
        sendView.addSubview(mircoButton)
        
        let addButton = UIButton(frame:CGRectMake(screenWidth - 45,9,33,30))
        addButton.addTarget(self, action:#selector(ViewController.sendMessage) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"add3"),forState:UIControlState.Normal)
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
    
    func changMessageViewToVoiceView(){
        let MessageView = self.view.viewWithTag(100)
        MessageView?.removeFromSuperview()
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        let voiceView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        
        voiceView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        voiceView.alpha = 0.5
        voiceButton = UIButton(frame: CGRect(x: 44, y: 7, width: screenWidth - 95, height: 36))
        voiceButton.setTitle("Hold to talk", forState: UIControlState.Normal)
        voiceButton.backgroundColor = UIColor.lightGrayColor()
        voiceButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        voiceButton.addTarget(self, action:#selector(ViewController.holdOnVoiceButton) ,
                              forControlEvents:UIControlEvents.TouchDown)
        voiceButton.addTarget(self, action:#selector(ViewController.leftVoiceButton) ,
                              forControlEvents:UIControlEvents.TouchUpInside)
        voiceButton.alpha = 0.5
        voiceButton.layer.cornerRadius = 5
        voiceView.addSubview(voiceButton)
        voiceView.tag = 101
        self.view.addSubview(voiceView)
        
        let keyBoardButton = UIButton(frame:CGRectMake(5,6,30,38))
        keyBoardButton.addTarget(self, action:#selector(ViewController.setupSendPanel) ,
                              forControlEvents:UIControlEvents.TouchUpInside)
        keyBoardButton.setImage(UIImage(named:"keyword"),forState:UIControlState.Normal)
        voiceView.addSubview(keyBoardButton)
        
        let addButton = UIButton(frame:CGRectMake(screenWidth - 45,9,33,30))
        addButton.addTarget(self, action:#selector(ViewController.sendMessage) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"add3"),forState:UIControlState.Normal)
        voiceView.addSubview(addButton)
        
        
        
    }

        
    
    func holdOnVoiceButton()
    {   print("button down")
        voiceButton.backgroundColor = UIColor.darkGrayColor()
    }
    
    func leftVoiceButton()
    {   print("button up")
        voiceButton.backgroundColor = UIColor.lightGrayColor()
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
        self.tableView = TableView(frame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 70), style: .Plain)
        
        // 创建一个重用的单元格
        self.tableView!.registerClass(TableViewCell.self, forCellReuseIdentifier: "ChatCell")
        me = UserInfo(name:"user" ,logo:("femail.png"))
        Watson  = UserInfo(name:"watson", logo:("rainbow.png"))
        
        let zero =  MessageItem(body:"Hi Dear,I'm watson,What can I do for you!", user:Watson,  date:NSDate(timeIntervalSinceNow:0), mtype:ChatType.Someone)
        
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