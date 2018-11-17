COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cwordFileSel.asm

AUTHOR:		Steve Scholl, Sep 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	9/27/94		Initial revision


DESCRIPTION:
	
		

	$Id: cwordFileSel.asm,v 1.1 97/04/04 15:14:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordFileCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSFilteredGetFilterRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return far ptr to filter routine

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFilteredFileSelectorClass

RETURN:		

	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSFilteredGetFilterRoutine method dynamic CwordFilteredFileSelectorClass, 
					MSG_GEN_FILE_SELECTOR_GET_FILTER_ROUTINE
	.enter

	lea	dx, extAttrDesc
	mov	bp,cs

	cmp	ds:[di].CFFSI_mode,CFFST_IN_PROGRESS
	jne	other

	mov	cx,vseg FSInProgressPuzzleFilter
	mov	ax, offset FSInProgressPuzzleFilter

done:
	.leave
	ret

other:
	cmp	ds:[di].CFFSI_mode,CFFST_NEVER_STARTED
	jne	completed
	mov	cx,vseg FSNeverStartedPuzzleFilter
	mov	ax, offset FSNeverStartedPuzzleFilter
	jmp	done

completed:
	mov	cx,vseg FSCompletedPuzzleFilter
	mov	ax, offset FSCompletedPuzzleFilter
	jmp	done


FSFilteredGetFilterRoutine		endm

extAttrDesc FileExtAttrDesc \
	<FEA_NAME, 0, length FileLongName,0>,
	<FEA_FILE_ATTR, 0, length FileAttrs,0>,
	<FEA_END_OF_LIST, 0,0,0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSInProgressPuzzleFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry clear if file is in the solutions document
		or is a directory

CALLED BY:	FileSelector

PASS:		
		es - segment of FileEnumCallbackData
		*ds:si - FileSelectorObject
		bp - inherite stack frame for FileEnum helper routines

RETURN:		
		carry clear if file is in solutions document
		carry set if file is NOT in solutions document


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSInProgressPuzzleFilter		proc	far
	class	CwordFilteredFileSelectorClass
	uses	ax,bx,cx,ds,si,es,di
	.enter

	Assert 	objectPtr dssi, CwordFilteredFileSelectorClass

	call	FSAcceptDirectories
	jnc	done

	call	FSGetUserDocHandle

	;    If there is no user doc then so no
	;

	jcxz	skipIt

	call	FSGetNamePtr
	mov	bx,cx				;vm file handle
	call	FSIsPuzzleInUserDoc
	jc	skipIt

	mov	di,ds:[si]
	add	di,ds:[di].CwordFilteredFileSelector_offset
	inc	ds:[di].CFFSI_numIns
	clc
done:
	.leave
	ret

skipIt:
	stc
	jmp	done

FSInProgressPuzzleFilter		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSNeverStartedPuzzleFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry clear if file is NOT in the solutions document
		and NOT in completed document or is directory

CALLED BY:	FileSelector

PASS:		
		es - segment of FileEnumCallbackData
		*ds:si - FileSelectorObject
		bp - inherite stack frame for FileEnum helper routines

RETURN:		
		carry set if file is in solutions document
		carry clear if file is NOT in solutions document


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSNeverStartedPuzzleFilter		proc	far
	class	CwordFilteredFileSelectorClass
	uses	ax,bx,cx,ds,si,es,di
	.enter

	Assert 	objectPtr dssi, CwordFilteredFileSelectorClass

	call	FSAcceptDirectories
	jnc	done

	call	FSGetUserDocHandle

	;    If there is no user doc then so yes
	;

	jcxz	keepIt

	;   If in solutions document then reject
	;

	call	FSGetNamePtr
	mov	bx,cx				;vm file handle
	call	FSIsPuzzleInUserDoc		;carry clear if in
	jnc	rejectIt			;reject if in

	;    If not in solutions document completed then accept
	;

	call	FSIsPuzzleInUserDocCompleted
	jc	keepIt

rejectIt:
	stc
done:
	.leave
	ret

keepIt:
	clc
	jmp	done

FSNeverStartedPuzzleFilter		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSCompletedPuzzleFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry clear if file is in the completed array in
		solutions document or is a directory

CALLED BY:	FileSelector

PASS:		
		es - segment of FileEnumCallbackData
		*ds:si - FileSelectorObject
		bp - inherite stack frame for FileEnum helper routines

RETURN:		
		carry clear if file is in completed array of solutions document

		carry set if file is NOT in completed array of solutions 
			document


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSCompletedPuzzleFilter		proc	far
	class	CwordFilteredFileSelectorClass
	uses	ax,bx,cx,ds,si,es,di
	.enter

	Assert 	objectPtr dssi, CwordFilteredFileSelectorClass

	call	FSAcceptDirectories
	jnc	done

	call	FSGetUserDocHandle

	;    If there is no user doc then so no
	;

	jcxz	skipIt

	call	FSGetNamePtr
	mov	bx,cx				;vm file handle
	call	FSIsPuzzleInUserDocCompleted
	jc	skipIt

done:
	.leave
	ret

skipIt:
	stc
	jmp	done

FSCompletedPuzzleFilter		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSAcceptDirectories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if enumerated file is a directory

CALLED BY:	FSInProgressPuzzleFilter, FSNeverStartedPuzzleFilter

PASS:		
		es - segment of FileEnumCallbackData
		bp - inherite stack frame for FileEnum helper routines

RETURN:		
		carry clear - if its a directory
		carry set - if not a directory

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSAcceptDirectories		proc	near
	uses	ax,bx,ds,si,es,di
	.enter

	mov	ax,FEA_FILE_ATTR
	segmov	ds,es
	clr	si
	call	FileEnumLocateAttr
EC <	ERROR_C CWORD_FILE_SELECTOR_CANT_FIND_ATTR 	
	add	di,offset FEAD_value
	les	di,es:[di]
	mov	al,es:[di]
	test	al,mask FA_SUBDIR

	jnz	directory
	stc
done:
	.leave
	ret

directory:
	clc
	jmp	done

FSAcceptDirectories		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSGetNamePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pointer to name for call back attrs

CALLED BY:	UTILITY

PASS:		
		bp - stack frame for FileEnum helper routines
		es - segment of FileEnumCallbackData
		
RETURN:		
		es:di - ptr to null terminated file name

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSGetNamePtr		proc	near
	uses	ax,bx,ds,si
	.enter

	mov	ax,FEA_NAME
	segmov	ds,es
	clr	si
	call	FileEnumLocateAttr
EC <	ERROR_C CWORD_FILE_SELECTOR_CANT_FIND_NAME	
	add	di,offset FEAD_value

	les	di,es:[di]

	.leave
	ret
FSGetNamePtr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSGetUserDocHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get handle of user doc from interaction

CALLED BY:	UTITLITY

PASS:		
		*ds:si - FileSelector

RETURN:		
		cx - user doc handle or 0

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSGetUserDocHandle		proc	near
	uses	bx,si,di,ax
	.enter

	mov	bx,handle SelectorInteraction
	mov	si,offset SelectorInteraction
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	mov	ax,MSG_CFSLI_GET_USER_DOC_HANDLE
	call	ObjMessage

	.leave
	ret
FSGetUserDocHandle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSIsPuzzleInUserDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if puzzle name is in user doc

CALLED BY:	FSIsPuzzleInUserDoc

PASS:		
		bx - VM File handle of User Doc
		es:di - null terminated file name 

RETURN:		
		clc - puzzle in userdoc
		stc - puzzle not in userdoc

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSIsPuzzleInUserDoc		proc	near
	uses	ax,cx,dx
	.enter

	Assert  nullTerminatedAscii esdi

	mov	dx,di				;offset of string
	call	FileFindPuzzleInMapBlockLow

	cmp	cx,TRUE	
	jne	notInUserDoc
	clc
done:
	.leave
	ret

notInUserDoc:
	stc
	jmp	done

FSIsPuzzleInUserDoc		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSIsPuzzleInUserDocCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if puzzle name is in user doc completed array

CALLED BY:	UTILITY

PASS:		
		bx - VM File handle of User Doc
		es:di - null terminated file name 

RETURN:		
		clc - puzzle in userdoc completed
		stc - puzzle not in userdoc completed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSIsPuzzleInUserDocCompleted		proc	near
	uses	ax,cx,dx
	.enter

	Assert  nullTerminatedAscii esdi

	mov	dx,di				;offset of string
	call	FileFindCompletedPuzzleInMapBlockLow

	cmp	cx,TRUE	
	jne	notInUserDoc
	clc

done:
	.leave
	ret

notInUserDoc:
	stc
	jmp	done

FSIsPuzzleInUserDocCompleted		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFFSSetMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set mode and rescan if necessary

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFilteredFileSelectorClass
	
		cl - new mode CFFSType

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFFSSetMode	method dynamic CwordFilteredFileSelectorClass, 
						MSG_CFFS_SET_MODE
	uses	cx,dx
	.enter

	Assert	etype cl, CFFSType

	cmp	cl,ds:[di].CFFSI_mode
	je	done
	mov	ds:[di].CFFSI_mode,cl

	clr	ch					;high word if indentif
	clr	dx					;not indeterminate
	mov	ax,MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	FSMessageToChoiceList

	;   If there isn't a user document then it probably means the 
	;   file selector isn't up yet. So don't force a rescan now because
	;   it will potentially clear the canAutoSwitchMode because there
	;   will be no IN_PROGRESS puzzles because the user doc isn't open
	;   

	call	FSGetUserDocHandle
	jcxz	done

	mov	ax,MSG_GEN_FILE_SELECTOR_RESCAN
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
CFFSSetMode		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFFSGetMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFilteredFileSelectorClass

RETURN:		
		cl - CFFSType
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFFSGetMode	method dynamic CwordFilteredFileSelectorClass, 
						MSG_CFFS_GET_MODE
	.enter

	mov	cl,ds:[di].CFFSI_mode

	.leave
	ret
CFFSGetMode		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFFSSetDefaultMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFilteredFileSelectorClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFFSSetDefaultMode	method dynamic CwordFilteredFileSelectorClass, 
						MSG_CFFS_SET_DEFAULT_MODE
	.enter

	;   If the mode is IN_PROGRESS then set autoswitch to true
	;

	cmp	ds:[di].CFFSI_mode, CFFST_IN_PROGRESS
	jne	done
	mov	ds:[di].CFFSI_canAutoSwitchMode,TRUE
done:
	.leave
	ret
CFFSSetDefaultMode		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clr count then call superclass to do rescan. Potentially
		rescan depennding on values of counts after rescan.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFilteredFileSelectorClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSRescan	method dynamic CwordFilteredFileSelectorClass, 
						MSG_GEN_FILE_SELECTOR_RESCAN
	.enter

	clr	ds:[di].CFFSI_numIns

	mov	di, offset CwordFilteredFileSelectorClass
	call	ObjCallSuperNoLock

	mov	di,ds:[si]
	add	di,ds:[di].CwordFilteredFileSelector_offset

	cmp	ds:[di].CFFSI_mode, CFFST_IN_PROGRESS
	je	inProgress

cancelAutoSwitch:
	mov	ds:[di].CFFSI_canAutoSwitchMode,FALSE

	.leave
	ret

inProgress:
	tst	ds:[di].CFFSI_numIns
	jnz	cancelAutoSwitch

	tst	ds:[di].CFFSI_canAutoSwitchMode
	jz	cancelAutoSwitch

	;    Switch modes to never started. This way when the user
	;    first launches the program and there are no puzzles
	;    in progress it will switch to showing the puzzles
	;    they can play.
	;

	mov	cl,CFFST_NEVER_STARTED
	mov	ax,MSG_CFFS_SET_MODE
	call	ObjCallInstanceNoLock
	jmp	cancelAutoSwitch

FSRescan		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSMessageToChoiceList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send  message to the ChoiceList

CALLED BY:	UTILTIY

PASS:		ax - message
		ds - object block segment

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSMessageToChoiceList		proc	near
	uses	bx,si,dx,di
	.enter

	mov	bx, handle SelectorChoiceList
	mov	si, offset SelectorChoiceList
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
FSMessageToChoiceList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFSLIGetUserDocHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileSelectorInteractionClass

RETURN:		
		cx - file handle
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFSLIGetUserDocHandle	method dynamic CwordFileSelectorInteractionClass, 
						MSG_CFSLI_GET_USER_DOC_HANDLE
	.enter

	mov	cx,ds:[di].CFSII_userDocFileHandle

	.leave
	ret
CFSLIGetUserDocHandle		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFSLIVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open user doc and save handle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileSelectorInteractionClass
		bp - 0 or window handle

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFSLIVisOpen	method dynamic CwordFileSelectorInteractionClass, 
						MSG_VIS_OPEN
	.enter

	call	FileOpenUserDocument
	jnc	10$				;jmp if no error
	clr	bx
10$:
	mov	ds:[di].CFSII_userDocFileHandle,bx

	mov	di, offset CwordFileSelectorInteractionClass
	call	ObjCallSuperNoLock

	.leave
	Destroy	ax,cx,dx,bp
	ret
CFSLIVisOpen		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CFSLIVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close user doc

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordFileSelectorInteractionClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFSLIVisClose	method dynamic CwordFileSelectorInteractionClass, 
						MSG_VIS_CLOSE
	.enter

	clr	bx
	xchg	ds:[di].CFSII_userDocFileHandle,bx
	tst	bx
	jz	10$
	push	ax				;message
	clr	al
	call	VMClose
	pop	ax				;message

10$:
	mov	di, offset CwordFileSelectorInteractionClass
	call	ObjCallSuperNoLock

	.leave
	Destroy	ax,cx,dx,bp
	ret
CFSLIVisClose		endm







CwordFileCode	ends
