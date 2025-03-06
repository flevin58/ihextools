const std = @import("std");

const BUFFER_SIZE = 16;

inline fn msb(addr: u16) u16 {
    return (addr >> 8) & 0xff;
}

inline fn lsb(addr: u16) u16 {
    return addr & 0xff;
}

fn bin2ihex(in: anytype, out: anytype) !void {
    var addr: u16 = 0;
    var nbytes: usize = BUFFER_SIZE;
    var record: [BUFFER_SIZE]u8 = undefined;
    while (nbytes == BUFFER_SIZE) : (addr += BUFFER_SIZE) {
        @memset(&record, 0);
        var sum: usize = 0;
        nbytes = try in.read(&record);
        try out.print(":{X:0>2}{X:0>4}{X:0>2}", .{ nbytes, addr, 0 });
        if (nbytes == 0) break;
        for (0..nbytes) |i| {
            try out.print("{X:0>2}", .{record[i]});
            sum += record[i];
        }
        sum += nbytes + msb(addr) + lsb(addr);
        try out.print("{X:0>2}\n", .{(~sum + 1) & 0xff});
    }
    try out.print(":{X:0>2}{X:0>4}{X:0>2}{X:0>2}\n", .{ 0, 0, 1, 0xff });
}

pub fn main() !void {
    // Get command line arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Check for command line error
    if (args.len < 2 or args.len > 3) {
        std.debug.print("\nusage: {s} infile [outfile]\n", .{args[0]});
        std.process.exit(1);
    }

    // Set the File handles
    var ifile = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
    defer ifile.close();
    var ofile = if (args.len == 2) std.io.getStdOut() else try std.fs.cwd().createFile(args[2], .{});
    defer ofile.close();

    // Do the conversion!
    try bin2ihex(ifile.reader(), ofile.writer());
}
