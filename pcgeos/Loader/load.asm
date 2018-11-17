COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Loader
FILE:		load.asm

ROUTINES:
	Name			Description
	----			-----------
   	OpenKernelGetDataSize	Open the kernel and find the size of kdata
	ZoomerLoadKernel	Load the kernel for the Zoomer
	BulletLoadKernel	Load the kernel for the Bullet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:

	$Id: load.asm,v 1.1 97/04/04 17:26:54 newdeal Exp $

------------------------------------------------------------------------------@

GEODE_FILE_TABLE_SIZE	equ	GH_geoHandle

RELOCATION_STACK_SIZE	=	256

PC <kernelFileHeader	GeosFileHeader	<>				>
PC <kernelExecHeader	ExecutableFileHeader <>				>
kernelCoreBlock		GeodeHeader <>

PC <resourceCounter	word						>
PC <idataSizeToRead	word						>
PC <exportTablePos	dword						>


COMMENT @-----------------------------------------------------------------------

FUNCTION:	OpenKernelGetDataSize

DESCRIPTION:	Open the kernel and find the size of kdata

CALLED BY:	INTERNAL (InitGeos)

PASS:
	ds, es - loader

RETURN:
	KLV_handleTableStart - set
	kdataSize - set
	kernelFileHeader, kernelExecHeader, kernelCoreBlock - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

-------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
OpenKernelGetDataSize	proc	near


	; find the kernel (it may be on a path) and open it

	call	FindAndOpenKernel

	; Read in Geode header

	call	ReadProcessHeaderAndCoreBlock

	; find out how big kdata is

	mov	cx, ds:[kdataSize]
	add	cx, ds:[kernelExecHeader].EFH_udataSize
	add	cx, 15		; Round to paragraph boundary!
	andnf	cx, not 0xf
	mov	ds:[loaderVars].KLV_handleTableStart, cx
	mov	ds:[loaderVars].KLV_dgroupHandle, cx
	mov	ax, ds:[loaderVars].KLV_handleFreeCount

figureLastHandle:
	shl	ax
	shl	ax
	shl	ax
	shl	ax
	add	ax, cx
	jc	tooManyHandles

	mov	ds:[loaderVars].KLV_lastHandle, ax

	ret

tooManyHandles:
	;
	; Requested number of handles would push kdata over 64K. We can't
	; allow that. Figure the number of handles that will fit from the
	; start of the handle table to just before 64K (can't have
	; KLV_lastHandle be 0...)
	; 
	mov	ax, 0xfff0
	sub	ax, cx
	shr	ax
	shr	ax
	shr	ax
	shr	ax
	mov	ds:[loaderVars].KLV_handleFreeCount, ax
	jmp	figureLastHandle

OpenKernelGetDataSize	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindAndOpenKernel

DESCRIPTION:	Find the kernel and open it

CALLED BY:	OpenKernelGetDataSize

PASS:
	ds, es - loader

RETURN:
	bx - file handle

DESTROYED:
	ax, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
FindAndOpenKernel	proc	near

	; try opening the kernel in the local SYSTEM dir

	mov	dx, offset systemString
	mov	ah, MSDOS_SET_CURRENT_DIR
	int	21h
	jc	notLocal

	call	TryOpeningKernel
	jnc	done
notLocal:

	; try opening along a path

	mov	cx, SP_SYSTEM
	mov	ax, DirPathInfo <1, 0, SP_SYSTEM>
pathLoop:
	call	SetDirOnPath
	jc	done

	call	TryOpeningKernel
	jnc	done
	jmp	pathLoop

done:
	;
	; Save away the drive on which we may have found the kernel.
	; 
	pushf
	push	ax
	mov	ah, MSDOS_GET_DEFAULT_DRIVE
	int	21h
	mov	ds:[loaderVars].KLV_kernelFileDrive, al
	pop	ax
	popf

	call	SetTopLevelPath			;saves flags
	ERROR_C	LS_CANNOT_LOCATE_KERNEL

	ret

FindAndOpenKernel	endp

NEC <kernelName		char	'geos.geo', 0		>
EC <kernelName		char	'geosec.geo', 0		>
endif

ifidn	HARDWARE_TYPE, <PC>
systemString		char	"SYSTEM", 0
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetDirOnPath

DESCRIPTION:	Set the DOS current path to be the next directory on the
		path for the logical path

CALLED BY:	FindAndOpenKernel

PASS:
	cx - StandardPath
	ax - DirPathInfo

RETURN:
	carry - set if error (no more paths)
	al, ah - updated
	DOS path - set

DESTROYED:
	none

REGISTER/STACK USAGE:
	ds - paths block
	cx - curEnumEntry
	dx - curEnumStdPath
	ax, bx, si, di - scratch

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ifidn	HARDWARE_TYPE, <PC>
StdPathUpwardNode	struct
    SPN_parent		byte		;SP_NOT_STANDARD_PATH if none
StdPathUpwardNode	ends

stdPathUpwardTree	StdPathUpwardNode	\
	<SP_NOT_STANDARD_PATH>,		;top
	<SP_TOP>,		;world
	<SP_TOP>,		;document
	<SP_TOP>,		;system
	<SP_TOP>,		;privdata
	<SP_PRIVATE_DATA>,	;state
	<SP_PUBLIC_DATA>,	;font
	<SP_PRIVATE_DATA>,	;spool
	<SP_SYSTEM>,		;sysappl
	<SP_TOP>,		;userdata
	<SP_SYSTEM>,		;mouse
	<SP_SYSTEM>,		;printer
	<SP_SYSTEM>,		;fs
	<SP_SYSTEM>,		;video
	<SP_SYSTEM>,		;swap
	<SP_SYSTEM>,		;kbd
	<SP_SYSTEM>,		;fontDr
	<SP_SYSTEM>,		;faxDr
	<SP_SYSTEM>,		;impex
	<SP_SYSTEM>,		;task
	<SP_PUBLIC_DATA>,	;help
	<SP_DOCUMENT>,		;template
	<SP_SYSTEM>,		;power
	<SP_TOP>,		;dosroom
	<SP_SYSTEM>,		;hwr
	<SP_PRIVATE_DATA>	;wastebasket

SetDirOnPath	proc	near	uses bx, cx, di, si, di, ds
logicalStdPath	local	StandardPath	\
				push	cx
SBCS <	pathBuf	local	PathName					>
DBCS <	pathBuf	local	PATH_BUFFER_SIZE dup (char)			>
	ForceRef logicalStdPath
	ForceRef pathBuf

	.enter

	mov_trash	cx, ax			;cx = DirPathInfo

	cmp	ds:[loaderVars].KLV_stdDirPaths, 0
	jz	cantBeDone

	mov	ds, ds:[loaderVars].KLV_stdDirPaths	;ds = paths

	; look for this path

lookForEntry:
	call	FindNextPathEntry
	jc	notFound

	; found an entry, construct the full path and set it

	call	BuildPathEntry			;build entry in ss:bp
	jc	lookForEntry

	; we've set the path, save our variables and leave

	mov_trash	ax, cx
	jmp	done

	; we've run out of entries on this path, try moving up

notFound:
	mov	si, cx
	and	si, mask DPI_STD_PATH
	mov	ch, (mask DPI_EXISTS_LOCALLY) shr 8	;a hack so that
							;FindNextPathEntry does
							;not start at 2nd entry
	shr	si				; convert to byte index
	mov	cl, cs:[stdPathUpwardTree-1][si].SPN_parent	;cx = parent
	tst	cl
	jnz	lookForEntry

	; no more, give up
cantBeDone:
	stc

done:
	.leave
	ret

SetDirOnPath	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindNextPathEntry

DESCRIPTION:	Find the next path entry in the paths block

CALLED BY:	SetDirOnPath

PASS:
	ds - path block
	cx - DirPathInfo

RETURN:
	cx, dx - updated
	carry - set if error (does not exist)
	ds:si - std path string

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ifidn	HARDWARE_TYPE, <PC>
FindNextPathEntry	proc	near	uses ax
	.enter

	; move to next

	test	cx, mask DPI_EXISTS_LOCALLY
	jnz	10$
	inc	ch
10$:
	and	cx, not mask DPI_EXISTS_LOCALLY

	push	cx

	; get pointer to path

	mov	si, cx
	and	si, mask DPI_STD_PATH
	dec	si		; convert to word index (constants are odd
				;  and start with 1...)
	mov	ax, ds:[si]			;ds:ax = path
	cmp	ax, ds:[si+2]
	stc
	jz	done

	; skip any other paths

	mov_trash	si, ax
	mov	cl, ch
	clr	ch				;cx = entry #
	clc
	jcxz	done
skipLoop:
	lodsb
	tst	al
	jnz	skipLoop			;al = 0
	cmp	al, ds:[si]
	stc
	jz	done
	loop	skipLoop
	clc
done:
	pop	cx

	.leave
	ret

FindNextPathEntry	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	BuildPathEntry

DESCRIPTION:	Construct the full path and set it

CALLED BY:	SetDirOnPath

PASS:
	ss:bp - inherited variables
	ds:si - path (from paths block)
	cx - DirPathInfo

RETURN:
	carry - set if error (cannot set path)
	bx - disk handle (locked)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ifidn	HARDWARE_TYPE, <PC>
BuildPathEntry	proc	near	uses 	ax, cx, dx, si, di, ds, es
logicalStdPath	local	StandardPath
SBCS <	pathBuf	local	PathName					>
DBCS <	pathBuf	local	PATH_BUFFER_SIZE dup (char)			>
	.enter	inherit near

	clr	dh
	mov	dl, cl				;dx = std path

	; Example: Logical path: "c:/geoworks/document/tech_doc"
	;	   entry in .ini file: top = "g:/netgeos"
	;	ds:si = "g:/netgeos"
	;	dx = SP_TOP
	;	logicalStdPath = SP_DOCUMENT
	;	pathTail = "tech_doc"
	;
	;	Result: "g:/netgeos/document/tech_doc"

	mov	cx, size PathName
	segmov	es, ss
	lea	di, pathBuf
SBCS <	call	CopyNTStringCXMaxPointAtNull	;copy path entry	>
DBCS <	call	CopyNTStringCXMaxPointAtNullDBCSToSBCS	;copy path entry>

	; copy difference between std path that entry is for and std of
	; logical path

	push	bp
	mov	bp, logicalStdPath
	cmp	dx, bp
	jz	afterCopyDiff

	; *** FOR NOW, only deal with system directory.  We can add more later
	;     if needed

	mov	al, '\\'
	stosb

	segmov	ds, cs
	mov	si, offset systemString
	call	CopyNTStringCXMaxPointAtNull

afterCopyDiff:
	pop	bp

	; try to set path

	segmov	ds, ss
	lea	dx, pathBuf
	call	SetCurrentDirAndDisk

	.leave
	ret

BuildPathEntry	endp

CopyNTStringCXMaxPointAtNull	proc	near
10$:
	lodsb
	stosb
	tst	al
	loopne	10$

	jcxz	done
	dec	di
	inc	cx
done:
	ret

CopyNTStringCXMaxPointAtNull	endp

if	DBCS_PCGEOS

CopyNTStringCXMaxPointAtNullDBCSToSBCS	proc	near
10$:
	lodsw
	stosb
	tst	al
	loopne	10$

	jcxz	done
	dec	di
	inc	cx
done:
	ret

CopyNTStringCXMaxPointAtNullDBCSToSBCS	endp

endif	; DBCS_PCGEOS

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	TryOpeningKernel

DESCRIPTION:	Try opening the kernel in the current directory

CALLED BY:	FindAndOpenKernel

PASS:
	DOS path - set

RETURN:
	bx - file handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
TryOpeningKernel	proc	near	uses ax, cx, dx, ds
	.enter

	;
	; If DOS version >= 3, use DENY_W so other folks on the net can
	; actually open the thing (which wouldn't be possible if always
	; opened the beast in compatibility mode...)
	; 
	mov	ah, MSDOS_GET_VERSION
	int	21h		; al = major, ah = minor, bx:cx = oemSerialNum
	cmp	al, 3
	mov	ax, (MSDOS_OPEN_FILE shl 8) or \
			FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	jae	doOpen
	mov	ax, (MSDOS_OPEN_FILE shl 8) or FA_READ_ONLY
doOpen:
	mov	dx, offset cs:[kernelName]
	segmov	ds, cs
	int	21h
	mov_trash	bx, ax			;bx = file handle

	.leave
	ret
TryOpeningKernel	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReadProcessHeaderAndCoreBlock

DESCRIPTION:	Read in the header for the kernel and check to see if it
		is legal

CALLED BY:	OpenKernelGetDataSize

PASS:
	bx - file handle
	ds, es - loader

RETURN:
	bx - file handle
	kernelExecHeader - GeodeLoadFrame variables for new Geode

DESTROYED:
	ax, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Read GeosFileHeader, check signature and type

	Read Geode header
	if (signature wrong) -> return error
	if (version too high) -> return error
	if (file type does not match) -> return error
	if (attributes do not match) -> return error

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
ReadProcessHeaderAndCoreBlock	proc	near

	; read geos file header (core part)

	mov	cx,size GeosFileHeader	;read first header info
	mov	dx, offset kernelFileHeader
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	;if (signature wrong) -> return error

	cmp	{word} ds:[kernelFileHeader].GFH_signature, GFH_SIG_1_2
	ERROR_NZ	LS_CANNOT_LOAD_KERNEL
	cmp	{word} ds:[kernelFileHeader].GFH_signature+2, GFH_SIG_3_4
	ERROR_NZ	LS_CANNOT_LOAD_KERNEL

	;if (not executable file) -> return error

	cmp	ds:[kernelFileHeader].GFH_type,GFT_EXECUTABLE
	ERROR_NZ	LS_CANNOT_LOAD_KERNEL

	; read in executable file header

	mov	cx, size ExecutableFileHeader
	mov	dx, offset kernelExecHeader
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	; read in the core block

	mov	cx, GEODE_FILE_TABLE_SIZE
	mov	dx, offset kernelCoreBlock
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	; save the file position of the exported entry table

	clr	cx
	mov	dx, cx
	mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
	int	21h				;dx.ax = file position
	ERROR_C	LS_CANNOT_LOAD_KERNEL
	mov	ds:[exportTablePos].high, dx
	mov	ds:[exportTablePos].low, ax

	; skip the exported entry point table and skip one extra word
	; for the first resource handle (size) entry (for the core block)

	mov	dx, ds:[kernelCoreBlock].GH_exportEntryCount
	shl	dx
	shl	dx
	add	dx, 2
	clr	cx
	mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_RELATIVE
	int	21h				;dx.ax = file position
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	; load in the first words to get the size of kdata block

	mov	cx, size kdataSize
	mov	dx, offset kdataSize
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	; store file handle (it's a DOS file handle, but the kernel will
	; open the file under geos eventually)

	mov	ds:[kernelCoreBlock].GH_geoHandle, bx

	; set the number of extra libraries to 0 so we don't try to notify
	; anyone when our threads start.

	mov	ds:[kernelCoreBlock].GH_extraLibCount, 0

	ret
ReadProcessHeaderAndCoreBlock	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadKernel

DESCRIPTION:	Load in the kernel

CALLED BY:	INTERNAL (InitGeos)

PASS:
	ds, es - loader

RETURN:
	bx:ax - library entry

DESTROYED:
	cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

-------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
LoadKernel	proc	near	uses ds
	.enter

	; allocate the core block and set it up

	call	AllocateCoreBlock		;ds <- core block

	call	LoadExportTable

	call	InitResources

	call	RelocateExportTable

	call	ProcessGeodeFile		;bx:ax <- library entry

	.leave
	ret

LoadKernel	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocateCoreBlock

DESCRIPTION:	Allocate the core block for the kernel.

CALLED BY:	LoadKernel

PASS:
	ds, es - loader

RETURN:
	ds - core block for new Geode with core data information
		loaded in and these fields set:
		    GH_geodeHandle, GH_geoHandle, GH_parentProcess

DESTROYED:
	ax, bx, cd, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
AllocateCoreBlock	proc	near

	; calculate size to allocate
	;	= size ProcessHeader
	;	+ (number resources) * 8
	;	+ (number exported entry points) * 4

	mov	ax, ds:kernelExecHeader.EFH_resourceCount
	shl	ax
	add	ax, ds:kernelExecHeader.EFH_exportEntryCount
	shl	ax
	shl	ax
	add	ax, size ProcessHeader

	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE \
						or (mask HAF_ZERO_INIT shl 8)
	call	LoaderMemAlloc
	mov	si, bx			;si = core block handle
	mov	es, ax			;es = core block

	mov	ds:[kernelCoreBlock].GH_geodeHandle, si

	; Copy core block information

	push	si
	mov	si, offset kernelCoreBlock
	mov	cx, size kernelCoreBlock
	clr	di
	rep	movsb
	pop	si

	segxchg	ds, es			;ds = core block, es = loader

	; Set up remaining geode fields:
	;	- referenced once
	;	- library table (if it existed) would follow a ProcessHeader

	mov	ds:[GH_geodeRefCount], 1
	mov	ds:[GH_libOffset], size ProcessHeader

	ret
AllocateCoreBlock	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadExportTable

DESCRIPTION:	Load the exported entry point table for the kernel

CALLED BY:	LoadKernel

PASS:
	ds - core block for new Geode
	es - kernel variables

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

ifidn	HARDWARE_TYPE, <PC>
LoadExportTable	proc	near

	; Position file at export table

	mov	cx, es:[exportTablePos].high
	mov	dx, es:[exportTablePos].low
	mov	bx,ds:[GH_geoHandle]	;file handle to read from
	mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
	; already relative to start of file, since comes from FILE_POS_RELATIVE
	; call.
	int	21h				;dx.ax = file position
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	; Compute location for the exported entry point table
	;	libOffset + (2 * #libraries)

	mov	dx, ds:[GH_libOffset]	;resources go after import table
	mov	ds:[GH_exportLibTabOff], dx

	; Read in table

	mov	cx, ds:[GH_exportEntryCount]
	shl	cx			;*2
	shl	cx			;*4
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	ret
LoadExportTable	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocateExportTable

DESCRIPTION:	Relocate the exported entry point table for the kernel

CALLED BY:	LoadKernel

PASS:
	ds - core block for new Geode
	es - kernel variables

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
RelocateExportTable	proc	near

	mov	cx, ds:[GH_exportEntryCount]

	mov	di, ds:[GH_exportLibTabOff]
	add	di,2			;ds:di = segment of first entry point
relocLoop:
	call	ConvertIDToSegment
	add	di, 4
	loop	relocLoop

	ret

RelocateExportTable	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertIDToSegment

DESCRIPTION:	Convert a resource ID to a segment (or to a handle shifted
		right 4 times) in a geode's core block

CALLED BY:	ProcessGeodeFile, RelocateExportTable

PASS:
	di - offset of field to convert
	ds - core block

RETURN:
	field - converted

DESTROYED:
	si, ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Tell DoRelocation we've got a geode segment relocation at the
	indicated address. This ensures consistency in the system (in
	contrast to when this would figure out its own self what to store
	and I forgot to change it when MAX_SEGMENT came into vogue...)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
ConvertIDToSegment	proc	near 	uses bx, dx, es
	.enter

	segmov	es, ds
	mov	bx, di
	mov	al,(GRS_RESOURCE shl offset GRI_SOURCE) or GRT_SEGMENT
	call	DoRelocation
	mov	di, bx

	.leave
	ret
ConvertIDToSegment	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoRelocation

DESCRIPTION:	Do a relocation

CALLED BY:	DoLoadResource, ConvertIDToSegment

PASS:
	al - GeodeRelocationInfo:
		high nibble = GeodeRelocationSource (GRS_RESOURCE only)
		low nibble = GeodeRelocationType
	ah - GRE_extra: extra data depending on relocation source
	bx - offset of relocation
	es - segment containing relocation
	ds - process's core block

RETURN:
	relocation inserted

DESTROYED:
	ax, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
DoRelocation	proc	near	uses ds
	.enter

	; first, get the correct address based on the source

	mov	dx, ax
	and	dl, mask GRI_SOURCE		;dl = GRI_SOURCE
	and	al, mask GRI_TYPE		;al = GRI_TYPE
	cmp	al, GRT_LAST_XIP_RESOURCE
	ERROR_Z	LS_CANNOT_LOAD_XIP_KERNEL_WITH_STANDARD_LOADER
	mov	di, es:[bx]			;di = data at relocation

	; resource relocation (di = resource #)

	shl	di				;di = module# * 2
	add	di, ds:GH_resHandleOff		;di = offset of handle

	mov	si, ds:[di]			;si = handle
	cmp	al, GRT_HANDLE			;optimize -- if handle
	jz	storeSI

	mov	ds, cs:[loaderVars].KLV_heapStart
	mov	di, ds:[si].HM_addr		;assume fixed (use segment)
	test	ds:[si].HM_flags,mask HF_FIXED
	jnz	storeDI				;if fixed then store segment
						;(can't have CALL reloc to
						;fixed block...)

	cmp	al,GRT_SEGMENT
	jnz	storeMovableInt			;=> must be CALL reloc...

	shr	si				;form handle >> 4 with
	shr	si				; high four bits set to mark as
	shr	si				; invalid segment.
	shr	si
	add	si, MAX_SEGMENT

storeSI:
	mov	di, si

storeDI:
	mov	es:[bx], di
	.leave
	ret

storeMovableInt:
	; call relocation for geode resource call (si = handle)

	mov	byte ptr es:[bx][-1], INT_OPCODE

	xchg	ax,si				;ax = handle (1-byte inst)
	shr	al				;shift four bits of handle down
	shr	al				; so they're recorded in the
	shr	al				; interrupt number used
	shr	al
	or	al,RESOURCE_CALL_INT_BASE
	xchg	ax, di				;(1-byte inst)
	jmp	storeDI				;store es:[bx][0] with INT #

DoRelocation	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitResources

DESCRIPTION:	Initialize resources for the kernel

CALLED BY:	LoadKernel

PASS:
	file pointing at resource table
	ds - data segment for new Geode
	es - kernel variables

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NOTE: The resource handle table is initially all 0
	Read in resource table
	Read in allocation flags table
	Call FindMatchingGeode to determine if another instance of this Geode
		is loaded
	if (another instance exists)
		copy its resource handles
	allocate handles for each resource
	load in each resource

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
InitResources	proc	near

	; Read in resource table and set offsets
	;	resource table at (exportEntryOffset + 4*#exported)

	mov	ax, ds:[GH_exportEntryCount]
	shl	ax			;*2
	shl	ax			;*4
	add	ax, ds:[GH_exportLibTabOff]

	mov	ds:[GH_resHandleOff], ax
	mov	dx, ax			;for FileRead, below
	mov	cx, ds:[GH_resCount]
	mov	es:[resourceCounter], cx
	shl	cx			;cx = #resources * 2
	add	ax, cx
	mov	ds:[GH_resPosOff],ax
	shl	cx			;cx = #resources * 4
	add	ax, cx
	mov	ds:[GH_resRelocOff],ax

	; calculate table size

	shl	cx			;cx = #resources * 8
	mov	bx, ds:[GH_geoHandle]
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	;Read allocation flags into local variable space

	mov	cx, ds:[GH_resCount]	;calculate table size
	shl	cx
	mov	dx, sp
	sub	sp, cx
	mov	di, sp			;allocate local variables, di = BOTTOM
	push	dx			;save stack ptr before locals

	push	ds			;read into stack
	segmov	ds, ss
	mov	dx, di
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL
	pop	ds

	clr	si		;start at 0, fall through to increment so that
				;first resource (core block) is skipped

	mov	ax, ds:[GH_geodeHandle]
	mov	bx, ds:[GH_resHandleOff]	;but set the handle for the
	mov	ds:[bx], ax			;core block to be correct

	;For each resource:
	;	Allocate handle for it using flags from table

allocLoop:
	inc	si
	inc	si
	inc	di
	inc	di
	dec	es:[resourceCounter]
	jz	doneAlloc

	mov	bx, ds:[GH_resHandleOff]
	mov	ax, ds:[bx][si]		;load size of module
	mov	cx, ss:[di]		;load allocation flags
	call	AllocateResource
	jmp	allocLoop

doneAlloc:

	; pre-load resources that need to be pre-loaded

	call	PreLoadResources

	pop	cx
	mov	sp,cx			;recover local space
	ret

InitResources	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocateResource

DESCRIPTION:	Allocate a handle for a resource and read it in.

CALLED BY:	InitResources

PASS:
	ds - data segment for new Geode
	es - kernel variables
	ss:di - Allocation flags table
	si - module number * 2
	ax - size of resource
	bx - GH_resHandleOff
	cx - allocation flags
	ds - core block for new Geode
	es - kernel variables

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:
	di - points at local variables

PSEUDO CODE/STRATEGY:
	Allocate handle for it using flags from table

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
AllocateResource	proc	near

	; if allocating kdata then use kdataSize and kdata handle allocated
	; by InitHeap

	cmp	si, 2
	jnz	notIdata
	mov	es:[idataSizeToRead], ax
	mov	bx, es:[loaderVars].KLV_handleTableStart
	jmp	haveHandle
notIdata:

	tst	ax
	jnz	10$
	inc	ax				;allocate at least 1 byte
10$:
	test	cx, mask HF_DISCARDED
	jnz	allocEmpty

	push	cx
	call	LoaderMemAlloc
	pop	cx

haveHandle:
	mov	dx, ds:[GH_geodeHandle]		;set owner to new geode
	push	ds
	mov	ds, es:[loaderVars].KLV_heapStart
	mov	ds:[bx].HM_owner, dx
	pop	ds

	mov	ax, bx				;save handle of new block
	mov	bx, ds:[GH_resHandleOff]
	mov	ds:[si][bx], ax			;save module handle
	ret

allocEmpty:
	;
	; Resource is discarded, so allocate a discarded handle with the
	; resource size for the resource.
	;
	push	ds
	mov	ds, es:[loaderVars].KLV_heapStart
	call	AllocateHandle
	mov	ds:[bx].HM_otherInfo, 1
	mov	ds:[bx].HM_flags, cl
	call	BytesToParas
	mov	ds:[bx].HM_size, ax
	pop	ds
	jmp	haveHandle
AllocateResource	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	PreLoadResources

DESCRIPTION:	Pre-load resources that are not shared and not discarded

CALLED BY:	InitResources

PASS:
	ds - data segment for new Geode
	es - loader

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
PreLoadResources	proc	near

	; load dgroup specially

	mov	cx, es:[idataSizeToRead]
	mov	ax, es:[loaderVars].KLV_heapStart
	mov	si, 2				;resource #1
	call	DoLoadResource

	mov	cx, ds:[GH_resCount]
	dec	cx
	dec	cx
	mov	es:[resourceCounter], cx
	mov	si, 4				;skip core block

	; For each resource: Load resource if not discarded

loadLoop:
	mov	bx, ds:[GH_resHandleOff]
	mov	ax, ds:[bx][si]
	mov	bx, ax
	push	ds
	mov	ds, es:[loaderVars].KLV_heapStart
	mov	ax, ds:[bx].HM_addr
	test	ds:[bx].HM_flags, mask HF_FIXED
	jnz	loadResource
	test	ds:[bx].HM_flags, mask HF_DISCARDED
	jnz	noLoadResource
loadResource:
	mov	cx, ds:[bx].HM_size	;pass size
	shl	cx
	shl	cx
	shl	cx
	shl	cx
	pop	ds
	call	DoLoadResource
	jmp	common
noLoadResource:
	pop	ds
common:
	inc	si
	inc	si
	dec	es:[resourceCounter]
	jnz	loadLoop
	ret

PreLoadResources	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessGeodeFile

DESCRIPTION:	Process the kernel's geode file

CALLED BY:	LoadKernel

PASS:
	file pointing at imported library table
	ds - core block for new Geode
	es - kernel variables

RETURN:
	bx:ax - kernel's library entry point

DESTROYED:
	cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
ProcessGeodeFile	proc	near

	; Make the Geode own itself so Swat reads in symbols

	mov	bx, ds:[GH_geodeHandle]
	push	ds
	mov	ds, es:[loaderVars].KLV_heapStart
	mov	ds:[bx].HM_owner,bx
	pop	ds

	ornf	ds:[GH_geodeAttr],mask GA_LIBRARY_INITIALIZED or \
						mask GA_GEODE_INITIALIZED

	; initialize class table pointer (stored in kernel's dgroup)

	mov	dx, es:[kernelExecHeader].EFH_classPtr.offset
	mov	si, es:[kernelExecHeader].EFH_classPtr.segment
	shl	si			;index into handle table
	add	si, ds:[GH_resHandleOff]
	mov	si, ds:[si]
	push	ds, es
	mov	ds, es:[loaderVars].KLV_heapStart
	mov	cx, ds:[si].HM_addr		;cx = segment of classPtr

	mov	ds:[TPD_classPointer].segment,cx
	mov	ds:[TPD_classPointer].offset,dx
	clr	ax
	mov	ds:[TPD_curPath], ax
	mov	ds:[TPD_threadHandle], ax

	segmov	es, ds
	mov	di, offset TPD_heap
	mov	cx, size TPD_heap / 2
	rep	stosw

	pop	ds, es

	; relocate the library entry point

	mov	di,offset GH_libEntrySegment
	call	ConvertIDToSegment		;converts segment to handle>>4

	mov	bx, ds:[GH_libEntrySegment]

	; if entry in movable resource, lock it down and get its current
	; segment. If it's not around, we fatal-error.
	; XXX: use LoadResource to bring it in?
	cmp	bx, MAX_SEGMENT
	jb	haveSegment
	shl	bx
	shl	bx
	shl	bx
	shl	bx
	push	ds
	mov	ds, es:[loaderVars].KLV_heapStart
	inc	ds:[bx].HM_lockCount
	mov	bx, ds:[bx].HM_addr
	pop	ds
	tst	bx
	ERROR_Z	LS_CANNOT_LOAD_KERNEL
haveSegment:
	mov	ax, ds:[GH_libEntryOff]

	ret
ProcessGeodeFile	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoLoadResource

DESCRIPTION:	Load a resource and if it is a code resource do the relocations

CALLED BY:	PreLoadResources

PASS:
	ax - segment address to load resource
	cx - size of resource
	si - resource number * 2
	ds - kernel's core block
	es - loader

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

-------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
DoLoadResource	proc	near	uses si, di, bp, ds, es
	.enter

	;Call LoadResourceData to load in the code

	call	LoadResourceData
	mov	es, ax			;save module address

	;Allocate stack space for relocations

	sub	sp, RELOCATION_STACK_SIZE
	mov	bp, sp

	add	si, ds:[GH_resRelocOff]
	mov	cx, ds:[si]		;size of relocation table

	; cx = size of relocation table

groupLoop:
	tst	cx
	jz	done			;if no relocations then branch
	mov	dx, cx			;set cx = size this pass, assume all
	cmp	cx, RELOCATION_STACK_SIZE
	jbe	10$
	mov	cx, RELOCATION_STACK_SIZE ;too big, do only one group
10$:
	sub	dx, cx			;compute relocations left (in dx)
	push	dx

	;Read in relocations

	push	ds
	mov	dx, bp			;address to read in
	mov	bx, ds:[GH_geoHandle]
	segmov	ds, ss
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL
	pop	ds

	;Loop to do relocations

	clr	si

	;ss:bp - reloc table
	;ds = process's stack segment
	;es = new code segment
	;cx = size of relocation table to do this pass
	;si = counter

relocLoop:
	push	si
	mov	ax, word ptr ss:[bp][si].GRE_info ;load GeodeRelocationEntry
	mov	bx, ss:[bp][si].GRE_offset	 ;load offset of relocation
	call	DoRelocation
	pop	si
	add	si, size GeodeRelocationEntry
	cmp	si, cx
	jnz	relocLoop

	pop	cx
	jmp	groupLoop			;loop to do more

done:
	add	sp, RELOCATION_STACK_SIZE	;reclaim local space

	.leave
	ret

DoLoadResource	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadResourceData

DESCRIPTION:	Load the data for a resource

CALLED BY:	DoLoadResource

PASS:
	ax - segment address to load resource
	cx - size of resource
	si - resource number * 2
	ds - kernel's core block
	es - loader

RETURN:
	ax, cx, dx, si, ds - same

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Get file position from table, move to file position
	Read in resource

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

-------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
LoadResourceData	proc	near	uses ax, bx, cx, dx, si, ds
	.enter

	push	cx			;save size
	push	ax			;save segment address

	;Get file position from table, move to file position

	shl	si			;resource number * 4
	add	si, ds:[GH_resPosOff]
	mov	dx, ({dword} ds:[si]).low	;put position in cx:dx
	mov	cx, ({dword} ds:[si]).high
	mov	bx, ds:[GH_geoHandle]
	add	dx, size GeosFileHeader
	adc	cx, 0
	mov	al,FILE_POS_START
	mov	ah, MSDOS_POS_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	;Read in resource

	pop	ds			;recover segment to load into
	pop	cx			;recover size

	clr	dx			;read at offset 0
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_CANNOT_LOAD_KERNEL

	.leave
	ret

LoadResourceData	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZoomerLoadKernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bank the kernel into the Zoomer's EMS pages

CALLED BY:	LoadGEOS

PASS:		DX	= Top of heap

RETURN:		BX:AX	= Kernel entry point

DESTROYED:	CX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BulletLoadKernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bank the kernel into the Bullet's EMS pages

CALLED BY:	LoadGEOS

PASS:		DX	= Top of heap

RETURN:		BX:AX	= Kernel entry point

DESTROYED:	CX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Muck with dx to set it to a value I expect.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedwoodLoadKernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bank the kernel into the Redwood's EMS pages

CALLED BY:	LoadGEOS

PASS:		DX	= Top of heap

RETURN:		BX:AX	= Kernel entry point

DESTROYED:	CX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Muck with dx to set it to a value I expect.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @----------------------------------------------------------------------

ROUTINE:	GlobalFileCopy

SYNOPSIS:	Do a file copy between two absolute places in memory.
		

CALLED BY:	BFSMapOffset

PASS:		dxax -- absolute source address
		cxbx -- absolute destination address
		di -- number of words to move

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 7/93       	Initial version

------------------------------------------------------------------------------@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BulletInitEMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes EMS memory

CALLED BY:	BulletLoadKernel
PASS:		nothing
RETURN:		carry set if no EMS
DESTROYED:	ax,bx,cx,dx,si,di,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Instead of fatal error, how about unloading the emm driver?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



if	FULL_EXECUTE_IN_PLACE


ifidn	HARDWARE_TYPE, <EMMXIP>
;------------------------------------------------------------------------------
;	List of lists (for finding device)
;------------------------------------------------------------------------------
DosListOfLists	struct		; > 3.0
    DLOL_DCB		fptr.DeviceControlBlock
    DLOL_SFT		fptr.SFTBlockHeader
    DLOL_clock		fptr.DeviceHeader; Device header for CLOCK$
    DLOL_console	fptr.DeviceHeader; Device header for CON
    DLOL_maxSect	word		; Size of largest sector on any drive
    DLOL_cache		fptr		; First cache block
    DLOL_CWDs		fptr		; Current Working Directory info per
					;  drive
    DLOL_FCBs		fptr		; SFT for FCB access
    DLOL_FCBsize	word		; Number of entries in FCB SFT
    DLOL_numDrives	byte		; Number of drives in system
    DLOL_lastDrive	byte		; Last real drive
    DLOL_null		DeviceHeader	; Header for NUL device -- the head
					;  of the driver chain.
DosListOfLists	ends

Dos3_0ListOfLists struct		; 3.0
    D3LOL_DCB		fptr.DeviceControlBlock
    D3LOL_SFT		fptr.SFTBlockHeader
    D3LOL_clock		fptr.DeviceHeader
    D3LOL_console	fptr.DeviceHeader
    D3LOL_numDrives	byte
    D3LOL_maxSector	word
    D3LOL_cache		fptr
    D3LOL_CWDs		fptr.CurrentDirectory
    D3LOL_lastDrive	byte
    			byte	12 dup(?); Who knows?
    D3LOL_null		DeviceHeader
Dos3_0ListOfLists ends

Dos2ListOfLists	struct		; 2.X
    D2LOL_DCB		fptr.DeviceControlBlock
    D2LOL_SFT		fptr.SFTBlockHeader
    D2LOL_clock		fptr.DeviceHeader; Device header for CLOCK$
    D2LOL_console	fptr.DeviceHeader; Device header for CON
    D2LOL_numDrives	byte		; Number of drives in system
    D2LOL_maxSect	word		; Size of largest sector on any drive
    D2LOL_cache		fptr		; First cache block
    D2LOL_null		DeviceHeader	; Header for NUL device -- the head
					;  of the driver chain.
Dos2ListOfLists	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfEMMPresent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if an EMM driver is present

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if none present
DESTROYED:	ax, bx, cx, dx, di, si, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 2/94   	Scarfed from Adam's code in the swap driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
emm_device_name	char	"EMMXXXX0"	;guaranteed name of EMM driver
CheckIfEMMPresent	proc	near	uses	es, ds
	.enter
	;
	; First make sure the driver's around. Just because we've been loaded
	; doesn't mean there's a manager around...
	; We use the device chain to locate the last EMMXXXX0 device so we
	; don't get fooled by things like Super PC-Kwik that intercept int 67h
	; for their own purposes.
	;
		mov	ah, MSDOS_GET_VERSION
		int 21h
		xchg	ax, cx
		
		mov	ah, MSDOS_GET_DOS_TABLES
		int 21h
		
		add	bx, offset D2LOL_null	; assume DOS 2.X
		cmp	cl, 2
		je	haveNull		; yup
		
		; Deal with DOS 3.0, which has a smaller ListOfLists
		add	bx, offset D3LOL_null - offset D2LOL_null
		cmp	cl, 3
		jne	10$			; > 3
		cmp	ch, 10			; 3.10 or above?
		jb	haveNull		; no
10$:		
		add	bx, offset DLOL_null - offset D3LOL_null
haveNull:
		segmov	ds, cs
devLoop:
	;
	; EMS driver must be a character device...
	;
		test	es:[bx].DH_attr, mask DA_CHAR_DEV
		jz	nextDev
	;
	; Does the thing match the defined name for the EMM?
	;		
		lea	di, es:[bx].DH_name
		lea	si, emm_device_name
		mov	cx, length emm_device_name;number of bytes to compare
		repe	cmpsb
		clc
		je	haveEMM

nextDev:
		les	bx, es:[bx].DH_next
		cmp	bx, -1		; end of the line?
		jne	devLoop		; no -- keep looking
		stc
haveEMM:
	.leave
	ret
CheckIfEMMPresent	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BankInFixedReadOnlyResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Banks in all the fixed read-only resources for the
		system

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		es - segment of first physical page
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <EMMXIP>
START_OF_UPPER_MEMORY	equ	0xa000
PAGE_BOUNDARY_INCREMENT	equ	0x0100
BankInFixedReadOnlyResources	proc	near	uses	ax, bx, cx, dx, di
	.enter
	clr	di
	clr	si

;	Now, we map in the start of the XIP image into the various physical
;	EMS pages on this system. Basically, we start at the beginning of
;	upper memory, and try to bank things in from there.

	mov	bx, START_OF_UPPER_MEMORY
loopTop:
	cmp	bx, cs:[loaderVars].KLV_mapPageAddr
	jne	notMapPage
	add	bx, MAPPING_PAGE_SIZE/16
	jc	done
notMapPage:

;	BX <- segment we are trying to map image data into
;	DI <- segment of start of mapped-in XIP image
;	SI <- logical page number we are mapping	

	call	MapSegmentToPhysicalPageNumber		; ax <- physical #
	jc	next

;	We have a valid page here, so map data into it

	tst	di		;DI <- segment of XIPHeader
	jnz	10$		;Branch if already set
	mov	di, bx
10$:
	xchg	si, bx		;BX <- logical page to map in
	mov	ah, high EMF_MAP_BANK
	mov	dx, cs:[loaderVars].KLV_emmHandle
	int	EMM_INT
	tst	ah			;If error, whine...
	ERROR_NZ	LS_EMMXIP_EMM_ERROR

	xchg	si, bx		;SI <- logical page to map in
	inc	si		;Go to next logical page

	add	bx, PHYSICAL_PAGE_SIZE/16
	jmp	nextTest

next:
	; Some systems (like NT) don't put the physical pages on
	; even 16K boundaries, so we must creep along in 4K increments
	; looking for them.

	add	bx, PAGE_BOUNDARY_INCREMENT
nextTest:
	jnc	loopTop
done:
	mov	es, di
	.leave
	ret
	
BankInFixedReadOnlyResources	endp

elifidn	HARDWARE_TYPE, <ZOOMERXIP>

BankInFixedReadOnlyResources	proc	near	
		uses	ax, bx, cx, dx, di
		.enter
	;
	; Bank the fixed read-only resources into EMS windows. Mark each window
	; as write-protected.
	;
		mov	dx, ZOOMER_XIP_1ST_EMS_WINDOW
		mov	cx, ZOOMER_XIP_NUM_EMS_WINDOWS
		mov	ax, ZOOMER_XIP_ROM_WINDOW
emsWindowLoop:
		out	dx, ax
		add	dx, 2		; go to next EMS register
		inc	ax		; go to next 16K block of resource
		loop	emsWindowLoop
	;
	; Return the segment of the first physical page
	;	
		mov	di, ZOOMER_XIP_1ST_EMS_SEGMENT
		mov	es, di

		.leave
		ret
BankInFixedReadOnlyResources	endp
elifidn	HARDWARE_TYPE, <BULLETXIP>

elifidn	HARDWARE_TYPE, <BULLETXIP>

BankInFixedReadOnlyResources	proc	near	uses	ax, bx, cx, dx, si
		.enter
		;
		; Remember where the EMS and conventional memory windows were
		; before we bank them for the XIP.  We'll recover
		; these when exiting Geos.
		;
		mov	cx, BULLET_NUM_16K_PAGES
		mov	si, offset loaderVars.KLV_originalPages
		mov	al, BULLET_3RD_KERNEL_EMS_SEGMENT
rememberOriginalsLoop:
		mov	cs:[si].BPM_ems_segment, al
 		out	BULLET_ADDR_REGISTER, al 	; ah <- window to map
		mov	dl, al				; dl <- remember it
		in	ax, BULLET_DATA_REGISTER	; ax <- current EMS
							; window
		mov	cs:[si].BPM_original_segment, ax
		add	si, size BulletPageMap
		mov	al, dl			;Bump AL to be the high byte of
						; the segment address of the
						; next physical page
		add	al, high (PHYSICAL_PAGE_SIZE/16)
		loop	rememberOriginalsLoop

		;
		; Bank the first part of the kernel in (which contains the 
		; FullXIPHeader).
		;
		mov	cx, BULLET_NUM_3RD_KERNEL_EMS_WINDOWS
		mov	bx, BULLET_ROM_KERNEL_SEGMENT
		mov	al, BULLET_3RD_KERNEL_EMS_SEGMENT
		call	bankROM


		mov	cx, BULLET_NUM_2ND_KERNEL_EMS_WINDOWS
		mov	al, BULLET_2ND_KERNEL_EMS_SEGMENT
		call	bankROM

		mov	al, BULLET_1ST_KERNEL_EMS_SEGMENT
		mov	cx, BULLET_NUM_1ST_KERNEL_EMS_WINDOWS
		call	bankROM
		
		LoadXIPSeg	es, ax
		.leave
		ret
bankROM:
		INT_OFF
 		out	BULLET_ADDR_REGISTER, al 	; ah <- window to map
		mov	ax, bx
 		out	BULLET_DATA_REGISTER, ax	; ax <- rom segment 
 		in	al, BULLET_ADDR_REGISTER
		INT_ON
		add	al, 4			; go to next 16K EMS window
		inc	bx			; go to next 16K ROM block
		loop	bankROM
		retn

BankInFixedReadOnlyResources	endp

elseif	VG230_FULL_XIP
; Common code for Jedi, NIKE, et al.

BankInFixedReadOnlyResources	proc	near
		uses	ax, bx, cx
		.enter


	;
	; Bank in all the fixed XIP resources (such as the kernel) 
	; which also contains the FullXIPHeader.
							; cx <- # of pages
		mov	cx, (FIXED_XIP_SIZE_BYTES / PHYSICAL_PAGE_SIZE)
							; al <- page segment
		mov	al, ((FIXED_XIP_BASE_ADDRESS) and 0ff00h) shr 8
							; bx <- PageDesc.
		mov	bx, FIXED_XIP_BASE_PAGE_DESC

bankROM:
		INT_OFF
 		out	VG230_ADDR_REGISTER, al 	; al <- page to map
		mov	ax, bx
 		out	VG230_DATA_REGISTER, ax		; ax <- rom segment 
 		in	al, VG230_ADDR_REGISTER
		INT_ON
		add	al, 4			; go to next 16K EMS window
		inc	bx			; go to next 16K ROM block
		loop	bankROM

		LoadXIPSeg	es, ax
		.leave
		ret

BankInFixedReadOnlyResources	endp

elseif	GULLIVER_COMMON
; Gulliver code (AMD Elan)

BankInFixedReadOnlyResources	proc	near
		uses	ax, bx, cx, dx
		.enter
	
	;
	; Bank in all the fixed XIP resources (such as the kernel) 
	    ; Be sure that all of the fixed stuff is below 2Mb so we can
	    ; just set the lower seven bits of the page number in the loop
	    ; and zero out all of the upper bits.
	    CheckHack <(FIXED_XIP_BASE_ADDRESS + FIXED_XIP_SIZE_BYTES) lt \
	    		 200000h>
	 
		; Select the correct memory bank for Fixed XIP resources
		SelectFixedXIPBank
		
		; Clear the 23rd bit of all of our windows
		mov	al, FIXED_XIP_A_23_REG
		out	ELAN_INDEX, al
		in	al, ELAN_DATA
		and	al, not FIXED_XIP_A_23_MASK
		out	ELAN_DATA, al

		; Clear bits 21-22 of all of our windows
		mov	al, FIXED_XIP_A_21_22_REG_1
		out	ELAN_INDEX, al
	if (FIXED_XIP_A_21_22_MASK_1 eq 0ffh)
    	    	clr	al
	else
		in	al, ELAN_DATA
		and	al, not FIXED_XIP_A_21_22_MASK_1
	endif
		out	ELAN_DATA, al
		
		mov	al, FIXED_XIP_A_21_22_REG_2
		out	ELAN_INDEX, al
	if (FIXED_XIP_A_21_22_MASK_2 eq 0ffh)
    	    	clr	al
	else
		in	al, ELAN_DATA
		and	al, not FIXED_XIP_A_21_22_MASK_2
	endif
		out	ELAN_DATA, al
		
		; cx <- # of pages in FIXED XIP image
		mov	cx, ((FIXED_XIP_TOP_WINDOW - FIXED_XIP_BASE_ADDRESS)\
		              *16)/ PHYSICAL_PAGE_SIZE
		
		; dx <- First I/O address to program page numbers
		mov	dx, FIXED_XIP_FIRST_IO_ADDRESS
					
		; al <- Page number of the first FIXED XIP page in ROM
		;	with high bit on (PAGE ENABLE)
		mov	al, FIXED_XIP_BASE_ROM_BANK
		or	al, ELAN_PAGEEN
		
		; Loop through and program the lower 7 bits of all fixed XIP
		; pages.  (Are we having fun yet?)
programPages:
		out	dx, al
		inc	al				; advance page number
		add	dx, 02000h			; advance I/O addr
		loop	programPages

		LoadXIPSeg	es, ax
		
		.leave
		ret
BankInFixedReadOnlyResources	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenXIPImageFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the XIP image file, and returns a file handle for it

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		bx - file handle
		carry set if error
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <EMMXIP>
OpenXIPImageFile	proc	near
	.enter

	;
	; If DOS version >= 3, use DENY_W so other folks on the net can
	; actually open the thing (which wouldn't be possible if always
	; opened the beast in compatibility mode...)
	; 
	mov	ah, MSDOS_GET_VERSION
	int	21h		; al = major, ah = minor, bx:cx = oemSerialNum
	cmp	al, 3
	mov	ax, (MSDOS_OPEN_FILE shl 8) or \
			FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	jae	doOpen
	mov	ax, (MSDOS_OPEN_FILE shl 8) or FA_READ_ONLY
doOpen:
	mov	dx, offset cs:[imageName]
	segmov	ds, cs
	int	21h
	mov_trash	bx, ax			;bx = file handle
	.leave
	ret
OpenXIPImageFile	endp
imageName	char	"xipimage",0
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateEMSMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates EMS memory for the XIP image

CALLED BY:	GLOBAL
PASS:		dx.ax - # bytes to allocate
RETURN:		dx - EMM handle
		carry set if not enough memory
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <EMMXIP>
AllocateEMSMemory	proc	near	uses	ax, bx, cx, ds, si
	bytesToAlloc	local	dword
	.enter
	movdw	bytesToAlloc, dxax

;	First, see if there already is an EMM handle owned by GEOS. If so,
;	free it and allocate a new one.

	segmov	ds, cs
	mov	si, offset hanName
	mov	ax, EMF_SEARCH
	int	EMM_INT
	tst	ah
	jnz	notFound

	mov	ah, high EMF_FREE
	int	EMM_INT
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR
	
notFound:

;	Re-Allocate handle 0 to have no pages on it - for some random reason,
;	EMS drivers allocate memory for handle 0, which we want to use.
;
;	DON'T DO THIS! I GOT RANDOM CRASHES AND RANDOM TRASHING OF IMAGE
;	DATA WHEN I DID THIS, SO DON'T!
;
; 	OK, we won't. Geez, Drew, take a deep breath...
;
;	mov	ax, EMF_REALLOC
;	clr	dx			;Reallocate handle 0 to 0 pages...
;	clr	bx
;	int	EMM_INT

;	Allocate an EMM handle with the correct # pages associated with it...

	push	dx
	movdw	dxax, bytesToAlloc
	adddw	dxax, MAPPING_PAGE_SIZE-1
	mov	bx, MAPPING_PAGE_SIZE
	div	bx
if	MAPPING_PAGE_SIZE	eq	PHYSICAL_PAGE_SIZE * 2
	shl	ax
endif
	mov_tr	bx, ax			;BX <- # pages needed to hold XIP image
	pop	dx			;DX <- EMM handle

	mov	ax, EMF_ALLOC
	int	EMM_INT
	tst	ah			;If there is an error allocating our
	stc				; memory, return it...
	jnz	exit

	mov	ax, EMF_SET_NAME	;Set the name to the string whose ptr
	int	EMM_INT			; is still in DS:SI
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR

exit:
	.leave
	ret
AllocateEMSMemory	endp
hanName		char	"GEOS XIP" ;No null necessary - only 8 bytes copied
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadXIPImageIntoMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the XIP image data from the file into EMS memory...

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		carry set if we couldn't alloc enough memory
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <EMMXIP>
LoadXIPImageIntoMemory	proc	near	uses	ax, bx, cx, dx
	.enter

;
; 	Get the length of the file
;
	mov	ax, FILE_POS_END or MSDOS_POS_FILE shl 8
	clrdw	cxdx
	int	21h		;dx:ax = file size
	ERROR_C	LS_EMMXIP_CANNOT_READ_IMAGE_FILE
	
	pushdw	dxax
	clrdw	cxdx
	mov	ax, FILE_POS_START or MSDOS_POS_FILE shl 8
	int	21h
	ERROR_C	LS_EMMXIP_CANNOT_READ_IMAGE_FILE
	popdw	dxax

;	Allocate an EMM handle with enough mem

	pushdw	dxax
	call	AllocateEMSMemory		;Return DX = EMM handle
	popdw	cxax
	jc	exit				;Exit if not enough mem
	mov	cs:[loaderVars].KLV_emmHandle, dx
	
	call	CopyFileIntoMemory
exit:

;	Close the file, and preserve any errors returned from AllocateEMMHandle
;	above.

	pushf
	mov	ah, MSDOS_CLOSE_FILE
	int	21h
	ERROR_C	LS_EMMXIP_CANNOT_READ_IMAGE_FILE
	popf	
	.leave
	ret
LoadXIPImageIntoMemory	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyFileIntoMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads data from the file and stores it in logical pages

CALLED BY:	GLOBAL
PASS:		DX - EMM handle
		BX - file handle
		CX:AX <- # bytes to read
RETURN:		carry clear
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <EMMXIP>
CopyFileIntoMemory	proc	near	uses	ax, bx, cx, dx, ds
	fileHan		local	word	\
			push	bx
	emmHan		local	word	\
			push	dx
	logicalPageNum	local	word
	bytesToRead	local	dword
	.enter
	clr	logicalPageNum
	movdw	bytesToRead, cxax

;	Now, sit in a loop, and copy data from the file until we reach
;	the end.

nextBank:

;	Map in memory to page #0

	mov	ax, EMF_MAP_BANK
	mov	bx, logicalPageNum
	mov	dx, emmHan
	int	EMM_INT
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR

;	Find out the address of physical page #0

	mov	ah, high EMF_GET_PAGE_FRAME
	int	EMM_INT
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR
	mov	ds, bx			
	clr	dx	;DS:DX <- dest for incoming data

	mov	bx, fileHan
	mov	cx, PHYSICAL_PAGE_SIZE
	mov	ah, MSDOS_READ_FILE
	int	21h
	ERROR_C	LS_EMMXIP_CANNOT_READ_IMAGE_FILE

	tst	ax		;Barf if 0 bytes read
	ERROR_Z		LS_EMMXIP_CANNOT_READ_IMAGE_FILE

	sub	bytesToRead.low, ax
	sbb	bytesToRead.high, 0
	ERROR_C		LS_EMMXIP_CANNOT_READ_IMAGE_FILE

	inc	logicalPageNum
	tstdw	bytesToRead	;Keep looping until no more bytes are read
	jnz	nextBank

;	Unmap the EMS bank from addressable memory...

	mov	ax, EMF_MAP_BANK
	mov	bx, UNMAP_BANK
	mov	dx, emmHan
	int	EMM_INT
	
	tst_clc	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR
	.leave
	ret
CopyFileIntoMemory	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDataFromXIPImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies data out of the XIP image

CALLED BY:	
PASS:		dx - logical page # of page where data lies
		ax - offset into logical page where data lies
		cx - # bytes to copy
		es:di - ptr to buffer to copy data into
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BULLXIP<MAX_PAGE	equ	82h					>
BULLXIP<MIN_PAGE	equ	(low BULLET_ROM_KERNEL_SEGMENT)		>
BULLXIP<DO_PAGE_BOUNDS_CHECKING	equ	1				>


    ; Not exact bounds, but at least they are in the ballpark.
    ;
PENE<DO_PAGE_BOUNDS_CHECKING	equ	1				>
PENE<MAX_PAGE	equ	PENE_LAST_FLASH_PAGE				>
PENE<MIN_PAGE	equ	PENE_FIRST_FLASH_PAGE				>


CopyDataFromXIPImage	proc	near

	uses	ax, bx, cx, dx, ds, si, di

bytesToCopy		local	word	push	cx
CXIP <pageNumber	local	word	push	dx			>
	.enter

EC <	cmp	ax, MAPPING_PAGE_SIZE					>
EC <	ERROR_AE	-1						>


; Decide which logical page the data starts in (divide the offset by
; the physical page size).

	mov	ds, cs:[loaderVars].KLV_mapPageAddr
	mov_tr	si, ax		;DS:SI <- offset into physical page to copy 
				; data from.
CXIP <	andnf	dx, 0x7fff			; clear compressed flag	>
	mov	bx, dx

if	MAPPING_PAGE_SIZE eq	PHYSICAL_PAGE_SIZE * 2
if not VG230_FULL_XIP
	shl	bx
endif
elseif MAPPING_PAGE_SIZE ne PHYSICAL_PAGE_SIZE
	PrintError <Mapping page size is not a multiple of PHYSICAL_PAGE_SIZE>
endif

ifdef	DO_PAGE_BOUNDS_CHECKING
EC <	cmp	bx, MAX_PAGE						>
EC <	ERROR_A	XIP_MAP_ERROR						>
EC <	cmp	bx, MIN_PAGE						>
EC <	ERROR_B	XIP_MAP_ERROR						>
endif

EMMXIP<	mov	dx, cs:[loaderVars].KLV_emmHandle			>
BULLXIP<or	bh, BULLET_ROM_AREA					>
loopTop:

;	Map in the first EMS page

ZOOMXIP<mov	ax, bx				; ax <- page address	>
ZOOMXIP<mov	dx, ZOOMER_XIP_MAP_PAGE_REG				>
ZOOMXIP<out	dx, ax							>

EMMXIP<	mov	al, cs:[loaderVars].KLV_mapPage				>
EMMXIP<	mov	ah, high EMF_MAP_BANK					>
EMMXIP<	int	EMM_INT							>
EMMXIP<	tst	ah							>
EMMXIP<	ERROR_NZ	LS_EMMXIP_EMM_ERROR				>

BULLXIP <mov	al, high BULLET_XIP_MAP_PAGE_SEGMENT			>
BULLXIP	<INT_OFF							>
BULLXIP <out	BULLET_ADDR_REGISTER,al					>
BULLXIP <mov	ax, bx							>
BULLXIP <out	BULLET_DATA_REGISTER,ax					>
BULLXIP	<INT_ON								>


PENE<	mov	dx, PENE_XIP_MAP_PAGE_REGISTER				>
PENE<	mov	ax, bx							>
PENE<	out	dx, ax							>


if VG230_FULL_XIP
	mov	al, high MOVABLE_XIP_WINDOW_BASE_ADDRESS
	INT_OFF
	out	VG230_ADDR_REGISTER,al
	mov	ax, bx
	out	VG230_DATA_REGISTER,ax
	INT_ON	
endif

; Already inside FULL_EXECUTE_IN_PLACE.  Besides, there is no gulliver nonXIP.
if GULLIVER_COMMON
	; Select the correct memory bank for Movable XIP resources
	SelectMovableXIPBank
	
	; BX = page number
	
	; Store in bh the value to set the 7 and 8th bits of the page number
	; (A21 and A22) for both windows.
	clr	bh
	shl	bx, 1
	shr	bl, 1

if MOVABLE_XIP_BASE_A_21_22_OFFSET ne 0
    	shl	bh, MOVABLE_XIP_BASE_A_21_22_OFFSET
endif
	
;	Set the lower page's lower 7 bits
	mov	al, bl
	or	al, ELAN_PAGEEN
	ELAN_SET_PAGE_REGISTER	MOVABLE_XIP_BASE_WINDOW, al, trashDX
	
endif ;GULLIVER_COMMON

;====== Map in next EMS page if we are using two pages ===============
;
if	MAPPING_PAGE_SIZE eq	PHYSICAL_PAGE_SIZE * 2

ZOOMXIP<inc	bx							>
ZOOMXIP<inc	ax							>
ZOOMXIP<add	dx, 2	; next EMS register				>
ZOOMXIP<out	dx, ax							>

BULLXIP <mov	al, high (BULLET_XIP_MAP_PAGE_SEGMENT + PHYSICAL_PAGE_SIZE/16)>
BULLXIP	<INT_OFF							>
BULLXIP <out	BULLET_ADDR_REGISTER,al					>
BULLXIP <inc	bx							>
BULLXIP <mov	ax, bx							>
BULLXIP <out	BULLET_DATA_REGISTER,ax					>
BULLXIP	<INT_ON								>

    ; For PENELOPE and RESPONDER both (and other E3G future products),
    ; just go to the next EMS register.
    ;
I_E3G <	add	dx, size word						>
I_E3G <	inc	bx							>
I_E3G <	inc	ax							>
I_E3G <	out	dx, ax							>

if VG230_FULL_XIP
	mov	al, high (MOVABLE_XIP_WINDOW_BASE_ADDRESS + \
				PHYSICAL_PAGE_SIZE/16)
	INT_OFF
	out	VG230_ADDR_REGISTER,al
	inc	bx
	mov	ax, bx
	out	VG230_DATA_REGISTER,ax
	INT_ON
endif
		
EMMXIP<	inc	bx							>
EMMXIP<	mov	al, cs:[loaderVars].KLV_mapPage				>
EMMXIP<	inc	al							>
EMMXIP<	mov	ah, high EMF_MAP_BANK					>
EMMXIP<	int	EMM_INT							>
EMMXIP<	tst	ah							>
EMMXIP<	ERROR_NZ	LS_EMMXIP_EMM_ERROR				>

if	GULLIVER_COMMON
	
	; Put the second page's A21 and A22 bits into bh
	inc	bl
	clr	ax
	mov	al, bl
	shl	ax, 1
	shr	al, 1
	shl	ah, MOVABLE_XIP_NEXT_A_21_22_OFFSET
	or	bh, ah
	
	; Set the lower 7 bits of the second page
	or	al, ELAN_PAGEEN
	ELAN_SET_PAGE_REGISTER	MOVABLE_XIP_NEXT_WINDOW, al, trashDX

endif	;GULLIVER_COMMON

endif	;MAPPING_PAGE_SIZE eq	PHYSICAL_PAGE_SIZE * 2
;=====================================================================

if	GULLIVER_COMMON
	; We're not quite done with Gulliver because we have to set the 8th
	; bits appropriately.
	
	mov	al, MOVABLE_XIP_A_21_22_REG
	out	ELAN_INDEX, al
	in	al, ELAN_DATA
	
	; Mask out the old data (based on mapping page size)
	
if	MAPPING_PAGE_SIZE eq	PHYSICAL_PAGE_SIZE * 2
	and	al, not (MOVABLE_XIP_BASE_A_21_22_MASK or \
				MOVABLE_XIP_NEXT_A_21_22_MASK)
else
	and	al, not MOVABLE_XIP_BASE_A_21_22_MASK
endif

	; Or in the new info, store in bh (lucky for us!)
	or	al, bh
	out	ELAN_DATA, al
	
	; Now we're done.  Whew!
endif	;GULLIVER_COMMON

;	Now that data has been mapped in, copy it to the destination.

	;DS:SI <- src for data to copy
	;ES:DI <- dest for data to copy

if COMPRESSED_XIP
	test	ss:[pageNumber], 0x8000	;Check compressed flag
	jz	copy

	call	LZGUncompress
EC <	cmp	cx, ss:[bytesToCopy]					>
EC <	ERROR_NE -1			;COMPRESSED_XIP_IMAGE_IS_HOSED!	>
	jmp	done
copy:
endif ; COMPRESSED_XIP

	mov	cx, MAPPING_PAGE_SIZE
	sub	cx, si			;CX <- # bytes of data in this physical
					; page
	cmp	cx, bytesToCopy
	jbe	copyIt
	mov	cx, bytesToCopy
copyIt:
	sub	bytesToCopy, cx
	rep	movsb


	clr	si			;The next byte of data will be at the
	inc	bx			; start of the next logical page
	tst	bytesToCopy
	jnz	loopTop
done::
	.leave
	ret
CopyDataFromXIPImage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LZGUncompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LZG uncompress

CALLED BY:	EXTERNAL
PASS:		ds:si	= compressed data
		es:di	= uncompressed data buffer
RETURN:		cx	= size of uncompressed data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if COMPRESSED_XIP

.186

LZG_PAIR_POSITION_BITS		equ	10
LZG_PAIR_LENGTH_BITS		equ	(14-LZG_PAIR_POSITION_BITS)
LZG_MIN_MATCH_LENGTH		equ	3
LZG_MAX_LITERAL_LENGTH		equ	0x07
LZG_MAX_LITERAL_STRING_LENGTH	equ	0x1f
LZG_SMALL_PAIR_FLAG		equ	0x80
LZG_LITERALS_FLAG		equ	0x40
LZG_RUN_LENGTH_FLAG		equ	0x20

LZGUncompress	proc	far
	uses	ax,bx,dx,si
	.enter

	push	di			; save output offset
	clr	ax, cx			; start out with ah = 0, ch = 0

loadFlags:
	lodsb				; load flag byte
	mov	dx, ax			; dh = 0, dl = flags
	dec	dh			; dh = 11111111b, dl = flags

uncompress:
	shl	dh, 1			; if no flags left
	jnc	loadFlags		;   then load next flag byte
	shl	dl, 1			; if not literal byte
	jnc	notLiteralByte		;   then notLiteralByte

	movsb				; copy literal byte
	jmp	uncompress

notLiteralByte:
	lodsb				; load flag byte
	test	al, LZG_SMALL_PAIR_FLAG
	jnz	smallPair

	test	al, LZG_LITERALS_FLAG	; test for literals
	jz	pair			; else do pair

	test	al, LZG_RUN_LENGTH_FLAG
	jnz	runLength

literals::
	and	al, not LZG_LITERALS_FLAG
	jz	longLiterals

	mov	cl, al			; cx = size of literals(*)
	shr	cx, 1			; # of bytes -> # of words
	rep	movsw			; copy literal
	jnc	uncompress		; loop back for more
	movsb				; copy leftover byte
	jmp	uncompress		; loop back for more

longLiterals:
	lodsb				; get long literal length byte
	mov	cl, al			; cx = size of literals(*)
	shr	cx, 1			; # of bytes -> # of words
	rep	movsw			; copy literal
	jnc	uncompress		; loop back for more
	movsb				; copy leftover byte
	jmp	uncompress		; loop back for more

runLength:
	and	al, not (LZG_LITERALS_FLAG or LZG_RUN_LENGTH_FLAG)
	jz	done			; done if no runLength

	mov	cl, al			; cx = size of zeros
	clr	ax			; ax = NULL
	shr	cx, 1			; # of bytes -> # of words
	rep	stosw			; write NULL's
	jnc	uncompress		; loop back for more
	stosb				; write NULL
	jmp	uncompress		; loop back for more

pair:
	mov	cl, al			; cx=cl = 4 length bits, 2 offset bits
	lodsb				; load low 8 bits of dictionary offset
	mov	bl, al			; bl = low 8 bits of dictionary offset
	mov	bh, cl			; bh has high bits of offset
	and	bh, (1 shl (LZG_PAIR_POSITION_BITS-8)) - 1
					; bx = dictionary offset
	neg	bx
	add	bx, di			; bx = position in output buffer
	CheckHack <(LZG_PAIR_POSITION_BITS-8) eq 2>
	shr	cl, 2			; shift out offset bits
	jz	longPair
	xchg	si, bx			; ds:si = source string
	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

longPair:
	lodsb				; load long match length
	mov	cl, al			; cx = match length
	xchg	si, bx			; ds:si = source string
	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

smallPair:
	andnf	al, not LZG_SMALL_PAIR_FLAG
	mov	bx, di
	sub	bx, ax			; bx = position in output buffer
	xchg	si, bx			; ds:si = source string
	movsb	es:			; copy a byte (not a word)
	movsb	es:			; copy a byte (not a word)
	movsb	es:			; copy a byte (not a word)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more
done:
	mov	cx, di			; cx = end of output
	pop	di			; di = start of output
	sub	cx, di			; cx = size of uncompressed data

	.leave
	ret
LZGUncompress	endp

endif	; COMPRESSED_XIP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitKernelDgroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the kernel's dgroup resource, by copying in 
		kdata and the handle table from the XIP image.

CALLED BY:	XIPLoadKernel
PASS:		es - segment of FullXIPHeader
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if COMPRESSED_XIP

InitKernelDgroup	proc	near	uses	ax, bx, cx, dx, di, si, es, ds
	.enter

;	Get the offste into the ROM image where the kdata resource lies

	segmov	ds, es			;DS <- FullXIPHeader
	mov	di, ds:[FXIPH_bottomBlock]	;DI <- handle of dgroup
						; resource
	sub	di, ds:[FXIPH_handleTableStart]
	shr	di
	shr	di			;DI <- index into handleAddresses
					; table.

	add	di, ds:[FXIPH_handleAddresses]
	movdw	dxax, ds:[di]		;DX:AX <- address of resource in ROM
					; image.

;	Read the kdata information in from the ROM image

	mov	cx, ds:[FXIPH_numHandles]
	shl	cx
	shl	cx
	shl	cx
	shl	cx			;CX <- size of handle table
	add	cx, ds:[FXIPH_handleTableStart]	
					;CX <- # bytes to copy
	mov	es, ds:[FXIPH_dgroupSegment]
	clr	di			;ES:DI <- dest for data
	call	CopyDataFromXIPImage

;	Make sure that dgroup was loaded correctly...

EC <	mov	di, es							>
EC <	cmp	di, es:[TPD_dgroup]					>
EC <	ERROR_NE	XIP_IMAGE_ERROR					>

	.leave
	ret
InitKernelDgroup	endp

else	; not COMPRESSED_XIP

InitKernelDgroup	proc	near	uses	ax, bx, cx, dx, di, si, es, ds
	.enter

;	Get the offset into the ROM image where the kdata resource lies

	segmov	ds, es			;DS <- FullXIPHeader
	mov	di, ds:[FXIPH_bottomBlock]	;DI <- handle of dgroup 
						; resource
	sub	di, ds:[FXIPH_handleTableStart]
	shr	di
	shr	di			;DI <- index into handleAddresses
					; table.

	add	di, ds:[FXIPH_handleAddresses]
	movdw	dxax, ds:[di]		;DX:AX <- address of resource in ROM
					; image.

;	Read the kdata information in from the ROM image

	mov	cx, ds:[FXIPH_kdataSize] ;CX <- # bytes to copy
	mov	es, ds:[FXIPH_dgroupSegment]
	clr	di			;ES:DI <- dest for data	
	call	CopyDataFromXIPImage

;	Make sure that dgroup was loaded correctly...

EC <	mov	di, es							>
EC <	cmp	di, es:[TPD_dgroup]					>
EC <	ERROR_NE	XIP_IMAGE_ERROR					>

;	Read the handle table in from the ROM image

	add	ax, cx			;DX:AX <- offset in ROM image after
	adc	dx, 0			; kdata resource (this is where the
					; handle table lies)

loopTop:
	cmp	ax, MAPPING_PAGE_SIZE
	jb	10$
	inc	dx
if VG230_FULL_XIP and (MAPPING_PAGE_SIZE eq PHYSICAL_PAGE_SIZE*2)
	inc	dx
endif
	sub	ax, MAPPING_PAGE_SIZE
	jmp	loopTop
10$:

	mov	cx, ds:[FXIPH_numHandles]
	shl	cx
	shl	cx
	shl	cx
	shl	cx			;CX = size of handle table
.assert size HandleMem eq 16

	mov	di, ds:[FXIPH_handleTableStart]	;ES:DI <- dest for handle table
	call	CopyDataFromXIPImage

;	Make sure that the HM_addr field of the kernel's dgroup handle matches
;	the kernel's dgroup segment.

EC <	mov	di, ds:[FXIPH_bottomBlock]				>
EC <	mov	cx, es							>
EC <	cmp	cx, es:[di].HM_addr					>
EC <	ERROR_NE	XIP_IMAGE_ERROR					>

;	Now, zero out the udata area (the area from the end of the kdata
;	resource to the start of the handle table)
;
;	CX <- size of kdata (also, offset of udata)

	mov	di, ds:[FXIPH_kdataSize] ;DI <- offset to first byte of udata
	mov	cx, ds:[FXIPH_handleTableStart]
	sub	cx, ds:[FXIPH_kdataSize] ;CX <- # bytes of udata to zero out
	clr	al
	rep	stosb

	.leave
	ret
InitKernelDgroup	endp

endif	; COMPRESSED_XIP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocateMapPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locates where the user has specified the map page to be.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		bx - segment of map area
		al - physical page number of map area
DESTROYED:	cx, dx, di, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		fills in the "physicalPages" array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	HARDWARE_TYPE, <EMMXIP>
	physicalPages	EMMGetBanks MAX_PHYSICAL_PAGES dup (<?>)
	numPhysicalPages	word (?)
LocateMapPage	proc	near
	.enter

;	Bank in the XIP header to bank 0, and get the address of it

	mov	ax, EMF_MAP_BANK	;Start XIPHeader into bank "0"
	clr	bx
	mov	dx, cs:[loaderVars].KLV_emmHandle
	int	EMM_INT
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR
	
	mov	ah, high EMF_GET_PAGE_FRAME
	int	EMM_INT
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR
	mov	es, bx			
	mov	bx, es:[FXIPH_mapPageAddr]	;BX <- address of XIP page

;	Get information about all the physical pages in the system
;	(this is used below to figure out what physical page number will
;	be used as the mapping page, and in BankInFixedReadOnlyResources
;	to determine what pages to bank the image into).

	mov	ax, EMF_GET_BANKS
	segmov	es, cs
	mov	di, offset physicalPages
	int	EMM_INT
	tst	ah
	ERROR_NZ	LS_EMMXIP_EMM_ERROR
	cmp	cx, MAX_PHYSICAL_PAGES
	ERROR_A	LS_EMMXIP_EMM_ERROR
	mov	cs:[numPhysicalPages], cx

	call	MapSegmentToPhysicalPageNumber
EC <	ERROR_C	LS_MAP_PAGE_NOT_FOUND				>

	.leave
	ret
LocateMapPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapSegmentToPhysicalPageNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Given a segment, maps it to the associate physical page #.

CALLED BY:	GLOBAL
PASS:		bx - segment to match
RETURN:		ax - physical page #
		carry set if not found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapSegmentToPhysicalPageNumber	proc	near	uses	es, di, cx
	.enter
	segmov	es, cs
	mov	di, offset physicalPages - size EMMGetBanks
	mov	cx, cs:[numPhysicalPages]
	stc
	jcxz	exit
10$:
	add	di, size EMMGetBanks
	cmp	bx, cs:[di].EMMGB_physicalPageSegment
	loopne	10$
	stc
	jnz	exit
	mov	ax, cs:[di].EMMGB_physicalPageNumber
	clc
exit:
	.leave
	ret
MapSegmentToPhysicalPageNumber	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyFWKernelResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies all fixed writable kernel resources to the heap.

CALLED BY:	XIPLoadKernel
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NUM_IGNORED_RESOURCES	equ	2
; We ignore the first 2 resources (the coreblock and dgroup) as dgroup is
; copied in by InitKernelDgroup, and the coreblock is in the ROM image.
CopyFWKernelResources	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es,ds
		.enter
	;
	; First get the start of the handle table from the kernels GeodeHeader.
	; (not counting the first two - coreblock and idata - since don't care
	; about them.	
	;
		mov	si, cs:[kernelCoreBlock].GH_resHandleOff
		add	si, (size hptr) * NUM_IGNORED_RESOURCES
	;
	; Get the number of resources from the GeodeHeader and subract two
	; since we don't care about the coreblock and idata.
	;
		mov	cx, cs:[kernelCoreBlock].GH_resCount
		sub	cx, NUM_IGNORED_RESOURCES
	;
	; Get the segment of the XIP coreblock
	;
		mov	es, cs:[loaderVars].KLV_xipHeader
		mov	bx, es:[FXIPH_handleTableStart]
		mov	es, es:[FXIPH_dgroupSegment]
		mov	ds, es:[bx].HM_addr	; es <- seg of coreblock
	;
	; Foreach handle in the handle table
	;
topOfLoop:
		mov	di, ds:[si]		; offset of HandleMem in kdata
		mov	ax, es:[di].HM_addr	; segment of resource
		mov	dl, es:[di].HM_flags	
	;
	; Is the resource fixed and writable?
	;
		tst	ax			; if non-zero copy
		jz	noCopy
		test	dl, mask HF_DISCARDED
		jnz	noCopy
		cmp	ax, cs:[loaderVars].KLV_xipHeader	; on heap?
		jae	noCopy
	;
	; At this point we know that the current resource is fixed and 
	; writable se we now copy it to the heap using the address in
	; HM_addr
	;
		push	cx, es, ds
	;
	; Now find out where in the XIP image this resource is.  We do that
	; by looking up the handle in the FXIPH_handleAddresses table.
	;
		mov	bx, di
		sub	bx, cs:[loaderVars].KLV_handleTableStart
		mov	ds, cs:[loaderVars].KLV_xipHeader
		shr	bx
		shr	bx
		add	bx, ds:[FXIPH_handleAddresses]
		movdw	dxax, ds:[bx]		; dxax <- pos of res in image
	;
	; Now call CopyDataFromXIPImage to do the actual work
	;
		mov	cx, es:[di].HM_size	; cx <- size in paragraphs
		shl	cx
		shl	cx
		shl	cx
		shl	cx			; cx <- size in bytes
		mov	es, es:[di].HM_addr	; es:di <- addres to copy to
		clr	di			; offset
		call	CopyDataFromXIPImage
		pop	cx, es, ds
noCopy:
		add	si, size hptr
		loop	topOfLoop

		.leave
		ret
CopyFWKernelResources	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XIPLoadKernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bank in the kernel data, load the kernel's dgroup into
		the top of the heap, init the KLV_ vars, and return the
		kernel's entry pt

CALLED BY:	LoadGeos
PASS:		DX = top of heap
RETURN:		bx:ax - kernel entry point
DESTROYED:	cx, di, si, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XIPLoadKernel	proc	near	uses	ds, es
	.enter

ifdif	HARDWARE_TYPE, <BULLETXIP>
	push	dx
RESPEC <cmp	dx, RESPONDER_TOP_OF_HEAP			>
RESPEC <ERROR_B	TOP_OF_MEMORY_DIFFERS_FROM_CONSTANT		>
DOVEEC <cmp	dx, DOVE_TOP_OF_HEAP				>
DOVEEC <ERROR_NE TOP_OF_MEMORY_DIFFERS_FROM_CONSTANT		>
else
EC <	cmp	dx, BULLET_TOP_OF_HEAP				>
EC <	ERROR_B BULLET_TOP_OF_MEMORY_DIFFERS_FROM_CONSTANT	>

	call	BulletInitEMS

	;
	; Signal to the Bullet BIOS that we will handle the
	; password screen.
	;
	call	BulletInitCMOSFlags

	;
	; Move the 5K XBIOS RAM segment to where we expect it.
	;
	call	BulletMoveXBIOS

endif


;	For EMMXIP systems, make sure there's a EMM driver, open the image
;	file, and load the image into expanded memory.

ifidn	HARDWARE_TYPE, <EMMXIP>
		call	CheckIfEMMPresent
		ERROR_C	LS_EMMXIP_NO_EMM_DRIVER

		call	OpenXIPImageFile
		ERROR_C	LS_EMMXIP_CANNOT_OPEN_IMAGE_FILE

		call	LoadXIPImageIntoMemory
		ERROR_C	LS_EMMXIP_NOT_ENOUGH_EMS_MEMORY


;	Determine where the map page is (or use a hard-coded value)

		call	LocateMapPage					
	;Returns BX - segment of map segment, AL - physical page number
		mov	cs:[loaderVars].KLV_mapPageAddr, bx		
		mov	cs:[loaderVars].KLV_mapPage, al			

endif
		
	; On the Gulliver unit, make sure the MMS (Memory Mapping System) is
	; initialized correctly.
GULL <	call	GulliverInitializeMMSRegisters				>

ZOOMXIP<mov	cs:[loaderVars].KLV_mapPageAddr, ZOOMER_XIP_MAP_PAGE_ADDR  >
BULLXIP<mov	cs:[loaderVars].KLV_mapPageAddr, BULLET_XIP_MAP_PAGE_SEGMENT  >
GULL <	mov	cs:[loaderVars].KLV_mapPageAddr, \
			 MOVABLE_XIP_WINDOW_BASE_ADDRESS >
PENE <	mov	cs:[loaderVars].KLV_mapPageAddr, PENE_XIP_MAP_PAGE_SEGMENT  >

if VG230_FULL_XIP
	mov	cs:[loaderVars].KLV_mapPageAddr,
				MOVABLE_XIP_WINDOW_BASE_ADDRESS
endif

;	Now that the XIP image is loaded, bank the fixed read-only data
;	into memory

	call	BankInFixedReadOnlyResources	;Returns ES - segment of
						; FullXIPHeader

;	Do some simple error checking on the XIP image before we start.

MAX_GEODE_NAMES	equ	128

EC <	cmp	es:[FXIPH_numGeodeNames], MAX_GEODE_NAMES		>
EC <	ERROR_A	XIP_IMAGE_ERROR						>
EC <	tst	es:[FXIPH_numGeodeNames]				>
EC <	ERROR_Z	XIP_IMAGE_ERROR						>
EC <	mov	ax, es:[FXIPH_numFreeHandles]				>
EC <	cmp	ax, es:[FXIPH_numHandles]				>
EC <	ERROR_AE	XIP_IMAGE_ERROR					>
EC <	cmp	es:[FXIPH_numHandles], 65536/(size HandleMem)		>
EC <	ERROR_A		XIP_IMAGE_ERROR					>


;	Initialize various fields in the KernelLoaderVars

	mov	cs:[loaderVars].KLV_xipHeader, es
	mov	ax, es:[FXIPH_dgroupSegment]
	mov	cs:[loaderVars].KLV_dgroupSegment, ax
	mov	cs:[simpleAllocSegment], ax
	mov	ax, es:[FXIPH_numHandles]
	dec	ax
	shl	ax
	shl	ax
	shl	ax
	shl	ax
	add	ax, es:[FXIPH_handleTableStart]
	mov	cs:[loaderVars].KLV_lastHandle, ax
	mov	ax, es:[FXIPH_bottomBlock]
	mov	cs:[loaderVars].KLV_handleBottomBlock, ax
	mov	cs:[loaderVars].KLV_dgroupHandle, ax
	mov	ax, es:[FXIPH_firstFreeHandle]
	mov	cs:[loaderVars].KLV_handleFreePtr, ax
	
	mov	ax, es:[FXIPH_numFreeHandles]
	mov	cs:[loaderVars].KLV_handleFreeCount, ax

	mov	ax, es:[FXIPH_handleTableStart]
	mov	cs:[loaderVars].KLV_handleTableStart, ax
	mov	cs:[loaderVars].KLV_kernelHandle, ax

;	Copy in the kernel's kdata resource, and the associated handle table

	call	InitKernelDgroup
	
;	Now, load the kernel's coreblock into memory.

;	The kernel's coreblock is the first handle in the system, so it is
;	the first entry in the handleAddresses table...

	mov	bx, es:[FXIPH_handleAddresses]	;
	movdw	dxax, es:[bx]
	segmov	es, cs, di
	mov	di, offset kernelCoreBlock	;ES:DI <- dest to copy resource
	mov	cx, size GeodeHeader
	call	CopyDataFromXIPImage

;	Copy any fixed, writable kernel resource to the heap.

	call	CopyFWKernelResources

	movdw	bxax, cs:[kernelCoreBlock].GH_libEntry

ifdif	HARDWARE_TYPE, <BULLETXIP>
	pop	dx
else
	mov	dx, BULLET_TOP_OF_HEAP
endif

	.leave
	ret
XIPLoadKernel	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GulliverInitializeMMSRegisters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes MMS registers on Gulliver (Elan)

CALLED BY:	XIPLoadKernel (Gulliver only)

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	GULLIVER_COMMON

GulliverInitializeMMSRegisters	proc	near
	uses	ax
	.enter
	
	; Put MMSA at C000 and use I/O address x208H for the base I/O
	; address for lower 7 bits of the page registers.
	;
	mov	al, ELAN_MMSA_B_ADDRESS_SELECT
	out	ELAN_INDEX, al
	clr	ax
	out	ELAN_DATA, al
	
	; Enable MMSA memory
	;
	mov	al, ELAN_ROM_CONFIGURATION
	out	ELAN_INDEX, al
	in	al, ELAN_DATA
	or	al, ELAN_ENMMSA			; enable MMSA
	xor	al, ELAN_ENROMF			; must flip this bit on write
	out	ELAN_DATA, al
	
	; Enable MMSB memory
	;
	mov	al, ELAN_MMSB_CONTROL
	out	ELAN_INDEX, al
	in	al, ELAN_DATA
	or	al, ELAN_ENMMSB			; enable MMSB
	and	al, not ELAN_MMSABSEL		; select MMSB for stuff later
	out	ELAN_DATA, al
	
	; Clear the top bit of the page number (bit 23) for the movable 
	; XIP windows
	;
	mov	al, MOVABLE_XIP_A_23_REG
	out	ELAN_INDEX, al
	in	al, ELAN_DATA
	and	al, not MOVABLE_XIP_A_23_MASK
	out	ELAN_DATA, al
	
	; Select the ROMDOS device for the movable XIP windows
	;
    CheckHack <ELAN_SELECT_ROMDOS eq 0>
	mov	al, MOVABLE_XIP_DEVICE_SELECT_REG
	out	ELAN_INDEX, al
	in	al, ELAN_DATA
	and	al, not MOVABLE_XIP_DEVICE_SELECT_MASK
	out	ELAN_DATA, al
	
	; Select the ROMDOS device for the fixed XIP windows
	;
    CheckHack <ELAN_SELECT_ROMDOS eq 0>

	out	ELAN_INDEX, al
if (FIXED_XIP_DEVICE_SELECT_MASK_1 eq 0ffh)
	clr	al
else
	in	al, ELAN_DATA
	and	al, not FIXED_XIP_DEVICE_SELECT_MASK_1
endif
	out	ELAN_DATA, al
	
	mov	al, FIXED_XIP_DEVICE_SELECT_REG_2
	out	ELAN_INDEX, al
if (FIXED_XIP_DEVICE_SELECT_MASK_2 eq 0ffh)
	clr	al
else
	in	al, ELAN_DATA
	and	al, not FIXED_XIP_DEVICE_SELECT_MASK_2
endif
	out	ELAN_DATA, al
	
	; Make sure we have a 16-bit configuration selected for ROMDOS
	;
	mov	al, ELAN_ROM_CONFIGURATION_2		; write-only
	out	ELAN_INDEX, al
	mov	al, ELAN_ROM16
	out	ELAN_DATA, al
	
	; Make sure ROMDOS is write-protected (not necessary for real device)
	;
	mov	al, ELAN_MEMORY_WAIT_STATE		; write-only
	out	ELAN_INDEX, al
	clr	ax
	out	ELAN_DATA, al
	
	.leave
	ret
GulliverInitializeMMSRegisters	endp

endif	;GULLIVER_COMMON

endif	; FULL_EXECUTE_IN_PLAGE

