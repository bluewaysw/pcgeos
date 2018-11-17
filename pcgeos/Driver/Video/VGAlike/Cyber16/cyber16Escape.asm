COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Cyber16 Video Driver
FILE:		cyber16Escape.asm

AUTHOR:		Allen Yuen, Mar 25, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99   	Initial revision


DESCRIPTION:
		
	Escape functions specifically for Cyber16

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Cyber16GetHorizPosParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the parameters for controlling horizontal image position

CALLED BY:	VID_ESC_GET_HORIZ_POS_PARAMS
PASS:		nothing
RETURN:		dx	= max value, or 0 if not in TV mode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	In Cyber16, there are two registers to control the horizontal
	position.  Here are the rules that we must observe:
	- The difference in the two register values must remain constant.
	- Both register values must be within the range of
		0 <= reg <= mask YIWSF_VALUE (we assume that mask YIWSF_VALUE
			is the same as mask UVIWSF_VALUE)
	- The legal increments of the register values is not necessary 1.
	  (Currently it is 2).

	Moreover, in the positioning API, only one value is used to control
	the positioning.  However, the driver is free to decide how this one
	value corresponds to the real value(s), if any, used to control the
	hardware.

	Therefore, we use this strategy in Cyber16:
	- The register with the smaller initial value is the reference
	  register.
	- The set of legal values of the reference register (init. value +-
	  i * increment) are mapped to the set of values n, n-1, n-2, ..., 2,
	  1, 0 used by the API.  (The order is reversed because a higher
	  value used by the UI [e.g. slider GenValue] is usually associated
	  with the rightward direction, but a higher horizontal register
	  value actually moves the image to the left.)
	- The value of the other register is calculated as a constant offset
	  to the value of the reference register.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.assert	mask YIWSF_VALUE eq mask UIWSF_VALUE
.assert	YINTWST_640x440_INIT_VALUE le UVINTWST_640x440_INIT_VALUE

Cyber16GetHorizPosParams	proc	near

	clr	dx			; assume not in TV mode
	tst	cs:[tvMode]
EC <	WARNING_Z CANNOT_SET_HORIZ_VERT_POS_IN_NON_TV_MODE		>
	jz	done			; => not in TV mode.  Return 0

if ERROR_CHECK
	push	ax, cx

	;
	; Make sure the difference between UVINTWST and YINTWST didn't change.
	;
	mov	dx, YINTWST
	call	ReadTVReg
	andnf	ax, mask YIWSF_VALUE	; ax = YINTWST
	mov_tr	cx, ax			; cx = YINTWST

	mov	dx, UVINTWST
	call	ReadTVReg
	andnf	ax, mask UIWSF_VALUE	; ax = UVINTWST
	sub	ax, cx			; ax = UVINTWST - YINTWST
	Assert	e, ax, <UVINTWST_640x440_INIT_VALUE - \
			YINTWST_640x440_INIT_VALUE>

	pop	ax, cx
endif	; ERROR_CHECK

	;
	; Return max value for the API.
	;
	mov	dx, (YINTWST_640x440_MAX_VALUE - YINTWST_640x440_MIN_VALUE) \
			/ HORIZ_POS_INCREMENT

done:
	ret
Cyber16GetHorizPosParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Cyber16GetVertPosParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the parameters for controlling vertical image position

CALLED BY:	VID_ESC_GET_VERT_POS_PARAMS
PASS:		nothing
RETURN:		dx	= max value, or 0 if not in TV mode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Similar to strategy in Cyber16GetHorizPosParams, except that the
	order of mapping numbers is not reversed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.assert	mask VSTF_VALUE eq mask VSPF_VALUE
.assert	VSST_INIT_VALUE le VSSP_INIT_VALUE

Cyber16GetVertPosParams	proc	near

	clr	dx			; assume not in TV mode
	tst	cs:[tvMode]
EC <	WARNING_Z CANNOT_SET_HORIZ_VERT_POS_IN_NON_TV_MODE		>
	jz	done			; => not in TV mode.  Return 0

if ERROR_CHECK
	push	ax, cx

	;
	; Make sure the difference between EVENVSSP and EVENVSST didn't change.
	;
	mov	dx, EVENVSST
	call	ReadTVReg
	andnf	ax, mask VSTF_VALUE	; ax = EVENVSST
	mov_tr	cx, ax			; cx = EVENVSST

	mov	dx, EVENVSSP
	call	ReadTVReg
	andnf	ax, mask VSPF_VALUE	; ax = EVENVSSP
	sub	ax, cx
	Assert	e, ax, <VSSP_INIT_VALUE - VSST_INIT_VALUE>

	;
	; Make sure ODDVSST is still the same as EVENVSST.
	;
	mov	dx, ODDVSST
	call	ReadTVReg
	andnf	ax, mask VSTF_VALUE	; ax = ODDVSST
	Assert	e, ax, cx

	;
	; Make sure the difference between ODDVSSP and EVENVSST didn't change.
	;
	mov	dx, ODDVSSP
	call	ReadTVReg
	andnf	ax, mask VSPF_VALUE	; ax = ODDVSSP
	sub	ax, cx
	Assert	e, ax, <VSSP_INIT_VALUE - VSST_INIT_VALUE>

	pop	ax, cx
endif	; ERROR_CHECK

	;
	; Return max value for the API.
	;
	mov	dx, (VSST_MAX_VALUE - VSST_MIN_VALUE) / VERT_POS_INCREMENT

done:
	ret
Cyber16GetVertPosParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Cyber16SetHorizPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the horizontal image position

CALLED BY:	VID_ESC_SET_HORIZ_POS
PASS:		ax	= new value
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	See strategy in Cyber16GetHorizPosParams

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.assert	mask YIWSF_VALUE eq mask UIWSF_VALUE
.assert	YINTWST_640x440_INIT_VALUE le UVINTWST_640x440_INIT_VALUE

Cyber16SetHorizPos	proc	near
	uses	dx
	.enter

	tst	cs:[tvMode]
EC <	WARNING_Z CANNOT_SET_HORIZ_VERT_POS_IN_NON_TV_MODE		>
	jz	done

	;
	; Calculate the corresponding YINTWST value for the passed value.
	;
		CheckHack <HORIZ_POS_INCREMENT eq 2>
	shl	ax			; ax *= HORIZ_POS_INCREMENT
	sub	ax, YINTWST_640x440_MAX_VALUE
	neg	ax
	Assert	record, ax, YIntWStFlags

	;
	; Write to YINTWST
	;
	push	ax			; save new value
	mov	dx, YINTWST
	call	WriteTVReg
	pop	ax			; ax = new value

	;
	; Calculate the corresponding value for UVINTWST.
	;
	add	ax, UVINTWST_640x440_INIT_VALUE - YINTWST_640x440_INIT_VALUE
	Assert	record , ax, UvIntWStFlags
	mov	dx, UVINTWST
	call	WriteTVReg

done:
	.leave
	ret
Cyber16SetHorizPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Cyber16SetVertPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the vertical image position

CALLED BY:	VID_ESC_SET_VERT_POS
PASS:		ax	= new value
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Similar to strategy in Cyber16SetHorizPos.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/25/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.assert	mask VSTF_VALUE eq mask VSPF_VALUE
.assert	VSST_INIT_VALUE le VSSP_INIT_VALUE

Cyber16SetVertPos	proc	near
	uses	dx
	.enter

	tst	cs:[tvMode]
EC <	WARNING_Z CANNOT_SET_HORIZ_VERT_POS_IN_NON_TV_MODE		>
	jz	done

	;
	; Calculate the corresponding EVENVSST value for the passed value.
	;
		CheckHack <VERT_POS_INCREMENT eq 1>
		; no need to multiply by VERT_POS_INCREMENT (= 1)
if VSST_MIN_VALUE gt 0
	addnf	ax, VSST_MIN_VALUE
endif
	Assert	record, ax, VsStFlags

	;
	; Write to EVENVSST and ODDVSST
	;
	push	ax			; save new value
	mov	dx, EVENVSST
	call	WriteTVReg
	pop	ax			; ax = new value
	push	ax			; save new value
	mov	dx, ODDVSST
	call	WriteTVReg
	pop	ax			; ax = new value

	;
	; Calculate the corresponding value for EVENVSSP and ODDVSSP.
	;
	add	ax, VSSP_INIT_VALUE - VSST_INIT_VALUE
	Assert	record, ax, VsSpFlags
	push	ax			; save new value
	mov	dx, EVENVSSP
	call	WriteTVReg
	pop	ax
	mov	dx, ODDVSSP
	call	WriteTVReg

done:
	.leave
	ret
Cyber16SetVertPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Cyber16SetTVSubcarrierFreq
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set which TV subcarrier frequency to use.

CALLED BY:	VID_ESC_SET_TV_SUBCARRIER_FREQ
PASS:		ax	= zero if use default freq, non-zero if use
			  alternate freq.
RETURN:		nothing
DESTROYED:	nothing (ax allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/05/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn	PRODUCT, <>			; default version is NTSC

Cyber16SetTVSubcarrierFreq	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	tst	cs:[tvMode]
	jz	done

		CheckHack <FSC_NTSC_SPEC_VALUE shr 16 \
			eq FSC_NTSC_FREEZE_CRAWLING_DOTS shr 16>
	tst	ax
	mov	ax, FSC_NTSC_SPEC_VALUE and 0xFFFF
	jz	write			; => was zero, use default
	mov	ax, FSC_NTSC_FREEZE_CRAWLING_DOTS and 0xFFFF

write:
	mov	dx, FSCLOW
	call	WriteTVReg

done:
	.leave
	ret
Cyber16SetTVSubcarrierFreq	endp

endif	; PRODUCT, <>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Cyber16SetBlackWhite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns the display into black & white.

CALLED BY:	VID_ESC_SET_BLACK_WHITE
PASS:		ax	= zero if display color, non-zero if display B&W.
RETURN:		nothing
DESTROYED:	nothing (ax allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	8/10/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Cyber16SetBlackWhite	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	tst	cs:[tvMode]
	jz	done

	mov_tr	cx, ax			; cx = zero if color

	mov	ax, GainFlags <GAIN_U_COLOR, GAIN_V_COLOR>
	jcxz	writeGain
		CheckHack <GainFlags <GAIN_U_BW, GAIN_V_BW> eq 0>
	clr	ax			; ax = GainFlags <Gain_U_BW, GAIN_V_BW>
writeGain:
	mov	dx, GAIN
	call	WriteTVReg

	mov	ax, BurstAmpFlags <BURST_AMP_U_COLOR, BURST_AMP_V_COLOR>
	jcxz	writeBurstAmp
	mov	ax, BurstAmpFlags <BURST_AMP_U_BW, BURST_AMP_V_BW>
writeBurstAmp:
	mov	dx, BURSTAMP
	call	WriteTVReg

done:
	.leave
	ret
Cyber16SetBlackWhite	endp
