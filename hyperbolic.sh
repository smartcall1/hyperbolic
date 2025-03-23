#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color (reset)

# Check if curl is installed, install if missing
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Display logo
curl -s https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/logo_club.sh | bash

# Menu
echo -e "${YELLOW}Select an action:${NC}"
echo -e "${CYAN}1) Install bot${NC}"
echo -e "${CYAN}2) Update bot${NC}"
echo -e "${CYAN}3) View logs${NC}"
echo -e "${CYAN}4) Restart bot${NC}"
echo -e "${CYAN}5) Remove bot${NC}"

echo -e "${YELLOW}Enter a number:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Installing bot...${NC}"

        # --- 1. Update system and install required packages ---
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y python3 python3-venv python3-pip curl
        
        # --- 2. Create project directory ---
        PROJECT_DIR="$HOME/hyperbolic"
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR" || exit 1
        
        # --- 3. Create virtual environment and install dependencies ---
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install requests
        deactivate
        cd
        
        # --- 4. Download hyper_bot.py ---
        BOT_URL="https://raw.githubusercontent.com/smartcall1/hyperbolic/refs/heads/main/hyper_bot.py"
        curl -fsSL -o hyperbolic/hyper_bot.py "$BOT_URL"

        # --- 5. Request API key and insert it into hyper_bot.py ---
        echo -e "${YELLOW}Enter your API key for Hyperbolic:${NC}"
        read USER_API_KEY
        sed -i "s/HYPERBOLIC_API_KEY = \"\$API_KEY\"/HYPERBOLIC_API_KEY = \"$USER_API_KEY\"/" "$PROJECT_DIR/hyper_bot.py"
        
        # --- 6. Download questions.txt ---
        QUESTIONS_URL="https://raw.githubusercontent.com/noxuspace/cryptofortochka/main/hyperbolic/questions.txt"
        curl -fsSL -o hyperbolic/questions.txt "$QUESTIONS_URL"

        # --- 7. Create systemd service ---
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/hyper-bot.service
[Unit]
Description=Hyperbolic API Bot Service
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

        # --- 8. Reload systemd configuration and start the service ---
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hyper-bot.service
        sudo systemctl start hyper-bot.service
        
        # Final message
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}"
        echo "sudo journalctl -u hyper-bot.service -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — all crypto in one place!${NC}"
        echo -e "${CYAN}Our Telegram: https://t.me/cryptoforto${NC}"
        sleep 2
        sudo journalctl -u hyper-bot.service -f
        ;;

    2)
        echo -e "${BLUE}Updating bot...${NC}"
        sleep 2
        echo -e "${GREEN}Bot update is not required!${NC}"
        ;;

    3)
        echo -e "${BLUE}Viewing logs...${NC}"
        sudo journalctl -u hyper-bot.service -f
        ;;

    4)
        echo -e "${BLUE}Restarting bot...${NC}"
        sudo systemctl restart hyper-bot.service
        sudo journalctl -u hyper-bot.service -f
        ;;
        
    5)
        echo -e "${BLUE}Removing bot...${NC}"

        # Stop and remove service
        sudo systemctl stop hyper-bot.service
        sudo systemctl disable hyper-bot.service
        sudo rm /etc/systemd/system/hyper-bot.service
        sudo systemctl daemon-reload
        sleep 2

        # Remove project directory
        rm -rf $HOME_DIR/hyperbolic

        echo -e "${GREEN}Bot successfully removed!${NC}"
        # Final output
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}CRYPTO FORTOCHKA — all crypto in one place!${NC}"
        echo -e "${CYAN}Our Telegram: https://t.me/cryptoforto${NC}"
        sleep 1
        ;;

    *)
        echo -e "${RED}Invalid choice. Please enter a number from 1 to 5!${NC}"
        ;;
esac
