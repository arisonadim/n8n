.PHONY: help init up down restart logs logs-n8n logs-nginx logs-acme status backup restore security-check

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

.DEFAULT_GOAL := help

help: ## Show all commands
	@echo "$(BLUE)n8n Docker Setup - Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Start/Stop:$(NC)"
	@echo "  make init           Initialize and generate encryption key"
	@echo "  make up             Start all containers"
	@echo "  make down           Stop all containers"
	@echo "  make restart        Restart all containers"
	@echo ""
	@echo "$(GREEN)Logs:$(NC)"
	@echo "  make logs           View all container logs"
	@echo "  make logs-n8n       View n8n logs only"
	@echo "  make logs-nginx     View nginx logs"
	@echo "  make logs-acme      View Let's Encrypt logs"
	@echo ""
	@echo "$(GREEN)Backup:$(NC)"
	@echo "  make backup         Backup n8n data"
	@echo "  make restore        Restore from backup"
	@echo ""
	@echo "$(GREEN)Other:$(NC)"
	@echo "  make status         Show container status"
	@echo "  make security-check Verify security configuration"
	@echo ""

init: ## Initialize .env and generate encryption key
	@if [ -f .env ]; then \
		echo "$(YELLOW)⚠ .env already exists$(NC)"; \
	else \
		cp .env.example .env; \
		echo "$(GREEN)Created .env$(NC)"; \
	fi
	@KEY=$$(openssl rand -hex 32); \
	if grep -q "N8N_ENCRYPTION_KEY=changeme" .env 2>/dev/null; then \
		sed -i '' "s/N8N_ENCRYPTION_KEY=changeme.*/N8N_ENCRYPTION_KEY=$$KEY/" .env; \
		echo "$(GREEN)Generated N8N_ENCRYPTION_KEY$(NC)"; \
	fi
	@echo "$(YELLOW)Edit .env with your domain and password:$(NC)"
	@echo "  nano .env"

up: ## Start all containers
	@docker-compose up -d
	@echo "$(GREEN)✓ Containers started (waiting 30s for services)$(NC)"
	@sleep 30
	@docker-compose ps

down: ## Stop all containers
	@docker-compose down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

restart: ## Restart all containers
	@docker-compose restart
	@echo "$(GREEN)✓ Containers restarted$(NC)"

logs: ## View all container logs
	docker-compose logs -f

logs-n8n: ## View n8n logs
	docker-compose logs -f n8n

logs-nginx: ## View nginx logs
	docker-compose logs -f nginx-proxy

logs-acme: ## View Let's Encrypt logs
	docker-compose logs -f acme-companion

status: ## Show container status
	@echo "$(BLUE)Container Status:$(NC)"
	@docker-compose ps
	@echo ""
	@DOMAIN=$$(grep VIRTUAL_HOST .env 2>/dev/null | cut -d= -f2); \
	echo "$(BLUE)Access at: https://$$DOMAIN$(NC)"

backup: ## Backup n8n data
	@BACKUP_DIR="backups/$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	docker run --rm \
		-v n8n_data:/data:ro \
		-v "$$(pwd)/$$BACKUP_DIR:/backup" \
		alpine:latest \
		tar czf /backup/n8n_data.tar.gz -C / data; \
	echo "$(GREEN)✓ Backup: $$BACKUP_DIR/n8n_data.tar.gz$(NC)"

restore: ## Restore from backup
	@read -p "Enter backup directory (e.g., backups/20240101_120000): " BACKUP_DIR; \
	if [ ! -d "$$BACKUP_DIR" ]; then \
		echo "$(RED)Directory not found$(NC)"; exit 1; \
	fi; \
	docker run --rm \
		-v n8n_data:/data \
		-v "$$(pwd)/$$BACKUP_DIR:/backup" \
		alpine:latest \
		tar xzf /backup/n8n_data.tar.gz -C /; \
	echo "$(GREEN)✓ Restored from: $$BACKUP_DIR$(NC)"

security-check: ## Verify security configuration
	@echo "$(BLUE)Security Check:$(NC)"
	@echo ""
	@echo "$(YELLOW)Basic Auth:$(NC)"
	@grep "N8N_BASIC_AUTH" .env 2>/dev/null || echo "Not configured"
	@echo ""
	@echo "$(YELLOW)Encryption Key:$(NC)"
	@if grep -q "N8N_ENCRYPTION_KEY=changeme" .env 2>/dev/null; then \
		echo "$(RED)✗ Using default key (not secure)$(NC)"; \
	else \
		echo "$(GREEN)✓ Custom encryption key set$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Firewall (UFW):$(NC)"
	@sudo ufw status 2>/dev/null | grep -E "Status|22|80|443" || echo "Not available (run with sudo)"
