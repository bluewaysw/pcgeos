COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Socket
MODULE:		access point database
FILE:		accpntCApi.asm

AUTHOR:		Eric Weber, May 25, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95   	Initial revision


DESCRIPTION:
	C Stubs for Access Point
		

	$Id: accpntCApi.asm,v 1.1 97/04/04 17:41:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGeosConvention

ApiCode	segment resource


;
; transform carry flag into a boolean
;
; carry set ->	 ax = BW_TRUE
; carry clear -> ax = BW_FALSE
;
CarryToBoolean macro
		mov	ax,0
		rcl	ax
		neg	ax
endm


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointCreateEntry

C DECLARATION:	
	extern  word _pascal AccessPointCreateEntry(word loc, 
	                                            AccessPointType apt);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTCREATEENTRY	proc	far	loc:word,
					apt:AccessPointType;
		.enter
		mov	bx, loc
		mov	ax, apt
		call	AccessPointCreateEntry
		.leave
		ret
ACCESSPOINTCREATEENTRY	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointDestroyEntry

C DECLARATION:	
	extern  Boolean _pascal AccessPointDestroyEntry(word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTDESTROYENTRY	proc	far	id:word
		.enter
		mov	ax, id
		call	AccessPointDestroyEntry
		CarryToBoolean
		.leave
		ret
ACCESSPOINTDESTROYENTRY	endp

ACCESSPOINTDESTROYENTRYDIRECT	proc	far	id:word
		.enter
		mov	ax, id
		call	AccessPointDestroyEntryDirect
		CarryToBoolean
		.leave
		ret
ACCESSPOINTDESTROYENTRYDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetType

C DECLARATION:	
	extern  AccessPointType _pascal AccessPointGetType(word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTGETTYPE	proc	far	id:word
		.enter
		mov	ax, id
		call	AccessPointGetType
		mov	ax, bx
		.leave
		ret
ACCESSPOINTGETTYPE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointSetStringProperty

C DECLARATION:	
	extern void _pascal AccessPointSetStringProperty(word id, 
	                                                 char *prop,
	                                                 char *val);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTSETSTRINGPROPERTY	proc	far	id:word,
						prop:fptr.char,
						val:fptr.char
		uses	es,di
		.enter
		mov	ax, id
		movdw	cxdx, prop
		movdw	esdi, val
		call	AccessPointSetStringProperty
		CarryToBoolean
		.leave
		ret
ACCESSPOINTSETSTRINGPROPERTY	endp

ACCESSPOINTSETSTRINGPROPERTYDIRECT	proc	far	id:word,
						prop:fptr.char,
						val:fptr.char
		uses	es,di
		.enter
		mov	ax, id
		movdw	cxdx, prop
		movdw	esdi, val
		call	AccessPointSetStringPropertyDirect
		CarryToBoolean
		.leave
		ret
ACCESSPOINTSETSTRINGPROPERTYDIRECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointSetIntegerProperty

C DECLARATION:	
	extern void _pascal AccessPointSetIntegerProperty(word id,
	                                                  char *prop,
	                                                  int val);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTSETINTEGERPROPERTY	proc	far	id:word,
						prop:fptr.char,
						val:word
		.enter
		push	bp
		mov	ax, id
		movdw	cxdx, prop
		mov	bp, val
		call	AccessPointSetIntegerProperty
		pop	bp
		CarryToBoolean
		.leave
		ret
ACCESSPOINTSETINTEGERPROPERTY	endp

ACCESSPOINTSETINTEGERPROPERTYDIRECT	proc	far	id:word,
						prop:fptr.char,
						val:word
		.enter
		push	bp
		mov	ax, id
		movdw	cxdx, prop
		mov	bp, val
		call	AccessPointSetIntegerPropertyDirect
		pop	bp
		CarryToBoolean
		.leave
		ret
ACCESSPOINTSETINTEGERPROPERTYDIRECT	endp
		

COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetStringPropertyBlock

C DECLARATION:	
	extern Boolean _pascal AccessPointGetStringPropertyBlock(word id, 
	                                                        char *prop,
	                                                        MemHandle *data,
	                                                        int *datalen);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTGETSTRINGPROPERTYBLOCK	proc	far	id:word,
							prop:fptr.char,
							data:fptr.hptr,
							datalen:fptr.word
		uses	ds, si
		.enter
		mov	ax, id
		movdw	cxdx, prop
		push	bp
		clr	bp
		call	AccessPointGetStringProperty
		pop	bp

		movdw	dssi, data
		mov	ds:[si], bx
		movdw	dssi, datalen
		mov	ds:[si], cx
		CarryToBoolean
		.leave
		ret
ACCESSPOINTGETSTRINGPROPERTYBLOCK	endp

ACCESSPOINTGETSTRINGPROPERTYBLOCKDIRECT	proc	far	id:word,
							prop:fptr.char,
							data:fptr.hptr,
							datalen:fptr.word
		uses	ds, si
		.enter
		mov	ax, id
		movdw	cxdx, prop
		push	bp
		clr	bp
		call	AccessPointGetStringPropertyDirect
		pop	bp

		movdw	dssi, data
		mov	ds:[si], bx
		movdw	dssi, datalen
		mov	ds:[si], cx
		CarryToBoolean
		.leave
		ret
ACCESSPOINTGETSTRINGPROPERTYBLOCKDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetStringPropertyBuffer

C DECLARATION:	
	extern Boolean _pascal AccessPointGetStringPropertyBuffer(word id,
	                                                       char *prop,
	                                                       char *buf,
	                                                       int *datalen);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTGETSTRINGPROPERTYBUFFER	proc	far	id:word,
							prop:fptr.char,
							buf:fptr.char,
							datalen:fptr.word
		uses	ds,si,es,di
		.enter
		mov	ax, id
		movdw	cxdx, prop
		movdw	dssi, datalen
		movdw	esdi, buf
		push	bp
		mov	bp, ds:[si]
		call	AccessPointGetStringProperty
		pop	bp
		mov	ds:[si], cx
		CarryToBoolean
		.leave
		ret
ACCESSPOINTGETSTRINGPROPERTYBUFFER	endp

ACCESSPOINTGETSTRINGPROPERTYBUFFERDIRECT	proc	far	id:word,
							prop:fptr.char,
							buf:fptr.char,
							datalen:fptr.word
		uses	ds,si,es,di
		.enter
		mov	ax, id
		movdw	cxdx, prop
		movdw	dssi, datalen
		movdw	esdi, buf
		push	bp
		mov	bp, ds:[si]
		call	AccessPointGetStringPropertyDirect
		pop	bp
		mov	ds:[si], cx
		CarryToBoolean
		.leave
		ret
ACCESSPOINTGETSTRINGPROPERTYBUFFERDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetIntegerProperty

C DECLARATION:	
	extern Boolean _pascal AccessPointGetIntegerProperty(word id,
	                                                     char *prop,
	                                                     int *val);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTGETINTEGERPROPERTY	proc	far	id:word,
						prop:fptr.char,
						val:fptr.word
		uses	ds,si
		.enter
		mov	ax, id
		movdw	cxdx, prop
		call	AccessPointGetIntegerProperty
		movdw	dssi, val
		mov	ds:[si], ax
		CarryToBoolean
		.leave
		ret
ACCESSPOINTGETINTEGERPROPERTY	endp

ACCESSPOINTGETINTEGERPROPERTYDIRECT	proc	far	id:word,
						prop:fptr.char,
						val:fptr.word
		uses	ds,si
		.enter
		mov	ax, id
		movdw	cxdx, prop
		call	AccessPointGetIntegerPropertyDirect
		movdw	dssi, val
		mov	ds:[si], ax
		CarryToBoolean
		.leave
		ret
ACCESSPOINTGETINTEGERPROPERTYDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointDestroyProperty

C DECLARATION:	
	extern Boolean _pascal AccessPointDestroyProperty(word id, char *prop);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTDESTROYPROPERTY	proc	far	id:word,
						prop:fptr.char
		uses	si, di
		.enter
		mov	ax, id
		movdw	cxdx, prop
		call	AccessPointDestroyProperty
		CarryToBoolean
		.leave
		ret
ACCESSPOINTDESTROYPROPERTY	endp

ACCESSPOINTDESTROYPROPERTYDIRECT	proc	far	id:word,
						prop:fptr.char
		uses	si, di
		.enter
		mov	ax, id
		movdw	cxdx, prop
		call	AccessPointDestroyPropertyDirect
		CarryToBoolean
		.leave
		ret
ACCESSPOINTDESTROYPROPERTYDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetEntries

C DECLARATION:	
	extern ChunkHandle _pascal AccessPointGetEntries(MemHandle mh,
	                                                 ChunkHandle chunk,
	                                                 AcessPointType apt);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTGETENTRIES	proc	far	mh:hptr,
					chnk:lptr,
					apt:AccessPointType
		uses	ds,si
		.enter
		mov	bx, mh
		call	MemDerefDS
		mov	si, chnk
		mov	ax, apt
		call	AccessPointGetEntries
		mov	ax, si
		.leave
		ret
ACCESSPOINTGETENTRIES	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointCompareStandardProperty

C DECLARATION:	
	extern Boolean _pascal
	    AccessPointCompareStandardProperty(AccessPointStandardProperty prop,
	                                       char *str);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/25/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTCOMPARESTANDARDPROPERTY	proc	far	prop:AccessPointStandardProperty,
							s:fptr.char
		uses	si, di
		.enter
		clr	ax
		mov	dx, prop
		movdw	esdi, s
		call	AccessPointCompareStandardProperty
		jnz	done
		mov	ax, BW_TRUE
done:
		.leave
		ret
ACCESSPOINTCOMPARESTANDARDPROPERTY	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointIsEntryValid

C DECLARATION:	
	extern Boolean _pascal AccessPointIsEntryValid(word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/95		Initial Revision

------------------------------------------------------------------------------@
ACCESSPOINTISENTRYVALID	proc	far	id:word
		.enter
		mov	ax, id
		call	AccessPointIsEntryValid
		cmc
		CarryToBoolean
		.leave
		ret
ACCESSPOINTISENTRYVALID	endp

ACCESSPOINTISENTRYVALIDDIRECT	proc	far	id:word
		.enter
		mov	ax, id
		call	AccessPointIsEntryValidDirect
		cmc
		CarryToBoolean
		.leave
		ret
ACCESSPOINTISENTRYVALIDDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointLock

C DECLARATION:	extern void _pascal AccessPointLock (word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/25/96	Initial version
------------------------------------------------------------------------------@
ACCESSPOINTLOCK	proc	far	id:word
		.enter

		mov	ax, id
		call	AccessPointLock

		.leave
		ret
ACCESSPOINTLOCK	endp

ACCESSPOINTLOCKDIRECT	proc	far	id:word
		.enter

		mov	ax, id
		call	AccessPointLockDirect

		.leave
		ret
ACCESSPOINTLOCKDIRECT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointUnlock

C DECLARATION:	extern void _pascal AccessPointUnlock (word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/25/96	Initial version
------------------------------------------------------------------------------@
ACCESSPOINTUNLOCK	proc	far	id:word
		.enter

		mov	ax, id
		call	AccessPointUnlock

		.leave
		ret
ACCESSPOINTUNLOCK	endp

ACCESSPOINTUNLOCKDIRECT	proc	far	id:word
		.enter

		mov	ax, id
		call	AccessPointUnlockDirect

		.leave
		ret
ACCESSPOINTUNLOCKDIRECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointInUse

C DECLARATION:	extern Boolean _pascal AccessPointInUse (word id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/25/96	Initial version
------------------------------------------------------------------------------@
ACCESSPOINTINUSE	proc	far	id:word
		.enter

		mov	ax, id
		call	AccessPointInUse
		CarryToBoolean			

		.leave
		ret
ACCESSPOINTINUSE	endp

ACCESSPOINTINUSEDIRECT	proc	far	id:word
		.enter

		mov	ax, id
		call	AccessPointInUseDirect
		CarryToBoolean			

		.leave
		ret
ACCESSPOINTINUSEDIRECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointSetActivePoint

C DECLARATION:	extern Boolean _pascal AccessPointSetActivePoint (word id, word tp);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	2/2/99		Initial version
------------------------------------------------------------------------------@
ACCESSPOINTSETACTIVEPOINT	proc	far	id:word,
						tp:word
		.enter

		mov	ax, id
		mov	dx, tp
		call	AccessPointSetActivePoint
		CarryToBoolean			

		.leave
		ret
ACCESSPOINTSETACTIVEPOINT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetActivePoint

C DECLARATION:	extern word _pascal AccessPointGetActivePoint (word tp);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	2/2/99		Initial version
------------------------------------------------------------------------------@
ACCESSPOINTGETACTIVEPOINT	proc	far	tp:word
		.enter

		mov	dx, tp
		call	AccessPointGetActivePoint
		jnc	done
		mov	ax, 0			; return 0 for error
done:

		.leave
		ret
ACCESSPOINTGETACTIVEPOINT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetDialingOptions

C DECLARATION:	extern void _pascal AccessPointGetDialingOptions(
			AccessPointDialingOptions *pOptions);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/3/99		Initial version
------------------------------------------------------------------------------@
ACCESSPOINTGETDIALINGOPTIONS	proc	far	pOptions:fptr.AccessPointDialingOptions
		.enter

		movdw	cxdx, pOptions
		call	AccessPointGetDialingOptions	; destroys: none

		.leave
		ret
ACCESSPOINTGETDIALINGOPTIONS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointSetDialingOptions

C DECLARATION:	extern void _pascal AccessPointSetDialingOptions(
			AccessPointDialingOptions *pOptions);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/3/99		Initial version
------------------------------------------------------------------------------@
ACCESSPOINTSETDIALINGOPTIONS	proc	far	pOptions:fptr.AccessPointDialingOptions
		.enter

		movdw	cxdx, pOptions
		call	AccessPointSetDialingOptions	; destroys: none

		.leave
		ret
ACCESSPOINTSETDIALINGOPTIONS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	AccessPointGetPhoneStringWithOptions

C DECLARATION:	extern Boolean _pascal AccessPointGetPhoneStringWithOptions(
			word id, MemHandle *pStringHan, int *datalen);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/3/99		Initial version
------------------------------------------------------------------------------@
ACCESSPOINTGETPHONESTRINGWITHOPTIONS	proc	far	id:word,
							pHan:fptr.hptr,
							datalen:fptr.word
		uses	ds, si
		.enter

		movdw	dssi, pHan
		mov	bx, ds:[si]
		mov	ax, id

		call	AccessPointGetPhoneStringWithOptions	; destroys: none

		mov	ds:[si], bx

		mov	ax, 0
		jnc	done
		dec	ax				; success - return true
		movdw	dssi, datalen			; return datalen
		mov	ds:[si], cx
done:
		.leave
		ret
ACCESSPOINTGETPHONESTRINGWITHOPTIONS	endp

ApiCode	ends

SetDefaultConvention
