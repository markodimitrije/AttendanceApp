//
//  DataAccess.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 04/12/2018.
//  Copyright © 2018 Navus. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Realm
import RealmSwift

class DataAccess: NSObject {
    
    lazy private var _roomSelected = BehaviorRelay<Int?>.init(value: roomInitial)
    lazy private var _blockSelected = BehaviorRelay<Block?>.init(value: sessionInitial)
    lazy private var _dateSelected = BehaviorRelay<Date?>.init(value: dateInitial)
    lazy private var _autoSwitchSelected = BehaviorRelay<Bool>.init(value: autoSwitchInitial)
    
    private var roomInitial: Int?
    private var sessionInitial: Block?
    private var dateInitial: Date?
    private var autoSwitchInitial: Bool
    
    static var shared = DataAccess()
    
    // API: input, output
    var userSelection: (roomId: Int?, blockId: Int?, selectedDate: Date?, autoSwitch: Bool) {
        get {
            return (UserDefaults.standard.value(forKey: "roomId") as? Int,
                    UserDefaults.standard.value(forKey: "sessionId") as? Int,
                    UserDefaults.standard.value(forKey: "date") as? Date,
                    UserDefaults.standard.value(forKey: "autoSwitch") as? Bool ?? true
            )
        }
        set {
            UserDefaults.standard.set(newValue.0, forKey: "roomId")
            UserDefaults.standard.set(newValue.1, forKey: "sessionId")
            UserDefaults.standard.set(newValue.2, forKey: "date")
            UserDefaults.standard.set(newValue.3, forKey: "autoSwitch")
            userDefaultsIsUpdated(forKeyPath: "roomId")
            userDefaultsIsUpdated(forKeyPath: "sessionId")
            userDefaultsIsUpdated(forKeyPath: "date")
            userDefaultsIsUpdated(forKeyPath: "autoSwitch")
        }
    }
    
    // API: output
    var output: Observable<(Int?, Block?, Date?, Bool)> {
        return Observable.combineLatest(_roomSelected.asObservable(),
                                        _blockSelected.asObservable(),
                                        _dateSelected.asObservable(),
                                        _autoSwitchSelected.asObservable(),
            resultSelector: { (room, block, date, autoSwitch) -> (Int?, Block?, Date?, Bool) in
            //print("emitujem iz DataAccess..room i session za.... \(room?.id), \(block?.id), sa blockName = \(block?.name ?? "no  name")")
            return (room, block, date, autoSwitch)
        })
    }
    
    override init() {
        
        self.roomInitial = UserDefaults.standard.value(forKey: "roomId") as? Int
        
        if let sessionId = UserDefaults.standard.value(forKey: "sessionId") as? Int {
            self.sessionInitial = BlockRepository().getBlock(id: sessionId) as? Block
        } else {sessionInitial = nil}
        
        dateInitial = UserDefaults.standard.value(forKey: "date") as? Date
        autoSwitchInitial = UserDefaults.standard.value(forKey: "autoSwitch") as? Bool ?? true
        
        super.init()
    }
    
    private func userDefaultsIsUpdated(forKeyPath keyPath: String?) {
        
        guard let keyPath = keyPath else {return}
        guard let realm = try? Realm.init() else {return}
        
        if keyPath == "roomId" {
            let roomId = UserDefaults.standard.value(forKey: keyPath) as? Int
            _roomSelected.accept(roomId)
        } else if keyPath == "sessionId" {
            guard let sessionId = UserDefaults.standard.value(forKey: keyPath) as? Int,
                let realmBlock = RealmBlock.getBlock(withId: sessionId, withRealm: realm) else {
                    return
            }
            let block = BlockFactory.make(from: realmBlock) as! Block
            _blockSelected.accept(block)
        } else if keyPath == "date" {
            guard let date = UserDefaults.standard.value(forKey: keyPath) as? Date else {
                return
            }
            _dateSelected.accept(date)
        } else if keyPath == "autoSwitch" {
            guard let autoSwitch = UserDefaults.standard.value(forKey: keyPath) as? Bool else {
                return
            }
//            print("DataAccess/// emitujem state za autoSwitch = \(autoSwitch)")
            _autoSwitchSelected.accept(autoSwitch)
        }
        
    }
    
}
