/*
 * Lossy VP8 core derived from SimpleWebP commit
 * d1a728a1f8ec7348ca2a5039b6dd813b83986fbb.
 * See LICENSE.md and PATENTS.md.
 */

struct swebp__picture_header
{
	simplewebp_u16 width, height;
	simplewebp_u8 xscale, yscale, colorspace, clamp_type;
};

struct swebp__finfo
{
	simplewebp_u8 limit, ilevel, inner, hev_thresh;
};

struct swebp__topsmp
{
	simplewebp_u8 y[16], u[8], v[8];
};

struct swebp__mblock
{
	simplewebp_u8 nz, nz_dc;
};

struct swebp__mblockdata
{
	simplewebp_i16 coeffs[384];
	simplewebp_u32 nonzero_y, nonzero_uv;
	simplewebp_u8 imodes[16], is_i4x4, uvmode, dither, skip, segment;
};

typedef simplewebp_u8 swebp__probarray[11];

struct swebp__bandprobas
{
	swebp__probarray probas[3];
};

struct swebp__proba
{
	simplewebp_u8 segments[3];
	struct swebp__bandprobas bands[4][8];
	const struct swebp__bandprobas *bands_ptr[4][17];
};

struct swebp__frame_header
{
	simplewebp_u8 key_frame, profile, show;
	simplewebp_u32 partition_length;
};

struct swebp__filter_header
{
	simplewebp_u8 simple, level, sharpness, use_lf_delta;
	simplewebp_i32 ref_lf_delta[4], mode_lf_delta[4];
};

struct swebp__segment_header
{
	simplewebp_u8 use_segment, update_map, absolute_delta;
	simplewebp_i8 quantizer[4], filter_strength[4];
};

/* Bit reader and boolean decoder */
struct swebp__bdec
{
	WebPDecoder *decoderP;
	WebPBoolReader reader;
};

typedef simplewebp_i32 swebp__quant_t[2];
struct swebp__quantmat
{
	swebp__quant_t y1_mat, y2_mat, uv_mat;
	simplewebp_i32 uv_quant, dither;
};

struct swebp__alpha
{
	simplewebp_u8 filter_method;
	simplewebp_bool is_lossless_compressed;
};

struct swebp__vp8
{
	simplewebp_u8 ready;

	struct swebp__bdec br;
	struct swebp__frame_header frame_header;
	struct swebp__picture_header picture_header;
	struct swebp__filter_header filter_header;
	struct swebp__segment_header segment_header;

	simplewebp_i32 mb_w, mb_h;
	simplewebp_i32 tl_mb_x, tl_mb_y;
	simplewebp_i32 br_mb_x, br_mb_y;

	simplewebp_u32 nparts_minus_1;
	struct swebp__bdec parts[8];

	struct swebp__quantmat dqm[4];

	struct swebp__proba proba;
	simplewebp_u8 use_skip_proba, skip_proba;

	simplewebp_u8 *intra_t, intra_l[4];

	struct swebp__topsmp *yuv_t;

	struct swebp__mblock *mb_info;
	struct swebp__finfo *f_info;
	simplewebp_u8 *yuv_b;


	simplewebp_u8 *cache_y, *cache_u, *cache_v;
	simplewebp_i32 cache_y_stride, cache_uv_stride;


	simplewebp_u8* mem;
	size_t mem_size;

	simplewebp_i32 mb_x, mb_y;
	struct swebp__mblockdata *mb_data;

	simplewebp_i8 filter_type;
	struct swebp__finfo fstrengths[4][2];

	simplewebp_u8 *alpha_plane;
};
struct swebp__yuvdst
{
	WebPDecoder *decoderP;
	simplewebp_u8 *rgbP;
	word firstLine;
	word lineCount;
};

struct swebp__pixel
{
	simplewebp_u8 r, g, b, a;
};

struct swebp__chroma
{
	simplewebp_u8 u, v;
};
static void swebp__bitread_init(struct swebp__bdec *br,
	WebPDecoder *decoderP, dword start, dword size, Boolean token)
{
	br->decoderP = decoderP;
	WebPBoolInit(decoderP, &br->reader, start, size, token);
}

static simplewebp_u32 swebp__bitread_getbit(struct swebp__bdec *br, simplewebp_u32 prob)
{
	return WebPBoolGet(br->decoderP, &br->reader, (word)prob);
}

static simplewebp_u32 swebp__bitread_getval(struct swebp__bdec *br, simplewebp_u8 bits)
{
	simplewebp_u32 value = 0;

	while (bits--)
		value |= swebp__bitread_getbit(br, 0x80) << bits;

	return value;
}

static simplewebp_i32 swebp__bitread_getvalsigned(struct swebp__bdec *br, simplewebp_u8 bits)
{
	simplewebp_i32 value = swebp__bitread_getval(br, bits);
	return swebp__bitread_getval(br, 1) ? -value : value;
}

static simplewebp_i32 swebp__bitread_getsigned(struct swebp__bdec *br, simplewebp_i32 v)
{
	return swebp__bitread_getbit(br, 128) ? -v : v;
}

/* RFC 6386 section 14.1 */
static const simplewebp_u8 swebp__dctab[128] = {
  4,     5,   6,   7,   8,   9,  10,  10,
  11,   12,  13,  14,  15,  16,  17,  17,
  18,   19,  20,  20,  21,  21,  22,  22,
  23,   23,  24,  25,  25,  26,  27,  28,
  29,   30,  31,  32,  33,  34,  35,  36,
  37,   37,  38,  39,  40,  41,  42,  43,
  44,   45,  46,  46,  47,  48,  49,  50,
  51,   52,  53,  54,  55,  56,  57,  58,
  59,   60,  61,  62,  63,  64,  65,  66,
  67,   68,  69,  70,  71,  72,  73,  74,
  75,   76,  76,  77,  78,  79,  80,  81,
  82,   83,  84,  85,  86,  87,  88,  89,
  91,   93,  95,  96,  98, 100, 101, 102,
  104, 106, 108, 110, 112, 114, 116, 118,
  122, 124, 126, 128, 130, 132, 134, 136,
  138, 140, 143, 145, 148, 151, 154, 157
};

static const simplewebp_u16 swebp__actab[128] = {
	4,     5,   6,   7,   8,   9,  10,  11,
	12,   13,  14,  15,  16,  17,  18,  19,
	20,   21,  22,  23,  24,  25,  26,  27,
	28,   29,  30,  31,  32,  33,  34,  35,
	36,   37,  38,  39,  40,  41,  42,  43,
	44,   45,  46,  47,  48,  49,  50,  51,
	52,   53,  54,  55,  56,  57,  58,  60,
	62,   64,  66,  68,  70,  72,  74,  76,
	78,   80,  82,  84,  86,  88,  90,  92,
	94,   96,  98, 100, 102, 104, 106, 108,
	110, 112, 114, 116, 119, 122, 125, 128,
	131, 134, 137, 140, 143, 146, 149, 152,
	155, 158, 161, 164, 167, 170, 173, 177,
	181, 185, 189, 193, 197, 201, 205, 209,
	213, 217, 221, 225, 229, 234, 239, 245,
	249, 254, 259, 264, 269, 274, 279, 284
};

/* RFC 6386 section 13 */
static const simplewebp_u8 swebp__coeff_update_proba[4][8][3][11] = {
	{ { { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 176, 246, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 223, 241, 252, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 249, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 244, 252, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 234, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 246, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 239, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 251, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 251, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 254, 253, 255, 254, 255, 255, 255, 255, 255, 255 },
			{ 250, 255, 254, 255, 254, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		}
	},
	{ { { 217, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 225, 252, 241, 253, 255, 255, 254, 255, 255, 255, 255 },
			{ 234, 250, 241, 250, 253, 255, 253, 254, 255, 255, 255 }
		},
		{ { 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 223, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 238, 253, 254, 254, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 248, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 249, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 253, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 247, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 252, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 253, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 254, 253, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		}
	},
	{ { { 186, 251, 250, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 234, 251, 244, 254, 255, 255, 255, 255, 255, 255, 255 },
			{ 251, 251, 243, 253, 254, 255, 254, 255, 255, 255, 255 }
		},
		{ { 255, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 236, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 251, 253, 253, 254, 254, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		}
	},
	{ { { 248, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 250, 254, 252, 254, 255, 255, 255, 255, 255, 255, 255 },
			{ 248, 254, 249, 253, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 246, 253, 253, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 252, 254, 251, 254, 254, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 254, 252, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 248, 254, 253, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 253, 255, 254, 254, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 245, 251, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 253, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 251, 253, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 252, 253, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 252, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 249, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 254, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 253, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 250, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		},
		{ { 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
			{ 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 }
		}
	}
};

/* RFC 6386 section 13.5 */
static const simplewebp_u8 swebp__coeff_proba0[4][8][3][11] = {
	{ { { 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 }
		},
		{ { 253, 136, 254, 255, 228, 219, 128, 128, 128, 128, 128 },
			{ 189, 129, 242, 255, 227, 213, 255, 219, 128, 128, 128 },
			{ 106, 126, 227, 252, 214, 209, 255, 255, 128, 128, 128 }
		},
		{ { 1, 98, 248, 255, 236, 226, 255, 255, 128, 128, 128 },
			{ 181, 133, 238, 254, 221, 234, 255, 154, 128, 128, 128 },
			{ 78, 134, 202, 247, 198, 180, 255, 219, 128, 128, 128 },
		},
		{ { 1, 185, 249, 255, 243, 255, 128, 128, 128, 128, 128 },
			{ 184, 150, 247, 255, 236, 224, 128, 128, 128, 128, 128 },
			{ 77, 110, 216, 255, 236, 230, 128, 128, 128, 128, 128 },
		},
		{ { 1, 101, 251, 255, 241, 255, 128, 128, 128, 128, 128 },
			{ 170, 139, 241, 252, 236, 209, 255, 255, 128, 128, 128 },
			{ 37, 116, 196, 243, 228, 255, 255, 255, 128, 128, 128 }
		},
		{ { 1, 204, 254, 255, 245, 255, 128, 128, 128, 128, 128 },
			{ 207, 160, 250, 255, 238, 128, 128, 128, 128, 128, 128 },
			{ 102, 103, 231, 255, 211, 171, 128, 128, 128, 128, 128 }
		},
		{ { 1, 152, 252, 255, 240, 255, 128, 128, 128, 128, 128 },
			{ 177, 135, 243, 255, 234, 225, 128, 128, 128, 128, 128 },
			{ 80, 129, 211, 255, 194, 224, 128, 128, 128, 128, 128 }
		},
		{ { 1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 246, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 }
		}
	},
	{ { { 198, 35, 237, 223, 193, 187, 162, 160, 145, 155, 62 },
			{ 131, 45, 198, 221, 172, 176, 220, 157, 252, 221, 1 },
			{ 68, 47, 146, 208, 149, 167, 221, 162, 255, 223, 128 }
		},
		{ { 1, 149, 241, 255, 221, 224, 255, 255, 128, 128, 128 },
			{ 184, 141, 234, 253, 222, 220, 255, 199, 128, 128, 128 },
			{ 81, 99, 181, 242, 176, 190, 249, 202, 255, 255, 128 }
		},
		{ { 1, 129, 232, 253, 214, 197, 242, 196, 255, 255, 128 },
			{ 99, 121, 210, 250, 201, 198, 255, 202, 128, 128, 128 },
			{ 23, 91, 163, 242, 170, 187, 247, 210, 255, 255, 128 }
		},
		{ { 1, 200, 246, 255, 234, 255, 128, 128, 128, 128, 128 },
			{ 109, 178, 241, 255, 231, 245, 255, 255, 128, 128, 128 },
			{ 44, 130, 201, 253, 205, 192, 255, 255, 128, 128, 128 }
		},
		{ { 1, 132, 239, 251, 219, 209, 255, 165, 128, 128, 128 },
			{ 94, 136, 225, 251, 218, 190, 255, 255, 128, 128, 128 },
			{ 22, 100, 174, 245, 186, 161, 255, 199, 128, 128, 128 }
		},
		{ { 1, 182, 249, 255, 232, 235, 128, 128, 128, 128, 128 },
			{ 124, 143, 241, 255, 227, 234, 128, 128, 128, 128, 128 },
			{ 35, 77, 181, 251, 193, 211, 255, 205, 128, 128, 128 }
		},
		{ { 1, 157, 247, 255, 236, 231, 255, 255, 128, 128, 128 },
			{ 121, 141, 235, 255, 225, 227, 255, 255, 128, 128, 128 },
			{ 45, 99, 188, 251, 195, 217, 255, 224, 128, 128, 128 }
		},
		{ { 1, 1, 251, 255, 213, 255, 128, 128, 128, 128, 128 },
			{ 203, 1, 248, 255, 255, 128, 128, 128, 128, 128, 128 },
			{ 137, 1, 177, 255, 224, 255, 128, 128, 128, 128, 128 }
		}
	},
	{ { { 253, 9, 248, 251, 207, 208, 255, 192, 128, 128, 128 },
			{ 175, 13, 224, 243, 193, 185, 249, 198, 255, 255, 128 },
			{ 73, 17, 171, 221, 161, 179, 236, 167, 255, 234, 128 }
		},
		{ { 1, 95, 247, 253, 212, 183, 255, 255, 128, 128, 128 },
			{ 239, 90, 244, 250, 211, 209, 255, 255, 128, 128, 128 },
			{ 155, 77, 195, 248, 188, 195, 255, 255, 128, 128, 128 }
		},
		{ { 1, 24, 239, 251, 218, 219, 255, 205, 128, 128, 128 },
			{ 201, 51, 219, 255, 196, 186, 128, 128, 128, 128, 128 },
			{ 69, 46, 190, 239, 201, 218, 255, 228, 128, 128, 128 }
		},
		{ { 1, 191, 251, 255, 255, 128, 128, 128, 128, 128, 128 },
			{ 223, 165, 249, 255, 213, 255, 128, 128, 128, 128, 128 },
			{ 141, 124, 248, 255, 255, 128, 128, 128, 128, 128, 128 }
		},
		{ { 1, 16, 248, 255, 255, 128, 128, 128, 128, 128, 128 },
			{ 190, 36, 230, 255, 236, 255, 128, 128, 128, 128, 128 },
			{ 149, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 }
		},
		{ { 1, 226, 255, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 247, 192, 255, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 240, 128, 255, 128, 128, 128, 128, 128, 128, 128, 128 }
		},
		{ { 1, 134, 252, 255, 255, 128, 128, 128, 128, 128, 128 },
			{ 213, 62, 250, 255, 255, 128, 128, 128, 128, 128, 128 },
			{ 55, 93, 255, 128, 128, 128, 128, 128, 128, 128, 128 }
		},
		{ { 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128 }
		}
	},
	{ { { 202, 24, 213, 235, 186, 191, 220, 160, 240, 175, 255 },
			{ 126, 38, 182, 232, 169, 184, 228, 174, 255, 187, 128 },
			{ 61, 46, 138, 219, 151, 178, 240, 170, 255, 216, 128 }
		},
		{ { 1, 112, 230, 250, 199, 191, 247, 159, 255, 255, 128 },
			{ 166, 109, 228, 252, 211, 215, 255, 174, 128, 128, 128 },
			{ 39, 77, 162, 232, 172, 180, 245, 178, 255, 255, 128 }
		},
		{ { 1, 52, 220, 246, 198, 199, 249, 220, 255, 255, 128 },
			{ 124, 74, 191, 243, 183, 193, 250, 221, 255, 255, 128 },
			{ 24, 71, 130, 219, 154, 170, 243, 182, 255, 255, 128 }
		},
		{ { 1, 182, 225, 249, 219, 240, 255, 224, 128, 128, 128 },
			{ 149, 150, 226, 252, 216, 205, 255, 171, 128, 128, 128 },
			{ 28, 108, 170, 242, 183, 194, 254, 223, 255, 255, 128 }
		},
		{ { 1, 81, 230, 252, 204, 203, 255, 192, 128, 128, 128 },
			{ 123, 102, 209, 247, 188, 196, 255, 233, 128, 128, 128 },
			{ 20, 95, 153, 243, 164, 173, 255, 203, 128, 128, 128 }
		},
		{ { 1, 222, 248, 255, 216, 213, 128, 128, 128, 128, 128 },
			{ 168, 175, 246, 252, 235, 205, 255, 255, 128, 128, 128 },
			{ 47, 116, 215, 255, 211, 212, 255, 255, 128, 128, 128 }
		},
		{ { 1, 121, 236, 253, 212, 214, 255, 255, 128, 128, 128 },
			{ 141, 84, 213, 252, 201, 202, 255, 219, 128, 128, 128 },
			{ 42, 80, 160, 240, 162, 185, 255, 205, 128, 128, 128 }
		},
		{ { 1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 244, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 },
			{ 238, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128 }
		}
	}
};

static const simplewebp_u8 swebp__fextrarows[3] = {2, 2, 8};

#ifndef WEBP_HOST_TEST
#pragma code_seg("WebPDspCode")
#endif

/* RFC 6386 section 14.4 */
static void swebp__transform_wht(const simplewebp_i16 *in, simplewebp_i16 *out)
{
	simplewebp_i32 temp[16], i;

	for (i = 0; i < 4; i++)
	{
		simplewebp_i32 a0, a1, a2, a3;

		a0 = (simplewebp_i32)in[i] + in[i + 12];
		a1 = (simplewebp_i32)in[i + 4] + in[i + 8];
		a2 = (simplewebp_i32)in[i + 4] - in[i + 8];
		a3 = (simplewebp_i32)in[i] - in[i + 12];
		temp[i] = a0 + a1;
		temp[i + 4] = a3 + a2;
		temp[i + 8] = a0 - a1;
		temp[i + 12] = a3 - a2;
	}
	for (i = 0; i < 4; i++)
	{
		simplewebp_i32 dc, a0, a1, a2, a3;

		dc = temp[i * 4] + 3;
		a0 = dc + temp[i * 4 + 3];
		a1 = temp[i * 4 + 1] + temp[i * 4 + 2];
		a2 = temp[i * 4 + 1] - temp[i * 4 + 2];
		a3 = dc - temp[i * 4 + 3];
		out[i * 64] = (a0 + a1) >> 3;
		out[i * 64 + 16] = (a3 + a2) >> 3;
		out[i * 64 + 32] = (a0 - a1) >> 3;
		out[i * 64 + 48] = (a3 - a2) >> 3;
	}
}

static simplewebp_i32 swebp__mul1(simplewebp_i16 a)
{
	return (((simplewebp_i32) a * 20091) >> 16) + a;
}

static simplewebp_i32 swebp__mul2(simplewebp_i16 a)
{
	return ((simplewebp_i32) a * 35468) >> 16;
}


static simplewebp_u8 swebp__clip8b(simplewebp_i32 v) {
	return (!(v & ~0xff)) ? v : (v < 0) ? 0 : 255;
}

static void swebp__store(simplewebp_u8 *out, simplewebp_i32 x, simplewebp_i32 y, simplewebp_i32 v)
{
	out[y * 32 + x] = swebp__clip8b(out[y * 32 + x] + (v >> 3));
}

static void swebp__transform_one(const simplewebp_i16 *in, simplewebp_u8 *out)
{
	simplewebp_i32 tmp[16], i;

	/* Vertical pass */
	for (i = 0; i < 4; i++)
	{
		simplewebp_i32 a, b, c, d;

		a = (simplewebp_i32)in[i] + in[i + 8];
		b = (simplewebp_i32)in[i] - in[i + 8];
		c = swebp__mul2(in[i + 4]) - swebp__mul1(in[i + 12]);
		d = swebp__mul1(in[i + 4]) + swebp__mul2(in[i + 12]);
		tmp[i * 4] = a + d;
		tmp[i * 4 + 1] = b + c;
		tmp[i * 4 + 2] = b - c;
		tmp[i * 4 + 3] = a - d;
	}
	/* Horizontal pass */
	for (i = 0; i < 4; i++)
	{
		simplewebp_i32 dc, a, b, c, d;

		dc = tmp[i] + 4;
		a = dc + tmp[i + 8];
		b = dc - tmp[i + 8];
		c = swebp__mul2(tmp[i + 4]) - swebp__mul1(tmp[i + 12]);
		d = swebp__mul1(tmp[i + 4]) + swebp__mul2(tmp[i + 12]);
		swebp__store(out, 0, i, a + d);
		swebp__store(out, 1, i, b + c);
		swebp__store(out, 2, i, b - c);
		swebp__store(out, 3, i, a - d);
	}
}

static void swebp__transform(const simplewebp_i16 *in, simplewebp_u8 *out, simplewebp_u8 do_2)
{
	swebp__transform_one(in, out);
	if (do_2)
		swebp__transform_one(in + 16, out + 4);
}

static void swebp__transform_dc(const simplewebp_i16 *in, simplewebp_u8 *out)
{
	simplewebp_i32 dc, x, y;
	dc = (simplewebp_i32)in[0] + 4;

	for (y = 0; y < 4; y++)
	{
		for (x = 0; x < 4; x++)
			swebp__store(out, x, y, dc);
	}
}

static void swebp__store2(simplewebp_u8 *out, simplewebp_i32 y, simplewebp_i32 dc, simplewebp_i32 d, simplewebp_i32 c)
{
	swebp__store(out, 0, y, dc + d);
	swebp__store(out, 1, y, dc + c);
	swebp__store(out, 2, y, dc - c);
	swebp__store(out, 3, y, dc - d);
}

static void swebp__transform_ac3(const simplewebp_i16 *in, simplewebp_u8 *out)
{
	simplewebp_i32 a, c4, d4, c1, d1;

	a = (simplewebp_i32)in[0] + 4;
	c4 = swebp__mul2(in[4]);
	d4 = swebp__mul1(in[4]);
	c1 = swebp__mul2(in[1]);
	d1 = swebp__mul1(in[1]);
	swebp__store2(out, 0, a + d4, d1, c1);
	swebp__store2(out, 1, a + c4, d1, c1);
	swebp__store2(out, 2, a - c4, d1, c1);
	swebp__store2(out, 3, a - d4, d1, c1);
}

static void swebp__transform_uv(const simplewebp_i16 *in, simplewebp_u8 *out)
{
	swebp__transform(in, out, 1);
	swebp__transform(in + 32 /* 2*16 */, out + 128 /* 4*BPS */, 1);
}

static void swebp__transform_dcuv(const simplewebp_i16 *in, simplewebp_u8 *out)
{
	if (in[0])
		swebp__transform_dc(in, out);
	if (in[16])
		swebp__transform_dc(in + 16, out + 4);
	if (in[32])
		swebp__transform_dc(in + 32, out + 128);
	if (in[48])
		swebp__transform_dc(in + 48, out + 132);
}

/* Host tests use the C reference filters below, including the simple filters.
 * PC/GEOS builds use WebPFilterSimple/24/26 from webpfilter.asm; _pascal
 * resolves these calls to WEBPFILTERSIMPLE/24/26. Host tests do not run ASM.
 */
#ifdef WEBP_HOST_TEST
static simplewebp_i32 swebp__abs(simplewebp_i32 v)
{
	return v < 0 ? -v : v;
}

static simplewebp_i32 swebp__sclip1_value(simplewebp_i32 v)
{
	return v < -128 ? -128 : (v > 127 ? 127 : v);
}

static simplewebp_i32 swebp__sclip2_value(simplewebp_i32 v)
{
	return v < -16 ? -16 : (v > 15 ? 15 : v);
}
#endif

static simplewebp_u8 swebp__clip1_value(simplewebp_i32 v)
{
	return v < 0 ? 0 : (v > 255 ? 255 : (simplewebp_u8) v);
}

#ifdef WEBP_HOST_TEST
static simplewebp_i32 swebp__needsfilter2(const simplewebp_u8 *p, simplewebp_i32 step, simplewebp_i32 t, simplewebp_i32 it)
{
	simplewebp_i32 p3, p2, p1, p0, q0, q1, q2, q3;
	p3 = p[-4 * step];
	p2 = p[-3 * step];
	p1 = p[-2 * step];
	p0 = p[-step];
	q0 = p[0];
	q1 = p[step];
	q2 = p[2 * step];
	q3 = p[3 * step];

	if ((4 * swebp__abs(p0 - q0) + swebp__abs(p1 - q1)) > t)
		return 0;

	return
		swebp__abs(p3 - p2) <= it &&
		swebp__abs(p2 - p1) <= it &&
		swebp__abs(p1 - p0) <= it &&
		swebp__abs(q3 - q2) <= it &&
		swebp__abs(q2 - q1) <= it &&
		swebp__abs(q1 - q0) <= it;
}

static simplewebp_i32 swebp__hev(const simplewebp_u8 *p, simplewebp_i32 step, simplewebp_i32 thresh)
{
	simplewebp_i32 p1, p0, q0, q1;

	p1 = p[-2 * step];
	p0 = p[-step];
	q0 = p[0];
	q1 = p[step];

	return (swebp__abs(p1 - p0) > thresh) || (swebp__abs(q1 - q0) > thresh);
}

static void swebp__do_filter2(simplewebp_u8 *p, simplewebp_i32 step)
{
	simplewebp_i32 p1, p0, q0, q1, a, a1, a2;

	p1 =  p[-2 * step];
	p0 = p[-step];
	q0 = p[0];
	q1 = p[step];
	a = 3 * (q0 - p0) + swebp__sclip1_value(p1 - q1);
	a1 =  swebp__sclip2_value((a + 4) >> 3);
	a2 =  swebp__sclip2_value((a + 3) >> 3);
	p[-step] = swebp__clip1_value(p0 + a2);
	p[0] = swebp__clip1_value(q0 - a1);
}

static void swebp__do_filter6(simplewebp_u8 *p, simplewebp_i32 step)
{
	simplewebp_i32 p2, p1, p0, q0, q1, q2, a, a1, a2, a3;

	p2 =  p[-3 * step];
	p1 =  p[-2 * step];
	p0 = p[-step];
	q0 = p[0];
	q1 = p[step];
	q2 = p[2 * step];
	a = swebp__sclip1_value(3 * (q0 - p0) +
		swebp__sclip1_value(p1 - q1));
	a1 = (27 * a + 63) >> 7;
	a2 = (18 * a + 63) >> 7;
	a3 = (9 * a + 63) >> 7;

	p[-3 * step] = swebp__clip1_value(p2 + a3);
	p[-2 * step] = swebp__clip1_value(p1 + a2);
	p[-step] = swebp__clip1_value(p0 + a1);
	p[0] = swebp__clip1_value(q0 - a1);
	p[step] = swebp__clip1_value(q1 - a2);
	p[2 * step] = swebp__clip1_value(q2 - a3);
}

static void swebp__filterloop26(simplewebp_u8 *p, simplewebp_i32 hstride, simplewebp_i32 vstride, simplewebp_i32 size, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	simplewebp_i32 thresh2 = 2 * thresh + 1;

	while (size-- > 0)
	{
		if (swebp__needsfilter2(p, hstride, thresh2, ithresh))
		{
			if (swebp__hev(p, hstride, hev_thresh))
				swebp__do_filter2(p, hstride);
			else
				swebp__do_filter6(p, hstride);
		}

		p += vstride;
	}
}

static void swebp__do_filter4(simplewebp_u8 *p, simplewebp_i32 step)
{
	simplewebp_i32 p1, p0, q0, q1, a, a1, a2, a3;

	p1 =  p[-2 * step];
	p0 = p[-step];
	q0 = p[0];
	q1 = p[step];
	a = 3 * (q0 - p0);
	a1 = swebp__sclip2_value((a + 4) >> 3);
	a2 = swebp__sclip2_value((a + 3) >> 3);
	a3 = (a1 + 1) >> 1;

	p[-2 * step] = swebp__clip1_value(p1 + a3);
	p[-step] = swebp__clip1_value(p0 + a2);
	p[0] = swebp__clip1_value(q0 - a1);
	p[step] = swebp__clip1_value(q1 - a3);
}

static void swebp__filterloop24(simplewebp_u8 *p, simplewebp_i32 hstride, simplewebp_i32 vstride, simplewebp_i32 size, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	simplewebp_i32 thresh2 = 2 * thresh + 1;

	while (size-- > 0)
	{
		if (swebp__needsfilter2(p, hstride, thresh2, ithresh))
		{
			if (swebp__hev(p, hstride, hev_thresh))
				swebp__do_filter2(p, hstride);
			else
				swebp__do_filter4(p, hstride);
		}

		p += vstride;
	}
}
#else
#define swebp__filterloop24 WebPFilter24
#define swebp__filterloop26 WebPFilter26
#endif

static void swebp__vfilter16(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	swebp__filterloop26(p, stride, 1, 16, thresh, ithresh, hev_thresh);
}

static void swebp__vfilter16_i(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	simplewebp_i32 i;

	for (i = 3; i > 0; i--)
	{
		p += 4 * stride;
		swebp__filterloop24(p, stride, 1, 16, thresh, ithresh, hev_thresh);
	}
}

static void swebp__hfilter16(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	swebp__filterloop26(p, 1, stride, 16, thresh, ithresh, hev_thresh);
}

static void swebp__vfilter8(simplewebp_u8 *u, simplewebp_u8 *v, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	swebp__filterloop26(u, stride, 1, 8, thresh, ithresh, hev_thresh);
	swebp__filterloop26(v, stride, 1, 8, thresh, ithresh, hev_thresh);
}

static void swebp__vfilter8_i(simplewebp_u8 *u, simplewebp_u8 *v, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	swebp__filterloop24(u + 4 * stride, stride, 1, 8, thresh, ithresh, hev_thresh);
	swebp__filterloop24(v + 4 * stride, stride, 1, 8, thresh, ithresh, hev_thresh);
}

#ifdef WEBP_HOST_TEST
static simplewebp_bool swebp__needsfilter(const simplewebp_u8 *p, simplewebp_i32 step, simplewebp_i32 t)
{
	simplewebp_i32 p1, p0, q0, q1;

	p1 =  p[-2 * step];
	p0 = p[-step];
	q0 = p[0];
	q1 = p[step];
	return (4 * swebp__abs(p0 - q0) + swebp__abs(p1 - q1)) <= t;
}
#endif

static void swebp__simple_vfilter16(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh)
{
#ifdef WEBP_HOST_TEST
	simplewebp_i32 i, thresh2;

	thresh2 = 2 * thresh + 1;
	for (i = 0; i < 16; i++)
	{
		if (swebp__needsfilter(p + i, stride, thresh2))
			swebp__do_filter2(p + i, stride);
	}
#else
	WebPFilterSimple(p, stride, 1, 16, thresh);
#endif
}

static void swebp__simple_hfilter16(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh)
{
#ifdef WEBP_HOST_TEST
	simplewebp_i32 i, thresh2;
	simplewebp_u8 *target;

	thresh2 = 2 * thresh + 1;
	for (i = 0; i < 16; i++)
	{
		target = p + i * stride;

		if (swebp__needsfilter(target, 1, thresh2))
			swebp__do_filter2(target, 1);
	}
#else
	WebPFilterSimple(p, 1, stride, 16, thresh);
#endif
}

static void swebp__simple_vfilter16_i(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh)
{
	simplewebp_i32 k;

	for (k = 3; k > 0; k--)
	{
		p += 4 * stride;
		swebp__simple_vfilter16(p, stride, thresh);
	}
}

static void swebp__simple_hfilter16_i(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh)
{
	simplewebp_i32 k;

	for (k = 3; k > 0; k--)
	{
		p += 4;
		swebp__simple_hfilter16(p, stride, thresh);
	}
}

static void swebp__hfilter16_i(simplewebp_u8 *p, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	simplewebp_i32 k;

	for (k = 3; k > 0; k--)
	{
		p += 4;
		swebp__filterloop24(p, 1, stride, 16, thresh, ithresh, hev_thresh);
	}
}

static void swebp__hfilter8(simplewebp_u8 *u, simplewebp_u8 *v, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	swebp__filterloop26(u, 1, stride, 8, thresh, ithresh, hev_thresh);
	swebp__filterloop26(v, 1, stride, 8, thresh, ithresh, hev_thresh);
}

static void swebp__hfilter8_i(simplewebp_u8 *u, simplewebp_u8 *v, simplewebp_i32 stride, simplewebp_i32 thresh, simplewebp_i32 ithresh, simplewebp_i32 hev_thresh)
{
	swebp__filterloop24(u + 4, 1, stride, 8, thresh, ithresh, hev_thresh);
	swebp__filterloop24(v + 4, 1, stride, 8, thresh, ithresh, hev_thresh);
}

#ifndef WEBP_HOST_TEST
#pragma code_seg("WebPPredCode")
#endif

/* DC */
static void swebp__predluma4_0(simplewebp_u8 *out)
{
	simplewebp_u32 dc;
	simplewebp_i32 i;

	dc = 4;
	for (i = 0; i < 4; i++)
		dc += out[i - 32] + out[-1 + i * 32];
	dc >>= 3;
	for (i = 0; i < 4; i++)
		memset(out + i * 32, dc, 4);
}

static void swebp__truemotion(simplewebp_u8 *out, simplewebp_i32 size)
{
	const simplewebp_u8 *top;
	simplewebp_i32 x, y, left, topLeft;

	top = out - 32;
	topLeft = top[-1];

	for (y = 0; y < size; y++)
	{
		left = out[-1];

		for (x = 0; x < size; x++)
			out[x] = swebp__clip1_value(top[x] + left - topLeft);

		out += 32;
	}
}

/* TM4 */
static void swebp__predluma4_1(simplewebp_u8 *out)
{
	swebp__truemotion(out, 4);
}

static simplewebp_u8 swebp__avg3(simplewebp_u32 a, simplewebp_u32 b, simplewebp_u32 c)
{
	return (simplewebp_u8) ((a + 2 * b + c + 2) >> 2);
}

/* Vertical */
static void swebp__predluma4_2(simplewebp_u8 *out)
{
	const simplewebp_u8 *top;
	simplewebp_u8 vals[4], i;

	top = out - 32;

	for (i = 0; i < 4; i++)
		vals[i] = swebp__avg3(top[i - 1], top[i], top[i + 1]);
	for (i = 0; i < 4; i++)
		memcpy(out + i * 32, vals, sizeof(vals));
}

static void swebp__from_uint32(simplewebp_u8 *out, simplewebp_u32 value)
{
	/* Little endian */
	out[0] = (simplewebp_u8) value;
	out[1] = (simplewebp_u8) (value >> 8);
	out[2] = (simplewebp_u8) (value >> 16);
	out[3] = (simplewebp_u8) (value >> 24);
}

/* Horizontal*/
static void swebp__predluma4_3(simplewebp_u8 *out)
{
	simplewebp_i32 vals[5], i;
	for (i = -1; i < 4; i++)
		vals[i + 1] = out[-1 + i * 32];

	swebp__from_uint32(out, 0x01010101U * swebp__avg3(vals[0], vals[1], vals[2]));
	swebp__from_uint32(out + 32, 0x01010101U * swebp__avg3(vals[1], vals[2], vals[3]));
	swebp__from_uint32(out + 64, 0x01010101U * swebp__avg3(vals[2], vals[3], vals[4]));
	swebp__from_uint32(out + 96, 0x01010101U * swebp__avg3(vals[3], vals[4], vals[4]));
}

/* Right Down */
static void swebp__predluma4_4(simplewebp_u8 *out)
{
	simplewebp_u32 i, j, k, l, x, a, b, c, d;

	i = out[-1];
	j = out[-1 + 1 * 32];
	k = out[-1 + 2 * 32];
	l = out[-1 + 3 * 32];
	x = out[-1 - 32];
	a = out[0 - 32];
	b = out[1 - 32];
	c = out[2 - 32];
	d = out[3 - 32];

	out[3 * 32 + 0] = swebp__avg3(j, k, l);
	out[3 * 32 + 1] = out[2 * 32 + 0] = swebp__avg3(i, j, k);
	out[3 * 32 + 2] = out[2 * 32 + 1] = out[1 * 32 + 0] = swebp__avg3(x, i, j);
	out[3 * 32 + 3] = out[2 * 32 + 2] = out[1 * 32 + 1] = out[0 * 32 + 0] = swebp__avg3(a, x, i);
	out[2 * 32 + 3] = out[1 * 32 + 2] = out[0 * 32 + 1] = swebp__avg3(b, a, x);
	out[1 * 32 + 3] = out[0 * 32 + 2] = swebp__avg3(c, b, a);
	out[0 * 32 + 3] = swebp__avg3(d, c, b);
}

static simplewebp_u8 swebp__avg2(simplewebp_u32 a, simplewebp_u32 b)
{
	return (simplewebp_u8) ((a + b + 1) >> 1);
}

/* Vertical-Right */
static void swebp__predluma4_5(simplewebp_u8 *out)
{
	simplewebp_u32 i, j, k, x, a, b, c, d;

	i = out[-1];
	j = out[-1 + 1 * 32];
	k = out[-1 + 2 * 32];
	x = out[-1 - 32];
	a = out[0 - 32];
	b = out[1 - 32];
	c = out[2 - 32];
	d = out[3 - 32];

	out[0 * 32 + 0] = out[2 * 32 + 1] = swebp__avg2(x, a);
	out[0 * 32 + 1] = out[2 * 32 + 2] = swebp__avg2(a, b);
	out[0 * 32 + 2] = out[2 * 32 + 3] = swebp__avg2(b, c);
	out[0 * 32 + 3] = swebp__avg2(c, d);
	out[3 * 32 + 0] = swebp__avg3(k, j, i);
	out[2 * 32 + 0] = swebp__avg3(j, i, x);
	out[1 * 32 + 0] = out[3 * 32 + 1] = swebp__avg3(i, x, a);
	out[1 * 32 + 1] = out[3 * 32 + 2] = swebp__avg3(x, a, b);
	out[1 * 32 + 2] = out[3 * 32 + 3] = swebp__avg3(a, b, c);
	out[1 * 32 + 3] = swebp__avg3(b, c, d);
}

/* Left Down */
static void swebp__predluma4_6(simplewebp_u8 *out)
{
	simplewebp_i32 a, b, c, d, e, f, g, h;

	a = out[-32];
	b = out[-31];
	c = out[-30];
	d = out[-29];
	e = out[-28];
	f = out[-27];
	g = out[-26];
	h = out[-25];

	out[0 * 32 + 0] = swebp__avg3(a, b, c);
	out[0 * 32 + 1] = out[1 * 32 + 0] = swebp__avg3(b, c, d);
	out[0 * 32 + 2] = out[1 * 32 + 1] = out[2 * 32 + 0] = swebp__avg3(c, d, e);
	out[0 * 32 + 3] = out[1 * 32 + 2] = out[2 * 32 + 1] = out[3 * 32 + 0] = swebp__avg3(d, e, f);
	out[1 * 32 + 3] = out[2 * 32 + 2] = out[3 * 32 + 1] = swebp__avg3(e, f, g);
	out[2 * 32 + 3] = out[3 * 32 + 2] = swebp__avg3(f, g, h);
	out[3 * 32 + 3] = swebp__avg3(g, h, h);
}

/* Vertical-Left */
static void swebp__predluma4_7(simplewebp_u8 *out)
{
	simplewebp_i32 a, b, c, d, e, f, g, h;

	a = out[-32];
	b = out[-31];
	c = out[-30];
	d = out[-29];
	e = out[-28];
	f = out[-27];
	g = out[-26];
	h = out[-25];

	out[0 * 32 + 0] = swebp__avg2(a, b);
	out[0 * 32 + 1] = out[2 * 32 + 0] = swebp__avg2(b, c);
	out[0 * 32 + 2] = out[2 * 32 + 1] = swebp__avg2(c, d);
	out[0 * 32 + 3] = out[2 * 32 + 2] = swebp__avg2(d, e);
	out[1 * 32 + 0] = swebp__avg3(a, b, c);
	out[1 * 32 + 1] = out[3 * 32 + 0] = swebp__avg3(b, c, d);
	out[1 * 32 + 2] = out[3 * 32 + 1] = swebp__avg3(c, d, e);
	out[1 * 32 + 3] = out[3 * 32 + 2] = swebp__avg3(d, e, f);
	out[2 * 32 + 3] = swebp__avg3(e, f, g);
	out[3 * 32 + 3] = swebp__avg3(f, g, h);
}

/* Horizontal-Down */
static void swebp__predluma4_8(simplewebp_u8 *out)
{
	simplewebp_u32 i, j, k, l, x, a, b, c;

	i = out[-1];
	j = out[-1 + 1 * 32];
	k = out[-1 + 2 * 32];
	l = out[-1 + 3 * 32];
	x = out[-1 - 32];
	a = out[0 - 32];
	b = out[1 - 32];
	c = out[2 - 32];

	out[0 * 32 + 0] = out[1 * 32 + 2] = swebp__avg2(i, x);
	out[1 * 32 + 0] = out[2 * 32 + 2] = swebp__avg2(j, i);
	out[2 * 32 + 0] = out[3 * 32 + 2] = swebp__avg2(k, j);
	out[3 * 32 + 0] = swebp__avg2(l, k);
	out[0 * 32 + 3] = swebp__avg3(a, b, c);
	out[0 * 32 + 2] = swebp__avg3(x, a, b);
	out[0 * 32 + 1] = out[1 * 32 + 3] = swebp__avg3(i, x, a);
	out[1 * 32 + 1] = out[2 * 32 + 3] = swebp__avg3(j, i, x);
	out[2 * 32 + 1] = out[3 * 32 + 3] = swebp__avg3(k, j, i);
	out[3 * 32 + 1] = swebp__avg3(l, k, j);
}

/* Horizontal-Up */
static void swebp__predluma4_9(simplewebp_u8 *out)
{
	simplewebp_u32 i, j, k, l;

	i = out[-1];
	j = out[-1 + 1 * 32];
	k = out[-1 + 2 * 32];
	l = out[-1 + 3 * 32];

	out[0 * 32 + 0] = swebp__avg2(i, j);
	out[0 * 32 + 2] = out[1 * 32 + 0] = swebp__avg2(j, k);
	out[1 * 32 + 2] = out[2 * 32 + 0] = swebp__avg2(k, l);
	out[0 * 32 + 1] = swebp__avg3(i, j, k);
	out[0 * 32 + 3] = out[1 * 32 + 1] = swebp__avg3(j, k, l);
	out[1 * 32 + 3] = out[2 * 32 + 1] = swebp__avg3(k, l, l);
	out[2 * 32 + 3] = out[2 * 32 + 2] =
	out[3 * 32 + 0] = out[3 * 32 + 1] =
	out[3 * 32 + 2] = out[3 * 32 + 3] = l;
}

static void swebp__predluma4(simplewebp_u8 num, simplewebp_u8 *out)
{
	switch (num)
	{
		case 0:
			swebp__predluma4_0(out);
			break;
		case 1:
			swebp__predluma4_1(out);
			break;
		case 2:
			swebp__predluma4_2(out);
			break;
		case 3:
			swebp__predluma4_3(out);
			break;
		case 4:
			swebp__predluma4_4(out);
			break;
		case 5:
			swebp__predluma4_5(out);
			break;
		case 6:
			swebp__predluma4_6(out);
			break;
		case 7:
			swebp__predluma4_7(out);
			break;
		case 8:
			swebp__predluma4_8(out);
			break;
		case 9:
			swebp__predluma4_9(out);
			break;
		default:
			break;
	}
}

static void swebp__put16(simplewebp_i32 v, simplewebp_u8 *out)
{
	simplewebp_i32 j;
	for (j = 0; j < 16; j++)
		memset(out + j * 32, v, 16);
}

/* DC */
static void swebp__predluma16_0(simplewebp_u8 *out)
{
	simplewebp_i32 dc, j;

	dc = 16;
	for (j = 0; j < 16; j++)
		dc += out[-1 + j * 32] + out[j - 32];

	swebp__put16(dc >> 5, out);
}

/* TM */
static void swebp__predluma16_1(simplewebp_u8 *out)
{
	swebp__truemotion(out, 16);
}

/* Vertical */
static void swebp__predluma16_2(simplewebp_u8 *out)
{
	simplewebp_i32 j;
	for (j = 0; j < 16; j++)
		memcpy(out + j * 32, out - 32, 16);
}

/* Horizontal */
static void swebp__predluma16_3(simplewebp_u8 *out)
{
	simplewebp_i32 j;
	for (j = 16; j > 0; j--)
	{
		memset(out, out[-1], 16);
		out += 32;
	}
}

/* DC w/o Top */
static void swebp__predluma16_4(simplewebp_u8 *out)
{
	simplewebp_i32 dc, j;

	dc = 8;
	for (j = 0; j < 16; j++)
		dc += out[-1 + j * 32];

	swebp__put16(dc >> 4, out);
}

/* DC w/o Left */
static void swebp__predluma16_5(simplewebp_u8 *out)
{
	simplewebp_i32 dc, j;

	dc = 8;
	for (j = 0; j < 16; j++)
		dc += out[j - 32];

	swebp__put16(dc >> 4, out);
}

/* DC w/o Top Left */
static void swebp__predluma16_6(simplewebp_u8 *out)
{
	swebp__put16(128, out);
}

static void swebp__predluma16(simplewebp_u8 num, simplewebp_u8 *out)
{
	switch (num)
	{
		case 0:
			swebp__predluma16_0(out);
			break;
		case 1:
			swebp__predluma16_1(out);
			break;
		case 2:
			swebp__predluma16_2(out);
			break;
		case 3:
			swebp__predluma16_3(out);
			break;
		case 4:
			swebp__predluma16_4(out);
			break;
		case 5:
			swebp__predluma16_5(out);
			break;
		case 6:
			swebp__predluma16_6(out);
			break;
		default:
			break;
	}
}

static void swebp__put8x8uv(simplewebp_i32 value, simplewebp_u8 *out)
{
	simplewebp_i32 j;
	for (j = 0; j < 8; j++)
		memset(out + j * 32, value, 8);
}

/* DC */
static void swebp__predchroma8_0(simplewebp_u8 *out)
{
	simplewebp_i32 dc0, i;

	dc0 = 8;
	for (i = 0; i < 8; i++)
		dc0 += out[i - 32] + out[-1 + i * 32];

	swebp__put8x8uv(dc0 >> 4, out);
}

/* TM */
static void swebp__predchroma8_1(simplewebp_u8 *out)
{
	swebp__truemotion(out, 8);
}

/* Vertical */
static void swebp__predchroma8_2(simplewebp_u8 *out)
{
	simplewebp_i32 j;
	for (j = 0; j < 8; j++)
		memcpy(out + j * 32, out - 32, 8);
}

/* Horizontal */
static void swebp__predchroma8_3(simplewebp_u8 *out)
{
	simplewebp_i32 j;
	for (j = 0; j < 8; j++)
		memset(out + j * 32, out[j * 32 - 1], 8);
}

/* DC w/o Top */
static void swebp__predchroma8_4(simplewebp_u8 *out)
{
	simplewebp_i32 dc0, i;

	dc0 = 4;
	for (i = 0; i < 8; i++)
		dc0 += out[-1 + i * 32];

	swebp__put8x8uv(dc0 >> 3, out);
}

/* DC w/o Left */
static void swebp__predchroma8_5(simplewebp_u8 *out)
{
	simplewebp_i32 dc0, i;

	dc0 = 4;
	for (i = 0; i < 8; i++)
		dc0 += out[i - 32];

	swebp__put8x8uv(dc0 >> 3, out);
}

/* DC w/o Top Left */
static void swebp__predchroma8_6(simplewebp_u8 *out)
{
	swebp__put8x8uv(128, out);
}

static void swebp__predchroma8(simplewebp_u8 num, simplewebp_u8 *out)
{
	switch (num)
	{
		case 0:
			swebp__predchroma8_0(out);
			break;
		case 1:
			swebp__predchroma8_1(out);
			break;
		case 2:
			swebp__predchroma8_2(out);
			break;
		case 3:
			swebp__predchroma8_3(out);
			break;
		case 4:
			swebp__predchroma8_4(out);
			break;
		case 5:
			swebp__predchroma8_5(out);
			break;
		case 6:
			swebp__predchroma8_6(out);
			break;
		default:
			break;
	}
}

#ifndef WEBP_HOST_TEST
#pragma code_seg()
#endif

/* RFC 6386 section 11.5 */
static const simplewebp_u8 swebp__modes_proba[10][10][9] = {
	{ { 231, 120, 48, 89, 115, 113, 120, 152, 112 },
		{ 152, 179, 64, 126, 170, 118, 46, 70, 95 },
		{ 175, 69, 143, 80, 85, 82, 72, 155, 103 },
		{ 56, 58, 10, 171, 218, 189, 17, 13, 152 },
		{ 114, 26, 17, 163, 44, 195, 21, 10, 173 },
		{ 121, 24, 80, 195, 26, 62, 44, 64, 85 },
		{ 144, 71, 10, 38, 171, 213, 144, 34, 26 },
		{ 170, 46, 55, 19, 136, 160, 33, 206, 71 },
		{ 63, 20, 8, 114, 114, 208, 12, 9, 226 },
		{ 81, 40, 11, 96, 182, 84, 29, 16, 36 } },
	{ { 134, 183, 89, 137, 98, 101, 106, 165, 148 },
		{ 72, 187, 100, 130, 157, 111, 32, 75, 80 },
		{ 66, 102, 167, 99, 74, 62, 40, 234, 128 },
		{ 41, 53, 9, 178, 241, 141, 26, 8, 107 },
		{ 74, 43, 26, 146, 73, 166, 49, 23, 157 },
		{ 65, 38, 105, 160, 51, 52, 31, 115, 128 },
		{ 104, 79, 12, 27, 217, 255, 87, 17, 7 },
		{ 87, 68, 71, 44, 114, 51, 15, 186, 23 },
		{ 47, 41, 14, 110, 182, 183, 21, 17, 194 },
		{ 66, 45, 25, 102, 197, 189, 23, 18, 22 } },
	{ { 88, 88, 147, 150, 42, 46, 45, 196, 205 },
		{ 43, 97, 183, 117, 85, 38, 35, 179, 61 },
		{ 39, 53, 200, 87, 26, 21, 43, 232, 171 },
		{ 56, 34, 51, 104, 114, 102, 29, 93, 77 },
		{ 39, 28, 85, 171, 58, 165, 90, 98, 64 },
		{ 34, 22, 116, 206, 23, 34, 43, 166, 73 },
		{ 107, 54, 32, 26, 51, 1, 81, 43, 31 },
		{ 68, 25, 106, 22, 64, 171, 36, 225, 114 },
		{ 34, 19, 21, 102, 132, 188, 16, 76, 124 },
		{ 62, 18, 78, 95, 85, 57, 50, 48, 51 } },
	{ { 193, 101, 35, 159, 215, 111, 89, 46, 111 },
		{ 60, 148, 31, 172, 219, 228, 21, 18, 111 },
		{ 112, 113, 77, 85, 179, 255, 38, 120, 114 },
		{ 40, 42, 1, 196, 245, 209, 10, 25, 109 },
		{ 88, 43, 29, 140, 166, 213, 37, 43, 154 },
		{ 61, 63, 30, 155, 67, 45, 68, 1, 209 },
		{ 100, 80, 8, 43, 154, 1, 51, 26, 71 },
		{ 142, 78, 78, 16, 255, 128, 34, 197, 171 },
		{ 41, 40, 5, 102, 211, 183, 4, 1, 221 },
		{ 51, 50, 17, 168, 209, 192, 23, 25, 82 } },
	{ { 138, 31, 36, 171, 27, 166, 38, 44, 229 },
		{ 67, 87, 58, 169, 82, 115, 26, 59, 179 },
		{ 63, 59, 90, 180, 59, 166, 93, 73, 154 },
		{ 40, 40, 21, 116, 143, 209, 34, 39, 175 },
		{ 47, 15, 16, 183, 34, 223, 49, 45, 183 },
		{ 46, 17, 33, 183, 6, 98, 15, 32, 183 },
		{ 57, 46, 22, 24, 128, 1, 54, 17, 37 },
		{ 65, 32, 73, 115, 28, 128, 23, 128, 205 },
		{ 40, 3, 9, 115, 51, 192, 18, 6, 223 },
		{ 87, 37, 9, 115, 59, 77, 64, 21, 47 } },
	{ { 104, 55, 44, 218, 9, 54, 53, 130, 226 },
		{ 64, 90, 70, 205, 40, 41, 23, 26, 57 },
		{ 54, 57, 112, 184, 5, 41, 38, 166, 213 },
		{ 30, 34, 26, 133, 152, 116, 10, 32, 134 },
		{ 39, 19, 53, 221, 26, 114, 32, 73, 255 },
		{ 31, 9, 65, 234, 2, 15, 1, 118, 73 },
		{ 75, 32, 12, 51, 192, 255, 160, 43, 51 },
		{ 88, 31, 35, 67, 102, 85, 55, 186, 85 },
		{ 56, 21, 23, 111, 59, 205, 45, 37, 192 },
		{ 55, 38, 70, 124, 73, 102, 1, 34, 98 } },
	{ { 125, 98, 42, 88, 104, 85, 117, 175, 82 },
		{ 95, 84, 53, 89, 128, 100, 113, 101, 45 },
		{ 75, 79, 123, 47, 51, 128, 81, 171, 1 },
		{ 57, 17, 5, 71, 102, 57, 53, 41, 49 },
		{ 38, 33, 13, 121, 57, 73, 26, 1, 85 },
		{ 41, 10, 67, 138, 77, 110, 90, 47, 114 },
		{ 115, 21, 2, 10, 102, 255, 166, 23, 6 },
		{ 101, 29, 16, 10, 85, 128, 101, 196, 26 },
		{ 57, 18, 10, 102, 102, 213, 34, 20, 43 },
		{ 117, 20, 15, 36, 163, 128, 68, 1, 26 } },
	{ { 102, 61, 71, 37, 34, 53, 31, 243, 192 },
		{ 69, 60, 71, 38, 73, 119, 28, 222, 37 },
		{ 68, 45, 128, 34, 1, 47, 11, 245, 171 },
		{ 62, 17, 19, 70, 146, 85, 55, 62, 70 },
		{ 37, 43, 37, 154, 100, 163, 85, 160, 1 },
		{ 63, 9, 92, 136, 28, 64, 32, 201, 85 },
		{ 75, 15, 9, 9, 64, 255, 184, 119, 16 },
		{ 86, 6, 28, 5, 64, 255, 25, 248, 1 },
		{ 56, 8, 17, 132, 137, 255, 55, 116, 128 },
		{ 58, 15, 20, 82, 135, 57, 26, 121, 40 } },
	{ { 164, 50, 31, 137, 154, 133, 25, 35, 218 },
		{ 51, 103, 44, 131, 131, 123, 31, 6, 158 },
		{ 86, 40, 64, 135, 148, 224, 45, 183, 128 },
		{ 22, 26, 17, 131, 240, 154, 14, 1, 209 },
		{ 45, 16, 21, 91, 64, 222, 7, 1, 197 },
		{ 56, 21, 39, 155, 60, 138, 23, 102, 213 },
		{ 83, 12, 13, 54, 192, 255, 68, 47, 28 },
		{ 85, 26, 85, 85, 128, 128, 32, 146, 171 },
		{ 18, 11, 7, 63, 144, 171, 4, 4, 246 },
		{ 35, 27, 10, 146, 174, 171, 12, 26, 128 } },
	{ { 190, 80, 35, 99, 180, 80, 126, 54, 45 },
		{ 85, 126, 47, 87, 176, 51, 41, 20, 32 },
		{ 101, 75, 128, 139, 118, 146, 116, 128, 85 },
		{ 56, 41, 15, 176, 236, 85, 37, 9, 62 },
		{ 71, 30, 17, 119, 118, 255, 17, 18, 138 },
		{ 101, 38, 60, 138, 55, 70, 43, 26, 142 },
		{ 146, 36, 19, 30, 171, 255, 97, 27, 20 },
		{ 138, 45, 61, 62, 219, 1, 81, 188, 64 },
		{ 32, 41, 20, 117, 151, 142, 20, 21, 163 },
		{ 112, 19, 12, 61, 195, 128, 48, 4, 24 } }
};

static const simplewebp_u8 swebp__bands[17] = {
	0, 1, 2, 3, 6, 4, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 0
};

#ifndef WEBP_HOST_TEST
#pragma code_seg("WebPHeaderCode")
#endif

static simplewebp_error swebp__load_vp8_header(
	WebPDecoder *decoderP,
	struct swebp__vp8 *vp8d)
{
	struct swebp__segment_header *segmnt_hdr;
	struct swebp__filter_header *filt_hdr;
	struct swebp__bdec br;
	dword tokenStart;
	dword tokenBytes;

	/* Populate picture headers */
	vp8d->mb_w = (vp8d->picture_header.width + 15) >> 4;
	vp8d->mb_h = (vp8d->picture_header.height + 15) >> 4;

	/* Reset proba */
	memset(vp8d->proba.segments, 255, sizeof(vp8d->proba.segments));
	/* Reset segment header */
	vp8d->segment_header.use_segment = 0;
	vp8d->segment_header.update_map = 0;
	vp8d->segment_header.absolute_delta = 1;
	memset(&vp8d->segment_header.quantizer, 0, sizeof(vp8d->segment_header.quantizer));
	memset(&vp8d->segment_header.filter_strength, 0, sizeof(vp8d->segment_header.filter_strength));

	/* Initialize bitreader */
	swebp__bitread_init(&br, decoderP, decoderP->vp8Start + 10,
		vp8d->frame_header.partition_length, FALSE);
	tokenStart = decoderP->vp8Start + 10 +
		vp8d->frame_header.partition_length;
	tokenBytes = decoderP->vp8Length - 10 -
		vp8d->frame_header.partition_length;

	/* Read more picture headers. This is a keyframe */
	vp8d->picture_header.colorspace = swebp__bitread_getval(&br, 1);
	vp8d->picture_header.clamp_type = swebp__bitread_getval(&br, 1);
	if (vp8d->picture_header.colorspace != 0)
		return SIMPLEWEBP_CORRUPT_ERROR;

	/* Parse segment header */
	segmnt_hdr = &vp8d->segment_header;
	segmnt_hdr->use_segment = swebp__bitread_getval(&br, 1);
	if (segmnt_hdr->use_segment)
	{
		simplewebp_i32 s;
		segmnt_hdr->update_map = swebp__bitread_getval(&br, 1);

		if (swebp__bitread_getval(&br, 1) /* update data */)
		{
			segmnt_hdr->absolute_delta = swebp__bitread_getval(&br, 1);
			for (s = 0; s < 4; s++)
				segmnt_hdr->quantizer[s] = swebp__bitread_getval(&br, 1)
					? swebp__bitread_getvalsigned(&br, 7)
					: 0;
			for (s = 0; s < 4; s++)
				segmnt_hdr->filter_strength[s] = swebp__bitread_getval(&br, 1)
					? swebp__bitread_getvalsigned(&br, 6)
					: 0;

		}

		if (segmnt_hdr->update_map)
		{
			for (s = 0; s < 3; s++)
				vp8d->proba.segments[s] = swebp__bitread_getval(&br, 1)
					? swebp__bitread_getval(&br, 8)
					: 255;
		}
	}
	else
		segmnt_hdr->update_map = 0;

	if (br.reader.eof)
		return br.reader.ioError ?
			SIMPLEWEBP_IO_ERROR : SIMPLEWEBP_CORRUPT_ERROR;

	/* Parse filters */
	filt_hdr = &vp8d->filter_header;
	filt_hdr->simple = swebp__bitread_getval(&br, 1);
	filt_hdr->level = swebp__bitread_getval(&br, 6);
	filt_hdr->sharpness = swebp__bitread_getval(&br, 3);
	filt_hdr->use_lf_delta = swebp__bitread_getval(&br, 1);

	if (filt_hdr->use_lf_delta)
	{
		if (swebp__bitread_getval(&br, 1) /* update lf-delta? */)
		{
			simplewebp_i32 i;

			for (i = 0; i < 4; i++)
			{
				if (swebp__bitread_getval(&br, 1))
					filt_hdr->ref_lf_delta[i] = swebp__bitread_getvalsigned(&br, 6);
			}

			for (i = 0; i < 4; i++)
			{
				if (swebp__bitread_getval(&br, 1))
					filt_hdr->mode_lf_delta[i] = swebp__bitread_getvalsigned(&br, 6);
			}
		}
	}

	vp8d->filter_type = filt_hdr->level == 0 ? 0 : (filt_hdr->simple ? 1 : 2);

	if (br.reader.eof)
		return br.reader.ioError ?
			SIMPLEWEBP_IO_ERROR : SIMPLEWEBP_CORRUPT_ERROR;

	/* Parse partitions */
	{
		simplewebp_u8 sz[3];
		dword size_left, part_start, psize;
		word last_part, p;

		last_part = vp8d->nparts_minus_1 = (1 << swebp__bitread_getval(&br, 2)) - 1;
		if ((dword)3 * last_part > tokenBytes)
			return SIMPLEWEBP_CORRUPT_ERROR;

		part_start = tokenStart + (dword)last_part * 3;
		size_left = tokenBytes - (dword)last_part * 3;

		for (p = 0; p < last_part; p++)
		{
			if (FilePos(decoderP->source, tokenStart + (dword)p * 3,
				    FILE_POS_START) != tokenStart + (dword)p * 3 ||
			    FileRead(decoderP->source, sz, 3, FALSE) != 3)
				return SIMPLEWEBP_IO_ERROR;
			psize = (dword)sz[0] | ((dword)sz[1] << 8) |
				((dword)sz[2] << 16);
			if (psize > size_left)
				return SIMPLEWEBP_CORRUPT_ERROR;

			swebp__bitread_init(vp8d->parts + p, decoderP,
				part_start, psize, TRUE);
			part_start += psize;
			size_left -= psize;
		}

		if (size_left == 0)
			return SIMPLEWEBP_CORRUPT_ERROR;
		swebp__bitread_init(vp8d->parts + last_part, decoderP,
			part_start, size_left, TRUE);
	}

	/* Parse quantizer */
	{
		simplewebp_i32 base_q0, dqy1_dc, dqy2_dc, dqy2_ac, dquv_dc, dquv_ac, i;
		base_q0 = swebp__bitread_getval(&br, 7);
		dqy1_dc = swebp__bitread_getval(&br, 1)
			? swebp__bitread_getvalsigned(&br, 4)
			: 0;
		dqy2_dc = swebp__bitread_getval(&br, 1)
			? swebp__bitread_getvalsigned(&br, 4)
			: 0;
		dqy2_ac = swebp__bitread_getval(&br, 1)
			? swebp__bitread_getvalsigned(&br, 4)
			: 0;
		dquv_dc = swebp__bitread_getval(&br, 1)
			? swebp__bitread_getvalsigned(&br, 4)
			: 0;
		dquv_ac = swebp__bitread_getval(&br, 1)
			? swebp__bitread_getvalsigned(&br, 4)
			: 0;

		for (i = 0; i < 4; i++)
		{
			simplewebp_i32 q;
			struct swebp__quantmat *m;

			if (segmnt_hdr->use_segment)
				q = segmnt_hdr->quantizer[i] + (!segmnt_hdr->absolute_delta) * base_q0;
			else
			{
				if (i > 0)
				{
					vp8d->dqm[i] = vp8d->dqm[0];
					continue;
				}
				else
					q = base_q0;
			}

			m = vp8d->dqm + i;
			m->y1_mat[0] = swebp__dctab[swebp__clip(q + dqy1_dc, 127)];
			m->y1_mat[1] = swebp__actab[swebp__clip(q + 0,       127)];

			m->y2_mat[0] = swebp__dctab[swebp__clip(q + dqy2_dc, 127)] * 2;
			m->y2_mat[1] = (swebp__actab[swebp__clip(q + dqy2_ac, 127)] * 101581) >> 16;
			if (m->y2_mat[1] < 8)
				m->y2_mat[1] = 8;

			m->uv_mat[0] = swebp__dctab[swebp__clip(q + dquv_dc, 117)];
			m->uv_mat[1] = swebp__actab[swebp__clip(q + dquv_ac, 127)];

			m->uv_quant = q + dquv_ac;
		}
	}

	/* Ignore "update proba" */
	swebp__bitread_getval(&br, 1);

	/* Parse proba */
	{
		struct swebp__proba *proba;
		simplewebp_i32 t, b, c, p, v;

		proba = &vp8d->proba;

		for (t = 0; t < 4; t++)
		{
			for (b = 0; b < 8; b++)
			{
				for (c = 0; c < 3; c++)
				{
					for (p = 0; p < 11; p++)
					{
						v = swebp__bitread_getbit(&br, swebp__coeff_update_proba[t][b][c][p])
							? swebp__bitread_getval(&br, 8)
							: swebp__coeff_proba0[t][b][c][p];
						proba->bands[t][b].probas[c][p] = v;
					}
				}
			}

			for (b = 0; b < 17; b++)
				proba->bands_ptr[t][b] = &proba->bands[t][swebp__bands[b]];
		}

		vp8d->use_skip_proba = swebp__bitread_getval(&br, 1);
		if (vp8d->use_skip_proba)
			vp8d->skip_proba = swebp__bitread_getval(&br, 8);
	}

	if (br.reader.eof)
		return br.reader.ioError ?
			SIMPLEWEBP_IO_ERROR : SIMPLEWEBP_CORRUPT_ERROR;

	vp8d->br = br;
	vp8d->ready = 1;
	return SIMPLEWEBP_NO_ERROR;
}

static void swebp__vp8_enter_critical(struct swebp__vp8 *vp8d)
{
	vp8d->tl_mb_x = vp8d->tl_mb_y = 0;
	vp8d->br_mb_x = vp8d->mb_w;
	vp8d->br_mb_y = vp8d->mb_h;

	if (vp8d->filter_type > 0)
	{
		simplewebp_i32 s;
		struct swebp__filter_header *filt_hdr;

		filt_hdr = &vp8d->filter_header;

		for (s = 0; s < 4; s++)
		{
			simplewebp_i32 i4x4, base_level;

			if (vp8d->segment_header.use_segment)
				base_level = vp8d->segment_header.filter_strength[s]
					+ filt_hdr->level * (!vp8d->segment_header.absolute_delta);
			else
				base_level = filt_hdr->level;

			for (i4x4 = 0; i4x4 <= 1; i4x4++)
			{
				struct swebp__finfo *info;
				simplewebp_i32 level;

				info = &vp8d->fstrengths[s][i4x4];
				level = base_level
					+ filt_hdr->ref_lf_delta[0] * filt_hdr->use_lf_delta
					+ filt_hdr->mode_lf_delta[0] * i4x4 * filt_hdr->use_lf_delta;

				level = (level < 0) ? 0 : ((level > 63) ? 63 : level);
				if (level > 0)
				{
					simplewebp_i32 ilevel = level;

					if (filt_hdr->sharpness > 0)
					{
						ilevel >>= 1 + (filt_hdr->sharpness > 4);

						if (ilevel > 9 - filt_hdr->sharpness)
							ilevel = 9 - filt_hdr->sharpness;
					}

					if (ilevel < 1)
						ilevel = 1;

					info->ilevel = ilevel;
					info->limit = 2 * level + ilevel;
					info->hev_thresh = (level >= 40) + (level >= 15);
				}
				else
					info->limit = 0;

				info->inner = i4x4;
			}
		}
	}
}

#ifndef WEBP_HOST_TEST
#pragma code_seg()
#endif

static void swebp__vp8_parse_intra_mode(struct swebp__vp8 *vp8d, simplewebp_i32 mb_x)
{
	simplewebp_u8 *top, *left;
	struct swebp__mblockdata *block;
	struct swebp__bdec *br;

	top = vp8d->intra_t + 4 * mb_x;
	left = vp8d->intra_l;
	block = vp8d->mb_data;
	br = &vp8d->br;

	if (vp8d->segment_header.update_map)
		block->segment = !swebp__bitread_getbit(br, vp8d->proba.segments[0])
			? swebp__bitread_getbit(br, vp8d->proba.segments[1])
			: swebp__bitread_getbit(br, vp8d->proba.segments[2]) + 2;
	else
		block->segment = 0;

	if (vp8d->use_skip_proba)
		block->skip = swebp__bitread_getbit(br, vp8d->skip_proba);

	block->is_i4x4 = !swebp__bitread_getbit(br, 145);
	if (!block->is_i4x4)
	{
		simplewebp_i32 ymode = swebp__bitread_getbit(br, 156)
			? (swebp__bitread_getbit(br, 128) ? 1 : 3)
			: (swebp__bitread_getbit(br, 163) ? 2 : 0);

		block->imodes[0] = ymode;
		memset(top, ymode, 4);
		memset(left, ymode, 4);
	}
	else
	{
		simplewebp_u8 *modes;
		simplewebp_i32 y;

		modes = block->imodes;
		for (y = 0; y < 4; y++)
		{
			simplewebp_i32 ymode, x;

			ymode = left[y];
			for (x = 0; x < 4; x++)
			{
				const simplewebp_u8 *const prob = swebp__modes_proba[top[x]][ymode];
				ymode = !swebp__bitread_getbit(br, prob[0]) ? 0 :
					!swebp__bitread_getbit(br, prob[1]) ? 1 :
						!swebp__bitread_getbit(br, prob[2]) ? 2 :
							!swebp__bitread_getbit(br, prob[3]) ?
								(!swebp__bitread_getbit(br, prob[4]) ? 3 :
									(!swebp__bitread_getbit(br, prob[5]) ? 4
																				: 5)) :
								(!swebp__bitread_getbit(br, prob[6]) ? 6 :
									(!swebp__bitread_getbit(br, prob[7]) ? 7 :
										(!swebp__bitread_getbit(br, prob[8]) ? 8
																					: 9))
								);
				top[x] = ymode;
			}

			memcpy(modes, top, 4);
			modes += 4;
			left[y] = ymode;
		}
	}

	block->uvmode = !swebp__bitread_getbit(br, 142) ? 0 : (
		!swebp__bitread_getbit(br, 114) ? 2 : (
			swebp__bitread_getbit(br, 183) ? 1 : 3
		));
}


static void swebp__vp8_init_scanline(struct swebp__vp8 *vp8d)
{
	struct swebp__mblock *const left = vp8d->mb_info - 1;
	left->nz = 0;
	left->nz_dc = 0;
	memset(vp8d->intra_l, 0, sizeof(vp8d->intra_l));
	vp8d->mb_x = 0;
}

static const simplewebp_u8 swebp__cat3[] = { 173, 148, 140, 0 };
static const simplewebp_u8 swebp__cat4[] = { 176, 155, 140, 135, 0 };
static const simplewebp_u8 swebp__cat5[] = { 180, 157, 141, 134, 130, 0 };
static const simplewebp_u8 swebp__cat6[] = { 254, 254, 243, 230, 196, 177, 153, 140, 133, 130, 129, 0 };
static const simplewebp_u8* const swebp__cat3456[] = {
	swebp__cat3,
	swebp__cat4,
	swebp__cat5,
	swebp__cat6
};
static const simplewebp_u8 swebp__zigzag[16] = {
	0, 1, 4, 8,
	5, 2, 3, 6,
	9, 12, 13, 10,
	7, 11, 14, 15
};

static simplewebp_i32 swebp__get_large_value(struct swebp__bdec *br, const simplewebp_u8 *p)
{
	simplewebp_i32 v;

	if (!swebp__bitread_getbit(br, p[3]))
	{
		if (!swebp__bitread_getbit(br, p[4]))
			v = 2;
		else
			v = 3 + swebp__bitread_getbit(br, p[5]);
	}
	else
	{
		if (!swebp__bitread_getbit(br, p[6]))
		{
			if (!swebp__bitread_getbit(br, p[7]))
				v = 5 + swebp__bitread_getbit(br, 159);
			else
			{
				v = 7 + 2 * swebp__bitread_getbit(br, 165);
				v += swebp__bitread_getbit(br, 145);
			}
		}
		else
		{
			const simplewebp_u8 *tab;
			simplewebp_i32 bit1, bit0, cat;

			bit1 = swebp__bitread_getbit(br, p[8]);
			bit0 = swebp__bitread_getbit(br, p[9 + bit1]);
			cat = 2 * bit1 + bit0;
			v = 0;

			for (tab = swebp__cat3456[cat]; *tab; ++tab)
				v += v + swebp__bitread_getbit(br, *tab);

			v += 3 + (8 << cat);
		}
	}

	return v;
}

static simplewebp_i32 swebp__get_coeffs(
	struct swebp__bdec *br,
	const struct swebp__bandprobas *prob[],
	simplewebp_i32 ctx,
	const swebp__quant_t dq,
	simplewebp_i32 n,
	simplewebp_i16 *out
)
{
	const simplewebp_u8 *p = prob[n]->probas[ctx];

	for (; n < 16; n++)
	{
		if (!swebp__bitread_getbit(br, p[0]))
			return n;

		while (!swebp__bitread_getbit(br, p[1]))
		{
			p = prob[++n]->probas[0];
			if (n == 16)
				return 1;
		}

		{
			const swebp__probarray *p_ctx;
			simplewebp_i32 v;

			p_ctx = &prob[n + 1]->probas[0];

			if (!swebp__bitread_getbit(br, p[2]))
			{
				v = 1;
				p = p_ctx[1];
			}
			else
			{
				v = swebp__get_large_value(br, p);
				p = p_ctx[2];
			}

			out[swebp__zigzag[n]] = swebp__bitread_getsigned(br, v) * dq[n > 0];
		}
	}

	return 16;
}

static simplewebp_u32 swebp__nz_code_bits(simplewebp_u32 nz_coeffs, simplewebp_i32 nz, simplewebp_i8 dc_nz)
{
	nz_coeffs <<= 2;
	nz_coeffs |= (nz > 3) ? 3 : (nz > 1) ? 2 : dc_nz;
	return nz_coeffs;
}

static simplewebp_i32 swebp__vp8_decode_macroblock(struct swebp__vp8 *vp8d, struct swebp__bdec *token_br)
{
	struct swebp__mblock *left, *mb;
	struct swebp__mblockdata *block;
	simplewebp_u8 skip;

	left = vp8d->mb_info - 1;
	mb = vp8d->mb_info + vp8d->mb_x;
	block = vp8d->mb_data;
	skip = vp8d->use_skip_proba ? block->skip : 0;

	if (!skip)
	{
		/* Parse residuals */
		const struct swebp__bandprobas * (*bands)[17], **ac_proba;
		struct swebp__quantmat *q;
		simplewebp_i16 *dst;
		struct swebp__mblock *left_mb;
		simplewebp_u8 tnz, lnz;
		simplewebp_u32 non0_y, non0_uv, out_t_nz, out_l_nz;
		simplewebp_i32 x, y, ch, first;

		bands = vp8d->proba.bands_ptr;
		q = &vp8d->dqm[block->segment];
		dst = block->coeffs;
		left_mb = vp8d->mb_info - 1;
		non0_y = non0_uv = 0;

		memset(dst, 0, 384 * sizeof(simplewebp_i16));
		if (!block->is_i4x4)
		{
			simplewebp_i16 dc[16];
			simplewebp_i32 ctx, nz;

			memset(dc, 0, sizeof(dc));
			ctx = mb->nz_dc + left_mb->nz_dc;
			nz = swebp__get_coeffs(token_br, bands[1], ctx, q->y2_mat, 0, dc);

			mb->nz_dc = left_mb->nz_dc = nz > 0;
			if (nz > 1)
				swebp__transform_wht(dc, dst);
			else
			{
				simplewebp_i32 i, dc0;
				dc0 = ((simplewebp_i32)dc[0] + 3) >> 3;
				for (i = 0; i < 16; i++)
					dst[i * 16] = dc0;
			}

			first = 1;
			ac_proba = bands[0];
		}
		else
		{
			first = 0;
			ac_proba = bands[3];
		}

		tnz = mb->nz & 0xf;
		lnz = left_mb->nz & 0xf;

		for (y = 0; y < 4; y++)
		{
			simplewebp_i32 l;
			simplewebp_u32 nz_coeffs;

			l = lnz & 1;
			nz_coeffs = 0;

			for (x = 0; x < 4; x++)
			{
				simplewebp_i32 ctx, nz;

				ctx = l + (tnz & 1);
				nz = swebp__get_coeffs(token_br, ac_proba, ctx, q->y1_mat, first, dst);
				l = nz > first;
				tnz = (tnz >> 1) | (l << 7);
				nz_coeffs = swebp__nz_code_bits(nz_coeffs, nz, dst[0] != 0);
				dst += 16;
			}

			tnz >>= 4;
			lnz = (lnz >> 1) | (l << 7);
			non0_y = (non0_y << 8) | nz_coeffs;
		}

		out_t_nz = tnz;
		out_l_nz = lnz >> 4;

		for (ch = 0; ch < 4; ch += 2)
		{
			simplewebp_u32 nz_coeffs = 0;

			tnz = mb->nz >> (4 + ch);
			lnz = left_mb->nz >> (4 + ch);

			for (y = 0; y < 2; y++)
			{
				simplewebp_i32 l = lnz & 1;

				for (x = 0; x < 2; x++)
				{
					simplewebp_i32 ctx, nz;

					ctx = l + (tnz & 1);
					nz = swebp__get_coeffs(token_br, bands[2], ctx, q->uv_mat, 0, dst);
					l = nz > 0;
					tnz = (tnz >> 1) | (l << 3);
					nz_coeffs = swebp__nz_code_bits(nz_coeffs, nz, dst[0] != 0);
					dst += 16;
				}

				tnz >>= 2;
				lnz = (lnz >> 1) | (l << 5);
			}

			non0_uv |= nz_coeffs << (4 * ch);
			out_t_nz |= tnz << (4 + ch);
			out_l_nz |= (lnz & 0xf0) << ch;
		}

		mb->nz = out_t_nz;
		left_mb->nz = out_l_nz;

		block->nonzero_y = non0_y;
		block->nonzero_uv = non0_uv;
		block->dither = (non0_uv & 0xaaaa) ? 0 : q->dither;

		skip = !(non0_y | non0_uv);
	}
	else
	{
		left->nz = mb->nz = 0;
		if (!block->is_i4x4)
			left->nz_dc = mb->nz_dc = 0;

		block->nonzero_y = block->nonzero_uv = block->dither = 0;
	}

	if (vp8d->filter_type > 0)
	{
		struct swebp__finfo *const finfo = vp8d->f_info + vp8d->mb_x;
		*finfo = vp8d->fstrengths[block->segment][block->is_i4x4];
		finfo->inner |= !skip;
	}

	return !token_br->reader.eof;
}

#ifndef WEBP_HOST_TEST
#pragma code_seg("WebPRowCode")
#endif

static void swebp__do_transform(simplewebp_u32 bits, const simplewebp_i16 *src, simplewebp_u8 *dst)
{
	switch (bits >> 30)
	{
		case 3:
			swebp__transform(src, dst, 0);
			break;
		case 2:
			swebp__transform_ac3(src, dst);
			break;
		case 1:
			swebp__transform_dc(src, dst);
			break;
		default:
			break;
	}
}

static simplewebp_i32 swebp__check_mode(simplewebp_i32 mb_x, simplewebp_i32 mb_y, simplewebp_i32 mode)
{
	if (mode == 0) {
		if (mb_x == 0)
			return (mb_y == 0) ? 6 : 5;
		else
			return (mb_y == 0) ? 4 : 0;
	}

	return mode;
}

static void swebp__do_transform_uv(simplewebp_u32 bits, const simplewebp_i16 *src, simplewebp_u8 *dst)
{
	if (bits & 0xff)
	{
		if (bits & 0xaa)
			swebp__transform_uv(src, dst);
		else
			swebp__transform_dcuv(src, dst);
	}
}

static void swebp__yuv2rgb_plain(simplewebp_u8 y, simplewebp_u8 u, simplewebp_u8 v, struct swebp__pixel *rgb)
{
	WebPYUVToRGB(y, u, v, (byte *)rgb);
}

/* r = top-left, g = top-right, b = bottom-left, a = bottom-right */

/* This is bilinear interpolation with center chroma. */
/* See https://stackoverflow.com/a/43784809 */


static void swebp__vp8_bind_cache_buffers(
	struct swebp__vp8 *vp8d,
	simplewebp_u8 *lumaP,
	simplewebp_u8 *chromaP);

static void swebp__vp8_bind_buffers(
	struct swebp__vp8 *vp8d,
	WebPDecoder *decoderP,
	simplewebp_u8 *contextP,
	simplewebp_u8 *lumaP,
	simplewebp_u8 *chromaP)
{
	simplewebp_u8 *workP;

	workP = contextP;
	vp8d->intra_t = workP;
	workP += 4 * vp8d->mb_w;
	vp8d->yuv_t = (struct swebp__topsmp *)workP;
	workP += sizeof(struct swebp__topsmp) * vp8d->mb_w;
	vp8d->mb_info = ((struct swebp__mblock *)workP) + 1;
	workP += sizeof(struct swebp__mblock) * (vp8d->mb_w + 1);
	if (vp8d->filter_type > 0) {
		vp8d->f_info = (struct swebp__finfo *)workP;
		workP += sizeof(struct swebp__finfo) * vp8d->mb_w;
	} else {
		vp8d->f_info = (void *)0;
	}
	vp8d->yuv_b = workP;

	swebp__vp8_bind_cache_buffers(vp8d, lumaP, chromaP);
	(void)decoderP;
}

static void swebp__vp8_bind_cache_buffers(
	struct swebp__vp8 *vp8d,
	simplewebp_u8 *lumaP,
	simplewebp_u8 *chromaP)
{
	simplewebp_i32 extraRows;
	simplewebp_i32 uvPlaneRows;

	vp8d->cache_y_stride = 16 * vp8d->mb_w;
	vp8d->cache_uv_stride = 8 * vp8d->mb_w;
	extraRows = swebp__fextrarows[vp8d->filter_type];
	vp8d->cache_y = lumaP + extraRows * vp8d->cache_y_stride;
	uvPlaneRows = 8 + extraRows / 2;
	vp8d->cache_u = chromaP +
		(extraRows / 2) * vp8d->cache_uv_stride;
	vp8d->cache_v = chromaP +
		uvPlaneRows * vp8d->cache_uv_stride +
		(extraRows / 2) * vp8d->cache_uv_stride;
}

static simplewebp_error swebp__vp8_output_rows(
	struct swebp__vp8 *vp8d,
	struct swebp__yuvdst *destination)
{
	WebPDecoder *decoderP;
	simplewebp_u8 *contextP;
	simplewebp_u8 *lumaP;
	simplewebp_u8 *chromaP;
	simplewebp_i32 extraRows;
	simplewebp_i32 yBase;
	simplewebp_i32 uvBase;
	simplewebp_i32 end;
	simplewebp_i32 line;
	simplewebp_i32 uvHeight;
	simplewebp_i32 uvWidth;
	simplewebp_error error;

	decoderP = destination->decoderP;
	extraRows = swebp__fextrarows[vp8d->filter_type];
	yBase = vp8d->mb_y == 0 ? 0 : vp8d->mb_y * 16 - extraRows;
	uvBase = vp8d->mb_y == 0 ? 0 :
		vp8d->mb_y * 8 - extraRows / 2;
	if (vp8d->mb_y == vp8d->mb_h - 1)
		end = vp8d->picture_header.height;
	else
		end = (vp8d->mb_y + 1) * 16 - extraRows + 1;
	if (end > vp8d->picture_header.height)
		end = vp8d->picture_header.height;
	uvWidth = (vp8d->picture_header.width + 1) / 2;
	uvHeight = (vp8d->picture_header.height + 1) / 2;
	destination->firstLine = decoderP->nextOutputLine;
	destination->lineCount = 0;
	error = SIMPLEWEBP_NO_ERROR;
	lumaP = vp8d->cache_y - extraRows * vp8d->cache_y_stride;
	chromaP = vp8d->cache_u -
		(extraRows / 2) * vp8d->cache_uv_stride;
	MemUnlock(decoderP->contextH);
	destination->rgbP = MemLock(decoderP->rgbH);
	destination->rgbP += WEBP_PACKBITS_GAP(decoderP->rowBytes);

	for (line = decoderP->nextOutputLine; line < end; line++) {
		simplewebp_u8 *yP;
		simplewebp_u8 *uP;
		simplewebp_u8 *vP;
		simplewebp_u8 *packedP;
		simplewebp_i32 chromaY;
		simplewebp_i32 otherY;
		simplewebp_i32 x;
		word packedSize;
		yP = (vp8d->cache_y - (vp8d->mb_y ?
			extraRows * vp8d->cache_y_stride : 0)) +
			(line - yBase) * vp8d->cache_y_stride;
		chromaY = line / 2;
		if (line & 1)
			otherY = chromaY + 1 < uvHeight ? chromaY + 1 : chromaY;
		else
			otherY = chromaY > 0 ? chromaY - 1 : chromaY;
		if (chromaY < uvBase || otherY < uvBase) {
			error = SIMPLEWEBP_CORRUPT_ERROR;
			break;
		}
		uP = vp8d->cache_u -
			(vp8d->mb_y ? (extraRows / 2) *
			 vp8d->cache_uv_stride : 0);
		vP = vp8d->cache_v -
			(vp8d->mb_y ? (extraRows / 2) *
			 vp8d->cache_uv_stride : 0);

		for (x = 0; x < vp8d->picture_header.width; x++) {
			simplewebp_i32 chromaX;
			simplewebp_i32 otherX;
			simplewebp_i32 u;
			simplewebp_i32 v;
			simplewebp_u8 *uMidP;
			simplewebp_u8 *uOtherP;
			simplewebp_u8 *vMidP;
			simplewebp_u8 *vOtherP;

			chromaX = x / 2;
			if (x & 1)
				otherX = chromaX + 1 < uvWidth ?
					chromaX + 1 : chromaX;
			else
				otherX = chromaX > 0 ? chromaX - 1 : chromaX;
			uMidP = uP + (chromaY - uvBase) *
				vp8d->cache_uv_stride;
			uOtherP = uP + (otherY - uvBase) *
				vp8d->cache_uv_stride;
			vMidP = vP + (chromaY - uvBase) *
				vp8d->cache_uv_stride;
			vOtherP = vP + (otherY - uvBase) *
				vp8d->cache_uv_stride;
			u = (9 * uMidP[chromaX] + 3 * uMidP[otherX] +
				3 * uOtherP[chromaX] + uOtherP[otherX] + 8) >> 4;
			v = (9 * vMidP[chromaX] + 3 * vMidP[otherX] +
				3 * vOtherP[chromaX] + vOtherP[otherX] + 8) >> 4;
			swebp__yuv2rgb_plain(yP[x], (byte)u, (byte)v,
				(struct swebp__pixel *)(destination->rgbP + x * 3));
		}

		MemUnlock(decoderP->lumaH);
		MemUnlock(decoderP->chromaH);
		packedP = destination->rgbP -
			WEBP_PACKBITS_GAP(decoderP->rowBytes);
		packedSize = WebPPackBits(packedP, destination->rgbP,
			decoderP->rowBytes);
		HugeArrayAppend(decoderP->destination, decoderP->bitmap,
			packedSize, packedP);
		lumaP = MemLock(decoderP->lumaH);
		chromaP = MemLock(decoderP->chromaH);
		swebp__vp8_bind_cache_buffers(vp8d, lumaP, chromaP);
		destination->lineCount++;
	}
	MemUnlock(decoderP->rgbH);
	contextP = MemLock(decoderP->contextH);
	swebp__vp8_bind_buffers(vp8d, decoderP,
		contextP, lumaP, chromaP);
	if (error == SIMPLEWEBP_NO_ERROR)
		decoderP->nextOutputLine = end;
	return error;
}

static simplewebp_error swebp__vp8_process_row(struct swebp__vp8 *vp8d, struct swebp__yuvdst *destination)
{
	simplewebp_i32 filter_row;

	filter_row = vp8d->filter_type > 0 && vp8d->mb_y >= vp8d->tl_mb_y && vp8d->mb_y <= vp8d->br_mb_y;

	/* Reconstruct row */
	{
		simplewebp_i32 j, mb_x, mb_y;
		simplewebp_u8 *y_dst, *u_dst, *v_dst;

		mb_y = vp8d->mb_y;
		y_dst = vp8d->yuv_b + 40;
		u_dst = vp8d->yuv_b + 584;
		v_dst = vp8d->yuv_b + 600;

		for (j = 0; j < 16; j++)
			y_dst[j * 32 - 1] = 129;
		for (j = 0; j < 8; j++)
		{
			u_dst[j * 32 - 1] = 129;
			v_dst[j * 32 - 1] = 129;
		}

		if (mb_y > 0)
			y_dst[-33] = u_dst[-33] = v_dst[-33] = 129;
		else
		{
			memset(y_dst - 33, 127, 21);
			memset(u_dst - 33, 127, 9);
			memset(v_dst - 33, 127, 9);
		}

		for (mb_x = vp8d->mb_x; mb_x <= vp8d->mb_x; mb_x++)
		{
			struct swebp__mblockdata *const block = vp8d->mb_data;

			if (mb_x > 0)
			{
				for (j = -1; j < 16; j++)
					memcpy(y_dst + j * 32 - 4, y_dst + j * 32 + 12, 4);
				for (j = -1; j < 8; j++)
				{
					memcpy(u_dst + j * 32 - 4, u_dst + j * 32 + 4, 4);
					memcpy(v_dst + j * 32 - 4, v_dst + j * 32 + 4, 4);
				}
			}

			{
				struct swebp__topsmp *top_yuv;
				const simplewebp_i16 *coeffs;
				simplewebp_u32 bits;
				simplewebp_i32 n;

				top_yuv = vp8d->yuv_t + mb_x;
				coeffs = block->coeffs;
				bits = block->nonzero_y;

				if (mb_y > 0)
				{
					memcpy(y_dst - 32, top_yuv[0].y, 16);
					memcpy(u_dst - 32, top_yuv[0].u, 8);
					memcpy(v_dst - 32, top_yuv[0].v, 8);
				}

				if (block->is_i4x4)
				{
					simplewebp_u32 *const top_right = (simplewebp_u32 *) (y_dst - 32 + 16);

					if (mb_y > 0)
					{
						if (mb_x >= vp8d->mb_w - 1)
							memset(top_right, top_yuv[0].y[15], 4);
						else
							memcpy(top_right, top_yuv[1].y, 4);
					}

					top_right[32] = top_right[64] = top_right[96] = top_right[0];

					for (n = 0; n < 16; n++, bits <<= 2)
					{
						/* kScan[n] = (n & 3) * 4 + (n >> 2) * 128 */
						simplewebp_u8 *const dst = y_dst + ((n & 3) * 4 + (n >> 2) * 128);
						swebp__predluma4(block->imodes[n], dst);
						swebp__do_transform(bits, coeffs + n * 16, dst);
					}
				}
				else
				{
					const simplewebp_i32 pred_func = swebp__check_mode(mb_x, mb_y, block->imodes[0]);
					swebp__predluma16(pred_func, y_dst);

					if (bits)
					{
						for (n = 0; n < 16; n++, bits <<= 2)
						{
							simplewebp_u8 *const dst = y_dst + ((n & 3) * 4 + (n >> 2) * 128);
							swebp__do_transform(bits, coeffs + n * 16, dst);
						}
					}
				}

				{
					/* Chroma */
					simplewebp_u32 bits_uv;
					simplewebp_i32 pred_func;

					bits_uv = block->nonzero_uv;
					pred_func = swebp__check_mode(mb_x, mb_y, block->uvmode);

					swebp__predchroma8(pred_func, u_dst);
					swebp__predchroma8(pred_func, v_dst);
					swebp__do_transform_uv(bits_uv >> 0, coeffs + 16 * 16, u_dst);
					swebp__do_transform_uv(bits_uv >> 8, coeffs + 20 * 16, v_dst);
				}

				if (mb_y < vp8d->mb_h - 1)
				{
					memcpy(top_yuv[0].y, y_dst + 15 * 32, 16);
					memcpy(top_yuv[0].u, u_dst + 7 * 32, 8);
					memcpy(top_yuv[0].v, v_dst + 7 * 32, 8);
				}
			}

			/* Transfer reconstructed samples */
			{
				simplewebp_u8 *y_out, *u_out, *v_out;

				y_out = vp8d->cache_y + mb_x * 16;
				u_out = vp8d->cache_u + mb_x * 8;
				v_out = vp8d->cache_v + mb_x * 8;

				for (j = 0; j < 16; j++)
					memcpy(y_out + j * vp8d->cache_y_stride, y_dst + j * 32, 16);
				for (j = 0; j < 8; j++)
				{
					memcpy(u_out + j * vp8d->cache_uv_stride, u_dst + j * 32, 8);
					memcpy(v_out + j * vp8d->cache_uv_stride, v_dst + j * 32, 8);
				}
			}
		}
	}

	if (vp8d->mb_x < vp8d->mb_w - 1)
		return SIMPLEWEBP_NO_ERROR;

	/* Finish row */
	{
		simplewebp_i32 extra_y_rows, ysize, uvsize, mb_y;
		simplewebp_u8 *ydst, *udst, *vdst, is_last_row;

		extra_y_rows = swebp__fextrarows[vp8d->filter_type];
		ysize = extra_y_rows * vp8d->cache_y_stride;
		uvsize = (extra_y_rows / 2) * vp8d->cache_uv_stride;
		mb_y = vp8d->mb_y;
		is_last_row = mb_y >= vp8d->br_mb_y - 1;

		if (filter_row)
		{
			/* Filter row */
			simplewebp_i32 mb_x;

			for (mb_x = vp8d->tl_mb_x; mb_x < vp8d->br_mb_x; mb_x++)
			{
				simplewebp_i32 y_bps, ilevel, limit;
				struct swebp__finfo *f_info;
				simplewebp_u8 *y_dst;

				f_info = vp8d->f_info + mb_x;
				limit = f_info->limit;

				if (limit > 0)
				{
					ilevel = f_info->ilevel;
					y_bps = vp8d->cache_y_stride;
					y_dst = vp8d->cache_y + mb_x * 16;

					if (vp8d->filter_type == 1)
					{
						/* Simple filter */
						if (mb_x > 0)
							swebp__simple_hfilter16(y_dst, y_bps, limit + 4);
						if (f_info->inner)
							swebp__simple_hfilter16_i(y_dst, y_bps, limit);
						if (mb_y > 0)
							swebp__simple_vfilter16(y_dst, y_bps, limit + 4);
						if (f_info->inner)
							swebp__simple_vfilter16_i(y_dst, y_bps, limit);
					}
					else
					{
						/* Complex filter */
						simplewebp_i32 uv_bps, hev_thresh;
						simplewebp_u8 *u_dst, *v_dst;

						uv_bps = vp8d->cache_uv_stride;
						hev_thresh = f_info->hev_thresh;
						u_dst = vp8d->cache_u + mb_x * 8;
						v_dst = vp8d->cache_v + mb_x * 8;

						if (mb_x > 0)
						{
							swebp__hfilter16(y_dst, y_bps, limit + 4, ilevel, hev_thresh);
							swebp__hfilter8(u_dst, v_dst, uv_bps, limit + 4, ilevel, hev_thresh);
						}
						if (f_info->inner)
						{
							swebp__hfilter16_i(y_dst, y_bps, limit, ilevel, hev_thresh);
							swebp__hfilter8_i(u_dst, v_dst, uv_bps, limit, ilevel, hev_thresh);
						}
						if (mb_y > 0)
						{
							swebp__vfilter16(y_dst, y_bps, limit + 4, ilevel, hev_thresh);
							swebp__vfilter8(u_dst, v_dst, uv_bps, limit + 4, ilevel, hev_thresh);
						}
						if (f_info->inner)
						{
							swebp__vfilter16_i(y_dst, y_bps, limit, ilevel, hev_thresh);
							swebp__vfilter8_i(u_dst, v_dst, uv_bps, limit, ilevel, hev_thresh);
						}
					}
				}
			}
		}

		if (swebp__vp8_output_rows(vp8d, destination) !=
		    SIMPLEWEBP_NO_ERROR)
			return SIMPLEWEBP_IO_ERROR;

		/* output_rows may move the unlocked cache blocks. */
		ydst = vp8d->cache_y - ysize;
		udst = vp8d->cache_u - uvsize;
		vdst = vp8d->cache_v - uvsize;

		/* Rotate top samples */
		if (!is_last_row)
		{
			memcpy(vp8d->cache_y - ysize, ydst + 16 * vp8d->cache_y_stride, ysize);
			memcpy(vp8d->cache_u - uvsize, udst + 8 * vp8d->cache_uv_stride, uvsize);
			memcpy(vp8d->cache_v - uvsize, vdst + 8 * vp8d->cache_uv_stride, uvsize);
		}
	}

	return SIMPLEWEBP_NO_ERROR;
}

#ifndef WEBP_HOST_TEST
#pragma code_seg()
#endif
