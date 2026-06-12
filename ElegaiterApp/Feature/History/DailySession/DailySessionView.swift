//
//  DailySessionView.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import ElegaiterSDK

/// 일별 세션 상세 화면
///
/// Android의 `DailySessionScreen`을 SwiftUI로 변환
/// - 특정 날짜의 모든 운동 세션 목록 표시
/// - 각 세션 클릭 시 상세 결과 화면으로 이동
struct DailySessionView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel: HistoryViewModel
    
    /// 표시할 세션 목록
    let sessions: [SessionInfo]
    
    /// 선택된 날짜
    let selectedDate: String?
    
    init(
        sessions: [SessionInfo],
        selectedDate: String? = nil,
        viewModel: HistoryViewModel? = nil
    ) {
        self.sessions = sessions
        self.selectedDate = selectedDate
        
        if let viewModel = viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: HistoryViewModel())
        }
    }
    
    var body: some View {
        ZStack {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "",
                    onBackClick: {
                        coordinator.pop(in: Binding(
                            get: { coordinator.historyPath },
                            set: { coordinator.historyPath = $0 }
                        ))
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 날짜 제목 및 세션 목록 (안드로이드: padding(top = 20.dp, bottom = 60.dp, start = 16.dp, end = 16.dp))
                        VStack(alignment: .leading, spacing: 0) {
                            // 날짜 제목 (안드로이드: ElegaiterTypography.Headline5, TextMain, padding(bottom = 16.dp))
                            Text(formatDateTitle(selectedDate))
                                .typography(ElegaiterTypography.Headline5)
                                .foregroundColor(ElegaiterColors.Text.main)
                                .padding(.bottom, 16)
                            
                            // 세션 목록
                            let displaySessions = viewModel.uiState.selectedDaySessions.isEmpty ? sessions : viewModel.uiState.selectedDaySessions
                            
                            VStack(spacing: 8) {
                                ForEach(displaySessions, id: \.fileName) { session in
                                    HistoryListItem(
                                        record: session,
                                        onRecordClick: {
                                            handleRecordClick(fileName: session.fileName)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                        .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.white) // NavigationStack 배경색 명시
            .navigationBarBackButtonHidden(true) // 시스템 백 버튼 제거
            .onAppear {
                viewModel.coordinator = coordinator
                // 날짜가 있으면 세션 로드
                if let selectedDate = selectedDate {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd"
                    if let date = formatter.date(from: selectedDate) {
                        viewModel.loadSessionForSpecificDay(date: date)
                    }
                }
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Private Methods
    
    /// 기록 클릭 처리
    private func handleRecordClick(fileName: String) {
        Task { @MainActor in
            guard let metrics = await viewModel.getRecordDetails(fileName: fileName) else {
                // 보행 분석 결과를 불러올 수 없을 때 토스트 표시
                ToastManager.shared.show(message: "record_error_get_analysis".localized())
                return
            }
            
            guard let recordDto = await viewModel.getRecordMetaData(fileName: fileName) else {
                // 보행 분석 결과를 불러올 수 없을 때 토스트 표시
                ToastManager.shared.show(message: "record_error_get_analysis".localized())
                return
            }
            
            // ExerciseResult로 이동하기 전의 탭 저장 (뒤로가기 시 History로 돌아가기 위해)
            coordinator.exerciseResultSourceTab = .history
            
            // Exercise 탭으로 전환
            coordinator.selectedTab = .exercise
            
            // ExerciseResult 화면으로 이동
            coordinator.exerciseRouter.navigateToResult(metrics: metrics, record: recordDto)
        }
    }
    
    /// 날짜 제목 포맷팅
    ///
    /// yyyyMMdd 형식을 현재 언어에 맞는 형식으로 변환
    /// 한국어: "X월 Y일 운동 기록"
    /// 영어: "Exercise Record - Month Day"
    private func formatDateTitle(_ dateString: String?) -> String {
        guard let dateString = dateString else {
            return "record_title".localized()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        guard let date = formatter.date(from: dateString) else {
            return "record_title".localized()
        }
        
        // 현재 언어에 따라 날짜 포맷팅
        let currentLanguage = LanguageManager.shared.currentLanguage
        
        if currentLanguage == "ko" {
            // 한국어: "X월 Y일 운동 기록"
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "M"
            let month = monthFormatter.string(from: date)
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            let day = dayFormatter.string(from: date)
            
            return "\(month)월 \(day)일 \("record_title".localized())"
        } else {
            // 영어: "Exercise Record - Month Day"
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            dateFormatter.dateFormat = "MMMM d"
            let formattedDate = dateFormatter.string(from: date)
            return "\(formattedDate) - \("record_title".localized())"
        }
    }
}

#Preview {
    DailySessionView(
        sessions: [
            SessionInfo(
                fileName: "test_20250101_1.json",
                displayName: "06월 10일 1회차",
                date: "20250101",
                session: 1,
                elapsedTime: 1470
            ),
            SessionInfo(
                fileName: "test_20250101_2.json",
                displayName: "06월 10일 2회차",
                date: "20250101",
                session: 2,
                elapsedTime: 1215
            )
        ],
        selectedDate: "20250101"
    )
    .environmentObject(AppCoordinator())
}
