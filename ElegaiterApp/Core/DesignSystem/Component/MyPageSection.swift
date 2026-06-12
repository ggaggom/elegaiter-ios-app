//
//  MyPageSection.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import os.log

private let myPageSectionPreviewLogger = Logger(subsystem: "com.elegaiter.app", category: "MyPageSection+Preview")

/// 마이페이지 섹션 컴포넌트
/// 
/// Android의 `MyPageSection`을 SwiftUI로 변환
/// - 제목과 메뉴 항목 리스트를 표시
/// - 각 메뉴 항목 클릭 시 액션 실행
/// - 아이콘, 화살표 표시 여부, 텍스트 색상 커스터마이징 지원
struct MyPageSection: View {
    /// 섹션 제목 (빈 문자열이면 제목 숨김)
    let title: String
    /// 메뉴 항목 리스트
    let menuItems: [MyPageMenuItem]
    /// 추가 horizontal padding (기본값: 0)
    var additionalHorizontalPadding: CGFloat = 0
    
    init(
        title: String,
        menuItems: [MyPageMenuItem],
        additionalHorizontalPadding: CGFloat = 0
    ) {
        self.title = title
        self.menuItems = menuItems
        self.additionalHorizontalPadding = additionalHorizontalPadding
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 제목 (빈 문자열이 아니면 표시)
            if !title.isEmpty {
                Text(title)
                    .typography(ElegaiterTypography.Label3)
                    .foregroundColor(ElegaiterColors.Text.sub2)
                    .padding(.bottom, 12)
            }
            
            // 메뉴 항목 리스트 (WhiteGrayCard 사용)
            WhiteGrayCard {
            VStack(spacing: 0) {
                ForEach(Array(menuItems.enumerated()), id: \.offset) { index, item in
                        Button(action: item.onClick) {
                            HStack(alignment: .center, spacing: 0) {
                                // 아이콘 (있는 경우)
                                if let iconName = item.iconName {
                                    Image(iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .padding(.trailing, 8)
                                }
                                
                                // 메뉴 텍스트
                                Text(item.name)
                                .typography(ElegaiterTypography.Body2)
                                    .foregroundColor(item.textColor ?? ElegaiterColors.Text.sub2)
                            
                            Spacer()
                            
                                // 화살표 (showArrow가 true인 경우만)
                                if item.showArrow {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ElegaiterColors.Text.sub2)
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // 구분선 (마지막 항목 제외)
                    if index < menuItems.count - 1 {
                        Divider()
                                .background(ElegaiterColors.Stroke.medium)
                        }
                    }
                    }
                }
            }
        .padding(.vertical, 20)
        .padding(.horizontal, 16 + additionalHorizontalPadding)
    }
}

/// 마이페이지 메뉴 아이템 데이터 모델
/// 
/// Android의 `MyPageMenuItem`을 Swift로 변환
struct MyPageMenuItem {
    /// 메뉴 이름
    let name: String
    /// 클릭 액션
    let onClick: () -> Void
    /// 아이콘 이름 (SF Symbols)
    let iconName: String?
    /// 텍스트 색상 (nil이면 기본값 TextSub2 사용)
    let textColor: Color?
    /// 화살표 표시 여부 (기본값: true)
    let showArrow: Bool
    
    init(
        _ name: String,
        _ onClick: @escaping () -> Void,
        iconName: String? = nil,
        textColor: Color? = nil,
        showArrow: Bool = true
    ) {
        self.name = name
        self.onClick = onClick
        self.iconName = iconName
        self.textColor = textColor
        self.showArrow = showArrow
    }
}

#Preview {
    VStack(spacing: 0) {
        MyPageSection(
            title: "",
            menuItems: [
                MyPageMenuItem(
                    "내 성취",
                    { myPageSectionPreviewLogger.debug("내 성취") },
                    iconName: "trophy.fill"
                )
            ]
        )
        
        MyPageSection(
            title: "계정 관련",
            menuItems: [
                MyPageMenuItem("내 정보 수정", { myPageSectionPreviewLogger.debug("내 정보 수정") }),
                MyPageMenuItem("비밀번호 재설정", { myPageSectionPreviewLogger.debug("비밀번호 재설정") }),
                MyPageMenuItem("목표 걸음 수 설정", { myPageSectionPreviewLogger.debug("목표 걸음 수 설정") }),
            ]
        )
        
        MyPageSection(
            title: "기기 관련",
            menuItems: [
                MyPageMenuItem("임계값 설정", { myPageSectionPreviewLogger.debug("임계값 설정") }),
                MyPageMenuItem("블루투스 재연결", { myPageSectionPreviewLogger.debug("블루투스 재연결") }, showArrow: false),
                MyPageMenuItem("디바이스 에러", { myPageSectionPreviewLogger.debug("디바이스 에러") }),
            ]
        )
        
        MyPageSection(
            title: "",
            menuItems: [
                MyPageMenuItem("로그아웃", { myPageSectionPreviewLogger.debug("로그아웃") }, showArrow: false),
                MyPageMenuItem(
                    "회원 탈퇴",
                    { myPageSectionPreviewLogger.debug("회원 탈퇴") },
                    textColor: ElegaiterColors.Status.error,
                    showArrow: false
                ),
            ]
        )
    }
    .background(Color(.systemGroupedBackground))
}
