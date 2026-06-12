//
//  TermsBottomSheet.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// iOS 버전 호환성을 위한 CornerRadius Modifier
/// iOS 16.4 이상에서만 presentationCornerRadius를 적용
struct CornerRadiusModifier: ViewModifier {
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}

/// 약관 상세보기 바텀 시트 컴포넌트
/// 
/// Android의 `TermsBottomSheet`를 SwiftUI로 변환
/// - 약관 제목 및 내용 표시
/// - 스크롤 가능한 텍스트 영역
/// - 닫기 버튼
struct TermsBottomSheet: View {
    /// 약관 항목
    let termItem: TermItem
    /// 닫기 액션
    let onDismissClick: () -> Void
    
    var body: some View {
            VStack(spacing: 0) {
            // 헤더 (제목과 닫기 버튼)
                HStack {
                    Text(termItem.title)
                    .typography(ElegaiterTypography.Headline4)
                    .foregroundColor(ElegaiterColors.Green.green500)
                    
                    Spacer()
                    
                    Button(action: onDismissClick) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    }
                }
            .padding(.top, 28)
                .padding(.horizontal, 20)
            .padding(.bottom, 28)
                
                // 약관 내용 (스크롤 가능)
                ScrollView {
                    Text(termItem.content)
                    .typography(ElegaiterTypography.Body4)
                    .foregroundColor(ElegaiterColors.Text.sub1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TermsBottomSheet(
        termItem: TermItem(
            id: "terms",
            title: "이용 약관",
            content: """
            제1조 (목적)
            이 약관은 회사가 제공하는 서비스의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.
            
            제2조 (정의)
            1. "서비스"란 회사가 제공하는 모든 서비스를 의미합니다.
            2. "이용자"란 이 약관에 따라 서비스를 이용하는 회원 및 비회원을 의미합니다.
            
            (약관 내용 계속...)
            """,
            fileName: "terms_of_service.txt"
        ),
        onDismissClick: {}
    )
}
