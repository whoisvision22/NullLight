# frozen_string_literal: true
require 'json'
require 'base64'
require 'digest'
require 'fileutils'
require 'tmpdir'
require 'securerandom'
require 'time'
require 'open3'

class NullLightUpdater
  BOOTSTRAP = 1
  FILES = %w[NullLight.html artnet.rb routing.rb scene_ai.rb updater.rb version.json].freeze
  MAX_BYTES = 8 * 1024 * 1024

  def initialize(bundle, cache: nil)
    @bundle = File.expand_path(bundle)
    @cache = cache || File.join(Dir.home, 'Library', 'Application Support', 'NullLight', 'Updates')
    config = JSON.parse(File.read(File.join(@bundle, 'update-source.json')))
    @source = config.fetch('manifest')
    raise ArgumentError, 'Die lokale Update-Quelle ist ungültig.' unless @source.is_a?(String) && @source.start_with?('/')
    @bundle_version = JSON.parse(File.read(File.join(@bundle, 'version.json'))).fetch('version')
    raise ArgumentError, 'Ungültige App-Version.' unless @bundle_version.is_a?(Integer)
    FileUtils.mkdir_p(@cache, mode: 0700)
  end

  def read_json(path)
    raise ArgumentError, 'Die Update-Datei ist zu groß.' if File.size(path) > MAX_BYTES
    JSON.parse(File.read(path, encoding: 'UTF-8'))
  end

  def atomic_json(path, value)
    temporary = path + '.tmp-' + SecureRandom.hex(6)
    begin
      File.open(temporary, 'wb', 0600) do |file|
        file.write(JSON.generate(value))
        file.flush
        file.fsync
      end
      File.rename(temporary, path)
    ensure
      File.unlink(temporary) if File.exist?(temporary)
    end
  end

  def cached_release
    pointer = read_json(File.join(@cache, 'current.json'))
    name = pointer.fetch('directory')
    raise ArgumentError, 'Ungültiger Update-Pfad.' unless name.is_a?(String) && name.match?(/\A\d+-[a-f0-9]{12}\z/)
    path = File.join(@cache, name)
    metadata = read_json(File.join(path, 'release.json'))
    raise ArgumentError, 'Unvollständige Update-Version.' unless metadata.fetch('files').keys.sort == FILES.sort
    metadata['files'].each do |filename, checksum|
      file = File.join(path, filename)
      raise ArgumentError, 'Die Update-Dateien wurden verändert.' unless File.file?(file) && !File.symlink?(file) && Digest::SHA256.file(file).hexdigest == checksum
    end
    version = JSON.parse(File.read(File.join(path, 'version.json'))).fetch('version')
    raise ArgumentError, 'Widersprüchliche Update-Version.' unless version.is_a?(Integer) && version == pointer['version'] && version == metadata['version']
    return { path: @bundle, version: @bundle_version } if version <= @bundle_version
    { path: path, version: version }
  rescue Errno::ENOENT, JSON::ParserError, KeyError, ArgumentError
    { path: @bundle, version: @bundle_version }
  end

  def status
    result = read_json(File.join(@cache, 'status.json'))
    result.merge('source' => @source)
  rescue Errno::ENOENT, JSON::ParserError, ArgumentError
    { 'state' => 'unchecked', 'version' => cached_release[:version], 'source' => @source }
  end

  def check
    File.open(File.join(@cache, 'update.lock'), File::RDWR | File::CREAT, 0600) do |lock|
      lock.flock(File::LOCK_EX)
      current = cached_release
      begin
        manifest = read_json(@source)
        raise ArgumentError, 'Dieses Update benötigt eine neuere Mac-App.' unless manifest['schema'] == 1 &&
          manifest['minimumBootstrap'].is_a?(Integer) && manifest['minimumBootstrap'] <= BOOTSTRAP
        version = manifest.fetch('version')
        raise ArgumentError, 'Ungültige Update-Version.' unless version.is_a?(Integer) && version > 0
        result = if version > current[:version]
                   stage_release(manifest)
                   { 'state' => 'ready', 'version' => version, 'message' => 'Update geladen. Beim nächsten App-Start wird es verwendet.' }
                 else
                   { 'state' => 'current', 'version' => current[:version], 'message' => 'NullLight ist aktuell.' }
                 end
      rescue Errno::ENOENT
        result = { 'state' => 'unavailable', 'version' => current[:version], 'message' => 'Der Projektordner ist nicht erreichbar. Die vorhandene Version startet weiter.' }
      rescue StandardError => error
        result = { 'state' => 'error', 'version' => current[:version], 'message' => "Update nicht übernommen: #{error.message}" }
      end
      result['checkedAt'] = Time.now.utc.iso8601
      atomic_json(File.join(@cache, 'status.json'), result)
      result.merge('source' => @source)
    end
  end

  def stage_release(manifest)
    filename = manifest.fetch('payload')
    checksum = manifest.fetch('sha256')
    version = manifest.fetch('version')
    raise ArgumentError, 'Ungültiger Paketname.' unless filename.is_a?(String) && filename.match?(/\ANullLight-release-\d+\.json\z/)
    raise ArgumentError, 'Ungültige Prüfsumme.' unless checksum.is_a?(String) && checksum.match?(/\A[a-f0-9]{64}\z/)
    payload_path = File.join(File.dirname(@source), filename)
    raise ArgumentError, 'Das Update-Paket ist zu groß.' if File.size(payload_path) > MAX_BYTES
    bytes = File.binread(payload_path)
    raise ArgumentError, 'Die Prüfsumme des Updates stimmt nicht.' unless Digest::SHA256.hexdigest(bytes) == checksum
    payload = JSON.parse(bytes)
    raise ArgumentError, 'Widersprüchliche Paketversion.' unless payload['version'] == version
    files = payload.fetch('files')
    raise ArgumentError, 'Unvollständiges Update.' unless files.is_a?(Hash) && files.keys.sort == FILES.sort
    staged = Dir.mktmpdir('staging-', @cache)
    begin
      hashes = {}
      files.each do |name, item|
        content = Base64.strict_decode64(item.fetch('contentBase64'))
        digest = Digest::SHA256.hexdigest(content)
        raise ArgumentError, "Ungültige Datei #{name}." unless item['sha256'] == digest
        File.open(File.join(staged, name), 'wb', 0600) do |file|
          file.write(content)
          file.flush
          file.fsync
        end
        hashes[name] = digest
      end
      %w[artnet.rb routing.rb scene_ai.rb updater.rb].each do |name|
        _, status = Open3.capture2e('/usr/bin/ruby', '-c', File.join(staged, name))
        raise ArgumentError, "Die Programmprüfung für #{name} ist fehlgeschlagen." unless status.success?
      end
      file_version = JSON.parse(File.read(File.join(staged, 'version.json'))).fetch('version')
      raise ArgumentError, 'Widersprüchliche Programmversion.' unless file_version == version
      atomic_json(File.join(staged, 'release.json'), { 'version' => version, 'files' => hashes })
      directory = "#{version}-#{checksum[0, 12]}"
      destination = File.join(@cache, directory)
      if File.exist?(destination)
        # Preserve any earlier candidate. Never run an unverified existing directory.
        directory += SecureRandom.hex(2)
        directory = "#{version}-#{Digest::SHA256.hexdigest(directory)[0, 12]}"
        destination = File.join(@cache, directory)
      end
      File.rename(staged, destination)
      atomic_json(File.join(@cache, 'current.json'), { 'version' => version, 'directory' => directory })
    ensure
      FileUtils.remove_entry_secure(staged) if File.directory?(staged)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  updater = NullLightUpdater.new(ARGV.fetch(0), cache: ENV['NULLLIGHT_UPDATE_CACHE_DIR'])
  updater.check
  puts JSON.generate(updater.cached_release)
end
