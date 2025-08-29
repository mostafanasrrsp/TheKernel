#!/bin/bash

# RadiateOS Intel Mac Installation Test Script
# Tests the installation and verifies correct branding

set -euo pipefail

echo "🧪 Testing RadiateOS Intel Mac Installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test 1: Check if running on Intel Mac
echo "Test 1: Verifying Intel Mac compatibility..."
if [[ "$(uname -m)" == "x86_64" ]]; then
    echo -e "${GREEN}✅ Intel Mac detected${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Not running on Intel Mac${NC}"
    ((FAILED++))
fi

# Test 2: Check if installer was created
echo ""
echo "Test 2: Checking installer files..."
INSTALLER_DMG="/workspace/build/installers/intel-pc/RadiateOS-Intel-Installer.dmg"
if [[ -f "$INSTALLER_DMG" ]]; then
    echo -e "${GREEN}✅ Intel installer DMG found${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Intel installer DMG not found${NC}"
    ((FAILED++))
fi

INSTALLER_CFG="/workspace/build/installers/intel-pc/installer.cfg"
if [[ -f "$INSTALLER_CFG" ]]; then
    echo -e "${GREEN}✅ Installer configuration found${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Installer configuration not found${NC}"
    ((FAILED++))
fi

# Test 3: Verify installer configuration
echo ""
echo "Test 3: Verifying installer configuration..."
if [[ -f "$INSTALLER_CFG" ]]; then
    if grep -q 'NAME="RadiateOS"' "$INSTALLER_CFG"; then
        echo -e "${GREEN}✅ Correct OS name configured${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Incorrect OS name in configuration${NC}"
        ((FAILED++))
    fi

    if grep -q 'ARCHITECTURE="x86_64"' "$INSTALLER_CFG"; then
        echo -e "${GREEN}✅ Correct architecture configured${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Incorrect architecture in configuration${NC}"
        ((FAILED++))
    fi
fi

# Test 4: Check if boot branding fix script exists
echo ""
echo "Test 4: Checking boot branding fix script..."
BOOT_FIX_SCRIPT="/workspace/fix_intel_boot_branding.sh"
if [[ -f "$BOOT_FIX_SCRIPT" ]] && [[ -x "$BOOT_FIX_SCRIPT" ]]; then
    echo -e "${GREEN}✅ Boot branding fix script found and executable${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Boot branding fix script not found or not executable${NC}"
    ((FAILED++))
fi

# Test 5: Check if installation guide exists
echo ""
echo "Test 5: Checking installation documentation..."
INSTALL_GUIDE="/workspace/INTEL_MAC_INSTALLATION_GUIDE.md"
if [[ -f "$INSTALL_GUIDE" ]]; then
    echo -e "${GREEN}✅ Intel Mac installation guide found${NC}"
    ((PASSED++))

    # Check if guide contains key information
    if grep -q "blue screen" "$INSTALL_GUIDE" && grep -q "Windows" "$INSTALL_GUIDE"; then
        echo -e "${GREEN}✅ Installation guide addresses known issues${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  Installation guide may be missing issue coverage${NC}"
    fi
else
    echo -e "${RED}❌ Intel Mac installation guide not found${NC}"
    ((FAILED++))
fi

# Test 6: Check RadiateOS project structure
echo ""
echo "Test 6: Verifying RadiateOS project structure..."
if [[ -d "/workspace/RadiateOS" ]]; then
    echo -e "${GREEN}✅ RadiateOS project directory found${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ RadiateOS project directory not found${NC}"
    ((FAILED++))
fi

if [[ -f "/workspace/RadiateOS/RadiateOS.xcodeproj/project.pbxproj" ]]; then
    echo -e "${GREEN}✅ Xcode project found${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Xcode project not found${NC}"
    ((FAILED++))
fi

# Test 7: Check available storage space
echo ""
echo "Test 7: Checking available storage space..."
AVAILABLE_SPACE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
if [[ $AVAILABLE_SPACE -ge 25 ]]; then
    echo -e "${GREEN}✅ Sufficient storage space available (${AVAILABLE_SPACE}GB)${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️  Limited storage space (${AVAILABLE_SPACE}GB). Need 25GB+ for installation${NC}"
fi

# Summary
echo ""
echo "=== Test Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total:  $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 All tests passed! Ready for installation.${NC}"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Run: ./create_intel_bootable_installer.sh"
    echo "2. Follow: INTEL_MAC_INSTALLATION_GUIDE.md"
    echo "3. If issues occur, run: ./fix_intel_boot_branding.sh"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please address the issues before installation.${NC}"
fi

# Specific recommendations
if [[ ! -f "$INSTALLER_DMG" ]]; then
    echo ""
    echo -e "${YELLOW}💡 Recommendation: Run installer creation script${NC}"
    echo "   ./create_intel_bootable_installer.sh"
fi

if [[ ! -f "$BOOT_FIX_SCRIPT" ]]; then
    echo ""
    echo -e "${YELLOW}💡 Recommendation: Boot branding fix script is missing${NC}"
fi

echo ""
echo "📋 System Information:"
echo "  Architecture: $(uname -m)"
echo "  OS: $(sw_vers -productName) $(sw_vers -productVersion)"
echo "  Build: $(sw_vers -buildVersion)"
echo "  Available Space: ${AVAILABLE_SPACE}GB"