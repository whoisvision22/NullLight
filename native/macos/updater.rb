# frozen_string_literal: true
require 'json'
require 'base64'
require 'digest'
require 'fileutils'
require 'tmpdir'
require 'securerandom'
require 'time'
require 'open3'
require 'net/http'
require 'uri'
require 'rbconfig'

class NullLightUpdater
  BOOTSTRAP = 2
  FILES = %w[NullLight.html artnet.rb routing.rb scene_ai.rb updater.rb version.json].freeze
  MAX_BYTES = 8 * 1024 * 1024
  FEED = 'https://github.com/whoisvision22/NullLight/releases/latest/download/NullLight-update.json'
  HOSTS = %w[github.com release-assets.githubusercontent.com objects.githubusercontent.com].freeze

  def initialize(bundle, cache: nil)
    @bundle = File.expand_path(bundle)
    @cache = cache || File.join(Dir.home, 'Library', 'Application Support', 'NullLight', 'Updates')
    @source = JSON.parse(File.read(File.join(@bundle, 'update-source.json'))).fetch('manifest')
    raise ArgumentError, 'Ungültige Update-Quelle.' unless @source.is_a?(String) && (@source.start_with?('/') || @source == FEED)
    @bundle_version = JSON.parse(File.read(File.join(@bundle, 'version.json'))).fetch('version')
    raise ArgumentError, 'Ungültige App-Version.' unless @bundle_version.is_a?(Integer)
    FileUtils.mkdir_p(@cache, mode: 0700)
  end

  def read_bytes(path, redirects = 0)
    unless path.start_with?('https://')
      raise ArgumentError, 'Die Update-Datei ist zu groß.' if File.size(path) > MAX_BYTES
      return File.binread(path)
    end
    uri = URI.parse(path)
    raise ArgumentError, 'Ungültige Download-Adresse.' unless uri.scheme == 'https' && HOSTS.include?(uri.host) && (uri.port == 443) && !uri.userinfo
    raise ArgumentError, 'Zu viele Weiterleitungen.' if redirects > 5
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 15
    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'NullLight-Updater/2'
    request['Cache-Control'] = 'no-cache'
    bytes = ''.b
    redirect = nil
    http.start do |connection|
      connection.request(request) do |response|
        if response.is_a?(Net::HTTPRedirection)
          redirect = URI.join(path, response.fetch('location')).to_s
        elsif response.code == '404'
          raise Errno::ENOENT, 'Noch keine GitHub-Veröffentlichung vorhanden.'
        elsif !response.is_a?(Net::HTTPSuccess)
          raise ArgumentError, "GitHub-Download fehlgeschlagen (#{response.code})."
        else
          raise ArgumentError, 'Die Update-Datei ist zu groß.' if response['content-length'].to_i > MAX_BYTES
          response.read_body do |chunk|
            bytes << chunk
            raise ArgumentError, 'Die Update-Datei ist zu groß.' if bytes.bytesize > MAX_BYTES
          end
        end
      end
    end
    redirect ? read_bytes(redirect, redirects + 1) : bytes
  end

  def read_json(path)
    JSON.parse(read_bytes(path).force_encoding('UTF-8'))
  end

  def atomic_json(path, value)
    temporary = path + '.tmp-' + SecureRandom.hex(6)
    begin
      File.open(temporary, 'wb', 0600) { |file| file.write(JSON.generate(value)); file.flush; file.fsync }
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
    raise ArgumentError, 'Unvollständiges Update.' unless metadata.fetch('files').keys.sort == FILES.sort
    metadata['files'].each do |filename, checksum|
      file = File.join(path, filename)
      raise ArgumentError, 'Update-Dateien wurden verändert.' unless File.file?(file) && !File.symlink?(file) && Digest::SHA256.file(file).hexdigest == checksum
    end
    version = JSON.parse(File.read(File.join(path, 'version.json'))).fetch('version')
    raise ArgumentError, 'Widersprüchliche Update-Version.' unless version.is_a?(Integer) && version == pointer['version'] && version == metadata['version']
    return { path: @bundle, version: @bundle_version } if version <= @bundle_version
    { path: path, version: version }
  rescue Errno::ENOENT, JSON::ParserError, KeyError, ArgumentError
    { path: @bundle, version: @bundle_version }
  end

  def status
    read_json(File.join(@cache, 'status.json')).merge('source' => @source)
  rescue Errno::ENOENT, JSON::ParserError, ArgumentError
    { 'state' => 'unchecked', 'version' => cached_release[:version], 'source' => @source }
  end

  def manifest
    result = read_json(@source)
    raise ArgumentError, 'Dieses Update benötigt eine neuere Mac-App.' unless result['schema'] == 1 && result['minimumBootstrap'].is_a?(Integer) && result['minimumBootstrap'] <= BOOTSTRAP
    raise ArgumentError, 'Ungültige Update-Version.' unless result['version'].is_a?(Integer) && result['version'] > 0
    result
  end

  def operation
    File.open(File.join(@cache, 'update.lock'), File::RDWR | File::CREAT, 0600) do |lock|
      lock.flock(File::LOCK_EX)
      current = cached_release
      begin
        result = yield current
      rescue Errno::ENOENT
        result = { 'state' => 'unavailable', 'version' => current[:version], 'message' => 'GitHub hat noch kein Update bereitgestellt. Die vorhandene Version bleibt nutzbar.' }
      rescue StandardError => error
        result = { 'state' => 'error', 'version' => current[:version], 'message' => "Update nicht übernommen: #{error.message}" }
      end
      result['stagedVersion'] = cached_release[:version]
      result['checkedAt'] = Time.now.utc.iso8601
      atomic_json(File.join(@cache, 'status.json'), result)
      result.merge('source' => @source)
    end
  end

  def check
    operation do |current|
      remote = manifest
      newer = remote['version'] > current[:version]
      { 'state' => newer ? 'available' : 'current', 'version' => [remote['version'], current[:version]].max,
        'message' => newer ? "Version #{remote['version']} ist verfügbar." : 'NullLight ist aktuell.' }
    end
  end

  def install
    operation do |current|
      remote = manifest
      if remote['version'] > current[:version]
        stage_release(remote)
      end
      { 'state' => 'ready', 'version' => cached_release[:version], 'message' => 'Update geprüft und vorbereitet. Du kannst jetzt neu starten.' }
    end
  end

  def stage_release(manifest)
    filename, checksum, version = manifest.fetch('payload'), manifest.fetch('sha256'), manifest.fetch('version')
    raise ArgumentError, 'Ungültiger Paketname.' unless filename.is_a?(String) && filename.match?(/\ANullLight-release-\d+\.json\z/)
    raise ArgumentError, 'Ungültige Prüfsumme.' unless checksum.is_a?(String) && checksum.match?(/\A[a-f0-9]{64}\z/)
    payload_path = @source.start_with?('https://') ? URI.join(@source, filename).to_s : File.join(File.dirname(@source), filename)
    bytes = read_bytes(payload_path)
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
        File.open(File.join(staged, name), 'wb', 0600) { |file| file.write(content); file.flush; file.fsync }
        hashes[name] = digest
      end
      %w[artnet.rb routing.rb scene_ai.rb updater.rb].each do |name|
        _, status = Open3.capture2e(RbConfig.ruby, '-c', File.join(staged, name))
        raise ArgumentError, "Die Programmprüfung für #{name} ist fehlgeschlagen." unless status.success?
      end
      raise ArgumentError, 'Widersprüchliche Programmversion.' unless JSON.parse(File.read(File.join(staged, 'version.json'))).fetch('version') == version
      atomic_json(File.join(staged, 'release.json'), { 'version' => version, 'files' => hashes })
      directory = "#{version}-#{checksum[0, 12]}"
      directory = "#{version}-#{SecureRandom.hex(6)}" if File.exist?(File.join(@cache, directory))
      File.rename(staged, File.join(@cache, directory))
      atomic_json(File.join(@cache, 'current.json'), { 'version' => version, 'directory' => directory })
    ensure
      FileUtils.remove_entry_secure(staged) if File.directory?(staged)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  updater = NullLightUpdater.new(ARGV.fetch(0), cache: ENV['NULLLIGHT_UPDATE_CACHE_DIR'])
  # App launch never depends on a network request; only verified cached files are selected.
  puts JSON.generate(updater.cached_release)
end
