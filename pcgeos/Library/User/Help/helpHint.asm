COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpHint.asm

AUTHOR:		Gene Anderson, Oct 28, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/28/92	Initial revision


DESCRIPTION:
	Routines and methods for dealing with help controller hints

	$Id: helpHint.asm,v 1.1 97/04/07 11:47:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHAddHintsForMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add hints to help controller based on the mode

CALLED BY:	HelpControlResolveVariantSuperclass()
PASS:		*ds:si - controller
		ds:di - controller
RETURN:		*ds:si - controller (ds fixed up)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: only hints that are on the controller itself or modify
	NOTE: the features should be added here; the features do not
	NOTE: yet exist at this point.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


featuresForMode	HPCFeatures \
	mask HPCF_TEXT or \
		mask HPCF_CLOSE or \
		mask HPCF_CONTENTS or \
		mask HPCF_GO_BACK or \
		mask HPCF_HISTORY,		;HT_NORMAL_HELP
	mask HPCF_TEXT or \
		mask HPCF_CLOSE or \
		mask HPCF_FIRST_AID or \
		mask HPCF_FIRST_AID_GO_BACK or \
		mask HPCF_INSTRUCTIONS,		;HT_FIRST_AID
	mask HPCF_TEXT,				;HT_STATUS_HELP
	mask HPCF_TEXT or \
		mask HPCF_CLOSE,		;HT_SIMPLE_HELP
	mask HPCF_TEXT or \
		mask HPCF_CLOSE or \
		mask HPCF_CONTENTS or \
		mask HPCF_GO_BACK or \
		mask HPCF_HISTORY,		;HT_SYSTEM_HELP
	mask HPCF_TEXT or \
		mask HPCF_CLOSE 		;HT_SYSTEM_MODAL_HELP

CheckHack <(length featuresForMode) eq HelpType>


HHAddHintsForMode		proc	far
	uses	ax, bx, cx, dx, bp, di
	class	HelpControlClass
	.enter

	mov	dl, ds:[di].HCI_helpType
	mov	dh, ds:[di].GII_visibility

	;
	; If we're a dialog, add some hints
	;
	cmp	dh, GIV_DIALOG
	jne	noDialogHints

	;
	; Add a hint to position the window
	;
	mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
	mov	cx, (size SpecWinSizePair)	;cx <- size of extra data
	call	ObjVarAddData
	mov	ax, mask SWSS_RATIO or HT_MON_HELP_POS_X
	mov	cx, mask SWSS_RATIO or HT_MON_HELP_POS_Y
storePosition::
	mov	ds:[bx].SWSP_x, ax
	mov	ds:[bx].SWSP_y, cx
	;
	; Add a hint to make the window resizable unless told otherwise
	;
	mov	ax, HINT_HELP_NOT_RESIZABLE
	call	ObjVarFindData
	jc	noDialogHints			;branch if no resizing wanted
	mov	ax, HINT_INTERACTION_MAKE_RESIZABLE
	clr	cx				;cx <- no extra data
	call	ObjVarAddData
noDialogHints:
	;
	; Add a hint to size the window appropriately, unless there is
	; a HINT_HELP_TEXT_FIXED_SIZE already set.  If there is, the
	; size of the window will be based on the text size.
	;
	cmp	dl, HT_STATUS_HELP		;status help?
	je	noSizeHint			;branch if status help
	cmp	dh, GIV_DIALOG
	jne	noSizeHint
	mov	ax, HINT_HELP_TEXT_FIXED_SIZE
	call	ObjVarFindData
	jc	noSizeHint			;branch if text size exists
	mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD
	call	ObjVarFindData
	jc	noSizeHint			;branch if already exists
	mov	cx, (size SpecWinSizePair)	;cx <- size of extra data
	call	ObjVarAddData
	mov	ax, mask SWSS_RATIO or HT_MON_HELP_WIDTH
	mov	cx, mask SWSS_RATIO or HT_MON_HELP_HEIGHT
storeSize::
	mov	ds:[bx].SWSP_x, ax
	mov	ds:[bx].SWSP_y, cx
noSizeHint:

	;
	; Add features based on the mode
	;
	mov	ax, ATTR_GEN_CONTROL_REQUIRE_UI
	call	ObjVarFindData
	jc	afterAddFeature			;branch if features already set
	mov	cx, (size HPCFeatures)		;cx <- size of extra data
	call	ObjVarAddData
	clr	{word}ds:[bx]			;no features initially
afterAddFeature:
	clr	dh
	shl	dx
	mov	di, dx
	mov	ax, cs:featuresForMode[di]	;HPCFeatures
	ornf	ds:[bx], ax
EC <	test	ds:[bx], mask HPCF_TEXT		;>
EC <	ERROR_Z	HELP_CONTROL_MUST_HAVE_TEXT	;>

	.leave
	ret
HHAddHintsForMode		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHSetTextHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets:
			minimum size so the text doesn't get too small
			scrollable text

CALLED BY:	HelpControlGenerateUI()
PASS:		*ds:si - controller
RETURN:		none
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

helpColorCat	char	"motif options", 0	;put it with the other colors
helpColorKey	char	"helpbgcolor", 0

HHSetTextHints		proc	near
	uses	bp, si
	class	HelpControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	call	HHGetChildBlockAndFeatures
	mov	si, offset HelpTextDisplay	;^lbx:si <- OD of text object
	;
	; Don't set text hints for status help or focus help
	; (other than setting the background white)
	;
	cmp	ds:[di].HCI_helpType, HT_STATUS_HELP
	je	done
	;
	; Set a minimum size so text doesn't get too small on a small screen
	;
	sub	sp, (size SetSizeArgs)
	mov	bp, sp				;ss:bp <- args
	mov	ss:[bp].SSA_width, \
		(SST_PIXELS shl offset SW_TYPE) or HT_MIN_TEXT_WIDTH
	mov	ss:[bp].SSA_height, \
		(SST_PIXELS shl offset SW_TYPE) or HT_MIN_TEXT_HEIGHT
	clr	ss:[bp].SSA_count		;no children
	mov	ss:[bp].SSA_updateMode, VUM_NOW	;VisUpdateMode
	mov	ax, MSG_GEN_SET_MINIMUM_SIZE
	call	callObjMessage
	add	sp, (size SetSizeArgs)
	;
	; check if any background color is specified
	;
	push	ds, si
	segmov	ds, cs, cx
	mov	si, offset helpColorCat		;ds:si <- category
	mov	dx, offset helpColorKey		;cx:dx <- key
	call	InitFileReadInteger
	pop	ds, si
	jc	afterColor
	;
	; set the color
	; NOTE: use MF_FORCE_QUEUE so the spui text object doesn't set
	; the wash color back to gray after we set it.
	;
	mov_tr	cl, al				;cl <- color
	mov	ch, CF_INDEX
	mov	ax, MSG_VIS_TEXT_SET_WASH_COLOR
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
afterColor:

	;
	; Set the text scrollable
	;
	mov	ax, MSG_GEN_TEXT_SET_ATTRS
	mov	cx, mask GTA_INIT_SCROLLING	;cl <- set; ch <- clear
	call	callObjMessage
done:

	.leave
	ret

callObjMessage:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	retn
HHSetTextHints		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHScanForHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan hints for the help controller

CALLED BY:	HelpControlGenerateUI()
PASS:		*ds:si - instance data
		ds:di - *ds:si
RETURN:		ds - fixed up
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHScanForHints		proc	far
	uses	bp
	class	HelpControlClass

	.enter

	call	HHGetChildBlockAndFeatures
	mov	cx, bx				;cx <- child block
	;
	; NOTE: do not use ObjVarScanData() here -- it does not
	; allow the callback routines to add or remove vardata
	;
	mov	ax, HINT_HELP_TEXT_FIXED_SIZE
	call	ObjVarFindData
	jnc	noFixedSize			;branch if no hint
	call	HCHTextFixedSize
noFixedSize:
	mov	ax, ATTR_HELP_INITIAL_HELP
	call	ObjVarFindData
	jnc	noInitialHelp			;branch if no hint
	call	HCHInitialHelp
noInitialHelp:

	.leave
	ret
HHScanForHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HCHTextFixedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set HINT_FIXED_SIZE on the help object's text object

CALLED BY:	HelpControlScanHints()
PASS:		*ds:si - controller
		cx - handle of child block
		ds:bx - ptr to extra data for hint
RETURN:		none
DESTROYED:	ax, bx, dx, bp, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HCHTextFixedSize		proc	near
	uses	cx, si
	.enter

	sub	sp, (size SetSizeArgs)
	mov	bp, sp				;ss:bp <- ptr to args
	clr	ss:[bp].SSA_count		;no children
	mov	ss:[bp].SSA_updateMode, VUM_NOW	;VisUpdateMode

	push	cx				;save child block
	mov	cx, (size SpecWidth)+(size SpecHeight)
	mov	si, bx				;ds:si <- source
	segmov	es, ss
	lea	di, ss:[bp].SSA_width		;es:di <- dest
	rep	movsb				;copy me jesus
	pop	bx				;bx <- child block

	mov	si, offset HelpTextDisplay	;^lbx:si <- OD of text object
	mov	ax, MSG_GEN_SET_FIXED_SIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	add	sp, (size SetSizeArgs)

	.leave
	ret
HCHTextFixedSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HCHInitialHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get ATTR_HELP_INITIAL_HELP for a help object

CALLED BY:	HelpControlScanHints()
PASS:		*ds:si - controller
		ds:bx - ptr to extra data for hint
RETURN:		ds - fixed up
DESTROYED:	ax, bx, dx, bp, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HCHInitialHelp		proc	near
	uses	cx, si
	class	HelpControlClass
	.enter

	push	ds:LMBH_handle
	sub	sp, (size FileLongName)
	;
	; See if the initial help file is specified.
	;
	push	bx
	mov	ax, ATTR_HELP_INITIAL_HELP_FILE
	call	ObjVarFindData
	mov	di, bx				;ds:di <- help file, if any
	pop	bx
	jnc	doHelpFile			;branch if not specified
	;
	; The initial help file is specified -- use it instead of doing
	; the normal query to get the help file.
	;
	push	bx				;save ptr to context
	call	AllocHelpNotification
	;
	; Get and specify the help type
	;
	call	getHelpType			;al <- HelpType
	mov	es:NHCC_type, al
	;
	; Copy the filename for both the help file and TOC file
	;
	mov	si, di				;ds:si <- ptr to filename
	mov	di, offset NHCC_filename	;es:di <- ptr to dest #1
DBCS <	clr	ah							>
fileCopyLoop:
	lodsb					;al <- character of string
SBCS <	mov	es:[NHCC_filenameTOC-NHCC_filename][di], al		>
DBCS <	mov	es:[NHCC_filenameTOC-NHCC_filename][di], ax		>
	LocalPutChar esdi, ax
	LocalIsNull	ax			;reached NULL?
	jnz	fileCopyLoop			;loop until NULL
	;
	; Get and copy the context
	;
	pop	si				;ds:si <- ptr to context
	mov	di, offset NHCC_context		;es:di <- ptr to dest
DBCS <	clr	ah							>
contextCopyLoop:
	lodsb
	LocalPutChar esdi, ax
	LocalIsNull ax				;reached NULL?
	jnz	contextCopyLoop			;loop until NULL
	;
	; Unlock the notification and send it off
	;
	call	UnlockSendHelpNotification
	jmp	done

	;
	; Get the name of the help file from the application
	; object.  If we get it from ourselves, it will get
	; the name of the library we are defined in (ui).
	;
doHelpFile:
	movdw	cxdx, sssp			;cx:dx <- ptr to buffer
	mov	ax, MSG_META_GET_HELP_FILE
	call	UserCallApplication
EC <	ERROR_NC HELP_NO_FILENAME_FOUND		;>
NEC <	jnc	done				;>
	;
	; Get the type of the help
	;
	call	getHelpType			;al <- HelpType
	;
	; Get a pointer to the vardata with the context name
	;
	mov	si, bx				;ds:si <- ptr to context
	;
	; Send the notification
	;
	movdw	esdi, cxdx			;es:di <- ptr to file name
	call	HelpSendHelpNotification
done:
	add	sp, (size FileLongName)
	;
	; Fixup DS in case it moved
	;
	pop	bx
	call	MemDerefDS			;ds <- fixed up

	.leave
	ret

	;
	; Get the type of the help
	;
getHelpType:
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	mov	al, ds:[di].HCI_helpType	;al <- HelpType
	pop	di
	retn
HCHInitialHelp		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for a controller
CALLED BY:	UTILITY

PASS:		*ds:si - controller
RETURN:		ax - features
		bx - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HHGetChildBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
HHGetChildBlockAndFeatures	endp

HelpControlInitCode ends
