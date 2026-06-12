//
//  StatusOverlay.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 상태 오버레이 컴포넌트
/// 
/// Android의 `StatusOverlay`를 SwiftUI로 변환
/// - 어두운 배경으로 화면 전체 덮기
/// - 중앙에 제목과 본문 텍스트 표시
/// - 아이콘 표시 지원 (기본값: IcChecked)
struct StatusOverlay: View {
    /// 제목
    let title: String
    /// 본문 텍스트 (선택적)
    var bodyText: String? = nil
    /// 아이콘 이름 (기본값: IcChecked, 안드로이드: ic_checked)
    var iconName: String? = "IcChecked"
    /// 아이콘 크기 (기본값: 120, 안드로이드: 120.dp)
    var iconSize: CGFloat = 120
    /// 제목 타이포그래피 스타일 (기본값: Headline2, 안드로이드와 동일)
    var titleStyle: ElegaiterTypography.TypographyStyle = ElegaiterTypography.Headline2
    
    var body: some View {
        ZStack {
            // 어두운 배경 (안드로이드: BackgroundDark)
            ElegaiterColors.Background.dark
                .ignoresSafeArea()
                .allowsHitTesting(false) // 클릭 비활성화
            
            // 중앙 컨텐츠 (안드로이드: Column, horizontalAlignment = CenterHorizontally)
            VStack(alignment: .center, spacing: 0) {
                // 아이콘 (안드로이드: 기본값 ic_checked, size = iconSize)
                if let iconName = iconName {
                    Image(iconName)
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: iconSize, height: iconSize)
                }
                
                // 제목 (안드로이드: titleStyle, padding(top = 24.dp, bottom = 8.dp))
                Text(title)
                    .typography(titleStyle)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.bottom, bodyText != nil ? 8 : 0)
                
                // 본문 (안드로이드: Body2)
                if let bodyText = bodyText {
                    Text(bodyText)
                        .typography(ElegaiterTypography.Body2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
            .ignoresSafeArea()
        
        VStack {
            Text("배경 화면")
                .foregroundColor(.white)
        }
        
        StatusOverlay(
            title: "준비 완료!",
            bodyText: "이제 본격적으로 측정을 시작할게요"
        )
        
        StatusOverlay(
            title: "운동 완료!"
        )
    }
}
