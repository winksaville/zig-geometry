const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;

const matrix = @import("matrix.zig");
const Matrix = matrix.Matrix;
const M44f32 = matrix.M44f32;
const mulM44f32 = matrix.mulM44f32;

const vec = @import("vec.zig");
const V3f32 = vec.V3f32;
const V2f32 = vec.V2f32;

const degrad = @import("degrad.zig");
const degToRad = degrad.degToRad;
const radToDeg = degrad.radToDeg;

const ae = @import("modules/zig-approxeql/approxeql.zig");

const DBG = false;

/// Builds a Pitch Yaw Roll Rotation matrix from point with x, y, z angles in radians.
pub fn rotateCwPitchYawRollV3f32(point: V3f32) M44f32 {
    if (DBG) warn("rotateCwPitchYawRollV3f32: point={}\n", &point);
    return rotateCwPitchYawRoll(point.x(), point.y(), point.z());
}

/// Builds a Pitch Yaw Roll Rotation matrix from y, x, z angles in radians.
pub fn rotateCwPitchYawRoll(x: f32, y: f32, z: f32) M44f32 {
    const rx = RotateCwX(x);
    const ry = RotateCwY(y);
    const rz = RotateCwZ(z);

    var m = mulM44f32(&rz, &mulM44f32(&ry, &rx));
    if (DBG) warn("rotateCwPitchYawRoll x={.5} y={.5} z={.5} m:\n{}\n", x, y, z, &m);

    return m;
}

/// Builds a Pitch Yaw Roll Rotation matrix from x, y, z angles in radians.
pub fn rotateCwPitchYawRollNeg(x: f32, y: f32, z: f32) M44f32 {
    const rx = RotateCwX(x);
    const ry = RotateCwY(y);
    const rz = RotateCwZ(z);

    var m = mulM44f32(&rx, &mulM44f32(&ry, &rz));
    if (DBG) warn("rotateCwPitchYawRollNeg x={.5} y={.5} z={.5} m:\n{}\n", x, y, z, &m);

    return m;
}

// Return a `M44f32` for x axis Clockwise
// Bug: This rotates Monkey Counter Clockwise
fn RotateCwX(x: f32) M44f32 {
    const rx = M44f32{ .data = [][4]f32{
        []f32{ 1.0, 0.0, 0.0, 0.0 },
        []f32{ 0.0, math.cos(x), math.sin(x), 0.0 },
        []f32{ 0.0, -math.sin(x), math.cos(x), 0.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotateCwX x={.5} rx:\n{}\n", x, &rx);
    return rx;
}

// Return a `M44f32` for y axis that rotates Clockwise
// Bug: This rotates Monkey Counter Clockwise
fn RotateCwY(y: f32) M44f32 {
    const ry = M44f32{ .data = [][4]f32{
        []f32{ math.cos(y), 0.0, -math.sin(y), 0.0 },
        []f32{ 0.0, 1.0, 0.0, 0.0 },
        []f32{ math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotateCwY y={.5} ry:\n{}\n", y, &ry);
    return ry;
}

// Return a `M44f32` for z axis Clockwise.
fn RotateCwZ(z: f32) M44f32 {
    const rz = M44f32{ .data = [][4]f32{
        []f32{ math.cos(z), math.sin(z), 0.0, 0.0 },
        []f32{ -math.sin(z), math.cos(z), 0.0, 0.0 },
        []f32{ 0.0, 0.0, 1.0, 0.0 },
        []f32{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotateCwZ z={.5} rz:\n{}\n", z, &rz);
    return rz;
}

test "rotation.rotateCwX" {
    if (DBG) warn("\n");
    const radians: f32 = degToRad(10.0);
    var m = RotateCwX(radians);
    if (DBG) warn("m:\n{}\n", &m);
    var c: f32 = math.cos(radians);
    var s: f32 = math.sin(radians);
    assert(m.data[1][1] == c);
    assert(m.data[2][2] == c);
    assert(m.data[1][2] == s);
    assert(m.data[2][1] == -s);

    var point = V3f32.init(0, 1, 0);
    if (DBG) warn("point: {}\n", &point);
    var rot_point = point.transform(&m);
    if (DBG) warn("rot_point: {}\n", &rot_point);
    assert(rot_point.x() == 0);
    assert(ae.approxEql(rot_point.y(), c, 7));
    assert(ae.approxEql(rot_point.z(), s, 7));
}

test "rotation.rotateCwY" {
    if (DBG) warn("\n");
    const radians: f32 = degToRad(10.0);
    var m = RotateCwY(radians);
    if (DBG) warn("m:\n{}\n", &m);
    var c: f32 = math.cos(radians);
    var s: f32 = math.sin(radians);
    assert(m.data[0][0] == c);
    assert(m.data[2][2] == c);
    assert(m.data[0][2] == -s);
    assert(m.data[2][0] == s);

    var point = V3f32.init(0, 0, 1);
    if (DBG) warn("point: {}\n", &point);
    var rot_point = point.transform(&m);
    if (DBG) warn("rot_point: {}\n", &rot_point);
    assert(ae.approxEql(rot_point.x(), s, 7));
    assert(rot_point.y() == 0);
    assert(ae.approxEql(rot_point.z(), c, 7));
}

test "rotation.rotateCwZ" {
    if (DBG) warn("\n");
    const radians: f32 = degToRad(10.0);
    var m = RotateCwZ(radians);
    if (DBG) warn("m:\n{}\n", &m);
    var c: f32 = math.cos(radians);
    var s: f32 = math.sin(radians);
    assert(m.data[0][0] == c);
    assert(m.data[1][1] == c);
    assert(m.data[0][1] == s);
    assert(m.data[1][0] == -s);

    var point = V3f32.init(0, 1, 0);
    if (DBG) warn("point: {}\n", &point);
    var rot_point = point.transform(&m);
    if (DBG) warn("rot_point: {}\n", &rot_point);
    assert(ae.approxEql(rot_point.x(), -s, 7));
    assert(ae.approxEql(rot_point.y(), c, 7));
    assert(rot_point.z() == 0);
}

test "rotation.rotateCwPitchYawRoll" {
    if (DBG) warn("\n");
    const radians: f32 = degToRad(10.0);
    var m_zero = rotateCwPitchYawRoll(0, 0, 0);

    var m_x_pos_ten_deg = rotateCwPitchYawRoll(radians, 0, 0);
    var m_x_neg_ten_deg = rotateCwPitchYawRoll(-radians, 0, 0);
    var x = mulM44f32(&m_x_pos_ten_deg, &m_x_neg_ten_deg);
    if (DBG) warn("m_x_pos_ten_deg:\n{}\n", &m_x_pos_ten_deg);
    if (DBG) warn("m_x_neg_ten_deg:\n{}\n", &m_x_neg_ten_deg);
    if (DBG) warn("x = pos * neg:\n{}\n", &x);
    assert(matrix.approxEql(&m_zero, &x, 7));

    var m_y_pos_ten_deg = rotateCwPitchYawRoll(0, radians, 0);
    var m_y_neg_ten_deg = rotateCwPitchYawRoll(0, -radians, 0);
    var y = mulM44f32(&m_y_pos_ten_deg, &m_y_neg_ten_deg);
    if (DBG) warn("m_y_pos_ten_deg:\n{}\n", m_y_pos_ten_deg);
    if (DBG) warn("m_y_neg_ten_deg:\n{}\n", m_y_neg_ten_deg);
    if (DBG) warn("y = pos * neg:\n{}\n", &y);
    assert(matrix.approxEql(&m_zero, &y, 7));

    var m_z_pos_ten_deg = rotateCwPitchYawRoll(0, 0, radians);
    var m_z_neg_ten_deg = rotateCwPitchYawRoll(0, 0, -radians);
    var z = mulM44f32(&m_z_pos_ten_deg, &m_z_neg_ten_deg);
    if (DBG) warn("m_z_neg_ten_deg:\n{}\n", m_z_neg_ten_deg);
    if (DBG) warn("m_z_pos_ten_deg:\n{}\n", m_z_pos_ten_deg);
    if (DBG) warn("z = pos * neg:\n{}\n", &z);
    assert(matrix.approxEql(&m_zero, &z, 7));

    var xy_pos = mulM44f32(&m_x_pos_ten_deg, &m_y_pos_ten_deg);
    var a = mulM44f32(&xy_pos, &m_y_neg_ten_deg);
    var b = mulM44f32(&a, &m_x_neg_ten_deg);
    if (DBG) warn("xy_pos = x_pos_ten * y_pos_ten:\n{}\n", &xy_pos);
    if (DBG) warn("a = xy_pos * y_pos_ten\n{}\n", &a);
    if (DBG) warn("b = a * x_pos_ten\n{}\n", &b);
    assert(matrix.approxEql(&m_zero, &b, 7));

    // To undo a rotateCwPitchYawRoll the multiplication in rotateCwPitchYawRoll
    // must be applied in reverse order.  mulM44f32(&rz, &mulM44f32(&ry, &rx))
    //   1) r1 = ry * rx
    //   2) r2 = rz * ry
    // must be applied:
    //   1) r3 = -rz * r2
    //   2) r4 = -ry * r3
    //   3) r5 = -rx * r4
    var r2 = rotateCwPitchYawRoll(radians, radians, radians);
    if (DBG) warn("r2:\n{}\n", &r2);
    var r3 = mulM44f32(&m_z_neg_ten_deg, &r2);
    var r4 = mulM44f32(&m_y_neg_ten_deg, &r3);
    var r5 = mulM44f32(&m_x_neg_ten_deg, &r4);
    if (DBG) warn("r5:\n{}\n", &r5);
    assert(matrix.approxEql(&m_zero, &r5, 7));

    // Here is the above as a single line both are equal to m_zero
    r5 = mulM44f32(&m_x_neg_ten_deg, &mulM44f32(&m_y_neg_ten_deg, &mulM44f32(&m_z_neg_ten_deg, &r2)));
    if (DBG) warn("r5 one line:\n{}\n", &r5);
    assert(matrix.approxEql(&m_zero, &r5, 7));

    // Or you can use rotateCwPitchYawRollNeg
    var rneg = rotateCwPitchYawRollNeg(-radians, -radians, -radians);
    if (DBG) warn("rneg:\n{}\n", &rneg);
    var r6 = mulM44f32(&rneg, &r2);
    if (DBG) warn("r6:\n{}\n", &r6);
    assert(matrix.approxEql(&m_zero, &r6, 7));
}
