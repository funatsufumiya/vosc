// vosc.v - V module for OSC message parsing and serialization
// Ported from nosc.nim

module vosc

// Types

pub struct OscTime {
pub mut:
    seconds u32
    frac u32
}

const osc_time_immediate = OscTime{
    seconds: u32(0),
    frac: u32(1),
}

fn fraction_to_nano(fraction u32) u32 {
    frac := (f64(fraction) * 1_000_000_000.0) / f64(1 << 32)
    return u32(frac)
}

fn nano_to_fraction(nanoseconds u32) u32 {
    frac := (f64(nanoseconds) / 1_000_000_000.0) * f64(1 << 32)
    return u32(frac)
}

pub struct OscColor {
pub mut:
    r u8
    g u8
    b u8
    a u8
}

pub struct OscMidi {
pub mut:
    port_id u8
    status u8
    data1 u8
    data2 u8
}

pub enum OscType {
    osc_float
    osc_int
    osc_string
    osc_blob
    osc_true
    osc_false
    osc_nil
    osc_inf
    osc_array
    osc_time
    osc_bigint
    osc_double
    osc_char
    osc_color
    osc_midi
}

pub struct OscBigIntValue {
pub mut:
    big_int_val i64
}

type OscValue =
    int | f32 | f64 | string
    | []u8 | u8 | rune | OscBigIntValue
    | OscTime | OscColor | OscMidi
    | []OscValue

pub struct OscMessage {
pub mut:
    address string
    args []OscValue
}
