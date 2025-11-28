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