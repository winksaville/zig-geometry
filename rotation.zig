const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;

//const geo = @import("index.zig");

const matrix = @import("matrix.zig");
const Matrix = matrix.Matrix;
const M44f32 = matrix.M44f32;
const mulM44f32 = matrix.mulM44f32;

const vec = @import("vec.zig");
const V3f32 = vec.V3f32;
const V2f32 = vec.V2f32;

const DBG = false;

/// Builds a Yaw Pitch Roll Rotation matrix from point with x, y, z angles in radians.
pub fn rotationYawPitchRollV3f32(point: V3f32) M44f32 {
    return rotationYawPitchRoll(point.x(), point.y(), point.z());
}

/// Builds a Yaw Pitch Roll Rotation matrix from x, y, z angles in radians.
pub fn rotationYawPitchRoll(x: f32, y: f32, z: f32) M44f32 {
    const rx = RotateX(x);
    const ry = RotateY(y);
    const rz = RotateZ(z);

    var m = mulM44f32(&rz, &mulM44f32(&ry, &rx));
    if (DBG) warn("rotationYawPitchRoll m:\n{}", &m);

    return m;
}

/// Builds a Yaw Pitch Roll Rotation matrix from x, y, z angles in radians.
/// With the x, y, z applied in the opposite order then rotationYawPitchRoll.
pub fn rotationYawPitchRollNeg(x: f32, y: f32, z: f32) M44f32 {
    const rx = RotateX(x);
    const ry = RotateY(y);
    const rz = RotateZ(z);

    var m = mulM44f32(&rx, &mulM44f32(&ry, &rz));
    if (DBG) warn("rotationYawPitchRollNeg m:\n{}", &m);

    return m;
}

// Return a `M44f32` for x axis
fn RotateX(x: f32) M44f32 {
    const rx = M44f32{ .data = [][4]f32{
        []f32{ 1.0, 0.0, 0.0, 0.0 },
        []f32{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRoll rx:\n{}", &rx);
    return rx;
}

// Return a `M44f32` for y axis
fn RotateY(y: f32) M44f32 {
    const ry = M44f32{ .data = [][4]f32{
        []f32{ math.cos(y), 0.0, math.sin(y), 0.0 },
        []f32{ 0.0, 1.0, 0.0, 0.0 },
        []f32{ -math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRoll ry:\n{}", &ry);
    return ry;
}

// Return a `M44f32` for z axis
fn RotateZ(z: f32) M44f32 {
    const rz = M44f32{ .data = [][4]f32{
        []f32{ math.cos(z), -math.sin(z), 0.0, 0.0 },
        []f32{ math.sin(z), math.cos(z), 0.0, 0.0 },
        []f32{ 0.0, 0.0, 1.0, 0.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRoll rz:\n{}", &rz);
    return rz;
}

test "math3d.rotationYawPitchRoll" {
    if (DBG) warn("\n");
    const deg10rad: f32 = 0.174522;
    var m_zero = rotationYawPitchRoll(0, 0, 0);

    var m_x_pos_ten_deg = rotationYawPitchRoll(deg10rad, 0, 0);
    var m_x_neg_ten_deg = rotationYawPitchRoll(-deg10rad, 0, 0);
    var x = mulM44f32(&m_x_pos_ten_deg, &m_x_neg_ten_deg);
    if (DBG) warn("m_x_pos_ten_deg:\n{}", &m_x_pos_ten_deg);
    if (DBG) warn("m_x_neg_ten_deg:\n{}", &m_x_neg_ten_deg);
    if (DBG) warn("x = pos * neg:\n{}", &x);
    assert(matrix.approxEql(&m_zero, &x, 7));

    var m_y_pos_ten_deg = rotationYawPitchRoll(0, deg10rad, 0);
    var m_y_neg_ten_deg = rotationYawPitchRoll(0, -deg10rad, 0);
    var y = mulM44f32(&m_y_pos_ten_deg, &m_y_neg_ten_deg);
    if (DBG) warn("\nm_y_pos_ten_deg:\n{}", m_y_pos_ten_deg);
    if (DBG) warn("m_y_neg_ten_deg:\n{}", m_y_neg_ten_deg);
    if (DBG) warn("y = pos * neg:\n{}", &y);
    assert(matrix.approxEql(&m_zero, &y, 7));

    var m_z_pos_ten_deg = rotationYawPitchRoll(0, 0, deg10rad);
    var m_z_neg_ten_deg = rotationYawPitchRoll(0, 0, -deg10rad);
    var z = mulM44f32(&m_z_pos_ten_deg, &m_z_neg_ten_deg);
    if (DBG) warn("\nm_z_neg_ten_deg:\n{}", m_z_neg_ten_deg);
    if (DBG) warn("m_z_pos_ten_deg:\n{}", m_z_pos_ten_deg);
    if (DBG) warn("z = pos * neg:\n{}", &z);
    assert(matrix.approxEql(&m_zero, &z, 7));

    var xy_pos = mulM44f32(&m_x_pos_ten_deg, &m_y_pos_ten_deg);
    var a = mulM44f32(&xy_pos, &m_y_neg_ten_deg);
    var b = mulM44f32(&a, &m_x_neg_ten_deg);
    if (DBG) warn("\nxy_pos = x_pos_ten * y_pos_ten:\n{}", &xy_pos);
    if (DBG) warn("a = xy_pos * y_pos_ten\n{}", &a);
    if (DBG) warn("b = a * x_pos_ten\n{}", &b);
    assert(matrix.approxEql(&m_zero, &b, 7));

    // To undo a rotationYayPitchRoll the multiplication in rotationYawPitch
    // must be applied reverse order. So rz.mult(&ry.mult(&rx)) which is
    //   1) r1 = ry * rx
    //   2) r2 = rz * r1
    // must be applied:
    //   1) r3 = -rz * r2
    //   2) r4 = -ry * r3
    //   3) r5 = -rx * r4
    if (DBG) warn("\n");
    var r2 = rotationYawPitchRoll(deg10rad, deg10rad, deg10rad);
    if (DBG) warn("r2:\n{}", &r2);
    var r3 = mulM44f32(&m_z_neg_ten_deg, &r2);
    var r4 = mulM44f32(&m_y_neg_ten_deg, &r3);
    var r5 = mulM44f32(&m_x_neg_ten_deg, &r4);
    if (DBG) warn("r5:\n{}", &r5);
    assert(matrix.approxEql(&m_zero, &r5, 7));

    // Here is the above as a single line both are equal to m_zero
    r5 = mulM44f32(&m_x_neg_ten_deg, &mulM44f32(&m_y_neg_ten_deg, &mulM44f32(&m_z_neg_ten_deg, &r2)));
    if (DBG) warn("r5 one line:\n{}", &r5);
    assert(matrix.approxEql(&m_zero, &r5, 7));

    // Or you can use rotationYawPitchRollNeg
    var rneg = rotationYawPitchRollNeg(-deg10rad, -deg10rad, -deg10rad);
    if (DBG) warn("rneg:\n{}", &rneg);
    r5 = mulM44f32(&rneg, &r2);
    if (DBG) warn("r5:\n{}", &r5);
    assert(matrix.approxEql(&m_zero, &r5, 7));
}
