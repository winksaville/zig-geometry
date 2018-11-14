# Geomtry for 3D graphics engine in zig

Some matrix and vector objects's for use in 3D graphics.
I'm just learning so use/peruse with care.

Developed while trying to learn 3D graphics using [Scrachapixel 2.0](https://www.scratchapixel.com/)
and working through David Rousset's
[tutorial](https://www.davrous.com/2013/06/13/tutorial-series-learning-how-to-write-a-3d-soft-engine-from-scratch-in-c-typescript-or-javascript/)
which uses [SharpDx](https://github.com/sharpdx/SharpDX).

[Zig](https://ziglang.org) is developed by Andrew Kelly and his community, and I used his math3d library from [Tetris](https://github.com/andrewrk/tetris) for initial code developement.

## Dependencies besides Zig

Co-module dependencies, expects ../zig-misc, ../zig-approxeql to exist.


## Test
```
$ zig test matrix.zig --test-filter matrix
Test 1/10 matrix.init...OK
Test 2/10 matrix.eql...OK
Test 3/10 matrix.1x1*1x1...OK
Test 4/10 matrix.2x2*2x2...OK
Test 5/10 matrix.1x2*2x1...OK
Test 6/10 matrix.i32.1x2*2x1...OK
Test 7/10 matrix.format.f32...OK
Test 8/10 matrix.format.i32...OK
Test 9/10 matrix.approxEql...OK
Test 10/10 matrix.perspectiveM44...OK
All tests passed.

$ zig test vec.zig --test-filter vec
Test 1/19 vec3.init...OK
Test 2/19 vec3.copy...OK
Test 3/19 vec3.eql...OK
Test 4/19 vec3.approxEql...OK
Test 5/19 vec2.neg...OK
Test 6/19 vec3.neg...OK
Test 7/19 vec3.add...OK
Test 8/19 vec3.sub...OK
Test 9/19 vec3.mul...OK
Test 10/19 vec3.div...OK
Test 11/19 vec2.format...OK
Test 12/19 vec3.format...OK
Test 13/19 vec3.length...OK
Test 14/19 vec3.dot...OK
Test 15/19 vec3.normal...OK
Test 16/19 vec3.normalize...OK
Test 17/19 vec3.cross...OK
Test 18/19 vec3.transform...OK
Test 19/19 vec3.world_to_screen...OK
All tests passed.
```
