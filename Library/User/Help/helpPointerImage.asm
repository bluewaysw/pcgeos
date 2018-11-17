COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpPointerImage.asm

AUTHOR:		Gene Anderson, Oct 28, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/28/92	Initial revision


DESCRIPTION:
	Pointer images for the help object

	$Id: helpPointerImage.asm,v 1.1 97/04/07 11:47:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the pointer image to use for help.

CALLED BY:	MSG_HELP_CONTROL_GET_POINTER_IMAGE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		cx - (-1) if not over a link

RETURN:		ax - MouseReturnFlags with MRF_SET_POINTER_IMAGE
		^lcx:dx - OD of pointer image (if MRF_SET_POINTER_IMAGE)

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGetPointerImage		method dynamic HelpControlClass,
					MSG_HELP_CONTROL_GET_POINTER_IMAGE
	;
	; Clear the pointer image if we are not over a link
	;
	mov	ax, mask MRF_CLEAR_POINTER_IMAGE
	cmp	cx, -1				;over a link?
	je	done				;branch if not over link
	;
	; See if there is a custom pointer image specified
	;
	mov	ax, ATTR_HELP_CUSTOM_POINTER_IMAGE
	call	ObjVarFindData
	mov	cx, handle ptrHelpLink
	mov	dx, offset ptrHelpLink		;^lcx:dx <- custom pointer
	jnc	setPointer		;branch if no custom pointer
	movdw	cxdx, ds:[bx]			;^lcx:dx <- OD of pointer image
setPointer:
	mov	ax, mask MRF_SET_POINTER_IMAGE
done:
	ret
HelpControlGetPointerImage		endm

HelpControlCode ends

PointerImages	segment lmem LMEM_TYPE_GENERAL

ptrHelpLink chunk
PointerDef <
	16,				; PD_width
	16,				; PD_height
	0,				; PD_hotX
	0				; PD_hotY
>

	byte	11111111b, 00000000b,
		11111111b, 00000000b,
		11111110b, 00000000b,
		11111110b, 01111100b,
		11111111b, 11111110b,
		11111111b, 11111111b,
		11111111b, 11111111b,
		11001111b, 11111111b,
		00000111b, 11111111b,
		00000001b, 11111111b,
		00000000b, 11111110b,
		00000000b, 11111100b,
		00000000b, 11111000b,
		00000000b, 11111000b,
		00000000b, 11111000b,
		00000000b, 11111000b

	byte	11111111b, 00000000b,
		10000001b, 00000000b,
		10000110b, 00000000b,
		10000010b, 01111100b,
		10000001b, 10000110b,
		10100001b, 00000011b,
		10110010b, 00000001b,
		11001010b, 00110001b,
		00000110b, 00110001b,
		00000001b, 11100001b,
		00000000b, 11000010b,
		00000000b, 10000100b,
		00000000b, 10001000b,
		00000000b, 11111000b,
		00000000b, 10001000b,
		00000000b, 10001000b,
		00000000b, 11111000b

ptrHelpLink endc

PointerImages	ends
