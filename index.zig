pub use @import("matrix.zig");
pub use @import("vec.zig");
pub use @import("rotation.zig");
pub use @import("translation.zig");
pub use @import("lookat.zig");
pub use @import("screencoord.zig");
pub use @import("mesh.zig");

const math = @import("std").math;

pub fn rad(d: var) @typeOf(d) {
    const T = @typeOf(d);
    return d * T(math.pi) / T(180.0);
}

pub fn deg(r: var) @typeOf(r) {
    const T = @typeOf(r);
    return r * T(180.0) / T(math.pi);
}
