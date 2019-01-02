const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;
const bufPrint = std.fmt.bufPrint;

const matrix = @import("matrix.zig");
const Matrix = matrix.Matrix;
const M44f32 = matrix.M44f32;
const m44f32_unit = matrix.m44f32_unit;
const ae = @import("modules/zig-approxeql/approxeql.zig");
const tc = @import("typeconversions.zig");

const misc = @import("modules/zig-misc/index.zig");
const testExpected = misc.testExpected;

const DBG = false;

pub fn Vec(comptime T: type, comptime size: usize) type {
    if (@typeId(T) != TypeId.Float) @compileError("Vec only support TypeId.Floats at this time");

    switch (size) {
        2 => {
            return struct {
                const Self = @This();

                pub data: [2]T,

                pub fn init(xp: T, yp: T) Self {
                    return Self{ .data = []T{ xp, yp } };
                }

                pub fn initVal(val: T) Self {
                    return Vec(T, size).init(val, val);
                }

                pub fn x(pSelf: *const Self) T {
                    return pSelf.data[0];
                }

                pub fn y(pSelf: *const Self) T {
                    return pSelf.data[1];
                }

                pub fn setX(pSelf: *Self, v: T) void {
                    pSelf.data[0] = v;
                }

                pub fn setY(pSelf: *Self, v: T) void {
                    pSelf.data[1] = v;
                }

                pub fn eql(pSelf: *const Self, pOther: *const Self) bool {
                    return pSelf.x() == pOther.x() and pSelf.y() == pOther.y();
                }

                pub fn approxEql(pSelf: *const Self, pOther: *const Self, digits: usize) bool {
                    return ae.approxEql(pSelf.x(), pOther.x(), digits) and
                        ae.approxEql(pSelf.y(), pOther.y(), digits);
                }

                pub fn neg(pSelf: *const Self) Self {
                    return Vec(T, size).init(-pSelf.x(), -pSelf.y());
                }

                pub fn scale(pSelf: *const Self, factor: T) Self {
                    return Vec(T, size).init(pSelf.x() * factor, pSelf.y() * factor);
                }

                pub fn add(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init((pSelf.x() + pOther.x()), (pSelf.y() + pOther.y()));
                }

                pub fn sub(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() - pOther.x()),
                        (pSelf.y() - pOther.y()),
                    );
                }

                pub fn mul(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() * pOther.x()),
                        (pSelf.y() * pOther.y()),
                    );
                }

                pub fn div(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() / pOther.x()),
                        (pSelf.y() / pOther.y()),
                    );
                }

                /// Returns the length as a f64, f32 or f16
                pub fn length(pSelf: *const Self) T {
                    return math.sqrt(pSelf.normal());
                }

                pub fn dot(pSelf: *const Self, pOther: *const Self) T {
                    return (pSelf.x() * pOther.x()) + (pSelf.y() * pOther.y());
                }

                pub fn normal(pSelf: *const Self) T {
                    return (pSelf.x() * pSelf.x()) + (pSelf.y() * pSelf.y());
                }

                pub fn normalize(pSelf: *const Self) Self {
                    var len = pSelf.length();
                    var v: Self = undefined;
                    if (len > 0) {
                        v.setX(pSelf.x() / len);
                        v.setY(pSelf.y() / len);
                    } else {
                        v = pSelf.*;
                    }
                    return v;
                }

                /// Custom format routine
                pub fn format(
                    self: *const Self,
                    comptime fmt: []const u8,
                    context: var,
                    comptime FmtError: type,
                    output: fn (@typeOf(context), []const u8) FmtError!void,
                ) FmtError!void {
                    try formatVec(T, size, self, fmt, context, FmtError, output);
                }
            };
        },
        3 => {
            return struct {
                const Self = @This();

                pub data: [3]T,

                pub fn init(xp: T, yp: T, zp: T) Self {
                    return Self{ .data = []T{ xp, yp, zp } };
                }

                pub fn initVal(val: T) Self {
                    return Vec(T, size).init(val, val, val);
                }

                pub fn unitX() Self {
                    return Self.init(1, 0, 0);
                }

                pub fn unitY() Self {
                    return Self.init(0, 1, 0);
                }

                pub fn unitZ() Self {
                    return Self.init(0, 0, 1);
                }

                pub fn x(pSelf: *const Self) T {
                    return pSelf.data[0];
                }

                pub fn y(pSelf: *const Self) T {
                    return pSelf.data[1];
                }

                pub fn z(pSelf: *const Self) T {
                    return pSelf.data[2];
                }

                pub fn setX(pSelf: *Self, v: T) void {
                    pSelf.data[0] = v;
                }

                pub fn setY(pSelf: *Self, v: T) void {
                    pSelf.data[1] = v;
                }

                pub fn setZ(pSelf: *Self, v: T) void {
                    pSelf.data[2] = v;
                }

                pub fn eql(pSelf: *const Self, pOther: *const Self) bool {
                    return pSelf.x() == pOther.x() and
                        pSelf.y() == pOther.y() and
                        pSelf.z() == pOther.z();
                }

                pub fn approxEql(pSelf: *const Self, pOther: *const Self, digits: usize) bool {
                    return ae.approxEql(pSelf.x(), pOther.x(), digits) and
                        ae.approxEql(pSelf.y(), pOther.y(), digits) and
                        ae.approxEql(pSelf.z(), pOther.z(), digits);
                }

                pub fn neg(pSelf: *const Self) Self {
                    return Vec(T, size).init(-pSelf.x(), -pSelf.y(), -pSelf.z());
                }

                pub fn scale(pSelf: *const Self, factor: T) Self {
                    return Vec(T, size).init(pSelf.x() * factor, pSelf.y() * factor, pSelf.z() * factor);
                }

                pub fn add(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() + pOther.x()),
                        (pSelf.y() + pOther.y()),
                        (pSelf.z() + pOther.z()),
                    );
                }

                pub fn sub(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() - pOther.x()),
                        (pSelf.y() - pOther.y()),
                        (pSelf.z() - pOther.z()),
                    );
                }

                pub fn mul(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() * pOther.x()),
                        (pSelf.y() * pOther.y()),
                        (pSelf.z() * pOther.z()),
                    );
                }

                pub fn div(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.x() / pOther.x()),
                        (pSelf.y() / pOther.y()),
                        (pSelf.z() / pOther.z()),
                    );
                }

                /// Returns the length as a f64, f32 or f16
                pub fn length(pSelf: *const Self) T {
                    return math.sqrt(pSelf.normal());
                }

                pub fn dot(pSelf: *const Self, pOther: *const Self) T {
                    return (pSelf.x() * pOther.x()) +
                        (pSelf.y() * pOther.y()) +
                        (pSelf.z() * pOther.z());
                }

                pub fn normal(pSelf: *const Self) T {
                    return (pSelf.x() * pSelf.x()) + (pSelf.y() * pSelf.y()) + (pSelf.z() * pSelf.z());
                }

                pub fn normalize(pSelf: *const Self) Self {
                    var len = pSelf.length();
                    var v: Self = undefined;
                    if (len > 0) {
                        v.setX(pSelf.x() / len);
                        v.setY(pSelf.y() / len);
                        v.setZ(pSelf.z() / len);
                    } else {
                        v = pSelf.*;
                    }
                    return v;
                }

                /// Custom format routine
                pub fn format(
                    self: *const Self,
                    comptime fmt: []const u8,
                    context: var,
                    comptime FmtError: type,
                    output: fn (@typeOf(context), []const u8) FmtError!void,
                ) FmtError!void {
                    try formatVec(T, size, self, fmt, context, FmtError, output);
                }

                pub fn cross(pSelf: *const Self, pOther: *const Self) Self {
                    return Vec(T, size).init(
                        (pSelf.y() * pOther.z()) - (pSelf.z() * pOther.y()),
                        (pSelf.z() * pOther.x()) - (pSelf.x() * pOther.z()),
                        (pSelf.x() * pOther.y()) - (pSelf.y() * pOther.x()),
                    );
                }

                pub fn transform(pSelf: *const Self, m: *const Matrix(T, 4, 4)) Self {
                    var vx = pSelf.x();
                    var vy = pSelf.y();
                    var vz = pSelf.z();
                    const rx = (vx * m.data[0][0]) + (vy * m.data[1][0]) + (vz * m.data[2][0]) + m.data[3][0];
                    const ry = (vx * m.data[0][1]) + (vy * m.data[1][1]) + (vz * m.data[2][1]) + m.data[3][1];
                    const rz = (vx * m.data[0][2]) + (vy * m.data[1][2]) + (vz * m.data[2][2]) + m.data[3][2];
                    var rw = (vx * m.data[0][3]) + (vy * m.data[1][3]) + (vz * m.data[2][3]) + m.data[3][3];

                    if (rw != 1) {
                        rw = 1.0 / rw;
                    }
                    return Self.init(rx * rw, ry * rw, rz * rw);
                }
            };
        },
        else => @compileError("Only Vec size 2 and 3 supported"),
    }
}

pub const V2f32 = Vec(f32, 2);
pub const V3f32 = Vec(f32, 3);

/// Custom format routine
fn formatVec(
    comptime T: type,
    comptime size: usize,
    pSelf: *const Vec(T, size),
    comptime fmt: []const u8,
    context: var,
    comptime FmtError: type,
    output: fn (@typeOf(context), []const u8) FmtError!void,
) FmtError!void {
    try std.fmt.format(context, FmtError, output, "[]{} {{ ", @typeName(T));
    for (pSelf.data) |col, i| {
        try std.fmt.format(context, FmtError, output, "{}{.5}{}", if (math.signbit(col)) "-" else " ", if (math.signbit(col)) -col else col, if (i < (pSelf.data.len - 1)) ", " else " ");
    }
    try std.fmt.format(context, FmtError, output, "}}");
}

test "vec3.init" {
    const vf64 = Vec(f64, 3).initVal(0);
    assert(vf64.x() == 0);
    assert(vf64.y() == 0);
    assert(vf64.z() == 0);

    const vf32 = Vec(f32, 3).initVal(1);
    assert(vf32.x() == 1);
    assert(vf32.y() == 1);
    assert(vf32.z() == 1);

    var v1 = V3f32.init(1, 2, 3);
    assert(v1.x() == 1);
    assert(v1.y() == 2);
    assert(v1.z() == 3);

    v1 = V3f32.unitX();
    assert(v1.x() == 1);
    assert(v1.y() == 0);
    assert(v1.z() == 0);

    v1 = V3f32.unitY();
    assert(v1.x() == 0);
    assert(v1.y() == 1);
    assert(v1.z() == 0);

    v1 = V3f32.unitZ();
    assert(v1.x() == 0);
    assert(v1.y() == 0);
    assert(v1.z() == 1);
}

test "vec3.copy" {
    var v1 = Vec(f32, 3).init(1, 2, 3);
    assert(v1.x() == 1);
    assert(v1.y() == 2);
    assert(v1.z() == 3);

    // Copy a vector
    var v2 = v1;
    assert(v2.x() == 1);
    assert(v2.y() == 2);
    assert(v2.z() == 3);

    // Copy via a pointer
    var pV1 = &v1;
    var v3 = pV1.*;
    assert(v3.x() == 1);
    assert(v3.y() == 2);
    assert(v3.z() == 3);
}

test "vec3.eql" {
    const v1 = Vec(f32, 3).init(1.2345678, 2.3456789, 3.4567890);
    const v2 = Vec(f32, 3).init(1.2345678, 2.3456789, 3.4567890);
    assert(v1.eql(&v2));
}

test "vec3.approxEql" {
    const v1 = Vec(f32, 3).init(1.2345678, 2.3456789, 3.4567890);
    const v2 = Vec(f32, 3).init(1.2345600, 2.3456700, 3.4567800);
    assert(v1.approxEql(&v2, 1));
    assert(v1.approxEql(&v2, 2));
    assert(v1.approxEql(&v2, 3));
    assert(v1.approxEql(&v2, 4));
    assert(v1.approxEql(&v2, 5));
    assert(v1.approxEql(&v2, 6));
    assert(!v1.approxEql(&v2, 7));
    assert(!v1.approxEql(&v2, 8));
}

test "vec2.neg" {
    const v1 = V2f32.init(1, 2);
    const v2 = V2f32.init(-1, -2);
    assert(v2.eql(&v1.neg()));
}

test "vec3.neg" {
    const v1 = V3f32.init(1, 2, 3);
    const v2 = V3f32.init(-1, -2, -3);
    assert(v2.eql(&v1.neg()));
}

test "vec2.scale" {
    const factor = f32(0.5);
    const v1 = V2f32.init(1, 2);
    const v2 = V2f32.init(1 * factor, 2 * factor);
    assert(v2.eql(&v1.scale(factor)));
}

test "vec3.scale" {
    const factor = f32(0.5);
    const v1 = V3f32.init(1, 2, 3);
    const v2 = V3f32.init(1 * factor, 2 * factor, 3 * factor);
    assert(v2.eql(&v1.scale(factor)));
}

test "vec3.add" {
    const v1 = Vec(f32, 3).init(3, 2, 1);
    const v2 = Vec(f32, 3).init(1, 2, 3);
    const v3 = v1.add(&v2);
    assert(v3.x() == 4);
    assert(v3.y() == 4);
    assert(v3.z() == 4);
}

test "vec3.sub" {
    const v1 = Vec(f32, 3).init(3, 2, 1);
    const v2 = Vec(f32, 3).init(1, 2, 3);
    const v3 = v1.sub(&v2);
    assert(v3.x() == 2);
    assert(v3.y() == 0);
    assert(v3.z() == -2);
}

test "vec3.mul" {
    const v1 = Vec(f32, 3).init(3, 2, 1);
    const v2 = Vec(f32, 3).init(1, 2, 3);
    const v3 = v1.mul(&v2);
    assert(v3.x() == 3);
    assert(v3.y() == 4);
    assert(v3.z() == 3);
}

test "vec3.div" {
    const v1 = Vec(f32, 3).init(3, 2, 1);
    const v2 = Vec(f32, 3).init(1, 2, 3);
    const v3 = v1.div(&v2);
    assert(v3.x() == 3);
    assert(v3.y() == 1);
    assert(v3.z() == f32(1.0 / 3.0));
}

test "vec2.format" {
    var buf: [100]u8 = undefined;

    const v2 = Vec(f32, 2).init(2, 1);
    var result = try bufPrint(buf[0..], "v2={}", v2);
    if (DBG) warn("\nvec.format: {}\n", result);
    assert(testExpected("v2=[]f32 {  2.00000,  1.00000 }", result));
}

test "vec3.format" {
    var buf: [100]u8 = undefined;

    const v3 = Vec(f32, 3).init(3, 2, 1);
    var result = try bufPrint(buf[0..], "v3={}", v3);
    if (DBG) warn("vec3.format: {}\n", result);
    assert(testExpected("v3=[]f32 {  3.00000,  2.00000,  1.00000 }", result));
}

test "vec2.length" {
    const x = f32(3);
    const y = f32(4);
    const v1 = V2f32.init(x, y);
    var len = v1.length();
    if (DBG) warn("vec2.length: {}\n", len);
    assert(len == math.sqrt((x * x) + (y * y)));
}

test "vec3.length" {
    const x = f32(3);
    const y = f32(4);
    const z = f32(5);
    const v1 = V3f32.init(x, y, z);
    var len = v1.length();
    if (DBG) warn("vec3.length: {}\n", len);
    assert(len == math.sqrt((x * x) + (y * y) + (z * z)));
}

test "vec3.dot" {
    if (DBG) warn("\n");
    const v1 = Vec(f32, 3).init(3, 2, 1);
    const v2 = Vec(f32, 3).init(1, 2, 3);
    var d = v1.dot(&v2);
    if (DBG) warn("d={.3}\n", d);
    assert(d == (3 * 1) + (2 * 2) + (3 * 1));

    // Sqrt of the dot product of itself is the length
    assert(math.sqrt(v2.dot(&v2)) == v2.length());
}

test "vec3.normal" {
    var v0 = Vec(f32, 3).initVal(0);
    assert(v0.normal() == 0);

    v0 = Vec(f32, 3).init(4, 5, 6);
    assert(v0.normal() == 4 * 4 + 5 * 5 + 6 * 6);
}

test "vec3.normalize" {
    var v0 = Vec(f32, 3).initVal(0);
    var v1 = v0.normalize();
    assert(v1.x() == 0);
    assert(v1.y() == 0);
    assert(v1.z() == 0);

    v0 = Vec(f32, 3).init(1, 1, 1);
    v1 = v0.normalize();
    var len: f32 = math.sqrt(1.0 + 1.0 + 1.0);
    assert(v1.x() == 1.0 / len);
    assert(v1.y() == 1.0 / len);
    assert(v1.z() == 1.0 / len);
}

test "vec3.cross" {
    if (DBG) warn("\n");
    var v1 = Vec(f32, 3).init(1, 0, 0); // Unit Vector X
    var v2 = Vec(f32, 3).init(0, 1, 0); // Unit Vector Y

    // Cross product of two unit vectors on X,Y yields unit vector Z
    var v3 = v1.cross(&v2);
    assert(v3.x() == 0);
    assert(v3.y() == 0);
    assert(v3.z() == 1);

    v1 = V3f32.init(1.5, 2.5, 3.5);
    v2 = V3f32.init(4.5, 3.5, 2.5);
    v3 = v1.cross(&v2);
    if (DBG) warn("v3={}\n", &v3);
    assert(v3.eql(&V3f32.init(
                (v1.y() * v2.z()) - (v1.z() * v2.y()),
                (v1.z() * v2.x()) - (v1.x() * v2.z()),
                (v1.x() * v2.y()) - (v1.y() * v2.x())
          ))
    );

    v1 = Vec(f32, 3).init(3, 2, 1);
    v2 = Vec(f32, 3).init(1, 2, 3);
    v3 = v1.cross(&v2);
    assert(v3.x() == 4);
    assert(v3.y() == -8);
    assert(v3.z() == 4);

    // Changing the order yields neg.
    var v4 = v2.cross(&v1);
    assert(v3.x() == -v4.x());
    assert(v3.y() == -v4.y());
    assert(v3.z() == -v4.z());
    assert(v4.eql(&v3.neg()));
}

test "vec3.transform" {
    if (DBG) warn("\n");
    var v1 = V3f32.init(2, 3, 4);
    var v2 = v1.transform(&m44f32_unit);
    assert(v1.eql(&v2));

    var m1 = M44f32.initVal(0.2);
    v1 = V3f32.init(0.5, 0.5, 0.5);
    v2 = v1.transform(&m1);
    if (DBG) warn("v1:\n{}\nm1:\n{}\nv2:\n{}\n", &v1, &m1, &v2);
    assert(v2.eql(&V3f32.init(1, 1, 1)));

    m1.data[3][3] = 1;
    v2 = v1.transform(&m1);
    if (DBG) warn("v1:\n{}\nm1:\n{}\nv2:\n{}\n", &v1, &m1, &v2);
    assert(v2.approxEql(&V3f32.init(0.3846154, 0.3846154, 0.3846154), 6));
}

test "vec3.world.to.screen" {
    if (DBG) warn("\n");
    const T = f32;
    const M44 = Matrix(T, 4, 4);
    const fov: T = 90;
    const widthf: T = 512;
    const heightf: T = 512;
    const width: u32 = @floatToInt(u32, 512);
    const height: u32 = @floatToInt(u32, 512);
    const aspect: T = widthf / heightf;
    const znear: T = 0.01;
    const zfar: T = 1.0;
    var camera_to_perspective_matrix = matrix.perspectiveM44(T, fov, aspect, znear, zfar);

    var world_to_camera_matrix = M44f32.initUnit();
    world_to_camera_matrix.data[3][2] = 2;

    var world_vertexs = []V3f32{
        V3f32.init(0, 1.0, 0),
        V3f32.init(0, -1.0, 0),
        V3f32.init(0, 1.0, 0.2),
        V3f32.init(0, -1.0, -0.2),
    };
    var expected_camera_vertexs = []V3f32{
        V3f32.init(0, 1.0, 2),
        V3f32.init(0, -1.0, 2.0),
        V3f32.init(0, 1.0, 2.2),
        V3f32.init(0, -1.0, 1.8),
    };
    var expected_projected_vertexs = []V3f32{
        V3f32.init(0, 0.30869, 1.00505),
        V3f32.init(0, -0.30869, 1.00505),
        V3f32.init(0, 0.28062, 1.00551),
        V3f32.init(0, -0.34298, 1.00449),
    };
    var expected_screen_vertexs = [][2]u32{
        []u32{ 256, 176 },
        []u32{ 256, 335 },
        []u32{ 256, 184 },
        []u32{ 256, 343 },
    };
    for (world_vertexs) |world_vert, i| {
        if (DBG) warn("world_vert[{}]  = {}\n", i, &world_vert);

        var camera_vert = world_vert.transform(&world_to_camera_matrix);
        if (DBG) warn("camera_vert    = {}\n", camera_vert);
        assert(camera_vert.approxEql(&expected_camera_vertexs[i], 6));

        var projected_vert = camera_vert.transform(&camera_to_perspective_matrix);
        if (DBG) warn("projected_vert = {}", projected_vert);
        assert(projected_vert.approxEql(&expected_projected_vertexs[i], 6));

        var xf = projected_vert.x();
        var yf = projected_vert.y();
        if (DBG) warn(" {.3}:{.3}", xf, yf);
        if ((xf < -1) or (xf > 1) or (yf < -1) or (yf > 1)) {
            if (DBG) warn(" clipped\n");
        }

        var x = @floatToInt(u32, math.min(widthf - 1, (xf + 1) * 0.5 * widthf));
        var y = @floatToInt(u32, math.min(heightf - 1, (1 - (yf + 1) * 0.5) * heightf));
        if (DBG) warn(" visible {}:{}\n", x, y);
        assert(x == expected_screen_vertexs[i][0]);
        assert(y == expected_screen_vertexs[i][1]);
    }
}
