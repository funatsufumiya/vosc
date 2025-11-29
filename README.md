# vosc

A pure V implementation of the [OSC(Open Sound Control) 1.0](https://opensoundcontrol.stanford.edu/spec-1_0.html) protocol.

Ported from [Okabintaro/nosc](https://github.com/Okabintaro/nosc)

## Usage

### Sender

see [sender example](./examples/example_sender/main.v).

```v
import vosc
import net

fn main() {
	raddr := '127.0.0.1:9000'
	mut sender := net.dial_udp(raddr)!
	defer {
		sender.close() or { panic(err) }
	}

	mut msg := vosc.OscMessage{}
    msg.address = "/hello"
    msg.args = [1, f32(2.3), "world"]

    mut buf := []u8{cap: 128}
    vosc.add_message(mut buf, msg)

	sender.write_ptr(buf.data, int(buf.len))!

	println('OSC sent to ${raddr}.')
	println("")
	println("The content is ${msg}")
}
```

### Receiver

see [receiver example](./examples/example_receiver/main.v).

```v
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
```

## Install

```bash
$ git clone https://github.com/funatsufumiya/vosc ~/.vmodules/vosc
```

## Tests

```bash
$ v test .
```

## License

see [LICENSE](./LICENSE).

Please note that the original [Okabintaro/nosc](https://github.com/Okabintaro/nosc) contains codes by [treeform](https://github.com/treeform) codes, see [LICENSE_treeform](./LICENSE_treeform) and [original README](https://github.com/Okabintaro/nosc/blob/master/README.md).
