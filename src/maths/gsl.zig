///
/// Import and alias common types from the GNU Scientific Library.
///

const c = @cImport({
    @cInclude("gsl/gsl_vector.h") ;
    @cInclude("gsl/gsl_matrix.h") ;
}) ;                                                                         


