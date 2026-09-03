# Project Zomboid dedicated server, installed via SteamCMD.
# https://pzwiki.net/wiki/Dedicated_server
FROM debian:bookworm-slim

ARG PZUID=1000
ENV DEBIAN_FRONTEND=noninteractive \
    STEAMCMD_DIR=/opt/steamcmd \
    PZSERVER_DIR=/opt/pzserver

# SteamCMD itself is a 32-bit binary, hence the i386 arch + lib32 packages
# even though the Project Zomboid dedicated server is 64-bit only.
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      lib32gcc-s1 \
      lib32stdc++6 \
      tini && \
    rm -rf /var/lib/apt/lists/*

# The server's JVM resolves its data dir (~/Zomboid) from the OS passwd
# entry (getpwuid), not the $HOME env var -- so the container user's home
# directory must BE the volume mount point for save/config data to persist.
RUN useradd --uid "${PZUID}" --shell /bin/bash --home-dir /data --no-create-home pzuser && \
    mkdir -p "$STEAMCMD_DIR" "$PZSERVER_DIR" /data && \
    chown -R pzuser:pzuser "$STEAMCMD_DIR" "$PZSERVER_DIR" /data

COPY --chown=pzuser:pzuser --chmod=755 entrypoint.sh /opt/entrypoint.sh

USER pzuser
WORKDIR /opt/pzserver

RUN curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
      | tar -xz -C "$STEAMCMD_DIR"

# Bake the server files into the image so the container can run standalone;
# entrypoint.sh re-runs this at container start (UPDATE_ON_START=true) to
# pick up game patches without rebuilding the image.
RUN "$STEAMCMD_DIR/steamcmd.sh" \
      +force_install_dir "$PZSERVER_DIR" \
      +login anonymous \
      +app_update 380870 validate \
      +quit

# Save/config data -- mount a volume here to persist across container
# restarts and image updates. This is also the container user's $HOME.
VOLUME ["/data"]

# 16261/udp: direct-connect game port (DefaultPort)
# 16262/udp: Steam query port (DefaultPort+1)
# 27015/tcp: RCON
EXPOSE 16261/udp 16262/udp 27015/tcp

ENTRYPOINT ["tini", "--", "/opt/entrypoint.sh"]
