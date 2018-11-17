
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bigcalcUnaryCvt.asm

AUTHOR:		Christian Puscasiu, Jun 16, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/16/92		Initial revision
	AS	8/27/96		Fixed PENELOPE related conversion
				functions to use correct constants.
				Added BigCalcFloatDivide10000.  
				Reversed order of F2C and C2F
				functions in the function tables

DESCRIPTION:
	
		

	$Id: bigcalcUnaryCvt.asm,v 1.1 97/04/04 14:37:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%% DON'T NEED THIS FOR RESPONDER %%%%%%%%%%%%%%%%%%%%%%@

MathCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CEConvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts the number in the display according to cx

CALLED BY:	
PASS:		cx - ConvertOperator
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	5/ 2/92    	Initial version
	AS	6/27/96		Reversed F2C and C2F order.
				Renamed three US->UK conversion
				functions (i.e. from UKMli2OuFunction 
				to MLi2UKouFunction)
	AS	9/17/96		Change paper tape color to gray and
				print the number being converted

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CEConvert	method dynamic CalcEngineClass, 
					MSG_CE_CONVERT
	uses	ax, cx, dx, bp
	.enter

	
	call	FloatDepth
	cmp	ax, 1
	jl	done

	mov	di, offset ConvertFunctionTable
	shl	cx
	add	di, cx
	call	cs:[di]

	call	InfixEngineCalcInputFieldSetUnaryOpDone
done:
	.leave
	ret
CEConvert	endm

if _NEW_CONVERSIONS_IN_PENELOPE

ConvertFunctionTable	word	\
\
	offset	In2CmFunction,
	offset	Cm2InFunction,
	offset	Ft2MFunction,
	offset	M2FtFunction,
	offset	Mi2KmFunction,
	offset	Km2MiFunction,
	offset	Gal2LiFunction,
	offset	Li2GalFunction,
	offset	Lbs2KgFunction,
	offset	Kg2LbsFunction,
	offset	C2FFunction,
	offset	F2CFunction,
	offset	Deg2RadFunction,
	offset	Rad2DegFunction,
	offset	LtoRCurrencyFunction,
	offset	RtoLCurrencyFunction,  
	offset	M2YaFunction,
	offset  Ya2MFunction,
	offset	Sin2ScmFunction,
	offset	Scm2SinFunction,
	offset	Sft2SmFunction,
	offset	Sm2SftFunction,
	offset	Sya2SmFunction,
	offset	Sm2SyaFunction,
	offset	Smi2SkmFunction,
	offset	Skm2SmiFunction,
	offset	Ar2SkmFunction,
	offset	Skm2ArFunction,
	offset	Ou2MliFunction,
	offset  Mli2OuFunction,
	offset  Pi2LiFunction,
	offset  Li2PiFunction,
	offset	UKou2mliFunction,
	offset 	Mli2UKouFunction,
	offset	UKpi2liFunction,
	offset	Li2UKpiFunction,
	offset	UKgal2liFunction,
	offset 	Li2UKgalFunction,
	offset	Ou2GFunction,
	offset  G2OuFunction,
	offset  St2KgFunction,
	offset  Kg2StFunction,
	offset  Ton2TonneFunction,
	offset  Tonne2TonFunction
else 
ConvertFunctionTable	word	\
\
	offset	In2CmFunction,
	offset	Cm2InFunction,
	offset	Ft2MFunction,
	offset	M2FtFunction,
	offset	Mi2KmFunction,
	offset	Km2MiFunction,
	offset	Gal2LiFunction,
	offset	Li2GalFunction,
	offset	Lbs2KgFunction,
	offset	Kg2LbsFunction,
	offset	F2CFunction,
	offset	C2FFunction,
	offset	Deg2RadFunction,
	offset	Rad2DegFunction,
	offset	LtoRCurrencyFunction,

	offset	RtoLCurrencyFunction
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFunctions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	executes the conversion

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/16/92		Initial version
	AS	8/27/96		Moved most of the original functions
				out of a _NEW_CONVERSIONS_IN_PENELOPE 
				block.  Replaced the constants used
				for the PENELOPE version.
	DR	8/20/00		Added accuracy, eliminated redundant
				PENELOPE functions (combined with the
				standard functions where possible)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;;; Angle Conversion Functions ;;;

Deg2RadFunction	proc	near
	.enter

	call	FloatPi
	call	FloatMultiply
	mov	ax, 180
	call	FloatWordToFloat
	call	FloatDivide

	.leave
	ret
Deg2RadFunction	endp

Rad2DegFunction	proc	near
	.enter

	mov	ax, 180
	call	FloatWordToFloat
	call	FloatMultiply
	call	FloatPi
	call	FloatDivide

	.leave
	ret
Rad2DegFunction	endp


;;; Length Conversion Functions ;;;

In2CmFunction	proc	near
	.enter

	call	BigCalcFloat2Point54
	call	FloatMultiply

	.leave
	ret
In2CmFunction	endp

Cm2InFunction	proc	near
	.enter

	call	BigCalcFloat2Point54
	call	FloatDivide

	.leave
	ret
Cm2InFunction	endp

Ft2MFunction	proc	near
	.enter

	call	BigCalcFloatPoint32808333
	call	FloatDivide

	.leave
	ret
Ft2MFunction	endp

M2FtFunction	proc	near
	.enter

	call	BigCalcFloatPoint32808333
	call	FloatMultiply

	.leave
	ret
M2FtFunction	endp

Mi2KmFunction	proc	near
	.enter

	call	BigCalcFloat1Point6093
	call	FloatMultiply

	.leave
	ret
Mi2KmFunction	endp

Km2MiFunction	proc	near
	.enter

	call	BigCalcFloat1Point6093
	call	FloatDivide

	.leave
	ret
Km2MiFunction	endp


;;; Volume Conversion Functions ;;;

Gal2LiFunction	proc	near
	.enter

	call	BigCalcFloat3Point7854
	call	FloatMultiply

	.leave
	ret
Gal2LiFunction	endp

Li2GalFunction	proc	near
	.enter

	call	BigCalcFloat3Point7854
	call	FloatDivide

	.leave
	ret
Li2GalFunction	endp


;;; Weight/Mass Conversion Functions ;;;

Lbs2KgFunction	proc	near
	.enter

	call	BigCalcFloat2Point205
	call	FloatDivide

	.leave
	ret
Lbs2KgFunction	endp

Kg2LbsFunction	proc	near
	.enter

	call	BigCalcFloat2Point205
	call	FloatMultiply

	.leave
	ret
Kg2LbsFunction	endp


;;; Temperature Conversion Functions ;;;

F2CFunction	proc	near
	.enter

	mov	ax, -32
	call	FloatWordToFloat
	call	FloatAdd
	mov	ax, 5
	call	FloatWordToFloat
	mov	ax, 9
	call	FloatWordToFloat
	call	FloatDivide
	call	FloatMultiply

	.leave
	ret
F2CFunction	endp

C2FFunction	proc	near
	.enter

	mov	ax, 9
	call	FloatWordToFloat
	mov	ax, 5
	call	FloatWordToFloat
	call	FloatDivide
	call	FloatMultiply
	mov	ax, 32
	call	FloatWordToFloat
	call	FloatAdd

	.leave
	ret
C2FFunction	endp


;;; Additional Conversion Functions For Penelope;;;

if _NEW_CONVERSIONS_IN_PENELOPE
M2YaFunction proc near
	.enter

	call	BigCalcFloat0Point9144
	call	FloatDivide

	.leave
	ret
M2YaFunction endp

Ya2MFunction proc near
	.enter

	call	BigCalcFloat0Point9144
	call	FloatMultiply

	.leave
	ret
Ya2MFunction endp

Sin2ScmFunction proc near
	.enter

	call	BigCalcFloat6Point4516
	call	FloatMultiply

	.leave
	ret
Sin2ScmFunction endp

Scm2SinFunction proc near
	.enter

	call	BigCalcFloat6Point4516
	call	FloatDivide

	.leave
	ret
Scm2SinFunction endp

Sft2SmFunction proc near
	.enter

	call	BigCalcFloat0Point0929
	call	FloatMultiply

	.leave
	ret
Sft2SmFunction endp

Sm2SftFunction proc near
	.enter

	call	BigCalcFloat0Point0929
	call	FloatDivide

	.leave
	ret
Sm2SftFunction endp

Sya2SmFunction proc near
	.enter

	call	BigCalcFloat0Point8361
	call	FloatMultiply

	.leave
	ret
Sya2SmFunction endp

Sm2SyaFunction proc near
	.enter

	call	BigCalcFloat0Point8361
	call	FloatDivide

	.leave
	ret
Sm2SyaFunction endp

Ar2SkmFunction proc near
	.enter

	call	BigCalcFloat0Point0040
	call	FloatMultiply

	.leave
	ret
Ar2SkmFunction endp

Skm2ArFunction proc near
	.enter

	call	BigCalcFloat0Point0040
	call	FloatDivide

	.leave
	ret
Skm2ArFunction endp

Smi2SkmFunction proc near
	.enter

	call	BigCalcFloat2Point590
	call	FloatMultiply

	.leave
	ret
Smi2SkmFunction endp


Skm2SmiFunction proc near
	.enter

	call	BigCalcFloat2Point590
	call	FloatDivide

	.leave
	ret
Skm2SmiFunction endp

Ou2MliFunction proc near
	.enter

	call	BigCalcFloat29Point573
	call	FloatMultiply

	.leave
	ret
Ou2MliFunction endp

Mli2OuFunction proc near
	.enter

	call	BigCalcFloat29Point573
	call	FloatDivide

	.leave
	ret
Mli2OuFunction endp

Pi2LiFunction proc near
	.enter

	call	BigCalcFloat0Point4732
	call	FloatMultiply

	.leave
	ret
Pi2LiFunction endp

Li2PiFunction proc near
	.enter

	call	BigCalcFloat0Point4732
	call	FloatDivide

	.leave
	ret
Li2PiFunction endp

UKou2mliFunction proc near
	.enter
	
	call	BigCalcFloat28Point413
	call	FloatMultiply
	
	.leave
	ret
UKou2mliFunction endp

Mli2UKouFunction proc near
	.enter
	
	call	BigCalcFloat28Point413
	call	FloatDivide
	
	.leave
	ret
Mli2UKouFunction endp

UKpi2liFunction proc near
	.enter
	call	BigCalcFloat0Point5683
	call	FloatMultiply
	.leave
	ret
UKpi2liFunction endp

Li2UKpiFunction proc near
	.enter

	call	BigCalcFloat0Point5683
	call	FloatDivide

	.leave
	ret
Li2UKpiFunction endp

UKgal2liFunction proc near
	.enter
	
	call	BigCalcFloat4Point546
	call	FloatMultiply

	.leave
	ret
UKgal2liFunction endp

Li2UKgalFunction proc near
	.enter
	
	call	BigCalcFloat4Point546
	call	FloatDivide

	.leave
	ret
Li2UKgalFunction endp

Ou2GFunction proc near
	.enter

	call 	BigCalcFloat28Point349
	call	FloatMultiply

	.leave
	ret
Ou2GFunction endp

G2OuFunction proc near
	.enter
	
	call	BigCalcFloat28Point349
	call	FloatDivide

	.leave
	ret
G2OuFunction endp

St2KgFunction proc near
	.enter

	call	BigCalcFloat6Point3504
	call	FloatMultiply
	
	.leave
	ret
St2KgFunction endp

Kg2StFunction proc near
	.enter

	call	BigCalcFloat6Point3504
	call	FloatDivide
	
	.leave
	ret
Kg2StFunction endp

Ton2TonneFunction proc near
	.enter
	
	call	BigCalcFloat1Point016
	call	FloatMultiply

	.leave
	ret
Ton2TonneFunction endp

Tonne2TonFunction proc near
	.enter
	
	call	BigCalcFloat1Point016
	call	FloatDivide

	.leave
	ret
Tonne2TonFunction endp
endif	; if _NEW_CONVERSIONS_IN_PENELOPE


if (NOT FALSE)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RtoLCurrencyFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the calculation from one currency to another.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Grab the current exchange rate and do the right thing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RtoLCurrencyFunction	proc	near
		.enter
		call	GetAndPushExchangeRateOnFPStack
		call	FloatDivide
		.leave
		ret
RtoLCurrencyFunction		endp

LtoRCurrencyFunction	proc	near
		.enter
		call	GetAndPushExchangeRateOnFPStack
		call	FloatMultiply
		.leave
		ret
LtoRCurrencyFunction		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAndPushExchangeRateOnFPStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets and pushes the exchange rate on the fp stack 

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	7/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAndPushExchangeRateOnFPStack	proc	near
	uses	ax,bx,cx,dx,si,di,bp, ds,es
	.enter

	;
	; get the value from the left field and put it onto the fp
	; stack, then get value from the excahnge rate and the
	; multiply the two and put them into the right field
	;
	mov	bx, handle ExchangeRateNumber
	mov	si, offset ExchangeRateNumber
	GetResourceSegmentNS	dgroup, es
	mov	dx, es
	mov	bp, offset textBuffer
	clr	cx
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	;
	; push on stack
	;
	mov	al, mask FAF_PUSH_RESULT
	GetResourceSegmentNS	dgroup, ds
	mov	si, offset textBuffer
	mov	cx, NUMBER_DISPLAY_WIDTH
	call	FloatAsciiToFloat

	.leave
	ret
GetAndPushExchangeRateOnFPStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetExchangeRateInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called on the APPLY button pressed

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= SetExchangeRateClass object
		ds:di	= SetExchangeRateClass instance data
		ds:bx	= SetExchangeRateClass object (same as *ds:si)
		es 	= segment of SetExchangeRateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		At this point we need to save the options and reset the 
		menu item names.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jad	9/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetExchangeRateInteractionInitiate	method dynamic SetExchangeRateClass, 
					MSG_GEN_INTERACTION_INITIATE

	; First, send out a save options to ourselves, so that we
	; can handle the RESET situation easily
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	call	ObjCallInstanceNoLock

	; Now ensure each of the text objects are marked as not modified,
	; so that when they are changed the OK button will become enabled.
	;
	push	si
	mov	si, offset ExchangeRateNumber
	call	ClearModifiedState
	mov	si, offset LeftCurrencyDescription
	call	ClearModifiedState
	mov	si, offset RightCurrencyDescription
	call	ClearModifiedState
	pop	si

	; Finally, let superclass do the rest of the work
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset SetExchangeRateClass
	GOTO	ObjCallSuperNoLock
SetExchangeRateInteractionInitiate	endm

ClearModifiedState	proc	near
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	clr	cx
	call	ObjCallInstanceNoLock
	ret
ClearModifiedState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetExchangeRateApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called on the APPLY button pressed

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= SetExchangeRateClass object
		ds:di	= SetExchangeRateClass instance data
		ds:bx	= SetExchangeRateClass object (same as *ds:si)
		es 	= segment of SetExchangeRateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		At this point we need to save the options and reset the 
		menu item names.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jad	9/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetExchangeRateApply	method dynamic SetExchangeRateClass, 
					MSG_GEN_APPLY
	.enter

	; first, call the super class to get default behaviour for the button

	mov	di, offset SetExchangeRateClass
	call	ObjCallSuperNoLock

	; first, save the options.

	mov	ax, MSG_META_SAVE_OPTIONS
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; do text moniker replacement for the menu items.

	call	SetConvertCurrencyMenuItems

	.leave
	ret
SetExchangeRateApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetExchangeRateReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called on the APPLY button pressed

CALLED BY:	MSG_GEN_RESET
PASS:		*ds:si	= SetExchangeRateClass object
		ds:di	= SetExchangeRateClass instance data
		ds:bx	= SetExchangeRateClass object (same as *ds:si)
		es 	= segment of SetExchangeRateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		At this point we need to reload the options

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jad	9/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetExchangeRateReset	method dynamic SetExchangeRateClass, 
					MSG_GEN_RESET

	; first, call the super class to get default behaviour for the button

	mov	di, offset SetExchangeRateClass
	call	ObjCallSuperNoLock

	; reset the options.

	mov	ax, MSG_META_LOAD_OPTIONS
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
SetExchangeRateReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetExchangeRateLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called on the APPLY button pressed

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= SetExchangeRateClass object
		ds:di	= SetExchangeRateClass instance data
		ds:bx	= SetExchangeRateClass object (same as *ds:si)
		es 	= segment of SetExchangeRateClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		At this point we need to reset the menu item names

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jad	9/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetExchangeRateLoadOptions	method dynamic SetExchangeRateClass, 
						MSG_META_LOAD_OPTIONS
	.enter

	; first, call the super class to get default behaviour

	mov	di, offset SetExchangeRateClass
	call	ObjCallSuperNoLock

	; do text moniker replacement for the menu items.

	call	SetConvertCurrencyMenuItems

	.leave
	ret
SetExchangeRateLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetConvertCurrencyMenuItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text monikers for the menu items

CALLED BY:	SetExchangeRateLoadOptions (EXTERNAL)
		SetExchangeRateApply, BigCalcProcessOpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetConvertCurrencyMenuItems		proc	near
		uses	ax, bx, cx, dx, di, si, bp
chgMoniker	local ReplaceVisMonikerFrame
newMoniker	local TextMonikerStruct
		.enter

	; init some stuff for the replacement of the text moniker

	mov	ss:[chgMoniker].RVMF_source.segment, ss
	lea	ax, newMoniker
	mov	ss:[chgMoniker].RVMF_source.offset, ax
	mov	ss:[chgMoniker].RVMF_sourceType, VMST_FPTR
	mov	ss:[chgMoniker].RVMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[chgMoniker].RVMF_length, size TextMonikerStruct.TMS_data
	mov	ss:[newMoniker].TMS_moniker.VM_type, 0
	mov	ss:[newMoniker].TMS_moniker.VM_width, 0
	mov	ss:[newMoniker].TMS_text.VMT_mnemonicOffset, 0

	; next, grab the text out of the name fields and stuff it in the 
	; menu items.

SBCS<	mov	ax, '1.'						>
DBCS<	mov	ax, '1'							>
	mov	bx, handle MainInterface
	mov	si, offset MainInterface:LeftCurrencyDescription
	mov	di, offset MainInterface:RightCurrencyDescription
	mov	cx, handle LtoRCurrencyButton
	mov	dx, offset LtoRCurrencyButton
	call	CreateConvertMoniker	
	
	; now do the other button

SBCS<	mov	ax, '2.'						>
DBCS<	mov	ax, '2'							>
	mov	bx, handle MainInterface
	mov	si, offset MainInterface:RightCurrencyDescription
	mov	di, offset MainInterface:LeftCurrencyDescription
	mov	cx, handle RtoLCurrencyButton
	mov	dx, offset RtoLCurrencyButton
	call	CreateConvertMoniker	

	.leave
	ret
SetConvertCurrencyMenuItems		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateConvertMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a moniker for one of the two currency conversion
		triggers

CALLED BY:	SetConvertCurrencyMenuItems (INTERNAL)

PASS:	SBCS<	AX	= '1.' or '2.'			>
	DBCS<	AX	= '1'  or '2'			>
		BX	= Handle of object block holding source text
		SI	= Chunk handle of text #1
		DI	= Chunk handle of text #2
		CX:DX	= OD of GenTrigger whose moniker we are replacing

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateConvertMoniker	proc	near
	uses	es
	.enter	inherit	SetConvertCurrencyMenuItems
	
	; Initialize the moniker
	;
	push	cx, dx				; save OD of GenTrigger
	push	di, bp
if DBCS_PCGEOS
	mov	ss:[newMoniker].TMS_data, ax
	mov	ss:[newMoniker].TMS_data+2, '.'
	mov	ss:[newMoniker].TMS_data+4, ' '
else
	mov	{word} ss:[newMoniker].TMS_data+0, ax
	mov	{char} ss:[newMoniker].TMS_data+2, ' '
endif
	mov	dx, ss
	mov	es, dx
SBCS<	lea	bp, ss:[newMoniker].TMS_data+3	; leave room for "1. "	>
DBCS<	lea	bp, ss:[newMoniker].TMS_data+6	; leave room for "1. "	>

	; Copy in text #1
	;
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	clr	cx
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	di, bp				; save string pointer
	pop	bp
DBCS<	shl	cx, 1				; cx is byte offset	>
	add	di, cx				; ss:di -> after string

	; Now copy in joining phrase (" to ")
	;
	push	bx, ds
	mov	bx, handle DescriptionResource
	call	MemLock
	mov	ds, ax
	assume	ds:DescriptionResource
	mov	si, ds:[ConvertJoinString]
	ChunkSizePtr ds, si, cx			; length of string => CX
	LocalPrevChar	dscx			; ignore NULL-terminator
	rep	movsb
	assume	ds:Nothing
	call	MemUnlock
	pop	si, bx, ds

	; Copy in text #2
	;
	push	bp
	mov	dx, ss
	mov	bp, di				; start where we left off
	clr	cx
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage
	pop	bp
	
	; Now replace the moniker (need to set RVMF_updateMode now,
	; as it gets nuked by method for MSG_GEN_REPLACE_VIS_MONIKER
	;
	pop	bx, si
	push	bp
	mov	ss:[chgMoniker].RVMF_updateMode, VUM_NOW
	lea	bp, chgMoniker
DBCS<	mov	dx, size chgMoniker	; args on stack			>
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_CALL
	call	ObjMessage	
	pop	bp

	.leave
	ret
CreateConvertMoniker	endp

endif  ; NOT _PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigCalcFloatConstant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	puts a constant on top of the fp stack

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Information was gathered from http://www.nist.gov about how
	to make our calculations more accurate. The specific URL is:
	   http://ts.nist.gov/ts/htdocs/230/235/appxc/appxc.htm		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	6/16/92		Initial version
	AS	8/27/96		Added new constants for PENELOPE
	Don	8/20/00		Organized & added precision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; For Inches <-> CM conversion
; Precision = EXACT
;
BigCalcFloat2Point54	proc	near
	uses	ax
	.enter

	mov	ax, 2540
	call	FloatWordToFloat
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloat2Point54	endp

; For Feet <-> M conversion
; Precision = EXACT
;
BigCalcFloatPoint32808333	proc	near
	uses	ax
	.enter

	mov	ax, 10000
	call	FloatWordToFloat
	mov	ax, 3048
	call	FloatWordToFloat
	call	FloatDivide

	.leave
	ret
BigCalcFloatPoint32808333	endp

; For Mile <-> Km conversion
; Precision = EXACT
;
BigCalcFloat1Point6093	proc	near
	uses	ax,dx
	.enter

	movdw	dxax, 1609344
	call	FloatDwordToFloat
	call	BigCalcFloatDivide10E6

	.leave
	ret
BigCalcFloat1Point6093	endp

; For Gallon <-> Liter conversion
; Precision = best available
;
BigCalcFloat3Point7854	proc	near
	uses	ax, dx
	.enter

if _ENGLISH_GALLONS
	movdw	dxax, 454579
	call	FloatDwordToFloat
	call	BigCalcFloatDivide10000
	call	FloatDivide10
else
	movdw	dxax, 3785412
	call	FloatDwordToFloat
	call	BigCalcFloatDivide10E6
endif
	.leave
	ret
BigCalcFloat3Point7854	endp

; For Pounds <-> Kg conversion
; Precision = best available
;
BigCalcFloat2Point205	proc	near
	uses	dx, ax
	.enter

	movdw	dxax, 2204623
	call	FloatDwordToFloat
	call	BigCalcFloatDivide10E6

	.leave
	ret
BigCalcFloat2Point205	endp


if _NEW_CONVERSIONS_IN_PENELOPE

; For Yards <-> M conversion
;
BigCalcFloat0Point9144	proc 	near
	uses 	ax
	.enter

	mov	ax, 9144
	call	FloatWordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat0Point9144 	endp

; For Sq. Inches <-> Sq. Cm conversion
;
BigCalcFloat6Point4516	proc 	near
	uses 	ax,dx
	.enter

	movdw	dxax, 64516
	call	FloatDwordToFloat
	call	BigCalcFloatDivide10000	

	.leave
	ret
BigCalcFloat6Point4516 	endp

; For Sq. Feet <-> Sq. M conversion
;
BigCalcFloat0Point0929	proc 	near
	uses 	ax
	.enter

	mov	ax, 929
	call	FloatWordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat0Point0929 	endp

; For Sq. Yard <-> Sq. M conversion
;
BigCalcFloat0Point8361	proc 	near
	uses 	ax
	.enter

	mov	ax, 8361
	call	FloatWordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat0Point8361 	endp

; For ...
;
BigCalcFloat0Point0040	proc 	near
	uses 	ax
	.enter

	mov	ax, 40
	call	FloatWordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat0Point0040	endp

; For Sq. Mile <-> Sq. Km conversion
;
BigCalcFloat2Point590	proc 	near
	uses 	ax
	.enter

	mov	ax, 2590
	call	FloatWordToFloat
	call	BigCalcFloatDivide1000	

	.leave
	ret
BigCalcFloat2Point590 	endp

; For ...
;
BigCalcFloat29Point573	proc 	near
	uses 	ax,dx
	.enter

	movdw	dxax, 29573
	call	FloatDwordToFloat
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloat29Point573	endp

; For ...
;
BigCalcFloat0Point4732	proc 	near
	uses 	ax
	.enter

	mov	ax, 4732
	call	FloatWordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat0Point4732	endp

; For ...
;
BigCalcFloat28Point413	proc 	near
	uses 	ax,dx
	.enter

	movdw	dxax, 28413
	call	FloatDwordToFloat
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloat28Point413	endp

; For ...
;
BigCalcFloat0Point5683	proc 	near
	uses 	ax
	.enter

	mov	ax, 5683
	call	FloatWordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat0Point5683	endp

; For UK gallon <-> Li conversion
;
BigCalcFloat4Point546	proc	near
	uses	ax,dx
	.enter

	movdw	dxax, 4546
	call	FloatDwordToFloat
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloat4Point546	endp

; For...
;
BigCalcFloat28Point349	proc	near
	uses	ax,dx
	.enter

	movdw	dxax, 28349
	call	FloatDwordToFloat
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloat28Point349	endp

; For ...
;
BigCalcFloat6Point3504	proc	near
	uses	ax,dx
	.enter

	movdw	dxax, 63504
	call	FloatDwordToFloat
	call	BigCalcFloatDivide10000

	.leave
	ret
BigCalcFloat6Point3504	endp

; For ...
;
BigCalcFloat1Point016	proc	near
	uses	ax
	.enter

	mov	ax, 1016
	call	FloatWordToFloat
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloat1Point016	endp

BigCalcFloatDivide10000	proc	near
	.enter

	call	BigCalcFloatDivide1000
	call	FloatDivide10

	.leave
	ret
BigCalcFloatDivide10000	endp
endif


BigCalcFloatDivide1000	proc	near
	.enter

	call	FloatDivide10
	call	FloatDivide10
	call	FloatDivide10

	.leave
	ret
BigCalcFloatDivide1000	endp

BigCalcFloatDivide10E6	proc	near
	.enter

	call	BigCalcFloatDivide1000
	call	BigCalcFloatDivide1000

	.leave
	ret
BigCalcFloatDivide10E6	endp

MathCode	ends



