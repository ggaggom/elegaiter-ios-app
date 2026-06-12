//
//  ArcadeGameConfig.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation

/// 아케이드 게임 설정 상수
/// 
/// Android의 `ArcadeGameConfig` object를 Swift로 변환
enum ArcadeGameConfig {
    // 충돌 박스 계산
    static let collisionThresholdTop: Float = 1.2
    
    // 장애물 판정 범위
    /// 이 위치 전까지만 충돌 인정
    static let obstacleHitboxMaxBias: Float = 2.8
    /// 장애물이 이 위치 넘으면 회피 성공
    static let obstaclePassBias: Float = 2.8
    /// 장애물이 이 위치 넘으면 삭제
    static let obstacleRemoveBias: Float = 3.0
    /// 캐릭터가 이 값보다 위로 올라가면 장애물 회피 인정
    static let safeAltitudeBias: Float = 0.6
    
    // 스폰 타이밍
    /// 최소 스폰 간격 (밀리초)
    static let spawnDelayMin: Int64 = 9000
    /// 최대 스폰 간격 (밀리초)
    static let spawnDelayMax: Int64 = 16500
    /// 더블 스폰 확률 (0.0 ~ 1.0)
    static let doubleSpawnChance: Double = 0.3
    
    // 장애물 속도
    /// 장애물 최소 이동 시간 (밀리초)
    static let obstacleDurationMin: Int64 = 6000
    /// 장애물 최대 이동 시간 (밀리초)
    static let obstacleDurationMax: Int64 = 9000
    /// 더블 스폰 시 두 번째 장애물 이동 시간 (밀리초)
    static let obstacleDurationDoubleSpawn: Int64 = 10000
}

