COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:		Main
FILE:		mainC.asm

AUTHOR:		Cassie Hartzog, Oct 4, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95	Initial revision

DESCRIPTION:
	This file contains C stubs for the DS routines.	

	$Id: mainC.asm,v 1.1 97/04/04 17:53:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DataStoreC	segment	resource

SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORECREATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
		    _pascal DataStoreCreate(DataStoreCreateParams *params,
				word *dsToken);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORECREATE	proc	far	params:fptr, dsToken:fptr.word
	uses	ds, si
	.enter

	lds	si, params
	call	DataStoreCreate
	jc	exit
	lds	si, dsToken
	mov	ds:[si], ax	
	mov	ax, DSE_NO_ERROR

exit:
	.leave
	ret
DATASTORECREATE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREOPEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
		    _pascal DataStoreOpen(TCHAR *dsName, optr object, 
				DataStoreOpenFlags flag, word *dsToken);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREOPEN	proc	far	dsName:fptr.TCHAR, object:optr, 
				flag:word, dsToken:fptr.word
	uses	si,di,ds,es
	.enter

	les	di, dsName
	movdw	cxdx, object
	mov	ax, flag		; al - flag
	clr	ah
	call	DataStoreOpen
	jc	exit
	lds	si, dsToken		
	mov	ds:[si], ax
	mov	ax, DSE_NO_ERROR
exit:
	.leave
	ret
DATASTOREOPEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORECLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern word
		    _pascal DataStoreClose(word dsToken);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORECLOSE	proc	far	dsToken:word
	.enter

	mov	ax, dsToken
	call	DataStoreClose

	.leave
	ret
DATASTORECLOSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREDELETE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
	    		_pascal DataStoreDelete(TCHAR* dsname);		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREDELETE	proc	far	dsname:fptr.TCHAR
	uses	ds
	.enter

	lds	dx, dsname
	call	DataStoreDelete
	
	.leave
	ret
DATASTOREDELETE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORERENAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
		    _pascal DataStoreRename(TCHAR* oldName, TCHAR* newName)		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORERENAME	proc	far	oldName:fptr.TCHAR, newName:fptr.TCHAR
	uses	ds, es, di
	.enter
	
	lds	dx, oldName
	les	di, newName
	call	DataStoreRename

	.leave
	ret
DATASTORERENAME	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFIELDCOUNT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
	    _pascal DataStoreGetFieldCount(word dsToken, word* count)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFIELDCOUNT	proc	far	dsToken:word, count:fptr.word
	uses	ds, si
	.enter

	mov	ax, dsToken
	call	DataStoreGetFieldCount
	jc	exit			; CF set: ax = DataStoreStructureError
	lds	si, count
	mov	ds:[si], ax		; CF clear: ax = field count
	mov	ax, DSE_NO_ERROR
exit:
	.leave
	ret
DATASTOREGETFIELDCOUNT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETRECORDCOUNT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
	    _pascal DataStoreGetRecordCount(word dsToken, dword* count)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETRECORDCOUNT	proc	far	dsToken:word, count:fptr.dword
	uses	ds, si
	.enter

	mov	ax, dsToken
	call	DataStoreGetRecordCount
	jc	exit
	lds	si, count
	movdw	ds:[si], dxax
	mov	ax, DSE_NO_ERROR
exit:
	.leave
	ret
DATASTOREGETRECORDCOUNT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFLAGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
	    _pascal DataStoreGetFlags(word dsToken, DataStoreFlags* flags);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFLAGS	proc	far	dsToken:word, flags:fptr.DataStoreFlags
	uses	ds, si
	.enter

	mov	ax, dsToken
	call	DataStoreGetFlags
	jc	exit
	lds	si, flags
	mov	{word} ds:[si], ax
	mov	ax, DSE_NO_ERROR		
exit:
	.leave
	ret
DATASTOREGETFLAGS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETOWNER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
	    _pascal DataStoreGetOwner(word dsToken, GeodeToken* token);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETOWNER	proc	far	dsToken:word, token:fptr.GeodeToken
		uses	ds, si
		.enter

		mov	ax, dsToken
		call	DataStoreGetOwner
		jc	exit

		lds	si, token
		movdw	ds:[si].GT_chars, dxax		
		mov	ds:[si].GT_manufID, cx
		mov	ax, DSE_NO_ERROR		
exit:
		.leave
		ret
DATASTOREGETOWNER	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETVERSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION: extern DataStoreError
	    _pascal DataStoreGetVersion(word dsToken, ProtocolNumber* version)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETVERSION	proc	far	dsToken:word, version:fptr.ProtocolNumber
		uses	ds, si
		.enter

		mov	ax, dsToken
		call	DataStoreGetVersion
		jc	exit

		lds	si, version
		movdw	ds:[si], dxax
		mov	ax, DSE_NO_ERROR
exit:
		.leave
		ret
DATASTOREGETVERSION	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESETVERSION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
    _pascal DataStoreSetVersion(word dsToken, ProtocolNumber version)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESETVERSION	proc	far	dsToken:word, version:ProtocolNumber
	.enter

	mov	ax, dsToken
	movdw	dxcx, version	
	call	DataStoreSetVersion

	.leave
	ret
DATASTORESETVERSION	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETEXTRADATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
    _pascal DataStoreGetExtraData(word dsToken, void *dsData, word *dsSize);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETEXTRADATA	proc	far	dsToken:word, dsData:fptr, dsSize:fptr
	uses	si, di, ds
	.enter

	mov	ax, dsToken
	lds	si, dsSize
	mov	cx, ds:[si]
	les	di, dsData
	call	DataStoreGetExtraData
	jc	exit
	lds	si, dsSize
	mov	ds:[si], cx
exit:
	.leave
	ret
DATASTOREGETEXTRADATA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESETEXTRADATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
    _pascal DataStoreSetExtraData(word dsToken, void *data, word dsSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESETEXTRADATA	proc	far	dsToken:word, data:fptr, dsSize:word
	uses	ds
	.enter

	mov	ax, dsToken
	lds	dx, data
	mov	cx, dsSize
	call	DataStoreSetExtraData

	.leave
	ret
DATASTORESETEXTRADATA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETTIMESTAMP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
    _pascal DataStoreGetTimeStamp(word dsToken, FileDateAndTime *fdat)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETTIMESTAMP	proc	far	dsToken:word, fdat:fptr.FileDateAndTime
		uses	es, di
		.enter

		mov	ax, dsToken
		call	DataStoreGetTimeStamp
		jc	done
		les	di, fdat
		movdw	es:[di], dxax
		mov	ax, DSE_NO_ERROR
done:
		.leave
		ret
DATASTOREGETTIMESTAMP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESETTIMESTAMP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreError
    _pascal DataStoreSetTimeStamp(word dsToken, FileDateAndTime fdat)	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESETTIMESTAMP	proc	far	dsToken:word, fdat:FileDateAndTime
		.enter

		mov	ax, dsToken
		movdw	dxcx, fdat
		call	DataStoreSetTimeStamp
		jc	done
		mov	ax, DSE_NO_ERROR
done:		
		.leave
		ret
DATASTORESETTIMESTAMP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREADDFIELD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
		    _pascal DataStoreAddField(word dsToken,
					FieldDescriptor *field, FieldID *id);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREADDFIELD	proc	far	dsToken:word, field:fptr, id:fptr
		uses	es, di
		.enter

		mov	ax, dsToken
		les	di, field
		call	DataStoreAddField
		jc	exit
		les	di, id
		mov	{byte}	es:[di], al
		mov	ax, DSSE_NO_ERROR
exit:
		.leave
		ret
DATASTOREADDFIELD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREDELETEFIELD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
		    _pascal DataStoreDeleteField(word dsToken,
						 TCHAR *field, FieldID id);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREDELETEFIELD	proc	far	dsToken:word, field:fptr, id:word
		uses	si
		.enter

		movdw	cxsi, field, ax
		mov	ax, dsToken
		mov	dx, id
		call	DataStoreDeleteField
		.leave
		ret
DATASTOREDELETEFIELD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORERENAMEFIELD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
	    _pascal DataStoreRenameField(word dsToken, TCHAR *newName, 
					 TCHAR *oldName, FieldID id)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORERENAMEFIELD	proc	far	dsToken:word,
			newName:fptr, oldName:fptr, id:word

	uses	es, di, si
	.enter

	mov	ax, dsToken
	les	di, newName
	movdw	bxsi, oldName
	mov	dx, id
	call	DataStoreRenameField
	.leave
	ret
DATASTORERENAMEFIELD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREFIELDNAMETOID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
    _pascal DataStoreFieldNameToID(word dsToken, TCHAR* dsName, FieldID *id)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREFIELDNAMETOID	proc	far	dsToken:word, dsName:fptr, id:fptr.byte
	uses	es, di
	.enter

	mov	ax, dsToken
	les	di, dsName
	call	DataStoreFieldNameToID
	jc	exit
	les	di, id
	mov	{byte} es:[di], al
	mov	ax, DSSE_NO_ERROR
exit:
	.leave
	ret
DATASTOREFIELDNAMETOID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREFIELDIDTONAME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
	    _pascal DataStoreFieldIDToName(word dsToken, FieldID id, 
					   TCHAR *dsName, word *dsSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREFIELDIDTONAME	proc	far	dsToken:word, id:word,
					dsName:fptr, dsSize:fptr.word
	uses	di, es
	.enter

	mov	ax, dsToken
	les	di, dsSize
	mov	cx, es:[di]
	les	di, dsName
	mov	dx, id
	call	DataStoreFieldIDToName
	jc	exit
	les	di, dsSize
	mov	es:[di], cx
exit:
	.leave
	ret
DATASTOREFIELDIDTONAME	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFIELDINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
	    _pascal DataStoreGetFieldInfo(word dsToken,
					  FieldDescriptor *field,
					  FieldID id,
					  word fieldNameSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version
	jmagasin 9/17/96	Added fieldNameSize, size of field->FD_name.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFIELDINFO	proc	far	dsToken:word, field:fptr,
					id:word, fieldNameSize:word
	uses	di, es
	.enter

	mov	ax, dsToken
	les	di, field
	mov	dx, id
	mov	cx, fieldNameSize
	call	DataStoreGetFieldInfo
	.leave
	ret
DATASTOREGETFIELDINFO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORENEWRECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
		    _pascal DataStoreNewRecord(word dsToken)


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORENEWRECORD	proc	far	dsToken:word
	.enter
	mov	ax, dsToken
	call	DataStoreNewRecord	
	.leave
	ret
DATASTORENEWRECORD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORELOADRECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreLoadRecord(word dsToken, RecordID id, RecordNum num)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORELOADRECORD	proc	far	dsToken:word, id:RecordID,
					num:fptr.RecordNum
	uses	si, ds
	.enter

	mov	ax, dsToken
	movdw	dxcx, id
	call	DataStoreLoadRecord
	jc	done
	lds	si, num
	movdw	ds:[si], dxcx
done:
	.leave
	ret
DATASTORELOADRECORD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORELOADRECORDNUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreLockRecordNum(word dsToken, RecordNum dsRec, 
						RecordID *id)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORELOADRECORDNUM	proc	far	dsToken:word, dsRec:dword,
					id:fptr.dword
	uses	ds, di
	.enter
	mov	ax, dsToken
	movdw	dxcx, dsRec
	call	DataStoreLoadRecordNum
	jc	exit
	lds	di, id
	movdw	ds:[di], dxcx
exit:
	.leave
	ret
DATASTORELOADRECORDNUM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREDISCARDRECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreDiscardRecord(word dsToken)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREDISCARDRECORD	proc	far	dsToken:word
	.enter

	mov	ax, dsToken
	call	DataStoreDiscardRecord

	.leave
	ret
DATASTOREDISCARDRECORD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESAVERECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern void
	    _pascal DatastoreSaveRecord(word dsToken, void *cbData,
			PCB(word, callback,
			(RecordHandle rec1, RecordHandle rec2,
			word dsToken, void *cbData)),
			RecordNum *index, RecordID *rid);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESAVERECORD	proc	far	dsToken:word,
					cbData:fptr,
					callback:fptr,
					index:fptr.RecordNum,
					rid:fptr.RecordID
	uses	si, di, ds	
	passedES	local	sptr	push	es
	passedDS	local	sptr	push	ds

	ForceRef	cbData
	ForceRef	passedES
	ForceRef	passedDS
	.enter

	mov	ax, dsToken
	clr	cx, dx
	tst	callback.high
	jz	noCallback
	mov	cx, vseg InsertCallback
	mov	dx, offset InsertCallback
noCallback:
	call	DataStoreSaveRecord
	jc	exit		
	lds	si, index
	movdw	ds:[si], dxax
	lds	si, rid
	movdw	ds:[si], bxcx
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTORESAVERECORD	endp

DATASTORESAVERECORDNOUPDATE	proc	far	dsToken:word,
						cbData:fptr,
						callback:fptr,
						index:fptr.RecordNum,
						rid:fptr.RecordID
	uses	si, di, ds	
	passedES	local	sptr	push	es
	passedDS	local	sptr	push	ds

	ForceRef	cbData
	ForceRef	passedES
	ForceRef	passedDS
	.enter

	mov	ax, dsToken
	clr	cx, dx
	tst	callback.high
	jz	noCallback
	mov	cx, vseg InsertCallback
	mov	dx, offset InsertCallback
noCallback:
	call	DataStoreSaveRecordNoUpdate
	jc	exit		
	lds	si, index
	movdw	ds:[si], dxax
	lds	si, rid
	movdw	ds:[si], bxcx
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTORESAVERECORDNOUPDATE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the user provided callback

CALLED BY:	EXTERNAL (DataStoreSaveRecord)
PASS:		ds:si - RecordHeader for record 2 (record in datastore)
		es:di -	RecordHeader for record 1 (record to insert)
		ax    - datstore token
		bp    - stack frame inherited from DATASTORESAVERECORD
		
RETURN:		ax - 0 if records are equal
		    -1 if rec1 comes before rec2
		     1 if rec1 comes after rec2
DESTROYED:	ax, bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertCallback	proc	far
	.enter	inherit DATASTORESAVERECORD

	pushdw	esdi			; rec1
	pushdw	dssi			; rec2
	push	ax			; dsToken
	pushdw	cbData			; cbData
	mov	ds, passedDS
	mov	es, passedES
	movdw	bxax, callback
	call	ProcCallFixedOrMovable
	.leave
	ret
InsertCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreRecordEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern Boolean
	    _pascal DataStoreRecordEnum(word dsToken, RecordNum *startRecord,
			    DataStoreRecordEnumFlags flags, void *enumData,
				PCB(Boolean, callback,
				(RecordHeader *record, void *enumData)));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95     	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORERECORDENUM	proc	far	dsToken:word, startRecord:fptr.dword,
					flags:word, enumData:fptr,
					callback:fptr
		passedDS	local	sptr	\
				push	ds
		passedES	local	sptr	\
				push	es
		ForceRef	callback
		ForceRef	enumData
		ForceRef	passedDS
		ForceRef	passedES
		uses	di, si, es
		.enter	

		mov	ax, dsToken
		mov	si, flags
		les	di, startRecord
		movdw	dxcx, es:[di]
		mov	bx, SEGMENT_CS
		mov	di, offset DataStoreRecordEnumCCallback
		call	DataStoreRecordEnum
		jc	done

		cmp	ax, DSE_NO_ERROR
		jne	done
		les	di, startRecord
		movdw	es:[di], dxcx
done:
		.leave
		ret
DATASTORERECORDENUM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreRecordEnumCCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls a callback routine

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to record element
		ss:bp - stack frame inherited from DATASTORERECORDENUM
RETURN:		carry set to stop enumerating
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreRecordEnumCCallback	proc	far
	uses	ds, es
	.enter	inherit	DATASTORERECORDENUM
	pushdw	dsdi			;Push pointer to record on stack
	pushdw	enumData
	mov	ds, passedDS
	mov	es, passedES
	mov	bx, callback.segment
	mov	ax, callback.offset
	call	ProcCallFixedOrMovable
	tst_clc	ax
	jz	exit
	stc
exit:
	.leave
	ret
DataStoreRecordEnumCCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORELOCKRECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
		    _pascal DataStoreLockRecord(word dsToken,
				RecordHeader **record);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORELOCKRECORD	proc	far	dsToken:word, rec:fptr.RecordHeader
	uses	si,di,ds,es
	.enter
	mov	ax, dsToken
	call	DataStoreLockRecord	; ds:si <- RecordHeader
	jc	exit
	les	di, rec
	movdw	es:[di], dssi, ax
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTORELOCKRECORD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREUNLOCKRECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern void
		    _pascal DataStoreLockRecord(word dsToken);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREUNLOCKRECORD	proc	far	dsToken:word
	.enter
	mov	ax, dsToken
	call	DataStoreUnlockRecord
	.leave
	ret
DATASTOREUNLOCKRECORD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREDELETERECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreDeleteRecord(word dsToken, RecordID dsRec)	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREDELETERECORD	proc	far	dsToken:word, dsRec:dword
	.enter

	mov	ax, dsToken
	movdw	dxcx, dsRec
	call	DataStoreDeleteRecord

	.leave
	ret
DATASTOREDELETERECORD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREDELETERECORDNUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreDeleteRecordNum(word dsToken, RecordNum dsRec)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREDELETERECORDNUM	proc	far	dsToken:word, dsRec:dword
	.enter

	mov	ax, dsToken
	movdw	dxcx, dsRec
	call	DataStoreDeleteRecordNum

	.leave
	ret
DATASTOREDELETERECORDNUM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFIELDSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreGetFieldSize(word dsToken, TCHAR *field, 
					  FieldID id, word *dsSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFIELDSIZE	proc	far	dsToken:word, field:fptr,
					id:word, dsSize:fptr.word

	uses	ds, si,di
	.enter

	movdw	bxsi, field, ax
	mov	ax, dsToken
	mov	dx, id
	clr	dh
	call	DataStoreGetFieldSize
	jc	exit
	lds	si, dsSize
	mov	ds:[si], ax
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTOREGETFIELDSIZE	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFIELD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreGetField(word dsToken, TCHAR *field, 
		FieldID id, void **data, word *dsSize, MemHandle *mh)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFIELD	proc	far	dsToken:word, field:fptr, id:word,
					data:fptr.fptr, dsSize:fptr.word,
					mh:fptr.MemHandle		 
	uses	es, ds, si,di
	.enter
	
	mov	ax, dsToken
	lds	si, data		; data - ptr to buffer ptr
	les	di, ds:[si]		; es:[di]- ptr to buffer
	lds	si, dsSize
	mov	cx, ds:[si]
	movdw	bxsi, field
	mov	dx, id
	mov	dh, 0				
	call	DataStoreGetField
	jc	exit		

	mov	ax, DSDE_NO_ERROR

	lds	si, dsSize
	mov	ds:[si], cx
	tst	bx
	jz	exit	; no buffer allocated
	lds	si, mh
	mov	ds:[si], bx
	lds	si, data
	movdw	ds:[si], esdi
exit:		
	.leave
	ret
DATASTOREGETFIELD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFIELDCHUNK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	    _pascal DataStoreGetFieldChunk(word dsToken, TCHAR *field, 
		FieldID id, MemHandle mh, ChunkHandle *chHan, word *dsSize)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFIELDCHUNK	proc	far	dsToken:word, field:fptr, id:word,
					mh:hptr, chHan:fptr.ChunkHandle,
					dsSize:fptr.word
	uses	ds, si,di
	.enter
	
	mov	ax, dsToken
	movdw	cxsi, field
	mov	dx, id
	clr	dh
	mov	bx, mh
	lds	di, chHan
	mov	di, ds:[di]		; di <- ChunkHandle
	call	DataStoreGetFieldChunk
	jc	exit		


	lds	si, dsSize
	mov	ds:[si], cx
	tst	cx			; check if the field is absent
	jz	done

	lds	si, chHan
	mov	ds:[si], ax
done:
	mov	ax, DSDE_NO_ERROR
exit:		
	.leave
	ret
DATASTOREGETFIELDCHUNK	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESETFIELD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
		    _pascal DataStoreSetField(word dsToken, 
		    			      TCHAR* field, FieldID id,
					      TCHAR *data, word dataSize)


REVISION HISTORY:
	Data	Date		Description
	----	----		-----------
	wy	10/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESETFIELD	proc	far	dsToken:word, field:fptr.TCHAR,
					id:word, data:fptr, dataSize:word
				
	uses	es, si, di
	.enter
	mov	ax, dsToken
	movdw	bxsi, field
	mov	dx, id
	clr	dh
	les	di, data
	mov	cx, dataSize
	call	DataStoreSetField
	.leave
	ret
DATASTORESETFIELD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREREMOVEFIELDFROMRECORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
		_pascal DatastoreRemoveFieldFromRecord(word dsToken, 
					TCHAR *field, FieldID id);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREREMOVEFIELDFROMRECORD	proc	far	dsToken:word,
						field:fptr.TCHAR, id:word

	uses	si
	.enter
	mov	ax, dsToken
	movdw	cxsi, field, dx
	mov	dx, id
	mov	dh, 0
	call	DataStoreRemoveFieldFromRecord

	.leave
	ret
DATASTOREREMOVEFIELDFROMRECORD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETFIELDPTR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreDataError
	_pascal DatastoreGetFieldPtr(word dsToken, RecordHeader *rec, 
		   		     FieldID id, void **content,
				     FieldType *fType, word *fSize);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	11/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETFIELDPTR	proc	far	dsToken:word, rec:fptr,
					id:word, content:fptr.fptr,
					fType:fptr, fSize:fptr

	uses	si,di,ds,es
	.enter
	mov	ax, dsToken
	lds	si, rec
	mov	dx, id
	mov	dh, 0
	call	DataStoreGetFieldPtr
	jc	exit
	les	si, fSize
	mov	es:[si], cx
	les	si, fType
	mov	{byte} es:[si], dh
	les	si, content
	movdw	es:[si], dsdi, ax
	mov	ax, DSDE_NO_ERROR
exit:

	.leave
	ret
DATASTOREGETFIELDPTR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREMAPRECORDNUMTOID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreDataError
    _pascal DatastoreMapRecordNumToID(word dsToken, RecordNum num, 
					RecordID *id);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREMAPRECORDNUMTOID	proc	far 	dsToken:word, num:RecordNum,
					id:fptr.RecordID
	uses	si, ds
	.enter
	movdw	dxcx, num, ax
	mov	ax, dsToken
	call	DataStoreMapRecordNumToID
	jc	exit
	lds	si, id
	movdw	ds:[si], dxcx, ax
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTOREMAPRECORDNUMTOID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETNUMFIELDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreDataError
    _pascal DatastoreGetNumFields(word dsToken, word* num);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETNUMFIELDS	proc	far 	dsToken:word, num:fptr.word
	uses	si, ds
	.enter
	mov	ax, dsToken
	call	DataStoreGetNumFields
	jc	exit
	lds	si, num
	mov	ds:[si], ax
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTOREGETNUMFIELDS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREFIELDENUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern Boolean
	    _pascal DatastoreFieldEnum(word dsToken, RecordHeader *rec,
	void *enumData, PCB(Boolean, callback, (void *content, 
	word size, FieldType type, FieldCategory cat, FieldID fid, 
	FieldFlags flags, void *enumData)));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREFIELDENUM	proc	far	dsToken:word, rec:fptr, 
					enumData:fptr, callback:fptr
	passedDS	local	sptr	push	ds
	passedES	local	sptr	push	es
	ForceRef	callback
	ForceRef	enumData
	ForceRef	passedDS
	ForceRef	passedES
	uses	di, ds, si
	.enter	
	mov	ax, dsToken
	lds	si, rec
	mov	bx, vseg DatastoreFieldEnumCCallback
	mov	di, offset DatastoreFieldEnumCCallback
	call	DataStoreFieldEnum
	mov	ax, 0
	jnc	exit
	mov	ax, -1
exit:
	.leave
	ret
DATASTOREFIELDENUM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DatastoreFieldEnumCCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls a callback routine

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to field content
		cx - field content size
		al - field type
		ah - field category
		dl - field id
		dh - field flags
		bp - callback data

RETURN:		carry set to stop enum
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DatastoreFieldEnumCCallback	proc	far
	uses	ds, es
	.enter	inherit	DATASTOREFIELDENUM
	pushdw	dsdi		; push field content
	push	cx		; push field content size
	clr	ch
	mov	cl, al
	push	cx		; push field type
	mov	cl, ah
	push	cx		; push field category
	mov	cl, dl
	push	cx		; push field id
	mov	cl, dh
	push	cx		; push field flags
	pushdw	enumData
	mov	ds, passedDS
	mov	es, passedES
	mov	bx, callback.segment
	mov	ax, callback.offset
	call	ProcCallFixedOrMovable
	tst_clc	ax
	jz	exit
	stc
exit:
	.leave
	ret
DatastoreFieldEnumCCallback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETNUMFIELDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreError
    _pascal DatastoreStringSearch(word dsToken, SearchParams* params);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESTRINGSEARCH	proc	far 	dsToken:word, params:fptr
		uses	di, es
		.enter
		mov	ax, dsToken
		les	di, params
		call	DataStoreStringSearch
		jc	done
		les	di, params
		movdw	es:[di].SP_startRecord, dxax
		mov	es:[di].SP_startField, bl
		mov	ax, DSE_NO_ERROR
done:		
		.leave
		ret
DATASTORESTRINGSEARCH	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREBUILDINDEX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern DataStoreStructureError
	_pascal DataStoreBuildIndex(word dsToken, MemHandle *indexHandle,
		                word headerSize,
				DataStoreIndexCallbackParams *params, 
	 	                PCB(sword, callback, (word dsToken,
				    DataStoreIndexCallbackParams *params)));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREBUILDINDEX	proc	far	dsToken:word,
					indexHandle:fptr.MemHandle,
					headerSize:word, params:fptr,
					callback:fptr
	uses	si, di, ds,es	
	passedES	local	sptr	push	es
	passedDS	local	sptr	push	ds
	ForceRef	passedES
	ForceRef	passedDS
	.enter

	clr	cx, di
	mov	ax, dsToken
	mov	dx, headerSize
	lds	si, params	
	tst	callback.high
	jz	noCallback
	mov	cx, vseg IndexCallback
	mov	di, offset IndexCallback
noCallback:
	call	DataStoreBuildIndex
	jc	exit		
	lds	si, indexHandle
	mov	ds:[si], bx
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret

DATASTOREBUILDINDEX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndexCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the user provided callback

CALLED BY:	EXTERNAL (DataStoreBuildIndex)
PASS:		es:di - DataStoreIndexCallbackParams pointer
		ax    - datastore token
		bp    - stack frame inherited from DATASTORESAVERECORD
		
RETURN:		ax - -1 if rec1 comes before rec2
		      1 if rec1 comes after rec2
DESTROYED:	ax, bx, si, ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IndexCallback	proc	far
	uses	bx,ds,es
	.enter	inherit DATASTOREBUILDINDEX

	push    ax
	pushdw  esdi

	mov	ds, passedDS
	mov	es, passedES
	movdw	bxax, callback
	call	ProcCallFixedOrMovable

	.leave
	ret
IndexCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETRECORDID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreDataError
    _pascal DatastoreGetRecordID(word dsToken, RecordID* rid);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETRECORDID	proc	far	dsToken:word, rid:fptr.RecordID
	uses	si,ds
	.enter
	mov	ax, dsToken
	call	DataStoreGetRecordID
	jc	exit
	lds	si, rid
	movdw	ds:[si], dxax
	mov	ax, DSDE_NO_ERROR
exit:
	.leave
	ret
DATASTOREGETRECORDID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESETRECORDID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreDataError
    _pascal DatastoreSetRecordID(word dsToken, RecordID rid);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESETRECORDID	proc	far	dsToken:word, rid:RecordID
	.enter
	movdw	dxcx, rid, ax
	mov	ax, dsToken
	call	DataStoreSetRecordID
	.leave
	ret
DATASTORESETRECORDID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETNEXTRECORDID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreError
    _pascal DatastoreGetNextRecordID(word dsToken, RecordID *rid);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETNEXTRECORDID	proc	far	dsToken:word, rid:fptr.RecordID
	uses	si,ds
	.enter
	mov	ax, dsToken
	call	DataStoreGetNextRecordID
	jc	exit
	lds	si, rid
	movdw	ds:[si], dxax
	mov	ax, DSE_NO_ERROR
exit:
	.leave
	ret
DATASTOREGETNEXTRECORDID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTORESETNEXTRECORDID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION: extern DataStoreError
    _pascal DatastoreSetNextRecordID(word dsToken, RecordID rid);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	WY	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTORESETNEXTRECORDID	proc	far	dsToken:word, rid:RecordID
	.enter
	movdw	dxcx, rid, ax
	mov	ax, dsToken
	call	DataStoreSetNextRecordID
	.leave
	ret
DATASTORESETNEXTRECORDID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATASTOREGETCURRENTTRANSACTIONNUMBER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DEFINITION:	extern DataStoreError
	_pascal DatastoreGetCurrentTransactionNumber(word dsToken);

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	3/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATASTOREGETCURRENTTRANSACTIONNUMBER	proc	far	dsToken:word
	.enter
	mov	ax, dsToken
	call	DataStoreGetCurrentTransactionNumber
	jc	done
	mov	ax, DSE_NO_ERROR
done:
	.leave
	ret
DATASTOREGETCURRENTTRANSACTIONNUMBER	endp

DataStoreC	ends

