//
//  ViewController.swift
//  VoiceroidClient
//
//  Created by mosin on 2018/03/24.
//  Copyright © 2018年 mosin. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, AVAudioPlayerDelegate, UITextFieldDelegate {
    static var sharedInstance: ViewController? = nil
    //入力フィールド
    @IBOutlet weak var wordField: UITextField!
    //音声入力ボタン
    @IBOutlet weak var audioInputButton: UIButton!
    //テキスト入力ボタン
    @IBOutlet weak var textInputButton: UIButton!
    //ゆかりさんのセリフ
    @IBOutlet weak var yukariSerifuLabel: UILabel!
    //自分のセリフ
    @IBOutlet weak var mySerifuLabel: UILabel!
    //録音状況のラベル
    @IBOutlet weak var audioStatusLabel: UILabel!
    
    var voiceroid_URL: String = "http://mosin.jp:7180"
    
    
    
    var voiceData: Data?
    //音声再生オブジェクト
    var audioPlayerInstance: AVAudioPlayer? = nil
    
    //音声認識系
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var inputText: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.sharedInstance = self
        speechRecognizer.delegate = self
        textInputButton.isHidden = true
        wordField.isHidden = true
        
        mySerifuLabel.text = ""
        yukariSerifuLabel.text = ""
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeAccessPoint(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if(index == 0){
            voiceroid_URL = "http://192.168.0.5:7180"
        }else if(index  == 1) {
            voiceroid_URL = "http://mosin.jp:7180"
        }else if(index == 2){
            voiceroid_URL = "https://voiceroid.mosin.jp/"
        }
    }
    
    
    
    @IBAction func pushAudioInputButton(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            audioInputButton.isEnabled = false
            self.audioStatusLabel.text = "停止中"
        } else {
            try! startRecording()
            self.audioStatusLabel.text = "音声認識停止"
        }
    }
    @IBAction func pushTextInputButton(_ sender: UIButton) {
        if let text: String = wordField.text {
            Docomo.sharedInstance.getResponse(text: text)
            mySerifuLabel.text = text
        }else{
            mySerifuLabel.text = "テキストを入力してください！"
        }
        
        
    }
    
    @IBOutlet weak var inputType: UISegmentedControl!
    @IBAction func inputTypeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            //Text入力を選択
            audioInputButton.isHidden = true
            textInputButton.isHidden = false
            wordField.isHidden = false
        }else{
            //音声入力を選択
            audioInputButton.isHidden = false
            textInputButton.isHidden = true
            wordField.isHidden = true
        }
    }
    
    
    
    func speakProcess(_ text: String) {
        let request: Request = Request()
        //let url: URL = URL(string: "https://voiceroid.mosin.jp/")!
        let url: URL = URL(string: voiceroid_URL)!
        let params: [String:Any] = [
            "CV": "YUKARI_EX",
            "DO": "SAVE",
            "INTONATION": 1,
            "PITCH": 1,
            "SPEED": 1,
            "VOLUME": 1,
            "TALKTEXT": text
        ]
        
        do {
            try request.post(url: url, params: params, completionHandler: { data, response, error in
                if(!(error != nil)){
                    self.voiceData = data
                    self.playVoice()
                }
            })
        } catch {
            print("network error")
        }
        
        OperationQueue.main.addOperation {
            self.yukariSerifuLabel.text = text
        }
    }
    
    func playVoice() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
            try AVAudioSession.sharedInstance().setActive(false, with: .notifyOthersOnDeactivation)
        }catch{
            print("recognize error")
        }
        
        do {
            audioPlayerInstance = try AVAudioPlayer(data: voiceData!)
            audioPlayerInstance?.delegate = self
            audioPlayerInstance?.play()
        } catch {
            print("audio error")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        wordField.resignFirstResponder()
        return true
    }
}

extension ViewController: SFSpeechRecognizerDelegate {
    // 音声認識の可否が変更したときに呼ばれるdelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            audioInputButton.isEnabled = true
            audioStatusLabel.text = "音声認識スタート"
        } else {
            audioInputButton.isEnabled = false
            audioStatusLabel.text = "音声認識ストップ"
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestRecognizerAuthorization()
    }
    
    private func requestRecognizerAuthorization() {
        // 認証処理
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // メインスレッドで処理したい内容のため、OperationQueue.main.addOperationを使う
            OperationQueue.main.addOperation { [weak self] in
                guard let `self` = self else { return }
                
                switch authStatus {
                case .authorized:
                    self.audioInputButton.isEnabled = true
                    
                case .denied:
                    self.audioInputButton.isEnabled = false
                    self.audioStatusLabel.text = "音声認識へのアクセスが拒否されています。"
                    
                case .restricted:
                    self.audioInputButton.isEnabled = false
                    self.audioStatusLabel.text = "この端末で音声認識はできません。"
                    
                case .notDetermined:
                    self.audioInputButton.isEnabled = false
                    self.audioStatusLabel.text = "音声認識はまだ許可されていません。"
                }
            }
        }
    }
    
    private func startRecording() throws {
        refreshTask()
        
        let audioSession = AVAudioSession.sharedInstance()
        // 録音用のカテゴリをセット
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode: AVAudioInputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // 録音が完了する前のリクエストを作るかどうかのフラグ。
        // trueだと現在-1回目のリクエスト結果が返ってくる模様。falseだとボタンをオフにしたときに音声認識の結果が返ってくる設定。
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let `self` = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let inputText = result.bestTranscription.formattedString
                //self.speakProcess(inputText)
                self.mySerifuLabel.text = inputText
                isFinal = result.isFinal
                if(isFinal){
                    Docomo.sharedInstance.getResponse(text: inputText)
                }
            }
            
            // エラーがある、もしくは最後の認識結果だった場合の処理
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.audioInputButton.isEnabled = true
                self.audioStatusLabel.text = "音声認識スタート"
            }
        }
        
        // マイクから取得した音声バッファをリクエストに渡す
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        try startAudioEngine()
    }
    
    private func refreshTask() {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
    }
    
    private func startAudioEngine() throws {
        // startの前にリソースを確保しておく。
        audioEngine.prepare()
        
        try audioEngine.start()
        
        audioStatusLabel.text = "どうぞ喋ってください。"
    }

}

