const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const math = std.math;

const geo = @import("index.zig");
const V2f32 = geo.V2f32;
const V3f32 = geo.V3f32;
const M44f32 = geo.M44f32;

const DBG = false;
const DBG1 = false;

pub const Face = struct {
    a: usize,
    b: usize,
    c: usize,
};

pub const Vertex = struct {
    pub fn init(x: f32, y: f32, z: f32) Vertex {
        return Vertex{
            .coord = V3f32.init(x, y, z),
            .world_coord = V3f32.init(0, 0, 0),
            .normal_coord = V3f32.init(0, 0, 0),
        };
    }

    pub coord: V3f32,
    pub world_coord: V3f32,
    pub normal_coord: V3f32,
};

pub const Mesh = struct {
    const Self = @This();

    pub name: []const u8,
    pub position: V3f32,
    pub rotation: V3f32,
    pub vertices: []Vertex,
    pub faces: []Face,

    pub fn init(pAllocator: *Allocator, name: []const u8, vertices_count: usize, faces_count: usize) !Self {
        return Self{
            .name = name,
            .position = V3f32.init(0.0, 0.0, 0.0),
            .rotation = V3f32.init(0.0, 0.0, 0.0),
            .vertices = try pAllocator.alloc(Vertex, vertices_count),
            .faces = try pAllocator.alloc(Face, faces_count),
        };
    }
};

/// Compute the normal for each vertice. Assume the faces in the mesh
/// are ordered counter clockwise so the computed normal always points
/// "out".
///
/// Note: From http://www.iquilezles.org/www/articles/normals/normals.htm
pub fn computeVerticeNormalsDbg(comptime dbg: bool, meshes: []Mesh) void {
    if (dbg) warn("computeVn:\n");
    // Loop over each mesh
    for (meshes) |msh| {
        // Zero the normal_coord of each vertex
        for (msh.vertices) |*vertex, i| {
            vertex.normal_coord = V3f32.initVal(0);
        }

        // Calculate the face normal and sum the normal into its vertices
        for (msh.faces) |face| {
            if (dbg) warn(" v{}:v{}:v{}\n", face.a, face.b, face.c);

            var a: V3f32 = msh.vertices[face.a].coord;
            var b: V3f32 = msh.vertices[face.b].coord;
            var c: V3f32 = msh.vertices[face.c].coord;
            if (dbg) warn("    {}={}  {}={}  {}={}\n", face.a, a, face.b, b, face.c, c);

            // Use two edges and compute the face normal
            var ab: V3f32 = a.sub(&b);
            var bc: V3f32 = b.sub(&c);
            var nm = ab.cross(&bc);
            if (dbg) warn("   ab={} bc={} nm={}", ab, bc, nm);

            // Sum the face normals into this faces vertices.normal_coord
            msh.vertices[face.a].normal_coord = msh.vertices[face.a].normal_coord.add(&nm);
            msh.vertices[face.b].normal_coord = msh.vertices[face.b].normal_coord.add(&nm);
            msh.vertices[face.c].normal_coord = msh.vertices[face.c].normal_coord.add(&nm);
            if (dbg) {
                warn("  s {}={}  {}={}  {}={}\n", face.a, msh.vertices[face.a].normal_coord, face.b, msh.vertices[face.b].normal_coord, face.c, msh.vertices[face.c].normal_coord);
            }
        }

        // Normalize each vertex
        for (msh.vertices) |*vertex, i| {
            if (dbg) warn(" nrm v{}.normal_coord={}", i, vertex.normal_coord);
            vertex.normal_coord = vertex.normal_coord.normalize();
            if (dbg) warn(" v{}.normal_coord.normalized={}\n", i, vertex.normal_coord);
        }
    }
}

/// Compute the normal for each vertice. Assume the faces in the mesh
/// are ordered counter clockwise so the computed normal always points
/// "out".
pub fn computeVerticeNormals(meshes: []Mesh) void {
    computeVerticeNormalsDbg(false, meshes);
}

test "mesh" {
    if (DBG or DBG1) warn("\n");
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var mesh = try Mesh.init(pAllocator, "mesh1", 8, 12);
    assert(std.mem.eql(u8, mesh.name[0..], "mesh1"));
    assert(mesh.position.x() == 0.0);
    assert(mesh.position.data[1] == 0.0);
    assert(mesh.position.data[2] == 0.0);
    assert(mesh.rotation.data[0] == 0.0);
    assert(mesh.rotation.data[1] == 0.0);
    assert(mesh.rotation.data[2] == 0.0);

    // Unit cube about 0,0,0
    mesh.vertices[0] = Vertex{
        .coord = V3f32.init(-1, 1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[0].coord.x() == -1);
    assert(mesh.vertices[0].coord.y() == 1);
    assert(mesh.vertices[0].coord.z() == 1);
    mesh.vertices[1] = Vertex{
        .coord = V3f32.init(1, 1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[1].coord.x() == 1);
    assert(mesh.vertices[1].coord.y() == 1);
    assert(mesh.vertices[1].coord.z() == 1);
    mesh.vertices[2] = Vertex{
        .coord = V3f32.init(-1, -1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[2].coord.x() == -1);
    assert(mesh.vertices[2].coord.y() == -1);
    assert(mesh.vertices[2].coord.z() == 1);
    mesh.vertices[3] = Vertex{
        .coord = V3f32.init(1, -1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[3].coord.x() == 1);
    assert(mesh.vertices[3].coord.y() == -1);
    assert(mesh.vertices[3].coord.z() == 1);

    mesh.vertices[4] = Vertex{
        .coord = V3f32.init(-1, 1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[4].coord.x() == -1);
    assert(mesh.vertices[4].coord.y() == 1);
    assert(mesh.vertices[4].coord.z() == -1);
    mesh.vertices[5] = Vertex{
        .coord = V3f32.init(1, 1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[5].coord.x() == 1);
    assert(mesh.vertices[5].coord.y() == 1);
    assert(mesh.vertices[5].coord.z() == -1);
    mesh.vertices[6] = Vertex{
        .coord = V3f32.init(1, -1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[6].coord.x() == 1);
    assert(mesh.vertices[6].coord.y() == -1);
    assert(mesh.vertices[6].coord.z() == -1);
    mesh.vertices[7] = Vertex{
        .coord = V3f32.init(-1, -1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
    };
    assert(mesh.vertices[7].coord.x() == -1);
    assert(mesh.vertices[7].coord.y() == -1);
    assert(mesh.vertices[7].coord.z() == -1);

    // The cube has 6 side each composed
    // of 2 trianglar faces on the side
    // for 12 faces;
    mesh.faces[0] = Face{ .a = 0, .b = 1, .c = 2 };
    mesh.faces[1] = Face{ .a = 1, .b = 2, .c = 3 };
    mesh.faces[2] = Face{ .a = 1, .b = 3, .c = 6 };
    mesh.faces[3] = Face{ .a = 1, .b = 5, .c = 6 };
    mesh.faces[4] = Face{ .a = 0, .b = 1, .c = 4 };
    mesh.faces[5] = Face{ .a = 1, .b = 4, .c = 5 };

    mesh.faces[6] = Face{ .a = 2, .b = 3, .c = 7 };
    mesh.faces[7] = Face{ .a = 3, .b = 6, .c = 7 };
    mesh.faces[8] = Face{ .a = 0, .b = 2, .c = 7 };
    mesh.faces[9] = Face{ .a = 0, .b = 4, .c = 7 };
    mesh.faces[10] = Face{ .a = 4, .b = 5, .c = 6 };
    mesh.faces[11] = Face{ .a = 4, .b = 6, .c = 7 };
}
