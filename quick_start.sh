#!/bin/bash

# RadiateOS Quick Start Script
# Gets developers up and running quickly with RadiateOS

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     RadiateOS Quick Start Setup        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

echo -e "${BLUE}[1/5]${NC} Detected OS: $OS"

# Install dependencies based on OS
echo -e "${BLUE}[2/5]${NC} Installing dependencies..."

case $OS in
    macos)
        # Check for Homebrew
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # Install required tools
        brew install swift-format swiftlint
        
        # Check for Xcode
        if ! command -v xcodebuild &> /dev/null; then
            echo -e "${YELLOW}Please install Xcode from the App Store${NC}"
            echo "After installing, run: sudo xcode-select --switch /Applications/Xcode.app"
            exit 1
        fi
        ;;
    
    linux)
        # Update package manager
        sudo apt-get update || sudo yum update || sudo pacman -Syu
        
        # Install Swift
        if ! command -v swift &> /dev/null; then
            echo "Installing Swift..."
            wget https://swift.org/builds/swift-5.9-release/ubuntu2204/swift-5.9-RELEASE/swift-5.9-RELEASE-ubuntu22.04.tar.gz
            tar xzf swift-5.9-RELEASE-ubuntu22.04.tar.gz
            sudo mv swift-5.9-RELEASE-ubuntu22.04 /usr/share/swift
            echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc
            source ~/.bashrc
        fi
        
        # Install build tools
        sudo apt-get install -y build-essential git cmake libssl-dev || \
        sudo yum install -y gcc gcc-c++ make cmake openssl-devel || \
        sudo pacman -S base-devel git cmake openssl
        ;;
    
    windows)
        echo -e "${YELLOW}Please ensure you have WSL2 installed${NC}"
        echo "Run: wsl --install"
        echo "Then run this script inside WSL2"
        exit 1
        ;;
    
    *)
        echo -e "${YELLOW}Unknown OS. Please install dependencies manually.${NC}"
        ;;
esac

# Clone or update repository
echo -e "${BLUE}[3/5]${NC} Setting up repository..."

if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit"
fi

# Build RadiateOS
echo -e "${BLUE}[4/5]${NC} Building RadiateOS..."

if [[ "$OS" == "macos" ]]; then
    cd RadiateOS
    xcodebuild -project RadiateOS.xcodeproj \
               -scheme RadiateOS \
               -configuration Debug \
               -destination "platform=macOS" \
               build
    cd ..
    echo -e "${GREEN}✓ Build successful${NC}"
else
    swift build
    echo -e "${GREEN}✓ Build successful${NC}"
fi

# Run tests
echo -e "${BLUE}[5/5]${NC} Running tests..."

if [[ "$OS" == "macos" ]]; then
    cd RadiateOS
    xcodebuild test -project RadiateOS.xcodeproj \
                    -scheme RadiateOS \
                    -destination "platform=macOS" || echo -e "${YELLOW}Some tests failed${NC}"
    cd ..
else
    swift test || echo -e "${YELLOW}Some tests failed${NC}"
fi

# Create development environment
echo
echo -e "${GREEN}Setting up development environment...${NC}"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cat > .env << EOF
# RadiateOS Development Environment
RADIATEOS_ENV=development
RADIATEOS_DEBUG=true
RADIATEOS_LOG_LEVEL=debug
EOF
    echo "Created .env file"
fi

# Create VS Code workspace settings
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "swift.path": "/usr/bin/swift",
    "swift.buildArguments": [
        "-Xswiftc",
        "-target",
        "-Xswiftc",
        "x86_64-apple-macosx10.15"
    ],
    "files.associations": {
        "*.swift": "swift"
    },
    "editor.formatOnSave": true,
    "swift.formatOnSave": true
}
EOF

# Success message
echo
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Setup Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo
echo "RadiateOS is ready for development!"
echo
echo "Next steps:"
echo "  1. Run RadiateOS:"
if [[ "$OS" == "macos" ]]; then
    echo "     open RadiateOS/build/Debug/RadiateOS.app"
else
    echo "     .build/debug/RadiateOS"
fi
echo
echo "  2. Build for release:"
echo "     ./build_and_package.sh"
echo
echo "  3. Run benchmarks:"
echo "     python3 system_benchmark.py"
echo
echo "  4. View documentation:"
echo "     open README.md"
echo
echo "Happy coding! 🚀"