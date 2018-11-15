const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;

const geo = @import("index.zig");

const DBG = false;

/// Builds a 4x4 translation matrix
pub fn translation(x: f32, y: f32, z: f32) geo.M44f32 {
    return geo.M44f32{ .data = [][4]f32{
        []f32{ 1.0, 0.0, 0.0, x },
        []f32{ 0.0, 1.0, 0.0, y },
        []f32{ 0.0, 0.0, 1.0, z },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
}

pub fn translationV3f32(vertex: geo.V3f32) geo.M44f32 {
    return translation(vertex.x(), vertex.y(), vertex.z());
}

test "math3d.translation" {
    if (DBG) warn("\n");
    var m = translation(1, 2, 3);
    const expected = geo.M44f32 { .data = [][4]f32{
        []f32{ 1.0, 0.0, 0.0, 1.0 },
        []f32{ 0.0, 1.0, 0.0, 2.0 },
        []f32{ 0.0, 0.0, 1.0, 3.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("translation: expected\n{}", &expected);
    assert(geo.approxEql(&m, &expected, 7));
}
