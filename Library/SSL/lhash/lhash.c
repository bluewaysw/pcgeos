/* crypto/lhash/lhash.c */
/* Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@cryptsoft.com).
 * The implementation was written so as to conform with Netscapes SSL.
 * 
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to.  The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code.  The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@cryptsoft.com).
 * 
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@cryptsoft.com)"
 *    The word 'cryptographic' can be left out if the rouines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from 
 *    the apps directory (application code) you must include an acknowledgement:
 *    "This product includes software written by Tim Hudson (tjh@cryptsoft.com)"
 * 
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * The licence and distribution terms for any publically available version or
 * derivative of this code cannot be changed.  i.e. this code cannot simply be
 * copied and put under another distribution licence
 * [including the GNU Public Licence.]
 */
#ifndef COMPILE_OPTION_HOST_SERVICE_ONLY


#ifndef GEOS_CLIENT
char *lh_version="lhash part of SSLeay 0.9.0b 29-Jun-1998";
#endif

/* Code for dynamic hash table routines
 * Author - Eric Young v 2.0
 *
 * 2.0 eay - Fixed a bug that occured when using lh_delete
 *	     from inside lh_doall().  As entries were deleted,
 *	     the 'table' was 'contract()ed', making some entries
 *	     jump from the end of the table to the start, there by
 *	     skiping the lh_doall() processing. eay - 4/12/95
 *
 * 1.9 eay - Fixed a memory leak in lh_free, the LHASH_NODEs
 *	     were not being free()ed. 21/11/95
 *
 * 1.8 eay - Put the stats routines into a separate file, lh_stats.c
 *	     19/09/95
 *
 * 1.7 eay - Removed the fputs() for realloc failures - the code
 *           should silently tolerate them.  I have also fixed things
 *           lint complained about 04/05/95
 *
 * 1.6 eay - Fixed an invalid pointers in contract/expand 27/07/92
 *
 * 1.5 eay - Fixed a misuse of realloc in expand 02/03/1992
 *
 * 1.4 eay - Fixed lh_doall so the function can call lh_delete 28/05/91
 *
 * 1.3 eay - Fixed a few lint problems 19/3/1991
 *
 * 1.2 eay - Fixed lh_doall problem 13/3/1991
 *
 * 1.1 eay - Added lh_doall
 *
 * 1.0 eay - First version
 */
#ifdef __GEOS__
#include <Ansi/stdio.h>
#else
#include <stdio.h>
#endif
#ifdef __GEOS__
#include <Ansi/string.h>
#else
#include <string.h>
#endif
#ifdef __GEOS__
#include <Ansi/stdlib.h>
#else
#include <stdlib.h>
#endif
#include "lhash.h"

#ifdef __GEOS__
#  ifdef COMPILE_OPTION_MAP_HEAP
#    include <MapHeap.h>
void *MapMalloc(word newSize);
void *MapRealloc(void *blockPtr, word newSize);
void MapFree(void *blockPtr);
#    define Malloc(blockSize)		MapMalloc(blockSize)
#    define Realloc(blockPtr, newSize)		MapRealloc(blockPtr, newSize)
#    define Free(blockPtr)					MapFree(blockPtr)
#  else
#    define Malloc(blockSize)		_Malloc(blockSize,GeodeGetCodeProcessHandle(),0)
#    define Realloc(blockPtr,newSize)	_ReAlloc(blockPtr,newSize,GeodeGetCodeProcessHandle())
#    define Free(blockPtr)			_Free(blockPtr,GeodeGetCodeProcessHandle())
#  endif
#endif

#undef MIN_NODES 
#define MIN_NODES	16
#define UP_LOAD		(2*LH_LOAD_MULT) /* load times 256  (default 2) */
#define DOWN_LOAD	(LH_LOAD_MULT)   /* load times 256  (default 1) */

#ifndef NOPROTO

#define P_CP	char *
#define P_CPP	char *,char *
static void expand(LHASH *lh);
static void contract(LHASH *lh);
static LHASH_NODE **getrn(LHASH *lh, char *data, unsigned long *rhash);

#else

#define	P_CP
#define P_CPP
static void expand();
static void contract();
static LHASH_NODE **getrn();

#endif

#ifdef __GEOS__
LHASH *lh_new(unsigned long (*h)(), int (*c)())
#else
LHASH *lh_new(h, c)
unsigned long (*h)();
int (*c)();
#endif
	{
	LHASH *ret;
	int i;

#ifdef __GEOS__
	if ((ret=(LHASH *)Malloc(sizeof(LHASH))) == NULL)
#else
	if ((ret=(LHASH *)malloc(sizeof(LHASH))) == NULL)
#endif
		goto err0;
#ifdef __GEOS__
	if ((ret->b=(LHASH_NODE **)Malloc(sizeof(LHASH_NODE *)*MIN_NODES)) == NULL)
#else
	if ((ret->b=(LHASH_NODE **)malloc(sizeof(LHASH_NODE *)*MIN_NODES)) == NULL)
#endif
		goto err1;
	for (i=0; i<MIN_NODES; i++)
		ret->b[i]=NULL;
	ret->comp=((c == NULL)?(int (*)())strcmp:c);
	ret->hash=((h == NULL)?(unsigned long (*)())lh_strhash:h);
	ret->num_nodes=MIN_NODES/2;
	ret->num_alloc_nodes=MIN_NODES;
	ret->p=0;
	ret->pmax=MIN_NODES/2;
	ret->up_load=UP_LOAD;
	ret->down_load=DOWN_LOAD;
	ret->num_items=0;

	ret->num_expands=0;
	ret->num_expand_reallocs=0;
	ret->num_contracts=0;
	ret->num_contract_reallocs=0;
	ret->num_hash_calls=0;
	ret->num_comp_calls=0;
	ret->num_insert=0;
	ret->num_replace=0;
	ret->num_delete=0;
	ret->num_no_delete=0;
	ret->num_retrieve=0;
	ret->num_retrieve_miss=0;
	ret->num_hash_comps=0;

	return(ret);
err1:
#ifdef __GEOS__
	Free((char *)ret);
#else
	free((char *)ret);
#endif
err0:
	return(NULL);
	}

void lh_free(lh)
LHASH *lh;
	{
	unsigned int i;
	LHASH_NODE *n,*nn;

	for (i=0; i<lh->num_nodes; i++)
		{
		n=lh->b[i];
		while (n != NULL)
			{
			nn=n->next;
#ifdef __GEOS__
			Free(n);
#else
			free(n);
#endif
			n=nn;
			}
		}
#ifdef __GEOS__
	Free((char *)lh->b);
	Free((char *)lh);
#else
	free((char *)lh->b);
	free((char *)lh);
#endif
	}

char *lh_insert(lh, data)
LHASH *lh;
char *data;
	{
	unsigned long hash;
	LHASH_NODE *nn,**rn;
	char *ret;

	if (lh->up_load <= (lh->num_items*LH_LOAD_MULT/lh->num_nodes))
		expand(lh);

	rn=getrn(lh,data,&hash);

	if (*rn == NULL)
		{
#ifdef __GEOS__
		if ((nn=(LHASH_NODE *)Malloc(sizeof(LHASH_NODE))) == NULL)
#else
		if ((nn=(LHASH_NODE *)malloc(sizeof(LHASH_NODE))) == NULL)
#endif
			return(NULL);
		nn->data=data;
		nn->next=NULL;
#ifndef NO_HASH_COMP
		nn->hash=hash;
#endif
		*rn=nn;
		ret=NULL;
		lh->num_insert++;
		lh->num_items++;
		}
	else /* replace same key */
		{
		ret= (*rn)->data;
		(*rn)->data=data;
		lh->num_replace++;
		}
	return(ret);
	}

char *lh_delete(lh, data)
LHASH *lh;
char *data;
	{
	unsigned long hash;
	LHASH_NODE *nn,**rn;
	char *ret;

	rn=getrn(lh,data,&hash);

	if (*rn == NULL)
		{
		lh->num_no_delete++;
		return(NULL);
		}
	else
		{
		nn= *rn;
		*rn=nn->next;
		ret=nn->data;
#ifdef __GEOS__
		Free((char *)nn);
#else
		free((char *)nn);
#endif
		lh->num_delete++;
		}

	lh->num_items--;
	if ((lh->num_nodes > MIN_NODES) &&
		(lh->down_load >= (lh->num_items*LH_LOAD_MULT/lh->num_nodes)))
		contract(lh);

	return(ret);
	}

char *lh_retrieve(lh, data)
LHASH *lh;
char *data;
	{
	unsigned long hash;
	LHASH_NODE **rn;
	char *ret;

	rn=getrn(lh,data,&hash);

	if (*rn == NULL)
		{
		lh->num_retrieve_miss++;
		return(NULL);
		}
	else
		{
		ret= (*rn)->data;
		lh->num_retrieve++;
		}
	return(ret);
	}

#ifdef __GEOS__
void lh_doall(LHASH *lh, void (*func)())
#else
void lh_doall(lh, func)
LHASH *lh;
void (*func)();
#endif
	{
	lh_doall_arg(lh,func,NULL);
	}

#ifdef __GEOS__
void lh_doall_arg(LHASH *lh, void (*func)(), char *arg)
#else
void lh_doall_arg(lh, func, arg)
LHASH *lh;
void (*func)();
char *arg;
#endif
	{
	int i;
	LHASH_NODE *a,*n;

	/* reverse the order so we search from 'top to bottom'
	 * We were having memory leaks otherwise */
	for (i=lh->num_nodes-1; i>=0; i--)
		{
		a=lh->b[i];
		while (a != NULL)
			{
			/* 28/05/91 - eay - n added so items can be deleted
			 * via lh_doall */
			n=a->next;
#ifdef __GEOS__
			CALLCB2(func, a->data, arg);
#else
			func(a->data,arg);
#endif
			a=n;
			}
		}
	}

static void expand(lh)
LHASH *lh;
	{
	LHASH_NODE **n,**n1,**n2,*np;
	unsigned int p,i,j;
	unsigned long hash,nni;

	lh->num_nodes++;
	lh->num_expands++;
	p=(int)lh->p++;
	n1= &(lh->b[p]);
	n2= &(lh->b[p+(int)lh->pmax]);
	*n2=NULL;        /* 27/07/92 - eay - undefined pointer bug */
	nni=lh->num_alloc_nodes;
	
	for (np= *n1; np != NULL; )
		{
#ifndef NO_HASH_COMP
		hash=np->hash;
#else
		hash=(*(lh->hash))(np->data);
		lh->num_hash_calls++;
#endif
		if ((hash%nni) != p)
			{ /* move it */
			*n1= (*n1)->next;
			np->next= *n2;
			*n2=np;
			}
		else
			n1= &((*n1)->next);
		np= *n1;
		}

	if ((lh->p) >= lh->pmax)
		{
		j=(int)lh->num_alloc_nodes*2;
#ifdef __GEOS__
		n=(LHASH_NODE **)Realloc((char *)lh->b,
			(unsigned int)sizeof(LHASH_NODE *)*j);
#else
		n=(LHASH_NODE **)realloc((char *)lh->b,
			(unsigned int)sizeof(LHASH_NODE *)*j);
#endif
		if (n == NULL)
			{
/*			fputs("realloc error in lhash",stderr); */
			lh->p=0;
			return;
			}
		/* else */
		for (i=(int)lh->num_alloc_nodes; i<j; i++)/* 26/02/92 eay */
			n[i]=NULL;			  /* 02/03/92 eay */
		lh->pmax=lh->num_alloc_nodes;
		lh->num_alloc_nodes=j;
		lh->num_expand_reallocs++;
		lh->p=0;
		lh->b=n;
		}
	}

static void contract(lh)
LHASH *lh;
	{
	LHASH_NODE **n,*n1,*np;

	np=lh->b[lh->p+lh->pmax-1];
	lh->b[lh->p+lh->pmax-1]=NULL; /* 24/07-92 - eay - weird but :-( */
	if (lh->p == 0)
		{
#ifdef __GEOS__
		n=(LHASH_NODE **)Realloc((char *)lh->b,
			(unsigned int)(sizeof(LHASH_NODE *)*lh->pmax));
#else
		n=(LHASH_NODE **)realloc((char *)lh->b,
			(unsigned int)(sizeof(LHASH_NODE *)*lh->pmax));
#endif
		if (n == NULL)
			{
/*			fputs("realloc error in lhash",stderr); */
			return;
			}
		lh->num_contract_reallocs++;
		lh->num_alloc_nodes/=2;
		lh->pmax/=2;
		lh->p=lh->pmax-1;
		lh->b=n;
		}
	else
		lh->p--;

	lh->num_nodes--;
	lh->num_contracts++;

	n1=lh->b[(int)lh->p];
	if (n1 == NULL)
		lh->b[(int)lh->p]=np;
	else
		{
		while (n1->next != NULL)
			n1=n1->next;
		n1->next=np;
		}
	}

static LHASH_NODE **getrn(lh, data, rhash)
LHASH *lh;
char *data;
unsigned long *rhash;
	{
	LHASH_NODE **ret,*n1;
	unsigned long hash,nn;
	int (*cf)();

	hash=(*(lh->hash))(data);
	lh->num_hash_calls++;
	*rhash=hash;

	nn=hash%lh->pmax;
	if (nn < lh->p)
		nn=hash%lh->num_alloc_nodes;

	cf=lh->comp;
	ret= &(lh->b[(int)nn]);
	for (n1= *ret; n1 != NULL; n1=n1->next)
		{
#ifndef NO_HASH_COMP
		lh->num_hash_comps++;
		if (n1->hash != hash)
			{
			ret= &(n1->next);
			continue;
			}
#endif
		lh->num_comp_calls++;
		if ((*cf)(n1->data,data) == 0)
			break;
		ret= &(n1->next);
		}
	return(ret);
	}

/*
static unsigned long lh_strhash(str)
char *str;
	{
	int i,l;
	unsigned long ret=0;
	unsigned short *s;

	if (str == NULL) return(0);
	l=(strlen(str)+1)/2;
	s=(unsigned short *)str;
	for (i=0; i<l; i++)
		ret^=(s[i]<<(i&0x0f));
	return(ret);
	} */

/* The following hash seems to work very well on normal text strings
 * no collisions on /usr/dict/words and it distributes on %2^n quite
 * well, not as good as MD5, but still good.
 */
unsigned long lh_strhash(c)
char *c;
	{
	unsigned long ret=0;
	long n;
	unsigned long v;
	int r;

	if ((c == NULL) || (*c == '\0'))
		return(ret);
/*
	unsigned char b[16];
	MD5(c,strlen(c),b);
	return(b[0]|(b[1]<<8)|(b[2]<<16)|(b[3]<<24)); 
*/

	n=0x100;
	while (*c)
		{
		v=n|(*c);
		n+=0x100;
		r= (int)((v>>2)^v)&0x0f;
		ret=(ret<<r)|(ret>>(32-r));
		ret&=0xFFFFFFFFL;
		ret^=v*v;
		c++;
		}
	return((ret>>16)^ret);
	}

#endif
