//
//

pub const nc = @cImport(@cInclude("ncurses.h"));

const curses_err = error{CURSES_ERR};

pub const ncw = struct {
    pub var ww: ?[*]nc.struct__win_st = undefined;
    pub var col: u32 = undefined;

    pub fn wrapper0(func: fn () callconv(.C) c_int) curses_err!void {
        if (func() < 0) {
            return curses_err.CURSES_ERR;
        }
        return;
    }

    pub fn mwrapper1(comptime T: type, func: fn ([*c]nc.struct__win_st, T) callconv(.C) c_int, val: T) curses_err!void {
        if (func(ww, val) < 0) {
            return curses_err.CURSES_ERR;
        }
        return;
    }
    pub fn mwrapper2(comptime T: type, func: fn ([*c]nc.struct__win_st, T, T) callconv(.C) c_int, val1: T, val2: T) curses_err!void {
        if (func(ww, val1, val2) < 0) {
            return curses_err.CURSES_ERR;
        }
        return;
    }

    pub fn initscr() curses_err!void {
        ww = nc.initscr();
        col = 0;
        if (ww == null) {
            return curses_err.CURSES_ERR;
        }
        try wrapper0(nc.start_color);

        if (nc.init_pair(2, nc.COLOR_GREEN, nc.COLOR_BLACK) < 0) {
            return curses_err.CURSES_ERR;
        }
        if (nc.init_pair(3, nc.COLOR_RED, nc.COLOR_BLACK) < 0) {
            return curses_err.CURSES_ERR;
        }
        if (nc.init_pair(4, nc.COLOR_MAGENTA, nc.COLOR_BLACK) < 0) {
            return curses_err.CURSES_ERR;
        }
        if (nc.init_pair(5, nc.COLOR_BLUE, nc.COLOR_BLACK) < 0) {
            return curses_err.CURSES_ERR;
        }
        if (nc.init_pair(6, nc.COLOR_YELLOW, nc.COLOR_BLACK) < 0) {
            return curses_err.CURSES_ERR;
        }

        if (nc.wattr_set(ww, nc.A_BOLD, 2, null) < 0) {
            return curses_err.CURSES_ERR;
        }

        try mwrapper1(bool, nc.scrollok, false);
        try mwrapper1(bool, nc.idlok, false);

        try ncw.noecho();

        return;
    }

    pub fn col_set(color: u32) !void {
        ncw.col = color;
        if (nc.wattr_set(ncw.ww, nc.A_BOLD, @intCast(col), null) < 0) {
            return curses_err.CURSES_ERR;
        }
        return;
    }

    pub fn refresh() curses_err!void {
        return wrapper0(nc.refresh);
    }

    pub fn noecho() curses_err!void {
        return wrapper0(nc.noecho);
    }

    pub fn endwin() curses_err!void {
        return wrapper0(nc.endwin);
    }

    pub fn nodelay() curses_err!void {
        return mwrapper1(bool, nc.nodelay, true);
    }

    pub fn move(x: u16, y: u16) curses_err!void {
        return mwrapper2(c_int, nc.wmove, y, x);
    }

    pub fn printch(ch: u8) curses_err!void {
        return mwrapper1(c_uint, nc.waddch, ch);
    }

    pub fn printline(str: [*]const u8) !void {
        return if (nc.printw(str) < 0) curses_err.CURSES_ERR;
    }

    pub fn mvaddch(x: i32, y: i32, c: u8) !void {
        if (nc.mvaddch(y, x, c) < 0) {
            return curses_err.CURSES_ERR;
        }
    }

    pub fn getch() curses_err!u16 {
        const ch = nc.getch();
        if (ch == nc.ERR) {
            return curses_err.CURSES_ERR;
        }
        return @intCast(ch);
    }

    pub fn getCols() i32 {
        return @intCast(nc.getmaxx(ww));
    }
    pub fn getLines() i32 {
        return @intCast(nc.getmaxy(ww));
    }
};
