const std = @import("std");

pub fn build(b: *std.build.Builder) void {

    // Compile the ELF itself for aarch64 Linux
    const switch_target = std.zig.CrossTarget{ .os_tag = .linux, .cpu_arch = .aarch64 };

    // Compile elf2nro for the current machine
    const native_target = std.zig.CrossTarget{ .os_tag = null, .cpu_arch = null };

    const exe = b.addExecutable(.{
        .name = "zig-hos",
        .target = switch_target,
        .link_libc = true,
        .root_source_file = .{ .path = "src/main.c" },
        .optimize = b.standardOptimizeOption(.{}),
    });
    b.installArtifact(exe);

    const elf2nro = b.addExecutable(.{
        .name = "elf2nro",
        .root_source_file = .{ .path = "ext/switch-tools/src/elf2nro.c" },
        .link_libc = true,
        .target = native_target,
    });

    // No idea why we can't just pass in normal strings anymore, but this is required now...
    elf2nro.addCSourceFile(.{ .file = std.build.LazyPath.relative("ext/switch-tools/src/romfs.c"), .flags = &.{} });
    elf2nro.addCSourceFile(.{ .file = std.build.LazyPath.relative("ext/switch-tools/src/filepath.c"), .flags = &.{} });
    elf2nro.addIncludePath(.{ .path = "ext/switch-tools/src" });
    elf2nro.addIncludePath(.{ .path = "include" });
    b.installArtifact(elf2nro);

    const build_nro = b.addRunArtifact(elf2nro);
    build_nro.addArtifactArg(exe);
    build_nro.addArg("zig_arm64.nro");
    build_nro.addArg("--icon=thumb.jpeg");

    const build_step = b.step("nro", "convert to an NRO");
    build_step.dependOn(&build_nro.step);
}
