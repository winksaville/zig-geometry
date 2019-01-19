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
    normal: V3f32,

    pub fn init(a: usize, b: usize, c: usize, normal: V3f32) Face {
        return Face {
            .a = a, .b = b, .c = c, .normal = normal
        };
    }

    pub fn initComputeNormal(vertexes: []const Vertex, a: usize, b: usize, c: usize) Face {
        var normal = computeFaceNormal(vertexes, a, b, c);
        return Face.init(a, b, c, normal);
    }
};

pub fn computeFaceNormal(vertexes: []const Vertex, a: usize, b: usize, c: usize) V3f32 {
    // Get the corresponding vertice coordinates
    const v3a = vertexes[a].coord;
    const v3b = vertexes[b].coord;
    const v3c = vertexes[c].coord;

    // Use two edges and compute the face normal and return it
    var ab: V3f32 = v3a.sub(&v3b);
    var bc: V3f32 = v3b.sub(&v3c);

    return ab.cross(&bc);
}

pub const Vertex = struct {
    pub fn init(x: f32, y: f32, z: f32) Vertex {
        return Vertex{
            .coord = V3f32.init(x, y, z),
            .world_coord = V3f32.init(0, 0, 0),
            .normal_coord = V3f32.init(0, 0, 0),
            .texture_coord = V2f32.init(0, 0),
        };
    }

    pub coord: V3f32,
    pub world_coord: V3f32,
    pub normal_coord: V3f32,
    pub texture_coord: V2f32,
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

            var nm = computeFaceNormal(msh.vertices, face.a, face.b, face.c);
            if (dbg) warn(" nm={}\n", nm);

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
        .texture_coord = undefined,
    };
    assert(mesh.vertices[0].coord.x() == -1);
    assert(mesh.vertices[0].coord.y() == 1);
    assert(mesh.vertices[0].coord.z() == 1);
    mesh.vertices[1] = Vertex{
        .coord = V3f32.init(1, 1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[1].coord.x() == 1);
    assert(mesh.vertices[1].coord.y() == 1);
    assert(mesh.vertices[1].coord.z() == 1);
    mesh.vertices[2] = Vertex{
        .coord = V3f32.init(-1, -1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[2].coord.x() == -1);
    assert(mesh.vertices[2].coord.y() == -1);
    assert(mesh.vertices[2].coord.z() == 1);
    mesh.vertices[3] = Vertex{
        .coord = V3f32.init(1, -1, 1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[3].coord.x() == 1);
    assert(mesh.vertices[3].coord.y() == -1);
    assert(mesh.vertices[3].coord.z() == 1);

    mesh.vertices[4] = Vertex{
        .coord = V3f32.init(-1, 1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[4].coord.x() == -1);
    assert(mesh.vertices[4].coord.y() == 1);
    assert(mesh.vertices[4].coord.z() == -1);
    mesh.vertices[5] = Vertex{
        .coord = V3f32.init(1, 1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[5].coord.x() == 1);
    assert(mesh.vertices[5].coord.y() == 1);
    assert(mesh.vertices[5].coord.z() == -1);
    mesh.vertices[6] = Vertex{
        .coord = V3f32.init(1, -1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[6].coord.x() == 1);
    assert(mesh.vertices[6].coord.y() == -1);
    assert(mesh.vertices[6].coord.z() == -1);
    mesh.vertices[7] = Vertex{
        .coord = V3f32.init(-1, -1, -1),
        .world_coord = undefined,
        .normal_coord = undefined,
        .texture_coord = undefined,
    };
    assert(mesh.vertices[7].coord.x() == -1);
    assert(mesh.vertices[7].coord.y() == -1);
    assert(mesh.vertices[7].coord.z() == -1);

    // The cube has 6 side each composed
    // of 2 trianglar faces on the side
    // for 12 faces;
    mesh.faces[0] = Face.initComputeNormal(mesh.vertices, 0, 1, 2);
    mesh.faces[1] = Face.initComputeNormal(mesh.vertices, 1, 2, 3);
    mesh.faces[2] = Face.initComputeNormal(mesh.vertices, 1, 3, 6);
    mesh.faces[3] = Face.initComputeNormal(mesh.vertices, 1, 5, 6);
    mesh.faces[4] = Face.initComputeNormal(mesh.vertices, 0, 1, 4);
    mesh.faces[5] = Face.initComputeNormal(mesh.vertices, 1, 4, 5);

    mesh.faces[6] = Face.initComputeNormal(mesh.vertices, 2, 3, 7);
    mesh.faces[7] = Face.initComputeNormal(mesh.vertices, 3, 6, 7);
    mesh.faces[8] = Face.initComputeNormal(mesh.vertices, 0, 2, 7);
    mesh.faces[9] = Face.initComputeNormal(mesh.vertices, 0, 4, 7);
    mesh.faces[10] = Face.initComputeNormal(mesh.vertices, 4, 5, 6);
    mesh.faces[11] = Face.initComputeNormal(mesh.vertices, 4, 6, 7);
}
