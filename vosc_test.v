module vosc

import math

fn test_nano_to_fraction_to_nano(){
	want := u32(1_000_000_000)
	fr := nano_to_fraction(want)
	result := fraction_to_nano(fr)
	assert result == want, "${result} should be ${want}"
}

fn test_to_color() {
	osc_color := OscColor{
		r: 0x12
		g: 0x34
		b: 0x56
		a: 0xff
	}
	color := to_color(osc_color)
	assert color == 0x123456
}

fn test_to_osc_color() {
	c := u32(0x123456)
	alpha := u8(128)
	osc_color := to_osc_color(c, alpha)
	assert osc_color.r == 0x12
	assert osc_color.g == 0x34
	assert osc_color.b == 0x56
	assert osc_color.a == 128
}

fn test_to_time_and_to_osc_time() {
	// Test round-trip conversion
	orig := OscTime{
		seconds: u32(123456789)
		frac: nano_to_fraction(u32(987654321))
	}
	t := to_time(orig)
	converted := to_osc_time(t)
	assert converted.seconds == orig.seconds, 'seconds mismatch: ${converted.seconds} != ${orig.seconds}'
	// Allow 1ns deviation due to lossy conversion
	assert math.abs(fraction_to_nano(converted.frac) - fraction_to_nano(orig.frac)) <= 1, 'nanoseconds mismatch: ${fraction_to_nano(converted.frac)} != ${fraction_to_nano(orig.frac)}'

	// Test with zero time
	zero := OscTime{
		seconds: u32(0)
		frac: nano_to_fraction(u32(0))
	}
	t_zero := to_time(zero)
	converted_zero := to_osc_time(t_zero)
	assert converted_zero.seconds == zero.seconds
	assert math.abs(fraction_to_nano(converted_zero.frac) - fraction_to_nano(zero.frac)) <= 1
}

fn test_padded4() {
    assert padded4(0) == 0
    assert padded4(1) == 4
    assert padded4(2) == 4
    assert padded4(3) == 4
    assert padded4(4) == 4
    assert padded4(5) == 8
    assert padded4(7) == 8
    assert padded4(8) == 8
    assert padded4(9) == 12
}

fn test_index_byte() {
    // Basic case: separator found
    assert index_byte([u8(1), 2, 3, 4], u8(3)) == 2
    // Separator at start
    assert index_byte([u8(9), 2, 3], u8(9)) == 0
    // Separator at end
    assert index_byte([u8(1), 2, 3], u8(3)) == 2
    // Separator not found
    assert index_byte([u8(1), 2, 3], u8(4)) == -1
    // Empty slice
    assert index_byte([]u8{}, u8(1)) == -1
    // Multiple separators, returns first
    assert index_byte([u8(5), 6, 5, 7], u8(5)) == 0
    // Separator is zero
    assert index_byte([u8(1), 0, 2], u8(0)) == 1
}

fn test_read_osc_time() {
    // Prepare payload: seconds = 0x12345678, frac = 0x9abcdef0 (big-endian)
    payload := [
        u8(0x12), 0x34, 0x56, 0x78, // seconds
        0x9a, 0xbc, 0xde, 0xf0      // frac
    ]
    osc_time, next_index := read_osc_time(payload, 0)
    assert osc_time.seconds == 0x12345678
    assert osc_time.frac == 0x9abcdef0
    assert next_index == 8

    // Test with offset
    payload2 := [
        u8(0), 0, 0, 0, // padding
        0x01, 0x02, 0x03, 0x04, // seconds
        0x05, 0x06, 0x07, 0x08  // frac
    ]
    osc_time2, next_index2 := read_osc_time(payload2, 4)
    assert osc_time2.seconds == 0x01020304
    assert osc_time2.frac == 0x05060708
    assert next_index2 == 12
}

fn test_add_color() {
    // Test add_color
    mut buf := []u8{}
    osc_color := OscColor{
        r: 0x11
        g: 0x22
        b: 0x33
        a: 0x44
    }
    add_color(mut buf, osc_color)
    assert buf == [u8(0x11), 0x22, 0x33, 0x44], 'add_color failed: ${buf}'
}

fn test_add_midi() {
    // Test add_midi
    mut midi_buf := []u8{}
    osc_midi := OscMidi{
        port_id: 0x55
        status: 0x66
        data1: 0x77
        data2: 0x88
    }
    add_midi(mut midi_buf, osc_midi)
    assert midi_buf == [u8(0x55), 0x66, 0x77, 0x88], 'add_midi failed: ${midi_buf}'
}

fn test_read_osc_color() {
    // Normal case
    payload := [u8(0x10), 0x20, 0x30, 0x40]
    osc_color, next_index := read_osc_color(payload, 0) or { panic(err.msg()) }
    assert osc_color.r == 0x10
    assert osc_color.g == 0x20
    assert osc_color.b == 0x30
    assert osc_color.a == 0x40
    assert next_index == 4

    // Offset case
    payload2 := [u8(0), 0, 0, 0, 0x01, 0x02, 0x03, 0x04]
    osc_color2, next_index2 := read_osc_color(payload2, 4) or { panic(err.msg()) }
    assert osc_color2.r == 0x01
    assert osc_color2.g == 0x02
    assert osc_color2.b == 0x03
    assert osc_color2.a == 0x04
    assert next_index2 == 8

    // Error case: not enough bytes
    payload3 := [u8(1), 2, 3]
	mut has_error := false
    read_osc_color(payload3, 0) or { has_error = true }
	assert has_error == true
}

fn test_read_osc_midi() {
    // Normal case
    payload := [u8(0x90), 0x80, 0x70, 0x60]
    osc_midi, next_index := read_osc_midi(payload, 0) or { panic(err.msg()) }
    assert osc_midi.port_id == 0x90
    assert osc_midi.status == 0x80
    assert osc_midi.data1 == 0x70
    assert osc_midi.data2 == 0x60
    assert next_index == 4

    // Offset case
    payload2 := [u8(0), 0, 0, 0, 0x01, 0x02, 0x03, 0x04]
    osc_midi2, next_index2 := read_osc_midi(payload2, 4) or { panic(err.msg()) }
    assert osc_midi2.port_id == 0x01
    assert osc_midi2.status == 0x02
    assert osc_midi2.data1 == 0x03
    assert osc_midi2.data2 == 0x04
    assert next_index2 == 8

    // Error case: not enough bytes
    payload3 := [u8(1), 2, 3]
	mut has_error := false
   	read_osc_midi(payload3, 0) or { has_error = true }
	assert has_error == true
}

fn test_vosc_msg_init(){
    msg := vosc.OscMessage{}
    assert true
}

fn test_vosc_msg_to_str(){
    mut msg := vosc.OscMessage{}
    msg.address = "/hello"
    s := msg.str()
    assert s.contains("/hello")
}

fn test_vosc_msg_to_bytes(){
    mut msg := vosc.OscMessage{}
    msg.address = "/hello"

    mut buf := []u8{cap: 128}
    vosc.add_message(mut buf, msg)
    
    assert buf.len == 12
}

fn test_vosc_msg_to_bytes_with_args(){
    mut msg := vosc.OscMessage{}
    msg.address = "/hello"
    msg.args = [1, f32(2.0), "world"]

    mut buf := []u8{cap: 128}
    vosc.add_message(mut buf, msg)
    
    assert buf.len == 32
}