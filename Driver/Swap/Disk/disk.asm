COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Driver/Swap/Disk -- Memory Swapping to Disk
FILE:		disk.asm

AUTHOR:		Adam de Boor, Jun 11, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/11/90		Initial revision


DESCRIPTION:

	This driver contains routines to swap blocks on the heap to a single
	swap file.
	
	The swap file resides on a fixed disk only and is of a fixed maximum
	size, though the actual size of the file starts at 0 and grows as the
	system swaps more and more. For now, the file never shrinks, though that
	might be a good optimization at some point.
	
	The space in the swap file is tracked by a fixed block called the "swap
	map". This block is allocated by SwapRealInit and remains until SwapExit
	is called. Each word in the map represents a page in the swap file and
	contains the offset of the next word in the list to which the page
	belongs -- either the free list or the page list for a block.
	
	The size of a "page" is set by the call to SwapRealInit, as is the total
	size of the swap file itself.
	
	The free list is kept sorted so pages at the start of the file will
	be allocated before pages at the end (attempt to keep the file from
	growing too big unnecessarily).
	
	The allocation attempts to keep a block contiguous so it can be read
	and written with a single call. It does this at the expense of making
	the file big. There should, perhaps, be a threshold at which the
	size of the file becomes a priority and multiple writes/reads/seeks will
	be issued instead. Given a reasonable-sized page, however, we do not
	anticipate much of a fragmentation problem, so perhaps this isn't an
	issue. Empiricism needs must triumph here.

	$Id: disk.asm,v 1.1 97/04/18 11:58:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_SwapDriver		=	1
_Driver			=	1

;------------------------------------------------------------------------------
;	Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include driver.def
include sem.def
include system.def
include file.def
include initfile.def
include drive.def
include disk.def
include Internal/heapInt.def
include localize.def

UseDriver Internal/fsDriver.def
include	Internal/dosFSDr.def

include Internal/interrup.def
include Internal/fileInt.def		;includes dos.def as well
DefDriver Internal/swapDr.def

UseLib	Internal/swap.def

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

SWAP_DEFAULT_PAGE =	2048	;2K is the default page size

SWAP_DEFAULT_SIZE =	(2 * 1024)	; 2 Mb is the default swap size

CANNOT_OPEN_SWAP_FILE					enum FatalErrors
CANNOT_READ_SWAP_FILE					enum FatalErrors

udata	segment

swapFile	hptr	0			; Handle of open swap file.
dosSwapFile	word	0			; handle for dos file
diskSwapMap	sptr.SwapMap			; Base of swap map.
SBCS <swapFileName	char	PATH_BUFFER_SIZE dup(0)	; Name of swap file for>
DBCS <swapFileName	wchar	PATH_BUFFER_SIZE dup(0)	; Name of swap file for>
						;  removal on exit

LOG_ACTIONS	= FALSE


if	LOG_ACTIONS
%out TURN OFF ACTION LOGGING BEFORE YOU INSTALL

MAX_LOG		equ	128
logPtr		word	0

OpType		etype	word
OP_READ		enum	OpType
OP_WRITE	enum	OpType

opLog		OpType	MAX_LOG dup(?)
segLog		sptr	MAX_LOG	dup(?)
offLog		word	MAX_LOG dup(?)
sizeLog		sword	MAX_LOG dup(?)
pageLog		word	MAX_LOG dup(?)

endif

udata	ends

idata	segment

DriverTable	DriverInfoStruct <DiskStrategy,<>,DRIVER_TYPE_SWAP>

idata	ends

Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for this here driver

CALLED BY:	Kernel
PASS:		di	= function code
		refer to swapDriver.def for interface
RETURN:		depends on function invoked
DESTROYED:	depends on function invoked

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
diskFunctions	nptr	DiskExit, DiskDoNothing, DiskDoNothing,
			DiskSwapOut, DiskSwapIn, DiskDiscard,
			DiskGetMap, DiskDoNothing, DiskDoNothing,
			DiskDoNothing

DiskStrategy	proc	far	uses ds, es
		.enter
		segmov	ds, dgroup, ax	; ds <- data segment
		
	;
	; Special-case DR_INIT as it's in a movable module.
	;
		cmp	di, DR_INIT
		jne	notInit
		call	DiskInit
done:
		.leave
		ret
notInit:
		call	cs:diskFunctions-2[di]
		jmp	done
DiskStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskSwapOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap a block out to disk

CALLED BY:	DR_SWAP_SWAP_OUT
PASS:		dx	= segment of data block
		cx	= size of data block (bytes)
RETURN:		carry clear if no error
		ax	= swap ID of block
DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
	Allocate room for the block in the swap file. If can't, return error.
	Call WritePageList to write the data to the swap file.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskSwapOut	proc	near
		.enter
		mov	ax, ds:diskSwapMap
		call	SwapWrite
		.leave
		ret
DiskSwapOut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskSwapIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap a block in from disk

CALLED BY:	DR_SWAP_SWAP_IN
PASS:		ds	= dgroup
		bx	= ID of swapped data (initial page)
		dx	= segment of destination block
		cx	= size of data block (bytes)
RETURN:		carry clear if no error
DESTROYED:	ax, bx, cx (ds, es preserved by DiskStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	ardeb	12/ 9/89	Changed to single-swapfile model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskSwapIn	proc	near
		.enter
		mov	ax, ds:[diskSwapMap]
		call	SwapRead
		.leave
		ret
DiskSwapIn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskDiscard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the swap space associated with a block

CALLED BY:	DR_SWAP_DISCARD
PASS:		bx	= ID returned from DR_SWAP_SWAP_OUT (first page #)
		ds	= dgroup
RETURN:		carry clear if no error
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	Free up the page list whose head is bx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Jim's code review added
	ardeb	12/9/89		Changed to single-swapfile model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskDiscard	proc	near
		.enter
		mov	ax, ds:diskSwapMap
		call	SwapFree
		.leave
		ret
DiskDiscard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskGetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the segment of the swap map used by the driver.

CALLED BY:	DR_SWAP_GET_MAP
PASS:		ds	= dgroup
RETURN:		ax	= segment of swap map
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskGetMap	proc	near
		.enter
		mov	ax, ds:[diskSwapMap]
		.leave
		ret
DiskGetMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish swapping by closing and removing the swapfile
		we opened on startup.

CALLED BY:	EndGeos
PASS:		ds	= kdata
RETURN:		nothing
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskExit	proc	near
		.enter
if 0		; Kernel closes this for us, since it's still open.
		; XXX: if we double-fault, the thing won't be closed...
		mov	bx, ds:swapFile
		tst	bx
		jz	notSwappingToDisk
		clr	al
		call	FileClose
notSwappingToDisk:
endif
		mov	dx, offset swapFileName

if 0		; While this would be nice, it can't be done b/c FileDelete
		; will try to call DR_FS_FILE_IN_USE?, whose handler could
		; well not be in memory. Since the fs driver's file will have
		; been closed by now, there's no place from which to get the
		; code, so we die horribly...
		call	FileDelete
else
		; As Tony says, this is simply following the long-established
		; rules laid down for system drivers...sometimes, they're hacked
		mov	ah, MSDOS_DELETE_FILE
		call	FileInt21
endif
		.leave
		ret
DiskExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine for suspend/unsuspend

CALLED BY:	DR_SUSPEND, DR_UNSUSPEND
PASS:		who cares?
RETURN:		carry clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskDoNothing	proc	near
		.enter
		clc
		.leave
		ret
DiskDoNothing	endp


;==============================================================================
;
;		    UTILITY AND CALLBACK ROUTINES
;
;==============================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the swap file to the indicated page

CALLED BY:	DiskWritePage, DiskReadPage
PASS:		ax	= page number
		es	= SwapMap
		bx	= swap file handle	(dos file handle if appropiate)
RETURN:		carry set on error
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskPosition	proc	near
		uses	cx, dx
		.enter
		mul	es:[SM_page]
		mov	cx, dx
		xchg	dx, ax		; (1-byte inst)

		mov	al, FILE_POS_START
		call	SwapIsKernelInMemory?
		jc	geosMode
	;
	; use dos functions
	;
		mov	ah, MSDOS_POS_FILE
		int	21h
		jmp	done
		
geosMode:
		call	FilePos
done:		.leave
		ret
DiskPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskGetSwapFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle of our swap file.

CALLED BY:	DiskReadPage, DiskWritePage
PASS:		nothing
RETURN:		bx	= swap file handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
		If we are using the dos handle, 
		   if the dos handle is 0, create a new one

		else (we are using the geos handle)
		   if the dos handle in not 0, deallocate it. make it 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version
	ron	3/9/94		Added geos file / dos file stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskGetSwapFile	proc	near	uses ds
		.enter
		segmov	ds, dgroup, bx
		call	SwapIsKernelInMemory?
	;
	; geos case
	;
		mov	bx, ds:[swapFile]
		jnc	dosCase
		tst	ds:[dosSwapFile]
		stc
		jz	done
		call	DiskDeallocDosSwapFile		; updates dgroup
		stc
		jmp	done
	;
	; dos case
	;
dosCase:	mov	bx, ds:[dosSwapFile]
		tst	bx
		jnz	done
		call	DiskCreateDosHandleForFile	; updates dgroup
		clc
done:
		.leave
		ret
DiskGetSwapFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskReadPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read page(s) from the swap file for the swap library

CALLED BY:	SwapRead
PASS:		ds:dx	= address to which to read the page(s)
		ax	= starting page number
		cx	= number of bytes to read
		es	= segment of SwapMap
RETURN:		carry set if all bytes could not be read
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskReadPage	proc	far
		uses	cx
		.enter
if LOG_ACTIONS
		push	bx, di, ds
		mov	di, ds
		segmov	ds, dgroup, bx
		mov	bx, ds:[logPtr]
		mov	ds:opLog[bx], OP_READ
		mov	ds:segLog[bx], di
		mov	ds:offLog[bx], dx
		mov	ds:sizeLog[bx], cx
		mov	ds:pageLog[bx], ax
		inc	bx
		inc	bx
		cmp	bx, MAX_LOG * word
		jne	10$
		clr	bx
10$:
		mov	ds:[logPtr], bx
		pop	bx, di, ds
endif
		call	DiskGetSwapFile
		call	DiskPosition

		clr	al		; We accept errors
		call	SwapIsKernelInMemory?
		jc	geosMode
		mov	ah, MSDOS_READ_FILE
		int	21h
		jc	done
		cmp	ax, cx
		je	done
		mov	ax, ERROR_SHORT_READ_WRITE
		stc
		jmp	done
geosMode:
		call	FileRead
done:
EC <		ERROR_C	CANNOT_READ_SWAP_FILE				>
		.leave
		ret
DiskReadPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskWritePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write page(s) to the swap file for the swap library

CALLED BY:	SwapWrite
PASS:		ds:dx	= address from which to write
		ax	= starting page number
		cx	= number of bytes to write
		es	= segment of SwapMap
RETURN:		carry set if all bytes could not be written
			cx	= bytes actually written
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskWritePage	proc	far
		.enter
if LOG_ACTIONS
		push	bx, di, ds
		mov	di, ds
		segmov	ds, dgroup, bx
		mov	bx, ds:[logPtr]
		mov	ds:opLog[bx], OP_WRITE
		mov	ds:segLog[bx], di
		mov	ds:offLog[bx], dx
		mov	ds:sizeLog[bx], cx
		mov	ds:pageLog[bx], ax
		inc	bx
		inc	bx
		cmp	bx, MAX_LOG * word
		jne	10$
		clr	bx
10$:
		mov	ds:[logPtr], bx
		pop	bx, di, ds
endif
		call	DiskGetSwapFile
		call	DiskPosition
		clr	al		; We accept errors
		call	SwapIsKernelInMemory?
		jc	geosWrite
	;
	; Write the page out using dos instead of geos
	; becuase the filesystem code is currently swapped out
	;
		mov	ah, MSDOS_WRITE_FILE
		int	21h
		jmp	done
geosWrite:
		call	FileWrite
done:
		.leave
		ret
DiskWritePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskCreateDosHandleForFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a dos handle for a the swap file

CALLED BY:	DiskRealInit
PASS:		nothing
RETURN:		bx 	= dos file handle	
DESTROYED:	nothing
SIDE EFFECTS:	alters a variable in dgroup

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	11/17/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskCreateDosHandleForFile	proc	near
	uses	ax,ds, cx, dx, di,si
	.enter
	;
	; Get the FS driver so we can create the dos handle
	;
		mov	ax, GDDT_FILE_SYSTEM
		call	GeodeGetDefaultDriver
		tst	ax
		jz	fail			; not loaded, so we can do
						;  nothing
		mov_tr	bx, ax
		call	GeodeInfoDriver
		
		mov	cx, ds:[si].FSDIS_altProto.PN_major
		mov	dx, ds:[si].FSDIS_altProto.PN_minor

		cmp	cx, DOS_PRIMARY_FS_PROTO_MAJOR
		jne	fail
		cmp	dx, DOS_PRIMARY_FS_PROTO_MINOR
		jae	callDriver
fail:
		stc
		jmp	done
callDriver:
	;
	; Get SFN from file handle
	;
		push	ds				; FSDIS
		segmov	ds, dgroup, ax
		mov	bx, ds:[swapFile]
		mov	ax, SGIT_HANDLE_TABLE_SEGMENT
		call	SysGetInfo
		mov	ds, ax
		mov	bl, ds:[bx].HF_sfn
		
		pop	ds				; FSDIS
		mov	di, DR_DPFS_ALLOC_DOS_HANDLE
		call	ds:[si].FSDIS_altStrat
		clc
		segmov	ds, dgroup, ax
		mov	ds:[dosSwapFile], bx
done:
		
	.leave
	ret
DiskCreateDosHandleForFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskDeallocDosSwapFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deallocates dos handle for swap file.

CALLED BY:	DiskGetSwapFile
PASS:		ds	- dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		It is necessary to alloc / dealloc the dos handle as
		needed rather than holding on to one across login's.
		In SchoolView where we logout the user while running
		geos, the handles get closed and opened.  It is better
		If we don't have a file open at this time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	3/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskDeallocDosSwapFile	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
		mov	bp, ds:[dosSwapFile]
	;
	; Get the FS driver so we can create the dos handle
	;
		mov	ax, GDDT_FILE_SYSTEM
		call	GeodeGetDefaultDriver
		tst	ax
		jz	fail			; not loaded, so we can do
						;  nothing
		mov_tr	bx, ax
		call	GeodeInfoDriver
		
		mov	cx, ds:[si].FSDIS_altProto.PN_major
		mov	dx, ds:[si].FSDIS_altProto.PN_minor

		cmp	cx, DOS_PRIMARY_FS_PROTO_MAJOR
		jne	fail
		cmp	dx, DOS_PRIMARY_FS_PROTO_MINOR
		jae	callDriver
fail:
		stc
		jmp	done
callDriver:
		mov	bx, bp
		mov	di, DR_DPFS_FREE_DOS_HANDLE
		call	ds:[si].FSDIS_altStrat
		segmov	ds, dgroup, ax
		clr	ds:[dosSwapFile]
		clc
done:
	.leave
	ret
DiskDeallocDosSwapFile	endp


Resident	ends

;==============================================================================
;
;			    INITIALIZATION
;
;==============================================================================
Init		segment	resource

swapCategory		char	"diskswap", 0
swapPageString		char	"page", 0
swapFileString		char	"file", 0
swapSizeString		char	"size", 0

LocalDefNLString defSwapName <"swap", 0	; default filename for swap>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open up the system swap file, setting paging parameters

CALLED BY:	INTERNAL (ProcessInitFile)
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskInit	proc	far
		.enter
	;
	; First fetch the page size we should use. If none given,
	; default to SWAP_DEFAULT_PAGE.
	;
		mov	dx, offset swapPageString
		call	GetDiskSwapInteger
		jnc	gotPage
		mov	ax, SWAP_DEFAULT_PAGE
gotPage:
		push	ax		; Save page size

	;
	; See if the user has specified a max size for the file.
	;
		mov	dx, offset swapSizeString
		call	GetDiskSwapInteger
		jnc	gotSize
		mov	ax, SWAP_DEFAULT_SIZE
gotSize:
		push	ax
	;
	; Now see if the user has specified a file to use. Tell the InitFile
	; folks to store the result in our swapFileName buffer rather than
	; having to copy it there...
	;
		mov	dx, offset swapFileString
		segmov	ds, cs, cx	; cx, ds <- Init
		mov	si, offset swapCategory
		mov	bp, INITFILE_INTACT_CHARS	; alloc memory block
		call	InitFileReadString
		jnc	gotFile
	;
	; Copy default file into the buffer instead, since user has no
	; preference (es:di still = swapFileName).
	; 
		mov	si, offset defSwapName
		mov	ax, size defSwapName
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	es, ax
		clr	di
		mov	cx, length defSwapName
		LocalCopyNString		;rep movsb/movsw
		call	MemUnlock
gotFile:
		mov	ax, dgroup
		mov	ds, ax
		mov	es, ax

		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA	; default swap file is in
						; "privdata" directory
		call	FileSetStandardPath

		call	DiskRealInit

		call	FilePopDir
		.leave
		ret
DiskInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDiskSwapInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch an integer for a key in the [system] category

CALLED BY:	GetFontSize, OpenSwap
PASS:		dx	= offset in Init of key string
RETURN:		ax	= value
		carry set if key not found
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDiskSwapInteger proc	near
		.enter
		segmov	ds, cs, cx	; cx, ds <- Init
		mov	si, offset cs:[swapCategory]
		call	InitFileReadInteger
		.leave
		ret
GetDiskSwapInteger endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskRealInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize swapping to disk.

CALLED BY:	SwapInit
PASS:		ds	= dgroup
		es	= dgroup
		bx	= handle of block holding name of file to swap to
		on stack (easiest to do):
			pageSize		page size to use
			maxSize			maximum file size
RETURN:		Nothing (args popped)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskRealInit	proc	near	maxSize:word, pageSize:word
		uses	es
		.enter
	;
	; Build an absolute path for the swap file...
	; 
		call	MemLock
		push	ds, bp, bx
		mov	ds, ax
		clr	si
		clr	bx		; prepend current path
		mov	di, offset swapFileName
		mov	dx, TRUE	; add drive specifier
		mov	cx, size swapFileName
		call	FileConstructFullPath
		pop	ds, bp, bx
		call	MemFree
	;
	; First try and create the swap file. Mark access really
	; exclusive with FAF_EXCLUSIVE so not even system functions
	; can open the thing for reading.
	;
		mov	dx, offset swapFileName
tryCreate:
		mov	ax, ((mask FCF_NATIVE or FILE_CREATE_TRUNCATE) shl 8) \
				or FileAccessFlags <FE_EXCLUSIVE,FA_READ_WRITE>\
				or FAF_EXCLUSIVE
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
		jc	checkCreateError ; Couldn't create -- no disk swapping
		
	;
	; Store the file handle away and make sure the file wasn't
	; opened on a floppy disk, with which we are not prepared to
	; deal.
	;
		mov	ds:[swapFile], ax
		mov	bx, ax
if 0
Bernoulli Boxes are considered removable and it'd be rather a bummer if
people were unable to swap to them, so we allow removable drives now. Swapping
to a floppy is still a Bad Idea, but what the heck. It won't kill anything...
					-- ardeb 5/30/91
		push	bx
		call	FileGetDiskHandle
		call	DiskHandleGetDrive
		pop	bx
		call	DriveGetStatus
		test	ah, mask DS_MEDIA_REMOVABLE
		jz	allocMap
else
		jmp	allocMap
endif

error:
		;
		; Close the file if it's on a floppy.
		;
		mov	bx, ds:[swapFile]	; in case MemAlloc chokes...
		mov	al, FILE_NO_ERRORS
		call	FileClose

noSwap:
	;
	; Return carry set to indicate error (so we exit).
	;
		stc
		jmp	done

checkCreateError:
	;
	; If format mismatch (from old swap file lying about), nuke it
	; and try the create again.
	; 
		cmp	ax, ERROR_FILE_FORMAT_MISMATCH
		jne	noSwap
		call	FileDelete
		jnc	tryCreate
		jmp	noSwap
allocMap:
	;
	; Commit the file to disk after writing a single byte. This makes
	; sure we don't get scrutloads of lost clusters or cross-linked files
	; in the event of a crash...we hope.
	;
		mov	bx, ds:[swapFile]
		mov	dx, offset swapFile
		mov	cx, 1
		clr	al		; errors are handleable here...
		call	FileWrite
		jc	error
		
		clr	al		; errors are handleable here...
		call	FileCommit
		jc	error		; just in case...
	;
	; Figure the size of the swap map. maxSize is expressed in Kb, while
	; pageSize is in bytes, so first convert the size to bytes before
	; dividing by the page size, giving us the number of pages in the file.
	;
		mov	ax, maxSize
		mov	cx, 1024
		mul	cx
		;
		; XXX: See how much room is on the disk and decide if this 
		; file size is reasonable?
		;

		mov	cx, pageSize
		div	cx
		
		tst	dx		; Any remainder?
		jnz	error		; Must divide evenly or we consider it
					;  an error.

	;
	; Allocate the swap map owned by us.
	;
		mov	bx, handle 0
		mov	si, segment DiskWritePage
		mov	di, offset DiskWritePage
		mov	dx, segment DiskReadPage
		mov	bp, offset DiskReadPage
		call	SwapInit
		jc	error

		mov	ds:diskSwapMap, ax	; Record map segment

	;
	; Tell the kernel we're here...
	;
		mov	cx, segment DiskStrategy
		mov	dx, offset DiskStrategy
		mov	ax, SS_KINDA_SLOW
		call	MemAddSwapDriver
		jc	error		; Couldn't register, so return error.

	;
	; Create a DOS handle for the the swap file for later use
	;
;		call	DiskCreateDosHandleForFile
	;
	; Make the init code be discard-only now, since we need it no
	; longer.
	;
		mov	bx, handle Init
		mov	ax, mask HF_DISCARDABLE or (mask HF_SWAPABLE shl 8)
		call	MemModifyFlags
done:
		.leave
		ret	@ArgSize
DiskRealInit	endp


Init		ends
