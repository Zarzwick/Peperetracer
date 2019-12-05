///
/// This module defines lightweight common vector types (and probably at some
/// point small matrices) to avoid the heavy allocated GSL types (with the
/// guarantee that is can be used for OpenGL).
///


const std = @import("std") ;


///
/// Assess that a given type is indeed a Mat(Scalar, _, 1) or Mat(Scalar, 1, )
/// for some compile-time functionnalities.
///
pub fn isVec(comptime Scalar: type, comptime T: type) bool {
    return (T == Mat(Scalar, 2, 1)) or (T == Mat(Scalar, 1, 2)) or
           (T == Mat(Scalar, 3, 1)) or (T == Mat(Scalar, 1, 3)) or
           (T == Mat(Scalar, 4, 1)) or (T == Mat(Scalar, 1, 4)) ;
}


///
/// The main {Mat,Vec}{2,3,4} type. It is made to ressemble GLM, however it is
/// _not_ benchmarked in any way. That's a FIXME I'll do at some point :D
///
pub fn Mat(comptime Scalar: type, comptime M: u32, comptime N: u32) type {
    return struct {
        data: [M*N]Scalar,

        const Self = @This() ;

        pub fn rows() usize {
            return M ;
        }

        pub fn cols() usize {
            return N ;
        }

        pub fn size() usize {
            return M*N ;
        }

        pub fn x(self: Self) Scalar { return self.data[0] ; }
        pub fn y(self: Self) Scalar { return self.data[1] ; }
        pub fn z(self: Self) Scalar {
            if (Self.size() < 3)
                unreachable ;
            return self.data[2] ;
        }
        pub fn w(self: Self) Scalar {
            if (Self.size() < 4)
                unreachable ;
            return self.data[3] ;
        }

        ///
        /// Return a vector/matrix filled with zeros.
        ///
        pub fn zeros() Self {
            return Self { .data = [_]Scalar {0} ** (M*N) } ;
        }

        ///
        /// Return a vector/matrix filled with ones.
        ///
        pub fn ones() Self {
            return Self { .data = [_]Scalar {1} ** (M*N) } ;
        }

        ///
        /// Build an identity square matrix.
        ///
        pub fn identity() Self {
            if (M == N) {
                const m : u32 = M ;
                var mat = Self.zeros() ;
                var i : u32 = 0 ;
                while (i < m) : (i += 1) {
                    mat.data[i+i*m] = 1 ;
                }
                return mat ;
            } else {
                //@compileError("Can only build square identity matrices.") ;
                unreachable ;
            }
        }

        ///
        /// Generate a vector from a sequence of vectors and scalars.
        ///
        fn vecFrom(args: ...) Self {
            var self : Self = undefined ;
            comptime const d = Self.size() ;

            if (args.len == 0 or args.len > d) {
                //@compileError("Invalid number of arguments.") ;
                unreachable ;
            }

            comptime var next_arg = 0 ;
            comptime var next_coeff = 0 ;

            inline while ((next_arg < args.len) and (next_coeff < d))
            : (next_arg += 1) {
                const arg = args[next_arg] ;

                // This is required by now.
                // TODO Submit a bug report or find a related issue.
                comptime const is_vec = isVec(Scalar, @typeOf(arg)) ;

                if (@typeOf(arg) == Scalar) {
                    self.data[next_coeff] = arg ;
                    next_coeff += 1 ;
                } else if (is_vec) {
                    comptime const darg = @typeOf(arg).size() ;
                    comptime var i = 0 ;
                    inline while (i < darg) : (i += 1) {
                        self.data[next_coeff] = arg.data[i] ;
                        next_coeff += 1 ;
                    }
                } else {
                    @compileError("Bad argument.") ;
                }
            }

            if (next_arg != args.len) {
                @compileError("Arguments unused.") ;
            }

            inline while (next_coeff < d) : (next_coeff += 1) {
                self.data[next_coeff] = 0 ;
            }

            return self ;
        }

        ///
        /// Generate a variable of type @This, given a list of arguments which
        /// can be scalars or other valuations of the Mat type. Values left
        /// unspecified will be padded with 0.
        ///
        pub fn from(args: ...) Self {
            comptime const is_vec = isVec(Scalar, Self) ;
            if (is_vec) {
                return vecFrom(args) ;
            } else {
                @compileError("Aha") ;
            }
        }

        ///
        /// Add two vectors/matrices.
        ///
        pub fn add(a: Self, b: Self) Self {
            var mat : Self = undefined ;
            comptime var i = 0 ;
            inline while (i < M*N) : (i += 1) {
                mat.data[i] = a.data[i] + b.data[i] ;
            }
            return mat ;
        }

        ///
        /// Subtract two vectors/matrices.
        ///
        pub fn subtract(a: Self, b: Self) Self {
            var mat : Self = undefined ;
            comptime var i = 0 ;
            inline while (i < M*N) : (i += 1) {
                mat.data[i] = a.data[i] - b.data[i] ;
            }
            return mat ;
        }

        ///
        /// Multiply component-wise.
        ///
        pub fn times(a: Self, b: Self) Self {
            var mat : Self = undefined ;
            comptime var i = 0 ;
            inline while (i < M*N) : (i += 1) {
                mat.data[i] = a.data[i] * b.data[i] ;
            }
            return mat ;
        }

        ///
        /// Divide component-wise.
        ///
        pub fn over(a: Self, b: Self) Self {
            var mat : Self = undefined ;
            comptime var i = 0 ;
            inline while (i < M*N) : (i += 1) {
                mat.data[i] = a.data[i] / b.data[i] ;
            }
            return mat ;
        }

        ///
        /// Compute the L2-norm of the vector/matrix.
        ///
        pub fn norm(self: Self) Scalar {
            return std.math.sqrt(self.normSquared()) ;
        }

        ///
        /// Compute the squared L2-norm of the vector/matrix.
        ///
        pub fn normSquared(self: Self) Scalar {
            comptime const is_vec = isVec(Scalar, Self) ;
            if (! is_vec) {
                //@compileError("Norm not yet implemented for matrices...") ;
                unreachable ;
            }

            var res : Scalar = 0.0 ;
            comptime const d = Self.size() ;
            comptime var i = 0 ;
            inline while (i < d) : (i += 1) {
                res += self.data[i] * self.data[i] ;
            }
            return res ;
        }

        ///
        /// Return a normalised copy of the matrix/vector.
        ///
        pub fn normalised(self: Self) Self {
            const n = self.norm() ;
            var o : Self = self ;
            comptime const d = Self.size() ;
            comptime var i = 0 ;
            inline while (i < d) : (i += 1) {
                o.data[i] /= n ;
            }
            return o ;
        }

        ///
        /// Returns the type that would be generated by a dot product.
        ///
        fn dotType(comptime B: type) type {
            comptime const A = Self ;
            if (A == B) {
                return Scalar ;
            } else if (A.cols() != B.rows()) {
                @compileError("Dot product between incompatible matrices.") ;
            } else {
                return Mat(Scalar, A.rows(), B.cols()) ;
            }
        }

        ///
        /// Dot (inner) product.
        ///
        pub fn dot(self: Self, o: var) dotType(@typeOf(o)) {
            if (Self == @typeOf(o)) {
                return self.data[0] * o.data[0] +
                       self.data[1] * o.data[1] +
                       self.data[2] * o.data[2] ;
            } else {
                var mat = dotType(@typeOf(o)).zeros() ;
                const ar = Self.rows() ;
                const ac = Self.cols() ;
                const br = @typeOf(o).rows() ;
                const bc = @typeOf(o).cols() ;
                var i : u32 = 0 ;
                while (i < ar) : (i += 1) {
                    var j : usize = 0 ;
                    while (j < bc) : (j += 1) {
                        var k : usize = 0 ;
                        while (k < ac) : (k += 1) {
                            mat.data[i*bc+j] += self.data[i*ac+k] * self.data[k*bc+j] ;
                        }
                    }
                }
                return mat ;
            }
        }

        ///
        /// Cross (outer) product.
        ///
        pub fn cross(self: Self, o: Self) Self {
            if (Self != Vec3(Scalar) or Self != RowVec3(Scalar)) {
                unreachable ;
                //@compileError("The cross product is only valid in R³.") ;
            }
        
            return Self { .data = [_]Scalar
                { self.data[1]*o.data[2] - self.data[2]*o.data[1]
                , self.data[2]*o.data[0] - self.data[0]*o.data[2]
                , self.data[0]*o.data[1] - self.data[1]*o.data[0]
                }
            } ;
        }

        ///
        /// Returns a copy of the matrix, transposed. Before you look
        /// somewhere else, the library doesn't provide an inplace transpose.
        /// I don't know what it would even look like in this type system.
        ///
        pub fn transposed(self: Self) Mat(Scalar, N, M) {
            var mat : Mat(Scalar, N, M) = undefined ;
            std.debug.warn("{} → {}\n", @typeName(Self), @typeName(Mat(Scalar, N, M))) ;
            comptime var i : u32 = 0 ;
            inline while (i < M) : (i += 1) {
                comptime var j : u32 = 0 ;
                inline while (j < N) : (j += 1) {
                    mat.data[i+j*M] = self.data[j+i*N] ;
                }
            }
            return mat ;
        }

        pub fn formatVec(value: Self,
                         comptime fmt: []const u8,
                         options: std.fmt.FormatOptions,
                         context: var,
                         comptime Errors: type,
                         output: fn (@typeOf(context), []const u8) Errors!void
                         ) Errors!void {
            try output(context, "gl(") ;
            comptime const L = Self.size() ;
            comptime var i = 0 ;
            inline while (i < L-1) : (i += 1) {
                try std.fmt.formatType(value.data[i], "", options,
                                       context, Errors, output, 1) ;
                try output(context, ", ") ;
            }
            try std.fmt.formatType(value.data[i], "", options,
                                   context, Errors, output, 1) ;
            if (M == 1) {
                try output(context, ")") ;
            } else {
                try output(context, ")'") ;
            }
        }

        pub fn formatMat(value: Self,
                         comptime fmt: []const u8,
                         options: std.fmt.FormatOptions,
                         context: var,
                         comptime Errors: type,
                         output: fn (@typeOf(context), []const u8) Errors!void
                         ) Errors!void {
            var i : u32 = 0 ;
            while (i < M) : (i += 1) {
                try output(context, "[") ;
                var j : u32 = 0 ;
                while (j < N) : (j += 1) {
                    try std.fmt.formatType(value.data[j+N*i], "", options,
                                           context, Errors, output, 1) ;
                    try output(context, ", ") ;
                }
                try output(context, "]\n") ;
            }
        }

        ///
        /// Output a string with the representation of the variable content.
        /// Matrix one is very primitive, but it works.
        ///
        pub fn format(value: Self,
                      comptime fmt: []const u8,
                      options: std.fmt.FormatOptions,
                      context: var,
                      comptime Errors: type,
                      output: fn (@typeOf(context), []const u8) Errors!void
                      ) Errors!void {
            if (isVec(Scalar, Self)) {
                try formatVec(value, fmt, options, context, Errors, output) ;
            } else {
                try formatMat(value, fmt, options, context, Errors, output) ;
            }
        }
    } ;
}


pub fn Vec2(comptime Scalar: type) type { return Mat(Scalar, 2, 1) ; }
pub fn Vec3(comptime Scalar: type) type { return Mat(Scalar, 3, 1) ; }
pub fn Vec4(comptime Scalar: type) type { return Mat(Scalar, 4, 1) ; }

pub fn RowVec2(comptime Scalar: type) type { return Mat(Scalar, 1, 2) ; }
pub fn RowVec3(comptime Scalar: type) type { return Mat(Scalar, 1, 3) ; }
pub fn RowVec4(comptime Scalar: type) type { return Mat(Scalar, 1, 4) ; }

pub fn Mat4(comptime Scalar: type) type { return Mat(Scalar, 4, 4) ; }

