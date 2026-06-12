//
//  ArcadeView.swift
//  ElegaiterApp
//
//  Created on 2025-01-XX.
//

import SwiftUI

/// 아케이드 게임 화면
/// 
/// Android의 `ArcadeRoute`와 `ArcadeScreen`을 Swift로 변환
/// - 게임 화면 진입/이탈 처리
/// - 게임 엔진 및 UI 렌더링
struct ArcadeView: View {
    @ObservedObject var router: ExerciseRouter
    @ObservedObject var viewModel: ExerciseSessionViewModel
    
    var body: some View {
        ArcadeRoute(
            viewModel: viewModel,
            navigateToRealTimeExercise: {
                // 안드로이드와 동일하게 pop을 사용하여 이전 화면으로 돌아감
                if let coordinator = router.coordinator {
                    coordinator.pop(in: Binding(
                        get: { coordinator.exercisePath },
                        set: { coordinator.exercisePath = $0 }
                    ))
                }
            }
        )
    }
}

/// 아케이드 게임 라우트 컴포저블
/// 
/// Android의 `ArcadeRoute` Composable을 Swift로 변환
/// - 게임 화면 진입/이탈 시 ViewModel 메서드 호출
private struct ArcadeRoute: View {
    @ObservedObject var viewModel: ExerciseSessionViewModel
    let navigateToRealTimeExercise: () -> Void
    
    @State private var showDisconnectionDialog = false
    
    var body: some View {
        ZStack {
            if !viewModel.showFinishOverlay {
                ArcadeScreen(
                    uiState: viewModel.uiState,
                    gameState: viewModel.gameState,
                    navigateToRealTimeExercise: navigateToRealTimeExercise,
                    onObstaclePassed: {
                        viewModel.onObstaclePassed()
                    },
                    onObstacleCollision: {
                        viewModel.onObstacleCollision()
                    },
                    decreaseStunTime: { deltaMs in
                        viewModel.decreaseStunTime(deltaMs: deltaMs)
                    }
                )
            }
            
            if viewModel.showFinishOverlay {
                ExerciseEndFlowOverlay(viewModel: viewModel)
            }
            
            if showDisconnectionDialog {
                StyledAlertDialog(
                    isPresented: $showDisconnectionDialog,
                    title: "exercise_bluetooth_connection_lost_title".localized(),
                    message: "realtime_exercise_bluetooth_disconnected_message".localized(),
                    content: { EmptyView() },
                    confirmText: "btn_confirm".localized(),
                    onConfirm: {
                        showDisconnectionDialog = false
                        viewModel.onStopExerciseClick(gotoJawsSearch: true)
                    },
                    dismissText: "exercise_end".localized(),
                    onDismiss: {
                        showDisconnectionDialog = false
                        viewModel.onStopExerciseClick(gotoJawsSearch: false)
                    }
                )
            }
        }
        .onAppear {
            viewModel.onGameScreenEntered()
        }
        .onDisappear {
            viewModel.onGameScreenExited()
        }
        .onChange(of: viewModel.bleConnectionState) { state in
            if state != .connected {
                showDisconnectionDialog = true
            }
        }
    }
}

/// 아케이드 게임 화면 (실제 게임 UI)
/// 
/// Android의 `ArcadeScreen` Composable을 Swift로 변환
/// - 게임 엔진 인스턴스 생성 및 관리
/// - 게임 루프 실행 (60fps)
/// - 캐릭터 및 장애물 렌더링
/// - 점수, 콤보, 배율 UI 표시
private struct ArcadeScreen: View {
    let uiState: ExerciseSessionUiState
    let gameState: ArcadeGameState
    let navigateToRealTimeExercise: () -> Void
    let onObstaclePassed: () -> Void
    let onObstacleCollision: () -> Void
    let decreaseStunTime: (Int64) -> Void
    
    /// 게임 엔진 인스턴스 (remember와 동일한 역할)
    @StateObject private var gameEngine = ArcadeGameEngine()
    
    /// 콤보 표시 여부 (안드로이드: showCombo)
    @State private var showCombo: Bool = false
    
    /// 콤보 스케일 애니메이션 (안드로이드: comboScale)
    @State private var comboScale: CGFloat = 0
    
    /// 콤보 알파 애니메이션 (안드로이드: comboAlpha)
    @State private var comboAlpha: Double = 0
    
    /// 충돌 시 빨간색 틴트 효과 (일시적)
    @State private var isCollisionTint: Bool = false
    
    /// 캐릭터 애니메이션된 실제 위치 (안드로이드: animatedBias)
    /// 안드로이드: animateFloatAsState로 800ms 동안 LinearOutSlowInEasing으로 애니메이션
    /// iOS: 수동으로 애니메이션 값을 계산하여 게임 엔진에 전달
    @State private var animatedBias: Float = 0.95 // 초기값은 바닥 위치
    @State private var animationStartBias: Float = 0.95
    @State private var animationTargetBias: Float = 0.95
    @State private var animationStartTime: Double = 0 // CFAbsoluteTime (밀리초)
    
    var body: some View {
        ZStack {
            // 배경 이미지 (안드로이드: Image with ContentScale.Crop)
            Image("GameBackground")
                .resizable()
                .scaledToFill() // ContentScale.Crop에 해당 (비율 유지하면서 영역을 채움)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped() // 영역을 벗어나는 부분 잘라내기
                .ignoresSafeArea(.all) // Safe Area 무시하여 전체 화면 채우기
            
            // 장애물 렌더링 (zIndex 적용)
            ForEach(gameEngine.obstacles) { obstacle in
                ObstacleView(obstacle: obstacle)
                    .zIndex(Double(obstacle.scale)) // 안드로이드: Modifier.zIndex(obstacle.scale)
            }
            
            // 캐릭터 렌더링
            CharacterView(
                displayStepType: uiState.displayStepType,
                targetBias: uiState.targetCharacterBias,
                isStunned: gameState.isStunned,
                isCollisionTint: isCollisionTint
            )
            .zIndex(10) // 캐릭터가 장애물 위에 표시되도록
            .onChange(of: uiState.targetCharacterBias) { newTargetBias in
                // 안드로이드: animateFloatAsState로 자동 애니메이션
                // iOS: 수동으로 애니메이션 시작
                animationStartBias = animatedBias
                animationTargetBias = newTargetBias
                animationStartTime = Date().timeIntervalSince1970 * 1000 // 밀리초 (System.currentTimeMillis()와 동일)
            }
            
            VStack(spacing: 0) {
                // Header와 점수/배율/콤보를 같은 선상에 배치
                HStack(alignment: .top, spacing: 0) {
                    // Header (타이틀 없이 뒤로가기만)
                    ElegaiterHeader(
                        title: "", // 타이틀 없음
                        onBackClick: {
                            navigateToRealTimeExercise()
                        }
                    )
                    .padding(.top, 8) // status bar 영역 여백
                    
                    Spacer()
                    
                    // 점수/배율/콤보 영역 (우측) - 안드로이드: Column with Alignment.TopEnd
                    // 안드로이드: Column(modifier = Modifier.align(Alignment.TopEnd).padding(12.dp))
                    VStack(alignment: .trailing, spacing: 7) {
                        // 점수 (안드로이드: Headline1, White, 반투명 검정 배경)
                        // 안드로이드: modifier = Modifier.background(...).padding(horizontal = 8.dp, vertical = 4.dp)
                        // SwiftUI: padding을 먼저 적용한 후 background를 적용하여 박스 내부 패딩 구현
                        Text("\(gameState.score)")
                            .typography(ElegaiterTypography.Headline1)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8) // 박스 내부 패딩
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0x4D / 255.0)) // 0x4D000000
                            )
                        
                        // 배율 (안드로이드: Headline5, Green800, 반투명 검정 배경, padding(top = 6.dp))
                        // 안드로이드: 점수와 배율 사이 6dp 여백
                        // 안드로이드: modifier = Modifier.padding(top = 6.dp).background(...).padding(horizontal = 8.dp, vertical = 4.dp)
                        // SwiftUI: 안드로이드와 동일한 순서로 적용 - top padding → background → horizontal/vertical padding
                        let multiplierText = gameState.multiplier.truncatingRemainder(dividingBy: 1) == 0
                            ? "x \(Int(gameState.multiplier))"
                            : "x \(String(format: "%.1f", gameState.multiplier))"
                        
                        Text(multiplierText)
                            .typography(ElegaiterTypography.Headline5)
                            .foregroundColor(ElegaiterColors.Green.green800)
                            .padding(.horizontal, 8) // 박스 내부 패딩 (background 앞에 적용)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0x4D / 255.0)) // 0x4D000000
                            )
                        
                        // 콤보 (안드로이드: showCombo && combo > 0일 때만 표시, StatusWarning 색상, padding(top = 8.dp))
                        // 안드로이드: 배율과 콤보 사이 8dp 여백
                        // 안드로이드: modifier = Modifier.padding(top = 8.dp).graphicsLayer { scaleX, scaleY, alpha }
                        // 안드로이드: 콤보는 background 없음
                        if showCombo && gameState.combo > 0 {
                            Text("\(gameState.combo) Combo")
                                .typography(ElegaiterTypography.Headline5)
                                .foregroundColor(ElegaiterColors.Status.warning)
                                .padding(.top, 8) // 안드로이드: padding(top = 8.dp) - 배율과 콤보 사이 여백
                                .scaleEffect(x: comboScale, y: comboScale) // 안드로이드: graphicsLayer { scaleX, scaleY }
                                .opacity(comboAlpha) // 안드로이드: graphicsLayer { alpha }
                        }
                    }
                    .padding(12) // 안드로이드: Column 전체에 padding(12.dp) 적용
                    .padding(.top, 8) // Header와 같은 높이
                    .padding(.trailing, 12) // 우측 여백
                }
                
                Spacer()
            }
        }
        .onAppear {
            // 게임 엔진 초기화 (새 게임 시작 시 이전 상태 초기화)
            gameEngine.reset()
            
            // 캐릭터 위치 애니메이션 초기화
            animatedBias = uiState.targetCharacterBias
            animationStartBias = uiState.targetCharacterBias
            animationTargetBias = uiState.targetCharacterBias
            animationStartTime = Date().timeIntervalSince1970 * 1000 // 밀리초 (System.currentTimeMillis()와 동일)
        }
        .task {
            // 게임 루프 시작 (60fps 목표)
            // Android: LaunchedEffect + withFrameNanos
            // 안드로이드의 withFrameNanos는 실제 프레임 타이밍에 맞춰 동기화
            // iOS: 안드로이드와 동일한 시간 기준 사용 (System.currentTimeMillis()와 동일)
            
            while !Task.isCancelled {
                // 안드로이드: currentTime = System.currentTimeMillis()
                // System.currentTimeMillis()는 1970년 1월 1일부터의 밀리초 (UTC)
                // iOS: Date().timeIntervalSince1970 * 1000으로 동일한 시간 기준 사용
                let currentTime = Int64(Date().timeIntervalSince1970 * 1000) // 밀리초
                
                // 캐릭터 위치 애니메이션 업데이트 (안드로이드: animateFloatAsState)
                // 안드로이드: LinearOutSlowInEasing, 800ms
                // LinearOutSlowInEasing은 cubic bezier (0.0, 0.0, 0.2, 1.0)
                let animationElapsed = Double(currentTime) - animationStartTime
                let animationDuration: Double = 800.0 // 800ms
                if animationElapsed < animationDuration {
                    let progress = Float(animationElapsed / animationDuration)
                    let clampedProgress = min(max(progress, 0), 1)
                    // LinearOutSlowInEasing: cubic bezier (0.0, 0.0, 0.2, 1.0)
                    let easedProgress = linearOutSlowInEasing(progress: clampedProgress)
                    animatedBias = animationStartBias + (animationTargetBias - animationStartBias) * easedProgress
                } else {
                    animatedBias = animationTargetBias
                }
                
                // 게임 엔진 업데이트
                // 안드로이드: rememberUpdatedState와 유사하게 매 프레임마다 최신 값 사용
                // 안드로이드: playerBias = animatedBias.value (애니메이션된 실제 위치 사용)
                gameEngine.update(
                    currentTime: currentTime,
                    playerBias: animatedBias, // 애니메이션된 실제 위치 사용 (안드로이드와 동일)
                    isStunned: gameState.isStunned, // 매 프레임마다 최신 값 사용
                    onCollision: {
                        onObstacleCollision()
                        triggerCollisionTint() // 충돌 시 빨간색 틴트 효과
                    },
                    onPass: {
                        // 안드로이드: onPass 콜백에서 콤보 UI 효과 트리거
                        onObstaclePassed()
                        triggerComboAnimation()
                    },
                    onTick: decreaseStunTime
                )
                
                // 다음 프레임까지 대기 (60fps = 약 16.67ms)
                // 안드로이드: withFrameNanos는 자동으로 프레임 동기화
                // iOS: 수동으로 60fps 목표로 대기
                let frameStart = Date()
                let targetFrameTime = 1.0 / 60.0 // 60fps = 16.67ms
                let frameDuration = Date().timeIntervalSince(frameStart)
                let sleepTime = max(0, targetFrameTime - frameDuration)
                try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
            }
        }
        .navigationBarBackButtonHidden(true) // 시스템 back 버튼 제거
        .navigationBarTitleDisplayMode(.inline) // 네비게이션 바 타이틀 숨김
        .onAppear {
            // 화면 유지 설정 (안드로이드: view.keepScreenOn = true)
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // 화면 유지 해제
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    /// 충돌 시 빨간색 틴트 효과 트리거
    /// 
    /// 충돌 발생 시 캐릭터에 일시적으로 빨간색 틴트 효과를 적용
    /// - 약 0.2초 동안 빨간색 틴트 유지
    private func triggerCollisionTint() {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.1)) {
                isCollisionTint = true
            }
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            withAnimation(.easeOut(duration: 0.1)) {
                isCollisionTint = false
            }
        }
    }
    
    /// 콤보 애니메이션 트리거
    /// 
    /// 안드로이드의 콤보 애니메이션 로직을 Swift로 변환
    /// 안드로이드: comboScale.animateTo(1.2f, tween(200, easing = FastOutSlowInEasing))
    ///            comboScale.animateTo(1f, tween(100, easing = FastOutSlowInEasing))
    ///            comboAlpha.animateTo(1f, tween(200))
    ///            comboAlpha.animateTo(0f, tween(300))
    /// - scale: 0 -> 1.2 -> 1.0 (200ms + 100ms, 동시 실행, FastOutSlowInEasing)
    /// - alpha: 0 -> 1.0 -> 0 (200ms + 1000ms 대기 + 300ms, 동시 실행)
    /// - 총 1300ms 후 showCombo = false
    private func triggerComboAnimation() {
        Task { @MainActor in
            showCombo = true
            comboScale = 0
            comboAlpha = 0
            
            // Scale 애니메이션: 0 -> 1.2 -> 1.0 (동시 실행)
            // 안드로이드: FastOutSlowInEasing (처음 빠르게, 중간 느리게, 끝 빠르게)
            // SwiftUI: .spring()이 FastOutSlowInEasing과 유사한 효과
            Task {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    comboScale = 1.2
                }
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                withAnimation(.spring(response: 0.1, dampingFraction: 0.7)) {
                    comboScale = 1.0
                }
            }
            
            // Alpha 애니메이션: 0 -> 1.0 -> 0 (동시 실행)
            Task {
                withAnimation(.easeOut(duration: 0.2)) {
                    comboAlpha = 1.0
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1000ms 대기 + 200ms 애니메이션
                withAnimation(.easeOut(duration: 0.3)) {
                    comboAlpha = 0
                }
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms 애니메이션 대기
                showCombo = false
            }
        }
    }
    
    /// LinearOutSlowInEasing 계산 함수
    /// 
    /// 안드로이드의 LinearOutSlowInEasing (cubic bezier 0.0, 0.0, 0.2, 1.0)을 Swift로 구현
    /// - Parameter progress: 0.0 ~ 1.0 사이의 진행률
    /// - Returns: easing이 적용된 진행률 (0.0 ~ 1.0)
    private func linearOutSlowInEasing(progress: Float) -> Float {
        // Cubic bezier: (0.0, 0.0, 0.2, 1.0)
        // p0 = (0, 0), p1 = (0, 0), p2 = (0.2, 1.0), p3 = (1, 1)
        let t = Double(progress)
        let oneMinusT = 1.0 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT
        let tSquared = t * t
        let tCubed = tSquared * t
        
        // Cubic bezier 공식: (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
        // P₀ = 0, P₁ = 0, P₂ = 0.2, P₃ = 1
        let result = oneMinusTCubed * 0.0 +
                     3 * oneMinusTSquared * t * 0.0 +
                     3 * oneMinusT * tSquared * 0.2 +
                     tCubed * 1.0
        
        return Float(result)
    }
}

/// 장애물 View
/// 
/// Android의 `ApproachingObstacle` Composable을 SwiftUI로 변환
private struct ObstacleView: View {
    @ObservedObject var obstacle: ActiveObstacle
    
    var body: some View {
        GeometryReader { geometry in
            // isVisible 체크 (안드로이드: if (!obstacle.isVisible) return)
            if !obstacle.isVisible {
                EmptyView()
            } else {
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                let obstacleSize = screenWidth * 6 / 5 // 화면 너비의 120%
                
                // Bias 값을 화면 Y 좌표로 변환
                // 안드로이드: BiasAlignment(0f, obstacle.bias)
                // obstacle.bias: -0.3 (멀리, 위쪽 밖) ~ 4.2 (가까이, 아래쪽 밖)
                // 
                // 안드로이드의 BiasAlignment는 화면 중앙(0.0)을 기준으로 위치 결정
                // - bias 0.0 = 화면 중앙
                // - bias가 증가하면 아래로 이동
                // - bias가 감소하면 위로 이동
                //
                // 게임 로직상:
                // - bias 1.2 ~ 2.8: 충돌 판정 영역 (화면 중앙~아래쪽)
                // - bias 0.0: 화면 중앙
                // - bias -0.3: 화면 위쪽 밖 (시작 위치)
                // - bias 4.2: 화면 아래쪽 밖 (종료 위치)
                //
                // 화면 높이를 기준으로 매핑:
                // bias 0.0을 화면 중앙에 맞추고, bias 값에 비례하여 위치 결정
                let centerY = screenHeight / 2
                // bias 값이 화면 높이의 일정 비율로 변환됨
                // 화면 높이의 약 1/4 ~ 1/5 정도를 1.0 bias 단위로 사용
                // 이렇게 하면 bias 0.0 = 중앙, bias 2.0 = 화면 아래쪽 근처
                let biasToPixelRatio = screenHeight / 4.5 // 화면 높이를 4.5로 나눈 값
                let yPosition = centerY + CGFloat(obstacle.bias) * biasToPixelRatio
                
                Image(obstacle.imageRes)
                    .resizable()
                    .scaledToFit()
                    .frame(width: obstacleSize, height: obstacleSize) // 기본 크기
                    .scaleEffect(x: CGFloat(obstacle.scale), y: CGFloat(obstacle.scale)) // 원근감 스케일 (0.15 ~ 1.15)
                    .opacity(obstacle.isCollided ? 0.3 : 1.0) // 충돌 시 투명도 감소
                    .animation(.easeOut(duration: 0.2), value: obstacle.isCollided) // 부드러운 전환
                    .position(
                        x: geometry.size.width / 2, // 가로 중앙 (horizontalBias = 0f)
                        y: yPosition // 계산된 Y 위치
                    )
            }
        }
    }
}

