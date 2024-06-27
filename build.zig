const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// A rough recreation of C's system() function
pub fn system(cmd: []const u8) !void {
    const allocator = gpa.allocator();
    // This will break when quotes are involved, but it's fine for now.
    var spliterator = std.mem.splitSequence(u8, cmd, " ");

    // Find number of tokens
    var argv_len: u16 = 0;
    while (spliterator.next() != null) {
        argv_len +|= 1;
    }
    spliterator.reset();

    // Fill out argv for launching the command
    var argv = try allocator.alloc([]const u8, argv_len);
    for (0..argv.len) |i| {
        argv[i] = spliterator.peek().?;
        _ = spliterator.next();
    }

    var proc = std.process.Child.init(argv, allocator);

    // Launch command and wait on it to finish
    try proc.spawn();
    _ = try proc.wait();
}

// Build an assembly file at [src] into an object file at [obj_name], and add
// the object file to [target].
pub fn build_assembly_obj(src: std.Build.LazyPath, obj_name: std.Build.LazyPath, target: *std.Build.Step.Compile, b: *std.Build) !void {
    const cmd_base = "zig build-obj -target aarch64-freestanding-none -cflags -Qunused-arguments -o{s} -- {s}";
    const size = cmd_base.len + src.getPath(b).len + obj_name.getPath(b).len;

    const buffer = try gpa.allocator().alloc(u8, size);
    defer gpa.allocator().free(buffer);

    const cmd = try std.fmt.bufPrintZ(buffer, cmd_base, .{ obj_name.getPath(b), src.getPath(b) });
    try system(cmd);

    target.addObjectFile(obj_name);
}

// There's a weird bug in Zig that adds parameters that aren't needed to the
// Clang assembler command. Zig treats the Clang warnings as errors, and
// there's no way to pass Clang flags for assembly files. The workaround is to
// manually run "zig build-obj" with the correct flags and add the object file.
// This bug seems to randomly appear and disappear, so this function makes the
// workaround easy to toggle.
fn add_asm_files(use_workaround: bool, exe: *std.Build.Step.Compile, b: *std.Build) !void {
    if (use_workaround) {
        try build_assembly_obj(b.path("src/nro_entry.s"), b.path("nro_entry.o"), exe, b);
        try build_assembly_obj(b.path("src/aarch64.s"), b.path("aarch64.o"), exe, b);
        try build_assembly_obj(b.path("ext/libnx/nx/source/kernel/svc.s"), b.path("svc.o"), exe, b);
    } else {
        exe.addAssemblyFile(b.path("ext/libnx/nx/source/kernel/svc.s"));
        exe.addAssemblyFile(b.path("src/nro_entry.s"));
        exe.addAssemblyFile(b.path("src/aarch64.s"));
    }
}

pub fn build(b: *std.Build) !void {
    const switch_target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.cortex_a57 },
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
    });

    const libc_dep = b.dependency("picolibc", .{
        .target = switch_target,
    }).artifact("c");

    const exe = b.addExecutable(.{
        .name = "zig-hos",
        .target = switch_target,
        .link_libc = false,
        .optimize = b.standardOptimizeOption(.{}),
    });
    exe.addCSourceFile(.{ .file = b.path("src/main.c"), .flags = &.{} });
    exe.addCSourceFile(.{ .file = b.path("src/vfile.c"), .flags = &.{} });
    exe.addCSourceFile(.{ .file = b.path("src/crt0.c"), .flags = &.{} });

    try add_asm_files(true, exe, b);
    exe.addIncludePath(b.path("ext/libnx/nx/include/switch"));
    exe.addIncludePath(b.path("ext/picolibc-zig/newlib/libc/include/"));
    exe.linkLibrary(libc_dep);
    exe.setLinkerScript(b.path("src/set_base_addr.ld"));
    b.installArtifact(exe);

    const elf2nro = b.addExecutable(.{
        .name = "elf2nro",
        .link_libc = true,
        .target = b.host,
    });

    // C source struct has more than just the path string
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
