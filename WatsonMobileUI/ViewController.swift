import UIKit
import AVFoundation

class ViewController: UIViewController, ChatDataSource,UITextFieldDelegate,EZMicrophoneDelegate,EZRecorderDelegate {
    
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
    var recorderSeetingsDic:[String : AnyObject]?
    var aacPath:String?
    var volumeTimer:NSTimer! //定时器线程，循环监测录音的音量大小
    var imageViewFlag:String = "show"
    var microphone: EZMicrophone!
    var ezRecorder: EZRecorder!


    
    override func viewDidLoad() {

        super.viewDidLoad()
        setupChatTable()
        setupSendPanel()
        
        //初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        //设置录音类型
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        //设置支持后台
        try! session.setActive(true)
        //获取Document目录
        docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                         .UserDomainMask, true)[0]
        //初始化字典并添加设置参数
        recorderSeetingsDic =
            [
                AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey: 2, //录音的声道数，立体声为双声道
                AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
                AVEncoderBitRateKey : 320000,
                AVSampleRateKey : 44100.0 //录音器每秒采集的录音样本数
        ]
        
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
        sendView = UIView(frame:CGRectMake(0,self.view.frame.size.height - 50,screenWidth,50))
        
        sendView.backgroundColor = UIColor(red:0, green:0.1, blue:0.1, alpha:0.1)
        sendView.alpha = 0.5
        
        txtMsg = UITextField(frame:CGRectMake(44,7,screenWidth - 95,36))
        //txtMsg.placeholder = "Please input something."
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
        addButton.setImage(UIImage(named:"text129"),forState:UIControlState.Normal)
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
        addButton.setImage(UIImage(named:"text129"),forState:UIControlState.Normal)
        sendView.addSubview(addButton)
        
        hiddenImageView()
        imageViewFlag = "show"
        
    }
    
    
    
    func holdOnVoiceButton()
    {
        print("button down")
        self.notice("Recording", type: NoticeType.success, autoClear: false)
        voiceButton.backgroundColor = UIColor.darkGrayColor()
        //组合录音文件路径
        let now = NSDate()
        let dformatter = NSDateFormatter()
        dformatter.dateFormat = "HH_mm_ss"
        aacPath = docDir + "/play_"+dformatter.stringFromDate(now)+".wav"
        print(aacPath)
        
        microphone = EZMicrophone(delegate: self, startsImmediately: true)
        
        ezRecorder = EZRecorder(URL: NSURL(string: aacPath!), clientFormat: self.microphone.audioStreamBasicDescription(), fileType: EZRecorderFileType.WAV, delegate: self)
        
        microphone.startFetchingAudio()
        
    }
    
    //定时检测录音音量
    func levelTimer(){
        //recorder!.updateMeters() // 刷新音量数据
        //let averageV:Float = recorder!.averagePowerForChannel(0) //获取音量的平均值
        //let maxV:Float = recorder!.peakPowerForChannel(0) //获取音量最大值
        //let lowPassResult:Double = pow(Double(10), Double(0.05*maxV))
        
    }
    
    func leftVoiceButton()
    {   print("button up")
        self.clearAllNotice()
        voiceButton.backgroundColor = UIColor.lightGrayColor()
        microphone.stopFetchingAudio()
        ezRecorder.closeAudioFile()
        print(aacPath)
        //let url = "http://watsonserver.mybluemix.net/speech"
         let url = "http://123.57.164.21/WeiXin/WatsonDemo2Servlet"
        postUrl(url)
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
    
    
    func showOrHiddenImageView()
    {
        if(imageViewFlag=="show"){
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
        
        let addButton = UIButton(frame:CGRectMake(70,6,35,35))
        addButton.alpha = 0.8
        addButton.addTarget(self, action:#selector(ViewController.showOrHiddenImageView) ,
                            forControlEvents:UIControlEvents.TouchUpInside)
        addButton.setImage(UIImage(named:"photo189"),forState:UIControlState.Normal)
        imageView.addSubview(addButton)
        
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
    
    func postUrl(urlString:String) ->  Void {
        let URL = NSURL(string:urlString)
        let urlRequest = NSMutableURLRequest(URL: URL!)
        urlRequest.HTTPMethod = "POST"
        urlRequest.HTTPBodyStream  = NSInputStream.init(fileAtPath: aacPath!)
        
        NSURLConnection.sendAsynchronousRequest(urlRequest,queue:NSOperationQueue.mainQueue(),completionHandler:{
            (response,data,error)-> Void in
            if error == nil && data?.length > 0{
                let datastring = String(data:data!, encoding: NSUTF8StringEncoding)
                print(datastring)
                let thisChat =  MessageItem(body:"\(datastring!)", user:self.me, date:NSDate(), mtype:ChatType.Mine)
                self.Chats.addObject(thisChat)
                self.tableView.chatDataSource = self
                self.tableView.reloadData()
                
            }else{
                print(error)
            }
        })
    }
    
    
    
    func microphone(microphone: EZMicrophone!, hasBufferList bufferList: UnsafeMutablePointer<AudioBufferList>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        ezRecorder.appendDataFromBufferList(bufferList, withBufferSize:bufferSize)
        
    }
}