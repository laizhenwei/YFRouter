Pod::Spec.new do |s|
  s.name             = 'YFRouter'
  s.version          = '0.1.1'
  s.summary          = 'A iOS Router Component'
  s.description      = <<-DESC
                       YFRouter is a part of YFKit，
                       DESC
  s.homepage         = 'https://github.com/laichanwai/YFRouter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'laizw' => 'i@laizw.cn' }
  s.source           = { :git => 'https://github.com/laichanwai/YFRouter.git', :tag => s.version }
  s.ios.deployment_target = '8.0'
  s.source_files = 'YFRouter', 'YFRouter/*.{h,m}'
  s.dependency 'YFLog'
end
