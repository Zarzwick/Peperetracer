const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("peperetracer", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("gsl");
    exe.linkSystemLibrary("gslcblas");

    // So this seems to actually work.
    exe.linkSystemLibrary("/usr/lib/libIlmImf.so");

    // Use to define the symbol __gxx_personality_v0 required by libunwind.
    // A better option would clealry be to build openEXR alongside all of
    // this and build it with -fno-exceptions.
    exe.addObjectFile("src/gxx_personality.o");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
