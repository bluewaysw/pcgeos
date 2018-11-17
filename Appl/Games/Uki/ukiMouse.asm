COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Uki
FILE:		ukiMouse.asm

AUTHOR:		Don Reeves, Nov 26, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/26/92	Initial revision

DESCRIPTION:
	Contains the Uki mouse-interaction code	

	$Id: ukiMouse.asm,v 1.1 97/04/04 15:47:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiStartSelect

DESCRIPTION:   handles all mouse clicks in the view


PASS:          cx, dx: position of mouse click
		
RETURN:        nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCommonStartSelect	method	UkiContentClass, MSG_META_START_SELECT

	; create gstate
	mov	di, es:[viewWindow]
	call	GrCreateState
	push	di
	; see if games over
	tst	es:[gameOver]
	jnz	bleep
	; see if mouse click was in the playing grid
	call	UkiClickedInGrid
	jc	done

	; if the computer is playing itself ignore the click
	tst	es:[computerTwoPlayer]
	jnz	bleep

	; if so get the board coordinates of the click
	; x position = (x clicked position - x start coord)/cellsize
	; y position = (y clicked position - y start coord)/cellsize
	sub	cx, es:[xStartCoord]
	mov	ax, cx
	mov	bx, es:[cellSize]
	div	bl
	clr	ah
	push	ax
	mov	ax, dx
	sub	ax, es:[yStartCoord]
	div	bl
	clr	ah
	mov	dx, ax
	pop	cx
	
	; now call the specific routine for the current game that will
	; decide what to do for this mouse click
	call	UkiCallMouseClick
done:
	pop	di
	call	GrDestroyState
	ret
bleep:
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	done
UkiCommonStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiClickedInGrid

DESCRIPTION:   checks bounds of grid to see if mouse click inside


PASS:          cx, dx: position of mouse click

RETURN:        carry set if click is outside the board

DESTROYED:     nothing

PSEUDO CODE/STRATEGY:
		this code is very simple, just see if the point cx,dx
		lies in the box defined by the two points
		(xStartCoord, YStartCoord) and (XEndCoord, YEndCoord)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version
	rsf	6/27/91		shrunk

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiClickedInGrid	proc	near
	cmp	cx, es:[xStartCoord]		; is it to the left
	jc	done
	cmp	es:[xEndCoord],cx		; to the right
	jc	done
	cmp	dx, es:[yStartCoord]		; above
	jc	done
	cmp	es:[yEndCoord], dx		; or below
done:
	ret
UkiClickedInGrid	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetPtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the pointer image to the appropriate shape

CALLED BY:	Global

PASS:		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/ 2/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetPtrImage	proc	far
	uses	ax, bx, cx, dx, di, si
	.enter

	; Load pointer image => CX:DX
	;
	mov	cx, handle DataBlock
	mov	dx, offset DataBlock:player1Ptr
	mov	bx, es:[whoseTurn]
	cmp	es:[bx].SP_player, mask GDN_PLAYER2
	jnz	setImage
	mov	dx, offset DataBlock:player2Ptr

	; Now set the pointer image
setImage:
	mov	ax, MSG_GEN_VIEW_SET_PTR_IMAGE
	GetResourceHandleNS	Interface, bx
	mov	si, offset UkiView
	mov	bp, PIL_WINDOW
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
UkiSetPtrImage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Pointer images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DataBlock	segment lmem LMEM_TYPE_GENERAL

player1Ptr	chunk

     PointerDef <16, 16, 7, 7>

     byte       00000000b, 00000000b,
                00011000b, 00011000b,
		00111100b, 00111100b,
		01111110b, 01111110b,
                01111110b, 01111110b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                01111110b, 01111110b,
                01111110b, 01111110b,
                00111100b, 00111100b,
                00011000b, 00011000b

     byte       00000000b, 00000000b,
                00000000b, 00000000b,
		00011000b, 00011000b,
		00111100b, 00111100b,
                00111100b, 00111100b,
                01111110b, 01111110b,
                01001110b, 01001110b,
                01001110b, 01001110b,
                01001110b, 01001110b,
                01001110b, 01001110b,
                01001110b, 01001110b,
                01111110b, 01111110b,
                00111100b, 00111100b,
                00111100b, 00111100b,
                00011000b, 00011000b,
                00000000b, 00000000b

if 0
     byte       00000000b, 00000000b,
                00011000b, 00011000b,
		00100100b, 00100100b,
		01000010b, 01000010b,
                01000010b, 01000010b,
                10000001b, 10000001b,
                10110001b, 10110001b,
                10110001b, 10110001b,
                10110001b, 10110001b,
                10110001b, 10110001b,
                10110001b, 10110001b,
                10000001b, 10000001b,
                01000010b, 01000010b,
                01000010b, 01000010b,
                00100100b, 00100100b,
                00011000b, 00011000b
endif

player1Ptr	endc



player2Ptr	chunk

     PointerDef <16, 16, 7, 7>

     byte       00000000b, 00000000b,
                00011000b, 00011000b,
		00111100b, 00111100b,
		01111110b, 01111110b,
                01111110b, 01111110b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                11111111b, 11111111b,
                01111110b, 01111110b,
                01111110b, 01111110b,
                00111100b, 00111100b,
                00011000b, 00011000b

     byte       00000000b, 00000000b,
                00000000b, 00000000b,
		00011000b, 00011000b,
		00111100b, 00111100b,
                00111100b, 00111100b,
                01111110b, 01111110b,
                01110010b, 01110010b,
                01110010b, 01110010b,
                01110010b, 01110010b,
                01110010b, 01110010b,
                01110010b, 01110010b,
                01111110b, 01111110b,
                00111100b, 00111100b,
                00111100b, 00111100b,
                00011000b, 00011000b,
                00000000b, 00000000b
if 0
     byte       00000000b, 00000000b,
                00011000b, 00011000b,
		00100100b, 00100100b,
		01000010b, 01000010b,
                01000010b, 01000010b,
                10000001b, 10000001b,
                10001101b, 10001101b,
                10001101b, 10001101b,
                10001101b, 10001101b,
                10001101b, 10001101b,
                10001101b, 10001101b,
                10000001b, 10000001b,
                01000010b, 01000010b,
                01000010b, 01000010b,
                00100100b, 00100100b,
                00011000b, 00011000b
endif

player2Ptr	endc

DataBlock	ends
