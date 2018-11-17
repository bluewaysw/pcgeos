COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsIO.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Functions to mess with open files.
		

	$Id: gfsIO.asm,v 1.1 97/04/18 11:46:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on a file handle. If appropriate, the
		disk on which the file is located will have been locked.

CALLED BY:	DR_FS_HANDLE_OP
PASS:		ah	= FSHandleOpFunction to perform
		bx	= handle of open file
		es:si	= DiskDesc (FSInfoResource and affected drive locked
			  shared)
		other parameters as appropriate.
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful:
			return values depend on subfunction
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	*** MORE INFO HERE ***

    FSHOF_READ		enum	FSHandleOpFunction
    ;	Pass:	ds:dx	= buffer to which to read
    ;		cx	= # bytes to read
    ;	Return:	carry clear if successful:
    ;			ax	= # bytes read
    Add the base to the seek position, bound the number of bytes to read to the
    size of the file, and call GFSDevRead, then advance the seek position by
    that much and return the number of bytes read.

    FSHOF_WRITE		enum	FSHandleOpFunction
    ;	Pass:	ds:dx	= buffer from which to write
    ;		cx	= # bytes to write
    ;	Return:	carry clear if successful:
    ;			ax	= # bytes written
    ERROR_WRITE_PROTECTED

    FSHOF_POSITION	enum	FSHandleOpFunction
    ;	Pass:	al	= FileSeekModes
    ;		cx:dx	= offset to use
    ;	Return:	carry clear if successful:
    ;			dx:ax	= new absolute file position
    Store as seek position and return in dxax

    FSHOF_TRUNCATE	enum	FSHandleOpFunction
    ;	Pass:	cx:dx	= size to which to truncate the file
    ;	Return:	nothing (besides carry & error code)
    ;
    ERROR_WRITE_PROTECTED

    FSHOF_COMMIT	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing (besides carry & error code)
    do nothing

    FSHOF_LOCK		enum	FSHandleOpFunction
    ;	Pass:	cx	= top of inherited stack frame, set up as:
    ;			regionStart	local	dword
    ;			regionLength	local	dword
    ;					.enter
    ;	Return:	nothing (besides carry & error code)
    ;
    do nothing

    FSHOF_UNLOCK	enum	FSHandleOpFunction
    ;	Pass:	cx	= top of inherited stack frame, set up as:
    ;			regionStart	local	dword
    ;			regionLength	local	dword
    ;					.enter
    ;	Return:	nothing (besides carry & error code)
    ;
    do nothing

    FSHOF_GET_DATE_TIME	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx	= last modification time (FileTime record)
    ;		dx	= last modification date (FileDate record)
    ;
    Map EA and fetch 

    FSHOF_SET_DATE_TIME	enum	FSHandleOpFunction
    ;	Pass:	cx	= new modification time (FileTime record)
    ;		dx	= new modification date (FileDate record)
    ;	Return:	nothing (besides carry & error code)
    ;
    ERROR_WRITE_PROTECTED

    FSHOF_FILE_SIZE	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	dx:ax	= size of the file
    ;
    Return size from priv data

    FSHOF_ADD_REFERENCE	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;
    Increment GFE_refCount

    FSHOF_CHECK_DIRTY	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	ax	= non-zero if file is dirty.
    ;
    ;	Notes:	This is used by the FileClose code in the kernel to determine
    ;		if it needs to lock the file's disk. IF THE FSD SAYS THE
    ;		FILE IS NOT DIRTY, THE DISK WILL NOT BE LOCKED AND NO I/O FOR
    ;		THE FILE MAY TAKE PLACE.
    ;
    return ax=0

    FSHOF_CLOSE		enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;
    ;	Notes:	As noted for FSHOF_CHECK_DIRTY, the disk will not be locked
    ;		unless the previous call to FSHOF_CHECK_DIRTY returned that
    ;		the file was dirty. If the disk is not locked, no I/O may
    ;		take place on behalf of the file, not even to update its
    ;		directory entry.
    ;
    decrement reference count; if 0, entry will be reused
		
    FSHOF_GET_FILE_ID	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx:dx	= file ID
    ;
    return GFE_extAttrs

    FSHOF_CHECK_NATIVE	enum	FSHandleOpFunction
    ;	Pass:	ch	= FileCreateFlags
    ;	Return:	carry set if file is in format implied by FCF_NATIVE
    ;
    Map ea and check GEA_attrs.FA_GEOS

    FSHOF_GET_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	ss:dx	= FSHandleExtAttrData
    ;		cx	= size of FHEAD_buffer, or # entries in same if
    ;			  FHEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    Copy stuff to gfsLastFound/gfsLastFoundEA and call common code
    
    FSHOF_SET_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	ss:dx	= FSHandleExtAttrData
    ;		cx	= size of FHEAD_buffer, or # entries in same if
    ;			  FHEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    ERROR_WRITE_PROTECTED
    
    FSHOF_GET_ALL_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	ax	= handle of locked block with array of FileExtAttrDesc
    ;			  structures for all attributes possessed by the file,
    ;			  except those that can never be set.
    ;		cx	= number of entries in that array.
    ;
    call common code

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSHandleOp	proc	far
		uses	es, si, bx
		.enter
	;
	; Point es:si to the GFSFileEntry for the thing.
	; 
		push	ax
		mov	es, es:[FIH_dgroup]
		mov	al, es:[bx].HF_sfn
		mov	es, es:[bx].HF_private
		mov	ah, size GFSFileEntry
		mul	ah
		add	ax, offset GFTB_entries
		mov_tr	bx, ax
EC <		tst	es:[bx].GFE_refCount				>
EC <		ERROR_Z	FILE_NOT_OPEN					>
if _PCMCIA
		mov	al, mask GDLF_FILE
else
		clr	al
endif
		call	GFSDevLock
		pop	ax
		
		xchg	al, ah
		mov	di, ax
		xchg	al, ah
		andnf	di, 0xff
		shl	di
		jmp	cs:[handleOpJmpTable][di]

handleOpJmpTable	nptr.near	\
			doRead,			; FSHOF_READ                  
			writeP,			; FSHOF_WRITE                 
			doPos,			; FSHOF_POSITION              
			writeP,			; FSHOF_TRUNCATE              
			doNothing,		; FSHOF_COMMIT                
			doNothing,		; FSHOF_LOCK                  
			doNothing,		; FSHOF_UNLOCK                
			doGetDate,		; FSHOF_GET_DATE_AND_TIME     
			writeP,			; FSHOF_SET_DATE_AND_TIME     
			doSize,			; FSHOF_FILE_SIZE             
			doAddRef,		; FSHOF_ADD_REFERENCE         
			doCheckDirty,		; FSHOF_CHECK_DIRTY           
			doClose,		; FSHOF_CLOSE                 
			doGetFileID,		; FSHOF_GET_FILE_ID           
			doCheckNative,		; FSHOF_CHECK_NATIVE          
			doGetExtAttrs,		; FSHOF_GET_EXT_ATTRIBUTES    
			writeP,			; FSHOF_SET_EXT_ATTRIBUTES    
			doGetAllExtAttrs,	; FSHOF_GET_ALL_EXT_ATTRIBUTES
			doNothing,		; FSHOF_FORGET
			doNothing		; FSHOF_SET_FILE_NAME

CheckHack	<length handleOpJmpTable eq FSHandleOpFunction>

	;--------------------
writeP:
		mov	ax, ERROR_WRITE_PROTECTED
		stc
		jmp	done
	;--------------------
doRead:
	; es:bx	= GFSFileEntry
	; ds:dx	= buffer
	; cx	= # bytes to read
	; -> ax	= # bytes read
	; 
		push	dx, cx
		mov	di, dx		; we'll want es:di eventually...
	;
	; Make sure current position isn't past the end of the file.
	; 
		movdw	dxax, es:[bx].GFE_curPos
		cmpdw	dxax, es:[bx].GFE_size
		jae	readNothingAndLikeIt	; blech, it is
	;
	; Add the number of bytes to read to the position and figure whether
	; that's beyond the end of the file. Should end up with dx=-1, and
	; ax= the amount of the overshoot, if it is.
	; 
		add	ax, cx
		adc	dx, 0
		subdw	dxax, es:[bx].GFE_size
		jb	readCX
		sub	cx, ax		; reduce bytes to read by amount of
					;  overshoot
readCX:
	;
	; Read the number of bytes in CX from the current seek position.
	; 
		movdw	dxax, es:[bx].GFE_data		; dxax <- base o' file
		adddw	dxax, es:[bx].GFE_curPos	; dxax <- current pos
		push	es, cx
		segmov	es, ds				; es:di <- buffer
		call	GFSDevRead
		pop	es, cx
		jc	readComplete
	;
	; Read successful. Adjust the seek position by the number of bytes
	; read.
	; 
		add	es:[bx].GFE_curPos.low, cx
		adc	es:[bx].GFE_curPos.high, 0
		mov_tr	ax, cx
readComplete:
		pop	dx, cx
		jmp	done

readNothingAndLikeIt:
	;
	; Current position is beyond the end of the file, so return 0 bytes
	; read, but no error.
	; 
		clr	ax
		jmp	readComplete
	;--------------------
doPos:
	; es:bx	= GFSFileEntry
	; al	= FilePosMode
	; cxdx	= new position
	; -> dxax = new file position
	; 
		push	cx
		
CheckHack <FILE_POS_START lt FILE_POS_RELATIVE and \
	   FILE_POS_END gt FILE_POS_RELATIVE>

		cmp	al, FILE_POS_RELATIVE
		jb	haveNewPos
		
		movdw	siax, es:[bx].GFE_curPos; assume relative
		je	haveBasePos
		
		movdw	siax, es:[bx].GFE_size	; nope, from end

haveBasePos:
		adddw	cxdx, siax
		jns	haveNewPos
		clrdw	cxdx		; went negative -- truncate it to 0
haveNewPos:
		movdw	es:[bx].GFE_curPos, cxdx
		mov_tr	ax, dx		; return new position in dxax
		mov	dx, cx
		clc
		pop	cx
		jmp	done
		
	;--------------------
doGetDate:
	; es:bx	= GFSFileEntry
	; -> cx	= FileTime
	;    dx = FileDate
	;    
		movdw	dxax, es:[bx].GFE_extAttrs
		call	GFSDevMapEA
		jc	done
		
		mov	cx, es:[di].GEA_modified.FDAT_time
		mov	dx, es:[di].GEA_modified.FDAT_date
		call	GFSDevUnmapEA
		jmp	done

	;--------------------
doSize:
		movdw	dxax, es:[bx].GFE_size
		jmp	doneOK

	;--------------------
doAddRef:
		inc	es:[bx].GFE_refCount
if _PCMCIA
		push	ds
		call	LoadVarSegDS
		mov	bx, ds:[curSocketPtr]
		inc	ds:[bx].PGFSSI_inUseCount
		pop	ds
endif
		jmp	doneOK
	;--------------------
doCheckDirty:
		clr	ax		; these files are never dirty
		jmp	done
	;--------------------
doClose:
EC <		tst	es:[bx].GFE_refCount				>
EC <		ERROR_Z	FILE_ALREADY_CLOSED				>
		dec	es:[bx].GFE_refCount
		push	cx
if _PCMCIA
		push	ds, bx
		call	LoadVarSegDS
		mov	bx, ds:[curSocketPtr]
		dec	ds:[bx].PGFSSI_inUseCount
		pop	ds, bx
endif
		push	dx		
		movdw	cxdx, es:[bx].GFE_extAttrs
		mov	ax, FCNT_CLOSE
		call	GFSNotifyIfNecessary
		pop	dx
		pop	cx
		
		clc
		jmp	exit		; (device unlocked by
					; GFSNotifyIfNecessary)
	;--------------------
doGetFileID:
		movdw	cxdx, es:[bx].GFE_extAttrs
		jmp	doneOK
	;--------------------
doNothing:
doneOK:
		clc

done:
		call	GFSDevUnlock
exit:
		.leave
		ret
	;--------------------
doCheckNative:
		push	cx, dx, ax
		andnf	cx, (mask FCF_NATIVE shl 8)
		movdw	dxax, es:[bx].GFE_extAttrs
		call	GFSDevMapEA
		jc	compareTheoryAndReality
		test	es:[di].GEA_attrs, FA_GEOS
		jnz	compareTheoryAndReality
		ornf	cl, mask FCF_NATIVE
compareTheoryAndReality:
		xor	ch, cl
		pop	cx, dx, ax
		js	cNDone		; => theory didn't match reality, so
					;  leave carry clear
		stc
cNDone:
		call	GFSDevUnmapEA
		jmp	done
	;--------------------
doGetExtAttrs:
	; es:bx	= GFSFileEntry
	; ss:dx	= FSHandleExtAttrData
	; cx	= size of FHEAD_buffer or # entries in same if multiple
	; -> carry/ax
	; 
		call	GFSDevUnlock	; can't hold this while calling to
					;  Movable...
		call	GFSEAGetHandleExtAttrs
		jmp	done
	;--------------------
doGetAllExtAttrs:
	; es:bx	= GFSFileEntry
	; -> ax = handle of attrs
	;    cx = # attrs
		call	GFSDevUnlock	; can't hold this while calling to
					;  Movable
		call	GFSEAGetAllHandleExtAttrs
		jmp	done
	;--------------------
GFSHandleOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if two file handles point to the same file on disk

CALLED BY:	DR_FS_COMPARE_FILES
PASS:		al	= HF_SFN for first file
		bx	= HF_private for first file
		cl	= HF_SFN for second file
		dx	= HF_private for second file
RETURN:		ah	= flags byte for sahf that will allow je if the
			  two files refer to the same disk file, with
			  carry clear always
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The files are the same if their GFE_data fields are the same

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCompareFiles	proc	far
		uses	ds, es, bx, si
		.enter
		mov	ah, size GFSFileEntry
		mul	ah
		mov_tr	si, ax
		mov	ds, bx
		mov	al, size GFSFileEntry
		mul	cl
		mov_tr	bx, ax
		mov	es, dx
		cmpdw	es:[bx].GFE_data, ds:[si].GFE_data, ax
		clc
		lahf
		.leave
		ret
GFSCompareFiles	endp


Resident	ends
