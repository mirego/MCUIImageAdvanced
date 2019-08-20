Pod::Spec.new do |s|
  s.name = 'MCUIImageAdvanced'
  s.version = '1.1.4'
  s.summary = 'Advanced and powerful functionality enhancements to UIImage.'
  s.homepage = 'https://github.com/mirego/MCUIImageAdvanced'
  s.license = 'BSD 3-Clause'
  s.authors = { 'Mirego, Inc.' => 'info@mirego.com' }
  s.source = { :git => 'https://github.com/mirego/MCUIImageAdvanced.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Mirego'

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.requires_arc = true
  s.source_files = 'MCUIImageAdvanced/**/*.{h,m}'
end
