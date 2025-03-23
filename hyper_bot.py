import time
import requests
import logging

# Hyperbolic API 설정
HYPERBOLIC_API_URL = "https://api.hyperbolic.xyz/v1/chat/completions"
HYPERBOLIC_API_KEY = "$API_KEY"  # API 키를 입력하세요.
MODEL = "meta-llama/Llama-3.3-70B-Instruct"  # 또는 원하는 모델을 지정하세요.
MAX_TOKENS = 2048
TEMPERATURE = 0.7
TOP_P = 0.9
DELAY_BETWEEN_QUESTIONS = 30  # 질문 간 지연 시간 (초)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_response(question: str) -> str:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {HYPERBOLIC_API_KEY}"
    }
    data = {
        "messages": [{"role": "user", "content": question}],
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "temperature": TEMPERATURE,
        "top_p": TOP_P
    }
    response = requests.post(HYPERBOLIC_API_URL, headers=headers, json=data, timeout=30)
    response.raise_for_status()
    json_response = response.json()
    # 응답이 OpenAI API와 유사한 구조라고 가정
    return json_response.get("choices", [{}])[0].get("message", {}).get("content", "No answer")

def main():
    # "questions.txt" 파일에서 질문 읽기
    try:
        with open("questions.txt", "r", encoding="utf-8") as f:
            questions = [line.strip() for line in f if line.strip()]
    except Exception as e:
        logger.error(f"questions.txt 파일을 읽는 중 오류 발생: {e}")
        return

    if not questions:
        logger.error("questions.txt 파일에 질문이 없습니다.")
        return

    index = 0
    while True:
        question = questions[index]
        logger.info(f"질문 #{index+1}: {question}")
        try:
            answer = get_response(question)
            logger.info(f"응답: {answer}")
        except Exception as e:
            logger.error(f"질문에 대한 응답을 가져오는 중 오류 발생: {question}\n{e}")
        index = (index + 1) % len(questions)
        time.sleep(DELAY_BETWEEN_QUESTIONS)

if __name__ == "__main__":
    main()
