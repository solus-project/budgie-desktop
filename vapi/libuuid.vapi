[CCode (cheader_filename = "uuid.h", lower_case_cprefix = "uuid_")]

namespace LibUUID {
    public static void unparse ([CCode (array_length = false)] uint8 uu[16], [CCode (array_length = false)] char @out[37]);
    public static void unparse_lower ([CCode (array_length = false)] uint8 uu[16], [CCode (array_length = false)] char @out[37]);
	public static void unparse_upper ([CCode (array_length = false)] uint8 uu[16], [CCode (array_length = false)] char @out[37]);
	public static void generate ([CCode (array_length = false)] uint8 @out[16]);
	public static void generate_random ([CCode (array_length = false)] uint8 @out[16]);
	public static void generate_time ([CCode (array_length = false)] uint8 @out[16]);
	public static void generate_time_safe ([CCode (array_length = false)] uint8 @out[16]);
}
