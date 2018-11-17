COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsEnum.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Support for FileEnum
		

	$Id: gfsEnum.asm,v 1.1 97/04/18 11:46:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSFileEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all files/dirs in the thread's current directory
		calling the kernel back for each one after gathering whatever
		extended file attributes are requested.

CALLED BY:	DR_FS_FILE_ENUM
PASS:		cx:dx	= routine to call back
		ds	= segment of FileEnumCallbackData
		es:si	= DiskDesc of current path, with FSIR and drive locked
			  shared. Disk is locked into drive.
		ss:bx	= stack frame to pass to callback
RETURN:		carry set if no files/dirs to enumerate:
			ax	= ERROR_NO_MORE_FILES
		else carry & registers as set by callback routine.
DESTROYED:	ax, bx, cx, dx may all be nuked before the callback is
		called, but not if it returns carry set.
		bp may be destroyed before & after the callback.

PSEUDO CODE/STRATEGY:
		The callback function is called as:
			Pass:	ds	= segment of FileEnumCallbackData.
					  Any attribute descriptor for which
					  the file has no corresponding
					  attribute should have the
					  FEAD_value.segment set to 0. All
					  others must have FEAD_value.segment
					  set to DS when their value is stored.
				ss:bp	= ss:bx passed to FSD
			Return:	carry set to stop enumerating files:
					ax	= error code
			Destroy:es, bx, cx, dx, di, si

		If the filesystem supports the "." and ".." special directories,
		they must *not* be passed to the callback routine.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSFileEnum	proc	far
		uses	si, es
		.enter
	;
	; Lock the device and let it know we'll be marching through extended
	; attribute structures, not getting them piecemeal.
	; 
		mov	al, mask GDLF_SCANNING or mask GDLF_DISK
		call	GFSDevLock
	;
	; Allocate work area.
	; 
		mov	ax, size GFSGetExtAttrData
		push	cx, bx
		mov	cx, mask HF_FIXED
		call	MemAlloc
		pop	cx, bp
		jnc	haveDataBlock
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	exit

haveDataBlock:
	;
	; Fill in the various pieces of our data block.
	; 
		push	cx, bx
			CheckHack <offset FECD_attrs eq 0>
		clr	bx
		mov	cx, -1
countAttrsLoop:
		inc	cx
		cmp	ds:[bx].FEAD_attr, FEA_END_OF_LIST
		lea	bx, ds:[bx+size FileExtAttrDesc]
		jne	countAttrsLoop
afterCount::
		pop	bx
		push	ds			; push FECD
		mov	ds, ax
		pop	ds:[GGEAD_attrs].segment; to pop it into place
		mov	ds:[GGEAD_attrs].offset, 0
		mov	ds:[GGEAD_numAttrs], cx
		mov	ds:[GGEAD_block], bx
		pop	cx
	    ;
	    ; Fetch the DirPathInfo from the thread's current path.
	    ; 
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	es, ax
		mov	ax, es:[FP_pathInfo]
		mov	ds:[GGEAD_pathInfo], ax
	    ;
	    ; Store away the callback routine, so we can call it easily.
	    ; 
		mov	ds:[GGEAD_spec].GGEASD_enum.GED_callback.offset, dx
		mov	ds:[GGEAD_spec].GGEASD_enum.GED_callback.segment, cx
	    ;
	    ; Save the frame the kernel expects.
	    ; 
		mov	ds:[GGEAD_spec].GGEASD_enum.GED_kernelFrame, bp


	    ;
	    ; Store the address of the first extended attributes block and
	    ; the number of directory entries in the current directory into
	    ; our private data in the work area.
	    ; 
		movdw	dxax, ({GFSPathPrivate}es:[FP_private]).GPP_dirEnts
		mov	cx, ({GFSPathPrivate}es:[FP_private]).GPP_size
		mov	ds:[GGEAD_spec].GGEASD_enum.GED_numEntries, cx
		call	GFSDevFirstEA
		movdw	ds:[GGEAD_spec].GGEASD_enum.GED_eaOffset, dxax
		call	MemUnlock

	    ;
	    ; Set things for GFSVirtGetExtAttrsLow
	    ; 
	    	mov	ds:[GGEAD_disk], si
		mov	ds:[GGEAD_flags], mask GGEAF_CLEAR_VALUE_SEG_IF_ABSENT
					; remaining flags filled in by
					;  GFSVirtGetExtAttrsLow
findLoop:
	;
	; ds	= GFSGetExtAttrData
	;
		movdw	dxax, ds:[GGEAD_spec].GGEASD_enum.GED_eaOffset
		call	GFSDevMapEA	; es:di <- the thing
		jc	done		; error => complete for one reason
					;  or another
	;
	; We're not supposed to pass . or .. to the callback. Since these are
	; the only files that start with . in the GFS universe, we have only
	; to check the first char for being . and bail if so.
	; 

		cmp	es:[di].GEA_dosName, '.'
		jne	processFile
		
		call	GFSDevUnmapEA
		jmp	endFindLoop

processFile:
	;
	; Initialize the header state to indicate we have it. It'll get
	; unmapped by GFSEAGetExtAttrsLow.
	; 
		movdw	ds:[GGEAD_header], esdi

	;
	; Assume all attributes will be there...
	; 
		call	GFSEnumInitAttrs
	;
	; Now try and fetch them.
	; 
		call	GFSEAGetExtAttrsLow
	;
	; All the extended attributes have been filled in, or not, as
	; appropriate, and we're ready now to call the kernel back.
	;
		call	GFSEnumCallCallback
		jc	done			; => stop enumerating and don't
						;  biff any registers
endFindLoop:		
	;
	; Go for the next file.
	; 
		movdw	dxax, ds:[GGEAD_spec].GGEASD_enum.GED_eaOffset
		call	GFSDevNextEA
		movdw	ds:[GGEAD_spec].GGEASD_enum.GED_eaOffset, dxax
		dec	ds:[GGEAD_spec].GGEASD_enum.GED_numEntries
		jnz	findLoop		

	;--------------------
done:
	;
	; Free our data block and restore the FECD segment.
	;
		pushf
		push	bx
		mov	bx, ds:[GGEAD_block]
		mov	ds, ds:[GGEAD_attrs].segment	; return ds = FECD
		call	MemFree
		pop	bx
	;
	; Release the working directory lock and boogie.
	;
		popf

exit:
		call	GFSDevUnlock
		.leave
		ret
GFSFileEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEnumInitAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the array of attributes on the assumption that
		all requested attrs are present.

CALLED BY:	(INTERNAL) GFSFileEnum
PASS:		ds	= FECD segment
		es:di	= GFSExtAttrs
RETURN:		nothing
DESTROYED:	es, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEnumInitAttrs proc	near
		.enter
	;
	; Copy the requisite pieces to the gfsLastFound structure for
	; GetExtAttrsLow.
	; 
		push	ds
		segmov	ds, dgroup, cx
		movdw	ds:[gfsLastFound].GDE_size, es:[di].GEA_size, cx
		mov	cx, es:[di].GEA_type
		mov	ds:[gfsLastFound].GDE_fileType, cl
		segmov	es, ds
		pop	ds
		movdw	es:[gfsLastFoundEA], \
			ds:[GGEAD_spec].GGEASD_enum.GED_eaOffset, \
			cx
		
	;
	; Assume all attributes will be there...
	; 
		les	di, ds:[GGEAD_attrs]
		mov	cx, ds:[GGEAD_numAttrs]
setSegment:
		mov	es:[di].FEAD_value.segment, es
		add	di, size FileExtAttrDesc
		loop	setSegment
		.leave
		ret
GFSEnumInitAttrs endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSEnumCallCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the passed in callback function

CALLED BY:	(INTERNAL) GFSEnum
PASS:		ds	= FECD
RETURN:		carry set:
			all registers from callback except ds
		carry clear:
			all registers from callback except ds & bp
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSEnumCallCallback proc	near
		.enter
		push	bp
	;
	; Reload frame pointer from original caller.
	; 
		mov	bp, ds:[GGEAD_spec].GGEASD_enum.GED_kernelFrame
							; restore its stack
							;  frame
		push	ds				; it can biff ES, so
							;  save data segment
							;  now
		segmov	es, ds				; es <- our data
		mov	ds, es:[GGEAD_attrs].segment	; ds <- FECD
	;
	; We use ProcCallFixedOrMovable in all cases, so we can call callbacks
	; in XIP kernels, even if we aren't the "XIP" version.
	;
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		movdw	bxax, es:[GGEAD_spec].GGEASD_enum.GED_callback
		call	ProcCallFixedOrMovable
		pop	ds
		jc	aborted
	;
	; Restore BP, in case needed by GFSLinkEnum, for example.
	; 
		pop	bp
done:
		.leave
		ret

aborted:
		inc	sp		; discard saved bp
		inc	sp
		jmp	done
GFSEnumCallCallback endp

Movable	ends
