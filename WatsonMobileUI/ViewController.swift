import UIKit
import AVFoundation

class ViewController: UIViewController, ChatDataSource,UITextFieldDelegate,EZMicrophoneDelegate,EZRecorderDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    var Chats:NSMutableArray!
    var tableView:TableView!
    var sendView:UIView!
    var me:UserInfo!
    var Watson:UserInfo!
    var txtMsg:UITextField!
    var voiceButton:UIButton!
    var recorder:AVAudioRecorder?
    var docDir:String!
    var player:AVAudioPlayer?
    var aacPath:String?
    var imageViewFlag:String = "show"
    var microphone: EZMicrophone!
    var ezRecorder: EZRecorder!
    var plot: EZAudioPlot!
    var pickerView: UIPickerView!
    var itemlist: NSArray!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupChatTable()
        setupSendPanel()
        
        // 初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // 设置录音类型
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        // 设置支持后台
        try! session.setActive(true)
        // 获取Document目录
        docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                     .UserDomainMask, true)[0]
    }
    
    // 绑定键盘事件
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // 键盘显示事件view上移
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
    
    // 键盘显示事件view下移复位
    func keyboardWillHide(notification:NSNotification){
        let width = self.view.frame.size.width;
        let height = self.view.frame.size.height;
        let rect = CGRectMake(0.0, 0,width,height);
        self.view.frame = rect
    }
    
    // view初期表示
    func setupSendPanel()
    {
        let MessageView = self.view.viewWithTag(101)
        MessageView?.removeFromSuperview()
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        
        sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        sendView.alpha = 0.5
        
        txtMsg = UITextField(frame:CGRectMake(44,7,screenWidth - 95,36))
        //txtMsg.placeholder = "Please input something."
        txtMsg.backgroundColor = UIColor.whiteColor()
        txtMsg.textColor = UIColor.blackColor()
        txtMsg.font = UIFont.boldSystemFontOfSize(15)
        txtMsg.clearButtonMode = UITextFieldViewMode.WhileEditing
        txtMsg.keyboardType = UIKeyboardType.ASCIICapable
        txtMsg.layer.cornerRadius = 5.0
        txtMsg.returnKeyType = UIReturnKeyType.Send
        txtMsg.delegate = self
        sendView.addSubview(txtMsg)
        sendView.tag = 100
        self.view.addSubview(sendView)
        
        let mircoButton = UIButton(frame:CGRectMake(5,10,30,30))
        mircoButton.alpha = 0.8
        mircoButton.addTarget(self, action:#selector(ViewController.changMessageViewToVoiceView) ,
                              forControlEvents:UIControlEvents.TouchUpInside)
        mircoButton.setImage(UIImage(named:"wifi75"),forState:UIControlState.Normal)
        sendView.addSubview(mircoButton)
        
        let addButton = UIButton(frame:CGRectMake(screenWidth - 43,10,30,30))
        addButton.alpha = 0.8
        addButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageView) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"add"),forState:UIControlState.Normal)
        sendView.addSubview(addButton)
        
        hiddenImageView()
        imageViewFlag = "show"
        
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
        
        //UIView.animateWithDuration(0.1, animations: {
        //   MessageView?.alpha = 0.0
        //}, completion: { finished in MessageView?.removeFromSuperview() })
        
        
        MessageView?.removeFromSuperview()
        let screenWidth = UIScreen.mainScreen().bounds.width
        sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        
        sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        sendView.alpha = 0.5
        voiceButton = UIButton(frame: CGRect(x: 44, y: 7, width: screenWidth - 95, height: 36))
        voiceButton.setTitle("Hold to talk", forState: UIControlState.Normal)
        voiceButton.backgroundColor = UIColor.lightGrayColor()
        voiceButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        voiceButton.addTarget(self, action:#selector(ViewController.holdOnVoiceButton) ,
                              forControlEvents:UIControlEvents.TouchDown)
        voiceButton.addTarget(self, action:#selector(ViewController.leftVoiceButton) ,
                              forControlEvents:UIControlEvents.TouchUpInside)
        voiceButton.alpha = 0.9
        voiceButton.layer.cornerRadius = 5
        sendView.addSubview(voiceButton)
        sendView.tag = 101
        self.view.addSubview(sendView)
        
        let keyBoardButton = UIButton(frame:CGRectMake(7,5,30,38))
        keyBoardButton.alpha = 0.9
        keyBoardButton.addTarget(self, action:#selector(ViewController.setupSendPanel) ,
                                 forControlEvents:UIControlEvents.TouchUpInside)
        keyBoardButton.setImage(UIImage(named:"edit"),forState:UIControlState.Normal)
        sendView.addSubview(keyBoardButton)
        
        let addButton = UIButton(frame:CGRectMake(screenWidth - 43,10,30,30))
        addButton.alpha = 0.8
        addButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageView) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"add"),forState:UIControlState.Normal)
        sendView.addSubview(addButton)
        
        hiddenImageView()
        imageViewFlag = "show"
        
    }
    
    
    
    func holdOnVoiceButton()
    {
        print("button down")
        // self.notice("Recording", type: NoticeType.success, autoClear: false)
        self.voiceButton.backgroundColor = UIColor.darkGrayColor()
        // 组合录音文件路径
        let now = NSDate()
        let dformatter = NSDateFormatter()
        dformatter.dateFormat = "HH_mm_ss"
        aacPath = docDir + "/play_"+dformatter.stringFromDate(now)+".wav"
        print(aacPath)
        
        microphone = EZMicrophone(delegate: self, startsImmediately: true)
        
        ezRecorder = EZRecorder(URL: NSURL(string: aacPath!), clientFormat: self.microphone.audioStreamBasicDescription(), fileType: EZRecorderFileType.WAV, delegate: self)
        microphone.startFetchingAudio()
        
        
        self.plot = EZAudioPlot.init(frame: CGRectMake(self.view.frame.width/2-35, self.view.frame.height/2-70, 70, 70))
        self.plot.plotType = EZPlotType.Rolling
        self.plot.shouldFill = true
        self.plot.shouldMirror = true
        self.plot.alpha = 0.7
        self.plot.layer.cornerRadius = 10
        self.plot.waveformLayer.cornerRadius = 10
        self.plot.backgroundColor = UIColor.blackColor()
        self.plot.color = UIColor.whiteColor()
        
        let recordlable:UILabel = UILabel.init(frame: CGRectMake(14, 35, 60, 60))
        recordlable.text = "Recording"
        recordlable.font = UIFont.boldSystemFontOfSize(8)
        recordlable.textColor = UIColor.whiteColor()
        self.plot.addSubview(recordlable)
        self.view.addSubview(plot)
        
    }
    
    func leftVoiceButton()
    {
        self.plot.removeFromSuperview()
        voiceButton.backgroundColor = UIColor.lightGrayColor()
        microphone.stopFetchingAudio()
        ezRecorder.closeAudioFile()
        print(aacPath)
        let url = "http://watsonserver.mybluemix.net/speech"
        //let url = "http://123.57.164.21/WeiXin/WatsonDemo2Servlet"
        postUrl(url)
        
    }
    
    func sendMessage()
    {
        let sender = txtMsg
        let thisChat =  MessageItem(body:sender.text!, user:me, date:NSDate(), mtype:ChatType.Mine)
        
        let url = "http://123.57.164.21/WeiXin/WatsonDemo2Servlet?text="+sender.text!
        requestUrl(url)
        
        Chats.addObject(thisChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
        sender.resignFirstResponder()
        sender.text = ""
        
    }
    
    
    func showOrHiddenImageView()
    {
        if(imageViewFlag == "show"){
            showImageView()
            imageViewFlag = "hidden"
        }else{
            hiddenImageView()
            imageViewFlag = "show"
        }
        
    }
    
    func showImageView()
    {
        let tableViewWidth = tableView.frame.size.width
        let tableViewHeight = tableView.frame.size.height
        let tableViewRect = CGRectMake(0.0, -30,tableViewWidth,tableViewHeight)
        tableView.frame = tableViewRect
        
        let sendViewWidth = sendView.frame.size.width
        let sendViewHeight = sendView.frame.size.height
        let sendViewRect = CGRectMake(0.0, self.view.frame.size.height - 100,sendViewWidth,sendViewHeight)
        sendView.frame = sendViewRect
        
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        let imageView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,60))
        
        imageView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        imageView.alpha = 0.5
        imageView.layer.borderWidth = 1.5
        imageView.tag = 102
        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.view.addSubview(imageView)
        
        
        let mircoButton = UIButton(frame:CGRectMake(10,6,35,35))
        mircoButton.alpha = 0.8
        mircoButton.addTarget(self, action:#selector(ViewController.changMessageViewToVoiceView) ,
                              forControlEvents:UIControlEvents.TouchUpInside)
        mircoButton.setImage(UIImage(named:"pictures"),forState:UIControlState.Normal)
        imageView.addSubview(mircoButton)
        mircoButton.enabled = false
        
        let addButton = UIButton(frame:CGRectMake(70,6,35,35))
        addButton.alpha = 0.8
        addButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageView) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"photo189"),forState:UIControlState.Normal)
        imageView.addSubview(addButton)
        addButton.enabled = false
        
    }
    
    func hiddenImageView()
    {
        let imageView = self.view.viewWithTag(102)
        imageView?.removeFromSuperview()
        
        let tableViewWidth = tableView.frame.size.width;
        let tableViewHeight = tableView.frame.size.height;
        let tableViewRect = CGRectMake(0.0, 20,tableViewWidth,tableViewHeight);
        tableView.frame = tableViewRect
        
        let sendViewWidth = sendView.frame.size.width;
        let sendViewHeight = sendView.frame.size.height;
        let sendViewRect = CGRectMake(0.0, self.view.frame.size.height - 50,sendViewWidth,sendViewHeight)
        
        sendView.frame = sendViewRect
        
    }
    
    override func prefersStatusBarHidden()->Bool{
        return true
    }
    
    func setupChatTable()
    {
        
        //self.view.backgroundView = UIImageView(image:UIImage(named:"watsonlogo.jpeg"))
        
        let backGroundImage:UIImage  = UIImage(named:"watson11.png")!
        let a:UIImageView = UIImageView(image:backGroundImage)
        a.alpha = 0.4
        // a.layer.contents = backGroundImage.CGImage
        
        
        self.view.backgroundColor = UIColor(patternImage: backGroundImage)
        self.view.layer.contents = backGroundImage.CGImage
        //self.view.insertSubview(a, atIndex: 0)
        
        self.tableView = TableView(frame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 70), style: .Plain)
        //self.tableView.backgroundView = UIImageView(image:UIImage(named:"watsonlogo.jpeg"))
        
        // 创建一个重用的单元格
        self.tableView!.registerClass(TableViewCell.self, forCellReuseIdentifier: "ChatCell")
        me = UserInfo(name:"user" ,logo:("UserFemale.png"))
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
                print(datastring)
                let jsonData:AnyObject = (data?.objectFromJSONData())!
                let type: String = jsonData.objectForKey("type") as! String
                
                if(type == "text"){
                    let text: String = jsonData.objectForKey("value") as! String
                    let thatChat =  MessageItem(body:"\(text)", user:self.Watson, date:NSDate(), mtype:ChatType.Someone)
                    self.Chats.addObject(thatChat)
                    self.tableView.chatDataSource = self
                    self.tableView.reloadData()
                }
                if(type == "itemlist"){
                    self.itemlist = jsonData.objectForKey("value")! as! NSArray
                    let thatChat =  MessageItem(body:"\("You may want to say:")", user:self.Watson, date:NSDate(), mtype:ChatType.Someone)
                    self.Chats.addObject(thatChat)
                    
//                    for i in 0..<itemlist.count{
//                        let jsonItemData:AnyObject = itemlist[i]
//                        let itemText =  jsonItemData.objectForKey("text") as! String
//                        let item =  MessageItem(body:"\(itemText)", date:NSDate(), mtype:ChatType.ItemList)
//                        self.Chats.addObject(item)
// 
//                    }
//                    self.tableView.chatDataSource = self
//                    self.tableView.reloadData()
                    
                    let screenWidth = UIScreen.mainScreen().bounds.width
                    self.pickerView = UIPickerView(frame: CGRectMake(0,self.view.frame.size.height - 100,screenWidth,100))
                    self.pickerView.dataSource = self
                    self.pickerView.delegate = self
                    self.pickerView.showsSelectionIndicator = true
                    self.pickerView.reloadAllComponents()
                    self.view.addSubview(self.pickerView)
                    
                    let okView:UIView = UIView(frame:CGRectMake(0, self.view.frame.size.height - 140, screenWidth,40))
                    
                    okView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
                    okView.layer.borderWidth = 0.5
                    okView.layer.borderColor = UIColor.lightGrayColor().CGColor
                    okView.alpha = 0.5
                    self.view.addSubview(okView)
                    
                    let okButton = UIButton(frame:CGRectMake(screenWidth - 43, 1, 38, 38))
                    okButton.alpha = 0.8
                    okButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageView) ,
                        forControlEvents:UIControlEvents.TouchUpInside)
                    okButton.setImage(UIImage(named:"Ok-96.png"),forState:UIControlState.Normal)
                    okView.addSubview(okButton)
                    
                    self.sendView.removeFromSuperview()
                    
                    
                    let tableViewWidth = self.tableView.frame.size.width;
                    let tableViewHeight = self.tableView.frame.size.height;
                    let tableViewRect = CGRectMake(0.0, -75,tableViewWidth,tableViewHeight)
                    self.tableView.frame = tableViewRect
                    
                }
                
            }else{
                
                
            }
        })
    }
    
    func postUrl(urlString:String) ->  Void {
        let URL = NSURL(string:urlString)
        let urlRequest = NSMutableURLRequest(URL: URL!)
        urlRequest.HTTPMethod = "POST"
        urlRequest.HTTPBodyStream  = NSInputStream.init(fileAtPath: aacPath!)
        
        NSURLConnection.sendAsynchronousRequest(urlRequest,queue:NSOperationQueue.mainQueue(),completionHandler:{
            (response,data,error)-> Void in
            if error == nil && data?.length > 0{
                let datastring = String(data:data!, encoding: NSUTF8StringEncoding)
                let thisChat =  MessageItem(body:"\(datastring!)", user:self.me, date:NSDate(), mtype:ChatType.Mine)
                self.Chats.addObject(thisChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
                
            }else{
                if(data?.length == 0){
                }
            }
        })
    }
    
    
    // 实时抓取音轨Buffer
    func microphone(microphone: EZMicrophone!, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        ezRecorder.appendDataFromBufferList(bufferList, withBufferSize:bufferSize)
    }
    
    // 根据音轨计算出波形图
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        self.plot.updateBuffer(buffer[0], withBufferSize: bufferSize)
    }
    
    
    // 设置选择框的列数为
    func numberOfComponentsInPickerView( pickerView: UIPickerView) -> Int{
        return 1
    }
    
    // 设置选择框的行数为
    func pickerView(pickerView: UIPickerView,numberOfRowsInComponent component: Int) -> Int{
        return itemlist.count
    }
    
    // 设置选择框各选项的内容
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String? {
            
            let contenObject:AnyObject = itemlist[row]
            let itemText:String =  contenObject.objectForKey("text") as! String
            return itemText
    }
    
    
}