
COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial revision

DESCRIPTION:
		
	$Id: uiFormatC.asm,v 1.1 97/04/05 01:23:22 newdeal Exp $

------------------------------------------------------------------------------@
	SetGeosConvention

FloatFormatCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATINIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatInit

C DECLARATION:	extern word _far_pascal FloatFormatInit

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATINIT	proc	far	vmFileHan:word
	uses	di,si
	.enter
	mov	bx, vmFileHan
	call	FloatFormatInit		; ax <- vm block handle of format array
	.leave
	ret
FLOATFORMATINIT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATGETFORMATPARAMSWITHLISTENTRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatGetFormatParamsWithListEntry

C DECLARATION:	extern void _far_pascal FloatFormatGetFormatParamsWithListEntry

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATGETFORMATPARAMSWITHLISTENTRY	proc	far	formatInfoStruc:fptr
	uses	es,di
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatGetFormatParamsWithListEntry	; cx <- token
	mov	ax, cx
	.leave
	ret
FLOATFORMATGETFORMATPARAMSWITHLISTENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATINITFORMATLIST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatInitFormatList

C DECLARATION:	extern void _far_pascal FloatFormatInitFormatList

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATINITFORMATLIST	proc	far	formatInfoStruc:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatInitFormatList
	.leave
	ret
FLOATFORMATINITFORMATLIST	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATPROCESSFORMATSELECTED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatProcessFormatSelected

C DECLARATION:	extern void _far_pascal FloatFormatProcessFormatSelected

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATPROCESSFORMATSELECTED	proc	far	formatInfoStruc:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatProcessFormatSelected
	.leave
	ret
FLOATFORMATPROCESSFORMATSELECTED	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATINVOKEUSERDEFDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatInvokeUserDefDB

C DECLARATION:	extern void _far_pascal FloatFormatInvokeUserDefDB

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATINVOKEUSERDEFDB	proc	far	formatInfoStruc:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatInvokeUserDefDB
	.leave
	ret
FLOATFORMATINVOKEUSERDEFDB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATUSERDEFOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatUserDefOK

C DECLARATION:	extern word _far_pascal FloatFormatUserDefOK

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATUSERDEFOK	proc	far	formatInfoStruc:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatUserDefOK	; cx <- non-zero if error
	mov	ax, cx
	.leave
	ret
FLOATFORMATUSERDEFOK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATGETFORMATTOKENWITHNAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatGetFormatTokenWithName

C DECLARATION:	extern word _far_pascal FloatFormatGetFormatTokenWithName

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATGETFORMATTOKENWITHNAME	proc	far	formatInfoStruc:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatGetFormatTokenWithName	; cx <- format token
	mov	ax, cx
	.leave
	ret
FLOATFORMATGETFORMATTOKENWITHNAME	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATGETFORMATPARAMSWITHTOKEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatGetFormatParamsWithToken

C DECLARATION:	extern void _far_pascal FloatFormatGetFormatParamsWithToken

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATGETFORMATPARAMSWITHTOKEN	proc	far	formatInfoStruc:fptr,
							buffer:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	push	bp
	mov	dx, buffer.segment
	mov	bp, buffer.offset
	call	FloatFormatGetFormatParamsWithToken
	pop	bp
	.leave
	ret
FLOATFORMATGETFORMATPARAMSWITHTOKEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATDELETE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatDelete

C DECLARATION:	extern word _far_pascal FloatFormatDelete
		
		if format was deleted, ax <- format token
		else if deletion was aborted, ax <- FORMAT_ID_INDETERMINATE

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATDELETE	proc	far	formatInfoStruc:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatDelete	; cx <- deleted format token
	mov	ax, FORMAT_ID_INDETERMINATE
	jc	done
	mov	ax, cx
done:
	.leave
	ret
FLOATFORMATDELETE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATISFORMATTHESAME?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatIsFormatTheSame?

C DECLARATION:	extern word _far_pascal FloatFormatIsFormatTheSame?

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATISFORMATTHESAME?	proc	far	formatInfoStruc:fptr,
						formatParams:fptr,
						formatToken:word
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
	mov	dx, formatParams.segment
	mov	bp, formatParams.offset
	mov	cx, formatToken
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatIsFormatTheSame?
	mov	ax, cx
	.leave
	ret
FLOATFORMATISFORMATTHESAME?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATADDFORMAT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatAddFormat

C DECLARATION:	extern word _far_pascal FloatFormatAddFormat

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FLOATFORMATADDFORMAT	proc	far	formatInfoStruc:fptr,
					formatParams:fptr
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
	mov	dx, ss:[formatParams].segment
	mov	bp, ss:[formatParams].offset
EC<	tst	di >
EC<	ERROR_NE FLOAT_FORMAT_ZERO_OFFSET_EXPECTED >
	call	FloatFormatAddFormat
	mov	ax, dx			; ax <- token
	jnc	done

	clr	ax
done:
	.leave
	ret
FLOATFORMATADDFORMAT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FLOATFORMATGETMODIFIEDFORMAT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	FloatFormatAddFormat

C DECLARATION:	extern word _pascal FloatFormatGetModifiedFormat(
					FormatInfoStruc *formatInfoStruc,
					FloatModifyFormatFlags modifyFlags);

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLOATFORMATGETMODIFIEDFORMAT	proc	far	formatInfoStruc:fptr,
						modifyFlags:word
	uses	es,di,si
	.enter
	les	di, formatInfoStruc
	mov	dx, modifyFlags
	call	FloatFormatGetModifiedFormat	; ax = token
	.leave
	ret
FLOATFORMATGETMODIFIEDFORMAT	endp

FloatFormatCode	ends
