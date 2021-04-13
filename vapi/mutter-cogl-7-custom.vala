namespace Cogl {
	[Compact]
	[CCode (cname = "CoglHandle")]
	public class Buffer: Handle {
		public uint get_size ();
		public bool set_data (size_t offset, [CCode (array_length_type = "size_t")] uint8[] data);
		public void unmap ();
	}

	[CCode (has_type_id = false)]
	public struct Color {
		public Color.from_4f (float red, float green, float blue, float alpha);
		public Color.from_4ub (uint8 red, uint8 green, uint8 blue, uint8 alpha);
	}

	[Compact]
	[CCode (ref_function = "cogl_handle_ref", unref_function = "cogl_handle_unref")]
	public class Handle {
		[CCode (cname = "cogl_is_bitmap")]
		public bool is_bitmap ();
		[CCode (cname = "cogl_is_buffer")]
		public bool is_buffer ();
		[CCode (cname = "cogl_is_material")]
		public bool is_material ();
		[CCode (cname = "cogl_is_offscreen")]
		public bool is_offscreen ();
		[CCode (cname = "cogl_is_pixel_buffer")]
		public bool is_pixel_buffer ();
		[CCode (cname = "cogl_is_program")]
		public bool is_program ();
		[CCode (cname = "cogl_is_shader")]
		public bool is_shader ();
		[CCode (cname = "cogl_is_texture")]
		public bool is_texture ();
		[CCode (cname = "cogl_is_vertex_buffer")]
		public bool is_vertex_buffer ();
	}

	[CCode (cheader_filename = "cogl/cogl.h", copy_function = "cogl_path_copy")]
	[Compact]
	public class Path {
		public static void @new ();
	}

	[Compact]
	public class PixelBuffer: Handle {
		public PixelBuffer (uint size);
		public PixelBuffer.for_size (uint width, uint height, Cogl.PixelFormat format, uint stride);
	}

	[Compact]
	[CCode (cname = "CoglHandle", ref_function = "cogl_program_ref", unref_function = "cogl_program_unref")]
	public class Program: Handle {
		[CCode (cname = "cogl_create_program", type = "CoglHandle*", has_construct_function = false)]
		public Program ();
		public void attach_shader (Cogl.Shader shader_handle);
		public int get_uniform_location (string uniform_name);
		public void link ();
		public static void uniform_1f (int uniform_no, float value);
		public static void uniform_1i (int uniform_no, int value);
		public static void uniform_float (int uniform_no, int size, [CCode (array_length_pos = 2.9)] float[] value);
		public static void uniform_int (int uniform_no, int size, [CCode (array_length_pos = 2.9)] int[] value);
		public static void uniform_matrix (int uniform_no, int size, bool transpose, [CCode (array_length_pos = 2.9)] float[] value);
		public void use ();
	}

	[Compact]
	[CCode (cname = "CoglHandle", ref_function = "cogl_shader_ref", unref_function = "cogl_shader_unref")]
	public class Shader: Handle {
		[CCode (cname = "cogl_create_shader", type = "CoglHandle*", has_construct_function = false)]
		public Shader (Cogl.ShaderType shader_type);
		public void compile ();
		public string get_info_log ();
		public Cogl.ShaderType get_type ();
		public bool is_compiled ();
		public void source (string source);
	}

	[Compact]
	[CCode (cname = "CoglHandle", ref_function = "cogl_vertex_buffer_ref", unref_function = "cogl_vertex_buffer_unref")]
	public class VertexBuffer: Handle {
		[CCode (type = "CoglHandle*", has_construct_function = false)]
		public VertexBuffer (uint n_vertices);
		public void add (string attribute_name, uchar n_components, Cogl.AttributeType type, bool normalized, uint16 stride, void* pointer);
		public void delete (string attribute_name);
		public void disable (string attribute_name);
		public void draw (Cogl.VerticesMode mode, int first, int count);
		public void draw_elements (Cogl.VerticesMode mode, VertexBufferIndices indices, int min_index, int max_index, int indices_offset, int count);
		public void enable (string attribute_name);
		public uint get_n_vertices ();
		public void submit ();
	}

	[Compact]
	[CCode (cname = "CoglHandle")]
	public class VertexBufferIndices: Handle {
		public VertexBufferIndices (Cogl.IndicesType indices_type, void* indices_array, int indices_len);
		public static unowned Cogl.VertexBufferIndices get_for_quads (uint n_indices);
		public Cogl.IndicesType get_type ();
	}

	[CCode (type_id = "COGL_TYPE_MATRIX", cheader_filename = "cogl/cogl.h")]
	public struct Matrix {
		[CCode (cname = "cogl_matrix_init_from_array", array_length = false, array_null_terminated = false)]
		public Matrix.from_array ([CCode (array_length = false)] float[] array);
		[CCode (cname = "cogl_matrix_init_identity")]
		public Matrix.identity ();
		[CCode (cname = "cogl_matrix_multiply")]
		public Matrix.multiply (Cogl.Matrix a, Cogl.Matrix b);
	}

	[SimpleType]
	[GIR (name = "Bool")]
	[BooleanType]
	public struct Bool : bool {
	}

	public static GLib.Callback get_proc_address(string s);
}
