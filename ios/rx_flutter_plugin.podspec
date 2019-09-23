#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'rx_flutter_plugin'
  s.version          = '0.0.3'
  s.summary          = 'A flutter plugin to bridge RxJava &amp; RxSwift to Dart streams.'
  s.description      = <<-DESC
A flutter plugin to bridge RxJava &amp; RxSwift to Dart streams.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'tenko' => 'keithle888@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'RxSwift', '~> 5.0'

  s.ios.deployment_target = '8.0'
end

