import UIKit
import AVFoundation

class ViewController: UIViewController, ChatDataSource,UITextFieldDelegate,EZMicrophoneDelegate,EZRecorderDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    var Chats:NSMutableArray!
    var tableView:TableView!
    var sendView:UIView!
    var me:UserInfo!
    var Watson:UserInfo!
    var txtMsg:UITextField!
    var voiceButton:UIButton?
    var keyBoardButton:UIButton?
    var microButton:UIButton!
    var addButton:UIButton!
    var recorder:AVAudioRecorder?
    var docDir:String!
    var player:AVAudioPlayer?
    var aacPath:String?
    var imageSelectViewFlag:String = "show"
    var microphone: EZMicrophone!
    var ezRecorder: EZRecorder!
    var plot: EZAudioPlot!
    var pickerView: UIPickerView!
    var confirmView: UIView!
    var itemlist: NSArray!
    var goodslist: NSArray!
    var timer:NSTimer!
    var times:Int!
    var callWebServiceFlag:String!
    var currentIndex:Int!
    var currentViewName:String!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        initChatTableView()
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
    
    // 文本消息view初期表示
    func setupSendPanel()
    {
        // 移除语音View
        let VoiceView = self.view.viewWithTag(101)
        VoiceView?.removeFromSuperview()
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        self.sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        self.sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        self.sendView.alpha = 0.5
        
        self.txtMsg = UITextField(frame:CGRectMake(44,7,screenWidth - 95,36))
        self.txtMsg.placeholder = "Input words here."
        self.txtMsg.backgroundColor = UIColor.whiteColor()
        self.txtMsg.textColor = UIColor.blackColor()
        self.txtMsg.font = UIFont.boldSystemFontOfSize(15)
        self.txtMsg.clearButtonMode = UITextFieldViewMode.WhileEditing
        self.txtMsg.keyboardType = UIKeyboardType.ASCIICapable
        self.txtMsg.layer.cornerRadius = 5.0
        self.txtMsg.returnKeyType = UIReturnKeyType.Send
        self.txtMsg.delegate = self
        self.sendView.addSubview(self.txtMsg)
        self.sendView.tag = 100
        self.view.addSubview(self.sendView)
        
        self.microButton = UIButton(frame:CGRectMake(5,10,30,30))
        self.microButton.alpha = 0.8
        self.microButton.addTarget(self, action:#selector(ViewController.changMessageViewToVoiceView) ,
                                   forControlEvents:UIControlEvents.TouchUpInside)
        self.microButton.setImage(UIImage(named:"wifi75"),forState:UIControlState.Normal)
        self.sendView.addSubview(self.microButton)
        
        self.addButton = UIButton(frame:CGRectMake(screenWidth - 43,10,30,30))
        self.addButton.alpha = 0.8
        self.addButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageSelectView) ,
                                 forControlEvents:UIControlEvents.TouchUpInside)
        self.addButton.setImage(UIImage(named:"add"),forState:UIControlState.Normal)
        self.sendView.addSubview(self.addButton)
        hiddenImageSelectView()
        self.imageSelectViewFlag = "show"
        self.currentViewName = "sendTextMessageView"
        
    }
    
    func showAlertMessage(messageContent:String) ->Void{
        
        let alertController = UIAlertController(title: "",
                                                message: messageContent, preferredStyle: .Alert)
        
        let confirmAction = UIAlertAction(title: "OK", style: .Default,
                                          handler: {
                                            action in
                                            
        })
        
        alertController.addAction(confirmAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool
    {
        let text:String = txtMsg.text!
        if(text.isEmpty){
            showAlertMessage("Please input something.")
            return false;
        }
        
        let sender = txtMsg
        let mineChat =  MessageItem(body:sender.text!, user:me, date:NSDate(), mtype:ChatType.Mine)
        self.Chats.addObject(mineChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
        // let url = "http://123.57.164.21/WeiXin/WatsonDemo2Servlet?text=" + sender.text!
        let url = "http://watsonserver.mybluemix.net/sample?text=" + sender.text!
        sendTextMessage(url)
        sender.resignFirstResponder()
        sender.text = ""
        return true
    }
    
    func changMessageViewToVoiceView(){
        
        let MessageView = self.view.viewWithTag(100)
        MessageView?.removeFromSuperview()
        let screenWidth = UIScreen.mainScreen().bounds.width
        self.sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        
        self.sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        self.sendView.alpha = 0.5
        self.voiceButton = UIButton(frame: CGRect(x: 44, y: 7, width: screenWidth - 95, height: 36))
        self.voiceButton!.setTitle("Hold to talk", forState: UIControlState.Normal)
        self.voiceButton!.backgroundColor = UIColor.lightGrayColor()
        self.voiceButton!.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        self.voiceButton!.addTarget(self, action:#selector(ViewController.holdOnVoiceButton) ,
                                    forControlEvents:UIControlEvents.TouchDown)
        self.voiceButton!.addTarget(self, action:#selector(ViewController.leftVoiceButton) ,
                                    forControlEvents:UIControlEvents.TouchUpInside)
        self.voiceButton!.alpha = 0.9
        self.voiceButton!.layer.cornerRadius = 5
        self.sendView.addSubview(voiceButton!)
        self.sendView.tag = 101
        self.view.addSubview(sendView)
        
        self.keyBoardButton = UIButton(frame:CGRectMake(7,5,30,38))
        self.keyBoardButton!.alpha = 0.9
        self.keyBoardButton!.addTarget(self, action:#selector(ViewController.setupSendPanel) ,
                                       forControlEvents:UIControlEvents.TouchUpInside)
        self.keyBoardButton!.setImage(UIImage(named:"edit"),forState:UIControlState.Normal)
        self.sendView.addSubview(self.keyBoardButton!)
        
        self.addButton = UIButton(frame:CGRectMake(screenWidth - 43,10,30,30))
        self.addButton.alpha = 0.8
        self.addButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageSelectView) ,
                                 forControlEvents:UIControlEvents.TouchUpInside)
        self.addButton.setImage(UIImage(named:"add"),forState:UIControlState.Normal)
        self.sendView.addSubview(self.addButton)
        
        hiddenImageSelectView()
        self.imageSelectViewFlag = "show"
        self.currentViewName = "sendVoiceMessageView"
        
    }
    
    
    // 录音按钮Hold事件
    func holdOnVoiceButton()
    {
        self.voiceButton!.backgroundColor = UIColor.darkGrayColor()
        // 组合录音文件路径
        let now = NSDate()
        let dformatter = NSDateFormatter()
        dformatter.dateFormat = "HH_mm_ss"
        self.aacPath = docDir + "/play_"+dformatter.stringFromDate(now)+".wav"
        
        // 初始化麦克风
        self.microphone = EZMicrophone(delegate: self, startsImmediately: true)
        self.microphone.startFetchingAudio()
        
        // 初始化recorder
        self.ezRecorder = EZRecorder(URL: NSURL(string: self.aacPath!)!, clientFormat: microphone.self.audioStreamBasicDescription(), fileType: EZRecorderFileType.WAV, delegate: self)
        
        // 初始化波形图view
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
    
    // 录音按钮松开事件
    func leftVoiceButton()
    {
        self.plot.removeFromSuperview()
        self.voiceButton!.backgroundColor = UIColor.lightGrayColor()
        self.microphone.stopFetchingAudio()
        self.ezRecorder.closeAudioFile()
        let url = "http://watsonserver.mybluemix.net/speech"
        //let url = "http://123.57.164.21/WeiXin/WatsonDemo2Servlet"
        sendVoiceMessage(url)
        
    }
    
    // 显示或者隐藏图片选择View
    func showOrHiddenImageSelectView()
    {
        if(self.imageSelectViewFlag == "show"){
            showImageSelectView()
            self.imageSelectViewFlag = "hidden"
        }else{
            hiddenImageSelectView()
            self.imageSelectViewFlag = "show"
        }
        
    }
    
    // 显示图片选择View
    func showImageSelectView()
    {
        let tableViewWidth = tableView.frame.size.width
        let tableViewHeight = tableView.frame.size.height
        let tableViewRect = CGRectMake(0.0, -30,tableViewWidth,tableViewHeight)
        self.tableView.frame = tableViewRect
        
        let sendViewWidth = sendView.frame.size.width
        let sendViewHeight = sendView.frame.size.height
        let sendViewRect = CGRectMake(0.0, self.view.frame.size.height - 100,sendViewWidth,sendViewHeight)
        self.sendView.frame = sendViewRect
        
        
        let screenWidth = UIScreen.mainScreen().bounds.width
        let imageSelectView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,60))
        
        imageSelectView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        imageSelectView.alpha = 0.5
        imageSelectView.layer.borderWidth = 1.5
        imageSelectView.tag = 102
        imageSelectView.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.view.addSubview(imageSelectView)
        
        
        let localImageButton = UIButton(frame:CGRectMake(10,6,35,35))
        localImageButton.alpha = 0.8
        localImageButton.addTarget(self, action:#selector(ViewController.changMessageViewToVoiceView) ,
                                   forControlEvents:UIControlEvents.TouchUpInside)
        localImageButton.setImage(UIImage(named:"pictures"),forState:UIControlState.Normal)
        imageSelectView.addSubview(localImageButton)
        localImageButton.enabled = false
        
        let cameraButton = UIButton(frame:CGRectMake(70,6,35,35))
        cameraButton.alpha = 0.8
        cameraButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageSelectView) ,
                               forControlEvents:UIControlEvents.TouchUpInside)
        cameraButton.setImage(UIImage(named:"photo189"),forState:UIControlState.Normal)
        imageSelectView.addSubview(cameraButton)
        cameraButton.enabled = false
        
    }
    
    // 隐藏图片选择View
    func hiddenImageSelectView()
    {
        let imageSelectView = self.view.viewWithTag(102)
        imageSelectView?.removeFromSuperview()
        
        let tableViewWidth = tableView.frame.size.width;
        let tableViewHeight = tableView.frame.size.height;
        let tableViewRect = CGRectMake(0.0, 20,tableViewWidth,tableViewHeight);
        self.tableView.frame = tableViewRect
        
        let sendViewWidth = sendView.frame.size.width;
        let sendViewHeight = sendView.frame.size.height;
        let sendViewRect = CGRectMake(0.0, self.view.frame.size.height - 50,sendViewWidth,sendViewHeight)
        self.sendView.frame = sendViewRect
        
    }
    
    override func prefersStatusBarHidden()->Bool{
        return true
    }
    
    func initChatTableView()
    {
        let backGroundImage:UIImage  = UIImage(named:"watson11.png")!
        let backGroundImageView:UIImageView = UIImageView(image:backGroundImage)
        backGroundImageView.alpha = 0.4
        
        self.view.backgroundColor = UIColor(patternImage: backGroundImage)
        self.view.layer.contents = backGroundImage.CGImage
        self.tableView = TableView(frame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 70), style: .Plain)
        
        // 创建一个重用的单元格
        self.tableView!.registerClass(TableViewCell.self, forCellReuseIdentifier: "ChatCell")
        self.me = UserInfo(name:"user" ,logo:("UserFemale.png"))
        self.Watson  = UserInfo(name:"watson", logo:("rainbow.png"))
        
        let zero =  MessageItem(body:"Hi Dear,I'm watson,What can I do for you!", user:Watson,  date:NSDate(timeIntervalSinceNow:0), mtype:ChatType.Someone)
        
        self.Chats = NSMutableArray()
        self.Chats.addObjectsFromArray([zero])
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
        return self.Chats[row] as! MessageItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func sendTextMessage(urlString:String) ->  Void {
        self.callWebServiceFlag = "sending"
        disableOrEnableAllsendButton()
        let URL = NSURL(string:urlString)
        let urlRequest = NSURLRequest(URL: URL!)
        
        NSURLConnection.sendAsynchronousRequest(urlRequest,queue:NSOperationQueue.mainQueue(),completionHandler:{
            (response,data,error)-> Void in
            self.callWebServiceFlag = "end"
            self.disableOrEnableAllsendButton()
            
            if error == nil && data?.length > 0{
                let datastring = String(data:data!, encoding: NSUTF8StringEncoding)
                print(datastring)
                let jsonData:AnyObject = (data?.objectFromJSONData())!
                let type: String = jsonData.objectForKey("type") as! String
                
                if(type == "text"){
                    let text: String = jsonData.objectForKey("value") as! String
                    let wasonChat:MessageItem =  MessageItem(body:"\(text)", user:self.Watson, date:NSDate(), mtype:ChatType.Someone)
                    self.Chats.addObject(wasonChat)
                    self.tableView.chatDataSource = self
                    self.tableView.reloadData()
                }else if(type == "itemlist"){
                    self.itemlist = jsonData.objectForKey("value")! as! NSArray
                    let title:String = jsonData.objectForKey("title")! as! String
                    let wasonChat:MessageItem =  MessageItem(body:"\(title)", user:self.Watson, date:NSDate(), mtype:ChatType.Someone)
                    self.Chats.addObject(wasonChat)
                    self.tableView.reloadData()
                    
                    let screenWidth = UIScreen.mainScreen().bounds.width
                    self.pickerView = UIPickerView(frame: CGRectMake(0,self.view.frame.size.height - 100,screenWidth,100))
                    self.pickerView.dataSource = self
                    self.pickerView.delegate = self
                    self.pickerView.showsSelectionIndicator = true
                    self.pickerView.reloadAllComponents()
                    self.view.addSubview(self.pickerView)
                    
                    self.confirmView = UIView(frame:CGRectMake(0, self.view.frame.size.height - 135, screenWidth,40))
                    
                    self.confirmView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
                    self.confirmView.layer.borderWidth = 0.5
                    self.confirmView.layer.borderColor = UIColor.lightGrayColor().CGColor
                    self.confirmView.alpha = 0.5
                    self.view.addSubview(self.confirmView)
                    
                    let confirmButton = UIButton(frame:CGRectMake(screenWidth - 43, 1, 38, 38))
                    confirmButton.alpha = 0.8
                    confirmButton.addTarget(self, action:#selector(ViewController.getSelectItem) ,
                        forControlEvents:UIControlEvents.TouchUpInside)
                    confirmButton.setImage(UIImage(named:"Ok-96.png"),forState:UIControlState.Normal)
                    self.confirmView.addSubview(confirmButton)
                    
                    self.sendView.removeFromSuperview()
                    
                    let tableViewWidth = self.tableView.frame.size.width;
                    let tableViewHeight = self.tableView.frame.size.height;
                    let tableViewRect = CGRectMake(0.0, -70,tableViewWidth,tableViewHeight)
                    self.tableView.frame = tableViewRect
                    
                }else{
                    self.goodslist = jsonData.objectForKey("value")! as! NSArray
                    let title:String = jsonData.objectForKey("title")! as! String
                    let wasonChat:MessageItem =  MessageItem(body:"\(title)", user:self.Watson, date:NSDate(), mtype:ChatType.Someone)
                    self.Chats.addObject(wasonChat)
                    
                    for i in 0..<self.goodslist.count{
                        let jsonGoodsData:AnyObject = self.goodslist[i]
                        let name =  jsonGoodsData.objectForKey("title") as! String
                        let price =  jsonGoodsData.objectForKey("price") as! String
                        let imgurl = jsonGoodsData.objectForKey("imgurl") as! String
                        
                        
                        //self.Chats.addObject(item)
                        
                    }
                    self.tableView.chatDataSource = self
                    self.tableView.reloadData()
                    
                    
                    
                }
                
            }else{
                // 服务器挂了
                
            }
        })
    }
    
    func sendVoiceMessage(urlString:String) ->  Void {
        self.callWebServiceFlag = "sending"
        disableOrEnableAllsendButton()
        let URL = NSURL(string:urlString)
        let urlRequest = NSMutableURLRequest(URL: URL!)
        urlRequest.HTTPMethod = "POST"
        urlRequest.HTTPBodyStream  = NSInputStream.init(fileAtPath: self.aacPath!)
        
        let mineChat =  MessageItem(body:"\("......")", user:self.me, date:NSDate(), mtype:ChatType.Mine)
        self.Chats.addObject(mineChat)
        self.tableView.reloadData()
        self.currentIndex = self.rowsForChatTable(self.tableView)
        
        self.times = 1
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5,
                                                            target:self,selector:#selector(ViewController.timerWaitCustomer),
                                                            userInfo:nil,repeats:true)
        
        NSURLConnection.sendAsynchronousRequest(urlRequest,queue:NSOperationQueue.mainQueue(),completionHandler:{
            (response,data,error)-> Void in
            self.callWebServiceFlag = "end"
            self.disableOrEnableAllsendButton()
            self.timer.invalidate()
            if error == nil && data?.length > 0{
                let datastring = String(data:data!, encoding: NSUTF8StringEncoding)
                self.Chats[self.currentIndex - 1] =  MessageItem(body:"\(datastring!)", user:self.me, date:NSDate(), mtype:ChatType.Mine)
                self.tableView.chatDataSource = self
                self.tableView.reloadDataForWaitCell()
                let url = "http://watsonserver.mybluemix.net/sample?text=" + datastring!
                self.sendTextMessage(url)
            }else{
                if(data?.length == 0){
                    self.Chats.removeObjectAtIndex(self.currentIndex - 1)
                    self.tableView.chatDataSource = self
                    self.tableView.reloadData()
                    self.showAlertMessage("Sorry, I can't get what you said, please try again.")
                }
            }
        })
    }
    
    
    // 实时抓取音轨Buffer
    func microphone(microphone: EZMicrophone!, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        self.ezRecorder.appendDataFromBufferList(bufferList, withBufferSize:bufferSize)
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
        return self.itemlist.count
    }
    
    // 设置选择框各选项的内容
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int)
        -> String? {
            let contenObject:AnyObject = itemlist[row]
            let itemText:String =  contenObject.objectForKey("text") as! String
            return itemText
    }
    
    // 取得提示list选中的值
    func getSelectItem()
    {
        let selectInt:Int  = pickerView.selectedRowInComponent(0)
        let itemSelectObject:AnyObject = itemlist[selectInt]
        let itemSelectText:String =  itemSelectObject.objectForKey("text") as! String
        self.confirmView.removeFromSuperview()
        self.pickerView.removeFromSuperview()
        if self.currentViewName == "sendTextMessageView"{
            setupSendPanel()
        }else{
            changMessageViewToVoiceView()
        }
        
        let mineChat =  MessageItem(body:itemSelectText, user:me, date:NSDate(), mtype:ChatType.Mine)
        self.Chats.addObject(mineChat)
        self.tableView.chatDataSource = self
        self.tableView.reloadData()
        let url = "http://watsonserver.mybluemix.net/sample?text=" + itemSelectText
        sendTextMessage(url)
    }
    
    // 非活性or活性所有送信按钮
    func disableOrEnableAllsendButton()
    {
        if(self.callWebServiceFlag == "sending"){
            if self.voiceButton != nil {
                self.voiceButton!.enabled = false
            }
            if self.keyBoardButton != nil {
                self.keyBoardButton!.enabled = false
            }
            if self.addButton != nil {
                self.addButton!.enabled = false
            }
            if self.microButton != nil {
                self.microButton!.enabled = false
            }
            self.txtMsg.enabled = false
        }else{
            if self.voiceButton != nil {
                self.voiceButton!.enabled = true
            }
            if self.keyBoardButton != nil {
                self.keyBoardButton!.enabled = true
            }
            if self.addButton != nil {
                self.addButton!.enabled = true
            }
            if self.microButton != nil {
                self.microButton!.enabled = true
            }
            
            self.txtMsg.enabled = true
        }
        
    }
    
    // 等待Waston Api执行结果
    func timerWaitCustomer()
    {
        var timeSting:String = "......"
        if(self.times == 1){
            timeSting = "."
            self.times = 2
        }else if(self.times == 2){
            timeSting = ".."
            self.times = 3
        }else if(self.times == 3){
            timeSting = "..."
            self.times = 4
        }else if(self.times == 4){
            timeSting = "...."
            self.times = 5
        }else if(self.times == 5){
            timeSting = "....."
            self.times = 6
        }else{
            timeSting = "......"
            self.times = 1
        }
        let msgItem = MessageItem(body:"\(timeSting)", user:self.me, date:NSDate(), mtype:ChatType.Mine)
        self.Chats[self.currentIndex - 1] = msgItem
        self.tableView.reloadDataForWaitCell()
        self.tableView.chatDataSource = self
        
    }
    
    
}