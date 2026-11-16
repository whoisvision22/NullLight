# frozen_string_literal: true
require_relative '../native/macos/artnet'
require_relative '../native/macos/scene_ai'
def assert(value,message);raise message unless value;end
def rejects(message);begin;yield;rescue ArgumentError;return;end;raise message;end
sender=ArtNet::Sender.new
sender.instance_variable_set(:@config,{address:0,target:'127.0.0.1',source:'127.0.0.1'})
channels=Array.new(512,0)
pixels=(1..5).each_with_object({}){|number,out|out[number.to_s]=Array.new(512,number*20)}
sender.frame(channels,pixels)
assert(sender.output_addresses.sort==[0,1,2,3,4,5],'Pixel universes missing from subscription/blackout targets')
assert(sender.mapped_frames[5][0]==100,'Pixel values missing')
rejects('Invalid universe accepted'){sender.frame(channels,{'x'=>channels})}
rejects('Invalid channel count accepted'){sender.frame(channels,{'1'=>[1]})}
rejects('Invalid channel value accepted'){sender.frame(channels,{'1'=>Array.new(512,300)})}
assert(sender.mapped_frames[5][0]==100,'Invalid request changed buffers')
class PixelTestSocket
 def close;@closed=true;end
 def closed?;!!@closed;end
end
sender.instance_variable_set(:@enabled,true)
sender.instance_variable_set(:@socket,PixelTestSocket.new)
sender.define_singleton_method(:subscribed?){|_address|true}
sent=[]
sender.define_singleton_method(:send_frame){|frame,address=0|sent << [address,frame.dup]}
rejects('Pixel universe overwrote main output'){sender.frame(channels,{'0'=>channels})}
sender.frame(channels,{'1'=>pixels['1']})
assert(sent.count{|address,frame|address==5&&frame.all?(&:zero?)}==3,'Removed pixel universe did not receive blackout')
sent.clear;sender.stop
assert(sent.map(&:first).sort==[0,0,0,1,1,1],'Stop did not blackout normal and pixel universes')

ai=NullLightSceneAI.new
ai.configure('apiKey'=>'')
assert(!ai.status[:configured],'Unexpected configured key')
fixtures=[{'id'=>'bar','name'=>'Pixelbar','kind'=>'pixelbar','pixelCount'=>60}]
request={'prompt'=>'Blauer Laufpunkt','fixtures'=>fixtures}
rejects('Generation accepted missing key'){ai.generate(request)}
key='sk-test-'+('x'*40)
ai.configure('apiKey'=>key)
assert(ai.status[:configured]&&!JSON.generate(ai.status).include?(key),'Secret exposed in status')
proposal={'name'=>'Laufpunkt','summary'=>'Ein blauer Pixel','loop'=>true,'steps'=>[{'fade'=>0,'hold'=>0.5,'darkAfter'=>false,'darkHold'=>0.25,'fixtures'=>[{'fixtureId'=>'bar','color'=>'#0000ff','secondaryColor'=>'#000000','level'=>100,'pixelEffect'=>'chase','position'=>5}]}]}
observed=[]
ai.define_singleton_method(:post_json){|body,secret|observed << [body,secret];{'status'=>'completed','output'=>[{'content'=>[{'type'=>'output_text','text'=>JSON.generate(proposal)}]}]}}
result=ai.generate(request)
assert(result[:proposal]['steps'].length==1,'Missing scene proposal')
assert(observed[0][0][:store]==false&&observed[0][0][:text][:format][:strict],'Structured response configuration missing')
assert(observed[0][1]==key,'Key not passed to authenticated API request')
invalid=Marshal.load(Marshal.dump(proposal));invalid['steps'][0]['fixtures'][0]['fixtureId']='other'
rejects('Unknown fixture accepted'){ai.validate_proposal(invalid,fixtures)}
invalid=Marshal.load(Marshal.dump(proposal));invalid['steps'][0]['fixtures'][0]['position']=60
rejects('Out of range pixel accepted'){ai.validate_proposal(invalid,fixtures)}
invalid=Marshal.load(Marshal.dump(proposal));invalid['steps'][0]['hold']=-1
rejects('Negative timing accepted'){ai.validate_proposal(invalid,fixtures)}
invalid=Marshal.load(Marshal.dump(proposal));invalid['steps'][0]['fixtures']=['bad']
rejects('Malformed fixture accepted'){ai.validate_proposal(invalid,fixtures)}
rejects('Laser accepted for scene generator'){ai.generate({'prompt'=>'Test','fixtures'=>[{'id'=>'laser','name'=>'L','kind'=>'laser','pixelCount'=>0}]})}
ai.configure('apiKey'=>'');assert(!ai.status[:configured],'Key was not cleared')
puts 'Passed: pixel universe validation, isolated buffers, blackout on removed universes and stop; AI schema, credential isolation, proposal validation and unknown-device rejection (mocked API, no billed request).'
