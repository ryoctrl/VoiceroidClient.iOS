//
//  Docomo.swift
//  VoiceroidClient
//
//  Created by mosin on 2018/03/24.
//  Copyright © 2018年 mosin. All rights reserved.
//

import Foundation
//import swiftyJSON

class Docomo {
    static let sharedInstance: Docomo = Docomo()
    let content_type = "application/json"
    let api_key = Consts.api_key
    
    
    func getResponse(text: String) {
        let request: Request = Request()

        let url: URL = URL(string: "https://api.apigw.smt.docomo.ne.jp/dialogue/v1/dialogue/?APIKEY=\(api_key)")!
        
        let data: NSMutableDictionary = NSMutableDictionary()
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
        
        
        do {
            try request.post(url: url, body: data, completionHandler: { data, response, error in
                if(!(error != nil)){
                    //let response = JSON(data: data!)
                    print(String(data: data!, encoding: .utf8))
                    //ViewController.sharedInstance!.speakProcess(response["utt"]!)
                }
            })
        } catch {
            print("network error")
        }
    }
}
