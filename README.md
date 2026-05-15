# Resource Center

一个面向内网使用的轻量级资源共享中心，支持资源分类展示、搜索、文件下载和 AI 助手问答。当前版本适合小团队或部门内部共享常用软件、运维工具、使用文档和常见问题资料。

## 功能特性

- 资源分类展示：常用软件、运维工具、使用文档、常见问题
- 文件搜索：按文件名、分类和描述快速查找
- 静态资源下载：通过 Node.js 服务对外提供文件访问
- AI 助手：基于可用文件列表回答 IT 支持类问题
- 文件列表自动生成：Windows PowerShell 监控目录变化并更新 `data.js`
- 本地配置隔离：API Key 放在 `config.js`，不提交到仓库

## 技术栈

- 前端：原生 HTML、CSS、JavaScript
- 后端：Node.js 原生 `http` / `https` 模块
- 数据源：本地资源目录 + 自动生成的 `data.js`
- 运行脚本：PowerShell / VBScript
- AI 接口：火山引擎 Ark Chat Completions API

## 目录结构

```text
.
├── index.html              # 前端页面
├── proxy.js                # 静态文件服务和 AI 接口代理
├── safe_watch.ps1          # 扫描资源目录并生成 data.js
├── start_watcher_hidden.vbs# 后台启动监控脚本
├── config.example.js       # 配置示例
├── config.js               # 本地私有配置，不提交
├── data.js                 # 自动生成的资源数据，不提交
├── 常用软件/               # 本地资源目录，不提交
├── 运维工具/               # 本地资源目录，不提交
├── 使用文档/               # 本地资源目录，不提交
└── 常见问题/               # 本地资源目录，不提交
```

## 运行环境

- Node.js 18 或更高版本
- Windows PowerShell 5.1 或更高版本
- 可选：火山引擎 Ark API Key，用于启用 AI 助手

## 快速开始

1. 克隆仓库后进入项目目录。

2. 复制配置文件。

```bash
cp config.example.js config.js
```

3. 编辑 `config.js`，填写自己的 API Key。

```js
const CONFIG = {
  apiKey: "ark-your-api-key-here",
  model: "ark-code-latest"
};
```

如果不配置 API Key，资源中心仍可使用，AI 助手会显示未配置提示。

4. 启动服务。

```bash
npm start
```

或者直接运行：

```bash
node proxy.js
```

5. 浏览器访问：

```text
http://localhost:18888
```

## 自动更新资源列表

资源文件不建议提交到 GitHub。请把实际文件放入以下本地目录：

- `常用软件/`
- `运维工具/`
- `使用文档/`
- `常见问题/`

然后运行：

```bash
npm run watch
```

脚本会扫描资源目录，生成 `data.js`，并在文件变化时自动更新。

Windows 下也可以双击运行 `start_watcher_hidden.vbs`，让监控脚本在后台运行。

## AI 助手说明

前端会把用户问题发送到本地 Node.js 服务，`proxy.js` 再转发到 Ark API。这样可以避免浏览器直接跨域访问模型接口。

注意：当前项目仍是轻量级实现，`config.js` 仍会被浏览器加载，因此只适合内网可信环境。企业级部署时应把 API Key 完全移动到后端环境变量或密钥管理服务中，前端不应接触真实 Key。

## 安全注意事项

- 不要提交 `config.js`，其中可能包含真实 API Key。
- 如果 API Key 曾经提交到公开仓库，请立即在服务商控制台轮换密钥。
- 不要把 ISO、EXE、MSI、ZIP、PDF、DOCX 等大文件直接提交到 GitHub。
- 生产环境建议增加登录认证、权限校验、访问审计和下载鉴权。
- 公开部署前建议把 AI 代理改为后端持有密钥，并增加用户级限流。

## 企业化演进建议

如果后续要支持十万级文件、LDAP 域账号、数千用户和较高并发，建议升级为完整后端架构：

- 使用数据库保存文件元数据、用户、权限和审计日志
- 使用 Elasticsearch / OpenSearch 做文件搜索和全文检索
- 接入 LDAP / Active Directory 做统一认证
- 使用 Redis 做缓存、会话和限流
- 使用对象存储或 NAS 管理真实文件
- AI 助手改为后端 RAG 检索增强，按权限过滤可见文件

## License

MIT
