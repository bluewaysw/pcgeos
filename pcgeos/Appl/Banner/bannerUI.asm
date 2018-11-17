COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		bannerUI
FILE:		bannerUI.asm
AUTHOR:		Roger Flores

ROUTINES:

Name				Description
----				-----------
BannerSetTextStyle		-- called by style controller
BannerSetSpecialEffects		-- sets special effects & updates preview.
GetOldBorderOrSpecialEffect	-- called by BannerSetSpecialEffects
BannerSetSpecialEffectsStructure - sets up the special-effects structure
BannerSetFont			-- controller sends out font-change message

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	10/10/90	Initial version, cut from banner.asm
	stevey	10/5/92		port to 2.0

DESCRIPTION:
	This file contains the code to handle banner's ui.  It is included
	by banner.asm.

	$Id: bannerUI.asm,v 1.1 97/04/04 14:37:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets text style & updates the preview. 

CALLED BY:	MSG_VIS_TEXT_SET_TEXT_STYLE  (from TextStyleControl)

PASS:		ds:di = instance data
		ss:bp = VisTextSetTextStyleParams:

VisTextSetTextStyleParams	struct
    VTSTSP_range		VisTextRange
    VTSTSP_styleBitsToSet	word	;TextStyle (can ignore high byte)
    VTSTSP_styleBitsToClear	word	;TextStyle (can ignore high byte)
    VTSTSP_extendedBitsToSet	word	;VisTextExtendedStyles
    VTSTSP_extendedBitsToClear	word	;VisTextExtendedStyles
VisTextSetTextStyleParams	ends

RETURN:		nothing

DESTROYED:	ax, cx, dx
		bp - unchanged

REGISTER/STACK USAGE

PSEUDO CODE/STRATEGY:

	- set flag to indicate the banner has changed
	- update the effects structure
	- update the BannerTextEdit
	- update the banner

	This routine didn't exist in the 1.2 version, more or less.
	I added a style controller, and so we have to do things a
	bit differently.  What we do is this:  in this routine, we
	set up a TextStyle structure in cl that has all the correct
	bits set (and cleared) before we call BannerSetSpecialEffects.
	Roger used to do something similar to what he did with the
	border and effects 'controllers', where he'd just pass along
	whatever the menu sent and deal with it in his
	BannerSetSpecialEffectsStructure.  I've changed that routine
	so that it just takes whatever's in cl and moves it directly
	into the low byte of BI_specialEffects.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Look at OLPaneSendNotification for an example of what I'm 
	doing. (steve)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	7/90		Initial version
	roger	10/11/90	added none options
	stevey	10/5/92		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetTextStyle	method dynamic BannerClass,
					MSG_VIS_TEXT_SET_TEXT_STYLE
	;
	;  update BannerTextEdit
	;

	push	ds:[LMBH_handle], si, bp	; save instance data & style
	GetResourceHandleNS	BannerTextEdit, bx
	mov	si, offset	BannerTextEdit
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	call	ObjMessage
	pop	bx, si, bp

	call	MemDerefDS
	mov	di, ds:[si]
	add	di, ds:[di].Banner_offset

	;
	; Notify the controller of the new UI change.  First we make
	; a block containing a NotifyTextStyleChange structure with
	; the appropriate bits set.  Then we give it in initial
	; reference count of 1. 
	;
	
	mov	dl, ds:[di].BI_specialEffects.low	; old TextStyle
	ornf	dl, ss:[bp].VTSTSP_styleBitsToSet.low
	mov	al, ss:[bp].VTSTSP_styleBitsToClear.low ; mask for bits to clear
	not	al					; keep all other bits
	andnf	dl, al					; nuke bits-to-clear
	push	bx, si, bp			; save instance & style again

	;
	;  Make the data block
	;

	mov	ax, size NotifyTextStyleChange
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	LONG	jc	errorPop3
	mov	ds, ax

	;
	;  initialize the NotifyTextStyleChange structure, unlock
	;  the block and initialize the RefCount to 1 (it was zero
	;  when we alloc'd the block)
	;

	mov	ds:[NTSC_styles], dl		; new TextStyle
	clr	ds:[NTSC_indeterminates]	; not applicable

	call	MemUnlock
	
	mov	ax, 1
	call	MemInitRefCount			; initialize reference count
	mov	bp, bx				; bp <- handle to block

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

	segmov	ds, es				; ds has to be an object block
	call	UserCallApplication

	add	sp, size GCNListMessageParams

	pop	bx, si, bp				; restore passed stuff
	call	MemDerefDS

	;
	;  update cx for call to BannerSetSpecialEffectsStructure
	;

	mov	di, ds:[si]
	add	di, ds:[di].Banner_offset		; banner instance data

	;
	;  Here we do the same functionality as BannerSetSpecialEffects,
	;  except we're changing the text style instead of a border or
	;  special effect.
	;

	clr	ds:[di].BI_lastMaximizedHeight		; recalc height

	mov	cx, ds:[di].BI_specialEffects
	ornf	cl, ss:[bp].VTSTSP_styleBitsToSet.low
	mov	al, ss:[bp].VTSTSP_styleBitsToClear.low ; mask for bits to clear
	not	al					; keep all other bits
	andnf	cl, al					; nuke bits-to-clear

	call	BannerSetSpecialEffectsStructure

	BitSet	ds:[di].BI_bannerState, BS_CONTROLS_DIRTY

	mov	bl, UPDATE_NOW
	call	BannerUpdate

	jmp	short	done

errorPop3:
	add	sp, 6					; restore sp
done:
	ret
BannerSetTextStyle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetSpecialEffects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This either sets or unsets special effects by modifying
		the appropiate bit in bannerSpecialEffect and then updates
		the preview.

CALLED BY:	MSG_BANNER_SET_SPECIAL_EFFECT

PASS:		ds:di	= BannerClass instance data
		cx = SpecialEffects

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- set flag to indicate the banner has changed
	- update the effects structure
	- update the banner

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetSpecialEffects	method  BannerClass, 
					MSG_BANNER_SET_SPECIAL_EFFECT
	uses	ax, cx, dx, bp
	.enter

	;
	; Notify BannerMaximizeTextHeight that things have changed.
	;

	clr	ds:[di].BI_lastMaximizedHeight

	call	GetOldBorderOrSpecialEffect

	call	BannerSetSpecialEffectsStructure

	BitSet	ds:[di].BI_bannerState, BS_CONTROLS_DIRTY

	mov	bl, UPDATE_NOW
	call	BannerUpdate

	.leave
	ret
BannerSetSpecialEffects	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOldBorderOrSpecialEffect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets up cx correctly for BannerSetSpecialEffectsStructure

CALLED BY:	BannerSetSpecialEffects

PASS:		ds:di = banner special effects structure
		cx = new special effect or border

RETURN:		cx = new special effect and old border, or
		     new border and old special effect

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- just move the current text style into cl

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/3/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOldBorderOrSpecialEffect	proc	near
	class	BannerClass
	uses	ax
	.enter

	mov	cl, ds:[di].BI_specialEffects.low

	;
	;  Check to see if any border bits are set
	;

	test	cx, (mask SE_THIN_BOX or mask SE_THICK_BOX or \
			mask SE_DOUBLE_BOX)
	jz	notBorder

	;
	;  We're setting a new border style.  Get the old special-
	;  effect into cx without killing the new border.
	;

	mov	ax, ds:[di].BI_specialEffects
	and	ax, (mask SE_SMALL_SHADOW or mask SE_LARGE_SHADOW or \
			mask SE_THREE_D or mask SE_FOG)
	ornf	ch, ah
	jmp	short	done

notBorder:
	;
	;  Check to see if any special effects bits are set
	;

	test	cx, (mask SE_SMALL_SHADOW or mask SE_LARGE_SHADOW or \
			mask SE_THREE_D or mask SE_FOG)
	jz	done

	;
	;  We're setting a new special effect.  Get the old border
	;  into cx without killing the new special effect.
	;

	mov	ax, ds:[di].BI_specialEffects
	and	ax, (mask SE_THIN_BOX or mask SE_THICK_BOX or \
			mask SE_DOUBLE_BOX)	; isolates old border bit
	ornf	ch, ah				; set that baby
	jmp	short	done

done:
	.leave
	ret
GetOldBorderOrSpecialEffect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		   BannerSetSpecialEffectsStructure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the appropriate bits in the Special Effects structure.
		Basically takes care of SE_NO_EFFECT and SE_NO_BORDER.

CALLED BY:	BannerSetSpecialEffects, BannerSetTextStyle

PASS:		ds:di	- Banner instance data
		cx = SpecialEffects

RETURN:		nothing
DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine gets called when the user changes the border,
	special effect, or text style.

PSEUDO CODE/STRATEGY:

	- if we're passed SE_NO_EFFECT clear all effects
	- if we're passed SE_NO_BORDER clear all borders
	- if ch is clear (meaning we're supposed to be setting a TextStyle
	  and not a border or effect), move the contents of cl into
	  BI_specialEffects.low, and bail
	- if ch has something in it, logical-or it with BI_specialEffects

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/3/91		Initial version
	stevey	10/5/92		Port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetSpecialEffectsStructure	proc	near
	class	BannerClass
	.enter

	;
	;  SE_NO_EFFECT -- clear all the other effects bits.  This is easier
	;  than figuring out which effect was selected before and clearing it.
	;

	mov	ax, cx
	and	ax, SE_NO_EFFECT
	cmp	ax, SE_NO_EFFECT
	jne	notNoEffect

	;
	; clear the effects bits
	;
	andnf	ds:[di].BI_specialEffects, not \
		(mask SE_SMALL_SHADOW or mask SE_LARGE_SHADOW \
		or mask SE_THREE_D or mask SE_FOG)
	jmp	short done

notNoEffect:
	;
	;  SE_NO_BORDER -- clear all the other borders.  This is easier than
	;  figuring out which border was selected before and clearing it.
	;

	mov	ax, cx
	and	ax, SE_NO_BORDER
	cmp	ax, SE_NO_BORDER
	jne	notNoBorder		; we weren't passed SE_NO_BORDER

	;
	; clear all the border bits
	;
	andnf	ds:[di].BI_specialEffects, not \
		(mask SE_THIN_BOX or mask SE_THICK_BOX or mask SE_DOUBLE_BOX)
	jmp	short done

notNoBorder:

	mov	ds:[di].BI_specialEffects, cx

done:
	.leave
	ret
BannerSetSpecialEffectsStructure	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This sets the BannerTextEdit's font and stores the fontID in 
	       	the banner's instance data.  It also updates the banner
		preview.

CALLED BY:	MSG_VIS_TEXT_SET_FONT_ID

PASS:		*ds:si	= BannerClass object
		ds:di	= BannerClass instance data
		ss:bp 	= VisTextSetFontIDParams structure

RETURN:		nothing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

	When we set the font of the BannerTextEdit object, we must pass:
		ss:bp   = VisTextSetFontIDParams	struct
		 	    VTSFIDP_range	VisTextRange
			    VTSFIDP_fontID	FontID		
			  VisTextSetFontIDParams	ends
	We set the font of the text object first, because the
	update of the preview area can take a relatively long time.

	Look at BannerSetTextStyle for more details.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerSetFont	method dynamic BannerClass, 
				MSG_VIS_TEXT_SET_FONT_ID
	uses	bp
	.enter

	;
        ;  This notifies BannerMaximizeTextHeight that things have changed.
	;

	clr	ds:[di].BI_lastMaximizedHeight

	;
	; save the banner's fontID
	;
	
	mov	ax, ss:[bp].VTSFIDP_fontID
	mov	ds:[di].BI_fontID, ax
	ornf	ds:[di].BI_bannerState, mask BS_TEXT_DIRTY

	;
	;  Set the font of the BannerTextEdit
	;

	push	ds:[LMBH_handle], si, bp

	GetResourceHandleNS	BannerTextEdit, bx
	mov	si, offset	BannerTextEdit
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bx, si, bp
	call	MemDerefDS
	mov	di, ds:[si]
	add	di, ds:[di].Banner_offset

	;
	;  Notify the controller of the new UI change.  First we make
	;  a block containing a NotifyFontChange structure with
	;  the appropriate bits set.  Then we give it in initial
	;  reference count of 1. 
	;
	
	mov	dx, ss:[bp].VTSFIDP_fontID	; new font
	push	bx, si, bp			; save instance & stuff again

	;
	;  Make the data block
	;

	mov	ax, size NotifyFontChange
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	LONG	jc	errorPop3
	mov	ds, ax

	;
	;  Initialize the NotifyFontChange structure, unlock
	;  the block and initialize the RefCount to 1 (it was zero
	;  when we alloc'd the block)
	;

	mov	ds:[NFC_fontID], dx
	clr	ds:[NFC_diffs]		; not applicable

	call	MemUnlock
	
	mov	ax, 1
	call	MemInitRefCount			; initialize reference count
	mov	bp, bx				; bp <- handle to block

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

	segmov	ds, es				; ds has to be an object block
	call	UserCallApplication

	add	sp, size GCNListMessageParams

	pop	bx, si, bp
	call	MemDerefDS			; *ds:si = banner

	;
	;  Now update the banner
	;

	mov	bl, UPDATE_NOW
	call	BannerUpdate

	jmp	short	done

errorPop3:
	add	sp, 6
done:
	.leave
	ret
BannerSetFont	endm
