# 评分系统 API 文档

## 概述

评分系统为 MindTuner 应用提供了完整的评分和反馈功能，支持多种类型的评分（冥想、心情、通用），并提供统计和分析功能。

## 功能特性

- ✅ 支持多种评分类型（冥想、心情、通用）
- ✅ 1-5星评分系统
- ✅ 评论和反馈功能
- ✅ 用户评分历史记录
- ✅ 评分统计和分析
- ✅ 批量操作支持
- ✅ 完整的CRUD操作

## API 端点

### 基础URL
```
http://localhost:8080/rating
```

### 1. 创建评分
**POST** `/rating/`

创建新的评分记录。

**请求体：**
```json
{
  "user_id": "user123",
  "rating_type": "meditation",
  "score": 4,
  "comment": "这次冥想体验很棒！"
}
```

**响应：**
```json
{
  "rating_id": "uuid-string",
  "user_id": "user123",
  "rating_type": "meditation",
  "score": 4,
  "comment": "这次冥想体验很棒！",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

### 2. 获取用户评分列表
**GET** `/rating/user/{user_id}`

获取指定用户的所有评分记录。

**查询参数：**
- `rating_type` (可选): 评分类型过滤
- `limit` (可选): 返回记录数量限制 (默认50, 最大100)

**示例：**
```
GET /rating/user/user123?rating_type=meditation&limit=20
```

### 3. 获取特定评分记录
**GET** `/rating/{rating_id}`

根据评分ID获取特定记录。

### 4. 更新评分记录
**PUT** `/rating/{rating_id}`

更新现有的评分记录。

**请求体：**
```json
{
  "score": 5,
  "comment": "更新后的评论"
}
```

### 5. 删除评分记录
**DELETE** `/rating/{rating_id}`

删除指定的评分记录。

### 6. 获取用户评分统计
**GET** `/rating/user/{user_id}/statistics`

获取用户的评分统计信息。

**查询参数：**
- `rating_type` (可选): 评分类型过滤
- `days` (可选): 统计天数 (默认30, 最大365)

**响应：**
```json
{
  "total_ratings": 10,
  "average_score": 4.2,
  "score_distribution": {
    "1": 0,
    "2": 1,
    "3": 2,
    "4": 4,
    "5": 3
  },
  "recent_ratings": [...]
}
```

### 7. 获取所有评分统计
**GET** `/rating/statistics/all`

获取所有用户的评分统计信息（管理员功能）。

### 8. 批量创建评分
**POST** `/rating/batch`

批量创建多个评分记录。

**请求体：**
```json
[
  {
    "user_id": "user123",
    "rating_type": "meditation",
    "score": 4,
    "comment": "第一次冥想"
  },
  {
    "user_id": "user123",
    "rating_type": "mood",
    "score": 5,
    "comment": "心情很好"
  }
]
```

### 9. 健康检查
**GET** `/rating/health`

检查评分服务状态。

## 评分类型

系统支持以下评分类型：

- `meditation`: 冥想体验评分
- `mood`: 心情记录评分
- `general`: 通用评分

## 数据模型

### RatingRecord
```python
class RatingRecord(BaseModel):
    rating_id: str
    user_id: str
    rating_type: RatingType
    score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None
    created_at: datetime
    updated_at: datetime
```

### RatingStatistics
```python
class RatingStatistics(BaseModel):
    total_ratings: int
    average_score: float
    score_distribution: dict[int, int]
    recent_ratings: list[RatingResponse]
```

## 前端集成

### Flutter 组件使用示例

```dart
import '../widgets/mark.dart';

// 使用评分组件
MarkWidget(
  ratingType: RatingType.meditation,
  onRatingSubmitted: (rating, comment) {
    print('评分: $rating, 评论: $comment');
    // 处理评分提交逻辑
  },
  onCancel: () {
    Navigator.of(context).pop();
  },
)

// 使用简化版评分组件
SimpleRatingWidget(
  initialRating: 3,
  starSize: 40,
  onRatingChanged: (rating) {
    print('评分: $rating');
  },
)
```

## 测试

运行测试脚本验证API功能：

```bash
cd MindTuner/backend
python test_rating_api.py
```

## 错误处理

API 使用标准的 HTTP 状态码：

- `200`: 成功
- `400`: 请求参数错误
- `404`: 资源不存在
- `500`: 服务器内部错误

错误响应格式：
```json
{
  "detail": "错误描述信息"
}
```

## 部署说明

1. 确保后端服务正在运行：
   ```bash
   cd MindTuner/backend/app
   python main.py
   ```

2. 前端配置API地址：
   - 开发环境: `http://localhost:8080`
   - 生产环境: 配置相应的服务器地址

3. 数据库配置：
   - 确保 Firebase 配置正确
   - 评分数据存储在 `ratings` 集合中

## 注意事项

1. 评分范围限制为 1-5 星
2. 用户ID需要从认证系统获取
3. 时间戳使用 UTC 时间
4. 评论字段为可选
5. 统计功能支持时间范围过滤

## 扩展功能

未来可以考虑添加的功能：

- 评分趋势分析
- 用户评分对比
- 评分推荐系统
- 评分导出功能
- 评分通知系统
