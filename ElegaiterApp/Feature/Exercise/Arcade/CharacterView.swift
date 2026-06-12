//
//  CharacterView.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import SwiftUI

/// 아케이드 게임 캐릭터 View
/// 
/// Android의 캐릭터 렌더링 로직을 SwiftUI로 변환
/// - 걷기/뛰기 상태에 따른 이미지 전환
/// - 프레임 애니메이션 (0.25초 간격)
/// - 위치 애니메이션 (800ms)
/// - 스턴 효과 (충돌 시)
struct CharacterView: View {
    let displayStepType: DisplayStepType
    let targetBias: Float
    let isStunned: Bool
    let isCollisionTint: Bool
    
    /// 프레임 전환을 위한 상태 (0.25초마다 토글)
    @State private var isFrameOne: Bool = true
    
    /// 스턴 회전 애니메이션 각도
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            // 안드로이드: val characterHeightRatio = 1f / 3.5f
            //            val characterSize = screenHeightDp * characterHeightRatio
            // 화면 높이의 1/3.5 (약 28.57%)로 설정
            let screenHeight = geometry.size.height
            let characterHeightRatio: CGFloat = 1.0 / 3.5
            let characterSize = screenHeight * characterHeightRatio
            
            // Bias 값을 화면 Y 좌표로 변환
            // 안드로이드: BiasAlignment(horizontalBias = 0f, verticalBias = animatedBias.value)
            // 안드로이드의 BiasAlignment는 자동으로 -1.0 ~ 1.0 범위로 제한됨
            // - verticalBias -1.0 = 화면 위쪽 끝 (상단)
            // - verticalBias 0.0 = 화면 중앙
            // - verticalBias 1.0 = 화면 아래쪽 끝 (하단)
            // 
            // targetBias: -0.7 (하늘, 위쪽) ~ 0.95 (바닥, 아래쪽)
            // 안드로이드에서는 BiasAlignment가 자동으로 범위를 제한하지만,
            // iOS에서는 수동으로 제한해야 함
            // 
            // BiasAlignment 동작 방식:
            // - 화면 중앙(0.0)을 기준으로 위치 결정
            // - 화면 높이의 절반을 1.0 bias 단위로 사용
            // - 즉, bias 1.0 = 화면 높이의 절반만큼 아래로 이동
            let centerY = geometry.size.height / 2
            let halfHeight = geometry.size.height / 2
            
            // 안드로이드: BiasAlignment는 자동으로 -1.0 ~ 1.0 범위로 제한
            // iOS: 수동으로 제한 (안드로이드와 동일하게)
            let clampedBias = min(max(targetBias, -1.0), 1.0)
            
            // BiasAlignment 계산: centerY + (bias * halfHeight)
            // bias 0.0 = centerY (화면 중앙)
            // bias -1.0 = centerY - halfHeight = 0 (화면 상단)
            // bias 1.0 = centerY + halfHeight = screenHeight (화면 하단)
            let rawYPosition = centerY + CGFloat(clampedBias) * halfHeight
            
            // 캐릭터가 화면 밖으로 나가지 않도록 제한
            // 캐릭터의 중심점이 화면 내에 있어야 하므로, 캐릭터 크기의 절반을 고려
            let characterHalfHeight = characterSize / 2
            let minY = characterHalfHeight // 캐릭터 상단이 화면 상단을 넘지 않도록
            let maxY = geometry.size.height - characterHalfHeight // 캐릭터 하단이 화면 하단을 넘지 않도록
            let yPosition = min(max(rawYPosition, minY), maxY)
            
            ZStack {
                // 캐릭터 이미지 (안드로이드와 동일하게 단순 이미지 교체)
                // 안드로이드: currentPainter를 계산하여 Image에 직접 사용
                Image(characterImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: characterSize, height: characterSize)
                    .colorMultiply(isCollisionTint ? .red : .white) // 충돌 시 빨간색 틴트 효과
                    .animation(nil, value: characterImageName)
                    .animation(.easeOut(duration: 0.1), value: isCollisionTint) // 부드러운 전환
                    .drawingGroup() // 이미지를 미리 렌더링하여 깜빡임 방지
                
                // 스턴 효과 (안드로이드와 동일: ic_stun_ring + ic_stun_stars)
                // 안드로이드: Box(modifier = Modifier.align(Alignment.TopCenter).offset(y = (-20).dp).size(50.dp))
                if isStunned {
                    // 안드로이드: 고정 크기 50.dp, 고정 오프셋 -20.dp
                    let stunEffectSize: CGFloat = 50
                    // 안드로이드: .align(Alignment.TopCenter) = 캐릭터 Box의 상단 중앙에 정렬
                    // 그 위치에서 .offset(y = (-20).dp) = 상단 중앙 기준 -20dp 위로 이동
                    // iOS: ZStack 내부에서 offset은 캐릭터 이미지 중앙 기준이므로,
                    // 상단 중앙으로 가려면 -characterSize/2, 거기서 -10pt 더 올림 (살짝 내림)
                    let stunOffset: CGFloat = -characterSize / 2 - 5
                    
                    // 안드로이드: Box(size(50.dp)) 내부에 두 이미지가 fillMaxSize()로 채워짐
                    ZStack {
                        // 링 (고정) - 안드로이드: ic_stun_ring, modifier = Modifier.fillMaxSize()
                        Image("IcStunRing")
                            .resizable()
                            .scaledToFill() // 안드로이드: fillMaxSize()와 동일 (비율 무시하고 크기 채움)
                            .frame(width: stunEffectSize, height: stunEffectSize)
                            .clipped() // 프레임을 벗어나는 부분 잘라냄
                        
                        // 별 (회전 애니메이션) - 안드로이드: ic_stun_stars, modifier = Modifier.fillMaxSize().rotate(rotation)
                        // 안드로이드: rememberInfiniteTransition + infiniteRepeatable(animation = tween(1000, easing = LinearEasing))
                        Image("IcStunStars")
                            .resizable()
                            .scaledToFill() // 안드로이드: fillMaxSize()와 동일 (비율 무시하고 크기 채움)
                            .frame(width: stunEffectSize, height: stunEffectSize)
                            .clipped() // 프레임을 벗어나는 부분 잘라냄
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    // 안드로이드: .align(Alignment.TopCenter).offset(y = (-20).dp)
                    // 캐릭터 머리 위에 위치 (캐릭터 상단 중앙 기준 -20pt)
                    .offset(y: stunOffset)
                }
            }
            .position(
                x: geometry.size.width / 2, // 가로 중앙 (horizontalBias = 0f)
                y: yPosition // 계산된 Y 위치
            )
            .animation(.easeOut(duration: 0.8), value: targetBias)
        }
        .task {
            // 프레임 전환 (안드로이드와 동일: 0.25초마다 토글)
            // 안드로이드: LaunchedEffect { while(true) { delay(250L); isFrameOne = !isFrameOne } }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25초
                // transition 상태가 아닐 때만 프레임 전환
                if displayStepType != .transition {
                    isFrameOne.toggle()
                }
            }
        }
        .onChange(of: isStunned) { stunned in
            // 스턴 효과 회전 애니메이션 (안드로이드와 동일)
            // 안드로이드: rememberInfiniteTransition + infiniteRepeatable(animation = tween(1000, easing = LinearEasing))
            if stunned {
                // 무한 반복 회전 애니메이션 시작
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            } else {
                // 스턴 해제 시 애니메이션 중지
                withAnimation(.linear(duration: 0)) {
                    rotationAngle = 0
                }
            }
        }
    }
    
    /// 현재 표시할 캐릭터 이미지 이름 (안드로이드의 currentPainter와 동일)
    /// 안드로이드: val currentPainter = when (displayStepType) {
    ///     WALK -> if (isFrameOne) walkPainter1 else walkPainter2
    ///     FLY -> if (isFrameOne) flyPainter1 else flyPainter2
    ///     else -> transitionPainter
    /// }
    private var characterImageName: String {
        switch displayStepType {
        case .walk:
            return isFrameOne ? "GameWalking1" : "GameWalking2"
        case .fly:
            return isFrameOne ? "GameFlying1" : "GameFlying2"
        case .transition:
            return "GameTransition"
        }
    }
}

