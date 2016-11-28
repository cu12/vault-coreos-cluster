#cloud-config
  coreos:
    etcd:
      discovery: ${discovery_url}
      addr: "$$private_ipv4:4001"
      peer-addr: "$$private_ipv4:7001"
    units:
      - name: etcd.service
        command: start
      - name: docker.service
        command: start
      - name: fleet.service
        command: start
      - name: vault.service
        command: start
        content: |
          [Unit]
          Description=Vault Service
          Requires=docker.service
          Requires=etcd.service
          After=docker.service
          After=etcd.service

          [Service]
          EnvironmentFile=/etc/environment
          ExecStartPre=-/usr/bin/docker rm -f %p
          ExecStartPre=/usr/bin/docker pull brandfolder/vault-coreos
          ExecStart=/usr/bin/docker run \
            --rm \
            --name %p \
            -e SERVICE_NAME=vault \
            -e ETCD_ADDRESS="http://$${COREOS_PRIVATE_IPV4}:2379" \
            -e ETCD_ADVERTISE_ADDR="http://$${COREOS_PRIVATE_IPV4}:8200" \
            -e VAULT_LISTEN="0.0.0.0:8200" \
            -e VAULT_TLS_DISABLE=1 \
            -p 8200:8200 \
            --cap-add IPC_LOCK \
            brandfolder/vault-coreos
          Restart=always
          RestartSec=5

          [X-Fleet]
          Conflicts=%p@*.service
