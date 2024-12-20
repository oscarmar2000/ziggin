//
//
const std = @import("std");
const print = std.debug.print;

const vector = @import("vector").vector;
const ncw = @import("ncurses_wrapper").ncw;
const nc = @import("ncurses_wrapper").nc;

// 2d Point type
const Pt = struct {
    x: i32,
    y: i32,
    fn addTo(self: *Pt, p: Pt) void {
        self.x += p.x;
        self.y += p.y;
    }
    fn add(p1: Pt, p2: Pt) Pt {
        return Pt{ .x = p1.x + p2.x, .y = p1.y + p2.y };
    }
};

// Animation handling
const Anim = struct {
    base: Pt = undefined,
    pts: vector(Pt) = undefined,
    ch: u8 = undefined,
    steps: usize = undefined,
    color: u32 = undefined,
    alloc: std.mem.Allocator = undefined,
    incs: vector(Pt) = undefined,

    // update animation
    fn nextStep(self: *Anim) !bool {
        try draw(self.pts, ' ');
        if (self.steps > 0) {
            self.steps -= 1;

            if (self.steps == 0) {
                self.pts.clear();
                return false;
            }

            const old_col = ncw.col;
            try ncw.col_set(self.color);

            var npts: vector(Pt) = try vector(Pt).init(12, self.alloc);
            defer npts.destr();

            try vadd(Pt, self.pts, self.incs, &npts);

            const transform_wrap = struct {
                pub fn wp(p: Pt) ?Pt {
                    return wrap_pos(p, Pt{ .x = ncw.getCols(), .y = ncw.getLines() });
                }
            }.wp;

            const sz = self.pts.size;
            self.pts.clear();

            self.pts = try vector(Pt).init(sz, self.alloc);

            try vapply(Pt, npts, &self.pts, transform_wrap);
            try draw(self.pts, self.ch);

            try ncw.col_set(old_col);

            return true;
        }
        return false;
    }

    // draw animation characters
    fn draw(pts: vector(Pt), ch: u8) !void {
        for (0..pts.len()) |i| {
            const p = try pts.at(i);
            ncw.mvaddch(p.x, p.y, ch) catch {
                print("e", .{});
            };
        }
    }

    // setup animation object
    fn create(p: Pt, v: Pt, c: u8, col: u32, allo: std.mem.Allocator) !Anim {
        var pv: vector(Pt) = try vector(Pt).init(12, allo);

        var incs = try vector(Pt).init(12, allo);

        if (v.x > 0) {
            try incs.push(Pt{ .x = 2, .y = 2 });
            try incs.push(Pt{ .x = 2, .y = -2 });
            try incs.push(Pt{ .x = 3, .y = 1 });
            try incs.push(Pt{ .x = 3, .y = -1 });
        }

        if (v.x < 0) {
            try incs.push(Pt{ .x = -3, .y = -1 });
            try incs.push(Pt{ .x = -3, .y = 1 });
            try incs.push(Pt{ .x = -2, .y = 2 });
            try incs.push(Pt{ .x = -2, .y = -2 });
        }

        if (v.y > 0) {
            try incs.push(Pt{ .x = -2, .y = 2 });
            try incs.push(Pt{ .x = 2, .y = 2 });
            try incs.push(Pt{ .x = 1, .y = 3 });
            try incs.push(Pt{ .x = -1, .y = 3 });
        }

        if (v.y < 0) {
            try incs.push(Pt{ .x = 2, .y = -2 });
            try incs.push(Pt{ .x = -2, .y = -2 });
            try incs.push(Pt{ .x = -1, .y = -3 });
            try incs.push(Pt{ .x = 1, .y = -3 });
        }

        for (0..incs.size) |_| {
            try pv.push(p.add(v).add(v));
        }

        return Anim{ .base = p, .pts = pv, .ch = c, .steps = 100, .color = col, .alloc = allo, .incs = incs };
    }
};

// main function
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try ncw.initscr();

    var pos = Pt{ .x = 0, .y = 0 }; // cursor position
    var dir = Pt{ .x = 0, .y = 0 }; // cursor direction

    var count: u32 = 0;
    var tcount: u32 = 0;

    const anim_vec = vector(Anim);
    var anims = try anim_vec.init(4, allocator);

    try ncw.printline("Press arrows to start:");

    try ncw.refresh();

    var ch = try ncw.getch(); // wait for initial key press

    try ncw.nodelay();

    while (ch != 'q') {
        const odir = dir; // save old direction
        count += 1;

        // check arrows presses to set direction
        if (ch == 0x1B) {
            if (ncw.getch() catch 0 == 0x5B) {
                ch = try ncw.getch();
                switch (ch) {
                    0x41 => {
                        dir.y = -1;
                        dir.x = 0;
                    },
                    0x42 => {
                        dir.y = 1;
                        dir.x = 0;
                    },
                    0x44 => {
                        dir.x = -1;
                        dir.y = 0;
                    },
                    0x43 => {
                        dir.x = 1;
                        dir.y = 0;
                    },
                    else => {
                        pos.x += 0;
                        pos.y += 0;
                    },
                }
            }
        }

        // check for space press
        if (ch == ' ') {
            if (dir.x > 0)
                try anims.push(try Anim.create(pos, dir, '>', ncw.col, allocator));
            if (dir.x < 0)
                try anims.push(try Anim.create(pos, dir, '<', ncw.col, allocator));
            if (dir.y > 0)
                try anims.push(try Anim.create(pos, dir, 'v', ncw.col, allocator));
            if (dir.y < 0)
                try anims.push(try Anim.create(pos, dir, '^', ncw.col, allocator));
            ch = '.';
        }

        // update animations
        for (0..anims.len()) |i| {
            _ = try (try anims.at(i)).nextStep();
        }

        // if (ch == 'w') pos.y -= 1;
        // if (ch == 's') pos.y += 1;
        // if (ch == 'a') pos.x -= 1;
        // if (ch == 'd') pos.x += 1;

        var key_s: u8 = undefined;

        // clear old char
        if (ncw.move(@intCast(pos.x), @intCast(pos.y))) {} else |_| {
            try ncw.move(@intCast(0), @intCast(0));
            pos.x = 0;
            pos.y = 0;
        }

        // replace last pointer
        if (dir.x != 0) {
            key_s = '-';
        }
        if (dir.y != 0) {
            key_s = '|';
        }
        // in case of direction change
        if (dir.y != 0 and odir.y == 0 or
            dir.y == 0 and odir.y != 0 or
            dir.x != 0 and odir.x == 0 or
            dir.x == 0 and odir.x != 0 or
            dir.x == odir.x and dir.y != odir.y or
            dir.x != odir.x and dir.y == odir.y)
        {
            key_s = '+';
            tcount += 1;
            try ncw.col_set(@intCast(tcount % 5 + 2));
        }

        // draw last pointer
        if (ncw.printch(key_s)) {} else |_| {
            print(":", .{});
        }

        // update position
        pos.x += dir.x;
        pos.y += dir.y;

        pos = wrap_pos(pos, Pt{ .x = ncw.getCols(), .y = ncw.getLines() });

        // move to new position
        try ncw.move(@intCast(pos.x), @intCast(pos.y));

        // print head
        const o_col = ncw.col;
        try ncw.col_set(nc.COLOR_WHITE);

        if (ncw.printch('X')) {} else |_| {
            print("_", .{});
        }

        // cleanup finished animations
        if (count % 21 == 0) {
            if (anims.len() > 0) {
                var anims_cpy = try anim_vec.init(anims.len() / 4 + 1, allocator);

                for (0..anims.len()) |i| {
                    if ((try anims.at(i)).steps > 0)
                        try anims_cpy.push((try anims.at(i)).*);
                }

                anims.clear();
                anims = anims_cpy;
            }

            try ncw.move(@intCast(0), @intCast(0));
            const string = try std.fmt.allocPrintZ(allocator, "a:{d}  ", .{anims.len()});
            try ncw.printline(string);
            try ncw.move(@intCast(pos.x), @intCast(pos.y));
        }

        try ncw.col_set(o_col);

        // move out cursor
        try ncw.move(@intCast(0), @intCast(0));

        // get new character
        ch = ncw.getch() catch ch;

        try ncw.refresh();
        std.time.sleep(20 * 1000_000);
    }

    try ncw.endwin();
}

// wrap position around the edges
fn wrap_pos(pos: Pt, max: Pt) Pt {
    var pps = pos;
    if (pos.y < 0) pps.y = max.y - 1;
    if (pos.x < 0) pps.x = max.x - 1;
    if (pos.y >= max.y) pps.y = 0;
    if (pos.x >= max.x) pps.x = 0;
    return pps;
}

// Add two vectors
pub fn vadd(T: type, v1: vector(T), v2: vector(T), vout: *vector(T)) !void {
    for (0..v1.len()) |i| {
        try vout.push(Pt.add((try v1.at(i)).*, (try v2.at(i)).*));
    }
}

// Apply transformation to vector
pub fn vapply(T: type, v: vector(T), vout: *vector(T), ap: (fn (T) ?T)) !void {
    for (0..v.len()) |i| {
        const nval = ap((try v.at(i)).*);
        if (nval != null)
            try vout.push(nval.?);
    }
}
