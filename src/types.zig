///
/// My own favourite pile of aliases.
///

pub const glalg = @import("maths/glalgebra.zig") ;

pub const Scalar = f32 ;

pub const Vec2  = glalg.Vec2(Scalar) ;
pub const Vec3  = glalg.Vec3(Scalar) ;

pub const Vec2i = glalg.Vec2(i32) ;
pub const Vec3i = glalg.Vec3(i32) ;

pub const Vec2u = glalg.Vec2(u32) ;
pub const Vec3u = glalg.Vec3(u32) ;

