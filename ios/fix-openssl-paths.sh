#!/bin/bash

# Fix OpenSSL library paths for ijkplayer iOS build
# This script copies OpenSSL libraries to the expected build locations

set -e

UNI_BUILD_ROOT=`pwd`
FF_ALL_ARCHS="armv7 arm64 i386 x86_64"

echo "Fixing OpenSSL library paths..."

for ARCH in $FF_ALL_ARCHS
do
    echo "Processing $ARCH..."
    
    # Create build directory structure
    mkdir -p build/openssl-$ARCH/output/lib
    mkdir -p build/openssl-$ARCH/output/include/openssl
    
    # Copy OpenSSL libraries if they exist
    if [ -f "openssl-$ARCH/libssl.a" ]; then
        cp openssl-$ARCH/libssl.a build/openssl-$ARCH/output/lib/
        echo "  ✅ Copied libssl.a for $ARCH"
    else
        echo "  ❌ Missing libssl.a for $ARCH"
    fi
    
    if [ -f "openssl-$ARCH/libcrypto.a" ]; then
        cp openssl-$ARCH/libcrypto.a build/openssl-$ARCH/output/lib/
        echo "  ✅ Copied libcrypto.a for $ARCH"
    else
        echo "  ❌ Missing libcrypto.a for $ARCH"
    fi
    
    # Copy OpenSSL headers if they exist - resolve symlinks to actual files
    if [ -d "openssl-$ARCH/include/openssl" ]; then
        # Remove any existing broken symlinks
        rm -rf build/openssl-$ARCH/output/include/openssl/*
        
        # Copy all header files, resolving symlinks
        find openssl-$ARCH/include/openssl -name "*.h" -exec cp {} build/openssl-$ARCH/output/include/openssl/ \;
        echo "  ✅ Copied headers for $ARCH"
    else
        echo "  ❌ Missing headers for $ARCH"
    fi
done

echo "OpenSSL library paths fixed!"
echo "Now run: ./compile-ffmpeg.sh lipo" 