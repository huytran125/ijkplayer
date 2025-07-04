#!/bin/bash

echo "🔧 Adding framework search paths to IJKMediaDemo..."

cd ios/IJKMediaDemo

# Backup the project file
cp IJKMediaDemo.xcodeproj/project.pbxproj IJKMediaDemo.xcodeproj/project.pbxproj.backup2

# Add FRAMEWORK_SEARCH_PATHS to Debug configuration (after LIBRARY_SEARCH_PATHS)
sed -i '' '/E6903F1A17EAF70200CFD954.*Debug.*{/,/name = Debug;/{
  /LIBRARY_SEARCH_PATHS = /a\
                                FRAMEWORK_SEARCH_PATHS = (\
                                        "$(inherited)",\
                                        "../IJKMediaPlayer/build/Debug-iphoneos",\
                                );
}' IJKMediaDemo.xcodeproj/project.pbxproj

# Add FRAMEWORK_SEARCH_PATHS to Release configuration (after LIBRARY_SEARCH_PATHS)
sed -i '' '/E6903F1B17EAF70200CFD954.*Release.*{/,/name = Release;/{
  /LIBRARY_SEARCH_PATHS = /a\
                                FRAMEWORK_SEARCH_PATHS = (\
                                        "$(inherited)",\
                                        "../IJKMediaPlayer/build/Release-iphoneos",\
                                );
}' IJKMediaDemo.xcodeproj/project.pbxproj

echo "✅ Framework search paths added successfully!"
echo "📍 Added paths:"
echo "   - Debug: ../IJKMediaPlayer/build/Debug-iphoneos"
echo "   - Release: ../IJKMediaPlayer/build/Release-iphoneos" 