//
//  CountdownProgressBar.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 카운트다운 프로그레스 바 컴포넌트
/// 
/// Android의 `CountdownProgressBar`를 SwiftUI로 변환
/// - 원형 프로그레스 바로 남은 시간을 시각화
/// - 중앙에 남은 초 표시
struct CountdownProgressBar: View {
    /// 전체 시간 (초)
    let totalSeconds: Int
    /// 남은 시간 (초)
    let remainingTime: Int
    /// 크기 (안드로이드 기본값: 120.dp)
    var size: CGFloat = 120
    /// 스트로크 너비 (안드로이드 기본값: 8.dp)
    var strokeWidth: CGFloat = 8
    /// 진행률 브러시 (안드로이드 기본값: Green300 그라데이션)
    var progressColor: Color = ElegaiterColors.Green.green300
    /// 배경색 (안드로이드 기본값: Transparent)
    var backgroundColor: Color = .clear
    /// 텍스트 색상 (안드로이드 기본값: White)
    var textColor: Color = .white
    
    /// 진행률 (0.0 ~ 1.0)
    /// 안드로이드: remainingTime.toFloat().coerceAtLeast(0f) / totalSeconds.toFloat()
    private var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        let safeRemainingTime = max(remainingTime, 0)
        return Double(safeRemainingTime) / Double(totalSeconds)
    }
    
    /// 애니메이션된 진행률
    /// 안드로이드: animateFloatAsState(targetValue = progress, animationSpec = tween(durationMillis = 950))
    /// remainingTime이 변경될 때마다 새로운 애니메이션이 시작되도록 함
    @State private var animatedProgress: Double = 1.0
    /// 이전 remainingTime 값 추적 (변경 감지용)
    @State private var previousRemainingTime: Int? = nil
    
    /// 애니메이션 duration (안드로이드: 950ms)
    private let animationDuration: Double = 0.95
    
    var body: some View {
        ZStack {
            // 배경 원 (안드로이드: backgroundColor, 기본값 Transparent)
            if backgroundColor != .clear {
                Circle()
                    .stroke(backgroundColor, lineWidth: strokeWidth)
                    .frame(width: size, height: size)
            }
            
            // 진행률 원 (안드로이드: progressBrush, 기본값 Green300 그라데이션)
            // 안드로이드: sweepAngle = -360f * animatedProgress (시계 반대 방향)
            // 시작 시 전체 원(progress=1.0)이 그려지고, 카운트다운 시 오른쪽 방향으로 제거됨
            Circle()
                .trim(from: 1.0 - animatedProgress, to: 1.0)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // 12시 방향에서 시작
            
            // 중앙 텍스트 (안드로이드: ElegaiterTypography.Display1)
            Text("\(remainingTime)")
                .typography(ElegaiterTypography.Display1)
                .foregroundColor(textColor)
        }
        .onChange(of: remainingTime) { newValue in
            // remainingTime이 변경될 때마다 새로운 애니메이션 시작
            // 안드로이드의 animateFloatAsState와 동일한 동작
            let newProgress = Double(max(newValue, 0)) / Double(totalSeconds)
            
            // 이전 값과 다를 때만 애니메이션
            // 안드로이드: tween(durationMillis = 950) - 기본 easing 사용
            if previousRemainingTime == nil || previousRemainingTime != newValue {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    animatedProgress = newProgress
                }
            }
            
            // previousRemainingTime 업데이트
            previousRemainingTime = newValue
        }
        .onAppear {
            // 초기값 설정 (애니메이션 없이)
            // 시작 시 전체 원이 그려진 상태 (progress = 1.0)
            let initialProgress = progress
            animatedProgress = initialProgress
            // previousRemainingTime은 nil로 두어 첫 번째 onChange에서 감지되도록 함
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            CountdownProgressBar(totalSeconds: 5, remainingTime: 5)
            CountdownProgressBar(totalSeconds: 5, remainingTime: 3)
            CountdownProgressBar(totalSeconds: 5, remainingTime: 1)
            CountdownProgressBar(totalSeconds: 10, remainingTime: 7)
        }
    }
}
