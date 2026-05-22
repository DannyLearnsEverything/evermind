const std = @import("std");

pub const UuidGenerator = struct {
    random: std.Random,
    pub fn init(random: std.Random) UuidGenerator {
        return .{
            .random = random,
        };
    }
    pub fn v4(self: UuidGenerator) [36]u8 {
        var random_bytes: [16]u8 = undefined;
        self.random.bytes(&random_bytes);

        // Set the version bits
        random_bytes[6] = random_bytes[6] & 0x0F | 0x40;

        // Set the variant bits
        random_bytes[8] = random_bytes[8] & 0x3F | 0x80;

        var output: [36]u8 = undefined;
        var read_head: usize = 0;
        var write_head: usize = 0;

        const groups = [_]u3{ 4, 2, 2, 2, 6 };
        for (groups) |n| {
            if (write_head != 0) {
                output[write_head] = '-';
                write_head += 1;
            }
            for (0..n) |_| {
                const byte: u8 = random_bytes[read_head];
                read_head += 1;

                const high_nibble = byte >> 4;
                const high_offset: u8 = if (high_nibble < 10) '0' else ('a' - 10);
                output[write_head] = high_nibble + high_offset;
                write_head += 1;

                const low_nibble = byte & 15;
                const low_offset: u8 = if (low_nibble < 10) '0' else ('a' - 10);
                output[write_head] = low_nibble + low_offset;
                write_head += 1;
            }
        }
        return output;
    }
};

test "UUIDV4 Generation" {
    const seed: u64 = 0;
    var rand_implementation = std.Random.DefaultPrng.init(seed);
    const random = rand_implementation.random();
    const gen: UuidGenerator = .init(random);
    const id = gen.v4();
    try std.testing.expectEqualStrings("df230b49-615d-4753-c7d5-80c33d6fda61", &id);
}
