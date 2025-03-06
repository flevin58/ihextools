const std = @import("std");

const BUFFER_SIZE = 44;

inline fn msb(addr: u16) u16 {
    return (addr >> 8) & 0xff;
}

inline fn lsb(addr: u16) u16 {
    return addr & 0xff;
}

fn ihex2bin(in: anytype, out: anytype) !void {
    var record: [BUFFER_SIZE]u8 = undefined;
    var current: usize = 0;

    // : 10 0000 00 23 09 24 4F 70 65 6E 42 53 44 24 0A 0A 50 52 4F 0C
    //
    while (try in.readUntilDelimiterOrEof(&record, '\n')) |line| {
        if (line[0] != ':') return error.BadRecordFrormat;
        const nbytes: usize = try std.fmt.parseInt(u8, record[1..3], 16);
        const addr: u16 = try std.fmt.parseInt(u16, record[3..7], 16);
        const code: u8 = try std.fmt.parseInt(u8, record[7..9], 16);
        if (nbytes == 0) continue;
        if (code == 1) break;
        if (addr != current) return error.BadAddressInRecord;
        var i: usize = 0;
        while (i < nbytes * 2) : (i += 2) {
            const hbyte = record[9 + i .. 9 + i + 2];
            const byte = try std.fmt.parseInt(u8, hbyte, 16);
            try out.writeByte(byte);
        }
        current += nbytes;
    }
}

pub fn main() !void {
    // Get command line arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Set the File handles
    var ifile: std.fs.File = undefined;
    var ofile: std.fs.File = undefined;
    switch (args.len) {
        2 => {
            ifile = std.io.getStdIn();
            ofile = try std.fs.cwd().createFile(args[1], .{});
        },
        3 => {
            ifile = try std.fs.cwd().openFile(args[1], .{ .mode = .read_only });
            ofile = try std.fs.cwd().createFile(args[2], .{});
        },
        else => {
            std.debug.print("\nusage: {s} infile [outfile]\n", .{args[0]});
            std.process.exit(1);
        },
    }
    defer ifile.close();
    defer ofile.close();

    // Do the conversion!
    try ihex2bin(ifile.reader(), ofile.writer());
}
