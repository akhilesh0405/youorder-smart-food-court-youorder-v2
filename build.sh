#!/bin/bash
# Install Flutter stable
git clone https://github.com/flutter/flutter.git -b stable
FLUTTER_BIN="`pwd`/flutter/bin/flutter"

# Enable web
$FLUTTER_BIN config --enable-web

# Get dependencies
$FLUTTER_BIN pub get

# Build the web app
$FLUTTER_BIN build web --release