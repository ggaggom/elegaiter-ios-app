//
//  ArcadeGameEngine.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import Foundation
import SwiftUI

/// 아케이드 게임 엔진
/// 
/// Android의 `ArcadeGameEngine` class를 Swift로 변환
/// - 장애물 스폰/이동 관리
/// - 충돌 판정
/// - 원근감 애니메이션 계산
@MainActor
class ArcadeGameEngine: ObservableObject {
    // MARK: - Published Properties
    
    /// 활성 장애물 목록 (외부에서는 읽기 전용)
    @Published private(set) var obstacles: [ActiveObstacle] = []
    
    // MARK: - Private Properties
    
    /// 장애물 이미지 리소스 이름 목록
    private let obstacleResIds = [
        "GameObstacleLog",
        "GameObstaclePuddle",
        "GameObstacleFire",
        "GameObstacleRock",
        "GameObstacleBarricade"
    ]
    
    /// 원근감 애니메이션 곡선 (Cubic Bezier)
    /// Android: CubicBezierEasing(0.9f, 0.0f, 1.0f, 1.0f)
    /// Compose의 CubicBezierEasing은 제어점 (x1, y1, x2, y2)를 받아서
    /// 시간 t에 대해 곡선의 y 좌표를 반환합니다.
    /// P0=(0,0), P1=(0.9, 0.0), P2=(1.0, 1.0), P3=(1,1)
    private let perspectiveEasing = CubicBezierEasing(
        controlPoint1: CGPoint(x: 0.9, y: 0.0),
        controlPoint2: CGPoint(x: 1.0, y: 1.0)
    )
    
    /// 다음 스폰 시간 (밀리초)
    private var nextSpawnTime: Int64 = 0
    
    // MARK: - Public Methods
    
    /// 게임 엔진 초기화
    /// 
    /// 게임을 새로 시작할 때 호출하여 모든 상태를 초기화합니다.
    func reset() {
        obstacles.removeAll()
        nextSpawnTime = 0
    }
    
    /// 매 프레임마다 호출되는 메인 업데이트 함수
    /// 
    /// Android의 `update()` 메서드를 Swift로 변환
    /// - Parameters:
    ///   - currentTime: 현재 시간 (밀리초)
    ///   - playerBias: 현재 캐릭터의 Y축 위치 (Animated value)
    ///   - isStunned: 플레이어가 현재 스턴 상태인지
    ///   - onCollision: 충돌 발생 시 콜백
    ///   - onPass: 장애물 통과(성공) 시 콜백
    ///   - onTick: 스턴 시간 감소 등을 위한 틱 콜백
    func update(
        currentTime: Int64,
        playerBias: Float,
        isStunned: Bool,
        onCollision: @escaping () -> Void,
        onPass: @escaping () -> Void,
        onTick: @escaping (Int64) -> Void
    ) {
        // 초기화 로직 (첫 실행 시 스폰 시간 설정)
        if nextSpawnTime == 0 {
            nextSpawnTime = currentTime + 3000 // 3초 후 첫 장애물 스폰
        }
        
        // 틱 업데이트 (스턴 시간 감소 등)
        // 스턴 상태가 아니어도 남은 스턴 시간이 있을 수 있으므로 항상 호출
        // decreaseStunTime 내부에서 stunRemainingMs > 0 체크를 하므로 안전함
        onTick(16) // 약 60fps 기준 1프레임 시간
        
        // 장애물 스폰
        spawnObstacles(currentTime: currentTime)
        
        // 장애물 이동 및 충돌 판정
        moveAndCheckCollisions(
            currentTime: currentTime,
            playerBias: playerBias,
            isStunned: isStunned,
            onCollision: onCollision,
            onPass: onPass
        )
    }
    
    // MARK: - Private Methods
    
    /// 장애물 스폰 로직
    private func spawnObstacles(currentTime: Int64) {
        guard currentTime >= nextSpawnTime else { return }
        
        let isDoubleSpawn = Double.random(in: 0..<1) < ArcadeGameConfig.doubleSpawnChance
        
        // 첫 번째 장애물
        addObstacle(currentTime: currentTime)
        
        // 다음 스폰 시간 설정
        let delayRange = ArcadeGameConfig.spawnDelayMin...ArcadeGameConfig.spawnDelayMax
        let randomDelay = Int64.random(in: delayRange)
        nextSpawnTime = currentTime + randomDelay
        
        // 더블 스폰 (1초 뒤 출발하는 장애물 예약)
        if isDoubleSpawn {
            addObstacle(
                currentTime: currentTime,
                startDelay: 1000,
                forceDuration: ArcadeGameConfig.obstacleDurationDoubleSpawn
            )
        }
    }
    
    /// 장애물 추가
    private func addObstacle(
        currentTime: Int64,
        startDelay: Int64 = 0,
        forceDuration: Int64? = nil
    ) {
        let duration = forceDuration ?? (Double.random(in: 0..<1) < 0.5 ? ArcadeGameConfig.obstacleDurationMin : ArcadeGameConfig.obstacleDurationMax)
        
        let randomImageRes = obstacleResIds.randomElement() ?? obstacleResIds[0]
        
        let obstacle = ActiveObstacle(
            imageRes: randomImageRes,
            speedDuration: duration,
            startTime: currentTime + startDelay
        )
        
        obstacles.append(obstacle)
    }
    
    /// 장애물 이동 및 충돌 판정
    private func moveAndCheckCollisions(
        currentTime: Int64,
        playerBias: Float,
        isStunned: Bool,
        onCollision: @escaping () -> Void,
        onPass: @escaping () -> Void
    ) {
        var obstaclesToRemove: [UUID] = []
        
        for obstacle in obstacles {
            // 아직 시작 시간 전인 장애물(더블 스폰 대기 등)은 처리 안 함
            if currentTime < obstacle.startTime {
                continue
            }
            
            // --- [이동 로직] ---
            // 안드로이드: val rawProgress = (elapsed.toFloat() / obs.speedDuration).coerceIn(0f, 1.2f)
            //            val easedProgress = perspectiveEasing.transform(rawProgress.coerceAtMost(1f))
            // easing 계산 시에는 최대값을 1.0으로 제한하여 0~1.0 구간만 easing 곡선 적용
            // 1.0~1.2 구간은 선형으로 진행 (easing 곡선이 1.0을 넘어서도 적용되지 않도록)
            let elapsed = currentTime - obstacle.startTime
            let rawProgress = Float(elapsed) / Float(obstacle.speedDuration)
            let clampedProgress = min(max(rawProgress, 0), 1.2)
            // easing 계산 시 최대값을 1.0으로 제한 (안드로이드와 동일)
            let easedProgress = perspectiveEasing.transform(min(clampedProgress, 1.0))
            
            obstacle.bias = -0.3 + (4.2 * easedProgress)
            obstacle.scale = 0.15 + (1.0 * easedProgress)
            obstacle.isVisible = true
            
            // --- [충돌/판정 로직] ---
            if !obstacle.passed {
                // 캐릭터가 (장애물에 맞을 만큼) 충분히 낮게(아래에) 있는가?
                // 안드로이드: val isLowEnoughToHit = playerBias > ArcadeGameConfig.SAFE_ALTITUDE_BIAS
                // playerBias > 0.6이면 낮은 위치(바닥 근처)를 의미하므로 충돌 가능
                let isLowEnoughToHit = playerBias > ArcadeGameConfig.safeAltitudeBias
                
                // 히트박스 진입 여부
                // 안드로이드: val inHitBox = obs.bias > ArcadeGameConfig.COLLISION_THRESHOLD_TOP &&
                //                        obs.bias < ArcadeGameConfig.OBSTACLE_HITBOX_MAX_BIAS
                let inHitBox = obstacle.bias > ArcadeGameConfig.collisionThresholdTop &&
                               obstacle.bias < ArcadeGameConfig.obstacleHitboxMaxBias
                
                // 안드로이드: if (inHitBox && isLowEnoughToHit)
                if inHitBox && isLowEnoughToHit {
                    // 충돌!
                    if !isStunned {
                        onCollision()
                    }
                    obstacle.passed = true
                    obstacle.isCollided = true
                } else if obstacle.bias > ArcadeGameConfig.obstaclePassBias {
                    // 회피 성공!
                    onPass()
                    obstacle.passed = true
                }
            }
            
            // --- [삭제 로직] ---
            if obstacle.bias > ArcadeGameConfig.obstacleRemoveBias {
                obstaclesToRemove.append(obstacle.id)
            }
        }
        
        // 삭제할 장애물 제거
        obstacles.removeAll { obstaclesToRemove.contains($0.id) }
    }
}

// MARK: - Cubic Bezier Easing Helper

/// Cubic Bezier Easing 계산을 위한 헬퍼 클래스
/// 
/// Android의 `CubicBezierEasing`을 Swift로 변환
private class CubicBezierEasing {
    private let controlPoint1: CGPoint
    private let controlPoint2: CGPoint
    
    init(controlPoint1: CGPoint, controlPoint2: CGPoint) {
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
    }
    
    /// 입력값(0~1)을 변환하여 반환
    /// 
    /// 안드로이드 Compose의 CubicBezierEasing.transform()은
    /// 시간 t에 대해 곡선의 y 좌표를 반환합니다.
    /// 
    /// 곡선: P0=(0,0), P1=(controlPoint1.x, controlPoint1.y), 
    ///       P2=(controlPoint2.x, controlPoint2.y), P3=(1,1)
    /// 
    /// 시간 t에 대해 y 좌표를 계산하여 반환
    func transform(_ t: Float) -> Float {
        let clampedT = min(max(t, 0), 1)
        // y 좌표 계산 (안드로이드와 동일)
        return Float(cubicBezierY(
            t: Double(clampedT),
            p0y: 0.0,
            p1y: Double(controlPoint1.y),
            p2y: Double(controlPoint2.y),
            p3y: 1.0
        ))
    }
    
    /// Cubic Bezier 곡선의 y 좌표 계산
    /// 
    /// 안드로이드 Compose의 CubicBezierEasing은 시간 t에 대해 곡선의 y 좌표를 반환
    /// 곡선 공식: (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
    private func cubicBezierY(t: Double, p0y: Double, p1y: Double, p2y: Double, p3y: Double) -> Double {
        let oneMinusT = 1.0 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT
        let tSquared = t * t
        let tCubed = tSquared * t
        
        return oneMinusTCubed * p0y +
               3 * oneMinusTSquared * t * p1y +
               3 * oneMinusT * tSquared * p2y +
               tCubed * p3y
    }
}

