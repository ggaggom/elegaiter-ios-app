//
//  AchievementView.swift
//  ElegaiterApp
//
//  Created on 2025-12-05.
//

import SwiftUI

/// 내 성취 화면
///
/// Android의 `AchievementScreen`을 SwiftUI로 변환
/// - 이번 달 성취 뱃지 표시
/// - 뱃지 달성 여부에 따라 다른 아이콘 표시
struct AchievementView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = AchievementViewModel()
    
    /// 뱃지 항목 리스트
    private let badgeItems: [BadgeItem] = [
        BadgeItem(key: "hasRecordThisMonth", localizationKey: "achievement_first", resourceKey: "First"),
        BadgeItem(key: "3", localizationKey: "achievement_badge_3days", resourceKey: "3day"),
        BadgeItem(key: "7", localizationKey: "achievement_badge_7days", resourceKey: "7day"),
        BadgeItem(key: "15", localizationKey: "achievement_badge_15days", resourceKey: "15day"),
        BadgeItem(key: "30", localizationKey: "achievement_badge_30days", resourceKey: "30day"),
        BadgeItem(key: "10000", localizationKey: "achievement_badge_10k", resourceKey: "10k"),
        BadgeItem(key: "30000", localizationKey: "achievement_badge_30k", resourceKey: "30k"),
        BadgeItem(key: "50000", localizationKey: "achievement_badge_50k", resourceKey: "50k"),
        BadgeItem(key: "100000", localizationKey: "achievement_badge_100k", resourceKey: "100k"),
    ]
    
    /// 뱃지 항목을 3개씩 행으로 그룹화
    private var badgeRows: [[BadgeItem]] {
        badgeItems.chunked(into: 3)
    }
    
    var body: some View {
        ZStack {
            // 배경색 (Safe Area까지 확장) - 흰색
            Color.white
                .ignoresSafeArea(edges: .all)
            
            VStack(spacing: 0) {
                // 고정 헤더 (Safe Area 내부에 배치)
                ElegaiterTopBar(
                    title: "setting_menu_my_achievement".localized(),
                    onBackClick: {
                        viewModel.navigateBack()
                    }
                )
                .padding(.top, 8) // status bar 영역 여백
                .background(Color.white) // 헤더 배경색 (흰색)
                
                // 스크롤 가능한 컨텐츠
                ScrollView {
                    VStack(spacing: 0) {
                        // 제목
                        Text("setting_menu_my_achievement".localized())
                            .typography(ElegaiterTypography.Headline5)
                            .foregroundColor(ElegaiterColors.Text.main)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                        
                        // 뱃지 그리드
                        VStack(spacing: 20) {
                            ForEach(Array(badgeRows.enumerated()), id: \.offset) { _, rowItems in
                                HStack(spacing: 0) {
                                    ForEach(rowItems, id: \.key) { item in
                                        BadgeItemView(
                                            item: item,
                                            isAchieved: viewModel.isBadgeAchieved(item: item)
                                        )
                                        .frame(maxWidth: .infinity)
                                    }
                                    
                                    // 빈 공간 채우기 (3개 미만인 경우)
                                    if rowItems.count < 3 {
                                        ForEach(0..<(3 - rowItems.count), id: \.self) { _ in
                                            Spacer()
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.white) // NavigationStack 배경색 명시
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.coordinator = coordinator
            viewModel.loadAchievements()
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

// MARK: - Badge Item View

/// 개별 뱃지 아이템 뷰
private struct BadgeItemView: View {
    let item: BadgeItem
    let isAchieved: Bool
    
    /// 뱃지 아이콘 이름
    ///
    /// 에셋 이름 형식: IcBadge[resourceKey]Default, IcBadge[resourceKey]Success
    /// 예: IcBadgeFirstDefault, IcBadgeFirstSuccess, IcBadge3dayDefault, IcBadge3daySuccess
    private var badgeIconName: String {
        let statusSuffix = isAchieved ? "Success" : "Default"
        return "IcBadge\(item.resourceKey)\(statusSuffix)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 뱃지 아이콘
            Image(badgeIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
            
            // 뱃지 이름
            Text(item.localizationKey.localized())
                .typography(ElegaiterTypography.Body4)
                .foregroundColor(ElegaiterColors.Text.sub2)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Badge Item Model

/// 뱃지 항목 데이터 모델
struct BadgeItem {
    /// 뱃지 키 (달성 여부 확인용)
    let key: String
    /// 로컬라이제이션 키 (뱃지 이름)
    let localizationKey: String
    /// 리소스 키 (아이콘 이름 생성용)
    let resourceKey: String
}

// MARK: - Array Extension

extension Array {
    /// 배열을 지정된 크기로 청크로 나누기
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    AchievementView()
        .environmentObject(AppCoordinator())
}
