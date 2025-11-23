module vosc

fn test_nano_to_fraction_to_nano(){
	v := u32(99999)
	fr := nano_to_fraction(v)
	nn := fraction_to_nano(fr)
	assert v == nn, "${nn} should be ${v}"
}