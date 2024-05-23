#!/bin/sh

set -e

clang-format -i ./*.m ./*.metal

rm -rf build
mkdir -p build/MetalMemoryUsage.app/Contents
mkdir build/MetalMemoryUsage.app/Contents/MacOS
mkdir build/MetalMemoryUsage.app/Contents/Resources

cp MetalMemoryUsage-Info.plist build/MetalMemoryUsage.app/Contents/Info.plist
plutil -convert binary1 build/MetalMemoryUsage.app/Contents/Info.plist

clang -o build/MetalMemoryUsage.app/Contents/MacOS/MetalMemoryUsage \
	-fmodules -fobjc-arc \
	-g3 \
	-Os \
	-ftrivial-auto-var-init=zero -fwrapv \
	-W \
	-Wall \
	-Wextra \
	-Wpedantic \
	-Wconversion \
	-Wimplicit-fallthrough \
	-Wmissing-prototypes \
	-Wshadow \
	-Wstrict-prototypes \
	-Wno-unused-parameter \
	entry_point.m

xcrun metal \
	-o build/MetalMemoryUsage.app/Contents/Resources/shaders.metallib \
	-gline-tables-only -frecord-sources \
	shaders.metal

cp MetalMemoryUsage.entitlements build/MetalMemoryUsage.entitlements
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.get-task-allow bool YES' \
	build/MetalMemoryUsage.entitlements
codesign \
	--sign - \
	--entitlements build/MetalMemoryUsage.entitlements \
	--options runtime build/MetalMemoryUsage.app/Contents/MacOS/MetalMemoryUsage
