# bash, not zsh: the bootstrap layer must work on stock Linux (devcontainers,
# CI runners, fresh VMs) where zsh is typically absent.
SHELL := /bin/bash

# Text colors
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
CYAN := \033[36m
GRAY := \033[90m
NC := \033[0m

CHECK := $(GREEN)✓$(NC)
CROSS := $(RED)✗$(NC)
DASH := $(GRAY)-$(NC)

.PHONY: all bootstrap check hook-check install-rust install-rust-force install-just install-just-force help

all: help

# Two-level setup (R42). This Makefile is Level 1 ONLY — the bootstrap that
# installs the base toolchain (rustup + just) using only what a bare machine
# already has. Everything after that is Level 2: `just setup` (dev tools,
# hooks, workspace verification). Do not add project tasks here; they belong
# in the Justfile.

bootstrap: ## Level 1 — install base toolchain (rustup + just) if missing, then verify
	@if command -v rustup >/dev/null 2>&1; then \
		echo -e "[$(CHECK)] rustup already installed"; \
	else \
		echo "Installing rustup (minimal profile; rust-toolchain.toml selects channel & components)..."; \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal; \
	fi
	@if command -v just >/dev/null 2>&1; then \
		echo -e "[$(CHECK)] just already installed"; \
	else \
		echo "Installing just to $(HOME)/.local/bin..."; \
		mkdir -p "$(HOME)/.local/bin"; \
		curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$(HOME)/.local/bin" \
		|| { \
			echo "just.systems installer failed — falling back to cargo install --locked just..."; \
			PATH="$(HOME)/.cargo/bin:$(HOME)/.local/bin:$$PATH" cargo install --locked just; \
		}; \
	fi
	@PATH="$(HOME)/.cargo/bin:$(HOME)/.local/bin:$$PATH" $(MAKE) --no-print-directory check
	@echo ""
	@echo -e "Bootstrap complete. Ensure $(HOME)/.cargo/bin and $(HOME)/.local/bin are on PATH."
	@echo -e "Next: $(BLUE)just setup$(NC)"

check: ## Check Level 1 base toolchain requirements
	@echo "Checking Level 1 base toolchain..."
	@echo "=== System Requirements Status ==="
	@ERROR_COUNT=0; MISSING_DEPS=""; \
	for pair in "rustup:install-rust" "cargo:install-rust" "just:install-just"; do \
		cmd="$${pair%%:*}"; \
		target="$${pair##*:}"; \
		if command -v "$$cmd" >/dev/null 2>&1; then \
			printf "[$(CHECK)] %s\n" "$$cmd"; \
		else \
			printf "[$(CROSS)] %s ($(GREEN)make %s$(NC))\n" "$$cmd" "$$target"; \
			ERROR_COUNT=$$((ERROR_COUNT + 1)); \
			MISSING_DEPS="$${MISSING_DEPS:+$${MISSING_DEPS}, }$$cmd"; \
		fi; \
	done; \
	if command -v blaze >/dev/null 2>&1; then \
		printf "[$(CHECK)] blaze (optional local accelerator)\n"; \
	else \
		printf "[$(DASH)] blaze (optional — accelerates default CLI/core loop; $(CYAN)just install-blaze$(NC))\n"; \
	fi; \
	if [ "$${ERROR_COUNT}" = "0" ]; then \
		echo -e "$(GREEN)All Level 1 dependencies are installed!$(NC)"; \
	else \
		echo ""; \
		echo -e "$(RED)Found $${ERROR_COUNT} missing deps: $${MISSING_DEPS}$(NC)"; \
		exit 1; \
	fi

hook-check: ## F186 — report-only readiness doctor for git-hook toolchain (R37, R39, R40)
	@echo "Checking git-hook toolchain..."
	@echo "=== Hook Toolchain Status ==="
	@PATH="$(HOME)/.local/bin:$(HOME)/.cargo/bin:$$PATH"; \
	LEFTHOOK_PIN="2.1.14"; \
	ISSUES=0; \
	if command -v lefthook >/dev/null 2>&1; then \
		LH_VER=$$(lefthook version 2>/dev/null || true); \
		if [ "$$LH_VER" = "$$LEFTHOOK_PIN" ]; then \
			printf "[$(CHECK)] lefthook (%s)\n" "$$LH_VER"; \
		else \
			printf "[$(CROSS)] lefthook version mismatch (got %s, want %s — $(CYAN)just install-tool ubi:evilmartians/lefthook@v%s$(NC))\n" "$$LH_VER" "$$LEFTHOOK_PIN" "$$LEFTHOOK_PIN"; \
			ISSUES=$$((ISSUES + 1)); \
		fi; \
		if lefthook check-install >/dev/null 2>&1; then \
			printf "[$(CHECK)] lefthook hooks installed\n"; \
		else \
			printf "[$(CROSS)] lefthook hooks not installed or stale ($(CYAN)just hooks-install$(NC))\n"; \
			ISSUES=$$((ISSUES + 1)); \
		fi; \
	else \
		printf "[$(CROSS)] lefthook ($(CYAN)just install-tool ubi:evilmartians/lefthook@v%s$(NC))\n" "$$LEFTHOOK_PIN"; \
		ISSUES=$$((ISSUES + 1)); \
	fi; \
	for TOOL in dprint ast-grep committed gitleaks editorconfig-checker ryl typos actionlint shellcheck; do \
		if command -v "$$TOOL" >/dev/null 2>&1; then \
			printf "[$(CHECK)] %s\n" "$$TOOL"; \
		else \
			printf "[$(CROSS)] %s ($(CYAN)just setup$(NC))\n" "$$TOOL"; \
			ISSUES=$$((ISSUES + 1)); \
		fi; \
	done; \
	if [ "$$ISSUES" = "0" ]; then \
		echo -e "$(GREEN)All git-hook tools are ready!$(NC)"; \
	else \
		echo ""; \
		echo -e "$(YELLOW)Found $${ISSUES} hook-toolchain issue(s). Run $(BLUE)just setup$(NC)$(YELLOW) or $(BLUE)just hooks-install$(NC)$(YELLOW) to remediate.$(NC)"; \
	fi

install-rust: ## Print rustup installation command
	@echo "rustup installation command (minimal profile; rust-toolchain.toml pins channel/components):"
	@echo -e "  $(CYAN)curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal$(NC)"
	@echo "or run:"
	@echo -e "  $(CYAN)make install-rust-force$(NC)"
	@echo "Docs: https://rustup.rs"

install-rust-force: ## Install rustup non-interactively (minimal profile)
	@echo "Installing rustup..."
	@curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
	@echo -e "Ensure $(HOME)/.cargo/bin is on PATH, then run $(BLUE)just setup$(NC)."

install-just: ## Print just installation command
	@echo "just installation command:"
	@echo -e "  $(CYAN)curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin$(NC)"
	@echo "or run:"
	@echo -e "  $(CYAN)make install-just-force$(NC)"
	@echo -e "Cargo fallback: $(CYAN)cargo install --locked just$(NC)"
	@echo "Docs: https://github.com/casey/just"

install-just-force: ## Install just to ~/.local/bin (cargo fallback if installer fails)
	@echo "Installing just to $(HOME)/.local/bin..."
	@mkdir -p "$(HOME)/.local/bin"
	@curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$(HOME)/.local/bin" \
	|| { \
		echo "just.systems installer failed — falling back to cargo install --locked just..."; \
		if PATH="$(HOME)/.cargo/bin:$$PATH" command -v cargo >/dev/null 2>&1; then \
			PATH="$(HOME)/.cargo/bin:$$PATH" cargo install --locked just; \
		else \
			echo -e "$(CROSS) cargo not found — run $(YELLOW)make install-rust-force$(NC) first."; \
			exit 1; \
		fi; \
	}
	@echo -e "Ensure $(HOME)/.local/bin is on PATH."

help: ## Show available Level 1 bootstrap targets
	@echo ""
	@echo "Purpose of this Makefile (Level 1 bootstrap):"
	@echo -e "  Check and install the base toolchain ($(GREEN)rustup$(NC) + $(GREEN)just$(NC))."
	@echo -e "  All project tasks live in $(CYAN)Justfile$(NC) — run $(BLUE)just$(NC) to list them."
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(CYAN)%-24s$(NC) %s\n", $$1, $$2}'
	@echo ""
