# Immich Machine Learning 工作原理

## 概述

Immich 的 machine-learning 模块是一个独立的 Python 微服务，基于 FastAPI 框架构建，为 Immich 提供 AI 功能支持。它主要负责三大核心任务：

1. **CLIP 图像搜索** - 使用 CLIP 模型实现语义化的图像搜索
2. **人脸识别** - 检测和识别照片中的人脸
3. **OCR 文字识别** - 从图像中提取文字内容

## 主机配置要求

### 最低配置要求

#### 基础系统要求（整个 Immich 系统）

- **操作系统**: 推荐 Linux 或类 Unix 系统（Ubuntu、Debian 等）
  - Windows/macOS 可通过 Docker Desktop 运行，但体验较差
  - WSL2 是 Windows 上的推荐方案
- **内存**: 
  - 最低 6GB RAM（启用 ML 功能）
  - 推荐 8GB+ RAM
  - 仅 4GB RAM 的系统需要禁用 ML 功能
- **CPU**: 
  - 最低 2 核心
  - 推荐 4 核心以上
- **存储**: 
  - 推荐 Unix 兼容文件系统（EXT4、ZFS、APFS 等）
  - 缩略图和转码视频会增加 10-20% 的存储空间
  - AI 模型缓存需要额外 2-10GB 空间（取决于启用的功能）

#### Machine Learning 服务专用要求

**CPU 模式（默认）**:
- **内存**: 2-4GB RAM（取决于模型大小和并发数）
- **CPU**: 2+ 核心，推荐 4 核心
- **存储**: 2-5GB（模型缓存）
- **Python**: 3.11+

**模型大小参考**:
```
CLIP (ViT-B-32):        ~350MB
人脸识别 (buffalo_l):   ~600MB
OCR (PP-OCRv5):         ~200MB
总计（全部启用）:        ~2-3GB
```

### 硬件加速配置（可选）

启用硬件加速可以显著提升性能并降低 CPU 负载。

#### 1. NVIDIA GPU (CUDA)

**要求**:
- **GPU**: 计算能力 ≥ 5.2 的 NVIDIA 显卡
  - 支持的显卡：GTX 900 系列及以上、所有 RTX 系列
  - 查询计算能力：https://developer.nvidia.com/cuda-gpus
- **驱动**: NVIDIA 驱动 ≥ 545（支持 CUDA 12.3）
- **Linux**: 需要安装 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- **VRAM**: 推荐 4GB+（取决于模型和并发数）
- **额外依赖**: cuDNN 9.10+

**Docker 镜像**:
```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-cuda
```

**性能提升**: 5-10 倍（相比 CPU）

#### 2. AMD GPU (ROCm)

**要求**:
- **GPU**: ROCm 官方支持的 AMD 显卡
  - 非官方支持的显卡可尝试设置 `HSA_OVERRIDE_GFX_VERSION`
- **磁盘空间**: 至少 35GB（镜像很大）
- **注意事项**: 
  - 新后端，可能存在问题
  - 空闲时 GPU 功耗可能较高（5 分钟后恢复正常）
  - MIGraphX 首次推理较慢（运行时编译模型）

**Docker 镜像**:
```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-rocm
```

#### 3. Intel GPU (OpenVINO)

**要求**:
- **GPU**: Intel 集成显卡或独立显卡（Iris Xe、Arc 系列）
- **内核**: 足够新的 Linux 内核版本
- **内存**: 比 CPU 模式需要更多 RAM
- **注意**: 集成显卡比独立显卡更容易出问题

**Docker 镜像**:
```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-openvino
```

**WSL2 特殊配置**:
需要确保容器可以访问 `/dev/dri` 目录，并添加正确的用户组。

#### 4. ARM Mali GPU (ARM NN)

**要求**:
- **GPU**: Mali GPU（仅限 Mali 芯片）
- **驱动**: 预装的 Linux 内核驱动
- **设备**: `/dev/mali0` 必须可用
- **固件**: 闭源 `libmali.so` 固件文件
  - 通常位于 `/usr/lib/libmali.so`
  - 可能需要额外的 `/lib/firmware/mali_csffw.bin`
- **注意**: 搜索延迟不会改善（模型兼容性问题）

**Docker 镜像**:
```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-armnn
```

**性能优化**:
```bash
MACHINE_LEARNING_ANN_FP16_TURBO=true  # 显著提升性能，略微降低精度
```

#### 5. 瑞芯微 NPU (RKNN)

**要求**:
- **SoC**: RK3566、RK3568、RK3576、RK3588
- **驱动**: RKNPU 驱动 V0.9.8 或更高
  - 验证：`cat /sys/kernel/debug/rknpu/version`
- **优势**: 
  - 比 ARM NN 支持更多模型（包括搜索加速）
  - 发热更低
  - 与转码共享 GPU 时性能更好（使用独立 NPU）

**Docker 镜像**:
```yaml
image: ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION:-release}-rknn
```

**性能优化**:
```bash
MACHINE_LEARNING_RKNN_THREADS=2  # RK3576/RK3588 推荐 2-3
# 注意：增加线程会成倍增加内存使用
```

### 多 GPU 配置

如果有多个 NVIDIA 或 Intel GPU，可以配置多 GPU 并行：

```bash
MACHINE_LEARNING_DEVICE_IDS=0,1  # 使用 GPU 0 和 1
MACHINE_LEARNING_WORKERS=2       # 启动 2 个工作进程
```

**注意事项**:
- 每个 GPU 必须能加载所有模型
- 无法将单个模型分配到多个 GPU
- 需要增加任务并发数以提高利用率

### 配置建议

#### 小型家庭服务器（< 1000 张照片）
```
CPU: 2-4 核心
RAM: 6-8GB
存储: 50-100GB
ML 配置: CPU 模式即可
```

#### 中型服务器（1000-10000 张照片）
```
CPU: 4-6 核心
RAM: 8-16GB
存储: 200-500GB
ML 配置: 推荐 GPU 加速（如有）
```

#### 大型服务器（> 10000 张照片）
```
CPU: 8+ 核心
RAM: 16-32GB
存储: 1TB+
ML 配置: 强烈推荐 GPU 加速
GPU VRAM: 6-8GB+
```

### 性能对比

| 硬件配置 | CLIP 编码速度 | 人脸检测速度 | 相对性能 |
|---------|-------------|------------|---------|
| CPU (4核) | ~2-3 张/秒 | ~1-2 张/秒 | 1x (基准) |
| NVIDIA RTX 3060 | ~15-20 张/秒 | ~10-15 张/秒 | 5-8x |
| NVIDIA RTX 4090 | ~40-50 张/秒 | ~30-40 张/秒 | 15-20x |
| Intel Arc A770 | ~10-15 张/秒 | ~8-12 张/秒 | 4-6x |
| RK3588 (RKNN) | ~8-12 张/秒 | ~6-10 张/秒 | 3-5x |

*注：实际性能取决于模型大小、图像分辨率和系统配置*

### 资源消耗监控

**查看 GPU 使用率**:
```bash
# NVIDIA
nvidia-smi
nvtop

# Intel
intel_gpu_top

# AMD
radeontop
```

**查看容器资源使用**:
```bash
docker stats immich_machine_learning
```

**检查模型加载日志**:
```bash
docker logs immich_machine_learning | grep "Available ORT providers"
# 或
docker logs immich_machine_learning | grep "Loaded ANN model"
```

## 架构设计

### 1. 服务架构

```
┌─────────────────────────────────────────┐
│         FastAPI Web 服务                 │
│  (main.py - 提供 REST API 接口)          │
└──────────────┬──────────────────────────┘
               │
               ├─ /predict (POST) - 主要推理接口
               ├─ /ping (GET) - 健康检查
               └─ / (GET) - 服务信息
               │
┌──────────────┴──────────────────────────┐
│         模型缓存层 (ModelCache)          │
│  - 内存缓存已加载的模型                   │
│  - TTL 自动卸载机制                      │
│  - 并发访问控制                          │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│         推理模型层                        │
│  ├─ CLIP (textual + visual)             │
│  ├─ 人脸识别 (detection + recognition)   │
│  └─ OCR (detection + recognition)        │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│         会话层 (Session)                 │
│  ├─ ONNX Runtime (默认)                  │
│  ├─ ARM NN (ARM 优化)                    │
│  └─ RKNN (瑞芯微 NPU)                    │
└─────────────────────────────────────────┘
```

### 2. 核心组件

#### 2.1 主服务 (main.py)

FastAPI 应用程序，提供以下功能：

- **请求处理**: 接收图像或文本输入，执行 AI 推理
- **线程池管理**: 使用 ThreadPoolExecutor 处理阻塞的推理操作
- **生命周期管理**: 
  - 启动时预加载指定模型
  - 空闲超时自动关闭（可配置）
  - 优雅关闭和资源清理

关键端点：
```python
POST /predict
- 参数: entries (JSON), image (文件) 或 text (字符串)
- 返回: 推理结果（embeddings、人脸信息等）
```

#### 2.2 模型缓存 (cache.py)

使用 `aiocache` 实现的智能缓存系统：

- **按需加载**: 首次请求时才加载模型到内存
- **TTL 机制**: 模型在指定时间（默认 300 秒）无活动后自动卸载
- **重新验证**: 访问时重置 TTL，保持活跃模型在内存中
- **乐观锁**: 防止并发加载同一模型

#### 2.3 模型基类 (base.py)

所有 AI 模型的抽象基类，提供：

- **统一接口**: `load()`, `predict()`, `download()`
- **多格式支持**: ONNX、ARM NN、RKNN
- **自动下载**: 从 Hugging Face 下载模型文件
- **缓存管理**: 本地模型文件缓存
- **错误恢复**: 加载失败时清除缓存并重试

### 3. 支持的 AI 任务

#### 3.1 CLIP 图像搜索

**工作流程**:
1. **文本编码器** (textual.py): 将搜索文本转换为向量
2. **视觉编码器** (visual.py): 将图像转换为向量
3. **相似度匹配**: 通过向量相似度实现语义搜索

**模型来源**: OpenCLIP, mCLIP (多语言支持)

#### 3.2 人脸识别

**两阶段流程**:
1. **人脸检测** (detection.py): 
   - 检测图像中的人脸位置
   - 返回边界框和关键点
   - 置信度过滤（默认 > 0.7）

2. **人脸识别** (recognition.py):
   - 提取人脸特征向量（embeddings）
   - 用于人脸比对和聚类

**模型来源**: InsightFace (antelopev2, buffalo 系列)

#### 3.3 OCR 文字识别

**两阶段流程**:
1. **文本检测**: 定位图像中的文本区域
2. **文本识别**: 识别文本内容

**模型来源**: PaddleOCR

## 配置系统

### 环境变量配置 (config.py)

```bash
# 缓存目录
MACHINE_LEARNING_CACHE_FOLDER=~/.cache/immich_ml

# 模型 TTL（秒）
MACHINE_LEARNING_MODEL_TTL=300

# 工作进程数
MACHINE_LEARNING_WORKERS=1

# 请求线程数
MACHINE_LEARNING_REQUEST_THREADS=4

# 预加载模型
MACHINE_LEARNING_PRELOAD__CLIP__TEXTUAL=ViT-B-32__openai
MACHINE_LEARNING_PRELOAD__CLIP__VISUAL=ViT-B-32__openai
MACHINE_LEARNING_PRELOAD__FACIAL_RECOGNITION__DETECTION=buffalo_l
MACHINE_LEARNING_PRELOAD__FACIAL_RECOGNITION__RECOGNITION=buffalo_l

# 硬件加速
MACHINE_LEARNING_ANN=true              # ARM NN 支持
MACHINE_LEARNING_RKNN=true             # 瑞芯微 NPU 支持
MACHINE_LEARNING_DEVICE_ID=0           # GPU 设备 ID
```

### 模型格式优先级

系统自动选择最优的模型格式：
1. **RKNN** - 瑞芯微 NPU（如果可用）
2. **ARM NN** - ARM 设备优化（如果启用）
3. **ONNX** - 通用格式（默认）

## 推理流程

### 完整请求流程

```
1. 客户端发送请求
   ↓
2. 解析 entries (模型配置)
   ↓
3. 解码输入 (图像/文本)
   ↓
4. 从缓存获取模型
   │  ├─ 缓存命中 → 直接使用
   │  └─ 缓存未命中 → 下载并加载
   ↓
5. 执行推理 (在线程池中)
   │  ├─ 无依赖模型并行执行
   │  └─ 有依赖模型顺序执行
   ↓
6. 返回结果 (JSON)
```

### 依赖处理

某些模型依赖其他模型的输出：
- **人脸识别**依赖**人脸检测**的结果
- **OCR 识别**依赖**文本检测**的结果

系统自动处理依赖关系，确保正确的执行顺序。

## 性能优化

### 1. 并发处理
- **线程池**: 避免 asyncio 的性能瓶颈
- **并行推理**: 无依赖的模型同时执行
- **请求跟踪**: 监控活跃请求数

### 2. 内存管理
- **模型卸载**: TTL 机制释放不活跃模型
- **垃圾回收**: 显式调用 gc.collect()
- **流式处理**: 大文件分块处理（64 MiB 阈值）

### 3. 空闲关闭
当满足以下条件时自动关闭服务：
- 超过 TTL 时间无请求
- 无活跃请求
- 无锁定资源

## 数据模型

### 请求格式 (PipelineRequest)

```json
{
  "clip": {
    "textual": {
      "modelName": "ViT-B-32__openai",
      "options": {}
    },
    "visual": {
      "modelName": "ViT-B-32__openai",
      "options": {}
    }
  },
  "facial-recognition": {
    "detection": {
      "modelName": "buffalo_l",
      "options": {"minScore": 0.7}
    },
    "recognition": {
      "modelName": "buffalo_l",
      "options": {}
    }
  }
}
```

### 响应格式 (InferenceResponse)

```json
{
  "clip": "base64_encoded_embedding",
  "facial-recognition": [
    {
      "boundingBox": {"x1": 100, "y1": 100, "x2": 200, "y2": 200},
      "embedding": "base64_encoded_embedding",
      "score": 0.95
    }
  ],
  "imageHeight": 1080,
  "imageWidth": 1920
}
```

## 部署方式

### Docker 容器
- 基于 Python 镜像
- 使用 Gunicorn + Uvicorn 运行
- 支持 CPU、CUDA、ROCm、OpenVINO

### 硬件加速
- **CUDA**: NVIDIA GPU (计算能力 ≥ 5.2)
- **ROCm**: AMD GPU
- **OpenVINO**: Intel 硬件
- **ARM NN**: ARM 设备优化
- **RKNN**: 瑞芯微 NPU

## 监控和调试

### 日志级别
```bash
IMMICH_LOG_LEVEL=info  # critical, error, warning, info, debug
```

### 性能测试
使用 Locust 进行负载测试：
```bash
locust --web-host 127.0.0.1
# 访问 localhost:8089
```

### 健康检查
```bash
curl http://localhost:3003/ping
# 返回: pong
```

## 技术栈

- **Web 框架**: FastAPI + Uvicorn
- **AI 推理**: ONNX Runtime, ARM NN, RKNN
- **图像处理**: Pillow, NumPy
- **模型管理**: Hugging Face Hub
- **缓存**: aiocache
- **并发**: ThreadPoolExecutor, asyncio
- **配置**: Pydantic Settings

## 用户控制选项

### 是否可以禁用？

**是的，用户可以完全控制 machine-learning 功能的启用和禁用。**

### 1. 全局开关

在管理界面的 "系统设置 > Machine Learning" 中，有一个主开关：

```typescript
machineLearning.enabled = true  // 默认启用
```

- **默认状态**: 启用（除非设置环境变量 `IMMICH_MACHINE_LEARNING_ENABLED=false`）
- **影响范围**: 关闭后，所有 AI 功能都将停止工作

### 2. 功能级别开关

即使 ML 服务启用，用户也可以单独控制每个 AI 功能：

#### 智能搜索 (CLIP)
```typescript
machineLearning.clip.enabled = true  // 默认启用
```
- 控制语义化图像搜索功能
- 关闭后无法使用自然语言搜索照片

#### 人脸识别
```typescript
machineLearning.facialRecognition.enabled = true  // 默认启用
```
- 控制人脸检测和识别功能
- 关闭后无法自动识别和分组人脸

#### OCR 文字识别
```typescript
machineLearning.ocr.enabled = true  // 默认启用
```
- 控制图像中的文字提取功能
- 关闭后无法搜索照片中的文字内容

#### 重复检测
```typescript
machineLearning.duplicateDetection.enabled = true  // 默认启用
```
- 控制重复照片检测功能
- 依赖 CLIP 功能，需要先启用智能搜索

### 3. 部署级别控制

#### Docker Compose 配置

用户可以选择：

**完全不部署 ML 服务**:
```yaml
# 在 docker-compose.yml 中注释掉或删除
# immich-machine-learning:
#   container_name: immich_machine_learning
#   ...
```

**通过环境变量禁用**:
```bash
# .env 文件
IMMICH_MACHINE_LEARNING_ENABLED=false
```

**自定义 ML 服务地址**:
```bash
# 可以指向自己部署的 ML 服务
IMMICH_MACHINE_LEARNING_URL=http://my-ml-server:3003
```

### 4. 管理界面配置路径

用户可以在以下位置管理 ML 设置：

1. **管理面板** → **系统设置** → **Machine Learning**
2. 可配置项：
   - 启用/禁用 ML 服务
   - ML 服务 URL（支持多个）
   - 健康检查设置
   - 各个 AI 功能的开关
   - 模型选择和参数调整

### 5. 代码层面的检查

系统在执行 AI 任务前会检查配置：

```typescript
// 检查 ML 是否启用
if (!isMachineLearningEnabled(machineLearning)) {
  return JobStatus.Skipped;
}

// 检查智能搜索是否启用
if (!isSmartSearchEnabled(machineLearning)) {
  throw new BadRequestException('Smart search is not enabled');
}

// 检查人脸识别是否启用
if (!isFacialRecognitionEnabled(machineLearning)) {
  return JobStatus.Skipped;
}
```

### 6. 性能考虑

关闭 ML 功能的好处：
- **节省资源**: ML 服务占用较多内存和 CPU
- **减少存储**: 不需要下载和缓存 AI 模型（可达数 GB）
- **加快启动**: 无需等待模型加载
- **降低成本**: 在资源受限的环境中运行

### 7. 默认配置总结

```typescript
machineLearning: {
  enabled: true,                          // 主开关：默认启用
  clip: { enabled: true },                // 智能搜索：默认启用
  facialRecognition: { enabled: true },   // 人脸识别：默认启用
  ocr: { enabled: true },                 // OCR：默认启用
  duplicateDetection: { enabled: true },  // 重复检测：默认启用
}
```

## 总结

Immich 的 machine-learning 模块是一个高性能、可扩展的 AI 推理服务，通过智能缓存、并发处理和多格式支持，为照片管理提供强大的 AI 能力。

**重要特性**:
- ✅ 用户可以完全控制是否启用 ML 功能
- ✅ 支持全局和功能级别的细粒度控制
- ✅ 默认启用，但可以轻松禁用
- ✅ 可以选择不部署 ML 服务容器以节省资源
- ✅ 模块化设计使得添加新的 AI 功能变得简单
