#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="`pwd`/flutter/bin:$PATH"

# Debug version
flutter --version

# Get dependencies
flutter pub get

# Build the web app with HTML renderer
flutter build web --release --web-renderer=html