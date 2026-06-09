# Personal Vault（个人数字档案库）

一款完全离线的 Android 个人数据管理应用，基于 Flutter 构建。

## 功能特性

### 多类型数据存储
- **文本记录** — 账号密码、银行卡信息、API Key、个人备注等
- **密码保险箱** — 专门的密码管理，一键复制、密码强度检测
- **图片管理** — JPG/PNG/WEBP，缩略图预览和全屏查看
- **文件管理** — PDF/Word/Excel/TXT/ZIP
- **链接管理** — 网站链接、网盘链接、视频链接

### 分类系统
- 无限级分类，自由创建/修改/删除
- 树形结构展示
- 每条记录归属一个分类

### 模板系统
- 自定义数据模板（网站账号、客户信息、设备信息等）
- 内置预设模板
- 录入时自动套用模板

### 标签系统
- 自定义标签，多标签支持
- 彩色标签

### 全局搜索
- 搜索标题、内容、标签、文件名、分类
- 类型筛选
- 模糊搜索

### 导出系统
- Markdown / PDF / TXT / JSON 多格式导出
- 单条导出、分类导出、全部导出

### 本地备份
- 一键完整备份（数据 + 文件）
- 本地恢复
- 备份历史管理

### 数据安全
- AES-256 加密存储敏感数据
- 指纹/面容识别解锁
- 主密码保护
- 5次错误密码自动锁定

## 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| 数据库 | SQLite (sqflite) |
| 加密 | AES-256 (encrypt) |
| 生物识别 | local_auth |
| 安全存储 | flutter_secure_storage |
| 主题 | Material 3 + Google Fonts |

## 项目结构

```
lib/
├── main.dart                          # 入口
├── core/
│   ├── constants/                     # 常量
│   ├── database/                      # SQLite 数据库层
│   ├── models/                        # 数据模型
│   ├── providers/                     # Riverpod 状态管理
│   ├── services/                      # 业务服务
│   ├── theme/                         # 主题配置
│   └── utils/                         # 工具函数
└── features/
    ├── home/                          # 首页
    ├── categories/                    # 分类管理
    ├── entries/                       # 记录编辑/详情
    ├── passwords/                     # 密码保险箱
    ├── templates/                     # 模板管理
    ├── search/                        # 全局搜索
    ├── settings/                      # 设置
    ├── backup/                        # 备份恢复
    └── shared/                        # 共享组件
```

## 运行方式

```bash
# 安装依赖
flutter pub get

# 运行调试
flutter run

# 构建 APK
flutter build apk --release
```

## 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK >= 21 (Android 5.0)
- 推荐 Android SDK >= 34
