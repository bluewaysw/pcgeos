COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Card Library
FILE:		cardMain.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	9/90		Initial Version

DESCRIPTION:


RCS STAMP:
$Id: cardsMain.asm,v 1.1 97/04/04 17:44:29 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Library		= 1


;Standard include files


include	geos.def
include geode.def
include ec.def

include myMacros.def

include	library.def
include geode.def


;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the cards lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif


if FULL_EXECUTE_IN_PLACE
include	Internal/xip.def
endif

include resource.def

include object.def
include	graphics.def
include gstring.def
include	Objects/winC.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include hugearr.def
include Objects/inputC.def
include myMacros.def
include deckMap.def
include chunkarr.def
include initfile.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def
DefLib	cards.def

CardBackDynamicListClass	class	GenDynamicListClass
CardBackDynamicListClass	endc

include cards.rdef

CardsCodeResource	segment	resource
include game.asm
include card.asm
include deck.asm
include hand.asm
include uiCardBackSelector.asm

udata	segment

	vmFileHandle	hptr

udata	ends

if FULL_EXECUTE_IN_PLACE and ERROR_CHECK

NOT_DGROUP					enum	FatalErrors

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CardsEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry procedure for the cards library. Since we don't need
		to do anything special for our clients, we just clear the
		carry to indicate our happiness.

CALLED BY:	Kernel
PASS:		di	= LibraryCallType
				LCT_ATTACH	= library just loaded
				LCT_NEW_CLIENT	= client of the library just
						  loaded
				LCT_CLIENT_EXIT	= client of the library is
						  going away
				LCT_DETACH	= library is about to be
						  unloaded
		cx	= handle of client geode, if LCT_NEW_CLIENT or
			  LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
;
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	global	CardsEntry:far	; so Esp won't whine
CardsEntry	proc	far

FXIP  <	mov_tr	ax, bx				; save value of bx	>
FXIP  <	mov	bx, handle dgroup					>
FXIP  <	call	MemDerefDS			; ds = dgroup		>
FXIP  <	mov_tr	bx, ax				; restore bx		>
NOFXIP<	segmov	ds, dgroup, ax						>
	cmp	di, LCT_ATTACH			; attaching???
	je	attach
	cmp	di, LCT_DETACH			; detaching???
	je	detach
;default:
	clc
	jmp	endCardsEntry
attach:
	;
	;	The library is trying to attach, so we call CardsAttach
	;
	call	CardsAttach
	jmp	endCardsEntry
detach:
	;
	;	The library is trying to detach, so we call CardsDetach
	;
	call	CardsDetach
endCardsEntry:
	ret
CardsEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardsAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by entry routine on attaching. Opens up the card
		deck vm file and checks its protocol

CALLED BY:	

PASS:		ds	= dgroup
		
CHANGES:	

RETURN:		carry clear if everything went ok
		carry set on error

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardsAttach	proc	near
	;
	;	Open the VM file containing the card bitmaps
	;
	call	FilePushDir

	call	CardsFindVMFile
	jc	fileError

	call	CardsCheckProtocol
	jc	protocolError

						;Give the ownership of this
	mov	ax, handle 0			;file to the library. This
	call	HandleModifyOwner		;makes sure that the file will
						;stay open until we close it.
if FULL_EXECUTE_IN_PLACE and ERROR_CHECK
	;
	; make sure ds is dgroup
	;
	push	ax, bx, ds
	mov	ax, ds				; ax = dgroup (supposed)
	mov	bx, handle dgroup
	call	MemDerefDS			; ds = dgroup
	mov	bx, ds				; bx = dgroup
	cmp	ax, bx
	ERROR_NE	NOT_DGROUP
	pop	ax, bx, ds
endif
	mov	ds:vmFileHandle, bx

	clc
	jmp	endCardsAttach

fileError:
	mov	bx, handle vmErrorText
	mov	si, offset vmErrorText
	jmp	bitchAtUser

protocolError:
	mov	al, FILE_NO_ERRORS
	call	VMClose
	mov	bx, handle badProtocolText
	mov	si, offset badProtocolText

bitchAtUser:

if 0	; Don't do this anymore, this causes threadlock when UI's 
	; launching and only has two threads! -dhunter 2/11/2000

SBCS< 	sub	sp, DOS_STD_PATH_LENGTH					>
DBCS<	sub	sp, DOS_STD_PATH_LENGTH*(size wchar)			>
	mov	di, sp
	segmov	es, ss
	call	CardsGetDeckDir

	sub	sp, FILE_LONGNAME_BUFFER_SIZE
	mov_tr	cx, di					;es:cx <- path
	mov	di, sp
	call	CardsGetDeckName			;es:di <- filename

	sub	sp, (size StandardDialogParams)
	mov	bp, sp				;ss:di <- params
	mov	ss:[bp].SDP_customFlags,  mask CDBF_SYSTEM_MODAL or \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)

	call	MemLock
	mov	ds, ax
	mov	ax, ds:[si]			;ds:si <- error string
	movdw	ss:[bp].SDP_customString, dsax
	movdw	ss:[bp].SDP_stringArg1, escx
	movdw	ss:[bp].SDP_stringArg2, esdi
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog

	;
	;  UserStandardDialog pops the StandardDialogParams off
	;  the stack. Why? I don't know.
	;
SBCS<	add	sp, DOS_STD_PATH_LENGTH + FILE_LONGNAME_BUFFER_SIZE		>
DBCS<	add	sp, DOS_STD_PATH_LENGTH*(size wchar) + FILE_LONGNAME_BUFFER_SIZE >

	call	MemUnlock
endif

	stc					;return failure
endCardsAttach:
	call	FilePopDir
	ret
CardsAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CardsFindVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		nothing

Return:		carry set on error
		else bx = VM file

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardsFindVMFile	proc	near
	uses	ax, cx, dx, bp, di, si, es, ds
	.enter

SBCS< 	mov	bp, DOS_STD_PATH_LENGTH						>
DBCS<	mov	bp, DOS_STD_PATH_LENGTH*(size wchar)	; attr from .ini file	>
	sub	sp, bp
	mov	di, sp
	segmov	es, ss

	call	CardsGetDeckDir

	segmov	ds, es
	mov	dx, di
	mov	bx, SP_PUBLIC_DATA
	call	FileSetCurrentPath
SBCS<	add	sp, DOS_STD_PATH_LENGTH						>
DBCS<	add	sp, DOS_STD_PATH_LENGTH*(size wchar) 				>

	mov	bp, FILE_LONGNAME_BUFFER_SIZE
	sub	sp, bp
	mov	di, sp

	call	CardsGetDeckName

	segmov	ds, es
	mov	dx, di
	mov	ax, (VMO_OPEN shl 8) or mask VMAF_FORCE_READ_ONLY or mask VMAF_FORCE_DENY_WRITE
	clr	cx		; Use standard compaction threshhold
	call	VMOpen		; Go ahead, open it!
	lahf
	add	sp, FILE_LONGNAME_BUFFER_SIZE
	sahf

	.leave
	ret
CardsFindVMFile	endp

cardsCategoryString		char	"cards",0
cardsDeckDirKey			char	"deckdir",0
cardsDeckNameKey		char	"deckfile",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CardsGetDeckDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Get the sub directory of SP_PUBLIC_DATA that presumably
		contains the card bitmap file.

Pass:		es:di - empty buffer
		bp	- InitFileReadFlags

Return:		es:di - null terminated string 

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardsGetDeckDir	proc	near
	uses	ax, bx, cx, dx, di, si, ds
	.enter

	mov	cx, cs
	segmov	ds, cx
	mov	si, offset cardsCategoryString
	mov	dx, offset cardsDeckDirKey
	call	InitFileReadString
	jc	useDefaultDir

done:
	.leave
	ret

useDefaultDir:
	;
	;  We want to fill the buffer at es:di with the default directory
	;
	mov	bx, handle cardsDefaultDeckDir
	call	MemLock
	mov	ds, ax
	mov	si, offset cardsDefaultDeckDir
	mov	si, ds:[si]
;copyDirLoop:
	LocalCopyString

	call	MemUnlock
	jmp	done
CardsGetDeckDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CardsGetDeckName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Get the longname of the cards bitmap file
		containing the card bitmap file.

Pass:		es:di - empty buffer
		bp	- InitFileReadFlags

Return:		es:di - null terminated string 

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardsGetDeckName	proc	near
	uses	ax, bx, cx, dx, di, si, ds
	.enter

	mov	cx, cs
	mov	ds, cx
	mov	si, offset cardsCategoryString
	mov	dx, offset cardsDeckNameKey
	call	InitFileReadString
	jc	useDefaultName

done:
	.leave
	ret

useDefaultName:
	;
	;  We want to fill the buffer at es:di with the default name
	;
	mov	bx, handle cardsDefaultDeckName
	call	MemLock
	mov	ds, ax
	mov	si, offset cardsDefaultDeckName
	mov	si, ds:[si]
;copyNameLoop:
	LocalCopyString

	call	MemUnlock
	jmp	done
CardsGetDeckName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CardsDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when the cards library detaches from he system. Closes
		the card bitmap VM file.

CALLED BY:	

PASS:		ds	= dgroup
		
CHANGES:	

RETURN:		ax, bx

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10/90		initial version
	clee	6/30/94		add XIP EC code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardsDetach	proc	near

if FULL_EXECUTE_IN_PLACE and ERROR_CHECK
	;
	; make sure ds is dgroup
	;
	push	ax, bx, ds
	mov	ax, ds				; ax = dgroup (supposed)
	mov	bx, handle dgroup
	call	MemDerefDS			; ds = dgroup
	mov	bx, ds				; bx = dgroup
	cmp	ax, bx
	ERROR_NE	NOT_DGROUP
	pop	ax, bx, ds
endif
	mov	bx, ds:vmFileHandle
	mov	al, FILE_NO_ERRORS
	call	VMClose
	ret
CardsDetach	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CardsCheckProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the deck vm file and the cards library have
		the same protocol numbers

CALLED BY:	CardsAttach

PASS:		bx	= VM file handle

RETURN:		carry set if protocol mismatch

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CardsCheckProtocol	proc	near
	uses ax, ds, dx
	.enter

	;
	;  Let's get the protocol of this thing and compare it to the
	;  values from our last compile
	;

	mov	cx, size ProtocolNumber
	sub	sp, cx
	mov	di, sp
	segmov	es, ss
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes
	jc	clearStack

	; Check major protocol number (the library and the vm file must
	; have the same major protocol number to work properly).

	cmp	es:[di].PN_major, DECK_PROTO_MAJOR
	jne	noDice

	;
	; Check minor protocol number (the vm file's minor protocol must be
	; less than or equal to the deck's minor protocol number).
	;

	cmp	es:[di].PN_minor, DECK_PROTO_MINOR
	ja	noDice

	clc	;OK!

clearStack:
	lahf
	add	sp, size ProtocolNumber
	sahf

	.leave
	ret

noDice:
	stc
	jmp	clearStack
CardsCheckProtocol	endp

CardsCodeResource ends

