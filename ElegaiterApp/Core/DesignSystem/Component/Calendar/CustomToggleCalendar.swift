//
//  CustomToggleCalendar.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import os.log

private let customToggleCalendarPreviewLogger = Logger(subsystem: "com.elegaiter.app", category: "CustomToggleCalendar+Preview")

/// 주간/월간 토글 캘린더 컴포넌트
/// 
/// Android의 `CustomToggleCalendar`를 SwiftUI로 변환
/// - 주간/월간 뷰 전환 지원
/// - 날짜별 목표 달성률 표시
/// - 날짜 선택 기능
/// - 주차 표시 및 네비게이션 지원
struct CustomToggleCalendar: View {
    /// 주간 뷰 여부
    let isWeeklyView: Bool
    
    /// 날짜별 목표 달성률 맵 (키: "yyyyMMdd", 값: 0~100)
    let dailyGoalProgressMap: [String: Int]
    
    /// 날짜 범위 변경 콜백
    let onVisibleDateRangeChanged: (Date, Date) -> Void
    
    /// 날짜 선택 콜백
    let onDaySelected: (Date) -> Void
    
    /// 날짜 포맷터 (yyyyMMdd)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    /// 현재 표시 중인 날짜 (주간/월간 네비게이션용)
    @State private var currentDisplayDate: Date = Date()
    
    /// 선택된 날짜
    @State private var selectedDate: Date = Date()
    
    /// 캘린더 인스턴스
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // 월요일을 주의 시작으로 설정
        return cal
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 (이전/다음 버튼 및 주차/월 표시)
            CalendarHeader(
                currentDate: currentDisplayDate,
                isWeeklyView: isWeeklyView,
                onPrevious: {
                    navigateToPrevious()
                },
                onNext: {
                    navigateToNext()
                }
            )
            
            Spacer()
                .frame(height: 24)
            
            // 요일 헤더
            DayOfWeekHeader()
            
            Spacer()
                .frame(height: 13)
            
            // 날짜 그리드
            if isWeeklyView {
                WeeklyDateGrid(
                    currentDate: currentDisplayDate,
                    today: Date(),
                    dailyGoalProgressMap: dailyGoalProgressMap,
                    onDayClick: { date in
                        selectedDate = date
                        onDaySelected(date)
                    }
                )
            } else {
                MonthlyDateGrid(
                    currentDate: currentDisplayDate,
                    today: Date(),
                    dailyGoalProgressMap: dailyGoalProgressMap,
                    onDayClick: { date in
                        selectedDate = date
                        onDaySelected(date)
                    }
                )
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ElegaiterColors.Stroke.medium, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            currentDisplayDate = Date()
            selectedDate = Date()
            updateDateRange()
        }
        .onChange(of: isWeeklyView) { _ in
            updateDateRange()
        }
        .onChange(of: currentDisplayDate) { _ in
            updateDateRange()
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - Helper Methods
    
    /// 날짜 범위 업데이트
    private func updateDateRange() {
        if isWeeklyView {
            // 주간 뷰: 현재 주의 시작일과 종료일 (항상 7일 범위)
            let startOfWeek = getStartOfWeek(for: currentDisplayDate)
            guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
                return
            }
            
            // 현재 월에 속한 날짜만 필터링하여 범위 계산
            let datesInWeek = (0..<7).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: startOfWeek)
            }
            let visibleDates = datesInWeek.filter { date in
                calendar.isDate(date, equalTo: currentDisplayDate, toGranularity: .month)
            }
            
            if let firstDate = visibleDates.first, let lastDate = visibleDates.last {
                onVisibleDateRangeChanged(firstDate, lastDate)
            }
        } else {
            // 월간 뷰: 현재 월의 첫 번째 날과 마지막 날
            let components = calendar.dateComponents([.year, .month], from: currentDisplayDate)
            guard let firstDay = calendar.date(from: components),
                  let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) else {
                return
            }
            onVisibleDateRangeChanged(firstDay, lastDay)
        }
    }
    
    /// 주의 시작일 구하기 (월요일)
    private func getStartOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        // 일요일 = 1, 월요일 = 2, ..., 토요일 = 7
        // 월요일까지의 일수 계산
        let daysToSubtract = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date) ?? date
    }
    
    /// 이전 주/월로 이동
    private func navigateToPrevious() {
        if isWeeklyView {
            let startOfWeek = getStartOfWeek(for: currentDisplayDate)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? currentDisplayDate
            
            // 주가 월을 넘나드는 경우 처리
            if !calendar.isDate(startOfWeek, equalTo: endOfWeek, toGranularity: .month) {
                // 현재 날짜가 속한 월에 따라 결정
                if calendar.isDate(currentDisplayDate, equalTo: endOfWeek, toGranularity: .month) {
                    currentDisplayDate = startOfWeek
                } else {
                    // 이전 주로 이동
                    if let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek) {
                        let prevWeekEnd = calendar.date(byAdding: .day, value: 6, to: prevWeek) ?? prevWeek
                        if !calendar.isDate(prevWeek, equalTo: prevWeekEnd, toGranularity: .month) {
                            currentDisplayDate = prevWeekEnd
                        } else {
                            currentDisplayDate = prevWeek
                        }
                    }
                }
            } else {
                // 같은 월 내에서 이전 주로 이동
                if let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfWeek) {
                    let prevWeekEnd = calendar.date(byAdding: .day, value: 6, to: prevWeek) ?? prevWeek
                    if !calendar.isDate(prevWeek, equalTo: prevWeekEnd, toGranularity: .month) {
                        currentDisplayDate = prevWeekEnd
                    } else {
                        currentDisplayDate = prevWeek
                    }
                }
            }
        } else {
            // 월간 뷰: 이전 월로 이동
            if let prevMonth = calendar.date(byAdding: .month, value: -1, to: currentDisplayDate) {
                currentDisplayDate = prevMonth
            }
        }
    }
    
    /// 다음 주/월로 이동
    private func navigateToNext() {
        if isWeeklyView {
            let startOfWeek = getStartOfWeek(for: currentDisplayDate)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? currentDisplayDate
            
            // 주가 월을 넘나드는 경우 처리
            if !calendar.isDate(startOfWeek, equalTo: endOfWeek, toGranularity: .month) {
                // 현재 날짜가 속한 월에 따라 결정
                if calendar.isDate(currentDisplayDate, equalTo: startOfWeek, toGranularity: .month) {
                    currentDisplayDate = endOfWeek
                } else {
                    // 다음 주로 이동
                    if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) {
                        currentDisplayDate = nextWeek
                    }
                }
            } else {
                // 같은 월 내에서 다음 주로 이동
                if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek) {
                    currentDisplayDate = nextWeek
                }
            }
        } else {
            // 월간 뷰: 다음 월로 이동
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDisplayDate) {
                currentDisplayDate = nextMonth
            }
        }
    }
    
    /// 주차 계산 (해당 월의 몇 번째 주인지)
    private func getWeekOfMonth(for date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return 1
        }
        
        // 첫 번째 월요일 찾기
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToFirstMonday = (firstWeekday + 5) % 7
        guard let firstMonday = calendar.date(byAdding: .day, value: -daysToFirstMonday, to: firstDayOfMonth) else {
            return 1
        }
        
        // 현재 날짜가 속한 주의 시작일
        let startOfCurrentWeek = getStartOfWeek(for: date)
        
        // 첫 번째 월요일부터 현재 주까지의 일수
        let daysDiff = calendar.dateComponents([.day], from: firstMonday, to: startOfCurrentWeek).day ?? 0
        let weekOfMonth = (daysDiff / 7) + 1
        
        return max(1, weekOfMonth)
    }
}

// MARK: - Calendar Header

/// 캘린더 헤더 (이전/다음 버튼 및 주차/월 표시)
private struct CalendarHeader: View {
    let currentDate: Date
    let isWeeklyView: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // 월요일
        return cal
    }
    
    private var displayText: String {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        
        // 현재 언어 확인
        let currentLanguage = LanguageManager.shared.currentLanguage
        
        if isWeeklyView {
            // 주차 계산
            let weekOfMonth = getWeekOfMonth(for: currentDate)
            
            if currentLanguage == "ko" {
                return "\(year)년 \(month)월 \(weekOfMonth)주차"
            } else {
                // 영어: "Week X, Month Year" 형식
                let monthFormatter = DateFormatter()
                monthFormatter.locale = Locale(identifier: "en_US")
                monthFormatter.dateFormat = "MMMM"
                let monthName = monthFormatter.string(from: currentDate)
                return "Week \(weekOfMonth), \(monthName) \(year)"
            }
        } else {
            if currentLanguage == "ko" {
                return "\(year)년 \(month)월"
            } else {
                // 영어: "Month Year" 형식
                let monthFormatter = DateFormatter()
                monthFormatter.locale = Locale(identifier: "en_US")
                monthFormatter.dateFormat = "MMMM"
                let monthName = monthFormatter.string(from: currentDate)
                return "\(monthName) \(year)"
            }
        }
    }
    
    private func getWeekOfMonth(for date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return 1
        }
        
        // 첫 번째 월요일 찾기
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToFirstMonday = (firstWeekday + 5) % 7
        guard let firstMonday = calendar.date(byAdding: .day, value: -daysToFirstMonday, to: firstDayOfMonth) else {
            return 1
        }
        
        // 현재 날짜가 속한 주의 시작일
        let startOfWeek = getStartOfWeek(for: date)
        
        // 첫 번째 월요일부터 현재 주까지의 일수
        let daysDiff = calendar.dateComponents([.day], from: firstMonday, to: startOfWeek).day ?? 0
        let weekOfMonth = (daysDiff / 7) + 1
        
        return max(1, weekOfMonth)
    }
    
    private func getStartOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date) ?? date
    }
    
    var body: some View {
        HStack {
            // 이전 버튼
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ElegaiterColors.Neutral.neutral600)
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            // 주차/월 표시
            Text(displayText)
                .typography(ElegaiterTypography.Label2)
                .foregroundColor(ElegaiterColors.Text.main)
            
            Spacer()
            
            // 다음 버튼
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ElegaiterColors.Neutral.neutral600)
                    .frame(width: 24, height: 24)
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

// MARK: - Day Of Week Header

/// 요일 헤더
private struct DayOfWeekHeader: View {
    private var daysOfWeek: [String] {
        [
            "calendar_monday".localized(),
            "calendar_tuesday".localized(),
            "calendar_wednesday".localized(),
            "calendar_thursday".localized(),
            "calendar_friday".localized(),
            "calendar_saturday".localized(),
            "calendar_sunday".localized()
        ]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .typography(ElegaiterTypography.Caption1)
                    .foregroundColor(ElegaiterColors.Text.sub1)
                    .frame(maxWidth: .infinity)
            }
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

// MARK: - Weekly Date Grid

/// 주간 날짜 그리드
private struct WeeklyDateGrid: View {
    let currentDate: Date
    let today: Date
    let dailyGoalProgressMap: [String: Int]
    let onDayClick: (Date) -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // 월요일
        return cal
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }
    
    private var dates: [Date] {
        let startOfWeek = getStartOfWeek(for: currentDate)
        
        // 항상 7일을 모두 반환
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private func getStartOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysToSubtract = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: date) ?? date
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates, id: \.self) { date in
                let currentMonth = calendar.component(.month, from: currentDate)
                let isCurrentMonth = calendar.component(.month, from: date) == currentMonth
                
                if isCurrentMonth {
                    CalendarDayCell(
                        date: date,
                        isToday: calendar.isDate(date, inSameDayAs: today),
                        progress: dailyGoalProgressMap[dateFormatter.string(from: date)] ?? 0,
                        onDayClick: {
                            onDayClick(date)
                        }
                    )
                } else {
                    // 현재 월에 속하지 않은 날짜는 빈 공간으로 표시
                    Spacer()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(4)
                }
            }
        }
    }
}

// MARK: - Monthly Date Grid

/// 월간 날짜 그리드
private struct MonthlyDateGrid: View {
    let currentDate: Date
    let today: Date
    let dailyGoalProgressMap: [String: Int]
    let onDayClick: (Date) -> Void
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // 월요일
        return cal
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }
    
    private var dates: [[Date]] {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return []
        }
        
        // 첫 번째 날의 요일 (일요일 = 1, 월요일 = 2, ...)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToSubtract = (firstWeekday + 5) % 7 // 월요일까지의 일수
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else {
            return []
        }
        
        // 6주치 날짜 생성 (42일)
        var weeks: [[Date]] = []
        for weekIndex in 0..<6 {
            var week: [Date] = []
            for dayIndex in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: weekIndex * 7 + dayIndex, to: startDate) {
                    week.append(date)
                }
            }
            // 현재 월에 속한 날짜가 있는 주만 추가
            if week.contains(where: { calendar.isDate($0, equalTo: firstDayOfMonth, toGranularity: .month) }) {
                weeks.append(week)
            }
        }
        
        return weeks
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(dates.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { date in
                        let isCurrentMonth = calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
                        
                        if isCurrentMonth {
                            CalendarDayCell(
                                date: date,
                                isToday: calendar.isDate(date, inSameDayAs: today),
                                progress: dailyGoalProgressMap[dateFormatter.string(from: date)] ?? 0,
                                onDayClick: {
                                    onDayClick(date)
                                }
                            )
                        } else {
                            // 다른 월의 날짜는 빈 공간
                            Spacer()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .padding(4)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Calendar Day Cell

/// 날짜 셀 컴포넌트
private struct CalendarDayCell: View {
    let date: Date
    let isToday: Bool
    let progress: Int // 0~100
    let onDayClick: () -> Void
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var dayOfMonth: Int {
        calendar.component(.day, from: date)
    }
    
    private var dayTextColor: Color {
        if isToday && progress == 0 {
            return .white // 오늘, 운동 기록 없음
        } else if isToday && progress > 0 {
            return ElegaiterColors.Text.main // 오늘, 운동 기록 있음
        } else if !isToday && progress > 0 {
            return ElegaiterColors.Text.main // 오늘 아님, 운동 기록 있음
        } else {
            return ElegaiterColors.Text.disabled // 오늘 아님, 운동 기록 없음
        }
    }
    
    var body: some View {
        Button(action: onDayClick) {
            ZStack {
                // 기본 배경 (모든 날짜에 투명 배경 적용하여 공간 확보)
                // 안드로이드: padding(2.dp).background(color = Color.Transparent, shape = RoundedCornerShape(50))
                Circle()
                    .fill(isToday ? 
                        LinearGradient(
                            colors: [
                                ElegaiterColors.Green.green300,
                                ElegaiterColors.Green.green400
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : 
                        LinearGradient(
                            colors: [Color.clear, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 진행률 원형 프로그레스 (progress > 0일 때만 표시)
                // 안드로이드: Canvas가 matchParentSize()로 Box 전체 크기 사용
                if progress > 0 {
                    GeometryReader { geometry in
                        let size = min(geometry.size.width, geometry.size.height)
                        
                        ZStack {
                            // 배경 원 (회색)
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 2)
                            
                            // 진행률 원
                            Circle()
                                .trim(from: 0, to: CGFloat(progress) / 100.0)
                                .stroke(
                                    ElegaiterColors.Green.green500,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: size, height: size)
                    }
                }
                
                // 날짜 텍스트
                Text("\(dayOfMonth)")
                    .typography(ElegaiterTypography.Label5)
                    .foregroundColor(dayTextColor)
            }
            .padding(2) // 안드로이드: Box에 padding(2.dp) 적용
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(4) // 안드로이드: 셀에 padding(4.dp) 적용
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomToggleCalendar(
            isWeeklyView: true,
            dailyGoalProgressMap: [
                "20250101": 80,
                "20250102": 100,
                "20250103": 50
            ],
            onVisibleDateRangeChanged: { start, end in
                customToggleCalendarPreviewLogger.debug("Date range changed: \(start) - \(end)")
            },
            onDaySelected: { date in
                customToggleCalendarPreviewLogger.debug("Day selected: \(date)")
            }
        )
        .padding()

        CustomToggleCalendar(
            isWeeklyView: false,
            dailyGoalProgressMap: [
                "20250101": 80,
                "20250102": 100,
                "20250103": 50
            ],
            onVisibleDateRangeChanged: { start, end in
                customToggleCalendarPreviewLogger.debug("Date range changed: \(start) - \(end)")
            },
            onDaySelected: { date in
                customToggleCalendarPreviewLogger.debug("Day selected: \(date)")
            }
        )
        .padding()
    }
}
