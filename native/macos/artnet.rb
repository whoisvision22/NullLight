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

  def self.run(page_path)
    token = SecureRandom.hex(32)
    sender = Sender.new
    bundle_resources = ENV['NULLLIGHT_BUNDLE_RESOURCES'] || File.dirname(page_path)
    begin
      updates = NullLightUpdater.new(bundle_resources, cache: ENV['NULLLIGHT_UPDATE_CACHE_DIR'])
    rescue StandardError
      updates = nil
    end
    begin
      running_version = JSON.parse(File.read(File.join(File.dirname(page_path), 'version.json'))).fetch('version')
    rescue StandardError
      running_version = 0
    end
    update_status = lambda do
      info = updates ? updates.status : { 'state' => 'unavailable', 'message' => 'Update-Quelle nicht erreichbar.' }
      if ENV['NULLLIGHT_UPDATE_FAILED'] == '1'
        info = info.merge('state' => 'error', 'message' => 'Das Update konnte nicht starten. Die mitgelieferte Version wurde gestartet.')
      end
      info.merge('runningVersion' => running_version)
    end
    server = WEBrick::HTTPServer.new(
      BindAddress: '127.0.0.1', Port: 49365,
      Logger: WEBrick::Log.new(File::NULL), AccessLog: [],
      RequestTimeout: 5, MaxClients: 8
    )
    origin = 'http://127.0.0.1:49365'
    server.mount_proc('/') do |request, response|
      response['Cache-Control'] = 'no-store'
      response['X-Content-Type-Options'] = 'nosniff'
      response['Referrer-Policy'] = 'no-referrer'
      response['Content-Type'] = 'application/json; charset=utf-8'
      begin
        raise ArgumentError, 'Zugriff abgelehnt.' unless request['host'] == '127.0.0.1:49365'
        if request.path == '/' && request.request_method == 'GET' && request.query['session'] == token
          response['Content-Type'] = 'text/html; charset=utf-8'
          response['Content-Security-Policy'] = "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; img-src 'self' blob: data:; frame-ancestors 'none'"
          response.body = File.read(page_path, encoding: 'UTF-8').sub('/* NATIVE_SESSION */', "window.lichtpultSession = #{JSON.generate(token)};")
          next
        end
        raise ArgumentError, 'Zugriff abgelehnt.' unless request['x-lichtpult-session'] == token
        if request.path == '/api/status' && request.request_method == 'GET'
          response.body = JSON.generate(sender.status.merge(interfaces: interfaces, update: update_status.call))
          next
        end
        raise ArgumentError, 'Ungültige Anfrage.' unless request.request_method == 'POST' &&
          request['content-type'].to_s.start_with?('application/json') &&
          request.body.to_s.bytesize <= 16_384
        input = JSON.parse(request.body)
        result = case request.path
                 when '/api/enable' then sender.enable(input)
                 when '/api/frame' then sender.frame(input.fetch('channels'))
                 when '/api/stop' then sender.stop
                 when '/api/mapping' then sender.set_mapping(input.fetch('mapping'))
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
    end
  end
end

ArtNet.run(ARGV.fetch(0)) if $PROGRAM_NAME == __FILE__
