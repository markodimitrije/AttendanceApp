//
//  CodeReportApiControllerFactory.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 31/03/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

class CodeReportApiControllerFactory {
    static func make() -> ICodeReportApiController {
        return CodeReportApiController(apiController: ApiController.shared)
    }
}
