//
//  IScanningCodeReporting.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 04/04/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

import Foundation

protocol IScanningCodeReporting {
    func scannedCodeAccepted(code: String)
    func scannedCodeRejected(code: String)
}
