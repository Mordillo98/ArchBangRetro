#!/bin/bash

# Check if the line exists, if not append it with surrounding newlines
if ! grep -q 'export PYTHONHOME=/usr' /etc/makepkg.conf; then
    sudo sh -c "printf '\nexport PYTHONHOME=/usr\n\n' >> /etc/makepkg.conf"
fi
