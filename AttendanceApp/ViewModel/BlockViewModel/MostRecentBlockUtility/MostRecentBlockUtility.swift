//
//  MostRecentBlockUtility.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 03/04/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

import Foundation

protocol IMostRecentBlockUtility {
    //func getMostRecentSession(blocksSortedByDate: [RealmBlock], date: Date?) -> RealmBlock?
    func getMostRecentSession(blocksSortedByDate: [RealmBlock]) -> RealmBlock?
}

class MostRecentBlockUtility: IMostRecentBlockUtility {
    //func getMostRecentSession(blocksSortedByDate: [RealmBlock], date: Date?) -> RealmBlock? {
    func getMostRecentSession(blocksSortedByDate: [RealmBlock]) -> RealmBlock? {
        
        let todayBlocks = blocksSortedByDate.filter {
            return Calendar.current.compare(NOW,
                                            to: Date.parse($0.starts_at),
                                            toGranularity: Calendar.Component.day) == ComparisonResult.orderedSame
        }
        
        let actualOrNextInFiftheenMinutes =
            todayBlocks.filter { block -> Bool in
                let startsAt = Date.parse(block.starts_at)
                return startsAt.addingTimeInterval(-MyTimeInterval.waitToMostRecentSession) < NOW
            }.last
        
        return actualOrNextInFiftheenMinutes
    }
}
