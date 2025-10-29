const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const http = std.http;
const mem = std.mem;
const meta = std.meta;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const ApplicationError = error{RequestFailed} || http.Client.FetchError;

pub fn generate_gitignore(allocator: Allocator, client: *http.Client, templates: []const []const u8) ApplicationError![]const u8 {
    var response_body: std.Io.Writer.Allocating = .init(allocator);
    defer response_body.deinit();

    const segment = try mem.join(allocator, ",", templates);
    defer allocator.free(segment);

    const slices = .{ URL_GENERATE, segment };
    const url = try mem.join(allocator, "", &slices);
    defer allocator.free(url);

    const res = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = url },
        .response_writer = &response_body.writer,
    });

    switch (res.status.class()) {
        .success => return try response_body.toOwnedSlice(),
        else => {
            debug.print("{s}", .{res.status.phrase().?});
            response_body.deinit();
            return ApplicationError.RequestFailed;
        },
    }
}

pub fn list_templates(allocator: Allocator, client: *http.Client) ApplicationError![]const []const u8 {
    var response_body: std.Io.Writer.Allocating = .init(allocator);
    defer response_body.deinit();

    const res = try client.fetch(.{
        .method = .GET,
        .location = .{ .url = URL_LIST },
        .response_writer = &response_body.writer,
    });

    switch (res.status.class()) {
        .success => {
            var templates: ArrayList([]const u8) = .empty;
            defer templates.deinit(allocator);

            var iter = mem.tokenizeAny(u8, response_body.written(), ", \t\n\r");
            while (iter.next()) |id| {
                try templates.append(allocator, id);
            }
            return templates.toOwnedSlice(allocator);
        },
        else => {
            return ApplicationError.RequestFailed;
        },
    }
}

pub const Shell = enum { bash, fish };

pub fn generate_bash_completion_str(allocator: Allocator, client: *http.Client) ![]const u8 {
    const templates = try list_templates(allocator, client);
    defer allocator.free(templates);

    const all_templates = try mem.join(allocator, " ", templates);
    defer allocator.free(all_templates);

    return fmt.allocPrint(allocator, FMT_BASH_COMPLETION, .{all_templates});
}

pub fn generate_fish_completion_str(allocator: Allocator, client: *http.Client) ![]const u8 {
    const templates = try list_templates(allocator, client);
    defer allocator.free(templates);

    const all_templates = try mem.join(allocator, " ", templates);
    defer allocator.free(all_templates);

    const field_names = comptime meta.fieldNames(Shell);
    const all_shells = comptime blk: {
        if (field_names.len == 0) break :blk "";
        if (field_names.len == 1) break :blk field_names[0];

        var s = field_names[0];
        for (field_names) |name| s = s ++ " " ++ name;
        break :blk s;
    };

    return fmt.allocPrint(allocator, FMT_FISH_COMPLETION, .{ all_templates, all_shells });
}

pub const URL_LIST = "https://www.toptal.com/developers/gitignore/api/list/";
pub const URL_GENERATE = "https://www.toptal.com/developers/gitignore/api/";

pub const FMT_BASH_COMPLETION =
    \\#!/usr/bin/env bash
    \\complete -W "{s}" gi
    \\
;

pub const FMT_FISH_COMPLETION =
    \\complete -c gi -f
    \\complete -c gi -a '{s}'
    \\complete -c gi -s h -l help -d 'Print a short help text and exit'
    \\complete -c gi -s v -l version -d 'Print a short version string and exit'
    \\complete -c gi -l no-pager -d 'Do not pipe output into a pager'
    \\complete -c gi -l completion -a '{s}' -d 'Generate shell completion file'
    \\
;
