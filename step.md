千萬不能用 root 執行：PetaLinux 極度排斥 root 權限，用 root 安裝或編譯會直接報錯。因此，Docker 容器內必須建立一個「普通使用者」。

硬碟空間要掛載 (Volume)：PetaLinux 的編譯過程會產生高達 100GB~200GB 的檔案。千萬不能把檔案存在 Container 內部，必須將 Host (您的 20.04) 的資料夾掛載進去。

Locale 和 Shell 設定：容器必須設定為 en_US.UTF-8 編碼，且預設 Shell 必須是 bash (不能是 dash)。

## 目錄
mkdir -p ~/petalinux_docker/workspace
並把bsp和petalinux丟進去
cd ~/petalinux_docker

## Dockerfile
'''
# 使用 Ubuntu 22.04 為基底
FROM ubuntu:22.04

# 設定非互動模式，避免安裝時卡在時區選擇
ENV DEBIAN_FRONTEND=noninteractive

# 安裝 PetaLinux 所需的所有依賴
RUN apt-get update && apt-get install -y \
    lsb-release \
    iproute2 gawk python3 build-essential gcc git make net-tools \
    libncurses5-dev tftpd zlib1g-dev libssl-dev flex bison libselinux1 gnupg wget \
    git-core diffstat chrpath socat xterm autoconf libtool tar unzip texinfo zlib1g-dev \
    gcc-multilib automake screen pax gzip cpio python3-pip python3-pexpect xz-utils \
    debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
    libtinfo5 rsync openssh-server openssh-client bc dnsutils \
    sudo locales vim && \
    apt-get clean

# 設定系統語系為 UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# 將預設 shell 改為 bash
RUN ln -sf /bin/bash /bin/sh

# 建立一個與 Host 相同 UID/GID 的使用者 (避免檔案權限問題)
# 這裡預設用 pluser，密碼也是 pluser
ARG USERNAME=pluser
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && adduser $USERNAME sudo

# 切換到一般使用者
USER $USERNAME
WORKDIR /home/$USERNAME/workspace

# 啟動時預設開啟 bash
CMD ["/bin/bash"]
'''

## Docker image
docker build -t petalinux:22.04 .

docker run -it --name pnx_env \
  -v ~/petalinux_docker/workspace:/home/pluser/workspace \
  petalinux:22.04

## 進入容器
docker ps -a
docker start pnx_env

docker exec -it pnx_env bash

source /home/pluser/petalinux/settings.sh

## 安裝petalinux
chmod +x petalinux-v2024.2-final-installer.run
./petalinux-v2024.2-final-installer.run --dir /home/pluser/petalinux

## build bsp
# 進入工作目錄
cd ~/workspace

# 建立專案 (請將 <bsp_file> 換成您的實際檔名，例如 ultra96v2_oob_2022_1.bsp)
petalinux-create -t project -s <bsp_file> -n my_test_bsp

# 進入專案資料夾
cd my_test_bsp

# 靜默配置 (使用預設值)
petalinux-config --silentconfig

## build
petalinux-build

## package
petalinux-package --boot --fsbl images/linux/zynqmp_fsbl.elf --u-boot images/linux/u-boot.elf --pmufw images/linux/pmufw.elf --fpga images/linux/system.bit --force