COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	resolver
MODULE:		cache management
FILE:		resolverCache.asm

AUTHOR:		Steve Jang, Oct 17, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/17/95   	Initial revision


DESCRIPTION:
  This file contains the routines to implement the following features:

  1. reinitializing cache
  2. limiting the size of cache
  3. refreshing cache periodically
  4. preserving cache in a file

START/EXIT SEQUENCE

       	       	       	resolver       	     detach
		       operations         delay period
flags			   |		       |
	                   |     RSF_TIMER_STARTED
			   |    	       |     RSF_SHUTTING_DOWN
			   v   	       	       v
START -------> REGISTER -------> UNREGISTER -------> DETACH -------> EXIT
1. resource  	 1. create     	 1. initiate   	     1. destroy	     1. res
   alloc            socket	    detach      	socket  	dealloc
2. load	         2. create                           2. destroy      2. save
   cache            event queue                         event queue     cache
		 3  create threads                   3. kill threads

PLAN:

  [ re-initializing cache ]

  - a function to re-initialize cache( deleting all its entries )

  [ limiting cache size ]

  - number of allowed cache entries will be read in from .ini file
  - cache will be reduced into half once cache limit is reached, deleting
    any cache entry that is over 1 day old( finding median seems like an
    overkill ).  If over half of the cache enries are less than 1 day old, 
    we will delete random entries of them to secure more space.

  [ refreshing cache ]

  - TTL(time to live) for each incoming resource record will be converted from
    initial second unit into day unit
  - a new cache entry will be deleted in 7 days or when TTL value reaches 0,
    whichever is sooner( see constant MAX_CACHE_ENTRY_LIFE )
  - TTLs for cache entries will be updated at midnight or when resolver exits
    or starts up

  [ preserving cache ]

  - current cache will be downloaded to a file when resolver exits
  - cached data in the file will be read in on startup

ROUTINES:

  CacheReinitialize	- delete all cache entries
  CacheDeallocateHalf	- delete half of current cache entries
  CacheRefresh		- delete cache entries that are older than age limit
  CacheSave		- save all cache entries
  CacheLoad		- load all cache entries updating their TTLs

	$Id: resolverCache.asm,v 1.9 98/10/01 17:16:53 reza Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResolverCommonCode	segment	resource

; ----------------------------------------------------------------------------
; Re-initializing cache
; ----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheReinitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all cache entries

CALLED BY:	utility
PASS:		dx	= file handle to save cache entries to
			  ( file is open before this routine is called )
			or 0 to delete cache entries without saving them
RETURN:		carry set if disk is full or other write error happened
			ax	= FileError
DESTROYED:	ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheReinitialize	proc	far
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; If file handle is given, we will be saving all cache entries to a
	; file.  So, time stamp the file
	;
		tst	dx
		jz	skipTimeStamp
	;
	; Timestamp the file
	;
		push	dx
		call	ResolverGetCurrentDate	; ax = current date converted
		push	ax			;      into 1-365
		clr	al
		mov	bx, dx
		mov	cx, size word		; time stamp = word( 1-365 )
		segmov	ds, ss, dx
		mov	dx, sp
		call	FileWrite		; write time stamp into file
		pop	dx
		pop	dx
		jc	done
skipTimeStamp:
	;
	; Lock the block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax
	;
	; The first element is the root
	;
		mov	bp, ds:CBH_root		;*ds:bp = root
		mov	si, ds:[bp]		; ds:si = root
		mov	di, si			; ds:di = root
		mov	bx, vseg CacheRRCloseCB
		mov	ax, offset CacheRRCloseCB
		call	TreeEnum		; ds:si/*bp = root, CF set if
						;  out of disk space
		mov	ax, ERROR_SHORT_READ_WRITE  ; ax = FileError if CF set
	;
	; Unlock the block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
done:	
		.leave
		ret
CacheReinitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverGetCurrentDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current date in terms of ordinal number from 1 to 365

CALLED BY:	CacheReinitialize, CacheLoad
PASS:		nothing
RETURN:		ax	= date in terms of 1 - 365
DESTROYED:	nothing

LOW BUG:
		In the years in which February has 29 days, date is technically
		off by 1 day, but this shouldn't cause serious problem.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
monthTable	byte 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
ResolverGetCurrentDate	proc	near
		uses	bx,cx,dx,si,ds
		.enter
		call	TimerGetDateAndTime	; bl = month, bh = day
						; cx, dx, ax destroyed
	;
	; calculate current date
	;
		segmov	ds, cs, si
		mov	si, offset monthTable
		clr	dh
		mov	dl, bh			; dx = date
		clr	ch
		mov	cl, bl			; cx = month
		clr	ah
nextMonth:
		dec	cx
		jcxz	done
		lodsb
		add	dx, ax
		jmp	nextMonth
done:
		mov	ax, dx
		.leave
		ret
ResolverGetCurrentDate	endp

; ----------------------------------------------------------------------------
; Limiting cache size
; ----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheDeallocateHalf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deallocate half of current cache entries
		
CALLED BY:	ResolverEventCleanupCache
PASS:		nothing
RETURN:		nothing
DESTROYED:	ds, es

NOTE:
   We want to get rid of RRT_NS resource records first.  Here is why:
   If you have, at node cs.washington.edu, some RRT_NS records such as
   "june.cs.washington.edu" or "trout.cs.washington.edu", when resolver
   composes a list of servers to query for "wolf.cs.washington.edu", it
   will include "june..." and "trout...".  Now, if we don't have addresses
   for these servers, it will recursively try to compose a list of name
   servers to query addresses "june..." or "trout...".

   At this point, it will again use "june..." and "trout..." as name servers
   since these RRT_NS RRs are stored in the path.  So this will go on forever
   until an answer comes in from a different name server.  So we don't want to
   delete addresses before deleting RRT_NS type RRs that might use those
   addresses.

   In delegation packets, addresses of name servers are usually included.

   Also, I've decided to rotate the tree before deleting entries in order to
   delete the old ones first.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheDeallocateHalf	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; How many entries are allowed?
	;
		GetDgroup es, bx
		tst	es:cacheSizeAllowed
		jz	done		
	;
	; How many entries do we need to delete?
	;
		mov	dx, es:cacheSize
		mov	ax, es:cacheSizeAllowed
		cmp	dx, ax
LONG		jbe	done
		shr	ax, 1		; leave only half of allowed cache size
		sub	dx, ax
		mov	es:deleteCount, dx
	;
	; Rotate the tree
	;   CacheSave-CacheLoad sequence has the side effect of rotating cache
	;   tree so that records added first become the ones visited first by
	;   tree enum.  If any errors occur while doing this, entire cache
	;   will be deleted.  No big deal.
	;
		segmov	ds, es, ax	; ds = dgroup
		call	CacheSave
		jc	done
		call	CacheLoad
		tst	es:cacheSize	; Did cache fail to load?
		jz	done
	;
	; Lock the cache block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax
		mov	bp, ds:CBH_root
		mov	si, ds:[bp]
		mov	di, si
	;
	; Mark RRT_NS resource records as expired
	;
		mov	bx, vseg CacheExpireNSCB
		mov	ax, offset CacheExpireNSCB
		call	TreeEnum	; es destroyed
	;
	; Get dgroup again
	;
		GetDgroup es, ax
	;
	; Delete All expired records
	; es = dgroup
	; dx = anything below this will be deleted until deleteCount is 0
	; ds:si = root
	; ds:di = root
	; ds:*bp= root
	; es:deleteCount = number of cache entries to be deleted
	;
		mov	dx, 1
		mov	bx, vseg CacheRRUpdateCB
		mov	ax, offset CacheRRUpdateCB
		call	TreeEnum
		jc	unlock
	;
	; Delete records over 1 day old
	; es = dgroup
	; dx = anything below this will be deleted until deleteCount is 0
	; ds:si = root
	; ds:di = root
	; ds:*bp= root
	; es:deleteCount = number of cache entries to be deleted
	;
		mov	dx, MAX_CACHE_ENTRY_LIFE
		mov	bx, vseg CacheRRUpdateCB
		mov	ax, offset CacheRRUpdateCB
		call	TreeEnum
		jc	unlock
	;
	; Delete records less than 1 day old stopping if dx = 0
	; es = dgroup
	; dx = anything below this will be deleted until deleteCount is 0
	; ds:si = root
	; ds:di = root
	; ds:*bp= root
	; es:deleteCount = number of cache entries to be deleted
	;
	; we should be back up at the root again
	;
EC <		cmp	bp, ds:CBH_root					>
EC <		ERROR_NE RFE_TREE_BUG					>
		mov	dx, MAX_CACHE_ENTRY_LIFE + 1
		call	TreeEnum
EC <		tst	es:deleteCount					>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
unlock:
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
done:
		.leave
		ret
CacheDeallocateHalf	endp

; ----------------------------------------------------------------------------
; Refreshing cache
; ----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheRefreshTimerStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a continual timer that goes off every 24 hours and
		records age of cache

CALLED BY:	ResolverInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheRefreshTimerStart	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; store current TimerCompressedDate into cx
	;
		call	TimerGetDateAndTime	; ax = yr; bl = mo.; bh = date
		call	GetNextDay		; cx = TimerCompressedDate for
	;					;      the next day
	; set alarm to go off at 00:01am
	;
		mov	di, DATE_CHANGE_TIME	; 00:01am
chk1::
	;
	; setup timer
	;
		mov	al, TIMER_ROUTINE_REAL_TIME
		mov	bx, segment TwentyFourHourCallback
		mov	si, offset TwentyFourHourCallback
		clr	dx			; first time 24HrCB is called
		mov	bp, handle 0
		call	TimerStartSetOwner ; ax = timer ID, bx = timer handle
		GetDgroup es, cx
		movdw	es:refreshTimer, axbx
		.leave
		ret
CacheRefreshTimerStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheRefreshTimerStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop cache refresh timer

CALLED BY:	ResolverExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheRefreshTimerStop	proc	far
		uses	ax,bx,es
		.enter
		GetDgroup es, ax
		movdw	axbx, es:refreshTimer
		call	TimerStop
		.leave
		ret
CacheRefreshTimerStop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return next date

CALLED BY:	CacheRefreshTimerStart
PASS:		ax = year
		bh = date
		bl = month
RETURN:		cx = TimerCompressedDate for the next day
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextDay	proc	near
		uses	ax,bx,di
		.enter
		
		call	LocalCalcDaysInMonth	; ch = days in the month
		inc	bh
		cmp	ch, bh
		jb	monthChange
cont:
		sub	ax, 1980
		mov	di, ax
		mov	cl, offset TCD_YEAR
		shl	di, cl			; di = year filled in
		clr	ah
		mov	al, bl
		mov	cl, offset TCD_MONTH
		shl	ax, cl
		ornf	di, ax			; di = month filled in
		clr	ah
		mov	al, bh
		ornf	di, ax			; di = date filled in
		mov	cx, di			; cx = today's date
		.leave
		ret
monthChange:
		sub	bh, ch
		inc	bl
		cmp	bl, 12			; last month?
		jna	cont
		inc	ax			; year change
		jmp	cont
GetNextDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheUpdateTTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update TTL according to resolverStatus.RSF_CACHE_AGE

CALLED BY:	ResolverRegister, ResolverPoll
PASS:		nothing
RETURN:		carry set if cache age was older than 0 days,
		and TTL of cache entries were updated
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheUpdateTTL	proc	far
		uses	dx,es
		.enter
	;
	; If cache age == 0, exit
	;
		GetDgroup es, dx
		mov	dx, es:resolverStatus
		and	dx, mask RSF_CACHE_AGE
		tst	dx			; CF = 0
		jz	exit
	;
	; dx = cache age in days, update TTL for all cache entries
	;
		BitClr	es:resolverStatus, RSF_CACHE_AGE
		call	CacheDecrementTTL
		stc
exit:		
		.leave
		ret
CacheUpdateTTL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheDecrementTTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subtract age from each resource record in the cache

CALLED BY:	CacheUpdateTTL
PASS:		es	= dgroup
		dx	= age in days
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheDecrementTTL	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Lock the cache block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax
		mov	bp, ds:CBH_root
		mov	si, ds:[bp]
		mov	di, si
	;
	; Delete records if they have less than 1 day to live
	; es = dgroup
	; dx = cache age
	; ds:si = root
	; ds:di = root
	; ds:*bp= root
	; es:deleteCount = number of cache entries to be deleted
	;
		mov	bx, vseg CacheRRDecrementTTLCB
		mov	ax, offset CacheRRDecrementTTLCB
		call	TreeEnum		; es = destroyed
		
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
		
		.leave
		ret
CacheDecrementTTL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheRRDecrementTTLCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement TTL value of each resource record

CALLED BY:	TreeEnum via CacheDecrementTTL
PASS:		dx	= cache age
		ds:di	= prev node
		ds:si	= current node
		ds:*bp	= current node

RETURN:		carry clear
DESTROYED:	ax, bx, cx, di, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheRRDecrementTTLCB	proc	far
		.enter
		jc	doneClr	; on the way up, do nothing
	;
	; visit each RR, and decrement TTL
	;
		movdw	axdi, ds:[si].RRN_resource
nextRr:
		tst	ax
		jz	done
		mov_tr	bx, ax
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[di]
		cmp	dx, es:[di].RR_common.RRC_ttl.low
		jbe	subt
		clr	es:[di].RR_common.RRC_ttl.low
subt:
		sub	es:[di].RR_common.RRC_ttl.low, dx
		movdw	axdi, es:[di].RR_next
		call	HugeLMemUnlock
		jmp	nextRr
doneClr:
		clc
done:
		.leave
		ret
CacheRRDecrementTTLCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheExpireNSCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expire all RRT_NS resource records in the chain

CALLED BY:	TreeEnum via CacheDeallocateHalf
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheExpireNSCB	proc	far
		.enter
		jc	doneClr	; on the way up, do nothing
	;
	; visit each RR, and decrement TTL
	;
		movdw	axdi, ds:[si].RRN_resource
nextRr:
		tst	ax
		jz	done
		mov_tr	bx, ax
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[di]
	;
	; Check if this is RRT_NS; if so, mark it as expired
	;
		cmp	es:[di].RR_common.RRC_type, RRT_NS
		jne	skip
		clr	es:[di].RR_common.RRC_ttl.low
skip:
		movdw	axdi, es:[di].RR_next
		call	HugeLMemUnlock
		jmp	nextRr
doneClr:
		clc
done:
		.leave
		ret
CacheExpireNSCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheRefresh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete cache entries that have expired

CALLED BY:	ResolverEventCacheRefresh
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheRefresh	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Use CacheRRUpdateCB, and put up with some inconveniences
	; that might follow because of that.
	;
		GetDgroup es, bx
		mov	dx, es:cacheSize
		mov	es:deleteCount, dx	; delete all if necessary
	;
	; Lock the cache block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax
		mov	bp, ds:CBH_root
		mov	si, ds:[bp]
		mov	di, si
	;
	; Delete records if they have less than 1 day to live
	; es = dgroup
	; dx = anything below this will be deleted until deleteCount is 0
	; ds:si = root
	; ds:di = root
	; ds:*bp= root
	; es:deleteCount = number of cache entries to be deleted
	;
		mov	dx, 1 ; if anyone has less than 1 day to live, delete
		mov	bx, vseg CacheRRUpdateCB
		mov	ax, offset CacheRRUpdateCB
		call	TreeEnum
		
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
		
		.leave
		ret
CacheRefresh	endp

; ----------------------------------------------------------------------------
; Preserving cache
; ----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save all cache entries and delete all of it
		If disk is full, delete the cache file and exit.

CALLED BY:	ResolverExit
PASS:		ds = dgroup
RETURN:		carry set if certain error occured in saving
		- most likely to be disk full
		( in this case, cache file has been deleted )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheSave	proc	far
		uses	ax,bx,cx,dx
		.enter
	;
	; If the allowed cache size is 0, then don't try to create the
	; cache file
	;
		tst_clc	ds:cacheSizeAllowed
		jz	justExit
	;
	; Open a new file, destroying the file if already exists
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
		jc	error
		mov	ax, (FILE_CREATE_TRUNCATE shl 8) or \
			    ((FE_NONE shl offset FAF_EXCLUDE) or FA_READ_WRITE)
		clr	cx
		mov	dx, offset cacheFileName
		call	FileCreate	; ax = file handle
		jc	error
	;
	; Write cache entries into the file and destroy cache entries in the
	; memory
	;
		mov_tr	dx, ax
		push	ds
		call	CacheReinitialize ; carry set if error, ax = FileError
					  ; ds = destroyed
		pop	ds
	;
	; Close the file
	;
		push	ax		; save possible FileError

		pushf
		mov	bx, dx
		clr	al
		call	FileClose
		popf
		jc	deleteFile
popDone:
		pop	ax		; restore possible FileError
done:
	;
	; Make sure cacheSize = 0
	;
EC <		jnc	ecCacheSize					>
EC <		cmp	ax, ERROR_SHORT_READ_WRITE			>
EC <		ERROR_NE RFE_GENERAL_FAILURE				>
EC <		WARNING	RW_OUT_OF_DISK_SPACE				>
EC <		stc							>
EC <		jmp	ecDone						>
EC <ecCacheSize:							>
EC <		tst_clc	ds:cacheSize					>
EC <		ERROR_NZ RFE_GENERAL_FAILURE 				>
EC <ecDone:								>

	;
	; Restore the path
	;
		call	FilePopDir
justExit:
		mov	ds:cacheSize, 0	; cacheSize = 0
		.leave
		ret
error:
	;
	; Handle file create error
	;
		jmp	done
deleteFile:
	;
	; disk is full, so delete the file to prevent corrupted cache file
	; ax = file handle
	;
		mov	dx, offset cacheFileName
		call	FileDelete
		stc
		jmp	popDone
		
CacheSave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in cache entries from cache file
		If we can't find cache file, we don't do anything.

CALLED BY:	ResolverInit, CacheDeallocateHalf
PASS:		ds	= dgroup
RETURN:		carry clear
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheLoad	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	; go to private data directory
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
		jc	done
	;
	; check if we're cache allowed size is 0, then we don't load
	; it and delete the existing cache file to be sure
	;
		tst	ds:cacheSizeAllowed
		jz	fileCorrupted
	;
	; check if error count is too high, if so, we assume that cache
	; is corrupted or useless.  And don't load it.
	;
		push	ds
		segmov	ds, cs, ax
		mov	si, offset resCategory
		mov	cx, cs
		mov	dx, offset errorCountStr
		call	InitFileReadInteger	; ds, si, dx saved
		pop	ds			; ax = fail count
		jc	skipCheck
	;
	; compare it to fail count allowed
	; if fail count is above what is allowed, delete cache file and
	; start out from scratch
	; 
		cmp	ax, RESOLVER_FAILURE_ALLOWANCE
		ja	fileCorrupted
skipCheck:
	;
	; Open cache file, and if not found, don't do anything
	;
		mov	al, FileAccessFlags< FE_NONE, FA_READ_ONLY >
		mov	dx, offset cacheFileName
		call	FileOpen	; ax = file handle
		jc	done
	;
	; Read time stamp
	;
		mov	bx, ax
		clr	al		; we want errors to be returned
		mov	cx, size word
		sub	sp, size word	; allocate word size buffer
		segmov	ds, ss, dx
		mov	dx, sp		; ds:dx = buffer into which to read in
		call	FileRead	; cx = #bytes read, carry set on error
		pop	dx		; read buffer
		jc	closeFile
	;
	; Read in cache entries and construct cache in memory
	;
		call	CacheFileReadEntries ; carry set if file was corrupted
closeFile:
	;
	; Close the file
	;
		pushf
		clr	al
		call	FileClose
		popf
		jc	fileCorrupted
done:
		call	FilePopDir
		clc
		.leave
		ret
fileCorrupted:
	;
	; reset the counter
	;
		segmov	ds, cs, ax
		mov	si, offset resCategory
		mov	cx, cs
		mov	dx, offset errorCountStr
		clr	bp		; counter = 0
		call	InitFileWriteInteger
		call	InitFileCommit
	;
	; If file was corrupted, delete it
	;
		GetDgroup ds, dx
		clr	ds:cacheSize
		mov	dx, offset cacheFileName
		call	FileDelete
		clc
		jmp	done
		
CacheLoad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheFileReadEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in cache entries from a file

CALLED BY:	CacheLoad
PASS:		bx	= file handle
		dx	= timestamp when file was saved
RETURN:		carry set if file was corrupted
		carry clr if file was successfully read into memory cache
DESTROYED:	dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheFileReadEntries	proc	near
		uses	ax,bx,ds
		.enter
	;
	; Check arguments
	;
EC <		Assert_fileHandle bx					>
EC <		cmp	dx, DAYS_IN_A_YEAR + 1				>
EC <		ERROR_NB RFE_BAD_ARGUMENT				>
	;
	; Get time difference
	;
		call	ResolverGetCurrentDate	; ax = date in 1-365 format
		cmp	ax, dx
		jae	noWrap
	;
	; We wrapped around a year
	;
		add	ax, DAYS_IN_A_YEAR
noWrap:
		sub	ax, dx			; difference in days
		mov_tr	dx, ax			; dx = time elapsed since save
	;
	; Setup things to call CacheFileReadSubTree
	;
		GetDgroup es, ax		; es = dgroup
		push	bx
		mov	bx, handle ResolverCacheBlock
		call	MemLock
		mov	ds, ax			; ds = ResolverCacheBlock seg
		pop	bx			; bx = file handle
	;
	; Read subtree which is the entire tree
	;
		call	CacheFileReadSubTree	; bp = chunk handle of root
		jc	unlockDone		; we will not attempt to
	;					; delete entries read in so far
	; Verify that this is the root node	; cache block/hugelmem will be
	;					; deleted when resolver exits
EC <		push	si						>
EC <		mov	si, ds:[bp]					>
EC <		test	ds:[si].NC_flags, mask NF_ROOT			>
EC <		ERROR_Z	RFE_TREE_CORRUPTED				>
EC <		pop	si						>
	;
	; Replace current root with the new root
	;
		xchg	bp, ds:CBH_root
	;
	; The cache must be empty at this point
	;
EC <		push	si						>
EC <		mov	si, ds:[bp]					>
EC <		test	ds:[si].NC_flags, mask NF_HAS_CHILD		>
EC <		ERROR_NE RFE_TREE_CORRUPTED				>
EC <		pop	si						>
	;
	; Free old root node
	;
		mov	ax, bp
		call	LMemFree		; free old root
		clc				; carry clear
unlockDone:
	;
	; Unlock cache block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
		
		.leave
		ret
CacheFileReadEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheFileReadSubTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a sub tree of cache entries

CALLED BY:	CacheReadEntries or CacheReadSubTree

PASS:		bx	= file handle
		dx	= time elapse since last save
		ds	= segment of ResolverCacheBlock
		es	= dgroup

RETURN:		bp	= chunk handle of a subtree just read
		ds	= segment of ResolverCacheBlock may have moved
		carry set if entry is corrupted

DESTROYED:	nothing

ALGORITHM:

	This recursive algorithm shouldn't overflow stack since there is a
	relatively low limit on depth of cache tree

	subtree = CacheFileReadRecord
	re-initialize( subtree )

	if subtree HAS_CHILD {
	   repeat {
	      child = CacheFileReadSubTree
	      TreeAppendChild( child -> subtree )
	      } unless (child == LAST CHILD)
	}

	return( subtree )

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheFileReadSubTree	proc	near
		uses	ax,bx,dx,si,di
		.enter
	;
	; Read one RR node
	;
		call	CacheFileReadRecord	; bp	= record chunk
		jc	done
	;
	; Initialize fields so that we'll know if we ever get into trouble
	;
		mov	di, ds:[bp]		; ds:di = subtree
		clr	ax
	;
	; if root, prev/next must point at the root itself
	;
		test	ds:[di].NC_flags, mask NF_ROOT
		jz	notRoot
		mov	ax, bp
notRoot:
		mov	ds:[di].NC_prev, ax
		mov	ds:[di].NC_next, ax
		mov	ds:[di].NC_child, bp	; initialize child field
		test	ds:[di].NC_flags, mask NF_HAS_CHILD
		jz	done
	;
	; Clr HAS_CHILD flag, so that TreeAddChild don't get confused
	;
		BitClr	ds:[di].NC_flags, NF_HAS_CHILD
repeat:
	;
	; Read Subtrees and append them to the current tree
	;
		push	bp
		mov	di, bp			; di	= *cur tree
		call	CacheFileReadSubTree	; bp	= record chunk
		jc	fileCorrupted
		mov	si, ds:[bp]		; ds:si = child tree
		mov	di, ds:[di]		; ds:di = parent tree
		test	ds:[si].NC_flags, mask NF_LAST
		pushf
		call	TreeAddChildFar		; appended to ds:di
		popf
		pop	bp			; bp	= subtree
		jz	repeat			; more siblings to read
done:
		.leave
		ret
fileCorrupted:
	;
	; carry is set
	;
		pop	bp
		jmp	done
CacheFileReadSubTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheFileReadRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a resource record node from a file

CALLED BY:	CacheFileReadSubTree

PASS:		bx	= file handle
		dx	= time elapse since saved to file
		ds	= segment of ResolverCacheBlock
		es	= dgroup

RETURN:		bp	= record chunk handle
		ds	= ResolverCacheBlock may have moved

		carry set on error

ALGORITHM:
		Read ResourceRecordNode structure
		Read one byte -> number of characters for label
		Allocate new node
		   read in label
		If ResourceRecord is not null,
			Read a chain of resource records for this node
			Attach

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheFileReadRecord	proc	near
		uses	ax,bx,cx,dx,si,di,es
		.enter
		push	dx		; save time elapse
	;
	; Read in ResourceRecordNode and label length 
	;
		clr	al		; we want error to be returned
		mov	dx, offset CBH_tempNode	; ds:dx = buffer
		mov	cx, size RRRootNode	; size of CBH_tempNode
		call	FileRead	; carry set if error
		jc	errorPopDx
	;
	; Allocate a new node
	;
		clr	ch
		mov	cl, ds:CBH_tempNode.RRRN_name
		add	cx, size ResourceRecordNode + 1 ; include label length
		call	LMemAlloc		; ax = new chunk handle
		mov	bp, ax			; *ds:bp = new node
		mov	di, ds:[bp]		; ds:di  = new node
	;
	; Copy content of temp node into the real node
	;
		segmov	es, ds, ax		; es:di	 = new node
		mov	si, offset CBH_tempNode	; ds:si  = temp node
		mov	cx, size RRRootNode	; size of tempNode
		rep movsb
	;
	; Read in label
	; bx = file handle
	;
EC <		Assert_fileHandle bx					>
		clr	al			; we want error to be returned
		clr	ch
		mov	cl, ds:CBH_tempNode.RRRN_name	; cx = label size
		mov	dx, di				; ds:di = new node
		call	FileRead		; ax,cx destroyed
		jc	errorPopDx
	;
	; Read in ResourceRecord associated with the current node
	;
		pop	dx			; dx = time elapse
		mov	si, ds:[bp]		; ds:si = new node
		test	ds:[si].NC_flags, mask NF_RESERVED
		jnz	error
		tst	ds:[si].RRN_resource.high
		jz	done			; carry clear
	;
	; Read in the resource record chain associated with this node
	;
		call	CacheFileReadRRChain	; axcx  = optr to chain
		jc	error
		movdw	ds:[si].RRN_resource, axcx
done:
		.leave
		ret
errorPopDx:
		pop	dx
error:
		stc
		jmp	done
CacheFileReadRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheFileReadRRChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in resource record chain

CALLED BY:	CacheFileReadRecord
PASS:		bx	= file handle
		dx	= time elapse in days
RETURN:		axcx	= optr to RR chain in hugeLMem
		carry set if error
DESTROYED:	nothing

NOTE:
	this routine should not allocate anything in ResoverCacheBlock

ALGORITHM:

	Variables: head    optr -> local head
		   prev    optr -> local prev
		   current optr	-> ^lax:cx

	head = 0
	prev = 0
repeat:
	read tempRecord
	update TTL
	if TTL = 0,
		advance read/write pointer by dataSize
		goto exit
	else
		allocate ResourceRecord node in HugeLMem -> current
		copy tempRecord into current
		read data into ResourceRecord node

	if head = 0
		head = current
	else
		prev.next = current /* prev should not be 0 at this point */

	prev = current

exit:
	if tempRecord.next = 0
		return head, and quit

	goto repeat
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheFileReadRRChain	proc	near
		tempRecord	local	ResourceRecord
		head		local	optr
		prev		local	optr
		uses	si,ds,es
		.enter
	;
	; Set up
	;
		clr	ax
		movdw	head, axax	; head = 0
		movdw	prev, axax	; prev = 0
repeat:
	;
	; Read temp record
	;
		push	dx		; save time elapse
		segmov	ds, ss, ax
		mov	dx, bp
		add	dx, offset tempRecord
		mov	cx, size ResourceRecord
		clr	al		; we need error to be returned
		call	FileRead	; ax, cx destroyed
		pop	dx		; dx = time elapse
LONG		jc	error
	;
	; update TTL
	;
		sub	tempRecord.RR_common.RRC_ttl.low, dx
LONG		jbe	ttlZero
	;
	; TTL is a legal value
	; Allocate ResourceRecord
	;
		GetDgroup	es, ax
		inc	es:cacheSize	; increment number of cache entries
		push	bx		; save file handle
		mov	bx, es:hugeLMem
		mov	ax, tempRecord.RR_common.RRC_dataLen
		add	ax, size ResourceRecord
		clr	cx		; we don't want to wait
		call	HugeLMemAllocLock ; ds:di, ^lax:cx = new node
		pop	bx		; bx = file handle
LONG		jc	error
	;
	; copy tempRecord into new node allocated and clear the next field
	; just in case
	;
		push	ax, cx, dx
		segmov	es, ds		; es:di = new record node
		segmov	ds, ss
		mov	si, bp
		add	si, offset tempRecord
		mov	cx, size ResourceRecord
		mov	dx, di		; dx = di before copying RR structure
		rep movsb		; di changed
		xchg	dx, di	; dx = di after copying, di = before copying
		clr	ax
		mov	es:[di].RR_next.high, ax
		mov	es:[di].RR_next.low, ax
	;
	; Read data from file
	; ax = 0
	; es:dx = buffer for RR data
	;
		mov	cx, tempRecord.RR_common.RRC_dataLen ; cx = data len
		segmov	ds, es, si
		call	FileRead	; ax,cx destroyed
		pop	ax, cx, dx	; restore optr to new chunk
		push	bx
		mov	bx, ax
		call	HugeLMemUnlock	; unlock new node
		pop	bx
		jc	error
	;
	; At this point:
	;   ^lax:cx = chunk optr to new node allcoated
	;   bx	    = file handle
	;   dx	    = time elapse
	;
	; Update head/next pointer
	;
chk1::
		tst	head.high
		jnz	updateNext
		movdw	head, axcx
		jmp	cont2
updateNext:
	;
	; prev    = optr to the prev RR node added to the chain
	; ^lax:cx = current node
	;
EC <		tst	prev.high					>
EC <		ERROR_Z	RFE_GENERAL_FAILURE				>
		push	bx		; save file handle
		movdw	bxsi, prev
		push	ax		; save hptr to new node
		call	HugeLMemLock
		mov	ds, ax
		pop	ax		; ^laxcx = new node
		mov	si, ds:[si]
		movdw	ds:[si].RR_next, axcx
		call	HugeLMemUnlock
		pop	bx		; bx = file handle
cont2:
	;
	; prev = current
	;
		movdw	prev, axcx
exit:
	;
	; if tempRecord.next = 0, return head
	;
		tst	tempRecord.RR_next.high
		jz	returnHead
		jmp	repeat
returnHead:
		movdw	axcx, head
done:
		.leave
		ret
ttlZero:
	;
	; TTL of the record expired
	; advance read/write pointer by the length of data
	; bx	= file handle
	; dx	= time elapse
	;
		push	dx
		mov	al, FILE_POS_RELATIVE
		clr	cx
		mov	dx, tempRecord.RR_common.RRC_dataLen ; cx = data len
		call	FilePos		; dx:ax = new file position
		pop	dx		; dx = time elapse
		jmp	exit
error:
		jmp	done
CacheFileReadRRChain	endp

ResolverCommonCode	ends


ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TwentyFourHourCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment cache age

CALLED BY:	see CacheSetupRefreshTimer
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TwentyFourHourCallback	proc	far
		uses	ax,cx,es
		.enter
	;
	; stop the timer if any
	;
		mov	si, vseg CacheRefreshTimerStop
		mov	di, offset CacheRefreshTimerStop
		call	CallOnUiThread
	;
	; Update resolverStutus
	;
		GetDgroup es, cx
		mov	ax, es:resolverStatus
		and	ax, mask RSF_CACHE_AGE
		cmp	ax, MAX_CACHE_ENTRY_LIFE
		jb	notMax
		mov	ax, MAX_CACHE_ENTRY_LIFE - 1
notMax:
		inc	ax
		ornf	es:resolverStatus, ax
	;
	; restart timer
	;
		mov	si, vseg CacheRefreshTimerStart
		mov	di, offset CacheRefreshTimerStart
		call	CallOnUiThread
		
		.leave
		ret
TwentyFourHourCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallOnUiThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call RLPNmi on UI thread

CALLED BY:	EXTERNAL
PASS:		ax,bx,cx,dx	= Data to pass to the called routine
		sidi		= Routine to call( vseg )
RETURN:		carry set if ui thread does not exist yet
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallOnUiThread	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es,ds
		.enter
	;
	; prepare arguments
	;
		sub	sp, size ProcessCallRoutineParams
		mov	bp, sp
		mov	ss:[bp].PCRP_dataAX, ax
		mov	ss:[bp].PCRP_dataBX, bx
		mov	ss:[bp].PCRP_dataCX, cx
		mov	ss:[bp].PCRP_dataDX, dx
		mov	ss:[bp].PCRP_address.high, si
		mov	ss:[bp].PCRP_address.low, di
	;
	; Check if we have thread handle to use
	;
		GetDgroup es, ax
		mov	ax, es:uiThreadHandle
		tst	ax
		jnz	cont
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo	; ax = ui process handle
		tst	ax		; ui thread is not running yet
		jz	doneC
		mov	es:uiThreadHandle, ax
cont:	;
	; call ui thread
	;
		mov_tr	bx, ax
		mov	ax, MSG_PROCESS_CALL_ROUTINE
		mov	dx, size ProcessCallRoutineParams
		mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
		call	ObjMessage
		add	sp, size ProcessCallRoutineParams	; CF = 0
reallyDone:
		.leave
		ret
doneC:
		stc
		jmp	reallyDone
CallOnUiThread	endp

ResolverResidentCode	ends
