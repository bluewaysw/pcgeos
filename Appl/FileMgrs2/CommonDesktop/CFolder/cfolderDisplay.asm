COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		folderDisplay.asm
AUTHOR:		Brian Chin

ROUTINES:
	INT	DrawFolderObjectIcon - draw one object in folder window
	INT	DrawFullFileDetail - draw long version of file info
	INT	BuldDisplayList - build list of files to be displayed
	INT	SortFolderBuffer - sort files in folder buffer
	INT	CompareSortFields - compare two entries in folder buffer
	INT	BuildListPass - low-level routine to build display list
	INT	CheckFileInList - check if file should be in display list
	INT	CheckFileTypes - check file types to be included in display list
	INT	CheckFileAttrs - check file attributes to be included
	INT	PrintFolderInfoString - print folder size information
	INT	BuildBoundsFolderObjectIcon - build display bounds of
					      one object in folder window 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file contains routines to display the contents of a folder object.

	$Id: cfolderDisplay.asm,v 1.3 98/06/03 13:32:36 joon Exp $

------------------------------------------------------------------------------@

FolderCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFolderObjectIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draws the icon/name for a folder object

CALLED BY:	INTERNAL
			FolderDraw

PASS:		es:di - pointer to entry in folder buffer for this object
		*ds:si - FolderClass object
		bp - gState to draw with
			(font and pt-size set correctly)
		ax =	mask DFI_CLEAR to clear
			mask DFI_DRAW to draw
			mask DFI_INVERT to invert (to show selection)
			mask DFI_GREY to grey (to show file operation progress)
		legal modes:
			cannot have both DRAW and INVERT

RETURN:		cx, dx, ds, es, si, bp, di unchanged

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFolderObjectIcon	proc	far
	class	FolderClass

	uses	si, cx, dx

	.enter

EC <	test	ax, not DrawFolderObjectIconFlags			>
EC <	ERROR_NZ	BAD_DRAW_FOLDER_OBJECT_ICON_FLAGS		>
EC <	test	ax, mask DFI_DRAW					>
EC <	jz	good							>
EC <	test	ax, mask DFI_INVERT					>
EC <	ERROR_NZ	BAD_DRAW_FOLDER_OBJECT_ICON_FLAGS		>
EC <good:								>

	test	ax, mask DFI_GREY		; greying?
	jz	5$				; no
						; else, clear and draw first
	ornf	ax, mask DFI_CLEAR or mask DFI_DRAW
5$:

	DerefFolderObject	ds, si, bx

	xchg	di, bp				; di = gState, bp = entry
	mov	dh, ds:[bx].FOI_displayMode	; load up for DrawIconModeIcon

	test	ax, mask DFI_CLEAR		; clearing?
	jz	afterClear			; no
if _NEWDESK
	call	CheckBWOrTextModes		; don't clear if color icons
	jnz	afterClear
endif
	call	ClearFolderObjectIcon		; else, clear file
afterClear:
	test	ax, mask DFI_DRAW		; drawing?
	jz	afterDraw			; no

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------

	call	CheckBWOrTextModes
	je	normalDraw
	;
	; color icon mode, special draw/invert handling
	;
	test	ds:[bx].FOI_folderState, mask FOS_TARGET ; target?
	jz	noColorIconDraw			; no, can't invert
	test	es:[bp].FR_state, mask FRSF_SELECTED
	jnz	colorIconDraw
noColorIconDraw:
	call	DrawFolderObjectIconLow		; else, draw file
	jmp	short afterInvert		; branch back into place

colorIconDraw:
	call	InvertColorIconFolderObject	; draw and invert
	jmp	short afterInvert		; branch back into place

normalDraw:
	;
	; mono or text mode, normal draw/invert handling
	;

endif	;--------------------------------------------------------------------

	call	DrawFolderObjectIconLow		; else, draw file
	jnz	invert				; Z clear if inversion needed

afterDraw:
	test	ax, mask DFI_INVERT		; inverting?
	jz	afterInvert			; no

invert:
	test	ds:[bx].FOI_folderState, mask FOS_TARGET ; target?
	jz	afterInvert			; no, can't invert

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------

	call	InvertPreserveColor		; else, invert file

else	;---------------------------------------------------------------------

	call	InvertFolderObjectIcon		; else, invert file

endif	;---------------------------------------------------------------------

afterInvert:
	test	ax, mask DFI_GREY		; greying?
	jz	afterGrey			; no
	call	GreyFolderObjectIcon		; else, grey out file

afterGrey:
	xchg	di, bp				; di = entry, bp = gState

	.leave
	ret
DrawFolderObjectIcon	endp

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------

InvertPreserveColor	proc	near
	class	FolderClass

	call	CheckBWOrTextModes
	je	normalInvert
	;
	; color icon mode, special invert handling
	;
	call	InvertColorIconFolderObject	; draw and invert
	jmp	short done

normalInvert:
	call	InvertFolderObjectIcon		; else, invert file

done:
	ret
InvertPreserveColor	endp

;
; pass:		*ds:si = FolderInstance
; return:	Z set if b/w or text modes
;
CheckBWOrTextModes	proc	near
	class	FolderClass

	uses	bx, cx
	.enter
	;
	; if mono or text mode, do normal draw/invert handling
	; if color icon mode, do special draw/invert handling
	;
	mov	cl, ss:[desktopDisplayType]
	andnf	cl, mask DT_DISP_CLASS
	cmp	cl, DC_GRAY_1 shl offset DT_DISP_CLASS
	je	done
	DerefFolderObject	ds, si, bx
	test	ds:[bx].FOI_displayMode, mask FIDM_LICON or mask FIDM_SICON
done:
	.leave
	ret				; Z set if text modes
CheckBWOrTextModes	endp

endif	;---------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFolderObjectIconLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to actually do the drawing

CALLED BY:	DrawFolderObjectIcon

PASS:		es:bp - FolderRecord 
		*ds:si - FolderClass object 
		di - gstate handle

RETURN:		ZERO FLAG CLEAR - if we should invert the current
		file. 

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFolderObjectIconLow	proc 	near
		class	FolderClass
		uses	ax, bx
		.enter
		
if OPEN_CLOSE_NOTIFICATION
		
		test	es:[bp].FR_state, mask FRSF_OPENED
		jz	afterPattern
		
		call	DrawOpenPattern
afterPattern:
endif
		
		xchg	di, bp			; Always determine the token
		call	InitFileHeaderToken	;  for the thing, since we may
		xchg	di, bp			;  need the creator token later

	;
	; Get the display mode & decide whether to draw the icon, or
	; just name & details.
	;
		
		DerefFolderObject	ds, si, bx
		mov	dh, ds:[bx].FOI_displayMode	; dh = display mode
		test	dh, mask FIDM_FULL		
		jnz	fullFileDetails			

	;
	; It's names only or icon mode -- so draw the name first.
	; DrawFolderObjectName returns the name vertical position in
	; BX, which trashes the instance data ptr, so preserve it...
	;
		
		push	bx
		call	DrawFolderObjectName		
		pop	bx

drawIcon:
		mov	dl, ds:[bx].FOI_displayType	
		call	DrawIconModeIcon		
		jmp	selectTest			

fullFileDetails:
		push	bx			; save FOI_
		call	DrawFullFileDetail
		pop	bx			; ds:bx = FOI_
		jmp	short drawIcon
selectTest:

	;
	; See if this object is selected, and if so, return Z clear
	;
		
		test	es:[bp].FR_state, mask FRSF_SELECTED
		.leave
		ret
		
DrawFolderObjectIconLow	endp

if OPEN_CLOSE_NOTIFICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOpenPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a pattern to show that this file is open

CALLED BY:	DrawFolderObjectIconLow

PASS:		*ds:si - FolderInstance
		es:bp - FolderRecord 
		di - gstate handle

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

	Rectangle is (boundBox.top, boundBox.left, boundBox.right,
		      iconBounds.bottom) 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOpenPattern	proc near
	.enter

	mov	al, MM_COPY
	call	GrSetMixMode

	mov	ax, SDM_DIAG_NE
	call	GrSetAreaMask

	mov	ax, C_BLACK or (CF_INDEX shl 8)

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------
	call	CheckBWOrTextModes
	je	haveColor			; if b/w or text, use black
	test	es:[bp].FR_state, mask FRSF_SELECTED
	jz	haveColor			; if not selected, use black
	mov	ax, C_WHITE or (CF_INDEX shl 8)	; else is selected, use white
haveColor:
endif	;---------------------------------------------------------------------

	call	GrSetAreaColor

	call	RectFolderObjectIconIconBox

	mov	ax, SDM_100
	call	GrSetAreaMask

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------
	;
	; in case we set it to C_WHITE
	;
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
endif	;---------------------------------------------------------------------

	.leave
	ret
DrawOpenPattern	endp

endif	; OPEN_CLOSE_NOTIFICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFolderObjectName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw name, clipping if needed

CALLED BY:	INTERNAL
			DrawFolderObjectIconLow

PASS:		*ds:si - FolderClass object 
		es:bp = file entry in folder buffer
		di = gstate

RETURN:		bx - vertical position of name

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFolderObjectName	proc	near
		class	FolderClass
		
		uses	ds, si, dx, bp
		
		.enter

if ICON_INVERT_MASK
		test	ss:[desktopFeatures], mask DF_SHOW_LINKS
		jz	notLink
		test	es:[bp].FR_fileAttrs, mask FA_LINK
		jz	notLink
		mov	ax, C_BLUE
		call	checkLightColor
		jc	haveColor
		mov	ax, C_LIGHT_BLUE
		jmp	short haveColor
notLink:
		mov	ax, C_BLACK
		call	checkLightColor
		jc	haveColor
		mov	ax, C_WHITE
haveColor:
		call	GrSetTextColor
else
		test	ss:[desktopFeatures], mask DF_SHOW_LINKS
		jz	afterColor
		test	es:[bp].FR_fileAttrs, mask FA_LINK
		jz	afterColor
		mov	ax, C_BLUE
		call	GrSetTextColor
afterColor:
endif

		test	ss:[desktopFeatures], mask DF_SHOW_REMOTE
		jz	textStyleSet
		test	es:[bp].FR_pathInfo, mask DPI_ENTRY_NUMBER_IN_PATH
		jz	textStyleSet
		mov	ax, mask TS_UNDERLINE		; set underline
		call	GrSetTextStyle

textStyleSet:
	; di = GState handle
		
		call	FolderSetBackgroundFillPattern
		jc	skipFill
		
		call	RectFolderObjectIconNameBox	; wash out name area
		
		mov	ax, C_BLACK or (CF_INDEX shl 8)
		call	GrSetAreaColor
skipFill:
	;
	; Load the name bounds in case we skipped the fill
	;
		call	LoadNameBounds		
if ICON_INVERT_MASK
		add	ax, ICON_BOX_X_MARGIN
endif
	;
	; set up correct values for file drawing box width and box height
	;
		call	SetFileBoxWidthHeight
	;
	; Based on the display mode, fetch the proper max width
	;
		push	bx
		DerefFolderObject	ds, si, bx
		mov	cl, ds:[bx].FOI_displayMode	; cl = display mode
		pop	bx
		
		mov	dx, ss:[largeIconBoxWidth]
		test	cl, mask FIDM_LICON	
		jnz	gotMaxWidth

		mov	dx, ss:[shortTextBoxWidth]
		sub	dx, TEXT_ICON_WIDTH + TEXT_ICON_HORIZ_SPACING
		test	cl, mask FIDM_SHORT
		jnz	gotMaxWidth

		mov	dx, ss:[longTextNameWidth]
if GPC_NAMES_AND_DETAILS_TITLES
	;
	; adjust for the icon
	;
		sub	dx, TEXT_ICON_WIDTH + TEXT_ICON_HORIZ_SPACING + 1
endif
		test	cl, mask FIDM_FULL
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
		jz	notFull
		test	cl, mask FIDM_FULL_DATES
		jnz	gotMaxWidth
		mov	dx, ZMGR_FULL_DATES_RIGHT_BOUND	; dx = right bound
		sub	dx, ax				; dx = max area width
		sub	dx, ss:[widestFileSize]		; dx = max name width
		jmp	short gotMaxWidth

notFull:
else
		jnz	gotMaxWidth
endif
		
		mov	dx, ss:[smallIconBoxWidth]
		sub	dx, SMALL_ICON_WIDTH + SMALL_ICON_HORIZ_SPACING
EC <		test	cl, mask FIDM_SICON		>
EC <		ERROR_Z	DESKTOP_FATAL_ERROR				>
gotMaxWidth:
		
		mov	cx, dx				; max width
		call	GetFolderObjectName		; ds:si = filename

if WRAP
		test	es:[bp].FR_state, mask FRSF_WORD_WRAP
		jz	dontWrap
		call	WordWrapFilename
		jmp	afterName
dontWrap:
		
endif
		mov	dx, es:[bp].FR_nameWidth
		call	DrawFilenameAndClipIfNecessary

afterName::
		mov	ax, (mask TS_UNDERLINE) shl 8 	; clear underline
		call	GrSetTextStyle

		test	ss:[desktopFeatures], mask DF_SHOW_LINKS
		jz	done
		mov	ax, C_BLACK
		call	GrSetTextColor
done:
		.leave
		ret

if ICON_INVERT_MASK
checkLightColor	label	near
		push	ax, bx, si
		mov	si, WIT_COLOR
		call	WinGetInfo
		test	ah, mask WCF_RGB
		jnz	haveRGB
	;
	; if an index color, map to RGB and fall through
	;
haveIndex::
		push	di
		clr	di			;di <- default mapping
		mov_tr	ah, al			;ah <- index color
		call	GrMapColorIndex
		pop	di
	;
	; magic formula for RGB: 2*R + 4*G + 1*B > (7/2)*255 is light
	; (al = R, bl = G, bh = B)
	;
haveRGB:
		clr	ah
		shl	al, 1			; ax = 2R
		add	al, bh
		adc	ah, 0			; ax = 2R + B
		clr	bh
		shl	bx, 2			; bx = 4G
		add	ax, bx			; ax = 2R + B + 4G
		mov	bx, (255*7)/2
		sub	bx, ax			; C set if > (255*7)/2
haveLightColor:
		pop	ax, bx, si
		retn
endif
DrawFolderObjectName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFilenameAndClipIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the filename, making sure to clip if it's longer
		than it should be.

CALLED BY:	DrawFolderObjectName, WordWrapFilename

PASS:		ds:si - name
		cx - maximum width
		dx - width of name
		(ax, bx) - position at which to draw
		di - gstate handle

RETURN:		bx - vertical position of name 

DESTROYED:	ax,cx,dx,si,di,ds,bp 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFilenameAndClipIfNecessary	proc near


		.enter

	;
	; Skip leading spaces
	;
		call	FolderNameSkipLeadingSpace
	;
	; if the filename is less than the max allowed, then no need
	; to clip
	;
		cmp	cx, dx
		jge	wideEnough

		mov	bp, cx				; bp = max width
		sub	bp, ss:[ellipsesWidth]		; bp = max. name width
		clr	cx
	;
 	; We're not doing word wrap, so draw as many characters on this
	; line as we can, and then truncate and draw ellipses
	; (ax, bx) = position to draw

fitLoop:

	;
	; Keep increasing the number of chars until we run out of room...
	;
		
		inc	cx
EC <		cmp	cx, size FileLongName				>
EC <		ERROR_A	DESKTOP_FATAL_ERROR				>
		call	GrTextWidth			; dx = width
							; of this part
		cmp	dx, bp				
		jbe	fitLoop				

	;
	; We've run out of room.  Remove the last character, and draw
	; the name with the ellipses
	;
		dec	cx		
		call	GrDrawText
NOFXIP<		segmov	ds, cs, si					>
FXIP <		mov	si, bx						>
FXIP <		GetResourceSegmentNS dgroup, ds, TRASH_BX		>
FXIP <		mov	bx, si						>
		mov	si, offset ellipsesString	; ds:si = "..."
		mov	cx, length ellipsesString
		call	GrDrawTextAtCP
		jmp	done

wideEnough:
		mov	cx, FILE_LONGNAME_LENGTH
		call	GrDrawText			; draw name
done:
		
		.leave
		ret
DrawFilenameAndClipIfNecessary	endp

if _FXIP
idata	segment
endif

LocalDefNLString ellipsesString <"...">

if _FXIP
idata	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderNameSkipLeadingSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the first character in the passed string is a space
		character, then skip it.

CALLED BY:	DrawFilenameAndClipIfNecessary, FolderGetTextWidth

PASS:		ds:si - filename (or a portion thereof)

RETURN:		ds:si - points to filename AFTER leading blanks

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderNameSkipLeadingSpace	proc near
		uses	ax
		.enter
		
SBCS <		clr	ah						>
		LocalGetChar	ax, dssi, noAdvance
		LocalIsNull	ax
		jz	done
		call	LocalIsSpace
		jz	done

		LocalNextChar	dssi
		
done:
		
		.leave
		ret
FolderNameSkipLeadingSpace	endp



if WRAP

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WordWrapFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the filename on two lines

CALLED BY:	DrawFolderObjectName

PASS:		es:bp - FolderRecord
		ds = es
		si = bp
		bx - vertical position at which to draw
		di - gstate handle
		cx - max width

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WordWrapFilename	proc near
		uses	ax,bx,cx,dx,di,si
		.enter

	;
	; First, draw line 1.  We know for certain that no clipping is
	; necessary, so...
	;

		push	cx			; max width
		mov	ax, es:[bp].FR_line1Pos
		mov	cx, es:[bp].FR_line1NumChars
		call	FolderNameSkipLeadingSpace
		call	GrDrawText
		
	;
	; Now, draw the remainder, clipping rather than going to
	; a third line.
	;

		add	si, es:[bp].FR_line1NumChars
DBCS <		add	si, es:[bp].FR_line1NumChars			>
		clr	cx
		call	FolderGetTextWidth
		add	bx, ss:[desktopFontHeight]
		mov	ax, es:[bp].FR_line2Pos
		
		pop	cx			; max allowed width
		call	DrawFilenameAndClipIfNecessary

		.leave
		ret
WordWrapFilename	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawIconModeIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	special routine to draw icon from token database

CALLED BY:	INTERNAL
			DrawFolderObjectIconLow

PASS:		es:bp - entry for this file in folder buffer
		*ds:si - FolderClass object 
		dl - DisplayType for this Folder Window
		dh - display mode for this Folder Window
			(FIDM_LICON or FIDM_SICON)
GPC_* <			(also FIDM_SHORT or FIDM_FULL)			>
		di - GState to draw with

RETURN:		icon drawn

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/21/89	Initial version
	dlitwin	7/28/94		Removed token item and group # caching

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawIconModeIcon	proc	near
	uses	bx, bp

	mov	ax, bp			; preserve entry offset

gState		local	word	push	di	; save gState for later
displayType	local	byte
displayMode	local	byte

	.enter

	ForceRef	gState
	mov	di, ax				; es:di = entry
	mov	displayType, dl			; save DisplayType for later
	mov	displayMode, dh			; save display mode for later


;
; Special template drawing disabled -3/93
;	test	es:[di].FR_fileFlags, mask GFHF_TEMPLATE
;	jz	drawNormalIcon
;	call	FolderDrawTemplateIcon		; draws background,
;						; and sets small
;drawNormalIcon:				; mode (i.e. use tool icon)...


	;
	; lookup token in token database
	;
	mov	ax, {word}es:[di].FR_token.GT_chars[0]
	tst	al				; null-token, don't bother
	jz	noIcon				;	looking up
	mov	bx, {word}es:[di].FR_token.GT_chars[2]

	ornf	es:[di].FR_state, cx		; flag lookup attempt

	xchg	dh, dl				; dh = DisplayType
	push	si
	mov	si, es:[di].FR_token.GT_manufID
if _NEWDESK
	cmp	ax, 'nd'
	jne	haveToken
	cmp	bx, 'WB'
	jne	haveToken
	cmp	si, MANUFACTURER_ID_GEOWORKS
	jne	haveToken
	cmp	ss:[wastebasketEmpty], BB_TRUE
	je	haveToken
	mov	bx, 'WF'		; use full wastebasket icon
haveToken:
endif
tokenCommon::
	call	FolderTokenLookupMoniker	; cx:dx = moniker ID
	pop	si				; ax <- shared/local
						;  token DB file flag
	jnc	lookupGood			; if found, check for gstring

	;
	; lookup failed, if GEOS file, try calling application to install
	; its token; if non-GEOS file, use default icon
	;
noIcon:
	test	es:[di].FR_geodeAttrs, mask GA_APPLICATION
	jz	useDefaultIcon			; not app, so use default
if _WRITABLE_TOKEN_DATABASE
	call	CallApplToGetMoniker		; attempt launching appl to
						;	install moniker list
else
	stc
endif
	jc	useDefaultIcon			; if not possible, use default

	;
	; token installation SEEMS successful, try to lookup moniker again
	;	ax:bx:si = GeodeToken
	;
	mov	dh, displayType
	mov	dl, displayMode
	push	si
	mov	si, es:[di].FR_token.GT_manufID
	call	FolderTokenLookupMoniker
	pop	si
	jc	useDefaultIcon			; use default if we fail


	;
	; lookup successful, save icon for next time
	; first check if moniker found is really a gstring, if not use defaults
	;
lookupGood:
	push	ds, si
	call	TokenLockTokenMoniker		; ds:*bx = moniker
	mov	si, ds:[bx]			; deref. moniker

	push	ds:[si].VM_width
	test	ds:[si].VM_type, mask VMT_GSTRING
	pushf
	call	TokenUnlockTokenMoniker
	popf
	pop	bx				; bx <- moniker width
	pop	ds, si
	jz	useDefaultIcon			; not gstring, use default icon

	test	displayMode, mask FIDM_LICON		; large icon mode?
	jnz	confirmIconIsLarge
	cmp	bx, SMALL_ICON_WIDTH
	jg	noIcon
	jmp	drawIcon

confirmIconIsLarge:
	cmp	bx, SMALL_ICON_WIDTH
	jg	drawIcon

	;
	; if the default fails, skip drawing in non-ec
	;
useDefaultIcon:
	mov	dl, displayMode
	mov	dh, displayType
	call	FolderGetDefaultIcon
	jc	errExit

drawIcon:
	call	DrawIconModeIconLow

exit:
	.leave
	ret

errExit:
	mov	di, gState
	jmp	short exit
DrawIconModeIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetDefaultIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	low level routine to draw icon from token database

CALLED BY:	INTERNAL -
			DrawIconModeIcon

PASS:		es:[di]	- FolderRecord of file to draw
GPC <		dl - FIDM_					>
RETURN:		carry	- set on error
			- clear for success
				cx = default group of icon
				dx = default item of icon
				ax = shared/local token DB file flag
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/27/94		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetDefaultIcon	proc	near
	uses	si
	.enter

	;
	; All of the default tokens have the Geoworks Manufacturers ID
	;
	mov	si, MANUFACTURER_ID_GEOWORKS

	;
	; assume a default DOS document
	;
	movdw	bxax, cs:[defaultDOSDataIconChars]
	cmp	es:[di].FR_fileType, GFT_NOT_GEOS_FILE
	je	gotChars

	;
	; its a GEOS file, assume data
	;
	movdw	bxax, cs:[defaultGEOSDataIconChars]
	cmp	es:[di].FR_fileType, GFT_EXECUTABLE
	jne	gotChars

	movdw	bxax, cs:[defaultGEOSApplIconChars]

	;
	; if looking up the token fails, error in EC.  I'm using the
	; CANT_FIND_FILE_MONIKER because it exists.  Maybe its not
	; exactly the 'file' moniker that couldn't be found, but hey,
	; close enough.
	;
gotChars:
	push	dx				; save display mode (dl)
	call	FolderTokenLookupMoniker
	pop	bx				; bl = display mode
	jc	gotIconResult
	test	bl, mask FIDM_LICON		; large icon mode?
	pushf
	push	ds, si
	call	TokenLockTokenMoniker
	mov	si, ds:[bx]
	mov	bx, ds:[si].VM_width
	call	TokenUnlockTokenMoniker
	pop	ds, si
	popf
	jnz	confirmIconIsLarge
	cmp	bx, SMALL_ICON_WIDTH
	jbe	goodIcon
badIcon:
	stc
	jmp	gotIconResult

confirmIconIsLarge:
	cmp	bx, SMALL_ICON_WIDTH
	jbe	badIcon
goodIcon:
	clc
gotIconResult:

	.leave
	ret
FolderGetDefaultIcon	endp

if 1 ;_NEWDESK
defaultDOSDataIconChars		dword	"nDOS"
defaultGEOSDataIconChars	dword	"nDAT"
defaultGEOSApplIconChars	dword	"nAPP"
else
defaultDOSDataIconChars		dword	"gDOS"
defaultGEOSDataIconChars	dword	"gDAT"
defaultGEOSApplIconChars	dword	"gAPP"
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawIconModeIconLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	low level routine to draw icon from token database

CALLED BY:	INTERNAL
			DrawFolderObjectIcon

PASS:		ax	= shared/local token DB file flag
		cx:dx 	= group/item of a specific moniker
		es:di 	= entry for this file in folder buffer
		ss:bp	= stack frame inherited from DrawIconModeLow

RETURN:		di 	= gState
		icon drawn

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/3/92		pulled out of DrawIconModeIcon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawIconModeIconLow	proc	near
	
	uses	ds, si
	.enter	inherit	DrawIconModeIcon

	;
	; draw icon
	;
	push	ax				; save shared/local
						;  token db flag
	call	TokenLockTokenMoniker		; ds:bx = seg:chunk of moniker
	mov	si, ds:[bx]			; ds:si = moniker

EC <	test	ds:[si].VM_type, mask VMT_GSTRING	; gstring?	>
EC <	jz	notIconic						>
	;
	; figure out where to put the icon within the icon box
	;	relevant if moniker is sized bogus-ly
	;
	mov	ax, LARGE_ICON_HEIGHT		; icon box height
	call	FolderCodeCheckIfCGA
	jnc	notCGA
	sub	ax, CGA_ICON_HEIGHT_DIFFERENCE
notCGA:
	; use same spacing for small and large icon modes...
	;
;	test	displayMode, mask FIDM_LICON
;	jnz	55$
;	mov	ax, SMALL_ICON_HEIGHT
;55$:
	test	displayMode, mask FIDM_LICON
	jnz	56$
	mov	ax, TEXT_ICON_HEIGHT
56$:
	sub	ax, ({VisMonikerGString} ds:[si].VM_data).VMGS_height	
						; minus actual icon height
	sar	ax, 1				; divided by two
	tst	ax				; check width adjustment
	jge	goodHeightAdjust		; positive adjustment
	clr	ax				; else, no adjustment
goodHeightAdjust:
	add	ax, es:[di].FR_iconBounds.R_top	; adjust
	mov	bx, ax				; bx = actual icon top
	mov	ax, LARGE_ICON_WIDTH		; icon box width
	test	displayMode, mask FIDM_LICON
	jnz	66$
	mov	ax, TEXT_ICON_HEIGHT


66$:
	sub	ax, ds:[si].VM_width		; minus actual icon width
	sar	ax, 1				; divided by two
	tst	ax				; check width adjustment
	jge	goodWidthAdjust			; positive adjustment
	clr	ax				; else, no adjustment
goodWidthAdjust:
	add	ax, es:[di].FR_iconBounds.R_left	; adjust
						; ax = actual icon left
	mov	di, gState
	add	si, VM_data + VMGS_gstring	; ds:si = GString

	; The following code was changed since the kernel no longer supports
	; GrPlayString.  I've pushed all the registers that get trashed,
	; and this code could probably be optimized by someone who knows 
	; the code  :-)   jim  4/23/92
	;
	push	bx				; save y position
	mov	cl, GST_PTR
	mov	bx, ds				; bx:si -> string
	call	GrLoadGString
	pop	bx
	clr	dx
	call	GrSaveState
	call	GrDrawGString			; draw icon
	call	GrRestoreState
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

EC <notIconic:								>
	pop	ax				; ax <- shared/local
						;  token db flag
	call	TokenUnlockTokenMoniker		; unlock ds block
	.leave
	ret
DrawIconModeIconLow	endp

FolderCodeCheckIfCGA	proc	near
	cmp	ss:[desktopDisplayType], CGA_DISPLAY_TYPE
	stc					; assume CGA
	je	short done			; yes, CGA
	clc					; else, not CGA
done:
	ret
FolderCodeCheckIfCGA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FolderTokenLookupMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up visual flags and calls TokenLookupMoniker.	

CALLED BY:	INTERNAL - 
			DrawIconModeIcon,
			FolderGetObjectIconToken

PASS:		es:di 	= pointer to folder record
		axbxsi	= GeodeToken characters for lookup
		dl	= DisplayMode 
		dh	= DisplayType 

RETURN:		carry clear if token exists in database
			cx:dx - group/item of moniker
			ax - shared/local token DB file flag
		carry set otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/3/92		Pulled out of DrawIconModeIcon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderTokenLookupMoniker	proc	near
	uses	bp
	.enter
	mov     bp, LARGE_ICON_SEARCH_FLAGS	; bp = VisMonikerSearchFlags
	test	dl, mask FIDM_LICON		; large icon mode?
	jnz	10$				; yes
	mov     bp, SMALL_ICON_SEARCH_FLAGS
10$:
	;
	; keep to DS_STANDARD or smaller (i.e. convert DS_HUGE and DS_LARGE
	; into DS_STANDARD)
	;
	mov	cl, dh
	andnf	cl, mask DT_DISP_SIZE		; cl = DisplaySize
	.assert DS_STANDARD gt DS_TINY
	.assert DS_LARGE gt DS_STANDARD
	.assert DS_HUGE gt DS_LARGE
	cmp	cl, DS_STANDARD shl offset DT_DISP_SIZE
	jbe	20$
	andnf	dh, not mask DT_DISP_SIZE	; clear current size
						; set DS_STANDARD
	ornf	dh, DS_STANDARD shl offset DT_DISP_SIZE
20$:
	call	TokenLookupMoniker		; cx:dx = moniker
						; ax <- shared/local
						;  token DB file flag
	.leave
	ret
FolderTokenLookupMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileHeaderToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize token field in file header of file entry

CALLED BY:	INTERNAL
			DrawIconModeIcon

PASS:		es:di - file entry

RETURN:		token field initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The token is only needed if drawing in icon mode, so this
		doesn't need to be called until the file actually needs to
		be drawn.  This saves much time.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileHeaderToken	proc	near
	test	es:[di].FR_state, mask FRSF_HAVE_TOKEN	; already have token?
	jnz	done					; yes
	ornf	es:[di].FR_state, mask FRSF_HAVE_TOKEN	; set state flag

	tst	es:[di].FR_token.GT_chars[0]		; any token?
	jnz	done					; yes, use it

	push	ax, bx, si				; save for exit
	test	es:[di].FR_fileAttrs, mask FA_SUBDIR	; folder?
	jnz	subdir					; if so, handle it

	cmp	es:[di].FR_fileType, GFT_NOT_GEOS_FILE
	je	nonGEOS				; no, check mappings
	;
	; GEOS file has no token, check if executable
	; if so, use 'GAPP' - default token for GEOS appls
	;
	cmp	es:[di].FR_fileType, GFT_EXECUTABLE
	jne	nonGEOSExec			; not exec, do default file
GM <	mov	ax, ('g') or ('A' shl 8)	; store 'gAPP'		>
GM <	mov	bx, ('P') or ('P' shl 8)				>
ND <	mov	ax, ('n') or ('A' shl 8)	; store 'nAPP'		>
ND <	mov	bx, ('P') or ('P' shl 8)				>
	jmp	short storeToken

subdir:
if 0
GM <	mov	ax, ('F') or ('L' shl 8)	; store 'FLDR'		>
GM <	mov	bx, ('D') or ('R' shl 8)				>
ND <	mov	ax, ('n') or ('F' shl 8)	; store 'nFDR'		>
ND <	mov	bx, ('D') or ('R' shl 8)				>
else
	mov	ax, ('n') or ('F' shl 8)	; store 'FLDR'
	mov	bx, ('D') or ('R' shl 8)
endif
	jmp	short storeToken

nonGEOSExec:
GM <	mov	ax, ('g') or ('D' shl 8)	; store 'gDAT'		>
GM <	mov	bx, ('A') or ('T' shl 8)				>
ND <	mov	ax, ('n') or ('D' shl 8)	; store 'nDAT'		>
ND <	mov	bx, ('A') or ('T' shl 8)				>
	jmp	short storeToken

nonGEOS:
	call	CheckNonGEOSTokenMapping
	jnc	gotToken			; found token (ax:bx:si)
	;
	; no token found for non-GEOS file, use default file token
	; also fill in default file monikers
	;
GM <	mov	ax, ('F') or ('I' shl 8)	; default token	'FILE'	>
GM <	mov	bx, ('L') or ('E' shl 8)				>
ND <	mov	ax, ('n') or ('F' shl 8)	; default token 'nFIL'	>
ND <	mov	bx, ('I') or ('L' shl 8)				>
storeToken:
	mov	si, MANUFACTURER_ID_GEOWORKS
gotToken:
	mov	{word}es:[di].FR_token.GT_chars[0], ax
	mov	{word}es:[di].FR_token.GT_chars[2], bx
	mov	es:[di].FR_token.GT_manufID, si
	pop	ax, bx, si

done:
	ret
InitFileHeaderToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNonGEOSTokenMapping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if non-GEOS file has associated token in geos.ini file

CALLED BY:	INTERNAL
			InitFileHeaderToken

PASS:		es:di - file entry in folder buffer

RETURN:		carry clear if token found
			ax:bx:si - token
		carry set if no token

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNonGEOSTokenMapping	proc	near

	uses	cx, dx, ds, es, di, bp

	.enter

		CheckHack <(offset FR_name) eq 0> 	;es:di <- ptr to name
	mov	bx, ss:[filenameTokenMapBuffer]	; lock buffer
	tst	bx
	stc					; in case no buffer
	jz	done
	push	bx
	call	MemLock
	mov	ds, ax				; ds:si = mappings
	clr	si
nextMapping:
	call	GetNextMappingEntry		; mappingField1, mappingField2
	jc	noMore				; if no more, exit with C set
	;
	; compare this entry with filename we want to find token for
	;
	push	ds, si
NOFXIP<	segmov	ds, dgroup, ax						>
FXIP  <	mov	ax, bx							>
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	bx, ax							>
	mov	si, offset dgroup:mappingField1
	call	CheckFilemaskLow		; check for match
	pop	ds, si
	jne	nextMapping
	;
	; found mapping, load up token values
	;
NOFXIP<	segmov	ds, dgroup, ax						>
FXIP  <	mov	ax, bx							>
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	bx, ax							>
	mov	si, offset dgroup:mappingField2
	call	GetTokenFromMapField		; ax:bx:si = token
	; di now points to FR_name.  Set bit in FR_state.
	ornf	es:[di-offset FR_name].FR_state, mask FRSF_DOS_FILE_WITH_TOKEN

	push	ax, bx, si
	mov	si, cx
SBCS <	cmp	{char}ds:[si-1], ','					>
DBCS <	cmp	{wchar}ds:[si-2], ','					>
	jne	foundToken
	call	GetTokenFromMapField
	; di now points to DFIS_name. Adjust it to point to the creator token
	; and store away the individual pieces. GT_chars comes first, then
	; GT_manufID.
		CheckHack <(size GT_chars eq 4) and \
				(offset GT_chars eq 0) and \
				(offset GT_manufID eq 4)>
	add	di, offset FR_creator - offset FR_name
	ornf	es:[di-offset FR_creator].FR_state,
		mask FRSF_DOS_FILE_WITH_CREATOR
	stosw
	mov_tr	ax, bx
	stosw
	mov_tr	ax, si
	stosw
foundToken:
	pop	ax, bx, si
	clc					; indicate found
noMore:
	mov	cx, ax				; save token chars
	mov	dx, bx
	pop	bx				; unlock mapping list
	call	MemUnlock
	mov	ax, cx				; retrieve token chars
	mov	bx, dx
done:

	.leave

	ret
CheckNonGEOSTokenMapping	endp

if _WRITABLE_TOKEN_DATABASE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallApplToGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call application to install its token and moniker list
		into token database

CALLED BY:	INTERNAL
			DrawIconModeIcon

PASS:		es:di - entry in folder buffer of application
			must be GEOS file
		*ds:si - FolderClass object 

RETURN:		carry set if not possible:
			not an executable
			error loading application

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallApplToGetMoniker	proc	near
	class	FolderClass

	uses	ax, bx, cx, dx, si, es, di, bp

	.enter

	cmp	ss:[disableTokenLaunch], BB_TRUE ; are we avoiding this?
	LONG je	nope				 ; yes

						; did we attempt this already?
	test	es:[di].FR_state, mask FRSF_CALLED_APPLICATION
	jnz	nopeJNZ				; yes
						; flag so we don't try again
	ornf	es:[di].FR_state, mask FRSF_CALLED_APPLICATION
EC <	cmp	es:[di].FR_fileType, GFT_NOT_GEOS_FILE	; GEOS file?	>
EC <	ERROR_E	NOT_GEOS_FILE					>
	cmp	es:[di].FR_fileType, GFT_EXECUTABLE

nopeJNZ:
	LONG	jne	nope			; not executable, cannot launch

	; We also can't launch (IACPConnect) ourself to install the token.
	; Instead, we'll just send MSG_GEN_APPLICATION_INSTALL_TOKEN to 
	; our application object to install the token.

ND <	cmp	{word}es:[di].FR_token.GT_chars[0], 'nD'		>
GM <	cmp	{word}es:[di].FR_token.GT_chars[0], 'DE'		>
	jne	launch
ND <	cmp	{word}es:[di].FR_token.GT_chars[2], 'SK'		>
GM <	cmp	{word}es:[di].FR_token.GT_chars[2], 'SK'		>
	jne	launch
	cmp	es:[di].FR_token.GT_manufID, MANUFACTURER_ID_GEOWORKS
	jne	launch

	mov	ax, MSG_GEN_APPLICATION_INSTALL_TOKEN
	call	UserCallApplication
	clc
	jmp	exit	

launch:
	;
	; 3...2...1...Launch!
	;

	; Before we get too far, turn off our ability to be transparently
	; detached, so that we don't get tossed out as a result of starting
	; up an app just to get its moniker -- Doug 4/16/93
	;
	mov	cx, mask AS_AVOID_TRANSPARENT_DETACH
	clr	dx
	mov	ax, MSG_GEN_APPLICATION_SET_STATE
	call	UserCallApplication

	mov	ax, size AppLaunchBlock		; allocate AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or \
				ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	LONG	jc	done			; memory error, no token
						;	(exit with C set)
	push	ds
	push	es, di, bx
	mov	es, ax
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	call	Folder_GetDiskAndPath		; ax <- disk handle,
						; ds:bx <- GenFilePath
	mov	es:[ALB_appRef.AIR_diskHandle], ax
	lea	si, ds:[bx].GFP_path
	mov	di, offset ALB_appRef.AIR_fileName
	call	CopyNullSlashString		; store path + final slash
	pop	ds, si, bx
	pop	ax				; ax <- folder object segment
	push	ds, si, ax			; save FolderRecord again so
						;  we can get to its token. put
						;  folder object seg back on
						;  stack too
	add	si, offset FR_name
	call	CopyNullTermString		; tack on path and null-term
	mov	es:[ALB_appMode], MSG_GEN_PROCESS_OPEN_ENGINE
	mov	es:[ALB_launchFlags], 0
	call	MemUnlock			; unlock AppLaunchBlock
	mov	dx, bx				; dx = AppLaunchBlock
	pop	ds				; retrieve folder obj segment
	push	ds:[LMBH_handle]
	call	GetLoadAppGenParent		; fill in ALB_genParent field
	pop	bx
	call	MemDerefDS

	mov	bx, dx				; bx <- ALB handle
	pop	es, di				; es:di <- FolderRecord
	add	di, offset FR_token
	mov	ax, mask IACPCF_FIRST_ONLY or \
		    (IACPSM_NOT_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	call	IACPConnect
	jc	done				; exit with carry set

	;
	; Successfully connected to the beast. Send its process a message
	; to install its token. There's a bit of fun, here, as we need to
	; block until the server has processed the request. We can't "call" the
	; server, only send it a message, and it can send us one back. However,
	; we're not supposed to return from this routine until we're certain
	; the server has attempted to install its token. Through the magic of
	; the IACP completion message, we can do all this.
	; 1) allocate a queue
	; 2) record a junk message to be send to this queue; this is the
	;    completion message we give to IACP
	; 3) record a MSG_GEN_PROCESS_INSTALL_TOKEN to be sent to the server's
	;    process.
	; 4) call IACPSendMessage to send the request. When it's done, the
	;    server (or IACP if the server has decided to vanish) will send
	;    the message recorded in #2 to our unattached event queue.
	; 5) call QueueGetMessage to pluck the first message from the head
	;    of the queue. This will block until the server has done its thing.
	; 6) nuke the queue and the junk message.
	; 7) shutdown the IACP connection
	;
	call	GeodeAllocQueue
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; cx <- completion msg
	push	bx			; save queue handle for blocking &
					;  nuking
	
	mov	ax, MSG_GEN_PROCESS_INSTALL_TOKEN
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage		; record install-token message

	mov	bx, di			; bx <- msg to send
	mov	dx, TO_PROCESS		; dx <- send it to the server's process
	mov	ax, IACPS_CLIENT	; ax <- we be the client
	call	IACPSendMessage

	pop	bx
	call	QueueGetMessage		; wait for junk completion msg to
					;  arrive
	call	GeodeFreeQueue		; nuke the queue (no further need)
	mov_tr	bx, ax			; bx <- junk completion msg
	call	ObjFreeMessage		; nuke it too

	clr	cx, dx
	call	IACPShutdown		; shutdown the client side of the
					;  connection. The server will exit
					;  if we're its only tie to life.

done:
	clr	cx
	mov	dx, mask AS_AVOID_TRANSPARENT_DETACH
	mov	ax, MSG_GEN_APPLICATION_SET_STATE
	call	UserCallApplication
	clc

	jmp	short exit

nope:
	stc
exit:
	.leave
	ret
CallApplToGetMoniker	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearFolderObjectIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear folder icon

CALLED BY:	DrawFolderObjectIcon

PASS:		es:bp - file entry in folder buffer
		ds:si - folder instance data
		di - gState to draw with
		dh - display mode

RETURN:		

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/11/89	broke out, added header, change for icon modes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearFolderObjectIcon	proc	near
	uses	ax, bx, si
		
	.enter

	call	FolderSetBackgroundFillPattern
	test	dh, mask FIDM_LICON or mask FIDM_SICON	; icon modes?
	jnz	clearIcon			; yes
	;
	; text modes - wash out bounding box
	;
	call	RectFolderObjectIconBoundBox	; wash out icon area
	jmp	clearDone
	;
	; icon modes - wash out icon area and name area
	;
clearIcon:
	call	RectFolderObjectIconIconBox	; wash out icon area
	call	RectFolderObjectIconNameBox	; wash out name area
clearDone:
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor			; restore drawing color
	.leave
	ret
ClearFolderObjectIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertFolderObjectIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	special file inversion that inverts icon and name portions
		separately

CALLED BY:	DrawFolderObjectIcon

PASS:		es:bp - file entry in folder buffer
		*ds:si - FolderClass object
		di - gState to draw with

RETURN:		

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/7/89		Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertFolderObjectIcon	proc	near
	uses	ax, bx, si
	.enter
	mov	al, MM_INVERT			; set invert mode
	call	GrSetMixMode
	call	RectFolderObjectIcon		; draw it
	mov	al, MM_COPY
	call	GrSetMixMode			; restore mode
	.leave
	ret
InvertFolderObjectIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertColorIconFolderObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert w/o screwing up icon colors

CALLED BY:	DrawFolderObjectIcon

PASS:		es:bp - file entry in folder buffer
		*ds:si - FolderClass object
		di - gState to draw with

RETURN:		

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------

InvertColorIconFolderObject	proc	near
	uses	ax, bx, si
	.enter
	test	es:[bp].FR_state, mask FRSF_SELECTED
	jnz	selected
unselected::
	;
	; unselected, clear icon and name, draw icon and name
	;
if _NEWDESK
	call	CheckBWOrTextModes
	jnz	10$
endif
	call	ClearFolderObjectIcon		; clear icon & name area
10$::
	call	DrawFolderObjectIconLow		; redraw icon & name
	jmp	short done

selected:
	;
	; selected, draw black rect and draw icon over it
	;
if _NEWDESK
	call	CheckBWOrTextModes
	jnz	20$
endif
	call	RectFolderObjectIcon		; draw black rect
20$::
	call	DrawFolderObjectIconLow		; draw icon over black rect
	;
	; invert name
	;
	mov	al, MM_INVERT			; set invert mode
	call	GrSetMixMode
	call	RectFolderObjectIconNameBox
	mov	al, MM_COPY
	call	GrSetMixMode			; restore mode
	;
	; invert icon
	;
if ICON_INVERT_MASK
	call	MaskIcon
endif
done:
	.leave
	ret
InvertColorIconFolderObject	endp

if ICON_INVERT_MASK

; Pass: es:bp = FolderRecord
;	di = gstate
;	*ds:si = Folder object
MaskIcon	proc	far
		class	FolderClass
		uses	ds, si, di, es
passedGState	local	word	push	di
folderChunk	local	word	push	si
memBlock	local	word
gstringHandle	local	word
gstringChunk	local	word
		.enter
	;
	; create gstring
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem		; bx = mem handle
		mov	memBlock, bx
		mov	cl, GST_CHUNK
		call	GrCreateGString		; di = gstring, si = chunk
		mov	gstringHandle, di
		mov	gstringChunk, si
		mov	si, folderChunk
		DerefFolderObject	ds, si, bx
		mov	dl, ds:[bx].FOI_displayType
		mov	dh, ds:[bx].FOI_displayMode
		push	bp
		mov	bp, ss:[bp]
		call	DrawIconModeIcon
		pop	bp
		mov	di, gstringHandle
		call	GrEndGString
	;
	; go in change DRAW_BITMAP to FILL_BITMAP
	;
		push	ds, es
		segmov	es, cs
		mov	bx, memBlock
		call	MemLock
		mov	ds, ax
		mov	si, gstringChunk
		mov	si, ds:[si]
checkOp:
		mov	al, ds:[si]
		cmp	al, GR_DRAW_BITMAP_CP
		jne	checkSkipOps
		mov	{byte}ds:[si], GR_FILL_BITMAP_CP
		clc
		jmp	short fixedGString

checkSkipOps:
		mov	di, offset opCodeTable
		mov	cx, length opCodeTable
		repne	scasb
		stc				; in case error
		jne	fixedGString
		sub	di, offset opCodeTable
		clr	ax
		mov	al, cs:[opCodeSizeTable][di-1]
		add	si, ax
		jmp	short checkOp
		
fixedGString:
		call	MemUnlock		; (preserves flags)
		pop	ds, es
		jc	freeGString		; unexpected gstring
	;
	; draw it with 50% inverse of background color
	;
		mov	di, passedGState
		call	GrSaveState
		mov	si, WIT_COLOR
		call	WinGetInfo
		test	ah, mask WCF_RGB
		mov	ah, CF_INDEX		; assume color index
		jz	haveIndex
		mov	ah, CF_RGB
		xor	bl, 11111111b		; invert G value
		xor	bh, 11111111b		; invert B value
		xor	al, 11110000b		; invert part of R value
haveIndex:
		xor	al, 00001111b		; invert color index or other
						;  part of R value
		call	GrSetAreaColor
		mov	ax, SDM_50
		call	GrSetAreaMask
		mov	si, gstringHandle
		clr	ax, bx, dx	; don't care: coord is in gstring
		call	GrDrawGString
		call	GrRestoreState
	;
	; free gstring, etc
	;
freeGString:
		mov	di, passedGState
		mov	si, gstringHandle
		mov	dl, GSKT_KILL_DATA
		call	GrDestroyGString
		mov	bx, memBlock
		call	MemFree
		.leave
		ret
MaskIcon	endp

opCodeTable	byte	GR_SAVE_STATE,
			GR_MOVE_TO,
			GR_SAVE_TRANSFORM,
			GR_APPLY_TRANSLATION,
			GR_INIT_DEFAULT_TRANSFORM

opCodeSizeTable	byte	size OpSaveState,
			size OpMoveTo,
			size OpSaveTransform,
			size OpApplyTranslation,
			size OpInitDefaultTransform

endif  ; ICON_INVERT_MASK

endif	;---------------------------------------------------------------------

GreyFolderObjectIcon	proc	near
	class	FolderClass
	uses	ax, bx
	.enter			

	DerefFolderObject	ds, si, bx
	test	es:[bp].FR_state, mask FRSF_SELECTED	; selected?
	jz	dontUnInvert			; no, file not inverted
	test	ds:[bx].FOI_folderState, mask FOS_TARGET	; target?
	jz	dontUnInvert			; no, file not inverted

if ICON_INVERT_PRESERVES_COLOR	;---------------------------------------------

	andnf	es:[bp].FR_state, not mask FRSF_SELECTED ; fake unselected
	call	InvertPreserveColor		; else uninvert file, first
	ornf	es:[bp].FR_state, mask FRSF_SELECTED	; restore selected

else	;---------------------------------------------------------------------

	call	InvertFolderObjectIcon		; else uninvert file, first

endif	;---------------------------------------------------------------------

dontUnInvert:
	mov	al, SDM_50			; set grey mode
	call	GrSetAreaMask
	call	RectFolderObjectIcon		; draw it
	mov	al, SDM_100			; restore mode
	call	GrSetAreaMask
	.leave
	ret
GreyFolderObjectIcon	endp

RectFolderObjectIcon	proc	near
	class	FolderClass
	uses	bx
	.enter
	DerefFolderObject	ds, si, bx		
	test	ds:[bx].FOI_displayMode, mask FIDM_LICON or \
					mask FIDM_SICON		; icon modes?
	jz	regularDraw			; if not, use regular draw
	;
	; draw for icon modes - draw icon and name separately
	;
	call	RectFolderObjectIconIconBox
	call	RectFolderObjectIconNameBox
	jmp	short drawDone
	;
	; draw for text modes - draw bounding box
	;

regularDraw:
	call	RectFolderObjectIconBoundBox

drawDone:
	.leave
	ret
RectFolderObjectIcon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectFolderObjectIconIconBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a rectangle around the folder object

CALLED BY:

PASS:		es:bp - FolderRecord 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	
	For NewDesk - draw 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/24/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectFolderObjectIconIconBox	proc near

	call	LoadIconBounds
	call	GrFillRect			; draw icon
	ret
RectFolderObjectIconIconBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadIconBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the bounds of the icon part of the FolderRecord 

CALLED BY:	UTILITY

PASS:		es:[bp] - FolderRecord 

RETURN:		ax, bx, cx, dx, - icon bounds

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadIconBounds	proc	near
	mov	ax, es:[bp].FR_iconBounds.R_left
	mov	bx, es:[bp].FR_iconBounds.R_top
	mov	cx, es:[bp].FR_iconBounds.R_right
	mov	dx, es:[bp].FR_iconBounds.R_bottom
	ret
LoadIconBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectFolderObjectIconNameBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wash out the area of the icon name

CALLED BY:	DrawFolderObjectName, etc.

PASS:		es:bp - FolderRecord

RETURN:		ax, bx - upper left-hand corner of name box

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/17/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectFolderObjectIconNameBox	proc	near
		call	LoadNameBounds
		call	GrFillRect			; draw name
		ret
RectFolderObjectIconNameBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadNameBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the bounds of the "name" part of the FolderRecord 

CALLED BY:

PASS:		es:[bp] - FolderRecord 

RETURN:		ax, bx, cx, dx - bounds

DESTROYED:	nothing -- flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadNameBounds	proc	near
	mov	ax, es:[bp].FR_nameBounds.R_left
	mov	bx, es:[bp].FR_nameBounds.R_top
	mov	cx, es:[bp].FR_nameBounds.R_right
	mov	dx, es:[bp].FR_nameBounds.R_bottom
	ret
LoadNameBounds	endp

RectFolderObjectIconBoundBox	proc	near
	call	LoadBoundBox
	call	GrFillRect
	ret
RectFolderObjectIconBoundBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBoundBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the bounding box of the current FolderRecord 

CALLED BY:	UTILITY

PASS:		es:bp - FolderRecord 

RETURN:		ax, bx, cx, dx- bounds of FolderRecord 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	added header.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadBoundBox	proc	near
	mov	ax, es:[bp].FR_boundBox.R_left
	mov	bx, es:[bp].FR_boundBox.R_top
	mov	cx, es:[bp].FR_boundBox.R_right
	mov	dx, es:[bp].FR_boundBox.R_bottom
	ret
LoadBoundBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFullFileDetail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	display long version of file, includes file name, size,
		modification date and time

CALLED BY:	INTERNAL
			DrawFolderObjectIcon

PASS:		*ds:si - FolderClass object
		es:bp - file to draw
		di - gState to draw with

RETURN:		preserves ds, si, es, bp, di

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFullFileDetail	proc	near
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
		class	FolderClass
endif
		uses	ds, si
		.enter
	;
	; Need to do token processing to handle creator token -- ardeb 6/14/91
	; 
		xchg	di, bp				; es:di <- entry
		call	InitFileHeaderToken
		xchg	di, bp
	;
	; get name position and draw
	;
		segxchg	ds, es				; ds = FolderRecord
							; es = FolderInstance

		push	di				; save gstate
		mov	di, bp				; ds:di = FolderRecord
		call	FolderRecordGetNameWidth
		pop	di				; restore gstate
		segxchg	ds, es				; es = FolderRecord
							; ds = FolderInstance

		call	DrawFolderObjectName
	;
	; print file size
	;
		test	es:[bp].FR_fileAttrs, mask FA_SUBDIR
		jnz	date			; skip size if a subdir.
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
		;
		; for ZMGR, either doing Names and Dates or Names and Sizes
		;
		push	di
		DerefFolderObject	ds, si, di
		test	ds:[di].FOI_displayMode, mask FIDM_FULL_DATES
		pop	di
		jnz	date		; Names and Dates, skip size
endif
		mov	dx, es:[bp].FR_size.low
		mov	ax, es:[bp].FR_size.high
		call	PrintFileSize
	;
	; print file modification date
	;
date:
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
		;
		; for ZMGR, either doing Names and Dates or Names and Sizes
		;
		push	di
		DerefFolderObject	ds, si, di
		test	ds:[di].FOI_displayMode, mask FIDM_FULL_DATES
		pop	di
		jz	done		; Names and Sizes, all done
endif
		push	bx
		mov	ax, ss:[fullFileDatePos]		; bx unchanged
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
		;
		; slide back to the left over space made for absent size field
		;
		mov	ax, ss:[widest83FilenameWidth]
					; match code in SetUpFontAndGState
		add	ax, 2 + \
				TEXT_ICON_WIDTH + TEXT_ICON_HORIZ_SPACING + \
				LONG_TEXT_HORIZ_SPACING + \
				LONG_TEXT_HORIZ_SPACING*2
endif
		call	GrMoveTo
		sub	sp, EVEN_DATE_TIME_BUFFER_SIZE
		mov	si, sp
		push	es, ds, di
		
		mov	ax, es:[bp].FR_modified.FDAT_time ; ax <- FileTime
		mov	bx, es:[bp].FR_modified.FDAT_date ; bx <- FileDate
		segmov	es, ss				  ; es:di <- buffer
		mov	di, si
		;
		; add leading 0, if necessary, to even up columns
		;
		mov	cx, ax
		andnf	cx, mask FT_HOUR
		cmp	cx, 0 shl offset FT_HOUR
		je	noLeading0
		cmp	cx, 10 shl offset FT_HOUR
		je	noLeading0
		cmp	cx, 11 shl offset FT_HOUR
		je	noLeading0
		cmp	cx, 12 shl offset FT_HOUR
		je	noLeading0
		cmp	cx, 22 shl offset FT_HOUR
		je	noLeading0
		cmp	cx, 23 shl offset FT_HOUR
		je	noLeading0
		push	ax
		LocalLoadChar ax, '0'
		LocalPutChar esdi, ax
		pop	ax
noLeading0:
		push	ax				; save FileTime
		call	UtilFormatDateAndTime
		pop	ax
;
; ugly hack to deal with 24-hour time format - brianc 5/27/93
;
SBCS <		cmp	{byte} es:[si]+2, ':'		; two digits, then ':'?>
DBCS <		cmp	{wchar} es:[si]+4, ':'		; two digits, then ':'?>
		je	hackDone			; yup, it worked
							; else, forget leading 0
		mov	di, si				; es:di = buffer
		call	UtilFormatDateAndTime
hackDone:
		pop	di				; di <- gstate
		segmov	ds, es				; ds:si <- string
		clr	cx				; null-term
		call	GrDrawTextAtCP
		pop	es, ds
		add	sp, EVEN_DATE_TIME_BUFFER_SIZE
		pop	bx
		
;
; No attributes in ZMGR's Names and Sizes or Names and Dates
;
if GPC_NO_NAMES_AND_DETAILS_ATTRS ne TRUE
if (not _ZMGR or not SEPARATE_NAMES_AND_DETAILS)
	;
	; print file attributes
	;
		mov	ax, ss:[fullFileAttrPos]	; bx unchanged
		call	GrMoveTo
		mov	al, es:[bp].FR_fileAttrs
		test	al, mask FA_RDONLY	; check if READ-ONLY
		jz	notRO			; if not, skip
		mov	dl, 'R'			; else, get attribute indicator
		call	DrawAttrBit
notRO:
		test	al, mask FA_ARCHIVE	; check if ARCHIVE
		jz	notA			; if not, skip
		mov	dl, 'A'			; else, get attribute indicator
		call	DrawAttrBit
notA:
		test	al, mask FA_HIDDEN	; check if HIDDEN
		jz	notH			; if not, skip
		mov	dl, 'H'			; else, get attribute indicator
		call	DrawAttrBit
notH:
		test	al, mask FA_SYSTEM	; check if SYSTEM
		jz	notS			; if not, skip
		mov	dl, 'S'			; else, get attribute indicator
		call	DrawAttrBit
notS:
		mov	ax, es:[bp].FR_fileFlags
		test	ax, mask GFHF_TEMPLATE
		jz	notT
		mov	dl, 'T'
		call	DrawAttrBit
notT:
		test	ax, mask GFHF_SHARED_MULTIPLE
		jz	notM
		mov	dl, 'M'
		call	DrawAttrBit
notM:
		test	ax, mask GFHF_SHARED_SINGLE
		jz	notP
		mov	dl, 'P'
		call	DrawAttrBit
notP:
endif
endif
done::
		.leave
		ret
DrawFullFileDetail	endp

if GPC_NO_NAMES_AND_DETAILS_ATTRS ne TRUE
if (not _ZMGR or not SEPARATE_NAMES_AND_DETAILS)
DrawAttrBit	proc	near
	clr	dh
	call	GrDrawCharAtCP
	LocalLoadChar dx, ' '
	call	GrDrawCharAtCP
	ret
DrawAttrBit	endp
endif
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDisplayList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes though folder buffer, and builds linked-list of
		those files that are to be shown in the folder window.
		File selection depends on user-settable display attributes.
		Order depends on user-settable sort field.

CALLED BY:	INTERNAL -
			FolderLoadDirInfo
			FolderSetDisplayOptions

PASS:		*ds:si - FolderClass object
		ax = TRUE to sort
		     FALSE to no sort (just rearranging file positions)

RETURN:		carry clear if no error
			ds:[si].FOI_displayList - display list head
		carry set if memory allocation error

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDisplayList	proc	far
		
		class	FolderClass
		
		uses	bx, cx, dx, bp, di, es, si
		
		.enter
		
EC <	cmp	ax, TRUE						>
EC <	je	EC_good							>
EC <	cmp	ax, FALSE						>
EC <	ERROR_NZ	DESK_BAD_PARAMS					>
EC <EC_good:								>

		DerefFolderObject	ds, si, di
		tst	ds:[di].FOI_suspendCount			
		jnz	hourGlassSet					
		call	ShowHourglass		; might take a while...

hourGlassSet:							
		
		mov	bp, ax			; save flag for
						; SortFolderBuffer
	;
	; set up correct values for file drawing box width and box height
	;
		call	SetFileBoxWidthHeight
		call	FolderLockBuffer
		jz	clearBothLists
		
		mov	cl, ds:[di].FOI_displayTypes	; get display options
		mov	ch, ds:[di].FOI_displayAttrs
		mov	dl, ds:[di].FOI_displaySort
		mov	dh, ds:[di].FOI_displayMode
		push	cx			; save display types/attrs
		call	SortFolderBuffer	; sort the folder buffer
	;
	; returns dx=seg of index table
	;	  cx=handle of
	;	  index table
		
		mov	ds:[di].FOI_displayList, NIL	; clear list
							; in case no files
		pop	bx				; display types/attrs
		LONG jc	exit				
		
	;
	; Are there any files?  If not, done
	;
		
		tst	ds:[di].FOI_fileCount	
		jz	noFiles	
		push	cx				; handle of index table
		call	BuildListPass
		pop	bx				; free the index table
		call	MemFree
		
noFiles:
		call	RebuildSelectList	
		call	FolderUnlockBuffer
		jmp	finishUp
		
clearBothLists:
	;
	; Set both display and select lists to empty if no buffer. NOTE: Do
	; not attempt to do this before calling FolderLockBuffer, as
	; SortFolderBuffer relies on having a display list if ax passed to
	; us as FALSE (don't sort).
	; 
		mov	ds:[di].FOI_displayList, NIL
		mov	ds:[di].FOI_selectList, NIL
		
finishUp:
	;
	; Delay updating the folder info string and other visual things
	; if suspended.
	; 
		tst	ds:[di].FOI_suspendCount
		jz	buildString
		
		ornf	ds:[di].FOI_folderState, mask FOS_REBUILD_ON_UNSUSPEND
		jmp	visualStuffDone
		
buildString:
	call	PrintFolderInfoString
		
	;
	; now set increment size
	;
		
		mov	al, ds:[di].FOI_displayMode	; al, display mode
		push	ax				; save display mode
		mov	cx, ss:[largeIconBoxWidth]
		mov	dx, ss:[largeIconBoxHeight]
		test	al, mask FIDM_LICON
		jnz	gotIncrements

		mov	cx, ss:[shortTextBoxWidth]
		shr	cx
		mov	dx, ss:[shortTextBoxHeight]
		test	al, mask FIDM_SHORT
		jnz	gotIncrements

		mov	cx, ss:[longTextBoxWidth]
		shr	cx
		mov	dx, ss:[longTextBoxHeight]
		test	al, mask FIDM_FULL
		jnz	gotIncrements
		mov	cx, ss:[smallIconBoxWidth]
		mov	dx, ss:[smallIconBoxHeight]
EC <	test	al, mask FIDM_SICON					>
EC <	ERROR_Z	DESKTOP_FATAL_ERROR					>
		
gotIncrements:
		push	bp			
		sub	sp, size PointDWord
		mov	bp, sp
		mov	ss:[bp].PD_x.low, cx
		mov	ss:[bp].PD_x.high, 0
		mov	ss:[bp].PD_y.low, dx
		mov	ss:[bp].PD_y.high, 0
		mov	dx, size PointDWord
		mov	ax, MSG_GEN_VIEW_SET_INCREMENT
		mov	di, mask MF_CALL or mask MF_STACK
		call	FolderCallView
		add	sp, size PointDWord
		pop	bp

	;
	; Fetch the display mode, keeping it on the stack
	;
		
		pop	ax		; display mode
if not _NEWDESK
		push	ax		
endif
	;
	; set minimum document size
	;

		mov	cx, ss:[largeIconBoxWidth]
		add	cx, LARGE_ICON_INDENT
		mov	dx, ss:[largeIconBoxHeight]
		add	dx, LARGE_ICON_DOWNDENT
		test	al, mask FIDM_LICON
		jnz	gotMinSize

	;
	; Average filename width seems to be about 1/2 the maximum
	; width, so use that as the minimum width.  Then again, if a
	; user were listing a bunch of very short filenames, this
	; might be too much...
	;
		mov	cx, ss:[shortTextBoxWidth]
		add	cx, TEXT_INDENT
		shr	cx
		mov	dx, ss:[shortTextBoxHeight]
		add	dx, TEXT_DOWNDENT
		test	al, mask FIDM_SHORT
		jnz	gotMinSize
		
		mov	cx, ss:[shortTextBoxWidth]	
		add	cx, TEXT_INDENT
		mov	dx, ss:[longTextBoxHeight]
		add	dx, TEXT_DOWNDENT
EC <		test	al, mask FIDM_FULL				>
EC <		ERROR_Z	DESKTOP_FATAL_ERROR				>
		
gotMinSize:
		mov	ax, bp				;update mode

		sub	sp, size SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_updateMode, VUM_NOW
		mov	ss:[bp].SSA_width, cx
		mov	ss:[bp].SSA_height, dx
		clr	ss:[bp].SSA_count
		mov	dx, size SetSizeArgs
		mov	ax, MSG_GEN_SET_MINIMUM_SIZE	
		mov	di, mask MF_CALL or mask MF_STACK
		call	FolderCallView
		add	sp, size SetSizeArgs

		
if not _NEWDESK
	
	;
	; set correct scrollbars, depending on display mode.  Large
	; icon mode has a vertical scrollbar
	;
		pop	ax			; al - display mode
		mov	cx, 0 or (mask GVDA_SCROLLABLE shl 8)
		mov	dx, mask GVDA_SCROLLABLE or (0 shl 8)
		test	al, mask FIDM_LICON		
		jnz	gotScrollBars

	;
	; names only mode has a horizontal scrollbar
	;
		
		mov	cx, mask GVDA_SCROLLABLE or (0 shl 8)	
		mov	dx, 0 or (mask GVDA_SCROLLABLE shl 8)	
		test	al, mask FIDM_SHORT		; names only mode
		jnz	gotScrollBars

	;
	; Names and details mode has both vertical and horizontal
	; scrollers. 
	;
		

;
; ZMGR Names and Sizes/Names and Dates has only vertical scrollbar
;
if _ZMGR
		mov	cx, 0 or (mask GVDA_SCROLLABLE shl 8)
else
		mov	cx, mask GVDA_SCROLLABLE or (0 shl 8)	
endif
		mov	dx, mask GVDA_SCROLLABLE or (0 shl 8)	
		
gotScrollBars:

	;
	; IMPORTANT:  Use MF_CALL here, as we want to make sure the
	; GenView has put a MSG_META_CONTENT_VIEW_SIZE_CHANGED message
	; on our queue before we return from this procedure!
	;
		
		mov	bp, VUM_NOW
		mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
		mov	di, mask MF_CALL
		call	FolderCallView
endif
		clc				; indicate no error
		
exit:
		call	HideHourglass
		
visualStuffDone:
		.leave
		ret
BuildDisplayList	endp



COMMENT @-------------------------------------------------------------------
			SetFileBoxWidthHeight
----------------------------------------------------------------------------

DESCRIPTION:	Updates the following global variables:
			largeIconBoxWidth, largeIconBoxHeight
			smallIconBoxWidth, smallIconBoxHeight
			shortTextBoxWidth, shortTextBoxHeight
			longTextBoxWidth,  longTextBoxHeight
			fullFileWidth, fullFileAttrPos, 
			fullFileTimePos, fullFileDatePos

CALLED BY:	INTERNAL - BuildDisplayList,
			   DrawFolderObjectName,
			   SetFolderOpenSize

PASS:		*ds:si - FolderClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Added header

---------------------------------------------------------------------------@
SetFileBoxWidthHeight	proc	near
	class	FolderClass

	uses	ax, cx, dx, di
	.enter

	DerefFolderObject	ds, si, di

	test	ds:[di].FOI_displayAttrs, mask FIDA_COMPRESSED	; compressed?
	jz	notCompressed				; no

	mov	ss:[smallIconBoxWidth], SMALL_ICON_BOX_WIDTH_COMPRESSED
	mov	ss:[smallIconBoxHeight], SMALL_ICON_BOX_HEIGHT_COMPRESSED
	mov	ax, ss:[compressedLongTextWidth]
	mov	ss:[longTextNameWidth], ax
	mov	ax, ss:[compressedFullFileDatePos]
	mov	ss:[fullFileDatePos], ax
	mov	ax, ss:[compressedFullFileTimePos]
	mov	ss:[fullFileTimePos], ax
	mov	ax, ss:[compressedFullFileAttrPos]
	mov	ss:[fullFileAttrPos], ax
	mov	ax, ss:[compressedFullFileWidth]
	mov	ss:[fullFileWidth], ax
	mov	ss:[longTextBoxWidth], ax
	mov	ax, ss:[desktopFontHeight]
	add	ax, LONG_TEXT_EXTERNAL_VERT_SPACING
	cmp	ax, TEXT_ICON_HEIGHT
	jge	10$
	mov	ax, TEXT_ICON_HEIGHT
10$:
	mov	ss:[longTextBoxHeight], ax

	mov	ss:[shortTextBoxWidth], SHORT_TEXT_BOX_WIDTH_COMPRESSED
	mov	ax, ss:[desktopFontHeight]
	add	ax, SHORT_TEXT_EXTERNAL_VERT_SPACING
	cmp	ax, TEXT_ICON_HEIGHT
	jge	20$
	mov	ax, TEXT_ICON_HEIGHT
20$:
	mov	ss:[shortTextBoxHeight], ax
	jmp	done

notCompressed:

	mov	ss:[smallIconBoxWidth], SMALL_ICON_BOX_WIDTH_UNCOMPRESSED
	mov	ss:[smallIconBoxHeight], SMALL_ICON_BOX_HEIGHT_UNCOMPRESSED
	mov	ax, ss:[uncompressedLongTextWidth]
	mov	ss:[longTextNameWidth], ax
	mov	ax, ss:[uncompressedFullFileDatePos]
	mov	ss:[fullFileDatePos], ax
	mov	ax, ss:[uncompressedFullFileTimePos]
	mov	ss:[fullFileTimePos], ax
	mov	ax, ss:[uncompressedFullFileAttrPos]
	mov	ss:[fullFileAttrPos], ax
	mov	ax, ss:[uncompressedFullFileWidth]
	mov	ss:[fullFileWidth], ax
	mov	ss:[longTextBoxWidth], ax
	mov	ax, ss:[desktopFontHeight]
	add	ax, LONG_TEXT_EXTERNAL_VERT_SPACING
	cmp	ax, TEXT_ICON_HEIGHT
	jge	30$
	mov	ax, TEXT_ICON_HEIGHT
30$:
	mov	ss:[longTextBoxHeight], ax

	;
	; In names only mode, always allow the names to be as long as
	; they want.
	;
	mov	ax, ss:[uncompressedLongTextWidth]
	mov	ss:[shortTextBoxWidth], ax
	add	ss:[shortTextBoxWidth], TEXT_ICON_WIDTH + \
					TEXT_ICON_HORIZ_SPACING + \
					SHORT_TEXT_EXTERNAL_HORIZ_SPACING

	mov	ax, ss:[desktopFontHeight]
	add	ax, SHORT_TEXT_EXTERNAL_VERT_SPACING
	cmp	ax, TEXT_ICON_HEIGHT
	jge	40$
	mov	ax, TEXT_ICON_HEIGHT
40$:
	mov	ss:[shortTextBoxHeight], ax
done:
	call	FolderCalcIconBoxSize
	mov	ss:[largeIconBoxWidth], cx
	mov	ss:[largeIconBoxHeight], dx
	.leave
	ret
SetFileBoxWidthHeight	endp


COMMENT @-------------------------------------------------------------------
			FolderCalcIconBoxSize
----------------------------------------------------------------------------

DESCRIPTION:	Returns the size of icon box (used during a selection)
		used by the given folder. 

CALLED BY:	INTERNAL - SetFileBoxWidthHeight

PASS:		*ds:si - FolderClass object 
		ss:[desktopFontHeight]
		ss:[desktopDisplayType]

RETURN:		cx	= icon box width
		dx	= icon box height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderCalcIconBoxSize	proc	near
		class	FolderClass

		uses	di

		.enter
	;
	; First, assume we are *not* in compressed mode.
	;
		call	FolderCalcIconSize
		; cx = width
		; dx = height
		
		add	cx, LARGE_ICON_EXTERNAL_HORIZ_SPACING
		add	dx, LARGE_ICON_VERT_SPACING + \
			    LARGE_ICON_EXTERNAL_VERT_SPACING
		add	dx, ss:[desktopFontHeight]
		
	;
	; Handle any adjustments needed if we are in compressed mode.
	;
		DerefFolderObject	ds, si, di
		test	ds:[di].FOI_displayAttrs, mask FIDA_COMPRESSED
		jz	notCompressed
		sub	cx, 30
		sub	dx, 5
notCompressed:
		.leave
		ret
FolderCalcIconBoxSize	endp



COMMENT @-------------------------------------------------------------------
			FolderCalcIconSize
----------------------------------------------------------------------------

DESCRIPTION:	Returns the size of icons used by the given folder.

CALLED BY:	INTERNAL - SetFileBoxWidthHeight

PASS:		nothing 

RETURN:		cx	= icon width
		dx	= icon height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderCalcIconSize	proc	near
		.enter
	;
	; Assume non-CGA display mode
	;
		mov	cx, LARGE_ICON_WIDTH
		mov	dx, LARGE_ICON_HEIGHT
	;
	; Handle any adjustments needed if we are in CGA.
	;
		call	FolderCodeCheckIfCGA
		jnc	notCGA
		sub	dx, CGA_ICON_HEIGHT_DIFFERENCE
notCGA:
		.leave
		ret
FolderCalcIconSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortFolderBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sorts the files in the folder buffer; an external index
		table is built then sorted

CALLED BY:	INTERNAL
			BuildDisplayList

PASS:		dl - sort field (FI_DisplaySort record)
		*ds:si - FolderClass object 
		es - segment of locked folder buffer
		bp = TRUE to sort
		     FALSE to no sort (just rearranging file positions)

RETURN:		carry clear if no error
			dx - index table segment
			cx - index table handle
		carry set if memory allocation error
		preserves ds, si, es

DESTROYED:	ax, cx, bp

PSEUDO CODE/STRATEGY:
		uses selection sort (if you don't know the algorithm...:-)
		this is OK since typically the number of files to sort
		is fairly small (~20)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortFolderBuffer	proc	near
	class	FolderClass

	uses	bx, si, di

	.enter

EC <	cmp	bp, TRUE						>
EC <	je	EC_good							>
EC <	cmp	bp, FALSE						>
EC <	ERROR_NZ	DESK_BAD_PARAMS					>
EC <EC_good:								>

	DerefFolderObject	ds, si, si
	push	ds, si
	mov	ax, ds:[si].FOI_fileCount	; get number of files
	tst	ax				; if none, no sort (1 is ok)
	LONG jz	SFB_exit
	push	ax				; save file count
	mov	cx, ALLOC_DYNAMIC_LOCK		; locked block
	shl	ax, 1				; size of word table for files
	call	MemAlloc			; allocate buffer
	pop	cx				; retrieve file count
	LONG jc	SFB_exit			; if memory error, done
	push	bx				; save handle of index table
	push	es				; save segment of folder buffer
	mov	es, ax				; es - segment of index table
	cmp	bp, TRUE			; sort normally?
	je	SFB_sort			; yes
	;
	; build sorted index table from display list
	;	ds:si = folder instance data
	;	es = segment of index table
	;	cx = number of files (at least 1)
	;
	clr	di				; es:di = start of index buffer
	mov	si, ds:[si].FOI_displayList	; ds:si = first file in
	pop	ds				;	display list
SFB_sortedIndexLoop:
	cmp	si, NIL				; early end of display list?
	jne	SFB_moreToAdd			; no, continue
	mov	ax, NIL				; else, mark early end of index
	stosw					;	table...
	jmp	SFB_loopEnd			; ...and get out

SFB_moreToAdd:
	mov	ax, si
	stosw					; store its offset in index buf
	mov	si, ds:[si].FR_displayNext	; ds:si = next file in list
	loop	SFB_sortedIndexLoop
SFB_loopEnd:
	mov	dx, es				; return DX = index table seg.
	segmov	es, ds				; restore es = folder buffer
	jmp	SFB_done

SFB_sort:
	mov	ds, ax				; ds - segment of index table
	;
	; fill in index table with unsorted address of folder buffer entries
	;
	clr	di				; es:di = index buffer entry
	mov	ax, offset FBH_buffer		; ax = folder buffer entry
SFB_initLoop:
	stosw					; store folder buffer entry
	add	ax, size FolderRecord		; ptr to next fldr buf entry
	loop	SFB_initLoop			; go back to store it
	pop	es				; restore seg. of folder buffer
	mov	ax, di				; ax = end of index table
	;
	; sort via the index table
	;
if COUNT_SORT_COMPARISONS
	mov	ss:[sortComparisonCount].low, 0
	mov	ss:[sortComparisonCount].high, 0
endif		; if COUNT_SORT_COMPARISONS

if 0
;
; START of selection sort
;
	clr	bp				; bp = position to fill
SFB_fillNext:
	mov	si, bp				; si = smallest so far
	mov	di, si
SFB_nextIndex:
	add	di, 2				; di = scanner for smallest
	cmp	di, ax
	je	SFB_doneScan
	call	CompareSortFields		; cmp *si, *di
	jb	SFB_nextIndex			; if *si <= *di, check next
	mov	si, di				; else, point to new smallest
	jmp	short SFB_nextIndex		; check next
SFB_doneScan:
	;
	; swap position to fill with smallest
	;
	mov	bx, ds:[bp]			; get position to fill's ptr
	mov	cx, ds:[si]			; get new smallest ptr
	mov	ds:[bp], cx			; store new ptr in pos. to fill
	mov	ds:[si], bx			; store pos. to fill' ptr
	add	bp, 2				; move to next position to fill
	cmp	bp, ax				; check if done
	jne	SFB_fillNext			; if not, go back to fill it
;
; END selection sort
;
elif 0
;
; START insertion sort
;
	clr	bx				; bx = position being worked on
SFB_nextPos:
	add	bx, 2				; move to next position
	cmp	bx, ax				; finished sorting?
	je	SFB_doneSort			; yes
	mov	bp, ds:[bx]			; get this item
	mov	si, bx				; get item index for comparison
	mov	di, bx				; di = loop through sorted ones
	sub	di, 2				;	starting from back end
SFB_compareEntry:
	call	CompareSortFields		; cmp *si, *di fields
	jae	SFB_nextPos			; if in right place, do next
EC <	push	di							>
EC <	add	di, 2							>
EC <	cmp	di, ax							>
EC <	pop	di							>
EC <	ERROR_AE	DESKTOP_FATAL_ERROR				>
	mov	cx, ds:[di]			; shift down to make room
	mov	ds:[di+2], cx
	mov	ds:[di], bp			; store item being worked on
	mov	si, di
	tst	di
	jz	SFB_nextPos			; stored at 1st pos, do next
	sub	di, 2
	jmp	short SFB_compareEntry
SFB_doneSort:
;
; END insertion sort
;
elif 1
;
; START binary insertion sort
;
	clr	si				; si = position being worked on
SFB_nextPos:
	add	si, 2				; move to next position
	cmp	si, ax				; finished sorting?
	je	SFB_doneSort			; yes
	clr	bx				; bx = left
	mov	cx, si
	sub	cx, 2				; cx = right
SFB_binarySearchLoop:
	cmp	bx, cx				; finished?
	ja	SFB_binarySearchDone		; yes
	mov	di, bx
	add	di, cx
	shr	di				; di = middle
	andnf	di, 0xfffe			; nuke low bit for word index
	call	CompareSortFields		; compare *si, *di
	jae	SFB_secondHalf			; belongs after middle
	mov	cx, di
	tst	cx				; (special case, first position)
	jz	SFB_binarySearchDone
	sub	cx, 2				; cx = new right (before old
	jmp	short SFB_binarySearchLoop	;	middle)
SFB_secondHalf:
	mov	bx, di
	add	bx, 2				; bx = new left (after old
	jmp	short SFB_binarySearchLoop	;	middle)
SFB_binarySearchDone:
	; move ds:[si] to ds:[bx], shifting everything down
	mov	bp, ds:[si]			; bp = item being placed
	mov	di, si				; di = item to move
	mov	cx, si
	sub	cx, bx
	shr	cx				; cx = # to move
	jcxz	SFB_nextPos			; in right place, no move needed
SFB_moveLoop:
EC <	cmp	di, ax							>
EC <	ERROR_AE	DESKTOP_FATAL_ERROR				>
EC <	tst	di							>
EC <	ERROR_Z		DESKTOP_FATAL_ERROR				>
	mov	bx, ds:[di-2]
	mov	ds:[di], bx
	sub	di, 2
	loop	SFB_moveLoop
	mov	ds:[di], bp			; save item being placed
	jmp	short SFB_nextPos
SFB_doneSort:
;
; END binary insertion sort
;
endif
	mov	dx, ds				; return index segment in DX
SFB_done:
	pop	cx				; return index handle in CX
	clc					; indicate success
SFB_exit:
	pop	ds, si
	.leave
	ret
SortFolderBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareSortFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compares two elements to be sorted

CALLED BY:	INTERNAL
			SortFolderBuffer

PASS:		es - segment of folder buffer
		ds - segment of index table
		si - pointer into index table of current "smallest"
		di - pointer into index table of prospective "smallest"
		dl - sort field

RETURN:		C set if *si is "smaller" than *di
		C clear otherwise (will need to swap entries)

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		a directory is "smaller" than a non-directory (so that they
			will always appear first in file listing)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareSortFields	proc	near
	uses	ax, bx, cx
	.enter
if COUNT_SORT_COMPARISONS
	add	ss:[sortComparisonCount].low, 1
	adc	ss:[sortComparisonCount].high, 0
endif
	;
	; first, check if one or the other is a directory, if so, the
	; directory is "smaller" than the other
	;
	test	dl, mask FIDS_DOS		; DOS order sort ignores dirs.
	jnz	CSF_dos
	mov	bx, ds:[si]			; get smallest-so-far
	mov	cl, es:[bx].FR_fileAttrs
	andnf	cl, mask FA_SUBDIR		; cl<>0 if smallest is dir
	mov	bx, ds:[di]			; get possible smallest
	mov	ch, es:[bx].FR_fileAttrs
	andnf	ch, mask FA_SUBDIR		; ch<>0 if possible is dir
	cmp	ch, cl				; if sm=dir & pos<>dir, C set
						; if sm<>dir & pos=dir, C clr
	jne	doneJMP				; if different, use result
	;
	; if none or both are directories, sort by the sort field
	;
	test	dl, mask FIDS_EXT		; check if sort by extension
	jnz	CSF_ext				; if so, do it
	test	dl, mask FIDS_NAME		; check if sort by name
	jnz	nameJMP				; if so, do it
	test	dl, mask FIDS_SIZE		; check if sort by size
	jnz	CSF_size			; if so, do it
	test	dl, mask FIDS_CREATION
	jnz	CSF_creation
EC <	test	dl, mask FIDS_DATE		; check if sort by date/time >
EC <	jnz	CSF_date			; if so, do it		>
EC <	ERROR	NO_SORT_FIELD			; else, bad news	>
EC < CSF_date: 								>
	mov	ax, offset FR_modified
dateCommon:
	;
	; compare by dates
	;
	mov	bx, ds:[si]			; get smallest-so-far
						; cx = date of smallest
	add	bx, ax
	mov	cx, es:[bx].FDAT_date
	mov	bx, ds:[di]			; get possible smallest
	add	bx, ax
	cmp	es:[bx].FDAT_date, cx		; compare
	jne	doneJMP				; if different, use result
	mov	bx, ds:[si]			; get smallest-so-far
						; cx = time of smallest
	add	bx, ax
	mov	cx, es:[bx].FDAT_time
	mov	bx, ds:[di]			; get possible smallest
	add	bx, ax
	cmp	es:[bx].FDAT_time, cx		; compare
	je	nameJMP				; if dates are same, use name
doneJMP:
	jmp	CSF_done			; else, return result

CSF_creation:
	mov	ax, offset FR_created
	jmp	dateCommon

	;
	; compare by DOS order
	;
CSF_dos:
	mov	bx, ds:[si]			; get smallest-so-far
	mov	cx, es:[bx].FR_invPos		; get inverted position
	mov	bx, ds:[di]			; get possible smallest
						; compare inverted position
	cmp	es:[bx].FR_invPos, cx		; (ds:[si] smaller if cx bigger)
	jmp	doneJMP				; must be different, use result

	;
	; compare by sizes
	;
CSF_size:
	mov	bx, ds:[si]			; get smallest-so-far
						; high-word of size
	mov	cx, es:[bx].FR_size.high
	mov	bx, ds:[di]			; get possible smallest
						; compare high-word of size
	cmp	es:[bx].FR_size.high, cx
	jne	doneJMP				; if different, use result
	mov	bx, ds:[si]			; get smallest-so-far
						; low-word of size
	mov	cx, es:[bx].FR_size.low
	mov	bx, ds:[di]			; get possible smallest
						; compare low-word of size
	cmp	es:[bx].FR_size.low, cx
	jne	doneJMP				; if different, use results
nameJMP:
	jmp	short CSF_name			; else, use names

	;
	; compare by extensions
	;
CSF_ext:
	push	si, di
	; find smallest's extension (if any)
	mov	si, ds:[si]			; get smallest-so-far
						; first longname char, if any
	clr	ax
CSF_smExtLoop:
SBCS <	mov	cl, es:[si].FR_name		; its name		>
DBCS <	mov	cx, {wchar}es:[si].FR_name	; its name		>
	LocalIsNull cx
	jz	CSF_smDone
	LocalNextChar essi
	LocalCmpChar cx, '.'			; find extension for DOS files
	jne	CSF_smExtLoop
	mov	ax, si				; record possible ext start
	jmp	CSF_smExtLoop
CSF_smDone:
	tst	ax				; any ext?
	jz	CSF_poExtStart			; no => leave si pointing
						;  to null
	mov_tr	si, ax				; si <- start of ext
	; find possible smallest's extension (if any)
CSF_poExtStart:
	mov	di, ds:[di]			; get possible smallest
						; first longname char, if any
	clr	ax
CSF_poExtLoop:
SBCS <	mov	ch, es:[di].FR_name		; its name		>
DBCS <	mov	cx, {wchar}es:[di].FR_name	; its name		>
SBCS <	tst	ch							>
DBCS <	LocalIsNull cx							>
	jz	CSF_poDone
	LocalNextChar esdi
SBCS <	cmp	ch, '.'				; find extension for DOS files>
DBCS <	cmp	cx, '.'				; find extension for DOS files>
	jne	CSF_poExtLoop
	mov	ax, di
	jmp	CSF_poExtLoop

CSF_poDone:
	tst	ax				; any ext
	jz	CSF_cmpExts			; no => leave di pointing
						;  to null
	mov_tr	di, ax				; di <- start of ext
CSF_cmpExts:
SBCS <	mov	al, es:[si].FR_name					>
SBCS <	mov	ah, es:[di].FR_name					>
DBCS <	mov	ax, {wchar}es:[si].FR_name				>
DBCS <	or	ax, {wchar}es:[di].FR_name				>
SBCS <	tst	ax							>
	jnz	CSF_oneOrBothExt		; => one or both has extension
	pop	si, di
	jmp	CSF_name			; neither has ext, so use
						;  name as secondary sort
CSF_oneOrBothExt:
	push	ds
						; point to ext or null
		CheckHack <(offset FR_name) eq 0>
	segmov	ds, es				; ds = es = name segment
	mov	cx, DOS_FILE_NAME_EXT_LENGTH
	; now compare extensions starting at the ('.' or null), if no
	; extension, (null, '.') comparison will stop repeat loop with
	; (null < '.'), so files with no extensions come before those
	; with extensions
;	repe cmps[214zb
;case-insensitive
SBCS <	clr	ax				; DOS->GEOS convert both exts>
	call	NoCaseRepeCmpsb
	pop	ds
	pop	si, di
	jne	CSF_done			; if different, use result
;	jmp	short CSF_name			; else, use names
;FALL-THROUGH
	.assert	$ eq CSF_name
	;
	; compare by names
	;
CSF_name:
	push	ds, si, es, di, bp		; these are not pushed if this
						;	code isn't executed
						;	(saves time)
	clr	cl
	mov	bp, ds:[di]			; es:bp = possible's entry
	mov	ax, ds				; save index table segment
	mov	bx, si				; ds:[bx] = smallest's entry
	call	GetFolderObjectName		; ds:si = possible's name
SBCS <	jnc	conv2				; DOS name, need conversion >
SBCS <	ornf	cl, 0x2				; else longname, no convert >
SBCS <conv2:								>
	push	ds, si
	mov	ds, ax				; retrieve index table segment
	mov	bp, ds:[bx]			; es:bp = smallest's entry
	call	GetFolderObjectName		; ds:si = smallest's name
SBCS <	jnc	conv1				; DOS name, need conversion >
SBCS <	ornf	cl, 0x1				; else longname, no convert >
SBCS <conv1:								>
	pop	es, di				; es:di = possible's name
	clr	ax
	mov	al, cl				; ax = conversion flag
	mov	cx, FILE_LONGNAME_BUFFER_SIZE	; can always use this since
						;	names are null-termed.
;	repe cmpsb				; compare them
;case-insensitive
	call	NoCaseRepeCmpsb
	pop	ds, si, es, di, bp
CSF_done:
	.leave
	ret
CompareSortFields	endp

;
; ds:si = source
; es:di = dest
; cx = # chars
; SBCS:
; ax = conversion flag
;	bit 0 set to NOT convert string 1 (longname)
;	bit 1 set to NOT convert string 2 (longname)
;
NoCaseRepeCmpsb	proc	near
SBCS <	uses	bx							>
	.enter
if DBCS_PCGEOS
	call	LocalCmpStrings
else
	mov	bx, '_'			; bx=default char for DOS-to-GEOS conv.
	call	LocalCmpStringsDosToGeos
endif
	.leave
	ret
NoCaseRepeCmpsb	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildListPass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	low-level routine to build display list

CALLED BY:	INTERNAL
			BuildDisplayList

PASS:		*ds:si - FolderClass object
		es - segment of locked folder buffer
		dx - segment of locked index table for folder buffer
		bl - file types to display
		bh - file attributes to display

RETURN:		

DESTROYED:	ax, cx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/10/89		Initial version
	brianc	12/7/89		changed to call specific routines
	martin  7/22/92		Reworked to handle flexible placement
	martin	12/6/92		Simplified.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildListPass	proc	near
		class	FolderClass

		uses	bx, si, di

		.enter

		mov	bp, NIL

		clr	di			; dx:di = start of index table
		DerefFolderObject	ds, si, si
		mov	cx, ds:[si].FOI_fileCount
		jcxz	done

	;
	; The display list is built by creating links between the
	; FolderRecords on the index table, built in SortFolderBuffer.
	;
indexLoop:
		call	CheckEarlyEndOfIndexTable
		je	done
		push	di			; save index table offset
		call	DerefIndexAndCheckFile
		jc	skipThisOne

		call	LinkToDisplayList	; add to display list

skipThisOne:
		pop	di			; retrieve index table offset
		add	di, 2			; next index table entry
		loop	indexLoop
done:
		.leave
		ret			; <---- EXIT HERE
BuildListPass	endp

CheckEarlyEndOfIndexTable	proc	near
	push	es
	mov	es, dx
	cmp	es:[di], NIL
	pop	es
	ret
CheckEarlyEndOfIndexTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DerefIndexAndCheckFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the folder record from the index table, and
		checks if it should be added to the display list.
		If the file is not on the display list, will set 
		FR_StateFlags for the FolderRecord appropriately.

CALLED BY:	INTERNAL - BuildListPass

PASS:		ds:si - instance data of folder object
		es - segment of locked folder buffer
		dx - segment of locked index table for folder buffer
		di - offset into index table
		bl - file types to display
		bh - file attributes to display

RETURN:		carry clear if file should be added to display list
		carry set if file should not be added to display list
		es:di = pointer to folder record

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/22/92		Added header
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DerefIndexAndCheckFile	proc	near
		push	es			; save folder buffer segment
		mov	es, dx			; access index table
		mov	di, es:[di]		; deref. index table
		pop	es			; restore folder buffer segm.
		call	CheckFileInList		; should file be in disp. list?
		jnc	skip
	;
	; clear all state flags except FRSF_OPENED
	;
		pushf				; save carry flag
		andnf	es:[di].FR_state, mask FRSF_OPENED
		popf				; restore carry	
skip:
		ret
DerefIndexAndCheckFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkToDisplayList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends a given Folder Record to the end of the
		display list.

CALLED BY:	BuildListPass

PASS:		ds:si 	= instance data of folder object
		es:di	= pointer to locked Folder Record
		es:bp 	= pointer to last Folder Record in list
			  (NIL indicates that display list is empty)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/22/92		Added header
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkToDisplayList	proc	near
	class	FolderClass

	cmp	bp, NIL				; empty list?
	jne	linkToEnd			; no
	mov	ds:[si].FOI_displayList, di	; make this file the first
	jmp	short markEnd
linkToEnd:
	mov	es:[bp].FR_displayNext, di	; link this file to end of list
markEnd:
	mov	bp, di				; make this the new end-of-list
	mov	es:[bp].FR_displayNext, NIL	; make sure it has EOL marker
	ret
LinkToDisplayList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if this file should be included in the display list

CALLED BY:	INTERNAL -
			DerefIndexAndCheckFile

PASS:		ds:si - instance data of folder object
		es:di - folder buffer entry of this file
		bl - file types to display
		bh - file attributes to display

RETURN:		carry clear if file should be added to display list
		carry set if file should not be added to display list

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/10/89		Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileInList	proc	near

CheckHack	< offset FR_name eq 0 >

BA <	call	BACheckManagedFolder				>
BA <	jc	notManaged					>
BA <	call	IclasCheckSysFile				>
BA <	jc	reject						>
BA <notManaged:							>
BA <	call	BAHideOrShowUSERDATA				>
BA <	jc	reject						>

	call	CheckFileTypes
	jc	reject

	call	CheckFileAttrs

reject:
	ret
CheckFileInList	endp


if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BACheckManagedFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this folder object is considered "managed", i.e. if we
		constrict the type of files that get displayed to the user.

CALLED BY:	INT	CheckFileInList
PASS:		ds:si	= instance data of folder object
RETURN:		carry clear if folder is "managed"
		carry set if folder is "unmanaged"
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	HACK!  Check if the WOT type of this folder is < WOT_FOLDER (i.e. is a
	BA-only WOT type).  If so, return carry clear.
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BACheckManagedFolder		proc	near
		class	NDFolderClass
		
		uses	ax
		
		.enter

		mov	ax, ds:[si].NDFOI_ndObjType
		cmp	ax, WOT_FOLDER
CheckHack <WOT_FOLDER eq 0>
		jl	yup
		stc
done:
		.leave
		ret

yup:		clc
		jmp	done
BACheckManagedFolder		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BAHideOrShowUSERDATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if this is a home folder, and if it is continues
		on to check if the file is USERDATA.  If it is it checks the
		"Show USERDATA" UI in the Options dialog (OptionsMenu) and
		shows or hides USERDATA accordingly

CALLED BY:	CheckFileInList

PASS:		ds:si	- instance data of folder object
		es:di	- FolderRecord of file to check

RETURN:		carry	- set if this is USERDATA and we should hide it
			- clear otherwise

DESTROYED:	nothing


SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BAHideOrShowUSERDATA	proc	near
	class	NDFolderClass
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	mov	bp, ds:[si].NDFOI_ndObjType
	call	NDValidateWOT
	cmp	bp, WOT_TEACHER_HOME
	je	homeFolder
	cmp	bp, WOT_STUDENT_HOME
	jne	homeFolder
	cmp	bp, WOT_STUDENT_HOME_TVIEW
	jne	homeFolder
	cmp	bp, WOT_OFFICE_HOME
	jne	notHomeFolder

homeFolder:
CheckHack< offset FR_name eq 0 >
	segmov	ds, cs
	mov	si, offset UserDataString
	mov	cx, 9				; U S E R D A T A null
	repe	cmpsb
	clc
	jne	done				; not USERDATA

	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_SHOW_USERDATA
	call	ObjMessageCall
	cmc					; set carry if not selected
	jmp	done

notHomeFolder:
	clc
done:
	.leave
	ret
BAHideOrShowUSERDATA	endp

UserDataString	byte	"USERDATA", 0
endif		; if _NEWDESKBA




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileTypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this file is of a type accepted by this folder.

CALLED BY:	CheckFileInList

PASS:		es:di - FolderRecord
		bl - file types to display 

RETURN:		carry clear if accepted, carry set otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileTypes	proc	near
	test	bl, mask FIDT_ALL		; accept all?
	jnz	accept				; if so, accept this one

	test	bl, mask FIDT_PROGS		; accept only progs?
	jz	next				; if not, check next

	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	reject				; if so, reject if dir

	call	CheckDOSExecutable
	jne	reject				; if not a prog, reject

next:
	test	bl, mask FIDT_DATAS		; accept only datas?
	jz	nextNext			; if not, check next

	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	reject				; if so, reject if dir

	call	CheckDOSExecutable
	je	reject				; if a prog, reject

nextNext:
	test	bl, mask FIDT_DIRS		; accept only dirs?
	jz	accept				; if not, accept this one

	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	accept				; if so, accept if dir

reject:
	stc
	ret

accept:
	clc
	ret
CheckFileTypes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this file's attributes matches what we want

CALLED BY:	CheckFileInList, FolderRescanFolderEntry

PASS:		bh - FI_DisplayAttrs to match
		es:di - FolderRecord

RETURN:		carry clear to accept
		carry set to reject

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If not showing FIDA_HIDDEN files, then make sure both the
	FA_HIDDEN and the GFHF_HIDDEN are not set

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileAttrs	proc	far
	uses	ax
	.enter

	mov	al, es:[di].FR_fileAttrs
	test	bh, mask FIDA_ARCHIVE
	jnz	checkRO
	test	al, mask FA_ARCHIVE
	jnz	reject				; don't want A & A set, reject

checkRO:
	test	bh, mask FIDA_RO
	jnz	checkH
	test	al, mask FA_RDONLY
	jnz	reject				; don't want RO & RO set

checkH:
	test	bh, mask FIDA_HIDDEN
	jnz	checkS
	test	al, mask FA_HIDDEN
	jnz	reject				; don't want H & H set, reject
	test	es:[di].FR_fileFlags, mask GFHF_HIDDEN
	jnz	reject

checkS:
	test	bh, mask FIDA_SYSTEM
	jnz	done				; carry is clear
	test	al, mask FA_SYSTEM
	jnz	reject				; don't want S & S set, reject

done:
	.leave
	ret

reject:
	stc
	jmp	done
CheckFileAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFilemaskLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare a filename with a wildcard

CALLED BY:	INTERNAL
			CheckFileInList
			CheckDOSExecutable

PASS:		ds:si = file mask (wildcard)
		es:di = filename to check

RETURN:		Z set if names equal

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		'*' matches any sequence of characters before '.'
		'?' matches any one character (except '.') or a blank
			(i.e. ????? matches DORK and BUM)

		much of this code is inline spaghetti for psuedo-speed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFilemaskLowFar	proc	far
	call	CheckFilemaskLow
	ret
CheckFilemaskLowFar	endp


CheckFilemaskLow	proc	near
	push	si, di, bx
DBCS <	push	dx							>

	; get position of last '.' in filename
	mov	bx, di
	push	di
dotLoop:
	cmp	{TCHAR}es:[di], C_NULL
	je	gotDot
	cmp	{TCHAR}es:[di], '.'
	jne	nextDot
	mov	bx, di				; es:bx = last dot
nextDot:
	inc	di
	jmp	short dotLoop
gotDot:
	pop	di

startLoop:
	LocalGetChar ax, dssi			; get byte from filemask
	LocalIsNull ax				; check if end of filemask
	je	maskEnd_CLOSER
	LocalCmpChar  ax, '.'			; check if ext. delimiter
	je	extension
	LocalCmpChar ax, '*'			; check if match-all char.
	je	matchAll
	LocalCmpChar  ax, '?'			; check if match-one char.
	je	matchOne
	;
	; convert to upper case before comparing
	;
SBCS <	call	UpCaseAL						>
DBCS <	call	UpCaseAX						>
SBCS <	mov	ah, es:[di]			; else, want char. match >
DBCS <	mov	dx, es:[di]			; else, want char. match >
SBCS <	call	UpCaseAH						>
DBCS <	call	UpCaseDX						>
SBCS <	cmp	al, ah							>
DBCS <	cmp	ax, dx							>
	jne	done_JNE			; if NO MATCH, exit
matchOne:
	LocalNextChar esdi			; allow any 1 char. in filename
SBCS <	cmp	byte ptr es:[di], 0		; check if end of filename >
DBCS <	cmp	{wchar}es:[di], 0		; check if end of filename >
	je	filenameEnd			; if so, make sure mask ends
SBCS <	cmp	byte ptr es:[di], '.'		; check for ext. delimiter >
DBCS <	cmp	{wchar}es:[di], '.'		; check for ext. delimiter >
						;	in filename
	jne	startLoop
	cmp	bx, di				; last '.' in filename?
	je	getMaskExt			; if so, get ext. in filemask
	jmp	startLoop			; else, keep going
matchAll:
	LocalPrevChar dssi			; restore '*' for next time
	jmp	short matchOne
getMaskExt:
	LocalGetChar ax, dssi
	LocalIsNull ax				; check if end of filemask
	jz	noMatch				; if so, no match
	LocalCmpChar ax, '.'			; check if ext. delimiter
	jne	getMaskExt			; if not, loop
extension:
SBCS <	cmp	byte ptr es:[di], '.'		; make sure delimiter in fname >
DBCS <	cmp	{wchar}es:[di], '.'		; make sure delimiter in fname >
done_JNE:
	jne	done				; if not, NO MATCH; done
	LocalNextChar esdi			; skip delimiter in filename
nextExtChar:
	LocalGetChar ax, dssi			; get byte from filemask
	LocalIsNull ax				; check if end of filemask
maskEnd_CLOSER:
	je	maskEnd
	LocalCmpChar ax, '*'			; check if match-all char.
	je	extMatchAll
	LocalCmpChar ax, '?'			; check if match-one char.
	je	extMatchOne
	;
	; convert to upper case before comparing
	;
SBCS <	call	UpCaseAL						>
DBCS <	call	UpCaseAX						>
SBCS <	mov	ah, es:[di]			; else, want char match	>
DBCS <	mov	dx, es:[di]			; else, want char match	>
SBCS <	call	UpCaseAH						>
DBCS <	call	UpCaseDX						>
SBCS <	cmp	al, ah							>
DBCS <	cmp	ax, dx							>
	jne	done				; if NO MATCH, exit
extMatchOne:
	LocalNextChar esdi			; allow any 1 char. in filename
SBCS <	cmp	byte ptr es:[di], 0		; check if end of filename >
DBCS <	cmp	{wchar}es:[di], 0		; check if end of filename >
	je	checkMaskExtEnd		; if so, make sure mask ext ends
	jmp	short nextExtChar		; else, check next char.
extMatchAll:
	LocalPrevChar dssi			; restore '*' for next time
	jmp	short extMatchOne
noMatch:
	cmp	di, NIL				; clear Z flag (no match)
	jmp	short done
filenameEnd:
	LocalGetChar ax, dssi			; get filemask byte
	LocalIsNull ax				; check if end of filemask
	jz	done				; if so, MATCH; done
	LocalCmpChar ax, '.'
	jne	filenameEnd			; if not delimiter, check next
	LocalGetChar ax, dssi
	LocalCmpChar ax, '*'			; only allow "*.*"
	jne	done				; if not, NO MATCH
	LocalGetChar ax, dssi
	LocalIsNull ax
	jmp	short done			; if null, MATCH
						; if not null, NO MATCH
checkMaskExtEnd:
	LocalGetChar ax, dssi			; get byte of filemask
	LocalIsNull ax				; mask ends?
	je	done				; yes, MATCH
	LocalCmpChar ax, '*'				; allow '*.*'
	je	checkMaskExtEnd		; allow any number of '*'s
	jmp	short done			; if not '*', NO MATCH
maskEnd:
SBCS <	cmp	byte ptr es:[di], 0		; check if end of filename >
DBCS <	cmp	{wchar}es:[di], 0		; check if end of filename >
						; if so, MATCH
						; if not, NO MATCH
done:
DBCS <	pop	dx							>
	pop	si, di, bx
	ret
CheckFilemaskLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDOSExecutable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this FolderRecord is a DOS program

CALLED BY:	CheckFileTypes, FileOpenESDI

PASS:		es:di - FolderRecord

RETURN:		Z set if program, Z clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/19/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString checkExeMask <'*.EXE',0>
LocalDefNLString checkComMask <'*.COM',0>
LocalDefNLString checkBatMask <'*.BAT',0>

CheckDOSExecutable	proc	far
	uses	ds, si, ax

	.enter

	CheckHack <GFT_NOT_GEOS_FILE eq 0 and GFT_EXECUTABLE eq 1>
	cmp	es:[di].FR_fileType, GFT_EXECUTABLE
	jae	done

	CheckHack	<offset FR_name eq 0>			
	segmov	ds, cs, si
	mov	si, offset checkBatMask	; ds:si = *.BAT
	call	CheckFilemaskLow
	je	done				; exit with MATCH
	mov	si, offset checkExeMask	; ds:si = *.EXE
	call	CheckFilemaskLow
	je	done				; exit with MATCH
	mov	si, offset checkComMask	; ds:si = *.COM
	call	CheckFilemaskLow
done:

	.leave
	ret
CheckDOSExecutable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RebuildSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rebuild list of selected files are resorting, etc.

CALLED BY:	BuildDisplayList

PASS:		es - segment of locked folder buffer
		*ds:si - FolderClass object

RETURN:		ds:[si].FOI_selectList - list of selected files

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RebuildSelectList	proc	near

	class	FolderClass
	uses	ax, bx, di, si
	.enter
	DerefFolderObject	ds, si, si
	mov	ds:[si].FOI_selectList, NIL	; start with empty select list
	mov	di, ds:[si].FOI_displayList	; es:di = start of display list
RSL_loop:
	cmp	di, NIL				; check if end of display list
	je	RSL_done			; if so, done
	test	es:[di].FR_state, mask FRSF_SELECTED	; check if selected
	jz	RSL_getNext			; if not, get next
	cmp	ds:[si].FOI_selectList, NIL	; check if this will be first
	jne	RSL_notFirst			; if not, continue
	mov	ds:[si].FOI_selectList, di	; else, make this first in list
	jmp	RSL_afterFirst		; end select list

RSL_notFirst:
	mov	es:[bx].FR_selectNext, di	; hook to previous one
RSL_afterFirst:
	mov	bx, di				; make this the new previous
	mov	es:[di].FR_selectNext, NIL	; make this the end-of-list
RSL_getNext:
	mov	di, es:[di].FR_displayNext	; get next in dispaly list
	jmp	short RSL_loop
RSL_done:
	;
	; if running in keyboard only mode, force selection of first file,
	; if none currently selected
	;
	call	FlowGetUIButtonFlags		; al = UIBF
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	allDone				; not in keyboard only
	cmp	ds:[si].FOI_selectList, NIL	; any selection?
	jne	allDone				; yes, leave it alone
	mov	bx, ds:[si].FOI_displayList	; else select first file
	mov	ds:[si].FOI_selectList, bx
	mov	es:[bx].FR_selectNext, NIL
	ornf	es:[bx].FR_state, mask FRSF_SELECTED
allDone:
	.leave
	ret
RebuildSelectList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintFolderInfoString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build and display info string in folder window
		("10 file(s) (225 kilobytes) of 10.  12286 kilobytes free.")
		if more than one file is selected, display this:
		("Selected: 2 file(s) (28 kilobytes) from 10.") instead

CALLED BY:	INTERNAL
			FolderDraw
			FolderDeselectAll
			FolderDisplayOptionsInfo

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintFolderInfoString	proc	far
	class	FolderClass
	uses	ax, bx, cx, dx, bp, es, di, si


folderInfoStringBuffer	local	PathName
fileSize	local	dword
fileCount	local	word
folderChildType	local	FolderChildType
folderInstance	local	fptr
displayedFileCount	local	word

	.enter

	DerefFolderObject	ds, si, di
	movdw	ss:[folderInstance], dsdi

	clr	ax
	movdw	ss:[fileSize], axax
	mov	ss:[fileCount], ax

	;
	; enable or disable, as needed
	;

	push	si				; save instance data
	test	ds:[di].FOI_displayAttrs, mask FIDA_INFO	; get state
	mov	bx, ds:[di].FOI_windowBlock	; bx:si = text object
if _GMGR
	mov	si, offset FolderWindowTemplate:FolderInfo
elif _NEWDESK
	mov	si, offset NDFolderInfo
endif
	mov	ax, MSG_GEN_SET_USABLE	; assume shown
	jnz	haveShowState
	mov	ax, MSG_GEN_SET_NOT_USABLE	; else, not shown
haveShowState:
	mov	dl, VUM_NOW
	push	ax, bp
	call	ObjMessageCallFixup
	pop	ax, bp
	cmp	ax, MSG_GEN_SET_USABLE
	pop	si				; retrieve instance data

	je	printString
	jmp	exit
printString:

	;
	; point to buffer for info string
	;
	lea	di, ss:[folderInfoStringBuffer]
	mov	cx, size folderInfoStringBuffer

if (not _NEWDESK)
	;
	; build disk name and pathname, if needed
	;
	call	DiskNameAndPathnameForFolderInfo
endif

	push	di			; end of string

	;
	; Go through either the SELECT list or the DISPLAY list to
	; count up the file sizes.
	;

	clr	ax, dx, cx

	; Count number and size of displayed entries.

	push	bx
	mov	di, FCT_DISPLAY_LIST
	mov	ax, SEGMENT_CS
	mov	bx, offset CalcItemCountAndSizesCB
	call	FolderSendToChildren
		; fileCount = number of displayed files.
		; fileSize = combined size of displayed files.
	mov	ax, ss:[fileCount]
	mov	ss:[displayedFileCount], ax
	pop	bx

	DerefFolderObject	ds, si, bx	
	cmp	ds:[bx].FOI_selectList, NIL	; check if select or display
	jne	useSelectList			; if select, use it instead
						; else, use display list

	; Use the displayed file information.
	mov	ss:[folderChildType], FCT_DISPLAY_LIST
	jmp	gotSizeAndCount

useSelectList:
	DerefFolderObject	ds, si, bx
	clr	ax
	czr	ax, ss:[fileCount]	; Start over for selected files
	clrdw	ss:[fileSize], ax
	mov	di, FCT_SELECTED
	mov	ss:[folderChildType], di
	mov	ax, SEGMENT_CS
	mov	bx, offset CalcItemCountAndSizesCB
	call	FolderSendToChildren
		; fileCount = number of selected files.
		; fileSize = combined size of selected files.

gotSizeAndCount:
	segmov	es, ss				; es:di = info string buffer
	mov	bx, handle DeskStringsRare
	call	MemLock
	mov	ds, ax				; ds = string resource
	;
	; output "Selected: ", if needed
	;
	pop	di				; es:di - info string buffer
	cmp	ss:[folderChildType], FCT_SELECTED

	jne	afterSelect
	mov	si, offset FolderInfoSelectedString
	mov	si, ds:[si]			; ds:si = "Selected: "
	call	CopyNullString

afterSelect:

	;
	; go through template and stuff in params
	;	dx:ax = # bytes free on disk
	;
if	not _BMGR
	tst	ss:[smallScreen]
	jz	notSmallScreen
endif
	;
	; if small screen, show just disk space if there are no 
	; files selected otherwise, show selection info
	;

	mov	si, offset FolderInfoDiskSpaceString
	cmp	ss:[folderChildType], FCT_SELECTED
	jne	gotString

	;
	; If multiple files selected, use the multi-files string
	;

	mov	si, offset FolderInfoMultiSelectionString
	cmp	ss:[fileCount], 1
	jne	gotString

	;
	; Otherwise, use the single file string
	;

	mov	si, offset FolderInfoSingleSelectionString
	jmp	gotString

notSmallScreen:
						; assume multi-file string
	mov	si, offset FolderInfoMultiItemString
	cmp	ss:[fileCount], 1		; multi-file?
	jne	gotString			; yes
						; else, single file
	mov	si, offset FolderInfoSingleItemString
gotString:

	mov	si, ds:[si]			; ds:si = template string
stringLoop:
	;
	; See if we're getting too close to the end 
	;

	lea	ax, ss:[folderInfoStringBuffer]
SBCS <	add	ax, size folderInfoStringBuffer - 20			>
DBCS <	add	ax, size folderInfoStringBuffer - (20*(size wchar))	>
	cmp	di, ax
SBCS <	mov	al, 0							>
DBCS <	mov	ax, 0							>
	jae	stopString			; if so, stop
	LocalGetChar ax, dssi
stopString:
	LocalCmpChar ax, C_BACKSLASH		; parameter?
	LONG jne	storeChar
	LocalGetChar ax, dssi
	LocalCmpChar ax, '1'			; files displayed/selected?
	jne	not1				; nope, check next
	;
	; stuff # files displayed/selected
	;
	mov	ax, ss:[fileCount]
	call	ASCIIizeWordAX
	jmp	short stringLoop		; do next character
not1:
	LocalCmpChar ax, '2'			; bytes in above files?
	jne	not2				; nope, check next
	;
	; stuff # bytes in files displayed/selected
	;
	clr	ax
	mov	al, ss:[fileSize].high.high
	mov	dh, ss:[fileSize].high.low
	mov	dl, ss:[fileSize].low.high
	shrdw	axdx
	shrdw	axdx
	test	ss:[fileSize].low, 0x3ff
	jz	noFileSizeRound
	incdw	axdx
noFileSizeRound:
	call	ASCIIizeDWordAXDX
	jmp	short stringLoop		; do next character
not2:
	LocalCmpChar ax, '3'			; total number of files?
	jne	not3				; nope, check next
	;
	; stuff total # of displayed files
	;
	mov	cx, ds				; save template segment
	mov	ax, si				; save template offset
	lds	si, ss:[folderInstance]

	push	ax
	mov	ax, ss:[displayedFileCount]
	call	ASCIIizeWordAX
	pop	ax

	mov	ds, cx				; restore template segment
	mov	si, ax				; restore template offset
	jmp	short stringLoop		; do next character
not3:
	LocalCmpChar ax, '4'			; free disk space?
	jne	storeChar			; nope, store verbatim
	;
	; stuff free disk space
	;
	mov	cx, ds				; save template segment
	mov	ax, si				; save template offset

	push	ax, dx
	lds	si, ss:[folderInstance]
	clr	ax
	mov	al, ds:[si].FOI_diskInfo.DIS_freeSpace.high.high
	mov	dh, ds:[si].FOI_diskInfo.DIS_freeSpace.high.low
	mov	dl, ds:[si].FOI_diskInfo.DIS_freeSpace.low.high
	shrdw	axdx
	shrdw	axdx
	test	ds:[si].FOI_diskInfo.DIS_freeSpace.low, 0x3ff
	jz	noDiskSpaceRound
	incdw	axdx
noDiskSpaceRound:
	call	ASCIIizeDWordAXDX
	pop	ax, dx

	mov	ds, cx				; restore template segment
	mov	si, ax				; restore template offset
	jmp	stringLoop			; do next character
storeChar:
	LocalPutChar esdi, ax
	LocalIsNull ax				; end of template?
	LONG jne	stringLoop			; nope, back for more
	mov	bx, handle DeskStringsRare
	call	MemUnlock			; unlock string resource
	;
	; set the info string to the text object
	;

	lds	si, ss:[folderInstance]
	mov	bx, ds:[si].FOI_windowBlock	; bx:si = text object
fixupText::
	push	bp, si
	mov	dx, ss				; dx:bp = string
	lea	bp, ss:[folderInfoStringBuffer]
if _GMGR
	mov	si, offset FolderWindowTemplate:FolderInfo
elif _NEWDESK
	mov	si, offset NDFolderInfo
endif
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed,  4/22/93 -jw
; To show start of selection rather than end, and to do it without flickering.
;
;	call	CallFixupSetText
	;
	; Suspend the object.
	;
	push	dx, bp				; save string ptr
	mov	ax, MSG_META_SUSPEND
	call	ObjMessageCallFixup
	pop	dx, bp				; restore string ptr

	;
	; Replace the string
	;
	clr	cx				; null-terminated text
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessageCallFixup

	;
	; Set selection to 0,0
	;
	clr	cx
	clr	dx
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	ObjMessageCallFixup
	
	;
	; Unsuspend the object
	;
	mov	ax, MSG_META_UNSUSPEND
	call	ObjMessageCallFixup

;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	pop	bp, si
	;
	; update enabled state of File menu items, if needed
	;

if _GMGR
	test	ds:[si].FOI_folderState, mask FOS_TARGET	; are we?
	jz	exit				; nope, no updating
	mov	bx, ds:[si].FOI_selectList	; bx = select list

	mov	si, ds:[si].FOI_chunkHandle
	call	UpdateFileMenuCommon		; update it
endif

exit:
	.leave
	ret
PrintFolderInfoString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcItemCountAndSizesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to calculate the count of items
		in the folder buffer and their combined size

CALLED BY:	PrintFolderInfoString via FolderSendToChildren

PASS:		ds:di - FolderRecord
		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcItemCountAndSizesCB	proc far

	.enter	inherit	PrintFolderInfoString

	inc	ss:[fileCount]
	adddw	ss:[fileSize], ds:[di].FR_size, ax
	clc
	.leave
	ret
CalcItemCountAndSizesCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskNameAndPathnameForFolderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	PrintFolderInfoString

PASS:		*ds:si - FolderClass object 
		ss:di - info string
		cx - size of info string

RETURN:		di - updated to point at end

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 4/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if (not _NEWDESK)
DiskNameAndPathnameForFolderInfo	proc	near

	uses	ax, bx, cx, dx, si, es, bp

	.enter
	;
	; no pathname if smallScreen, as it will be shown in Folder Window
	; header if not-maximized and in primary window header if maximized
	;
	tst	ss:[smallScreen]
	jnz	done				; yes, small screen

	push	si, di, cx
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	ObjMessageCallFixup		; carry set if maximized
	pop	si, di, cx			; 
	jnc	done				; nope, no pathname in info str
	segmov	es, ss				; es:di = info string buffer
						; *ds:si <- folder
	call	BuildDiskAndPathName		; put nul-term'ed str
						; into es:di
	LocalPrevChar esdi			; remove null-terminator
SBCS <	mov	ax, ' ' or ('-' shl 8)					>
DBCS <	mov	ax, ' '							>
	stosw
DBCS <	mov	al, '-'							>
DBCS <	stosw								>
	mov	al, ' '
SBCS <	stosb					; add separator		>
DBCS <	stosw								>

done:
	.leave
	ret
DiskNameAndPathnameForFolderInfo	endp
endif ; (not _NEWDESK)

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FolderDrawTemplateIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL - 
			

PASS:		ds:si 	= instance data of Folder object
		es:di 	= pointer to locked folder record

RETURN:		dl, dh 	= set correctly
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	
	Name	Date		Description
	----	----		-----------
	martin	8/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderDrawTemplateIcon	proc	near
	class	FolderClass

	uses	di
	.enter	inherit	DrawIconModeIcon


	mov	ax, ('T') or ('M' shl 8)	; store 'TMPL'
	mov	bx, ('P') or ('L' shl 8)

	push	si, bp
	xchg	dh, dl				; dh = DisplayType
	mov	si, MANUFACTURER_ID_GEOWORKS
	mov     bp, LARGE_ICON_SEARCH_FLAGS	; bp = VisMonikerSearchFlags
	call	TokenLookupMoniker		; cx:dx = moniker ID
						; ax <- shared/local
						;  token DB file flag
	pop	si, bp

	call	DrawIconModeIconLow

	;
	; setup to draw the small icon in the center
	;
	mov	dl, displayType
	mov	dh, mask FIDM_SICON
	mov	displayMode, dh
	.leave
	ret
FolderDrawTemplateIcon	endp
endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCallView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the view

CALLED BY:	INTERNAL

PASS:		*ds:si - FolderClass object
		di - MessageFlags
		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned from view, if MF_CALL passed

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCallView	proc far
		class	FolderClass

		uses	bx, si, di

		.enter

		DerefFolderObject	ds, si, bx
		mov	bx, ds:[bx].FOI_windowBlock
		mov	si, FOLDER_VIEW_OFFSET
		ornf	di, mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
FolderCallView	endp




COMMENT @-------------------------------------------------------------------
			FolderSetBackgroundFillPattern
----------------------------------------------------------------------------

DESCRIPTION:	Sets the fill color of the current window

CALLED BY:	INTERNAL - FolderDraw,
			   FolderDrawObjectName

PASS:		di 	= handle of graphics state or window

RETURN:		CF	= set if wash not needed
			  clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/8/92		Initial version

---------------------------------------------------------------------------@
FolderSetBackgroundFillPattern	proc	near
	uses	ax, bx, cx, si
	.enter
	mov	si, WIT_COLOR		; ask for window's background color
	call	WinGetInfo		; color in ax/bx
	jc	washDone
	test	ah, mask WCF_TRANSPARENT ; if transparent, skip fill
	jnz	washDone
	mov	cx, ax			; save flags, color
	and	ah, mask WCF_MAP_MODE	; set the map mode
	mov	al, ah
	call	GrSetAreaColorMap		
	mov	al, cl
	mov	ah, CF_RGB
	test	ch, mask WCF_RGB	; if non-zero, have RGB color
	jnz	setColor
	mov	ah, CF_INDEX
setColor:
	call	GrSetAreaColor
	clc	
washDone:	; carry set
	.leave
	ret
FolderSetBackgroundFillPattern	endp




COMMENT @-------------------------------------------------------------------
		FolderPlaceIconsGeoManagerStyle
----------------------------------------------------------------------------

DESCRIPTION:	Places the given FolderRecord in the next "slot" as
		designated by a slew of global variables in dgroup.

CALLED BY:	INTERNAL - FolderPlaceUnpositionedIcons

PASS:		*ds:si - FolderClass object

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	View size calculations at the end of this routine are neither
	efficient, nor elegant.  They are the way they are for
	historical reasons (they have worked since V1.0)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/6/92		initial version

---------------------------------------------------------------------------@

FolderPlaceIconsGeoManagerStyle	proc	near
		class	FolderClass

		uses	di, bp

		.enter

	;
	; make sure we use the right set of bounds variables
	;

		call	SetFileBoxWidthHeight


		DerefFolderObject	ds, si, di
		mov	al, ds:[di].FOI_displayMode
		mov	cx, ds:[di].FOI_winBounds.P_x
		
	;
	; Check for Large Icon mode.
	;

		clr	ss:[buildListXPos]
		mov	ss:[buildListYPos], LARGE_ICON_DOWNDENT
		mov	bx, offset FolderRecordPositionLargeMode
		clr	bp
		test	al, mask FIDM_LICON
		jnz	callKids

	;
	; Check for Names & Details mode.
	;

		mov	ss:[buildListXPos], TEXT_INDENT
		mov	ss:[buildListYPos], TEXT_DOWNDENT
		mov	bx, offset FolderRecordPositionLongMode
		test	al, mask FIDM_FULL
		jnz	callKids

	;
	; Default to Names Only mode -- CX is used as max width
	;

		mov	bx, offset FolderRecordPositionNamesOnlyMode
		mov	dx, ds:[di].FOI_winBounds.P_y
		clr	cx
callKids:
		mov	ax, SEGMENT_CS
		call	FolderSendToDisplayList

		.leave
		ret

FolderPlaceIconsGeoManagerStyle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the document bounds of the folder

PASS:		*ds:si	- FolderClass object
		ds:di	- FolderClass instance data
		es	- segment of FolderClass
		cx, dx 	- document bounds

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderSetDocBounds	method	dynamic	FolderClass, 
					MSG_FOLDER_SET_DOC_BOUNDS

		movP	ds:[di].FOI_docBounds, cxdx
		ret
FolderSetDocBounds	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopSetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	decrement the doc bounds before setting

PASS:		*ds:si	- NDDesktopClass object
		ds:di	- NDDesktopClass instance data
		es	- segment of NDDesktopClass
		cx, dx	- doc bounds

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	I don't know why we have to do this, but the *#$&#%! view
comes up with scrollbars initially when returning from state, and this
seems to prevent it.  Of course, this causes additional problems, but...



KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/16/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESK

NDDesktopSetDocBounds	method	dynamic	NDDesktopClass, 
					MSG_FOLDER_SET_DOC_BOUNDS

		uses	ax, cx, dx
		.enter
	;
	; If the document bounds are bigger than the window size, then
	; make the thing scrollable.  This is supposed to happen
	; automatically, but it doesn't fucking work.
	;
		mov	di, ds:[di].DVI_gState
		tst	di
		jz	done
		
		push	cx, dx			; doc bounds
		call	GrGetWinBounds
EC <		ERROR_C	DESKTOP_FATAL_ERROR				>
		sub	cx, ax
		sub	dx, bx
		pop	ax, bx			; doc bounds (win
						; right, bottom in cx, dx)

	;
	; Compare horizontal dimensions, and add horizontal scroller
	; if needed
	;
		
		cmp	ax, cx
		mov	cx, mask GVDA_SCROLLABLE
		ja	gotHoriz
		xchg	cl, ch
gotHoriz:

	;
	; Do same for vertical
	;
		
		cmp	bx, dx
		mov	dx, mask GVDA_SCROLLABLE
		ja	gotVert
		xchg	dl, dh
gotVert:

		mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
		mov	bp, VUM_DELAYED_VIA_UI_QUEUE
		clr	di
		call	FolderCallView
		
done:
		.leave
		mov	di, offset NDDesktopClass
		GOTO	ObjCallSuperNoLock
NDDesktopSetDocBounds	endm

endif




COMMENT @-------------------------------------------------------------------
		FolderRecordPositionLargeMode
----------------------------------------------------------------------------

DESCRIPTION:	Places the given FolderRecord in the next "slot" as
		designated by a slew of global variables in dgroup.

CALLED BY:	FolderPlaceIconsGeoManagerStyle

PASS:		ds:di		= FolderRecord "instance data"
		cx		= width of parent folder
		bp		- nonzero if at least one folder on
				  this row is word-wrapped to 2 lines

GLOBALS USED:	buildListXPos 
		buildListYPos
		largeIconBoxWidth		

RETURN:		bp - updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/11/92	Pulled out of BuildListPass
---------------------------------------------------------------------------@
FolderRecordPositionLargeMode	proc	far
		class	FolderClass

		uses	ax, cx
		.enter

		mov	ax, ss:[buildListXPos]		; need new row?
		add	ax, ss:[largeIconBoxWidth]
		cmp	ax, cx
		jle	gotPos

	;
	; start new row
	;
		clr	ss:[buildListXPos]
		mov	ax, ss:[largeIconBoxHeight]
		add	ss:[buildListYPos], ax
if WRAP
	;
	; If there were any word-wrapped files on the previous row,
	; then scoot the next row down a bit.  In NewDesk, we add an
	; extra blank line -- in GMGR, just add an extra half.
	;
		test	ss:[desktopFeatures], mask DF_WRAP
		jz	gotPos

		mov	ax, ss:[desktopFontHeight]
		tst	bp
		jz	gotPos
		add	ss:[buildListYPos], ax
GM <		shr	ax						>
NPZ <		add	ss:[buildListYPos], ax				>
		clr	bp
endif
		
gotPos:
	;
	; compute bounds for file
	;

		cmp	ss:[buildListYPos], (LARGEST_POSITIVE_COORDINATE - 100)
		jge	done

		mov	cx, ss:[buildListXPos]
		add	cx, LARGE_ICON_INDENT

		mov	dx, ss:[buildListYPos]
		call	FolderRecordSetPosition
		mov	ax, ss:[largeIconBoxWidth]
		add	ss:[buildListXPos], ax		; for next time
if WRAP
		test	ds:[di].FR_state, mask FRSF_WORD_WRAP
		jz	done
		dec	bp	; signal that this line needs more space
endif
done:
		.leave
		ret
FolderRecordPositionLargeMode	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordPositionLongMode
----------------------------------------------------------------------------

DESCRIPTION:	Place this folder for Names & Details mode.

CALLED BY:	FolderPlaceIconsGeoManagerStyle

PASS:		ds:di	= FolderRecord
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/6/92		Pulled out of BuildLongMode

---------------------------------------------------------------------------@
FolderRecordPositionLongMode	proc	far
		.enter
		
		andnf	ds:[di].FR_state, not mask FRSF_WORD_WRAP
	;
	; compute bounds for file
	;

		cmp	ss:[buildListYPos], (LARGEST_POSITIVE_COORDINATE - 20)
		jge	skipEntry
		call	BuildBoundsLongMode
		mov	ax, ss:[longTextBoxHeight]
		add	ss:[buildListYPos], ax
skipEntry:
		.leave
		ret
FolderRecordPositionLongMode	endp



COMMENT @-------------------------------------------------------------------
			BuildBoundsLongMode
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	INTERNAL - FolderRecordPositionLongMode

PASS:		ds:di	= FolderRecord	
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/6/92		Added header

---------------------------------------------------------------------------@
BuildBoundsLongMode	proc	near
		uses	dx
		.enter

		mov	ax, ss:[longTextBoxHeight]
		sub	ax, TEXT_ICON_HEIGHT
		shr	ax, 1
		add	ax, ss:[buildListYPos]
		mov	ds:[di].FR_iconBounds.R_top, ax
		add	ax, TEXT_ICON_HEIGHT
		mov	ds:[di].FR_iconBounds.R_bottom, ax

		mov	ax, ss:[longTextBoxHeight]
		sub	ax, ss:[desktopFontHeight]
		sar	ax, 1
		add	ax, ss:[buildListYPos]
		mov	ds:[di].FR_nameBounds.R_top, ax
		add	ax, ss:[desktopFontHeight]
		mov	ds:[di].FR_nameBounds.R_bottom, ax

		mov	ax, ss:[buildListXPos]
		mov	ds:[di].FR_iconBounds.R_left, ax
		add	ax, TEXT_ICON_WIDTH
		mov	ds:[di].FR_iconBounds.R_right, ax

		add	ax, TEXT_ICON_HORIZ_SPACING+1
		mov	ds:[di].FR_nameBounds.R_left, ax

if _ZMGR and SEPARATE_NAMES_AND_DETAILS
; for ZMGR, go off the end - brianc 6/1/93
		mov	ax, ZMGR_FULL_DATES_RIGHT_BOUND+10
else
		mov	ax, ss:[buildListXPos]	; set this to get bound box
		add	ax, ss:[longTextBoxWidth]
endif
		mov	ds:[di].FR_nameBounds.R_right, ax

		call	FolderRecordSetPositionCommon

		.leave
		ret
BuildBoundsLongMode	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordPositionNamesOnlyMode
----------------------------------------------------------------------------

DESCRIPTION:	Position the FolderRecord in names only mode.

CALLED BY:	FolderPlaceIconsGeoManagerStyle

PASS:		ds:di	= FolderRecord
		cx 	- widest FolderRecord in this column
		dx	- height of parent folder

RETURN:		carry clear
		cx - updated

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	After placing each icon, get its width, and keep track of the
widest one seen so far, so we know where to set the next column.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/6/92		Initial version

---------------------------------------------------------------------------@
FolderRecordPositionNamesOnlyMode	proc	far

		.enter
		
		andnf	ds:[di].FR_state, not mask FRSF_WORD_WRAP

		mov	ax, ss:[buildListYPos]		; need new column?
		add	ax, ss:[shortTextBoxHeight]
		cmp	ax, dx
		jle	sameColumn			; no

	;
	; start new column
	;
		add	cx, SHORT_TEXT_EXTERNAL_HORIZ_SPACING * 3
		add	ss:[buildListXPos], cx
		clr	cx
		mov	ss:[buildListYPos], TEXT_DOWNDENT

sameColumn:

	;
	; compute bounds for file
	;

		cmp	ss:[buildListXPos], (LARGEST_POSITIVE_COORDINATE - 100)
		jge	done

		call	BuildBoundsNamesOnlyMode
		mov	ax, ss:[shortTextBoxHeight]
		add	ss:[buildListYPos], ax

	;
	; If this file is wider than any others seen so far, then
	; remember that fact.
	;
		
		mov	ax, ds:[di].FR_boundBox.R_right
		sub	ax, ds:[di].FR_boundBox.R_left
		cmp	ax, cx
		jbe	done
		mov	cx, ax
		
done:
		clc
		.leave
		ret
FolderRecordPositionNamesOnlyMode	endp


COMMENT @-------------------------------------------------------------------
			BuildBoundsNamesOnlyMode
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	FolderRecordPositionNamesOnlyMode

PASS:		ds:di	= FolderRecord
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/6/92		Initial version

---------------------------------------------------------------------------@
BuildBoundsNamesOnlyMode	proc	near
		uses	cx, dx
		.enter

		mov	ax, ss:[shortTextBoxHeight]
		sub	ax, TEXT_ICON_HEIGHT
		shr	ax, 1
		add	ax, ss:[buildListYPos]
		mov	ds:[di].FR_iconBounds.R_top, ax
		add	ax, TEXT_ICON_HEIGHT
		mov	ds:[di].FR_iconBounds.R_bottom, ax

		mov	ax, ss:[shortTextBoxHeight]
		sub	ax, ss:[desktopFontHeight]
		sar	ax, 1
		add	ax, ss:[buildListYPos]
		mov	ds:[di].FR_nameBounds.R_top, ax
		add	ax, ss:[desktopFontHeight]
		mov	ds:[di].FR_nameBounds.R_bottom, ax

		mov	ax, ss:[buildListXPos]
		mov	ds:[di].FR_iconBounds.R_left, ax
		add	ax, TEXT_ICON_WIDTH
		mov	ds:[di].FR_iconBounds.R_right, ax

		add	ax, TEXT_ICON_HORIZ_SPACING+1
		mov	ds:[di].FR_nameBounds.R_left, ax
		call	FolderRecordGetNameWidth	; dx = real name width
		add	ax, dx
		mov	ds:[di].FR_nameBounds.R_right, ax

		call	FolderRecordSetPositionCommon
		.leave
		ret
BuildBoundsNamesOnlyMode	endp


FolderCode ends




