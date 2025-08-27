#!/usr/bin/env python3
"""
后端服务器启动脚本
"""

import os
import sys
import uvicorn
from pathlib import Path

# 添加当前目录到Python路径
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

# 设置代理环境变量（如果需要）
os.environ.setdefault("HTTP_PROXY", "http://192.168.0.111:10809")
os.environ.setdefault("HTTPS_PROXY", "http://192.168.0.111:10809")

def main():
    """启动服务器"""
    print("🚀 启动MindTuner后端服务器...")
    print("📍 服务器地址: http://0.0.0.0:8080")
    print("📖 API文档: http://localhost:8080/docs")
    print("=" * 50)
    
    try:
        # 启动FastAPI服务器
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8080,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n🛑 服务器已停止")
    except Exception as e:
        print(f"❌ 启动服务器失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
