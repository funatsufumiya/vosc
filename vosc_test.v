module vosc

fn test_nano_to_fraction_to_nano(){
	want := u32(1_000_000_000)
	fr := nano_to_fraction(want)
	result := fraction_to_nano(fr)
	assert result == want, "${result} should be ${want}"
}