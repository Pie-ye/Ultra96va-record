# 檔名: Dockerfile
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# 安裝依賴套件
RUN apt-get update && apt-get install -y \
    iproute2 gawk python3 build-essential gcc git make net-tools \
    libncurses5-dev tftpd zlib1g-dev libssl-dev flex bison libselinux1 gnupg wget \
    git-core diffstat chrpath socat xterm autoconf libtool tar unzip texinfo \
    gcc-multilib automake screen pax gzip cpio python3-pip python3-pexpect xz-utils \
    debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
    libtinfo5 rsync openssh-server openssh-client bc dnsutils \
    sudo locales vim lsb-release python-is-python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 修正 Shell 與語系
RUN ln -sf /bin/bash /bin/sh
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# 設定使用者 (稍後 Build 時會自動對應您的 UID)
ARG USERNAME=pluser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && adduser $USERNAME sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME
CMD ["/bin/bash"]