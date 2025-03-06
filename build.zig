const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    // const optimize = b.standardOptimizeOption(.{});
    const optimize = .ReleaseSmall;

    const bin2ihex = b.addExecutable(.{
        .name = "bin2ihex",
        .root_source_file = b.path("src/bin2ihex.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ihex2bin = b.addExecutable(.{
        .name = "ihex2bin",
        .root_source_file = b.path("src/ihex2bin.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(bin2ihex);
    b.installArtifact(ihex2bin);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_b2i = b.addRunArtifact(bin2ihex);
    const run_i2b = b.addRunArtifact(ihex2bin);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_b2i.step.dependOn(b.getInstallStep());
    run_i2b.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_b2i.addArgs(args);
        run_i2b.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const b2irun_step = b.step("b2irun", "Run the bin2ihex app");
    b2irun_step.dependOn(&run_b2i.step);
    const i2brun_step = b.step("i2brun", "Run the ihex2bin app");
    i2brun_step.dependOn(&run_i2b.step);
    // Default run step is a clone of b2irun_step
    const run_step = b.step("run", "Run the bin2ihex app");
    run_step.dependOn(&run_b2i.step);

    const bin2ihex_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/bin2ihex.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ihex2bin_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/ihex2bin.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_bin2ihex_unit_tests = b.addRunArtifact(bin2ihex_unit_tests);
    const run_ihex2bin_unit_tests = b.addRunArtifact(ihex2bin_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_bin2ihex_unit_tests.step);
    test_step.dependOn(&run_ihex2bin_unit_tests.step);
}
