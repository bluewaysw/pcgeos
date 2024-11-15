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
        push    ds
        LoaderDS
	mov	cl, ds:[stdPathUpwardTree-1][si].SPN_parent	;cx = parent
        pop     ds
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

        LoaderDS
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
        LoaderDS
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
LoadKernel	proc	near	uses ds
	.enter

	; allocate the core block and set it up

	call	AllocateCoreBlock		;ds <- core block

	call	LoadExportTable

	call	InitResources

	call	RelocateExportTable

	call	ProcessGeodeFile		;bx:ax <- library entry

        push    bx, ax
        call    ConvertKernelBlocks
        pop     bx, ax

	.leave
	ret
LoadKernel	endp


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

	mov	ds, cs:[loaderVars].KLV_dgroupSegment
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
	mov	ds, es:[loaderVars].KLV_dgroupSegment
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
	mov	ds, es:[loaderVars].KLV_dgroupSegment

	push	ax, cx
	mov	cx, ax
	clr	bx
	add	cx, 15			;round cx to nearest paragraph
	and	cx, not 15
	call	GPMIAllocateNotPresentBlock
	ERROR_C	LS_NOT_ENOUGH_MEMORY
	mov	ax, bx
	call	AllocateHandle
	mov	ds:[bx].HM_addr, ax
	pop	ax, cx

	mov	ds:[bx].HM_otherInfo, 1
	mov	ds:[bx].HM_flags, cl
        ; If the block is a code block, convert it to such now.
	test	ch, mask HAF_CODE
	jz	notCode
	push	bx
	mov	bx, ds:[bx].HM_addr
	call	GPMIConvertToCodeBlock
	pop	bx
notCode:
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
	mov	ax, es:[loaderVars].KLV_dgroupSegment
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
	mov	ds, es:[loaderVars].KLV_dgroupSegment
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
	mov	ds, es:[loaderVars].KLV_dgroupSegment
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
	mov	ds, es:[loaderVars].KLV_dgroupSegment
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
	mov	ds, es:[loaderVars].KLV_dgroupSegment
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


COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertKernelBlocks

DESCRIPTION:	Make all code blocks be just that -- code16 blocks in the GPMI

CALLED BY:	LoadKernel

PASS:
	ds - core block for new Geode
	es - kernel variables

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LES	11/7/2000	Created.
------------------------------------------------------------------------------@
ifidn	HARDWARE_TYPE, <PC>
ConvertKernelBlocks	proc	near
	uses    bx, cx, ds
	.enter

	mov	bx, es:[loaderVars].KLV_handleBottomBlock
	mov	ds, es:[loaderVars].KLV_dgroupSegment
	mov	cx, bx
walkLoop:
	cmp	ds:[bx].HM_addr, 0
	je	skipHandle
	test	({word}ds:[bx].HM_usageValue).high, mask HAF_CODE
	je	skipHandle
	push	bx
	mov	bx, ds:[bx].HM_addr
	call	GPMIConvertToCodeBlock
	pop	bx
skipHandle:
	clr	ds:[bx].HM_usageValue
	mov	bx, ds:[bx].HM_next
	cmp	bx, cx
	jne	walkLoop

	.leave
	ret
ConvertKernelBlocks	endp
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

