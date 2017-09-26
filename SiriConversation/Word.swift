//
//  Word.swift
//  SiriConversation
//
//  Created by SuzukiShigeru on 2017/09/26.
//  Copyright © 2017年 Shigeru Suzuki. All rights reserved.
//

import Foundation
import RealmSwift

class Word: Object {
    dynamic var id = 0
    dynamic var question = ""
    dynamic var answer = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
