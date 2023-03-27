COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	Geos	
MODULE:		Irlmp
FILE:		irdbC.asm

AUTHOR:		Andy Chiu, Mar  4, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96   	Initial revision


DESCRIPTION:
	C stubs to the IAS database routines
		

	$Id: irdbC.asm,v 1.1 97/04/05 01:08:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

IrdbCode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRDBCREATEENTRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry to the database.  The information needed
		to establish an entry is a class name.
		You can also pass in an lptr to an endpoint.  This will
		enable irlmp to delete your entry.  If you do not want this
		feature, then pass zero.

CALLED BY:	GLOBAL
PASS:		see below
RETURN:		ax	= Object ID (or IrdbErrorType)
DESTROYED:	bx, cx, dx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	sword	_pascal
		IrdbCreateEntry(char *classname, word length,
				word clientHandle, word flags);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRDBCREATEENTRY	proc	far	classname:fptr.char, ln:word,
				clientHandle:word, flags:word
		uses	si, ds
		.enter

		lds	si, classname
		mov	cx, ln
		mov	dx, clientHandle
		mov	ax, flags
		call	IrdbCreateEntry

		.leave
		ret
IRDBCREATEENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRDBDELETEENTRY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an entry in the database.  Give only
		the object id that was returned in the
		IrdbCreateEntry function.

CALLED BY:	GLOBAL
PASS:		see below
RETURN:		ax	= 0 if successful or IrdbErrorType
DESTROYED:	bx, cx, dx, es

PSEUDO CODE/STRATEGY:

sword
_pascal IrdbDeleteEntry(word objectID);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRDBDELETEENTRY	proc	far
		.enter

		C_GetOneWordArg	bx, ax, cx	; bx = object ID
		
		call	IrdbDeleteEntry
		
		.leave
		ret
IRDBDELETEENTRY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRDBADDATTRIBUTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an attribute for an object.
		Note this keeps attributes like an array.  You
		are appending an attribute to the end of the list.

CALLED BY:	GLOBAL
PASS:		see below
RETURN:		ax	= current number of attributes (if positve)
		ax	= error type (if negative)
DESTROYED:	es, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

sword
_pascal IrdbAddAttribute(word objectID, char *attrName, word attrNameSize,
				word dataType, void *data, word dataLegth);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRDBADDATTRIBUTE	proc	far	objectID:word, attrName:fptr,
					attrNameSize:word, dataType:word,
					data:dword, dataDesc:word
		uses	si, di, ds
		.enter

		push	bp
		mov	bx, objectID
		lds	si, attrName
		mov	di, dataType
		mov	cx, dataDesc
		movdw	dxax, data
		mov	bp, attrNameSize
		
		call	IrdbAddAttribute

		pop	bp
		
		.leave
		ret
IRDBADDATTRIBUTE	endp

IrdbCode	ends

	SetDefaultConvention














