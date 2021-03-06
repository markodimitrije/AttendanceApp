//
//  CodeReport.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 18/04/2019.
//  Copyright © 2019 Navus. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class CodeReport: Object { // Realm Entity
    
    var code: String = ""
    var sessionId: Int = -1
    var date: Date = Date(timeIntervalSinceNow: 0)
    
    init(code: String, sessionId: Int, date: Date) {
        self.code = code
        self.sessionId = sessionId
        self.date = date
        super.init()
    }
    
    init(realmCodeReport: RealmCodeReport) {
        self.code = realmCodeReport.code
        self.sessionId = realmCodeReport.sessionId
        self.date = realmCodeReport.date ?? Date(timeIntervalSinceNow: 0)
        super.init()
    }
    
    func getPayload() -> [String: String] {
        
        return [
            "block_id": "\(sessionId)",
            "code": trimmedToSixCharactersCode(code: code),
            "time_of_scan": date.toString(format: Date.defaultFormatString) ?? ""
        ]
    }
    
    static func getPayload(_ report: CodeReport) -> [String: String] {
        
        return [
            "block_id": "\(report.sessionId)",
            "code": trimmedToSixCharactersCode(code: report.code),
            "time_of_scan": report.date.toString(format: Date.defaultFormatString) ?? ""
        ]
    }
    
    static func getPayload(_ reports: [CodeReport]) -> [String: Any] {
        
        let listOfReports = reports.map {getPayload($0)}
        
        return ["data": listOfReports]
    }
    
    // kompajler me tera da implementiram, mogu li ikako bez toga ? ...
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
}
