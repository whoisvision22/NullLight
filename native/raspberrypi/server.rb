# frozen_string_literal: true
require 'fileutils'
require_relative '../macos/artnet'

# A stable key lets bookmarks survive service restarts. Do not put it in Git.
root = File.expand_path('../..', __dir__)
state = ENV['NULLLIGHT_STATE_DIR'] || File.join(Dir.home, '.local', 'state', 'nulllight')
FileUtils.mkdir_p(state, mode: 0700)
key_path = File.join(state, 'session.key')
unless File.exist?(key_path)
  File.open(key_path, File::WRONLY | File::CREAT | File::EXCL, 0600) { |file| file.write(SecureRandom.hex(32)) }
end
token = File.read(key_path).strip
raise 'Ungültiger Sitzungsschlüssel.' unless token.match?(/\A[a-f0-9]{64}\z/)
port = Integer(ENV.fetch('NULLLIGHT_PORT', '49365'))
raise 'Ungültiger HTTP-Port.' unless port.between?(1024, 65_535)
bind = ENV.fetch('NULLLIGHT_BIND', '127.0.0.1')
raise 'Bind-Adresse muss IPv4 sein.' unless IPAddr.new(bind).ipv4?
ArtNet.run(File.join(root, 'app', 'NullLight.html'), bind: bind, port: port, token: token, platform: 'raspberrypi')
