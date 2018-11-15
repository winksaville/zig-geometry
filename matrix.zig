const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const math = std.math;
const meta = std.meta;
const assert = std.debug.assert;
const warn = std.debug.warn;
const bufPrint = std.fmt.bufPrint;

const ae = @import("../zig-approxeql/approxeql.zig");

const misc = @import("../zig-misc/index.zig");
const testExpected = misc.testExpected;

const DBG = false;

pub fn Matrix(comptime T: type, comptime m: usize, comptime n: usize) type {
    return struct {
        const Self = @This();
        const row_cnt = m;
        const col_cnt = n;

        pub data: [m][n]T,

        /// Create an uninitialized Matrix
        pub fn create() Self {
            return Self{ .data = undefined };
        }

        /// Initialize Matrix to a value
        pub fn initVal(val: T) Self {
            var r = Self.create();
            return r.visit(fillFunc, val).*;
        }

        /// Initialize Matrix as a Unit matrix with 1's on the diagonal
        pub fn initUnit() Self {
            var r = Self.create();
            return r.visit(unitFunc, 0).*;
        }

        /// Return true of pSelf.data == pOther.data
        pub fn eql(pSelf: *const Self, pOther: *const Self) bool {
            for (pSelf.data) |row, i| {
                for (row) |val, j| {
                    if (val != pOther.data[i][j]) return false;
                }
            }
            return true;
        }

        /// Visit each matrix value starting at [0][0], [0][1] .. [m][n]
        /// calling func for each passing the Matrix and current i, j plus
        /// the parameter. To continue looping func returns true or false
        /// to stop looping.
        pub fn visit(
            pSelf: *Self,
            comptime func: fn (pSelf: *Self, i: usize, j: usize, param: var) bool,
            param: var,
        ) *Self {
            // Unroll the loops for speed
            comptime var i: usize = 0;
            done: inline while (i < m) : (i += 1) {
                //warn("visit {}:", i);
                comptime var j: usize = 0;
                inline while (j < n) : (j += 1) {
                    if (!func(pSelf, i, j, param)) {
                        break :done;
                    }
                    //warn(" {}", pSelf.data[i][j]);
                }
                //warn("\n");
            }
            return pSelf;
        }

        /// Custom format routine for Mat4x4
        pub fn format(
            self: *const Self,
            comptime fmt: []const u8,
            context: var,
            comptime FmtError: type,
            output: fn (@typeOf(context), []const u8) FmtError!void,
        ) FmtError!void {
            for (self.data) |row, i| {
                try std.fmt.format(context, FmtError, output, "[]{}.{{ ", @typeName(T));
                for (row) |col, j| {
                    switch (@typeId(T)) {
                        TypeId.Float => try std.fmt.format(context, FmtError, output, "{.7}{}", col, if (j < (col_cnt - 1)) ", " else " "),
                        TypeId.Int => try std.fmt.format(context, FmtError, output, "{}{}", col, if (j < (col_cnt - 1)) ", " else " "),
                        else => @compileError("Only Float and Int types are supported"),
                    }
                }
                try std.fmt.format(context, FmtError, output, "}}");
                if (row_cnt > 1) {
                    if (i < (row_cnt - 1)) {
                        try std.fmt.format(context, FmtError, output, ",\n");
                    } else {
                        try std.fmt.format(context, FmtError, output, ",");
                    }
                }
            }
        }

        fn unitFunc(pSelf: *Self, i: usize, j: usize, param: var) bool {
            pSelf.data[i][j] = if (i == j) T(1) else T(0);
            return true;
        }

        fn fillFunc(pSelf: *Self, i: usize, j: usize, param: var) bool {
            pSelf.data[i][j] = param;
            return true;
        }
    };
}

/// Returns a struct.mul function that multiplies m1 by m2
pub fn MatrixMultiplier(comptime m1: type, comptime m2: type) type {
    const m1_DataType = @typeInfo(@typeInfo(meta.fieldInfo(m1, "data").field_type).Array.child).Array.child;
    const m2_DataType = @typeInfo(@typeInfo(meta.fieldInfo(m2, "data").field_type).Array.child).Array.child;

    // What other validations should I check
    if (m1_DataType != m2_DataType) {
        @compileError("m1:" ++ @typeName(m1_DataType) ++ " != m2:" ++ @typeName(m2_DataType));
    }

    if (m1.col_cnt != m2.row_cnt) {
        @compileError("m1.col_cnt: m1.col_cnt != m2.row_cnt");
    }
    const DataType = m1_DataType;
    const row_cnt = m1.row_cnt;
    const col_cnt = m2.col_cnt;
    return struct {
        pub fn mul(mt1: *const m1, mt2: *const m2) Matrix(DataType, row_cnt, col_cnt) {
            var r = Matrix(DataType, row_cnt, col_cnt).create();
            comptime var i: usize = 0;
            inline while (i < row_cnt) : (i += 1) {
                //warn("mul {}:\n", i);
                comptime var j: usize = 0;
                inline while (j < col_cnt) : (j += 1) {
                    //warn(" ({}:", j);
                    comptime var k: usize = 0;
                    // The inner loop is m1.col_cnt or m2.row_cnt, which are equal
                    inline while (k < m1.col_cnt) : (k += 1) {
                        var val = mt1.data[i][k] * mt2.data[k][j];
                        if (k == 0) {
                            r.data[i][j] = val;
                            //warn(" {}:{}={} * {}", k, val, mt1.data[i][k], mt2.data[k][j]);
                        } else {
                            r.data[i][j] += val;
                            //warn(" {}:{}={} * {}", k, val, mt1.data[i][k], mt2.data[k][j]);
                        }
                    }
                    //warn(" {})\n", r.data[i][j]);
                }
            }
            return r;
        }
    };
}

pub const M44f32 = Matrix(f32, 4, 4);
pub const m44f32_unit = M44f32.initUnit();
pub const m44f32_zero = M44f32.initVal(0);
pub const mulM44f32 = MatrixMultiplier(M44f32, M44f32).mul;

test "matrix.init" {
    if (DBG) warn("\n");
    const mf32 = Matrix(f32, 4, 4).initVal(1);
    if (DBG) warn("matrix.init: m4x4f32 init(1)\n{}", &mf32);

    for (mf32.data) |row| {
        for (row) |val| {
            assert(val == 1);
        }
    }

    const mf64 = Matrix(f64, 4, 4).initUnit();
    if (DBG) warn("matrix.init: mf64 initUnit\n{}", &mf64);
    for (mf64.data) |row, i| {
        for (row) |val, j| {
            if (i == j) {
                assert(val == 1);
            } else {
                assert(val == 0);
            }
        }
    }

    // Maybe initUnit shouldn't allow non-square values
    // See test "initUnit" for a possible solution
    const m2x4 = Matrix(f32, 2, 4).initUnit();
    if (DBG) warn("2x4: initUnit\n{}", &m2x4);
    for (m2x4.data) |row, i| {
        for (row) |val, j| {
            if (i == j) {
                assert(val == 1);
            } else {
                assert(val == 0);
            }
        }
    }
}

// Example of using visit outside of Matrix
// to create a unit matrix.
//
// I'm not completely happy with this as M1x1 in this
// example needed to be declared globally.
test "initUnit" {
    var m1x1 = M1x1.create();
    initUnit(&m1x1);
    if (DBG) warn("matrix.initUnit: 1x1 initUnit\n{}", &m1x1);
    const t1x1 = M1x1.initUnit();
    assert(m1x1.eql(&t1x1));
}

// Define the Matrix globaly so unitFunc can know the type
const M1x1 = Matrix(f32, 1, 1);

// Initialize Matrix as a Unit matrix with 1's on the diagonal
pub fn initUnit(pMat: var) void {
    comptime const T = @typeOf(pMat.*);
    comptime if (T.row_cnt != T.col_cnt) @compileError("initUnit can't be used on non-square Matrix's");
    _ = T.visit(pMat, unitFunc, 0);
}
fn unitFunc(pMat: *M1x1, i: usize, j: usize, param: var) bool {
    const T = @typeInfo(@typeInfo(meta.fieldInfo(@typeOf(pMat.*), "data").field_type).Array.child).Array.child;
    pMat.data[i][j] = if (i == j) T(1) else T(0);
    return true;
}
//test "initUnit.fails" {
//    var m4x2 = Matrix(f32, 4, 2).create();
//    initUnit(&m4x2);
//    if (DBG) warn("matrix.initUnit.fails: 4x2 initUnit\n{}", m4x2);
//}

test "matrix.eql" {
    if (DBG) warn("\n");
    const m0 = Matrix(f32, 4, 4).initVal(0);
    for (m0.data) |row| {
        for (row) |val| {
            assert(val == 0);
        }
    }
    var o0 = Matrix(f32, 4, 4).initVal(0);
    assert(m0.eql(&o0));

    // Modify last value and verify !eql
    o0.data[3][3] = 1;
    if (DBG) warn("matrix.eql: o0\n{}", &o0);
    assert(!m0.eql(&o0));

    // Modify first value and verify !eql
    o0.data[0][0] = 1;
    if (DBG) warn("matrix.eql: o0\n{}", &o0);
    assert(!m0.eql(&o0));

    // Restore back to 0 and verify eql
    o0.data[3][3] = 0;
    o0.data[0][0] = 0;
    if (DBG) warn("matrix.eql: o0\n{}", &o0);
    assert(m0.eql(&o0));
}

test "matrix.1x1*1x1" {
    if (DBG) warn("\n");

    const m1 = Matrix(f32, 1, 1).initVal(2);
    if (DBG) warn("matrix.1x1*1x1: m1\n{}", &m1);

    const m2 = Matrix(f32, 1, 1).initVal(3);
    if (DBG) warn("matrix.1x1*1x1: m2\n{}", &m2);

    const m3 = MatrixMultiplier(@typeOf(m1), @typeOf(m2)).mul(&m1, &m2);
    if (DBG) warn("matrix.1x1*1x1: m3\n{}", &m3);

    var expected = Matrix(f32, 1, 1).create();
    expected.data = [][1]f32{[]f32{(m1.data[0][0] * m2.data[0][0])}};
    if (DBG) warn("matrix.1x1*1x1: expected\n{}", &expected);
    assert(m3.eql(&expected));
}

test "matrix.2x2*2x2" {
    if (DBG) warn("\n");

    var m1 = Matrix(f32, 2, 2).create();
    m1.data = [][2]f32{
        []f32{ 1, 2 },
        []f32{ 3, 4 },
    };
    if (DBG) warn("matrix.2x2*2x2: m1\n{}", &m1);

    var m2 = Matrix(f32, 2, 2).create();
    m2.data = [][2]f32{
        []f32{ 5, 6 },
        []f32{ 7, 8 },
    };
    if (DBG) warn("matrix.2x2*2x2: m2\n{}", &m2);

    const m3 = MatrixMultiplier(@typeOf(m1), @typeOf(m2)).mul(&m1, &m2);
    if (DBG) warn("matrix.2x2*2x2: m3\n{}", &m3);

    var expected = Matrix(f32, 2, 2).create();
    expected.data = [][2]f32{
        []f32{
            (m1.data[0][0] * m2.data[0][0]) + (m1.data[0][1] * m2.data[1][0]),
            (m1.data[0][0] * m2.data[0][1]) + (m1.data[0][1] * m2.data[1][1]),
        },
        []f32{
            (m1.data[1][0] * m2.data[0][0]) + (m1.data[1][1] * m2.data[1][0]),
            (m1.data[1][0] * m2.data[0][1]) + (m1.data[1][1] * m2.data[1][1]),
        },
    };
    if (DBG) warn("matrix.2x2*2x2: expected\n{}", &expected);
    assert(m3.eql(&expected));
}

test "matrix.1x2*2x1" {
    if (DBG) warn("\n");

    var m1 = Matrix(f32, 1, 2).create();
    m1.data = [][2]f32{[]f32{ 3, 4 }};
    if (DBG) warn("matrix.1x2*2x1: m1\n{}", &m1);

    var m2 = Matrix(f32, 2, 1).create();
    m2.data = [][1]f32{
        []f32{5},
        []f32{7},
    };
    if (DBG) warn("matrix.1x2*2x1: m2\n{}", &m2);

    const m3 = MatrixMultiplier(@typeOf(m1), @typeOf(m2)).mul(&m1, &m2);
    if (DBG) warn("matrix.1x2*2x1: m3\n{}", &m3);

    var expected = Matrix(f32, 1, 1).create();
    expected.data = [][1]f32{[]f32{(m1.data[0][0] * m2.data[0][0]) + (m1.data[0][1] * m2.data[1][0])}};
    if (DBG) warn("matrix.1x2*2x1: expected\n{}", &expected);
    assert(m3.eql(&expected));
}

test "matrix.i32.1x2*2x1" {
    if (DBG) warn("\n");

    var m1 = Matrix(i32, 1, 2).create();
    m1.data = [][2]i32{[]i32{ 3, 4 }};
    if (DBG) warn("matrix.i32.1x2*2x1: m1\n{}", &m1);

    var m2 = Matrix(i32, 2, 1).create();
    m2.data = [][1]i32{
        []i32{5},
        []i32{7},
    };
    if (DBG) warn("matrix.i32.1x2*2x1: m2\n{}", &m2);

    const m3 = MatrixMultiplier(@typeOf(m1), @typeOf(m2)).mul(&m1, &m2);
    if (DBG) warn("matrix.i32.1x2*2x1: m3\n{}", &m3);

    var expected = Matrix(i32, 1, 1).create();
    expected.data = [][1]i32{[]i32{(m1.data[0][0] * m2.data[0][0]) + (m1.data[0][1] * m2.data[1][0])}};
    if (DBG) warn("matrix.i32.1x2*2x1: expected\n{}", &expected);
    assert(m3.eql(&expected));
}

test "matrix.format.f32" {
    var buf: [256]u8 = undefined;

    const v2 = Matrix(f32, 1, 2).initVal(2);
    var result = try bufPrint(buf[0..], "v2={}", v2);
    if (DBG) warn("\nmatrix.format: {}\n", result);
    assert(testExpected("v2=[]f32.{ 2.0000000, 2.0000000 }", result));

    const v3 = Matrix(f32, 3, 3).initVal(4);
    result = try bufPrint(buf[0..], "v3\n{}", v3);
    if (DBG) warn("matrix.format: {}\n", result);
    assert(testExpected(
        \\v3
        \\[]f32.{ 4.0000000, 4.0000000, 4.0000000 },
        \\[]f32.{ 4.0000000, 4.0000000, 4.0000000 },
        \\[]f32.{ 4.0000000, 4.0000000, 4.0000000 },
    , result));
}

test "matrix.format.i32" {
    var buf: [100]u8 = undefined;

    const v2 = Matrix(i32, 1, 2).initVal(2);
    var result = try bufPrint(buf[0..], "v2={}", v2);
    if (DBG) warn("\nmatrix.format: {}\n", result);
    assert(testExpected("v2=[]i32.{ 2, 2 }", result));

    const v3 = Matrix(i32, 3, 3).initVal(4);
    result = try bufPrint(buf[0..], "v3\n{}", v3);
    if (DBG) warn("matrix.format: {}\n", result);
    assert(testExpected(
        \\v3
        \\[]i32.{ 4, 4, 4 },
        \\[]i32.{ 4, 4, 4 },
        \\[]i32.{ 4, 4, 4 },
    , result));
}

/// Return true of pSelf.data == pOther.data
pub fn approxEql(pSelf: var, pOther: var, digits: usize) bool {
    for (pSelf.data) |row, i| {
        for (row) |val, j| {
            if (!ae.approxEql(val, pOther.data[i][j], digits)) return false;
        }
    }
    return true;
}

test "matrix.approxEql" {
    if (DBG) warn("\n");
    const m0 = Matrix(f32, 4, 4).initVal(1.234567);
    const m1 = Matrix(f32, 4, 4).initVal(1.234578);
    assert(approxEql(&m0, &m1, 1));
    assert(approxEql(&m0, &m1, 2));
    assert(approxEql(&m0, &m1, 3));
    assert(approxEql(&m0, &m1, 4));
    assert(approxEql(&m0, &m1, 5));
    assert(!approxEql(&m0, &m1, 6));
    assert(!approxEql(&m0, &m1, 7));
    assert(!approxEql(&m0, &m1, 8));
}

/// Creates a perspective project matrix
/// BasedOn: https://github.com/sharpdx/SharpDX/blob/755cb46d59f4bfb94386ff2df3fceccc511c216b/Source/SharpDX.Mathematics/Matrix.cs#L2328
/// and: https://www.scratchapixel.com/code.php?id=4&origin=/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix
pub fn perspectiveM44(comptime T: type, fovDegrees: T, aspect: T, znear: T, zfar: T) Matrix(T, 4, 4) {
    var scale: T = 1.0 / math.tan(T(fovDegrees * math.pi / 180.0) * 0.5);
    var q = -zfar / (zfar - znear);

    return Matrix(T, 4, 4){ .data = [][4]T{
        []T{ scale / aspect, 0, 0, 0 },
        []T{ 0, scale, 0, 0 },
        []T{ 0, 0, q, -1.0 },
        []T{ 0, 0, q * znear, 0 },
    } };
}

test "matrix.perspectiveM44" {
    const T = f32;
    const M44 = Matrix(T, 4, 4);
    const fov: T = 90;
    const widthf: T = 512;
    const heightf: T = 512;
    const aspect: T = widthf / heightf;
    const znear: T = 0.01;
    const zfar: T = 1.0;
    var camera_to_perspective_matrix = perspectiveM44(T, fov, aspect, znear, zfar);

    var expected: M44 = undefined;
    expected.data = [][4]T{
        []T{ 1, 0, 0, 0 },
        []T{ 0, 1, 0, 0 },
        []T{ 0, 0, -1.01010, -1 },
        []T{ 0, 0, -0.01010, 0 },
    };
    assert(approxEql(&camera_to_perspective_matrix, &expected, 5));
}
