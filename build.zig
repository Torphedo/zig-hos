const std = @import("std");

pub fn build(b: *std.Build.Builder) void {

    // Compile the ELF itself for aarch64 Linux
    // elf2nro complains about the ELF file being bad if I compile for
    // freestanding and disable libc... It also complains if I don't jump to
    // _start, so right now I'm just adding a jump to start that's never hit
    // because I jump to main first. So right now libc is unavailable, which I
    // haven't really tried fixing yet. I might need to add a Switch OS tag or something.
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
    exe.addIncludePath(.{ .path = "ext/libnx/nx/include/switch" });
    // exe.addCSourceFile(.{ .file = std.Build.LazyPath.relative("ext/libnx/nx/source/services/sm.c"), .flags = &.{} });
    exe.addAssemblyFile(.{ .path = "ext/libnx/nx/source/kernel/svc.s" });
    exe.addAssemblyFile(.{ .path = "src/nro_entry.s" });
    exe.setLinkerScript(.{ .path = "src/set_base_addr.ld" });
    b.installArtifact(exe);

    const elf2nro = b.addExecutable(.{
        .name = "elf2nro",
        .root_source_file = .{ .path = "ext/switch-tools/src/elf2nro.c" },
        .link_libc = true,
        .target = native_target,
    });

    // No idea why we can't just pass in normal strings anymore, but this is required now...
    elf2nro.addCSourceFile(.{ .file = std.Build.LazyPath.relative("ext/switch-tools/src/romfs.c"), .flags = &.{} });
    elf2nro.addCSourceFile(.{ .file = std.Build.LazyPath.relative("ext/switch-tools/src/filepath.c"), .flags = &.{} });
    elf2nro.addIncludePath(.{ .path = "ext/switch-tools/src" });
    elf2nro.addIncludePath(.{ .path = "include" });
    b.installArtifact(elf2nro);

    const build_nro = b.addRunArtifact(elf2nro);
    build_nro.addArtifactArg(exe);
    build_nro.addArg("zig-hos.nro");
    build_nro.addArg("--icon=thumb.jpeg");

    const build_step = b.step("nro", "convert to an NRO");
    build_step.dependOn(&build_nro.step);
}
