//
//  SemiCircularProgressBar.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 반원형 프로그레스 바 컴포넌트
/// 
/// Android의 `SemiCircularProgressBar`를 SwiftUI로 변환
/// - 목표 달성률을 반원형으로 표시
/// - fillMaxWidth()와 aspectRatio(2f)를 사용하여 반원 비율 유지
struct SemiCircularProgressBar: View {
    /// 진행률 (0.0 ~ 1.0)
    let progress: Float
    /// 선 두께 (안드로이드: 기본값 20.dp)
    var strokeWidth: CGFloat = 20
    /// 원의 크기를 줄이는 패딩 (기본값 0, 선 두께는 유지하면서 원 크기만 조정)
    var radiusPadding: CGFloat = 0
    /// 배경 색상 (기본값: Background.light)
    var backgroundColor: Color = ElegaiterColors.Background.light
    
    /// 애니메이션 시작 여부
    @State private var shouldAnimate: Bool = false
    
    var body: some View {
        ZStack {
            // 배경 아크 (안드로이드: solidBrush, sweepAngle = 180f)
            SemiCircle(radiusPadding: radiusPadding)
                .stroke(
                    backgroundColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .aspectRatio(2.0, contentMode: .fit)
            
            // 진행률 아크 (안드로이드: progressBrush = Green300, sweepAngle = 180f * cappedProgress)
            SemiCircle(radiusPadding: radiusPadding)
                .trim(from: 0.0, to: shouldAnimate ? Double(progress).clamped(to: 0.0...1.0) : 0.0)
                .stroke(
                    ElegaiterColors.Green.green300,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .aspectRatio(2.0, contentMode: .fit)
                .animation(.linear(duration: 0.3), value: shouldAnimate ? progress : 0.0)
        }
        .frame(maxWidth: .infinity) // 안드로이드: fillMaxWidth()
        .onAppear {
            // 0.5초 지연 후 애니메이션 시작
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                shouldAnimate = true
            }
        }
        .onChange(of: progress) { _ in
            // progress가 변경될 때마다 애니메이션 재시작
            shouldAnimate = false
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                shouldAnimate = true
            }
        }
    }
}

/// 반원(Semi-Circle) Shape
/// 
/// Android의 Canvas drawArc와 동일한 방식으로 반원을 그립니다.
/// - 중심: 중앙 하단 지점 (rect.midX, rect.maxY)
/// - 반지름: width의 절반 - radiusPadding (선 두께는 유지하면서 원 크기만 조정)
/// - 시작 각도: 180도 (왼쪽)
/// - 종료 각도: 0도 (오른쪽)
struct SemiCircle: Shape {
    /// 반지름에서 빼는 값 (원의 크기를 줄이기 위해, 선 두께는 유지)
    var radiusPadding: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 중앙 하단 지점 (원의 중심이 될 곳)
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        // 반지름: width의 절반 - radiusPadding (radiusPadding을 증가시키면 원이 작아짐)
        let radius = (rect.width / 2) - radiusPadding
        
        // 반원 아크를 그림 (중앙 하단을 중심으로)
        // 시작 각도: 180도 (왼쪽)
        // 종료 각도: 0도 (오른쪽)
        // clockwise: false로 설정하여 왼쪽에서 오른쪽으로 진행 (trim과 호환)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        return path
    }
}

/// Float 값에 대한 범위 제한 확장
extension Float {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return max(range.lowerBound, min(range.upperBound, Double(self)))
    }
}

/// Double 값에 대한 범위 제한 확장
extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return max(range.lowerBound, min(range.upperBound, self))
    }
}

#Preview {
    VStack(spacing: 30) {
        SemiCircularProgressBar(progress: 0.5, strokeWidth: 20)
            .frame(height: 200)
        
        SemiCircularProgressBar(progress: 0.8, strokeWidth: 15)
            .frame(height: 150)
        
        SemiCircularProgressBar(progress: 1.0, strokeWidth: 25)
            .frame(height: 250)
    }
    .padding()
}
