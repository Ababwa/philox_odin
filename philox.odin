package philox

MULT_2X_32 :: 0xD256D193
MULT_2X_64 :: 0xD2B74407B1CE6E93

MULT_4X_32_0 :: 0xD2511F53
MULT_4X_32_1 :: 0xCD9E8D57
MULT_4X_64_0 :: 0xD2E7470EE14C6C93
MULT_4X_64_1 :: 0xCA5A826395121157

DELTA_32_0 :: 0x9E3779B9
DELTA_32_1 :: 0xBB67AE85
DELTA_64_0 :: 0x9E3779B97F4A7C15
DELTA_64_1 :: 0xBB67AE8584CAA73B

mul_hi_lo :: #force_inline proc "contextless" (a: $T, b: T) -> (T, T) {
	when T == u32 do D :: u64
	when T == u64 do D :: u128
	p := cast(D)a * cast(D)b
	return cast(T)(p >> (size_of(T) * 8)), cast(T)p
}

philox_bump_key :: #force_inline proc "contextless" (key: ^[$K]$T)
where K >= 1 && K <= 2 {
	when T == u32 do DELTA_0, DELTA_1 :: DELTA_32_0, DELTA_32_1
	when T == u64 do DELTA_0, DELTA_1 :: DELTA_64_0, DELTA_64_1
	key[0] += DELTA_0
	when K > 1 do key[1] += DELTA_1
}

philox_round :: #force_inline proc "contextless" (key: [$K]$T, state: ^[$C]T)
where K >= 1 && K <= 2 && C == 2 * K {
	when K == 1 {
		when T == u32 do MULT :: MULT_2X_32
		when T == u64 do MULT :: MULT_2X_64
		hi, lo := mul_hi_lo(state.x, MULT)
		state.x = key.x ~ state.y ~ hi
		state.y = lo
	}
	when K == 2 {
		when T == u32 do MULT_0, MULT_1 :: MULT_4X_32_0, MULT_4X_32_1
		when T == u64 do MULT_0, MULT_1 :: MULT_4X_64_0, MULT_4X_64_1
		hi0, lo0 := mul_hi_lo(state.x, MULT_0)
		hi1, lo1 := mul_hi_lo(state.z, MULT_1)
		state.x = key.x ~ state.y ~ hi1
		state.y = lo1
		state.z = key.y ~ state.w ~ hi0
		state.w = lo0
	}
}

philox_gen :: proc "contextless" ($ROUNDS: int, key: [$K]$T, state: ^[$C]T)
where K >= 1 && K <= 2 && C == 2 * K && ROUNDS > 0 {
	key := key
	philox_round(key, state)
	#unroll for _ in 1..<ROUNDS {
		philox_bump_key(&key)
		philox_round(key, state)
	}
}

philox_10 :: proc "contextless" (key: $K, counter: $C) -> C {
	when K == u32 do T :: [1]u32
	else when K == u64 do T :: [1]u64
	else do T :: K
	counter := counter
	philox_gen(10, cast(T)key, &counter)
	return counter
}

philox_2x32_10 :: proc "contextless" (key: u32, counter: [2]u32) -> [2]u32 {
	return philox_10(key, counter)
}

philox_4x32_10 :: proc "contextless" (key: [2]u32, counter: [4]u32) -> [4]u32 {
	return philox_10(key, counter)
}

philox_2x64_10 :: proc "contextless" (key: u64, counter: [2]u64) -> [2]u64 {
	return philox_10(key, counter)
}

philox_4x64_10 :: proc "contextless" (key: [2]u64, counter: [4]u64) -> [4]u64 {
	return philox_10(key, counter)
}
