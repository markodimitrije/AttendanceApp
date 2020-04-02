//
//  File.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 22/11/2018.
//  Copyright © 2018 Navus. All rights reserved.
//

import RxSwift
import RxCocoa

final class SettingsViewModel: ViewModelType {
    
    var dataAccess: DataAccess
    private let initialRoom: Room?
    private let initialBlock: Block?
    private let initialDate: Date?
    private let initialAutoSwitch: Bool
    
    init(dataAccess: DataAccess) {
        self.dataAccess = dataAccess
        // room
        if let roomId = self.dataAccess.userSelection.roomId {
           initialRoom = RoomRepository().getRoom(id: roomId) as? Room
        } else {
            initialRoom  = nil
        }
        //block
        if let blockId = self.dataAccess.userSelection.blockId {
            initialBlock = BlockRepository().getBlock(id: blockId) as? Block
        } else {
            initialBlock = nil
        }
        self.initialDate = self.dataAccess.userSelection.selectedDate
        self.initialAutoSwitch = self.dataAccess.userSelection.autoSwitch
    }
    
    func transform(input: Input) -> Output {
        
        let roomTxt = input.roomSelected.map { room -> String in
            return room?.name ?? RoomTextData.selectRoom
        }
        
        let interval = MyTimeInterval.waitToMostRecentSession
        let autoSessionDriver =
            Driver.combineLatest(input.roomSelected, input.sessionSwitch) {
                (room, switchIsOn) -> Block? in
            guard let roomId = room?.id else {
                return nil
            }
            if switchIsOn {
                let autoModelView = AutoSelSessionWithWaitIntervalViewModel.init(roomId: roomId)
                autoModelView.inSelTimeInterval.onNext(interval)
                return try! autoModelView.selectedSession.value() ?? nil // pazi ovde !! try !
            }
            return nil
        }.skip(1)
        
        let manualAndAutoSession = Driver.merge([input.sessionSelected, autoSessionDriver]).debug()
        let a = input.roomSelected.map { _ -> Void in return () }
        let b = input.sessionSelected.map { _ -> Void in return () }
        let c = autoSessionDriver.map { _ -> Void in return () }
        
        let composeAllEvents = Driver.merge([a,b,c])

        let saveSettingsAllowed = composeAllEvents.withLatestFrom(manualAndAutoSession)
            .map { block -> Bool in
                return block != nil
            }
        
        let sessionTxt =
            Driver.combineLatest(manualAndAutoSession, input.sessionSwitch) {
            (block, state) -> String in
                if let name = block?.name {
                    return name
                } else {
                    if state {
                        return SessionTextData.noAutoSessAvailable
                    } else {
                        return SessionTextData.selectSessionManually
                    }
                }
        }
        
        let saveCancelTrig = Driver.merge([input.cancelTrigger.map {return false},
                                           input.saveSettingsTrigger.map {return true}])
        
        //roomDriver
        let finalRoom = Driver.combineLatest(input.roomSelected, saveCancelTrig).map {
            $1 ? $0 : self.initialRoom
        }
        
        //sessionDriver
        let finalSession = Driver.combineLatest(manualAndAutoSession, saveCancelTrig).map {
            $1 ? $0 : self.initialBlock
        }
        
        //autoSwitchDriver
        let compositeSwitch: Driver<Bool> =
        Driver.merge(input.blockSelectedManually.map {_ in return false},
                                                     input.sessionSwitch)//.debug()
        
        let finalAutoSwitch = Driver.combineLatest(compositeSwitch, saveCancelTrig).map {
            $1 ? $0 : self.initialAutoSwitch
        }
        
        let finalDateSelected = Driver.combineLatest(manualAndAutoSession, saveCancelTrig).map {
            $1 ? $0?.getStartsAt() : self.initialDate
        }
        
        let sessionInfo = Driver.combineLatest(finalRoom,
                                               finalSession,
                                               finalDateSelected,
                                               finalAutoSwitch) {

            (room, session, date, autoSwitch) -> (Int, Int)? in

            self.dataAccess.userSelection = (room?.id, session?.id, date, autoSwitch) // MUST !

            guard let roomId = room?.id, let sessionId = session?.id else { return nil}

            return (roomId, sessionId)
        }
        
        
        let dateTxt = input.dateSelected.map { date -> String in
            guard let date = date else { return "Select date" }
            return date.toString(format: "yyyy-MM-dd") ?? "error converting to date"
        }
        
        return Output(roomTxt: roomTxt,
                      dateTxt: dateTxt,
                      sessionTxt: sessionTxt,
                      saveSettingsAllowed: saveSettingsAllowed,
                      selectedBlock: finalSession,
                      compositeSwitch: finalAutoSwitch,
                      sessionInfo: sessionInfo)
    }
}
