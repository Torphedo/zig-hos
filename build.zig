const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn system(cmd: []const u8) !void {
    const allocator = gpa.allocator();

    const result = try std.ChildProcess.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{cmd},
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
}

pub fn build_assembly_obj(src: []const u8, obj_name: []const u8) !void {
    const cmd_base = "zig build-obj -target aarch64-freestanding -cflags -Qunused-arguments -o{s} -- {s}";
    const size = cmd_base.len + src.len + obj_name.len;

    const buffer = try gpa.allocator().alloc(u8, size);
    defer gpa.allocator().free(buffer);

    const cmd = try std.fmt.bufPrintZ(buffer, cmd_base, .{ obj_name, src });
    system(cmd) catch |err| {
        if (err == error.FileNotFound) {
            // Really dirty hack to silently discard the error that doesn't
            // seem to actually cause problems. Sorry, my coffee went cold when
            // I was writing this.
        }
    };
}

pub fn build(b: *std.Build) !void {

    // libc is unavailable, which I haven't really tried fixing yet.
    const switch_target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a57 },
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
    });

    const exe = b.addExecutable(.{
        .name = "zig-hos",
        .target = switch_target,
        .link_libc = false,
        .optimize = b.standardOptimizeOption(.{}),
    });
    exe.addCSourceFile(.{ .file = b.path("src/main.c"), .flags = &.{} });

    // Adding the assembly file normally causes Clang error because of unused
    // parameters. We have to use this helper to compile them separately...
    // Nevermind this bug mysteriously vanished before my very eyes
    // try build_assembly_obj(b.path("src/nro_entry.s").getPath(b), b.path("nro_entry.o").getPath(b));
    // exe.addObjectFile(b.path("nro_entry.o"));
    // try build_assembly_obj(b.path("ext/libnx/nx/source/kernel/svc.s").getPath(), b.path("svc.o").getPath());
    // exe.addObjectFile(b.path("svc.o"));

    exe.addIncludePath(b.path("ext/libnx/nx/include/switch"));
    exe.addAssemblyFile(b.path("ext/libnx/nx/source/kernel/svc.s"));
    exe.addAssemblyFile(b.path("src/nro_entry.s"));
    exe.setLinkerScript(b.path("src/set_base_addr.ld"));
    b.installArtifact(exe);

    const elf2nro = b.addExecutable(.{
        .name = "elf2nro",
        .link_libc = true,
        .target = b.host,
    });

    // No idea why we can't just pass in normal strings anymore, but this is required now...
    elf2nro.addCSourceFile(.{ .file = b.path("ext/switch-tools/src/elf2nro.c"), .flags = &.{} });
    elf2nro.addCSourceFile(.{ .file = b.path("ext/switch-tools/src/romfs.c"), .flags = &.{} });
    elf2nro.addCSourceFile(.{ .file = b.path("ext/switch-tools/src/filepath.c"), .flags = &.{} });
    elf2nro.addIncludePath(b.path("ext/switch-tools/src"));
    elf2nro.addIncludePath(b.path("include"));
    b.installArtifact(elf2nro);

    const build_nro = b.addRunArtifact(elf2nro);
    build_nro.addArtifactArg(exe);
    build_nro.addArg("zig-hos.nro");
    build_nro.addArg("--icon=thumb.jpeg");

    const build_step = b.step("nro", "convert to an NRO");
    build_step.dependOn(&build_nro.step);
}
