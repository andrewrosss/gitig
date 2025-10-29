const std = @import("std");
const ascii = std.ascii;
const fs = std.fs;
const http = std.http;
const mem = std.mem;
const process = std.process;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Writer = std.Io.Writer;

/// https://github.com/ziglang/zig/pull/22907
const build = @import("build.zig.zon");
const gitig = @import("gitig");

pub fn main() !void {
    // choose the allocator
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // setup stdout and stderr
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    // container for template identifiers from command line arguments
    var templates: ArrayList([]const u8) = .empty;
    defer templates.deinit(allocator);

    // manually parse the command line arguments
    var args = try process.argsWithAllocator(allocator);
    _ = args.next(); // skip program name
    const action: Action = while (args.next()) |arg| {
        if (mem.eql(u8, arg, "-h")) break .show_help; // explicit help
        if (mem.eql(u8, arg, "--help")) break .show_help; // explicit help
        if (mem.eql(u8, arg, "--version")) break .show_version;
        if (mem.eql(u8, arg, "--completion")) {
            // we take the next arg as the shell identifier
            const shell_str = args.next() orelse break .show_help;
            if (ascii.eqlIgnoreCase(shell_str, "bash")) break .{ .shell_completion = .bash };
            if (ascii.eqlIgnoreCase(shell_str, "fish")) break .{ .shell_completion = .fish };
            break .show_help; // unknown shell; print help.
        }
        if (mem.startsWith(u8, arg, "-")) break .show_help; // unknown option; print help.
        // otherwise, treat this arg as a template identifier and collect it.
        try templates.append(allocator, arg);
    } else if (templates.items.len > 0) .{ .templates = templates.items } else .list_templates;

    switch (action) {
        .show_help => return print_help(stderr),
        .show_version => return print_version(stderr),
        .shell_completion => |shell| {
            var client: http.Client = .{ .allocator = allocator };
            defer client.deinit();

            try print_shell_completion(allocator, &client, stdout, shell);
        },
        .templates => |ts| {
            var client: http.Client = .{ .allocator = allocator };
            defer client.deinit();

            try print_generated_gitignore(allocator, &client, stdout, ts);
        },
        .list_templates => {
            var client: http.Client = .{ .allocator = allocator };
            defer client.deinit();

            try print_all_templates(allocator, &client, stdout);
        },
    }
}

const Action = union(enum) {
    show_help,
    show_version,
    shell_completion: gitig.Shell,
    templates: []const []const u8,
    list_templates,
};

fn print_help(w: *Writer) !void {
    try w.writeAll(
        \\gi: Generate .gitignore files from the command-line
        \\
        \\USAGE:
        \\    gi [options] [TEMPLATE ...]
        \\
        \\OPTIONS:
        \\    -h,--help           Show this help message
        \\    --version           Show version information
        \\    --completion SHELL  Generate shell completion script for SHELL (bash, fish)
        \\
        \\NOTES:
        \\   TEMPLATE names are case-insensitive and can be found
        \\   by running `gi` without arguments or options.
        \\
        \\   To enable shell completion, generate and install the completion script:
        \\
        \\   Bash:
        \\       gi --completion bash > /etc/bash_completion.d/gi.bash-completion
        \\
        \\   Bash (Homebrew):
        \\       gi --completion bash > $(brew --prefix)/etc/bash_completion.d/gi.bash-completion
        \\
        \\   Fish:
        \\       gi --completion fish > ~/.config/fish/completions/gi.fish
        \\
        \\   Fish (Homebrew):
        \\       gi --completion fish > (brew --prefix)/share/fish/vendor_completions.d/gi.fish
    );
    try w.flush();
}

fn print_version(w: *Writer) !void {
    try w.writeAll("gitig (");
    try w.writeAll(build.version);
    try w.writeAll(")\n");
    try w.flush();
}

fn print_shell_completion(allocator: Allocator, client: *http.Client, w: *Writer, shell: gitig.Shell) !void {
    const completion_str = switch (shell) {
        .bash => try gitig.generate_bash_completion_str(allocator, client),
        .fish => try gitig.generate_fish_completion_str(allocator, client),
    };
    defer allocator.free(completion_str);
    try w.writeAll(completion_str);
    try w.flush();
}

fn print_generated_gitignore(allocator: Allocator, client: *http.Client, w: *Writer, templates: []const []const u8) !void {
    const template_str = try gitig.generate_gitignore(allocator, client, templates);
    defer allocator.free(template_str);
    try w.writeAll(template_str);
    try w.flush();
}

fn print_all_templates(allocator: Allocator, client: *http.Client, w: *Writer) !void {
    const ts = try gitig.list_templates(allocator, client);
    defer allocator.free(ts);
    for (ts) |templates_str| {
        try w.writeAll(templates_str);
        try w.writeAll("\n");
    }
    try w.flush();
}
