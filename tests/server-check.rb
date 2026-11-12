# frozen_string_literal: true
require 'net/http'
require 'tmpdir'
require 'open3'
require 'timeout'
require 'rbconfig'
require_relative '../native/macos/artnet'

def assert(condition, message)
  raise message unless condition
end

# Full Pi HTTP process: private page, authenticated API, CDJ and MCP UI bridge.
Dir.mktmpdir('nulllight-pi-check-') do |state|
  port_socket = TCPServer.new('127.0.0.1', 0)
  port = port_socket.addr[1]
  port_socket.close
  env = { 'NULLLIGHT_STATE_DIR' => state, 'NULLLIGHT_PORT' => port.to_s, 'NULLLIGHT_BIND' => '127.0.0.1' }
  stdin, stdout, stderr, process = Open3.popen3(env, RbConfig.ruby, 'native/raspberrypi/server.rb')
  begin
    url = Timeout.timeout(10) { stdout.gets }
    assert(url && url.include?('?session='), 'Start-URL fehlt.')
    uri = URI(url.strip)
    token = File.read(File.join(state, 'session.key')).strip
    request = lambda do |path, body = nil, authenticated = true, extra = {}|
      target = URI("http://127.0.0.1:#{port}#{path}")
      req = body ? Net::HTTP::Post.new(target) : Net::HTTP::Get.new(target)
      req['X-Lichtpult-Session'] = token if authenticated
      req['Content-Type'] = 'application/json'
      extra.each { |key, value| req[key] = value }
      req.body = JSON.generate(body) if body
      Net::HTTP.start(target.host, target.port, nil, nil, nil, nil, read_timeout: 7) { |http| http.request(req) }
    end
    assert(request.call('/', nil, false).code == '400', 'Seite ohne Schlüssel zugänglich.')
    page = request.call(uri.request_uri, nil, false)
    assert(page.code == '200' && page.body.include?('lichtpultPlatform = "raspberrypi"'), 'Pi-Seite fehlt.')
    assert(page['content-security-policy'].include?("frame-ancestors 'none'"), 'CSP fehlt.')
    assert(request.call('/api/status', nil, false).code == '400', 'API ohne Schlüssel zugänglich.')
    assert(request.call('/api/status', nil, true, 'Host' => 'attacker.example').code == '400', 'Fremder Host akzeptiert.')
    assert(request.call('/api/stop', {}, true, 'Origin' => 'http://attacker.example').code == '400', 'Fremder Ursprung akzeptiert.')
    status = JSON.parse(request.call('/api/status').body)
    assert(status['platform'] == 'raspberrypi' && status['interfaces'].any?, 'Schnittstellen fehlen.')
    assert(status['update']['runningVersion'] == JSON.parse(File.read('version.json'))['version'], 'Pi-Version falsch.')
    assert(request.call('/api/dj/enable', { player: 1 }).code == '200', 'CDJ-Empfang startet nicht.')
    assert(JSON.parse(request.call('/api/dj/status').body)['enabled'], 'CDJ-Status falsch.')
    request.call('/api/dj/stop', {})
    assert(request.call('/api/control', { action: 'blackout' }).code == '400', 'MCP ohne Browser akzeptiert.')
    request.call('/api/control/poll', { state: { remoteEnabled: false } })
    assert(request.call('/api/control', { action: 'blackout' }).code == '400', 'MCP ohne Freigabe akzeptiert.')
    request.call('/api/control/poll', { state: { remoteEnabled: true } })
    command = Thread.new { request.call('/api/control', { action: 'set_master', args: { level: 25 } }) }
    incoming = nil
    Timeout.timeout(2) do
      until incoming
        incoming = JSON.parse(request.call('/api/control/poll', { state: { remoteEnabled: true } }).body)['command']
        sleep(0.01) unless incoming
      end
    end
    assert(incoming['action'] == 'set_master', 'MCP-Befehl fehlt in UI-Poll.')
    assert(command.alive?, 'MCP meldet Erfolg vor UI-Bestätigung.')
    request.call('/api/control/poll', { state: { remoteEnabled: true, master: 25 }, ack: { id: incoming['id'], result: { master: 25 } } })
    result = JSON.parse(command.value.body)
    assert(result['result']['master'] == 25, 'MCP-Ausführungsbestätigung fehlt.')
    assert(request.call('/api/control', { action: 'set_master', args: { level: 101 } }).code == '400', 'Ungültiger Master akzeptiert.')
    expired = request.call('/api/control', { action: 'blackout' })
    assert(expired.code == '400' && JSON.parse(expired.body)['error'].include?('Ausführungsbestätigung'), 'Nicht bestätigter Befehl als erfolgreich gemeldet.')
    poll = JSON.parse(request.call('/api/control/poll', { state: { remoteEnabled: true } }).body)
    assert(poll['command'].nil?, 'Abgelaufener Befehl darf nicht später ausgeführt werden.')
    puts 'Passed: real Pi server, private session, host/origin checks, interfaces, version, CDJ API and acknowledged MCP bridge.'
  ensure
    Process.kill(Gem.win_platform? ? 'KILL' : 'TERM', process.pid) if process.alive?
    process.join(5)
    Process.kill('KILL', process.pid) if process.alive?
    [stdin, stdout, stderr].each(&:close)
  end
end
