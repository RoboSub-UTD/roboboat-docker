#!/usr/bin/bash

# Install necessary packages for NeoVIM and nala
echo "Installing nala, and dependencies for NeoVIM"
add-apt-repository ppa:neovim-ppa/unstable -y &>/dev/null
apt-get -y --no-install-recommends install \
    nala libtree-sitter-dev ripgrep python3-venv unzip npm neovim \
    &>/dev/null
apt-get clean
rm -rf /var/lib/apt/lists/*

# Install Starship prompt
echo "----------------"
echo "Installing starship prompt"
curl -sS https://starship.rs/install.sh | sh -s -- -y &>/dev/null

# Set some aliases in ~/.bashrc
echo "alias apt='nala'" >>${HOME}/.config/.aliases.sh
echo 'eval "$(starship init bash)"' >>${HOME}/.bashrc

echo "----------------"
echo "Setup complete! Run 'source ~/.bashrc' to see the new changes"
