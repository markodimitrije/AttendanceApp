//
//  IBlocksProvider.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 29/03/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

import Foundation

protocol IBlockApiController {
    func getBlocks()
}

protocol IBlockProviderWorker {
    func fetchBlocksAndPersistOnDevice() // fetchSessionsAndSaveToRealm
}
