// vosc.v - V module for OSC message parsing and serialization
// Ported from nosc.nim

module vosc

// import gg
import time
import encoding.binary
import math
import strings

// Types

// struct OscParseError {
//     Error
//     reason string
// }

// fn (err OscParseError) msg() string {
//     return 'Failed to open path: ${err.reason}'
// }

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

fn init_time(abs_unix_timestamp i64, nanosecond int) time.Time {
    return time.unix_nanosecond(abs_unix_timestamp, nanosecond)
}

// NTP epoch constant
const ntp_epoch = init_time(-2208988800, 0)

// Convert OSC/NTP timestamp to Time object
pub fn to_time(t OscTime) time.Time {
    // This conversion is lossy. Round-trip will have a deviation of 1 nanosecond.
    // NOTE: Does not handle the special case of an immediate time.
    // You have to check using is_immediate yourself.
    unix_seconds := i64(t.seconds) + ntp_epoch.unix()
    nano := fraction_to_nano(t.frac)
    return init_time(unix_seconds, int(nano))
}

// Convert Time object to OSC/NTP timestamp
pub fn to_osc_time(t time.Time) OscTime {
    mut result := OscTime{}
    result.seconds = u32(t.unix() - ntp_epoch.unix())
    result.frac = nano_to_fraction(u32(t.nanosecond))
    return result
}

// Pad the given length to the next multiple of 4.
fn padded4(length int) int {
  if length % 4 != 0 {
    return length + (4 - length % 4)
  } else {
    return length
  }
}

// Add a padded string to buffer (OSC format)
pub fn add_padded_str(mut buffer []u8, val string) {
    buffer << val.bytes()
    // Always pad with at least one '\0'
    rem := 4 - (val.len % 4)
    for _ in 0 .. rem {
        buffer << u8(0)
    }
}

// Add a blob to buffer (OSC format)
pub fn add_blob(mut buffer []u8, val []u8) {
    for c in val {
        buffer << c
    }
    // No 0 terminator needed for blob
    if val.len % 4 != 0 {
        rem := 4 - (val.len % 4)
        for _ in 0 .. rem {
            buffer << u8(0)
        }
    }
}

fn index_byte(s []u8, sep u8) int {
    for i, c in s {
        if c == sep {
            // out = s[..i]
            return i
        }
    }
    // out = []
    return -1
}

// Read a padded string from payload, updating index
pub fn read_padded_str(payload []u8, i int) !(string, int) {
    if i >= payload.len {
        return error('Not enough bytes to read string')
    }
    buf := payload[i..]
    len := index_byte(buf, `\0`)
    if len == -1 {
        return error('Not enough bytes to read string')
    }
    result := buf[..len]
    next_index := i + padded4(len + 1) // len + 1 for the \0
    mut builder := strings.new_builder(result.len)
    builder.write(result)!
    return builder.bytestr(), next_index
}

pub fn read_osc_time(payload []u8, i int) (OscTime, int) {
  mut result := OscTime{}
  result.seconds = binary.big_endian_u32_at(payload, i)
  result.frac = binary.big_endian_u32_at(payload, i + 4)
  return result, i + 8
}

// Add OscColor to buffer (OSC format)
pub fn add_color(mut buffer []u8, val OscColor) {
    buffer << val.r
    buffer << val.g
    buffer << val.b
    buffer << val.a
}

// Add OscMidi to buffer (OSC format)
pub fn add_midi(mut buffer []u8, val OscMidi) {
    buffer << val.port_id
    buffer << val.status
    buffer << val.data1
    buffer << val.data2
}

// Read OscColor from payload, updating index
pub fn read_osc_color(payload []u8, i int) !(OscColor, int) {
    if i + 4 > payload.len {
        return error('Not enough bytes to read color')
    }
    mut result := OscColor{}
    result.r = payload[i]
    result.g = payload[i + 1]
    result.b = payload[i + 2]
    result.a = payload[i + 3]
    return result, i + 4
}

// Read OscMidi from payload, updating index
pub fn read_osc_midi(payload []u8, i int) !(OscMidi, int) {
    if i + 4 > payload.len {
        return error('Not enough bytes to read midi')
    }
    mut result := OscMidi{}
    result.port_id = payload[i]
    result.status = payload[i + 1]
    result.data1 = payload[i + 2]
    result.data2 = payload[i + 3]
    return result, i + 4
}

pub fn read_arguments(payload []u8, type_tags string, i int, j int, depth int) !([]OscValue, int, int) {
    max_array_depth := 64
    mut args := []OscValue{}
    mut idx := i
    mut tag_idx := j
    for tag_idx < type_tags.len {
        t := type_tags[tag_idx]
        tag_idx++
        match t {
            `,` {
                continue
            }
            `f` {
                raw := binary.big_endian_u32_at(payload, idx)
                val := math.f32_from_bits(raw)
                idx += 4
                args << val
            }
            `i` {
                val := int(binary.big_endian_u32_at(payload, idx))
                idx += 4
                args << val
            }
            `s` {
                str, next_idx := read_padded_str(payload, idx) or { return err }
                idx = next_idx
                args << str
            }
            `b` {
                length := int(binary.big_endian_u32_at(payload, idx))
                idx += 4
                if length < 0 {
                    return error('Payload length must be positive')
                }
                if idx + length > payload.len {
                    return error('Not enough bytes to read blob')
                }
                val := payload[idx..idx+length]
                idx += padded4(length)
                args << val
            }
            `T` {
                args << true
            }
            `F` {
                args << false
            }
            `N` {
                args << OscNilValue{}
            }
            `[` {
                if depth > max_array_depth {
                    return error('Too many nested arrays')
                }
                arr, new_idx, new_tag_idx := read_arguments(payload, type_tags, idx, tag_idx, depth + 1) or { return err }
                idx = new_idx
                tag_idx = new_tag_idx
                args << arr
            }
            `]` {
                if depth == 0 {
                    return error('Unmatched `]`')
                }
                return args, idx, tag_idx
            }
            `t` {
                val, next_idx := read_osc_time(payload, idx)
                idx = next_idx
                args << val
            }
            `h` {
                val := i64(binary.big_endian_u64_at(payload, idx))
                idx += 8
                args << OscBigIntValue{ big_int_val: val }
            }
            `d` {
                raw := binary.big_endian_u64_at(payload, idx)
                val := math.f64_from_bits(raw)
                idx += 8
                args << val
            }
            `I` {
                args << OscInfValue{}
            }
            `c` {
                c := rune(binary.big_endian_u32_at(payload, idx))
                idx += 4
                args << c
            }
            `r` {
                val, next_idx := read_osc_color(payload, idx) or { return err }
                idx = next_idx
                args << val
            }
            `m` {
                val, next_idx := read_osc_midi(payload, idx) or { return err }
                idx = next_idx
                args << val
            }
            else {
                continue
            }
        }
    }
    return args, idx, tag_idx
}