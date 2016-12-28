Pod::Spec.new do |s|

s.name         = "WZYCamera"
s.version      = "1.0.0"
s.summary      = "WZYCamera is a lightweight custom camera controller. A line of code integration, bid farewell to invoke complex system API distress."
s.description  = <<-DESC
WZYCamera is a lightweight custom camera controller. A line of code integration, bid farewell to invoke complex system API distress.
DESC
s.homepage     = "https://github.com/CoderZYWang/WZYCamera"
s.license      = "MIT"
s.author             = { "CoderZYWang" => "294250051@qq.com" }
s.social_media_url   = "http://blog.csdn.net/felicity294250051"
s.platform     = :ios
s.source       = { :git => "https://github.com/CoderZYWang/WZYCamera.git", :tag => "1.0.0" }
s.source_files  = "WZYCamera/*.{h,m}"
s.frameworks = 'UIKit', 'Foundation','AVFoundation','AssetsLibrary','CoreMotion'
s.requires_arc = true

end