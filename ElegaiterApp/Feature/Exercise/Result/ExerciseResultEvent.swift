//
//  ExerciseResultEvent.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation

/// ExerciseResult 화면의 이벤트
enum ExerciseResultEvent {
    case deleteSuccess
    case showDeleteFailedToast
    case openWebReport(url: String)
    case showWebReportError(Error)
}

