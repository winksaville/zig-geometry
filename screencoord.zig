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

const DBG = false;

pub fn pointToScreenCoord(widthf: f32, heightf: f32, pos_x: f32, pos_y: f32) V2f32 {
    // The transformed coord is based on a coordinate system
    // where the origin is the center of the screen. Convert
    // them to coordindates where x:0, y:0 is the upper left.
    var x = (pos_x + 1) * 0.5 * widthf;
    var y = (1 - ((pos_y + 1) * 0.5)) * heightf;
    if (DBG) warn("pointToScreenCoord:  pos_x={.3} pos_y={.3} x={.3} y={.3} widthf={.3} heightf={.3}\n", pos_x, pos_y, x, y, widthf, heightf);
    return V2f32.init(x, y);
}

test "screencoord.pointToScreenCoord" {
    const x: f32 = 0.1;
    const y: f32 = 0.2;
    var screen = pointToScreenCoord(640, 480, x, y);
    assert(screen.x() == (x + 1) * 0.5 * 640);
    assert(screen.y() == (1 - ((y + 1) * 0.5)) * 480);
}

pub fn projectToScreenCoord(widthf: f32, heightf: f32, coord: V3f32, transMat: *const M44f32) V2f32 {
    if (DBG) warn("projectToScreenCoord:    original coord={} widthf={.3} heightf={.3}\n", &coord, widthf, heightf);

    // Transform coord in 3D
    var point = coord.transform(transMat);
    if (DBG) warn("projectToScreenCoord: transformed point={}\n", &point);

    return pointToScreenCoord(widthf, heightf, point.x(), point.y());
}

test "screencoord.projectToScreenCoord" {
    var width: f32 = 640;
    var height: f32 = 480;
    var coord: V3f32 = undefined;
    var screen: V2f32 = undefined;
    var point: V2f32 = undefined;

    const view_matrix = M44f32{ .data = [][4]f32{
        []f32{ 1.00000, 0.00000, 0.00000, 0.00000 },
        []f32{ 0.00000, 1.00000, 0.00000, 0.00000 },
        []f32{ 0.00000, 0.00000, 1.00000, 0.00000 },
        []f32{ 0.00000, 0.00000, 10.00000, 1.00000 },
    } };

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
