COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpLink.asm

AUTHOR:		Gene Anderson, Oct 28, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/28/92	Initial revision


DESCRIPTION:
	

	$Id: helpLink.asm,v 1.1 97/04/07 11:47:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlFollowLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow a link in a help file

CALLED BY:	MSG_HELP_CONTROL_FOLLOW_LINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		cx - token of link name
		dx - token of link file (-1 for same)

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlFollowLink		method dynamic HelpControlClass,
						MSG_HELP_CONTROL_FOLLOW_LINK

HELP_LOCALS

	.enter

	;
	; Get the handle of the child block and the features for later
	;
	call	HUGetChildBlockAndFeaturesLocals
	;
	; Convert the link tokens to names
	;
	call	HLGetNamesForLink
	;
	; Display the new text
	;
	call	HLDisplayText
	jc	openError			;branch if error
	;
	; Update various things for history
	;
	call	HHUpdateHistoryForLink
openError:

	.leave
	ret

HelpControlFollowLink		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGetLinkName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	return the name of a link, given its token

PASS:		*ds:si	- HelpControlClass object
		ds:di	- HelpControlClass instance data
		es	- dgroup
		cx:dx	- fptr to GetLinkNameParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/16/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlGetLinkName	method	dynamic	HelpControlClass, 
					MSG_HC_GET_LINK_NAME

HELP_LOCALS
		.enter

	;
	; Fetch the link and file tokens from caller's buffer
	;
		
		mov	es, cx
		mov	di, dx
		mov	cx, es:[di].GLNP_linkToken
		mov	dx, es:[di].GLNP_fileToken

	;
	; Convert the link tokens to names
	;
		call	HLGetNamesForLink
	;
	; Copy the names out into the caller's buffer
	;
		segmov	ds, ss
		lea	si, ss:[filename]
		push	di
		lea	di, es:[di].GLNP_fileName
		LocalCopyString
		pop	di
		
		lea	si, ss:[context]
		lea	di, es:[di].GLNP_linkName
		LocalCopyString


		.leave
		ret
HelpControlGetLinkName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLGetNamesForLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert link tokens to names

CALLED BY:	HelpControlFollowLink()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			childBlock - handle of child block
		cx - token of link name
		dx - token of link file (-1 for same)
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HLGetNamesForLink		proc	near
	uses	es, di
HELP_LOCALS
	.enter	inherit

	;
	; Get the last history entry (ie. the current file & context)
	; if the link file token is -1 (ie. the current file)
	;
	cmp	dx, -1				;same file?
	jne	notSameFile			;branch if different file
	push	cx
	call	HHGetHistoryCurrent		;cx <- current item # + 1
EC <	tst	cx				;>
EC <	ERROR_Z	HELP_NO_HISTORY			;>
	dec	cx				;cx <- get last item
	call	HHGetHistoryEntry
	pop	cx
notSameFile:
	;
	; Convert the tokens to names
	;
	push	ds, si
	segmov	es, ss
	call	HNLockNameArray			;*ds:si <- name array
	cmp	dx, -1				;same file?
	je	afterFile			;branch if same file
	mov	ax, dx				;ax <- token of link file
	lea	di, ss:filename			;es:di <- dest buffer
	call	HNGetName
afterFile:
	mov	ax, cx				;ax <- token of link name
	lea	di, ss:context			;es:di <- dest buffer
	call	HNGetName
	;
	; Finished with the name array
	;
	call	HNUnlockNameArray
	pop	ds, si

	.leave
	ret
HLGetNamesForLink		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadOrFreeCompressLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads/frees the compress library, depending upon whether or
		not it is necessary.

CALLED BY:	GLOBAL
PASS:		*ds:si - HelpControl
RETURN:		carry set if we couldn't load the compress library
DESTROYED:	ds - may have moved
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
NEC <LocalDefNLString compressLibName <"PKware Lib",0>>
EC <LocalDefNLString compressLibName <"EC PKware Lib",0>>
else
NEC <LocalDefNLString compressLibName <"PKware Compression Library",0>>
EC <LocalDefNLString compressLibName <"EC PKware Compression Library",0>>
endif

COMPRESS_LIB_HEAPSPACE_REQUIREMENT	equ	8		; 8k

LoadOrFreeCompressLib	proc	near
	uses	ax, bx, di, dx
	class	HelpControlClass
	.enter

	call	HFGetFile
EC <	tst	bx							>
EC <	ERROR_Z	-1							>
	;
	; Get the compress type for the currently displayed file, and 
	; ensure that the compress library is loaded/freed appropriately.
	;
	call	DBLockMap
	mov	di, es:[di]
	mov	al, es:[di].HFMB_compressType
	call	DBUnlock

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset

	cmp	al, HCT_NONE
	LONG je	freeLib
EC <	cmp	al, HCT_PKZIP						>
EC <	ERROR_NZ	BAD_HELP_COMPACT_TYPE				>

	tst_clc	ds:[di].HCI_compressLib
	jnz	exit
	;
	; Borrow space for the compress library.
	;
	mov	cx, COMPRESS_LIB_HEAPSPACE_REQUIREMENT
	call	GeodeGetProcessHandle
	cmp	bx, handle 0		; global ui thread?
	mov	dx, 0			; in case global ui thread
	je	noSpace			; is run by ui thread, no space req.
	call	GeodeRequestSpace
	jc	exit		

	mov	dx, bx
	mov	cx, size hptr
	mov	ax, TEMP_HELP_HEAPSPACE_TOKEN
	call	ObjVarAddData

	mov	{word}ds:[bx], dx
noSpace:
	;
	; Load up the compress library
	;
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	push	ds, si
	segmov	ds, cs
	mov	si, offset compressLibName
	mov	ax, COMPRESS_PROTO_MAJOR
	mov	bx, COMPRESS_PROTO_MINOR
	call	GeodeUseLibrary
	pop	ds, si
	call	FilePopDir
	;
	; If request failed, return borrowed space.
	;
	jc	returnSpace
	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	mov	ds:[di].HCI_compressLib, bx
	jmp	exit
returnSpace:
	tst	dx
	jz	spaceReturned
	mov	bx, dx			; handle still in dx
	call	GeodeReturnSpace
	mov	ax, TEMP_HELP_HEAPSPACE_TOKEN
	call	ObjVarDeleteData
spaceReturned:
	stc
exit:
	.leave
	ret
freeLib:
	;
	; Free up the library if one was loaded
	;
	clr	bx
	xchg	bx, ds:[di].HCI_compressLib
	tst_clc	bx
	jz	exit
	call	GeodeFreeLibrary
	;
	; Return space, if any.
	;
	mov	ax, TEMP_HELP_HEAPSPACE_TOKEN
	call	ObjVarFindData		; carry set if found
	jnc	exit		

	mov	bx, {word}ds:[bx]
	call	GeodeReturnSpace
	call	ObjVarDeleteData
	clc
	jmp	exit
	
LoadOrFreeCompressLib	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HLDisplayText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the text for the context -- show the text at the
		current link

CALLED BY:	HelpControlFollowLink()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			childBlock - handle of child block
			features - features that are on
			context - name of context
			filename - name of help file
RETURN:		carry - set if error occurred
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HLDisplayText		proc	near
	uses	dx, si
	class	HelpControlClass
HELP_LOCALS
	.enter	inherit
	;
	; Is this the same file we've already got open?
	;
	call	HHSameFile?			;same file?
	je	afterOpen			;branch if same file

	;
	; Open the help file
	;

	call	HFOpenFile			;bx <- handle of help file
	jc	errorOpen			;branch if error opening file


	;
	; Save the help file handle for later
	;
	call	HFSetFileCloseOld
	;
	; Connect various text object attributes, including the
	; ever-important name array
	;
	call	HTConnectTextAttributes		;ax <- VM handle of name array
	call	HNSetNameArray
	;
	; Get the text and stuff it in the text object
	;
afterOpen:
	call	LoadOrFreeCompressLib		;Load/free the compress lib,
	jc	errorNoCompress			; depending upon whether or
						; not it is needed. Exit if
						; we couldn't load it.	
	call	HTGetTextForContext
	jc	errorNoContext			;branch if error
done:

	.leave
	ret

errorNoCompress:
	;
	; We couldn't load the compress/decompress library
	;
	mov	di, offset noCompressLibrary
	jmp	restoreFromFileAndExit
errorOpen:
	;
	; We couldn't find the file -- report an error to keep AndrewC happy
	; To keep him really happy, the message will include his phone # :-)
	;
	call	HUReportError
	stc					;carry <- error
	jmp	done

	;
	; The file was found, but the context wasn't -- report an error
	;
errorNoContext:
	mov	di, offset contextNotFound	;di <- chunk of error message
restoreFromFileAndExit:
	call	HUReportError
	;
	; If this was a different file we tried to open, close it
	;
	call	HHSameFile?
	je	sameFile			;branch if same file
	;
	; Get the last history entry
	;
	call	HHGetHistoryCurrent		;cx <- current item # + 1
	jcxz	sameFile			;branch if no history
	dec	cx				;cx <- last entry
	call	HHGetHistoryEntry
	;
	; Open the last file we had open before
	;
	call	HFOpenFile
EC <	ERROR_C	HELP_RECORDED_HELP_MISSING	;>
	;
	; Save the file handle and close the failed file
	;
	call	HFSetFileCloseOld
	;
	; Connect various text object attributes, including the
	; ever-important name array
	;
	call	HTConnectTextAttributes		;ax <- VM handle of name array
	call	HNSetNameArray
	;
	; Get the text and stuff it in the text object
	;
	call	LoadOrFreeCompressLib		;Load/free the compress lib
	jc	sameFile
	call	HTGetTextForContext
EC <	ERROR_C	HELP_RECORDED_HELP_MISSING	;>
sameFile:
	stc					;carry <- error 
	jmp	done
HLDisplayText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the box is brought off-screen, we free the compress
		library, on the assumption that the user won't be changing
		contexts for awhile.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlVisClose	method	dynamic HelpControlClass,
			MSG_VIS_CLOSE
	uses	ax
	.enter		
	clr	bx
	xchg	bx, ds:[di].HCI_compressLib
	tst	bx
	jz	exit
	call	GeodeFreeLibrary
exit:
	;
	; Return space if we borrowed any.
	;
	mov	ax, TEMP_HELP_HEAPSPACE_TOKEN
	call	ObjVarFindData		; carry set if found
	jnc	callSuper

	mov	bx, {word}ds:[bx]
	call	GeodeReturnSpace
	call	ObjVarDeleteData

callSuper:


	.leave

	mov	di, offset HelpControlClass
	GOTO	ObjCallSuperNoLock
HelpControlVisClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlBringUpTOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up table of contents for current application

CALLED BY:	MSG_HC_BRING_UP_TOC
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlBringUpTOC		method dynamic HelpControlClass,
						MSG_HC_BRING_UP_TOC
HELP_LOCALS
	.enter

	;
	; Get the handle of the child block and the features for later
	;
	call	HUGetChildBlockAndFeaturesLocals
	;
	; Make sure we're not already at the TOC
	;
	call	HHGetHistoryCount		;cx <- # entries
	jcxz	noSavedHistory
	dec	cx				;cx <- last entry
	call	HHGetHistoryEntry
	mov	di, offset TableOfContents
	call	HHAtTOC?			;at TOC already?
	je	quit				;branch if at TOC
noSavedHistory:
	;
	; Get the help file name
	;
	mov	ax, TEMP_HELP_TOC_FILENAME
	call	ObjVarFindData
	jnc	quit				;quit if no TOC filename
	push	si
	mov	si, bx				;ds:si <- ptr to source
	lea	di, ss:filename
	segmov	es, ss				;es:di <- ptr to dest
	VarDataSizePtr	ds, si, cx		;cx <- size of string
	rep	movsb				;copy me jesus
	pop	si
	;
	; Get the context name for the Table of Contents
	;
	mov	di, offset TableOfContents	;di <- chunk of name to get
	call	HNGetStandardName
	;
	; Display the text
	;
	call	HLDisplayText
	jc	openError			;branch if error
	;
	; Update various things for history
	;
	call	HHUpdateHistoryForLink
openError:
quit:

	.leave
	ret
HelpControlBringUpTOC		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlJumpToVersionInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the version information for the current help file

CALLED BY:	MSG_HC_JUMP_TO_VERSION_INFO
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlJumpToVersionInfo	method dynamic HelpControlClass,
				MSG_HC_JUMP_TO_VERSION_INFO
HELP_LOCALS
	.enter

	; Get the handle of the child block and the features for later
	;
	call	HUGetChildBlockAndFeaturesLocals

	; Get the current help file name
	;
	call	HHGetHistoryCurrent		;cx <- current element #
	jcxz	done				;if none, we're done
	dec	cx
	call	HHGetHistoryEntry		;writes local variables

	; Get the context name for the Version Information
	;
	mov	di, offset VersionInformation	;di <- chunk of name to get
	call	HNGetStandardName

	; Display the text
	;
	call	HLDisplayText
	jc	done				;branch if error

	; Update various things for history
	;
	call	HHUpdateHistoryForLink
done:
	.leave
	ret
HelpControlJumpToVersionInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlDisplayContextInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the version information for the current help file

CALLED BY:	MSG_HC_DISPLAY_CONTEXT_INFO
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlDisplayContextInfo	method dynamic HelpControlClass,
				MSG_HC_DISPLAY_CONTEXT_INFO
HELP_LOCALS
	.enter

	; Get the handle of the child block and the features for later
	;
	call	HUGetChildBlockAndFeaturesLocals

	; Get the current help file name
	;
	call	HHGetHistoryCurrent		;cx <- current element #
	jcxz	done				;if none, we're done
	dec	cx
	call	HHGetHistoryEntry		;writes local variables

	; Display the dialog box with the valuable information
	;
	mov	di, offset helpFileContextInfo
	call	HUReportError
done:
	.leave
	ret
HelpControlDisplayContextInfo	endm

HelpControlCode ends
