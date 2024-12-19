const std = @import("std");

const vector_error = error{INVALID_INDEX};

// vector template
pub fn vector(comptime T: type) type {
    return struct {
        const Self = @This();
        data: []T = undefined,
        size: usize = 0,
        capacity: usize = 0,
        alloc: std.mem.Allocator,

        pub fn init(cap: usize, alloc: std.mem.Allocator) !Self {
            return Self{
                .data = try alloc.alloc(T, cap),
                .size = 0,
                .capacity = cap,
                .alloc = alloc,
            };
        }

        pub fn at(self: *const Self, idx: usize) vector_error!*T {
            if (idx < self.size)
                return &self.data[idx];
            return vector_error.INVALID_INDEX;
        }

        pub fn len(self: Self) usize {
            return self.size;
        }

        pub fn push(self: *Self, val: T) !void {
            if (self.size <= self.capacity - 1) {
                self.data[self.size] = val;
                self.size += 1;
            } else {
                self.capacity *= 2;
                var tmp = try self.alloc.alloc(T, self.capacity + 1);

                if (self.size > 0) {
                    for (self.data, 0..) |e, i| {
                        tmp[i] = e;
                    }
                    tmp[self.size] = val;

                    self.alloc.free(self.data);
                }

                self.size += 1;
                self.data = tmp;
            }
        }
        pub fn set(self: *Self, idx: usize, v: T) !void {
            if (idx < self.size) {
                self.data[idx] = v;
                return;
            }
            return vector_error.INVALID_INDEX;
        }
        pub fn clear(self: *Self) void {
            if (self.size > 0) {
                self.alloc.free(self.data);
                self.size = 0;
                self.capacity = 1;
                self.data = undefined;
            }
        }

        pub fn destr(self: *Self) void {
            if (self.capacity > 1) {
                self.alloc.free(self.data);
            }
        }
    };
}
