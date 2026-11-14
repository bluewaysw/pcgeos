/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  htcache.h
 *
 * AUTHOR:  	  Kok Kin Kee: Mar 12, 1997
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	kkee    	3/12/97   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 *	$Id: htcache.h,v 1.1 97/04/04 15:56:03 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _HTCACHE_H_
#define _HTCACHE_H_

#endif /* _HTCACHE_H_ */
/*
 Cache.h
 Cache manager header file
 (C) Copyright STNC Enterprises 1995,1996.
 GEOS port (c) Copyright 1996 STNC Enterprises Ltd
*/

#ifndef __cache_h
#define __cache_h


/*********************************************
               Exported defines
***********************************************/

#define CACHE_MAX_ACCESS              4   /* Highest avaliable access */
#define CACHE_ACCESS_EXCLUSIVE        4   /* No acces to others */
#define CACHE_ACCESS_WRITE            3
#define CACHE_ACCESS_EXCLUSIVE_READ   2   /* Others can read */
#define CACHE_ACCESS_READ             1   /* Others can read/write */
#define CACHE_ACCESS_NONE             0 /* Not locked */

#define CACHE_ACCESS_WAIT             0x100  /* Wait for access */

#define CACHE_TYPE_MISC           0
#define CACHE_TYPE_URL_SESSION    1
#define CACHE_TYPE_DOCUMENT       2
#define CACHE_TYPE_TOKEN          3
#define CACHE_TYPE_LIST           4    /* A list of handles */

#define CACHE_FLAG_NOSHARE        (1<<0)

#define CACHE_FLAG_HUGE           (1l<<31)
#define CACHE_FLAG_LARGE          (1l<<30)

/*********************************************
               Exported functions
***********************************************/

/*
 Cache_alloc
 Allocate an entry in the cache
 Args:
      Type  -  type of element to allocate
      size  -  size of element
      flags -  bit                      value
               CACHE_FLAG_NOSHARE       Do not share

 Returns:

      0         Not enough memory

*/
extern HTHANDLE  _pascal htcache_alloc(uint16 type,uint32 size,uint32 flags);

/*
 Cache_lock
 Lock an entry in the cache and return pointer
 to memory block.

 Args:
      handle  -  Entry handle to lock
      access  -  value                         Action
                 CACHE_ACCESS_EXCLUSIVE       Don't allow other access
                 CACHE_ACCESS_WRITE           Allow others to read
                 CACHE_ACCESS_EXCLUSIVE_READ  Don't allow others to write
                 CACHE_ACCESS_READ            Read only

                 Can be ORed with:
                 CACHE_ACCESS_WAIT            Wait for access


 Returns:
      Pointer to locket memory.

*/
extern void *  _pascal htcache_lock(HTHANDLE handle,uint16 access);
 
/*
 Cache_free
 Free an entry in the cache

 Args:
      handle  -  Entry handle to free

 Returns:
      void.

 Note:
      Memory must be unlocked first if locked.

*/
extern void  _pascal htcache_free(HTHANDLE handle);


/*
 Cache_unlock
 Unlock an entry in the cache

 Args:
      handle  -  Entry handle to free

 Returns:
      void.
*/
extern void _pascal htcache_unlock(HTHANDLE handle);


#endif

