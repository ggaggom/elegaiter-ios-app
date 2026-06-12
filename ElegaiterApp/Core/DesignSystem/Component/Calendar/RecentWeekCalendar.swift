//
//  RecentWeekCalendar.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 최근 7일 캘린더 컴포넌트
/// 
/// Android의 `RecentWeekCalendar`를 SwiftUI로 변환
/// - 최근 7일간의 운동 기록 존재 여부를 표시
struct RecentWeekCalendar: View {
    /// 주간 기록 존재 여부 (날짜: 존재여부)
    let weeklyRecordExistence: [String: Bool]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private var today: Date {
        Date()
    }
    
    var body: some View {
        // 안드로이드와 동일: Arrangement.SpaceBetween 방식
        // 전체 너비에서 좌우 여백 16을 제외한 공간을 7개의 셀(각 44pt)이 균등하게 분배
        HStack(spacing: 0) {
            ForEach(Array(getRecent7Days().enumerated()), id: \.element) { index, date in
                DayCell(
                    date: date,
                    isToday: Calendar.current.isDate(date, inSameDayAs: today),
                    isCompleted: hasRecord(for: date)
                )
                
                // 마지막 셀이 아니면 Spacer 추가 (균등 분배)
                if index < getRecent7Days().count - 1 {
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    /// 최근 7일 날짜 배열 반환 (6일 전부터 오늘까지)
    private func getRecent7Days() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        // 6일 전부터 오늘까지 (총 7일)
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(date)
            }
        }
        
        return dates.reversed() // 오래된 날짜부터
    }
    
    /// 해당 날짜에 기록이 있는지 확인
    private func hasRecord(for date: Date) -> Bool {
        let dateStr = dateFormatter.string(from: date)
        return weeklyRecordExistence[dateStr] ?? false
    }
}

// MARK: - Day Cell

/// 날짜 셀 컴포넌트 (안드로이드 DayCell과 동일)
private struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isCompleted: Bool
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        // 현재 언어에 따라 로케일 설정
        let currentLanguage = LanguageManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage == "ko" ? "ko_KR" : "en_US")
        return formatter
    }
    
    private let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private var isFaded: Bool {
        !isCompleted && !isToday
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else {
            return ElegaiterColors.Text.sub1
        }
    }
    
    private var circleBackgroundColor: Color {
        if isToday && isCompleted {
            return ElegaiterColors.Status.success // Green400
        } else if isToday && !isCompleted {
            return .white
        } else if !isToday && isCompleted {
            return ElegaiterColors.Background.dark // BackgroundDark
        } else {
            return .white
        }
    }
    
    /// 체크마크 아이콘 에셋 이름 반환
    /// 
    /// 안드로이드와 동일한 색상 매핑:
    /// - 오늘 + 완료: 검은색 (IcCheckBlack16)
    /// - 오늘 + 미완료: 회색 (IcCheckGray16)
    /// - 과거 + 완료: 초록색 (IcCheckGreen16)
    /// - 과거 + 미완료: 회색 (IcCheckGray16)
    private var checkmarkIconName: String {
        if isToday && isCompleted {
            return "IcCheckBlack16"
        } else if isToday && !isCompleted {
            return "IcCheckGray16"
        } else if !isToday && isCompleted {
            return "IcCheckGreen16"
        } else {
            return "IcCheckGray16"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 날짜 숫자 (위)
            Text(dayNumberFormatter.string(from: date))
                .typography(ElegaiterTypography.Caption3)
                .foregroundColor(textColor)
                .padding(.top, 8)
            
            // 요일 (아래)
            Text(dayFormatter.string(from: date))
                .typography(ElegaiterTypography.Label2)
                .foregroundColor(textColor)
                .padding(.bottom, 6)
            
            // 체크마크 원형 아이콘
            CheckmarkCircle(
                isCompleted: isCompleted,
                isFaded: isFaded,
                isToday: isToday,
                circleBackgroundColor: circleBackgroundColor,
                checkmarkIconName: checkmarkIconName
            )
        }
        .frame(width: 44, height: 84) // 피그마 디자인: 높이 84
        .background(
            isToday ? ElegaiterColors.Background.dark : Color.clear
        )
        .cornerRadius(30)
        .localized() // 언어 변경 시 자동 업데이트
    }
}

// MARK: - Checkmark Circle

/// 체크마크 원형 아이콘 컴포넌트 (안드로이드 CheckmarkCircle과 동일)
private struct CheckmarkCircle: View {
    let isCompleted: Bool
    let isFaded: Bool
    let isToday: Bool
    let circleBackgroundColor: Color
    let checkmarkIconName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(circleBackgroundColor)
                .frame(width: 28, height: 28)
            
            // 안드로이드와 동일: 항상 체크마크 아이콘 표시 (에셋 이미지 사용)
            Image(checkmarkIconName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 16, height: 16)
        }
    }
}

#Preview {
    RecentWeekCalendar(
        weeklyRecordExistence: [
            "20250101": true,
            "20250102": false,
            "20250103": true,
            "20250104": true,
            "20250105": false,
            "20250106": true,
            "20250107": true
        ]
    )
    .padding()
}
