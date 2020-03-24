//
//  GlobalVars.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 30/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation

var settingsJourney = SettingsJourney()

let hourMinuteSet = Set<Calendar.Component>.init(arrayLiteral: .hour, .minute)

var defaultAutoSessionDate: Date {
    return Date.init(timeIntervalSinceNow: -MyTimeInterval.waitToMostRecentSession)
}

var resourcesState: ResourcesState!

var codesDumper: CodesDumper! // prazni codes (saved in Realm), koji su failed da se prijave pojedinacno na web

var NOW: Date {
    return Date.init(timeIntervalSinceNow: 0)
}

//let conferenceId = 7498 // hard-coded!

let conferenceState = ConferenceApiKeyState()
