/*	@(#)malloc.h 1.4 89/06/25 SMI; from include/malloc.h 1.5	*/
/*	$Id: malloc.h,v 1.4 96/05/20 18:56:44 dbaumann Exp $	*/

#ifndef	__malloc_h
#define	__malloc_h
#include <stddef.h>
/*
 *	Constants defining mallopt operations
 */
#define	M_MXFAST	1	/* set size of 'small blocks' */
#define	M_NLBLKS	2	/* set num of small blocks in holding block */
#define	M_GRAIN		3	/* set rounding factor for small blocks */
#define	M_KEEP		4	/* (nop) retain contents of freed blocks */

/*
 *	malloc information structure
 */
struct	mallinfo  {
	int arena;	/* total space in arena */
	int ordblks;	/* number of ordinary blocks */
	int smblks;	/* number of small blocks */
	int hblks;	/* number of holding blocks */
	int hblkhd;	/* space in holding block headers */
	int usmblks;	/* space in small blocks in use */
	int fsmblks;	/* space in free small blocks */
	int uordblks;	/* space in ordinary blocks in use */
	int fordblks;	/* space in free ordinary blocks */
	int keepcost;	/* cost of enabling keep option */

	int mxfast;	/* max size of small blocks */
	int nlblks;	/* number of small blocks in a holding block */
	int grain;	/* small block rounding factor */
	int uordbytes;	/* space (including overhead) allocated in ord. blks */
	int allocated;	/* number of ordinary blocks allocated */
	int treeoverhead;	/* bytes used in maintaining the free tree */
};

#if defined(__HIGHC__) || defined(__BORLANDC__) || defined(__WATCOMC__)
typedef char    *malloc_t;
#else
typedef	void 	*malloc_t;
#endif

extern	malloc_t	calloc(size_t, size_t);
extern	int		free(malloc_t);
extern	malloc_t	malloc(size_t size);
extern	malloc_t	realloc(malloc_t, size_t);
#define realloc_tagged(p,s) realloc((p), (s))
extern	int		mallopt();
extern	struct mallinfo mallinfo();

extern malloc_t	malloc_tagged(size_t nbytes, unsigned tag);
extern malloc_t	calloc_tagged(size_t elsize, unsigned nel, unsigned tag);
extern unsigned	malloc_tag(malloc_t ptr);
extern void 	malloc_settag(malloc_t ptr, unsigned tag);
#ifndef __HIGHC__
extern unsigned malloc_size(malloc_t  ptr);
#endif

typedef	void malloc_printstats_callback(void *, const char *, ...);
extern int  	malloc_printstats(malloc_printstats_callback *printFunc,
				  void *data);
extern int	shrinkheap(void);
#endif	/* !__malloc_h */
