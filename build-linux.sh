#!/bin/bash

# build-linux.sh - Build Skia for Linux
# Usage: ./build-linux.sh [options]
# Options:
#   -y, --non-interactive    Skip confirmation prompts (useful for CI/automation)
#   -h, --help              Show this help message

# Parse command line arguments
non_interactive=false
for arg in "$@"; do
    case $arg in
        -y|--non-interactive)
            non_interactive=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -y, --non-interactive    Skip confirmation prompts (useful for CI/automation)"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Confirmation function for interactive mode
confirm_continue() {
    if [ "$non_interactive" = true ]; then
        return 0  # Always continue in non-interactive mode
    fi
    
    local prompt="${1:-Continue anyway?}"
    read -p "$prompt [Y/n] " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        return 1  # User said no
    fi
    return 0  # User said yes or just pressed enter
}

# Check for required OpenGL/EGL libraries
check_gl_dependencies() {
    echo "Checking for OpenGL/EGL dependencies..."
    
    local missing_deps=()
    
    # Check for EGL headers
    if ! pkg-config --exists egl 2>/dev/null && ! [ -f /usr/include/EGL/egl.h ]; then
        missing_deps+=("libegl1-mesa-dev")
    fi
    
    # Check for OpenGL ES headers
    if ! pkg-config --exists glesv2 2>/dev/null && ! [ -f /usr/include/GLES2/gl2.h ]; then
        missing_deps+=("libgles2-mesa-dev")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "⚠ Missing OpenGL/EGL dependencies: ${missing_deps[*]}"
        echo "ℹ To install: sudo apt-get install ${missing_deps[*]}"
        return 1
    else
        echo "✓ OpenGL/EGL dependencies found"
        return 0
    fi
}

# Check for system library dependencies
check_system_dependencies() {
    echo "Checking for system library dependencies..."
    
    local missing_deps=()
    local warnings=()
    
    # Check for build essentials
    if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
        missing_deps+=("build-essential")
    fi
    
    # Check for FreeType
    if ! pkg-config --exists freetype2 2>/dev/null && ! [ -f /usr/include/freetype2/ft2build.h ]; then
        missing_deps+=("libfreetype6-dev" "libfreetype-dev")
    else
        echo "✓ FreeType found"
    fi
    
    # Check for FontConfig
    if ! pkg-config --exists fontconfig 2>/dev/null && ! [ -f /usr/include/fontconfig/fontconfig.h ]; then
        warnings+=("libfontconfig1-dev")
    else
        echo "✓ FontConfig found"
    fi
    
    # Check for libpng
    if ! pkg-config --exists libpng 2>/dev/null && ! [ -f /usr/include/png.h ]; then
        warnings+=("libpng-dev")
    else
        echo "✓ libpng found"
    fi
    
    # Check for libjpeg
    if ! pkg-config --exists libjpeg 2>/dev/null && ! [ -f /usr/include/jpeglib.h ]; then
        warnings+=("libjpeg-turbo8-dev" "libjpeg-dev")
    else
        echo "✓ libjpeg found"
    fi
    
    # Check for libwebp
    if ! pkg-config --exists libwebp 2>/dev/null; then
        warnings+=("libwebp-dev")
    else
        echo "✓ libwebp found"
    fi
    
    # Check for zlib
    if ! pkg-config --exists zlib 2>/dev/null && ! [ -f /usr/include/zlib.h ]; then
        warnings+=("zlib1g-dev")
    else
        echo "✓ zlib found"
    fi
    
    # Check for expat
    if ! pkg-config --exists expat 2>/dev/null && ! [ -f /usr/include/expat.h ]; then
        warnings+=("libexpat1-dev")
    else
        echo "✓ expat found"
    fi
    
    # Check for HarfBuzz
    if ! pkg-config --exists harfbuzz 2>/dev/null && ! [ -f /usr/include/harfbuzz/hb.h ]; then
        warnings+=("libharfbuzz-dev")
    else
        echo "✓ HarfBuzz found"
    fi
    
    # Check for libgif
    if ! [ -f /usr/include/gif_lib.h ] && ! [ -f /usr/local/include/gif_lib.h ]; then
        warnings+=("libgif-dev")
    else
        echo "✓ libgif found"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Missing required dependencies: ${missing_deps[*]}"
        echo "ℹ To install: sudo apt-get install ${missing_deps[*]}"
        return 1
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        echo "⚠ Optional system libraries not found: ${warnings[*]}"
        echo "ℹ These libraries are optional. System libraries can reduce binary size and receive OS security updates."
        echo "ℹ To install all: sudo apt-get install ${warnings[*]}"
        echo "ℹ Skia will use bundled versions if system libraries are not available."
        echo ""
        
        if ! confirm_continue "Do you want to continue with bundled libraries?"; then
            echo "Build cancelled by user."
            exit 1
        fi
    fi
    
    return 0
}

# Detect ICU installation
detect_icu() {
    echo "Detecting ICU installation..."
    
    # Check pkg-config for ICU
    if command -v pkg-config >/dev/null 2>&1; then
        if pkg-config --exists icu-uc icu-i18n; then
            icu_version=$(pkg-config --modversion icu-uc 2>/dev/null)
            echo "✓ Found ICU via pkg-config"
            if [ -n "$icu_version" ]; then
                echo "✓ ICU version: $icu_version"
            fi
            return 0
        fi
    fi
    
    # Check standard Linux locations
    for path in /usr /usr/local; do
        if [ -d "$path/include/unicode" ] && [ -d "$path/lib" ]; then
            # Basic verification that ICU libraries exist
            if ls "$path/lib/"*icu* >/dev/null 2>&1 || ls "$path/lib/x86_64-linux-gnu/"*icu* >/dev/null 2>&1; then
                export ICU_ROOT="$path"
                echo "✓ Found ICU at: $ICU_ROOT"
                return 0
            fi
        fi
    done
    
    echo "⚠ No compatible system ICU found"
    echo "ℹ To install ICU: sudo apt-get install libicu-dev (Ubuntu/Debian) or sudo yum install libicu-devel (CentOS/RHEL)"
    return 1
}

# ICU Configuration Function
configure_icu() {
    # Always try to use system ICU to avoid conflicts with V8's bundled ICU
    if detect_icu; then
        echo "✓ Configuring build to use system ICU (avoids V8 conflicts)"
        echo 'skia_use_icu = true' >> $args_file
        echo 'skia_use_system_icu = true' >> $args_file
    else
        echo "⚠ No system ICU found - this may cause conflicts with V8's bundled ICU"
        echo "ℹ Strongly recommended: sudo apt-get install libicu-dev"
        echo "ℹ Disabling ICU in Skia to avoid V8 conflicts"
        echo 'skia_use_icu = false' >> $args_file
    fi
}

# Detect current architecture
current_arch=$(uname -m)
if [ "$current_arch" = "x86_64" ]; then
    target_cpu="x64"
elif [ "$current_arch" = "aarch64" ]; then
    target_cpu="arm64"
else
    echo "Unsupported architecture: $current_arch"
    exit 1
fi

echo "Building Skia for Linux ($target_cpu)..."

# Check for required dependencies
echo ""
if ! check_system_dependencies; then
    echo ""
    echo "❌ Missing required dependencies. Please install them before continuing."
    exit 1
fi

echo ""
if ! check_gl_dependencies; then
    echo ""
    echo "❌ Missing OpenGL/EGL dependencies. Build will likely fail."
    echo "  Please install the missing packages before continuing."
    
    if ! confirm_continue "Do you want to try building anyway?"; then
        echo "Build cancelled by user."
        exit 1
    fi
    echo "⚠️  Proceeding without OpenGL/EGL dependencies - build may fail!"
fi

echo ""
echo "✅ All required dependencies found. Proceeding with build..."
echo ""

script_dir=$(pwd);

./get_depot_tools.sh;
export PATH=$(pwd)/depot_tools:$PATH;

./fetch.sh;

cd src/skia;
python3 tools/git-sync-deps;
python3 bin/fetch-ninja;

release_name=release-linux-$target_cpu;

rm -rf out/$release_name;
mkdir -p out/$release_name;

args_file=out/$release_name/args.gn;
echo 'is_official_build = true' >> $args_file;
echo "target_cpu = \"$target_cpu\"" >> $args_file;
echo 'skia_use_system_expat = false' >> $args_file;
echo 'skia_use_system_libjpeg_turbo = false' >> $args_file;
echo 'skia_use_system_libpng = false' >> $args_file;
echo 'skia_use_system_libwebp = false' >> $args_file;
echo 'skia_use_system_zlib = false' >> $args_file;
configure_icu;
echo 'skia_use_system_harfbuzz = false' >> $args_file;
echo 'skia_use_gl = true' >> $args_file;
echo 'skia_use_egl = true' >> $args_file;
echo 'extra_cflags_cc=["-fexceptions", "-frtti"]' >> $args_file;

bin/gn gen out/$release_name

bin/ninja -C out/$release_name;

cd $script_dir;

# Copy the build to a generic output location
if [ -d "src/skia/out/release-linux" ]; then
    rm -rf src/skia/out/release-linux;
fi
mkdir -p src/skia/out/release-linux;

# Copy all files from architecture-specific build
cp -r src/skia/out/$release_name/* src/skia/out/release-linux/;

# Clean up architecture-specific output
rm -rf src/skia/out/$release_name;

echo "Build complete for Linux ($target_cpu architecture)"
echo "Output: src/skia/out/release-linux/"
