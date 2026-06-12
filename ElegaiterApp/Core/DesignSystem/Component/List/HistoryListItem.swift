//
//  HistoryListItem.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import ElegaiterSDK
import os.log

private let historyListPreviewLogger = Logger(subsystem: "com.elegaiter.app", category: "HistoryListItem+Preview")

/// 기록 목록 아이템 컴포넌트
/// 
/// Android의 `HistoryListItem`를 SwiftUI로 변환
/// - 운동 기록 정보 표시
/// - 클릭 시 상세 화면으로 이동
struct HistoryListItem: View {
    /// 세션 정보
    let record: SessionInfo
    
    /// 기록 클릭 콜백
    let onRecordClick: () -> Void
    
    var body: some View {
        WhiteGrayCard {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 기록 제목 (안드로이드: Headline6, TextSub2)
                    Text(formatDisplayName(date: record.date, session: record.session))
                        .typography(ElegaiterTypography.Headline6)
                        .foregroundColor(ElegaiterColors.Text.sub2)
                    
                    // 운동 시간 (안드로이드: Body4, TextSub1, padding(top = 4.dp))
                    Text(formatElapsedTime(record.elapsedTime))
                        .typography(ElegaiterTypography.Body4)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                // 화살표 아이콘 (안드로이드: ic_arrow_right, size(24.dp))
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ElegaiterColors.Text.sub1)
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                onRecordClick()
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    /// 표시명 포맷팅
    /// 
    /// 날짜와 세션 번호를 사용하여 다국어 처리된 표시명 생성
    /// 한국어: "1월 7일 2회차"
    /// 영어: "1/7 - Session 2"
    private func formatDisplayName(date: String, session: Int) -> String {
        // 날짜 파싱: YYYYMMDD 형식
        guard date.count == 8 else {
            let formatString = "history_session_format".localized()
            return String(format: formatString, 1, 1, session)
        }
        
        let month = Int(String(date.dropFirst(4).prefix(2))) ?? 1
        let day = Int(String(date.dropFirst(6))) ?? 1
        
        // 로컬라이즈된 포맷 문자열 가져오기
        let formatString = "history_session_format".localized()
        return String(format: formatString, month, day, session)
    }
    
    /// 경과 시간 포맷팅
    /// 
    /// 안드로이드와 동일: 초 단위를 "X시간 X분 X초" 형식으로 변환
    private func formatElapsedTime(_ seconds: Int64) -> String {
        let hours = Int(seconds) / 3600
        let remainingSeconds = Int(seconds) % 3600
        let minutes = remainingSeconds / 60
        let secs = remainingSeconds % 60
        
        var result = ""
        if hours > 0 {
            result += "\(hours)" + "history_hour".localized() + " "
        }
        if minutes > 0 || hours > 0 {
            result += "\(minutes)" + "exercise_minutes_unit".localized() + " "
        }
        result += "\(secs)" + "exercise_seconds_unit".localized()
        return result
    }
}

#Preview {
    VStack(spacing: 12) {
        HistoryListItem(
            record: SessionInfo(
                fileName: "test_20250101_1.json",
                displayName: "06월 10일 1회차",
                date: "20250101",
                session: 1,
                elapsedTime: 1470
            ),
            onRecordClick: {
                historyListPreviewLogger.debug("Record clicked")
            }
        )
        
        HistoryListItem(
            record: SessionInfo(
                fileName: "test_20250101_2.json",
                displayName: "06월 10일 2회차",
                date: "20250101",
                session: 2,
                elapsedTime: 1215
            ),
            onRecordClick: {
                historyListPreviewLogger.debug("Record clicked")
            }
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
