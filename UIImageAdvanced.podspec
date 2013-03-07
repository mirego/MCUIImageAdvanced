Pod::Spec.new do |s|
  s.name     = 'UIImageAdvanced'
  s.version  = '0.1.0'
  s.license  = 'BSD 3-Clause'
  s.summary  = 'Advanced and powerful functionality enhancements to UIImage.'
  s.homepage = 'https://github.com/mirego/UIImageAdvanced'
  s.authors  = { 'Mirego, Inc.' => 'info@mirego.com' }
  s.source   = { :git => 'https://github.com/mirego/UIImageAdvanced.git', :tag => '0.1.0' }
  s.source_files = 'UIImageAdvanced/*.{h,m}'
  s.requires_arc = true
  
  s.platform = :ios, '5.0'
end