COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		letterpref.asm

AUTHOR:		Adam de Boor, Dec  3, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 3/92	Initial revision


DESCRIPTION:
	Saver-specific preferences for Letter driver.
		

	$Id: letterpref.asm,v 1.1 97/04/04 16:45:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; include the standard suspects
include geos.def
include geode.def
include lmem.def
include object.def
include graphics.def
include gstring.def
include initfile.def

include stdapp.def
UseLib	ui.def

UseLib	Objects/vTextC.def
UseLib	Objects/Text/tCtrlC.def

UseLib config.def		; Most objects we use come from here
UseLib saver.def		; Might need some of the constants from
				;  here, though we can't use objects from here.

;
; Include constants from Letter, the saver, for use in our objects.
;
include ../letter.def

;
; Include the class definitions used in this pref module.
;
include letterpref.def

idata	segment

;
; Define the preferences interaction subclass we use to attach the
; font controller to the active list, etc.
;
LetterPrefInteractionClass

idata	ends

;
; Now the object tree.
; 
include	letterpref.rdef

LetterPrefCode 	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterPrefGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none

RETURN:		dx:ax - OD of root of UI tree

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LetterPrefGetPrefUITree	proc	far
	.enter

	mov	dx, handle RootObject
	mov	ax, offset RootObject
	
	.leave
	ret
LetterPrefGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LPIPrefInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hook up the font controller to the active list, etc.

CALLED BY:      MSG_PREF_INIT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of LetterPrefInteractionClass
		ax - the method

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jdashe  4/18/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LPIPrefInit	method dynamic LetterPrefInteractionClass, MSG_PREF_INIT
	uses	ax, cx, dx, bp
	.enter

	push	si				; save chunk of object

	mov	ax, MSG_META_GCN_LIST_ADD
	mov	bx, GAGCNLT_SELF_LOAD_OPTIONS
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset LetterFonts
	call	LPIManipulateGCNList
	
	mov	bx, MGCNLT_ACTIVE_LIST
	call	LPIManipulateGCNList
	
	; Attach the controller.
	mov	ax, MSG_META_ATTACH
	mov	di, mask MF_CALL
	mov	si, offset LetterFonts 		; ds:si <- LetterFonts
	clr	cx, dx, bp			; No flags.
	call	ObjCallInstanceNoLock

	; Tell the font controller which font we'll be using.
	call	LPIUpdateFontController		; ax <- fontID to use

	pop	si				; recover chunk
	mov	di, ds:[si]
	add	di, ds:[di].LetterPrefInteraction_offset ; ds:di <- instance

	mov	ds:[di].LPI_fontID, ax

	; Recover original info for this message and call the superclass.
	.leave

	mov	di, offset LetterPrefInteractionClass
	call	ObjCallSuperNoLock
	ret
LPIPrefInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LPISaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept this to set the .ini font for the letter
		screen saver.  We've kept the font saved away in
		instance data.

CALLED BY:      MSG_META_SAVE_OPTIONS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of LetterPrefInteractionClass
		ax - the method

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jdashe  4/21/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LPISaveOptions	method dynamic LetterPrefInteractionClass, MSG_META_SAVE_OPTIONS
	uses	es, si, ds, bp
	.enter

	mov	bp, ds:[di].LPI_fontID	; bp - value to write
	mov	cx, cs			; ds:si - category,
	mov	ds, cx			; cx:dx - key
	mov	si, offset lpiIniCategory
	mov	dx, offset lpiIniFontIDKey

	call	InitFileWriteInteger

	; Recover original info for this message and call the superclass.
	.leave
	
	mov	di, offset LetterPrefInteractionClass
	call	ObjCallSuperNoLock
	ret
LPISaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LPIUpdateFontController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan through the .ini file for our current font, then
		send it off to the font controller.

CALLED BY:	LPIPrefInit

PASS:		ds - something to fixup

RETURN:		ax - fontID

DESTROYED:	ax, bx, cx, dx, es, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

lpiIniCategory		char	'letter', 0
lpiIniFontIDKey		char	'letterfont', 0

LPIUpdateFontController	proc	near
	uses	es, si, bp
	.enter

	; Save ds for the call below.
	push	ds

	;
	; Get the current font from the .ini file.
	;
	mov	cx, cs			; ds:si - category,
	mov	ds, cx			; cx:dx - key
	mov	si, offset lpiIniCategory
	mov	dx, offset lpiIniFontIDKey
	mov	ax, FID_DTC_URW_ROMAN	; ax <- default font if none found.
	call	InitFileReadInteger
	pop	ds			; recover block for 

	;
	; Tell the font controller which font we're currently using.
	;
	mov	dx, ax			; save font ID
	push	ax			; save it for returning

	mov	ax, size NotifyFontChange
	mov	cx, ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8) or \
		    (mask HF_SWAPABLE or mask HF_SHARABLE)
	call	MemAlloc			
	mov	es, ax			; es:si <- NotifyFontChange block
	clr	si
	mov	es:[si].NFC_fontID, dx
	clr	es:[si].NFC_diffs	

	call	MemUnlock
	
	mov	ax, 1			; set the init reference count
	call	MemInitRefCount		; to 1.

	mov	di, mask MF_RECORD
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
        mov     cx, MANUFACTURER_ID_GEOWORKS
        mov     dx, GWNT_FONT_CHANGE   	; cx:dx - notification type
        mov     bp, bx
        mov     di, mask MF_RECORD
        call    ObjMessage              ; event handle => DI
	
        ; Setup the GCNListMessageParams

        mov     dx, size GCNListMessageParams
        sub     sp, dx
        mov     bp, sp                  ; GCNListMessageParams => SS:BP
        mov     ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
        mov     ss:[bp].GCNLMP_ID.GCNLT_type, \
                        GAGCNLT_APP_TARGET_NOTIFY_FONT_CHANGE
        mov     ss:[bp].GCNLMP_block, bx        ; bx - handle of data block
        mov     ss:[bp].GCNLMP_event, di        ; di - even handle
        mov     ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
        mov     ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
        call    GeodeGetProcessHandle
        mov     di, mask MF_STACK or mask MF_FIXUP_DS
        call    ObjMessage		; send it!!
        add     sp, dx                  ; clean up the stack

	pop	ax			; recover fontID
	.leave
	ret
LPIUpdateFontController	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LPISetTextFontID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the font controller's spouting of which font
		we're using now.

CALLED BY:      MSG_META_SET_FONT_ID

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of LetterPrefInteractionClass
		ax - the method

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jdashe  4/20/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LPISetTextFontID	method dynamic LetterPrefInteractionClass,
			MSG_VIS_TEXT_SET_FONT_ID
	.enter

	; Save the new font
	mov	ax, ss:[bp].VTSFIDP_fontID
	mov	ds:[di].LPI_fontID, ax

	mov	ax, MSG_GEN_MAKE_APPLYABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	cx, dx, bp			; No flags.
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	mov	di, offset LetterPrefInteractionClass
	call	ObjCallSuperNoLock

	.leave
	ret
LPISetTextFontID	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LPIMetaBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach our controller from the active and self-load
		lists. 

CALLED BY:      MSG_META_BLOCK_FREE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of LetterPrefInteractionClass
		ax - the method

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jdashe  4/19/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LPIMetaBlockFree	method dynamic LetterPrefInteractionClass,
			MSG_META_BLOCK_FREE
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	bx, GAGCNLT_SELF_LOAD_OPTIONS
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset LetterFonts
	call	LPIManipulateGCNList
	
	mov	bx, MGCNLT_ACTIVE_LIST
	call	LPIManipulateGCNList
	
	; Recover original info for this message and call the superclass.

	.leave

	mov	di, offset LetterPrefInteractionClass
	call	ObjCallSuperNoLock
	ret
LPIMetaBlockFree	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LPIManipulateGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use this routine to add/remove controllers from GCN lists.

CALLED BY:	(INTERNAL)

PASS:		ax - MSG_META_GCN_LIST[ADD, REMOVE]
		bx - load option
		cx:dx - OD of controller

RETURN:		ds - fixed up (whatever it was...)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LPIManipulateGCNList	proc	near
	uses	ax, bx, cx, dx, si
	.enter

	; Create the gcn list structure and send it off.
	sub	sp, size GCNListParams
	mov	bp, sp				; ss:bp <- GCNListParams
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, bx
	movdw	ss:[bp].GCNLP_optr, cxdx
	mov	dx, size GCNListParams

	clr	bx
	call	GeodeGetAppObject		; bx:si <- app object
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams

	.leave
	ret
LPIManipulateGCNList	endp

LetterPrefCode		ends
