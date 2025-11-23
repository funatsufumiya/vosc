// vosc.v - V module for OSC message parsing and serialization
// Ported from nosc.nim

module vosc

import time

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
