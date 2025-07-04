#!/bin/bash

echo "🔧 Adding runtime search paths to IJKMediaDemo..."

cd ios/IJKMediaDemo

# Backup the project file
cp IJKMediaDemo.xcodeproj/project.pbxproj IJKMediaDemo.xcodeproj/project.pbxproj.backup3

# Add LD_RUNPATH_SEARCH_PATHS to Debug configuration (after FRAMEWORK_SEARCH_PATHS)
sed -i '' '/E6903F1A17EAF70200CFD954.*Debug.*{/,/name = Debug;/{
  /FRAMEWORK_SEARCH_PATHS = /,/);/a\
                                LD_RUNPATH_SEARCH_PATHS = (\
                                        "$(inherited)",\
                                        "@executable_path/Frameworks",\
                                );
}' IJKMediaDemo.xcodeproj/project.pbxproj

# Add LD_RUNPATH_SEARCH_PATHS to Release configuration (after FRAMEWORK_SEARCH_PATHS)
sed -i '' '/E6903F1B17EAF70200CFD954.*Release.*{/,/name = Release;/{
  /FRAMEWORK_SEARCH_PATHS = /,/);/a\
                                LD_RUNPATH_SEARCH_PATHS = (\
                                        "$(inherited)",\
                                        "@executable_path/Frameworks",\
                                );
}' IJKMediaDemo.xcodeproj/project.pbxproj

echo "✅ Runtime search paths added successfully!"
echo "📍 Added paths:"
echo "   - @executable_path/Frameworks (for both Debug and Release)" 