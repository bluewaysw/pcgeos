/*
 * Copyright (c) 1986 by Sun Microsystems, Inc.
 *
 * $Id: malloc.c,v 1.14 96/05/24 21:04:29 jacob Exp $
 */

/*
 * file: malloc.c
 * description:
 *	Yet another memory allocator, this one based on a method
 *	described in C.J. Stephenson, "Fast Fits"
 *
 *	The basic data structure is a "Cartesian" binary tree, in which
 *	nodes are ordered by ascending addresses (thus minimizing free
 *	list insertion time) and block sizes decrease with depth in the
 *	tree (thus minimizing search time for a block of a given size).
 *
 *	In other words: for any node s, let D(s) denote the set of
 *	descendents of s; for all x in D(left(s)) and all y in
 *	D(right(s)), we have:
 *
 *	a. addr(x) <  addr(s) <  addr(y)
 *	b. len(x)  <= len(s)  >= len(y)
 */
#include <config.h>
#include "malloc.h"
#include "mallint.h"
#include "malErr.h"
#include <errno.h>
#include <fileUtil.h>
#include <stddef.h>
#include <stdarg.h>
#include <compat/string.h>

#if defined(_MSDOS) && defined(__HIGHC__)
#include <pharlap.h>
#include <dos.h>
#endif

#if defined(_WIN32)
/*
 * I think this is okay in Win32...  I remeber it looked like we
 * have a home-grown version for other OS's...
 */
#include <assert.h>
#endif


/*#define MEM_LOG	1*/


#if defined(MEM_LOG)

#include <stdio.h>

static FileType	log = 0;

#define LOG(args) MemLog args

static void
MemLog(char *fmt, ...)
{

    int	    nbytes;
    char    buf[128];
    va_list args;
    int	    bytesWritten = 0;

    va_start(args, fmt);

    if (log == 0) {
	returnCode = FileUtil_Open(&log, "memlog",
				   O_WRONLY|O_BINARY|O_CREAT,
				   SH_DENYWR, 0666);
 	if (returnCode == FALSE) {
	    char errmsg[512];

	    FileUtil_SprintError(errmsg, "Cannot open file \"memlog\"");
	    fprintf(stderr, "%s", errmsg);
	    exit(1);
 	}
    }

    nbytes = vsprintf(buf, fmt, args);
    returnCode = FileUtil_Write(log, buf, nbytes, &bytesWritten);
    if (returnCode == FALSE) {
	char errmsg[512];

	FileUtil_SprintError(errmsg, "Error writing to file \"memlog\"");
	fprintf(stderr, "%s", errmsg);
	exit(1);
    }
    va_end(args);
}
#else
#define LOG(args)
#endif

#if defined(MEM_TRACE)
#define DEBUG
extern 	unsigned long caller(void);
#endif /* MEM_TRACE */

/* system interface */

#if defined(sun) || defined(isi) || defined(_LINUX)
extern				/* available from OS */
#else
static				/* implemented in this file */
#endif
malloc_t sbrk(int change);

#if defined(sun) || defined(isi)
extern	int	getpagesize(void);
#elif defined(_MSDOS) || defined(_LINUX)
#define getpagesize() (4096)	/* 386 has a 4K page size */
#endif

extern	void	abort(void);


static	int	nbpg = 0;	/* set by calling getpagesize() */
static	bool	morecore(unsigned nbytes);/* get more memory into free space */

/* SystemV-compatible information structure */
#define INIT_MXFAST 0
#define INIT_NLBLKS 100
#define INIT_GRAIN WORDSIZE

struct	mallinfo __mallinfo = {
	0,0,0,0,0,0,0,0,0,0,			/* basic info */
	INIT_MXFAST, INIT_NLBLKS, INIT_GRAIN,	/* mallopt options */
	0,0,0
};

/* heap data structures */

Freehdr	_root	= NIL;			/* root of free space list */
malloc_t _lbound = NULL;		/* lower bound of heap */
malloc_t _ubound = NULL;		/* upper bound of heap */

/* free header list management */

static	Freehdr	getfreehdr(int);
static	void 	putfreehdr(Freehdr p);
static	struct	freehdr	free_pool[NFREE_HDRS]; /* initial header pool */
static	Freehdr	freehdrptr = free_pool; /* Array of available headers */
static	int	nfreehdrs = NFREE_HDRS;	/* Num of elements in freehdrptr */
static	Freehdr	freehdrlist = NIL;	/* List of available headers */

/* error checking */
/* sets errno; prints msg and aborts if DEBUG is on */
static	void error(char *fmt, ...);
static	int  noerr=0;	/* If non-zero, allocators will never return NULL
			 * due to morecore's inability to get more memory */

#if defined(DEBUG)

int	malloc_debug(int level);
int	malloc_verify(void);
static	int debug_level = 1;

/*
 * A block with a negative size, a size that is not a multiple
 * of WORDSIZE, a size greater than the current extent of the
 * heap, or a size which extends beyond the end of the heap is
 * considered bad.
 */

#define badblksize(p,size)\
( (size) < SMALLEST_BLK \
	|| (size) & (WORDSIZE-1) \
	|| (size) > heapsize() \
	|| ((malloc_t)(p))+(size) > _ubound )

#else	/*!DEBUG	=================================================*/

#define malloc_debug(level) 0
#define malloc_verify() 1
#define debug_level 0
#define badblksize(p,size) 0

#endif	/*!DEBUG	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

#if defined(_MSDOS)

/***********************************************************************
 *				sbrk
 ***********************************************************************
 * SYNOPSIS:	    Extend or contract the allocation fence by a certain
 *		    amount.
 * CALLED BY:	    INTERNAL
 * RETURN:	    The previous fence, or -1 if can't alloc that amount.
 * SIDE EFFECTS:    the fence be moved
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	ardeb		Initial Revision
 *	JAG	23 May 96	Win32 Version
 *
 ***********************************************************************/
static malloc_t
sbrk(int change)
{
    static malloc_t fence = 0;
    malloc_t old;
    struct _SREGS segs;
    unsigned maxsize;

    if (fence == 0) {
	/*
	 * Not initialized yet. Determine the size of our arena.
	 */
	MS_PSP _far *psp;

	FP_SET(psp, 0, SS_PSP);

	fence = (malloc_t)psp->data_size;
    }
    old = fence;

    fence += change;
    _segread(&segs);

    if (_dos_setblock(((unsigned long)fence + nbpg - 1) / nbpg,
			segs.ds, &maxsize) != 0)
    {
	/*
	 * Can't do it -- return an error.
	 */
	fence -= change;
	old = (malloc_t)-1;
    }
    return(old);
}

#elif defined(_WIN32)

#include <compat/windows.h>

static char *end = NULL; /* for malloc_verify()'s edification */

malloc_t
sbrk(int change)
{
    static malloc_t	fence = 0;	/* if == 0, we haven't
					   been called yet */
    malloc_t		old;

    if (fence == 0) {
	/*
	 * We haven't been called before.  Our tactics are to
	 * "reserve" a large chunk of the address space of our process
	 * without actually "committing" any storage to it.  This
	 * simply prevents anyone else from trying to reserve it.
	 */
	fence = (malloc_t)
	    VirtualAlloc(NULL,
			 200 * 1024 * 1024,
			 MEM_RESERVE, PAGE_READWRITE);

	if (fence == NULL) {
	    /*
	     * VirtualAlloc barfed.  This should never happen.
	     * If it did, I feel sorry for you.
	     */
	    return fence = (malloc_t) -1;
	}

	end = (char *) fence; /* malloc_verify() wants to know */
    }

    old = fence;
    fence += change;

    if (change > 0) {
	/*
	 * Increase the size of the heap by "committing" some new
	 * pages at the end of heap.  It's okay to commit already
	 * committed pages.  VirtualAlloc rounds down the first
	 * parameter, and, effectively, rounds up the second parameter
	 * (to the nearest pagesize).
	 */
	if (VirtualAlloc((LPVOID) old, change, MEM_COMMIT, PAGE_READWRITE)
	    == NULL) {
	    assert(0);		/* XXX: for now... */
	    old = (malloc_t) -1; /* signal error */
	}
    } else if (change != 0) {
	LPVOID		start;
	DWORD		size;
	unsigned	fenceRemainder = ((unsigned) fence) % nbpg;

	/*
	 * VirtualFree decommits any pages "touched" by the range
	 * (lpAddress, lpAddress + cbSize).  We have to do some fancy
	 * foot-work to figure out which range to free.  We don't want
	 * to accidentally decommit a page which is still partly in
	 * use.
	 */
	if (fenceRemainder == 0) {
	    /*
	     * If the fence is now sitting on a page boundary, we
	     * should decommit the page it's on and everything after
	     * it since the higest valid address is one below the
	     * fence (i.e., the previous page).
	     */
	    start = (LPVOID) fence;
	    size = -change;
	} else if ((unsigned) (((unsigned) fence) / nbpg)
		   != (unsigned) ((unsigned) old / nbpg)) {
	    /*
	     * We're no longer on the page we used to be, but we're
	     * also in the middle of a page.  This means we have to
	     * uncommit all the committed pages above the one we're
	     * on.
	     */
	    unsigned bytesToNextPage = nbpg - fenceRemainder;

	    start = (LPVOID) (fence + bytesToNextPage);
	    size = -change - bytesToNextPage;
	}

	if (!VirtualFree(start, size, MEM_DECOMMIT)) {
	    assert(0);		/* this should never happen unless
				 * the above code is incorrect */
	    return (malloc_t) -1;
	}
    }

    return old;
}
#endif /* _WIN32 */


/*
 * insert (newblk, len)
 *	Inserts a new node in the free space tree, placing it
 *	in the correct position with respect to the existing nodes.
 *
 * algorithm:
 *	Starting from the root, a binary search is made for the new
 *	node. If this search were allowed to continue, it would
 *	eventually fail (since there cannot already be a node at the
 *	given address); but in fact it stops when it reaches a node in
 *	the tree which has a length less than that of the new node (or
 *	when it reaches a null tree pointer).
 *
 *	The new node is then inserted at the root of the subtree for
 *	which the shorter node forms the old root (or in place of the
 *	null pointer).
 */

static void
insert(register Dblk	newblk,	/* Ptr to the block to insert */
       register unsigned	len)	/* Length of new node */
{
    register Freehdr *fpp;	/* Address of ptr to subtree */
    register Freehdr x;
    register Freehdr *left_hook; /* Temp for insertion */
    register Freehdr *right_hook; /* Temp for insertion */
    register Freehdr newhdr;

    /*
     * check for bad block size.
     */
    if ( badblksize(newblk,len) ) {
	error("insert: bad block size (%d) at %#x\n", len, newblk);
	return;
    }

    /*
     * Search for the first node which has a weight less
     *	than that of the new node; this will be the
     *	point at which we insert the new node.
     */
    fpp = &_root;
    x = *fpp;
    while (weight(x) >= len) {
	if (newblk < x->block)
	    fpp = &x->left;
	else
	    fpp = &x->right;
	x = *fpp;
    }

    /*
     * Perform root insertion. The variable x traces a path through
     *	the fpp, and with the help of left_hook and right_hook,
     *	rewrites all links that cross the territory occupied
     *	by newblk.
     */

    newhdr = getfreehdr(1);
    *fpp = newhdr;

    newhdr->left = NIL;
    newhdr->right = NIL;
    newhdr->block = newblk;
    newhdr->size = len;

    /*
     * set length word in the block for consistency with the header.
     */

    newblk->size = len;
#if defined(MEM_TRACE)
    newblk->allocator = -1;
#endif /* MEM_TRACE */

    left_hook = &newhdr->left;
    right_hook = &newhdr->right;

    while (x != NIL) {
	/*
	 * Remark:
	 *	The name 'left_hook' is somewhat confusing, since
	 *	it is always set to the address of a .right link
	 *	field.  However, its value is always an address
	 *	below (i.e., to the left of) newblk. Similarly
	 *	for right_hook. The values of left_hook and
	 *	right_hook converge toward the value of newblk,
	 *	as in a classical binary search.
	 */
	if (x->block < newblk) {
	    /*
	     * rewrite link crossing from the left
	     */
	    *left_hook = x;
	    left_hook = &x->right;
	    x = x->right;
	} else {
	    /*
	     * rewrite link crossing from the right
	     */
	    *right_hook = x;
	    right_hook = &x->left;
	    x = x->left;
	}			/*else*/
    }				/*while*/

    *left_hook = *right_hook = NIL; /* clear remaining hooks */

}				/*insert*/


/*
 * delete(p)
 *	deletes a node from a cartesian tree. p is the address of
 *	a pointer to the node which is to be deleted.
 *
 * algorithm:
 *	The left and right branches of the node to be deleted define two
 *	subtrees which are to be merged and attached in place of the
 *	deleted node.  Each node on the inside edges of these two
 *	subtrees is examined and longer nodes are placed above the
 *	shorter ones.
 *
 * On entry:
 *	*p is assumed to be non-null.
 */
static void
delete(register Freehdr	*p)
{
    register Freehdr x;
    register Freehdr left_branch; /* left subtree of deleted node */
    register Freehdr right_branch; /* right subtree of deleted node */
    register unsigned left_weight;
    register unsigned right_weight;

    x = *p;
    left_branch = x->left;
    left_weight = weight(left_branch);
    right_branch = x->right;
    right_weight = weight(right_branch);

    while (left_branch != right_branch) {
	/*
	 * iterate until left branch and right branch are
	 * both NIL.
	 */
	if ( left_weight >= right_weight ) {
	    /*
	     * promote the left branch
	     */
	    if (left_branch != NIL) {
		if (left_weight == 0) {
		    /* zero-length block */
		    error("blocksize=0 at %#x\n",
			  (int)left_branch->block->data);
		    break;
		}
		*p = left_branch;
		p = &left_branch->right;
		left_branch = *p;
		left_weight = weight(left_branch);
	    }
	} else {
	    /*
	     * promote the right branch
	     */
	    if (right_branch != NIL) {
		if (right_weight == 0) {
		    /* zero-length block */
		    error("blocksize=0 at %#x\n",
			  (int)right_branch->block->data);
		    break;
		}
		*p = right_branch;
		p = &right_branch->left;
		right_branch = *p;
		right_weight = weight(right_branch);
	    }
	}			/*else*/
    }				/*while*/
    *p = NIL;
    putfreehdr(x);
}				/*delete*/


/*
 * demote(p)
 *	Demotes a node in a cartesian tree, if necessary, to establish
 *	the required vertical ordering.
 *
 * algorithm:
 *	The left and right subtrees of the node to be demoted are to
 *	be partially merged and attached in place of the demoted node.
 *	The nodes on the inside edges of these two subtrees are
 *	examined and the longer nodes are placed above the shorter
 *	ones, until a node is reached which has a length no greater
 *	than that of the node being demoted (or until a null pointer
 *	is reached).  The node is then attached at this point, and
 *	the remaining subtrees (if any) become its descendants.
 *
 * on entry:
 *   a. All the nodes in the tree, including the one to be demoted,
 *	must be correctly ordered horizontally;
 *   b. All the nodes except the one to be demoted must also be
 *	correctly positioned vertically.  The node to be demoted
 *	may be already correctly positioned vertically, or it may
 *	have a length which is less than that of one or both of
 *	its progeny.
 *   c. *p is non-null
 */

static void
demote(register Freehdr	*p)
{
    register Freehdr x;		/* addr of node to be demoted */
    register Freehdr left_branch;
    register Freehdr right_branch;
    register unsigned	left_weight;
    register unsigned	right_weight;
    register unsigned	x_weight;

    x = *p;
    x_weight = weight(x);
    left_branch = x->left;
    right_branch = x->right;
    left_weight = weight(left_branch);
    right_weight = weight(right_branch);

    while (left_weight > x_weight || right_weight > x_weight) {
	/*
	 * select a descendant branch for promotion
	 */
	if (left_weight >= right_weight) {
	    /*
	     * promote the left branch
	     */
	    *p = left_branch;
	    p = &left_branch->right;
	    left_branch = *p;
	    left_weight = weight(left_branch);
	} else {
	    /*
	     * promote the right branch
	     */
	    *p = right_branch;
	    p = &right_branch->left;
	    right_branch = *p;
	    right_weight = weight(right_branch);
	}			/*else*/
    }				/*while*/

    *p = x;			/* attach demoted node here */
    x->left = left_branch;
    x->right = right_branch;

}				/*demote*/


/*
 * malloc_t
 * malloc(nbytes)
 *	Allocates a block of length specified in bytes.  A value of
 *	0 results in a null result.
 *
 * algorithm:
 *	The freelist is searched by descending the tree from the root
 *	so that at each decision point the "better fitting" branch node
 *	is chosen (i.e., the shorter one, if it is long enough, or
 *	the longer one, otherwise).  The descent stops when both
 *	branch nodes are too short.
 *
 * function result:
 *	Malloc returns a pointer to the allocated block. A null
 *	pointer indicates an error.
 *
 * diagnostics:
 *
 *	ENOMEM: storage could not be allocated.
 *
 *	EINVAL: either the argument was invalid, or the heap was found
 *	to be in an inconsistent state.  More detailed information may
 *	be obtained by enabling range checks (cf., malloc_debug()).
 *
 * Note: In this implementation, each allocated block includes a
 *	length word, which occurs before the address seen by the caller.
 *	Allocation requests are rounded up to a multiple of wordsize.
 */

malloc_t
malloc(register size_t	nbytes)
{
    register Freehdr allocp;	/* ptr to node to be allocated */
    register Freehdr *fpp;	/* for tree modifications */
    register Freehdr left_branch;
    register Freehdr right_branch;
    register unsigned	 left_weight;
    register unsigned	 right_weight;
    Dblk	 retblk;	/* block returned to the user */

    /*
     * if rigorous checking was requested, do it.
     */
    if (debug_level >= 2) {
	malloc_verify();
    }

    /*
     * add the size of a block header to the request, and
     * guarantee at least one word of usable data.
     */
    nbytes += sizeof(struct dblk);
    if (nbytes < SMALLEST_BLK) {
	nbytes = SMALLEST_BLK;
    } else {
	nbytes = roundup(nbytes, WORDSIZE);
    }

    /*
     * ensure that at least one block is big enough to satisfy
     *	the request.
     */

    LOG(("a %d\n", nbytes));

    if (weight(_root) <= nbytes) {
	/*
	 * the largest block is not enough.
	 */
	if(!morecore(nbytes)) {
	    /*
	     * malloc_err might have freed stuff up for us to use, so check
	     * again.
	     */
	    if (weight(_root) <= nbytes) {
		return 0;
	    }
	}
    }

    /*
     * search down through the tree until a suitable block is
     *	found.  At each decision point, select the better
     *	fitting node.
     */

    fpp = &_root;
    allocp = *fpp;
    left_branch = allocp->left;
    right_branch = allocp->right;
    left_weight = weight(left_branch);
    right_weight = weight(right_branch);

    while (left_weight >= nbytes || right_weight >= nbytes) {
	if (left_weight <= right_weight) {
	    if (left_weight >= nbytes) {
		fpp = &allocp->left;
		allocp = left_branch;
	    } else {
		fpp = &allocp->right;
		allocp = right_branch;
	    }
	} else {
	    if (right_weight >= nbytes) {
		fpp = &allocp->right;
		allocp = right_branch;
	    } else {
		fpp = &allocp->left;
		allocp = left_branch;
	    }
	}
	left_branch = allocp->left;
	right_branch = allocp->right;
	left_weight = weight(left_branch);
	right_weight = weight(right_branch);
    }				/*while*/

    LOG(("\tuse %#x (%d bytes)\n", allocp->block, allocp->size));

    /*
     * allocate storage from the selected node.
     */

    if (allocp->size - nbytes <= SMALLEST_BLK) {
	/*
	 * not big enough to split; must leave at least
	 * a dblk's worth of space.
	 */
	retblk = allocp->block;
	delete(fpp);
    } else {

	/*
	 * Split the selected block n bytes from the top. The
	 * n bytes at the top are returned to the caller; the
	 * remainder of the block goes back to free space.
	 */
	register Dblk nblk;

	retblk = allocp->block;
	nblk = nextblk(retblk, nbytes);	/* ^next block */
	nblk->size =  allocp->size = retblk->size - nbytes;
#if defined(MEM_TRACE)
	nblk->allocator = (int)malloc;
#endif
	nblk->tag = 0xff;

	__mallinfo.ordblks++;	/* count fragments */

	/*
	 * Change the selected node to point at the newly split
	 * block, and move the node to its proper place in
	 * the free space list.
	 */
	allocp->block = nblk;
	demote(fpp);

	/*
	 * set the length field of the allocated block; we need
	 * this because free() does not specify a length.
	 */
	retblk->size = nbytes;
    }
    /* maintain statistics */
    __mallinfo.uordbytes += retblk->size; /* bytes allocated */
    __mallinfo.allocated++;	/* frags allocated */
    if (nbytes < __mallinfo.mxfast)
	__mallinfo.smblks++;	/* kludge to pass the SVVS */

#if defined(MEM_TRACE)
    retblk->allocator = caller();
#endif /* MEM_TRACE */
    retblk->tag = 0;

    return(retblk->data);

}				/*malloc*/

/*
 * free(p)
 *	return a block to the free space tree.
 *
 * algorithm:
 *	Starting at the root, search for and coalesce free blocks
 *	adjacent to one given.  When the appropriate place in the
 *	tree is found, insert the given block.
 *
 * Some sanity checks to avoid total confusion in the tree.
 *	If the block has already been freed, return.
 *	If the ptr is not from the sbrk'ed space, return.
 *	If the block size is invalid, return.
 */
void
free(malloc_t ptr)
{
    register unsigned 	 nbytes; /* Size of node to be released */
    register Freehdr *fpp;	/* For deletion from free list */
    register Freehdr neighbor;	/* Node to be coalesced */
    register Dblk	 neighbor_blk; /* Ptr to potential neighbor */
    register unsigned	 neighbor_size;	/* Size of potential neighbor */
    register Dblk	 oldblk; /* Ptr to block to be freed */

    /*
     * if rigorous checking was requested, do it.
     */
    if (debug_level >= 2) {
	malloc_verify();
    }

    /*
     * Check the address of the old block.
     */
    if ( misaligned(ptr) ) {
	error("free: illegal address (%#x)\n", ptr);
	return;
    }

    /*
     * Freeing something that wasn't allocated isn't
     * exactly kosher, but fclose() does it routinely.
     */
    if( ptr < _lbound || ptr > _ubound ) {
	errno = EINVAL;
	return;
    }

    /*
     * Get node length by backing up by the size of a header.
     * Check for a valid length.  It must be a positive
     * multiple of WORDSIZE, at least as large as SMALLEST_BLK,
     * no larger than the extent of the heap, and must not
     * extend beyond the end of the heap.
     */
    oldblk = blkhdr(ptr);
    nbytes = oldblk->size;

    LOG(("f %d %#x\n", nbytes, oldblk));

    if (badblksize(oldblk,nbytes)) {
	error("free: bad block size (%d) at %#x\n",
	      (int)nbytes, (int)oldblk );
	return;
    }

    /* maintain statistics */
    __mallinfo.uordbytes -= nbytes; /* bytes allocated */
    __mallinfo.allocated--;	/* frags allocated */

    /*
     * Search the tree for the correct insertion point for this
     *	node, coalescing adjacent free blocks along the way.
     */
    fpp = &_root;
    neighbor = *fpp;
    while (neighbor != NIL) {
	neighbor_blk = neighbor->block;
	neighbor_size = neighbor->size;
	if (oldblk < neighbor_blk) {
	    Dblk nblk = nextblk(oldblk,nbytes);
	    if (nblk == neighbor_blk) {
		/*
		 * Absorb and delete right neighbor
		 */
		nbytes += neighbor_size;
		LOG(("\tmerge %#x (now %d)\n", nblk, nbytes));
		__mallinfo.ordblks--;
		delete(fpp);
	    } else if (nblk > neighbor_blk) {
		/*
		 * The block being freed overlaps
		 * another block in the tree.  This
		 * is bad news.  Return to avoid
		 * further fouling up the the tree.
		 */
		error("free: blocks %#x, %#x overlap\n",
		      (int)oldblk, (int)neighbor_blk);
		return;
	    } else {
		/*
		 * Search to the left
		 */
		fpp = &neighbor->left;
	    }
	} else if (oldblk > neighbor_blk) {
	    Dblk nblk = nextblk(neighbor_blk, neighbor_size);
	    if (nblk == oldblk) {
		/*
		 * These things are necessary (at least, the setting of
		 * ->tag is). The garbage collection code relies on us mangling
		 * the tag to be something unrecognizable or it double-frees
		 * things.
		 */
#if defined(MEM_TRACE)
		oldblk->allocator = caller(); /* Remember who freed it */
#endif /* MEM_TRACE */
		oldblk->tag = -1;
		/*
		 * Absorb and delete left neighbor
		 */

		oldblk = neighbor_blk;
		nbytes += neighbor_size;
		LOG(("\tabsorbed by %#x (now %d)\n", neighbor_blk, nbytes));
		__mallinfo.ordblks--;
		delete(fpp);
	    } else if (nblk > oldblk) {
		/*
		 * This block has already been freed
		 */
		error("free: block %#x was already free\n",
		      (int)ptr);
		return;
	    } else {
		/*
		 * search to the right
		 */
		fpp = &neighbor->right;
	    }
	} else {
	    /*
	     * This block has already been freed
	     * as "oldblk == neighbor_blk"
	     */
	    error("free: block %#x was already free\n", (int)ptr);
	    return;
	}			/*else*/

	/*
	 * Note that this depends on a side effect of
	 * delete(fpp) in order to terminate the loop!
	 */
	neighbor = *fpp;

    }				/*while*/

    /*
     * Insert the new node into the free space tree
     */
    insert( oldblk, nbytes );

#if defined(MEM_TRACE)
    oldblk->allocator = caller(); /* Remember who freed it */
#endif /* MEM_TRACE */
    oldblk->tag = -1;

    return;

}				/*free*/


/*
 * malloc_t
 * shrink(oldblk, oldsize, newsize)
 *
 * Decreases the size of an old block to a new size.
 * Returns the remainder to free space.  Returns the
 * truncated block to the caller
 */

static	malloc_t
shrink(register Dblk	oldblk,
       register unsigned	oldsize,
       register unsigned	newsize)
{
    register Dblk remainder;

    if (oldsize - newsize >= SMALLEST_BLK) {
	/* Block is to be contracted. Split the old block and return the
	 * remainder to free space */
	remainder = nextblk(oldblk, newsize);
	remainder->size = oldsize - newsize;
	oldblk->size = newsize;

	/* maintain statistics */
	__mallinfo.ordblks++;	/* count fragments */
	__mallinfo.allocated++;	/* negate effect of free() */

	free(remainder->data);
    }
    return(oldblk->data);
}


/*
 * *** The following code was pulled out of realloc() ***
 *
 * int
 * reclaim(oldblk, oldsize, flag)
 *	If a block containing 'oldsize' bytes from 'oldblk'
 *	is in the free list, remove it from the free list.
 *	'oldblk' and 'oldsize' are assumed to include the free block header.
 *
 *	Returns 1 if block was successfully removed.
 *	Returns 0 if block was not in free list.
 *	Returns -1 if block spans a free/allocated boundary (error() called
 *						if 'flag' == 1).
 */
static int
reclaim(register Dblk	oldblk,
	unsigned		oldsize,
	int		flag)
{
    register Dblk oldneighbor;
    register Freehdr	*fpp;
    register Freehdr	fp;
    register Dblk		freeblk;
    register unsigned		size;

    /*
     * Search the free space list for a node describing oldblk,
     * or a node describing a block containing oldblk.  Assuming
     * the size of blocks decreases monotonically with depth in
     * the tree, the loop may terminate as soon as a block smaller
     * than oldblk is encountered.
     */

    oldneighbor = nextblk(oldblk, oldsize);

    fpp = &_root;
    fp = *fpp;
    while ( (size = weight(fp)) >= oldsize ) {
	freeblk = fp->block;
	if (badblksize(freeblk,size)) {
	    error("realloc: bad block size (%d) at %#x\n",
		  size, freeblk);
	    return(-1);
	}
	if ( oldblk == freeblk ) {
	    /*
	     * |<-- freeblk ...
	     * _________________________________
	     * |<-- oldblk ...
	     * ---------------------------------
	     * Found oldblk in the free space tree; delete it.
	     */
	    delete(fpp);

	    /* maintain statistics */
	    __mallinfo.uordbytes += oldsize;
	    __mallinfo.allocated++;
	    return(1);
	}
	else if (oldblk < freeblk) {
	    /*
	     * 		|<-- freeblk ...
	     * _________________________________
	     * |<--oldblk ...
	     * ---------------------------------
	     * Search to the left for oldblk
	     */
	    fpp = &fp->left;
	    fp = *fpp;
	}
	else {
	    /*
	     * |<-- freeblk ...
	     * _________________________________
	     * |     		|<--oldblk--->|<--oldneighbor
	     * ---------------------------------
	     * oldblk is somewhere to the right of freeblk.
	     * Check to see if it lies within freeblk.
	     */
	    register Dblk freeneighbor;
	    freeneighbor =  nextblk(freeblk, freeblk->size);
	    if (oldblk >= freeneighbor) {
		/*
		 * |<-- freeblk--->|<--- freeneighbor ...
		 * _________________________________
		 * |  		      |<--oldblk--->|
		 * ---------------------------------
		 * no such luck; search to the right.
		 */
		fpp =  &fp->right;
		fp = *fpp;
	    }
	    else {
		/*
		 * freeblk < oldblk < freeneighbor;
		 * i.e., oldblk begins within freeblk.
		 */
		if (oldneighbor > freeneighbor) {
		    /*
		     * |<-- freeblk--->|<--- freeneighbor
		     * _________________________________
		     * |     |<--oldblk--->|<--oldneighbor
		     * ---------------------------------
		     * oldblk straddles a block boundary!
		     */
		    if (flag) {
			error("realloc: block %#x straddles free block boundary\n", oldblk);
		    }
		    return(-1);
		}
		else if (  oldneighbor == freeneighbor ) {
		    /*
		     * |<-------- freeblk------------->|
		     * _________________________________
		     * |                 |<--oldblk--->|
		     * ---------------------------------
		     * Oldblk is on the right end of
		     * freeblk. Delete freeblk, split
		     * into two fragments, and return
		     * the one on the left to free space.
		     */
		    delete(fpp);

		    /* maintain statistics */
		    __mallinfo.ordblks++;
		    __mallinfo.uordbytes += oldsize;
		    __mallinfo.allocated += 2;

		    freeblk->size -= oldsize;
		    free(freeblk->data);
		    return(1);
		}
		else {
		    /*
		     * |<-------- freeblk------------->|
		     * _________________________________
		     * |        |oldblk  | oldneighbor |
		     * ---------------------------------
		     * Oldblk is in the middle of freeblk.
		     * Delete freeblk, split into three
		     * fragments, and return the ones on
		     * the ends to free space.
		     */
		    delete(fpp);

		    /* maintain statistics */
		    __mallinfo.ordblks += 2;
		    __mallinfo.uordbytes += freeblk->size;
		    __mallinfo.allocated += 3;

		    /*
		     * split the left fragment by
		     * subtracting the size of oldblk
		     * and oldblk's neighbor
		     */
		    freeblk->size -=
			( (malloc_t)freeneighbor
			 - (malloc_t)oldblk );
		    /*
		     * split the right fragment by
		     * setting oldblk's neighbor's size
		     */
		    oldneighbor->size =
			(malloc_t)freeneighbor
			    - (malloc_t)oldneighbor;
		    /*
		     * return the fragments to free space
		     */
		    free(freeblk->data);
		    free(oldneighbor->data);
		    return(1);
		}		/*else*/
	    }			/*else*/
	}			/* else */
    }				/*while*/

    return(0);			/* free block not found */
}

#if defined _MSC_VER || (defined(_MSDOS) && defined(__HIGHC__))
/* Avoid duplicate-symbol errors by defining our own calloc */
malloc_t
calloc(size_t nelem, size_t elsize)
{
    size_t	size = nelem * elsize;
    malloc_t	p = malloc(size);

    if (p != 0) {
	memset(p, 0, size);
    }
    return(p);
}
#endif



/*
 * malloc_t
 * realloc(ptr, nbytes)
 *
 * Reallocate an old block with a new size, returning the old block
 * if possible. The block returned is guaranteed to preserve the
 * contents of the old block up to min(size(old block), newsize).
 *
 * For backwards compatibility, ptr is allowed to reference
 * a block freed since the LAST call of malloc().  Thus the old
 * block may be busy, free, or may even be nested within a free
 * block.
 *
 * Some old programs have been known to do things like the following,
 * which is guaranteed not to work:
 *
 *	free(ptr);
 *	free(dummy);
 *	dummy = malloc(1);
 *	ptr = realloc(ptr,nbytes);
 *
 * This atrocity was found in the source for diff(1).
 */
malloc_t
realloc(malloc_t ptr,
	size_t nbytes)
{
    register Freehdr *fpp;
    register Freehdr fp;
    register Dblk	oldblk;
    register Dblk	freeblk;
    register Dblk	oldneighbor;
    register unsigned	oldsize;
    register unsigned	newsize;
    register unsigned	oldneighborsize;

#ifdef __BORLANDC__
    /*
     * Sigh...  Borland's realloc() acts like malloc() if ptr is passed in
     * as NULL.  Borland's startup code relies on this behavior!
     */
    if (ptr == NULL) {
	return malloc(nbytes);
    }
#endif


    /*
     * if rigorous checking was requested, do it.
     */
    if (debug_level >= 2) {
	malloc_verify();
    }

    /*
     * Check the address of the old block.
     */
    if ( misaligned(ptr) || ptr < _lbound || ptr > _ubound ) {
	error("realloc: illegal address (%#x)\n", ptr);
	return(NULL);
    }

    /*
     * check location and size of the old block and its
     * neighboring block to the right.  If the old block is
     * at end of memory, the neighboring block is undefined.
     */
    oldblk = blkhdr(ptr);
    oldsize = oldblk->size;
    if (badblksize(oldblk,oldsize)) {
	error("realloc: bad block size (%d) at %#x\n",
	      oldsize, oldblk);
	return(NULL);
    }
    oldneighbor = nextblk(oldblk,oldsize);

    /* *** tree search code pulled into separate subroutine *** */
    if (reclaim(oldblk, oldsize, 1) == -1) {
	return(NULL);		/* internal error */
    }

    /*
     * At this point, we can guarantee that oldblk is out of free
     * space. What we do next depends on a comparison of the size
     * of the old block and the requested new block size.  To do
     * this, first round up the new size request.
     */
    newsize = nbytes + sizeof(struct dblk); /* add size of a length word */
    if (newsize < SMALLEST_BLK) {
	newsize = SMALLEST_BLK;
    } else {
	newsize = roundup(newsize, WORDSIZE);
    }

    LOG(("r %#x from %d to %d\n", oldblk, oldblk->size, newsize));

    /*
     * Next, examine the size of the old block, and compare it
     * with the requested new size.
     */

    if (oldsize >= newsize) {
	/*
	 * Block is to be made smaller.
	 */
	LOG(("\tshrink it\n"));
	return(shrink(oldblk, oldsize, newsize));
    }

    /*
     * Block is to be expanded.  Look for adjacent free memory.
     */
    if ( oldneighbor < (Dblk)_ubound ) {
	/*
	 * Search for the adjacent block in the free
	 * space tree.  Note that the tree may have been
	 * modified in the earlier loop.
	 */
	fpp = &_root;
	fp = *fpp;
	oldneighborsize = oldneighbor->size;
	if ( badblksize(oldneighbor, oldneighborsize) ) {
	    error("realloc: bad blocksize(%d) at %#x\n",
		  oldneighborsize, oldneighbor);
	    return(NULL);
	}
	/*
	 * Assume the neighbor is free and see if it is big enough to
	 * join with the existing block to satisfy the request.
	 */
	if (oldsize + oldneighborsize >= newsize) {
	    /*
	     * It is. *now* see if the neighbor is free. We keep working down
	     * the tree until we find oldneighbor or we reach a node that's
	     * smaller than the old neighbor, which means the old neighbor
	     * can't possibly be in the tree, it being cartesian and all.
	     */
	    while (weight(fp) >= oldneighborsize ) {
		freeblk = fp->block;
		if (oldneighbor < freeblk) {
		    /*
		     * search to the left
		     */
		    fpp = &(fp->left);
		    fp = *fpp;
		}
		else if (oldneighbor > freeblk) {
		    /*
		     * search to the right
		     */
		    fpp = &(fp->right);
		    fp = *fpp;
		}
		else {		/* oldneighbor == freeblk */
		    /*
		     * neighboring block is free and we know it's big enough
		     * Delete freeblk, join oldblk to neighbor, return
		     * newsize bytes to the caller, and return the
		     * remainder to free storage.
		     */
		    delete(fpp);

		    LOG(("\texpand into %#x (%d bytes)\n", oldneighbor,
			 oldneighborsize));

		    /* maintain statistics */
		    __mallinfo.ordblks--;
		    __mallinfo.uordbytes += oldneighborsize;

		    oldsize += oldneighborsize;
		    oldblk->size = oldsize;
		    return(shrink(oldblk, oldsize, newsize));
		}			/*else*/
	    }			/*while*/
	}   	    	    	/*if*/
    }				/*if*/

    /*
     * At this point, we know there is no free space in which to
     * expand. Malloc a new block, copy the old block to the new,
     * and free the old block, IN THAT ORDER.
     */
    ptr = malloc(nbytes);
    if (ptr != NULL) {
	Dblk	tblk = blkhdr(ptr);

#if defined(MEM_TRACE)
	tblk->allocator = caller();
#endif /* MEM_TRACE */
	tblk->tag = oldblk->tag;
	bcopy(oldblk->data, ptr, oldsize - offsetof(struct dblk, data));
	free(oldblk->data);
#if defined(MEM_TRACE)
	oldblk->allocator = caller();
#endif /* MEM_TRACE */
	LOG(("\talloc new: %#x\n", tblk));
    }
    return(ptr);

}				/* realloc */


#if 0
/*
 * malloc_t
 * _malloc_at_addr(addr, nbytes)
 *	Allocate an 'nbyte' segment ONLY if it can be obtained at 'addr'.
 *
 *	Returns NULL if this is not possible.  Otherwise, returns 'addr'.
 *
 *	*** INCLUDED FOR SUN RELEASE 3.x SHARED-MEMORY ***
 */
malloc_t
_malloc_at_addr(malloc_t	addr,
		register unsigned	nbytes)
{
    register Dblk blk;
    register malloc_t end;
    register int save_level;

    if (debug_level >= 2) {
	malloc_verify();
    }

    blk = blkhdr(addr);
    nbytes += sizeof(struct dblk);
    nbytes = roundup(nbytes, WORDSIZE);

    if (misaligned(blk) || ((malloc_t)blk < _lbound)) {
	return(NULL);
    }

    end = (malloc_t)blk + nbytes;
    if (end > _ubound) {
	if (!morecore(end - _ubound)) {
	    return(NULL);
	}
    }

    /*
     * reclaim() calls free() when reclaiming a block in the middle
     * of a free block.  If the block size field of the reclaimed
     * block is invalid, malloc_verify() will crash.  Since we don't
     * know, yet, the state of things, we can't go scribbling the
     * size in until the block has been reclaimed.  So turn off
     * debugging during the reclaim() call and turn it back on after.
     */
    save_level = debug_level;
    (void) malloc_debug(0);	/* turn off debug during reclaim */

    /* try to pull this segment off of the free list */
    /* the 3rd arg suppresses the error if part of the block is allocated */
    if (reclaim(blk, nbytes, 0) != 1) {
	return(NULL);
    }
    blk->size = nbytes;		/* fill in the block size */
#if defined(MEM_TRACE)
    blk->allocator = caller();
#endif /* MEM_TRACE */
    blk->tag = 0;

    (void) malloc_debug(save_level); /* restore debugging */
    if (debug_level >= 2) {
	malloc_verify();
    }

    return(blk->data);
}

#endif /* 0 */

/*
 * bool
 * morecore(nbytes)
 *	Add a block of at least nbytes from end-of-memory to the
 *	free space tree.
 *
 * return value:
 *	true	if at least n bytes can be allocated
 *	false	otherwise
 *
 * remarks:
 *
 *   -- free space (delimited by the extern variable _ubound) is
 *	extended by an amount determined by rounding nbytes up to
 *	a multiple of the system page size.
 *
 *   -- The lower bound of the heap is determined the first time
 *	this routine is entered. It does NOT necessarily begin at
 *	the end of static data space, since startup code (e.g., for
 *	profiling) may have invoked sbrk() before we got here.
 */

static char *oom = "Virtual memory exhausted\n";

static bool
morecore(unsigned	nbytes)
{
    Dblk p;

    if (nbpg == 0)
	nbpg = getpagesize();
    nbytes = roundup(nbytes, nbpg);
    LOG(("\tmorecore(%d)\n", nbytes));

    p = (Dblk) sbrk((int)nbytes);
    if (p == (Dblk) -1) {
	if (noerr) {
	    malloc_err(1, oom, strlen(oom));
	}
	return(false);		/* errno = ENOMEM */
    }
    if (_lbound == NULL)	/* set _lbound the first time through */
	_lbound = (malloc_t) p;
    _ubound = (malloc_t) p + nbytes;
    p->size = nbytes;
#if defined(MEM_TRACE)
    p->allocator=0;
#endif /* MEM_TRACE */
    p->tag = 0;

    /* maintain statistics */
    __mallinfo.arena = _ubound - _lbound;
    __mallinfo.uordbytes += nbytes;
    __mallinfo.ordblks++;
    __mallinfo.allocated++;

    free(p->data);
    return(true);

}				/*morecore*/


/*
 * Get a free block header from the free header list.
 * When the list is empty, allocate an array of headers.
 * When the array is empty, allocate another one.
 * When we can't allocate another array, we're in deep weeds.
 */
static	Freehdr
getfreehdr(int allowgc)
{
    Freehdr	r;
    register Dblk	blk;
    register unsigned	size;

    if (freehdrlist != NIL) {
	r = freehdrlist;
	freehdrlist = freehdrlist->left;
	return(r);
    }
    if (nfreehdrs <= 0) {
	size = NFREE_HDRS*sizeof(struct freehdr) + sizeof(struct dblk);
	blk = (Dblk) sbrk(size);
	if ((int)blk == -1) {
	    if (noerr) {
		malloc_err(1, oom, strlen(oom));
		if (allowgc) {
		    return getfreehdr(0);
		}
	    }
	    malloc_debug(1);
	    error("getfreehdr: out of memory");
	    /* NOTREACHED */
	}

	if (_lbound == NULL)	/* set _lbound on first allocation */
	    _lbound = (malloc_t)blk;
	blk->size = size;
	freehdrptr = (Freehdr)blk->data;
	nfreehdrs = NFREE_HDRS;
	_ubound = (malloc_t) nextblk(blk,size);

	/* maintain statistics */
	__mallinfo.arena = _ubound - _lbound;
	__mallinfo.treeoverhead += size;
    }
    nfreehdrs--;
    return(freehdrptr++);
}

/*
 * Free a free block header
 * Add it to the list of available headers.
 */
static void
putfreehdr(Freehdr  p)
{
    p->left = freehdrlist;
    freehdrlist = p;
}


/***********************************************************************
 *				malloc_tagged
 ***********************************************************************
 * SYNOPSIS:	    Allocate memory with a given tag.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The block
 * SIDE EFFECTS:    The tag for the block is set.
 *
 * STRATEGY:	    Call malloc, then set allocator and tag properly
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
malloc_t
malloc_tagged(size_t nbytes, unsigned tag)
{
    malloc_t	result;
    Dblk    p;

    result = malloc(nbytes);
    if (result != 0) {
	p = blkhdr(result);
	p->tag = tag;
#if defined(MEM_TRACE)
	p->allocator = caller();
#endif /* MEM_TRACE */
    }
    return(result);
}

/***********************************************************************
 *				calloc_tagged
 ***********************************************************************
 * SYNOPSIS:	    Allocate a zero-filled array of things of a type.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The array
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
malloc_t
calloc_tagged(size_t 	elsize,
	      unsigned	nel,
	      unsigned	tag)
{
    malloc_t result;
    Dblk    p;

    result = calloc(elsize, nel);
    if (result != 0) {
	p = blkhdr(result);
	p->tag = tag;
#if defined(MEM_TRACE)
	p->allocator = caller();
#endif /* MEM_TRACE */
    }

    return(result);
}

/***********************************************************************
 *				malloc_tag
 ***********************************************************************
 * SYNOPSIS:	    Return the tag for a block of data.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The 8-bit tag.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
unsigned
malloc_tag(malloc_t ptr)
{
    Dblk    p;

    if (ptr < _lbound || ptr > _ubound) {
	return (0);
    } else {
	p = blkhdr(ptr);
	return(p->tag);
    }
}

/***********************************************************************
 *				malloc_size
 ***********************************************************************
 * SYNOPSIS:	    Return the size for a block of data.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The allocated size, or 0 if the pointer is outside
 *		    the heap.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
unsigned
malloc_size(malloc_t ptr)
{
    Dblk    p;

    if (ptr < _lbound || ptr > _ubound) {
	return (0);
    } else {
	p = blkhdr(ptr);
	return(p->size - sizeof(*p));
    }
}

#if defined(_WIN32)
/* Define _msize() as alias for malloc_size(). Some RTL functions, like
   atexit(), use the malloc'esque routines for memory management. If they
   link against our home-brow malloc(), they should also request the size
   in an appropriate way... */
unsigned _msize(void *blk) { return malloc_size(blk); }
#endif


/***********************************************************************
 *				malloc_settag
 ***********************************************************************
 * SYNOPSIS:	    Set the tag for a block of data.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The tag is altered
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
void
malloc_settag(malloc_t ptr,
	      unsigned	tag)
{
    Dblk    p;

    if (ptr >= _lbound && ptr < _ubound) {
	p = blkhdr(ptr);
	p->tag = tag;
    }
}


/***********************************************************************
 *				malloc_noerr
 ***********************************************************************
 * SYNOPSIS:	    Set the noerr flag. If noerr is true, malloc et al
 *		    will never return NULL when they cannot allocate
 *		    more memory from the system. Instead, they will print
 *		    a message and exit.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    noerr is altered.
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
void
malloc_noerr(int value)
{
    noerr = value;
}

#if !defined(DEBUG)

/*
 * stubs for error handling and diagnosis routines. These are what
 * you get in the standard C library; for non-placebo diagnostics
 * load /usr/lib/malloc.debug.o with your program.
 */
/*ARGSUSED*/
static void
error(char *fmt, ...)
{
    errno = EINVAL;
}

#undef malloc_debug

int
malloc_debug(int level) { return (0); }

#endif	/*!DEBUG	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


#if defined(DEBUG) || defined(MEM_LOG)
#endif

#if defined(DEBUG)

/*
 * malloc_debug(level)
 *
 * description:
 *
 *	Controls the level of error diagnosis and consistency checking
 *	done by malloc() and free(). level is interpreted as follows:
 *
 *	0:  malloc() and free() return 0 if error detected in arguments
 *	    (errno is set to EINVAL)
 *	1:  malloc() and free() abort if errors detected in arguments
 *	2:  same as 1, but scan entire heap for errors on every call
 *	    to malloc() or free()
 *
 * function result:
 *	returns the previous level of error reporting.
 */
int
malloc_debug(int    level)
{
    int old_level;
    old_level = debug_level;
    debug_level = level;
    return old_level;
}

/*
 * check a free space tree pointer. Should be in
 * the static free pool or somewhere in the heap.
 */

#define chkhdr(p)\
	if ( misaligned(p)\
		|| (((p) < free_pool || (p) >= free_pool+NFREE_HDRS)\
		&& ((p) < (Freehdr) _lbound || (p) >= (Freehdr) _ubound))) {\
		hdrerror(p);\
		return 0;\
	}

#define chkblk(p)\
	if ( misaligned(p)\
		|| ((Dblk)(p) < (Dblk)_lbound || (Dblk)(p) > (Dblk)_ubound)){\
		blkerror(p);\
		return 0;\
	}

static void
hdrerror(Freehdr    p)
{
    error("Bad free list pointer (%#x)\n", (p));
}

static void
blkerror(Dblk    p)
{
    error("Illegal block address (%#x)\n", (p));
}

/*
 * cartesian(p)
 *	returns 1 if free space tree p satisfies internal consistency
 *	checks.
 */

static int
cartesian(register Freehdr  p)
{
    register Freehdr probe;
    register Dblk db,pdb;

    if (p == NIL)		/* no tree to test */
	return 1;
    /*
     * check that root has a data block
     */
    chkhdr(p);
    pdb = p->block;
    chkblk(pdb);

    /*
     * check that the child blocks are no larger than the parent block.
     */
    probe = p->left;
    if (probe != NIL) {
	chkhdr(probe);
	db = probe->block;
	chkblk(db);
	if (probe->size > p->size) /* child larger than parent */
	    return 0;
    }
    probe = p->right;
    if (probe != NIL) {
	chkhdr(probe);
	db = probe->block;
	chkblk(db);
	if (probe->size > p->size) /* child larger than parent */
	    return 0;
    }
    /*
     * test data addresses in the left subtree,
     * starting at the left subroot and probing to
     * the right.  All data addresses must be < p->block.
     */
    probe = p->left;
    while (probe != NIL) {
	chkhdr(probe);
	db = probe->block;
	chkblk(db);
	if ( nextblk(db, probe->size) >= pdb ) /* overlap */
	    return 0;
	probe = probe->right;
    }
    /*
     * test data addresses in the right subtree,
     * starting at the right subroot and probing to
     * the left.  All addresses must be > nextblk(p->block).
     */
    pdb = nextblk(pdb, p->size);
    probe = p->right;
    while (probe != NIL) {
	chkhdr(probe);
	db = probe->block;
	chkblk(db);
	if (db == NULL || db <= pdb) /* overlap */
	    return 0;
	probe = probe->left;
    }
    return (cartesian(p->left) && cartesian(p->right));
}

/*
 * malloc_findhdr(p)
 *
 * Attempts to find the header for the given block.
 */
Freehdr
malloc_findhdr(register Dblk	p)
{
    register Freehdr	fp;

    fp = _root;
    while (fp != NIL) {
	if (fp->block == p) {
	    break;
	} else if (fp->block < p) {
	    fp = fp->right;
	} else {
	    fp = fp->left;
	}
    }
    return(fp);
}

/*
 * malloc_verify()
 *
 * This is a verification routine.  It walks through all blocks
 * in the heap (both free and busy) and checks for bad blocks.
 * malloc_verify returns 1 if the heap contains no detectably bad
 * blocks; otherwise it returns 0.
 */

int
malloc_verify(void)
{
	register int	maxsize;
	register int	size;
	register Dblk	p;
	register Dblk	prevP;
	Freehdr		fp;
	unsigned	lb,ub;
#if defined(_MSDOS)
	MS_PSP _far	*psp;

	FP_SET(psp, 0, SS_PSP);
#elif defined(sun) || defined(isi)
	extern  char	end[];
#endif

	if (_lbound == NULL)	/* no allocation yet */
		return 1;

	/*
	 * first check heap bounds pointers
	 */
#if defined(sun) || defined(isi) || defined(_WIN32)
	lb = (unsigned)end;
#elif defined(_MSDOS)
	lb = (unsigned)psp->data_size;
#endif

	ub = (unsigned)sbrk(0);

	if ((unsigned)_lbound < lb || (unsigned)_lbound > ub) {
		error("malloc_verify: illegal heap lower bound (%#x)\n",
			_lbound);
		return 0;
	}
	if ((unsigned)_ubound < lb || (unsigned)_ubound > ub) {
		error("malloc_verify: illegal heap upper bound (%#x)\n",
			_ubound);
		return 0;
	}
	maxsize = heapsize();
	p = (Dblk)_lbound;
	prevP = (Dblk)NULL;
	while (p < (Dblk) _ubound) {
	    size = p->size;
	    if ( (size) < SMALLEST_BLK
		|| (size) & (WORDSIZE-1)
		|| (size) > heapsize()
		|| ((malloc_t)(p))+(size) > _ubound ) {
		    fp = malloc_findhdr(p);
		    if (fp != NIL) {
#if defined(MEM_TRACE)
			error("malloc_verify: bad free block size (%d) at %#x (prev = %#x [%#x]) s/b %d\n",
			      size, p, prevP, prevP->allocator, fp->size);
#else
			error("malloc_verify: bad free block size (%d) at %#x (prev = %#x) s/b %d\n",
			      size, p, prevP, fp->size);
#endif /* MEM_TRACE */
		    } else {
#if defined(MEM_TRACE)
			error("malloc_verify: bad busy block size (%d) at %#x (prev = %#x [%#x])\n",
			      size, p, prevP, prevP->allocator);
#else
			error("malloc_verify: bad busy block size (%d) at %#x (prev = %#x)\n",
			      size, p, prevP);
#endif /* MEM_TRACE */
		    }
		    return(0);	/* Badness */
		}
	    prevP = p;
	    p = nextblk(p, size);
	}
	if (p > (Dblk) _ubound) {
		error("malloc_verify: heap corrupted\n");
		return(0);
	}
	if (!cartesian(_root)){
		error("malloc_verify: free space tree corrupted\n");
		return(0);
	}
	return(1);
}

/*
 * Error routine.
 * If debug_level == 0, does nothing except set errno = EINVAL.
 * Otherwise, prints an error message to stderr and generates a
 * core image.
 */

/*
 * The following is a kludge to avoid dependency on stdio, which
 * uses malloc() and free(), one of which probably got us here in
 * the first place.
 */

/*VARARGS2*/
static int
sprintf_internal(char *string,
		 char *fmt,
		 ...)
{
    va_list args;
    register char *buf = string;
    register char c;

    va_start(args, fmt);

    while ((c = *fmt++) != '\0') {
	if (c != '%') {
	    *buf++ = c;
	} else {
	    /*
	     * print formatted argument
	     */
	    register unsigned x;
	    unsigned short radix;
	    char prbuf[12];
	    register char *cp;

	    x = va_arg(args, unsigned);

	    switch( c = *fmt++ ) {
		case 'd':
		    radix = 10;
		    if ((int)x < 0) {
			*buf++ = '-';
			x = (unsigned)(-(int)x);
		    }
		    break;
		case '#':
		    c = *fmt++;
		    if (c == 'x') {
			*buf++ = '0';
			*buf++ = c;
		    }
		    /*FALL THROUGH*/
		case 'x':
		    radix = 16;
		    break;
		default:
		    *buf++ = c;
		    continue;
	    }			/*switch*/

	    cp = prbuf;
	    do {
		*cp++ = "0123456789abcdef"[x%radix];
		x /= radix;
	    } while(x);
	    do {
		*buf++ = *--cp;
	    } while(cp > prbuf);
	}			/*if*/
    }				/*while*/

    va_end(args);

    *buf = '\0';
    return(buf - string);

}				/*sprintf_internal*/

#define	LBUFSIZ	256

static	char	stderrbuf[LBUFSIZ];

/*VARARGS1*/
static void
error(char *fmt, ...)
{
    va_list args;

    static n = 0;	/* prevents infinite recursion when using stdio */
    register int nbytes;

    va_start(args, fmt);

    errno = EINVAL;
    if (debug_level == 0)
	return;
    if (!n++) {
	nbytes = sprintf_internal(stderrbuf, fmt, args);
	stderrbuf[nbytes++] = '\n';
	stderrbuf[nbytes] = '\0';
	malloc_err(0, stderrbuf, nbytes);
    }

    va_end(argPtr);

    abort();
}

#endif	/*DEBUG		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


/***********************************************************************
 *				malloc_printstats
 ***********************************************************************
 * SYNOPSIS:	    Print out heap-usage statistics
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Output is routed through the given procedure
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
int
malloc_printstats(malloc_printstats_callback *printFunc, void *data)
{
    register int	size;
    register Dblk	p;
    Freehdr		fp;
    int	    	    	freeblks, busyblks, freesize, busysize;

    if (_lbound == NULL)	/* no allocation yet */
	return 1;

    freeblks = busyblks = freesize = busysize = 0;
    p = (Dblk)_lbound;
    while (p < (Dblk) _ubound) {
	size = p->size;
#if !defined(DEBUG)
	fp = (Freehdr)(p->tag == 0xff);
#else
	fp = malloc_findhdr(p);
#endif
	if (fp != NIL) {
#if defined(MEM_TRACE)
            (*printFunc)(data, "%#x %d bytes free by %#x\n",
                         p->data, size, p->allocator);
#else
            (*printFunc)(data, "%#x %d bytes free\n", p->data, size);
#endif /* MEM_TRACE */
	    freeblks++; freesize += size;
	} else {
	    busyblks++; busysize += size;
#if defined(MEM_TRACE)
	    (*printFunc)(data, "%#x %d bytes type %d by %#x\n",
			 p->data, size, p->tag, p->allocator);
#else
	    (*printFunc)(data, "%#x %d bytes type %d\n",
			 p->data, size, p->tag);
#endif /* MEM_TRACE */
	}
	p = nextblk(p, size);
    }
    (*printFunc)(data, "%d bytes free in %d blocks\n", freesize, freeblks);
    (*printFunc)(data, "%d bytes used in %d blocks\n", busysize, busyblks);
    (*printFunc)(data, "%d bytes for free tree\n", __mallinfo.treeoverhead);
    (*printFunc)(data, "%d small blocks: %d free, %d in use\n",
		 __mallinfo.smblks, __mallinfo.fsmblks, __mallinfo.usmblks);
    (*printFunc)(data, "%d ordinary blocks: %d free, %d in use\n",
		 __mallinfo.ordblks, __mallinfo.fordblks, __mallinfo.uordblks);
    (*printFunc)(data, "%d holding blocks using %d bytes\n",
		 __mallinfo.hblks, __mallinfo.hblkhd);
    (*printFunc)(data, "%d bytes total block overhead\n",
		 (busyblks + freeblks)*offsetof(struct dblk, data));
    return(1);
}


/***********************************************************************
 *				shrinkheap
 ***********************************************************************
 * SYNOPSIS:	    Releases as much memory back to the system as
 *	    	    possible. Often, this won't be much, but...
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Number of bytes remaining in the heap.
 * SIDE EFFECTS:    _ubound may be shrunk and nodes deleted from the free
 *	    	    tree.
 *
 * STRATEGY:	    Since the addresses of elements in the tree increase
 *	    	    to the right, and blocks are always coalesced when
 *	    	    possible, we simply go as far right as we can and
 *	    	    set the brk back to the closest page above the block's
 *	    	    bottom, then re-free the remaining memory.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/89		Initial Revision
 *
 ***********************************************************************/
int
shrinkheap(void)
{
    Freehdr hp, *hpp;

    hpp = &_root;
    hp = _root;

    if (!hp) {
	return(0);
    }

    while (hp->right) {
	hpp = &hp->right;
	hp = hp->right;
    }

    if ((malloc_t)nextblk(hp->block,hp->size) == _ubound) {
	/*
	 * Final block is at the end of memory. Good. See if we can reduce
	 * it a page or more...
	 */
	malloc_t p = (malloc_t)roundup((int)hp->block,nbpg);
	Dblk	b;
	int 	size;

	if (p < _ubound) {
	    /*
	     * We can release some memory, since rounding the block's start
	     * up to the next page does not just give us the upper bound
	     * of the heap. First alter the size of the block we're shrinking.
	     */
	    b = hp->block;
	    delete(hpp);
	    /*
	     * Release all the memory between p and _ubound.
	     */
	    sbrk(p - _ubound);
	    _ubound = p;
	    __mallinfo.arena = _ubound - _lbound;
	    /*
	     * Free whatever's left, modifiying the size of the block to
	     * match reality.
	     */
	    size = p - (malloc_t)b;
	    if (size >= SMALLEST_BLK) {
		b->size = size;
		free(b->data);
	    }
	}
    }
    /*
     * Return the number of bytes still in the arena.
     */
    return(__mallinfo.arena);
}
