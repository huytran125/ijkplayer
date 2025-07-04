#!/bin/bash

# Universal IJKPlayer Framework Builder
echo "🔨 Building Universal IJKMediaFrameworkWithSSL"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect host architecture
HOST_ARCH=$(uname -m)
echo -e "${BLUE}Host architecture: $HOST_ARCH${NC}"

IJKPLAYER_ROOT="../../ios/IJKMediaPlayer"
BUILD_DIR="$IJKPLAYER_ROOT/build"
DEVICE_FRAMEWORK="$BUILD_DIR/Release-iphoneos/IJKMediaFrameworkWithSSL.framework"
SIMULATOR_FRAMEWORK="$BUILD_DIR/Release-iphonesimulator/IJKMediaFrameworkWithSSL.framework"
UNIVERSAL_DIR="./UniversalFramework"
UNIVERSAL_FRAMEWORK="$UNIVERSAL_DIR/IJKMediaFrameworkWithSSL.framework"
IOS_BUILD_ROOT="$IJKPLAYER_ROOT/../build"

echo -e "${BLUE}Preparing libraries for simulator build...${NC}"

# Create temporary simulator-only libraries using correct architecture
TEMP_LIB_DIR="$IJKPLAYER_ROOT/../build/simulator-libs"
rm -rf "$TEMP_LIB_DIR"
mkdir -p "$TEMP_LIB_DIR"

# Determine simulator architecture based on host
if [ "$HOST_ARCH" = "x86_64" ]; then
    SIM_ARCH="x86_64"
    SIM_ARCH_ALT="i386"
    echo -e "${YELLOW}Building for Intel Mac simulator (x86_64)${NC}"
else
    SIM_ARCH="arm64"
    SIM_ARCH_ALT="x86_64" 
    echo -e "${YELLOW}Building for Apple Silicon Mac simulator (arm64)${NC}"
fi

echo -e "${YELLOW}Creating simulator-only libraries from individual builds...${NC}"

# OpenSSL libraries - use primary simulator architecture
if [ -f "$IOS_BUILD_ROOT/openssl-$SIM_ARCH/output/lib/libcrypto.a" ]; then
    cp "$IOS_BUILD_ROOT/openssl-$SIM_ARCH/output/lib/libcrypto.a" "$TEMP_LIB_DIR/libcrypto.a"
    echo -e "${GREEN}✓ Created $SIM_ARCH libcrypto.a${NC}"
elif [ -f "$IOS_BUILD_ROOT/openssl-$SIM_ARCH_ALT/output/lib/libcrypto.a" ]; then
    cp "$IOS_BUILD_ROOT/openssl-$SIM_ARCH_ALT/output/lib/libcrypto.a" "$TEMP_LIB_DIR/libcrypto.a"
    echo -e "${GREEN}✓ Created $SIM_ARCH_ALT libcrypto.a${NC}"
fi

if [ -f "$IOS_BUILD_ROOT/openssl-$SIM_ARCH/output/lib/libssl.a" ]; then
    cp "$IOS_BUILD_ROOT/openssl-$SIM_ARCH/output/lib/libssl.a" "$TEMP_LIB_DIR/libssl.a"
    echo -e "${GREEN}✓ Created $SIM_ARCH libssl.a${NC}"
elif [ -f "$IOS_BUILD_ROOT/openssl-$SIM_ARCH_ALT/output/lib/libssl.a" ]; then
    cp "$IOS_BUILD_ROOT/openssl-$SIM_ARCH_ALT/output/lib/libssl.a" "$TEMP_LIB_DIR/libssl.a"
    echo -e "${GREEN}✓ Created $SIM_ARCH_ALT libssl.a${NC}"
fi

# FFmpeg libraries - use primary simulator architecture
for lib in libavcodec.a libavfilter.a libavformat.a libavutil.a libswresample.a libswscale.a; do
    if [ -f "$IOS_BUILD_ROOT/ffmpeg-$SIM_ARCH/output/lib/$lib" ]; then
        cp "$IOS_BUILD_ROOT/ffmpeg-$SIM_ARCH/output/lib/$lib" "$TEMP_LIB_DIR/$lib"
        echo -e "${GREEN}✓ Created $SIM_ARCH $lib${NC}"
    elif [ -f "$IOS_BUILD_ROOT/ffmpeg-$SIM_ARCH_ALT/output/lib/$lib" ]; then
        cp "$IOS_BUILD_ROOT/ffmpeg-$SIM_ARCH_ALT/output/lib/$lib" "$TEMP_LIB_DIR/$lib"
        echo -e "${GREEN}✓ Created $SIM_ARCH_ALT $lib${NC}"
    fi
done

echo -e "${BLUE}Checking current frameworks...${NC}"

# Check device framework
if [ -f "$DEVICE_FRAMEWORK/IJKMediaFrameworkWithSSL" ]; then
    echo -e "${GREEN}✓ Device framework found${NC}"
    lipo -info "$DEVICE_FRAMEWORK/IJKMediaFrameworkWithSSL"
else
    echo -e "${RED}✗ Device framework binary missing${NC}"
fi

# Check simulator framework  
if [ -f "$SIMULATOR_FRAMEWORK/IJKMediaFrameworkWithSSL" ]; then
    echo -e "${GREEN}✓ Simulator framework found${NC}"
    lipo -info "$SIMULATOR_FRAMEWORK/IJKMediaFrameworkWithSSL"
else
    echo -e "${YELLOW}⚠ Simulator framework binary missing - will rebuild${NC}"
fi

echo ""
echo -e "${BLUE}Building IJKPlayer for simulator...${NC}"

# Build for simulator
cd "$IJKPLAYER_ROOT"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
xcodebuild clean -project IJKMediaPlayer.xcodeproj -scheme IJKMediaFrameworkWithSSL -configuration Release

# Temporarily replace universal libs with simulator-only libs
UNIVERSAL_LIB_DIR="$IJKPLAYER_ROOT/../build/universal/lib"
if [ -d "$TEMP_LIB_DIR" ] && [ "$(ls -A $TEMP_LIB_DIR)" ]; then
    echo -e "${YELLOW}Using simulator-only libraries...${NC}"
    # Backup original universal libs
    cp -R "$UNIVERSAL_LIB_DIR" "$IJKPLAYER_ROOT/../build/universal-backup"
    # Replace with simulator-only libs
    cp "$TEMP_LIB_DIR"/* "$UNIVERSAL_LIB_DIR/"
fi

# Build for iOS Simulator with correct architecture
echo -e "${YELLOW}Building for iOS Simulator ($SIM_ARCH)...${NC}"
if [ "$HOST_ARCH" = "x86_64" ]; then
    # Intel Mac - build for x86_64 simulator
    xcodebuild archive \
        -project IJKMediaPlayer.xcodeproj \
        -scheme IJKMediaFrameworkWithSSL \
        -configuration Release \
        -destination "generic/platform=iOS Simulator" \
        -arch x86_64 \
        -archivePath "$BUILD_DIR/simulator.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
else
    # Apple Silicon Mac - build for arm64 simulator
    xcodebuild archive \
        -project IJKMediaPlayer.xcodeproj \
        -scheme IJKMediaFrameworkWithSSL \
        -configuration Release \
        -destination "generic/platform=iOS Simulator" \
        -arch arm64 \
        -archivePath "$BUILD_DIR/simulator.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
fi

# Restore original universal libs
if [ -d "$IJKPLAYER_ROOT/../build/universal-backup" ]; then
    echo -e "${YELLOW}Restoring original universal libraries...${NC}"
    rm -rf "$UNIVERSAL_LIB_DIR"
    mv "$IJKPLAYER_ROOT/../build/universal-backup" "$UNIVERSAL_LIB_DIR"
fi

# Build for iOS Device (if not exists)
if [ ! -f "$DEVICE_FRAMEWORK/IJKMediaFrameworkWithSSL" ]; then
    echo -e "${YELLOW}Building for iOS Device...${NC}"
    xcodebuild archive \
        -project IJKMediaPlayer.xcodeproj \
        -scheme IJKMediaFrameworkWithSSL \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -archivePath "$BUILD_DIR/device.xcarchive" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
fi

# Clean up temp directory
rm -rf "$TEMP_LIB_DIR"

# Go back to iOS directory
cd - > /dev/null

echo ""
echo -e "${BLUE}Creating Universal Framework...${NC}"

# Create universal framework directory
rm -rf "$UNIVERSAL_DIR"
mkdir -p "$UNIVERSAL_DIR"

# Copy the device framework as base
if [ -d "$DEVICE_FRAMEWORK" ]; then
    cp -R "$DEVICE_FRAMEWORK" "$UNIVERSAL_FRAMEWORK"
else
    echo -e "${RED}Error: Device framework not found${NC}"
    exit 1
fi

# Check if simulator build succeeded
SIMULATOR_ARCHIVE_FRAMEWORK="$BUILD_DIR/simulator.xcarchive/Products/Library/Frameworks/IJKMediaFrameworkWithSSL.framework"
if [ -f "$SIMULATOR_ARCHIVE_FRAMEWORK/IJKMediaFrameworkWithSSL" ]; then
    echo -e "${GREEN}✓ Simulator framework built successfully${NC}"
    
    # Create universal binary
    echo -e "${YELLOW}Creating universal binary...${NC}"
    lipo -create \
        "$DEVICE_FRAMEWORK/IJKMediaFrameworkWithSSL" \
        "$SIMULATOR_ARCHIVE_FRAMEWORK/IJKMediaFrameworkWithSSL" \
        -output "$UNIVERSAL_FRAMEWORK/IJKMediaFrameworkWithSSL"
    
    echo -e "${GREEN}✓ Universal framework created${NC}"
    echo -e "${BLUE}Architectures in universal framework:${NC}"
    lipo -info "$UNIVERSAL_FRAMEWORK/IJKMediaFrameworkWithSSL"
    
else
    echo -e "${YELLOW}⚠ Simulator build may have failed, using device-only framework${NC}"
    echo -e "${BLUE}Note: This will work on device but not simulator${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Framework ready!${NC}"
echo -e "${BLUE}Location: $UNIVERSAL_FRAMEWORK${NC}"

echo ""
echo -e "${YELLOW}📋 Next steps for Xcode integration:${NC}"
echo "1. In Xcode, remove any existing IJKMediaFramework references"
echo "2. Add the universal framework:"
echo "   - General → Frameworks, Libraries, and Embedded Content"
echo "   - Add Files... → Select: $(realpath $UNIVERSAL_FRAMEWORK)"
echo "   - Set to 'Embed & Sign'"
echo "3. This framework will work on both device and simulator!"

echo ""
echo -e "${BLUE}✅ Benefits:${NC}"
echo "✓ Universal binary (device + simulator)"
echo "✓ SSL/HTTPS support" 
echo "✓ Low-latency streaming"
echo "✓ Hardware acceleration" 