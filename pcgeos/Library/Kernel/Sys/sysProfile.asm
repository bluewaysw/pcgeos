COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		profile
FILE:		profile.asm

AUTHOR:		Ian Porteous, Sep 29, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	9/29/94   	Initial revision


DESCRIPTION:
	profiling routines

	$Id: sysProfile.asm,v 1.1 97/04/05 01:14:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	Internal/xms.def

XMSFlags	record
	XMSF_CACHE_DIRTY:1,	; indicates whether the cache is dirty
				; or not 
XMSFlags	end
		
	
;------------------------------------------------------------------------------
;	Constants
;------------------------------------------------------------------------------
XMS_TEST_SIZE	equ	128	; Number of bytes to copy in and out of the
				;  first K in the final 64K of any extended
				;  memory block we allocate.

XMS_PRESENT?	= 0x4300	; value in AX for int 2fh to determine
				;  if XMM is present
XMS_HERE	= 0x80		; value returned in al if manager is
				;  around
XMS_ADDRESS?	= 0x4310	; value in AX for int 2fh to fetch
				;  the entry point for the XMM

XMS_PAGE_SIZE	equ 0x40		; size in KB, 64KB pages

XMS_PAGE_TABLE_LENGTH	equ 256	; number of page table entries

PROFILE_CACHE_SIZE	equ 0x2000; 8KB cache size

;------------------------------------------------------------------------------
;	Fatal Errors
;------------------------------------------------------------------------------

PROFILE_COULD_NOT_WRITE_TO_XMS 		enum FatalErrors

PROFILE_ADDRESS_OUT_OF_RANGE		enum FatalErrors


PROFILE_EXPECTED_A_PAGE 		enum FatalErrors
;  Read from a page that has not yet been written to
;

PROFILE_ENTRY_SIZE_ZERO			enum FatalErrors
; Tried to read an entry of size zero.  What's up ?
;

PROFILE_TRANSFER_FAILED			enum FatalErrors
; Tried to transfer memory from Xms memory to the cache 
; and failed.
	
;------------------------------------------------------------------------------
;	Uninitialized Variables
;------------------------------------------------------------------------------
if PROFILE_LOG
udata	segment

xmsMoveParams	XMSMoveParams
	;
	; address of the xms memory manager.  This variable is used by
	; the swat module log.tcl.  If you change it, you will also
	; want to change log.tcl
	;
xmsAddr		fptr.far
	
	;
	; page table containing the handles to XMS memory blocks
	;
xmsPageTable	word XMS_PAGE_TABLE_LENGTH dup(?)

	;
	; handle and segment to the cache
	;
profileCacheHandle	hptr
profileCacheSegment	sptr

	;
	; current offset into the cache
	;
profileCacheOffset	word

	;
	; the address of the cache in xms memory
	;
xmsCacheAddress		dword

	; 
	; xms status flag
	;
xmsFlags	XMSFlags


udata	ends

idata	segment

profileModeFlags	ProfileModeFlags

profileSem		Semaphore <>

idata	ends

endif

;------------------------------------------------------------------------------
;	Code
;------------------------------------------------------------------------------

ProfileLessCommonCode	segment resource

if PROFILE_LOG

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize variables and data structures for 
		profiling 

CALLED BY:	Internal
PASS:		di	-> LibraryCallType
		cx	-> Handle of client

		ds	-> dgroup

RETURN:		carry set on error

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileInit	proc	far
	uses	ax,bx,cx
	.enter

	call	XmsInit
	jc	done
	;
	; allocate room for the log cache.  Make it fixed so it will
	; not get swapped.
	;
	mov	ax, PROFILE_CACHE_SIZE
	mov	ch, HAF_STANDARD
	mov	cl, ALLOC_FIXED
	call	MemAllocFar
	jc	done
	mov	ds:[profileCacheHandle], bx
	mov	ds:[profileCacheSegment], ax
	clr	ds:[profileCacheOffset]

	and	ds:[xmsFlags], not (mask XMSF_CACHE_DIRTY)
	clc
done:
	.leave
	ret

ProfileInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End profiling.  This will free the profiling cache and
		clear all of the profiling flags. It will also free
		all allocated xms blocks.

CALLED BY:	Internal
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileExit	proc	far
	uses	bx, dx, ax
	.enter

	;
	; Free memory allocated for the cache
	;
	mov	bx, ds:[profileCacheHandle]
	call	MemFree

	;
	; Free the xms memory allocated
	;
	clr	bx
freeXMS::
	mov	dx, ds:[xmsPageTable][bx]
	tst	dx
	jz	freed
	mov	ah, XMS_FREE_EMB
	call	ds:[xmsAddr]
	inc	bx
	inc	bx
	jmp 	freeXMS
freed:

	clr	ds:[profileCacheSegment]
	clr	ds:[profileModeFlags]
	.leave
	ret
ProfileExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsCheckFinal64K
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that we can actually read and write the final 64K
		of our extended memory block. It is sufficient to ensure we
		can read and write the first 128 bytes of the final 64K.
		This is to detect a buggy version of Microsoft's HIMEM.SYS
		that erroneously includes the HMA in the total extended
		memory available.

CALLED BY:	XmsInit
PASS:		ds	= dgroup
		ax	= number of Kb in our extended memory block
		dx	= the handle of our extended memory block
RETURN:		ax	= number of usable Kb in our extended memory block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsCheckFinal64K proc	near
kbUsable	local	word \
		push	ax		; assume all of it's usable
kbTrimmed	local	word
		uses	bx, cx, dx, ds, es, si, di
		.enter
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_handle, dx
	;
	; Figure the Kb offset to which to copy. It should be 64 less than
	; the total size. If the total size is less than 64K, however, just
	; use an offset of 0.
	; 
		sub	ax, 64
		jge	setDest
		clr	ax		; just check offset 0
setDest:
		mov	ss:[kbTrimmed], ax
	;
	; Shift to multiply the result by 2**10 (1024)
	; 
		clr	bx
		shl	ax
		rcl	bx
		shl	ax
		rcl	bx
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.low.low, 0
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.low.high, al
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.high.low, ah
		mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.high.high, bl
	;
	; Allocate a block twice the size of the test sample so we've got
	; a source from which to copy the test pattern out and a destination
	; to which to copy it back.
	;
		mov	cx, mask HF_FIXED
		mov	ax, XMS_TEST_SIZE*2
		call	MemAllocFar
		mov	es, ax		; es <- test block
		
	;
	; Initialize the low half of the block to some nice pattern, in this
	; case b[0] = block handle, b[i+1] = b[i]+17.
	; 
		clr	di
		mov	ax, bx
		mov	cx, XMS_TEST_SIZE/2
initLoop:
		stosw
		add	ax, 17
		loop	initLoop
	;
	; Perform the move out to extended memory.
	;
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_handle, 0
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.offset, 0
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.segment, es
		mov	ds:[xmsMoveParams].XMSMP_count.low, XMS_TEST_SIZE
		
		mov	ah, XMS_MOVE_EMB
		mov	si, offset xmsMoveParams
		call	ds:[xmsAddr]
		tst	ax
		jz	trim
	;
	; Now swap the source and dest, setting the dest to the second half of
	; the test staging area we allocated.
	;
		clr	ax
		xchg	ax, ds:[xmsMoveParams].XMSMP_dest.XMSA_handle
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_handle, ax
		mov	ax, XMS_TEST_SIZE
		xchg	ax, ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.offset
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.offset, ax
		mov	ax, es
		xchg	ax, ds:[xmsMoveParams].XMSMP_dest.XMSA_offset.segment
		mov	ds:[xmsMoveParams].XMSMP_source.XMSA_offset.segment, ax
		
		mov	ah, XMS_MOVE_EMB
		call	ds:[xmsAddr]
		tst	ax
		jz	trim
	;
	; Compare the two halves.
	;
		push	ds
		segmov	ds, es
		clr	si
		mov	di, XMS_TEST_SIZE
		mov	cx, XMS_TEST_SIZE/2
		repe	cmpsw
		pop	ds
		je	done
trim:
		mov	ax, ss:[kbTrimmed]
		mov	ss:[kbUsable], ax
done:
	;
	; Recover the staging-area's handle from its first word (clever of us
	; to use that pattern, wot?) and free the bloody thing.
	; 
		mov	bx, es:[0]
		call	MemFree
	;
	; Fetch the number of usable K on which we decided..
	;
		mov	ax, ss:[kbUsable]
		.leave
		ret
XmsCheckFinal64K endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XmsInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to Initialization the XMS memory for profiling

CALLED BY:	XmsInit
PASS:		DS	= dgroup
RETURN:		Carry set on error
DESTROYED:	AX, BX, ...

PSEUDO CODE/STRATEGY:
	Find the largest free block in extended memory and allocate it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/89		Initial version
	ian	9/29/94		modified for use by the profiling
				library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XmsInit		proc	far 	uses es, di, si
		.enter
	;
	; Make sure DOS is >= 3.0
	;
		mov	ax, MSDOS_GET_VERSION shl 8
		call	FileInt21
		cmp	al, 3
		LONG jb	outtaHere	; => major version < 3, so no XMS
					;  possible.
checkXms::
	;
	; See if an Extended Memory Manager is present.
	;
		mov	ax, XMS_PRESENT?
		int	2fh
		cmp	al, XMS_HERE
		je	fetchXMSAddr
		stc
		jmp	outtaHere

fetchXMSAddr:
	;
	; Fetch the entry address for the thing.
	;
EC <		push	es		; avoid segment-checking death 	>
		mov	ax, XMS_ADDRESS?
		int	2fh
		mov	ds:xmsAddr.offset, bx
		mov	ds:xmsAddr.segment, es
EC <		pop	es						>





tryForEMB::
	;
	; Allocate the largest free EMB.
	; XXX: Allocate them all, if more than one?
	;
		mov	ah, XMS_QUERY_FREE_EMB
		call	ds:[xmsAddr]
		tst	ax
		jz	noEMB

		push	ax		; Save block size...
		mov	dx, ax		; Give me THIS much
		mov	ah, XMS_ALLOC_EMB
		call	ds:[xmsAddr]
		tst	ax		; success?
		pop	ax
		jz	noEMB		; Nope. Yuck


		call	XmsCheckFinal64K
		tst	ax		; anything useful?
		jnz	haveEMB		; yup -- keep it

		mov	ah, XMS_FREE_EMB; bleah
		call	ds:[xmsAddr]
		jmp	noEMB

haveEMB:
	;
	; At this point ax contains the number of Kb we have
	; allocated and dx the handle of the block allocated.
	;
		mov	ah, XMS_FREE_EMB; bleah
		call	ds:[xmsAddr]

		clc
outtaHere:
		.leave
		ret

noEMB:	
		stc
		jmp	outtaHere

XmsInit		endp

else
;
;  None Of these routines should be called from the non PROFILE_LOG
;  kernel, but to keep the export table for the kernel consistent,
;  they must be defined
;
ProfileInit	proc	far
	ret
ProfileInit	endp

ProfileExit	proc	far
	ret
ProfileExit	endp	

endif

ProfileLessCommonCode	ends

if PROFILE_LOG

if 0
;--------------------------------------------------------------------------
; ProfileReadLogEntry allows the log to be accessed by geos code.  For
; now the log is only read from swat.  However, if we decide to read
; the data from geos, this code can be used.
;--------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileReadLogEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a log entry into a data block

CALLED BY:	
PASS:		es:di	- destination buffer
		bx:cx	- virtual address of entry to read
RETURN:		carry set when end of log reached.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileReadLogEntry	proc	far
entryAddress		local	dword	push  	bx, cx
destinationSegment	local	sptr	push	es
entrySize		local	byte
	uses	ax,bx,cx,dx,si,bp,ds,es,di
	.enter

	segmov	ds, dgroup, ax
	movdw	dxax, ds:[xmsCacheAddress]

	;
	; check to see if virtual address is below the cache
	;
	subdw	bxcx, dxax
	jb	loadCache
	
	;
	; check to see if the virtual address is above the cache
	;
	tst	bx
	jnz	loadCache
	
	cmp	cx, PROFILE_CACHE_SIZE
	jg	loadCache

	mov	bx, cx
	;
	; bx	- contains the offset into the cache of this entry
	;
	mov	es, ds:[profileCacheSegment]
	clr	cx
	mov	cl, es:[bx]
	mov	ss:[entrySize], cl
	add	cx, bx

	cmp	cx, PROFILE_CACHE_SIZE
	jg	loadCache

readLogEntry:
	;
	; bx		- contains the offset into the cache of this entry
	; ds:[entrySize]- contains the size of the this log entry
	;
	; Now we are ready to copy the data from the cache to the
	; destination 
	;
	mov	es, ss:[destinationSegment]	; es:di <- destination
	clr	cx
	mov	cl, ss:[entrySize]
	tst	cl				
	jz	endOfLog
	mov	ds, ds:[profileCacheSegment]
	mov	si, bx
	rep	movsb
done:
	.leave
	ret

endOfLog:
	stc	
	jmp	done

loadCache:
	;
	; We need to make sure that we write any data currently in the
	; cache out before we load it with new data
	;
	call	ProfileFlushCache

	movdw	bxcx, ss:[entryAddress]
	movdw	ds:[xmsCacheAddress], bxcx	; save the new xms
						; address of the cache
	mov	dx, ds:[profileCacheSegment]
	clr	si
	mov	ax, PROFILE_CACHE_SIZE
	;
	; dx:si <- destination of read
	; bx:cx <- virtual xms address to read from
	; ax	<- number of bytes to read

	call	XMSReadBlock

	;
	; The begining of the cache is now at the beginning of the
	; entry we are interested in, so find out how many bytes are
	; in that entry and put it in entrySize
	;
	mov	es, dx				; es <- cache segment
	mov	bl, es:PLE_size
	mov	ss:[entrySize], bl
	clr	bx
	
	jmp	readLogEntry
	

ProfileReadLogEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSReadBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the specified block of data to XMS memory.  A
		read can not be larger than XMS_PAGE_SIZE.

CALLED BY:	ProfileFlushCache
PASS:		dx:si	- (sourceAddress) fptr to source of block to write
		ax	- (numBytes) number of bytes
		bx:cx	- (destAddress) virtual xms address to write to 


RETURN:		bx:cx	- lastAddress written to + 1
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSReadBlock	proc	near
xmsTransferCallback	local	nptr
	.enter 

	mov	ss:[xmsTransferCallback], offset XMSReadBlockLow
	
	call 	XMSReadWriteCommon

	.leave
	ret
XMSReadBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSReadBlockLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block from memory, without worrying about whether
		or not the data will come from a single page or not

CALLED BY:	XMSReadBlock
PASS:		dx:si	- (destAddress) fptr to source dest of block
		ax	- (numBytes) number of bytes
		bx:cx	- (sourceAddress) virtual xms address to read
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSReadBlockLow	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	segmov	ds, dgroup, di
	push	dx
	mov	dx, ds:[xmsPageTable][bx]

EC<	tst	dx	>
EC<	ERROR_Z	PROFILE_EXPECTED_A_PAGE >

	mov	ds:[xmsMoveParams].XMSMP_source.XMSA_handle, dx
	movdw	ds:[xmsMoveParams].XMSMP_source.XMSA_offset, bxcx

	pop	dx
	clr	ds:[xmsMoveParams].XMSMP_dest.XMSA_handle 
	clr	ds:[xmsMoveParams].XMSMP_count.high
	mov	ds:[xmsMoveParams].XMSMP_count.low, ax
	movdw	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset, dxsi

	call	XMSTransfer

	.leave
	ret
XMSReadBlockLow	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the profile log.  clr the profileModeFlags,
		free all of the xms memory handles, clr
		xmsCacheAddress, and profileCacheOffset.

CALLED BY:	Swat
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	frees any xms pages
	clears the handle of allocated xms pages in the xmsPageTable
	clears the xmsCacheAddress
	clears the profileCacheOffset
	clears the profileModeFlags
	clears the xmsFlags
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileReset	proc	far
	uses	ax, bx, dx, ds
	.enter
	
	segmov	ds, dgroup, ax
	;
	; Free the xms memory allocated
	;
	clr	bx
freeXMS:	
	mov	dx, ds:[xmsPageTable][bx]
	tst	dx
	jz	freed
	mov	ah, XMS_FREE_EMB
	push	bx
	call	ds:[xmsAddr]
	pop	bx
	clr	{word}(ds:[xmsPageTable][bx])
	inc	bx
	inc	bx
	jmp	freeXMS
freed:
	clrdw	ds:[xmsCacheAddress]
	clr	ds:[profileCacheOffset]
	clr 	ds:[profileModeFlags]
	clr	ds:[xmsFlags]

	.leave
	ret
ProfileReset	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileWriteMessageEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a ProfileMessageEntry to the profiling log

CALLED BY:	GLOBAL
PASS:		ax	= message
		cx	= ProfileLogEntryType
		bxsi	= other data

RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileWriteMessageEntry	proc	far
profileEntry	local	ProfileMessageEntry
	uses	ds, dx, si
	.enter
	;
	; First test and make sure that the profiling mode associated
	; with this entry, is turned on
	;
	segmov	ds, dgroup, dx
	mov	dl, ds:[profileModeFlags]
	and 	dl, mask PMF_MESSAGE
	jz	exit

	; This is for the case when we are recording the class of a
	; message in ObjCallMethod table
	movdw	ss:[profileEntry].PME_class, esdi
	
	movdw 	ss:[profileEntry].PME_data, bxsi

	mov	ss:[profileEntry].PME_header.PLE_type, cx
	mov	ss:[profileEntry].PME_message, ax
	mov	ax, ss:[TPD_threadHandle]
	mov	ss:[profileEntry].PME_thread, ax
	movdw	ss:[profileEntry].PME_address, ss:[bp+2], ax

	lea	si, ss:[profileEntry]
	segmov	ds, ss, ax
	mov	cx, size ProfileMessageEntry
	call	ProfileWriteLogEntry
exit:
	.leave
	ret
ProfileWriteMessageEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileWriteGenericEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an ProfileGenericEntry to the profiling log

CALLED BY:	GLOBAL
PASS:		ax	= ProfileEntryType
		bl	= ProfileModeFlags
		cx	= word of data
RETURN:		nothing
DESTROYED:	bx, ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileWriteGenericEntry	proc	far
	push	bp
	mov	bp, sp
	uses	ds, dx, di, si
	.enter

	movdw	dxdi, ss:[bp+2]
	call 	ProfileWriteGenericEntryCommon

	.leave
	pop	bp
	ret
ProfileWriteGenericEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileWriteProcCallEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes a generic entry to the profiling log.  Same as
		ProfileWriteGenericLogEntry, except that it takes a
		pointer to store in the entry

CALLED BY:	Global (macro InsertProcCallEntry)
PASS:		ax	= ProfileEntryType
		bl	= ProfileModeFlags
		cx	= word of data
		^hdx:di	= procedure being called
RETURN:		nothing
DESTROYED:	bx, ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileWriteProcCallEntry	proc	far
	uses	ds, si
	.enter
	call ProfileWriteGenericEntryCommon
	.leave
	ret
ProfileWriteProcCallEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileWriteGenericEntryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an entry to the profiling log

CALLED BY:	GLOBAL
PASS:		ax	= ProfileEntryType
		bl	= ProfileModeFlags
		cx	= word of data
		dx:di	= dword to store in the entry

RETURN:		nothing
DESTROYED:	ds, dx, ax, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileWriteGenericEntryCommon	proc	near
profileEntry	local	ProfileGenericEntry
	.enter
	;
	; First test and make sure that the profiling mode associated
	; with this entry, is turned on
	;
	
	push 	dx	
	segmov	ds, dgroup, dx
	mov	dl, ds:[profileModeFlags]
	and 	dl, bl
	pop	dx
	jz	exit
	
	mov	ss:[profileEntry].PGE_header.PLE_type, ax
	movdw	ss:[profileEntry].PGE_address, dxdi
	mov	ax, ss:[TPD_threadHandle]
	mov	ss:[profileEntry].PGE_data, cx
	mov	ax, ss:[TPD_threadHandle]
	mov	ss:[profileEntry].PGE_thread, ax

	lea	si, ss:[profileEntry]
	segmov	ds, ss, ax
	mov	cx, size ProfileGenericEntry
	call	ProfileWriteLogEntry
exit:
	.leave
	ret
ProfileWriteGenericEntryCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileWriteLogEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write a block of data to the profiling log.  Null is
		written to the word after the log entry, this
		indicates the end of the log has been reached. This
		routine also adds the time stamp to the entry.

CALLED BY:	
PASS:		cx 	- size of block to write
		ds:si	- data to write

RETURN:		carry set on error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Add a time stamp to the log entry
	p the profile semaphore so more than one thread will not
		try to write to the profile log at the same time
	See if the data will fit in the cache.  
	If it does not, 
		flush the cache to XMS memory and reset the cache
		index. 
	Write the data to the cache.
	v the profile sem

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileWriteLogEntry	proc	far
		uses	ax,bx,cx,si,di,ds,es
	.enter
	;
	; add room for an end of log marker
	;
	inc	cx
	inc	cx

	;
	; Insert a time stamp into the entry
	;
	pushf	
	call	TimerStartCount
	mov	ds:[si].PLE_timeStamp.high, bx
	mov	ds:[si].PLE_timeStamp.low, ax
	popf

	push	ds
	segmov	ds, dgroup, ax
	PSem	ds,profileSem, TRASH_AX_BX


	mov	es, ds:[profileCacheSegment]
	mov	di, ds:[profileCacheOffset]

	mov	bx, cx	
	add	bx, di
	cmp	bx, PROFILE_CACHE_SIZE
	jbe	writeData

	;
	; Flush the cache if neccessary by writing everything in the
	; cache up to the profileCacheOffset to xms memory.
	;
flushCache::

	call	ProfileFlushCache
	clr	di				; profileCacheOffset <- 0

	;
	; Copy the data passed to ProfileWriteLogEntry into the cache.
	;
writeData:
	;
	; mark the cache as dirty
	;
	or	ds:[xmsFlags], mask XMSF_CACHE_DIRTY

	;
	; We want to write a 0 at the end of the log, so we added 2 to
	; cx to make room for it.  However, we don't want that extra
	; space added on when we do the copy, so subtract 2 from cx.
	; After we do the copy, the next word in the destination
	; buffer will be cleared.
	;
	dec	cx
	dec	cx

	pop	ax				
	push	ds				; save dgroup
	mov	ds, ax				; restore the address
						; of the source location
	rep	movsb				; mov data into cache
	pop	ds				; restore dgroup
	mov	ds:[profileCacheOffset], di
	;
	; mark the end of the log.  
	;
	clr	{word}es:[di]	
	
	VSem	ds, profileSem,  TRASH_AX_BX
	.leave
	ret
ProfileWriteLogEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileFlushCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the cache to XMS memory

CALLED BY:	ProfileWriteLogEntry
PASS:		ds	- udata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	updates:

		xmsCacheAddress is changed to point to the address
		after the old cache.  Since data is written out
		sequentially, this should be the base address for the
		new cache.  

		ProfileFlushCache is only called from
		ProfileReadLogEntry when a new section of the log is
		going to be loaded into the cache.  When that happens,
		the xmsCacheAddress will be overwritten.

pPSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileFlushCacheFar	proc	far
	.enter
	call 	ProfileFlushCache
	.leave
	ret
ProfileFlushCacheFar	endp

ForceRef	ProfileFlushCacheFar

ProfileFlushCache	proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter

	; 
	; test to see if we need to flush the cache
	;
	mov	dl, mask XMSF_CACHE_DIRTY
	and	dl, ds:[xmsFlags]
	jz	exit

	mov	dx, ds:[profileCacheSegment]	
	clr	si				; dx:si fptr to data
						; to write
	mov	ax, ds:[profileCacheOffset]	; number of bytes to
						; write 
	;
	; Make sure that the null word at the end of the cache is
	; written.
	;
	inc	ax
	inc	ax
if 0	;
	;  The assumption that log entries are word aligned, has been
	;  made for the purposes of reading things from swat, so this
	;  code to word align things, is no longer neccessary.
	; 
	; need to find out if it is word aligned, if it is alread word
	; aligned, no worries.  Otherwise we need to word align it and
	; then fixup the return address when we are done.
	;
	mov	bp, 1
	and	bp, ax
	jz	even1
	inc	ax
even1:
endif
	movdw	bxcx, ds:[xmsCacheAddress]

	call	XMSWriteBlock			; flush the cache to
						; xms memory

EC<	ERROR_C	PROFILE_COULD_NOT_WRITE_TO_XMS 	>
if 0
	;
	; If we had to change the size of the transfer to word align
	; it, then we need to dec the size of the transfer here so
	; that when we write the data again, it will be to the correct
	; place. 
	;
	tst	bp
	jnz	even2
	decdw	bxcx
even2:
endif
	;
	; Do not want to count the Null teerminating word written at
	; the end of the cache.
	;
	decdw	bxcx	
	decdw	bxcx	
	movdw 	ds:[xmsCacheAddress],bxcx
	or	ds:[xmsFlags], not (mask XMSF_CACHE_DIRTY)  ; The cache is Clean
exit:
	.leave
	ret
ProfileFlushCache	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSWriteBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the specified block of data to XMS memory.  A
		single write can not be larger than XMS_PAGE_SIZE.

CALLED BY:	ProfileFlushCache
PASS:		dx:si	- (sourceAddress) fptr to source of block to write
		ax	- (numBytes) number of bytes
		bx:cx	- (destAddress) virtual xms address to write to 


RETURN:		bx:cx	- lastAddress written to + 1
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSWriteBlock	proc	near
xmsTransferCallback	local	nptr
	.enter 

	mov	ss:[xmsTransferCallback], offset XMSWriteBlockLow
	
	call 	XMSReadWriteCommon

	.leave
	ret
XMSWriteBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSReadWriteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the specified block of data to XMS memory.  A
		single write can not cross more than one page.  So the
		largest write is XMS_PAGE_SIZE.

CALLED BY:	ProfileFlushCache
PASS:		dx:si	- (sourceAddress) fptr to source of block to write
		ax	- (numBytes) number of bytes
		bx:cx	- (destAddress) virtual xms address to write to 


RETURN:		bx:cx	- lastAddress + 1
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSReadWriteCommon	proc	near
	uses	ax,dx,si,di,bp
xmsTransferCallback	local	nptr
	.enter inherit

	;
	; Test to see if the write crosses a page.  We don't support a
	; write larger than one page size, so we don't have to worry
	; about the write crossing more than one page.
	;
	push	cx
	add	cx, ax	
	pop	cx
	jc	twoPages

onlyOnePage::
	call	ss:[xmsTransferCallback]
	add	cx, ax
	adc	bx, 0
	
exit:
	.leave
	ret

twoPages:
	;
	; write the data on the first page
	;
	push	ax
	mov	ax, cx
	neg	ax				; ax <- number of
						; bytes left on first
						; page.
	call	ss:[xmsTransferCallback]
	;
	; write the data out to the second page.
	;
	inc	bx
EC<	ERROR_Z	PROFILE_ADDRESS_OUT_OF_RANGE >
	clr	cx
	add	si, ax				; si <- data to write
						; to second page
	mov_tr	di, ax
	pop	ax
	sub	ax, di				; ax <- number of
						; bytes to write on
						; second page
	call	ss:[xmsTransferCallback]
	add	cx, ax
	adc	bx, 0
	jmp	exit

XMSReadWriteCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSWriteBlockLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write block to memory, without worrying about whether
		or not the data will fit in a single page or not

CALLED BY:	XMSWriteBlock
PASS:		dx:si	- (sourceAddress) fptr to source of block to write
		ax	- (numBytes) number of bytes
		bx:cx	- (destAddress) virtual xms address to write to 
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSWriteBlockLow	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	segmov	ds, dgroup, di
	push	dx
	call	XMSCheckAndAlloc		

EC<	ERROR_C	PROFILE_EXPECTED_A_PAGE >

	clr 	bx	
	movdw	ds:[xmsMoveParams].XMSMP_count, bxax
	mov	ds:[xmsMoveParams].XMSMP_dest.XMSA_handle, dx
	movdw	ds:[xmsMoveParams].XMSMP_dest.XMSA_offset, bxcx
	pop	dx
	clr	ds:[xmsMoveParams].XMSMP_source.XMSA_handle
	movdw	ds:[xmsMoveParams].XMSMP_source.XMSA_offset, dxsi

	call	XMSTransfer

EC<	ERROR_C	PROFILE_TRANSFER_FAILED >

	.leave
	ret
XMSWriteBlockLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSCheckAndAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if this xms page has been allocated yet
		by checking xmsPageTable.
		If so return it.  Otherwise attempt to allocate a
		page. 

CALLED BY:	XMSWriteBlock
PASS:		ds	-dgroup
		bx	- page to check
RETURN:		carry set on error
		or
		dx	- handle of allocated page

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSCheckAndAlloc	proc	far
	uses 	ax
	.enter
	;
	; The assumption made here is that the size of xms page tables
	; is 64K.  This allows the high word of the address to be the
	; offset into the page table, and the low word to be the
	; offset into the page
	;
	CheckHack <XMS_PAGE_SIZE EQ 64>
	shl	bx, 1
EC<	ERROR_C	PROFILE_ADDRESS_OUT_OF_RANGE >
	mov	dx, ds:[xmsPageTable][bx]
	tst	dx
	jz	allocPage

exit:
	.leave
	ret
	
allocPage:
	push	bx
	mov	dx, XMS_PAGE_SIZE
	mov	ah, XMS_ALLOC_EMB
	call	ds:xmsAddr
	pop	bx
	tst	ax
	jz	error
	mov	ds:[xmsPageTable][bx], dx
	clc	
	jmp	exit
error:
	stc					;allocation failed :(	
	jmp	exit
XMSCheckAndAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XMSTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a move to or from extended memory

CALLED BY:	XMSWriteBlockLow
PASS:		ds			= dgroup	
		ds:[xmsMoveParams]	= setup for transfer
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSTransfer	proc	near
	uses	ax
	.enter
	call	SysLockBIOSFar

	mov	si, offset xmsMoveParams
	mov	ah, XMS_MOVE_EMB
	call	ds:[xmsAddr]
	shr	ax			; Set carry if AX == 0
	cmc

	call	SysUnlockBIOSFar
	.leave
	ret
XMSTransfer	endp

else

;
;  None Of these routines should be called from the non PROFILE_LOG
;  kernel, but to keep the export table for the kernel consistent,
;  they must be defined
;
ProfileWriteLogEntry	proc	far
	ret
ProfileWriteLogEntry	endp

if 0

ProfileReadLogEntry	proc	far
	ret
ProfileReadLogEntry	endp

endif 

ProfileWriteGenericEntry	proc	far
	ret
ProfileWriteGenericEntry	endp

ProfileWriteMessageEntry	proc	far
	ret
ProfileWriteMessageEntry	endp

ProfileWriteProcCallEntry	proc	far
	ret
ProfileWriteProcCallEntry	endp

ForceRef 	ProfileWriteProcCallEntry

ProfileReset	proc	far
	ret
ProfileReset	endp	


endif
