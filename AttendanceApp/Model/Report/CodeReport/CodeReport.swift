//
//  CodeReport.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 18/04/2019.
//  Copyright © 2019 Navus. All rights reserved.
//

import Foundation
//import Realm
//import RealmSwift

extension CodeReport: ICodeReport {
    func getCode() -> String { self.code }
    func getSessionId() -> Int { self.sessionId }
    func getDate() -> Date { self.date }
}

struct CodeReport {
    
    var code: String = ""
    var sessionId: Int = -1
    var date: Date = Date(timeIntervalSinceNow: 0)
    
    init(code: String, sessionId: Int, date: Date) {
        self.code = code
        self.sessionId = sessionId
        self.date = date
    }
    
    init(realmCodeReport: RealmCodeReport) {
        self.code = realmCodeReport.code
        self.sessionId = realmCodeReport.sessionId
        self.date = realmCodeReport.date
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
    
}
