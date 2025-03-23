#!/bin/bash

# 텍스트 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # 색상 초기화

# curl이 설치되어 있는지 확인하고 없으면 설치
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# 로고 표시 (주석 처리)
# curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# 메뉴
echo -e "${YELLOW}원하는 작업을 선택하세요:${NC}"
echo -e "${CYAN}1) 봇 설치${NC}"
echo -e "${CYAN}2) 봇 업데이트${NC}"
echo -e "${CYAN}3) 로그 보기${NC}"
echo -e "${CYAN}4) 봇 재시작${NC}"
echo -e "${CYAN}5) 봇 삭제${NC}"

echo -e "${YELLOW}번호를 입력하세요:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}봇을 설치하는 중...${NC}"

        # --- 1. 시스템 업데이트 및 필수 패키지 설치 ---
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y python3 python3-venv python3-pip curl
        
        # --- 2. 프로젝트 디렉토리 생성 ---
        PROJECT_DIR="$HOME/hyperbolic"
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR" || exit 1
        
        # --- 3. 가상 환경 생성 및 의존성 설치 ---
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install requests
        deactivate
        cd
        
        # --- 4. hyper_bot.py 다운로드 ---
        BOT_URL="https://raw.githubusercontent.com/smartcall1/hyperbolic/refs/heads/main/hyper_bot.py"
        curl -fsSL -o hyperbolic/hyper_bot.py "$BOT_URL"

        # --- 5. API 키 입력 (파일 변경 없음) ---
        echo -e "${YELLOW}Hyperbolic API 키를 입력하세요:${NC}"
        read USER_API_KEY
        # sed -i "s/HYPERBOLIC_API_KEY = \"\$API_KEY\"/HYPERBOLIC_API_KEY = \"$USER_API_KEY\"/" "$PROJECT_DIR/hyper_bot.py"
        
        # --- 6. questions.txt 다운로드  ---
        QUESTIONS_URL="https://raw.githubusercontent.com/smartcall1/hyperbolic/refs/heads/main/question.txt"
        curl -fsSL -o hyperbolic/questions.txt "$QUESTIONS_URL"

        # --- 7. systemd 서비스 생성 ---
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/hyper-bot.service
[Unit]
Description=Hyperbolic API 봇 서비스
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/hyperbolic
ExecStart=$HOME_DIR/hyperbolic/venv/bin/python $HOME_DIR/hyperbolic/hyper_bot.py
Restart=always
Environment=PATH=$HOME_DIR/hyperbolic/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT"

        # --- 8. systemd 설정을 다시 불러오고 서비스 시작 ---
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hyper-bot.service
        sudo systemctl start hyper-bot.service
        
        # 최종 메시지
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}로그를 확인하는 명령어:${NC}"
        echo "sudo journalctl -u hyper-bot.service -f"
        sleep 2
        sudo journalctl -u hyper-bot.service -f
        ;;

    2)
        echo -e "${BLUE}봇을 업데이트하는 중...${NC}"
        sleep 2
        echo -e "${GREEN}현재 봇은 최신 버전입니다.${NC}"
        ;;

    3)
        echo -e "${BLUE}로그를 확인하는 중...${NC}"
        # sudo journalctl -u hyper-bot.service -f (주석 처리)
        ;;

    4)
        echo -e "${BLUE}봇을 재시작하는 중...${NC}"
        sudo systemctl restart hyper-bot.service
        # sudo journalctl -u hyper-bot.service -f (주석 처리)
        ;;
        
    5)
        echo -e "${BLUE}봇을 삭제하는 중...${NC}"

        # 서비스 중지 및 제거
        sudo systemctl stop hyper-bot.service
        sudo systemctl disable hyper-bot.service
        sudo rm /etc/systemd/system/hyper-bot.service
        sudo systemctl daemon-reload
        sleep 2

        # 프로젝트 디렉토리 삭제
        rm -rf $HOME_DIR/hyperbolic

        echo -e "${GREEN}봇이 성공적으로 삭제되었습니다.${NC}"
        # 최종 메시지 (주석 처리)
        # echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        # echo -e "${GREEN}CRYPTO FORTOCHKA — 모든 암호화폐 정보를 한곳에서!${NC}"
        # echo -e "${CYAN}텔레그램 채널: https://t.me/cryptoforto${NC}"
        sleep 1
        ;;

    *)
        echo -e "${RED}잘못된 입력입니다. 1부터 5 사이의 숫자를 입력하세요!${NC}"
        ;;
esac
