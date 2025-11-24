// vosc_packet_bundle.v
// Ported from nosc.nim

module vosc

import encoding.binary

pub enum OscPacketKind {
    message
    bundle
}

pub struct OscPacket {
pub mut:
    kind OscPacketKind
    msg OscMessage
    bundle OscBundle
}

pub struct OscBundle {
pub mut:
    time OscTime
    contents []OscPacket
}

// Read an OscBundle from payload, starting at index i
pub fn read_bundle(payload []u8, i int) !OscBundle {
    if payload.len < 12 {
        return error('Bundle is too small')
    }
    if payload[i..i+8].bytestr() != '#bundle\x00' {
        return error('Invalid bundle header')
    }
    mut idx := i + 8
    time, next_idx := read_osc_time(payload, idx)
    idx = next_idx
    mut contents := []OscPacket{}
    for idx < payload.len {
        if idx + 4 > payload.len {
            break
        }
        size := int(binary.big_endian_u32_at(payload, idx))
        idx += 4
        if size < 0 {
            return error('Bundle size must be positive')
        }
        if idx + size > payload.len {
            return error('Not enough bytes to read bundle data')
        }
        packet := read_packet(payload[idx..idx+size])!
        contents << packet
        idx += size
    }
    return OscBundle{
        time: time
        contents: contents
    }
}

// Read an OscPacket from payload, starting at index i
pub fn read_packet(payload []u8) !OscPacket {
    if payload.len < 4 {
        return error('Packet is too small')
    }
    if payload[0] == `#` {
        bundle := read_bundle(payload, 0)!
        return OscPacket{
            kind: .bundle
            bundle: bundle
        }
    } else if payload[0] == `/` {
        msg, _ := read_message(payload, 0)!
        return OscPacket{
            kind: .message
            msg: msg
        }
    } else {
        return error('Invalid packet header')
    }
}

// Add an OscBundle to buffer (OSC format)
pub fn add_bundle(mut buffer []u8, bundle OscBundle) {
    mut tmp_buf := []u8{cap: 512}
    add_padded_str(mut buffer, '#bundle')
    buffer << u8(0)
    buffer << binary.big_endian_get_u32(bundle.time.seconds)
    buffer << binary.big_endian_get_u32(bundle.time.frac)
    for packet in bundle.contents {
        tmp_buf.clear()
        add_packet(mut tmp_buf, packet)
        buffer << binary.big_endian_get_u32(u32(tmp_buf.len))
        buffer << tmp_buf
    }
}

// Add an OscPacket to buffer (OSC format)
pub fn add_packet(mut buffer []u8, packet OscPacket) {
    match packet.kind {
        .message {
            add_message(mut buffer, packet.msg)
        }
        .bundle {
            add_bundle(mut buffer, packet.bundle)
        }
    }
}

// Serialize the given OscBundle to a new buffer and return it
pub fn dgram_bundle(bundle OscBundle) []u8 {
    mut dgram := []u8{cap: 512}
    add_bundle(mut dgram, bundle)
    return dgram
}