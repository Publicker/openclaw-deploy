FROM ghcr.io/openclaw/openclaw:latest

USER root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends gosu sudo curl git openssh-server iptables && \
    curl -fsSL https://tailscale.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/* && \
    echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node && \
    mkdir -p /run/sshd

EXPOSE 18789

ENTRYPOINT ["entrypoint.sh"]
