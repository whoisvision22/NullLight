# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'
require_relative '../native/macos/updater'
def assert(condition, message)
  raise message unless condition
end
Dir.mktmpdir('nulllight-update-check-') do |root|
  # Ruby on Windows accepts /Users/... on the current drive; the updater's
  # local fixture source deliberately follows its macOS absolute-path format.
  root = root.sub(/\A[A-Za-z]:/, '') if Gem.win_platform?
  bundle = File.join(root, 'bundle'); cache = File.join(root, 'cache'); source = File.join(root, 'source')
  [bundle, source].each { |path| FileUtils.mkdir_p(path) }
  File.write(File.join(bundle, 'version.json'), JSON.generate(version: 17))
  File.write(File.join(bundle, 'update-source.json'), JSON.generate(manifest: File.join(source, 'NullLight-update.json')))
  updater = NullLightUpdater.new(bundle, cache: cache)
  publish = lambda do |version, bad_hash = false, bad_code = false|
    files = NullLightUpdater::FILES.each_with_object({}) do |name, result|
      content = name == 'version.json' ? JSON.generate(version: version) : name == 'NullLight.html' ? '<html>Update</html>' : "# valid Ruby\n"
      content = 'def broken(' if bad_code && name == 'artnet.rb'
      result[name] = { sha256: Digest::SHA256.hexdigest(content), contentBase64: Base64.strict_encode64(content) }
    end
    bytes = JSON.generate(version: version, files: files)
    filename = "NullLight-release-#{version}.json"
    File.binwrite(File.join(source, filename), bytes)
    manifest = { schema: 1, minimumBootstrap: 2, version: version, payload: filename, sha256: bad_hash ? '0' * 64 : Digest::SHA256.hexdigest(bytes) }
    File.write(File.join(source, 'NullLight-update.json'), JSON.generate(manifest))
  end
  publish.call(18)
  assert(updater.check['state'] == 'available', 'Update muss angeboten werden.')
  assert(updater.cached_release[:version] == 17, 'Prüfen darf kein Update installieren.')
  assert(!File.exist?(File.join(cache, 'current.json')), 'Prüfen darf keinen Versionszeiger schreiben.')
  assert(updater.install['state'] == 'ready', 'Installation muss vorbereitet werden.')
  assert(updater.cached_release[:version] == 18, 'Vorbereitete Version fehlt.')
  publish.call(19, true)
  assert(updater.install['state'] == 'error', 'Falsche Prüfsumme muss abgelehnt werden.')
  assert(updater.cached_release[:version] == 18, 'Fehler darf vorhandene Version nicht ersetzen.')
  publish.call(19, false, true)
  assert(updater.install['state'] == 'error', 'Ungültiger Ruby-Code muss abgelehnt werden.')
  assert(updater.cached_release[:version] == 18, 'Ungültiger Code darf nicht aktiv werden.')
  File.unlink(File.join(source, 'NullLight-update.json'))
  assert(updater.check['state'] == 'unavailable', 'Offline-Quelle muss gemeldet werden.')
  assert(updater.cached_release[:version] == 18, 'Offline-Start muss vorbereitetes Update verwenden.')
  selected = updater.cached_release[:path]
  File.write(File.join(selected, 'artnet.rb'), '# modified')
  assert(updater.cached_release[:version] == 17, 'Beschädigter Cache muss auf die mitgelieferte Version zurückfallen.')
  begin
    updater.read_bytes('https://example.com/update.json')
    raise 'Fremde Download-Hosts wurden akzeptiert.'
  rescue ArgumentError
    # Expected: source and redirected downloads are bounded to the trusted host set.
  end
end
puts 'Passed: check/install separation, SHA-256 rejection, Ruby validation, offline start, cache fallback and host restrictions.'
