COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderRecord.asm

AUTHOR:		Chris Boyke, Martin Turon

ROUTINES:
		Name			Description
		----			-----------
	EXT	BuildOpenFilePathname

	EXT	FolderSendToDisplayList
	EXT	FolderSendToChildren
	EXT	FolderRecordCallParent

	INT	FolderCallCallBack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	Initial version.

DESCRIPTION:
	Routines to operate on the FolderRecord data structure.

	$Id: cfolderRecord.asm,v 1.2 98/06/03 13:36:30 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderOpenCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildOpenFilePathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get complete pathname of FolderRecord

CALLED BY:	INTERNAL
			FileOpenESDI
		(NewDesk: various)

PASS:		es:di - pointer to file/subdirectory's entry in folder buffer
		*ds:si - FolderClass object 

RETURN:		pathBuffer - complete pathname
		openFileDiskHandle - disk handle
		preserves ds, si, es, di

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/1/89		Initial version
	brianc	12/18/89	updated

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESK
BuildOpenFilePathname	proc	far

else

BuildOpenFilePathname	proc	near

endif

	class	FolderClass

	uses	ds, si, es, di, ax, dx

	.enter

	call	Folder_GetDiskAndPath
	mov	ss:[openFileDiskHandle], ax

	push	es, di				; save entry
	lea	si, ds:[bx].GFP_path		; ds:si = this
						; folder's pathname
NOFXIP<	mov	di, segment pathBuffer 		; es:di = temp. buffer for >
NOFXIP<	mov	es, di				; complete pathname	>
FXIP<	mov	di, bx				; save value of bx	>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di				; restore bx		>
	mov	di, offset pathBuffer
	call	CopyNullSlashString		; path + '\'
	pop	ds, si				; ds:si = name of subdirectory
SBCS <	add	si, offset FR_name					>
DBCS <			CheckHack <(offset FR_name) eq 0>		>
	call	CopyNullTermString

	.leave

	ret
BuildOpenFilePathname	endp


FolderOpenCode	ends


FolderUtilCode	segment


COMMENT @-------------------------------------------------------------------
			FolderSendToDisplayList
----------------------------------------------------------------------------

SYNOPSIS:	Call a callback routine for each FolderRecord in the
		display list.

CALLED BY:	INTERNAL

PASS:		*ds:si - FolderClass object
		ax:bx  - far procedure to call for each FolderRecord
			 (must be vfptr if XIP'ed)
		cx,dx,bp - data to pass to callback

RETURN:		ax,cx,dx,bp - returned from callback

DESTROYED:	bx 

PSEUDO CODE/STRATEGY:	

	CALLBACK ROUTINE:

		PASS:		ds:di 	= FolderRecord "instance data"

		RETURN (PASSED TO NEXT CALLBACK): cx, dx, bp

		CAN DESTROY:  ax, bx, di, si, ds, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine was designed to ease the pain of changing
	FolderRecords to objects eventually...


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/1/92		Initial version

---------------------------------------------------------------------------@
FolderSendToDisplayList	proc	far
		uses	di
		.enter
		mov	di, FCT_DISPLAY_LIST
		call	FolderSendToChildren
		.leave
		ret
FolderSendToDisplayList	endp


COMMENT @-------------------------------------------------------------------
			FolderSendToChildren
----------------------------------------------------------------------------

SYNOPSIS:	Call a callback routine for each FolderRecord in the
		specified list.

CALLED BY:	INTERNAL

PASS:		*ds:si 	 = FolderClass object
		ax:bx 	 = far procedure to call for each FolderRecord
			   (must be vfptr if XIP'ed)
		cx,dx,bp = data to pass to callback
		di	 = which children to send to (FolderChildType)
			   (if FCT_SINGLE, bp = offset of FolderRecord)

RETURN:		ax,cx,dx,bp - returned from callback
		ds - fixed up if folder block moved

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

	CALLBACK ROUTINE:

		PASS:		ds:di 	= FolderRecord

		RETURN: cx, dx, bp
			CARRY SET to end enumeration

		CAN DESTROY:	ax, bx, di, si, ds, es

		ADDED NOTES:	Can use FolderRecordCallParent to get
				information from the parent folder.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/ 2/92	Initial version
	sh	 5/12/94	XIP'ed
---------------------------------------------------------------------------@
FolderSendToChildren	proc	far
		class	FolderClass 

paramBP 	local	word 		push	bp
folder		local	optr		push	ds:[LMBH_handle], si
callback 	local	fptr.far	push 	ax, bx 
childType	local	FolderChildType	push	di
count		local	word
		
		uses	es, di
		.enter

ForceRef	paramBP
ForceRef	callback
ForceRef	childType

if _FXIP
EC <		push	bx, si						>
EC <		movdw	bxsi, axbx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx, si						>
else
EC <		call	ECCheckSegment					>
endif
		call	FolderLockBufferDS
		clc
		jz	exit
		
		DerefFolderObject	es, si, di
		mov	ax, es:[di].FOI_fileCount
		mov	ss:[count], ax

		call	FolderGetFirstChild
		clc
		jz	unlock

sendToKidsLoop:

		lea	bx, ss:[callback]
		push	bp, ds, es, di
		mov	bp, ss:[paramBP]
NOFXIP<		call	{dword} ss:[bx]					>
FXIP<		mov	ax, ss:[bx]		; offset		>
FXIP<		mov	bx, ss:[bx+size word]	; vseg			>
FXIP<		call	ProcCallFixedOrMovable				>
		mov	bx, bp		; returned BP
		pop	bp, ds, es, di
		mov	ss:[paramBP], bx

		jc	unlock

		call	FolderGetNextChild
		jnz	sendToKidsLoop
		clc
unlock:
	;
	; Re-dereference the folder, in case the callback routine
	; caused the folder's block to move.
	;
		
		mov	si, ss:[folder].chunk
		mov	bx, ss:[folder].handle
		call	MemDerefDS
		call	FolderUnlockBuffer
exit:

		.leave
		ret
FolderSendToChildren	endp





COMMENT @-------------------------------------------------------------------
			FolderGetFirstChild
----------------------------------------------------------------------------

DESCRIPTION:	Locks folder buffer, and returns a pointer to the
		first child (FolderRecord) of the given type from the
		given folder. 

CALLED BY:	INTERNAL - FolderSendToChildren

PASS:		es:di - FolderClass instance data
		ds    - segment of locked FolderBuffer
		ss:bp - inherited local vars

RETURN:		IF VALID FIRST FolderRecord EXISTS:
			zero flag clear
			ds:di	= offset to first FolderRecord
		ELSE:
			zero flag set
			DS - destroyed

DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
		
FolderGetFirstChild	proc	near
		class	FolderClass

		.enter	inherit	FolderSendToChildren

		mov	bx, di			; instance data

		mov	di, ss:[childType]
EC <		cmp	di, FolderChildType			>
EC <		ERROR_A DESKTOP_FATAL_ERROR			>

		jmp	cs:[getFirstChildTable][di]

getFirstChildTable	nptr	\
	getFirstAll,
	getFirstDisplayList,
	getFirstSelected,
	getFirstPositioned,
	getFirstUnPositioned

.assert	(size getFirstChildTable eq FolderChildType)

getFirstAll:
		mov	di, offset FBH_buffer
		jmp	checkDI		; to clear the Z flag

getFirstDisplayList:
		mov	di, es:[bx].FOI_displayList
		jmp	checkDI

		
getFirstSelected:
		mov	di, es:[bx].FOI_selectList
		jmp	checkDI

		
getFirstPositioned:
		mov	di, es:[bx].FOI_displayList
		cmp	di, NIL
		je	done

		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED

	;
	; Toggle the ZERO flag
	;

		lahf
		xor	ah, mask CPU_ZERO
		sahf

		jnz	done

		call	FolderGetNextPositionedChild
		jmp	done


getFirstUnPositioned:
		mov	di, es:[bx].FOI_displayList
		cmp	di, NIL
		je	done

		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		jnz	done					; found first!

		call	FolderGetNextUnpositionedChild
		jmp	done

checkDI:
		cmp	di, NIL		; Z flag set if none available

done:
		.leave
		ret						; <--- exit!

FolderGetFirstChild	endp



COMMENT @-------------------------------------------------------------------
			FolderGetNextChild
----------------------------------------------------------------------------

DESCRIPTION:	Returns the offset to the first child (FolderRecord)
		of the given type from the given folder.

CALLED BY:	INTERNAL - FolderSendToChildren

PASS:		ds:di	= FolderRecord "instance data"

RETURN:		IF VALID NEXT CHILD EXISTS:
			zero flag clear
			ds:di	= next FolderRecord
		ELSE:
			zero flag set

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	** exits in two places, so watch out! **

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderGetNextChild	proc	near

		.enter	inherit	FolderSendToChildren

		mov	bx, ss:[childType]
EC <		cmp	bx, FolderChildType			>
EC <		ERROR_A DESKTOP_FATAL_ERROR			>
		jmp	cs:[getNextChildTable][bx]


getNextChildTable	nptr	\
	getNextAll,
	getNextDisplayList,
	getNextSelected,
	getNextPositioned,
	getNextUnPositioned

.assert	(size getNextChildTable eq FolderChildType)

getNextAll:
		add	di, size FolderRecord
		dec	ss:[count]			; count = 0, ZF = set
		jmp	done

getNextDisplayList:
		mov	di, ds:[di].FR_displayNext

checkPointer:
		cmp	di, NIL
done:
		.leave				; EXIT
		ret


getNextSelected:
		mov	di, ds:[di].FR_selectNext
		jmp	checkPointer

getNextPositioned:
		.leave
		GOTO	FolderGetNextPositionedChild

getNextUnPositioned:
		.leave
		GOTO	FolderGetNextUnpositionedChild


FolderGetNextChild	endp



COMMENT @-------------------------------------------------------------------
			FolderGetNextUnpositionedChild
----------------------------------------------------------------------------

DESCRIPTION:	Finds the next valid FolderRecord in the display list
		that doesn't have a position.

CALLED BY:	INTERNAL - FolderGetFirstChild,
			   FolderGetNextChild

PASS:		ds:di	= FolderRecord "instance data"

RETURN:		IF VALID NEXT CHILD EXISTS:
			zero flag clear
			ds:di	= next FolderRecord
		ELSE:
			zero flag set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderGetNextUnpositionedChild	proc	near
		.enter
checkNext:
		mov	di, ds:[di].FR_displayNext
		cmp	di, NIL
		je	done
		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		jz	checkNext		; if has position, get next
done:
		.leave
		ret
FolderGetNextUnpositionedChild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetNextPositionedChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the next child whose FRSF_UNPOSITIONED flag is CLEAR

CALLED BY:	FolderGetFirstChild, FolderGetNextChild

PASS:		ds:di - FolderRecord

RETURN:		if found:
			zero flag CLEAR
			ds:di - FolderRecord
		else
			zero flag SET

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetNextPositionedChild	proc	near
		.enter
checkNext:
		mov	di, ds:[di].FR_displayNext
		cmp	di, NIL
		je	done
		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		jnz	checkNext

	;
	; The child is positioned.  Clear the zero flag somehow.
	;
		dec	di
		inc	di			
done:
		.leave
		ret
FolderGetNextPositionedChild	endp



COMMENT @-------------------------------------------------------------------
			FolderLockBuffer
----------------------------------------------------------------------------

DESCRIPTION:	Locks the buffer of FolderRecords.

CALLED BY:	EXTERNAL - 
			FolderSendToChildren

PASS:		*ds:si - FolderClass object

RETURN:		IF BUFFER EXISTS:
			zero flag clear
			es	= folder buffer
		ELSE:
			zero flag set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/1/92		Initial version

---------------------------------------------------------------------------@
FolderLockBuffer	proc	far
	class	FolderClass

	uses	ax, bx
	.enter

	DerefFolderObject	ds, si, bx
	mov	bx, ds:[bx].FOI_buffer
	tst	bx
	jz	done

	pushf				; save Z flag
	call	MemLock
	mov	es, ax
EC <	ERROR_C	BLOCK_NOT_LOCKED		>
EC <	call	ECCheckFolderBufferHeader	>
	popf				; restore Z flag

done:
	.leave
	ret
FolderLockBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUnlockBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the folder's buffer

CALLED BY:	INTERNAL

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	nothing, flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderUnlockBuffer	proc far
		class	FolderClass
		uses	bx
		.enter
		pushf
		DerefFolderObject	ds, si, bx
		mov	bx, ds:[bx].FOI_buffer
		tst	bx
		jz	done
		call	MemUnlock
done:
		popf
		.leave
		ret
FolderUnlockBuffer	endp




COMMENT @-------------------------------------------------------------------
			FolderLockBufferDS
----------------------------------------------------------------------------

DESCRIPTION:	Locks the buffer of FolderRecords.

CALLED BY:	EXTERNAL - 

PASS:		*ds:si - FolderClass object

RETURN:		IF BUFFER EXISTS:
			zero flag clear
			ds	= folder buffer
			*es:si  - FolderClass object
		ELSE:
			zero flag set

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderLockBufferDS	proc	near
		class	FolderClass

		.enter

		call	FolderLockBuffer
		jz	done
		segxchg	ds, es
done:
		.leave
		ret
FolderLockBufferDS	endp


FolderUtilCode	ends
