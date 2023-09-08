const std = @import("std");

pub fn build(b: *std.build.Builder) void {

    // Compile the ELF itself for aarch64 Linux
    const switch_target = std.zig.CrossTarget{ .os_tag = .linux, .cpu_arch = .aarch64 };

    // Compile elf2nro for the current machine
    const native_target = std.zig.CrossTarget{ .os_tag = null, .cpu_arch = null };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zig_arm64", "src/main.c");
    exe.setTarget(switch_target);
    exe.setBuildMode(mode);
    exe.addIncludePath("src");
    exe.linkLibC();
    exe.install();

    const elf2nro = b.addExecutable("elf2nro", "ext/switch-tools/src/elf2nro.c");
    elf2nro.setTarget(native_target);

    // We could add these both with addCSourceFiles but it's more trouble than it's worth
    elf2nro.addCSourceFile("ext/switch-tools/src/romfs.c", &.{});
    elf2nro.addCSourceFile("ext/switch-tools/src/filepath.c", &.{});
    elf2nro.addIncludePath("ext/switch-tools/src");
    elf2nro.linkLibC();
    elf2nro.install();

    const build_nro = elf2nro.run();
    build_nro.addArtifactArg(exe);
    build_nro.addArg("zig_arm64.nro");
    build_nro.addArg("--icon=thumb.jpeg");

    const build_step = b.step("nro", "convert to an NRO");
    build_step.dependOn(&build_nro.step);
}
