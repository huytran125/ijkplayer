#!/bin/bash

echo "🔧 Quick fix: Manually copying IJKMediaFrameworkWithSSL to app bundle..."

# Build the project first
cd ios/IJKMediaDemo
xcodebuild build -project IJKMediaDemo.xcodeproj -target IJKMediaDemo -configuration Debug

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Create Frameworks directory in app bundle
APP_PATH="build/Debug-iphoneos/IJKMediaDemo.app"
FRAMEWORKS_PATH="$APP_PATH/Frameworks"

echo "📁 Creating Frameworks directory..."
mkdir -p "$FRAMEWORKS_PATH"

# Copy the framework
FRAMEWORK_SOURCE="../IJKMediaPlayer/build/Debug-iphoneos/IJKMediaFrameworkWithSSL.framework"

if [ -d "$FRAMEWORK_SOURCE" ]; then
    echo "📦 Copying IJKMediaFrameworkWithSSL.framework..."
    cp -R "$FRAMEWORK_SOURCE" "$FRAMEWORKS_PATH/"
    
    # Code sign the framework
    echo "🔐 Code signing framework..."
    codesign --force --sign - "$FRAMEWORKS_PATH/IJKMediaFrameworkWithSSL.framework"
    
    echo "✅ Framework copied and signed successfully!"
    echo "📱 You can now test the app on device"
    
    # Verify the framework is there
    ls -la "$FRAMEWORKS_PATH/"
else
    echo "❌ Framework not found at: $FRAMEWORK_SOURCE"
    echo "💡 Make sure to build IJKMediaFrameworkWithSSL first:"
    echo "   cd ../IJKMediaPlayer"
    echo "   xcodebuild -project IJKMediaPlayer.xcodeproj -target IJKMediaFrameworkWithSSL -configuration Debug -sdk iphoneos build"
fi 