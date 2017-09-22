Pod::Spec.new do |s|
  s.name     = 'MCUIImageAdvanced'
  s.version  = '1.1.2'
  s.license  = 'BSD 3-Clause'
  s.summary  = 'Advanced and powerful functionality enhancements to UIImage.'
  s.homepage = 'https://github.com/mirego/MCUIImageAdvanced'
  s.authors  = { 'Mirego, Inc.' => 'info@mirego.com' }
  s.source   = { :git => 'https://github.com/mirego/MCUIImageAdvanced.git', :tag => s.version.to_s }
  s.source_files = 'MCUIImageAdvanced/*.{h,m}', 'MCUIImageAdvanced/ShrinkPNG/*.{h,m}', 'MCUIImageAdvanced/MGImageUtilities/*.{h,m}'
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.tvos.deployment_target = '9.0'
end
