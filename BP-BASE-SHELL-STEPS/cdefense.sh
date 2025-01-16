#!/bin/bash

# Install CloudDefense if not already installed
install_cdefense() {
  if ! command -v cdefense &> /dev/null; then
    echo "Installing CloudDefense from $CDEFENSE_INSTALL_URL"
    curl -sSL "$CDEFENSE_INSTALL_URL" -o /tmp/cd-latest-linux-x64.tar.gz
    tar -C /usr/local/bin -xzf /tmp/cd-latest-linux-x64.tar.gz
    chmod +x /usr/local/bin/cdefense
    echo "CloudDefense installed successfully."
  else
    echo "CloudDefense already installed."
  fi
}

