/* inflate.c -- zlib interface to inflate modules
 * Copyright (C) 1995-1998 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

#include "zutil.h"
#include "infblock.h"
#include "inftrees.h"
#include "infcodes.h"
#include "infutil.h"

#undef NEEDBYTE         // we have our own versions...
#undef NEXTBYTE

struct inflate_codes_state {int dummy;}; /* for buggy compilers */
// struct inflate_blocks_state {int dummy;}; /* for buggy compilers */

typedef enum {
      METHOD,   /* waiting for method byte */
      FLAG,     /* waiting for flag byte */
      DICT4,    /* four dictionary check bytes to go */
      DICT3,    /* three dictionary check bytes to go */
      DICT2,    /* two dictionary check bytes to go */
      DICT1,    /* one dictionary check byte to go */
      DICT0,    /* waiting for inflateSetDictionary */
      BLOCKS,   /* decompressing blocks */
      CHECK4,   /* four check bytes to go */
      CHECK3,   /* three check bytes to go */
      CHECK2,   /* two check bytes to go */
      CHECK1,   /* one check byte to go */
      INFL_DONE,/* finished check, done */
      INFL_BAD} /* got an error--stay here */
inflate_mode;

/* inflate private state */
struct inf_internal_state {

  /* mode */
  inflate_mode  mode;   /* current inflate mode */

  /* mode dependent information */
  union {
    uInt method;        /* if FLAGS, method byte */
    struct {
      uLong was;                /* computed check value */
      uLong need;               /* stream check value */
    } check;            /* if CHECK, check values to compare */
    uInt marker;        /* if BAD, inflateSync's marker bytes count */
  } sub;        /* submode */

  /* mode independent information */
  int  nowrap;          /* flag for no wrapper */
  uInt wbits;           /* log2(window size)  (8..15, defaults to 15) */
  inflate_blocks_statef
    *blocks;            /* current inflate_blocks state */

};

#define Z_STATE ((struct inf_internal_state *)(z->state))

int ZEXPORT inflateReset(z)
z_streamp z;
{
  if (z == Z_NULL || Z_STATE == Z_NULL)
    return Z_STREAM_ERROR;
  z->total_in = z->total_out = 0;
  z->msg = Z_NULL;
  Z_STATE->mode = Z_STATE->nowrap ? BLOCKS : METHOD;
  inflate_blocks_reset(Z_STATE->blocks, z, Z_NULL);
  Trace((stderr, "inflate: reset\n"));
  return Z_OK;
}


int ZEXPORT inflateEnd(z)
z_streamp z;
{
  if (z == Z_NULL || Z_STATE == Z_NULL || z->zfree == Z_NULL)
    return Z_STREAM_ERROR;
  if (Z_STATE->blocks != Z_NULL)
    inflate_blocks_free(Z_STATE->blocks, z);
  ZFREE(z, Z_STATE);
  Z_STATE = Z_NULL;
  Trace((stderr, "inflate: end\n"));
  return Z_OK;
}


int ZEXPORT inflateInit2_(z, w, version, stream_size)
z_streamp z;
int w;
const char *version;
int stream_size;
{
  static alloc_func ipf_zcalloc = zcalloc;
  static free_func ipf_zcfree = zcfree;
  static check_func pf_adler32 = adler32;

  if (version == Z_NULL || version[0] != ZLIB_VERSION[0] ||
      stream_size != sizeof(z_stream))
      return Z_VERSION_ERROR;

  /* initialize state */
  if (z == Z_NULL)
    return Z_STREAM_ERROR;
  z->msg = Z_NULL;
  if (z->zalloc == Z_NULL)
  {
    z->zalloc = ipf_zcalloc;
    z->opaque = (voidpf)0;
  }
  if (z->zfree == Z_NULL) z->zfree = ipf_zcfree;
  if ((Z_STATE = (struct inf_internal_state FAR *)
       ZALLOC(z,1,sizeof(struct inf_internal_state))) == Z_NULL)
    return Z_MEM_ERROR;
  Z_STATE->blocks = Z_NULL;

  /* handle undocumented nowrap option (no zlib header or check) */
  Z_STATE->nowrap = 0;
  if (w < 0)
  {
    w = - w;
    Z_STATE->nowrap = 1;
  }

  /* set window size */
  if (w < 8 || w > 15)
  {
    inflateEnd(z);
    return Z_STREAM_ERROR;
  }
  Z_STATE->wbits = (uInt)w;

  /* create inflate_blocks state */
  if ((Z_STATE->blocks =
      inflate_blocks_new(z, Z_STATE->nowrap ? Z_NULL : pf_adler32, (uInt)1 << w))
      == Z_NULL)
  {
    inflateEnd(z);
    return Z_MEM_ERROR;
  }
  Tracev((stderr, "inflate: allocated\n"));

  /* reset state */
  inflateReset(z);
  return Z_OK;
}


int ZEXPORT inflateInit_(z, version, stream_size)
z_streamp z;
const char *version;
int stream_size;
{
  return inflateInit2_(z, DEF_WBITS, version, stream_size);
}


#define NEEDBYTE {if(z->avail_in==0)return r;r=f;}
#define NEXTBYTE (z->avail_in--,z->total_in++,*z->next_in++)

int ZEXPORT inflate(z, f)
z_streamp z;
int f;
{
  int r;
  uInt b;

  if (z == Z_NULL || Z_STATE == Z_NULL || z->next_in == Z_NULL)
    return Z_STREAM_ERROR;
  f = f == Z_FINISH ? Z_BUF_ERROR : Z_OK;
  r = Z_BUF_ERROR;

#ifdef __GEOS__
  GEOS_LOCK_WINDOW(Z_STATE->blocks);
#endif

  while (1) switch (Z_STATE->mode)
  {
    case METHOD:
      NEEDBYTE
      if (((Z_STATE->sub.method = NEXTBYTE) & 0xf) != Z_DEFLATED)
      {
        Z_STATE->mode = INFL_BAD;
        z->msg = (char*)"unknown compression method";
        Z_STATE->sub.marker = 5;       /* can't try inflateSync */
        break;
      }
      if ((Z_STATE->sub.method >> 4) + 8 > Z_STATE->wbits)
      {
        Z_STATE->mode = INFL_BAD;
        z->msg = (char*)"invalid window size";
        Z_STATE->sub.marker = 5;       /* can't try inflateSync */
        break;
      }
      Z_STATE->mode = FLAG;
    case FLAG:
      NEEDBYTE
      b = NEXTBYTE;
      if (((Z_STATE->sub.method << 8) + b) % 31)
      {
        Z_STATE->mode = INFL_BAD;
        z->msg = (char*)"incorrect header check";
        Z_STATE->sub.marker = 5;       /* can't try inflateSync */
        break;
      }
      Tracev((stderr, "inflate: zlib header ok\n"));
      if (!(b & PRESET_DICT))
      {
        Z_STATE->mode = BLOCKS;
	break;
      }
      Z_STATE->mode = DICT4;
    case DICT4:
      NEEDBYTE
      Z_STATE->sub.check.need = (uLong)NEXTBYTE << 24;
      Z_STATE->mode = DICT3;
    case DICT3:
      NEEDBYTE
      Z_STATE->sub.check.need += (uLong)NEXTBYTE << 16;
      Z_STATE->mode = DICT2;
    case DICT2:
      NEEDBYTE
      Z_STATE->sub.check.need += (uLong)NEXTBYTE << 8;
      Z_STATE->mode = DICT1;
    case DICT1:
      NEEDBYTE
      Z_STATE->sub.check.need += (uLong)NEXTBYTE;
      z->adler = Z_STATE->sub.check.need;
      Z_STATE->mode = DICT0;
      GEOS_UNLOCK_WINDOW(Z_STATE->blocks);
      return Z_NEED_DICT;
    case DICT0:
      Z_STATE->mode = INFL_BAD;
      z->msg = (char*)"need dictionary";
      Z_STATE->sub.marker = 0;       /* can try inflateSync */
      GEOS_UNLOCK_WINDOW(Z_STATE->blocks);
      return Z_STREAM_ERROR;
    case BLOCKS:
      r = inflate_blocks(Z_STATE->blocks, z, r);
      if (r == Z_DATA_ERROR)
      {
        Z_STATE->mode = INFL_BAD;
        Z_STATE->sub.marker = 0;       /* can try inflateSync */
        break;
      }
      if (r == Z_OK)
        r = f;
      if (r != Z_STREAM_END)
      {
        GEOS_UNLOCK_WINDOW(Z_STATE->blocks);
        return r;
      }
      r = f;
      inflate_blocks_reset(Z_STATE->blocks, z, &Z_STATE->sub.check.was);
      if (Z_STATE->nowrap)
      {
        Z_STATE->mode = INFL_DONE;
        break;
      }
      Z_STATE->mode = CHECK4;
    case CHECK4:
      NEEDBYTE
      Z_STATE->sub.check.need = (uLong)NEXTBYTE << 24;
      Z_STATE->mode = CHECK3;
    case CHECK3:
      NEEDBYTE
      Z_STATE->sub.check.need += (uLong)NEXTBYTE << 16;
      Z_STATE->mode = CHECK2;
    case CHECK2:
      NEEDBYTE
      Z_STATE->sub.check.need += (uLong)NEXTBYTE << 8;
      Z_STATE->mode = CHECK1;
    case CHECK1:
      NEEDBYTE
      Z_STATE->sub.check.need += (uLong)NEXTBYTE;

      if (Z_STATE->sub.check.was != Z_STATE->sub.check.need)
      {
        Z_STATE->mode = INFL_BAD;
        z->msg = (char*)"incorrect data check";
        Z_STATE->sub.marker = 5;       /* can't try inflateSync */
        break;
      }
      Trace((stderr, "inflate: zlib check ok\n"));
      Z_STATE->mode = INFL_DONE;
#ifdef __GEOS__
    case INFL_DONE:
      GEOS_UNLOCK_WINDOW(Z_STATE->blocks);
      return Z_STREAM_END;
    case INFL_BAD:
      GEOS_UNLOCK_WINDOW(Z_STATE->blocks);
      return Z_DATA_ERROR;
    default:
      GEOS_UNLOCK_WINDOW(Z_STATE->blocks);
      return Z_STREAM_ERROR;
#else
    case INFL_DONE:
      return Z_STREAM_END;
    case INFL_BAD:
      return Z_DATA_ERROR;
    default:
      return Z_STREAM_ERROR;
#endif
  }

#ifdef NEED_DUMMY_RETURN
  return Z_STREAM_ERROR;  /* Some dumb compilers complain without this */
#endif
}


int ZEXPORT inflateSetDictionary(z, dictionary, dictLength)
z_streamp z;
const Bytef *dictionary;
uInt  dictLength;
{
  uInt length = dictLength;

  if (z == Z_NULL || Z_STATE == Z_NULL || Z_STATE->mode != DICT0)
    return Z_STREAM_ERROR;

  if (adler32(1L, dictionary, dictLength) != z->adler) return Z_DATA_ERROR;
  z->adler = 1L;

  if (length >= ((uInt)1<<Z_STATE->wbits))
  {
    length = (1<<Z_STATE->wbits)-1;
    dictionary += dictLength - length;
  }
  inflate_set_dictionary(Z_STATE->blocks, dictionary, length);
  Z_STATE->mode = BLOCKS;
  return Z_OK;
}


int ZEXPORT inflateSync(z)
z_streamp z;
{
  uInt n;       /* number of bytes to look at */
  Bytef *p;     /* pointer to bytes */
  uInt m;       /* number of marker bytes found in a row */
  uLong r, w;   /* temporaries to save total_in and total_out */

  /* set up */
  if (z == Z_NULL || Z_STATE == Z_NULL)
    return Z_STREAM_ERROR;
  if (Z_STATE->mode != INFL_BAD)
  {
    Z_STATE->mode = INFL_BAD;
    Z_STATE->sub.marker = 0;
  }
  if ((n = z->avail_in) == 0)
    return Z_BUF_ERROR;
  p = z->next_in;
  m = Z_STATE->sub.marker;

  /* search */
  while (n && m < 4)
  {
    static const Byte mark[4] = {0, 0, 0xff, 0xff};
    if (*p == mark[m])
      m++;
    else if (*p)
      m = 0;
    else
      m = 4 - m;
    p++, n--;
  }

  /* restore */
  z->total_in += p - z->next_in;
  z->next_in = p;
  z->avail_in = n;
  Z_STATE->sub.marker = m;

  /* return no joy or set up to restart on a new block */
  if (m != 4)
    return Z_DATA_ERROR;
  r = z->total_in;  w = z->total_out;
  inflateReset(z);
  z->total_in = r;  z->total_out = w;
  Z_STATE->mode = BLOCKS;
  return Z_OK;
}


/* Returns true if inflate is currently at the end of a block generated
 * by Z_SYNC_FLUSH or Z_FULL_FLUSH. This function is used by one PPP
 * implementation to provide an additional safety check. PPP uses Z_SYNC_FLUSH
 * but removes the length bytes of the resulting empty stored block. When
 * decompressing, PPP checks that at the end of input packet, inflate is
 * waiting for these length bytes.
 */
int ZEXPORT inflateSyncPoint(z)
z_streamp z;
{
  if (z == Z_NULL || Z_STATE == Z_NULL || Z_STATE->blocks == Z_NULL)
    return Z_STREAM_ERROR;
  return inflate_blocks_sync_point(Z_STATE->blocks);
}
