#!/bin/bash

echo "🔧 Fixing IJKMediaFrameworkWithSSL embedding in IJKMediaDemo..."

# Navigate to the correct directory
cd "$(dirname "$0")/ios/IJKMediaDemo"

# Check if project exists
if [ ! -f "IJKMediaDemo.xcodeproj/project.pbxproj" ]; then
    echo "❌ IJKMediaDemo.xcodeproj not found!"
    exit 1
fi

# Backup the original project file
cp IJKMediaDemo.xcodeproj/project.pbxproj IJKMediaDemo.xcodeproj/project.pbxproj.backup

echo "📁 Adding Copy Files build phase for framework embedding..."

# Add the framework embedding configuration to the project file
# This adds a Copy Files build phase that embeds the framework

python3 << 'EOF'
import os
import re

project_file = "IJKMediaDemo.xcodeproj/project.pbxproj"

# Read the project file
with open(project_file, 'r') as f:
    content = f.read()

# Check if Copy Files phase already exists
if 'dstPath = "";' in content and 'dstSubfolderSpec = 10;' in content:
    print("✅ Copy Files phase already exists")
    exit()

# Find the build phases section for IJKMediaDemo target
build_phases_pattern = r'(buildPhases = \(\s*E6903EF817EAF70200CFD954 /\* Sources \*/,\s*E6903EF917EAF70200CFD954 /\* Frameworks \*/,\s*E6903EFA17EAF70200CFD954 /\* Resources \*/,)'

# Add a new Copy Files build phase ID
copy_files_id = "E6903EFD17EAF70200CFD955"

# Add the Copy Files phase to build phases
replacement = r'\1\n\t\t\t\t' + copy_files_id + r' /* Copy Frameworks */,'

content = re.sub(build_phases_pattern, replacement, content)

# Add the Copy Files build phase definition
copy_files_phase = f'''
/* Begin PBXCopyFilesBuildPhase section */
		{copy_files_id} /* Copy Frameworks */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 10;
			files = (
				{copy_files_id}01 /* IJKMediaFrameworkWithSSL.framework in Copy Frameworks */,
			);
			name = "Copy Frameworks";
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXBuildFile section */'''

# Insert before PBXBuildFile section
content = re.sub(r'(/\* Begin PBXBuildFile section \*/)', copy_files_phase + r'\n\1', content)

# Add the build file reference
build_file_entry = f'\t\t{copy_files_id}01 /* IJKMediaFrameworkWithSSL.framework in Copy Frameworks */ = {{isa = PBXBuildFile; fileRef = 3E8C42152E102F92005E4E9D /* IJKMediaFrameworkWithSSL.framework */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};'

# Find the first build file entry and add our entry after it
build_file_pattern = r'(\t\t[A-F0-9]{24} /\* .+ \*/ = \{isa = PBXBuildFile;.+?\};\n)'
content = re.sub(build_file_pattern, r'\1' + build_file_entry + '\n', content, 1)

# Write the modified content back
with open(project_file, 'w') as f:
    f.write(content)

print("✅ Added Copy Files build phase for framework embedding")
EOF

if [ $? -eq 0 ]; then
    echo "✅ Framework embedding configured successfully!"
    echo "📱 Now clean and rebuild the project:"
    echo "   xcodebuild clean -project IJKMediaDemo.xcodeproj -target IJKMediaDemo"
    echo "   xcodebuild build -project IJKMediaDemo.xcodeproj -target IJKMediaDemo -configuration Debug"
    echo ""
    echo "🔄 Or open in Xcode and build from there:"
    echo "   open IJKMediaDemo.xcodeproj"
else
    echo "❌ Failed to modify project file. Try the manual Xcode method instead."
    echo "🔄 Restoring backup..."
    mv IJKMediaDemo.xcodeproj/project.pbxproj.backup IJKMediaDemo.xcodeproj/project.pbxproj
fi 