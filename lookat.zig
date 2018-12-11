const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;

const matrix = @import("matrix.zig");
const Matrix = matrix.Matrix;
const M44f32 = matrix.M44f32;

const vec = @import("vec.zig");
const V3f32 = vec.V3f32;
const V2f32 = vec.V2f32;

const sc = @import("screencoord.zig");
const projectToScreenCoord = sc.projectToScreenCoord;
const pointToScreenCoord = sc.pointToScreenCoord;

const DBG = false;

/// Create look-at matrix
pub fn lookAtLh(eye: *const V3f32, target: *const V3f32, up: *const V3f32) M44f32 {
    if (DBG) warn("math3d.lookAtLh: eye {} target {}\n", eye, target);

    var zaxis = target.sub(eye).normalize();
    var xaxis = up.cross(&zaxis).normalize();
    var yaxis = zaxis.cross(&xaxis);

    // Column major order?
    var cmo = M44f32{ .data = [][4]f32{
        []f32{ xaxis.x(), yaxis.x(), zaxis.x(), 0 },
        []f32{ xaxis.y(), yaxis.y(), zaxis.y(), 0 },
        []f32{ xaxis.z(), yaxis.z(), zaxis.z(), 0 },
        []f32{ -xaxis.dot(eye), -yaxis.dot(eye), -zaxis.dot(eye), 1 },
    } };

    // Row major order?
    var rmo = M44f32{ .data = [][4]f32{
        []f32{ xaxis.x(), xaxis.y(), xaxis.z(), -xaxis.dot(eye) },
        []f32{ yaxis.x(), yaxis.y(), yaxis.z(), -yaxis.dot(eye) },
        []f32{ zaxis.x(), zaxis.y(), zaxis.z(), -zaxis.dot(eye) },
        []f32{ 0, 0, 0, 1 },
    } };

    var result = cmo;
    if (DBG) warn("math3d.lookAtLh: result\n{}", &result);
    return result;
}

test "lookat" {
    var width: f32 = 640;
    var height: f32 = 480;
    var scn_x: f32 = undefined;
    var scn_y: f32 = undefined;
    var coord: V3f32 = undefined;
    var screen: V2f32 = undefined;
    var point: V2f32 = undefined;

    var eye = V3f32.init(0, 0, -10);
    var target = V3f32.init(0, 0, 0);
    var view_matrix = lookAtLh(&eye, &target, &V3f32.unitY());

    const expected = M44f32{ .data = [][4]f32{
        []f32{ 1.00000, 0.00000, 0.00000, 0.00000 },
        []f32{ 0.00000, 1.00000, 0.00000, 0.00000 },
        []f32{ 0.00000, 0.00000, 1.00000, 0.00000 },
        []f32{ 0.00000, 0.00000, 10.00000, 1.00000 },
    } };
    assert(matrix.approxEql(&view_matrix, &expected, 7));

    coord = V3f32.init(0, 0, 0);
    screen = projectToScreenCoord(width, height, coord, &view_matrix);
    if (DBG) warn("math3d.lookAtLh: coord={} screen={}\n", &coord, &screen);
    assert(screen.x() == 320);
    assert(screen.y() == 240);

    coord = V3f32.init(0.1, 0.1, 0);
    screen = projectToScreenCoord(width, height, coord, &view_matrix);
    if (DBG) warn("math3d.lookAtLh: coord={} screen={}\n", &coord, &screen);
    point = pointToScreenCoord(width, height, 0.1, 0.1);
    if (DBG) warn("math3d.lookAtLh: point={}\n", &point);
    assert(screen.x() == point.x());
    assert(screen.y() == point.y());

    coord = V3f32.init(-0.1, -0.1, 0);
    screen = projectToScreenCoord(width, height, coord, &view_matrix);
    if (DBG) warn("math3d.lookAtLh: coord={} screen={}\n", &coord, &screen);
    point = pointToScreenCoord(width, height, -0.1, -0.1);
    if (DBG) warn("math3d.lookAtLh: point={}\n", &point);
    assert(screen.x() == point.x());
    assert(screen.y() == point.y());
}
