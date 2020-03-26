FROM docker.io/archlinux/base:latest

LABEL com.github.containers.toolbox="true" \
      com.github.debarshiray.toolbox="true" 

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        sudo git base-devel emacs-nox procps-ng tmux zsh \
        openssh mosh man wget htop neofetch \
        go go-tools \
        python python-pip python-virtualenv \
        nodejs yarn && \
    pacman -Scc --noconfirm && \
    touch /etc/machine-id && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/toolbox && \
    mkdir /media

CMD /bin/zsh
