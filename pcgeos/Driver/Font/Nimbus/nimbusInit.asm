COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Init
FILE:		nimbusInit.asm

AUTHOR:		Gene Anderson, Nov  7, 1989

ROUTINES:
	Name			Description
	----			-----------
	NimbusInit		initialize the Nimbus font driver
	NimbusExit		clean up after Nimbus font driver
	NimbusInitFonts		initialize any non-PC/GEOS fonts

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/ 7/89	Initial revision

DESCRIPTION:
	Initialization & exit routines for Nimbus font driver
		
	$Id: nimbusInit.asm,v 1.1 97/04/18 11:45:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Nimbus font driver.
CALLED BY:	DR_INIT - NimbusStrategy

PASS:		none
RETURN:		bitmapHandle - handle of block to use for bitmaps
		bitmapSize - size of above block (0 at start)
		variableHandle - handle of block containing variables
		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	NimbusInit
NimbusInit	proc	far
	uses	ax, bx, cx, si, di, ds, es
	.enter

	mov	ax, segment udata
	mov	ds, ax				;ds <- seg addr of vars
	;
	; First, we need a block of memory to use as a bitmap
	; for generating characters. We don't need to actually
	; allocate memory for it yet.
	;
	mov	ax, NIMBUS_BLOCK_SIZE		;ax <- size of block
	mov	bx, handle 0			;bx <- make Nimbus owner
	mov	cx, mask HF_DISCARDABLE \
		 or mask HF_SWAPABLE \
		 or mask HF_SHARABLE \
		 or mask HF_DISCARDED \
		 or (mask HAF_NO_ERR shl 8) 	;cl, ch <- alloc flags
	call	MemAllocSetOwner
	mov	ds:bitmapHandle, bx		;save handle of block
	mov	ds:bitmapSize, 0		;no bytes yet
	;
	; We also need a block to use for variables. We don't
	; need it yet, either.
	;
	mov	ax, size NimbusVars		;ax <- size of block
	mov	bx, handle 0			;bx <- make Nimbus owner
	mov	cx, mask HF_DISCARDABLE \
		 or mask HF_SWAPABLE \
		 or mask HF_SHARABLE \
		 or mask HF_DISCARDED \
		 or (mask HAF_NO_ERR shl 8) 	;cl, ch <- alloc flags
	call	MemAllocSetOwner
	mov	ds:variableHandle, bx		;save handle of block
	clc					;indicate no error

	.leave
	ret
NimbusInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up blocks used and exit the Nimbus driver.
CALLED BY:	DR_EXIT - NimbusStrategy

PASS:		bitmapHandle - handle of bitmap block
		variableHandle - handle of variable block
RETURN:		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusExit	proc	far
	uses	ax, bx, ds
	.enter

	mov	ax, segment udata
	mov	ds, ax				;ds <- seg addr of vars
	mov	bx, ds:bitmapHandle
EC <	clr	ds:bitmapHandle			;>
	call	MemFree				;done with bitmap block
	mov	bx, ds:variableHandle
EC <	clr	ds:variableHandle		;>
	call	MemFree				;done with variable block
	clc					;indicate no error

	.leave
	ret
NimbusExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusInitFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize any non-GEOS fonts for the font driver.
CALLED BY:	DR_FONT_INIT_FONTS - NimbusStrategy

PASS:		ds - seg addr of font info block
RETURN:		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusInitFonts	proc	far
	clc
	ret
NimbusInitFonts	endp
