//
//  YSC_SpineJSON.swift
//  YSC_SKSpine_New
//
//  Created by 최윤석 on 2015. 11. 5..
//  Copyright © 2015년 Yoonsuk Choi. All rights reserved.
//

import Foundation

class YSC_SpineJSONTools {
    func readJSONFile(name:String) -> JSON {
        
        let path = NSBundle.mainBundle().pathForResource(name, ofType: "json")
        var jsonData = NSData()
        do {
            jsonData = try NSData(contentsOfFile: path!, options: .DataReadingUncached)
        } catch let error as NSError {
            print(error.domain)
        }
        let jsonResult = JSON(data: jsonData)
        
        return jsonResult
    }
}