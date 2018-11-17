COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GeoWrite/pizza
MODULE:		Fixed Char/Line/Page controller
FILE:		uiFixed.asm

AUTHOR:		Brian Witt, Aug 24, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	8/24/93   	Initial revision
	witt	9/15/93 	Code cleanup (thanks gene!)
	witt	9/22/93 	Removed ERROR_cc and EC<> macros.

DESCRIPTION:
	File contains code to implement a fixed chars/line and fixed
	lines/page controller.  It is for the "pizza" project.  It is
	meant to be an option under the Layout menu.


	Default is to take max chars/line and lines/page values and to
	round up.  This can force more chars on a line than would normally
	(and confortably) fit there.

	$Id: uiFixed.asm,v 1.1 97/04/04 15:55:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


UseLib	Objects/vTextC.def
include	pageInfo.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

RegionParams	struct
	RP_avgCharHeight 	WWFixed
	RP_avgCharWidth  	WWFixed
RegionParams	ends


idata	segment
	FixedCharLinePageControlClass
idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
;		Code for FixedCharLinePageControlClass
;------------------------------------------------------------------------------

ControlCode	segment resource

;	The 'ControlCode' segment is loaded seperately from the main bulk
;	of code sothat if the user is just browsing, the kernel can just
;	page in enough of the code without getting all the features, which
;	are being used at this instant.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedSpacingCtrlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Often times the controller class needs information 
		describing ourselves (controller doesn't cache this info).
		When called, we'll make a copy of our info.  Fills in
		the memory caller provides us.

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= FixedCharLinePageControlClass object
		ds:di	= FixedCharLinePageControlClass instance data

		es 	= segment of FixedCharLinePageControlClass
		cx:dx	= GenControlBuildInfo structure to fill in.

RETURN:		structure filled in (but cx:dx registers changed)
DESTROYED:	cx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		(Based on code from Library/Text/UI/uiLineSpacing.asm)
		(Code is basically 'CopyDupInfoCommon')
		Code choosen to be small space.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	8/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedSpacingCtrlGetInfo	method dynamic FixedCharLinePageControlClass, 
					MSG_GEN_CONTROL_GET_INFO
	.enter

	mov	si, offset FCLPC_dupInfo
	segmov	ds, cs, ax			;ds:si = source (local)

	mov	es, cx
	mov	di, dx				;es:di = dest (caller space)

	mov	cx, size GenControlBuildInfo
	rep movsb

	.leave
	ret
FixedSpacingCtrlGetInfo	endm


FCLPC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	    ; GCBI_flags
	FCLPC_IniFileKey,			; _initFileKey
	FCLPC_gcnList,				; _gcnList
	length FCLPC_gcnList,			; _gcnCount
	FCLPC_notifyTypeList,			; _notificationList
	length FCLPC_notifyTypeList,
	FCLPCName,				; _controllerName

	handle FixedSpacingControlUI,		; _dupBlock
	FCLPC_childList,			; _childlist
	length FCLPC_childList,			; _childCount
	FCLPC_featuresList,			; _featuresList
	length FCLPC_featuresList,		; _featuresCount
	FCLP_DEFAULT_FEATURES,			; _features

	0,					; _toolBlock
	0,					; _toolList
	0,					; _toolCount
	0,					; _toolFeaturesList
	0,					; _toolFeaturesCount
	FCLP_DEFAULT_TOOLBOX_FEATURES,   	; _toolFeatures

	0 >				    ; GCBI_helpContext


FCLPC_IniFileKey	char	"fixedCharLinePage", C_NULL


;	The lists to listen to:
FCLPC_gcnList	GCNListType  \
     <MANUFACTURER_ID_GEOWORKS,GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
     <MANUFACTURER_ID_GEOWORKS,GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>,
     <MANUFACTURER_ID_GEOWORKS,GAGCNLT_APP_TARGET_NOTIFY_PAGE_INFO_STATE_CHANGE>


;	The typed-data we understand:
FCLPC_notifyTypeList	NotificationType  \
	<MANUFACTURER_ID_GEOWORKS,GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS,GWNT_TEXT_PARA_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS,GWNT_PAGE_INFO_STATE_CHANGE>

; - - - - -


FCLPC_childList	GenControlChildInfo  \
	<offset CharsLinesPageGroup, mask FCLPF_CHAR_LINE_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset FontSelectGroup, mask FCLPF_FONT_NAMING,
					mask GCCF_IS_DIRECTLY_A_FEATURE>


;  Careful, this table is in the *opposite* order as the record with which
;  it's defined.  Assembler allocates bits in record from high bit down..
;
FCLPC_featuresList	GenControlFeaturesInfo  \
	<offset FontSelectGroup, VisFontSelectName, 0>,
	<offset CharsLinesPageGroup, VisFixedSpacingName, 0>


ControlCode	ends


CommonCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedSpacingCtrlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles notice of attributes' change.  The result of
		something sending a GCN to us. ss:[bp].changeID can be
		PARA or TEXT.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= FixedCharLinePageControlClass object
		ds:di	= FixedCharLinePageControlClass instance data
		es 	= segment of FixedCharLinePageControlClass

		ss:bp	= GenControlUpdateUIParams structure ptr
RETURN:		nothing.
DESTROYED:	bx, si, di, es

SIDE EFFECTS:	recomputes maxes and updates UI.
		**  Once the [Apply] button is hit, we send out an update
		    message to the target VisText object.  The controller
		    logic turns off [Apply].  However, the VisText object
		    will then send out new GCNs.  These are intercepted
		    here and re-enable [Apply]!  This way, if the user hits
		    [Close], followed by another open, our [Apply] button
		    will still be usable!  Timing is everything.
		**  However, changing the controller from a "properties" type
		    into a "command" type would have the same result, except
		    that [Apply] would be usable even if we have not received
		    complete information.

PSEUDO CODE/STRATEGY:
		If GCN is char attrs, then
			store font point size, kind, and style.
		If GCN is page info, then
			widthRegion := width - rightMargin - leftMargin
			heightRegion := height - topMargin - bottomMargin
		endif.
		if maximums are computable, then
			update maximum values for spinners
			enable [Apply] button.
		endif

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	8/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedSpacingCtrlUpdateUI	method dynamic FixedCharLinePageControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	uses	ds, si
	.enter

	;  Get notification data
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax			; Notify Datablock starts at es:0

	push	bx
	push	ds, si, di		; remember who we are!

	mov	cx, ss:[bp].GCUUIP_changeType

	;  Registers  ;
	;   cx = change type, ss:bp = GCUUIP par  ;
	;   ds:si = *object, ds:di = instance data, es:0 datablock  ;

;firstTry:
	cmp	cx, GWNT_TEXT_CHAR_ATTR_CHANGE
	jne	tryParaChange

	call	FormatFontNameSize	; (needs ss:bp and es:)
	;
	;	Some character attributes have changed...
	;	Prepare to use `movsb' inst
	;
	segxchg	es, ds		; es:di = instance data, ds:0 = datablock
	;
	;	Grab track kerning
	;
	mov	ax, ds:VTNCAC_charAttr.VTCA_trackKerning
	mov	es:[di].FixedAttrs.FCLPI_trackKerning, ax
	;
	;	Copy over the goodies cuz I don't know how big these things
	;	are.  But they are contigious!
	;		VisTextNotifyCharAttrChange
	;
	;	   VTCA_fontID / VTCA_pointSize / VTCA_textStyles
	mov	cx, size FontID + size WBFixed + size TextStyle

	mov	si, offset ds:VTNCAC_charAttr.VTCA_fontID ; from notify data
	lea	di, es:[di].FixedAttrs.FCLPI_fontID	  ; to instance data

	rep	movsb		; from ds:si --> es:di

	jmp	fscuUnlock

	; ---------------------------------

tryParaChange:
	cmp	cx, GWNT_TEXT_PARA_ATTR_CHANGE
	jne	tryPageInfo

	mov	ax, {word}es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_lineSpacing
	mov	{word}ds:[di].FixedAttrs.FCLPI_lineSpacing, ax

	jmp	fscuUnlock

	; ---------------------------------

tryPageInfo:
EC<	cmp	cx, GWNT_PAGE_INFO_STATE_CHANGE	>
EC<	jne	fscuUnlock			>

	;
	;	The edges and line spacing might have changed...
	;	type:	NotifyPageInfoChange

	;	Compute Usable Width.
	;	widthRegion := width - rightMargin - leftMargin
	;
	mov	dx, es:[NPIC_width]
	clr	cx

	mov	bx, es:[NPIC_rightMargin]
	call	Convert13Dot3ToWWFixed	; bx.ax <- rightMargin
	subdw	dxcx, bxax

	mov	bx, es:[NPIC_leftMargin]
	call	Convert13Dot3ToWWFixed	; bx.ax <- leftMargin
	subdw	dxcx, bxax

	movdw	ds:[di].FixedAttrs.FCLPI_widthRegion, dxcx

	;
	;	Compute Usable Height.
	;	heightRegion = height - topMargin - bottomMargin
	;
	mov	dx, es:[NPIC_height]
	clr	cx

	mov	bx, es:[NPIC_topMargin]
	call	Convert13Dot3ToWWFixed	; bx.ax <- topMargin
	subdw	dxcx, bxax

	mov	bx, es:[NPIC_bottomMargin]
	call	Convert13Dot3ToWWFixed	; bx.ax <- bottomMargin
	subdw	dxcx, bxax

	movdw	ds:[di].FixedAttrs.FCLPI_heightRegion, dxcx

						; fall thru..
	; ---------------------------------
	;
	;	Unlock the GCN information that was sent out.
	;	Then, from the changes determine the new maximums.
	;	If possible, adjust the max values for the GenValue gadgets.
	;
fscuUnlock:
	pop	ds, si, di		; Now `pobj' will work.

	;  Registers  ;
	;   ds:si = *instance data, ds:di = instance data  ;

	call	FixedFindMaxCharsLinePage	; cx->max Lines/Page,
						; dx->max Chars/Line,
						; ax->min Lines/Page,
						; bx->min Chars/Line
						; di->current Lines/Page
						; bp->current Chars/Line
	jc	fscuAfterMaxs	   		; indeterminate values.. :-(

	;	First the UI updating.
	;
	push	di, bp				; save current vals
	mov	bp, bx				; bx = mix Chars/Line
	push	ax				; save min Lines/Page
	call	FixedGetChildBlockAndFeatures	; get correct BX
	pop	ax				; restore min Lines/Page
	call	FixedSetCharsLinePageMaxs	; Adjust UI's max values.
	pop	cx, dx				; restore current vals
	call	FixedSetCharsLinePageCurrent

	;
	;	Lastly, enable [Apply] button cuz our data might have changed.
	;
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	ObjCallInstanceNoLock
fscuAfterMaxs:

	pop	bx			; retrieve datablock handle. 
	call	MemUnlock

	.leave
	ret

FixedSpacingCtrlUpdateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the apply message arrives for the controller's dialog,
		tell the model to accept some new text settings.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= FixedCharsLinePageControlClass object
		ds:di	= FixedCharsLinePageControlClass instance data
		es 	= segment of FixedCharsLinePageControlClass
		ax	= message #
RETURN:		
DESTROYED:	ax, bx, cx, bp, si, di, ds, es (method handler)
SIDE EFFECTS:	
		(reference file: /S/P/L/Spreadsheet/UI/uiBorder.{asm|ui})
PSEUDO CODE/STRATEGY:
		Let superclass handle any visual stuff first.
		Vertical space is adjusted vis "line spacing"
		Horizontal space is adjust via "char kerning"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedApply	method dynamic FixedCharLinePageControlClass, 
					MSG_GEN_APPLY
	.enter

	push	di

	;	Do the superclasscall thing first (visible UI)	;
	mov	di, offset FixedCharLinePageControlClass
	call	ObjCallSuperNoLock

	pop	di			; get back ptr to instance data

	; ---------------------------------
	;
	;	Compute spacings and send results to VisText target.
	;
	call	FixedComputeSpacings	; yields cx=Lines/Page, dx=Chars/Line.
	push	dx

	mov	ax, MSG_VIS_TEXT_SET_LINE_SPACING
	call	SendVisText_AX_CX

	pop	cx
	mov	ax, MSG_VIS_TEXT_SET_TRACK_KERNING
	call	SendVisText_AX_CX

	.leave
	ret
FixedApply	endm


CommonCode	ends


; ---------------------------------------------------
;		Borrowed  Functions
; ---------------------------------------------------

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for a controller
CALLED BY:	UTIL

PASS:		*ds:si - controller
RETURN:		ax - features record
		bx - handle of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		(stolen from Library/Spreadsheet/UI/uiUtils.asm)
		Call this routine instead of "GetResourceHandle bx, UIitem"
		because the controller object uses a duplicated UI template
		resource.  Therefore we must call to findout the handle of
		the duplicate that's been made for this instance.

		Returns the handle in BX, just like normal.  Afterwards, the
		"mov si, offset UIitem" can be done since the UI currently
		in used by this instance of the controller is at the same
		offset as the UI in the template resource segment.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixedGetChildBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
FixedGetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendVisText_AX_CX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends your message to the whole VisText object.  Sends one
		word of data to object.

CALLED BY:	FixedApply
PASS:		ax	= message number for VisText object
		cx	= word of data to send
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	uses some stack space for an MF_STACK parameter block.

PSEUDO CODE/STRATEGY:
	(copied from Library/Text/UI/uiBorder.asm:SendVisText_AX_CX_Common)
	Push two Range structures, then the send-word datum passed in.
	call	GenControlOutputActionStack
	remove Ranges and send-word by adjusting sp directly.

	Contrary to what the include file sez (tCommon.def, 5%), the
	TEXT_ADDRESS_PAST_END must be in the VTR_end field.
	(tag TA_GetTextRange and look at the EC code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendVisText_AX_CX	proc	near
	uses	bx,dx,di,bp
	.enter

	clr	dx			; dx := 0

	push	cx			;datum

	;;;;  Affect the whole document  ;;;;
	mov	bx, TEXT_ADDRESS_PAST_END_HIGH
	mov	cx, TEXT_ADDRESS_PAST_END_LOW
	pushdw	bxcx			; range.end

	push	dx			;range.start.high (0)
	push	dx			;range.start.low (0)
	;;;;  Affect the whole document  ;;;;

	mov	bp, sp

	mov	dx, size VisTextRange + size word
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	GenControlOutputActionStack

	add	sp, size VisTextRange + size word	; struct was pushed.
CheckHack< (size VisTextRange + size word) eq (size VisTextSetLineSpacingParams) >

	.leave
	ret
SendVisText_AX_CX	endp

CommonCode	ends



; ---------------------------------------------------
;		Local  Function  Library
; ---------------------------------------------------

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedFindMaxCharsLinePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given current settings, compute the maximum of chars/line and
		lines/page settings for fitting within the region boundries.
		If values are computable, returns carry clr.

CALLED BY:	FixedSpacingCtrlUpdateUI
PASS:		*ds:si	= FixedCharLinePageControlClass object instance data
		ds:di	= instance data ptr
RETURN:		carry	= clr => maximums computed.
			  set => can't compute maxs.
		cx	= maximum allowable Lines/Page
		dx	= maximum allowable Chars/Line
		ax	= minimum allowable Lines/Page
		bx	= minimum allowable Chars/Line
		di	= current Lines/Page
		bp	= current Chars/Line
DESTROYED:	
SIDE EFFECTS:		
		Long division is performed here (GrUDivWWFixed).  Hopefully,
		division by zero is guarded against!

PSEUDO CODE/STRATEGY:
		* Caller should ensure FCLPI_heightRegion and FCLPI_widthRegion
		  are non-zero.
		* Compile time option to round the values.  This could caus
		  later calculations to go negative...

		Fetching region parameters.
		if invalid region, return carry set.

		cx = ( region height / point Size )
		dx = ( region width / avg char Width ).
		return carry clear.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	8/17/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedFindMaxCharsLinePage	proc	near
	class	FixedCharLinePageControlClass
regionParams	local	RegionParams
maxLinesPage	local	WWFixed
	push	si
	.enter
	push	bp
	lea	bp, ss:[regionParams]
	call	ComputeRegionParams
	pop	bp

	; Registers ;
	;  regionParams = RegionParams, ds:di = instance ptr ;
	; ----------------------------------------
	;
	;  Determine max lines per page.
	;
	clr	ax
	movwbf	bxah, ds:[di].FixedAttrs.FCLPI_pointSize
	tst	bx
	stc
LONG	jz	afterGettingGoodValues

	movdw	dxcx, ds:[di].FixedAttrs.FCLPI_heightRegion
					; heightRegion / lineToLineDist
	call	GrUDivWWFixed		; dx.cx / bx.ax -> dx.cx
					; dx.cx = most lines per page!
	movwwf	maxLinesPage, dxcx

	; ----------------------------------------
	;
	;  Determine max chars per line (within maximum)
	;
	movdw	bxax, regionParams.RP_avgCharWidth

	movdw	dxcx, ds:[di].FixedAttrs.FCLPI_widthRegion
					; widthRegion / avg font width
	call	GrUDivWWFixed		; dx.cx / bx.ax => dx.cx

	mov	bx, dx		; bx = most chars per line! (rnd dwn)

	mov	ax, MAX_FIXED_CHARS_PER_LINE
	cmp	ax, bx
	jg	afterCharsMax
	mov	bx, ax			; "Reduce speed ahead"
afterCharsMax:
	push	bx			; save max chars/line

	; ----------------------------------------
	;
	;  Determine min lines per page
	;	min = height / (pointsize * MAX_LINE_SPACING)
	;
	movwwf	dxcx, maxLinesPage	; dxcx = hgt/ptsize (max lines/page)
	mov	bx, VIS_TEXT_MAX_LINE_SPACING_INT
	mov	ax, VIS_TEXT_MAX_LINE_SPACING_FRAC
	call	GrUDivWWFixed		; dx.cx / bx.ax => dx.cx = min li/pg
	tst	cx			; round up?
	jz	noRoundUp
	inc	dx
noRoundUp:
	push	dx			; save min lines/page

	; ----------------------------------------
	;
	;  Determine current lines per page
	;	current = height / (pointsize * current line spacing)
	;	
	;	maxLinesPage = height/ptsize
	;
	movwwf	dxcx, maxLinesPage	; dx.cx = height/ptsize
	clr	bx, ax			; bx.ax = current line spacing
	mov	bl, ds:[di].FixedAttrs.FCLPI_lineSpacing.BBF_int
	mov	ah, ds:[di].FixedAttrs.FCLPI_lineSpacing.BBF_frac
	call	GrUDivWWFixed		; dx.cx = current lines per page
	rndwwf	dxcx, ax
	push	ax			; save current lines/page
	
	; ----------------------------------------
	;
	;  Determine min chars per line
	;	min = width / ( (avg font width + (MAX_KERN*ptsize/256)) )
	;
	mov	dx, MAX_TRACK_KERNING
	clr	cx
	clr	ax
	movwbf	bxah, ds:[di].FixedAttrs.FCLPI_pointSize
	call	GrMulWWFixed		; dx.cx = MAX_KERN*ptsize
	mov	cl, ch
	mov	ch, dl
	mov	dl, dh
	clr	dh
	tst	ch			; any remainder from dx.cx/256?
	jz	noRemainder
	inc	dx			; round up
noRemainder:
					; dx.cx = MAX_KERN*ptsize/256
	movdw	bxax, regionParams.RP_avgCharWidth
	adddw	bxax, dxcx		; bx.ax = (MAX_KERN*ptsize/256)+avgW
	movdw	dxcx, ds:[di].FixedAttrs.FCLPI_widthRegion
	call	GrUDivWWFixed		; dx.cx = min chars per line
	rndwwf	dxcx, ax		; ax = min chars/line
	push	ax
	
	; ----------------------------------------
	;
	;  Determine current chars per line
	;	min = width / ( (avg font width + (curr kern*ptsize/256)) )
	;
	mov	dx, ds:[di].FixedAttrs.FCLPI_trackKerning
	clr	cx
	clr	ax
	movwbf	bxah, ds:[di].FixedAttrs.FCLPI_pointSize
	call	GrMulWWFixed		; dx.cx = curr kern*ptsize
	mov	bx, 256
	clr	ax
	call	GrUDivWWFixed		; dx.cx = curr kern*ptsize/256
	movdw	bxax, regionParams.RP_avgCharWidth
	adddw	bxax, dxcx		; bx.ax = (curr kern*ptsize/256)+avgW
	movdw	dxcx, ds:[di].FixedAttrs.FCLPI_widthRegion
	call	GrUDivWWFixed		; dx.cx = current chars per line
	rndwwf	dxcx, si		; si = current chars/line
	
	; ----------------------------------------
	;
	;	Restore the line-to-line spacing needed and clear
	;	carry cuz it all worked out.
	;
	pop	bx			; bx = min chars/line
	pop	di			; di = current lines/page
	pop	ax			; ax = min lines/page
	pop	dx			; dx = max chars/line
	mov	cx, maxLinesPage.WWF_int	; cx = max lines/page
						;	(round down)
	clc				; OK!

afterGettingGoodValues:
	.leave
	mov	bp, si			; bp = current chars/line
	pop	si
	ret
FixedFindMaxCharsLinePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedSetCharsLinePageMaxs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given some max values, sets the spinners' upper limit.  The
		manual sez the maximums can adjust downward the current
		GenValue value, so we depend on this behavior.

CALLED BY:	FixedSpacingCtrlUpdateUI
PASS:		*ds:si	= controller instance
		bx	= handle of cvisible controller gadgetry
		cx	= max allowable Lines/Page
		dx	= max allowable Chars/Line
		ax	= min allowable Lines/Page
		bp	= max allowable Chars/Line
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, es, bp
SIDE EFFECTS:	Sets maximums in the spinners for Chars/Line and Lines/Page
		UI gadgetry.

PSEUDO CODE/STRATEGY:
		Set the spinners to the integer maximums.

yREVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedSetCharsLinePageMaxs	proc	near
	uses	bx,si
	.enter

	push	ax			; save min Lines/Page
	push	bp			; save min Chars/Line
	push	cx			; save max Lines/Page

	mov	si, offset CharsPerLineValue
	call	setMax

	mov	si, offset LinesPerPageValue
	pop	dx
	call	setMax

	mov	si, offset CharsPerLineValue
	pop	dx
	call	setMin

	mov	si, offset LinesPerPageValue
	pop	dx
	call	setMin

	.leave
	ret

setMin:
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	jmp	short setCommon

setMax:
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
setCommon:
	clr	cx			; dx.0 = new value
	mov	di, mask MF_CALL	; immediately set the max
	call	ObjMessage		; (value=dx.cx)
	retn
FixedSetCharsLinePageMaxs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedSetCharsLinePageCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given some current values, sets the spinners' value.

CALLED BY:	FixedSpacingCtrlUpdateUI
PASS:		*ds:si	= controller instance
		bx	= handle of cvisible controller gadgetry
		cx	= current Lines/Page
		dx	= current Chars/Line
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, es, bp
SIDE EFFECTS:	Sets value in the spinners for Chars/Line and Lines/Page
		UI gadgetry.

PSEUDO CODE/STRATEGY:
		Set the spinners to the integer values.

yREVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedSetCharsLinePageCurrent	proc	near
	uses	bx,si
	.enter

	push	cx			; save current Lines/Page

	mov	si, offset CharsPerLineValue
	call	setCurrent

	mov	si, offset LinesPerPageValue
	pop	dx
	call	setCurrent

	.leave
	ret

setCurrent:
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	cx			; dx.0 = new value
	clr	bp			; not indeterminate
	mov	di, mask MF_CALL	; immediately set the value
	call	ObjMessage		; (value=dx.cx)
	retn
FixedSetCharsLinePageCurrent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabCharsLinePageSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches current Lines/Page and chars/line settings and
		stores their values into registers.

CALLED BY:	FixedSpacingCtrlUpdateUI, FixedStatusCharsLinesPage,
		FixedComputeSpacings
PASS:		bx	= handle of actual controller UI gadgetry
RETURN:		cx	= Lines/Page
		dx	= Chars/Line
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For a controller, each particular instance has its own segment
		for actual UI.  The caller must pass us the handle.
		Items are still at the same offset, though.
		ObjMessage preserves bx and ds for us.

		Asks the two spinners for their current values.
		Returns two integers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	8/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabCharsLinePageSettings	proc	near
	uses	si, di, bp, es
	.enter

	mov	si, offset LinesPerPageValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage 		; get second value first
	push	dx			; save integer part

	mov	si, offset CharsPerLineValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage 		; get second value first
					; dx := Chars/Line
	pop	cx			; cx := Lines/Page

	.leave
	ret
GrabCharsLinePageSettings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatFontNameSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A change/update on the font has occured somewhere.
		Decode font information a redraw our text field.  Routine
		meant to be called from MSG_GEN_CONTROL_UPDATE_UI handler.

CALLED BY:	FixedSpacingCtrlUpdateUI
PASS:		es	= VisTextNotifyCharAttrChange
		ss:bp	= GenControlUpdateUIParams structure ptr
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Much of the appearance is governed by the UI GenValue.
		Decodes the FontID into a font name.
		Format the point size into a GenValue calibrated to points.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	8/26/93    	Initial version
	witt	9/22/93		Added error check/recovery code.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatFontNameSize	proc	near
	uses	bx, bp, si, di, es, ds
	.enter

	movwbf	dxch, es:[VTNCAC_charAttr].VTCA_pointSize
	pushdw	dxcx
	call	FixedGetChildBlockAndFeatures	; resource handle -> bx

	; ----------------------------------------
	;
	;	1. Create buffer on stack to receive font name.
	;
	sub	sp, FONT_NAME_LEN
	mov	si, sp
	segmov	ds, ss, ax
	push	bx			; save UI resource handle

	mov	cx, es:[VTNCAC_charAttr].VTCA_fontID
					; ds:si is buffer for font name.
	call	GrGetFontName		; cx => "length in chars"
	jc	afterUnknownFont

	; ---------------------------------
	;
	;	UUUggghhh!  Couldn't find font that ought to exist!
	;	Oh well, just leave it blank.
	;
	mov	ax, C_SPACE
	mov	cx, 1
DBCS<	mov	ds:[si], ax	>
SBCS<	mov	ds:[si], al	>

afterUnknownFont:

	;
	;	Prepare for ObjMessage calls.
	;
	movdw	dxbp, sssi		; now dx:bp -> string

	pop	bx			; retrieve UI resource handle
	mov	si, offset FontingFamily

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage 		; (cx=len, dx:bp=^str)

	add	sp, FONT_NAME_LEN

	; ----------------------------------------
	;
	;	2. Set font size spinner (formatted for point size).
	;
	mov	si, offset FontingSize

	clr	cx, bp			; bp = 0 ==> determinate value.
	popdw	dxcx			; retrieve point size.

	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjMessage 	; (dx.cx=value,0=determinate)

	.leave
	ret
FormatFontNameSize	endp

CommonCode	ends


; ---------------------------------------------------
;		Apply  Formatting  Functions
; ---------------------------------------------------

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedComputeSpacings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the desired lines/page and chars/line, computes the
		line spacing factor and character spacing value.  Always
		completes.  (See below for calculations.)

CALLED BY:	
PASS:		ds:si	= handle for FixedCharLinePageControlClass object
		ds:di	= instance ptr of FixedCharLinePageControlClass
RETURN:		cx	= line spacings (BBFixed)
		dx	= char spacings (sword)
DESTROYED:	ax, bx
		(must save ds:si,di)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	* Since the line spacing value will usually be between 1.00 and 1.10,
	  the value is rounded up by adding 1/512 to the BBFixed value.
	* Care is taken to detect overflows.  Generally, error occurs if
	  the high byte of a WWFixed is non-zero.
	* The subtraction is the spacing value forces signed division (see
	  note below).  With rounding enabled, values are rounded _away_
	  from zero; this seems to work...

	q = pointSize relative expansion factor.
	heightRegion = (pointSize * linesDown) * s.

		which yields:
	q  = (256 * ((widthRegion / CharsAcross) - avgCharWidth) / pointSize
	   = char Spacing value (sword)
	   = X expansion
	   = dx.

	s  = roundup( height / (pointSize * charsDown) )
	   = lineSpacing (BBFixed)
	   = Y expansion
	   = cx.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedComputeSpacings	proc	near
	class	FixedCharLinePageControlClass
	uses	si,di
	.enter

	sub	sp, size RegionParams
	mov	bp, sp
	call	ComputeRegionParams

	call	FixedGetChildBlockAndFeatures	; bx -> actual UI gadgetry

	call	GrabCharsLinePageSettings     ; --> cx=Lines/Page, dx=Chars/Line
	push	cx

	;----------------------------------------
	;
	;	Compute needed spacing between chars (X expansion, sword)
	;
	;  Note:  Because of rounding, the difference in dx.cx could be
	;	  negative.  Thus, division is signed.  This happens when
	;	  rounding the max chars across up, actually exceeding
	;	  the boundry by at most half an avg char width.
	;
	mov	bx, dx			; bx.ax = chars on line
	clr	ax

	movdw	dxcx, ds:[di].FixedAttrs.FCLPI_widthRegion

	call	GrUDivWWFixed		; width / charsAcross -> dx.cx

	movdw	bxax, ss:[bp].RP_avgCharWidth

	subwwf	dxcx, bxax		; w/cA - aCW -> dx.cx (maybe negative)

	movwbf	bxah, ds:[di].FixedAttrs.FCLPI_pointSize
	clr	al

	call	GrSDivWWFixed		; (w/cA - aCW) / pS -> dx.cx
	mov	bx, 256
	clr	ax
	call	GrMulWWFixed		; ( (w/cA - aCW) / pS ) * 256 -> dx.cx
;	rndwwf	dxcx			; round to word
;round down (truncate) - brianc 12/12/94
	mov_tr	ax, dx			; ax = track kerning degree
	cmp	ax, MAX_TRACK_KERNING-1
	jle	notTooBig
	mov	ax, MAX_TRACK_KERNING-1
notTooBig:
	cmp	ax, MIN_TRACK_KERNING+1
	jge	notTooSmall
	mov	ax, MIN_TRACK_KERNING+1
notTooSmall:
	pop	dx
	push	ax			; save tracking kern value.

	;----------------------------------------
	;
	;	Compute line-to-line spacing (Y expansion, BFixed)
	;	Value is rounded up.
	;
	clr	cx			; Lines/Page (dx.cx is WWFixed)

	movwbf	bxah, ds:[di].FixedAttrs.FCLPI_pointSize
	clr	al
	call	GrMulWWFixed		; LinesPage * pointSize -> dx.cx

	movdw	bxax, dxcx

	movdw	dxcx, ds:[di].FixedAttrs.FCLPI_heightRegion

	call	GrUDivWWFixed		; heightRegion / (LP * aCH) -> dx.cx
	tst	dh
	jnz	fcsLineOverflow	; (won't be negative)
					; dx.cx = line spacing
;	rndwwbf	dxcx			; round to 8-bit fraction
;round down (truncate) - brianc 12/12/94
	mov	cl, ch			; convert to BBFixed value
	mov	ch, dl			; .. in cx
	tst	cx
	jz	fcsLineOverflow	; (actually underflow; same result)
	cmp	cx, VIS_TEXT_MAX_LINE_SPACING
	jbe	afterLineRounding_CX
	mov	cx, VIS_TEXT_MAX_LINE_SPACING
afterLineRounding_CX:

	; ---------------------------------

	pop	dx			; retrive track kern value.

;fcsDone:
	add	sp, size RegionParams
	.leave
	ret

	; ---------------------------------
	;
	;	Most overflow routines set a maximum value since this routine
	;	must run to completion with sensible values.  Except if
	;	the region computation is indeterminate, then return 
	;	normal "default" values.
	;
fcsLineOverflow:
	mov	cx, (4 shl 8)		; 4 line spacing (BBFixed).
	jmp	afterLineRounding_CX

FixedComputeSpacings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeRegionParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using font specfications to compute average char width and
		height.  Builds GState from self.  Returns values in stack
		based structure; If indeterminate, then fake some values.

CALLED BY:	FixedFindMaxCharsLinePage, FixedComputeSpacings
PASS:		ss:bp	= ptr RegionParams strucuture (stack frame)
		ds:si	= handle for FixedCharLinePageControlClass object
		ds:di	= instance ptr of FixedCharLinePageControlClass
RETURN:		ss:bp	(filled in)
DESTROYED:	ax, bx, cx, dx, es
SIDE EFFECTS:	obtains a GState from self, but then destroys it.

IDEAS/THOUGHTS/PIDDLES:
	*  This routine deals only with instance data.
	*  The font metrics of width and height applied to a Unicode font
	   need to somehow take into account which portion of the Unicode
	   that is currently in use.  If the API changes (is adjusted),
	   the code below may need to adapt to the new interface.
	*  If the region sizes are weird (ie, 0), we default to an
	   8.5" x 11" paper with 1" margins all around.  This saves some
	   error checking code in our callers...

PSEUDO CODE/STRATEGY:
	compute width of region.
	compute height of region.
	if( width == 0 || height == 0 )    (* Indeterminate *)
		width  := 6.5"
		height := 9"		(* fake it *)
	endif

	determine avg char height
	line to line distance (in points) := avg char height * line spacing
	linesPerPage := height of region / line to line distance

	determine avg char width.
	charsPerLine := width of region / avg char width.

	return computed linesPerPage.
	return computed charsPerLine )
	return Carry Clear.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 8/93    	Initial version
	witt	9/23/93 	Always returns valid measurements

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeRegionParams	proc	near
	uses	si, di
	class	FixedCharLinePageControlClass	; (uses instance data)
	.enter

	;	Load up the width within paragraph margins inside region:
	tst	ds:[di].FixedAttrs.FCLPI_widthRegion.WWF_int
	jna	computeIndeterminate

	;	Load up the top/bottom, abort if size is 0.
	tst	ds:[di].FixedAttrs.FCLPI_heightRegion.WWF_int
	ja	beforeGstate

	; ---------------------------------
	;
	;	Either the width or height of printable area is 0.
	;	We create a default 8.5" x 11" with 1" margins all around.
	;
computeIndeterminate:
	mov	dx, 6*72 + 72/2	; 6.5" wide
	clr	ax
	movdw	ds:[di].FixedAttrs.FCLPI_widthRegion, dxax

	mov	dx, 9*72		; 9" tall
	movdw	ds:[di].FixedAttrs.FCLPI_heightRegion, dxax

	; ----------------------------------------
	;
	;	Create a GState so we can determine font dimensions
	;	Since settings for a GState are local, we cannot obtain
	;	a GState the relfects any changes the application has
	;	performed.  Therefore, we re-create on from GCN settings
	;	we've caught and stored.
	;
beforeGstate:
	push	bp

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock	; gives ^hbp Gstate

	;
	;	Now set up font similar to what we've been told.
	;
	mov	cx, ds:[di].FixedAttrs.FCLPI_fontID
	movwbf	dxah, ds:[di].FixedAttrs.FCLPI_pointSize
	mov	bl, ds:[di].FixedAttrs.FCLPI_textStyles	; (for later)

	mov	di, bp			; di = gstate,
	pop	bp			; (bp = frame ptr),
	call	GrSetFont		;  dx.ah = point size, cx = FontID

	mov	al, bl			; retrive text style value
	mov	ah, al
	not	ah			; ah := bits to clear = not(bits to set)
	call	GrSetTextStyle

	;
	;	Examine font average width and height:
	;
	mov	si, GFMI_AVERAGE_WIDTH
	call	GrFontMetrics		; -> WWFixed (points)
	clr	al
	movdw	ss:[bp].RP_avgCharWidth, dxax

	mov	si, GFMI_HEIGHT
	call	GrFontMetrics		; baseline height -> dx.ah
	clr	al
	movdw	ss:[bp].RP_avgCharHeight, dxax

	call	GrDestroyState		; (di=gstate) say good-bye to Mr. G!

	.leave
	ret

ComputeRegionParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Convert13Dot3ToWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accepts a value 8 times larger than it really is (13.3 format),
		converts it to WWFixed, and returns it in bx,ax regs.

CALLED BY:	FixedSpacingCtrlUpdateUI
PASS:		bx	= 13.3 value
RETURN:		bx.ax	= equivalent value as WWFixed
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		clear fractional portion (ax).
		divide by 8, shifting right bxax.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Convert13Dot3ToWWFixed	proc	near
	.enter

	clr	ax
	shrdw	bxax		; heave-ho!
	shrdw	bxax		; (I think three times is faster inline
	shrdw	bxax		;  than performing a loop--plus it saves
				;  a register, to boot!)
	.leave
	ret
Convert13Dot3ToWWFixed	endp


CommonCode	ends

