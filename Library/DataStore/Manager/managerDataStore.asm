COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	DataStore	
MODULE:		Manager
FILE:		managerDataStore.asm

AUTHOR:		Mybrid Spalding, Oct 11, 1995

ROUTINES:
	Name			Description
	----			-----------
EXT	DataStoreOpen		API stub which calls 
				MDDataStoreOpenWithFileHandle
EXT	MDDataStoreOpenWithFileHandle
				Opens a DataStore with or without a fileHandle

EXT	DataStoreClose		API stub which calls MDDataStoreCloseWithFlags
INT	MDDataStoreCloseWithFlags
				Closes a Datastore based on flags 
INT	MDDataStoreCloseFileCallBack
				Callback that closes the actual DataStore file

EXT	DataStoreCreate		API routine for creating a datastore.
INT	MDVerifyDataStoreCreateParams
				Verify the parameters passed to DataStoreCreate
INT	MDDuplicateNameCheck	Verify a primary key field name is not
				duplicated in the keylist.

INT	MDVerifyDataStoreFlags	Checks for bits corresponding to
				DataStoreFlags.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/11/95   	Initial revision


DESCRIPTION:
	DataStore API routines for the DataStore Manager which manipulate the
entire datastore. 

	$Id: managerDataStore.asm,v 1.1 97/04/04 17:53:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManagerMainCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a DataStore session. Adds the DSSessionElement to
		the Session array as well as a DSElement to the 
		DataStore array if the DataStore
                file is being opened for the first time.
		If the flag DSOF_EXCLUSIVE is passed, the app will
		open the file with exclusive access if no other
		application has the datastore open. If the file is
		opened by anyone else, this call will fail with  
		DSE_ACCESS_DENIED

CALLED BY:	(EXTERNAL) GLOBAL
PASS:		es:di - name
		cx:dx - optr to send notifications to
		al - open flags

RETURN:		if carry set, 
			ax = DataStoreError
		else
			ax = datastore token

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	See MDDataStoreOpenWithFileHandle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreOpen	proc	far
	uses	bx
	.enter
	
	mov	bx, 0				;bx - null handle
	call	MDDataStoreOpenWithFileHandle
	
	.leave
	ret
DataStoreOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDDataStoreOpenWithFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a DataStore session. Adds the DSSessionElement to
		the Session array as well as a DSElement to the 
		DataStore array if the DataStore
                file is being opened for the first time.

CALLED BY:	GLOBAL

PASS:		es:di - name
		cx:dx - optr to send notifications to
		^hbx - DataStore file
		al - open flag, ( DSOF_EXCLUSIVE, clear for sharable)
RETURN:		if carry set, 
			ax = DataStoreError
		else
			ax = datastore token

DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

        10) EC Check if the object optr for notification is a valid optr.
	15) Lock down the Manager Memory Block
	20) Use NameArrayFind to check if the DataStore is already
	    opened, if so get its DataStore DSElement data.
	30) Use DFFileOpen to verify the DataStore name if the
	    DataStore is not already open.
	35) Add a DSElement to the DSArray and keep track of its
	    token for the Session array. Note that the DSElement array is
	    a NameArray, which is an ElementArray, and that the
	    reference count needs to be incremented. Therefore, even if the
	    DataStore file is already opened, NameArrayAdd is still called.
	    We pass the exact same data so that only the reference count
	    gets updated.
	70) Use ChunkArrayAppend to add a new DSSessionElement
	50) Generate a new DSSE_session for session. 
	60) Use GeodeGetProcessHandle to get the Geode Handle
	80) Set all the values in DSSessionElement, setting the
	    DSSE_recordID to EMPTY_BUFFER_ID and DSSE_buffer to NULL.
	100) Unlock the Manager Memory Block
	110) Return the token or an error.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDDataStoreOpenWithFileHandle 	proc	far
	dsElement	local	DSElementData
	sessionToken	local	word
	openFlags	local	byte
	uses	cx, dx, si, di, ds
	.enter
	mov	ss:[openFlags], al
	clr	ss:[dsElement].DSED_flags

EC<	push	bx							>
EC<	movdw	bxsi, cxdx						>
EC<     call	ECCheckOD						>
EC<	pop	bx							>
	push	cx, dx
	call	MSLockMngrBlockP
	mov	si, ds:[MLBH_dsElementArray]
EC<	call	ECCheckChunkArray					>

	;Check if the name is already in the open DSArray, if it is
	;get the data out so that when it is added, only the reference
 	;count gets updated.

	mov	dx, ss
	lea	ax, ss:[dsElement]	;dx:ax - buffer for return data
	clr	cx			;null terminated es:di
	call	NameArrayFind         	;carry set if name found
	jnc	notInArray
	;
	;name exists in DataStore array
	;fail open exclusive
	;
	test	ss:[openFlags], mask DSOF_EXCLUSIVE
	mov	ax, DSE_ACCESS_DENIED
	LONG	jnz	error

	;
	; open sharable, check if the file was opened with exclusive access
	; fail if this is the case
	;

	test	ss:[dsElement].DSED_flags, mask DSEF_OPENED_EXCLUSIVE
	LONG	jnz	error			; ax - DSE_ACCESS_EXCLUSIVE
	clr	ax			; open sharable
	jmp	addDSElement	      	


notInArray:
	tst	bx			;was a new file handle passed in?
	jnz	addData			;yes, then no need to open file again

	;Verify the name is okay by trying to open the file.
	call	DFFileOpen      	;bx - DataStore file handle
	LONG	jc	error	  	;return the DSFileOpen error
		
addData:
	;Add the new data to the new DSElementData structure

EC<	call	ECCheckFileHandle					>
	mov	ss:[dsElement].DSED_fileHandle, bx

	;Set the DSElement flags accordingly
	test	ss:[openFlags], mask DSOF_EXCLUSIVE
	jz	addDSElement
	or	{byte} ss:[dsElement].DSED_flags, mask DSEF_OPENED_EXCLUSIVE

addDSElement:

	;Either increment the reference count for this datastore or
 	;add the newly opened datastore to the name array

	clr	cx				;name is null-terminated
	lea	ax, ss:[dsElement]			;dx:ax - DSElement
	clr	bx		      		;no flags
	call 	NameArrayAdd          		;ax - DataStore token

	;Before adding a new session element, make sure this geode
	;does not already have a session for this datastore.

	call 	GeodeGetProcessHandle 	
	mov	cx, bx 				;Pass: cx - client, ax - token
	mov	si, ds:[MLBH_sessionArray]
	mov	bx, SEGMENT_CS
	mov	di, offset MAGetSessionEntryByFileTokenCallback
	call	ChunkArrayEnum
	LONG	jc	duplicateSession

	push	ax				;Save DSElement token

	;Generate a new session token

	push	cx
	mov	cx, ds:[MLBH_tokenCount]	;cx - session token
	mov	ss:[sessionToken], cx
	pop	cx
	inc	ds:[MLBH_tokenCount]
EC <	tst	ds:[MLBH_tokenCount]					>
EC <	WARNING_Z INVALID_TOKEN_VALUE_GENERATED				>

	;Add the DSSessionElement to the Session array

	call	ChunkArrayAppend      		;ds:di - new DSSessionElement
EC <	ERROR_C ERROR_ADDING_TO_CHUNK_ARRAY				>
	pop	ax
	mov	ds:[di].DSSE_dsToken, ax	;DSElement token

	mov	ax, ss:[sessionToken]
	mov	ds:[di].DSSE_session, ax

	mov	ds:[di].DSSE_client, cx

	movdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID		

	mov	ds:[di].DSSE_buffer, 0  	;buffer == NULL

	mov	ds:[di].DSSE_dsFlags, 0		;no flags 

	popdw	cxdx
	movdw	ds:[di].DSSE_notifObj, cxdx
	call	MSUnlockMngrBlockV

	; Add the notification object to the gcnlist

	jcxz	noNotify
EC <	push	si						>
EC <	movdw	bxsi, cxdx					>
EC <	call	ECCheckOD					>
EC <	pop	si						>
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_NOTIFY_DATASTORE_CHANGE
	call	GCNListAdd
noNotify:
		
	clc					;return no error
	mov	ax, ss:[sessionToken]		;return the session token

done:					
	.leave
	ret

error:		
	pop	cx, dx
	call	MSUnlockMngrBlockV
	stc					;return error
	jmp	done

duplicateSession:
	;We must remove the extra reference to the datastore.
	; 	ax = datastore token

	clr	bx				;no callback
	mov	si, ds:[MLBH_dsElementArray]
	call	ElementArrayRemoveReference
EC <	ERROR_C -1				;element should NOT be removed>
	mov	ax, DSE_DATASTORE_ALREADY_OPEN
	jmp	error

MDDataStoreOpenWithFileHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes a DataStore session by deleting the Session element
		from the Session array. Will also close the DataStore file
		if no other Session is using of the DataStore. It is an 
		error to close a DataStore with a locked record.

CALLED BY:	GLOBAL	
PASS:		ax - DataStore token
RETURN:		ax - DataStoreError
DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the Manager LMem block, moving it
		  on the heap and invalidating stored segment pointers and
		  current register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	10) call MDDataStoreCloseWithFlags with all cleared DSCloseFlags, 
	    which specifies to return an error if the the DataStore
	    is attempting to be closed with a locked record buffer.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreClose	proc	far
	uses	bx, ds
	.enter

	call	MSLockMngrBlockP
	clr 	bx			;clear DSCloseFlags
	call	MDDataStoreCloseWithFlags
	call	MSUnlockMngrBlockV

	.leave
	ret
DataStoreClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDDataStoreCloseWithFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS	Closes the DataStore passed in ax. 
		The flag passed in determines whether to ignore
		modified record(s) in the record buffer. 
	
CALLED BY:	(INTERNAL) DataStoreClose
		(INTERNAL) MIDataStoreCloseIfHandlesMatchCallBack
	
PASS:		ax - DataStore token
		bx - DSCloseFlags
		ds - locked manager block
	
RETURN:		ax - DataStoreError
DESTROYED:	bx
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the Manager LMem block, moving it
		  on the heap and invalidating stored segment pointers and
		  current register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	10)  EC verify that ds passed in is correct.
	20)  Enumerate through the entire session table looking for 
	     sessions opened by this Geode and close them using
	     MDCloseSessionCallback
	30)  If the MDCloseSessionCallback doesn't return carry, than
	     that means the datastore token passed was bad and return
	     the error.
	40)  Return any error return by MDCloseSeesionCallback.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDDataStoreCloseWithFlags	proc	far
	uses	cx,dx,si,di,ds
	.enter

EC <	mov	si, ds						>
EC <	MngrDerefDS						>
EC <	mov	dx, ds						>
EC <	cmp	si, dx						>
EC <	ERROR_NE -1						>

	mov	si, ds:[MLBH_sessionArray]
EC<	call	ECCheckChunkArray					>

	mov	ss:[TPD_error], 0	;assume no error

	;Call ChunkArrayEnum to find the session element for the 
        ;dsToken and geode.	
	
	mov	dx, bx			;pass DSCloseFlags in dx
	call	GeodeGetProcessHandle
	mov	cx, bx			;pass client handle in cx
	mov	bx, SEGMENT_CS
	mov	di, offset MDCloseSessionCallback
	call	ChunkArrayEnum		;carry clear if token not found
	jnc	badToken
		
	mov	ax, 0
	xchg	ax, ss:[TPD_error]      ;CallBack stores return value here
	tst_clc	ax
	jz	exit
	stc

exit:
	.leave
	ret

badToken:
	mov 	ax, DSE_INVALID_TOKEN
	stc
	jmp 	exit

MDDataStoreCloseWithFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDCloseSessionCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the DataStore passed in ax. 
		The flag passed in determines whether to ignore
		modified record(s) in the record buffer.

CALLED BY:	MDDataStoreCloseWithFlags
PASS:		*ds:si - array
		ds:di - DSSessionElement
		ax - session token
		dx - session token DataStoreCloseFlags
		^hcx - GeodeHandle of exiting client
RETURN:		carry set on error, stops the enumeration
		error code is returned in TPD_error
			 - DSE_CLOSE_WITH_LOCKED_RECORD
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	20) If this is not the same session as the passed datastore
	    token, continue.
	30) If this session was not started by the passed client, continue.
	35) If the flag to discard a locked record is passed, then discard 
            record buffer memory if one exists.
	36) If the flag to not discard a locked record is passed, then check
    	    for locked record buffer and return and error if there is.
	38) Delete the Session element.
	40) Use ElementArrayRemoveReferenece to delete either the reference 
	    or the element in the DSElement array. Use a callback to close 
	    the file before the element is deleted.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDCloseSessionCallback		proc	far
	.enter

	;Is this the session entry? If not continue enumerationg.

	cmp	ax, ds:[di].DSSE_session
	clc
	jne	exit

	; Does this session belong to passed client? If not, 
	; shame on the caller, continue enumerating.

	cmp	cx, ds:[di].DSSE_client
	clc		
	jne	exit

	;Check for locked buffer and act accordingly depending on the
	;DSCloseFlags passed in.

	cmpdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID
	je	emptyBuffer             

	cmp	dx, mask DSCF_DISCARD_LOCKED_RECORDS
	jne	bufferError		;tried to close with locked records
	mov	bx, ds:[di].DSSE_buffer ;trash DSCloseFlags 
EC<	call	ECCheckLMemHandle					>
	call	MemFree			;discard the locked record
	mov	ds:[di].DSSE_buffer, 0
	movdw	ds:[di].DSSE_recordID, EMPTY_BUFFER_ID

emptyBuffer:

	;Delete the ElementArray reference or the DSElement itself. 
	;If the DSElement is deleted, use a callback to close the
 	;DataStore file and return any error from the DFFileClose
	;call.

	push	si, di
	mov	ax, ds:[di].DSSE_dsToken
	mov	si, ds:[MLBH_dsElementArray]	;*ds:si <= DSElement array
	mov	bx, SEGMENT_CS
	mov	di, offset MDDataStoreCloseFileCallBack
	call	ElementArrayRemoveReference
	pop	si, di

	; Remove the notification object from the gcnlist

	movdw	cxdx, ds:[di].DSSE_notifObj
	jcxz	noNotify
EC <	push	si						>
EC <	movdw	bxsi, cxdx					>
EC <	call	ECCheckOD					>
EC <	pop	si						>
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_NOTIFY_DATASTORE_CHANGE
	call	GCNListRemove

noNotify:
	;Delete this session element. We can do this in the middle
	;of the enumeration without skipping elements.
	
	mov	ax, ds:[di].DSSE_session
	call	ChunkArrayDelete
	stc				;stop callback, session found
	
exit:
	.leave
	ret

bufferError:
	mov 	ss:[TPD_error], DSE_CLOSE_WITH_LOCKED_RECORD
EC<	WARNING	DATASTORE_LOAD_OR_CLOSE_CALLED_WITHOUT_EMPTY_BUFFER	>
	stc				;stop callback, session found
	jmp	exit

MDCloseSessionCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDDataStoreCloseFileCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when ElementArrayRemoveReference actually
		deletes the element from the DataStore array.

CALLED BY:	(INTERNAL) MDDataStoreCloseWithFlags
PASS:		ds:di - segment with DataStore array

RETURN:		carry set if error
		DataStoreError stored in TDP_error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	20) Call DFFileClose on the FileHandle for the pointer.
	30) EC warning if unable to close the file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDDataStoreCloseFileCallBack	proc	far
	uses	ax,bx
	.enter

	;Close the file

	mov	bx, ds:[di].DSE_data.DSED_fileHandle
EC<	call	ECCheckFileHandle					> 
	call	DFFileClose
EC<	WARNING_C UNABLE_TO_CLOSE_DATASTORE_FILE			>
	xchg	ss:[TPD_error], ax	;ax destroyed, save error in TPD

	.leave
	ret
MDDataStoreCloseFileCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a DataStore file and opens a new Session for the
		file. 

CALLED BY:	(EXTERNAL) GLOBAL
PASS:		ds:si - DataStoreCreateParams

RETURN:		if carry set,
			ax = DataStoreError
		else 	ax = datastore token

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	10) Call MDVerifyDataStoreParams to verify parameters.
	20) Call DFFileCreate to actually do the create work :)
	60) Call DataStoreOpenWithFileHandle which checks the 
	    notification object.
	70) Return any error of DataStoreOpenWithFileHandle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataStoreCreate	proc	far
	uses	bx, cx, dx, es,di
	.enter

	call	MDVerifyDataStoreCreateParams
	jc	error

	;Parameters are okay, create and open the DataStore

	call	DFFileCreate		;bx - DataStore fileHandle
	jc	error
EC<	call 	ECCheckFileHandle 					>
	les	di, ds:[si].DSCP_name	
	mov	al, ds:[si].DSCP_openFlags
	movdw	cxdx, ds:[si].DSCP_notifObject
	call	MDDataStoreOpenWithFileHandle
	jc	error
		
	lds	dx, ds:[si].DSCP_name
	mov	bx, DSCT_DATASTORE_CHANGED
	call	DFSendDataStoreNotificationWithName
		
error:
	.leave
	ret

DataStoreCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDVerifyDataStoreCreateParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies DataStoreCreateParams are valid

CALLED BY:	INTERNAL
PASS:		*ds:si - DataStoreCreateParams
RETURN:		carry set if error
			ax - DataStoreError
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	20) Check the DataStore Flags for valid flags.
	25) Verify the name is not too long or a null pointer.
	30) Check and make sure the KeyList pointer is not null.
	40) Loop for each key filed and check FeildDescriptor type, 
	    category, and flags are in valid range. Make sure name 
	    is not null.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/24/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDVerifyDataStoreCreateParams		proc	near
	uses	cx, di, es, si, ds
	.enter

	;Verify the object being passed in.

EC<	push	si							>
EC<	movdw	bxsi, ds:[si].DSCP_notifObject				>
EC<     call	ECCheckOD						>
EC<	pop	si							>

	;Check the DataStoreFlags

	mov	ax, ds:[si].DSCP_flags
	call	MDVerifyDataStoreFlags
	jc	badFlags

	;Check open flags
	mov	al, ds:[si].DSCP_openFlags
	BitClr	al, DSOF_EXCLUSIVE
	tst_clc	al
	jnz	badFlags
	
	;Check the DataStore name

	tst	ds:[si].DSCP_name.high		;name pointer null?
	jz	badName
	les	di, ds:[si].DSCP_name	
	call	LocalStringLength
	jcxz	badName				;first character null?
;	cmp	cx, FILE_LONGNAME_LENGTH	;name too long?
;allow pathnames (should really check lengths of components) -- brianc 3/25/97
	cmp	cx, PATH_LENGTH
	ja	badName				
		
	;Check each key FieldDescriptor for valid flags, etc., etc.

	mov	cx, ds:[si].DSCP_keyCount
	clc
	jcxz	exit

	lds	si, ds:[si].DSCP_keyList

loop1:
	;Check the Field Name
	
	tst	ds:[si].FD_name.high		;name pointer null?
	jz	badKeyList
	les	di, ds:[si].FD_name	

	mov	ax, cx
	call	LocalStringLength
	jcxz	badKeyList			;first character null?
	cmp	cx, MAX_FIELD_NAME_LENGTH	;name too long?
	ja	badKeyList			
	mov	cx, ax
	call	MDDuplicateNameCheck		;duplicate name in list?
	jc	dupFieldName	

	;Check Field Type, Category, and Flags

	mov	al, ds:[si].FD_data.FD_type
	call	DSIsFieldTypeValid		;Check Field Type
	jc	badKeyList
	mov	al, ds:[si].FD_data.FD_category
	call	DSIsFieldCategoryValid  	;Check Field Category
	jc	badKeyList
EC <	mov	al, ds:[si].FD_data.FD_flags			>
EC <	call	DSIsAddFieldFlagValid		;Check Field Flags>
EC <	ERROR_C INVALID_FIELD_FLAGS				>
;;	jnz	badKeyList		
	add	si, size FieldDescriptor	;keyList++
	loop	loop1

exit:
	.leave
	ret

badFlags:
	stc
	mov	ax, DSE_INVALID_FLAGS
	jmp	exit

badName:
	stc
	mov	ax, DSE_INVALID_NAME
	jmp	exit

badKeyList:
	stc
	mov	ax, DSE_INVALID_KEY_LIST
	jmp	exit

dupFieldName:
	stc
	mov	ax, DSE_DUPLICATE_FIELD_NAME
	jmp	exit

MDVerifyDataStoreCreateParams		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDVerifyDataStoreFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the value passed only has bits corresponding to
		DataStoreFlags.

CALLED BY:	(INTERNAL) DataStoreCreate
PASS:		ax - DataStoreFlags
RETURN:		carry set if invalid 

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDVerifyDataStoreFlags		proc	near
	uses ax
	.enter

	and	ax, not mask DataStoreFlags
	tst_clc	ax			;clear carry - assume error
	jnz	error
	stc				;carry set if not error
error:
	cmc
	.leave
	ret
MDVerifyDataStoreFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MDDuplicateNameCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a field descriptor name in the primary key
		list has a duplicate name anywhere in the list AFTER this
		one. Thus, this does not do a complete check on the
		list. It assumes that this procedure was called on all
		all prior names in the list to check previous names.
		
CALLED BY:	(INTERNAL) MMVerifyDataStoreCreateParams
PASS:		cx - number elements in the list
		ds:si - field descriptor being checked
		es:di - name of field descriptor in ds:si

RETURN:		carry set if duplicate found

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	05)	save element name being checked in local var
	10) 	advance ds:si to next element
	20)	save element being checked in ds:si to bxax 
	30)	get next element name into es:di
	40) 	LocalStringCmp 	
	45)	return carry if duplicate found
	50)     restore element just checked into ds:si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	11/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MDDuplicateNameCheck	proc	near
	srcName		local	dword	push	es,di
	uses	ax,bx,cx,dx,ds,si,di,es
	.enter

	dec	cx			; don't include the current fd
	clc
	jcxz	exit			; at the end of the list, exit

loop1:
	add	si, size FieldDescriptor; keyList++
	movdw	bxax, dssi		; bxax 	- ptr to current FeildDesc.
	tst	ds:[si].FD_name.high	; name pointer null?
	clc	
	jz	continue		; ignore a null string
	les	di, ds:[si].FD_name	; es:di - target string to cmp
	movdw	dssi, srcName		; ds:si - source string to cmp	
	mov	dx, cx			; dx - number of elements left
	clr	cx			; testing null terminated string
	call	LocalCmpStrings
	stc				; return found if equal strings
	jz	exit			; strings are equal, duplicate found
	mov	cx, dx			; cx - number of elements left
	movdw	dssi, bxax		; ds:si - ptr to element just checked

continue:

	loop	loop1
	clc				; no duplicates, return none found

exit:
	.leave
	ret
MDDuplicateNameCheck	endp

ManagerMainCode ends
