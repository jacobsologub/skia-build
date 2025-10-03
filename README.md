# skia-build

Scripts to build Google's Skia library for macOS and iOS platforms.

## Description

This repository contains shell scripts that automate the process of building Skia for:
- macOS (arm64, x64, and universal binaries)
- iOS (device, simulator, and XCFramework)

## Skia Version

The Skia version is controlled by `version.txt` which contains a Chrome milestone branch (e.g., `chrome/m140`). This ensures builds use stable Skia releases aligned with Chrome releases.

To change the Skia version, edit `version.txt` with a different Chrome milestone. Available branches can be found at [Chromium Dash](https://chromiumdash.appspot.com/branches).

## Installation and Build

1. Clone this repository:
   ```bash
   git clone https://github.com/jacobsologub/skia-build.git
   ```
2. Navigate to the cloned directory:
   ```bash
   cd skia-build
   ```
3. Run the appropriate build script:

### macOS Builds
```bash
# Build for current architecture only
./build-macos.sh

# Build universal binary (arm64 + x64)
./build-macos.sh --universal
```

### iOS Builds
```bash
# Build for iOS device (arm64)
./build-ios.sh --device

# Build for iOS simulator (current architecture)
./build-ios.sh --simulator

# Build universal simulator (x64 + arm64)
./build-ios.sh --simulator --universal

# Build XCFramework (device + universal simulator)
./build-ios.sh --xcframework
```

[License](https://github.com/jacobsologub/skia-build/master/LICENSE)
-------
The MIT License (MIT)

Copyright (c) 2024 [Jacob Sologub](https://github.com/jacobsologub)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[Skia License](https://github.com/google/skia/blob/main/LICENSE)
-------
Copyright (c) 2011 Google Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

  * Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
