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
    
    //入力フィールド
    @IBOutlet weak var wordField: UITextField!
    //決定ボタン
    @IBOutlet weak var button: UIButton!
    //ラベル
    @IBOutlet weak var label: UILabel!
    
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
        
        speechRecognizer.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendButton(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            button.isEnabled = false
            button.setTitle("停止中", for: .disabled)
        } else {
            try! startRecording()
            button.setTitle("音声認識を中止", for: [])
        }
        
    }
    
    @IBAction func pushExtButton(_ sender: Any) {
        speakProcess("ぷろせす")
    }
    func speakProcess(_ text: String) {
        let word = text
        let request: Request = Request()
        
        //let url: URL = URL(string: "https://voiceroid.mosin.jp/")!
        let url: URL = URL(string: "http://mosin.jp:7180")!
        let params: [String:Any] = [
            "CV": "YUKARI_EX",
            "DO": "SAVE",
            "INTONATION": 1,
            "PITCH": 1,
            "SPEED": 1,
            "VOLUME": 1,
            "TALKTEXT": word
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
            print(AVAudioSession.sharedInstance().outputVolume)
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
            button.isEnabled = true
            button.setTitle("音声認識スタート", for: [])
        } else {
            button.isEnabled = false
            button.setTitle("音声認識ストップ", for: .disabled)
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
                    self.button.isEnabled = true
                    
                case .denied:
                    self.button.isEnabled = false
                    self.button.setTitle("音声認識へのアクセスが拒否されています。", for: .disabled)
                    
                case .restricted:
                    self.button.isEnabled = false
                    self.button.setTitle("この端末で音声認識はできません。", for: .disabled)
                    
                case .notDetermined:
                    self.button.isEnabled = false
                    self.button.setTitle("音声認識はまだ許可されていません。", for: .disabled)
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
        recognitionRequest.shouldReportPartialResults = false
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let `self` = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let inputText = result.bestTranscription.formattedString
                self.speakProcess(inputText)
                self.label.text = inputText
                isFinal = result.isFinal
            }
            
            // エラーがある、もしくは最後の認識結果だった場合の処理
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.button.isEnabled = true
                self.button.setTitle("音声認識スタート", for: [])
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
        
        label.text = "どうぞ喋ってください。"
    }

}

