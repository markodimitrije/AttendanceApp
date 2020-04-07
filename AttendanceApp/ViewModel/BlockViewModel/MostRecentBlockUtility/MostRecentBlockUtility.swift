//
//  MostRecentBlockUtility.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 03/04/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

import Foundation

protocol IMostRecentBlockUtility {
    func getMostRecentSession(blocksSortedByDate: [IBlock]) -> IBlock?
}

class MostRecentBlockUtility: IMostRecentBlockUtility {
    
    func getMostRecentSession(blocksSortedByDate: [IBlock]) -> IBlock? {
        
        let todayBlocks = blocksSortedByDate.filter {
            return Calendar.current.compare(Date.now,
                                            to: $0.getStartsAt(),
                                            toGranularity: Calendar.Component.day) == ComparisonResult.orderedSame
        }
        
        let actualOrNextInFiftheenMinutes =
            todayBlocks.filter { block -> Bool in
                let startsAt = block.getStartsAt()
                return startsAt.addingTimeInterval(-MyTimeInterval.waitToMostRecentSession) < Date.now
            }.last
        
        return actualOrNextInFiftheenMinutes
    }
}
