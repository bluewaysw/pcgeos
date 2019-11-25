## 3.4 Routines H-L
----------
#### HAL_COUNT()
	word	HAL_COUNT(
			dword	val);
This macro is provided for use with **HugeArrayLock()**. It extracts the lower 
word of the **HugeArrayLock()** return value. This is the number of elements 
in the Huge Array block after the locked one (counting that locked one).

----------
#### HAL_PREV
	word	HAL_PREV(
			dword	val);
This macro is provided for use with **HugeArrayLock()**. It extracts the upper 
word of the **HugeArrayLock()** return value. This is the number of elements 
in the Huge Array block before the locked one (counting that locked one).

----------
#### HandleModifyOwner()
	void	HandleModifyOwner(
			MemHandle		mh,			/* Handle of block to modify */
			GeodeHandle		owner);		/* Handle of block's new owner */
This routine changes the owner of the indicated global memory block. Note 
that this routine can be called only by a thread belonging to the block's 
original owner; that is, you can only use this routine to transfer ownership of 
a block *from* yourself *to* some other geode.

**Include:** heap.def

**Never Use Situations:** Never use this unless the block already belongs to you and you are giving up 
ownership.

**See Also:** MemGetInfo(), MemModifyFlags(), MemModifyOtherInfo()

----------
#### HandleP()
	void	HandleP(
			MemHandle		mh);		/* Handle of block to grab */
If several different threads will be accessing the same global memory block, 
they need to make sure their activities will not conflict. The way they do that 
is to use synchronization routines to get control of a block. **HandleP()** is part 
of one set of synchronization routines.

If the threads are using this family of routines, then whenever a thread needs 
access to the block in question, it can call **HandleP()**. This routine checks 
whether any thread has grabbed the block with **HandleP()** (or 
**MemPLock()**). If no thread has the block, it grabs the block for the calling 
thread and returns (it does not lock the block on the global heap). If a thread 
has the block, **HandleP()** puts the thread on a priority queue and sleeps. 
When the block is free for it to take, it awakens, grabs the block, and 
returns.When the thread is done with the block, it should release it with 
**MemUnlockV()** or **HandleV()**.

**Include:** heap.h

**Tips and Tricks:** If you will be locking the block after you grab it, use the routine 
**MemPLock()** (which calls **HandleP()** and then locks the block with 
**MemLock()**). You can find out if the block is being accessed by looking at the 
*HM_otherInfo* word (with **MemGetInfo()**). If *HM_otherInfo* equals one, the 
block is not grabbed; if it equals zero, it is grabbed, but no threads are 
queued; otherwise, it equals the handle of the first thread queued.

**Be Sure To:** Make sure that all threads accessing the block use **HandleP()** and/or 
**MemPLock()** to access the block. The routines use the *HM_otherInfo* field of 
the handle table entry; do not alter this field. Release the block with 
**HandleV()** or **MemUnlockV()** when you are done with it.

**Warnings:** If a thread calls **HandleP()** when it already has control of the block, it will 
deadlock; **HandleP()** will put the thread to sleep until the thread releases 
the block, but the thread will not be able to release the block because it's 
sleeping. **MemThreadGrab()** avoids this conflict. If you try to grab a 
non-sharable block owned by another thread, **HandleP()** will fatal-error.

**See Also:** HandleV(), MemPLock(), MemUnlockV()

----------
#### HandleToOptr()
	optr	HandleToOptr(
			Handle 	han;
This macro casts any handle to an optr, leaving the chunk handle portion of 
the resultant optr to be zero.

**See Also:** ConstructOptr(), OptrToHandle(), OptrToChunk()

----------
#### HandleV()
	void	HandleV(
			MemHandle		mh);		/* Handle of block to grab */
**HandleV()** is part of a set of synchronization routines. If several different 
threads will be accessing the same global memory block, they need to make 
sure their activities will not conflict. The way they do that is to use 
synchronization routines to get control of a block. **HandleV()** is part of one 
set of synchronization routines.

If a block is being accessed via these synchronization routines, then a thread 
will not access a block until it has "grabbed" it with **HandleP()** or 
**MemPLock()**. When a thread is done with the block, it can release it for use 
by the other threads by calling **HandleV()**. Note that **HandleV()** does not 
unlock the block; it just changes the block's semaphore so other threads can 
grab it.

**Include:** heap.h

**Tips and Tricks:** If you need to unlock the thread just before releasing it, use the routine 
**MemUnlockV()**, which first unlocks the thread, and then calls **HandleV()** 
to release it. You can find out if the block is being accessed by looking at the 
*HM_otherInfo* word (with **MemGetInfo()**). If *HM_otherInfo* equals one, the 
block is not grabbed; if it equals zero, it is grabbed, but no threads are 
queued; otherwise, it equals the handle of the first thread queued.

**Be Sure To:** Make sure that all threads accessing the block use **HandleP()** or 
**MemPLock()** to access the thread. The routines use the *HM_otherInfo* field 
of the handle table entry; do not alter this field.

**Warnings:** Do not use this on a block unless you have grabbed it. The routine does not 
check to see that you have grabbed the thread; it just clears the semaphore 
and returns.

**See Also:** HandleP(), MemPLock(), MemUnlockV()

----------
#### HugeArrayAppend()
	void	HugeArrayAppend(
			VMFileHandle		file,
			VMBlockhandle		vmBlock,	/* Handle of directory block */
			word				numElem,	/* # of elements to add to end of 
											 * array */
			const void *		initData);	/* Copy into each new element */
This routine appends one or more elements to a Huge Array. The data 
pointed to by *initData* will be copied into each new element. If *initData* is a 
null pointer, the elements will be uninitialized.

If the Huge Array contains variable sized elements, this routine will append 
a single element; this element will be *numElem* bytes long.

**Include:** hugearr.h

----------
#### HugeArrayCompressBlocks()
	void	HugeArrayCompressBlocks(
			VMFileHandle	vmFile,			/* File containing Huge Array */
			VMBlockHandle	vmBlock);		/* handle of directory block */
This routine compacts a Huge Array, resizing every block to be just as large 
as necessary to accommodate its elements. It does not change any of the data 
in the Huge Array.

**Include:** hugearr.h

----------
#### HugeArrayContract()
	word	HugeArrayContract(
			void **		elemPtr,		/* **elemPtr is first element to
 										 * delete */
			word		numElem);		/* # of elements to delete */
Delete a number of elements starting at an address in a Huge Array. The 
routine will fix up the pointer so it points to the first element after the deleted 
elements. The routine automatically locks and unlocks Huge Array blocks as 
necessary.

**Include:** hugearr.h

----------
#### HugeArrayCreate()
	VMBlockhandle 	HugeArrayCreate(
			VMFileHandle	vmFile,			/* Create in this VM file */
			word			elemSize,		/* Pass zero for variable-size
											 * elements */
			word			headerSize);	/* Pass zero for default header */
This routine creates and initializes a Huge Array in the specified file. It 
returns the handle of the Huge Array's directory block.

**Include:** hugearr.h

----------
#### HugeArrayDelete()
	void	HugeArrayDelete(
			VMFileHandle	vmFile,
			VMBlockHandle	vmBlock,	/* handle of directory block */
			word			numElem,	/* # of elements to delete */
			dword			elemNum);	/* Index of first element to delete */
This routine deletes one or more elements from a Huge Array. It contracts 
and frees blocks as necessary.

**Include:** hugearr.h

----------
#### HugeArrayDirty()
	void	HugeArrayDirty(
			const void *	elemPtr);		/* Element in dirty block */
This routine marks a block in a Huge Array as dirty. The routine is passed a 
pointer to anywhere in a dirty element; that element's block will be dirtied.

**Include:** hugearr.h

**Warnings:** Be sure to call this routine before you unlock the element; otherwise, the 
block may be discarded before you can dirty it.

----------
#### HugeArrayDestroy()
	void	HugeArrayDestroy(
			VMFileHandle	vmFile,
			VMBlockHandle	vmBlock);		/* Handle of directory block */
This routine destroys a HugeArray by freeing all of its blocks.

**Include:** hugearr.h

----------
#### HugeArrayEnum()
	Boolean	HugeArrayEnum(
			VMFileHandle	vmFile,			/* subject to override */
			VMBlockHandle	vmBlock,		/* Handle of the Huge Array's directory
											 * block */
			Boolean _pascal (*callback) (	/* return true to stop */
					void *		element,	/* element to examine */
					void * 		enumData),
			dword			startElement,	/* first element to examine */
			dword			count,			/* examine this many elements */
			void *			enumData;		/* this pointer is passed to callback
											 * routine */

This routine lets you examine a sequence of elements in a Huge Array. 
**HugeArrayEnum()** is passed six arguments. The first two are a file handle 
and block handle; these specify the Huge Array to be examined. The third is 
a pointer to a Boolean callback routine. The fourth argument is the index of 
the first element to be examined (remember, the first element in the Huge 
Array has an index of zero). The fifth argument is the number of elements to 
examine, or -1 to examine through the last element. The sixth argument is a 
pointer which is passed unchanged to the callback routine; you can use this 
to pass data to the callback routine, or to keep track of a scratch space.

The callback routine, which must be declared _pascal, itself takes two 
arguments. The first is a pointer to an element in the huge array. The 
callback routine will be called once for each element in the specified range; 
each time, the first argument will point to the element being examined. The 
second argument is the pointer that was passed as the final argument to 
**HugeArrayEnum()**. The callback routine can make **HugeArrayEnum()** 
abort by returning *true*; this is useful if you need to search for a specific 
element. Otherwise, the callback routine should return *false*. If the callback 
routine aborts the enumeration, **HugeArrayEnum()** returns *true*; 
otherwise, it returns *false*.

**HugeArrayEnum()** is guaranteed to examine the elements in numerical 
order, beginning with *startElement*. The routine will automatically stop with 
the last element, even if *count* elements have not been enumerated. However, 
the starting element must be the index of an element in the array.

**Include:** hugearr.h

**Warnings:** The callback routine may not allocate, free, or resize any elements in the 
Huge Array. All it should do is examine or change (*without* resizing) a single 
element. 

The starting element must be an element in the array. If you pass a starting 
index which is out-of-bounds, the results are undefined.

----------
#### HugeArrayExpand()
	word	HugeArrayExpand(
			void **			elemPtr,	/* **elemPtr is element at location
										 * where new elements will be
										 * created */
			word			numElem,	/* # of elements to insert */
			const void *	initData);	/* Copy this into each new 
										 * element */
This routine inserts a number of elements at a specified location in a 
HugeArray. The element pointed to will be shifted so it comes after the 
newly-created elements. The pointer will be fixed up to point to the first new 
element. The data pointed to by *initData* will be copied into each new 
element. If *initData* is null, the new elements will be uninitialized.

If the elements are of variable size, this routine will insert a single element; 
this element will be *numElem* bytes long.

**Include:** hugearr.h

----------
#### HugeArrayGetCount()
	dword	HugeArrayGetCount(
			VMFileHandle		vmFile,
			VMBlockHandle		vmBlock);	/* Handle of directory block */
This routine returns the number of elements in a Huge Array.

**Include:** hugearr.h

----------
#### HugeArrayInsert()
	void	HugeArrayInsert(
			VMFileHandle	vmFile,
			VMBlockHandle	vmBlock,	/* Handle of directory block */
			word			numElem,	/* # of elements to insert */
			dword			elemNum,	/* Index of first new element */
			const void *	initData);	/* Copy this into each new element */
This routine inserts one or more elements in the midst of a Huge Array. The 
first new element will have index *elemNum*; thus, the element which 
previously had that index will now come after the new elements. The data 
pointed to by *initData* will be copied into each new element. If *initData* is 
null, the new elements will be uninitialized.

If the elements are of variable size, this routine will insert a single element; 
this element will be *numElem* bytes long.

**Include:** heap.h

----------
#### HugeArrayLock()
	dword	HugeArrayLock(
			VMFileHandle	vmFile,
			VMBlockhandle	vmBlock,		/* Handle of directory block */
			dword			elemNum,		/* Element to lock */
			void **			elemPtr);		/* Pointer to element is written 
											 * here */
This routine locks an element in a Huge Array. It writes the element's 
address to **elemPtr*. The dword returned indicates how many elements come 
before and after the element in that block. The upper word indicates how 
many elements come before the locked one, counting the locked element. The 
lower word indicates how many elements come after the locked element, 
again counting the locked one. You may examine or change all the other 
elements in the block without making further calls to **HugeArrayLock()**.

**Include:** heap.h

**See Also:** HAL_COUNT(), HAL_PREV()

----------
#### HugeArrayNext()
	word	HugeArrayNext(
			void **		elemPtr);
This routine increments a pointer to an element in a HugeArray to point to 
the next element. If the element was the last element in its block, 
**HugeArrayNext()** will unlock its block and lock the next one. The routine 
writes the pointer to **elemPtr*; it returns the number of elements which come 
after the newly-locked one in its block, counting the newly-locked element. If 
this routine is passed a pointer to the last element in a HugeArray, it unlocks 
the element, writes a null pointer to **elemPtr*, and returns zero.

**Include:** heap.h

**Warnings:** This routine may unlock the block containing the passed element. Therefore, 
if you need to mark the block as dirty, do so before making this call.

----------
#### HugeArrayPrev()
	word	HugeArrayPrev(
			void **		elemPtr1,		/* indicates current element */
			void **		elemPtr2);
This routine decrements a pointer to an element in a HugeArray to point to 
the previous element. If the element was the first element in its block, 
**HugeArrayPrev()** will unlock its block and lock the previous one. The 
routine writes the pointer to **elemPtr1*, and writes a pointer to the first 
element in the block in **elemPtr2*. It returns the number of elements which 
come before the newly-locked one in its block, counting the newly-locked 
element. If this routine is passed a pointer to the first element in a 
HugeArray, it unlocks the element, writes a null pointer to **elemPtr*, and 
returns zero.

**Include:** hugearr.h

**Warnings:** This routine may unlock the block containing the passed element. Therefore, 
if you need to mark the block as dirty, do so before making this call.

----------
#### HugeArrayReplace()
	void	HugeArrayReplace(
			VMFileHandle	file,
			VMBlockHandle	vmblock,		/* Handle of directory block */
			word			numElem,		/* # of elements to replace */
			dword			elemNum,		/* First element to replace */
			const void *	initData);		/* Copy this into each element
This routine replaces one or more elements with copies of the passed data. If 
*initData* is null, the elements will be filled with null bytes.

If the elements are of variable size, a single element will be resized; its new 
size will be *enumData* bytes long.

**Include:** hugearr.h

**See Also:** HugeArrayResize()

----------
#### HugeArrayResize()
	void	HugeArrayResize(
			VMFileHandle	vmFile,
			VMBlockHandle	vmBlock,		/* Handle of directory block */
			dword			elemNum,		/* Resize this element */
			word			newSize);		/* New size in bytes */
This routine resizes an element in a Huge Array. The array must contain 
variable-sized elements. If the new size is larger than the old, the extra space 
will be zero-initialized. If it is smaller, the element will be truncated.

**Include:** hugearr.h

----------
#### HugeArrayUnlock()
	void	HugeArrayUnlock(
			void *		elemPtr);
This routine unlocks the block of a HugeArray which contains the passed 
element.

**Include:** hugearr.h

**Warnings:** If you have changed any of the elements in the block, be sure to call 
**HugeArrayDirty()** before you unlock the block; otherwise the block might 
be discarded.

----------
#### IACPConnect()
	IACPConnection IACPConnect(
			GeodeToken 			*list, 
			IACPConnectFlags 	flags, 
			MemHandle 			appLaunchBlock, 
			optr 				client, 
			word 				*numServers);

This routine establishes a connection between a client object (by default the 
calling thread's application object) and one or more servers registered with 
the indicated list.

The *client* argument should be **NullOptr** unless the 
IACPCF_CLIENT_OD_SPECIFIED flag is set in the flags parameter.

**Include:** iacp.goh

----------
#### IACPCreateDefaultLaunchBlock()
	MemHandle IACPCreateDefaultLaunchBlock(
			word 		appMode);
This routine creates a memory block holding an **AppLaunchBlock** 
structure suitable for passing to **IACPConnect()**. The two valid values to 
pass in appMode are MSG_GEN_PROCESS_OPEN_APPLICATION and 
MSG_GEN_PROCESS_OPEN_ENGINE.

**Include:** iacp.goh

----------
#### IACPFinishConnect()
	void	IACPFinishConnect(
			IACPConnection		connection,
			optr				server);
Finishes a connection made to a server which had to change from 
non-interactible to interactible.

**Include:** iacp.goh

----------
#### IACPLostConnection()
	void IACPLostConnection(
			optr 				oself, 
			IACPConnection 		connection);
This routine is called by IACP server objects to handle when a client closes a 
connection.

**Include:** iacp.goh

----------
#### IACPProcessMessage()
	void IACPProcessMessage(
			optr 				oself, 
			EventHandle 		msgToSend, 
			TravelOption 		topt, 
			EventHandle 		completionMsg);
This is a utility routine to dispatch an encapsulated message handed to an 
object by an IACP connection.

**Include:** iacp.goh

----------
#### IACPRegisterDocument()
	void IACPRegisterDocument(
			optr 	server,
			word 	disk,
			dword 	fileID);
This routine registers an open document and the server object for it.

This routine is to be used only by servers, not by clients, and should only be 
used by the creator of the document.  There is no provision for using IACP to 
connect to a server that is not the creator of the document in question.

**Include:** iacp.goh

----------
#### IACPRegisterServer()
	void 	IACPRegisterServer(
			GeodeToken 			*list, 
			optr 				server,
			IACPServerMode 		mode,
			IACPServerFlags 	flags);
This routine registers an object as a server for the IACP server list specified 
by the passed token.

**Include:** iacp.goh

----------
#### IACPSendMessage()
	word IACPSendMessage(
			IACPConnection 		connection, 
			EventHandle 		msgToSend, 
			TravelOption 		topt, 
			EventHandle 		completionMsg, 
			IACPSide 			side);
This routine sends a recorded message to all the  objects on the other side of 
an IACP connection.

**Include:** iacp.goh

----------
#### IACPSendMessageToServer()
	word IACPSendMessageToServer(
			IACPConnection 		connection, 
			EventHandle 		msgToSend, 
			TravelOption 		topt, 
			EventHandle 		completionMsg, 
			word 				serverNum);
This routine sends a message to a specific server on the other side of an IACP 
connection.

**Include:** iacp.goh

----------
#### IACPShutdown()
	void IACPShutdown(
			IACPConnection 		connection, 
			optr 				serverOD);
This routine removes a server or client from an IACP connection.

**Include:** iacp.goh

----------
#### IACPShutdownAll()
	void IACPShutdownAll(
			optr	obj);
This calls **IACPShutdown()** for all connections to which the passed object 
is a party. It's primarily used by **GenApplicationClass** when the 
application is exiting.

**Include:** iacp.goh

----------
#### IACPUnregisterDocument()
	void IACPUnregisterDocument(
			optr 	server,
			word 	disk,
			dword 	fileID);
This routine unregisters an open document and the server object for it.

**Include:** iacp.goh

----------
#### IACPUnregisterServer()
	void IACPUnregisterServer(
			GeodeToken 		*token, 
			optr 		object);
This removes the specified server object from the indicated IACP server list. 

**Include:** iacp.goh

----------
#### ImpexCreateTempFile()
	TransError ImpexCreateTempFile(
			char *			buffer,
			word			fileType,
			FileHandle *	file,
			MemHandle *		errorString);
This routine creates and opens a unique temporary file to be used by 
translation libraries for file importing and exporting. The routine is called 
only by translation libraries.

The routine is passed the following arguments:

*buffer* - The file name will be written to the buffer pointed to by this 
argument. The buffer should be at least 
FILE_LONGNAME_BUFFER_SIZE bytes long.

*fileType* - This specifies what kind of temporary file should be created. If 
IMPEX_TEMP_VM_FILE is passed, a GEOS VM file will be 
created. If IMPEX_TEMP_NATIVE_FILE is passed, a temporary 
file in the native format will be created.

*file* - This is a pointer to a FileHandle variable. The temporary file's 
handle will be written to **file*.

*errString* - If **ImpexCreateTempFile** fails with error condition 
TE_CUSTOM it will allocate a block containing an error string. 
It will write the block's handle to **errString*. It is the caller's 
responsibility to free this block when it's done with it.

If **ImpexCreateTempFile** is successful, it returns TE_NO_ERROR (which 
equals zero). If it fails, it returns a member of the **TransferErrors** 
enumerated type (usually TE_METAFILE_CREATION_ERROR). When you're 
done with the temporary file, call **FileDeleteTempFile()**.

**Include:** impex.goh

**Warnings:** If you close this file, the system may delete it at any time. Ordinarily you 
should close it with **ImpexDeleteTempFile()**, which deletes the file 
immediately.

If the routine does not fail with condition TE_CUSTOM, **errString* may 
contain a random value. Do not use **errString* if the routine did not return 
TE_CUSTOM.

----------
#### ImpexDeleteTempFile()
	TransError ImpexDeleteTempFile(
			const char *		buffer,
			FileHandle			tempFile,
			word				fileType);
This routine closes, then deletes, a temporary file which was created by 
**ImpexCreateTempFile()**. It is passed the following arguments:

*buffer* - This is a pointer to a character buffer containing the name of 
the temporary file. You can just pass the address of the buffer 
which was filled by **ImpexCreateTempFile()**.

*tempFile* - This is the handle of the temporary file.

*fileType* - This specifies what type of file is being deleted. If the 
temporary file is a GEOS VM file, this will be 
IMPEX_TEMP_VM_FILE. If it is a native-format file, it will be 
IMPEX_TEMP_NATIVE_FILE.

*errString* - If **ImpexDeleteTempFile** fails with error condition 
TE_CUSTOM it will allocate a block containing an error string. 
It will write the block's handle to **errString*. It is the caller's 
responsibility to free this block when it's done with it.

**ImpexDeleteTempFile()** closes the specified file, then deletes it. If it is 
successful, it returns TE_NO_ERROR (i.e. zero); otherwise, it returns an 
appropriate member of the **TransError** enumerated type.

**Include:** impex.goh

**Warnings:** If the routine does not fail with condition TE_CUSTOM, **errString* may 
contain a random value. Do not use **errString* if the routine did not return 
TE_CUSTOM.

----------
#### ImpexExportToMetafile()
	TransError 	ImpexExportToMetafile(
			Handle			xlatLib,
			VMFileHandle	xferFile,
			FileHandle		metafile,
			dword			xferFormat,
			word			arg1,
			word			arg2,
			MemHandle *		errString);
This routine is used by translation libraries. The routine calls an 
intermediate translation library to finish translating a given file into the 
GEOS Metafile format.

**Include:** impex.goh

**Warnings:** If the routine does not fail with condition TE_CUSTOM, **errString* may 
contain a random value. Do not use **errString* if the routine did not return 
TE_CUSTOM.

----------
#### ImpexImportExportCompleted()
	void 	ImpexImportExportCompleted(
			ImpexTranslationParams *		itParams);
The application should send this message when it is finished importing or 
exporting data. The routine will send an appropriate acknowledgment 
message to the ImportControl or ExportControl object, depending on the 
settings of *ITP_impexOD* and *ITP_returnMsg*.

If the application has just finished an import, it should not have changed the 
**ImpexTranslationParams** structure. If it had just finished preparing data 
for export, it should have set the *ITP_transferVMChain* field to contain the 
handle of the head of the VM chain.

**Warnings:** This routine, in essence, informs the ImportControl or ExportControl 
object that the application is finished with the transfer file. The 
ImportControl will respond by destroying the transfer file; the 
ExportControl will call the appropriate translation library to produce 
an output file. Therefore, an application should not call this routine 
until it is absolutely finished with the transfer file.

----------
#### ImpexImportFromMetafile()
	TransError 	ImpexExportToMetafile(
			Handle			xlatLib,
			VMFileHandle	xferFile,
			FileHandle		metafile,
			dword *			xferFormat,
			word			arg1,
			word			arg2,
			MemHandle *		errString);
This routine is used by translation libraries. The routine calls an 
intermediate translation library to translate a given file from the GEOS 
Metafile format to an intermediate format.

**Include:** impex.goh

**Warnings:** If the routine does not fail with condition TE_CUSTOM, **errString* may 
contain a random value. Do not use **errString* if the routine did not return 
TE_CUSTOM.

----------
#### InitFileCommit()
	void	InitFileCommit(void);
This routine commits any changes to the GEOS.INI file, removing and 
replacing its stored backup. It ensures that no other threads are working on 
the file during the commit operation.

**Include:** initfile.h

----------
#### InitFileDeleteCategory()
	void	InitFileDeleteCategory(
			const char 		*category);
This routine deletes the specified category, along with all its entries, from the 
GEOS.INI file. Pass it the following:

*category* - A pointer to the null-terminated string representing the 
category to be deleted. This string ignores white space and is 
case-insensitive.

**Include:** initfile.h

----------
#### InitFileDeleteEntry()
	void	InitFileDeleteEntry(
			const char 		*category,
			const char 		*key);
This routine deletes an entry in the GEOS.INI file. Pass it the following:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be deleted.

**Include:** initfile.h

----------
#### InitFileDeleteStringSection()
	void	InitFileDeleteStringSection(
			const char *		category,
			const char *		key,
			word				stringNum);
This routine deletes the specified string section from the given blob in the 
GEOS.INI file. Pass it the following:

category - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

key - A pointer to the null-terminated string representing the key to 
be edited.

stringNum - The zero-based string section number.

**Include:** initfile.h

----------
#### InitFileEnumStringSection()
	Boolean	InitFileEnumStringSection(
			const char *			category,
			const char *			key,
			InitFileReadFlags		flags,
			Boolean _pascal (*callback)		(const char *stringSection,
						 word 				sectionNum,
						 void *				enumData),
			void *					enumdata);

This routine enumerates a particular blob, allowing a callback routine to 
process each of the string sections in it. The routine will stop processing 
either after the last string section or when the callback routine returns *true*.

Pass this routine the following:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be enumerated.

*flags* - A record of **InitFileReadFlags** indicating the method of 
character conversion upon reading (upcase all, downcase all, do 
not change).

*callback* - A pointer to a Boolean callback routine. The callback routine is 
described below.

*enumData* - This pointer is passed unchanged to the callback routine. 
**InitFileEnumStringSection()** does not use it.

This routine returns a Boolean value. It returns *true* if the callback routine 
halted the enumeration by returning *true*; otherwise, it returns *false*.

**Callback Routine:**

The callback routine may do anything it wants with the string section it 
receives. It must be declared _pascal. It must return a Boolean value: If it 
returns *true*, **InitFileEnumStringSection()** will stop processing the blob. 
If it returns *false*, processing will continue to the next string section, if any. 
The callback will receive the following parameters:

*stringSection* - A pointer to the null-terminated string section to be processed.

*sectionNum* - The zero-based number of the string section currently being 
processed.

*enumData* - A pointer passed through from the caller of 
**InitFileEnumStringSection()**.

**Include:** initfile.h

----------
#### InitFileGetTimeLastModified()
	dword	InitFileGetTimeLastModified(void);
This routine returns the time when the GEOS.INI file was last modified. The 
returned time is the value of the system counter when the file was last 
written.

**Include:** initfile.h

----------
#### InitFileReadBoolean()
	Boolean	InitFileReadBoolean(
			const char *		category,
			const char *		key,
			Boolean *			bool);
This routine reads a Boolean entry in the GEOS.INI file, copying it into a 
passed buffer. It returns the first instance of the category/key combination it 
encounters, searching the local INI file first. Thus, local settings will always 
override system or network settings.

This routine is used for reading data written with **InitFileWriteBoolean()**. 
Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*bool* - A pointer to a Boolean variable in which the Boolean value will 
be returned.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

Warnings:	The return value of this function is *not* the Boolean stored in the GEOS.INI 
file. That value is returned in the Boolean pointed to by *bool*.

**Include:** initfile.h

----------
#### InitFileReadDataBlock()
	Boolean	InitFileReadDataBlock(
			const char *		category,
			const char *		key,
			MemHandle *			block,
			word *				dataSize);
This routine reads an entry in the GEOS.INI file, allocating a new block and 
copying the data into it. The routine returns the first instance of the 
category/key combination it encounters, searching the local INI file first. 
Thus, local settings will always override system or network settings.

This routine is used for reading data written with **InitFileWriteData()**. 
Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*block* - A pointer to a null memory handle. This pointer will point to 
the newly-allocated block handle upon return. The data read 
will be in the new block. It is your respojnsibility to free this 
block when you're done with it.

*dataSize* - The size of the read data. All the data will be read; the block 
will be as large as necessary.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileReadDataBuffer()
	Boolean	InitFileReadDataBuffer(
			const char *		category,
			const char *		key,
			void *				buffer,
			word				bufSize,
			word *				dataSize);
This routine reads an entry in the GEOS.INI file, copying it into a passed 
buffer. It returns the first instance of the category/key combination it 
encounters, searching the local INI file first. Thus, local settings will always 
override system or network settings.

This routine is used for reading data written with **InitFileWriteData()**. 
Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*buffer* - A pointer to the buffer in which the data will be returned. This 
buffer must be in locked or fixed memory.

*bufSize* - The size of the passed buffer in bytes. If you are not sure what 
the data's size will be, you may want to use the (slightly less 
efficient) **InitFileReadDataBlock()**.

*dataSize* - A pointer to a word; on return, the word pointed to will contain 
the size (in bytes) of the data returned.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileReadInteger()
	Boolean	InitFileReadInteger(
			const char *		category,
			const char *		key,
			word *				i);
This routine reads an integer entry in the GEOS.INI file, copying it into the 
passed variable. It returns the first instance of the category/key combination 
it encounters, searching the local INI file first. Thus, local settings will 
always override system or network settings.

This routine is used for reading data written with **InitFileWriteInteger()**. 
Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*i* - A pointer to a word in which the integer will be returned.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileReadStringBlock()
	Boolean	InitFileReadStringBlock(
			const char *		category,
			const char *		key,
			MemHandle *			block,
			InitFileReadFlags	flags,
			word *				dataSize);
This routine reads a string entry in the GEOS.INI file, allocates a new block 
on the global heap, and copies the read string into the new block. It returns 
the first instance of the category/key combination it encounters, searching 
the local INI file first. Thus, local settings will always override system or 
network settings.

This routine is used for reading data written with **InitFileWriteString()**. 
Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*block* - A pointer to a memory block handle variable. Upon return, this 
variable will contain the handle of the newly allocated block; 
the block will contain the string read from the file. It is your 
responsibility to free this block when you're done with it.

*flags* - A record of **InitFileReadFlags** indicating the method of 
character conversion upon reading (upcase all, downcase all, do 
not change).

*dataSize* - A pointer to a word which, upon return, will contain the size of 
the string (in bytes) actually read from the file.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileReadStringBuffer()
	Boolean	InitFileReadStringBuffer(
			const char *		category,
			const char *		key,
			char *				buffer,
			InitFileReadFlags	flags,
			word *				dataSize);
This routine reads a string entry in the GEOS.INI file, copying it into a 
passed, locked buffer. It returns the first instance of the category/key 
combination it encounters, searching the local INI file first. Thus, local 
settings will always override system or network settings.

This routine is used for reading data written with **InitFileWriteString()**. 
Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*buffer* - A pointer to a buffer into which the returned string will be 
written. This buffer must be in locked or fixed memory. If you 
don't know the approximate size of the data, you may want to 
use the (slightly less efficient) **InitFileReadStringBlock()**.

*flags* - A record of **InitFileReadFlags** indicating the size of the 
passed buffer as well as the method of character conversion 
upon reading (upcase all, downcase all, do not change).

*dataSize* - A pointer to a word which, upon return, will contain the size of 
the string (in bytes) actually read from the file.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileReadStringSectionBlock()
	Boolean	InitFileReadStringSectionBlock(
			const char *		category,
			const char *		key,
			word				section,
			MemHandle *			block,
			InitFileReadFlags	flags,
			word *				dataSize);
This routine reads a string section from the specified entry in the GEOS.INI 
file, allocates a new block on the global heap, and copies the read string 
section into the new block. It returns the first instance of the category/key 
combination it encounters, searching the local INI file first. Thus, local 
settings will always override system or network settings.

This routine is used for reading data written with **InitFileWriteString()** or 
**InitFileWriteStringSection()**. Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*section* - The zero-based number of the string section to retrieved.

*block* - A pointer to a memory block handle. Upon return, this pointer 
will point to the handle of the newly allocated block; the block 
will contain the string section read from the file.

*flags* - A record of **InitFileReadFlags** indicating the method of 
character conversion upon reading (upcase all, downcase all, do 
not change).

*dataSize* - A pointer to a word which, upon return, will contain the size of 
the string section (in bytes) actually read from the file.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileReadStringSectionBuffer()
	Boolean	InitFileReadStringSectionBuffer(
			const char *		category,
			const char *		key,
			word				section,
			char *				buffer,
			InitFileReadFlags	flags,
			word *				dataSize);
This routine reads a string section from the specified entry in the GEOS.INI 
file, copying it into a passed, locked buffer. It returns the indicated section in 
the first instance of the category/key combination it encounters, searching 
the local INI file first. Thus, local settings will always override system or 
network settings.

This routine is used for reading data written with 
**InitFileWriteStringSection()**. Pass it the following parameters:

*category* - A pointer to the null-terminated string representing the 
category in which the entry resides. This string ignores white 
space and is case-insensitive.

*key* - A pointer to the null-terminated string representing the key to 
be retrieved.

*section* - The zero-based number of the string section to be retrieved.

*buffer* - A pointer to a buffer into which the returned string section will 
be written. This buffer must be in locked or fixed memory. If 
you don't know the approximate size of the string section, you 
may want to use the (slightly less efficient) 
**InitFileReadStringSectionBlock()**.

*flags* - A record of **InitFileReadFlags** indicating the size of the 
passed buffer as well as the method of character conversion 
upon reading (upcase all, downcase all, do not change).

*dataSize* - A pointer to a word which, upon return, will contain the size of 
the string section (in bytes) actually read from the file.

The function's return value will be *true* if an error occurs or if the entry could 
not be found; it will be *false* otherwise.

**Include:** initfile.h

----------
#### InitFileRevert()
	Boolean	InitFileRevert(void);
This routine restores the GEOS.INI file from its saved backup version. It 
ensures that no other thread is operating on the file while it is being restored. 
This function returns an error flag: *true* represents an error in restoring the 
file; *false* indicates success.

**Include:** initfile.h

----------
#### InitFileSave()
	Boolean	InitFileSave(void);
This routine saves the GEOS.INI file synchronously by updating the backup 
file to be the current version. (**InitFileCommit()** actually overwrites the 
GEOS.INI file itself.) It ensures that no other thread is operating on the file 
while it is being written out. This function returns an error flag: *true* 
represents an error in trying to save the file; *false* indicates success.

**Include:** initfile.h

----------
#### InitFileWriteBoolean()
	void	InitFileWriteBoolean(
			const char *		category,
			const char *		key,
			Boolean 			bool);
This integer writes a Boolean value into the specified category and key of the 
local GEOS.INI file. The Boolean will appear as "true" or "false" if the user 
looks at GEOS.INI with a text editor, but it will be an actual Boolean value to 
GEOS. Pass this routine the following:

*category* - A pointer to the null-terminated character string representing 
the INI category into which the data should be written.

*key* - A pointer to the null-terminated character string representing 
the INI key within *category* into which the data should be 
written.

*bool* - The Boolean value to be written.

Once written, the Boolean value can be read with **InitFileReadBoolean()**.

**Include:** initfile.h

----------
#### InitFileWriteData()
	void	InitFileWriteData(
			const char 		*category,
			const char 		*key,
			const void 		*buffer,
			word			bufSize);
This routine writes a given piece of data to the local GEOS.INI file. Pass it the 
following:

*category* - A pointer to the null-terminated character string representing 
the INI category into which the data should be written.

*key* - A pointer to the null-terminated character string representing 
the INI key within *category* into which the data should be 
written.

*buffer* - A pointer to a locked or fixed buffer containing the data to be 
written.

*bufSize* - The size of the buffer in bytes.

Once data has been written to the INI file, it can be read with 
**InitFileReadDataBlock()** or **InitFileReadDataBuffer()**.

**Include:** initfile.h

----------
#### InitFileWriteInteger()
	void	InitFileWriteInteger(
			const char 		*category,
			const char 		*key,
			word			value);

This routine writes an integer into the category and key specified for the local 
GEOS.INI file. Pass the following:

*category* - A pointer to the null-terminated character string representing 
the INI category into which the data should be written.

*key* - A pointer to the null-terminated character string representing 
the INI key within *category* into which the data should be 
written.

*value* - The integer to be written.

The integer, once written, can be read with **InitFileReadInteger()**.

**Include:** initfile.h

----------
#### InitFileWriteString()
	void	InitFileWriteString(
			const char 		*category,
			const char 		*key,
			const char 		*str);
This routine writes an entire string into the category and key specified for the 
local GEOS.INI file. Pass it the following:

*category* - A pointer to the null-terminated character string representing 
the INI category into which the data should be written.

*key* - A pointer to the null-terminated character string representing 
the INI key within *category* into which the data should be 
written.

*str* - A pointer to the null-terminated string to be written. If the 
string contains line feeds or carriage returns, it will 
automatically be parsed into string segments and be put within 
curly braces; if it contains curly braces, all closing braces will 
automatically have a backslash inserted before them.

To read a string written with this routine, use **InitFileReadStringBlock()** 
or **InitFileReadStringBuffer()**.

**Include:** initfile.h

----------
#### InitFileWriteStringSection()
	void	InitFileWriteStringSection(
			const char 		*category,
			const char 		*key,
			const char 		*string);
This routine appends a string section onto the blob specified by the *category* 
and *key* parameters. The string section will become part of the blob and will 
be its last section. The section may not contain any carriage returns or line 
feeds. Pass this routine the following:

*category* - A pointer to the null-terminated character string representing 
the INI category into which the data should be written.

*key* - A pointer to the null-terminated character string representing 
the INI key within category into which the data should be 
written.

*string* - A pointer to the string section to be written.

Once written, the segment may be read with 
**InitFileReadStringSectionBlock()** or 
**InitfileReadStringSectionBuffer()**.

**Include:** initfile.h

----------
#### InkDBGetDisplayInfo()
	void 	InkDBGetDisplayInfo(
			InkDBDisplayInfo *		retVal,
			VMFileHandle 			fh);
This routine returns the dword ID of the note or folder which is presently 
being displayed by the Ink Database. It also returns the ID of the parent 
folder, and the page number, if applicable.

**Structures:** It returns this information by filling in an **InkDBDisplayInfo** structure:

	typedef struct {
		dword 	IDBDI_currentDisplay;
		dword 	IDBDI_parentFolder;
		word 	IDBDI_pageNumber;
	} InkDBDisplayInfo;

**Include:** pen.goh

----------
#### InkDBGetHeadFolder()
	dword 	InkDBGetHeadFolder(
			VMFileHandle 		fh);
This routine returns the dword ID of the head folder of an Ink Database file.

**Include:** pen.goh

----------
#### InkDBInit()
	void 	InkDBInit(
			VMFileHandle 		fh);
This routine takes a new Ink Database file. It initializes the file for use, 
creating all needed maps and a top-level folder. 

**Include:** pen.goh

----------
#### InkDBSetDisplayInfo()
	void 	InkDBSetDisplayInfo(
			VMFileHandle 	fh,
			dword 			ofh,	/* Parent Folder dword ID# */
			dword			note,	/* ID# of note or folder to display */
			word			page); 	/* If displaying note, page # to display*/
This routine sets the display information for an Ink Database file. This 
routine sets the user's location in the database. The caller must supply the 
dword ID number of the note or folder to display, the parent folder (0 if 
displaying the top level folder), and the page number to display if displaying 
a note.

**Include:** pen.goh

----------
#### InkFolderCreateSubFolder()
	dword 	InkFolderCreateSubFolder(
			dword 			tag, 	/* ID# of parent folder (0 for top-level) */
			VMFileHandle 	fh); 	/* Handle of Ink DB file */
This routine creates a subfolder within the passed folder. The new folder is 
automatically added to it's parent's chunk array. The return value is new 
folder's dword ID number.

**Include:** pen.goh

----------
#### InkFolderDelete()
	void 	InkFolderDelete(
			dword 			tag,		/* ID# of folder */
			VMFileHandle 	fh);		/* Handle of Ink DB file */
This routine removes an Ink Database folder.

**Include:** pen.goh

----------
#### InkFolderDepthFirstTraverse()
	word 	InkFolderDepthFirstTraverse(
			dword 			rfldr,		/* ID# of folder at root of search tree */
			VMFileHandle	fh, 		/* Handle of Ink DB file */
			Boolean 	_pascal	(*callback)( /* far ptr to callback routine */
				dword				fldr,
				VMFileHandle 		fh,
				word *				info),
			word *			info);		/* Extra data to pass to callback */

This routine does a depth-first traversal of a folder tree. The callback routine, 
which must be declared _pascal, can halt the search by returning *true*, in 
which case the search routine will immediately return *true*; otherwise the 
search will return *false*.

**Include:** pen.goh

----------
#### InkFolderDisplayChildInList()
	void 	InkFolderDisplayChildInList(
			dword 			fldr, 		/* ID# of folder */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			optr 			list, 		/* GenDynamicList */
			word			entry, 		/* entry number of child to display */
			Boolean			displayFolders); /* Include monikers in count,
											  * return their monikers */
This routine requests that a dynamic list display the name of one of a folder's 
children. It is normally called in an applications *GDLI_queryMsg* handler.

**Include:** pen.goh

----------
#### InkFolderGetChildInfo()
	Boolean 	InkFolderDisplayChildInfo( /* true if folder; else note */
			dword 			fldr, 		/* ID# of folder */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			word			entry, 		/* entry number of child */
			dword *			childID);	/* Pointer to returned child ID # */
This routine returns information about one of a folder's children. The explicit 
return value will be *true* if the child is a folder, *false* if the child is a note. In 
addition, the passed dword pointer will point to the child's dword ID number.

**Include:** pen.goh

----------
#### InkFolderGetChildNumber()
	word 	InkFolderDisplayChildInList( 
			dword 			fldr, 		/* ID# of folder */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			dword			note); 		/* ID# of child note or folder */
This routine returns the passed note or folder's entry number within its 
passed parent folder.

**Include:** pen.goh

----------
#### InkFolderGetContents()
	DBGroupAndItem 	InkFolderGetContents(
			dword 				tag, 			/* ID# of folder */
			VMFileHandle 		fh,				/* Handle of Ink DB file */
			DBGroupAndItem *	subFolders); 	/* pointer to return value */);
This routine returns the contents of a folder. It returns two chunk arrays, 
each of which is filled with dword ID numbers of the folder's children. The 
explicitly returned array holds the numbers of the folder's child notes. The 
routine also fills in a pointer with a DB item holding a chunk array with the 
ID numbers of the subfolders.

**Include:** pen.goh

----------
#### InkFolderGetNumChildren()
	dword 	InkFolderGetNumChildren( /* Subfolders:Notes */
			dword 			fldr, 		/* ID# of folder */
			VMFileHandle 	fh);		/* Handle of Ink DB file */
This message returns the number of children the Ink Database folder has. 
The high word of the return value holds the number of sub folders; the low 
word holds the number of notes.

**Include:** pen.goh

----------
#### InkFolderMove()
	void 	InkFolderMove(
			dword 		fldr, 		/* ID# of folder to move */
			dword 		pfldr);		/* ID# of new parent folder */
This routine moves an Ink Database folder to a new location in the folder 
tree.

**Include:** pen.goh

----------
#### InkFolderSetTitle()
	void 	InkFolderSetTitle(
			dword 			tag, 		/* ID# of folder */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			const char *	name); 		/* Text object */);
This routine renames an Ink Database folder. The passed name should be 
null-terminated.

**Include:** pen.goh

----------
#### InkFolderSetTitleFromTextObject()
	void 	InkFolderSetTitleFromTextObject(
			dword 		tag, 		/* ID# of folder */
			FileHandle 	fh,			/* Handle of Ink DB file */
			optr		text); 		/* Text object */);
This routine sets the name of the passed Ink Database folder from the 
contents of the passed VisText object.

**Include:** pen.goh

----------
#### InkGetDocPageInfo()
	void 	InkGetDocPageInfo(
			PageSizeReport *	psr, 	/* Structure to fill with return value */
			VMFileHandle 		fh);
This routine returns the dword ID of the head folder of an Ink Database file.

**Include:** pen.goh

----------
#### InkGetDocCustomGString()
	GStateHandle 	InkGetDocCustomGString(
			VMFileHandle 		dbfh);
This routine returns the custom GString associated with the passed Ink 
Database file. Note that this custom background will only be used if the 
document's basic **InkBackgroundType** is IBT_CUSTOM. (This may be 
determined using the **InkDBSetDocGString()** routine.

**Include:** pen.goh

----------
#### InkGetDocGString()
	InkBackgroundType 	InkGetDocGString(
			VMFileHandle 		dbfh);
This routine returns the standard GString to use as a background picture 
with the passed Ink Database file. If the returned background type is custom, 
be sure to also call **InkGetDocCustomGString()**.

**Include:** pen.goh

----------
#### InkGetParentFolder()
	dword 	InkGetParentFolder(
			dword 			tag, 		/* ID# of folder or note */
			VMFileHandle 	fh);		/* Handle of Ink DB file */
This message returns the dword ID of the passed Ink Database note or folder.

**Include:** pen.goh

----------
#### InkGetTitle()
	word 	InkGetTitle(
			dword 			tag, 		/* ID# of folder or note */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			char *			dest); 		/* should be INK_DB_MAX_TITLE_SIZE +1 */);
This message fills the passed text buffer with the folder's or note's title, a 
null-terminated string. The routine's explicit return value is the length of the 
string (including the terminator).

**Include:** pen.goh

----------
#### InkNoteCopyMoniker()
	dword 	InkNoteCopyMoniker(
			dword 	title,		/* ID# of parent folder */
			optr 	list, 		/* Output list */
			word 	type, 		/* 1: text note
								 * 0: ink note
								 * -1: folder */
			word	entry);		/* Handle of Ink DB file */
This routine copies the icon and title into the VisMoniker.

**Include:** pen.goh

----------
#### InkNoteCreate()
	dword 	InkNoteCreate(
			dword 			tag,		/* ID# of parent folder */
			VMFileHandle	fh);		/* Handle of Ink DB file */
This routine creates a note and adds it to the passed folder's child list. The 
new note's dword ID is returned.

**Include:** pen.goh

----------
#### InkNoteCreatePage()
	word 	InkNoteCreatePage(
			dword 			tag,	/* ID# of note */
			VMFileHandle	fh,		/* Handle of Ink DB file */
			word 			page); 	/* Page number to insert before, 
									 * CA_NULL_ELEMENT to append */
This routine creates a new page within a note. It returns the new page 
number.

**Include:** pen.goh

----------
#### InkNoteDelete()
	void 	InkNoteDelete(
			dword 			tag, 		/* ID# of note */
			VMFileHandle 	fh);		/* Handle of Ink DB file */
This message deletes the passed note. All references to the note are deleted.

**Include:** pen.goh

----------
#### InkNoteFindByKeywords()
	ChunkHandle 	InkNoteFindByKeywords( 
						/* Return value is chunk array with elements:
						 *  FindNoteHeader
						 *  -dword tag-
						 *  -dword tag-
						 *   etc- */
			VMFileHandle 	fh,
			char *			strings,	/* strings to match (separated by 
										 * whitespace or commas), can contain
										 * C_WILDCARD or C_SINGLE_WILDCARD */
			word 			opt,		/* true to match all keywords; 
										 * false to match at least one keyword */
This routine returns a chunk array containing the dword ID numbers of all 
notes whose keywords match the passed search string, preceded by the 
number of matching notes. If no such notes are found, then the returned 
handle will be NULL.

Note that this routine will only return about 20K notes; if there are more that 
match, only the first 20K will be returned.

**Include:** pen.goh

----------
#### InkNoteFindByTitle()
	ChunkHandle 	InkNoteFindByTitle( 
						/* Return value is chunk array with elements:
						 *  FindNoteHeader
						 *  -dword tag-
						 *  -dword tag-
						 *   etc- */
			const char *	string,	/* string to match (can contain C_WILDCARD
									 * or C_SINGLE_WILDCARD */
			SearchOptions 	opt,	/* Search options */
			Boolean 		Body, 	/* true if you want to look in the body
									 * of text notes */
			VMFileHandle	fh);	/* Handle of Ink DB file */
This routine returns a chunk array containing the dword ID numbers of all 
notes whose titles match the passed search string, preceded by the number 
of matching notes. If no such notes are found, then the returned handle will 
be NULL.

Note that this routine will only return about 20K notes; if there are more that 
match, only the first 20K will be returned.

**Include:** pen.goh

----------
#### InkNoteGetCreationDate()
	dword 	InkNoteGetCreationDate( 
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh);		/* Handle of Ink DB file */
This routine gets a note's creation date.

**Include:** pen.goh

----------
#### InkNoteGetKeywords()
	void 	InkNoteGetKeywords(
			dword 			tag, 		/* ID# of note */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			char *			text); 		/* String to hold return value */);
This routine fills the passed buffer with the note's keywords. The target 
buffer should be of atleast length INK_DB_MAX_NOTE_KEYWORDS_SIZE +1. 
The string will be null-terminated.

**Include:** pen.goh

----------
#### InkNoteGetModificationDate()
	dword 	InkNoteGetModificationDate( 
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh);		/* Handle of Ink DB file */
This routine gets a note's modification date.

**Include:** pen.goh

----------
#### InkNoteGetNoteType()
	NoteType 	InkNoteGetNoteType( /* 0: Ink, 1: Text */
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh);		/* Handle of Ink DB file */
This routine gets a note's **NoteType**: NT_INK or NT_TEXT.

**Include:** pen.goh

----------
#### InkNoteGetNumPages()
	word 	InkNoteGetNumPages(
			dword 		tag);		/* ID# of note */
This routine returns the number of pages within the passed note.

**Include:** pen.goh

----------
#### InkNoteGetPages()
	DBGroupAndItem 	InkNoteGetPages(
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh);		/* Handle of Ink DB file */
This routine returns a DB group and item containing a chunk array. The 
chunk array contains the page information of the note, either compressed 
pen data or text. Each array element holds one page of data.

**Include:** pen.goh

----------
#### InkNoteLoadPage()
	void 	InkNoteLoadPage(
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh,			/* Handle of Ink DB file */
			word 			page, 		/* Page number */
			optr 			obj, 		/* an Ink or VisText object */
			word 			type);		/* note type 0: ink, 1: text */
This routine loads a visual object (Ink or Text) with the contents of the passed 
Ink Database page. Be sure to load only the correct type of data into an object.

**Include:** pen.goh

----------
#### InkNoteMove()
	void 	InkNoteMove(
			dword 			tag, 		/* ID# of note */
			dword 			pfolder, 	/* ID# of new parent folder */
			VMFileHandle 	fh);		/* Handle of Ink DB file */
This message moves the passed note to a new location. All references to the 
note are suitably altered.

**Include:** pen.goh

----------
#### InkNoteSavePage()
	void 	InkNoteSavePage(
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh,			/* Handle of Ink DB file */
			word 			page, 		/* Page number */
			optr 			obj, 		/* an Ink or VisText object */
			word 			type);		/* note type 0: ink, 1: text */
This routine saves the contents of a visual object (Ink or Text) to the passed 
Ink Database page.

**Include:** pen.goh

----------
#### InkNoteSendKeywordsdToTextObject()
	void 	InkNoteSendKeywordsToTextObject(
			dword 			tag, 		/* ID# of note */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			optr			text); 		/* Text object to set */);
This message replaces the passed VisText object's text with the keywords 
from the passed folder or note of an Ink Database file.

**Include:** pen.goh

----------
#### InkNoteSetKeywords()
	void 	InkNoteSetKeywords(
			dword 			tag, 			/* ID# of note */
			VMFileHandle 	fh,				/* Handle of Ink DB file */
			const char *	text); 			/* Keyword string */);
This message sets an Ink Database note's keywords. The passed string 
should be null-terminated.

**Include:** pen.goh

----------
#### InkNoteSetKeywordsFromTextObject()
	void 	InkNoteSetKeywordsFromTextObject(
			dword 			tag, 			/* ID# of note */
			VMFileHandle 	fh,				/* Handle of Ink DB file */
			optr *			text); 			/* Text object */);
This message sets an Ink Database note's keywords by copying them from the 
passed text object.

**Include:** pen.goh

----------
#### InkNoteSetModificationDate()
	void 	InkNoteSetModificationDate( 
			word			tdft1, 		/* First two words of */
			word			tdft2,		/* TimerDateAndTime structure */
			dword 			note,		/* ID# of note */
			FileHandle		fh);		/* Handle of Ink DB file */
This routine sets a note's modification date.

**Include:** pen.goh

----------
#### InkNoteSetNoteType()
	void 	InkNoteSetNoteType( 
			dword 			tag,		/* ID# of note */
			VMFileHandle	fh,			/* Handle of Ink DB file */
			NoteType 		nt);		/* NT_INK or NT_TEXT */
This routine sets a note's type: text or ink.

**Include:** pen.goh

----------
#### InkNoteSetTitle()
	void 	InkNoteSetTitle(
			dword 			tag, 			/* ID# of note */
			VMFileHandle 	fh,				/* Handle of Ink DB file */
			const char *	name); 			/* Text object */);
This message renames an Ink Database note. The passed name should be 
null-terminated. The string may be up to 
INK_DB_MAX_NOTE_KEYWORDS_SIZE +1 in length.

**Include:** pen.goh

----------
#### InkNoteSetTitleFromTextObject()
	void 	InkNoteSetTitleFromTextObject(
			dword 			tag, 		/* ID# of note */
			FileHandle 		fh,			/* Handle of Ink DB file */
			optr			text); 		/* Text object */);
This message sets the name of the passed Ink Database note from the 
contents of the passed VisText object.

**Include:** pen.goh

----------
#### InkSendTitleToTextObject()
	void 	InkSendTitleToTextObject(
			dword 			tag, 		/* ID# of folder or note */
			VMFileHandle 	fh,			/* Handle of Ink DB file */
			optr			to); 		/* Text object to set */);
This message replaces the passed VisText object's text with the name from 
the passed folder or note of an Ink Database file.

**Include:** pen.goh

----------
#### InkSetDocCustomGString()
	void	InkSetDocCustomGString(
			VMFileHandle 		dbfh,
			Handle		gstring);
This routine sets the custom GString to use as a background for the passed 
Ink Database file. Note that this custom background will only be used if the 
document's basic **InkBackgroundType** is IBT_CUSTOM. (Set this using the 
**InkDBSetDocGString()** routine.)

**Include:** pen.goh

----------
#### InkSetDocGString()
	void	InkSetDocGString(
			VMFileHandle 			dbfh,
			InkBackgroundType		type);
This routine sets the standard GString to use as a background picture with 
the passed Ink Database file. If the passed background type is custom, be 
sure to also call **InkSetDocCustomGString()**.

**Include:** pen.goh

----------
#### InkSetDocPageInfo()
	void 	InkSetDocPageInfo(
			PageSizeReport *		psr,
			VMFileHandle 			fh);
Set the page information for an Ink Database file.

**Include:** pen.goh

----------
#### IntegerOf()
	word	IntegerOf(
			WWFixedAsDWord		wwf)
This macro returns the integral portion of a WWFixedAsDWord value.

**Include:** geos.h

----------
#### LMemAlloc()
	ChunkHandle	 LMemAlloc(
			MemHandle	mh,				/* Handle of block containing heap */
			word		chunkSize);		/* Size of new chunk in bytes */
This routine allocates a new chunk in the LMem heap. The heap must be 
locked or fixed. It allocates a chunk, expanding the chunk table if enccessary, 
and returns the chunk's handle. The chunk is not zero-initialized. If the 
chunk could not be allocated, it returns a null handle. Chunks are 
dword-aligned, so the chunk's actual size may be slightly larger than you 
request.

**Include:** lmem.h

**Be Sure To:** Lock the block on the global heap (unless the block is fixed).

**Warnings:** The heap may be compacted; thus, all pointers to chunks are invalidated. If 
LMF_NO_EXPAND is not set, the heap may be resized (and thus moved), thus 
invalidating all pointers to that block. Even fixed blocks can be resized and 
moved.

**See Also:** LMemDeref(), LMemReAlloc()

----------
#### LMemContract()
	void	LMemContract(
			MemHandle		mh);		/* Handle of LMem heap */
This routine contracts an LMem heap; that is, it deletes all the free chunks, 
moves all the used chunks to the beginning of the heap (right after the chunk 
handle table), and resizes the block to free the unused space at the end. It's 
a good idea to call this routine if you have just freed a lot of chunks, since that 
will free up some of the global heap. The LMem heap is guaranteed not to 
move; however, all pointers to chunks will be invalidated.

**Be Sure To:** Lock the block on the global heap (if it isn't fixed).

**Include:** lmem.h

----------
#### LMemDeleteAt()
	void	LMemDeleteAt(
			optr	chunk,			/* Chunk to resize */
			word	deleteOffset,	/* Offset within chunk of first 
									 * byte to be deleted */
			word	deleteCount);	/* # of bytes to delete */
This routine deletes a specified number of bytes from inside a chunk. It is 
guaranteed not to cause the heap to be resized or compacted; thus, pointers 
to other chunks remain valid.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Warnings:** The bytes you delete must all be in the chunk. If *deleteOffset* and *deleteCount* 
indicate bytes that are not in the chunk, results are undefined.

**Include:** lmem.h

**See Also:** LMemReAlloc(), LMemInsertAt(), LMemDeleteAtHandles()

----------
#### LMemDeleteAtHandles()
	void	LMemDeleteAtHandles(
			MemHandle		mh,				/* Handle of LMem heap */
			ChunkHandle		ch,				/* Handle of chunk to resize */
			word			deleteOffset,	/* Offset within chunk of first 
											 * byte to be deleted */
			word			deleteCount);	/* # of bytes to delete */
This routine is exactly like **LMemDeleteAt()** above, except that the chunk 
is specified by its global and chunk handles.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Warnings:** The bytes you delete must all be in the chunk. If *deleteOffset* and *deleteCount* 
indicate bytes that are not in the chunk, results are undefined.

**Include:** lmem.h

----------
#### LMemDeref()
	void *	LMemDeref(
			optr	chunk);	/* optr to chunk to dereference */
This routine translates an optr into the address of the chunk. The LMem 
heap must be locked or fixed on the global heap. Chunk addresses can be 
invalidated by many LMem routines, forcing you to dereference the optr 
again.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Include:** lmem.h

**See Also:** LMemDerefHandles()

----------
#### LMemDerefHandles()
	void *	LMemDerefHandles(
			MemHandle		mh,			/* Handle of LMem heap's block */
			ChunkHandle		chunk);		/* Handle of chunk to dereference */
This routine is exactly like **LMemDeref()** above, except that the chunk is 
specified by its global and chunk handles.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Include:** lmem.h

**See Also:** LMemDeref()

----------
#### LMemFree()
	void	LMemFree(
			optr	chunk);			/*optr of chunk to free */
This routine frees a chunk from an LMem heap. The chunk is added to the 
heap's free list. The routine is guaranteed not to compact or resize the heap; 
thus, all pointers within the block remain valid (except for pointers to data 
in the freed chunk, of course).

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Include:** lmem.h

**See Also:** LMemFreeHandles()

----------
#### LMemFreeHandles()
	void	LMemFreeHandles(
			MemHandle		mh,				/* Handle of LMem heap */
			ChunkHandle		chunk);			/* Handle of chunk to free */
This routine is just like **LMemFree()** above, except that the chunk is 
specified by its global and chunk handles (instead of by an optr).

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Include:** lmem.h

----------
#### LMemGetChunkSize()
	word	LMemGetChunkSize(
			optr	chunk);				/* optr of subject chunk */
This routine returns the size (in bytes) of a chunk in an LMem heap. Since 
LMem chunks are dword-aligned, the chunk's size may be slightly larger 
than the size specified when it was allocated. The routine is guaranteed not 
to compact or resize the heap; thus, all pointers within the block remain 
valid.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Include:** lmem.h

**See Also:** LMemGetChunkSizeHandles()

----------
#### LMemGetChunkSizeHandles()
	word	Routine(
			MemHandle		mh,			/* Handle of LMem heap */
			ChunkHandle		chunk);		/* Handle of chunk in question */
This routine is just like **LMemGetChunkSize()** above, except that the 
chunk is specified by its global and chunk handles (instead of by an optr).

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Include:** lmem.h

**See Also:** LMemGetChunkSize()

----------
#### LMemInitHeap()
	void	LMemInitHeap(
			MemHandle			mh,			/* Handle of (locked or fixed)
											 * block which will contain heap 	*/
			LMemType			type,		/* Type of heap to create */
			LocalMemoryFlags	flags,		/* Record of LocalMemoryFlags */
			word				lmemOffset,	/* Offset of first chunk in heap (or
											 * zero for default offset) */
			word				numHandles,	/* Size of starter handle table */
			word				freeSpace);	/* Size of first free chunk 
											 * created */
This routine creates an LMem heap in a global memory block. The block must 
be locked or fixed in memory. The routine initializes the 
**LMemBlockHeader**, creates a handle table, allocates a single free chunk, 
and turns on the HF_LMEM flag for the block. The block will be reallocated if 
necessary to make room for the heap. The routine takes six arguments:

*mh* - The memory block's handle

*type* - A member of the **LMemType** enumerated type, specifying the 
kind of block to create. For most applications, this will be 
LMEM_TYPE_GENERAL.

*flags* - A record of **LocalMemoryFlags**, specifying certain properties 
of the heap. Most applications will pass a null record.

*lmemOffset* - The offset within the block at which to start the heap. This 
must be larger than the size of the **LMemBlockHeader** 
structure which begins every heap block, or it must be zero, 
indicating that the heap should begin immediately after the 
header. Any space between the **LMemBlockHeader** and the 
heap is left untouched by all LMem routines.

*numHandles* - The number of entries to create in the block's chunk handle 
table. The chunk handle table will grow automatically when all 
entries have been used up. Applications should generally pass 
the constant STD_LMEM_INIT_HANDLES; they should 
definitely pass a positive number.

*freeSpace* - The amount of space to allocate to the first free chunk. 
Applications should generally pass the constant 
STD_LMEM_INIT_HEAP they should definitely pass a positive 
number.

To destroy an LMem heap, call **MemFree()** to free the block containing the 
heap.

**Structures:** There are two special data types used by this routine: **LMemTypes** and 
**LocalMemoryFlags**.

LMem heaps are created for many different purposes. Some of these 
purposes require the heap to have special functionality. For this reason, you 
must pass a member of the **LMemTypes** enumerated type to specify the kind 
of heap to create. The following types can be used; other types exist but 
should not be used with **LMemInitHeap()**.

LMEM_TYPE_GENERAL  
Ordinary heap. Most application LMem heaps will be of this 
type.

LMEM_TYPE_OBJ_BLOCK  
The heap will contain object instance chunks.

When an LMem heap is created, you must pass a record of flags to 
**LMemInitHeap()** to indicate how the heap should be treated. Most of the 
**LocalMemoryFlags** are only passed by system routines; all the flags 
available are listed below. The flags can be read by examining the 
**LMemBlockHeader** structure at the beginning of the block. Ordinarily, 
general LMem heaps will have all flags cleared.

LMF_HAS_FLAGS  
Set if the block has a chunk containing only flags. This flag is 
set for object blocks; it is usually cleared for general LMem 
heaps.

LMF_DETACHABLE  
Set if the block is an object block which can be saved to a state 
file.

LMF_NO_ENLARGE  
Indicates that the local-memory routines should not enlarge 
this block to fulfill chunk requests. This guarantees that the 
block will not be moved by a chunk allocation request; however, 
it makes these requests more likely to fail.

LMF_RETURN_ERRORS  
Set if local memory routines should return errors when 
allocation requests cannot be fulfilled. If the flag is not set, 
allocation routines will fatal-error if they cannot comply with 
requests.

STD_LMEM_OBJECT_FLAGS  
Not actually a flag; rather, it is the combination of 
LMF_HAS_FLAGS and LMF_RELOCATED. These flags are set 
for object blocks.

**Tips and Tricks:** If you want a fixed data space after the header, declare a structure whose first 
element is an **LMemBlockHeader** and whose other fields are for the data 
you will store in the fixed data space. Pass the size of this structure as the 
*LMemOffset* argument. You can now access the fixed data area by using the 
fields of the structure.

**Be Sure To:** Pass an offset of either zero or at least as large as 
**sizeof(LMemBlockHeader)**. If you pass a positive offset that is too small, 
the results are undefined. Lock the block on the global heap before calling 
this routine (unless the block is fixed).

**Warnings:** The block may be relocated, if its initial size is too small to accommodate the 
heap. This is true even for fixed blocks. If the flag LMF_NO_ENLARGE is set, 
the block will never be relocated; however, you must make sure it starts out 
large enough to accommodate the entire heap.

**Include:** lmem.h

**See Also:** LMemBlockHeader, LMemType, LocalMemoryFlags, MemAlloc(), 
MemFree(), VMAllocLMem()

----------
#### LMemInsertAt()
	void	LMemInsertAt(
			optr	chunk,			/* optr of chunk to resize */
			word	insertOffset,	/* Offset within chunk of first byte
									 * to be added */
			word	insertCount);	/* # of bytes to add */
This routine inserts space in the middle of a chunk and zero-initializes the 
new space. The first new byte will be at the specified offset within the chunk. 

**Be Sure To:** Lock the block on the global heap (unless it is fixed). Make sure the offset is 
within the specified chunk.

**Warnings:** This routine may resize or compact the heap; thus, all pointers to data within 
the block are invalidated.

You must pass an *insertOffset* that is actually within the chunk; if the offset 
is out-of-bounds, results are undefined.

**Include:** lmem.h

**See Also:** LMemReAlloc(), LMemDeleteAt(), LMemInsertAtHandles()

----------
#### LMemInsertAtHandles()
	void	LMemInsertAtHandles(
			MemHandle		mh,				/* Handle of LMem heap */
			ChunkHandle		chunk,			/* Chunk to resize */
			word			insertOffset,	/* Offset within chunk of first byte
											 * to be added */
			word			insertCount);	/* # of bytes to add */
This routine is just like **LMemInsertAt()** above, except that the chunk is 
specified by its global and chunk handles (instead of by an optr).

**Be Sure To:** Lock the block on the global heap (unless it is fixed). Make sure the offset is 
within the specified chunk.

**Warnings:** This routine may resize or compact the heap; thus, all pointers to data within 
the block are invalidated.

You must pass an *insertOffset* that is actually within the chunk; if the offset 
is out-of-bounds, results are undefined.

**Include:** lmem.h

----------
#### LMemReAlloc()
	Boolean	LMemReAlloc(
			optr	chunk,				/* optr of chunk to resize */
			word	chunkSize);			/* New size of chunk in bytes */
This routine resizes a chunk in an LMem heap. The heap must be in a locked 
or fixed block. If the routine succeeds, it returns zero. If it fails (because the 
heap ran out of space and could not be expanded), it returns non-zero.

If the new size is larger than the original size, extra bytes will be added to 
the end of the chunk. These bytes will not be zero-initialized. The heap may 
have to be compacted or resized to accommodate the request; thus, all 
pointers to data within the block are invalidated. 

If the new size is smaller than the old, the chunk will be truncated. The 
request is guaranteed to succeed, and the chunk will not be moved; neither 
will the heap be compacted or resized. Thus, all pointers to other chunks 
remain valid. Reallocating a chunk to zero bytes is the same as freeing it.

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Warnings:** As noted, if the new size is larger than the old, the heap may be compacted 
or resized, invalidating pointers.

**Include:** lmem.h

**See Also:** LMemReAllocHandles(), LMemInsertAt(), LMemDeleteAt()

----------
#### LMemReAllocHandles()
	void	LMemReAllocHandles(
			MemHandle		mh,				/* Handle of LMem heap */
			ChunkHandle		chunk,			/* Handle of chunk to resize */
			word			chunkSize);		/* New size of chunk in bytes */
This routine is just like **LMemReAlloc()** above, except that the chunk is 
specified by its global and chunk handles (instead of by an optr).

**Be Sure To:** Lock the block on the global heap (unless it is fixed).

**Warnings:** As noted, if the new size is larger than the old, the heap may be compacted 
or resized, invalidating pointers.

**Include:** lmem.h

----------
#### LocalAsciiToFixed()
	WWFixedAsDWord LocalAsciiToFixed(
			const char *		buffer,
			char **				parseEnd);
This routines converts a string like "12.345" to a fixed point number.

**Include:** localize.h

----------
#### LocalCmpStrings()
	sword	LocalCmpStrings(
			const char *		str1,
			const char *		str2,
			word				strSize);
This routine compares two strings to determine which comes first in a lexical 
(i.e. alphabetic) ordering. If the return value is negative, then *str1* is earlier 
than *str2*. If the return value is positive, then *str1* is later than *str2*. If the 
return value is zero, then the strings appear at the same place in 
alphabetical order.

**Include:** localize.h

----------
#### LocalCmpStringsDosToGeos()
	sword	LocalCmpStringsDosToGeos(
			const char *					str1,
			const char *					str2,
			word							strSize,
			word							defaultChar,
			LocalCmpStringsDosToGeosFlags 	flags);
This routine compares two strings to determine which comes first in lexical 
ordering. Either or both of these strings may be a DOS string.  If the return 
value is negative, then *str1* is earlier than *str2*. If the return value is positive, 
then *str1* is later than *str2*. If the return value is zero, then the strings appear 
at the same place in alphabetical order.

**Structures:**

	typedef ByteFlags LocalCmpStringsDosToGeosFlags;
		/* The following flags may be combined using | and &:
		 *		LCSDTG_NO_CONVERT_STRING_2,
		 * 		LCSDTG_NO_CONVERT_STRING_1 */

**Include:**	localize.h

----------
#### LocalCmpStringsNoCase()
	sword	LocalCmpStringsNoCase(
			const char *		str1,
			const char *		str2,
			word				strSize);
This routine compares two strings to determine which comes first in a lexical 
(i.e. alphabetic) ordering. The comparison used is not case-sensitive.  If the 
return value is negative, then *str1* is earlier than *str2*. If the return value is 
positive, then *str1* is later than *str2*. If the return value is zero, then the 
strings appear at the same place in alphabetical order.

**Include:** localize.h

----------
#### LocalCodePageToGeos()
	Boolean	LocalCodePageToGeos(
			char *			str,
			word			strSize,	/* Size of the string, in bytes */
			DosCodePage 	codePage,
			word			defaultChar);

This routine converts a DOS string to standard GEOS text using a specified 
code page. Any characters for which there is no GEOS equivalent will be 
replaced by the passed default character.  

**Include:** localize.h

----------
#### LocalCodePageToGeosChar()
	word	LocalCodePageToGeosChar(
			word			ch,
			DosCodePage		codePage,
			word			defaultChar);

This routine converts a DOS character to standard GEOS text using a 
specified code page. Any character for which there is no GEOS equivalent will 
be replaced by the passed default character.

**Include:**	localize.h

----------
#### LocalCustomFormatDateTime()
	word	LocalCustomFormatDateTime(
			char *					str,		/* Buffer to save formatted text in */
			const char *			format,		/* Format string */
			const TimerDateAndTime	*dateTime);
This routine takes a date or time and constructs a string using a custom 
format. 

**Include:** localize.h

----------
#### LocalCustomParseDateTime()
	word	LocalCustomParseDateTime(
			const char *			str,
			DateTimeFormat			format,
			TimerDateAndTime *		dateTime);
This routine parses a date and time string by comparing it with the passed 
**DateTimeFormat**. It fills in the fields of the **TimerDateAndTime** 
structure. Any fields which are not specified in the format string will be filled 
with -1.

If the string parses correctly, **LocalCustomParseDateTime()** returns -1. 
Otherwise it reutrns the offset to the start of the text which did not parse 
correctly.

**Include:** localize.h

----------
#### LocalDistanceFromAscii()
	WWFixedAsDword 	LocalDistanceFromAscii( 
			const char *			buffer,
			DistanceUnit 			distanceUnits,
			MeasurementTypes		measurementType);
This routine takes a function like "72 pt" and returns a number representing 
the distance. The returned answer represents the measure in points, inches, 
centimeters, or some other measure as specified by the passed unit.

**Include:** localize.h

----------
#### LocalDistanceToAscii()
	word	LocalDistanceToAscii( /* Length of string, including NULL */
			char *				buffer,		/*Buffer to save formatted text in */
			word 				value,
			DistanceUnit 		distanceUnits,
			MeasurementType 	measurementType);
This routine takes a distance and a set of units and returns a string 
containing a properly formatted distance.

**Include:** localize.h

----------
#### LocalDosToGeos()
	Boolean	LocalDosToGeos(
			char *	str,
			word	strSize,
			word	defaultChar);
Convert a DOS string to GEOS text. Any characters for which there is no 
GEOS equivalent will be replaced by the passed default character.

**Include:** localize.h

----------
#### LocalDosToGeosChar()
	word	LocalDosToGeosChar(
			word	ch,
			word	defaultChar);
Convert a DOS character to GEOS text. Any characters for which there is no 
GEOS equivalent will be replaced by the passed default character.

**Include:** localize.h

----------
#### LocalDowncaseChar()
	word	LocalDowncaseChar(
			word	ch);
Return the lower case equivalent, if any, of the passed character.

**Include:** localize.h

----------
#### LocalDowncaseString()
	void	LocalDowncaseString(
			char *	str,
			word	size);		/* Size of string, in bytes */
Convert the passed string to its all lower case equivalent.

**Include:** localize.h

----------
#### LocalFixedToAscii()
	void	LocalFixedToAscii(
			char *			buffer,
			WWFixedAsDWord	value,
			word			fracDigits);
This routine returns the ASCII expression of a fixed point number.

**Include:** localize.h

----------
#### LocalFormatDateTime()
	word	LocalFormatDateTime( /* Length of returned string */
			char *						str,
			DateTimeFormat 				format,
			const TimerDateAndTime *	dateTime);
This routine returns the string (e.g. "9:37") corresponding to the passed 
DateAndTime.

**Include:**	localize.h

----------
#### LocalGeosToCodePage()
	Boolean	LocalGeosToCodePage(
			char *			str,
			word			strSize,
			DosCodePage 	codePage,
			word			defaultChar);
Convert a GEOS string to DOS text, using the specified code page. Any 
characters for which there is no DOS equivalent will be replaced by the 
passed default character.

**Include:** localize.h

----------
#### LocalGeosToCodePageChar()
	word	LocalGeosToCodePageChar(
			word			ch,
			DosCodePage 	codePage,
			word			defaultChar);
Convert a GEOS character to DOS text, using the specified code page. Any 
character for which there is no DOS equivalent will be replaced by the passed 
default character.

**Include:** localize.h

----------
#### LocalGeosToDos()
	Boolean	LocalGeosToDos(
			char *	str,
			word	strSize,
			word	defaultChar);
Convert a GEOS string to DOS text. Any characters for which there is no DOS 
equivalent will be replaced by the passed default character.

**Include:** localize.h

----------
#### LocalGeosToDosChar()
	word	LocalGeosToDosChar(
			word	ch,
			word	defaultChar);
Convert a GEOS character to DOS text. Any character for which there is no 
DOS equivalent will be replaced by the passed default character.

**Include:** localize.h

----------
#### LocalGetCodePage()
	DosCodePage LocalGetCodePage(void);
This routine returns the current code page, used by DOS to handle 
international character sets.

**Include:** localize.h

----------
#### LocalGetCurrencyFormat()
	void	LocalGetCurrencyFormat(
			LocalCurrencyFormat *	buf,
			char *					symbol);
This routine returns the current currency format and symbol.

**Include:** localize.h

----------
#### LocalGetDateTimeFormat()
	void	LocalGetDateTimeFormat(
			char *				str,
			DateTimeFormat 		format);
This routine returns the user's preferred time and date formats.

**Include:** localize.h

----------
#### LocalGetDefaultPrintSizes()
	void	LocalGetDefaultPrintSizes(
			DefaultPrintSizes *		sizes);
This routine returns the system's default page and document size.

**Include:** localize.h

----------
#### LocalGetMeasurementType()
	MeasurementTypes LocalGetMeasurementType(void);
This routine returns the user preference between US and metric 
measurement systems.

**Include:** localize.h

----------
#### LocalGetNumericFormat()
	void	LocalGetNumericFormat(
			LocalNumericFormat *		buf);
This routine returns the user's preferred format for numbers.

**Include:** localize.h

----------
#### LocalGetQuotes()
	void	LocalGetQuotes(
			LocalQuotes *		quotes);
This routine returns the user's preferred quote marks.

**Include:** localize.h

----------
#### LocalIsAlpha()
	Boolean	LocalIsAlpha(
			word	ch);
This routine returns *true* if the passed character is alphabetic.

**Include:** localize.h

----------
#### LocalIsAlphaNumeric()
	Boolean	LocalIsAlphaNumeric(
			word	ch);
This routine returns *true* if the passed character is alphanumeric.

**Include:** localize.h

----------
#### LocalIsControl()
	Boolean	LocalIsControl(
			word	ch);
This routine returns *true* if the passed character is a control character.

**Include:** localize.h

----------
#### LocalIsDateChar()
	Boolean	LocalIsDateChar(
			word	ch);
This routine returns *true* if the passed character could be part of a date or 
time.

**Include:** localize.h

----------
#### LocalIsDigit()
	Boolean	LocalIsDigit(
			word	ch);
This routine returns *true* if the passed character is a decimal digit.

**Include:** localize.h

----------
#### LocalIsDosChar()
	Boolean	LocalIsDosChar(
			word	ch);
This routine returns *true* if the passed character is part of the DOS character 
set.

**Include:** localize.h

----------
#### LocalIsGraphic()
	Boolean	LocalIsGraphic(
			word	ch);
This routine returns true if the passed character is displayable.

**Include:** localize.h

----------
#### LocalIsHexDigit()
	Boolean	LocalIsHexDigit(
			word	ch);
This routine returns *true* if the passed character is a hexadecimal digit.

**Include:** localize.h

----------
#### LocalIsLower()
	Boolean	LocalIsLower(
			word	ch);
This routine returns *true* if the passed character is a lower case alphabetic 
character.

**Include:** localize.h

----------
##### LocalIsNumChar()
	Boolean	LocalIsNumChar(
			word	ch);
This routine returns *true* if the passed character is a number or part of the 
number format.

**Include:** localize.h

----------
#### LocalIsPrintable()
	Boolean	LocalIsPrintable(
			word	ch);
This routine returns *true* if the passed character is printable (i.e. takes up a 
space when printing).

**Include:** localize.h

----------
#### LocalIsPunctuation()
	Boolean	LocalIsPunctuation(
			word	ch);
This routine returns *true* if the passed character is a punctuation mark.

**Include:** localize.h

----------
#### LocalIsSpace()
	Boolean	LocalIsSpace(
			word	ch);
This routine returns *true* if the passed character is whitespace.

**Include:** localize.h

----------
#### LocalIsSymbol()
	Boolean	LocalIsSymbol(
			word	ch);
This routine returns *true* if the passed character is a symbol.

**Include:** localize.h

----------
#### LocalIsTimeChar()
	Boolean	LocalIsTimeChar(
			word	ch);
This routine returns *true* if the passed character is a number or part of the 
user's time format.

**Include:** localize.h

----------
#### LocalIsUpper()
	Boolean	LocalIsUpper(
			word	ch);
This routine returns *true* if the passed character is an upper case alphabetic 
character.

**Include:** localize.h

----------
#### LocalLexicalValue()
	word	LocalLexicalValue(
			word	ch);
This routine returns the passed character's lexical value, useful when trying 
to sort strings alphabetically.

**Include:** localize.h

----------
#### LocalLexicalValueNoCase()
	word	LocalLexicalValueNoCase(
			word	ch);
This routine returns the passed character's case-insensitive lexical value, 
useful when trying to sort strings alphabetically.

**Include:** localize.h

----------
#### LocalParseDateTime()
	Boolean	LocalParseDateTime(
			const char *			str,
			DateTimeFormat 			format,
			TimerDateAndTime *		dateTime);
This routine takes a string describing a date or time (e.g. "9:37") and parses 
it using the passed format.

**Include:** localize.h

----------
#### LocalSetCurrencyFormat()
	void	LocalSetCurrencyFormat(
			const LocalCurrencyFormat *		buf,
			const char *					symbol);
This routine changes the stored preferred currency format.

**Include:** localize.h

----------
#### LocalSetDateTimeFormat()
	void	LocalSetDateTimeFormat(
			const char *		str,
			DateTimeFormat 		format);
This routine changes the stored preferred time and date format.

**Include:** localize.h

----------
#### LocalSetDefaultPrintSizes()
	void	LocalSetDefaultPrintSizes(
			const DefaultPrintSizes *			sizes);
This routine changes the stored preferred default page and document sizes.

**Include:** localize.h

----------
#### LocalSetMeasurementType()
	void	LocalSetMeasurementType(
			MeasurementTypes meas);
This routine changes the stored preferred measurement type.

**Include:** localize.h

----------
#### LocalSetNumericFormat()
	void	LocalSetNumericFormat(
			const LocalNumericFormat *			buf);
This routine changes the stored preferred number format.

**Include:** localize.h

----------
#### LocalSetQuotes()
	void	LocalSetQuotes(
			const LocalQuotes *		quotes);
This routine changes the stored preferred quote marks.

**Include:** localize.h

----------
#### LocalStringLength()
	word	LocalStringLength(
			const char *		str);
This routine returns the length (in characters) of a null-terminated string 
(not counting the null), even for multibyte character sets.

**Include:** localize.h

----------
#### LocalStringSize()
	word	LocalStringSize(
			const char *		str);
This routine returns the size (in bytes) of a null-terminated string.

**Include:** localize.h

----------
#### LocalUpcaseChar()
	word	LocalUpcaseChar(
			word	ch);
This routine returns the upper case equivalent, if any, of the passed 
character.

**Include:** localize.h

----------
#### LocalUpcaseString()
	void	LocalUpcaseString(
			char *	str,
			word	size);
This routine converts the passed string to its all upper case equivalent.

**Include:** localize.h

[Routines G-G](rroutg_g.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Routines M-P](rroutm_p.md)