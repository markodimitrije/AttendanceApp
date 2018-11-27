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
    
    func transform(input: Input) -> Output {
        
        let roomTxt = input.roomSelected.map { room -> String in
            return room?.name ?? RoomTextData.selectRoom
        }
        
        let autoSessionDriver = Driver.combineLatest(input.roomSelected, input.autoSelSessionSwitch.startWith(true), input.picker) { (room, switchIsOn, interval) -> RealmBlock? in
            guard let roomId = room?.id else {return nil}
            if switchIsOn {
                let autoModelView = AutoSelSessionWithWaitIntervalViewModel.init(roomId: roomId)
                autoModelView.inSelTimeInterval.onNext(interval)
                return try! autoModelView.selectedSession.value() ?? nil // pazi ovde !! try !
            }
            return nil
        }
        
        
        
//        // mislim da treba 3 signala da combine da bih izvukao i roomId
//        let autoSessionDriver = Driver.combineLatest(input.autoSelSessionSwitch.startWith(true), input.picker) { (switchIsOn, interval) -> RealmBlock? in
//            if switchIsOn {
//                let autoModelView = AutoSelSessionWithWaitIntervalViewModel.init(roomId: 4008) // hard-coded!
//                autoModelView.inSelTimeInterval.onNext(interval)
//                return try! autoModelView.selectedSession.value() ?? nil // pazi ovde !! try !
//            }
//            return nil
//        }
        
        let finalSession = Driver.merge([input.sessionSelected, autoSessionDriver])//.debug()
        let a = input.roomSelected.map { _ -> Void in return () }
        let b = input.sessionSelected.map { _ -> Void in return () }
        let c = autoSessionDriver.map { _ -> Void in return () }
        
        let composeAllEvents = Driver.merge([a,b,c])

        let saveSettingsAllowed = composeAllEvents.withLatestFrom(finalSession)
            .map { block -> Bool in
                return block != nil
            }.debug()

        let cancelTap = input.cancelTrigger.map {return false}
        let saveTap = input.saveSettingsTrigger.withLatestFrom(saveSettingsAllowed)
        
        let settingsCorrect = Driver
                                .merge([cancelTap, saveTap])
        
        let sessionTxt = finalSession.map { block -> String in
            if let name = block?.name {
                return name
            } else {
                return SessionTextData.noAutoSessAvailable
            }
        }
        
        return Output(roomTxt: roomTxt,
                      sessionTxt: sessionTxt,
                      saveSettingsAllowed: saveSettingsAllowed,
//                      wiFiStaticTxt: editing,
//                      wiFiDynamicTxt: post,
                      settingsCorrect: settingsCorrect
        )
    }
}

extension SettingsViewModel {
    struct Input {
        let cancelTrigger: Driver<Void>
        let saveSettingsTrigger: Driver<Void>
        let roomSelected: Driver<RealmRoom?>
        let sessionSelected: Driver<RealmBlock?>
        let autoSelSessionSwitch: Driver<Bool>
        let picker: Driver<TimeInterval>
//        let internetConnection: Driver<Bool>
//        let unsyncScans: Driver<Int>
    }
    
    struct Output {
        let roomTxt: Driver<String>
        let sessionTxt: Driver<String>
        let saveSettingsAllowed: Driver<Bool>
//        let wiFiStaticTxt: Driver<String>
//        let wiFiDynamicTxt: Driver<String>
        let settingsCorrect: Driver<Bool>
    }
}

