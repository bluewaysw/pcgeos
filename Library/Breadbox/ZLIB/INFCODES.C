/* infcodes.c -- process literals and length/distance pairs
 * Copyright (C) 1995-1998 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h 
 */

#include "zutil.h"
#include "inftrees.h"
#include "infblock.h"
#include "infcodes.h"
#include "infutil.h"
#include "inffast.h"

struct inflate_codes_state {int dummy;}; /* for buggy compilers */

/* simplify the use of the inflate_huft type with some defines */
#define exop word.what.Exop
#define bits word.what.Bits

typedef enum {        /* waiting for "i:"=input, "o:"=output, "x:"=nothing */
      START,    /* x: set up for LEN */
      LEN,      /* i: get length/literal/eob next */
      LENEXT,   /* i: getting length extra (have base) */
      DIST,     /* i: get distance next */
      DISTEXT,  /* i: getting distance extra */
      COPY,     /* o: copying bytes in window, waiting for space */
      LIT,      /* o: got literal, waiting for output space */
      WASH,     /* o: got eob, possibly still output waiting */
      END,      /* x: got eob and all data flushed */
      BADCODE}  /* x: got error */
inflate_codes_mode;

/* inflate codes private state */
struct int_inflate_codes_state {

  /* mode */
  inflate_codes_mode mode;      /* current inflate_codes mode */

  /* mode dependent information */
  uInt len;
  union {
    struct {
      inflate_huft *tree;       /* pointer into tree */
      uInt need;                /* bits needed */
    } code;             /* if LEN or DIST, where in tree */
    uInt lit;           /* if LIT, literal */
    struct {
      uInt get;                 /* bits to get for extra */
      uInt dist;                /* distance back to copy from */
    } copy;             /* if EXT or COPY, where and how much */
  } sub;                /* submode */

  /* mode independent information */
  Byte lbits;           /* ltree bits decoded per branch */
  Byte dbits;           /* dtree bits decoder per branch */
  inflate_huft *ltree;          /* literal/length/eob tree */
  inflate_huft *dtree;          /* distance tree */

};

#define C ((struct int_inflate_codes_state *)c)


inflate_codes_statef *inflate_codes_new(bl, bd, tl, td, z)
uInt bl, bd;
inflate_huft *tl;
inflate_huft *td; /* need separate declaration for Borland C++ */
z_streamp z;
{
  inflate_codes_statef *c;

  if ((c = (inflate_codes_statef *)
       ZALLOC(z,1,sizeof(struct int_inflate_codes_state))) != Z_NULL)
  {
    C->mode = START;
    C->lbits = (Byte)bl;
    C->dbits = (Byte)bd;
    C->ltree = tl;
    C->dtree = td;
    Tracev((stderr, "inflate:       codes new\n"));
  }
  return c;
}


int inflate_codes(s, z, r)
inflate_blocks_statef *s;
z_streamp z;
int r;
{
  uInt j;               /* temporary storage */
  inflate_huft *t;      /* temporary pointer */
  uInt e;               /* extra bits or operation */
  uLong b;              /* bit buffer */
  uInt k;               /* bits in bit buffer */
  Bytef *p;             /* input data pointer */
  uInt n;               /* bytes available there */
  Bytef *q;             /* output window write pointer */
  uInt m;               /* bytes to end of window or read pointer */
  Bytef *f;             /* pointer to copy strings from */
  inflate_codes_statef *c = s->sub.decode.codes;  /* codes state */

  /* copy input/output information to locals (UPDATE macro restores) */
  LOAD

  /* process input and output based on current state */
  while (1) switch (C->mode)
  {             /* waiting for "i:"=input, "o:"=output, "x:"=nothing */
    case START:         /* x: set up for LEN */
#ifndef SLOW
      if (m >= 258 && n >= 10)
      {
        UPDATE
        r = inflate_fast(C->lbits, C->dbits, C->ltree, C->dtree, s, z);
        LOAD
        if (r != Z_OK)
        {
          C->mode = r == Z_STREAM_END ? WASH : BADCODE;
          break;
        }
      }
#endif /* !SLOW */
      C->sub.code.need = C->lbits;
      C->sub.code.tree = C->ltree;
      C->mode = LEN;
    case LEN:           /* i: get length/literal/eob next */
      j = C->sub.code.need;
      NEEDBITS(j)
      t = C->sub.code.tree + ((uInt)b & inflate_mask[j]);
      DUMPBITS(t->bits)
      e = (uInt)(t->exop);
      if (e == 0)               /* literal */
      {
        C->sub.lit = t->base;
        Tracevv((stderr, t->base >= 0x20 && t->base < 0x7f ?
                 "inflate:         literal '%c'\n" :
                 "inflate:         literal 0x%02x\n", t->base));
        C->mode = LIT;
        break;
      }
      if (e & 16)               /* length */
      {
        C->sub.copy.get = e & 15;
        C->len = t->base;
        C->mode = LENEXT;
        break;
      }
      if ((e & 64) == 0)        /* next table */
      {
        C->sub.code.need = e;
        C->sub.code.tree = t + t->base;
        break;
      }
      if (e & 32)               /* end of block */
      {
        Tracevv((stderr, "inflate:         end of block\n"));
        C->mode = WASH;
        break;
      }
      C->mode = BADCODE;        /* invalid code */
      z->msg = (char*)"invalid literal/length code";
      r = Z_DATA_ERROR;
      LEAVE
    case LENEXT:        /* i: getting length extra (have base) */
      j = C->sub.copy.get;
      NEEDBITS(j)
      C->len += (uInt)b & inflate_mask[j];
      DUMPBITS(j)
      C->sub.code.need = C->dbits;
      C->sub.code.tree = C->dtree;
      Tracevv((stderr, "inflate:         length %u\n", C->len));
      C->mode = DIST;
    case DIST:          /* i: get distance next */
      j = C->sub.code.need;
      NEEDBITS(j)
      t = C->sub.code.tree + ((uInt)b & inflate_mask[j]);
      DUMPBITS(t->bits)
      e = (uInt)(t->exop);
      if (e & 16)               /* distance */
      {
        C->sub.copy.get = e & 15;
        C->sub.copy.dist = t->base;
        C->mode = DISTEXT;
        break;
      }
      if ((e & 64) == 0)        /* next table */
      {
        C->sub.code.need = e;
        C->sub.code.tree = t + t->base;
        break;
      }
      C->mode = BADCODE;        /* invalid code */
      z->msg = (char*)"invalid distance code";
      r = Z_DATA_ERROR;
      LEAVE
    case DISTEXT:       /* i: getting distance extra */
      j = C->sub.copy.get;
      NEEDBITS(j)
      C->sub.copy.dist += (uInt)b & inflate_mask[j];
      DUMPBITS(j)
      Tracevv((stderr, "inflate:         distance %u\n", C->sub.copy.dist));
      C->mode = COPY;
    case COPY:          /* o: copying bytes in window, waiting for space */
#ifndef __TURBOC__ /* Turbo C bug for following expression */
      f = (uInt)(q - s->window) < C->sub.copy.dist ?
          s->end - (C->sub.copy.dist - (q - s->window)) :
          q - C->sub.copy.dist;
#else
      f = q - C->sub.copy.dist;
      if ((uInt)(q - s->window) < C->sub.copy.dist)
        f = s->end - (C->sub.copy.dist - (uInt)(q - s->window));
#endif
      while (C->len)
      {
        NEEDOUT
        OUTBYTE(*f++)
        if (f == s->end)
          f = s->window;
        C->len--;
      }
      C->mode = START;
      break;
    case LIT:           /* o: got literal, waiting for output space */
      NEEDOUT
      OUTBYTE(C->sub.lit)
      C->mode = START;
      break;
    case WASH:          /* o: got eob, possibly more output */
      if (k > 7)        /* return unused byte, if any */
      {
        Assert(k < 16, "inflate_codes grabbed too many bytes")
        k -= 8;
        n++;
        p--;            /* can always return one */
      }
      FLUSH
      if (s->read != s->write)
        LEAVE
      C->mode = END;
    case END:
      r = Z_STREAM_END;
      LEAVE
    case BADCODE:       /* x: got error */
      r = Z_DATA_ERROR;
      LEAVE
    default:
      r = Z_STREAM_ERROR;
      LEAVE
  }
#ifdef NEED_DUMMY_RETURN
  return Z_STREAM_ERROR;  /* Some dumb compilers complain without this */
#endif
}


void inflate_codes_free(c, z)
inflate_codes_statef *c;
z_streamp z;
{
  ZFREE(z, c);
  Tracev((stderr, "inflate:       codes free\n"));
}
