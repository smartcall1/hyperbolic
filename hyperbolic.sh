#!/bin/bash

cat << "EOF"

    ██████╗  ██████╗ ███╗   ██╗███████╗███╗   ███╗ ██████╗      ██╗██╗
    ██╔══██╗██╔═══██╗████╗  ██║██╔════╝████╗ ████║██╔═══██╗     ██║██║
    ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██╔████╔██║██║   ██║     ██║██║
    ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ██║╚██╔╝██║██║   ██║██   ██║██║
    ██████╔╝╚██████╔╝██║ ╚████║███████╗██║ ╚═╝ ██║╚██████╔╝╚█████╔╝██║
    ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝ ╚═════╝  ╚════╝ ╚═╝
    ═══════════════════════════════════════════════════════════════════
              🤖 MADE BY DONEMOJI, https://x.com/d0nemoji 🤖
    ═══════════════════════════════════════════════════════════════════

EOF

# 텍스트 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 색상 초기화

# 백그라운드 프로세스 관리
declare -a BACKGROUND_PIDS=()

# 프로세스 정리 함수
cleanup() {
    echo -e "\n${YELLOW}스크립트를 종료합니다. 백그라운드 프로세스를 정리합니다...${NC}"
    
    # 모든 백그라운드 프로세스 종료
    for pid in "${BACKGROUND_PIDS[@]}"; do
        if ps -p $pid > /dev/null; then
            echo -e "${BLUE}프로세스 $pid 종료 중...${NC}"
            kill $pid 2>/dev/null || kill -9 $pid 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}모든 백그라운드 프로세스가 종료되었습니다.${NC}"
    exit 0
}

# 스크립트 종료 시 cleanup 함수 실행
trap cleanup SIGINT SIGTERM EXIT

# 필수 패키지 설치 확인 및 설치
check_and_install_packages() {
    local packages=("curl" "jq")
    for pkg in "${packages[@]}"; do
        if ! command -v $pkg &> /dev/null; then
            echo -e "${YELLOW}$pkg 설치 중...${NC}"
            sudo apt update
            sudo apt install -y $pkg
        fi
    done
}

# API 설정
HYPERBOLIC_API_URL="https://api.hyperbolic.xyz/v1/chat/completions"
MODEL="meta-llama/Llama-3.3-70B-Instruct"
MAX_TOKENS=2048
TEMPERATURE=0.7
TOP_P=0.9

# API 응답 가져오기 함수
get_response() {
    local question="$1"
    local api_key="$2"
    
    curl -s -X POST "$HYPERBOLIC_API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d "{
            \"messages\": [{\"role\": \"user\", \"content\": \"$question\"}],
            \"model\": \"$MODEL\",
            \"max_tokens\": $MAX_TOKENS,
            \"temperature\": $TEMPERATURE,
            \"top_p\": $TOP_P
        }" | jq -r '.choices[0].message.content'
}

# 메인 봇 함수
run_bot() {
    local api_key="$1"
    local questions_file="$2"
    local delay="$3"
    local bot_id="$4"
    local status_file="$5"
    
    if [ ! -f "$questions_file" ]; then
        echo -e "${RED}오류: $questions_file 파일을 찾을 수 없습니다.${NC}"
        echo "status=error" > "$status_file"
        return 1
    fi
    
    # 질문 배열로 읽기
    mapfile -t questions < "$questions_file"
    
    if [ ${#questions[@]} -eq 0 ]; then
        echo -e "${RED}오류: 질문 파일이 비어있습니다.${NC}"
        echo "status=error" > "$status_file"
        return 1
    fi
    
    # 상태 파일 초기화
    echo "status=running" > "$status_file"
    echo "current_question=0" >> "$status_file"
    echo "total_questions=${#questions[@]}" >> "$status_file"
    echo "last_update=$(date +%s)" >> "$status_file"
    
    local index=0
    while true; do
        local question="${questions[$index]}"
        echo -e "${CYAN}질문 #$((index+1)): $question${NC}"
        
        # 상태 파일 업데이트
        echo "current_question=$((index+1))" > "$status_file"
        echo "status=running" >> "$status_file"
        echo "total_questions=${#questions[@]}" >> "$status_file"
        echo "last_update=$(date +%s)" >> "$status_file"
        echo "current_question_text=$question" >> "$status_file"
        
        local answer=$(get_response "$question" "$api_key")
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}응답: $answer${NC}"
            echo "last_response=success" >> "$status_file"
        else
            echo -e "${RED}오류: 질문에 대한 응답을 가져오는 중 오류가 발생했습니다.${NC}"
            echo "last_response=error" >> "$status_file"
        fi
        
        index=$((index + 1))
        if [ $index -ge ${#questions[@]} ]; then
            index=0
        fi
        
        echo -e "${YELLOW}다음 질문까지 ${delay}초 대기합니다.${NC}"
        echo "next_question_delay=$delay" >> "$status_file"
        sleep $delay
    done
}

# 상태 모니터링 함수
monitor_bots() {
    local status_dir="$1"
    local api_keys_file="$2"
    
    # API 키 배열로 읽기
    mapfile -t api_keys < "$api_keys_file"
    local api_count=${#api_keys[@]}
    
    # 화면 지우기
    clear
    
    # 상태 모니터링 루프
    while true; do
        # 화면 지우기
        clear
        
        # 현재 시간 표시
        echo -e "${PURPLE}===== 봇 상태 모니터링 ($(date)) =====${NC}"
        echo ""
        
        # 각 봇의 상태 확인
        local all_running=true
        
        for i in $(seq 1 $api_count); do
            local status_file="$status_dir/bot$i.status"
            local api_key="${api_keys[$i-1]}"
            local masked_key="${api_key: -4}"
            
            echo -e "${BLUE}API 키 (끝자리: ${masked_key}) - 봇 #$i${NC}"
            
            if [ -f "$status_file" ]; then
                # 상태 파일에서 정보 읽기
                local status=$(grep "status=" "$status_file" | cut -d= -f2)
                local current_question=$(grep "current_question=" "$status_file" | cut -d= -f2)
                local total_questions=$(grep "total_questions=" "$status_file" | cut -d= -f2)
                local last_update=$(grep "last_update=" "$status_file" | cut -d= -f2)
                local current_time=$(date +%s)
                local time_diff=$((current_time - last_update))
                
                # 상태에 따라 다른 메시지 표시
                if [ "$status" = "running" ]; then
                    if [ $time_diff -gt 300 ]; then
                        echo -e "${RED}상태: 응답 없음 (${time_diff}초 경과)${NC}"
                        all_running=false
                    else
                        echo -e "${GREEN}상태: 실행 중${NC}"
                    fi
                elif [ "$status" = "error" ]; then
                    echo -e "${RED}상태: 오류 발생${NC}"
                    all_running=false
                else
                    echo -e "${YELLOW}상태: 알 수 없음${NC}"
                    all_running=false
                fi
                
                # 현재 질문 정보 표시
                if [ -n "$current_question" ] && [ -n "$total_questions" ]; then
                    echo -e "진행 상황: $current_question / $total_questions 질문"
                    
                    # 현재 질문 텍스트 표시 (있는 경우)
                    if grep -q "current_question_text=" "$status_file"; then
                        local question_text=$(grep "current_question_text=" "$status_file" | cut -d= -f2-)
                        echo -e "현재 질문: $question_text"
                    fi
                fi
                
                # 마지막 응답 상태 표시
                if grep -q "last_response=" "$status_file"; then
                    local last_response=$(grep "last_response=" "$status_file" | cut -d= -f2)
                    if [ "$last_response" = "success" ]; then
                        echo -e "마지막 응답: ${GREEN}성공${NC}"
                    else
                        echo -e "마지막 응답: ${RED}실패${NC}"
                    fi
                fi
                
                # 다음 질문까지 대기 시간 표시
                if grep -q "next_question_delay=" "$status_file"; then
                    local delay=$(grep "next_question_delay=" "$status_file" | cut -d= -f2)
                    echo -e "다음 질문까지: ${YELLOW}${delay}초${NC}"
                fi
            else
                echo -e "${RED}상태: 상태 파일 없음${NC}"
                all_running=false
            fi
            
            echo ""
        done
        
        # 모든 봇이 실행 중인지 확인
        if [ "$all_running" = "true" ]; then
            echo -e "${GREEN}모든 봇이 정상적으로 실행 중입니다.${NC}"
        else
            echo -e "${YELLOW}일부 봇에 문제가 있습니다. 로그를 확인하세요.${NC}"
        fi
        
        echo -e "${PURPLE}===== 모니터링 중... (종료하려면 Ctrl+C를 누르세요) =====${NC}"
        
        # 5초마다 상태 업데이트
        sleep 5
    done
}

# 여러 API 키로 봇 실행 함수
run_multiple_bots() {
    local api_keys_file="$1"
    local questions_dir="$2"
    
    if [ ! -f "$api_keys_file" ]; then
        echo -e "${RED}오류: API 키 파일을 찾을 수 없습니다.${NC}"
        return 1
    fi
    
    # API 키 배열로 읽기
    mapfile -t api_keys < "$api_keys_file"
    
    if [ ${#api_keys[@]} -eq 0 ]; then
        echo -e "${RED}오류: API 키 파일이 비어있습니다.${NC}"
        return 1
    fi
    
    # 상태 디렉토리 생성
    local status_dir="$HOME/hyperbolic/status"
    mkdir -p "$status_dir"
    
    # 이전 상태 파일 정리
    rm -f "$status_dir"/*.status
    
    # 모든 API 키에 대해 동일한 랜덤 지연 시간 생성 (5분~30분)
    local delay=$((RANDOM % 1501 + 300))
    echo -e "${PURPLE}모든 API 키에 대해 ${delay}초의 동일한 지연 시간이 설정되었습니다.${NC}"
    
    # 각 API 키에 대해 백그라운드에서 봇 실행
    for i in "${!api_keys[@]}"; do
        local api_key="${api_keys[$i]}"
        local question_file="$questions_dir/question$((i+1)).txt"
        local bot_id=$((i+1))
        local status_file="$status_dir/bot$bot_id.status"
        
        # API 키의 마지막 4자리만 표시하여 보안 유지
        local masked_key="${api_key: -4}"
        echo -e "${BLUE}API 키 (끝자리: ${masked_key})에 대한 봇을 시작합니다...${NC}"
        echo -e "${BLUE}질문 파일: $question_file${NC}"
        
        run_bot "$api_key" "$question_file" "$delay" "$bot_id" "$status_file" &
        BACKGROUND_PIDS+=($!)
    done
    
    echo -e "${GREEN}모든 봇이 백그라운드에서 실행 중입니다.${NC}"
    echo -e "${YELLOW}상태 모니터링을 시작합니다...${NC}"
    
    # 상태 모니터링 시작
    monitor_bots "$status_dir" "$api_keys_file"
}

# 메뉴
echo -e "${YELLOW}원하는 작업을 선택하세요:${NC}"
echo -e "${CYAN}1) 봇 설치${NC}"
echo -e "${CYAN}2) 봇 실행${NC}"
echo -e "${CYAN}3) 봇 삭제${NC}"
echo -e "${CYAN}4) 봇 상태 확인${NC}"

echo -e "${YELLOW}번호를 입력하세요:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}봇을 설치하는 중...${NC}"
        check_and_install_packages
        
        # 프로젝트 디렉토리 생성
        PROJECT_DIR="$HOME/hyperbolic"
        mkdir -p "$PROJECT_DIR"
        mkdir -p "$PROJECT_DIR/questions"
        mkdir -p "$PROJECT_DIR/status"
        cd "$PROJECT_DIR" || exit 1
        
        # API 키 입력
        echo -e "${YELLOW}Hyperbolic API 키를 입력하세요 (여러 개 입력 가능, 빈 줄로 종료):${NC}"
        echo -e "${YELLOW}각 API 키를 새 줄에 입력하세요. 입력이 끝나면 빈 줄을 입력하세요.${NC}"
        
        # API 키를 임시 파일에 저장
        temp_file=$(mktemp)
        while true; do
            read -p "API 키: " api_key
            if [ -z "$api_key" ]; then
                break
            fi
            echo "$api_key" >> "$temp_file"
        done
        
        # API 키가 하나 이상 입력되었는지 확인
        if [ ! -s "$temp_file" ]; then
            echo -e "${RED}오류: 최소 하나의 API 키를 입력해야 합니다.${NC}"
            rm "$temp_file"
            exit 1
        fi
        
        # API 키를 프로젝트 디렉토리에 저장
        mv "$temp_file" "$PROJECT_DIR/api_keys.txt"
        
        # API 키 개수 확인
        api_count=$(wc -l < "$PROJECT_DIR/api_keys.txt")
        echo -e "${GREEN}총 $api_count개의 API 키가 입력되었습니다.${NC}"
        
        # 각 API 키마다 다른 질문 파일 다운로드
        echo -e "${YELLOW}각 API 키마다 다른 질문 파일을 다운로드합니다...${NC}"
        
        for i in $(seq 1 $api_count); do
            echo -e "${BLUE}질문 파일 $i 다운로드 중...${NC}"
            QUESTIONS_URL="https://raw.githubusercontent.com/smartcall1/hyperbolic/refs/heads/main/question$i.txt"
            curl -fsSL -o "$PROJECT_DIR/questions/question$i.txt" "$QUESTIONS_URL"
            
            # 파일이 존재하는지 확인
            if [ ! -s "$PROJECT_DIR/questions/question$i.txt" ]; then
                echo -e "${RED}경고: question$i.txt 파일을 다운로드할 수 없습니다. 기본 질문 파일을 사용합니다.${NC}"
                # 기본 질문 파일 다운로드
                QUESTIONS_URL="https://raw.githubusercontent.com/smartcall1/hyperbolic/refs/heads/main/question.txt"
                curl -fsSL -o "$PROJECT_DIR/questions/question$i.txt" "$QUESTIONS_URL"
            fi
        done
        
        echo -e "${GREEN}설치가 완료되었습니다!${NC}"
        ;;
        
    2)
        echo -e "${BLUE}봇을 실행하는 중...${NC}"
        PROJECT_DIR="$HOME/hyperbolic"
        
        if [ ! -f "$PROJECT_DIR/api_keys.txt" ]; then
            echo -e "${RED}오류: API 키 파일을 찾을 수 없습니다. 먼저 봇을 설치해주세요.${NC}"
            exit 1
        fi
        
        run_multiple_bots "$PROJECT_DIR/api_keys.txt" "$PROJECT_DIR/questions"
        ;;
        
    3)
        echo -e "${BLUE}봇을 삭제하는 중...${NC}"
        rm -rf "$HOME/hyperbolic"
        echo -e "${GREEN}봇이 삭제되었습니다.${NC}"
        ;;
        
    4)
        echo -e "${BLUE}봇 상태를 확인하는 중...${NC}"
        PROJECT_DIR="$HOME/hyperbolic"
        
        if [ ! -f "$PROJECT_DIR/api_keys.txt" ]; then
            echo -e "${RED}오류: API 키 파일을 찾을 수 없습니다. 먼저 봇을 설치해주세요.${NC}"
            exit 1
        fi
        
        # 상태 모니터링 시작
        monitor_bots "$PROJECT_DIR/status" "$PROJECT_DIR/api_keys.txt"
        ;;
        
    *)
        echo -e "${RED}잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac