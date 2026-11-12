# frozen_string_literal: true
module ArtNet
  def self.mapping(input)
    input ||= {}
    raise ArgumentError, 'Ungültiges Mapping.' unless input.is_a?(Hash)
    result = {}
    %w[dmx artnet].each do |kind|
      section = input[kind] || {}
      raise ArgumentError, 'Ungültige Mapping-Tabelle.' unless section.is_a?(Hash)
      routes = section['routes'] || []
      raise ArgumentError, 'Ungültige Mapping-Zeilen.' unless routes.is_a?(Array)
      used = {}
      validated = routes.map do |route|
        raise ArgumentError, 'Ungültige Mapping-Zeile.' unless route.is_a?(Hash)
        copy = {}
        {'sourceChannel' => 512, 'targetChannel' => 512, 'count' => 512}.each do |key, max|
          value = route[key]
          raise ArgumentError, 'Kanäle und Länge müssen zwischen 1 und 512 liegen.' unless value.is_a?(Integer) && value.between?(1, max)
          copy[key] = value
        end
        raise ArgumentError, 'Ein Kanalbereich endet hinter Kanal 512.' if
          copy['sourceChannel'] + copy['count'] > 513 || copy['targetChannel'] + copy['count'] > 513
        if kind == 'artnet'
          %w[sourceUniverse targetUniverse].each do |key|
            value = route[key]
            raise ArgumentError, 'Art-Net-Portadressen müssen zwischen 0 und 32767 liegen.' unless value.is_a?(Integer) && value.between?(0, 32767)
            copy[key] = value
          end
          ip = route.fetch('sourceIP', '')
          raise ArgumentError, 'Ungültige Sender-IP.' unless ip.is_a?(String)
          unless ip.empty?
            parsed = IPAddr.new(ip)
            raise ArgumentError, 'Bitte eine IPv4-Senderadresse eingeben.' unless parsed.ipv4?
            ip = parsed.to_s
          end
          copy['sourceIP'] = ip
        end
        copy['count'].times do |index|
          slot = [copy['targetUniverse'] || 0, copy['targetChannel'] + index]
          raise ArgumentError, 'Zielkanäle innerhalb einer Mapping-Tabelle überschneiden sich.' if used[slot]
          used[slot] = true
        end
        copy
      end
      result[kind] = { 'enabled' => section['enabled'] == true,
                       'passthrough' => section['passthrough'] == true, 'routes' => validated }
    end
    result
  end

  def self.remap_dmx(frame, mapping)
    table = mapping['dmx']
    return frame.dup unless table['enabled']
    result = table['passthrough'] ? frame.dup : Array.new(512, 0)
    table['routes'].each do |route|
      result[route['targetChannel'] - 1, route['count']] = frame[route['sourceChannel'] - 1, route['count']]
    end
    result
  end

  def self.read_dmx(packet)
    return nil unless packet.bytesize >= 20 && packet[0, 8] == ID && packet[8, 2].unpack('v')[0] == 0x5000
    return nil if packet[10, 2].unpack('n')[0] < 14
    length = packet[16, 2].unpack('n')[0]
    return nil unless length.between?(2, 512) && length.even? && packet.bytesize >= 18 + length
    { address: ((packet.getbyte(15) & 127) << 8) | packet.getbyte(14),
      sequence: packet.getbyte(12), channels: packet[18, length].bytes + Array.new(512 - length, 0) }
  end

  def self.subscriptions(packet)
    return [] unless packet.bytesize >= 194 && packet[0, 8] == ID && packet[8, 2].unpack('v')[0] == 0x2100
    net = packet.getbyte(18) & 127
    subnet = packet.getbyte(19) & 15
    count = [packet[172, 2].unpack('n')[0], 4].min
    count.times.each_with_object([]) do |index, result|
      next unless packet.getbyte(174 + index) & 128 != 0 && packet.getbyte(182 + index) & 1 == 0
      result << ((net << 8) | (subnet << 4) | (packet.getbyte(190 + index) & 15))
    end
  end
end
