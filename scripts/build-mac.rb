# frozen_string_literal: true
require 'json'
require 'base64'
require 'digest'
require 'fileutils'
require 'webrick'

root = File.expand_path('..', __dir__)
Dir.chdir(root)
version = JSON.parse(File.read('version.json')).fetch('version')
raise 'Ungültige Version.' unless version.is_a?(Integer) && version > 0
out = File.join(root, 'dist')
FileUtils.mkdir_p(out)
app = File.join(out, 'NullLight.app')
# Only this generated bundle is replaced. Cached installed versions remain untouched.
FileUtils.rm_rf(app)
raise 'Mac-App konnte nicht erstellt werden.' unless system('/usr/bin/osacompile', '-l', 'JavaScript', '-s', '-o', app, 'native/macos/launcher.js')
resources = File.join(app, 'Contents', 'Resources')
files = { 'NullLight.html' => File.binread('app/NullLight.html'), 'version.json' => JSON.generate(version: version) }
%w[artnet.rb routing.rb scene_ai.rb updater.rb].each { |name| files[name] = File.binread(File.join('native/macos', name)) }
files.each { |name, content| File.binwrite(File.join(resources, name), content) }
File.write(File.join(resources, 'update-source.json'), JSON.generate(manifest: 'https://github.com/whoisvision22/NullLight/releases/latest/download/NullLight-update.json'))
# Ship WEBrick with the app so the user does not need to install a gem.
webrick = $LOADED_FEATURES.find { |path| path.end_with?('/webrick.rb') }
raise 'WEBrick konnte nicht gefunden werden.' unless webrick
vendor = File.join(resources, 'vendor')
FileUtils.mkdir_p(vendor)
FileUtils.cp(webrick, vendor)
FileUtils.cp_r(File.join(File.dirname(webrick), 'webrick'), vendor)
plist = File.join(app, 'Contents', 'Info.plist')
{
  'CFBundleIdentifier' => 'de.lichtpult.macdemo',
  'CFBundleName' => 'NullLight', 'CFBundleDisplayName' => 'NullLight',
  'CFBundleVersion' => version.to_s, 'CFBundleShortVersionString' => "#{version}.0",
  'LSMinimumSystemVersion' => '12.0',
  'NSLocalNetworkUsageDescription' => 'NullLight steuert deinen Licht-Node im lokalen Netzwerk.'
}.each do |key, value|
  ok = system('/usr/bin/plutil', '-replace', key, '-string', value, plist)
  raise "Mac-Metadaten konnten nicht gesetzt werden: #{key}" unless ok
end
raise 'Signieren fehlgeschlagen.' unless system('/usr/bin/codesign', '--force', '--sign', '-', app)
raise 'Signaturprüfung fehlgeschlagen.' unless system('/usr/bin/codesign', '--verify', '--strict', app)
zip = File.join(out, "NullLight-Mac-v#{version}.zip")
raise 'Archiv konnte nicht erstellt werden.' unless system('/usr/bin/ditto', '-c', '-k', '--keepParent', app, zip)
payload = JSON.generate(version: version, files: files.transform_values { |content| { sha256: Digest::SHA256.hexdigest(content), contentBase64: Base64.strict_encode64(content) } })
filename = "NullLight-release-#{version}.json"
File.binwrite(File.join(out, filename), payload)
File.write(File.join(out, 'NullLight-update.json'), JSON.generate(schema: 1, minimumBootstrap: 2, version: version, payload: filename, sha256: Digest::SHA256.hexdigest(payload)))
puts "Mac-App und Update v#{version} gebaut: #{zip}"
