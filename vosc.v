// vosc.v - V module for OSC message parsing and serialization
// Ported from nosc.nim

module vosc

import gg
import time

// Types

type Color = u32

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
    return u32((u64(fraction) * 1_000_000_000) / (1 << 32))
}

fn nano_to_fraction(nanoseconds u32) u32 {
    return u32((u64(nanoseconds) * (1 << 32)) / 1_000_000_000)
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

pub struct OscNilValue {}
pub struct OscInfValue {}

type OscValue =
    int | f32 | f64 | string | bool
    | []u8 | u8 | rune | OscBigIntValue
    | OscTime | OscColor | OscMidi
    | []OscValue | OscNilValue | OscInfValue

pub struct OscMessage {
pub mut:
    address string
    args []OscValue
}

// // Add time to buffer (big-endian)
// pub fn add_time(mut buffer string, time OscTime) {
//     buffer += be32(time.seconds)
//     buffer += be32(time.frac)
// }

// Check if OscTime is immediate
pub fn is_immediate(t OscTime) bool {
    return t == osc_time_immediate
}

// Convert OscColor to Color
pub fn to_color(c OscColor) Color {
    return u32(c.r) << 16 | u32(c.g) << 8 | u32(c.b)
}

/// alpha becomes 255
fn extract_rgb(a Color) OscColor {
    // Extracts the red/green/blue components of the color `a`.
    mut result := OscColor{}
    result.r = u8((a >> 16) & 0xff)
    result.g = u8((a >> 8) & 0xff)
    result.b = u8(a & 0xff)
    result.a = 255
    return result
}

// Convert gg.Color to OscColor with alpha
pub fn to_osc_color(c u32, alpha u8) OscColor {
    rgb := extract_rgb(c)
    return OscColor{
        r: rgb.r
        g: rgb.g
        b: rgb.b
        a: alpha
    }
}