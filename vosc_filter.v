module vosc

pub fn filter_messages(packet &OscPacket, callback fn (&OscMessage)){
	if packet.kind == .message {
		msg := packet.msg
		callback(msg)
	} else if packet.kind == .bundle {
		bundle := packet.bundle
		// t := vosc.to_time(bundle.time)
		// print(t)
		for pac in bundle.contents {
			if pac.kind == .message {
				msg := pac.msg
				callback(msg)
			}
		}
	}
}

pub fn filter_address(packet &OscPacket, address string, callback fn (&OscMessage)) {
	if packet.kind == .message {
		msg := packet.msg
		if msg.address == address {
			callback(msg)
		}
	} else if packet.kind == .bundle {
		bundle := packet.bundle
		// t := vosc.to_time(bundle.time)
		// print(t)
		for pac in bundle.contents {
			if pac.kind == .message {
				msg := pac.msg
				if msg.address == address {
					callback(msg)
				}
			}
		}
	}
}