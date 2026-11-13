# frozen_string_literal: true
require_relative '../native/macos/artnet'

def assert(condition, message)
  raise message unless condition
end

clock = 10.0
sender = ArtNet::Sender.new
sender.define_singleton_method(:now) { clock }
node = UDPSocket.new
begin
  node_ip = '127.0.0.2'
  begin
    node.bind(node_ip, ArtNet::PORT)
  rescue Errno::EADDRNOTAVAIL
    # macOS does not create additional loopback aliases by default. Bind a
    # different address owned by this same host; packets still stay local.
    node_ip = ArtNet.interfaces.map { |item| item[:ip] }.find { |ip| ip != '127.0.0.1' }
    raise 'No second local IPv4 address available for the UDP integration test.' unless node_ip
    node.bind(node_ip, ArtNet::PORT)
  end
  sender.enable('source' => '127.0.0.1', 'target' => node_ip, 'net' => 0, 'subnet' => 0, 'universe' => 0)
  channels = Array.new(512, 0); channels[0] = 255
  sender.frame(channels)
  sender.tick
  assert(IO.select([node], nil, nil, 1), 'ArtPoll fehlt.')
  poll, = node.recvfrom(2048)
  assert(poll[8, 2].unpack('v')[0] == 0x2000, 'ArtPoll-Opcode falsch.')
  reply = "\0".b * 194
  reply[0, 8] = ArtNet::ID
  reply[8, 2] = [0x2100].pack('v')
  reply[172, 2] = [1].pack('n')
  reply.setbyte(174, 128)
  node.send(reply, 0, '127.0.0.1', ArtNet::PORT)
  IO.select([sender.instance_variable_get(:@socket)], nil, nil, 1)
  sender.tick
  assert(sender.status[:subscribed], 'Node-Antwort fehlt.')
  assert(IO.select([node], nil, nil, 1), 'ArtDmx fehlt.')
  frame, = node.recvfrom(2048)
  decoded = ArtNet.read_dmx(frame)
  assert(decoded && decoded[:channels] == channels, 'ArtDmx-Kanalwerte falsch.')
  clock += 3.1
  sender.tick
  assert(!sender.status[:enabled], 'Ausgabe ohne Browser-Frames nicht gestoppt.')
  3.times do
    assert(IO.select([node], nil, nil, 1), 'Blackout-Paket fehlt.')
    blackout, = node.recvfrom(2048)
    assert(ArtNet.read_dmx(blackout)[:channels].all?(&:zero?), 'Blackout-Kanäle nicht null.')
  end
  puts 'Passed: real ArtPoll / ArtPollReply / ArtDmx loopback, exact DMX channels and three blackout frames after browser timeout.'
ensure
  sender.stop
  node.close
end
