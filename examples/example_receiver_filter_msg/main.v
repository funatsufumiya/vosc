module main

import net
import vosc

fn main() {
	raddr := '0.0.0.0:9000'
	mut receiver := net.listen_udp(raddr)!
	defer {
		receiver.close() or { panic(err) }
	}
	println('OSC listening to ${raddr}')

	mut buf := []u8{len: 2048}
	for {
		receiver.read(mut buf) or { continue }

		packet := vosc.read_packet(buf)!

		// receive all messages
		vosc.filter_messages(packet, fn(msg &vosc.OscMessage){
			println(msg.address)
			println(msg.args)
		})
	}
}
