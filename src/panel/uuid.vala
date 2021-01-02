/*
 * This file is part of budgie-desktop.
 *
 * Copyright © 2015-2021 Budgie Desktop Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 */

namespace LibUUID {
	public enum UUIDFlags {
		LOWER_CASE = 1 << 0,
		UPPER_CASE = 1 << 1,
		DEFAULT_CASE = 1 << 2,
		RANDOM_TYPE = 1 << 3,
		DEFAULT_TYPE = 1 << 4,
		TIME_TYPE = 1 << 5,
		TIME_SAFE_TYPE = 1 << 6
	}

	public static string @new(LibUUID.UUIDFlags flags) {
		uint8 time[16];
		char uuid[37];
		if ((flags & LibUUID.UUIDFlags.RANDOM_TYPE) != 0) {
			LibUUID.generate_random(time);
		} else if ((flags & LibUUID.UUIDFlags.TIME_TYPE) != 0) {
			LibUUID.generate_time(time);
		} else if ((flags & LibUUID.UUIDFlags.TIME_SAFE_TYPE) != 0) {
			LibUUID.generate_time_safe(time);
		} else {
			LibUUID.generate(time);
		}

		if ((flags & LibUUID.UUIDFlags.UPPER_CASE) != 0) {
			LibUUID.unparse_upper(time, uuid);
		} else if ((flags & LibUUID.UUIDFlags.LOWER_CASE) != 0) {
			LibUUID.unparse_lower(time, uuid);
		} else {
			LibUUID.unparse(time, uuid);
		}
		return (string)uuid;
	}
}
