COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) 1990 Geoworks -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		graphics
FILE:		graphicsChars.asm

AUTHOR:		Gene Anderson


ROUTINES:
---------
GLBL	GrSetFont		Sets a font for all further drawing.
GLBL	GrGetDefFontID		Returns the current default font ID and size.

GLBL	GrCallFontDriverID	Finds the correct font driver and calls it.

EXT	IsFontAvail		Looks through fontsAvail list for desired font.
EXT	IsFaceAvail		Checks if pointsize and style is available.
EXT	InvalidateFont		Mark font in GState invalid.
EXT	DeleteFontByHandle	Given a handle, find & delete FontsInUseEntry

INT	CheckCallDriver		Check for correct font driver and call it.
INT	FindFontDriver		Finds the correct font driver, if any.
INT	AddInUseEntry		Add entry for new font.
INT	ReloadFont		Reloads a font if the block is discarded.
INT	FindFont		Loads the desired font into memory.
INT	IsFontInUse		Searches for font ID in fontInUse list.
INT	ReallocFont		Allocates memory for a font, calls ReloadFont
INT	LockInfoBlock		NearPLock the font info block.
INT	UnlockInfoBlock		NearUnlockV the font info block.
INT	NearLockFont		Lock font with GState or Window
INT	LockWinFont		Lock font with Window


EXT	DrFontLockFont		Loads, locks the font for use in drawing.
EXT	DrFontUnlockFont	Unlock the font.

DESCRIPTION:
	This contains all the font management routines.  All of the font
	setting stuff should come through here.

	$Id: graphicsChars.asm,v 1.1 97/04/05 01:13:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a font for all further drawing.  If the desired font
		is not on disk, the current default font is used.

CALLED BY:	GLOBAL

PASS:		cx -- font (typeface) to use (FontID) (0 to not set)
		dx.ah -- pointsize to use (WBFixed) (0 to not set)
		di -- handle of GState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	11/22/88	Initial version
		Gene	4/24/89		new version for outline fonts
		Jim	10/10/89	fixed gstring stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetFont		proc	far
	push	ds
	call	LockDI_DS_check			;lock the GState, check
	pushf					;save GString flag
	;
	; Optimization: see if the font ID and pointsize aren't changed
	; from what is already in the GState.
	;
	cmp	ds:GS_fontAttr.FCA_fontID, cx	;using same ID?
	jne	diffFont			;   no, branch
	cmpwbf	ds:GS_fontAttr.FCA_pointsize, dxah
	je	sameFont			;branch if same pointsize
	;
	; The font and/or pointsize have changed, so invalidate the
	; font handle in the GState.
	;
diffFont:
	call	InvalidateFont			;invalidate font handle
	;
	; If setting the font, store the new value.
	;
	jcxz	skipSetFont			;branch if not setting font
	mov	ds:GS_fontAttr.FCA_fontID, cx	;store font ID
skipSetFont:
	;
	; If setting the pointsize, store the new value.
	;
	tst	dx				;setting pointsize?
	jz	skipSetSize			;branch if not setting pointsize
	movwbf	ds:GS_fontAttr.FCA_pointsize, dxah
skipSetSize:

sameFont:
	popf					;restore GString flag
	jnc	exit				;branch if normal draw operation
	;
	; Write info out to the GString
	;
	call	LibGSSetFont
exit:
	GOTO_ECN	UnlockDI_popDS, ds	;unlock the GState
GrSetFont	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetDefFontID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the default font ID and pointsize, as set up
		in the .ini file, as well as the handle for the
		data block.
CALLED BY:	GLOBAL

PASS:		nothing
RETURN:		cx -- default font ID (FontID)
		dx.ah -- default font pointsize (WBFixed)
		bx -- default font data handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	11/22/88	Initial version
		Gene	5/5/89		updated comments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetDefFontID	proc	far
	uses	ds
	.enter

	LoadVarSeg	ds			;ds <- idata seg addr
	mov	cx, ds:defaultFontID		;cx <- default font ID
	clr	ah
	mov	dx, ds:defaultFontSize		;dx.ah <- default font size
	mov	bx, ds:defaultFontHandle	;bx <- default font handle

	.leave
	ret
GrGetDefFontID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReloadFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Reload a bitmap face from a font file.

CALLED BY:	INTERNAL
		ReallocFont

PASS: 		ax - handle of font file
		bx - handle of font block (HM_addr NOT valid)
		ds:di - ptr to PointSizeEntry

RETURN: 	ax - seg addr of font block
		carry - set if file read fails

DESTROYED: 	ax, bx, cx, dx, si, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	11/22/88	Initial version
		Tony	12/88		Changed
		Gene	5/5/89		Added comments from Jim's code review
		Gene	8/89		New version for PLocking fonts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReloadFont	proc	near
	push	ax				;save file handle
	mov	ax, ds:[di].PSE_dataSize	;ax <- size to realloc
	mov	dx, ax
	mov	ch, HAF_STANDARD_NO_ERR_LOCK	;ch <- allocation flags
	call	MemReAlloc			;allocate new block
	pop	bx				;bx <- file handle

	push	ax				;save font seg addr
	push	dx				;save font size
	mov	cx, ds:[di].PSE_filePosHi	;cx <- offset (high)
	mov	dx, ds:[di].PSE_filePosLo	;dx <- offset (low)
	mov	al, FILE_POS_START		;al <- flag: absolute offset
	call	FilePosFar			;position the file

	pop	cx				;cx <- # bytes to read
	pop	ds				;ds <- seg addr of font
	clr	dx				;ds:dx <- buffer
	clr	al				;return errors
	call	FileReadFar			;read in the data

	mov	ax, ds				;ax <- seg addr of font
	ret
ReloadFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFontInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Check to see if a font/style/pointsize is already in use.

SYNOPSIS:	Searches for font ID in fontInUse list.   Opens the in-use
		chunk and searches for the font ID in the list.  If it finds
		the font and size desired, it returns the handle of the font
		data block.  It compares the font ID, the pointsize, any
		transformation, and the style.

CALLED BY:	INTERNAL: FindFont

PASS:		ds -- segment of font info block (P'd)
		cx -- font ID (FontID)
		al -- font style (TextStyle)
		es -- seg addr of GState
		bp:si -- ptr to transformation matrix (in window or gstate)

RETURN:		if found:
			carry - set
			bx - handle of font
			di - offset of FontsInUseEntry

DESTROYED:	bx, di (if not found)

PSEUDO CODE/STRATEGY:
       		open in-use chunk
		while not past end of chunk
			if entry's font ID, size, & transform match then return
			go to next entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	11/23/88	Initial version
		Gene	4/27/89		new version for outline fonts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsFontInUse	proc	near
	uses	es, si
transform	local	fptr.TMatrix	push	bp, si
	.enter

	push	ds
	mov	ds, ss:transform.segment	;ds:si <- ptr to TMatrix
	clr	bl				;bl <- no flags to check
	test	ds:[si].TM_flags, TM_COMPLEX	;see if complex transform
	pop	ds
	je	isSimple			;branch if simple transform
	mov	bl, mask FBF_IS_COMPLEX		;bl <- check complex flag
isSimple:
	;
	; Get the start & end of the chunk
	;
	mov	si, ds:[FONTS_IN_USE_HANDLE]	;si <- chunk handle
	ChunkSizePtr	ds, si, di		;di <- chunk size
	add	di, si				;di <- end of list ptr
IFIU_loop:
	cmp	si, di				;are we through the list?
	jae	endList				;if so, exit (carry clear)
	;
	; Is the entry valid?
	;
	tst	ds:[si].FIUE_dataHandle		;see if empty entry
	jz	noMatch				;branch if empty entry
	;
	; Do the FontID and TextStyle match?
	;
	cmp	ds:[si].FIUE_attrs.FCA_fontID, cx
	jne	noMatch				;no, branch
	cmp	ds:[si].FIUE_attrs.FCA_textStyle, al
	jne	noMatch				;no, branch
	;
	; Do the other font attributes match?
	; Compare everything except TextStyle, because those
	;    may include underline and/or strikethrough, which
	;    are done by the kernel so they always 'match'.
	; We've compared the TextStyle above, so they match.
	;
	push	cx, si, di
	add	si, offset FIUE_attrs		;ds:si <- ptr to entry attrs
	mov	di, offset GS_fontAttr		;es:di <- ptr to GState attrs
	mov	cx, (size FontCommonAttrs)-(size FCA_textStyle)
	;
	; The following CheckHack is to ensure that the
	; TextStyle are at the end of FontCommonAttrs.
	; We want to compare everything except those.
	;
CheckHack <(size FontCommonAttrs)-(size TextStyle) eq (offset FCA_textStyle)>
	repe	cmpsb				;compare me jesus
	pop	cx, si, di
	jne	noMatch				;branch if mismatch
	;
	; Are the transformations both simple?
	;
	mov	bh, ds:[si].FIUE_flags		;bh <- font flags
	cmp	bh, bl				;see if flags match
	jne	noMatch				;no, branch
	test	bl, mask FBF_IS_COMPLEX		;see if simple transform
	je	match				;yes, branch
	;
	; If the transformations are both complex, do they match?
	;
	push	es, si, di, cx			;save FIUE ptr, tmtrx ptr
	add	si, offset FIUE_matrix		;ds:si <- ptr to font trans
	les	di, ss:transform		;es:di <- ptr to current trans
	add	di, offset TM_11		;es:di <- ptr to cur trans
	mov	cx, (size WWFixed)*4/2		;cx <- # words to compare
	repe	cmpsw				;cmp ds:si to es:di
	pop	es, si, di, cx			;recover FIUE ptr, tmtrx ptr
	je	match				;branch if match
noMatch:
	add	si, size FontsInUseEntry	;else move to next entry
	jmp	IFIU_loop			;and loop

	;
	; Success!
	;
match:
	mov	bx, ds:[si].FIUE_dataHandle	;bx <- handle of font
	mov	di, si				;ds:di <- ptr to FIUE
	stc					;indicate found match
endList:

	.leave
	ret
IsFontInUse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFontAvail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks through fontsAvail list for desired font.
CALLED BY:	EXTERNAL:  InitDefaultFont, FindFont

PASS:		ds -- seg addr of font block (P'd)
		cx -- font ID (FontID)
RETURN:		if found:
			carry -- set
			ds:bx -- ptr to FontInfo chunk
			ds:di -- ptr to FontsAvailEntry
DESTROYED:	bx, di (if not found)

PSEUDO CODE/STRATEGY:
		If the font is found in the fontsAvail list (indicating
		is available on disk), it returns the chunk handle
		containing the header for the font.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	11/23/88	Initial version
		Gene	5/4/89		updated code, comments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarIsFontAvail	proc	far
	call	IsFontAvail
	ret
FarIsFontAvail	endp

IsFontAvail	proc	near
	uses	ax
	.enter

	mov	di, ds:[FONTS_AVAIL_HANDLE]	;di <- ptr to chunk
	ChunkSizePtr	ds, di, ax		;ax <- chunk size
	add	ax, di				;ax -> end of chunk
IFA_loop:
	cmp	di, ax				;are we thru the list?
	jae	noMatch				;yes, exit carry clear
	cmp	ds:[di].FAE_fontID, cx		;see if ID matches
	je	match				;we have a match, branch
	add	di, size FontsAvailEntry	;else move to next entry
	jmp	IFA_loop			;and loop

match:
	mov	bx, ds:[di].FAE_infoHandle	;bx <- chunk handle
	mov	bx, ds:[bx]			;ds:bx <- ptr to FontInfo
	stc					;indicate is available
noMatch:

	.leave
	ret
IsFontAvail		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFaceAvail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a point size and style of a font is available.
CALLED BY:	FindFont(), ReallocFont()

PASS:		ds:bx -- ptr to FontInfo
		al -- style (TextStyle)
		es - seg addr of GState
		bp:si -- ptr to TMatrix
RETURN:		carry set if size found, with:
			di -- ptr to PointSizeEntry
DESTROYED:	di (if size not found)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Chris	11/23/88	Initial version
		Gene	5/5/89		added comments from Jim's code review

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsFaceAvail	proc	near
	uses	ax, bx, dx
	.enter

	andnf   al, not KERNEL_STYLES
	mov	di, bx				;di <- ptr to chunk
	;
	; Is there a complex transformation?
	; If so, the face isn't here.
	;
	push	ds
	mov	ds, bp				;ds:si <- addr of xform
	test	ds:[si].TM_flags, TM_COMPLEX	;see if complex xform (clear c)
	pop	ds
	jne	endList				;no complex xforms in file
	;
	; Is there superscript, subscript, or a non-standard width or weight?
	; If so, the face isn't here, because those things aren't here...
	;
	test	al, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
	jnz	endList
	cmp	es:GS_fontAttr.FCA_width, FWI_MEDIUM
	jne	endList
	cmp	es:GS_fontAttr.FCA_weight, FW_NORMAL
	jne	endList
SBCS <	movwbf	dxah, es:GS_fontAttr.FCA_pointsize			>
DBCS <	mov	dl, es:GS_fontAttr.FCA_pointsize.WBF_int.low		>
DBCS <	mov	ah, es:GS_fontAttr.FCA_charSet				>
	;
	; Get pointers to the start & end of the pointsize table
	;
	add	bx, ds:[di].FI_pointSizeEnd	;bx <- ptr to end
	add	di, ds:[di].FI_pointSizeTab	;di <- ptr to size table

IFA_loop:
	cmp	di, bx				;see if at end of list
	jae	endList				;yes, branch (carry clear)
	;
	; Does the character set match?
	;
DBCS <	cmp	ds:[di].PSE_charSet, ah					>
DBCS <	jne	noMatch							>
	;
	; Does the TextStyle match?
	;
	cmp	ds:[di].PSE_style, al		;see if style matches
	jne	noMatch				;branch if not
	;
	; Pointsize match?
	;
SBCS <	cmpwbf	ds:[di].PSE_pointSize, dxah	;pointsize match?	>
DBCS <	cmp	ds:[di].PSE_pointSize, dl	;pointsize match?	>
	je	match				;branch if so
noMatch:
	add	di, size PointSizeEntry		;else move to next entry
	jmp	IFA_loop			;and loop

	;
	; Failure...
	;
endList:
	clc					;flag : not found
	jmp	done

	;
	; Success!
	;
match:
	stc					;flag : found.
done:

	.leave
	ret
IsFaceAvail	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a GState, finds and locks the font specified.  If the
		pointsize or transformation don't exist, then the font
		driver is called to generate the specified point size.

CALLED BY:	INTERNAL: NearLockFont()

PASS:		ds -- seg addr of GState (locked)
		bp:si -- addr of transform (in GState or Window)
RETURN:		bx -- handle of font
		if carry set:
			font found is default
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	NearPLock (font info blk);
	if (font in use) {
	    UseFont (font);
	} else {
	    if (font and pointsize available) {
		UseFont (font);
	    } else {
		if (driver and outline data available) {
		    BuildFont (font);
		} else {
		    UseFont (default font);
		}
	    }
	}
	NearUnlockV (font info blk);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: FontsInUseEntry for the default font is first
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		eca	5/ 4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindFont	proc	near
	uses	cx, dx, si, di, bp, es
	.enter

	;
	; Get the current attributes
	;
	call	GetFontVals
	;
	; Lock the font info block
	;
	clr	ds:GS_fontFlags			;no flags yet
	segmov	es, ds				;es <- seg addr of GState
	push	ds				;save GState seg
	call	LockInfoBlock			;lock the font info block
EC <	call	ECLMemValidateHeap		;check info block>

checkFont:
	call	IsFontInUse			;see if font is in use
	jc	lockFont			;branch if already in use
	call	IsFontAvail			;is font even available?
	jnc	noFont				;branch if not available
	call	IsFaceAvail			;see if size/style available
	jc	newFont				;branch if bitmap available
	tst	ds:[bx].FI_outlineEnd		;check outline data ptr
	jnz	newFont				;branch if outlines available
noFont:
	call	SubstituteFont			;substitute something close
	jmp	checkFont			;jmp back (font will be there)

newFont:
	call	AddInUseEntry			;mark font as in use
	mov	ax, FID_INIT_SIZE		;ax <- initial size
	mov	bx, FONT_MAN_ID			;bx <- new owner (font manager)
	mov	cx, FID_SET_FLAGS		;cl, ch <- allocate handle only
	call	MemAllocSetOwner		;allocate a block for the font
	mov	ds:[di].FIUE_dataHandle, bx	;store new handle
lockFont:
	inc	ds:[di].FIUE_refCount		;one more reference to handle
	mov	si, ds:[FONTS_IN_USE_HANDLE]	;si <- chunk address
	call	UnlockInfoBlock			;unlock font info block
	pop	ds				;ds <- seg addr of GState
	mov	ds:GS_fontHandle, bx		;save handle in GState
	sub	di, si				;di <- index of FontsInUseEntry
	mov	ds:GS_fontIndex, di		;save index of in use entry
	;
	; The Z flag will be set according to the subtraction
	; above, which return zero iff the FontsInUseEntry index
	; is zero, which means the font is the default font.
	; The C flag will always be clear.
	;
	jnz	notDefault			;branch if not default font
	ornf	ds:GS_fontFlags, mask FBF_DEFAULT_FONT
	stc					;indicate default font
notDefault:

	.leave
	ret
FindFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalidateFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the font in a gstate.
CALLED BY:	EXTERNAL

PASS:		ds - seg addr of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarInvalidateFont	proc	far
	call	InvalidateFont
	ret
FarInvalidateFont	endp

InvalidateFont	proc	near
	uses	ax
	.enter

	mov	ax, ds:GS_fontHandle		;ax <- handle of font
	tst	ax				;see if any font
	jz	done				;branch if no font in use
	test	ds:GS_fontFlags, mask FBF_DEFAULT_FONT
	jnz	isDefaultFont			;branch if default font

	push	ds, si
	mov	si, ds:GS_fontIndex		;si <- index of in use entry
	call	LockInfoBlock			;lock font info block
	xchg	ax, si				;ax <- offset of in use entry
	mov	si, ds:[FONTS_IN_USE_HANDLE]	;si <- chunk address
	add	si, ax				;si <- ptr to FontsInUseEntry
	dec	ds:[si].FIUE_refCount		;decrement reference count
EC <	ERROR_S FONTMAN_FONT_HAS_NEGATIVE_REFERENCE_COUNT		>
	call	UnlockInfoBlock			;unlock font info block
	pop	ds, si

isDefaultFont:
	clr	ds:GS_fontHandle		;invalidate font handle
done:
	.leave
	ret
InvalidateFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteFontByHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a font in the in use list by handle and delete it.
CALLED BY:	EXTERNAL: DoDiscardFont

PASS:		ax - handle of font to find
		ds - seg addr of font info block
RETURN:		z flag - set if deleted (ie. ref count == 0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteFontByHandle	proc	near
	uses	si
	.enter

	mov	si, ds:[FONTS_IN_USE_HANDLE]	;si <- chunk address
fontLoop:
	cmp	ds:[si].FIUE_dataHandle, ax	;see if correct handle
	je	found				;branch if correct handle
	add	si, size FontsInUseEntry	;advance to next entry
	jmp	fontLoop

found:
	tst	ds:[si].FIUE_refCount		;set z flag
	jnz	done				;branch if still references
	mov	ds:[si].FIUE_dataHandle, 0	;mark entry as empty
done:
	.leave
	ret

DeleteFontByHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockInfoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PLock the font info block
CALLED BY:	INTERNAL:

PASS:		none
RETURN:		ds - seg addr of font info block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarLockInfoBlock	proc	far
	call	LockInfoBlock
	ret
FarLockInfoBlock	endp
	public FarLockInfoBlock

LockInfoBlock	proc	near
	uses	ax, bx
	.enter

	LoadVarSeg	ds			;ds <- seg addr of idata
	mov	bx, ds:fontBlkHandle		;bx <- handle of font info blk
	call	MemThreadGrab			;lock the font info block
	mov	ds, ax				;ds <- seg addr of font info

	.leave
	ret
LockInfoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockInfoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	UnlockV the font info block
CALLED BY:	INTERNAL:

PASS:		none
RETURN:		none
DESTROYED:	none (even flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarUnlockInfoBlock	proc	far
	call	UnlockInfoBlock
	ret
FarUnlockInfoBlock	endp
	public FarUnlockInfoBlock

UnlockInfoBlock	proc	near
	uses	ax, bx, ds
	.enter

	LoadVarSeg	ds			;ds <- seg addr of idata
	mov	bx, ds:fontBlkHandle		;bx <- handle of font info blk
	call	MemThreadRelease		;preserves flags

	.leave
	ret
UnlockInfoBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFontVals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get font ID, size and style from GState
CALLED BY:	FindFont, ReallocFont

PASS:		ds - seg addr of GState
RETURN:		cx - FontID
		al - TextStyle (minus KERNEL_STYLES)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetFontVals	proc	near
	mov	cx, ds:GS_fontAttr.FCA_fontID	;cx <- fontID
	mov	al, ds:GS_fontAttr.FCA_textStyle
	and	al, not KERNEL_STYLES		;don't check underline, et al
	ret
GetFontVals	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SubstituteFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a replacement for a font/pointsize/style
CALLED BY:	FindFont(), ReallocFont()

PASS:		bp:si - ptr to TMatrix
		ds - seg addr of font block
		es - seg addr of GState
RETURN:		bp:si - ptr to (new) TMatrix
		cx - font to use (FontID)
		dx.ah - pointsize to use (WBFixed)
		al - style to use (TextStyle)
		carry - set if outline font substituted
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SubstituteFont	proc	near
	.enter

	call	LibFindBestFace			;find best font to use
	jc	notBitmap			;branch if substituted outline
	mov	si, offset defaultState.GS_TMatrix
	mov	bp, segment idata		;bp:si <- ptr to NULL transform
notBitmap:

	.leave
	ret
SubstituteFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for font driver, build new font if found.

CALLED BY:	INTERNAL: FindFont

PASS:		ds:di - ptr to FontInfo
		bx - handle of font
		cx - font ID (FontID)
		dx:ah - pointsize (WBFixed)
		al - style (TextStyle)
		font info block - P'd
		es - seg addr of GState
		bp:si - ptr to TMatrix

RETURN:		if found:
			carry - set
			ax - seg addr of font (P'locked)
			bx - handle of font
		else:
			error or driver not loaded

DESTROYED:	di; ax, bx (if no driver or data)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCallDriver	proc	near
	uses	cx
	.enter

	mov	ax, ds:[di].FI_maker		;ax <- font manufacturer
	mov	cx, si				;bp:cx <- ptr to transform
	mov	di, DR_FONT_GEN_WIDTHS		;di <- function to call
	call	GrCallFontDriverID

	.leave
	ret
CheckCallDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddInUseEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a FontsInUseEntry for a font
CALLED BY:	INTERNAL: FindFont, FindBitmapFont, FindOutlineFont
		EXTERNAL: InitDefaultFont

PASS:		ds -- segment of font info block (P'd)
		cx -- font ID (FontID)
		al -- font style (TextStyle)
		es -- seg addr of GState
		bp:si -- ptr to TMatrix (in window or gstate)

RETURN:		ds:di - ptr to new FontsInUseEntry
		(only FBF_IS_COMPLEX bit is valid in FIUE_flags)
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddInUseEntry	proc	near
	uses	es, cx
	.enter

	push	ax				;save TextStyle
	mov	di, FONTS_IN_USE_HANDLE 	;ds:di = in use fonts
	xchg	si, di
	call	ChunkSizeHandleDS_SI_CX		;cx <- chunk size
	xchg	si, di
	jcxz	addNewEntry			;branch if empty chunk
	;
	; Search the list for any empty entries.
	;
	mov	ax, ds:[FONTS_IN_USE_HANDLE]	;ax <- ptr to chunk
	mov	di, ax
	add	ax, cx				;ax <- ptr to end of chunk
checkList:
	cmp	di, ax				;end of list?
	jae	addNewEntry			;if so, add new entry
	tst	ds:[di].FIUE_dataHandle		;empty entry?
	jz	fillEntry			;if so, use it
	add	di, size FontsInUseEntry	;advance to next entry
	jmp	checkList			;loop while more entries

	;
	; No free entries in the list, so add one at the end.
	;
addNewEntry:
	push	cx				;save old size
	mov	ax, FONTS_IN_USE_HANDLE 	;ax <- lmem handle of FIU
	add	cx, size FontsInUseEntry	;make room for another entry
	call	LMemReAlloc			;resize the thing
	mov	di, ds:[FONTS_IN_USE_HANDLE]	;di <- ptr to chunk
	pop	cx				;cx <- size of old chunk
	add	di, cx				;di <- ptr to new FIUE
	;
	; Fill the (new) entry
	;
fillEntry:
	mov	ds:[di].FIUE_refCount, 0	;no references yet
	;
	; Copy the rest of the values 
	;
	push	ds, es, di, si
	segxchg	ds, es				;ds <- GState, es <- font info
	mov	si, offset GS_fontAttr		;ds:si <- ptr to attrs
	mov	cx, (size FontCommonAttrs)-(size FCA_textStyle)
CheckHack <(offset FIUE_attrs) eq 0>
CheckHack <(size FontCommonAttrs)-(size TextStyle) eq (offset FCA_textStyle)>
	rep	movsb
	pop	ds, es, di, si
	pop	ax
	mov	ds:[di].FIUE_attrs.FCA_textStyle, al
	
	;
	; A simple transformation or complex?
	;
	mov	es, bp				;es <- seg addr of xform
	mov	ds:[di].FIUE_flags, 0		;assume simple xform
	test	es:[si].TM_flags, TM_COMPLEX	;see if complex xform
	je	isSimple			;branch if is simple
	;
	; The transformation is complex -- copy the relevant portion
	; of the TMatrix in.
	;
	ornf	ds:[di].FIUE_flags, mask FBF_IS_COMPLEX	;complex xform
	push	ds, di
	segmov	es, ds				;es <- seg addr of FIUE
	mov	ds, bp				;ds <- seg addr of xform
	add	di, offset FIUE_matrix		;di <- offset of FIUE xform
	add	si, offset TM_11		;si <- offset to TM_11
	mov	cx, (size WWFixed)*4/2		;cx <- # words to copy
	rep	movsw				;copy xform into FIUE
	pop	ds, di
isSimple:

	.leave
	ret
AddInUseEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReallocFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Re-allocate memory for a font and read it in
CALLED BY:	INTERNAL
		FindFont, FastLock{GState,Win}Font (macros)

PASS:		bx -- handle of font
		bp:si -- ptr to TMatrix
		ds - seg addr of GState

RETURN: 	ax -- segment of font

DESTROYED: 	bp, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (simple transform) {
		if (font avail) {
			if (pointsize avail) {
				ReloadFont(fontID, pointsize);
			} else {
				callFontDriver(GEN_WIDTHS, fontID, pointsize);
			}
		} else {
			UseDefaultFont();
		}
	} else {
		FindUsageEntry(handle);
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version
	Gene	7/89		New version for outline fonts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ReallocFont	proc	near
	uses	bx, cx, dx, di, ds, es
	.enter

	push	bx				;save font handle
	call	GetFontVals			;get ID, size, style
	segmov	es, ds				;es <- seg addr of gstate
	call	LockInfoBlock			;lock font info blk
	test	es:GS_fontFlags, mask FBF_MAPPED_FONT
	jz	afterSubstitute
	call	SubstituteFont			;find substituted font
afterSubstitute:
	call	IsFontAvail			;see if font available
NEC <	jnc	useDefaultFont			;>
EC <	WARNING_NC FONTMAN_IN_USE_FONT_FILE_DELETED	;>

	call	EnsureFontFileOpen
NEC <	jc	useDefaultFont			;>
EC <	ERROR_C	FONTMAN_COULDNT_OPEN_FONT_FILE	;>

	call	IsFaceAvail			;see if face available
	jnc	isComplexFont			;no such pointsize
	mov	ax, ds:[bx].FI_fileHandle	;ax <- file handle
	pop	bx				;bx <- handle of font
	call	ReloadFont			;reload font from file
NEC <	jc	useDefaultFontNoPop		;use default if read failed>
EC <	ERROR_C	FONTMAN_BAD_FONT_FILE_READ	;>
done:
	call	UnlockInfoBlock

	.leave
	ret

	;
	; The font has a complex transformation. We need to
	; call the font driver to build this font.
	;
isComplexFont:
	mov	di, bx				;di <- ptr to FontInfo chunk
	pop	bx				;bx <- handle of font
	call	CheckCallDriver			;rebuild font
	jnc	done
NEC <	jmp	useDefaultFontNoPop		;>
EC <	ERROR	FONTMAN_FONT_DRIVER_NOT_FOUND	;>

	;
	; Either:
	;  (a) the font can't be found
	;  (b) the pointsize/style can't be found
	;  (c) the font driver can't be found
	;  (d) the outline data can't be found
	; Any of these things at this point is a bad thing.
	; Use the default font, because that's always in memory
	;
NEC <useDefaultFont:				>
NEC <	pop	bx				;bx <- handle of font block>
NEC <useDefaultFontNoPop:			>
NEC <	call	HandleV				;can't realloc, so release it>
NEC <	call	GrGetDefFontID			;get default font ID,handle >
NEC <	call	NearLock			;lock the default font >
NEC <	jmp	done				>
ReallocFont	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FontDrEnsureFontFileOpen

DESCRIPTION:	Ensure that the font file for the given font is open

CALLED BY:	EXTERNAL

PASS:
	ds - font block (locked)
	cx - font ID

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NOTE: ds cannot be changed by this routine, since ds:si and ds:bx
	are expected to still be valid after the call.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

FontDrEnsureFontFileOpen	proc	far	uses bx, di
	.enter

	call	IsFontAvail
EC <	ERROR_NC FONTMAN_FILE_CACHE_CORRUPTED				>

	call	EnsureFontFileOpen
EC <	ERROR_C	FONTMAN_FILE_CACHE_CORRUPTED				>

	.leave
	ret

FontDrEnsureFontFileOpen	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureFontFileOpen

DESCRIPTION:	Ensure that the font file for the given font is open

CALLED BY:	EXTERNAL

PASS:
	ds - font block (locked)
	ds:di - ptr to FontsAvailEntry
	ds:bx - ptr to FontInfo entry

RETURN:
	carry - set if error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NOTE: ds cannot be changed by this routine, since ds:si and ds:bx
	are expected to still be valid after the call.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

EnsureFontFileOpen	proc	far
	uses ax, dx

	tst	ds:[bx].FI_fileHandle		;clears carry
	jnz	exit

	tst	{char}ds:[di].FAE_fileName	;clears carry
	jz	exit

	.enter

	call	FilePushDir
	mov	ax, SP_FONT
	call	FileSetStandardPath

	push	{word} ds:[di+FONT_FILE_LENGTH].FAE_fileName
	mov	{char} ds:[di+FONT_FILE_LENGTH].FAE_fileName, 0
	lea	dx, ds:[di].FAE_fileName
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call	FileOpen
	pop	{word} ds:[di+FONT_FILE_LENGTH].FAE_fileName
	call	FilePopDir
	jc	done
	mov	ds:[bx].FI_fileHandle, ax

	; make file owned by kernel

	push	ds
	LoadVarSeg	ds
	xchg	ax, bx				;bx = file handle
	call	SetOwnerToKernel
	xchg	ax, bx				;restore bx
	pop	ds
	;
	; Record that the file is open in our font cache, and close
	; a file if this puts us at the limit.
	;
	call	RecordNewFontFile
	clc					;carry <- no error
done:
	.leave
exit:
	ret

EnsureFontFileOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordNewFontFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record that a new font file is open, closing an old one
		if necessary to keep the total within limits.

CALLED BY:	EnsureFontFileOpen()
PASS:		ds - locked (P'd)
		ds:bx - FontInfo for font
		ds:di - FontsAvailEntry
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	NOTE: ds cannot be changed by this routine, since ds:si and ds:bx
	are expected to still be valid after the call.  This is dealt with
	by initially allocing the chunk as big as we need it, and then
	never resizing it.  Not as space efficient, but...
	
	The cache is an array of FontID values corresponding to the font
	files that are currently open.  FontIDs are stored rather than the
	file handles because there is an existing routine to get a font
	given its FontID, but no such routine for font file handles.

	The array has the oldest file at the start, with newer files
	working backward.  Empty slots have FID_INVALID (=0) to mark them.
	If a font that was open is deleted via FontDrDeleteFont(), its
	entry will be left open in the middle of the cache for use by the
	next font file opened.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordNewFontFile		proc	near
	uses	bx, cx, si, di, es
	.enter

CheckHack <FID_INVALID eq 0>
CheckHack <(size FontID) eq 2>
	push	ds:[di].FAE_fontID		;save ID of new font
	;
	; Scan for an open slot
	;
	mov	si, ds:[FONT_FILE_CACHE_HANDLE]	;ds:si <- ptr to cache
	mov	cx, ds:[si].LMC_size		;cx <- chunk size (w/size word)
	shr	cx, 1				;working with words
	dec	cx				;cx <- # of entries
	mov	di, si
	push	cx				;save # of entries
	segmov	es, ds				;es:di <- ptr to cache
	clr	ax
	repne	scasw				;scan for first open slot
	jne	tooManyFiles			;branch if no empty slot
	pop	cx				;don't need size
	;
	; Success!  Store the font ID
	;
CheckHack <(size FontID) eq 2>
	dec	di
	dec	di				;scasw goes one beyond...
storeID:
	pop	ds:[di]				;store ID in open slot

	.leave
	ret

	;
	; ds:si - ptr to first element
	; es - =ds
	; ax - =0
	; on stack: # of entries
	;
tooManyFiles:
	;
	; Find and close the oldest file
	;
	mov	cx, ds:[si]			;cx <- FontID
	call	IsFontAvail
EC <	ERROR_NC FONTMAN_FILE_CACHE_CORRUPTED	;>
	xchg	ax, ds:[bx].FI_fileHandle	;ax <- handle; field cleared
EC <	tst	ax				;>
EC <	ERROR_Z FONTMAN_FILE_CACHE_CORRUPTED	;>
	mov_tr	bx, ax				;bx <- file handle
	clr	al				;al <- flags
	call	FileCloseFar
	;
	; Make room in our cache for the new ID by shifting the elements.
	;
	pop	cx				;cx <- # of entries
	mov	di, si				;ds:di <- ptr to element[0]
CheckHack <(size FontID) eq 2>
	inc	si
	inc	si				;ds:si <- ptr to element[1]
	dec	cx				;cx <- # elements - 1
	rep	movsw				;shift me jesus
	;
	; Store the new font at the end of the cache, which is
	; where ds:di now points after the rep movsw above...
	;
	jmp	storeID
RecordNewFontFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCallFontDriverID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call particular font driver, with the font already locked
CALLED BY:	GLOBAL

PASS:		di - function to call (FontFunction)
		ax - font driver ID (FontMaker)
		rest - depends on function called
		       (can be bx, cx, dx, bp)
RETURN:		carry - set if error
DESTROYED:	depends on function

PSEUDO CODE/STRATEGY:
	PLock the font info block
	search the drivers available list
	call driver strategy
	UnlockV the font info block
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCallFontDriverID	proc	far
	uses	ds, si
	.enter

	call	LockInfoBlock			;lock font info block
	call	FindFontDriver			;find correct driver
	cmc
	jc	noDriver			;branch if driver not found
	call	ds:[si].DAE_strategy		;call the font driver
noDriver:
	call	UnlockInfoBlock			;unlock font info block

	.leave
	ret
GrCallFontDriverID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFontDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the correct font driver for a given font.

CALLED BY:	INTERNAL: GrCallFontDriver, FindFont

PASS:		ds - seg addr of font info block (P'd)
		ax - manufacturer ID

RETURN:		ds:si - addr of DriversAvailEntry w/correct strategy
		carry - set if driver found

DESTROYED:	none (si if no driver found)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindFontDriver	proc	near
	push	bx
	mov	si, ds:[FONT_DRIVERS_HANDLE]	;si <- ptr to DAE list
	cmp	si, 0ffffh			;see if empty list
	clc					;assume empty
	je	FFD_noMatch			;branch if empty list
	ChunkSizePtr	ds, si, bx		;bx <- chunk size
	add	bx, si				;bx <- ptr to end of chunk
FFD_loop:
	cmp	si, bx				;are we through the list?
	jae	FFD_noMatch			;if so, exit (carry clear)
	cmp	ds:[si].FAE_fontID, ax		;see if ID matches
	je	FFD_match			;we have a match, branch
	add	si, size DriversAvailEntry	;else move to next entry
	jmp	short FFD_loop			;and loop
FFD_match:
	stc					;indicate driver found
FFD_noMatch:
	pop	bx
	ret
FindFontDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFontGStateDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads and locks font given an unlocked GState
CALLED BY:	EXTERNAL

PASS:		di - handle of GState
RETURN:		ds -- segment addr of font (locked)
		bx -- handle of font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockFontGStateDS	proc	far
	uses	ax
	.enter

	mov	bx, di				;bx <- handle of GState
	call	NearLockDS			;ds <- seg addr of GState
	call	NearLockFont			;ax <- seg addr of font
	mov	ds, ax				;ds <- seg addr of font
	xchg	bx, di				;bx <- handle of GState
	call	NearUnlock			;unlock GState
	xchg	bx, di				;bx <- handle of font

	.leave
	ret
LockFontGStateDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrLockFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the font given in a graphics state is loaded.
CALLED BY:	GLOBAL (font drivers)

PASS:		ds -- segment of GState
RETURN:		ax -- segment addr of font (locked)
		bx -- handle of font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: this routine should only be called by font drivers
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrLockFont	proc	far
	call	NearLockFont
	ret
FontDrLockFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NearLockFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the font given in a graphics state is loaded.
CALLED BY:	INTERNAL

PASS:		ds -- segment of GState
RETURN:		ax -- segment addr of font (locked)
		bx -- handle of font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	The font might not have been determined (NULL handle),
	or the font may have been determined (used previously)
	but has been discarded.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NearLockFont	proc	near
	uses	bp, si
	.enter

	mov	bx, ds:GS_window		;bx <- handle of Window
	tst	bx				;any Window?
	jnz	hasWindow
	mov	bp, ds
	mov	si, offset GS_TMatrix		;bp:si <- ptr to TMatrix
	call	DoFontLock
afterLock:

	.leave
	ret

hasWindow:
	push	cx, es
	call	NearPLockES			;PLock Window
	push	bx
	call	LockWinFont			;w/Window locked, find font
	mov	cx, bx
	pop	bx				;bx <- handle of Window
	call	NearUnlockV
	mov	bx, cx				;bx <- handle of font
	pop	cx, es
	jmp	afterLock
NearLockFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFontLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the internals of locking a font.
CALLED BY:	INTERNAL:

PASS:		ds - seg addr of GState
		bp:si - ptr to TMatrix (in Window or GState)
RETURN:		bx - handle of font
		ax - seg addr of font
DESTROYED:	bp, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoFontLock	proc	near
EC <	call	ECCheckFonts						>
	;
	;	check to see if the font is still valid
	;
	mov	ax,ds:GS_fontIndex
	push	di,es
	segmov	es,ds				;es <- handle to gstate
	call 	LockInfoBlock			;ds <- handle to FontInfoBlock
	mov	di,FONTS_IN_USE_HANDLE
	mov	di,ds:[di]
	add	di,ax
	test	ds:[di].FIUE_flags, mask FBF_IS_INVALID
	jz	valid
notValid::
	segxchg	es,ds				;es <- handle to FontInfoBlock
						;ds <- handle to gstate
	call	InvalidateFont
	segxchg	es,ds
	;
	; if the font is not valid check to see if there are any
	; references to it left
	;
	tst	ds:[di].FIUE_refCount
	jz	freeFont
	jmp 	cont	
freeFont:
	;
	; if there are no references to the font, free the font data
	;
	clr	bx
	xchg	bx,ds:[di].FIUE_dataHandle
	call	MemFree
cont:
valid:	
	call	UnlockInfoBlock
	segmov	ds,es				;ds <- gstate handle
	pop	di,es

	;
	; See if the font is known or not.
	;
	mov	bx, ds:GS_fontHandle		;bx <- handle of font
	tst	bx				;font valid?
	jz	findFont	      		;branch if font unknown
	;
	; If the font is the default font, just lock it, don't P it.
	; This is to speed things along and avoid deadlock.
	;
	test	ds:GS_fontFlags, mask FBF_DEFAULT_FONT
	jnz	isDefault
	call	HandleP				;P the font handle
isDefault:
	call	NearLock			;lock the font block
	jc	loadFont			;branch if discarded
	ret

	;
	; The font is unknown (ie. there is no data handle)
	;
findFont:
	call	FindFont			;find font to use
	jc	foundDefault			;branch if default font
	;
	; As above, just lock the default font, don't P it.
	;
	call	HandleP				;P the font handle
foundDefault:
	call	NearLock			;lock the font block
	jnc	updateOpts			;branch if not discarded
	;
	; The lock failed, meaning the font is discarded.
	;
loadFont:
	call	ReallocFont			;realloc memory, load font
	;
	; Finally, we need to update the various optimizations
	; related to fonts in the GState.
	;
updateOpts:
	REAL_FALL_THRU	UpdateFontOpts
DoFontLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFontOpts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update font-related optimizations in the GState
CALLED BY:	DoFontLock()

PASS:		ds - seg addr of GState
		ax - seg addr of font
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: FBF_DEFAULT_FONT is not updated. If the font is
	the default font, this must be updated.
	If you make changes here, you will probably want to make
	similar changes to UpdateDefFontOpts() in the init code
	which initializes the default GState.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateFontOpts	proc	near
	uses	ax, es
	.enter

EC <	call	ECCheckFontBufAX					>
	mov	es, ax				;es <- seg addr of font
	;
	; stuff font height, first and last character...
	;
	mov	ax, es:FB_pixHeight		;ax <- pixel height
	mov	ds:GS_pixelHeightM1, ax
SBCS <	mov	ax, {word}es:FB_firstChar	;al,ah <- first, last char >
SBCS <	mov	{word}ds:GS_fontFirstChar, ax				>
DBCS <	mov	al, es:FB_firstChar.high				>
DBCS <	mov	ds:GS_fontAttr.FCA_charSet, al				>
	;
	; set opcode if a complex transform is in use...
	;
	mov	al, GO_SPECIAL_CASE		;al <- complex transform
	test	es:FB_flags, mask FBF_IS_COMPLEX
	jnz	isComplex			;branch if complex xform
	mov	al, GO_FALL_THRU		;al <- simple transform
isComplex:
	mov	ds:GS_complexOpcode, al		;store optimization
	;
	; stuff minimum left side bearing for clipping checks...
	;
	mov	ax, es:FB_minLSB		;ax <- min LSB
	mov	ds:GS_minLSB, ax
	mov	ax, es:FB_minTSB		;ax <- min TSB
	mov	ds:GS_minTSB, ax
	;
	; set bits if track kerning or pairwise kerning
	;
	andnf	ds:GS_textMode, not TM_KERNING	;assume no kerning
	mov	al, GO_FALL_THRU		;al <- opcode for no JMP
	tst	es:FB_kernCount			;see if any pair kerning info
	jz	noKernInfo			;branch if no info
	ornf	ds:GS_textMode, mask TM_PAIR_KERN
	mov	al, GO_SPECIAL_CASE		;al <- opcode for JMP
noKernInfo:
	mov	ds:GS_kernOp, al
	tst	{word}ds:GS_trackKernDegree	;see if track kerning
	jz	afterKern			;branch if no track kerning
	call	RecalcKernValues		;recalc track kerning
afterKern:
	mov	al, ds:GS_fontFlags
	andnf	al, FONT_GS_FLAGS		;keep internal bits
	ornf	al, es:FB_flags			;combine with fonts flags
	mov	ds:GS_fontFlags, al		;save font flags

	.leave
	ret
UpdateFontOpts	endp

RecalcKernValues	proc	near
	.enter
	call	LibRecalcKernValues		;calculate kerning value
	.leave
	ret
RecalcKernValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockWinFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	With locked Window, find and lock a font
CALLED BY:	INTERAL: NearLockFont

PASS:		ds - seg addr of GState
		es - seg addr of Window
RETURN:		ax - seg addr of font
		bx - handle of font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 9/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarLockWinFont	proc	far
	call	LockWinFont
	ret
FarLockWinFont	endp

LockWinFont	proc	near
	uses	bp, si
	.enter

	mov	ax, ds:LMBH_handle		;ax <- our GState handle
	cmp	ax, es:W_curState		;see if current in window
	pushf					;save comparison flags
	jne	matrixInvalid			;if not, matrix invalid
	test	es:W_grFlags, mask WGF_XFORM_VALID
	jne	matrixOK
matrixInvalid:
	push	cx, dx, di			;trashed by GrComposeMatrix
	call	GrComposeMatrix			;update xform matrix
	pop	cx, dx, di
matrixOK:
	mov	bp, es
	mov	si, offset W_curTMatrix		;bp:si <- addr of xform
	call	DoFontLock
	;
	; If this GState isn't the one current in the window, make darn
	; sure to mark the transformation invalid. We can't just make the
	; passed state the current one b/c we've not done anything about
	; the mask region, so...
	;
	popf					;cmp  LMBH_handle, W_curState
	je	leaveMatrixOK
	andnf	es:W_grFlags, not mask WGF_XFORM_VALID
leaveMatrixOK:

	.leave
	ret
LockWinFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrUnlockFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the font in a gstate.
CALLED BY:	GLOBAL (font drivers)

PASS:		bx - handle of font
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: this routine should only be called by font drivers
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrUnlockFont	proc	far
	call	NearUnlockFont
	ret
FontDrUnlockFont	endp

if DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockFontFromGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the current font given a GState

CALLED BY:	EXTERNAL
PASS:		ds - seg addr of GState
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockFontFromGState		proc	near
	mov	bx, ds:GS_fontHandle		;bx <- handle of font
	FALL_THRU	NearUnlockFont
UnlockFontFromGState		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NearUnlockFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the font in a gstate.
CALLED BY:	EXTERNAL: GrGetFontInfo, GrGetCharInfo

PASS:		bx - handle of font
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NearUnlockFont	proc	near
	uses	ds
	.enter

EC <	push	ax							>
EC <	call	MemDerefDS						>
EC <	mov	ax, ds				;ax <- seg addr of font	>
EC <	call	ECCheckFontBufAX					>
EC <	pop	ax							>

	call	NearUnlock			;unlock the font block
	LoadVarSeg	ds			;ds <- seg addr of idata
	cmp	bx, ds:defaultFontHandle	;default font?
	je	done				;branch if default font
	call	HandleV				;V the font handle
done:

	.leave
	ret
NearUnlockFont	endp

if DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrLockCharSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the current font and lock a different character set

CALLED BY:	GLOBAL (video drivers)
PASS:		ds - seg addr of GState
		dx - character to lock font for (Chars)
RETURN:		ax - new font seg addr
		carry - set if char does not exist
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: must be called with Window locked, or death awaits...
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrLockCharSet		proc	far
		mov	ax, dx			;dx <- Chars value
	;
	; Unlock and invalidate the old font
	;
		call	LockCharSetCommon
		jc	done			;branch if default char used
	;
	; Get the Window seg addr
	;
		push	bx, es
		mov	bx, ds:GS_window	;bx <- Window handle
		call	MemDerefES		;es <- seg addr of Window
	;
	; Lock the new font
	;
		call	LockWinFont
		pop	bx, es
	;
	; See if we've found anything
	;
		cmp	dh, ds:GS_fontAttr.FCA_charSet
		stc				;carry <- char does not exist
		jne	done			;branch if not found
		clc				;carry <- char exists
done:
		ret
FontDrLockCharSet		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockCharSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the current font and lock a different character section

CALLED BY:	EXTERNAL (GrTextWidthWBFixed())
PASS:		ds - seg addr of GState
		ax - character to lock font for (Chars)
RETURN:		ax - new font seg addr
		carry - set if char does not exist
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: do not call with the Window locked, or deadlock awaits...
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockCharSetFar		proc	far
		call	LockCharSet
		ret
LockCharSetFar		endp

LockCharSet		proc	near
		uses	dx
		.enter
		mov	dx, ax			;dx <- Chars value
	;
	; Unlock and invalidate the old font
	;
		call	LockCharSetCommon
		jc	done			;branch if default char used
	;
	; Lock the new font
	;
		push	bx
		call	NearLockFont
		pop	bx
	;
	; See if we've found anything
	;
		cmp	dh, ds:GS_fontAttr.FCA_charSet
		stc				;carry <- char does not exist
		jne	done			;branch if not found
		clc				;carry <- char exists
done:
		.leave
		ret
LockCharSet		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockCharSetCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to unlock a font and lock a new section

CALLED BY:	FontDrLockCharSet(), LockCharSet()
PASS:		ds - seg addr of GState
		ax - character to lock font for (Chars)
RETURN:		carry - set if char does not exist
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	7/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockCharSetCommon		proc	near
		uses	bx
		.enter

		mov	bx, ds:GS_fontHandle
	;
	; See if the character does not exist
	;
		cmp	ah, ds:GS_fontAttr.FCA_charSet
		je	charNoExist
	;
	; Unlock the old font
	;
		call	NearUnlockFont
	;
	; Invalidate the old font
	;
		call	InvalidateFont
	;
	; Set the character set
	;
		mov	ds:GS_fontAttr.FCA_charSet, ah
		clc				;carry <- default not used

done:
		.leave
		ret

	;
	; The character does not exist -- return the current font.
	;
charNoExist:
		mov	ax, MGIT_ADDRESS
		call	MemGetInfo		;ax <- seg addr of font
		stc				;carry <- char does not exist
		jmp	done
LockCharSetCommon		endp

endif


if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFontBufAX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a font is valid

CALLED BY:	ECCheckFonts()
PASS:		ax - seg addr of FontBuf
RETURN:		none
DESTROYED:	none (flags destroyed)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/30/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckFontBufAX		proc	far
		uses	ds, bx, ax, cx, si, di
		.enter

		mov	ds, ax
	;
	; See if we should bother with EC
	;
		call	SysGetECLevel
		test	ax, mask ECF_GRAPHICS
		jz	quit
	;
	; Check some values in the font header
	;
		mov	ax, ds:FB_maker
		test	ax, 0x0fff
		ERROR_NZ FONTMAN_FONT_BUF_CORRUPTED
	;
	; Set up for loop and check # of characters
	;
DBCS <		mov	cx, ds:FB_lastChar				>
SBCS <		mov	cl, ds:FB_lastChar				>
DBCS <		cmp	cx, ds:FB_firstChar				>
SBCS <		cmp	cl, ds:FB_firstChar				>
		ERROR_B FONTMAN_FONT_BUF_CORRUPTED
DBCS <		sub	cx, ds:FB_firstChar				>
SBCS <		sub	cl, ds:FB_firstChar				>
SBCS <		clr	ch						>
		inc	cx				;cx <- # of chars
		clr	si
charLoop:
	;
	; Get the pointer to the char data, if any
	;
		mov	di, ds:FB_charTable[si].CTE_dataOffset
		cmp	di, CHAR_MISSING
		jbe	nextChar
	;
	; Verify the pointer is within the block size
	;
		cmp	di, ds:FB_dataSize
		ERROR_AE FONTMAN_FONT_BUF_CORRUPTED
	;
	; Make sure the pointer + data is within the block size
	;
		mov	al, ds:[di].CD_pictureWidth
		add	al, 0x7
		shr	al, 1
		shr	al, 1
		shr	al, 1				;al <- byte width
		mul	ds:[di].CD_numRows		;ax <- data size
		add	ax, (size CharData)-1
		cmp	ax, ds:FB_dataSize
		ERROR_AE FONTMAN_FONT_BUF_CORRUPTED
	;
	; Go to the next char
	;
nextChar:
		add	si, (size CharTableEntry)
		loop	charLoop
quit:

		.leave
		ret
ECCheckFontBufAX		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify all fonts in memory

CALLED BY:	(f)utility
PASS:		none
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/30/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFonts		proc	far
		uses	ax, bx, si, di, ds
		.enter

		pushf
	;
	; See if we should bother with EC
	;
		call	SysGetECLevel
		test	ax, mask ECF_GRAPHICS
		jz	quit
	;
	; Get the font info block and the in use chunk
	;
		call	LockInfoBlock
		mov	si, ds:[FONTS_IN_USE_HANDLE]
		ChunkSizePtr	ds, si, di	;di <- chunk size
		add	di, si			;di <- end of list ptr
	;
	; Loop through all fonts in use
	;
IFIU_loop:
		cmp	si, di			;are we through the list?
		jae	endList			;if so, exit
	;
	; See if entry is in use
	;
		mov	bx, ds:[si].FIUE_dataHandle
		tst	bx			;any handle?
		jz	nextEntry		;branch if not
	;
	; See if block is in memory
	;
		mov	ax, MGIT_ADDRESS	;ax <- MemGetInfoType
		call	MemGetInfo
		tst	ax			;block in memory?
		jz	nextEntry		;branch if not
	;
	; See if the FontBuf is valid
	;
		call	ECCheckFontBufAX
	;
	; Go to next entry
	;
nextEntry:
		add	si, (size FontsInUseEntry)
		jmp	IFIU_loop

	;
	; Done with the font info block
	;
endList:
		call	UnlockInfoBlock
quit:
		popf

		.leave
		ret
ECCheckFonts		endp

endif
