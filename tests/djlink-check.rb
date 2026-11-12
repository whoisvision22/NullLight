# frozen_string_literal: true
require_relative '../native/macos/artnet'

def assert(condition, message)
  raise message unless condition
end

def beat_packet(player: 1, beat: 1, bpm: 12_800, pitch: 0x100000)
  packet = "\0".b * 96
  packet[0, 10] = 'Qspt1WmJOL'
  packet.setbyte(10, 0x28)
  packet[11, 8] = 'CDJ-3000'
  packet.setbyte(33, player)
  packet[34, 2] = [60].pack('n')
  packet[84, 4] = [pitch].pack('N')
  packet[90, 2] = [bpm].pack('n')
  packet.setbyte(92, beat)
  packet
end

value = ArtNet::DJLink.parse(beat_packet(pitch: 0x108000, beat: 4))
assert(value[:bpm] == 132.0 && value[:beat] == 4 && value[:name] == 'CDJ-3000', 'Pitch / BPM / Beat falsch.')
assert(ArtNet::DJLink.parse(beat_packet(player: 6)), 'Player 6 fehlt.')
[beat_packet[0, 95], beat_packet + "\0", beat_packet(player: 33), beat_packet(beat: 0),
 beat_packet(bpm: 65_535), beat_packet(pitch: 0), beat_packet(pitch: 0x300000), 'x' * 96].each do |packet|
  assert(ArtNet::DJLink.parse(packet).nil?, 'Ungültiges Beat-Paket akzeptiert.')
end
wrong = beat_packet.dup; wrong.setbyte(10, 3)
assert(ArtNet::DJLink.parse(wrong).nil?, 'Falscher Pakettyp akzeptiert.')

# Real UDP loopback exercises receive, source locking, duplicates and timeout.
clock = 10.0
listener = ArtNet::DJLink.new
listener.define_singleton_method(:now) { clock }
socket = UDPSocket.new
begin
  listener.enable('player' => 1)
  send_beat = lambda do |player, beat|
    socket.send(beat_packet(player: player, beat: beat), 0, '127.0.0.1', 50_001)
    IO.select([listener.instance_variable_get(:@socket)], nil, nil, 1)
    listener.tick
  end
  send_beat.call(2, 1)
  assert(!listener.status[:connected], 'Falscher Player wurde gewählt.')
  send_beat.call(1, 1)
  assert(listener.status[:connected] && listener.status[:sequence] == 1, 'UDP-Beat fehlt.')
  send_beat.call(1, 1)
  assert(listener.status[:sequence] == 1, 'Doppelter Beat übernommen.')
  clock += 0.5
  send_beat.call(1, 2)
  assert(listener.status[:sequence] == 2, 'Nächster Beat fehlt.')
  clock += 3.1
  assert(!listener.status[:connected], 'Verlust muss nach 3 Sekunden gemeldet werden.')
  listener.stop
  assert(!listener.status[:enabled], 'Socket nicht geschlossen.')
  listener.enable('player' => 0)
  send_beat.call(2, 1)
  clock += 0.5
  send_beat.call(1, 2)
  assert(listener.status[:device][:player] == 2, 'Automatik mischt Player.')
  clock += 3.1
  send_beat.call(1, 3)
  assert(listener.status[:device][:player] == 1, 'Neuer Player nach Timeout fehlt.')
ensure
  listener.stop
  socket.close
end
puts 'Passed: CDJ-3000 beat parsing, pitch, invalid packets, UDP, player selection, source lock, duplicate rejection and signal loss.'
