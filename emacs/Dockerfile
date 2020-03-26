FROM archlinux AS emacs

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm emacs-nox git base-devel cmake procps-ng libvterm libtool

WORKDIR /root
COPY emacs-entrypoint.sh /usr/local/bin/emacs-entrypoint.sh
ENTRYPOINT ["/bin/bash", "/usr/local/bin/emacs-entrypoint.sh"]
CMD ["emacs", "--fg-daemon"]
