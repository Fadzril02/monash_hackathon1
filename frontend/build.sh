#!/bin/bash
set -e

echo "🚀 Starting Flutter web build for Vercel..."

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
  echo "📦 Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  export PATH="$PATH:`pwd`/flutter/bin"
fi

# Verify Flutter
echo "🔍 Verifying Flutter installation..."
flutter doctor -v

# Get dependencies
echo "📚 Installing dependencies..."
flutter pub get

# Build web
echo "🏗️ Building Flutter web..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build complete! Output: build/web"

