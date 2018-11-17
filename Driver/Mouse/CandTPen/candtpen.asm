COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MOUSE DRIVER -- Mouse Systems serial mouse
FILE:		candtpen.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	MouseDevInit		Initialize device
	MouseDevExit		Exit device (actually MouseClosePort in
				mouseSerCommon.asm)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/23/93		Initial revision


DESCRIPTION:
	Device-dependent support for C and T version 2 handheld.
		

	$Id: candtpen.asm,v 1.1 97/04/18 11:48:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Mouse		= 1
;
MOUSE_CANT_SET_RATE	= 1
MOUSE_NUM_BUTTONS	= 2
MOUSE_USES_ABSOLUTE_DELTAS = 1

DIGITIZER_X_RES equ     95
DIGITIZER_Y_RES equ     95

DEBUG_CANDTPEN   =       0

DIGITIZER_MAX_X	=	313
DIGITIZER_MAX_Y	=	414

SCREEN_MAX_X    =       255
SCREEN_MAX_Y    =       319

SystemButtons       record	;button bits for MouseSendEvents routine.
        SB_LEFT_DOWN:1,
        SB_MIDDLE_DOWN:1,
        SB_RIGHT_DOWN:1
SystemButtons       end

		;Equates for the Digitizer registers.
Digitizer_Base	equ	0100h	;base I/O address for the Gazelle digitizer.
Digitizer_Clear	equ	Digitizer_Base
Digitizer_Status	equ	Digitizer_Base + 1
Digitizer_X_Hi	equ	Digitizer_Base + 2
Digitizer_X_Y	equ	Digitizer_Base + 3
Digitizer_Y_Lo	equ	Digitizer_Base + 4

PenStatus	record		;read only
	PS_STAT3:1,
        PS_STAT2:1,
        PS_STAT1:1,
	PS_BATTERY_LOW:1,
	PS_PEN_DOWN:1,
	PS_NEAR:1,
	PS_BARREL_SWITCH:1,
	PS_RESERVED:1
PenStatus	end

include		mouseCommon.asm	; Include common definitions/code.


;------------------------------------------------------------------------------
;				DEVICE STRINGS
;------------------------------------------------------------------------------
MouseExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

mouseExtendedInfo	DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		length mouseNameTable,		; Number of supported devices
		offset mouseNameTable,
		offset mouseInfoTable
>

mouseNameTable	lptr.char	candtPen
		lptr.char	0	; null-terminator

candtPen	chunk.char 'C and T Pen', 0

mouseInfoTable	MouseExtendedInfo	\
		0			;candtPen

CheckHack <length mouseInfoTable eq length mouseNameTable>
MouseExtendedInfoSeg	ends
		
;------------------------------------------------------------------------------
;			    VARIABLES/DATA/CONSTANTS
;------------------------------------------------------------------------------
idata		segment

oldVector	fptr.far

;
; Packet format
;
; The mouse motion is accumulated in coordX and coordY, while the packet's
;
coordX          word
coordY          word

offsetX         word                    ;offset from right
offsetY         word                    ;offset from bottom
scaleX          WWFixed                 ;scale factor for X coordinates
scaleY          WWFixed                 ;scale factor for Y coordinates

offScreenMessage word			;offscreen message.
hardIconOD	optr			;offscreen hard icons.

hardIconState	byte	0

mouseRates	label	byte	; Needed to avoid assembly errors.
MOUSE_NUM_RATES	equ	0	; We can't change the report rate.


if	DEBUG_CANDTPEN
HACK_BUF_SIZE	=	2000
hackPtr	word	0
pbuf	byte	HACK_BUF_SIZE dup (0)
endif

idata		ends


Resident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the com port for the mouse

CALLED BY:	MouseInit
PASS:		DS=ES=dgroup
RETURN:		Carry clear if ok
DESTROYED:	DI

PSEUDO CODE/STRATEGY:
	Figure out which port to use.
       	Open it.

	The data format is specified in the DEF constants above, as 
	extracted from the documentation.

	Return with carry clear.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevInit	proc	far	uses ax, bx, cx, dx, si, di, ds, bp
	.enter

	mov	di, offset oldVector
	mov	bx, segment MouseDevHandler
	mov	cx, offset MouseDevHandler
	mov	ax, 7
	call	SysCatchDeviceInterrupt


	;
	;Enable the controller hardware to receive IRQ7
	;

        mov     dx, IC1_MASKPORT        ; Assume controller 1
        in      al, dx                  ; Fetch current mask
        and     al, 07fh                ; Clear IRQ7 bit
	out     dx, al                  ; Store new mask

	;
	; Get the calibration stuff.
	;
	
	call	GazelleCalibrate

	;
	; Set up the INI file message handle stuff
	;

	mov	ds:hardIconState,0	;init the state flag for hard icons.
        mov     si,offset gazelleCategory ;init file category string.
        clr     bp                      ;write NULL.
        mov     dx,offset gazelleOffScreen ;init file key string.
        segmov  ds,cs,cx                ;stuff cx, and ds with the code seg
        call    InitFileWriteInteger     ;grab the value.

	;
	;clear the hardware so it can do its thing.
	;

	mov	dx,Digitizer_Clear	;reset location.
	in	al,dx			;read it and dont weep

	;
	; All's well that ends well...
	;
	clc

	.leave
	ret

MouseDevInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down.

CALLED BY:	MousePortExit
PASS:		DS	= dgroup
RETURN:		Carry set if couldn't close the port (someone else was
			closing it (!)).
DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevExit	proc	far
	;
	; Close down the port...if it was ever opened, that is.
	;
	segmov	es, ds
	mov	di, offset oldVector
	mov	ax, 7
	call	SysResetDeviceInterrupt

	ret
MouseDevExit	endp

;------------------------------------------------------------------------------
;		  RESIDENT DEVICE-DEPENDENT ROUTINES
;------------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a device

CALLED BY:	DRE_TEST_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		carry set if string is invalid
		carry clear if string is valid
		ax	= DevicePresent enum in either case
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseTestDevice	proc	near
		.enter
		clc
;;;		call	MouseDevTest
		.leave
		ret
MouseTestDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the device.

CALLED BY:	DRE_SET_DEVICE
PASS:		dx:si	= pointer to null-terminated device name string
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just call the device-initialization routine in Init		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseSetDevice	proc	near
		.enter
		call	MouseDevInit
		.leave
		ret
MouseSetDevice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseDevHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem the receipt of a byte in the packet.

CALLED BY:	INT2
PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseDevHandler	proc	far	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	call	SysEnterInterrupt

	mov	dx, dgroup
	mov	ds, dx


		;load the coordinates from the digitizer interface.
	mov	dx,Digitizer_Status
	in	al,dx			;get status bits.
	test	al,mask PS_NEAR		;is the pen in proximity to tablet
	LONG jz	exit
	mov	bh,0ffh			;init the button byte.
	test	al,mask PS_PEN_DOWN	;see if the left button is pressed. 
	jz	testRight
	and	bh,not mask SB_LEFT_DOWN

testRight:
	test	al,mask PS_BARREL_SWITCH ;see if the right button is pressed. 
	jz	buttonsCorrect
	and	bh,not mask SB_RIGHT_DOWN

buttonsCorrect:
	inc	dx			;hi 8 x bits.
	in	al,dx
	mov	ah,al			;we will have to shift these right.
	inc	dx			;lo 4 x bits and hi 4 y bits
	in	al,dx
	mov	bl,al
	mov	cl,4
	shr	ax,cl			;shift the coords right 4 bits.
	mov	ds:coordX,ax		;stuff away
	mov	ah,bl			;get back the y coords.
	inc	dx			;lo 8 y bits
	in	al,dx
	and 	ah,0fh			;get rid of the remaining x bits.
        mov     ds:coordY,ax            ;stuff away

	call	GazelleCorrectCoords

	cmp	cx,SCREEN_MAX_X		;see if we are onscreen
	ja	offScreen
	cmp	dx,SCREEN_MAX_Y
	jbe	onScreen

offScreen:
	test	ds:hardIconState,0ffh	;get the state flag to see if we 
					;should load the new message stuff.
	jnz	offScreenService
	mov	ds:coordX,cx		;stuff away
        mov     ds:coordY,dx            ;stuff away

        mov     si,offset gazelleCategory ;init file category string.
        clr     ax                      ;assume NULL.
        mov     dx,offset gazelleOffScreen ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
	test	ax,ax			;see if its non-zero
	jz	exit
	mov	ds:offScreenMessage,ax

	clr	ax			;assume NULL.
	mov	dx,offset gazelleHardIconHandle ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
	mov	ds:[hardIconOD].handle,ax

	clr	ax			;assume NULL.
	mov	dx,offset gazelleHardIconChunk ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
	mov	ds:[hardIconOD].chunk,ax

	mov	ds:hardIconState,0ffh	;set the state flag to skip this stuff
	mov	cx,ds:coordX		;recover the position info.
        mov     dx,ds:coordY	

offScreenService:
	clr	bl
	xchg	bl,bh			;orient button state for MSG_META_PTR
	mov	bp,bx			;and pass in bp.

	mov	ax, ds:[offScreenMessage]
        movdw   bxsi, ds:[hardIconOD]
        mov     di, mask MF_FORCE_QUEUE
        call    ObjMessage                      ; recorded event => DI
	jmp	exit

onScreen:
	call	MouseSendEvents

exit:
	mov	dx,Digitizer_Clear
	in	al,dx			;read this location to reset dig.

	call	SysExitInterrupt

	mov	al,IC_GENEOI		;send the end of interrupt.
	mov	dx,IC1_CMDPORT
	out	dx,al

	.leave
	iret

MouseDevHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GazelleCalibrate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       routine to correct for the digitizer's inaccuracies

CALLED BY:      MouseDevInit
PASS:           ds      = dgroup
RETURN:         calibration stuff loaded.
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
                read .ini file to get the scale factors, and the offsets
                for X and Y. Also get the offscreen message number.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        dave    11/13/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
gazelleCategory         byte    "mouse", 0
gazelleScaleXInt        byte    "scaleX", 0
gazelleScaleXFrac       byte    "scaleXfrac", 0
gazelleScaleYInt        byte    "scaleY", 0
gazelleScaleYFrac       byte    "scaleYfrac", 0
gazelleOffsetX          byte    "offsetX", 0
gazelleOffsetY          byte    "offsetY", 0
gazelleOffScreen	byte	"message", 0
gazelleHardIconHandle	byte	"handle", 0
gazelleHardIconChunk	byte	"chunk", 0

GazelleCalibrate        proc    near    uses ax,dx,cx,si
        .enter
        mov     si,offset gazelleCategory ;init file category string.

        mov     ax,7                    ;set up a default...
        mov     dx,offset gazelleScaleXInt ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
        mov     ds:scaleX.WWF_int,ax    ;stuff it.

        mov     ax,8192
        mov     dx,offset gazelleScaleXFrac ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
        mov     ds:scaleX.WWF_frac,ax

        mov     ax,7                    ;set up a default...
        mov     dx,offset gazelleScaleYInt ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
        mov     ds:scaleY.WWF_int,ax

        mov     ax,26214
        mov     dx,offset gazelleScaleYFrac ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
        mov     ds:scaleY.WWF_frac,ax

        mov     ax,0x2a0
        mov     dx,offset gazelleOffsetX ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
        mov     ds:offsetX,ax

        mov     ax,0x2f0
        mov     dx,offset gazelleOffsetY ;init file key string.
        call    GazelleFetchIniData     ;see if its in the init file...
        mov     ds:offsetY,ax

        .leave
        ret
GazelleCalibrate        endp


GazelleFetchIniData     proc    near
        uses    ds
        .enter
        segmov  ds,cs,cx                ;stuff cx, and ds with the code seg
        call    InitFileReadInteger     ;grab the value.
        .leave
        ret
GazelleFetchIniData     endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GazelleCorrectCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set the coordinates to ones PC/GEOS can use.

CALLED BY:      MouseDevHandler
PASS:           DS      = dgroup
RETURN:         cx = x coordinate
                dx = y coordinate
DESTROYED:      none

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
                REMEMBER: the pad is rotated so x and y are switched

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    11/13/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GazelleCorrectCoords    proc    near
	uses	ax,bx
	.enter
        clr     cx
        mov     dx,ds:coordY            ;really X coordinate.
        sub     dx,ds:offsetX           ;translate....
        jns     xPositive
        clr     dx                      ;zero if it went neg.
xPositive:
        mov     bx,ds:scaleX.WWF_int
        mov     ax,ds:scaleX.WWF_frac
        call    GrUDivWWFixed           ;do the scale down
                                        ;dx = x position, backwards.
        mov     ax,DIGITIZER_MAX_X
        sub     ax,dx                   ;now we're pointing the right way...
        jns     correctedXPositive
        clr     ax
correctedXPositive:
        mov     ds:coordY,ax            ;stuff away (remember it's X)
        clr     cx
        mov     dx,ds:coordX            ;really Y coordinate.
        sub     dx,ds:offsetY           ;translate....
        jns     yPositive
        clr     dx                      ;zero if it went neg.
yPositive:
        mov     bx,ds:scaleY.WWF_int
        mov     ax,ds:scaleY.WWF_frac
        call    GrUDivWWFixed           ;do the scale down
                                        ;dx = y position, backwards.
        mov     ax,DIGITIZER_MAX_Y
        sub     ax,dx                   ;now we're pointing the right way...
        jns     correctedYPositive
        clr     ax
correctedYPositive:
        mov     dx,ax                   ;put corrected Y Pos in correct reg
        mov     cx,ds:coordY            ;get back the corrected X Pos.
	.leave
        ret
GazelleCorrectCoords    endp

Resident ends
