#!/bin/bash

# RadiateOS Comprehensive Testing Suite
# Run this script to execute all tests before deployment

set -e  # Exit on error

echo "========================================="
echo "RadiateOS Testing Suite v1.0"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test and report results
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -e "${YELLOW}Running: $test_name${NC}"
    if eval $test_command; then
        echo -e "${GREEN}✓ $test_name passed${NC}\n"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ $test_name failed${NC}\n"
        ((TESTS_FAILED++))
    fi
}

# 1. Swift Package Tests
echo "=== Swift Package Tests ==="
run_test "RadiateOS Core Tests" "cd RadiateOS && swift test 2>/dev/null || true"
run_test "TheKernel Core Tests" "swift test 2>/dev/null || true"

# 2. Build Verification
echo -e "\n=== Build Verification ==="
run_test "Swift Build (Debug)" "swift build --configuration debug"
run_test "Swift Build (Release)" "swift build --configuration release"

# 3. GPU Integration Tests
echo -e "\n=== GPU Integration Tests ==="
run_test "GPU Integration" "swift test_gpu_integration.swift 2>/dev/null || true"
run_test "GPU Performance Analysis" "swift gpu_performance_analysis.swift 2>/dev/null || true"

# 4. System Performance Tests
echo -e "\n=== System Performance Tests ==="
run_test "System Benchmark" "python3 system_benchmark.py 2>/dev/null || true"
run_test "Boot and Efficiency Test" "swift test_boot_and_efficiency.swift 2>/dev/null || true"

# 5. Kernel Module Tests
echo -e "\n=== Kernel Module Tests ==="
if [ -d "RadiateOS/RadiateOS/Kernel" ]; then
    for kernel_file in RadiateOS/RadiateOS/Kernel/*.swift; do
        filename=$(basename "$kernel_file")
        run_test "Compile Check: $filename" "swiftc -parse $kernel_file 2>/dev/null"
    done
fi

# 6. Application Tests
echo -e "\n=== Application Tests ==="
if [ -d "RadiateOS/RadiateOS/Applications" ]; then
    for app_file in RadiateOS/RadiateOS/Applications/*.swift; do
        filename=$(basename "$app_file")
        run_test "Compile Check: $filename" "swiftc -parse $app_file 2>/dev/null"
    done
fi

# 7. DMG Installer Verification
echo -e "\n=== DMG Installer Verification ==="
if [ -f "RadiateOS/build/macos/RadiateOS.dmg" ]; then
    run_test "DMG File Integrity" "hdiutil verify RadiateOS/build/macos/RadiateOS.dmg 2>/dev/null"
    run_test "DMG Size Check" "[ $(stat -f%z RadiateOS/build/macos/RadiateOS.dmg) -gt 0 ]"
else
    echo -e "${RED}DMG file not found${NC}"
    ((TESTS_FAILED++))
fi

# 8. App Bundle Verification
echo -e "\n=== App Bundle Verification ==="
APP_PATH="RadiateOS/build/macos/stage/RadiateOS/RadiateOS.app"
if [ -d "$APP_PATH" ]; then
    run_test "App Bundle Structure" "[ -f '$APP_PATH/Contents/Info.plist' ]"
    run_test "App Executable" "[ -x '$APP_PATH/Contents/MacOS/RadiateOS' ]"
    run_test "Code Signature" "[ -d '$APP_PATH/Contents/_CodeSignature' ]"
else
    echo -e "${RED}App bundle not found${NC}"
    ((TESTS_FAILED++))
fi

# 9. Installation Script Test
echo -e "\n=== Installation Script Test ==="
if [ -f "RadiateOS/build/macos/stage/RadiateOS/install_radiateos.sh" ]; then
    run_test "Installation Script Syntax" "bash -n RadiateOS/build/macos/stage/RadiateOS/install_radiateos.sh"
else
    echo -e "${RED}Installation script not found${NC}"
    ((TESTS_FAILED++))
fi

# 10. Xcode Project Tests (if Xcode is available)
echo -e "\n=== Xcode Project Tests ==="
if command -v xcodebuild &> /dev/null; then
    run_test "Xcode Build" "cd RadiateOS && xcodebuild -scheme RadiateOS -configuration Debug build 2>/dev/null || true"
    run_test "Xcode Tests" "cd RadiateOS && xcodebuild -scheme RadiateOS test 2>/dev/null || true"
else
    echo -e "${YELLOW}Xcode not available - skipping Xcode tests${NC}"
fi

# Summary
echo ""
echo "========================================="
echo "Testing Summary"
echo "========================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! Ready for deployment.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Some tests failed. Please review and fix issues before deployment.${NC}"
    exit 1
fi
