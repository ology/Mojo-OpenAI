import json
from openai import OpenAI
import os
import sys

def get_response(messages):
    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
    response = client.chat.completions.create(
        messages=messages,
        model="gpt-4o-mini",
    )
    content = response.choices[0].message.content
    return content

def main():
    response = ""
    if sys.argv[1]:
        messages = sys.argv[1]
        if messages:
            messages = json.loads(messages)
            response = get_response(messages)
    print(response)

if __name__ == "__main__":
    main()
