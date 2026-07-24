#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Get dependencies
flutter pub get

# Build the web app with HTML renderer for best compatibility
flutter build web --release --web-renderer html