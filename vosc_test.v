module vosc

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
