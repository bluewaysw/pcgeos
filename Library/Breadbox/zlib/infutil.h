/* infutil.h -- types and macros common to blocks and codes
 * Copyright (C) 1995-1998 Mark Adler
 * For conditions of distribution and use, see copyright notice in zlib.h
 */

/* WARNING: this file should *not* be used by applications. It is
   part of the implementation of the compression library and is
   subject to change. Applications should only use zlib.h.
 */

#include "heap.h"

#ifdef __GEOS__
#include <ec.h>
#endif

#ifndef _INFUTIL_H
#define _INFUTIL_H

typedef enum {
      TYPE,     /* get type bits (3, including end bit) */
      LENS,     /* get lengths for stored */
      STORED,   /* processing stored block */
      TABLE,    /* get table lengths */
      BTREE,    /* get bit lengths tree for a dynamic block */
      DTREE,    /* get length, distance trees for a dynamic block */
      CODES,    /* processing fixed or dynamic block */
      DRY,      /* output remaining window bytes */
      INFU_DONE,     /* finished last block, done */
      INFU_BAD}      /* got a data error--stuck here */
inflate_block_mode;

/* inflate blocks semi-private state */
struct inflate_blocks_state {

  /* mode */
  inflate_block_mode  mode;     /* current inflate_block mode */

  /* mode dependent information */
  union {
    uInt left;          /* if STORED, bytes left to copy */
    struct {
      uInt table;               /* table lengths (14 bits) */
      uInt index;               /* index into blens (or border) */
      uIntf *blens;             /* bit lengths of codes */
      uInt bb;                  /* bit length tree depth */
      inflate_huft *tb;         /* bit length decoding tree */
    } trees;            /* if DTREE, decoding info for trees */
    struct {
      inflate_codes_statef
         *codes;
    } decode;           /* if CODES, current state */
  } sub;                /* submode */
  uInt last;            /* true if this block is the last block */

  /* mode independent information */
  uInt bitk;            /* bits in bit buffer */
  uLong bitb;           /* bit buffer */
  inflate_huft *hufts;  /* single malloc for tree space */

#ifdef __GEOS__
    MemHandle windowHan;  /* GEOS MemHandle for sliding window */
    word  windowSize;
    word  windowReadOffs;
    word  windowWriteOffs;
#endif

  Bytef *window;        /* sliding window */
  Bytef *end;           /* one byte after sliding window */
  Bytef *read;          /* window read pointer */
  Bytef *write;         /* window write pointer */
  check_func checkfn;   /* check function */
  uLong check;          /* check on output */
};



/*
 * Strategy:
 * We want to use IF_GEOS_LOCK_SLIDING_WINDOW and IF_GEOS_UNLOCK_SLIDING_WINDOW
 * as /high/ as possible in the API, so they come up mainly in inflate.c.
 * However, allocating and freeing memory has to be done in infblock.c (which is one
 * level down), but we try to use GEOS code there only in inflate_blocks_new
 * and inflate_blocks_free.
 */

 #ifdef __GEOS__

  typedef enum {
    /* Stream access while the window buf is already locked, which is unexpected. */
    ERROR_SLIDING_WINDOW_ALREAEDY_LOCKED,
    /* Stream access while the window buf is not locked, which is required. */
    ERROR_SLIDING_WINDOW_UNLOCKED
  } FatalErrors;
  extern FatalErrors shme;  /* For swat to use. */

  #define IF_GEOS_LOCK_SLIDING_WINDOW(s) { \
    /* if s->window is NOT 0 as of now, something is wrong, fatal error */ \
    EC_ERROR_IF(s->window != (Bytef*) 0, ERROR_SLIDING_WINDOW_ALREAEDY_LOCKED); \
    s->window = (Bytef *) MemLock(s->windowHan); \
    s->end = (Bytef *) (s->window + s->windowSize); \
    s->read = (Bytef *) (s->window + s->windowReadOffs); \
    s->write = (Bytef *) (s->window + s->windowWriteOffs); \
  }

  #define IF_GEOS_UNLOCK_SLIDING_WINDOW(s) { \
    /* if s->window is 0, something is wrong, fatal error*/ \
    EC_ERROR_IF(s->window == (Bytef*) 0, ERROR_SLIDING_WINDOW_UNLOCKED); \
    s->windowReadOffs = ((word) s->read) - ((word) s->window); \
    s->windowWriteOffs = ((word) s->write) - ((word) s->window); \
    MemUnlock(s->windowHan); \
    EC(s->window = (Bytef*) 0); \
  }
#else
  // these expand to nothing
  #define IF_GEOS_LOCK_SLIDING_WINDOW(s)
  #define IF_GEOS_UNLOCK_SLIDING_WINDOW(s)
#endif


/* defines for inflate input/output */
/*   update pointers and return */
#define UPDBITS {s->bitb=b;s->bitk=k;}
#define UPDIN {z->avail_in=n;z->total_in+=p-z->next_in;z->next_in=p;}
#define UPDOUT {s->write=q;}
#define UPDATE {UPDBITS UPDIN UPDOUT}
#define LEAVE {UPDATE return inflate_flush(s,z,r);}
/*   get bytes and bits */
#define LOADIN {p=z->next_in;n=z->avail_in;b=s->bitb;k=s->bitk;}
#define NEEDBYTE {if(n)r=Z_OK;else LEAVE}
#define NEXTBYTE (n--,*p++)
#define NEEDBITS(j) {while(k<(j)){NEEDBYTE;b|=((uLong)NEXTBYTE)<<k;k+=8;}}
#define DUMPBITS(j) {b>>=(j);k-=(j);}
/*   output bytes */
#define WAVAIL (uInt)(q<s->read?s->read-q-1:s->end-q)
#define LOADOUT {q=s->write;m=(uInt)WAVAIL;}
#define WRAP {if(q==s->end&&s->read!=s->window){q=s->window;m=(uInt)WAVAIL;}}
#define FLUSH {UPDOUT r=inflate_flush(s,z,r); LOADOUT}
#define NEEDOUT {if(m==0){WRAP if(m==0){FLUSH WRAP if(m==0) LEAVE}}r=Z_OK;}
#define OUTBYTE(a) {*q++=(Byte)(a);m--;}
/*   load local pointers */
#define LOAD {LOADIN LOADOUT}

/* masks for lower bits (size given to avoid silly warnings with Visual C++) */
extern uInt inflate_mask[17];

/* copy as much as possible from the sliding window to the output area */
extern int inflate_flush OF((
    inflate_blocks_statef *,
    z_streamp ,
    int));

// struct internal_state      {int dummy;}; /* for buggy compilers */

#endif
