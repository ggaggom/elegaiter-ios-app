//
//  ConnectionStatusRow.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 연결 상태 행 컴포넌트
/// 
/// Android의 `ConnectionStatusRow`를 SwiftUI로 변환
/// - 디바이스 이름, 타입, 연결 상태 표시
struct ConnectionStatusRow: View {
    /// 디바이스 이름
    let deviceName: String
    /// 디바이스 타입
    let deviceType: String
    /// 상태 텍스트
    let statusText: String
    /// 상태 텍스트 색상
    let statusTextColor: Color
    /// 상태 배경 색상
    let statusBackgroundColor: Color
    /// 체크 아이콘 표시 여부
    var showCheckIcon: Bool = false
    /// 태그 표시 여부 (마지막 연결 디바이스)
    var hasTag: Bool = false
    
    /// 안드로이드: isKoreanLocale() ? Label3 : Label4
    private var statusTextTypography: ElegaiterTypography.TypographyStyle {
        LanguageManager.shared.currentLanguage == "ko"
            ? ElegaiterTypography.Label3
            : ElegaiterTypography.Label4
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // 디바이스 정보 (안드로이드: weight(1f), padding(end = 16.dp))
            VStack(alignment: .leading, spacing: 0) {
                // 태그 + 디바이스명 세로 배치 (긴 이름 대응, spacedBy 6.dp)
                VStack(alignment: .leading, spacing: 6) {
                    if hasTag {
                        Text("device_recent".localized())
                            .typography(ElegaiterTypography.Caption3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(ElegaiterColors.Background.transparent)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(.trailing, 6)
                    }
                    Text(deviceName)
                        .typography(ElegaiterTypography.Headline6)
                        .foregroundColor(ElegaiterColors.Text.sub2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)
                
                Text(deviceType)
                    .typography(ElegaiterTypography.Body4)
                    .foregroundColor(ElegaiterColors.Text.sub1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 16)
            
            // 상태 배지 (안드로이드: RoundedCornerShape(20.dp), padding(vertical = 8.dp, horizontal = 16.dp))
            HStack(alignment: .center, spacing: 4) { // 안드로이드: Spacer(width = 4.dp)
                // 상태 텍스트 (안드로이드: 한국어 Label3, 그 외 Label4)
                Text(statusText)
                    .typography(statusTextTypography)
                    .foregroundColor(statusTextColor)
                
                // 체크 아이콘 (안드로이드: size(16.dp), statusTextColor와 동일)
                // DeviceError 화면에서는 IcCheckGray16 사용
                if showCheckIcon {
                    // statusTextColor가 TextDisabled인 경우 (DeviceError 화면) IcCheckGray16 사용
                    if statusTextColor == ElegaiterColors.Text.disabled {
                        Image("IcCheckGray16")
                            .renderingMode(.template)
                            .foregroundColor(statusTextColor)
                    } else {
                        Image("IcCheck16")
                            .renderingMode(.template)
                            .foregroundColor(statusTextColor) // 안드로이드: statusTextColor와 동일
                    }
                }
            }
            .padding(.horizontal, 16) // 안드로이드: horizontal = 16.dp
            .padding(.vertical, 8) // 안드로이드: vertical = 8.dp
            .background(statusBackgroundColor)
            .cornerRadius(20) // 안드로이드: RoundedCornerShape(20.dp)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionStatusRow(
            deviceName: "EL_KOR_SS_00001",
            deviceType: "JAWS 디바이스",
            statusText: "연결됨",
            statusTextColor: .white,
            statusBackgroundColor: .blue,
            hasTag: true
        )
        
        ConnectionStatusRow(
            deviceName: "EL_KOR_SS_00002",
            deviceType: "JAWS 디바이스",
            statusText: "연결 중",
            statusTextColor: .white,
            statusBackgroundColor: .orange
        )
    }
    .padding()
}
