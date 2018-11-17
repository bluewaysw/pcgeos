COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGALike video drivers
FILE:		vgacomUtils.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	PixelAddr	calculate the address of a pixel in the frame buffer
	SetEGAClrMode	set the EGA regs up to do color, draw mode
	SetEGAState	set the EGA regs up the way they were saved
	SetDither	common SetDither matrix for 4-bit VGA devices


	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	4/88	initial version


DESCRIPTION:
	These are a set of utility routines used by the VGALike video drivers.
		
	$Id: vgacomUtils.asm,v 1.1 97/04/18 11:42:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PixelAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate pixel address into video buffer

CALLED BY:	INTERNAL

PASS:		ax = x coordinate 
		bx = y coordinate

RETURN:		si = byte offset into video buffer
		bx = byte offset to start of scan line
		ax = byte offset into scan line

DESTROYED:	ax,bx,si

PSEUDO CODE/STRATEGY:
		offset = 80*y + x/8;
		#bitsToShiftLeft = NOT (x AND 7);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PixelAddr	proc	near

;	calculate scan line offset from start of frame buffer
	sal	bx, 1			; bx = ypos * 2
	sal	bx, 1			; bx = ypos * 4
	sal	bx, 1			; bx = ypos * 8
	sal	bx, 1			; bx = ypos * 16
	mov	si, bx			; si = ypos * 16
	sal	bx, 1			; bx = ypos * 32
	sal	bx, 1			; bx = ypos * 64
	add	si, bx			; si = ypos * 80
	mov	bx, si			; bx = byte offset to start of scan

	shr	ax, 1			; ax = xpos / 2
	shr	ax, 1			; ax = xpos / 4
	shr	ax, 1			; ax = xpos / 8
	add	si, ax			; si = byte offset into video buffer
					; ax = byte offset into scan line
	ret
PixelAddr	endp
	public	PixelAddr

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEGAClrMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the EGA to use a certain color, and implement the
		drawing mode

CALLED BY:	INTERNAL

PASS:		dh 	- color to use
		dl	- draw mode to use

RETURN:		color set
		dx	- set to GR_CONTROL address

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


SetEGAClrModeFar	proc	far
	call	SetEGAClrMode
	ret
SetEGAClrModeFar	endp

SetEGAClrMode	proc	near
	uses	ax, bx
	.enter

	mov	ah, dh
	mov	bl, dl

;	set up the EGA registers with color in set/reset reg, enable all planes

	mov	cs:d_savMODE, 0			; set write mode 0, read mode 0
	mov	cs:d_savENABLE_SR, 0fh		; enable all bit planes
	clr	bh				; make into a word
	test	bl, 1				; see if need alternate source
	jne	SECM10
	mov	ah, cs:constSrcTab[bx]		;  yes, grab constant value
SECM10:
	mov	cs:[d_savSET_RESET], ah
	mov	ah, cs:egaFunc[bx]		; get EGA function to use
	mov	cs:[d_savDATA_ROT], ah

	call	SetEGAState		; do all the outs

	.leave
	ret
SetEGAClrMode	endp
	public	SetEGAClrMode


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEGAState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the ega registers up to values stored in driver variable
		space. 

CALLED BY:	INTERNAL

PASS:		d_savMODE	- value to set for read/write mode register
		d_savENABLE_SR	- value to set for enable set/reset register
		d_savSET_RESET	- value to set for set/reset register
		d_savDATA_ROT	- value to set for data/rot register

RETURN:		dx	- set to GR_CONTROL (address of EGA i/o port)

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		just load ax from each variable and output to the port

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetEGAState	proc	near
	mov	dx, GR_CONTROL			; set up address of ega port
	mov	ah, cs:d_savMODE		; get the mode
	mov	al, WR_MODE			; index to mode register
	out	dx, ax
	mov	ah, cs:d_savENABLE_SR		; get the enable set/res reg
	mov	al, EN_SETRESET			; index to register
	out	dx, ax
	mov	ah, cs:d_savSET_RESET		; get the set/reset reg
	mov	al, SETRESET			; index to register
	out	dx, ax
	mov	ah, cs:d_savDATA_ROT		; get the data/rotate reg
	mov	al, DATA_ROT			; index to register
	out	dx, ax
	ret
SetEGAState	endp
	public	SetEGAState

