//
//  ActiveObstacle.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation
import SwiftUI

/// 장애물 상태를 관리하는 클래스
/// 
/// Android의 `ActiveObstacle` class를 Swift로 변환
/// - 이미지 리소스, 이동 속도, 시작 시간 등을 관리
/// - Y축 위치(bias), 크기(scale), 통과 여부 등을 상태로 관리
class ActiveObstacle: ObservableObject, Identifiable {
    /// 고유 식별자 (SwiftUI ForEach에서 사용)
    let id = UUID()
    
    /// 장애물 이미지 리소스 이름
    let imageRes: String
    
    /// 이동 시간 (밀리초)
    let speedDuration: Int64
    
    /// 시작 시간 (밀리초)
    let startTime: Int64
    
    /// Y축 위치 (-0.3 ~ 4.2)
    @Published var bias: Float = 0
    
    /// 크기 (0.15 ~ 1.15)
    @Published var scale: Float = 0
    
    /// 이미 지나갔거나 충돌했는지 여부
    var passed: Bool = false
    
    /// 충돌 여부 (충돌 시 투명도 감소 효과용)
    @Published var isCollided: Bool = false
    
    /// 화면에 보여줄지 여부를 로직에서 판단
    @Published var isVisible: Bool = false
    
    init(
        imageRes: String,
        speedDuration: Int64 = 6000,
        startTime: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.imageRes = imageRes
        self.speedDuration = speedDuration
        self.startTime = startTime
    }
}

