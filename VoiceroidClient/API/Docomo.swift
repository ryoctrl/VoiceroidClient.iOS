//
//  Docomo.swift
//  VoiceroidClient
//
//  Created by mosin on 2018/03/24.
//  Copyright © 2018年 mosin. All rights reserved.
//

import Foundation
import SwiftyJSON

class Docomo {
    static let sharedInstance: Docomo = Docomo()

    let api_key = Consts.api_key
    var latestContext = ""
    
    enum Mode: String {
        case SIRITORI = "srtr"
        case NORMAL = "dialog"
    }
    
    //let mode: Mode = .SIRITORI
    let mode: Mode = .NORMAL
    
    
    func getResponse(text: String) {
        let request: Request = Request()

        let url: URL = URL(string: "https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue/?APIKEY=\(api_key)")!
        
        let data: NSMutableDictionary = NSMutableDictionary()
        print(text)
        data.setValue(text, forKey: "utt")
        data.setValue("もしん", forKey: "nickname")
        data.setValue("モシン", forKey: "nickname_y")
        data.setValue("男", forKey: "sex")
        data.setValue("O", forKey: "bloodtype")
        data.setValue("1998", forKey: "birthdateY")
        data.setValue("1", forKey: "birthdateM")
        data.setValue("7", forKey: "birthdateD")
        data.setValue("20", forKey: "age")
        data.setValue("山羊座", forKey: "constellations")
        data.setValue("大阪", forKey: "place")
        data.setValue(mode.rawValue, forKey: "mode")
        if latestContext != "" {
            data.setValue(latestContext, forKey: "context")
        }
        
        
        do {
            try request.post(url: url, body: data, completionHandler: { data, response, error in
                if(error == nil){
                    self.responseProcess(data)
                }
            })
        } catch {
            print("network error")
        }
    }
    
    func responseProcess(_ data: Data?) {
        do {
            let response: JSON = try JSON(data: data!)
            print(response)
            let errorCode = response["error"]["code"] == "400" ? 400 : 200
            
            var text = ""
            if(errorCode == 400){
                text = "対話APIにエラーがありました"
                ViewController.sharedInstance!.speakProcess("対話APIにエラーがありました")
            }else{
                latestContext = response["context"].string!
                text = response["utt"].string!
            }
            
            ViewController.sharedInstance!.speakProcess(text)
        }catch{
            print("JSON parse error!")
        }
        
        
    }
}
