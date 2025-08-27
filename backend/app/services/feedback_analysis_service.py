import json
import time
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
import requests
from config.config import DEEPSEEK_API_KEY

@dataclass
class UserFeedback:
    """用户反馈数据结构"""
    user_id: str
    rating_score: int  # 1-5星评分
    rating_comment: Optional[str]  # 用户评论
    meditation_id: str  # 关联的冥想ID
    mood: str  # 用户当时的心情
    context: str  # 用户当时的描述
    created_at: datetime

@dataclass
class FeedbackAnalysis:
    """反馈分析结果"""
    overall_satisfaction: float  # 整体满意度 (0-1)
    key_issues: List[str]  # 主要问题
    improvement_suggestions: List[str]  # 改进建议
    user_preferences: Dict[str, Any]  # 用户偏好
    next_meditation_guidance: str  # 下次冥想的指导建议

class FeedbackAnalysisService:
    """用户反馈分析服务"""
    
    def __init__(self, deepseek_api_key: str):
        self.api_key = deepseek_api_key
        self.base_url = "https://api.deepseek.com"
        self.headers = {
            "Authorization": f"Bearer {deepseek_api_key}",
            "Content-Type": "application/json"
        }
    
    def analyze_user_feedback(self, feedback: UserFeedback, 
                            previous_feedbacks: List[UserFeedback] = None) -> FeedbackAnalysis:
        """分析用户反馈并生成优化建议"""
        
        if previous_feedbacks is None:
            previous_feedbacks = []
        
        overall_satisfaction = self._calculate_satisfaction(feedback, previous_feedbacks)
        analysis_result = self._analyze_feedback_content(feedback, previous_feedbacks)
        next_meditation_guidance = self._generate_next_meditation_guidance(
            feedback, previous_feedbacks, analysis_result
        )
        
        return FeedbackAnalysis(
            overall_satisfaction=overall_satisfaction,
            key_issues=analysis_result.get('key_issues', []),
            improvement_suggestions=analysis_result.get('improvement_suggestions', []),
            user_preferences=analysis_result.get('user_preferences', {}),
            next_meditation_guidance=next_meditation_guidance
        )
    
    def _calculate_satisfaction(self, feedback: UserFeedback, 
                              previous_feedbacks: List[UserFeedback]) -> float:
        """计算用户满意度"""
        current_satisfaction = feedback.rating_score / 5.0
        
        if previous_feedbacks:
            recent_cutoff = datetime.now() - timedelta(days=30)
            recent_feedbacks = [f for f in previous_feedbacks 
                              if f.created_at > recent_cutoff]
            
            if recent_feedbacks:
                recent_satisfaction = sum(f.rating_score for f in recent_feedbacks) / (len(recent_feedbacks) * 5.0)
                return current_satisfaction * 0.6 + recent_satisfaction * 0.4
        
        return current_satisfaction
    
    def _analyze_feedback_content(self, feedback: UserFeedback, 
                                previous_feedbacks: List[UserFeedback]) -> Dict[str, Any]:
        """分析反馈内容，提取关键信息和偏好"""
        
        # 使用DeepSeek API分析反馈内容
        analysis_prompt = self._build_analysis_prompt(feedback, previous_feedbacks)
        
        try:
            result = self._call_deepseek_api(analysis_prompt)
            return self._parse_analysis_result(result)
        except Exception as e:
            print(f"反馈分析失败: {e}")
            # 返回基础分析结果
            return self._basic_analysis(feedback)
    
    def _build_analysis_prompt(self, feedback: UserFeedback, 
                             previous_feedbacks: List[UserFeedback]) -> str:
        """构建分析提示词"""
        
        # 构建历史反馈摘要
        history_summary = ""
        if previous_feedbacks:
            recent_feedbacks = sorted(previous_feedbacks, 
                                    key=lambda x: x.created_at, reverse=True)[:5]
            history_summary = "\n历史反馈摘要:\n"
            for i, hist_feedback in enumerate(recent_feedbacks, 1):
                history_summary += f"{i}. 评分: {hist_feedback.rating_score}/5, "
                if hist_feedback.rating_comment:
                    history_summary += f"评论: {hist_feedback.rating_comment}, "
                history_summary += f"心情: {hist_feedback.mood}\n"
        
        prompt = f"""你是一个专业的冥想内容分析专家。请分析以下用户反馈，并提供详细的改进建议。

当前反馈:
- 用户ID: {feedback.user_id}
- 评分: {feedback.rating_score}/5星
- 评论: {feedback.rating_comment or "无评论"}
- 当时心情: {feedback.mood}
- 当时描述: {feedback.context}
- 反馈时间: {feedback.created_at.strftime('%Y-%m-%d %H:%M:%S')}
{history_summary}

请从以下角度进行分析:

1. 关键问题识别:
   - 用户可能遇到的主要问题
   - 内容质量方面的不足
   - 个性化程度的问题

2. 改进建议:
   - 内容调整建议
   - 风格优化建议
   - 个性化改进方向

3. 用户偏好分析:
   - 用户偏好的内容类型
   - 用户偏好的指导风格
   - 用户偏好的时长和节奏

4. 下次冥想指导建议:
   - 针对性的内容调整
   - 风格和语调的优化
   - 个性化元素的增强

请以JSON格式返回分析结果:
{{
    "key_issues": ["问题1", "问题2"],
    "improvement_suggestions": ["建议1", "建议2"],
    "user_preferences": {{
        "content_style": "描述用户偏好的内容风格",
        "guidance_tone": "描述用户偏好的指导语调",
        "duration_preference": "用户偏好的时长",
        "personalization_level": "用户偏好的个性化程度"
    }},
    "next_meditation_guidance": "详细的下次冥想指导建议"
}}

请确保分析准确、具体且可操作。"""

        return prompt
    
    def _call_deepseek_api(self, prompt: str) -> str:
        """调用DeepSeek API进行分析"""
        
        payload = {
            "model": "deepseek-chat",
            "messages": [
                {
                    "role": "system",
                    "content": "你是一个专业的冥想内容分析专家，擅长分析用户反馈并提供具体的改进建议。请始终以JSON格式返回分析结果。"
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.3,  # 较低的温度确保分析的一致性
            "max_tokens": 1000,
            "top_p": 0.9,
            "stream": False
        }
        
        response = requests.post(
            f"{self.base_url}/v1/chat/completions",
            headers=self.headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code != 200:
            raise Exception(f"API请求失败: {response.status_code}")
        
        result = response.json()
        if "choices" not in result or len(result["choices"]) == 0:
            raise Exception("无效的API响应格式")
        
        return result["choices"][0]["message"]["content"]
    
    def _parse_analysis_result(self, api_response: str) -> Dict[str, Any]:
        """解析API分析结果"""
        
        try:
            # 尝试提取JSON部分
            start_idx = api_response.find('{')
            end_idx = api_response.rfind('}') + 1
            
            if start_idx != -1 and end_idx != 0:
                json_str = api_response[start_idx:end_idx]
                result = json.loads(json_str)
                return result
            else:
                raise ValueError("未找到有效的JSON格式")
                
        except (json.JSONDecodeError, ValueError) as e:
            print(f"解析分析结果失败: {e}")
            return self._basic_analysis(None)
    
    def _basic_analysis(self, feedback: UserFeedback) -> Dict[str, Any]:
        """基础分析（当API分析失败时使用）"""
        
        if not feedback:
            return {
                "key_issues": [],
                "improvement_suggestions": [],
                "user_preferences": {},
                "next_meditation_guidance": "基于用户反馈优化冥想内容"
            }
        
        # 基于评分的基础分析
        if feedback.rating_score <= 2:
            key_issues = ["内容可能不够个性化", "指导风格可能不适合用户"]
            improvement_suggestions = ["增加个性化元素", "调整指导语调"]
        elif feedback.rating_score <= 3:
            key_issues = ["内容质量有待提升"]
            improvement_suggestions = ["优化内容结构", "增强实用性"]
        else:
            key_issues = []
            improvement_suggestions = ["保持当前风格", "微调个性化程度"]
        
        return {
            "key_issues": key_issues,
            "improvement_suggestions": improvement_suggestions,
            "user_preferences": {
                "content_style": "根据评分推断用户偏好",
                "guidance_tone": "温和指导",
                "duration_preference": "适中",
                "personalization_level": "中等"
            },
            "next_meditation_guidance": "基于用户评分调整内容风格和个性化程度"
        }
    
    def _generate_next_meditation_guidance(self, feedback: UserFeedback, 
                                         previous_feedbacks: List[UserFeedback],
                                         analysis_result: Dict[str, Any]) -> str:
        """生成下次冥想的指导建议"""
        
        guidance_prompt = f"""基于用户反馈分析，为下次冥想生成具体的指导建议。

用户信息:
- 当前评分: {feedback.rating_score}/5星
- 当前心情: {feedback.mood}
- 当前描述: {feedback.context}
- 用户评论: {feedback.rating_comment or "无评论"}

分析结果:
- 关键问题: {', '.join(analysis_result.get('key_issues', []))}
- 改进建议: {', '.join(analysis_result.get('improvement_suggestions', []))}
- 用户偏好: {analysis_result.get('user_preferences', {})}

请生成详细的下次冥想指导建议，包括:
1. 内容风格调整
2. 指导语调优化
3. 个性化元素增强
4. 具体的内容改进方向

请用中文回答，确保建议具体、可操作。"""

        try:
            result = self._call_deepseek_api(guidance_prompt)
            return result.strip()
        except Exception as e:
            print(f"生成指导建议失败: {e}")
            return "基于用户反馈优化冥想内容，增加个性化元素和实用性。"

# 创建全局实例
feedback_analysis_service = FeedbackAnalysisService(DEEPSEEK_API_KEY)
