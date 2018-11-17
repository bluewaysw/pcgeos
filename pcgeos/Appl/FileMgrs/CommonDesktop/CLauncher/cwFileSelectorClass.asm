COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Welcome
FILE:		wDOSStartupGroupClass.asm

AUTHOR:		brianc, Sept 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/25/91		Initial revision

DESCRIPTION:
	This file holds the definition for the WFileSelector class.

	$Id: cwFileSelectorClass.asm,v 1.1 97/04/04 15:02:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GEOLAUNCHER

WFileSelectorCode segment resource

FileMgrsClassStructures	segment	resource
	WFileSelectorClass
FileMgrsClassStructures	ends


filterRoutinePtr	fptr	WFileSelectorFilterRoutine
extraAttrsPtr		fptr	wfsCallbackAttrs

wfsCallbackAttrs	FileExtAttrDesc \
	<FEA_NAME, 0, size FileLongName>,
	<FEA_FILE_ATTR, 0, size FileAttrs>,
	<FEA_END_OF_LIST>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WFileSelectorGetFilterRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the GenFileSelector the address of our filter routine
		and extra attributes.

CALLED BY:	MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
PASS:		*ds:si	= object
RETURN:		ax:cx	= fptr to routine
		dx:bp	= fptr to extra attributes
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WFileSelectorGetFilterRoutine		method dynamic WFileSelectorClass,
				MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
		.enter
		mov	cx, cs:[filterRoutinePtr].segment
		mov	ax, cs:[filterRoutinePtr].offset
		mov	bp, cs:[extraAttrsPtr].segment
		mov	dx, cs:[extraAttrsPtr].offset
		.leave
		ret
WFileSelectorGetFilterRoutine		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WFileSelectorFilterRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine filters files for display in our file selectors.

CALLED BY:	GLOBAL
PASS:		*ds:si	= object
		es	= segment of FileEnumCallbackData
		bp	= inherited stack frame
RETURN:		carry clear to accept file
		carry set to reject file
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/25/91		Initial version
	ardeb	1/21/92		changed to be regular routine
	dlitwin	6/24/92		reworked, added: check .ini file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WFileSelectorFilterRoutine	proc far
	class	WFileSelectorClass
	uses	ds, si
	.enter

	segmov	ds, es
	clr	si

	; always accept subdirectories (won't ever see hidden or system)

FXIP <	mov	ss:[TPD_dataAX], FEA_FILE_ATTR				>
FXIP <	mov	bx, vseg FileEnumLocateAttr				>
FXIP <	mov	ax, offset FileEnumLocateAttr				>
FXIP <	call	ProcCallFixedOrMovable					>

NOFXIP<	mov	ax, FEA_FILE_ATTR					>
NOFXIP<	call	FileEnumLocateAttr					>

	mov	di, es:[di].FEAD_value.offset
	test	{FileAttrs} es:[di], mask FA_SUBDIR
	clc				; in case its a subdir
	jnz	done			; accept subdirs

	; locate the name and call the type-specific routine to match it

FXIP <	mov	ss:[TPD_dataAX], FEA_NAME				>
FXIP <	mov	bx, vseg FileEnumLocateAttr				>
FXIP <	mov	ax, offset FileEnumLocateAttr				>
FXIP <	call	ProcCallFixedOrMovable					>

NOFXIP<	mov	ax, FEA_NAME						>
NOFXIP<	call	FileEnumLocateAttr					>

	mov	di, es:[di].FEAD_value.offset

	; locate the extension, first
	mov	bp,di			; Save ptr to filename
	mov	cx, -1			; Get length of filename
	clr	ax
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	not	cx
	mov	di,bp			; Restore ptr to filename
SBCS <	mov	al, '.'							>
DBCS <	mov	ax, '.'							>
SBCS <	repne	scasb			; Get ptr to extension		>
DBCS <	repne	scasw			; Get ptr to extension		>
	stc				; in case of failure
	jne	done			; If no extension (can't find "."), exit

FXIP <	mov	bx, vseg CheckIfBatComExe				>
FXIP <	mov	ax, offset CheckIfBatComExe				>
FXIP <	call	ProcCallFixedOrMovable					>

NOFXIP<	call	CheckIfBatComExe					>
	jmp	done	
done:
	.leave
	ret
WFileSelectorFilterRoutine	endp
	
WFileSelectorCode ends

endif			; ifndef GEOLAUNCHER
