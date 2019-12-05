///
/// This file centralises the GSL (which I use for common linear algebra) and
/// my humble glm-like library, for practical stack-allocated linear algebra.
///


///
/// The GLAlgebra code, which forms the set of types I use for GL-compatible
/// linear algebra types. This supports swizzling, and as many cool things as
/// possible from the GL shading langage.
///
pub const glalg = @import("glalgebra.zig") ;


///
/// Aliased types to the GNU Scientific Library. Those types are
/// heap-allocated using malloc, given that I wrote this in the still early
/// days of Zig and there was no common allocator back then. Maybe this is
/// still the case, actually.
///
pub const gsl  = @import("gsl.zig") ;


// At some point, there should be a set of conversion functions between the
// two (GLAlgebra and the GSL).

