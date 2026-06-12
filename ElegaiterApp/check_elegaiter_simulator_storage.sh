#!/bin/bash

# iOS 시뮬레이터 저장소 확인 스크립트
# 
# ElegaiterApp의 시뮬레이터 저장소를 확인합니다:
# - JSON 파일 (gait_data 폴더)
# - CoreData 데이터베이스 (GaitDatabase.sqlite)
# 
# 사용법: ./check_elegaiter_simulator_storage.sh

echo "=== ElegaiterApp 저장소 확인 ==="
echo ""

# 앱 번들 ID
BUNDLE_ID="com.ciklux.elegaiter.app"

# 실행 중인 시뮬레이터 찾기
SIMULATOR_DEVICE=$(xcrun simctl list devices | grep "Booted" | head -1 | sed -E 's/.*\(([^)]+)\).*/\1/')

if [ -z "$SIMULATOR_DEVICE" ]; then
    echo "❌ 실행 중인 시뮬레이터를 찾을 수 없습니다."
    echo "시뮬레이터를 실행한 후 다시 시도해주세요."
    exit 1
fi

echo "📱 시뮬레이터 디바이스 ID: $SIMULATOR_DEVICE"
echo "📦 앱 번들 ID: $BUNDLE_ID"
echo ""

# 앱 데이터 디렉토리 찾기 (자동으로 APP_ID를 찾아줌)
APP_DATA_DIR=$(xcrun simctl get_app_container "$SIMULATOR_DEVICE" "$BUNDLE_ID" data 2>/dev/null)

if [ -z "$APP_DATA_DIR" ]; then
    echo "❌ 앱 데이터 디렉토리를 찾을 수 없습니다."
    echo ""
    echo "가능한 원인:"
    echo "1. 앱이 설치되어 있지 않습니다."
    echo "2. 번들 ID가 잘못되었습니다."
    echo ""
    echo "앱을 실행한 후 다시 시도해주세요."
    exit 1
fi

echo "📂 앱 데이터 디렉토리: $APP_DATA_DIR"
echo ""

# Documents 디렉토리
DOCUMENTS_DIR="$APP_DATA_DIR/Documents"
GAIT_DATA_DIR="$DOCUMENTS_DIR/gait_data"
SQLITE_FILE="$DOCUMENTS_DIR/GaitDatabase.sqlite"

echo "=== JSON 파일 확인 ==="
if [ -d "$GAIT_DATA_DIR" ]; then
    JSON_COUNT=$(find "$GAIT_DATA_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ gait_data 폴더 존재"
    echo "📊 JSON 파일 개수: $JSON_COUNT"
    echo ""
    if [ "$JSON_COUNT" -gt 0 ]; then
        echo "📄 JSON 파일 목록:"
        find "$GAIT_DATA_DIR" -name "*.json" -exec basename {} \; 2>/dev/null | sort
    else
        echo "⚠️ JSON 파일이 없습니다."
    fi
else
    echo "❌ gait_data 폴더가 없습니다."
fi

echo ""
echo "=== CoreData 확인 ==="
if [ -f "$SQLITE_FILE" ]; then
    echo "✅ GaitDatabase.sqlite 파일 존재"
    echo "📊 파일 크기: $(du -h "$SQLITE_FILE" | cut -f1)"
    echo ""
    
    if command -v sqlite3 &> /dev/null; then
        TOTAL_RECORDS=$(sqlite3 "$SQLITE_FILE" "SELECT COUNT(*) FROM GaitRecordEntity;" 2>/dev/null)
        echo "📊 총 레코드 수: $TOTAL_RECORDS"
        echo ""
        
        if [ "$TOTAL_RECORDS" -gt 0 ]; then
            echo "📋 최근 10개 레코드:"
            sqlite3 -header -column "$SQLITE_FILE" "SELECT fileName, userId, date, sessionCount, status, elapsedTime FROM GaitRecordEntity ORDER BY createdAt DESC LIMIT 10;" 2>/dev/null
        else
            echo "⚠️ 레코드가 없습니다."
        fi
    else
        echo "⚠️ sqlite3가 설치되어 있지 않습니다."
    fi
else
    echo "❌ GaitDatabase.sqlite 파일이 없습니다."
fi

echo ""
echo "=== 완료 ==="
