/* @(#)mallint.h 1.1 86/09/24 SMI*/

/*
 * Copyright (c) 1986 by Sun Microsystems, Inc.
 *
 * $Id: mallint.h,v 1.4 96/05/20 18:56:21 dbaumann Exp $
 */

/*
 * file: mallint.h
 * description:
 *
 * Definitions for malloc.c and friends (realloc.c, memalign.c)
 *
 * The node header structure.  Header info never overlaps with user
 * data space, in order to accommodate the following atrocity:
 *		free(p);
 *		realloc(p, newsize);
 * ... which was historically used to obtain storage compaction as
 * a side effect of the realloc() call, when the block referenced
 * by p was coalesced with another free block by the call to free().
 * 
 * To reduce storage consumption, a header block is associated with
 * free blocks only, not allocated blocks.
 * When a free block is allocated, its header block is put on 
 * a free header block list.
 *
 * This creates a header space and a free block space.
 * The left pointer of a header blocks is used to chain free header
 * blocks together.  New header blocks are allocated in chunks of
 * NFREE_HDRS.
 */
#include "malloc.h"

typedef enum {false,true} bool;
typedef struct	freehdr	*Freehdr;
typedef struct	dblk	*Dblk;

/*
 * Description of a header for a free block
 * Only free blocks have such headers.
 */
struct 	freehdr	{
	Freehdr	left;			/* Left tree pointer */
	Freehdr	right;			/* Right tree pointer */
	Dblk	block;			/* Ptr to the data block */
	unsigned long	size;
};

#ifdef NIL
#  undef NIL
#endif
#define NIL		((Freehdr) 0)

#if defined(sparc)
#define WORDSIZE    	sizeof(double)
#else
#define WORDSIZE	sizeof(int)
#endif

#define	NFREE_HDRS	512		/* Get this many headers at a time */
#define	SMALLEST_BLK	(sizeof(struct dblk)+WORDSIZE) /* Size of smallest block */

#ifdef  NULL
#undef  NULL
#endif
#define NULL            0

/*
 * Description of a data block.  
 * The size precedes the address returned to the user.
 */
struct	dblk	{
#ifdef MEM_TRACE
	unsigned long	size;		/* Size of the block */
	unsigned long	allocator:24,  	/* Caller who allocated it */
			tag:8; 	    	/* Type of data stored */
#else
	unsigned long	size:24,    	/* Size of block (limited to 16 Mb) */
		tag:8;	    	    	/* Type of data stored */
#if defined(sparc)
	unsigned long	pad;   	    	/* Ensure double-alignment */
#endif
#endif /* MEM_TRACE */
	char	data[LABEL_IN_STRUCT]; /* Addr returned to the caller */
};

/*
 * weight(x) is the size of a block, in bytes; or 0 if and only if x
 *	is a null pointer.  Note that malloc() and free() should be
 *	prepared to deal with things like zero-length blocks, which
 *	can be introduced by errant programs.
 */

#define blkhdr(p)   	(Dblk)((p)==0?(malloc_t)0:(((malloc_t)p)-(int)&((Dblk)0)->data))
#define	weight(x)	((x) == NIL? 0: (x->size))
#define	roundup(x, y)   ((((x)+((y)-1))/(y))*(y))
#define	nextblk(p, size) ((Dblk) ((malloc_t) (p) + (size)))
#ifndef max
#  define	max(a, b)	((a) < (b)? (b): (a))
#endif
#ifndef min
#  define	min(a, b)	((a) < (b)? (a): (b))
#endif
#define heapsize()	(_ubound - _lbound)

#if defined(sparc)
#define misaligned(p)	((unsigned)(p)&7)
#else
#define misaligned(p)	((unsigned)(p)&3)
#endif

extern	Freehdr	_root;
extern	malloc_t    _lbound, _ubound;

extern	int	malloc_debug(int level);
extern  int	malloc_verify(void);

extern	struct mallinfo __mallinfo;
