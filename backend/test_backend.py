#!/usr/bin/env python3
"""
后端API测试脚本
用于验证后端服务是否正常工作
"""

import requests
import json
import time

# 配置
BASE_URL = "http://localhost:8080"
TEST_USER_ID = "test-user-123"
TEST_MOOD = "stressed"
TEST_DESCRIPTION = "I have a lot of work to do and feel overwhelmed"

def test_root_endpoint():
    """测试根端点"""
    print("🔍 测试根端点...")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        print(f"✅ 状态码: {response.status_code}")
        print(f"📄 响应: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ 错误: {e}")
        return False

def test_meditation_generation():
    """测试冥想生成"""
    print("\n🎯 测试冥想生成...")
    
    url = f"{BASE_URL}/meditation/generate-meditation"
    data = {
        "user_id": TEST_USER_ID,
        "mood": TEST_MOOD,
        "description": TEST_DESCRIPTION
    }
    
    try:
        print(f"📤 发送请求到: {url}")
        print(f"📝 请求数据: {json.dumps(data, indent=2)}")
        
        response = requests.post(
            url,
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=120  # 2分钟超时
        )
        
        print(f"📊 状态码: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ 冥想生成成功！")
            print(f"📋 记录ID: {result.get('record_id')}")
            print(f"📝 脚本长度: {len(result.get('meditation_script', ''))} 字符")
            print(f"🎵 音频URL: {result.get('audio_url')}")
            return True
        else:
            print(f"❌ 请求失败: {response.status_code}")
            print(f"📄 错误响应: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 请求异常: {e}")
        return False

def test_network_connectivity():
    """测试网络连接"""
    print("\n🌐 测试网络连接...")
    
    test_urls = [
        "https://www.google.com",
        "https://www.baidu.com",
        "https://api.deepseek.com"
    ]
    
    for url in test_urls:
        try:
            response = requests.get(url, timeout=10)
            print(f"✅ {url} - 状态码: {response.status_code}")
        except Exception as e:
            print(f"❌ {url} - 错误: {e}")

def main():
    """主测试函数"""
    print("🚀 开始后端API测试...")
    print(f"📍 目标地址: {BASE_URL}")
    print("=" * 50)
    
    # 测试1: 根端点
    root_success = test_root_endpoint()
    
    # 测试2: 网络连接
    test_network_connectivity()
    
    # 测试3: 冥想生成
    if root_success:
        meditation_success = test_meditation_generation()
    else:
        print("\n⚠️ 跳过冥想生成测试（根端点测试失败）")
        meditation_success = False
    
    # 总结
    print("\n" + "=" * 50)
    print("📊 测试结果总结:")
    print(f"   根端点测试: {'✅ 通过' if root_success else '❌ 失败'}")
    print(f"   冥想生成测试: {'✅ 通过' if meditation_success else '❌ 失败'}")
    
    if root_success and meditation_success:
        print("\n🎉 所有测试通过！后端服务运行正常。")
    else:
        print("\n⚠️ 部分测试失败，请检查后端配置。")

if __name__ == "__main__":
    main()
