# require 'toml'
# Unlike 'json', this does not come pre-installed with Ruby, so will require installing with `gem install toml`.

# See: https://github.com/jm/toml
# cargo = TOML.load_file("Cargo.toml")

# The working directory of the Ruby code for this Pod will be PODS_TARGET_SRCROOT.
resourcesBesidesSrc = ['Cargo.toml', 'Cargo.lock', 'build.rs', 'rustfmt.toml']

inputFiles = []

# The POD* variables are found in the Build Settings of both the Pods project and the main project, under the User-Defined settings.
# Looks like PODS_ROOT is: "${SRCROOT}/Pods" i.e. /Users/jamie/Documents/git/wry-ios-poc-new/gen/apple/Pods
# Looks like PODS_TARGET_SRCROOT is: "${PODS_ROOT}/../../../../wry" i.e. /Users/jamie/Documents/git/wry
# From: https://github.com/apollographql/apollo-ios/issues/636#issuecomment-542238208
resourcesBesidesSrc.each do | path |
  inputFiles.push("$(PODS_TARGET_SRCROOT)/" + path)
end
Dir.glob("src/**/*").each do | path |
  pathObj = Pathname.new(path)
  if !pathObj.directory?
    inputFiles.push("$(PODS_TARGET_SRCROOT)/" + pathObj.relative_path_from("$(PODS_TARGET_SRCROOT)/..").to_s)
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
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
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
  s.source_files = ['src/**/*', *resourcesBesidesSrc]

  # cargo-mobile doesn't distribute an i386 architecture, so here we prevent i386 being part of ARCHS for the `cargo-apple` command.
  # https://github.com/CocoaPods/CocoaPods/issues/10077
  # https://stackoverflow.com/questions/63607158/xcode-12-building-for-ios-simulator-but-linking-in-object-file-built-for-ios

  common_xcconfig = {
    :EXCLUDED_ARCHS => 'i386',
  }

  s.ios.pod_target_xcconfig = {
    **common_xcconfig,
    # 'LIBRARY_SEARCH_PATHS' => '$(inherited) "{{prefix-path "target/x86_64-apple-darwin/$(CONFIGURATION)"}}"'
    # "/Users/jamie/Documents/git/wry-ios-poc-new/target/x86_64-apple-ios/$(CONFIGURATION)"
    'LIBRARY_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/../../target/aarch64-apple-ios/$(CONFIGURATION)',
    'LIBRARY_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/../../target/x86_64-apple-ios/$(CONFIGURATION)',
  }
  s.osx.pod_target_xcconfig = {
    **common_xcconfig,
    'LIBRARY_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/../../target/x86_64-apple-darwin/$(CONFIGURATION)',
  }

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

  # TODO: study https://github.com/BrainiumLLC/cargo-mobile/blob/8a021a7d21315d0d4ad16d5d3c6526340e2fabb8/templates/platforms/xcode/project.yml.hbs

  script_build_phase = {
    :name => 'Build',
    # :input_files => inputFiles,
    # I'm still working out the proper escaping for this.
    # When it goes really wrong, we get:
    #  xcode-script -v --platform iOS Simulator --sdk-root /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.4.sdk --configuration Debug  x86_64
    # This interprets "Simulator" as a terminal arg. So at the very least, platform needs to be quoted.
    # But we also don't want to quote FORCE_COLOR, as then it interprets "" as a terminal arg.
    # ${DERIVED_FILE_DIR}: /Users/jamie/Library/Developer/Xcode/DerivedData/wry-ios-fcjgozzuzcgfyxfffiscczkzobog/Build/Intermediates.noindex/Pods.build/debug-iphonesimulator/wry-iOS.build/DerivedSources
    # ${BUILT_PRODUCTS_DIR}: /Users/jamie/Library/Developer/Xcode/DerivedData/wry-ios-fcjgozzuzcgfyxfffiscczkzobog/Build/Products/debug-iphonesimulator/wry-iOS
    # See: https://apple.stackexchange.com/questions/360653/how-to-configure-xcode-external-build-system-to-build-and-clean-using-standard-s
    :script => <<-CMD
echo "This is the build phase for the 'wry' pod. HOME: ${HOME}; SRCROOT: ${SRCROOT}; PWD: ${PWD}; ARCHS: ${ARCHS}; CONFIGURATION: ${CONFIGURATION:?}"
echo "Will run: \"${HOME}/.cargo/bin/cargo-apple\" xcode-script -v --platform \"${PLATFORM_DISPLAY_NAME:?}\" --sdk-root \"${SDKROOT:?}\" --configuration \"${CONFIGURATION:?}\" ${FORCE_COLOR} ${ARCHS:?}"
echo "BUILT_PRODUCTS_DIR: \"${BUILT_PRODUCTS_DIR}\""

cd "${SRCROOT}/.."

"${HOME}/.cargo/bin/cargo-apple" xcode-script -v --platform "${PLATFORM_DISPLAY_NAME:?}" --sdk-root "${SDKROOT:?}" --configuration "${CONFIGURATION:?}" ${FORCE_COLOR} ${ARCHS:?}
    CMD
  }

  # For iOS, ARCHS returns "arm64 armv7". We want just "arm64" (because cargo-mobile doesn't support armv7 for iOS, and
  # maybe in a related fashion because it's the intersection between ARCHS and VALID_ARCHS).
  s.ios.script_phases = [
    {
      **script_build_phase,
      # If any output_files are missing, the script will be run again.
      # I'm not sure it's possible to support looking for only the active architecture in output_files, sadly; we'll have to look for both.
      #   https://github.com/Carthage/Carthage/commit/f622fafbec25ba3aaf7acbb1ddd1da2098cde8a6
      # More info here:
      #   https://faical.dev/articles/write-your-build-phase-scripts-in-swift.html
      :output_files => [
        # /Users/jamie/Documents/git/wry-ios-poc-new/target/aarch64-apple-ios/debug/libwry_ios.a
        # /Users/jamie/Documents/git/wry-ios-poc-new/target/x86_64-apple-ios/debug/libwry_ios.a
        '$(SRCROOT)/../../target/aarch64-apple-ios/$(CONFIGURATION)/libwry_ios.a',
        '$(SRCROOT)/../../target/x86_64-apple-ios/$(CONFIGURATION)/libwry_ios.a'
      ],
    }
  ]

  # For macOS, ARCHS returns "arm64 x86_64". I haven't tried running this for macOS yet, so haven't seen whether this needs restricting.
  s.osx.script_phases = [
    {
      **script_build_phase,
      :output_files => [
        # /Users/jamie/Documents/git/wry-ios-poc-new/target/x86_64-apple-darwin/debug/libwry_ios.a
        '$(SRCROOT)/../../target/x86_64-apple-darwin/$(CONFIGURATION)/libwry_ios.a'
      ],
    }
  ]

  s.info_plist = {
    'Additional licenses' => 'MIT - See LICENSE-MIT',
  }

end