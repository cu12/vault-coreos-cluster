SHELL += -eu

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

backup: ## Backup Consul to current directory
	@ssh -o ExitOnForwardFailure=yes -fL 8500:localhost:8500 core@$$(terraform output vault.private_ip) -o 'ProxyCommand = ssh core@$$(terraform output bastion.public_ip) -W $$(terraform output vault.private_ip):22' sleep 10
	@consul-backinator backup -scheme http || true

bastion: ## Connect to Bastion host
	@ssh -t core@$$(terraform output bastion.public_ip)

cleanup: ## Cleanup failed Consul peers
	@ssh -t core@$$(terraform output bastion.public_ip) /opt/bin/consul-cleanup || true

init: ## Initalize Vault
	@ssh -t core@$$(terraform output bastion.public_ip) /opt/bin/vault-init || true

healthcheck: ## Consul and Vault healthcheck
	@ssh -t core@$$(terraform output bastion.public_ip) /opt/bin/consul-healthcheck || true
	@ssh -t core@$$(terraform output bastion.public_ip) /opt/bin/vault-healthcheck || true

seal: ## Seal Vault
	@ssh -t core@$$(terraform output bastion.public_ip) /opt/bin/vault-seal || true

restore: ## Restore Consul from current directory
	@ssh -o ExitOnForwardFailure=yes -fL 8500:localhost:8500 core@$$(terraform output vault.private_ip) -o 'ProxyCommand = ssh core@$$(terraform output bastion.public_ip) -W $$(terraform output vault.private_ip):22' sleep 10
	@consul-backinator restore -scheme http || true

unseal: ## Unseal Vault
	@ssh -t core@$$(terraform output bastion.public_ip) /opt/bin/vault-unseal || true

%:
	@:
