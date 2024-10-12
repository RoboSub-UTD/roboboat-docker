#!/usr/bin/bash

# Install necessary packages for NeoVIM and nala
echo "Installing nala, and dependencies for NeoVIM"
add-apt-repository ppa:neovim-ppa/unstable -y &> /dev/null
apt-get -qq -y --no-install-recommends install \
    nala libtree-sitter-dev ripgrep python3-venv npm neovim
apt-get clean; rm -rf /var/lib/apt/lists/*

# Install Starship prompt
echo "----------------"
echo "Installing starship prompt"
curl -sS https://starship.rs/install.sh | sh -s -- -y &> /dev/null

# Set some aliases in ~/.bashrc
echo "alias apt='nala'" >> /root/.bash_aliases
echo 'eval "$(starship init bash)"' >> /root/.bashrc

echo "----------------"
echo "Setup complete! Run 'source ~/.bashrc' to see the new changes"

