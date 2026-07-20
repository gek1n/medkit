Pod::Spec.new do |s|
  s.name             = 'medkit_db_key_storage'
  s.version          = '1.0.0'
  s.summary          = 'Internal: minimal direct-Keychain storage for the local DB encryption key.'
  s.description      = <<-DESC
Internal MedKit plugin. Direct SecItemAdd/SecItemCopyMatching/SecItemDelete
wrapper for exactly one Keychain item, with a single fixed attribute set.
Not for general use outside this app.
                       DESC
  s.homepage         = 'https://ellyapp.com'
  s.license          = { :type => 'Private' }
  s.author           = { 'MedKit' => 'noreply@ellyapp.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
