COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driUtils.asm

AUTHOR:		Adam de Boor, Mar 10, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/92		Initial revision


DESCRIPTION:
	DR DOS-specific utilities
		

	$Id: driUtils.asm,v 1.1 97/04/10 11:54:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPointToSFTEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point es:di to the FileHandle for the passed SFN

CALLED BY:	EXTERNAL
PASS:		al	= SFN
RETURN:		carry clear if ok:
			es:di	= FileHandle
		carry set if SFN invalid
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPointToSFTEntry proc	far
		.enter
		segmov	es, dgroup, di
		mov	di, ax
		andnf	di, 0xff
		shl	di
		add	di, es:[handleTable].offset
		mov	es, es:[handleTable].segment
		mov	di, es:[di]
		tst	di		; (clears carry)
		jnz	done
		stc			; flag error
done:
		.leave
		ret
DOSPointToSFTEntry endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCompareSFTEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two entries in the file table.

CALLED BY:	DOSCompareFiles
PASS:		ds:si	= FileHandle 1
		es:di	= FileHandle 2
RETURN:		ZF set if ds:si and es:di refer to the same disk file
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCompareSFTEntries proc near
		.enter

		test	ds:[si].FH_ioctl, mask FHIS_DEV
		jnz	isDevice
		test	es:[di].FH_ioctl, mask FHIS_DEV
		jnz	notEqual
	;
	; Because DR DOS keeps a single FileDesc structure for each disk file
	; that's open, to which the individual FileHandle structures (1 per
	; open DOS handle) point, we need only compare the two FileDesc pointers
	; of the FileHandles to see if they're the same disk file.
	; 
		mov	ax, ds:[si].FH_desc
		cmp	ax, es:[di].FH_desc
done:
		.leave
		ret
isDevice:
		test	es:[di].FH_ioctl, mask FHIS_DEV
		jz	notEqual
		mov	ax, ds:[si].FH_info.FHDFI_device.offset
		cmp	ax, es:[di].FH_info.FHDFI_device.offset
		jne	done
		mov	ax, ds:[si].FH_info.FHDFI_device.segment
		cmp	ax, es:[di].FH_info.FHDFI_device.segment
		jmp	done

notEqual:
		or	ax, 1
		jmp	done
DOSCompareSFTEntries endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DRIFixFileData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix the DR DOS file handle/descriptor data for a single
		file, for which we know we are soley responsible.

CALLED BY:	DFI_callback, DOSHandleOp
PASS:		ds:bx	= HandleFile to fix
RETURN:		di	= SFN (di.high == 0)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DRIFixFileData proc	far
		uses	ds, bx, es
		.enter
		mov	di, {word}ds:[bx].HF_sfn
		andnf	di, 0xff		; get SFN and push it
		push	di			;  so it's there for us later

		mov	al, ds:[bx].HF_accessFlags
		mov	bx, ds:[bx].HF_private
		call	LoadVarSegDS
		cmp	ds:[bx].DFE_index, -1	; any index saved?
		je	bitManglingComplete	; no => can't be trashed...
		

		shl	di
		add	di, ds:[handleTable].offset
		mov	es, ds:[handleTable].segment
		mov	di, es:[di]		; es:di <- FileHandle
			CheckHack <FA_READ_ONLY eq 0>
	    ;
	    ; If file marked for writing,   make sure FHAM_WRITE is set in
	    ; the handle still.
	    ; 
		test	al, mask FFAF_MODE
		jz	accessModeOK
		ornf	es:[di].FH_mode, mask FHAM_WRITE
accessModeOK:
	    ;
	    ; If file was marked dirty at the last disk change, make sure
	    ; it's still marked dirty. XXX: cached blocks will have been
	    ; marked clean, though...or thrown out.
	    ; 
		mov	di, es:[di].FH_desc
		test	ds:[bx].DFE_flags, mask DFF_DIRTY
		jz	setIndex
		ornf	ds:[di].FD_flags, mask FDS_DIRTY
setIndex:		
	    ;
	    ; Store the proper directory index in the descriptor.
	    ; 
		mov	bx, ds:[bx].DFE_index
		mov	es:[di].FD_dirIndex, bx

bitManglingComplete:
		pop	di			; di <- SFN
		.leave
		ret
DRIFixFileData endp

Resident	ends

PathOpsRare	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DRIFixIndices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix the directory indices etc. for all files on the passed
		disk.

CALLED BY:	DOSAllocOp
PASS:		es:si	= DiskDesc whose files are to have their indices
			  restored.
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DRIFixIndices	proc	far
		uses	si, ax, bx, cx
		.enter
		mov	cx, si
		mov	di, cs
		mov	si, offset DFI_callback
		clr	bx
		call	FileForEach
		.leave
		ret
DRIFixIndices	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFI_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for DRIFixIndices to restore the
		directory index and dirty state for all files open to
		the passed disk.

CALLED BY:	DRIFixIndices via FileForEach
PASS:		ds:bx	= HandleFile to examine
		cx	= DiskDesc of disk
RETURN:		carry set to stop processing (always returns carry clear,
		    as who knows when we've seen the last file on the disk...)
DESTROYED:	di, si, es (if I want to)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFI_callback	proc	far
		.enter
		cmp	ds:[bx].HF_disk, cx
		jne	done
		call	DRIFixFileData
done:
		clc
		.leave
		ret
DFI_callback	endp

PathOpsRare	ends
