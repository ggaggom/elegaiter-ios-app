//
//  MonthlyAchievementSummary.swift
//  ElegaiterApp
//
//  Created on 2025-12-05.
//

import SwiftUI

/// 월간 성취 요약 컴포넌트
/// 
/// Android의 `MonthlyAchievementSummary`를 SwiftUI로 변환
/// - 현재 연속 운동 일수 및 이번 달 총 운동 일수 표시
/// - 그라데이션 배경 카드
struct MonthlyAchievementSummary: View {
    /// 현재 연속 운동 일수
    let currentStreak: Int
    /// 이번 달 총 운동 일수
    let totalExerciseDaysThisMonth: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // IcFire 아이콘
            Image("IcFire")
                .resizable()
                .renderingMode(.original)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                // 연속 기록 텍스트
                Text(streakText)
                    .typography(ElegaiterTypography.Headline6)
                    .foregroundColor(ElegaiterColors.Text.main)
                
                // 이번 달 총 운동 일수 텍스트
                Text("record_total_days_this_month".localized(format: totalExerciseDaysThisMonth))
                    .typography(ElegaiterTypography.Body4)
                    .foregroundColor(ElegaiterColors.Text.sub2)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [
                    ElegaiterColors.Green.green300,
                    ElegaiterColors.Green.green400.opacity(0.8)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    /// 연속 기록 텍스트 생성
    private var streakText: String {
        switch currentStreak {
        case 0:
            return "record_motivation1".localized()
        case 1:
            return "record_motivation2".localized()
        default:
            return "record_motivation3".localized(format: currentStreak)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MonthlyAchievementSummary(
            currentStreak: 0,
            totalExerciseDaysThisMonth: 5
        )
        .padding(.horizontal, 16)
        
        MonthlyAchievementSummary(
            currentStreak: 1,
            totalExerciseDaysThisMonth: 10
        )
        .padding(.horizontal, 16)
        
        MonthlyAchievementSummary(
            currentStreak: 7,
            totalExerciseDaysThisMonth: 15
        )
        .padding(.horizontal, 16)
    }
    .padding()
    .background(Color(.systemGray6))
}
