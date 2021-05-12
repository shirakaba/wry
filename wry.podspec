# require 'toml'
# Unlike 'json', this does not come pre-installed with Ruby, so will require installing with `gem install toml`.

# See: https://github.com/jm/toml
# cargo = TOML.load_file("Cargo.toml")

Pod::Spec.new do |s|

  # s.name         = cargo['package']['name']
  # s.version      = cargo['package']['version']
  # s.summary      = cargo['package']['description']
  # s.authors      = cargo['package']['authors']

  s.name         = wry
  s.version      = '0.9.2'
  s.summary      = 'Cross-platform WebView rendering library'
  s.authors      = 'Tauri Programme within The Commons Conservancy'

  s.homepage     = "https://github.com/tauri-apps/wry"
  s.license      = { :type => "Apache-2.0", :file => "LICENSE-APACHE" }
  # The lowest versions supported by React Native; we could certainly deploy lower, though I don't know how low.
  s.platforms    = { :ios => "10.0", :osx => "10.11" }
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

  s.resources = 'src/**/*'
  s.exclude_files = 'src/**/linux', 'src/**/win32', 'src/**/winrt'

  # A bash script that will be executed after the Pod is downloaded.
  # This command can be used to create, delete and modify any file downloaded and will be ran before any paths
  # for other file attributes of the specification are collected.
  # See: https://github.com/Geal/rust_on_mobile/blob/master/InRustWeTrustKit.podspec
  s.prepare_command = <<-CMD
    BASEPATH="${PWD}"
    echo "This is the prepare_command for wry."
  CMD

  s.info_plist = {
    'Additional licenses' => 'MIT - See LICENSE-MIT',
  }

end