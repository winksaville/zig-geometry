const std = @import("std");
const math = std.math;
const assert = std.debug.assert;

pub fn degToRad(d: var) @typeOf(d) {
    const T = @typeOf(d);
    return d * T(math.pi) / T(180.0);
}

test "degrad.degToRad" {
    assert(degToRad(45.0) == 45.0 * (math.pi / 180.0));
}

pub fn radToDeg(r: var) @typeOf(r) {
    const T = @typeOf(r);
    return r * T(180.0) / T(math.pi);
}

test "degrad.radToDeg" {
    assert(radToDeg(math.pi / 4.0) == 45.0);
}

