# require 'toml'
# Unlike 'json', this does not come pre-installed with Ruby, so will require installing with `gem install toml`.

# See: https://github.com/jm/toml
# cargo = TOML.load_file("Cargo.toml")

# Generate xcfilelists on pod install
xcfilelistName = 'wry-inputs.xcfilelist'
resourcesBesidesSrc = [xcfilelistName, 'Cargo.toml', 'Cargo.lock', 'build.rs', 'rustfmt.toml']

inputFiles = []

# FIXME: Confirm that incremental build support is working. I'm having issues with understanding when the Cocoapods env vars
#        get populated and where they're made available.
# Looks like PODS_ROOT is: "${SRCROOT}/Pods" i.e. /Users/jamie/Documents/git/wry-ios-poc-new/gen/apple/Pods
# Looks like PODS_TARGET_SRCROOT is: "${SRCROOT}/Pods/wry" i.e. /Users/jamie/Documents/git/wry-ios-poc-new/gen/apple/Pods/Target\ Support\ Files/wry
# Neither of these are related to src/**/*.
# It's found in Build Settings, in the User-Defined settings.
# From: https://github.com/apollographql/apollo-ios/issues/636#issuecomment-542238208
# The original comment may well have been using the wrong env var.
File.open(xcfilelistName, 'w') do |inputs|
  resourcesBesidesSrc.each do | path |
    if path != xcfilelistName
      resolvedPath = "$(PODS_TARGET_SRCROOT)/" + path
      inputs.puts resolvedPath
      inputFiles.push(resolvedPath)
    end
  end
  Dir.glob("src/**/*").each do | path |
    pathObj = Pathname.new(path)
    if !pathObj.directory?
      resolvedPath = "$(PODS_TARGET_SRCROOT)/" + pathObj.relative_path_from("$(PODS_TARGET_SRCROOT)/..").to_s
      inputs.puts resolvedPath
      inputFiles.push(resolvedPath)
    end
  end
end

Pod::Spec.new do |s|
  # s.name         = cargo['package']['name']
  # s.version      = cargo['package']['version']
  # s.summary      = cargo['package']['description']
  # s.authors      = cargo['package']['authors']

  s.name         = 'wry'
  s.version      = '0.9.2'
  s.summary      = 'Cross-platform WebView rendering library'
  s.authors      = 'Tauri Programme within The Commons Conservancy'

  s.homepage     = "https://github.com/tauri-apps/wry"
  s.license      = { :type => "Apache-2.0", :file => "LICENSE-APACHE" }
  # Of note, the last time I checked, the lowest version supported by React Native was iOS 10.0; and for macOS, it was 10.11.
  s.platforms    = { :ios => "9.0", :osx => "10.11" }
  s.source       = { :git => "https://github.com/tauri-apps/wry.git", :tag => "wry-v#{s.version}" }

  # s.source_files = 'Classes/*.{cpp,h}', 'ios/*.{m,h}'
  # # These are all entry points to Mecab that we don't want to include (because they lead to: "duplicate symbol_main").
  # s.exclude_files = 'Classes/mecab-cost-train.cpp', 'Classes/mecab-dict-gen.cpp', 'Classes/mecab-dict-index.cpp', 'Classes/mecab-system-eval.cpp', 'Classes/mecab-test-gen.cpp'
  # s.resources    = 'Assets/*'

  # s.xcconfig = {
  #   'CLANG_ENABLE_OBJC_ARC' => 'NO',
  #   'GCC_PREPROCESSOR_DEFINITIONS' => 'HAVE_CONFIG_H MECAB_DEFAULT_RC=\"./\" DIC_VERSION=102',
  # }
  # s.libraries  = 'iconv', 'c++'

  # This might be more of a tao concern, but we'll see.
  s.frameworks = 'WebKit'
  s.resources = ['src/**/*', *resourcesBesidesSrc]

  # While this won't exclude the (yellow) folder groups, it will exclude the (blue) folder references.
  # If iOS and macOS needs ever diverge, we can change this to `s.ios.exclude_files` and `s.osx.exclude_files`.
  s.exclude_files = 'src/**/linux', 'src/**/win32', 'src/**/winrt'

  # A bash script that will be executed after the Pod is downloaded.
  # This command can be used to create, delete and modify any file downloaded and will be ran before any paths
  # for other file attributes of the specification are collected.
  # See: https://github.com/Geal/rust_on_mobile/blob/master/InRustWeTrustKit.podspec
  s.prepare_command = <<-CMD
BASEPATH="${PWD}"
echo "This is the prepare_command for the wry pod. pwd: ${BASEPATH}"
  CMD

  # For iOS, ARCHS returns "arm64 armv7". We want just "arm64" (because cargo-mobile doesn't support armv7 for iOS, and
  # maybe in a related fashion because it's the intersection between ARCHS and VALID_ARCHS).
  s.ios.script_phases = [
    {
      :name => 'Build',
      # :input_file_lists => ['$(SRCROOT)/Target Support Files/' + s.name + '/' + xcfilelistName],
      # :input_files => inputFiles,
      :script => <<-CMD
echo "This is the build phase for the 'wry' pod. HOME: ${HOME}; SRCROOT: ${SRCROOT}; PWD: ${PWD}; ARCHS: ${ARCHS}; CONFIGURATION: ${CONFIGURATION:?}"

cd "${SRCROOT}/.."

${HOME}/.cargo/bin/cargo-apple xcode-script -v --platform ${PLATFORM_DISPLAY_NAME:?} --sdk-root ${SDKROOT:?} --configuration ${CONFIGURATION:?} ${FORCE_COLOR} arm64
      CMD
    },
  ]

  # For macOS, ARCHS returns "arm64 x86_64". I haven't tried running this for macOS yet, so haven't seen whether this needs restricting.
  s.osx.script_phases = [
    {
      :name => 'Build',
      # :input_file_lists => ['$(SRCROOT)/Target Support Files/' + s.name + '/' + xcfilelistName],
      # :input_files => inputFiles,
      :script => <<-CMD
echo "This is the build phase for the 'wry' pod. HOME: ${HOME}; SRCROOT: ${SRCROOT}; PWD: ${PWD}; ARCHS: ${ARCHS}; CONFIGURATION: ${CONFIGURATION:?}"

cd "${SRCROOT}/.."

${HOME}/.cargo/bin/cargo-apple xcode-script -v --platform ${PLATFORM_DISPLAY_NAME:?} --sdk-root ${SDKROOT:?} --configuration ${CONFIGURATION:?} ${FORCE_COLOR} ${ARCHS:?}
      CMD
    },
  ]

  s.info_plist = {
    'Additional licenses' => 'MIT - See LICENSE-MIT',
  }

end