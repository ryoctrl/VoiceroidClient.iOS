//
//  ViewController.swift
//  VoiceroidClient
//
//  Created by mosin on 2018/03/24.
//  Copyright © 2018年 mosin. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    @IBOutlet weak var wordField: UITextField!
    
    var audioPlayerInstance: AVAudioPlayer? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendButton(_ sender: Any) {
        print("sendButtonClicked")
        var word = wordField.text
        
        if word == "" {
            word = "こんにちは"
        }
        
        let request: Request = Request()
        
        let url: URL = URL(string: "https://voiceroid.mosin.jp/")!
        let params: [String:Any] = [
            "CV": "YUKARI_EX",
            "DO": "SAVE",
            "INTONATION": 1,
            "PITCH": 1,
            "SPEED": 1,
            "VOLUME": 1,
            "TALKTEXT": word!
        ]
        
        do {
            try request.post(url: url, params: params, completionHandler: { data, response, error in
                if(!(error != nil)){
                    self.playVoice(data: data!)
                }
               
            })
        } catch {
            print("network error")
        }
    }
    
    func playVoice(data: Data) {
        do {
            audioPlayerInstance = try AVAudioPlayer(data: data)
            audioPlayerInstance?.play()
        } catch {
            print("audio error")
        }
    }


}

