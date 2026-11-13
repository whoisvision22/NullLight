# frozen_string_literal: true
require 'socket'
require 'ipaddr'
require 'json'
require 'securerandom'
require 'webrick'
require_relative 'routing'
require_relative 'updater'

module ArtNet
  PORT = 6454
  ID = "Art-Net\0".b.freeze

  # Passive Pro DJ Link beat reception; no virtual player or commands are sent.
  # Layout: https://djl-analysis.deepsymmetry.org/djl-analysis/beats.html
  class DJLink
    MAGIC = 'Qspt1WmJOL'.b.freeze

    def self.parse(packet)
      return nil unless packet.bytesize == 96 && packet[0, 10] == MAGIC &&
        packet.getbyte(10) == 0x28 && packet.getbyte(32) == 0 && packet[34, 2].unpack('n')[0] == 60
      player = packet.getbyte(33)
      beat = packet.getbyte(92)
      pitch = packet[85, 3].unpack('C3').inject(0) { |value, byte| (value << 8) | byte }
      raw_bpm = packet[90, 2].unpack('n')[0]
      bpm = raw_bpm * pitch / 104857600.0
      return nil unless player.between?(1, 6) && beat.between?(1, 4) &&
        raw_bpm != 65_535 && pitch.between?(1, 2_097_152) && bpm.between?(30, 300)
      { player: player, beat: beat, bpm: bpm.round(2), name: packet[11, 20].delete("\0").force_encoding('UTF-8').scrub }
    end

    def initialize
      @lock = Mutex.new
      @sequence = 0
      @error = nil
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def status
      @lock.synchronize { status_unlocked }
    end

    def status_unlocked
      { enabled: !!@socket, connected: !!(@socket && @last && now - @last < 3),
        sequence: @sequence, selectedPlayer: @player || 0, device: @device, error: @error }
    end

    def enable(input)
      player = input.fetch('player')
      raise ArgumentError, 'Player muss zwischen 0 (erster aktiver Player) und 6 liegen.' unless player.is_a?(Integer) && player.between?(0, 6)
      @lock.synchronize do
        @socket.close if @socket
        @socket = nil
        @last = @device = nil
        @error = nil
        @player = player
        socket = UDPSocket.new
        begin
          socket.bind('0.0.0.0', 50_001)
          @socket = socket
        rescue SystemCallError
          socket.close
          raise
        end
        status_unlocked
      end
    end

    def stop
      @lock.synchronize do
        @socket.close if @socket
        @socket = nil
        @last = @device = nil
        status_unlocked
      end
    end

    def receive(packet, ip)
      value = DJLink.parse(packet)
      return unless value && (@player == 0 || @player == value[:player])
      # Lock to one IP/player while its beat stream is alive; never mix two decks.
      return if @last && now - @last < 3 && @device && [@device[:ip], @device[:player]] != [ip, value[:player]]
      return if @last && now - @last < 0.08
      @last = now
      @device = value.merge(ip: ip)
      @sequence += 1
    end

    def tick
      @lock.synchronize do
        return unless @socket
        64.times do
          incoming = @socket.recvfrom_nonblock(2048, exception: false)
          break if incoming == :wait_readable
          packet, peer = incoming
          receive(packet, peer[3])
        end
      rescue SystemCallError, IOError => error
        @socket.close if @socket && !@socket.closed?
        @socket = nil
        @error = "Pro DJ Link unterbrochen: #{error.message}"
      end
    end
  end

  def self.dmx(channels, address, sequence)
    raise ArgumentError, '512 ganzzahlige Kanalwerte von 0 bis 255 erforderlich.' unless
      channels.is_a?(Array) && channels.length == 512 &&
      channels.all? { |value| value.is_a?(Integer) && value.between?(0, 255) }
    ID + [0x5000].pack('v') + [14].pack('n') +
      [sequence, 0, address & 255, (address >> 8) & 127].pack('C4') +
      [512].pack('n') + channels.pack('C*')
  end

  def self.poll
    ID + [0x2000].pack('v') + [14, 0, 0].pack('nCC')
  end

  def self.subscriber?(packet, address)
    return false unless packet.bytesize >= 194 && packet[0, 8] == ID &&
      packet[8, 2].unpack('v')[0] == 0x2100
    net = packet.getbyte(18) & 127
    subnet = packet.getbyte(19) & 15
    count = [packet[172, 2].unpack('n')[0], 4].min
    count.times.any? do |index|
      output = packet.getbyte(174 + index) & 128 != 0
      artnet = packet.getbyte(182 + index) & 1 == 0
      port_address = (net << 8) | (subnet << 4) | (packet.getbyte(190 + index) & 15)
      output && artnet && port_address == address
    end
  end

  def self.interfaces
    Socket.getifaddrs.each_with_object([]) do |item, result|
      next unless item.addr && item.addr.ipv4?
      result << { name: item.name, ip: item.addr.ip_address }
    end.uniq
  end

  def self.config(input)
    target = IPAddr.new(input.fetch('target'))
    raise ArgumentError, 'Bitte eine IPv4-Unicast-Adresse eingeben.' unless target.ipv4? &&
      target.to_i > 0 && target.to_i < 0xe0000000 && target.to_s != '255.255.255.255'
    fields = [['net', 127], ['subnet', 15], ['universe', 15]].map do |key, max|
      value = input.fetch(key)
      raise ArgumentError, "Ungültiges Feld #{key}." unless value.is_a?(Integer) && value.between?(0, max)
      value
    end
    source = input.fetch('source')
    raise ArgumentError, 'Die gewählte Netzwerkschnittstelle ist nicht verfügbar.' unless
      interfaces.any? { |item| item[:ip] == source }
    { target: target.to_s, source: source, address: (fields[0] << 8) | (fields[1] << 4) | fields[2] }
  end

  class Sender
    def initialize
      @lock = Mutex.new
      @channels = Array.new(512, 0)
      @enabled = false
      @count = 0
      @sequence = 0
      @error = nil
      @last_frame = 0
      @last_reply = 0
      @subscriptions = {}
      @inputs = {}
      @received = 0
      @mapping = ArtNet.mapping(nil)
    end

    def status_unlocked
      { enabled: @enabled, subscribed: @enabled && output_addresses.any? { |address| subscribed?(address) },
        packets: @count, received: @received, subscribedUniverses: @subscriptions.select { |_, time| now - time < 10 }.keys, error: @error }
    end

    def status
      @lock.synchronize { status_unlocked }
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def enable(input)
      config = ArtNet.config(input)
      mapping = ArtNet.mapping(input['mapping'])
      @lock.synchronize do
        stop_unlocked
        socket = UDPSocket.new
        begin
          socket.bind(config[:source], PORT)
          @socket = socket
          @config = config
          @mapping = mapping
          @inputs = {}
          @subscriptions = {}
          @received = 0
          @channels = Array.new(512, 0)
          @enabled = true
          @error = nil
          @last_frame = now
          @last_reply = 0
          @last_poll = 0
          @count = 0
          @sequence = 0
        rescue
          socket.close
          raise
        end
        status_unlocked
      end
    end

    def frame(channels)
      # Validate before changing the frame buffer.
      ArtNet.dmx(channels, 0, 1)
      @lock.synchronize do
        @channels = channels
        @last_frame = now
        status_unlocked
      end
    end

    def send_frame(channels, address = @config[:address])
      @sequence = (@sequence % 255) + 1
      @socket.send(ArtNet.dmx(channels, address, @sequence), 0, @config[:target], PORT)
      @count += 1
    end

    def stop_unlocked
      if @enabled && @socket
        begin
          output_addresses.each do |address|
            3.times { send_frame(Array.new(512, 0), address) } if subscribed?(address)
          end
        rescue SystemCallError, IOError
          # The socket is still closed below if the network disappeared.
        end
      end
      @socket.close if @socket && !@socket.closed?
      @socket = nil
      @enabled = false
      @last_reply = 0
    end

    def stop
      @lock.synchronize { stop_unlocked; status_unlocked }
    end

    def output_addresses
      [@config[:address], *(@mapping['artnet']['enabled'] ? @mapping['artnet']['routes'].map { |route| route['targetUniverse'] } : [])].uniq
    end

    def subscribed?(address)
      @subscriptions.key?(address) && now - @subscriptions[address] < 10
    end

    def set_mapping(input)
      mapping = ArtNet.mapping(input)
      @lock.synchronize do
        old_addresses = @enabled ? output_addresses : []
        if @enabled
          new_addresses = [@config[:address], *(mapping['artnet']['enabled'] ? mapping['artnet']['routes'].map { |route| route['targetUniverse'] } : [])].uniq
          (old_addresses - new_addresses).each do |address|
            3.times { send_frame(Array.new(512, 0), address) } if subscribed?(address)
          end
        end
        @mapping = mapping
        @inputs.clear
        status_unlocked
      end
    end

    def receive_packet(packet, peer)
      ip = peer[3]
      if packet.bytesize >= 10 && packet[0, 8] == ID && packet[8, 2].unpack('v')[0] == 0x2100
        return unless ip == @config[:target]
        ArtNet.subscriptions(packet).each { |address| @subscriptions[address] = now }
        @last_reply = now if output_addresses.any? { |address| subscribed?(address) }
        return
      end
      return unless @mapping['artnet']['enabled'] && ip != @config[:source]
      incoming = ArtNet.read_dmx(packet)
      return unless incoming
      return unless @mapping['artnet']['routes'].any? do |route|
        route['sourceUniverse'] == incoming[:address] && (route['sourceIP'].empty? || route['sourceIP'] == ip)
      end
      key = [ip, incoming[:address]]
      old = @inputs[key]
      if old && now - old[:time] < 2.5 && incoming[:sequence] != 0 && old[:sequence] != 0
        distance = (incoming[:sequence] - old[:sequence]) & 255
        return unless distance.between?(1, 127)
      end
      @inputs[key] = incoming.merge(time: now)
      @received += 1
    end

    def mapped_frames
      frames = { @config[:address] => ArtNet.remap_dmx(@channels, @mapping) }
      return frames unless @mapping['artnet']['enabled']
      @mapping['artnet']['routes'].each do |route|
        destination = (frames[route['targetUniverse']] ||= Array.new(512, 0))
        # The newest eligible sender wins each explicitly mapped range.
        candidates = @inputs.select do |(ip, address), record|
          address == route['sourceUniverse'] && (route['sourceIP'].empty? || route['sourceIP'] == ip) && now - record[:time] < 2.5
        end
        source = candidates.values.max_by { |record| record[:time] }
        values = source ? source[:channels][route['sourceChannel'] - 1, route['count']] : Array.new(route['count'], 0)
        destination[route['targetChannel'] - 1, route['count']] = values
      end
      frames
    end

    def tick
      @lock.synchronize do
        return unless @enabled
        if now - @last_frame > 3
          stop_unlocked
          @error = 'Die Bedienoberfläche antwortet nicht. Ausgabe gestoppt.'
          return
        end
        if now - @last_poll >= 2.5
          @socket.send(ArtNet.poll, 0, @config[:target], PORT)
          @last_poll = now
        end
        20.times do
          incoming = @socket.recvfrom_nonblock(4096, exception: false)
          break if incoming == :wait_readable
          packet, peer = incoming
          receive_packet(packet, peer)
        end
        mapped_frames.each { |address, frame| send_frame(frame, address) if subscribed?(address) }
      rescue SystemCallError, IOError => error
        stop_unlocked
        @error = "Art-Net-Verbindung unterbrochen: #{error.message}"
      end
    end
  end

  # Commands are acknowledged by the active UI, never reported as executed on enqueue.
  class RemoteControl
    def initialize
      @lock = Mutex.new
      @changed = ConditionVariable.new
      @queue = []
      @results = {}
      @state = nil
      @last = 0
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def status
      @lock.synchronize { { connected: now - @last < 2, ui: @state } }
    end

    def poll(input)
      @lock.synchronize do
        state = input.fetch('state')
        raise ArgumentError, 'Ungültiger Bedienstatus.' unless state.is_a?(Hash)
        @state = state
        @last = now
        ack = input['ack']
        if ack.is_a?(Hash) && @results.key?(ack['id'])
          @results[ack['id']] = ack
          @changed.broadcast
        end
        command = @queue.shift
        { command: command }
      end
    end

    def command(input)
      action = input.fetch('action')
      args = input.fetch('args', {})
      raise ArgumentError, 'Unbekannter Steuerbefehl.' unless %w[play_scene blackout stop set_master].include?(action) && args.is_a?(Hash)
      if action == 'play_scene'
        raise ArgumentError, 'Szenen-ID fehlt.' unless args['sceneId'].is_a?(String) && args['sceneId'].match?(/\A[-a-zA-Z0-9]+\z/)
      elsif action == 'set_master'
        raise ArgumentError, 'Helligkeit muss zwischen 0 und 100 liegen.' unless args['level'].is_a?(Numeric) && args['level'].between?(0, 100)
      end
      @lock.synchronize do
        raise ArgumentError, 'Keine aktive Bedienoberfläche.' unless now - @last < 2
        raise ArgumentError, 'MCP-Fernsteuerung in Verbindung aktivieren.' unless @state && @state['remoteEnabled'] == true
        raise ArgumentError, 'Zu viele ausstehende Befehle.' if @results.length >= 8
        id = SecureRandom.hex(12)
        @results[id] = nil
        @queue << { id: id, action: action, args: args }
        deadline = now + 4
        begin
          while !@results[id] && now < deadline
            @changed.wait(@lock, deadline - now)
          end
          raise ArgumentError, 'Keine Ausführungsbestätigung von der Bedienoberfläche.' unless @results[id]
          @results[id]
        ensure
          @results.delete(id)
          @queue.reject! { |item| item[:id] == id }
        end
      end
    end
  end

  def self.run(page_path, bind: '127.0.0.1', port: 49365, token: SecureRandom.hex(32), platform: 'mac')
    sender = Sender.new
    dj = DJLink.new
    control = RemoteControl.new
    bundle_resources = ENV['NULLLIGHT_BUNDLE_RESOURCES'] || File.dirname(page_path)
    begin
      updates = platform == 'mac' ? NullLightUpdater.new(bundle_resources, cache: ENV['NULLLIGHT_UPDATE_CACHE_DIR']) : nil
    rescue StandardError
      updates = nil
    end
    begin
      running_version = JSON.parse(File.read(File.join(File.dirname(page_path), 'version.json'))).fetch('version')
    rescue StandardError
      running_version = JSON.parse(File.read(File.expand_path('../version.json', File.dirname(page_path)))).fetch('version') rescue 0
    end
    update_status = lambda do
      info = updates ? updates.status : { 'state' => 'unavailable', 'message' => 'Update-Quelle nicht erreichbar.' }
      if ENV['NULLLIGHT_UPDATE_FAILED'] == '1'
        info = info.merge('state' => 'error', 'message' => 'Das Update konnte nicht starten. Die mitgelieferte Version wurde gestartet.')
      end
      info.merge('runningVersion' => running_version)
    end
    server = WEBrick::HTTPServer.new(
      BindAddress: bind, Port: port,
      Logger: WEBrick::Log.new(File::NULL), AccessLog: [],
      RequestTimeout: 5, MaxClients: 8
    )
    origin = "http://#{bind == '0.0.0.0' ? '127.0.0.1' : bind}:#{port}"
    hosts = ['127.0.0.1', 'localhost', Socket.gethostname, Socket.gethostname + '.local', *interfaces.map { |item| item[:ip] }].map { |host| "#{host}:#{port}" }
    server.mount_proc('/') do |request, response|
      response['Cache-Control'] = 'no-store'
      response['X-Content-Type-Options'] = 'nosniff'
      response['Referrer-Policy'] = 'no-referrer'
      response['Content-Type'] = 'application/json; charset=utf-8'
      begin
        raise ArgumentError, 'Zugriff abgelehnt.' unless hosts.include?(request['host'])
        if request.path == '/' && request.request_method == 'GET' && request.query['session'] == token
          response['Content-Type'] = 'text/html; charset=utf-8'
          response['Content-Security-Policy'] = "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; img-src 'self' blob: data:; frame-ancestors 'none'"
          response.body = File.read(page_path, encoding: 'UTF-8').sub('/* NATIVE_SESSION */', "window.lichtpultSession = #{JSON.generate(token)}; window.lichtpultPlatform = #{JSON.generate(platform)};")
          next
        end
        raise ArgumentError, 'Zugriff abgelehnt.' unless request['x-lichtpult-session'] == token
        raise ArgumentError, 'Fremder Ursprung.' if request['origin'] && request['origin'] != "http://#{request['host']}"
        if request.path == '/api/update/status' && request.request_method == 'GET'
          response.body = JSON.generate(update_status.call)
          next
        end
        if request.path == '/api/dj/status' && request.request_method == 'GET'
          response.body = JSON.generate(dj.status)
          next
        end
        if request.path == '/api/control/status' && request.request_method == 'GET'
          response.body = JSON.generate(control.status.merge(output: sender.status, dj: dj.status))
          next
        end
        if request.path == '/api/status' && request.request_method == 'GET'
          response.body = JSON.generate(sender.status.merge(interfaces: interfaces, platform: platform, dj: dj.status, update: update_status.call))
          next
        end
        raise ArgumentError, 'Ungültige Anfrage.' unless request.request_method == 'POST' &&
          request['content-type'].to_s.start_with?('application/json') &&
          request.body.to_s.bytesize <= (request.path == '/api/control/poll' ? 262_144 : 16_384)
        input = JSON.parse(request.body)
        raise ArgumentError, 'JSON-Objekt erforderlich.' unless input.is_a?(Hash)
        result = case request.path
                 when '/api/enable' then sender.enable(input)
                 when '/api/frame' then sender.frame(input.fetch('channels'))
                 when '/api/stop' then sender.stop
                 when '/api/mapping' then sender.set_mapping(input.fetch('mapping'))
                 when '/api/dj/enable' then dj.enable(input)
                 when '/api/dj/stop' then dj.stop
                 when '/api/control/poll' then control.poll(input)
                 when '/api/control' then control.command(input)
                 when '/api/update/start'
                   updates.start_install if updates
                   update_status.call
                 when '/api/update/cancel'
                   updates.cancel_install if updates
                   update_status.call
                 when '/api/update/install'
                   updates.install if updates
                   update_status.call
                 when '/api/update/check'
                   updates.check if updates
                   update_status.call
                 else raise ArgumentError, 'Unbekannte Funktion.'
                 end
        response.body = JSON.generate(result)
      rescue ArgumentError, KeyError, JSON::ParserError, IPAddr::InvalidAddressError, SystemCallError => error
        response.status = 400
        response.body = JSON.generate(error: error.message)
      end
    end
    parent_pid = Process.ppid
    running = true
    worker = Thread.new do
      while running
        begin
          Process.kill(0, parent_pid)
        rescue Errno::ESRCH
          server.shutdown
          break
        end
        sender.tick
        dj.tick
        sleep(1.0 / 30)
      end
    end
    %w[TERM INT].each { |signal| trap(signal) { server.shutdown } }
    puts "#{origin}/?session=#{token}"
    STDOUT.flush
    begin
      server.start
    ensure
      running = false
      worker.join
      sender.stop
      dj.stop
    end
  end
end

ArtNet.run(ARGV.fetch(0)) if $PROGRAM_NAME == __FILE__
