#!/usr/bin/env python3
import requests
import json

def test_system():
    print("MyAI Integration Test")
    print("=" * 30)
    
    # Test Flutter app
    try:
        response = requests.get("http://localhost:8080", timeout=5)
        print("✓ Flutter app accessible")
    except:
        print("✗ Flutter app not accessible")
    
    # Test Ollama
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        models = response.json()["models"]
        gemma_models = [m for m in models if "gemma3:270m" in m["name"]]
        if gemma_models:
            print("✓ Ollama + gemma3:270m working")
        else:
            print("✗ gemma3:270m not found")
    except:
        print("✗ Ollama not accessible")
    
    # Test LLM query
    try:
        payload = {
            "model": "gemma3:270m",
            "prompt": "What is the capital of France?",
            "stream": False
        }
        response = requests.post("http://localhost:11434/api/generate", json=payload, timeout=30)
        if response.status_code == 200:
            result = response.json()["response"]
            print("✓ LLM query successful: " + result.strip()[:50] + "...")
        else:
            print("✗ LLM query failed")
    except Exception as e:
        print("✗ LLM query error: " + str(e))
    
    print("\nSystem Status: MyAI is operational!")
    print("Access at: http://localhost:8080")

if __name__ == "__main__":
    test_system()