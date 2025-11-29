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
		len, _ := receiver.read(mut buf) or { continue }

		packet := vosc.read_packet(buf)!

		// print(packet)

		if packet.kind == .message {
			msg := packet.msg
			print(msg)
		} else if packet.kind == .bundle {
			bundle := packet.bundle
			t := vosc.to_time(bundle.time)
			print(t)
			for pac in bundle.contents {
				if pac.kind == .message {
					msg := pac.msg
					print(msg)
				}
			}
		}
	}
}
