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
    
    init(dataAccess: DataAccess) {
        self.dataAccess = dataAccess
    }
    
    func transform(input: Input) -> Output {
        
        let roomTxt = input.roomSelected.map { room -> String in
            return room?.name ?? RoomTextData.selectRoom
        }
        
        let autoSessionDriver = Driver.combineLatest(input.roomSelected.startWith(nil),
                                                     input.autoSelSessionSwitch.startWith(true),
                                                     input.waitInterval.startWith(MyTimeInterval.waitToMostRecentSession)) { (room, switchIsOn, interval) -> Block? in
            guard let roomId = room?.id else {return nil}
            if switchIsOn {
                let autoModelView = AutoSelSessionWithWaitIntervalViewModel.init(roomId: roomId)
                autoModelView.inSelTimeInterval.onNext(interval)
                return try! autoModelView.selectedSession.value() ?? nil // pazi ovde !! try !
            }
            return nil
        }
        
        let manualAndAutoSession = Driver.merge([input.sessionSelected, autoSessionDriver])//.debug()
        let a = input.roomSelected.map { _ -> Void in return () }
        let b = input.sessionSelected.map { _ -> Void in return () }
        let c = autoSessionDriver.map { _ -> Void in return () }
        
        let composeAllEvents = Driver.merge([a,b,c])

        let saveSettingsAllowed = composeAllEvents.withLatestFrom(manualAndAutoSession)
            .map { block -> Bool in
                return block != nil
            }
        
        let sessionTxt = Driver.combineLatest(manualAndAutoSession.startWith(nil),
                                        input.autoSelSessionSwitch.startWith(true)) { (block, state) -> String in
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
        
        let finalSession = Driver.combineLatest(manualAndAutoSession, saveCancelTrig) {
            (session, tap) -> Block? in
                if tap {
                    return session
                } else {
                    return nil
                }
        }
        
        let compositeSwitch: Driver<Bool> = Driver.merge(input.blockSelectedManually.map {_ in return false},
                                                         input.autoSelSessionSwitch).debug()
        
        let sessionInfo = Driver.combineLatest(input.roomSelected,
                                               finalSession,
                                               input.dateSelected,
//                                               input.autoSelSessionSwitch) {
                                                compositeSwitch) {
            
            (room, session, date, autoSwitch) -> (Int, Int)? in

            print("emitovao je pre self.dataAccess.userSelection = , autoSwitch-compositeSwitch = \(autoSwitch) ")
            
            self.dataAccess.userSelection = (room?.id, session?.id, date, autoSwitch) // javi svom modelu, side effect

            guard let roomId = room?.id, let sessionId = session?.id else {
                return nil
            }
            
            return (roomId, sessionId)
        }
        
        let dateTxt = input.dateSelected.map { date -> String in
            let text = date?.toString(format: "yyyy-MM-dd") ?? "error converting to date"
            return text
        }
        
        return Output(roomTxt: roomTxt,
                      dateTxt: dateTxt,
                      sessionTxt: sessionTxt,
                      saveSettingsAllowed: saveSettingsAllowed,
                      selectedBlock: finalSession,
                      compositeSwitch: compositeSwitch,
                      sessionInfo: sessionInfo
        )
    }
}

// SettingsViewModel ima direktno povezan wi-fi observer (nije dosledno kodu u ovoj klasi....)

extension SettingsViewModel {
    struct Input {
        let cancelTrigger: Driver<Void>
        let saveSettingsTrigger: Driver<Void>
        let dateSelected: Driver<Date?>
        let roomSelected: Driver<Room?>
        let sessionSelected: Driver<Block?>
        let autoSelSessionSwitch: Driver<Bool>
        let blockSelectedManually: Driver<Bool>//self.tableView.rx.itemSelected.asDriver()
        let waitInterval: Driver<TimeInterval>
    }
    
    struct Output {
        let roomTxt: Driver<String>
        let dateTxt: Driver<String>
        let sessionTxt: Driver<String>
        let saveSettingsAllowed: Driver<Bool>
        let selectedBlock: Driver<Block?>
        let compositeSwitch: Driver<Bool>
        let sessionInfo: Driver<(Int, Int)?>
    }
}

