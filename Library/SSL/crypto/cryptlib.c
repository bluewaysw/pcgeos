/* crypto/cryptlib.c */
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
#include "cryptlib.h"
#include "crypto.h"
#include "date.h"
#ifdef __GEOS__
#include "thread.h"
#endif
#ifdef GEOS_CLIENT
#include "sem.h"
#include "library.h"
#ifdef COMPILE_OPTION_MAP_HEAP
#include <MapHeap.h>
#endif
#endif

#if defined(WIN32) || defined(WIN16)
static double SSLeay_MSVC5_hack=0.0; /* and for VC1.5 */
#endif

#ifndef GEOS_CLIENT

/* real #defines in crypto.h, keep these upto date */
static char* lock_names[CRYPTO_NUM_LOCKS] =
	{
	"<<ERROR>>",
	"err",
	"err_hash",
	"x509",
	"x509_info",
	"x509_pkey",
	"x509_crl",
	"x509_req",
	"dsa",
	"rsa",
	"evp_pkey",
	"x509_store",
	"ssl_ctx",
	"ssl_cert",
	"ssl_session",
	"ssl",
	"rand",
	"debug_malloc",
	"BIO",
	"bio_gethostbyname",
	"RSA_blinding",
	};

static STACK *app_locks=NULL;

#endif /* GEOS_CLIENT */

#ifndef NOPROTO
static void (MS_FAR *locking_callback)(int mode,int type,
	char *file,int line)=NULL;
static int (MS_FAR *add_lock_callback)(int *pointer,int amount,
	int type,char *file,int line)=NULL;
static unsigned long (MS_FAR *id_callback)(void)=NULL;
#else
static void (MS_FAR *locking_callback)()=NULL;
static int (MS_FAR *add_lock_callback)()=NULL;
static unsigned long (MS_FAR *id_callback)()=NULL;
#endif

#ifdef GEOS_CLIENT

static SemaphoreHandle lock_cs[CRYPTO_NUM_LOCKS];

static void CRYPTO_thread_setup()
	{
	int i;

	PUSHDS;
	for (i=0; i<CRYPTO_NUM_LOCKS; i++)
		{
		lock_cs[i]=ThreadAllocThreadLock();
		HandleModifyOwner(lock_cs[i], GeodeGetCodeProcessHandle());
		}
	POPDS;
	}

static void CRYPTO_thread_cleanup()
	{
	int i;

	PUSHDS;
	for (i=0; i<CRYPTO_NUM_LOCKS; i++)
		ThreadFreeThreadLock(lock_cs[i]);
	POPDS;
	}

#ifdef COMPILE_OPTION_MAP_HEAP
word mapped = 0;
MemHandle phyMemInfoBlk;
#endif

#ifdef COMPILE_OPTION_HOST_SERVICE
Boolean hostApiAvailable = FALSE;
#endif

int _far _pascal SSLLIBRARYENTRY(LibraryCallType ty, GeodeHandle client)
{
    if (ty == LCT_ATTACH) {
#ifdef COMPILE_OPTION_MAP_HEAP
#ifdef FULL_EXECUTE_IN_PLACE
#pragma option -dc-
#endif
        mapped = MapHeapCreate("ssl     ", &phyMemInfoBlk) ;
#ifdef FULL_EXECUTE_IN_PLACE
#pragma option -dc
#endif
#endif
#ifdef COMPILE_OPTION_HOST_SERVICE
	hostApiAvailable = HostIfDetect() >= 1;
#endif
		CRYPTO_thread_setup();
    } else if (ty == LCT_DETACH) {
	    CRYPTO_thread_cleanup();
#ifdef COMPILE_OPTION_MAP_HEAP
	    if (mapped) {
		MapHeapDestroy(phyMemInfoBlk) ;
	    }
#endif
    }
    return(0);
}

#ifdef COMPILE_OPTION_MAP_HEAP
void SSL_Enter(void)
{
    if (mapped) {
	MapHeapEnter(phyMemInfoBlk) ;
    }
}

void SSL_Leave(void)
{
    if (mapped) {
	MapHeapLeave() ;
    }
}

/*
 * simple mapped scheme -- if we have a mapped heap, always use it and only
 * use it
 */

#pragma code_seg(FixedCallbacks)

void *MapMalloc(word blockSize)
{
    if (mapped) {
	return MapHeapMalloc(blockSize);
    } else {
	return _Malloc(blockSize,GeodeGetCodeProcessHandle(),0);
    }
}

void *MapRealloc(void *blockPtr, word newSize)
{
    if (mapped) {
	return MapHeapRealloc(blockPtr, newSize);
    } else {
	return _ReAlloc(blockPtr, newSize, GeodeGetCodeProcessHandle());
    }
}

void MapFree(void *blockPtr)
{
    if (mapped) {
	MapHeapFree(blockPtr);
    } else {
	_Free(blockPtr, GeodeGetCodeProcessHandle());
    }
}

#pragma code_seg()

#endif

#endif /* GEOS_CLIENT */

#ifndef GEOS_CLIENT

int CRYPTO_get_new_lockid(name)
char *name;
	{
	char *str;
	int i;

	/* A hack to make Visual C++ 5.0 work correctly when linking as
	 * a DLL using /MT. Without this, the application cannot use
	 * and floating point printf's.
	 * It also seems to be needed for Visual C 1.5 (win16) */
#if defined(WIN32) || defined(WIN16)
	SSLeay_MSVC5_hack=(double)name[0]*(double)name[1];
#endif

	PUSHDS;
	if (app_locks == NULL)
	    if ((app_locks=sk_new_null()) == NULL) {
			CRYPTOerr(CRYPTO_F_CRYPTO_GET_NEW_LOCKID,ERR_R_MALLOC_FAILURE);
			POPDS;
			return(0);
	    }
	if ((str=BUF_strdup(name)) == NULL)
		{POPDS;return(0);}
	i=sk_push(app_locks,str);
	if (!i) {
		Free(str);
	} else {
		i+=CRYPTO_NUM_LOCKS; /* gap of one :-) */
	}
	POPDS;
	return(i);
	}

void (*CRYPTO_get_locking_callback(P_V))(P_I_I_P_I)
	{
#ifdef __GEOS__
	void (MS_FAR *ret)(P_I_I_P_I);
	PUSHDS;
	ret = locking_callback;
	POPDS;
	return(ret);
#else
	return(locking_callback);
#endif
	}

int (*CRYPTO_get_add_lock_callback(P_V))(P_IP_I_I_P_I)
	{
#ifdef __GEOS__
	int (MS_FAR *ret)(P_IP_I_I_P_I);
	PUSHDS;
	ret = add_lock_callback;
	POPDS;
	return(ret);
#else
	return(add_lock_callback);
#endif
	}

#ifdef __GEOS__
void CRYPTO_set_locking_callback(void (*func)(P_I_I_P_I))
#else
void CRYPTO_set_locking_callback(func)
void (*func)(P_I_I_P_I);
#endif
	{
	locking_callback=func;
	}

#ifdef __GEOS__
void CRYPTO_set_add_lock_callback(int (*func)(P_IP_I_I_P_I))
#else
void CRYPTO_set_add_lock_callback(func)
int (*func)(P_IP_I_I_P_I);
#endif
	{
	PUSHDS;
	add_lock_callback=func;
	POPDS;
	}

unsigned long (*CRYPTO_get_id_callback(P_V))(P_V)
	{
#ifdef __GEOS__
	unsigned long (MS_FAR *ret)(P_V);
	PUSHDS;
	ret = id_callback;
	POPDS;
	return(ret);
#else
	return(id_callback);
#endif
	}

#ifdef __GEOS__
void CRYPTO_set_id_callback(unsigned long (*func)(P_V))
#else
void CRYPTO_set_id_callback(func)
unsigned long (*func)(P_V);
#endif
	{
	PUSHDS;
	id_callback=func;
	POPDS;
	}

#endif /* GEOS_CLIENT */

unsigned long CRYPTO_thread_id()
	{
#ifdef GEOS_CLIENT
	return((unsigned long)ThreadGetInfo(0, TGIT_THREAD_HANDLE));
#else
	unsigned long ret=0;

	PUSHDS;
	if (id_callback == NULL)
		{
#ifdef WIN16
		ret=(unsigned long)GetCurrentTask();
#elif defined(WIN32)
		ret=(unsigned long)GetCurrentThreadId();
#elif defined(MSDOS)
		ret=1L;
#elif defined(__GEOS__)
		ret=(unsigned long)ThreadGetInfo(0, TGIT_THREAD_HANDLE);
#else
		ret=(unsigned long)getpid();
#endif
		}
	else
#ifdef __GEOS__
		ret=CALLCB0(id_callback);
#else
		ret=id_callback();
#endif
	POPDS;
	return(ret);
#endif /* GEOS_CLIENT */
	}

void CRYPTO_lock(mode,type,file,line)
int mode;
int type;
char *file;
int line;
	{
#ifdef GEOS_CLIENT
	    PUSHDS;
	    if (mode & CRYPTO_LOCK) {
		ThreadGrabThreadLock(lock_cs[type]);
	    } else {
		ThreadReleaseThreadLock(lock_cs[type]);
	    }
	    POPDS;
#else
#ifdef LOCK_DEBUG
		{
		char *rw_text,*operation_text;

		if (mode & CRYPTO_LOCK)
			operation_text="lock  ";
		else if (mode & CRYPTO_UNLOCK)
			operation_text="unlock";
		else
			operation_text="ERROR ";

		if (mode & CRYPTO_READ)
			rw_text="r";
		else if (mode & CRYPTO_WRITE)
			rw_text="w";
		else
			rw_text="ERROR";

		fprintf(stderr,"lock:%08lx:(%s)%s %-18s %s:%d\n",
			CRYPTO_thread_id(), rw_text, operation_text,
			CRYPTO_get_lock_name(type), file, line);
		}
#endif
	PUSHDS;
	if (locking_callback != NULL)
#ifdef __GEOS__
		CALLCB4(locking_callback,mode,type,file,line);
#else
		locking_callback(mode,type,file,line);
#endif
	POPDS;
#endif /* GEOS_CLIENT */
	}

int CRYPTO_add_lock(pointer,amount,type,file,line)
int *pointer;
int amount;
int type;
char *file;
int line;
	{
	int ret;

	PUSHDS;
	if (add_lock_callback != NULL)
		{
#ifdef LOCK_DEBUG
		int before= *pointer;
#endif

#ifdef __GEOS__
		ret=CALLCB5(add_lock_callback,pointer,amount,type,file,line);
#else
		ret=add_lock_callback(pointer,amount,type,file,line);
#endif
#ifdef LOCK_DEBUG
		fprintf(stderr,"ladd:%08lx:%2d+%2d->%2d %-18s %s:%d\n",
			CRYPTO_thread_id(),
			before,amount,ret,
			CRYPTO_get_lock_name(type),
			file,line);
#endif
		*pointer=ret;
		}
	else
		{
		CRYPTO_lock(CRYPTO_LOCK|CRYPTO_WRITE,type,file,line);

		ret= *pointer+amount;
#ifdef LOCK_DEBUG
		fprintf(stderr,"ladd:%08lx:%2d+%2d->%2d %-18s %s:%d\n",
			CRYPTO_thread_id(),
			*pointer,amount,ret,
			CRYPTO_get_lock_name(type),
			file,line);
#endif
		*pointer=ret;
		CRYPTO_lock(CRYPTO_UNLOCK|CRYPTO_WRITE,type,file,line);
		}
	POPDS;
	return(ret);
	}

#ifndef GEOS_CLIENT

char *CRYPTO_get_lock_name(type)
int type;
	{
#ifdef __GEOS__
	char *ret;
#endif
	PUSHDS;
	if (type < 0)
		{POPDS;return("ERROR");}
	else if (type < CRYPTO_NUM_LOCKS)
#ifdef __GEOS__
		{POPDS;ret=lock_names[type];return(ret);}
#else
		return(lock_names[type]);
#endif
	else if (type-CRYPTO_NUM_LOCKS >= sk_num(app_locks))
		{POPDS;return("ERROR");}
	else
#ifdef __GEOS__
		ret = sk_value(app_locks,type-CRYPTO_NUM_LOCKS);
		POPDS;
		return(ret);
#else
		return(sk_value(app_locks,type-CRYPTO_NUM_LOCKS));
#endif
	}

#endif /* GEOS_CLIENT */

#ifdef _DLL
#ifdef WIN32

/* All we really need to do is remove the 'error' state when a thread
 * detaches */

BOOL WINAPI DLLEntryPoint(hinstDLL,fdwReason,lpvReserved)
HINSTANCE hinstDLL;
DWORD fdwReason;
LPVOID lpvReserved;
	{
	switch(fdwReason)
		{
	case DLL_PROCESS_ATTACH:
		break;
	case DLL_THREAD_ATTACH:
		break;
	case DLL_THREAD_DETACH:
		ERR_remove_state(0);
		break;
	case DLL_PROCESS_DETACH:
		break;
		}
	return(TRUE);
	}
#endif

#endif
