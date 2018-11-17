COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Print Driver
FILE:		fontTopLevelPCL4.asm

AUTHOR:		Gene Anderson, Apr 13, 1990
		Dave Durran April 16, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	FontInit		Init font structures and printer fonts.
EXT	FontExit		Free font structures.

EXT	FontStartPage		Notify manager of page start.
EXT	FontAddFace		Add font to LaserJet.
EXT	FontAddChar		Add character to existing font.

INT	FontSetAttrs		Set font attributes in printer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/13/90		Initial revision
	Dave	8/91		New Initial versions
	Dave	1/92		Moved from Laserdwn

NOTES:
		All soft fonts are deleted from the printer
	during initialization.
---------------------------------------------Changed to be re-entrant------
		Also, this code is currently non-reentrant. The
	soft-font manager keeps a block of information around
	regarding which fonts are in the printer.
------------------------------------------------------Dave Durran----------
		The PState segment address is stored in the stack frame
	at the beginning of each of the ext. routines. This variable space is
	passed down to the various subroutines.

DESCRIPTION:
	External routines for dealing with HP downloadable soft fonts.

	$Id: fontTopLevelPCL4.asm,v 1.1 97/04/18 11:49:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the soft-font manager.
CALLED BY:	EXTERNAL: In PrintStartJob once a Job

PASS: 		es	- PState segment
RETURN: 	if carry clear:
		    PS_expansionInfo - handle of font manager data block
		else:
		    error occurred
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Should be called once for the life of the printer driver,
	as it nukes any existing soft fonts, and allocates a
	font info block to track which fonts and characters are
	in the printer.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/13/90		Initial version
	Dave	8/91		New Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontInit	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
curJob	local	FontDriverInfo
	.enter
	mov	es:[PS_previousAttribute],0ffffh ;init previous attribute
	mov	curJob.FDI_pstate,es

		; Allocate an LMem heap for tracking printer fonts:
	mov	cx, size HPFontInfo		;cx <- size of block
	mov	ax, LMEM_TYPE_GENERAL		;ax <- type of lmem heap
	call	MemAllocLMem			;allocate block for lmem heap
	mov	es:PS_expansionInfo, bx		;save handle of manager block

                ;we have our lmem block, now create the structures within.
        call    MemLock                 	;lock it down
	mov	ds, ax				;ds <- seg addr of block
	
		; Allocate a chunk arr. for a list of fonts in the printer:
        mov     bx,size SoftFontEntry           ;store the size of elements.
        clr     cx                   		;default ChunkArrayHeader.
        mov     si,cx                  		;new chunk.
        mov     al, mask OCF_IGNORE_DIRTY
        call    ChunkArrayCreate        ;do it.
	mov	ds:HPFI_fontEntries, si		;store handle

	clr	ax
	mov	ds:HPFI_numFonts, ax		;no fonts in printer yet
	mov	ds:HPFI_heapCount, ax		;init heap counter
	mov	ds:HPFI_allocID, INITIAL_HP_FONT_ID	;init font ID count

		;add the maximums for this printer.
	mov	es, curJob.FDI_pstate
	mov	bx,es:PS_deviceInfo		;get handle of device spec.
	call	MemLock				;data and lock it down.
	mov	es,ax				;address into es.
	mov	si,es:PI_fontGeometries		;get pointer to font geometry
	mov	ax,es:[si].DP_maxNumFonts	;load from info resource..
	mov	ds:HPFI_maxNumFonts,ax		;set in font block.
	mov	ax,es:[si].DP_maxPointsize	;load from info resource..
	mov	ds:HPFI_maxPointsize,ax		;set in font block.
        call    MemUnlock			;get rid of device info

	clr	ds:HPFI_fontMemory.low
	clr	ds:HPFI_fontMemory.high		;no memory used yet

	mov	es, curJob.FDI_pstate
	clr	ax				;init the PState variables
	mov	es:PS_curOptFont.OFE_spacePad,ax	;+
	mov	es:PS_curOptFont.OFE_trackKern,ax		;+

		;set up a VM file for the bitmap routines.
                ;From spooler to create a very wastefully huge array
                ;bitmap for each band. Yech!
        call    FilePushDir                     ; save dir state
        mov     ax, SP_SPOOL                    ; go to spool directory
        call    FileSetStandardPath

        push    ds
        segmov  ds, cs
        mov     dx, offset cbFileName           ; vm file to open
        mov     ah, VMO_CREATE_TRUNCATE
        clr     al
        clr     cx
        call    VMOpen
EC <    ERROR_C DRIVER_CANT_CREATE_VIDMEM_FILE                   >
        pop     ds
        mov     ds:HPFI_bmFileHandle, bx        ; save file handle
        call    FilePopDir                      ; restore directory

	mov	bx, es:PS_expansionInfo		;get handle of manager block
	call	MemUnlock			;unlock it for generousity.
	clc					;indicate no error

	.leave
	ret
FontInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free data structures used by soft-font manager.
CALLED BY:	EXTERNAL: in PrintEndJob once at end of Job.

PASS:		bp - Pstate segment 
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/18/90		Initial version
	Dave	8/91		New Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontExit	proc	near
	uses	di, es, bx
	.enter

	mov	es, bp				;ds <- seg addr of pstate
	mov	bx, es:PS_expansionInfo		;bx <- handle of manager block
	test	bx,bx				;see if zero.
	jz	exit				;already free.

        call    MemLock                         ;lock it down
        mov     ds, ax                          ;ds <- seg addr of block

		;get rid of all our fonts in the printer.
	mov	ax,ds:HPFI_allocID             ;ax <- last font ID
deleteLoop:
	cmp	ax,INITIAL_HP_FONT_ID		;see if at start.
	je	nukeVMFile			;if so, exit loop...
	push	ax
	mov	di,offset pr_codes_SetFontID
	call	WriteNumCommand			;set this font active...
	jc	adjustStack
	mov	al,HPFC_DELETE_SOFT_FONT	;and....
	mov	di,offset pr_codes_FontControl
	call	WriteNumByteCommand		;nuke it from the printer.
adjustStack:
	pop	ax
	jc	errExit				;pass transmission error out
	dec	ax				;point at next font ID
	jmp	deleteLoop

		;close the VM file here too.
nukeVMFile:
	mov	bx,ds:HPFI_bmFileHandle		;get the file handle
	mov	al, FILE_NO_ERRORS
        call    VMClose                         ; close it, then...

        call    FilePushDir                     ; save dir state
        mov     ax, SP_SPOOL                    ; go to spool directory
        call    FileSetStandardPath

        segmov  ds, cs
        mov     dx, offset cbFileName
        call    FileDelete                      ;  ..nuke it

        call    FilePopDir                      ; restore dir

	mov	bx, es:PS_expansionInfo		;bx <- handle of manager block
	call	MemFree				;free me
	mov	es:PS_expansionInfo,0		;zero handle of manager block
exit:
	clc
errExit:
	.leave
	ret
FontExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init all fonts & characters for new page.
CALLED BY:	EXTERNAL: In PrintStartPage once per page.
		NOT USED TILL FONTS ARE PRESERVED ACROSS PAGES.

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: size SoftCharFlags = 1
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/90		Initial version
	Dave	8/91		New Initial version


FontStartPage	proc	near
	uses	bx, cx, si, ds
curJob	local	FontDriverInfo
	push	ax
	mov	ax,bp		;save PState address
	.enter
	mov	curJob.FDI_pstate,ax

	call	LockFontInfo			;lock info block
	jcxz	endList				;branch if no fonts in printer

fontLoop:
	andnf	ds:[si].SFE_flags, not (mask SFF_ON_PAGE)
	push	cx, si
	add	si, offset SFE_chars		;ds:si <- ptr to chars
	mov	cx, HP_MAX_CHARS		;cx <- # of chars
charLoop:
	andnf	ds:[si].SCE_flags, not (mask SCF_ON_PAGE)
	add	si, size SoftCharEntry		;advance to next entry
	loop	charLoop			;loop while more chars
	pop	cx, si
	add	si, size SoftFontEntry		;advance to next entry
	loop	fontLoop			;loop while more fonts

endList:
	call	UnlockFontInfo			;unlock font manager blk

	.leave
	pop	ax
	ret
FontStartPage	endp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontAddFace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a face (font/size/style) combo to the LaserJet
		and set current font in printer.
CALLED BY:	EXTERNAL: PrintText

PASS: 		bp - seg addr of PState
		dx	- GeoWorks Font ID
RETURN:		carry set - some transmission error.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Should be called for each font/size/style *combination*.
	Otherwise, faces will get built and downloaded unnecessarily.
	The caller should combine all font/size/style changes before
	calling this routine to avoid wasting memory in the LaserJet.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/90		Initial version
	Dave	8/91		New Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontAddFace	proc	near
	uses	ax,bx, cx, si, di, es
curJob	local	FontDriverInfo
	.enter	inherit

	call	LockFontInfo			;lock info block

	mov	ax,ds:HPFI_maxNumFonts		;see if the number of fonts
	cmp	ax,ds:HPFI_numFonts		;is at or over the limit.
	jbe	done				;if so, cant add....

	mov     es, curJob.FDI_pstate		;get PState

		;test for the max pointsize that can be downloaded.
	mov	ax,ds:HPFI_maxPointsize
	cmp	ax,es:[PS_curFont].FE_size
	jb	done				;if bigger than max cant add.

		;test for zero width bitmaps coming, These are BAD for us.
	cmp	es:[PS_curOptFont].OFE_fontWidth,0
	je	done

	inc	ds:HPFI_heapCount		;update heap counter
	call	IsFontInPrinter			;see if already in use
	jnc	fontInUse			;branch if already in printer
	cmp	cx, MAX_SFE_NUMBER		;see if too many fonts
	jae	done				;branch if too many fonts
;	mov	ax, HP_FONT_SIZE		;ax <- # of bytes to find
;	call	AddSpace			;try to find space for it
;	jc	done				;branch if not enough memory
	mov	ax,ds:HPFI_allocID		;allocate new font ID
	inc	ax				;(a font will NEVER have the 
	mov	ds:HPFI_allocID,ax		;initial value)
	call	AddFontEntry			;add soft-font entry
	call	CreateFontHeader		;create HP font header
	call	SendFontHeader			;download to printer
fontInUse:
	mov	ax, ds:HPFI_heapCount		;ax <- current heap count
	mov	ds:[si].SFE_usage, ax		;update usage count
	ornf	ds:[si].SFE_flags, (mask SFF_ON_PAGE)
done:
	call	UnlockFontInfo			;done with info block
	clc
	.leave
	ret

FontAddFace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontAddChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add characters ffrom a string to a font in the LaserJet.
CALLED BY:	EXTERNAL: PrintText

PASS:		ds:si - characters to add
		cx - length of character string.
		dx	- GeoWorks Font ID
		bp - seg addr of PState
RETURN:		carry - set if character couldn't be added (no memory)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: current font (in HP) is font to add to
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/16/90		Initial version
	Dave	8/91		New Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontAddChars	proc	near
	uses	ax,bx, cx, dx, si, di, ds, es
curJob	local	FontDriverInfo
	.enter	inherit
	push	si,ds,cx

	call	LockFontInfo			;lock font manager block
	call	IsFontInPrinter			;find font entry
	segmov	es,ds,cx
	mov	di,si

	pop	si,ds,cx
	jc	fontNotHere	;the font is not here, do not add char.
;loop to go through the string passed in ds:si of length cx, and load the
;characters that are not already loaded.
downLoop:
	lodsb					;pick up the next char.
	cmp	al,C_SPACE			;see if its a space.
	jbe	charIsDown			;dont deal with spaces.
	cmp	al,C_NONBRKSPACE		;see if its a non break space.
	je	charIsDown			;dont deal with spaces.
	mov	bl,al
	clr	bh				;get byte pointer in bx
	test	es:[di][bx].SFE_chars.SCE_flags,mask SCF_ON_PAGE
	jnz	charIsDown
	ornf	es:[di][bx].SFE_chars.SCE_flags,mask SCF_ON_PAGE

;		al - character to add
	call	DownloadCharData		;send data to printer
charIsDown:
	loop	downLoop			;do another character.


	mov	ax, es:[di].SFE_fontTag		;ax <- printer font ID
	mov	di, offset pr_codes_SelectFont
	mov	es, curJob.FDI_pstate		;es <- seg addr of PState
	call	WriteNumCommand			;set current font

exit:
	call	UnlockFontInfo			;unlock font manager block
	clc

	.leave
	ret

fontNotHere:
	call	FontSetAttrs			;set attrs for best guess
	jmp	exit

FontAddChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontSendSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send space characters as cursor moves.
CALLED BY:	EXTERNAL: PrintText

PASS:	
		dx	- GeoWorks Font ID
		bp - seg addr of PState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontSendSpace	proc	near
	uses	ax,bx, cx, dx, si, di, ds, es
curJob	local	FontDriverInfo
	.enter	inherit
	mov	es,curJob.FDI_pstate 		; es -> PState
        cmp     es:PS_printerSmart,PS_DUMB_RASTER ;see if we can download font
        je      sendChar                        ;if not, skip.
	call	LockFontInfo			;lock font manager block
	call	IsFontInPrinter			;find font entry
	jc	sendLockedSpace			;if the font isnt downloaded,
						;I need to just send a space
						;char in the currently selected
						;font.
	clr	di				;no window.....
	call	GrCreateState			;create a GState for the 
	call	SetTextAttrs			;metrics routine to use.
	clr	ah
	mov	al,C_SPACE			;get the width of a space in 
	call	GrCharWidth			;this font.
	mov	ax,dx				;save the width of the space.
	call	GrDestroyState			;get rid of the GState.
	mov	es, curJob.FDI_pstate		;es <- seg addr of PState
	add	ax,ds:[si].SFE_optFontEntry.OFE_trackKern	;+ add in the additional width
	jge	axIsOK				;+ see if it went neg.
	clc					;+ clear carry.
	jmp	afterMove			;+ and bypass the cursor move.

axIsOK:						;+
	mov	di, offset pr_codes_RightRelMove
	call	WriteNumCommand			;set current font

afterMove:					;+ 
	pushf

	call	UnlockFontInfo			;unlock font manager block

	popf
	jmp	exit

sendLockedSpace:
        call    UnlockFontInfo                  ;unlock font manager block

sendChar:		
		;just send a space character, if dumb raster.
	mov	cl,C_SPACE
	call	PrintStreamWriteByte

exit:
	.leave
	ret
FontSendSpace	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set font attributes for LaserJet font selection.
CALLED BY:	INTERNAL: FontAddFace

PASS:		curJob.FDI_pstate - seg addr of PState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	We couldnt load another font so let the laserjet approximate the new
	font from whats already there.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/18/90		Initial version
	Dave	8/91		New Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontSetAttrs	proc	near
	uses	ax,cx,si,di,es
curJob	local	FontDriverInfo
	.enter	inherit

	mov	es, curJob.FDI_pstate		;es <- seg addr of PState

	call	PrintSetFontWayInt

	.leave
	ret
FontSetAttrs	endp

