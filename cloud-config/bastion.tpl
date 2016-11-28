#cloud-config
coreos:
  update:
    reboot-strategy: reboot
    group: stable

write_files:
  - path: "/opt/bin/vault-ssh"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      ssh \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        -o LogLevel=quiet \
        -t "$@"
  - path: "/opt/bin/vault-init"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      /opt/bin/vault-ssh ${prefix}-vault01.${domain} \
        '/opt/bin/vault init -address=http://127.0.0.1:8200'
  - path: "/opt/bin/vault-unseal"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      for VAULT in ${prefix}-vault{01..${size}}.${domain}; do
        /opt/bin/vault-ssh $VAULT \
          '/opt/bin/vault unseal -address=http://127.0.0.1:8200'
      done
  - path: "/opt/bin/vault-seal"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      for VAULT in ${prefix}-vault{01..${size}}.${domain}; do
        echo "Sealing Vault on $VAULT"
        /opt/bin/vault-ssh $VAULT \
          'sudo systemctl restart vault.service'
      done
      echo "Vault has been sealed!"
  - path: "/opt/bin/consul-cleanup"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      for VAULT in ${prefix}-vault{01..${size}}.${domain}; do
        /opt/bin/vault-ssh $VAULT \
          'for FAILED in $(/opt/bin/consul operator raft -list-peers | grep "(unknown)" | awk '\''{print $3}'\''); do
            /opt/bin/consul operator raft -remove-peer -address="$FAILED"
          done'
      done
  - path: "/opt/bin/consul-healthcheck"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      for VAULT in ${prefix}-vault{01..${size}}.${domain}; do
        echo "Consul Status on: $VAULT"
        echo "------------------------------------------"
        /opt/bin/vault-ssh $VAULT \
          '/opt/bin/consul operator raft -list-peers'
      done
  - path: "/opt/bin/vault-healthcheck"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      for VAULT in ${prefix}-vault{01..${size}}.${domain}; do
        echo "Vault Status on: $VAULT"
        echo "------------------------------------------"
        /opt/bin/vault-ssh $VAULT \
          '/opt/bin/vault status -address=http://127.0.0.1:8200'
      done
