# Windows 下的 GNU Make 可能忽略 SHELL 并退回到 cmd.exe（导致 ! was unexpected）
# 通过 MAKESHELL + SHELL 同时指定 sh.exe，可强制使用 POSIX shell。
ifeq ($(OS),Windows_NT)
MAKESHELL := C:/Progra~1/Git/usr/bin/sh.exe
SHELL := C:/Progra~1/Git/usr/bin/sh.exe
.SHELLFLAGS := -lc
else
SHELL := bash
.SHELLFLAGS := -lc
endif

.PHONY: dev dev-backend dev-web build build-backend build-web start \
       typecheck typecheck-backend typecheck-web typecheck-agent-runner \
       format format-check install clean reset-init update-sdk sync-types help

# ─── Development ─────────────────────────────────────────────

dev: ## 启动前后端（Windows 兼容：不使用 bash 条件语法）
	@echo "启动开发环境（如首次运行请先执行 make install）"
	npm --prefix container/agent-runner run build
	npm run dev:all

dev-backend: ## 仅启动后端
	npm run dev

dev-web: ## 仅启动前端
	npm run dev:web

# ─── Build ───────────────────────────────────────────────────

build: sync-types ## 编译前后端及 agent-runner
	npm run build:all
	npm --prefix container/agent-runner run build

build-backend: ## 仅编译后端
	npm run build

build-web: ## 仅编译前端
	npm run build:web

# ─── Production ──────────────────────────────────────────────

start: ## 一键启动生产环境（Windows 兼容：不使用 bash 条件语法）
	@echo "启动生产环境（如首次运行请先执行 make install，并确保已构建容器镜像）"
	$(MAKE) build
	npm run start

# ─── Quality ─────────────────────────────────────────────────

typecheck: sync-types typecheck-backend typecheck-web typecheck-agent-runner ## 全量类型检查
	@./scripts/check-stream-event-sync.sh

typecheck-backend:
	npm run typecheck

typecheck-web:
	cd web && npx tsc --noEmit

typecheck-agent-runner:
	cd container/agent-runner && npx tsc --noEmit

format: ## 格式化代码
	npm run format

format-check: ## 检查代码格式
	npm run format:check

# ─── Shared Types ────────────────────────────────────────────

sync-types: ## 同步 shared/ 下的类型定义到各子项目
	@./scripts/sync-stream-event.sh

# ─── SDK ─────────────────────────────────────────────────────

update-sdk: ## 更新 agent-runner 的 Claude Agent SDK 到最新版本
	cd container/agent-runner && npm update @anthropic-ai/claude-agent-sdk && npm run build
	@echo "SDK updated. Run 'make typecheck' to verify."

# ─── Setup ───────────────────────────────────────────────────

install: ## 安装全部依赖并编译 agent-runner
	npm install
	npm --prefix container/agent-runner install
	npm --prefix container/agent-runner run build
	cd web && npm install

clean: ## 清理构建产物
	rm -rf dist
	rm -rf web/dist
	rm -rf container/agent-runner/dist

reset-init: ## 完全重置为首装状态（清空所有运行时数据）
	rm -rf data store groups
	@echo "✅ 已完全重置为首装状态（数据库、配置、工作区、记忆、会话全部清除）"

# ─── Help ────────────────────────────────────────────────────

help: ## 显示帮助
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
