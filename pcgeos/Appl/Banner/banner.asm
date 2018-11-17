COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		banner
FILE:		banner.asm

ROUTINES:
Name				Description
----				-----------
BannerSetLongerSuffix		-- sets length of longer suffix (?)
BannerLoadSavedState		-- loads variables stored in state file
BannerSetUIFromSavedState	-- sets up UI from saved state variables
BannerGetTextString		-- locks a copy of the BannerTextEdit string
BannerSetFontDetails		-- common routine to set font attrs in gstate

METHOD HANDLERS:

Name				Description
----				-----------
BannerOpenApplication		-- initializes GeoBanner; builds fonts menu
BannerCloseApplication		-- state-saving stuff
BannerVisClose			-- removes timers & other junk on closing
BannerSetSavedSpecialEffects	-- set special effects
BannerGetSpecialEffects		-- get special effects
BannerGetState			-- get state info
BannerGetFont			-- get the font ID

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		Initial version
	stevey	10/92		port to 2.0
	witt	10/93		DBCS compliance

DESCRIPTION:
	This file contains the code for the banner application.  The goal
	of the application is to provide an easy way to make banners in
	the GCM enviroment.  The main features are to enter text and print
	it.  Additions are selecting fonts and special effects.

	$Id: banner.asm,v 1.1 97/04/04 14:37:31 newdeal Exp $

	-----------------------------------------------------------------

GOALS:
	The goal of this project was to have a program that could be left
	alone in a store or a public place and where a person could just
	walk up, type a message in, and print it, all without help.  
	(Well, OK, they might need help with the walking part.  -steve)

	When banner starts up, the user is presented with a place to type
	and a preview of the banner.  All changes to the text object will
	be reflected in the preview (after giving them time to type).

	The hope is that banner will enable people to quickly create
	banners which are exactly what they expect without getting lost.

TECHNICAL INFO:

	TOP AREA
	The banner screen has two main areas.  The top is the text edit.

	PREVIEW AREA/UPDATING
	The bottom contains the preview area.  This shows the user what they
	can expect the banner to look like when printed.  It is drawn scaled
	by the same code which makes the printout so that the two images are
	the same.  The preview must always be up to date, so whenever the
	text edit object becomes dirty or the either the fonts or special
	effects are changed then the preview gets a redraw command.  Redrawing
	does not occur for every change though;  otherwise typing would require
	a redraw for every letter!  Instead, when a change is noted we force a
	redraw onto the end of the queue.  When we get to the queued redraw, we
	redraw only if the banner is dirty, and we then mark the banner clean.
	The result is that when making four changes, four dirty events come in.
	Each dirty event places a redraw event onto the end of the queue.  
	After the four change events, the first dirty event redraws the 
	banner and clears the dirty bit.  The three remaining redraws 
	notice that the dirty bit is clean and so they do nothing.

	TEXT SCALING
	The text in the banner is always maximized to just fit within the
	borders.  To do this we set the point size to the desired height.
	First we find the max height of the text; then we calculate a ratio
	between the two and adjust the point size once more so that the
	largest character just fits within the borders.  The banner length
	is then calculated from the length of text string at the final point 
	size.  If a person were to type just an ellipsis, it would fill up
	the entire page on-screen.  However, printing an ellipsis in double
	height mode would take a region larger than possible and so this 
	condition can't be allowed.  Therefore, whenever the font size
	scales to above four times the graphics system limit, the size is
	cut.  Four times is a valid number as long as banner prints only in
	lo res mode.

	BANNER OBJECT
	The banner is an object which is the output to the GenView and it
	is subclassed off of VisContent.  The banner scales itself to any
	height (the tractor holes are not scaled; they are regions for speed).

	QUARTER INCH CALCULATION
	What is a quarter inch?  A quarter inch is 1/34 of a 8.5" page, so 
	when we scale, a quarter inch is simply 1/34 of the banner's height.

	BORDERS
	There are three types of borders.  Borders shrink the area that can
	be filled in with text, so text is maximized for the space within
	the borders and appears smaller.  There is always at least a quarter 
	inch left as a border because printers cannot print too close to the 
	margins.

	When one of the three border options is used, more than a
	quarter inch is left as a margin.  All borders leave a half inch
	between them and the text area.  The thin border uses a quarter inch
	itself plus another quarter inch outside the border and a half inch
	inside the border for a total of one inch.  Remember that there is a
	border both on the top and bottom.  The thick and the double line
	borders are the same size.  The thick border is 3/4" thick plus the
	quarter inch outside the border and the half inch between it and the
	text for a total of 1 1/2".  The double line is the same.  It is a
	wide border with a white rectangle 1/4" wide drawn through the center.

	CACHING
	Properly displaying a banner involves a lot of calculations.  To 
	speed it up the last set of values are remembered.  When a 
	MSG_VIS_RECALC_SIZE is received it checks if the requested size
	is the same as the last maximized height.  If so, the calculations
	are skipped and the existing values are reused.  When adding text,
	changing the font, or selecting a special effect, 
	BI_lastMaximizedHeight	should be cleared so that the information 
	reflects the change.  Adding text causes the display to resize 
	based on whether there are descenders, accent marks, and even 
	letters bigger than a lowercase 'a'.

	There are also cases (I think they still exist) were information is
	not calculated if there isn't any text.

	SPECIAL EFFECT SCALING
	Special effects require the text to be drawn multiple times in the
	same area.  Therefore, the text size must be smaller for all the
	text to fit the same area.  The scaling is done by fractions.  A
	fraction of the scaled text is due to the special effect.  This 
	fraction is then subtracted from the point size when scaling.
	This is different than when the text is being drawn though.  When
	the text is being drawn, the offsets are calculated.  These offsets
	must be taken from the size of the tallest character and NOT the
	point size.  The point size can be twice as large as the tallest 
	character and so the offset would be twice as large as it should be.
	So, there are two places for special effect calculations.  One is
	in BannerMaximizeTextHeight which calculates the point size, and the
	other is in the special effect routines called by BannerDraw which
	calculate the offsets used.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
include stdapp.def
include timer.def
include char.def
include localize.def
include font.def
include assert.def
		
UseLib Objects/vTextC.def
UseLib	spool.def
		
UseLib Objects/Text/tCtrlC.def
UseLib Objects/Text/tCommon.def
		
include bannerConstants.def
include		banner.rdef
		
;-----------------------------------------------------------------------------
;	Variables
;-----------------------------------------------------------------------------
		
idata	segment
		
	StartStateData	label	byte
		
	savedStateSpecialEffects	SpecialEffects
	savedStateBannerState		BannerState
	savedStateFontID		FontID
		
	EndStateData	label	byte
		
	BannerProcessClass	mask CLASSF_NEVER_SAVED
	BannerClass
	BannerTextClass
	BannerGenViewClass
	BannerPrimaryClass
;
; when a banner is printed in double height mode, it is printed with two
; documents, one for the top, and one for the bottom.  During open
; application, the longer of the two suffixes (top or bottom) is
; recorded here and then this is read by BannerGetDocName when a double
; height banner is printed.
;
	longestPrintedDocNameSuffix	byte	0
		
idata	ends
		
;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------
		
CommonCode segment resource
		
include bannerUI.asm
include bannerDraw.asm
include bannerPrint.asm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize GeoBanner, build a fonts menu

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		cx = AppAttachFlags
		dx = handle of AppLaunchBlock (0 for none)
		bp = handle of extra state block (0 for none)

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- Call the superclass
	- initialize all the menus

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	6/19/90		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerOpenApplication	method 	BannerProcessClass, 
				MSG_GEN_PROCESS_OPEN_APPLICATION
		
		call	BannerSetLongerSuffix
		call	BannerLoadSavedState
		
		push	bp		; save whether we restored from state
	;
	; Call our superclass to get the ball rolling...
	; The superclass must be called after the font list is created. tony
	;
		mov	di, offset BannerProcessClass
		call	ObjCallSuperNoLock
		
		pop	bp
		push	bp			; state-block handle
		call	BannerSetFontController
		call	BannerSetStyleController
	;
	; Restore the handle of the state file.  If it's 0 then
	; there was no file, and we don't have to set the ui.
	;
		pop	ax			; restore state block handle
		tst	ax
		jz	done
		
		call	BannerSetUIFromSavedState
done:
		ret
		
BannerOpenApplication	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetFontController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the font controller ui from saved state (if any)

CALLED BY:	BannerOpenApplication

PASS:		bp = handle to saved-state block (0 for none)
		ds = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This is almost exactly the same as BannerSetStyleController.
	Look there.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetFontController	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  If we had a state block, get the font ID out of it.  Otherwise
	;  use BANNER_DEFAULT_FONT_ID
	;
		tst	bp			; was there a state block?
		jz	noStateBlock
		
		mov	dx, ds:[savedStateFontID]
		jmp	short doIt
noStateBlock:
		mov	dx, BANNER_DEFAULT_FONT_ID
doIt:
	;
	;  make the data block
	;
		mov	ax, size NotifyFontChange
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc		; returns handle in bx
		LONG	jc	done		; no memory left
		mov	ds, ax
	;
	;  initialize the NotifyFontChange structure, unlock
	;  the block and initialize the RefCount to 1 (it was zero
	;  when we alloc'd the block)
	;
		mov	ds:[NFC_fontID], dx	; new font
		clr	ds:[NFC_diffs]		; not applicable
		
		call	MemUnlock
		
		mov	ax, 1
		call	MemInitRefCount		; initialize reference count
		mov	bp, bx			; bp <- handle to block
	;
	;  Record a MSG_META_NOTIFY_WITH_DATA_BLOCK.  In bx, pass the
	;  handle of the data block (which will later be replaced by
	;  the handle of the object on the GCN list which we are calling).
	;
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_FONT_CHANGE
		mov	di, mask MF_RECORD
		call	ObjMessage			; di is event
	;
	;  Now do a MSG_META_GCN_LIST_SEND
	;
		sub	sp, size GCNListMessageParams
		mov	bp, sp
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type, \
		GAGCNLT_APP_TARGET_NOTIFY_FONT_CHANGE
		mov	ss:[bp].GCNLMP_block, bx
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
		
		mov	ax, MSG_META_GCN_LIST_SEND
		mov	dx, size GCNListMessageParams
	;
	;  The following 7 lines of code are copied from UserCallApplication,
	;  except that I don't use MF_FIXUP_DS (there's no object block
	;  to save).
	;
		clr	bx
		call	GeodeGetAppObject
		tst	bx
		jz	moveAlongNowNothingToSeeHereFolks
		
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		
moveAlongNowNothingToSeeHereFolks:
		
		add	sp, size GCNListMessageParams		; restore stack
done:
		.leave
		ret
BannerSetFontController	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetStyleController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies the style control of the saved TextStyle. (if any)

CALLED BY:	BannerOpenApplication

PASS:		bp = handle to state block (0 for none)
		ds = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- make a data block holding a NotifyTextStyleChange
	- initialize the block from saved state
	- give the block an initial reference count of 1
	- record a MSG_META_NOTIFY_WITH_DATA_BLOCK 
	- send the classed event to the correct GCN list
	- grab a beer		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetStyleController	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  First make the block
	;
		mov	ax, size NotifyTextStyleChange
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc			; returns handle in bx
		LONG	jc	done
		mov	ds, ax
	;
	;  initialize the NotifyTextStyleChange structure, unlock
	;  the block and initialize the RefCount to 1 (it was zero
	;  when we alloc'd the block)
	;
		clr	ds:[NTSC_styles]		; new TextStyle
		clr	ds:[NTSC_indeterminates]	; not applicable
		
		call	MemUnlock
		
		mov	ax, 1
		call	MemInitRefCount		; initialize reference count
		mov	bp, bx			; bp <- handle to block
	;
	;  Record a MSG_META_NOTIFY_WITH_DATA_BLOCK.  In bx, pass the
	;  handle of the data block (which will later be replaced by
	;  the handle of the object on the GCN list which we are calling).
	;
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_TEXT_STYLE_CHANGE
		mov	di, mask MF_RECORD
		call	ObjMessage			; di is event
	;
	;  Now do a MSG_META_GCN_LIST_SEND
	;
		sub	sp, size GCNListMessageParams
		mov	bp, sp
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type, \
		GAGCNLT_APP_TARGET_NOTIFY_TEXT_STYLE_CHANGE
		mov	ss:[bp].GCNLMP_block, bx
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
		
		mov	ax, MSG_META_GCN_LIST_SEND
		mov	dx, size GCNListMessageParams
	;
	;  The following 7 lines of code are copied from UserCallApplication,
	;  except that I don't use MF_FIXUP_DS (there's no object block
	;  to save).
	;
		clr	bx
		call	GeodeGetAppObject
		tst	bx
		jz	moveAlongNowNothingToSeeHereFolks
		
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		
moveAlongNowNothingToSeeHereFolks:
		
		add	sp, size GCNListMessageParams		; restore stack
done:
		.leave
		ret
BannerSetStyleController	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetLongerSuffix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the length of the longer suffix

CALLED BY:	BannerOpenApplication

PASS:		*ds:si  = instance data
		es = ds = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	When a banner is printed in double height mode it is printed with 
	two documents:  one for the top, and one for the bottom.  Here, 
	the longer of the two suffixes is determined and saved in 
	longestPrintedDocNameSuffix.  This is then used by BannerGetDocName 
	when a double height banner is printed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/3/91		Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetLongerSuffix	proc	near
		uses	ax, bx, di
		.enter
		
		push	ds
		GetResourceHandleNS	BannerStrings, bx
		call	MemLock				; lock the block
		mov	ds, ax
		
		assume	ds:BannerStrings

		mov	di, ds:[topPostfix]
		ChunkSizePtr ds, di, ax			;ax <- size of "top"
		mov	di, ds:[bottomPostfix]
		ChunkSizePtr ds, di, bx			;bx <- size of "bottom"

		cmp	ax, bx
		jnb	notLarger
		mov	ax, bx
notLarger:
DBCS <		shr	ax, 1				;ax <- length w/NULL >
		dec	ax				; don't count the NULL
		mov	es:longestPrintedDocNameSuffix, al
		mov	bx, handle BannerStrings	; get the block handle
		call	MemUnlock			; unlock the block
		pop	ds
		assume	ds:dgroup
		
		.leave
		ret
BannerSetLongerSuffix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 BannerLoadSavedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the variables saved in a state file

CALLED BY:	BannerOpenApplication

PASS:		es = dgroup
		bp = handle to state file

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/ 3/91	Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerLoadSavedState	proc	near
		uses	ax, bx, cx, si, di
		.enter
	;
	; Reload the state data (if there is any) in TheBanner
	; if bp == 0 there is no handle so there is no state file
	;
		tst	bp
		jz	noState
	;
	; Restore the data (if any)
	;
		mov	bx, bp				; bx <- block handle
		call	MemLock
		mov	ds, ax				; ds <- segment
		
		mov	cx, (EndStateData - StartStateData)
		clr	si
		mov	di, offset StartStateData
		rep	movsb				; copy the bytes
		call	MemUnlock
		
		segmov	ds, es				; ds <- dgroup
		
		.leave
		ret
noState:
		mov	ds:[savedStateFontID], BANNER_DEFAULT_FONT_ID

if PZ_PCGEOS
	;
	; set font in Banner text entry
	;
		push	dx, bp
		mov	dx, size VisTextSetFontIDParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].VTSFIDP_fontID, BANNER_DEFAULT_FONT_ID
		movdw	ss:[bp].VTSFIDP_range.VTR_start, 0
		movdw	ss:[bp].VTSFIDP_range.VTR_end, TEXT_ADDRESS_PAST_END
		mov	ax, MSG_VIS_TEXT_SET_FONT_ID
		GetResourceHandleNS	BannerTextEdit, bx
		mov	si, offset BannerTextEdit
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size VisTextSetFontIDParams
		pop	dx, bp
endif
		
		.leave
		ret
BannerLoadSavedState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		      BannerSetUIFromSavedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ui based on the restored state variables

CALLED BY:	BannerOpenApplication
PASS:		ds = dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/3/91		Initial version
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetUIFromSavedState	proc	near
	;
	;  set selection in the border menu
	;
		mov	cx, ds:[savedStateSpecialEffects]
		test	cx, SE_NO_BORDER
		jz	doneBorders

		push	cx		; save special effects
		GetResourceHandleNS 	ExclusiveBoxList, bx
		mov	si, offset 	ExclusiveBoxList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS	
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
		pop	cx		; restore special effects
doneBorders:
	;
	;  set selection in the effects menu
	;
		test	cx, SE_NO_EFFECT
		jz	doneSpecialEffects
		
		push	cx		; save special effects
		GetResourceHandleNS	ExclusiveSpecialEffectsList, bx
		mov	si, offset 	ExclusiveSpecialEffectsList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS	
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
		pop	cx		; restore special effects
		
doneSpecialEffects:
	;
	; set the double-height menu entry
	;
		test	cx, mask SE_DOUBLE_HEIGHT
		jz	doneDoubleHeight
		
		push	cx		; save special effects
		GetResourceHandleNS 	DoubleHeightList, bx
		mov	si, offset 	DoubleHeightList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
		pop	cx		; restore special effects
		
doneDoubleHeight:
		
		GetResourceHandleNS	TheBanner, bx
		mov	si, offset	TheBanner
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_BANNER_SET_SAVED_SPECIAL_EFFECTS
		call	ObjMessage
	;
	;  The styles menu got set earlier.  However, if we have
	;  an actual special effect, we should set it in
	;  the banner.
	;
		and	cx, mask TS_BOLD or mask TS_ITALIC or mask TS_UNDERLINE
		jz	doneStyles
		
		GetResourceHandleNS	TheBanner, bx
		mov	si, offset	TheBanner
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_BANNER_SET_SPECIAL_EFFECT
		call	ObjMessage
doneStyles:
		ret
BannerSetUIFromSavedState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes care of state-saving stuff

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ds = es = dgroup

RETURN:		cx = block handle holding state data

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/27/91		Initial version
	rsf	9/26/91		pirated from perf!
	stevey	10/18/92	port to 2.0 (added comments :)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerCloseApplication	method	BannerProcessClass,
				MSG_GEN_PROCESS_CLOSE_APPLICATION
	;
	; save the special effects info
	;
		GetResourceHandleNS	TheBanner, bx
		mov	si, offset	TheBanner
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_BANNER_GET_SPECIAL_EFFECTS
		call	ObjMessage
		
		mov	es:[savedStateSpecialEffects], cx
	;
	; save the banner's state info
	;
		GetResourceHandleNS	TheBanner, bx
		mov	si, offset	TheBanner
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_BANNER_GET_STATE
		call	ObjMessage
		
		mov	es:[savedStateBannerState], cl
	;
	; save the font
	;
		GetResourceHandleNS	TheBanner, bx
		mov	si, offset	TheBanner
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_BANNER_GET_FONT
		call	ObjMessage
		
		mov	es:[savedStateFontID], cx
	;
	; Allocate the block
	;
		mov	ax, (EndStateData - StartStateData)
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc
		jc	done
		
		mov	es, ax			; es = state block segment
	;
	; Store the state
	;
		mov	cx, (EndStateData - StartStateData)
		clr	di			; es:di = destination block
		mov	si, offset StartStateData	; ds:si = state stuff
		rep	movsb
		
		call	MemUnlock
		mov	cx, bx			; return block handle in cx
done:
		ret
BannerCloseApplication	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerClosePrimary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask user if he really wants to exit the application
		if a Banner is in progress (only in the AUI)

CALLED BY:	MSG_GEN_DISPLAY_CLOSE

PASS:		*DS:SI	= BannerPrimaryClass object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/29/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerClosePrimary	method	BannerPrimaryClass,
				MSG_GEN_DISPLAY_CLOSE
	;
	; Check to see if we're in the CUI or the AUI
	;
		push	ds:[LMBH_handle], si
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		je	callSuper
	;
	; OK, we're not in the CUI, so let's see if there
	; is a banner in progress (i.e. any text)
	;
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		GetResourceHandleNS	BannerTextEdit, bx
		mov	si, offset	BannerTextEdit
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		tst	ax
		jz	callSuper
	;
	; There is text, so prompt the user to check if s/he really
	; does want to exit (and lose the banner in progress).
	;
		clr	ax
		pushdw	axax		; don't care about SDOP_helpContext
		pushdw	axax		; don't care about SDOP_customTriggers
		pushdw	axax		; don't care about SDOP_stringArg2
		pushdw	axax		; don't care about SDOP_stringArg1
		mov	bx, handle BannerStrings
		call	MemLock		; lock the resource block
		mov	ds, ax
		mov	si, offset BannerStrings:exitWarningString
		mov	si, ds:[si]	; point to the string
		pushdw	dssi		; save SDOP_customString
		mov	bx, CustomDialogBoxFlags <
				FALSE,
				CDT_QUESTION,
				GIT_AFFIRMATION,
				0
			>
		push	bx		; save SDOP_customFlags
		call	UserStandardDialog
		mov	bx, handle BannerStrings
		call	MemUnlock	; unlock the resource
		cmp	ax, IC_NO	; did user not want to exit?
		jne	callSuper	; nope - so continue exit
		mov	ax, MSG_META_NULL
		jmp	callSuperNewMsg	; abort close
	;
	; We do want to exit - call the superclass
	;
callSuper:
		mov	ax, MSG_GEN_DISPLAY_CLOSE
callSuperNewMsg:
		pop	bx, si
		call	MemDerefDS	; BannerPrimary object => *DS:SI
		mov	di, offset BannerPrimaryClass
		GOTO	ObjCallSuperNoLock
BannerClosePrimary	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerGetTextString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a block with the BannerTextEdit string.

CALLED BY:	BannerDraw, MaximizeTextSize, BannerScreenDraw, BannerPrint

PASS:		ds	= "fixup-able" segment (i.e. object block segment)

RETURN:		dx	= handle of block for text
		cx	= length of text string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- request the text to be placed into a global memory block
	- free the block if there isn't any text (might as well do it here)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerGetTextString		proc	near
		uses	ax, bx, si, di
		.enter
		
	;
	; Get a pointer (ds:si) to the text string in BannerTextEdit
	; Allocate a block for it.
	;
		GetResourceHandleNS	BannerTextEdit, bx
		mov	si, offset	BannerTextEdit
		clr	dx			; allocate a new block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; returns block handle in cx
		
		mov	dx, cx		; dx <- handle
		mov_tr	cx, ax		; cx <- length, not including NULL
		.leave
		ret
BannerGetTextString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetFontDetails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to set font attributes in gstate

CALLED BY:	global

PASS:		*ds:si	= instance data
		ds:[di]	= specific instance data to a banner
		bp	= gstate handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	10/ 3/90	Initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetFontDetails	proc	near
		class	BannerClass
		uses	ax, bx, cx, dx, di, bp
		.enter
		
		xchg	di, bp			; di = gstate, bp = instance
		
		mov	dx, ds:[bp].BI_pointSize
		clr	ah			; set the point size fraction
		mov	cx, ds:[bp].BI_fontID
		call	GrSetFont		; set the font size
		
	;
	;  Set the text style.  Only the following three styles may be
	;  set from here.  All other bits must be masked out because they
	;  are used differently by banner.
	;
		mov	ax, ds:[bp].BI_specialEffects
		andnf	al, mask TS_BOLD or mask TS_ITALIC or mask TS_UNDERLINE
		mov	ah, al			; unset the other bits
		not	ah
		call	GrSetTextStyle

		.leave
		ret
BannerSetFontDetails	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the timer, if any.

CALLED BY:	MSG_VIS_CLOSE

PASS:		*ds:si  - instance data

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	10/12/90	Initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerVisClose	method	BannerClass, MSG_VIS_CLOSE
		
	;
	; call the superclass to do its stuff
	;
		mov	di, offset BannerClass
		call	ObjCallSuperNoLock
		
		mov	di, ds:[si]
		add	di, ds:[di].Banner_offset
		
		call	BannerRemoveAnyTimer
		
		ret
BannerVisClose	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetSavedSpecialEffects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the special effects.

CALLED BY:	MSG_BANNER_SET_SAVED_SPECIAL_EFFECTS

PASS:		*ds:si  = TheBanner object
		ds:[di] = BannerInstance
		cx	= special effects structure

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	9/30/91		Initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetSavedSpecialEffects	method	BannerClass, 
				MSG_BANNER_SET_SAVED_SPECIAL_EFFECTS
		
		mov	ds:[di].BI_specialEffects, cx
		
		ret
BannerSetSavedSpecialEffects	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerGetSpecialEffects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the special effects.

CALLED BY:	MSG_BANNER_GET_SPECIAL_EFFECTS

PASS:		*ds:si  = TheBanner object
		ds:[di] = BannerInstance

RETURN:		cx	= BI_specialEffects
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	9/30/91		Initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerGetSpecialEffects		method		BannerClass, 
		MSG_BANNER_GET_SPECIAL_EFFECTS
		
		mov	cx, ds:[di].BI_specialEffects
		
		ret
BannerGetSpecialEffects	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerGetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the banner state info.

CALLED BY:	MSG_BANNER_GET_STATE

PASS:		*ds:si  = TheBanner object
		ds:[di] = BannerInstance

RETURN:		cx	= BI_bannerState

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	9/30/91		Initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerGetState	method	BannerClass, MSG_BANNER_GET_STATE
		
		mov	cl, ds:[di].BI_bannerState
		
		ret
BannerGetState	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerGetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the font ID.

CALLED BY:	MSG_BANNER_GET_FONT

PASS:		*ds:si  = TheBanner object
		ds:[di] = BannerInstance

RETURN:		cx	- FontDI

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	9/30/91		Initial version
	stevey	10/18/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerGetFont	method	BannerClass, MSG_BANNER_GET_FONT
		
		mov	cx, ds:[di].BI_fontID
		
		ret
BannerGetFont	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerViewStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give a warnining beep.

CALLED BY:	MSG_BANNER_GET_FONT

PASS:		*ds:si  = BannerView object
		ds:[di] = BannerView Instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	2/16/99		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerViewStartSelect	method	BannerClass, MSG_META_START_SELECT

		mov	di, offset BannerClass
		call	ObjCallSuperNoLock

		mov	ax, SST_ERROR
		call	UserStandardSound
		ret
BannerViewStartSelect	endm


;  Only one style for the text
;  ss:bp - VisTextSetTextStyleParams
;
BannerTextVisTextSetTextStyle	method BannerTextClass,
	MSG_VIS_TEXT_SET_TEXT_STYLE

	movdw	ss:[bp].VTSTSP_range.VTR_start, 0
	movdw	ss:[bp].VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	di, offset BannerTextClass
	call	ObjCallSuperNoLock

	ret
BannerTextVisTextSetTextStyle	endm

;  Only one font for the text
;  ss:bp - VisTextSetFontIDParams
;
BannerTextVisTextSetTextFont	method BannerTextClass,
	MSG_VIS_TEXT_SET_FONT_ID

	movdw	ss:[bp].VTSFIDP_range.VTR_start, 0
	movdw	ss:[bp].VTSFIDP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	di, offset BannerTextClass
	call	ObjCallSuperNoLock

	ret
BannerTextVisTextSetTextFont	endm
		
;  Only one color for the text
;  ss:bp - VisTextSetColorParams
;
BannerTextVisTextSetTextColor	method BannerTextClass,
	MSG_VIS_TEXT_SET_COLOR

	movdw	ss:[bp].VTSCP_range.VTR_start, 0
	movdw	ss:[bp].VTSCP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	di, offset BannerTextClass
	call	ObjCallSuperNoLock

	ret
BannerTextVisTextSetTextColor	endm
		

CommonCode	ends

