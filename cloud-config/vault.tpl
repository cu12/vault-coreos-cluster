#cloud-config
coreos:
  update:
    reboot-strategy: off
    group: stable

  units:
    - name: docker.service
      command: start
    - name: consul.service
      command: start
      content: |
        [Unit]
        Description=Consul Service
        Requires=docker.service
        After=docker.service

        [Service]
        ExecStartPre=-/usr/bin/docker rm -f %p
        ExecStartPre=/usr/bin/docker pull consul:${consul_version}
        ExecStart=/usr/bin/docker run \
          --rm \
          --name %p \
          --net=host \
          consul:${consul_version} agent \
          -server \
          -node=${fqdn} \
          -bind=$private_ipv4 \
          ${bootstrap} \
          -bootstrap-expect=${bootstrap_expect} \
          -rejoin
        Restart=always
        RestartSec=5

        [X-Fleet]
        Conflicts=%p@*.service
    - name: vault.service
      command: start
      content: |
        [Unit]
        Description=Vault Service
        Requires=docker.service
        After=docker.service
        Requires=consul.service
        After=consul.service

        [Service]
        ExecStartPre=-/usr/bin/docker rm -f %p
        ExecStartPre=/usr/bin/docker pull vault:${vault_version}
        ExecStart=/usr/bin/docker run \
          --rm \
          --name %p \
          --net=host \
          --cap-add IPC_LOCK \
          -v /vault/config/:/vault/config/ \
          -e VAULT_REDIRECT_ADDR=https://${vault_address}:443 \
          -e VAULT_ADDR=http://127.0.0.1:8200 \
          vault:${vault_version} server
        Restart=always
        RestartSec=5

        [X-Fleet]
        Conflicts=%p@*.service

write_files:
  - path: "/vault/config/vault.hcl"
    encoding: b64
    content: |
      ${vault_config}
  - path: "/opt/bin/vault"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      docker exec \
      --interactive \
      --tty \
      vault \
      vault "$@"
  - path: "/opt/bin/consul"
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -eo pipefail

      docker exec \
      --interactive \
      --tty \
      consul \
      consul "$@"
