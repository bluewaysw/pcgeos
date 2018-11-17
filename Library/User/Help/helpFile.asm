COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpFile.asm

AUTHOR:		Gene Anderson, Oct 23, 1992

ROUTINES:
	Name			Description
	----			-----------
	HFOpenFile		Open the help file.
	HFSetPath		Sets the correct path to search for
				the help file.
	VerifyHelpFile		Verify that the VM file we just opened
				is a help file.
	HFSetFileCloseOld	Set the new file and close the old
				one, if any.
	HFGetFile		Get the handle of the current file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/23/92	Initial revision
	PJC	10/21/94	Added multi-language patch support.

DESCRIPTION:
	Routines for dealing with help files in the help controller

	$Id: helpFile.asm,v 1.1 97/04/07 11:47:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Internal/patch.def
include initfile.def
include heap.def

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the help file

CALLED BY:	
PASS:		*ds:si - help controller
		ss:bp - inherited locals
			filename - name of help file to open
RETURN:		bx - handle of help file
		carry - set if error
		    di - chunk of an appropriate error message
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HFOpenFile		proc	near
	uses	dx, ds, es
HELP_LOCALS
	.enter	inherit

	;
	; Save the current directory
	;
	call	FilePushDir
	;
	; See if there is a custom directory
	;
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	jnc	useHelpDir			;branch if attr does not exist
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jnc	gotDirectory			;branch if no error
	;
	; Change to the help file directory
	;
useHelpDir:
	call	HFSetPath

gotDirectory:
	;
	; Try to open the file
	;
	push	bp
	lea	dx, ss:filename
	segmov	ds, ss				;ds:dx <- ptr to filename
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_FORCE_READ_ONLY or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx				;cx <- system compression
	call	VMOpen
	pop	bp
ifdef PRODUCT_WIN_DEMO
	mov	di, offset helpFileNotAvailable	;di <- chunk of error message
else
	mov	di, offset helpFileNotFound	;di <- chunk of error message
endif
	jc	error

	call	VerifyHelpFile
	mov	di, offset helpFileNotHelp	;di <- chunk of error message
	jc	errorCloseFile

	;
	; Get the map block and check the protocol
	;
	call	DBLockMap
	tst	di
	jz	errorCloseFile
		
	mov	di, es:[di]
	mov	cx, es:[di].HFMB_protocolMajor
	mov	dx, es:[di].HFMB_protocolMinor
	call	DBUnlock
	mov	di, offset helpFileBadProto	;di <- chunk of error message
	cmp	cx, HELP_FILE_PROTO_MAJOR
	jne	errorCloseFile
	cmp	dx, HELP_FILE_PROTO_MINOR
	jb	errorCloseFile
	clc
error:
	;
	; Return to the original directory
	;
	call	FilePopDir			;preserves flags
	.leave
	ret

errorCloseFile:
	clr	al
	call	VMClose
	stc					;carry <- error
	jmp	error
HFOpenFile		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the correct path to search for the help file.

CALLED BY:	HFOpenFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	The current path will be changed.

PSEUDO CODE/STRATEGY:
	"The correct path" is SP_HELP_FILES if not in multi-language 
	mode.  It is the sub-directory in SP_HELP_FILES corresponding 
	to the selected systemLanguage if we are in multi-language mode.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	canavese 10/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if MULTI_LANGUAGE
LocalDefNLString systemCategory <"system", 0>
LocalDefNLString systemLanguageKey <"systemLanguage",0>
endif ; MULTI_LANGUAGE

HFSetPath	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

if MULTI_LANGUAGE

	; Check if multi-language mode is on.

		call	IsMultiLanguageModeOn
		jc	changeToHelpSP		; Not in multi-language mode.

	; Copy language subdirectory into buffer.

		mov	cx, cs
		mov	ds, cx
		mov	si, offset systemCategory
		mov	dx, offset systemLanguageKey
		clr	bp
		call	InitFileReadString
			; bx = handle of language sub-directory.
		jc	changeToHelpSP		; Error: no system language.	

	; Change to language sub-directory.

		push	ds, bx
		call	MemLock			; Subdirectory block.
		mov	ds, ax			; Locked segment.
		clr	dx
		mov	bx, SP_HELP_FILES
		call	FileSetCurrentPath
		pop	ds, bx

	; Free the sub-directory buffer.

		call	MemFree
		jmp	done	

changeToHelpSP:

endif 	; (MULTI_LANGUAGE)

	; Just change to the standard help path.

		mov	ax, SP_HELP_FILES
		call	FileSetStandardPath

done::
		.leave
		ret	

HFSetPath	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the VM file we just opened is a help file

CALLED BY:	HFOpenFile()
PASS:		bx - handle of help file
RETURN:		carry - set if not a hep file
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
helpFileToken GeodeToken <
	"hlpf",
	MANUFACTURER_ID_GEOWORKS>

VerifyHelpFile		proc	near
	uses	ax, cx, si, di, ds, es
	.enter

	;
	; Get the token for the file
	;
	mov	cx, (size GeodeToken)		;cx <- size of buffer
	sub	sp, cx
	segmov	es, ss
	mov	di, sp				;es:di <- ptr to buffer
	mov	ax, FEA_TOKEN			;ax <- FileExtendedAttribute
	call	FileGetHandleExtAttributes
EC <	ERROR_C HELP_FILE_IS_NOT_A_HELP_FILE	;no such attribute >
	jc	done				;branch if no such attribute
	;
	; Make sure it is one of ours
	;
	segmov	ds, cs
	mov	si, offset helpFileToken	;ds:si <- ptr to our token
	repe	cmpsb				;compare me jesus
EC <	ERROR_NE HELP_FILE_IS_NOT_A_HELP_FILE	;>
	clc					;carry <- assume OK
	je	done				;branch if token matches
	stc					;carry <- not help
done:
	mov	di, sp
	lea	sp, ss:[di][(size GeodeToken)]	;preserve carry

	.leave
	ret
VerifyHelpFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFSetFileCloseOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the new file and close the old one, if any

CALLED BY:	HelpControlExit(), HelpUpdateUI()
PASS:		*ds:si - controller
		bx - handle of new file (0 for none)
RETURN:		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: also destroys and text object storage before closing the file
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HFSetFileCloseOld		proc	near
	uses	bx, di
	class	HelpControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	xchg	bx, ds:[di].HCI_curFile		;bx <- old file
	tst_clc	bx				;any old file?
	jz	noClose				;branch if no old file
	;
	; Destroy any old storage
	;
	call	HTDestroyTextStorage
	;
	; Close the file
	;
	mov	al, FILE_NO_ERRORS
	call	VMClose
noClose:
	.leave
	ret
HFSetFileCloseOld		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFGetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of the current file.

CALLED BY:	UTILITY
PASS:		*ds:si - controller
RETURN:		bx - handle of file
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HFGetFile		proc	near
	uses	di
	class	HelpControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	mov	bx, ds:[di].HCI_curFile		;bx <- current file

	.leave
	ret
HFGetFile		endp

HelpControlCode ends
