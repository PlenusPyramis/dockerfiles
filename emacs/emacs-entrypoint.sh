#!/bin/bash
set -e

if [ ! -d "$HOME/.emacs.d" ]; then
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
    git clone https://github.com/EnigmaCurry/emacs ~/git/vendor/enigmacurry/emacs
    ln -s ~/git/vendor/enigmacurry/emacs/spacemacs.el $HOME/.spacemacs
    cd ~/.emacs.d
    git checkout develop
fi

mkdir -p /root/tmp
exec "$@"
