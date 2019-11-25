## 3.3 Routines G-G
----------
#### GCNListAdd()
	Boolean	GCNListAdd(
			optr			OD,			/* optr to add to list */
			ManufacturerID	manufID,	/* manufacturer ID of list */
			word			listType);	/* list type */
This routine adds an object pointer (optr) to a GCN list interested in a 
particular change. The routine must be passed the optr to add, along with the 
*manufID* and the type of the list to add it to. If no list of the specified 
manufacturer and type currently exists, a new list will be created.

This routine will return *true* if the optr was successfully added to the GCN list 
and *false* if the optr could not be added. An optr cannot be added to a GCN list 
if it currently exists on that list.

**Include:** gcnlist.goh

----------
#### GCNListAddHandles()
	Boolean	GCNListAddHandles(
			MemHandle			mh,			/* handle of object to add */
			ChunkHandle			ch,			/* chunk of object to add */
			ManufacturerIDs		manufID,	/* manufacturer ID of list */
			word				listType);	/* list type */
This routine is exactly the same as **GCNListAdd()**, except it takes the 
memory and chunk handles of the object rather than a complete optr.

**Include:** gcnlist.goh

----------
#### GCNListAddToBlock()
	Boolean	GCNListAddToBlock(
			optr			OD,			/* optr of list to add */
			ManufacturerID	manufID,	/* manufacturer ID of list */
			word			listType,	/* list type */
			MemHandle		mh,			/* handle of block holding list */
			ChunkHandle		listOfLists);/* chunk of list of lists
										  * in block */
This routine adds a new GCN list to a block containing the GCN lists. Pass it 
the optr of the chunk containing the new GCN list as well as the list's type 
and manufacturer ID. Pass also the memory handle and chunk handle of the 
chunk containing the GCN "list of lists" which will manage the new list.

This routine returns true of the new optr is added to the GCN mechanism, 
false if it could not be added (if it was already there).

**Warnings:** This routine may resize chunks in the block, so you should dereference any 
pointers after calling this routine.

**Include:** gcnlist.goh

----------
#### GCNListCreateBlock()
	ChunkHandle GCNListCreateBlock(
			MemHandle mh);		/* handle of the locked LMem block */
This routine creates a list of lists for the GCN mechanism. It is rarely, if ever, 
called by applications. Pass it the handle of the locked LMem block in which 
the list should be created.

**Include:** gcnlist.goh

----------
#### GCNListDestroyBlock()
	void	GCNListDestroyBlock(
			MemHandle		mh,				/* handle of locked block to
											 * be destroyed */
			ChunkHandle		listOfLists);	/* chunk of list of lists */
This routine destroys a GCN list of lists and all the GCN lists associated with 
it. Pass it the handle of the locked LMem block containing the lists as well as 
the chunk handle of the chunk containing the list of lists.

**Include:** gcnlist.goh

----------
#### GCNListDestroyList()
	void	GCNListDestroyList(
			optr	list);		/* optr of the GCN list to be destroyed */
This routine destroys the specified GCN list.

**Include:** gcnlist.goh

----------
#### GCNListRelocateBlock()
	void	GCNListRelocateBlock(
			MemHandle		mh,				/* handle of locked LMem block
											 * containing GCN lists */
			ChunkHandle		listOfLists,	/* chunk of list of lists */
			MemHandle		relocBlock);	/* handle of block containing
											 * relocation information */
This routine relocates the GCN list of lists in the specified block, updating all 
the optrs stored therein.

**Warnings:** This routine can resize and/or move the LMem block, so you should 
dereference pointers after calling it.

**Include:** gcnlist.goh

----------
#### GCNListRemove()
	Boolean	GCNListRemove(
			optr			OD,			/* the optr to be removed */
			ManufacturerID	manufID,	/* manufacturer ID of the list */
			word			listType);	/* list type */
This routine removes the passed optr from the specified GCN list. The routine 
must be passed the optr to remove along with the manufacturer ID and list 
type of the list to remove it from.

This routine will return *true* if the optr was successfully removed from the 
GCN list and *false* if the optr could not be found on the GCN list and therefore 
could not be removed.

**Include:** gcnlist.goh

----------
#### GCNListRemoveFromBlock()
	Boolean	GCNListRemoveFromBlock(
			optr			OD,				/* optr of GCN list to remove */
			ManufacturerID	manufID,		/* manufacturer of list to remove */
			word			listType,		/* type of list being removed */
			MemHandle		mh,				/* handle of locked LMem block
											 * containing the list of lists */
			ChunkHandle		listOfLists);	/* chunk of list of lists */
This routine removes a GCN list from a GCN list block and from the list of lists 
therein.

**Include:** gcnlist.goh

----------
#### GCNListRemoveHandles()
	Boolean	GCNListRemoveHandles(
			MemHandle			mh,
			ChunkHandle			ch,
			ManufacturerID		manufID,
			word				listType);
This routine is exactly the same as **GCNListRemove()**, except it specifies 
the object to be removed via handles rather than an optr.

**Include:** gcnlist.goh

**See Also:** GCNListRemove()

----------
#### GCNListSend()
	word	GCNListSend(
			ManufacturerID	manufID,			/* manufacturer of list */
			word			listType,			/* notification type */
			EventHandle		event,				/* event to be sent to list */
			MemHandle		dataBlock,			/* data block, if any */
			word			gcnListSendFlags);	/* GCNListSendFlags */
This routine sends a message to all objects in the specified GCN list. The 
message is specified in *event*, and the list is specified in *manufID* and 
*listType*. The message will be sent asynchronously (some time after the 
change has occurred) by the message queue. 

The *dataBlock* parameter contains the memory handle of an extra data block 
to be sent with the notification, if any; this block should also be specified in 
the classed event. If no data block is required, pass a NullHandle. If a data 
block with a reference cound is used, increment the reference count by one 
before calling this routine; this routine decrements the count and frees the 
block if the count reaches zero.

The *gcnListSendFlags* parameter is of type **GCNListSendFlags**, which has 
only one meaningful flag for this routine:

GCNLSF_SET_STATUS  
Causes the message sent to the GCN list to be set as the lists 
"status." The list's status message is then sent to any object 
adding itself to the list at a later time. If this flag is set, the 
event handle in event will be returned by the routine. If this 
flag is not set, the return value will be the number of messages 
sent out.

**Include:** gcnlist.goh

----------
#### GCNListSendToBlock()
	word	GCNListSendToBlock(
			ManufacturerID		manufID,	/* manufacturer id of list */
			word				listType,	/* notification type */
			EventHandle			event,		/* event to be sent to list */
			MemHandle			dataBlock,	/* data block, if any */
			MemHandle			mh,			/* handle of locked LMem block
											 * containing GCN list of lists */
			ChunkHandle			listOfLists,/* chunk of list of lists */
			GCNListSendFlags	flags);		/* GCNListSendFlags */
This routine sends the specified *event* to the specified list, just as 
**GCNListSend()**. **GCNListSentToBlock()**, however, specifies a particular 
instance of the GCN list by specifying the appropriate list of lists in *mh* and 
*listOfLists*. Other parameters and return values are identical to 
**GCNListSend()**.

**See Also:** GCNListSend()

**Include:** gcnlist.goh

----------
#### GCNListSendToList()
	void	GCNListSendToList(
			optr				list,		/* optr of GCN list */
			EventHandle			event,		/* event to send to list */
			MemHandle			dataBlock,	/* handle of data block, if any */
			GCNListSendFlags	flags);		/* GCNListSendFlags */
This routine sends the specified *event* to the specified GCN *list*. The list is 
specified explicitly by optr as opposed to by manufacturer ID and type. The 
event will be sent via the proper queues to all objects registered on the list. 
After the notification is handled by all notified objects, the event will be freed, 
as will the data block passed. (If no data block, pass NullHandle in 
*dataBlock*)

The *flags* parameter can have one flag, GCNLSF_SET_STATUS. If this flag is 
set, the event passed will be set as the list's status message.

**Include:** gcnlist.goh

**See Also:** GCNListSend()

----------
#### GCNListSendToListHandles()
	void	GCNListSendToListHandles(
			MemHandle			mh,			/* handle of list's block */
			ChunkHandle			ch,			/* chunk of list */
			EventHandle			event,		/* event to send to list */
			MemHandle			dataBlock,	/* handle of data block, if any */
			GCNListSendFlags	flags);		/* GCNListSendFlags */
This routine is exactly the same as **GCNListSendToList()**; the list is 
specified not by optr, however, but by a combination of its global and chunk 
handles.

**See Also:** GCNListSendToList()

**Include:** gcnlist.goh

----------
#### GCNListUnRelocateBlock()
	Boolean	GCNListUnRelocateBlock(
			MemHandle	mh,				/* handle of the locked lmem block
										 * containing the list of lists */
			ChunkHandle	listOfLists,	/* chunk of the list of lists */
			MemHandle	relocBlock);	/* handle of block containing
										 * relocation/unrelocation info */
This routine unrelocates the specified list of lists, updating all the optrs 
according to the information in *relocBlock*. This routine is rarely, if ever, used 
by applications; it is used primarily by the UI when shutting down to a state 
file.

It returns *true* if the specified list of lists has no lists saved to state and 
therefore is simply destroyed. The return value is *false* if the list of lists is 
saved to the state file normally.

**Include:** gcnlist.goh

----------
#### GenCopyChunk()
	word	GenCopyChunk(
			MemHandle		destBlock,	/* handle of locked LMem block into
										 * which chunk will be copied */
			MemHandle		blk,		/* handle of locked source LMem block */
			ChunkHandle		chnk,		/* chunk handle of chunk to be copied */
			word			flags);		/* CompChildFlags */
This is a utility routine that copies one LMem chunk into a newly created 
chunk. The routine will allocate the new chunk in the block passed in 
*destBlock* and will return the chunk handle of the new chunk. It is used 
primarily by the UI to duplicate generic object chunks.

The source chunk is specified by the global handle *blk* and the chunk handle 
*chnk*. The flags parameter contains a record of **CompChildFlags**, of which 
only the CCF_MARK_DIRTY flag is meaningful. If this flag is set, the new 
chunk will be marked dirty.

**Warnings:** This routine may resize and/or move chunks and blocks, so you must 
dereference pointers after calling it.

**Include:** genC.goh

----------
#### GenFindObjectInTree()
	optr	GenFindObjectInTree(
			optr	startObject,	/* optr of object at which to start search */
			dword	childTable);	/* pointer to table of bytes, each indicating
									 * the position of the child at the given
									 * level; -1 is the end of the table */
This utility routine finds the object having the optr *startObject* in the generic 
tree. Applications will not likely need this routine.

The *childTable* parameter points to a table of bytes, each byte representing 
the child number to be found at each level. The first byte indicates the child 
of *startObject* to get; the second byte indicates the child to get at the next 
level; the third byte indicates the child to get at the next level, and so on. A 
byte of -1 indicates the end of the table. The object found will be returned.

**Include:** genC.goh

----------
#### GenInsertChild()
	void	GenInsertChild(
			MemHandle		mh,					/* handle of parent */
			ChunkHandle		chnk,				/* chunk of parent */
			optr			childToAdd,			/* optr of new child */
			optr			referenceChild,		/* optr of reference child */
			word			flags);				/* CompChildFlags */
This utility routine adds a child object to a composite object. It is used almost 
exclusively by the UI for generic objects - applications will typically use 
MSG_GEN_ADD_CHILD.

**See Also:** MSG_GEN_ADD_CHILD

**Warnings:** This routine may move or resize chunks and/or object blocks; therefore, you 
must dereference pointers after calling it.

**Include:** genC.goh

----------
#### GenProcessAction()
	void	GenProcessAction(
			MemHandle		mh,		/* handle of object calling the routine */
			ChunkHandle		chnk,	/* chunk of object calling the routine */
			word			mthd,		/* message to send to actionOptr */
			word			dataCX,		/* data to pass in CX register */
			word			dataDX,		/* data to pass in DX register */
			word			dataBP,		/* data to pass in BP register */
			optr			actionOptr);/* object to receive mthd */
This utility routine sends the action message specified in *mthd* to the action 
object specified in *actionOptr*. It is typically used by the UI and generic 
objects and corresponds to the **GenClass** message 
MSG_GEN_OUTPUT_ACTION.

**Warnings:** This routine may move or resize chunks and/or object blocks; therefore, you 
must dereference pointers after calling it.

**See Also:** MSG_GEN_OUTPUT_ACTION

**Include:** genC.goh

----------
#### GenProcessGenAttrsAfterAction()
	void	GenProcessGenAttrsAfterAction(
			MemHandle		mh,		/* handle of object calling the routine */
			ChunkHandle		chnk);	/* chunk of object calling the routine */
This utility routine processes various attributes for a generic object after the 
object's action message has been sent. It is used almost exclusively by the 
generic UI after MSG_GEN_OUTPUT_ACTION or **GenProcessAction()**.

**Warnings:** This routine may move or resize chunks and/or object blocks; therefore, you 
must dereference pointers after calling it.

**Include:** genC.goh

----------
#### GenProcessGenAttrsBeforeAction()
	void	GenProcessGenAttrsBeforeAction(
			MemHandle	mh,		/* handle of object calling the routine */
			ChunkHandle	chnk);	/* chunk of object calling the routine */
This utility routine processes various attributes for a generic object before 
the object's action message has been sent. It is used almost exclusively by the 
generic UI before MSG_GEN_OUTPUT_ACTION or **GenProcessAction()**.

Warnings:	This routine may move or resize chunks and/or object blocks; therefore, you 
must dereference pointers after calling it.

**Include:** genC.goh

----------
#### GenProcessUndoGetFile()
	VMFileHandle GenProcessUndoGetFile();
This routine returns the handle of the file that holds the process' undo 
information.

**Include:** Objects/gProcC.goh

----------
#### GenProcessUndoCheckIfIgnoring()
	Boolean GenProcessUndoCheckIfIgnoring();
This routine returns *true* if the process is currently ignoring actions.

**Include:** Objects/gProcC.goh

----------
#### GenRemoveDownwardLink()
	void	GenRemoveDownwardLink(
			MemHandle	mh,			/* handle of calling object */
			ChunkHandle	chnk,		/* chunk of calling object */
			word		flags);		/* CompChildFlags */
This utility routine removes a child from the generic tree, preserving the 
child's upward link and usability flags. It is called primarily by the generic 
UI and is rarely used by applications. The flags parameter specifies whether 
the object linkage should be marked dirty by passing the CCF_MARK_DIRTY 
flag.

**Warnings:** This routine may move or resize chunks and/or object blocks; therefore, you 
must dereference pointers after calling it.

**Include:** genC.goh

----------
#### GenSetUpwardLink()
	void	GenSetUpwardLink(
			MemHandle		mh,			/* handle of calling object */
			ChunkHandle		chnk,		/* chunk of calling object */
			optr			parent);	/* optr of calling object's parent */
This utility routine converts the child/parent link to an upward-only link. 
Pass the handle and chunk of the locked child object and the optr of the 
parent composite.

**Include:** genC.goh

----------
#### GeodeAllocQueue()
	QueueHandle GeodeAllocQueue();
This routine allocates an event queue which can then be attached to a thread 
with **ThreadAttachToQueue()**. It returns the queue's handle if one is 
allocated; it will return zero otherwise. This routine is used outside the 
kernel only in exceptional circumstances.

**Be Sure To:** You must free the queue when you are done with it; use 
**GeodeFreeQueue()**.

**Include:** geode.h

----------
#### GeodeDuplicateResource()
	MemHandle GeodeDuplicateResource(
			MemHandle mh);		/* handle of geode resource to duplicate */
This routine reads a resource from a geode into a newly-allocated block 
(allocated by this routine). Any relocations on the resource to itself are 
adjusted to be the duplicated block. The handle of the duplicated block is 
returned.

**Include:** resource.h

----------
#### GeodeFind()
	GeodeHandle GeodeFind(
			const char	* name,			/* geode's permanent name */
			word		numChars,		/* number of characters to match:
										 * 8 for name, 12 for name.ext */
			GeodeAttrs	attrMatch,		/* GeodeAttrs that must be set */
			GeodeAttrs	attrNoMatch);	/* GeodeAttrs that must be off */
This routine finds a geode given its permanent name, returning the geode 
handle if found. If the geode can not be found, a null handle will be returned. 
Pass it the following:

*name* - A pointer to the null-terminated permanent name of the geode.

*numChars* - The number of characters to match before returning. Pass 
GEODE_NAME_SIZE to match the permanent name, 
(GEODE_NAME_SIZE + GEODE_EXT_SIZE) to match the name 
and extension.

*attrMatch* - A record of **GeodeAttrs** the subject geode must have set for a 
positive match.

*attrNoMatch* - A record of **GeodeAttrs** the subject geode must have cleared 
for a positive match.

**Include:** geode.h

----------
#### GeodeFindResource()
	word	GeodeFindResource(
			FileHandle	file,			/* geode's executable file */
			word		resNum,			/* resource number to find */
			word		resOffset,		/* offset to resource */
			dword		* base);		/* pointer to second return value */
This routine locates a resource within a geode's executable (**.geo**) file. It 
returns the size of the resource as well as the base position of the first byte of 
the resource in the file (pointed to by *base*). Pass the following:

*file* - The file handle of the geode's executable file.

*resNum* - The number of the resource to be found.

*resOffset* - The offset within the resource at which to position the file's 
read/write position.

*base* - A pointer to a dword value to be filled in by the routine. This 
value will be the base offset from the beginning of the file to the 
first byte of the resource.

**Structures:** A geode's executable file is laid out as shown below.

	0:	Geode file header
	1:	Imported Library Table
	2:	Exported Routine Table
	3:	Resource Size Table
	4:	Resource Position Table
	5:	Relocation Table Size Table
	6:	Allocation Flags Table
	7+:	application resources

**Include:** geode.h

----------
#### GeodeFlushQueue()
	void	GeodeFlushQueue(
			QueueHandle		source,		/* source queue to flush */
			QueueHandle		dest,		/* queue to hold flushed events */
			optr			obj			/* object to handle flushed events */
			MessageFlags	flags);		/* MF_INSERT_AT_FRONT or zero */
This routine flushes all events from one event queue into another, 
synchronously. Pass it the following:

*source* - The queue handle of the source queue (the one to be emptied).

*dest* - The queue handle of the destination queue that will receive the 
flushed events.

*obj* - The object that will handle flushed events that were destined 
for the process owning the source queue. If the process owning 
the destination queue should be used, pass the destination 
queue handle in the handle portion of the optr and a null chunk 
handle.

*flags* - A record of **MessageFlags**. The only meaningful flag for this 
routine is MF_INSERT_AT_FRONT, which should be set to flush 
source queue's events to the front of the destination queue. If 
this flag is not passed, events will be appended to the queue.

**Include:** geode.h

----------
#### GeodeFreeQueue()
	void	GeodeFreeQueue(
			QueueHandle		qh);		/* handle of queue being freed */
This routine frees an event queue allocated with **GeodeAllocQueue()**. Any 
events still on the queue will be flushed as with **GeodeFlushQueue()**. You 
must pass the handle of the queue to be freed.

**Include:** geode.h

----------
#### GeodeFreeDriver()
	void	GeodeFreeDriver(
			GeodeHandle		gh);		/* handle of the driver */
This routine frees a driver geode that had been loaded with 
**GeodeUseDriver()**. Pass it the geode handle of the driver as returned by 
that routine.

**Include:** driver.h

----------
#### GeodeFreeLibrary()
	void	GeodeFreeLibrary(
			GeodeHandle		gh);		/* handle of the library */
This routine frees a library geode that had been loaded with 
**GeodeUseLibrary()**. Pass it the geode handle of the library.

**Include:** library.h

----------
#### GeodeGetAppObject()
	optr	GeodeGetAppObject(
			GeodeHandle		gh);	/* handle of the application geode */
This routine returns the optr of the specified geode's GenApplication object. 
The geode should be an application. Pass zero to get the optr of the caller's 
application object.

**Include:** geode.h

----------
#### GeodeGetCodeProcessHandle()
	GeodeHandle GeodeGetCodeProcessHandle();
This routine returns the geode handle of the geode that owns the block in 
which the code which calls this routine resides.

**Include:** geode.h

----------
#### GeodeGetDefaultDriver()
	GeodeHandle GeodeGetDefaultDriver(
			GeodeDefaultDriverType	type);	/* type of default driver to get */
This routine returns the default driver's geode handle for the type passed. 
The type must be one of the values of **GeodeDefaultDriverType**, which 
includes GDDT_FILE_SYSTEM (0)  
GDDT_KEYBOARD (2)  
GDDT_MOUSE (4)  
GDDT_VIDEO (6)  
GDDT_MEMORY_VIDEO (8)  
GDDT_POWER_MANAGEMENT(10)  
GDDT_TASK(12).

**Include:** driver.h

----------
#### GeodeGetInfo()
	word	GeodeGetInfo(
			GeodeHandle			gh,			/* handle of the subject geode */
			GeodeGetInfoType	info,		/* type of information to return */
			void	 			* buf);		/* buffer to contain returned info */
This routine returns information about the specified geode. The geode must 
be loaded already. The meaning of the returned word depends on the value 
passed in *info*; the **GeodeGetInfoType** is shown below. Pass the following:

*gh* - The geode handle of the geode.

*info* - The type of information requested; this should be one of the 
values listed below.

*buf* - A pointer to a locked or fixed buffer which will contain returned 
information for various types requested.

**GeodeGetInfoType** has the following enumerations (only one may be 
requested at a time):

GGIT_ATTRIBUTES  
Get the geode's attributes. The return value will be a record of 
**GeodeAttrs** corresponding to those attributes set for the 
geode. Pass a null buffer pointer.

GGIT_TYPE  
Get the type of the geode. The returned value will be a value of 
**GeosFileType** indicating the type of file storing the geode. 
Pass a null buffer pointer.

GGIT_GEODE_RELEASE  
Get the release number of the geode. The returned word will be 
the size of the buffer pointed to by *buf*, and the buffer will 
contain the **ReleaseNumber** structure of the geode.

 GGIT_GEODE_PROTOCOL  
Get the protocol level of the geode. The returned word will be 
the size of the buffer pointed to by *buf*, and the buffer will 
contain the **ProtocolNumber** structure of the geode.

 GGIT_TOKEN_ID  
Get the token identifier of the geode. The returned word will be 
the size of the buffer pointed to by *buf*, and the buffer will 
contain a **GeodeToken** structure containing the token 
characters and token ID of the geode's token.

 GGIT_PERM_NAME_AND_EXT  
Get the permanent name of the geode, with the extension 
characters. The returned word will be the size of the buffer 
pointed to by *buf*, and the buffer will contain a null-terminated 
character string representing the geode's permanent name (as 
set in its geode parameters file). Note that the buffer must be 
at least 13 bytes.

GGIT_PERM_NAME_ONLY  
Get the permanent name of the geode without the extension 
characters. The returned word will be the size of the buffer 
pointed to by buf, and the buffer will contain the 
null-terminated character string representing the geode's 
permanent name. The buffer must be at least nine bytes.

**Include:** geode.h

----------
#### GeodeGetOptrNS()
	optr	GeodeGetOptrNS(
			optr	obj);
This routine unrelocates an optr, changing the virtual-segment handle to an 
actual global handle.

**Include:** resource.h

----------
#### GeodeGetProcessHandle()
	GeodeHandle GeodeGetProcessHandle();
This routine returns the geode handle of the current executing process (i.e. 
the owner of the current running thread). Use it when you need to pass your 
application's geode handle or Process object's handle to a routine or message.

**Include:** geode.h

----------
#### GeodeGetUIData()
	word	GeodeGetUIData(
			GeodeHandle		gh);
**Include:** geode.h

----------
#### GeodeInfoDriver()
	DriverInfoStruct  * GeodeInfoDriver(
			GeodeHandle gh); /* handle of the driver to get information about */
This routine returns information about the specified driver geode. Pass the 
geode handle of the driver as returned by **GeodeUseDriver()**. It returns a 
pointer to a **DriverInfoStruct** structure, shown below.

	typedef struct {
		void				(*DIS_strategy)();
		DriverAttrs			DIS_driverAttributes;
		DriverType			DIS_driverType;
	} DriverInfoStruct;

For full information on this structure, see the **DriverInfoStruct** reference 
entry.

**Include:** driver.h

----------
#### GeodeInfoQueue()
	word	GeodeInfoQueue(
			QueueHandle qh);			/* queue to query */
This routine returns information about a specific event queue. Pass the 
handle of the queue; for information about the current process' queue, pass a 
null handle. This routine returns the number of events (or messages) 
currently in the queue.

**Include:** geode.h

----------
#### GeodeLoad()
	GeodeHandle GeodeLoad(
			const char *		name,			/* file name of geode */
			GeodeAttrs			attrMatch,		/* GeodeAttrs that must be set */
			GeodeAttrs			attrNoMatch,	/* GeodeAttrs that must be clear */
			word				priority,		/* priority of the loaded geode */
			dword				appInfo,		/* special load information */
			GeodeLoadError *	err);			/* returned error value */
This routine loads the specified geode from the given file and then executes 
the geode based on its type. It returns the geode handle of the loaded geode 
if successful; if unsuccessful, the returned value will be NullHandle and the 
*err* pointer will point to an error value. Pass this routine the following:

*name* - A pointer to the name of the geode's file. This is a 
null-terminated character string that represents the full path 
of the file (or a path relative to the current working directory).

*attrMatch* - A record of **GeodeAttrs** that must be set in the specified geode 
for the load to be successful.

*attrNoMatch* - A record of **GeodeAttrs** that must be cleared in the specified 
geode for the load to be successful. (That is, each bit which is 
set in *attrNoMatch* must be clear in the geode's **GeodeAttrs** 
field.)

*priority* - If the subject geode is a process, this is the priority at which its 
process thread will run.

*appInfo* - Two words of data to be passed directly to the loaded geode. For 
libraries and drivers, this should be a far pointer to a 
null-terminated string of parameters.

*err* - A pointer to an empty **GeodeLoadError** which will hold any 
returned error values.

**Warnings:** If you load a geode dynamically with **GeodeLoad()**, you must be sure to free 
it when you are done with **GeodeFree()**.

**Include:** geode.h

**See Also:** UserLoadApplication() 

----------
#### GeodeLoadDGroup
	void	GeodeLoadDGroup(
			MemHandle		mh);
This routine forces the **dgroup** segment into the data-segment register.

**Include:** resource.h

----------
#### GeodePrivAlloc()
	word	GeodePrivAlloc(
			GeodeHandle		gh,			/* handle of the owner of the
										 * newly-allocated private data */
			word			numWords);	/* number of words to allocate */
This routine allocates a string of contiguous words in all geodes' private data 
areas; each set of words will be owned by the geode specified in *gh*. The data 
allocated can be accessed with **GeodePrivWrite()** and **GeodePrivRead()** 
and must be freed with **GeodePrivFree()**. The return value will be the 
offset to the start of the allocated range, or zero if the routine could not 
allocate the space.

Each geode has a block of private data the is accessed using the 
**GeodePriv...()** routines. A specific geode's private data block is expanded 
only when a valid **GeodePrivWrite()** is performed for the geode. Space is 
"allocated" in the data blocks of all geodes (loaded or yet-to-be loaded) 
simultaneously via a call to **GeodePrivAlloc()**. Data that have never been 
written are returned as all zeros.

**Include:** geode.h

----------
#### GeodePrivFree()
	void	GeodePrivFree(
			word	offset,		/* offset returned by GeodePrivAlloc() */
			word	numWords);	/* number of words to free */
This routine frees a group of contiguous words from all geodes' private data 
areas. The space must previously have been allocated with 
**GeodePrivAlloc()**. Pass the offset to the words as returned by 
**GeodePrivAlloc()** as well as the number of words to be freed.

**Include:** geode.h

----------
#### GeodePrivRead()
	void	GeodePrivRead(
			GeodeHandle	gh,			/* handle of owner of private data */
			word		offset,		/* offset returned by
									 * GeodePrivAlloc() */
			word		numWords,	/* number of words to read */
			word		* dest);	/* pointer to buffer into which data
									 * will be copied */
This routine reads a number of words from the geode's private data area. 
Pass the following:

*gh* - The geode handle of the owner of the private data to be read.

*offset* - The offset to the private data as returned by 
GeodePrivAlloc().

*numWords* - The number of words to read.

*dest* - A pointer to a locked or fixed buffer into which the words should 
be read. It must be at least numWords words long.

**Include:** geode.h

----------
#### GeodePrivWrite()
	void	GeodePrivWrite(
			GeodeHandle	gh,			/* handle of owner of private data */
			word		offset,		/* offset returned by
									 * GeodePrivAlloc() */
			word		numWords,	/* number of words to be written */
			word		* src);		/* buffer containing data */
This routine writes a number of words into a geode's private data area. The 
area being written must have been allocated previously with 
**GeodePrivAlloc()**. Pass the following:

*gh* - The geode handle of the owner of the private data space.

*offset* - The offset to begin writing to, as returned by 
**GeodePrivAlloc()**.

*numWords* - The number of words to be written. This should be no more 
than had been previously allocated.

*src* - A pointer to the locked or fixed buffer containing the data to be 
written.

**Include:** geode.h

----------
#### GeodeSetDefaultDriver()
	void	GeodeSetDefaultDriver(
			GeodeDefaultDriverType	type,	/* type of default driver to set */
			GeodeHandle				gh);	/* driver to set as the default */
This routine sets the default driver for the indicated driver type. Pass the 
type of default driver in *type* and the handle of the driver in *gh*. The type must 
be a value of **GeodeDefaultDriverType**, which includes  
GDDT_FILE_SYSTEM (0)  
GDDT_KEYBOARD (2)  
GDDT_MOUSE (4)  
GDDT_VIDEO (6)  
GDDT_MEMORY_VIDEO (8)  
GDDT_POWER_MANAGEMENT(10)  
GDDT_TASK(12)

**Include:** driver.h

----------
#### GeodeSetUIData()
	void	GeodeSetUIData(
			GeodeHandle		gh,
			word			data)

----------
#### GeodeUseDriver()
	GeodeHandle GeodeUseDriver(
			const	char	* name,			/* file name of driver to load */
			word			protoMajor,		/* expected major protocol */
			word			protoMinor,		/* expected minor protocol */
			GeodeLoadError	* err);			/* pointer to returned error */
This routine dynamically loads a driver geode given the driver's file name. It 
returns the geode handle of the driver if successful; if unsuccessful, it returns 
an error code of type **GeodeLoadError** pointed to by *err*. Pass this routine 
the following:

*name* - A pointer to the driver's null-terminated full path and file 
name.

*protoMajor* - The expected major protocol of the driver. If zero, any protocol 
is acceptable.

*protoMinor* - The expected minor protocol of the driver.

*err* - A pointer to a **GeodeLoadError** in which any error values 
will be returned.

**Tips and Tricks:** It is much easier to automatically load the drivers you need by noting them 
in your geode parameters file.

**Be Sure To:** If you use **GeodeUseDriver()** to dynamically load a driver, you must also 
use **GeodeFreeDriver()** to free it when you are done using it.

**Include:** driver.h

----------
#### GeodeUseLibrary()
	GeodeHandle GeodeUseLibrary(
			const char *		name,		/* file name of library to load */
			word				protoMajor,	/* expected major protocol */
			word				protoMinor,	/* expected minor protocol */
			GeodeLoadError *	err);		/* pointer to returned error */
This routine dynamically loads a library geode when given the library's file 
name. (The library must be in the thread's working directory.) It returns the 
geode handle of the loaded library if successful; if unsuccessful, it returns an 
error code (**GeodeLoadError**) pointed to by *err*. Pass this routine the 
following parameters:

*name* - A pointer to the library's null-terminated file name.

*protoMajor* - The expected major protocol of the library. If zero, any protocol 
is acceptable.

*protoMinor* - The expected minor protocol of the library.

*err* - A pointer to a **GeodeLoadError** which will contain any 
returned error values.

**Be Sure To:** If you dynamically load a library with **GeodeUseLibrary()**, you must 
manually free it when finished, with **GeodeFreeLibrary()**.

**Include:** library.h

----------
#### GeoFree()
	void	* GeoFree(
			void			* blockPtr,		/* address of memory to free */
			GeodeHandle		geodeHan);		/* owner of block to be used */
The routine **malloc()** can free only memory in the malloc-block belonging to 
the calling geode. If you want to free memory in another geode's malloc-block, 
call **GeoFree()**. Passing a null **GeodeHandle** will make **GeoMalloc()** act 
on memory in the calling geode's malloc-block.

**Include:** geode.h

**Warnings:** Pass exactly the same address as the one returned to you when you allocated 
the memory. If you pass a different address, **GeoFree()** will take 
unpredictable actions, including possibly erasing other memory or crashing 
the system.

**See Also:** free()

----------
#### GeoMalloc()
	void	* GeoMalloc(
			size_t			blockSize,		/* # of bytes to allocate*/
			GeodeHandle		geodeHan,		/* Owner of block to be used */
			word			zeroInit);		/* Zero-initialize memory? */
The routine **malloc()** automatically allocates memory in the malloc-block 
belonging to the calling geode. It does not zero-initialize the memory. If you 
want to zero-initialize the memory, or want to allocate it in another geode's 
malloc-block, call **GeoMalloc()**. Pass *true* (i.e., non-zero) in *zeroInit* to 
zero-initialize the memory.

Passing a null **GeodeHandle** will make **GeoMalloc()** allocate the memory 
in the calling geode's malloc-block. If *zeroInit* is true, the memory will be 
initialized to null bytes; otherwise, the memory will be left uninitialized.

**Include:** geode.h

**Warnings:** All memory allocated with **malloc()** is freed when GEOS shuts down.

**See Also:** malloc()

----------
#### GeoReAlloc()
	void	* GeoReAlloc(
			void			* blockPtr,		/* address of memory to resize */
			size_t			newSize,		/* New size in bytes */
			GeodeHandle		geodeHan);		/* Owner of block to be used */
The routine **realloc()** can resize only memory in the malloc-block belonging 
to the calling geode. If you want to resize memory in another geode's 
malloc-block, call **GeoReAlloc()**. Passing a null **GeodeHandle** will make 
GeoReAlloc() act on memory in the calling geode's malloc-block.

If the block is resized larger, the new memory will not be zero-initialized. 
Resizing a block smaller will never fail. If **GeoReAlloc()** fails, it will return 
a null pointer (zero). If you pass a *newSize* of zero, the passed block pointer 
is freed and the return pointer is a null pointer.

**Include:** geode.h

**Warnings:** Pass exactly the same address as the one returned to you when you allocated 
the memory. If you pass a different address, **GeoReAlloc()** will take 
unpredictable actions, including possibly erasing other memory or crashing 
the system.

**See Also:** realloc()

----------
#### GrApplyRotation()
	void	GrApplyRotation(
			GStateHandle		gstate,		/* GState to alter */
			WWFixedAsDWord		angle); 	/* degrees counterclockwise */
Apply a rotation to the GState's transformation matrix.

**Include:** graphics.h 

----------
#### GrApplyScale()
	void	GrApplyScale(
			GStateHandle		gstate,		/* GState to alter */
			WWFixedAsDWord		xScale,		/* new x scale factor */
			WWFixedAsDWord		yScale);	/* new y scale factor */
Apply a scale factor to the GState's transformation matrix.

**Include:** graphics.h 

----------
#### GrApplyTransform()
	void	GrApplyTransform(
			GStateHandle		gstate,		/* GState to draw to */
			const TransMatrix	*tm);		/* transformation matrix to apply */
Apply a transformation, expressed as a transformation matrix, to a GState's 
coordinate system.

**Include:** graphics.h 

----------
#### GrApplyTranslation()
	void	GrApplyTranslation(
			GStateHandle		gstate,			/* GState to alter */
			WWFixedAsDWord		xTrans,			/* translation in x */
			WWFixedAsDWord		yTrans);		/* translation in y */
Apply a translation to the GState.

**Include:** graphics.h 

----------
#### GrApplyTranslationDWord()
	void	GrApplyTranslationDWord(
			GStateHandle	gstate,			/* GState to alter */
			sdword			xTrans,			/* extended translation in x */
			sdword			yTrans);		/* extended translation in y */
Apply a 32-bit integer extended translation to the GState.

**Include:** graphics.h 

----------
#### GrBeginPath()
	void	GrBeginPath(
			GStateHandle		gstate,			/* GState to alter */
			PathCombineType		params);		/* path parameters */
Starts or alters the path associated with a GState. All graphics operations 
that are executed until **GrEndPath()** is called become part of the path.

Depending on the value of the *params* field, the new path may replace the old 
path, or may be combined with the old path by intersection or union.

**Include:** graphics.h 

----------
#### GrBeginUpdate()
	void 	GrBeginUpdate(
			GStateHandle gstate);			/* GState to draw to */
Called by an application to signal that it is about to begin updating the 
exposed region. This routine is normally called as part of a 
MSG_META_EXPOSED handler. Blanks out the invalid area.

**Include:** win.h

----------
#### GrBitBlt()
	void	GrBitBlt(
			GStateHandle	gstate,		/* GState to draw to */
			sword			sourceX,	/* original x origin */
			sword			sourceY,	/* original y origin */
			sword			destX,		/* new x origin */
			sword			destY,		/* new y origin */
			word			width,		/* width of area */
			word			height,		/* height of area */
			BLTMode			mode);		/* draw mode (see below) */
Transfer a bit-boundary block of pixels between two locations in video 
memory. This routine is useful for animation and other applications which 
involve moving a drawing around the screen.

**Structures:**  

	typedef enum /* word */ {
		BLTM_COPY, 				/* Leave source region alone */
		BLTM_MOVE, 				/* Clear & invalidate source rect */
		BLTM_CLEAR				/* Clear source rectangle */
	} BLTMode;

**Include:** graphics.h 

----------
#### GrBrushPolyline()
	void	GrBrushPolyline(
			GStateHandle	gstate,		/* GState to draw to */
			const Point		* points,	/* array of Point structures to draw */
			word			numPoints,	/* number of points in array */
			word			brushH,		/* brush height */
			word			brushW);	/* brush width */
Draw a brushed connected polyline. Note that this routine ignores the 
GState's line width, and instead uses a brush height and width, measured in 
pixels.

**Include:** graphics.h 

----------
#### GrCharMetrics()
	dword	GrCharMetrics(
			GStatehandle	gstate,		/* GState to get metrics for */
			GCM_info		info,		/* information to return */
			word			ch);		/* character of type Chars */
Returns metric information for a single character of a font. This information 
is used to determine the drawing bounds for a character. To find out how wide 
a character is (how much space to leave for it if drawing a line of text 
character-by-character), use **GrCharWidth()** instead.

**Structures:** 

	typedef enum {
		GCMI_MIN_X, 				/* return = value << 16 */
		GCMI_MIN_X_ROUNDED,			/* return = value */
		GCMI_MIN_Y, 				/* return = value << 16 */
		GCMI_MIN_Y_ROUNDED,			/* return = value << 16 */
		GCMI_MAX_X, 				/* return = value << 16 */
		GCMI_MAX_X_ROUNDED, 		/* return = value << 16 */
		GCMI_MAX_Y, 				/* return = value << 16 */
		GCMI_MAX_Y_ROUNDED 			/* return = value << 16 */
	} GCM_Info;

**See Also:** GrCharWidth() 

**Include:** font.h

----------
#### GrCharWidth()
	dword	GrCharWidth( 	/* Returns width << 16 */
			GStateHandle	gstate,		/* GState to query */
			word			ch);		/* character of type Chars */
Return the width of a single character. Note that this routine does not take 
into account track kerning, pairwise kerning, space padding, or other 
attributes that apply to multiple characters.

**Include:** graphics.h 

----------
#### GrCheckFontAvailID()
	FontID 	GrCheckFontAvailID(
			FontEnumFlags 	flags,
			word 			family,
			FontID 			id);
See if font (identified by ID) exists.

**Include:** graphics.h 

----------
#### GrCheckFontAvailName()
	FontID 	GrCheckFontAvailName(
			FontEnumFlags 	flags,
			word 			family,
			const char 		* name);
See if font (identified by name) exists.

**Include:** graphics.h 

----------
#### GrClearBitmap()
	void	GrClearBitmap(
			GStateHandle 	gstate);	/* GState to affect */
Clear out the content of a bitmap. Note that the part of the bitmap actually 
cleared depends on the bitmap mode. For the normal mode, the data portion 
of the bitmap is cleared. If the bitmap is in BM_EDIT_MASK mode, then the 
mask is cleared and the data portion is left alone.

**Include:** graphics.h 

----------
#### GrCloseSubPath()
	void	GrCloseSubPath(
			GStateHandle gstate);		/* GState to affect */
Geometrically closes the currently open path segment. Note that you must 
still call **GrEndPath()** to end the path definition.

**Include:** graphics.h 

----------
#### GrComment()
	void	GrComment(
			GStateHandle	gstate,			/* GState to affect */
			const void  	* data,			/* comment string */
			word			size);			/* Size of data, in bytes */
Write a comment out to a graphics string.

**Include:** graphics.h 

----------
#### GrCopyGString()
	GSRetType GrCopyGString(
			GStateHandle	source,		/* GState from which to get GString */
			GStateHandle	dest,		/* GState to which to copy GString */
			GSControl 		flags);		/* flags for the copy */
Copy all or part of a Graphics String. The **GSControl** record can have the 
following flags:

	GSC_ONE				/* just do one element */
	GSC_MISC			/* return on MISC opcode */
	GSC_LABEL			/* return on GR_LABEL opcode */
	GSC_ESCAPE			/* return on GR_ESCAPE opcode */
	GSC_NEW_PAGE		/* return when we get to a NEW_PAGE */
	GSC_XFORM			/* return on TRANSFORMATIONopcode */
	GSC_OUTPUT:			/* return on OUTPUT opcode */
	GSC_ATTR			/* return on ATTRIBUTE opcode */
	GSC_PATH			/* return on PATH opcode */

The return value can be any one of **GSRetType**, a byte-size field:

	GSRT_COMPLETE
	GSRT_ONE
	GSRT_MISC
	GSRT_LABEL
	GSRT_ESCAPE
	GSRT_NEW_PAGE
	GSRT_XFORM
	GSRT_OUTPUT
	GSRT_ATTR
	GSRT_PATH
	GSRT_FAULT

**Include:** gstring.h 

----------
#### GrCreateBitmap()
	VMBlockHandle GrCreateBitmap(
			BMFormat 		initFormat,		/* color fomat of bitmap */
			word			initWidth,		/* initial width of bitmap */
			word			initHeight,		/* initial height of bitmap */
			VMFileHandle 	vmFile,			/* VM file to hold bitmap's data*/
			optr 			exposureOD,		/* optr to get MSG_META_EXPOSED */
			GStateHandle	* bmgs);		/* Draws to this GState
											 * will draw to the bitmap */
This routine allocates memory for a bitmap and creates an off-screen window 
in which to hold the bitmap. This routine takes the following arguments:

*initFormat* - The depth of the bitmap's color.

*initWidth* - Bitmap's width.

*initHeight* - Bitmap's height.

vmFile - File to hold the bitmap data; the routine will allocate a block 
within this file.

*exposureOD* - Object which will receive the "exposed" message when the 
bitmap's window is invalidated. If this argument is zero, then 
no exposed message will be sent. 
Remember that an off-screen window is created to house the 
bitmap. When this window is first created, it will be invalid, 
and it is conceivable that later actions could cause it to become 
invalid again. On these occasions, the object specified by this 
argument will receive a MSG_META_EXPOSED.

*bmgs* - The GStateHandle pointed to by this argument can start out as 
null; the routine will use it to return the GState by which the 
bitmap can be drawn to. Any graphics routines which draw to 
this returned GState will be carried out upon the bitmap.

The routine returns a VMBlockHandle, the handle of the block within the 
passed VM file which contains the bitmap's data. The block will be set up as 
the first block of a HugeArray. Its header area will be filled with the 
following:

Complex Bitmap Header  
This is a **CBitmap** structure which contains some basic 
information about the bitmap.

Editing Mode  
These flags can change how the bitmap is being edited.

Device Information Block  
This internal structure contains information about and used by 
the video driver. (Don't worry that you don't know the size of 
this structure; remember that the CBitmap structure contains 
the offsets of the bitmap and palette data areas.)

Pallette Information (optional)  
If the bitmap has its own pallette, this is where the palette data 
will be stored; it will consist of an array of 3-byte entries. 
Depending on how many colors the bitmap supports, there may 
be 16 or 256 entries in this array.

The bitmap's raw data is in the VM block, but outside of the header area.

**Include:** graphics.h 

----------
#### GrCreateGString()
	GStateHandle GrCreateGString(
			Handle		han,		/* memory, stream, or VM file handle */
			GStringType	hanType,	/* type of handle in han parameter */
			word		* gsBlock);	/* returned for GST_MEMORY and 
									 * GST_VMEM types only */
Open a graphics string and start redirecting graphics orders to the string. 
The *hanType* parameter must be GST_MEMORY, GST_STREAM, or 
GST_VMEM.

**Include:** gstring.h 

----------
#### GrCreatePalette()
	word	GrCreatePalette( /* Returns # of entries in color table
							  * or 0 for monochrome or 24-bit */
			GStateHandle gstate);

Create a color mapping table and associate it with the current window. 
Initialize the table entries to the default palette for the device.

**Include:** graphics.h 

----------
#### GrCreateState()
	GStateHandle GrCreateState(
			WindowHandle win);	/* Window in which GState will be active */
Create a graphics state (GState) block containg default GState information.

If zero is passed, then the GState created will have no window associated 
with it.

**Include:** graphics.h 

----------
#### GrDeleteGStringElement()
	void	GrDeleteGStringElement(
			GStateHandle	gstate,		/* GState containing GString */
			word			count);		/* number of elements to delete */
Delete a range of GString elements from the GString in the passed GState.

**Include:** graphics.h 

----------
#### GrDestroyBitmap()
	void	GrDestroyBitmap(
			GStateHandle	gstate,		/* GState containing bitmap */
			BMDestroy 		flags);		/* flags for removing data */
Free the bitmap and disassociate it with its window. Depending on the 
passed flag, the bitmap's data may be freed or preserved. Thus, it is possible 
to remove the GString used to edit the bitmap while maintaining the bitmap 
in a drawable state.

**Structures:**

	typedef ByteEnum BMDestroy;
	/* 	BMD_KILL_DATA, 
	 	BMD_LEAVE_DATA */

**Include:** graphics.h 

----------
#### GrDestroyGString()
	void	GrDestroyGString(
			Handle				gstring,	/* Handle of GString */
			GStateHandle		gstate,		/* NULL, or handle of another
											 * gstate to free*/
			GStringKillType		type);		/* Kill type for data removal */
Destroys a GString. Depending on the **GStringKillType** argument, this 
either constitutes removing the GState from the GString data; or freeing 
both the GState and the GString's data. If you have been drawing the 
GString to a GState, you should pass the GState's handle as *gstate*, and this 
routine will do some cleaning up.

**Structures:** 

	typedef ByteEnum GStringKillType;
		/* 	GSKT_KILL_DATA, 
			GSKT_LEAVE_DATA */

**Include:** gstring.h 

----------
#### GrDestroyPalette()
	void	GrDestroyPalette(
			GStateHandle gstate);		/* GState of palette to destroy */
Free any custom palette associated with the current window.

**Include:** graphics.h 

----------
#### GrDestroyState()
	void	GrDestroyState(
			GStateHandle gstate);		/* GState to be destroyed */
Free a graphics state block.

**Include:** graphics.h 

----------
#### GrDrawArc()
	void	GrDrawArc(
			GStateHandle	gstate,			/* GState to draw to */
			sword			left,			/* bounds of box outlining arc */
			sword			top,
			sword			right,
			sword			bottom,
			word			startAngle,		/* angles in degrees
			word			endAngle,		 * counter-clockwise */
			ArcCloseType	arcType);		/* how the arc is closed */
Draw an arc along the ellipse that is specified by a bounding box, from the 
starting angle to the ending angle.

**Include:** graphics.h 

----------
#### GrDrawArc3Point()
	void	GrDrawArc3Point(
			GStateHandle				gstate,		/* GState to draw to */
			const ThreePointArcParams 	*params);			
Draw a circular arc, given three points along the arc; both endpoints and any 
other point on the arc.

**Include:** graphics.h 

----------
#### GrDrawArc3PointTo()
	void	GrDrawArc3PointTo(
			GStateHandle				gstate,		/* GState to draw to */
			const ThreePointArcToParams *params);
As **GrDrawArc3Point()**, above, except that the current position is 
automatically used as one of the endpoints.

**Include:** graphics.h 

----------
#### GrDrawBitmap()
	void	GrDrawBitmap(
			GStateHandle	gstate,			/* GState to draw to */
			sword			x,				/* x starting point */
			sword			y,				/* y starting point */
			const	Bitmap	* bm,			/* pointer to the bitmap */
			Bitmap * _pascal (*callback) (Bitmap *bm));	/* NULL for no callback */
Draw a bitmap. Note that if the bitmap takes up a great deal of memory, it is 
necessary to manage its memory when drawing. If the bitmap resides in a 
**HugeArray** (true of any bitmap created using **GrCreateBitmap()**), then 
calling **GrDrawHugeBitmap()** will automatically take care of memory 
management. Otherwise, you may wish to provide a suitable callback 
routine. This routine should be declared _pascal and is passed a pointer into 
the passed bitmap and is expected to return a pointer to the next slice. This 
allows the bitmap to be drawn in horizontal bands, or swaths.

**Include:** graphics.h 

----------
#### GrDrawBitmapAtCP()
	void	GrDrawBitmapAtCP(
			GStateHandle		gstate,			/* GState to draw to */
			const	Bitmap		* bm,			/* pointer to the bitmap */
			Bitmap * (*callback) (Bitmap *bm));	/* NULL for no callback */
This routine is the same as **GrDrawBitmap()**, above, except that the 
bitmap is drawn at the current position.

**Include:** graphics.h 

----------
#### GrDrawChar()
	void	GrDrawChar(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x,			/* x position at which to draw */
			sword			y,			/* y position at which to draw */
			word			ch);		/* character of type Chars */
Draw a character at the given position with the current text drawing 
attributes.

**Include:** graphics.h 

----------
#### GrDrawCharAtCP()
	void	GrDrawCharAtCP(
			GStateHandle	gstate,			/* GState to draw to */
			word			ch);			/* character of type Chars */
Draw a character at the current position with the current text drawing 
attributes.

**Include:** graphics.h 

----------
#### GrDrawCurve()
	void	GrDrawCurve(
			GStateHandle		gstate,			/* GState to draw to */
			const Point			*points);		/* array of four Points */
Draw a Bezier curve.

**Include:** graphics.h 

----------
#### GrDrawCurveTo()
	void	GrDrawCurveTo(
			GStateHandle		gstate,			/* GState to draw to */
			const Point			*points);		/* array of three Points */
Draw a Bezier curve, using the current postion as the first point.

**Include:** graphics.h 

----------
#### GrDrawEllipse()
	void	GrDrawEllipse(
			GStateHandle	gstate,		/* GState to draw to */
			sword			left,		/* bounding box bounds */
			sword			top,
			sword			right,
			sword			bottom);
Draw an ellipse, defined by its bounding box.

**Include:** graphics.h 

----------
#### GrDrawGString()
	GSRetType GrDrawGString(
			GStateHandle	gstate,			/* GState to draw to */
			Handle			gstringToDraw,	/* GString to draw */
			sword			x,				/* point at which to draw */
			sword			y,
			GSControl 		flags,			/* GSControl record */
			GStringElement	* lastElement);	/* pointer to empty structure */
Draw a graphics string. The passed control flag allows drawing to stop upon 
encountering certain kinds of drawing elements. If this causes the drawing 
to stop in mid-string, then the routine will provide a pointer to the next 
**GStringElement** to be played.

+ You must provide a GState to draw to. You may wish to call 
**GrSaveState()** on the GState before drawing the GString (and call 
**GrRestoreState()** afterwards). If you will draw anything else to this 
GState after the GString, you must call **GrDestroyGString()** on the 
GString, and pass this GState's handle as the gstate argument so that 
**GrDestroyGString()** can clean up the GState.

+ You must provide a GString to draw. The GString must be properly 
loaded (probably by means of **GrLoadGString()**).

+ You can provide a pair of coordinates at which to draw the GString. The 
graphics system will translate the coordinate system by these 
coordinates before carrying out the graphics commands stored in the 
GString.

+ You can provide a **GSControl** argument which requests that the system 
stop drawing the GString when it encounters a certain type of GString 
element. If the GString interpreter encounters one of these elements, it 
will immediately stop drawing. The GString will remember where it 
stopped drawing. If you call **GrDrawGString()** with that same GString, 
it will continue drawing where you left off.

+ You must provide a pointer to an empty **GStringElement** structure. 
**GrDrawGString()** will return a value here when it is finished drawing. 
If the GString has stopped drawing partway through due to a passed 
**GSControl**, the returned **GStringElement** value will tell you what sort 
of command was responsible for halting drawing. For instance, if you had 
instructed **GrDrawGString()** to halt on an `output' element 
**(GrDraw...()** or **GrFill...()** commands), then when **GrDrawGString()** 
returns, you would check the value returned to see what sort of output 
element was present.

**Include:** gstring.h 

----------
#### GrDrawGStringAtCP()
	GSRetType GrDrawGStringAtCP(
			GStateHandle		gstate,			/* GState to draw to */
			GStringeHandle		gstringToDraw,	/* GString to draw */
			GSControl 			flags,			/* GSControl flags */
			GStringElement 		* lastElement);	/* last element to draw */
Draw a graphics string as **GrDrawGString()**, above, except that drawing 
takes place at the current position.

+ You must provide a GState to draw to. You may wish to call 
**GrSaveState()** on the GState before drawing the GString (and call 
**GrRestoreState()** afterwards). If you will draw anything else to this 
GState after the GString, you must call **GrDestroyGString()** on the 
GString, and pass this GState's handle as the gstate argument so that 
**GrDestroyGString()** can clean up the GState.

+ You must provide a GString to draw. The GString must be properly 
loaded (probably by means of **GrLoadGString()**).

+ You can provide a **GSControl** argument which requests that the system 
stop drawing the GString when it encounters a certain type of GString 
element. If the GString interpreter encounters one of these elements, it 
will immediately stop drawing. The GString will remember where it 
stopped drawing. If you call **GrDrawGString()** with that same GString, 
it will continue drawing where you left off.

+ You must provide a pointer to an empty **GStringElement** structure. 
**GrDrawGString()** will return a value here when it is finished drawing. 
If the GString has stopped drawing partway through due to a passed 
**GSControl**, the returned **GStringElement** value will tell you what sort 
of command was responsible for halting drawing. For instance, if you had 
instructed **GrDrawGString()** to halt on an `output' element 
(**GrDraw...()** or **GrFill...()** commands), then when **GrDrawGString()** 
returns, you would check the value returned to see what sort of output 
element was present.

**Include:** gstring.h 

----------
#### GrDrawHLine()
	void	GrDrawHLine(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x1,			/* first horizontal coordinate */
			sword			y,			/* vertical position of line */
			sword			x2);		/* second horizontal coordinate */
Draw a horizontal line.

**Include:** graphics.h 

----------
#### GrDrawHLineTo()
	void	GrDrawHLineTo(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x);			/* ending horizontal coordinate */
Draw a horizontal line starting from the current position.

**Include:** graphics.h 

----------
#### GrDrawHugeBitmap()
	void	GrDrawHugeBitmap(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x			/* Point at which to draw */
			sword			y,
			VMFileHandle 	vmFile,		/* VM File holding HugeArray */
			VMBlockHandle 	vmBlk);		/* VM block of HugeArray */
Draw a bitmap that resides in a HugeArray.

**Include:** graphics.h 

**See Also:** GrDrawBitmap() , GrDrawHugeBitmapAtCP(), 
GrDrawHugeImage() 

----------
#### GrDrawHugeBitmapAtCP()
	void	GrDrawHugeBitmapAtCP(
			GStateHandle		gstate,		/* GState to draw to */
			VMFileHandle	 	vmFile,		/* VM file containing HugeArray */
			VMBlockHandle 		vmBlk);		/* VM block containing HugeArray */
As **GrDrawHugeBitmap()**, above, except that the bitmap is drawn at the 
current position.

**Include:** graphics.h 

**See Also:** GrDrawBitmapAtCP(), GrDrawHugeBitmap() 

----------
#### GrDrawHugeImage()
	void	GrDrawHugeImage(
			GStateHandle 	gstate,		/* GState to draw to */
			sword			x			/* point at which to draw */
			sword			y,
			ImageFlags 		flags,
			VMFileHandle 	vmFile,		/* VM file holding HugeArray */
			VMBlockHandle 	vmBlk);		/* VM block holding HugeArray */
Draw a bitmap that resides in a **HugeArray**. Note that the bitmap will be 
drawn on an assumption of one device pixel per bitmap pixel. The bitmap will 
not draw rotated or scaled. Depending on the value of the flags argument, the 
bitmap may be expanded so that a square of device pixels displays each 
bitmap pixel.

**Structures:**	

	typedef ByteFlags ImageFlags;
	/* The following flags be be combined using | and &:
			IF_IGNORE_MASK,
			IF_BORDER
	 * The flags should be combined with one ImageBitSize:
			IF_BITSIZE */
	#define IBS_1 	0
	#define IBS_2 	1
	#define IBS_4 	2
	#define IBS_8 	3
	#define IBS_16	4

**Include:** graphics.h 

**See Also:** GrDrawImage() , GrDrawHugeBitmapAtCP()

----------
#### GrDrawImage()
	void	GrDrawImage(
			GStateHandle 		gstate,			/* GState to draw to */
			sword		x			/* point at which to draw */
			sword		y,
			ImageFlags 		flags,			
			const Bitmap 		* bm);			/* pointer to bitmap */
Draw a bitmap. Note that the bitmap will be drawn on an assumption of one 
device pixel per bitmap pixel. The bitmap will not draw rotated or scaled. 
Depending on the value of the flags argument, the bitmap may be expanded 
so that a square of device pixels displays each bitmap pixel.

**Structures:**	

	typedef ByteFlags ImageFlags;
	/* The following flags be be combined using | and &:
			IF_IGNORE_MASK,
			IF_BORDER
	 * The flags should be combined with one ImageBitSize:
		IF_BITSIZE */
	#define IBS_1 	0
	#define IBS_2 	1
	#define IBS_4 	2
	#define IBS_8 	3
	#define IBS_16	4

**Include:** graphics.h 

**See Also:** GrDrawHugeImage() , GrDrawBitmap() 

----------
#### GrDrawLine()
	void	GrDrawLine(
			GStateHandle	gstate,	/* GState to draw to */
			sword			x1,		/* First coordinate of line */
			sword			y1,
			sword			x2,		/* Second coordinate of line */
			sword			y2);
Draw a line.

**Include:** graphics.h 

**See Also:** GrDrawLineTo(), GrDrawHLine(), GrDrawVLine() 

----------
#### GrDrawLineTo()
	void	GrDrawLineTo(
			GStateHandle	gstate,	/* GState to draw to */
			sword			x,		/* Second coordinate of line */
			sword			y);
Draw a line starting from the current position.

**Include:** graphics.h 

**See Also:** GrDrawLine(), GrDrawHLineTo(), GrDrawVLineTo() 

----------
#### GrDrawPath()
	void	GrDrawPath(
			GStateHandle gstate);		/* GState to draw to */
Draws the stroked version of the current path, using the current graphic line 
attributes.

**Include:** graphics.h 

----------
#### GrDrawPoint()
	void	GrDrawPoint(
			GStateHandle	gstate,		/* GState to draw to */
			sword 			x,			/* Coordinates of point to draw */
			sword 			y);
Draw a pixel.

**Include:** graphics.h 

----------
#### GrDrawPointAtCP()
	void	GrDrawPointAtCP(
			GStateHandle gstate);		/* GState to draw to */
Draw a pixel.

**Include:** graphics.h 

----------
#### GrDrawPolygon()
	void	GrDrawPolygon(
			GStateHandle	gstate,			/* GState to draw to */
			const	Point 	* points,		/* array of points in polygon */
			word			numPoints);		/* number of points in array */
Draws a connected polygon.

**Include:** graphics.h 

----------
#### GrDrawPolyline()
	void	GrDrawPolyline(
			GStateHandle	gstate,			/* GState to draw to */
			const	Point	* points,		/* array of points in polyline */
			word			numPoints);		/* number of points in array */
Draws a simple polyline.

**Include:** graphics.h 

----------
#### GrDrawRect()
	void	GrDrawRect(
			GStateHandle	gstate,		/* GState to draw to */
			sword			left,		/* bounds of rectangle to draw */
			sword			top,
			sword			right,
			sword			bottom);
Draws the outline of a rectangle.

**Include:** graphics.h 

----------
#### GrDrawRectTo()
	void	GrDrawRectTo(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x,			/* opposite corner of rectangle */
			sword			y);
Draws the outline of a rectangle, with one corner defined by the current 
position.

**Include:** graphics.h 

----------
#### GrDrawRegion()
	void	GrDrawRegion(
			GStateHandle	gstate,		/* GState to draw to */
			sword			xPos,		/* Position at which to draw */
			sword			yPos,
			const	Region	* reg,		/* Region definition */
			sword			param0,		/* value to use with
										 * parameterized coordinates */
			sword			param)1;	/* value to use with
										 * parameterized coordinates */
Draw a region. The area will be rendered filled with the GState's area 
attributes.

**Include:** graphics.h 

----------
#### GrDrawRegionAtCP()
	void	GrDrawRegionAtCP(
			GStateHandle	gstate,	/* GState to draw to */
			const Region 	* reg,	/* region definition */
			sword			param0,	/* Value to use with parameterized coordinates */
			sword			param1,	/* Value to use with parameterized coordinates */
			sword			param2,	/* Value to use with parameterized coordinates */
			sword			param)3;/* Value to use with parameterized coordinates */
Draw a region at the current pen position. The area will be rendered filled 
with the GState's area attributes.

**Include:** graphics.h 

----------
#### GrDrawRelArc3PointTo()
	void 	GrDrawRelArc3PointTo(
			const ThreePointRelArcToParams	*params);

Draw a circular arc relative to the current point given two additional points: 
the other endpoint and any other point on the arc, both described in relative 
coordinates.

**Include:** graphics.h 

----------
#### GrDrawRelLineTo()
	void 	GrDrawRelLineTo(
			GStateHandle 	gstate,	/* GState to draw to */
			WWFixedAsDWord 	x,		/* horizontal offset of second point */
			WWFixedAsDWord 	y);		/* vertical offset of second point */
Draw a line from the current pen position, given a displacement from the 
current pen position to draw to.

**Include:** graphics.h 

----------
#### GrDrawRoundRect()
	void	GrDrawRoundRect(
			GStateHandle	gstate,			/* GState to draw to */
			sword			left,			/* bounds of rectangle */
			sword			top,
			sword			right,
			sword			bottom,
			word			cornerRadius);	/* radius of corner rounding */
Draw the outline of a rounded rectangle.

**Include:** graphics.h 

----------
#### GrDrawRoundRectTo()
	void	GrDrawRoundRectTo(
			GStateHandle	gstate,			/* GState to draw to */
			sword			x,				/* opposite corner of bounds */
			sword			y,
			word			cornerRadius);	/* radius of corner rounding */
Draw the outline of a rounded rectangle, where one corner of the bounding 
rectangle is the current position.

**Include:** graphics.h 

----------
#### GrDrawSpline()
	void	GrDrawSpline(
			GStateHandle	gstate,			/* GState to draw 	to */
			const Point		* points,		/* array of points */
			word			numPoints,); 	/* number of points in array */
Draw a Bezier spline.

**Include:** graphics.h 

**See Also:** GrDrawCurve() 

----------
#### GrDrawSplineTo()
	void	GrDrawSplineTo(
			GStateHandle	gstate,			/* GState to draw to */
			const Point		*points,		/* array of points */
			word			numPoints);		/* number of points in array */
Draw a Bezier spline, using the current position as one endpoint.

**Include:** graphics.h 

**See Also:** GrDrawCurveTo() 

----------
#### GrDrawText()
	void	GrDrawText(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x,			/* point at which to draw */
			sword			y,
			const Chars		* str,		/* pointer to character string */
			word			size);		/* length of string */
Draw a string of text. The string is represented as an array of characters. 
Note that the text will be drawn using the GState's font drawing attributes 
and that this routine does not accept any style run arguments.

If the passed *size* argument is zero, the string is assumed to be 
null-terminated.

**Include:** graphics.h 

----------
#### GrDrawTextAtCP()
	void	GrDrawTextAtCP(
			GStateHandle	gstate,		/* GState to draw to */
			const Chars		* str,		/* pointer to character string */
			word			size);		/* length of string */
As **GrDrawText()**, above, except that the text is drawn at the current 
position.

If the passed *size* argument is zero, the string is assumed to be 
null-terminated.

**Include:** graphics.h 

----------
#### GrDrawVLine()
	void	GrDrawVLine(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x,			/* horizontal position of line */
			sword			y1,			/* first vertical coordinate */
			sword			y2);		/* second vertical coordinate */
Draw a vertical line.

**Include:** graphics.h 

----------
#### GrDrawVLineTo()
	void	GrDrawVLine(
			GStateHandle	gstate,		/* GState to draw to */
			sword			y);			/* second vertical position */
Draw a vertical line starting from the current position.

**Include:** graphics.h 

----------
#### GrEditBitmap()
	GStateHandle GrEditBitmap(
			VMFileHandle 	vmFile,			/* VM file of bitmap */
			VMBlockHandle 	vmBlock,		/* VM block of bitmap */
			optr 			exposureOD);	/* optr to get MSG_META_EXPOSED */
This routine attaches a GState to the passed bitmap so that new drawings 
may be be sent to the bitmap.

**Include:** graphics.h 

----------
#### GrEditGString()
	GStateHandle GrEditGString(
			Handle	vmFile,		/* VM file containing the GString */
			word	vmBlock);	/* VM block containing the GString */
This routine takes the location of a GString data block stored in a VM file. It 
will associate a GState with this GString data and returns the handle of this 
GState. Any graphics commands issued using this GStateHandle will be 
appended to the GString.

**Include:** graphics.h 

----------
#### GrEndGString()
	GStringErrorType GrEndGString( 
			GStateHandle gstate);			/* GState to draw to */
Finish the definition of a graphics string.

**Structures:**

	typedef enum { 
		GSET_NO_ERROR, 
		GSET_DISK_FULL 
	} GStringErrorType;

**Include:** graphics.h 

----------
#### GrEndPath()
	void	GrEndPath(
			GStateHandle gstate);		/* GState to draw to */

Finish definition of a path. Further graphics commands will draw to the 
display, as normal.

**Include:** graphics.h 

----------
#### GrEndUpdate()
	void	GrEndUpdate(
			GStateHandle gstate);		/* GState to draw to */
Unlocks window from an update.

**Include:** win.h 

----------
#### GrEnumFonts()
	word	GrEnumFonts( /* Return value = number of fonts found */
			FontEnumStruct	* buffer,	/* buffer for returned values */
			word			size,		/* number of structures to return */
			FontEnumFlags	flags,		/* FontEnumFlags */
			word			family);	/* FontFamily */
Generate a list of available fonts. The font information includes both the 
font's ID and a string name.

**Structures:**	

	typedef struct {
		FontID	FES_ID; 
		char	FES_name[FID_NAME_LEN];
	} FontEnumStruct; 

**Include:** font.h 

----------
#### GrEscape()
	void	GrEscape(
			GStateHandle	gstate,			/* GState to draw to */
			word			code,			/* escape code */
			const void		* data,			/* pointer to the data */
			word			size);			/* Size of data, in bytes */
Write an escape code to a graphics string.

**Include:** graphics.h 

----------
#### GrFillArc()
	void	GrFillArc(
			GStateHandle	gstate,			/* GState to draw to */
			sword			left,			/* bounding rectangle */
			sword			top,
			sword			right,
			sword			bottom,
			word			startAngle,		/* angles in degrees
			word			endAngle		 * counter-clockwise */
			ArcCloseType 	closeType);		/* OPEN, CHORD, or PIE */
Fill an elliptical arc. The arc is defined by the bounding rectangle of the base 
ellipse and two angles. Depending on how the arc is closed, this will result in 
either a wedge or a chord fill.

**Include:** graphics.h 

----------
#### GrFillArc3Point()
	void	GrFillArc3Point(
			GStateHandle			gstate,		/* GState to draw to */
			const ThreePointParams	*params);
Fill an arc. Depending on how the arc is closed, this will result in either a 
wedge or a chord fill. The arc is defined in terms of its endpoints and one 
other point, all of which must lie on the arc.

**Include:** graphics.h 

----------
#### GrFillArc3PointTo()
	void	GrFillArc3PointTo(
			GStateHandle				gstate,		/* GState to draw to */
			const ThreePointArcParams 	*params);
As **GrFillArc3Point()**, above, except that one endpoint of the arc is defined 
by the current position.

**Include:** graphics.h 

----------
#### GrFillBitmap()
	void 	GrFillBitmap (
			GStateHandle 		gstate,		/* GState to draw to */
			sword 				x,			/* point at which to draw */
			sword 				y,
			const Bitmap 		* bm,		/* pointer to bitmap */
			Bitmap * (*callback) (Bitmap *bm));
Fill a monochrome bitmap with the current area attributes. The arguments 
to this routine are the same as those for **GrDrawBitmap()**.

**Include:** graphics.h 

----------
#### GrFillBitmapAtCP()
	void 	GrFillBitmapAtCP (
			GStateHandle 	gstate,			/* GState to draw to */
			const Bitmap 	* bm,			/* pointer to bitmap */
			Bitmap * (*callback) (Bitmap *bm));
Fill a monochrome bitmap with the current area attributes. The bitmap will 
be drawn at the current position. The arguments to this routine are the same 
as those for **GrDrawBitmapAtCP()**.

**Include:** graphics.h 

----------
#### GrFillEllipse()
	void	GrFillEllipse(
			GStateHandle	gstate,		/* GState to draw to */
			sword			left,		/* Bounds of bounding rectangle */
			sword			top,
			sword			right,
			sword			bottom);
Draw a filled ellipse. The ellipse's dimensions are defined by its bounding 
box.

**Include:** graphics.h 

----------
#### GrFillPath()
	void	GrFillPath(
			GStateHandle	gstate,			/* GState to draw to */
			RegionFillRule	rule);			/* ODD_EVEN or WINDING */
Fill an area whose outline is defined by the GState's path.

**Include:** graphics.h 

----------
#### GrFillPolygon()
	void	GrFillPolygon(
			GStateHandle		gstate,			/* GState to draw to */
			RegionFillRule		windingRule,	/* ODD_EVEN or WINDING */
			const Point			* points,		/* array of points in polygon */
			word				numPoints);		/* number of points in array */
Fill polygon. The polygon is defined by the passed array of points.

**Include:** graphics.h 

----------
#### GrFillRect()
	void	GrFillRect(
			GStateHandle	gstate,			/* GState to draw to */
			sword			left,			/* bounds of rectangle */
			sword			top,
			sword			right,
			sword			bottom);
Draw a filled rectangle.

**Include:** graphics.h 

----------
#### GrFillRectTo()
	void	GrFillRectTo(
			GStateHandle	gstate,		/* GState to draw to */
			sword			x,			/* opposite corner of rectangle */
			sword			y);
Draw a filled rectangle. The current position will define one of the corners.

**Include:** graphics.h 

----------
#### GrFillRoundRect()
	void	GrFillRoundRect(
			GStateHandle	gstate,			/* GState to draw to */
			sword			left,			/* bounds of rectangle */
			sword			top,
			sword			right,
			sword			bottom
			word 			cornerRadius);	/* radius of corner rounding */
Draw a filled rounded rectangle.

**Include:** graphics.h 

----------
#### GrFillRoundRectTo()
	void	GrFillRoundRectTo(
			GStateHandle	gstate,			/* GState to draw to */
			sword			x,				/* opposite corner of rectangle */
			sword			y
			word 			cornerRadius);	/* radius of corner roundings */
Draw a filled rounded rectangle, using the current position to define one 
corner of the bounding rectangle.

**Include:** graphics.h 

----------
#### GrFindNearestPointsize()
	Boolean	GrFindNearestPointsize( /* If false, then FontID invalid */
			FontID 		id,					/* fond ID */
			dword		sizeSHL16,			/* point size */
			TextStyle 	styles,				/* style */
			TextStyle 	* styleFound,		/* buffer for style */
			dword		* sizeFoundSHL16);	/* buffer for size */
Find the nearest available point size for a font. If the font passed in *id* exists, 
then *styleFound* will point to the styles available and *sizeFoundSHL16* will 
point to the nearest point size to that passed. If the font is not found, the 
return valued will be *true*.

**Include:** font.h 

----------
#### GrFontMetrics()
	dword	GrFontMetrics(
			GStateHandle	gstate,		/* subject GState */
			GFM_info		info);		/* Type of information to return */
Get metrics information about a font. It returns the requested information 
based on the *info* parameter.

**Structures:**	

	typedef enum /* word */ {
		GFMI_HEIGHT,					/* return = val << 16 */
		GFMI_MEAN,						/* return = val << 16 */
		GFMI_DESCENT,					/* return = val << 16 */
		GFMI_BASELINE,					/* return = val << 16 */
		GFMI_LEADING,					/* return = val << 16 */
		GFMI_AVERAGE_WIDTH,				/* return = val << 16 */
		GFMI_ASCENT,					/* return = val << 16 */
		GFMI_MAX_WIDTH,					/* return = val << 16 */
		GFMI_MAX_ADJUSTED_HEIGHT,		/* return = val << 16 */
		GFMI_UNDER_POS,					/* return = val << 16 */
		GFMI_UNDER_THICKNESS, 			/* return = val << 16 */
		GFMI_ABOVE_BOX,					/* return = val << 16 */
		GFMI_ACCENT,					/* return = val << 16 */
		GFMI_MANUFACTURER,				/* return = val */
		GFMI_KERN_COUNT, 				/* return = Char */
		GFMI_FIRST_CHAR, 				/* return = Char */
		GFMI_LAST_CHAR, 				/* return = FontMaker */
		GFMI_DEFAULT_CHAR,				/* return = Char */
		GFMI_STRIKE_POS,				/* return = Char */
		GFMI_BELOW_BOX, 				/* return = Char */
		GFMI_HEIGHT_ROUNDED				/* return = Char */
		GFMI_DESCENT_ROUNDED, 			/* return = Char */
		GFMI_BASELINE_ROUNDED, 			/* return = Char */
		GFMI_LEADING_ROUNDED, 			/* return = Char */
		GFMI_AVERAGE_WIDTH_ROUNDED,		/* return = Char */
		GFMI_ASCENT_ROUNDED, 			/* return = Char */
		GFMI_MAX_WIDTH_ROUNDED, 		/* return = Char */
		GFMI_MAX_ADJUSTED_HEIGHT_ROUNDED, /* ret = Char */
		GFMI_UNDER_POS_ROUNDED, 		/* return = Char */
		GFMI_UNDER_THICKNESS_ROUNDED, 	/* return = Char */
		GFMI_ABOVE_BOX_ROUNDED, 		/* return = Char */
		GFMI_ACCENT_ROUNDED=, 			/* return = Char */
		GFMI_STRIKE_POS_ROUNDED,		/* return = Char */
		GFMI_BELOW_BOX_ROUNDED			/* return = Char */
	} GFM_info; 

**Include:** font.h 

----------
#### GrGetAreaColor()
	RGBColorAsDWord 	GrGetAreaColor(
			GStateHandle gstate);		/* GState of which to get color */
Get the color which is being used to fill areas.

**Include:** graphics.h 

----------
#### GrGetAreaColorMap()
	ColorMapMode GrGetAreaColorMap(
			GStateHandle  gstate);	/* GState of which to get area color map */
Get the mapping mode used for filling areas with unavailable colors.

**Include:** graphics.h 

----------
#### GrGetAreaMask()
	SysDrawMask GrGetAreaMask(
			GStateHandle	gstate,		/* GState of which to get mask */
			DrawMask		* dm);		/* buffer for returned mask */
Get the draw mask used when filling areas. The *dm* argument should point 
to a buffer capable of holding at least eight bytes to get the bit-pattern of the 
mask; otherwise *dm* should be NULL. The returned buffer is the 8x8 bit 
pattern: each byte represents a row of the pattern, and the bytes are ordered 
from top row to bottom.

**Include:** graphics.h 

----------
#### GrGetAreaPattern()
	GraphicPattern 	GrGetAreaPattern(
			GStateHandle 	gstate,				/* GState of area pattern */
			const MemHandle	* customPattern,	/* pointer to handle of block for
						 						 * returned custom pattern */
			word 			* customSize);		/* pointer to size of returned
												 * buffer */
Get the area pattern used when filling areas.

**Include:** graphics.h 

----------
#### GrGetBitmap()
	MemHandle GrGetBitmap(
			GStateHandle	gstate,			/* GState containing bitmap */
			sword			x,				/* bitmap origin */
			sword			y,
			word			width,			/* bitmap width and height */
			word			height,
			XYSize	 		* sizeCopied);	/* buffer for returned size */
Dump an area of the display to a bitmap. The handle of a block containing 
the bitmap is returned; the *sizeCopied* pointer points to the actual size of the 
bitmap successfully copied.

**Include:** graphics.h 

----------
#### GrGetBitmapMode()
	BitmapMode 	GrGetBitmapMode(
			GStateHandle	gstate);	/* GState containing bitmap */
Get mode bits for an editable bitmap.

**Include:** graphics.h 

----------
#### GrGetBitmapRes()
	XYValueAsDWord GrGetBitmapRes(
			const Bitmap	* bm);		/* pointer to the bitmap */
Get the resolution of a bitmap. 

**Include:** graphics.h 

----------
#### GrGetBitmapSize()
	XYValueAsDWord GrGetBitmapSize(
			const Bitmap	* bm);		/* pointer to the bitmap */
Get the dimensions, in points, of a bitmap.

**Include:** graphics.h 

----------
#### GrGetClipRegion()
	MemHandle GrGetClipRegion(
			GStateHandle	gstate,			/* subject GState */
			RegionFillRule	rule);			/* ODD_EVEN or WINDING */
Get the current clip region. A null handle (zero) will be returned if no clip 
paths are set for the GState.

**Include:** graphics.h 

----------
#### GrGetCurPos()
	XYValueAsDWord GrGetCurPos(
			GStateHandle	gstate);		/* subject GState */
Get the current pen position.

**Include:** graphics.h 

----------
#### GrGetCurPosWWFixed()
	void	GrGetCurPosWWFixed(
			GStateHandle	gstate,			/* subject GState */
			PointWWFixed 	*cp);			/* buffer in which to return cur. pos. */
Get the current pen position.

**Include:** graphics.h 

----------
#### GrGetDefFontID()
	FontID	GrGetDefFontID(
			dword	* sizeSHL16);	/* pointer to buffer for returned size */
Get the system default font (including size).

**Include:** font.h 

----------
#### GrGetFont()
	FontID	GrGetFont(
			GStateHandle	gstate,			/* subject GState */
			WWFixedAsDWord	* pointSize);	/* pointer to buffer for
											 * returned point size */
Get the passed GState's current font, including point size.

**Include:** graphics.h 

----------
#### GrGetFontName()
	FontID 	GrGetFontName(
			FontID 			id,			/* ID of font */
			const char 		* name);	/* buffer for returned name string */
Get the string name of a font. Note that if the returned **FontID** is zero, then 
the font was not found. The name string buffer should be a least 
FID_NAME_LEN in size.

**Include:** font.h 

----------
#### GrGetFontWeight()
	FontWeight GrGetFontWeight(
			GStateHandle	gstate);	/* GState containing the font */
Get the current font weight set for the passed GState.

**Include:** font.h 

----------
#### GrGetFontWidth()
	FontWidth GrGetFontWidth(
			GStateHandle	gstate);	/* GState containing the font */
Get the current font width set for the passed GState.

**Include:** font.h 

----------
#### GrGetGStringBounds()
	void	GrGetGStringBounds(
			GStringHandle	source,			/* GString to be checked */
			GStateHandle	dest,			/* handle of GState to use */
			GSControl		flags,			/* GSControl flags */
			Rectangle		* bounds);		/* returned bounds of GState */
This routine returns the coordinate bounds of the *source* GString drawn at 
the current position in the GString. The *dest* GState will be used if passed; to 
have no GState restrictions, pass a null handle. The bounds of the smallest 
containing rectangle will be returned in the structure pointed to by *bounds*.

**Include:** gstring.h 

----------
#### GrGetGStringBoundsDWord
	void	GrGetGStringBoundsDWord(
			Handle			gstring,		/* GString to be checked */
			GStateHandle	gstate,			/* handle of GState to use */
			GSControl		flags,			/* GSControl flags */
			RectDWord		* bounds);		/* returned bounds of GState */
This routine behaves as **GrGetGStringBounds()**, but has been alterred to 
work with 32-bit graphics spaces.

This routine returns the coordinate bounds of a GString drawn at the current 
position in the GString. The *gstate* GState will be used if passed; to have no 
GState restrictions, pass a null handle. The bounds of the smallest 
containing rectangle will be returned in the structure pointed to by *bounds*.

**Include:** gstring.h 

----------
#### GrGetGStringElement()
	GStringElement GrGetGStringElement(
			GStateHandle	gstate,					/* handle of GString's GState */
			void 			* buffer,				/* pointer to return buffer */
			word 			bufSize,				/* size of return buffer */
			word 			* elementSize,			/* size of GString element */
			void			** pointerAfterData);	/* pointer to pointer to
													 * next element in GString */
Extract the next element from a graphics string. The opcode is returned 
explicitly. The routine's data can be returned in a buffer.

**Include:** gstring.h 

----------
#### GrGetInfo()
	void	GrGetInfo(
			GStateHandle	gstate,		/* GState to get information about */
			GrInfoTypes		type,		/* type of information to get */
			void	 		* data);	/* buffer for returned information */
Get the private data, window handle, or pen position associated with the 
GState.

**Structures:**

	typedef enum {
		GIT_PRIVATE_DATA,
		GIT_WINDOW, 
		GIT_PEN_POS
	} GrInfoType

**Include:** graphics.h 

----------
#### GrGetLineColor()
	RGBColorAsDWord GrGetLineColor(
			GStateHandle	gstate);		/* subject GState */
Get the color used when drawing lines.

**Include:** graphics.h 

----------
#### GrGetLineColorMap()
	ColorMapMode GrGetLineColorMap(
			GStateHandle	gstate);		/* subject GState */
Get the mode used when drawing lines in an unavailable color.

**Include:** graphics.h 

----------
#### GrGetLineEnd()
	LineEnd	GrGetLineEnd(
			GStateHandle	gstate);		/* subject GState */
Get the end used when drawing lines.

**Include:** graphics.h 

----------
#### GrGetLineJoin()
	LineJoin GrGetLineJoin(
			GStateHandle	gstate);		/* subject GState */
Get the join used when drawing corners.

**Include:** graphics.h 

----------
#### GrGetLineMask()
	SysDrawMask GrGetLineMask(
			GStateHandle	gstate,		/* subject GState */
			DrawMask		* dm);		/* buffer for returned custom mask */
Get the drawing mask used when drawing lines. The *dm* argument should 
point to a buffer capable of holding at least eight bytes to get the bit-pattern 
of the mask; otherwise *dm* should be NULL. The returned buffer is the 8x8 
bit pattern: each byte represents a row of the pattern, and the bytes are 
ordered from top row to bottom.

**Include:** graphics.h 

----------
#### GrGetLineStyle()
	LineStyle GrGetLineStyle(
			GStateHandle	gstate);		/* subject GState */
Get the style, or "dottedness," used when drawing lines.

**Include:** graphics.h 

----------
#### GrGetLineWidth()
	WWFixedAsDWord 	GrGetLineWidth(
			GStateHandle	gstate);		/* subject GState */
Get the current line width.

**Include:** graphics.h 

----------
#### GrGetMaskBounds()
	void	GrGetMaskBounds(
			GStateHandle	gstate,			/* subject GState */
			Rectangle		* bounds);		/* buffer for returned bounds */
Get the 16-bit bounds of the current clip rectangle.

**Include:** graphics.h 

----------
#### GrGetMaskBoundsDWord()
	void	GrGetMaskBoundsDWord(
			GStateHandle	gstate,			/* subject GState */
			RectDWord		* bounds);		/* buffer for returned bounds */
Get the 16-bit bounds of the current clip rectangle, accurate to a fraction of a 
point.

**Include:** graphics.h 

----------
#### GrGetMiterLimit()
	WWFixedAsDWord GrGetMiterLimit(
			GStateHandle	gstate);			/* subject GState */
Get the miter limit to use when drawing mitered corners.

**Include:** graphics.h 

----------
#### GrGetMixMode()
	MixMode GrGetMixMode(
			GStateHandle	gstate);			/* subject GState */
Get the current mixing mode.

**Include:** graphics.h 

----------
#### GrGetPalette()
	MemHandle GrGetPalette(
			GStateHandle	gstate,			/* subject GState */
			GetPalType		flag,			/* GPT_ACTIVE, GPT_CUSTOM, or
											 * GPT_DEFAULT */
			word	 		* numEntries);	/* number of entries in block */
Return all or part of the window's color lookup table. This routine returns the  
handle of a block containing all the returned palette entries.

**Include:** graphics.h 

----------
#### GrGetPath()
	MemHandle 	GrGetPath(
			GStateHandle	gstate,			/* subject GState */
			GetPathType 	ptype);			/* Which path to retrieve */
Returns handle to block containing path data. This handle may be passed to 
**GrSetPath()**. Either the current path, the clipping path, or the window 
clipping path may be retrieved.

**Include:** graphics.h 

----------
#### GrGetPathBounds()
	Boolean	GrGetPathBounds(
			GStateHandle	gstate,			/* subject GState */
			GetPathType 	ptype,
			Rectangle		* bounds);		/* buffer for returned bounds */
Returns the rectangular bounds that encompass the current path as it would 
be filled. A *true* return value indicates an error occurred or there was no path 
for the GState.

**Include:** graphics.h 

----------
#### GrGetPathBoundsDWord()
	Boolean	GrGetPathBoundsDWord(
			GStateHandle	gstate,			/* subject GState */
			GetPathType		ptype,
			RectDWord		* bounds);		/* buffer for returned bounds */
Returns the rectangular bounds that encompass the current path as it would 
be filled. A *true* return value indicates an error occurred or there was no path 
for the GState.

**Include:** graphics.h 

----------
#### GrGetPathPoints()
	MemHandle 	GrGetPathPoints(
			GStateHandle	gstate,			/* subject GState */
			word			resolution);	/* dots per inch */
Returns a series of points that fall along the current path. The returned 
points are in document coordinates.

**Include:** graphics.h 

----------
#### GrGetPathRegion()
	MemHandle GrGetPathRegion(
			GStateHandle		gstate,			/* subject GState */
			RegionFillRule		rule);			/* ODD_EVEN or WINDING */
Get the region enclosed by a path.

**Include:** graphics.h 

----------
#### GrGetPoint()
	RGBColorAsDWord GrGetPoint(
			GStateHandle	gstate,		/* subject GState */
			sword			x,			/* coordinates of pixel */
			sword			y);
Get the color of the pixel corresponding to the specified coordinates.

**Include:** graphics.h 

----------
#### GrGetPtrRegBounds()
	word	GrGetPtrRegBounds( /* Returns size of Region data struct. */
			const Region	* reg,			/* pointer to region */
			Rectangle		* bounds);		/* returned bounds of region */
Get the bounds of the passed region.

**Include:** graphics.h 

----------
#### GrGetSubscriptAttr()
	ScriptAttrAsWord GrGetSubscriptAttr(
			GStateHandle	gstate);		/* subject GState */
Get the GState's subscript drawing attributes. The high byte of the return 
value is the percentage of the font size for the subscript; the low byte is the 
percentage of the font size from the top at which the character gets drawn.

**Include:** font.h 

----------
#### GrGetSuperscriptAttr()
	ScriptAttrAsWord GrGetSuperscriptAttr(
			GStateHandle	gstate);		/* subject GState */
Get the GState's superscript drawing attributes. The high byte of the return 
value is the percentage of the font size for the superscript; the low byte is the 
percentage of the font size from the bottom at which the character gets 
drawn.

**Include:** font.h 

----------
#### GrGetTextBounds()
	Boolean	GrGetTextBounds(
			GStateHandle	gstate,		/* subject GState */
			word 			xpos,		/* position where text would be drawn */
			word 			ypos,
			const char		* str,		/* text string */
			word 			count, 		/* max number of characters to check */
			Rectangle 		* bounds);	/* returned bounding rectangle */
Get the bounds required to draw the passed text. If the passed size argument 
is zero, the string is assumed to be null-terminated.

**Include:** graphics.h 

----------
#### GrGetTextColor()
	RGBColorAsDWord GrGetTextColor(
			GStateHandle	gstate);		/* subject GState */
Get the color used when drawing text.

**Include:** graphics.h 

----------
#### GrGetTextColorMap()
	ColorMapMode 	GrGetTextColorMap(
			GStateHandle	gstate);		/* subject GState */
Get the mode used when drawing text in an unavailable color.

**Include:** graphics.h 

----------
#### GrGetTextMask()
	SystemDrawMask 	GrGetTextMask(
			GStateHandle	gstate,			/* subject GState */
			DrawMask		* dm);			/* returned custom mask, if any */
Get the draw mask used when drawing text.The *dm* argument should point 
to a buffer capable of holding at least eight bytes to get the bit-pattern of the 
mask; otherwise *dm* should be NULL. The returned buffer is the 8x8 bit 
pattern: each byte represents a row of the pattern, and the bytes are ordered 
from top row to bottom.

**Include:** graphics.h 

----------
#### GrGetTextMode()
	TextMode	GrGetTextMode(
			GStateHandle	gstate);		/* subject GState */
Get the text mode, including information about the vertical offset used when 
drawing text.

**Include:** graphics.h 

----------
#### GrGetTextPattern()
	GraphicPattern 	GrGetTextPattern(
			GStateHandle	gstate,				/* subject GState */
			const MemHandle	* customPattern,	/* pointer to returned handle
												 * of block containing the
												 * returned pattern */
			word			* customSize);		/* size of returned block */
Get the graphics pattern used when drawing text.

**Include:** graphics.h 

----------
#### GrGetTextSpacePad()
	WWFixedAsDWord GrGetTextSpacePad(
			GStateHandle	gstate);			/* subject GState */
Get the space pad used when drawing strings of text.

**Include:** graphics.h 

----------
#### GrGetTextStyle()
	TextStyle 	GrGetTextStyle(
			GStateHandle	gstate);			/* subject GState */
Get the style used when drawing text.

**Include:** graphics.h 

----------
#### GrGetTrackKern()
	word 	GrGetTrackKern(
			GStateHandle	gstate);			/* subject GState */
Get the track kerning used when drawing strings of text.

**Include:**	graphics.h 

----------
#### GrGetTransform()
	void	GrGetTransform(
			GStateHandle	gstate,		/* subject GState */
			TransMatrix		* tm);		/* pointer to returned TransMatrix */
Get the current coordinate transformation, expressed as a matrix.

**Include:** graphics.h 

----------
#### GrGetWinBounds()
	void	GrGetWinBounds(
			GStateHandle	gstate,			/* subject GState */
			Rectangle		* bounds);		/* returned window bounds */
Get the bounds of the GState's associated window.

**Include:** graphics.h 

----------
#### GrGetWinBoundsDWord()
	void	GrGetWinBoundsDWord(
			GStateHandle	gstate,			/* subject GState */
			RectDWord		* bounds);		/* returned window bounds */
Get the bounds of the GState's associated window, accurate to a fraction of a 
point.

**Include:** graphics.h 

----------
#### GrGetWinHandle()
	WindowHandle GrGetWinHandle(
			GStateHandle	gstate);		/* subject GState */
Get the handle of the GState's associated window.

**Include:** graphics.h 

----------
#### GrGrabExclusive()
	GStateHandle GrGrabExclusive(
			GeodeHandle		videoDriver,		/* NULL for default */
			GStateHandle	gstate);			/* subject GState */
Start drawing exclusively to a video driver.

**Include:** graphics.h 

----------
#### GrInitDefaultTransform()
	void	GrInitDefaultTransform(
			GStateHandle	gstate);			/* subject GState */
Initialize the GState's default transformation to hold hte value of the current 
transformation.

**Include:** graphics.h 

----------
#### GrInvalRect()
	void	GrInvalRect(
			GStateHandle	gstate,		/* subject GState */
			sword			left,		/* bounds to be invalidated */
			sword			top,
			sword			right,
			sword			bottom);
Invalidate the passed rectangular area. This area will be redrawn.

**Include:** graphics.h 

----------
#### GrInvalRectDWord()
	void	GrInvalRectDWord(
			GStateHandle		gstate,		/* subject GState */
			const RectDWord		* bounds);	/* bounds to be invalidated */
Invalidate the passed rectangular area. This area will be redrawn.

**Include:** graphics.h 

----------
#### GrLabel()
	void	GrLabel(
			GStringHandle	gstate,			/* subject GState */
			word			label);			/* label to write to GString */
Write the passed label into the passed GString.

**Include:** gstring.h 

----------
#### GrLoadGString()
	GStringHandle GrLoadGString(
			Handle			han,		/* handle of GString source */
			GStringType		hanType,	/* handle type */
			word			vmBlock);	/* if VM file, handle of VM block */
Load a graphics string from a file. Used with stream, VM, and pointer 
addressed GStrings.

**Structures:** 

	typedef ByteEnum GStringType;
	/*	GST_MEMORY,
		GST_STREAM,
		GST_VMEM,
		GST_PTR,
		GST_PATH		*/

**Include:** gstring.h 

----------
#### GrMapColorIndex()
	RGBColorAsDWord GrMapColorIndex(
			GStateHandle	gstate,			/* GState to use for mapping */
			Color			c);				/* source color to be mapped */
Map a color index to its RGB equivalent using the color mapping scheme of 
the passed GState.

**Include:** graphics.h 

----------
#### GrMapColorRGB()
	RGBColorAsDWord GrMapColorRGB(
			GStateHandle	gstate,			/* GState to use for mapping */
			word			red,			/* RGB values to map */
			word			green,
			word			blue);
Map an RGB color to an index.

**Include:** graphics.h 

----------
#### GrMoveReg()
	void	GrMoveReg(
			Region	* reg,		/* pointer to region */
			sword	xOffset,	/* amount to shift horizontally */
			sword	yOffset);	/* amount to shift vertically */
Moves a region a given amount. Note that this operation affects only the 
region's data structure. The region must be redrawn or used in some other 
way for the changes to have any visible effect.

**Include:** graphics.h 

----------
#### GrMoveTo()
		void	GrMoveTo(
			GStateHandle	gstate,		/* subject GState */
			sword			x,			/* new absolute pen position */
			sword			y);
Change the pen position.

**Include:** graphics.h 

----------
#### GrMulDWFixed()
	void	GrMulDWFixed(
			const DWFixed	* i,			/* first number */
			const DWFixed	* j,			/* second number */
			DWFixed			* result);		/* pointer to returned result */
Multiply two fixed point numbers.

**Include:** graphics.h 

----------
#### GrMulWWFixed()
	WWFixedAsDWord GrMulWWFixed(
			WWFixedAsDWord	i,			/* first number */
			WWFixedAsDWord	j);			/* second number */
Multiply two fixed point numbers.

**Include:** graphics.h 

----------
#### GrNewPage()
	void	GrNewPage(
			GStateHandle 		gstate,
			PageEndCommand 		pageEndCommand);
Begin drawing a new page. Normally used when printing documents.

**Include:** graphics.h 

----------
#### GrNullOp()
	void	GrNullOp(
			GStateHandle	gstate);		/* subject GState */
Write a null operation element to a GString.

**Include:** graphics.h 

----------
#### GrQuickArcSine()
	WWFixedAsDWord GrQuickArcSine(
			WWFixedAsDWord	deltaYDivDistance,	/* delta y / distance */
			word			origDeltaX);		/* original delta x */
Compute a fixed point arcsine. Angles are given in degrees counterclockwise 
of the positive x axis.

**Include:** graphics.h 

----------
#### GrQuickCosine()
	WWFixedAsDWord GrQuickCosine(
			WWFixedAsDWord	angle);			/* angle to cosine */
Compute a fixed point cosine. Angles are given in degrees counterclockwise 
of the positive x axis.

**Include:** graphics.h 

----------
#### GrQuickSine()
	WWFixedAsDWord GrQuickSine(
			WWFixedAsDWord	angle);			/* angle to sine */
Compute a fixed point sine. Angles are given in degrees counterclockwise of 
the positive x axis.

**Include:** graphics.h 

----------
#### GrQuickTangent()
	WWFixedAsDWord GrQuickTangent(
			WWFixedAsDWord	angle);			/* angle to tangent */
Compute a fixed point tangent. Angles are given in degrees counterclockwise 
of the positive x axis.

**Include:** graphics.h 

----------
#### GrReleaseExclusive()
	void 	GrReleaseExclusive( /* TRUE if system had to force a redraw */
			GeodeHandle		videoDriver,	/* handle of video driver */
			GStateHandle	gstate,			/* GState that was drawing */
			Rectangle 		*bounds);		/* Bounds of aborted drawings */
Stop drawing exclusively to a video driver.

**Include:** graphics.h 

----------
#### GrRelMoveTo()
	void	GrRelMoveTo(
			GStateHandle		gstate,		/* subject GState */
			WWFixedAsDWord 		x,			/* offsets to new pen position */
			WWFixedAsDWord 		y);
Change the pen position to coordinate expressed relative to the current 
position.

**Include:** graphics.h 

----------
#### GrRestoreState()
	void	GrRestoreState(
			GStateHandle	gstate);		/* subject GState */
Restore the values of a saved GState.

**Include:**	graphics.h 

----------
#### GrSaveState()
	void	GrSaveState(
			GStateHandle	gstate);		/* subject GState */
Save the values of a GState, so that they may be restored by 
**GrRestoreState()**.

**Include:** graphics.h 

----------
#### GrSDivDWFByWWF()
	void GrSDivDWFByWWF(
			const DWFixed 		* dividend,
			const WWFixed 		* divisor,
			DWFixed 			* quotient)		/* returned value */
Divide two fixed point numbers.

**Include:** graphics.h 

----------
#### GrSDivWWFixed()
	WWFixedAsDWord GrSDivWWFixed(
			WWFixedAsDWord	dividend,
			WWFixedAsDWord	divisor)
Divide two fixed point numbers.

**Include:** graphics.h 

----------
#### GrSetAreaAttr()
	void	GrSetAreaAttr(
			GStateHandle	gstate,			/* subject GState */
			const AreaAttr 	* aa);			/* AreaAttr structure */
Set all of the attributes used when filling areas.

**Structures:**

	typedef struct {
		byte				AA_colorFlag;
		RGBValue			AA_color;
		SystemDrawMask		AA_mask;
		ColorMapMode		AA_mapMode;
	} AreaAttr;

**Include:** graphics.h 

----------
#### GrSetAreaColor()
	void	GrSetAreaColor(
			GStateHandle 	gstate,			/* GState to set color for */
			ColorFlag 		flag,			/* flag of how to set color */
			word			redOrIndex,		/* color index or red RGB value */
			word			green,			/* green RGB value or zero */
			word			blue);			/* blue RGB value or zero */
Set the color to use when filling areas. The flag parameter may be CF_RGB 
(to set RGB values), CF_INDEX (to set a palette index), CF_GRAY, or CF_SAME.

**Include:** graphics.h 

----------
#### GrSetAreaColorMap()
	void	GrSetAreaColorMap(
			GStateHandle 	gstate,			/* subject GState */
			ColorMapMode 	colorMap);		/* color mapping mode */
Set mode to use when trying to fill an area with an unavailable color.

**Include:** graphics.h 

----------
#### GrSetAreaMaskCustom()
	void	GrSetAreaMaskCustom(
			GStateHandle 		gstate,			/* subject GState */
			const DrawMask  	* dm);			/* pointer to new custom mask */
Set the drawing mask to use when filling areas.

**Include:** graphics.h 

----------
#### GrSetAreaMaskSys()
	void	GrSetAreaMaskSys(
			GStateHandle 	gstate,			/* subject GState */
			SystemDrawMask 	sysDM);			/* new system area mask */
Set the drawing mask to use when filling areas.

**Include:** graphics.h 

----------
#### GrSetAreaPattern()
	void 	GrSetAreaPattern(
			GStateHandle 	gstate,			/* subject GState */
			GraphicPattern 	pattern);		/* new pattern */
Set the graphics pattern to use when filling areas.

**Include:** graphics.h 

----------
#### GrSetBitmapMode()
	void	GrSetBitmapMode(
			GStateHandle	gstate,		/* subject GState */
			word 			flags,		/* BM_EDIT_MASK or BM_CLUSTERED_DITHER */
			MemHandle 		colorCorr);	/* handle of ColorTransfer */
Set the bitmap editing mode. This allows the editing of a bitmap's mask, or 
turning on clustered dithering.

**Include:** graphics.h 

----------
#### GrSetBitmapRes()
	Boolean	GrSetBitmapRes(
			GStateHandle	gstate,			/* subject GState */
			word			xRes,			/* new resolutions */
			word			yRes);
Set a complex bitmap's resolution.

**Include:** graphics.h 

----------
#### GrSetClipPath()
	void	GrSetClipPath(
			GStateHandle 		gstate,		/* subject GState */
			PathCombineType 	params,		/* how paths should be combined */
			RegionFillRule 		rule);		/* ODD_EVEN or WINDING */
Restrict the clipping region by intersecting it with the passed path.

**Include:** graphics.h 

----------
#### GrSetClipRect()
	void	GrSetClipRect(
			GStateHandle 		gstate,		/* subject GState */
			PathCombineType		flags,		/* how paths should be combined */
			sword				left,		/* bounds of clipping rectangle */
			sword				top,
			sword				right,
			sword				bottom);
Restrict the clipping region by intersecting it with the passed rectangle.

**Include:** graphics.h 

----------
#### GrSetCustomAreaPattern()
	void 	GrSetCustomAreaPattern(
			GStateHandle 	gstate,			/* subject GState */
			GraphicPattern 	pattern,		/* new area pattern */
			const void *	patternData,	/* pointer to pattern data */
			word			patternSize);	/* size of pattern data buffer */
Set the graphics pattern to use when filling areas.

**Include:** graphics.h 

----------
#### GrSetCustomTextPattern()
	void 	GrSetCustomTextPattern(
			GStateHandle 	gstate,				/* subject GState */
			GraphicPattern	pattern,			/* new pattern */
			const void 		* patternData);		/* pointer to pattern data */
Set the graphic pattern used when drawing text.

**Include:** graphics.h 

----------
#### GrSetDefaultTransform()
	void	GrSetDefaultTransform(
			GStateHandle	gstate);			/* subject GState */
Replace the current coordinate transformation with the default 
transformation.

**Include: **graphics.h 

----------
#### GrSetFont()
	void	GrSetFont(
			GStateHandle 		gstate,			/* subject GState */
			FontID 				id,				/* new font ID */
			WWFixedAsDWord 		pointSize);		/* new point size */
Set the font to use when drawing text.

**Include:** graphics.h 

----------
#### GrSetFontWeight()
	void	GrSetFontWeight(
			GStateHandle 	gstate,			/* subject GState */
			FontWeight 		weight);		/* new font weight */
Set the font weight to use when drawing text.

**Include:** font.h 

----------
#### GrSetFontWidth()
	void	GrSetFontWidth(
			GStateHandle 	gstate,				/* subject GState */
			FontWidth 		width);				/* new font width */
Set the font width to use when drawing text.

**Include:** font.h 

----------
#### GrSetGStringBounds()
	void	GrSetGStringBounds(
			Handle		gstate,			/* GState or GString handle */
			sword		left,			/* new bounds of GString */
			sword		top,
			sword		right,
			sword		bottom);
Optimization routine which allows you to set bounds values for a GString. 
This bounds information will be returned by **GrGetGStringBounds()** 
whenever that routine is called upon the affected GString.

**Include:** graphics.h 

----------
#### GrSetGStringPos()
	void	GrSetGStringPos(
			GStateHandle		gstate,		/* subject GState */
			GStringSetPosType	type,		/* how to set position */
			word				skip);		/* number of elements to skip */
Set a graphics string's "playing position." Using this routine, it is possible to 
draw only selected elements of a GString.

**Structures:** 

	typedef ByteEnum GStringSetPosType;
	/*	GSSPT_SKIP, 
		GSSPT_RELATIVE, 
		GSSPT_BEGINNING,
		GSSPT_END		*/

**Include:** gstring.h 

----------
#### GrSetLineAttr()
	void	GrSetLineAttr(
			GStateHandle 		gstate,			/* subject GState */
			const LineAttr 		* la);			/* new line attributes */
Set all attributes to use when drawing lines and corners.

**Include:** graphics.h 

----------
#### GrSetLineColor()
	void	GrSetLineColor(
			GStateHandle 	gstate,			/* subject GState */
			ColorFlag 		flag,			/* color flag */
			word			redOrIndex,		/* new index or red RGB value */
			word			green,			/* new green RGB value or zero */
			word			blue);			/* new blue RGB value or zero */
Set the color to use when drawing lines.

**Include:** graphics.h 

----------
#### GrSetLineColorMap()
	void	GrSetLineColorMap(
			GStateHandle	gstate,			/* subject GState */
			ColorMapMode	colorMap);		/* new color map mode for lines */
Set the mode to use when trying to draw lines in an unavailable color.

**Include:** graphics.h 

----------
#### GrSetLineEnd()
	void	GrSetLineEnd(
			GStateHandle 	gstate,			/* subject GState */
			LineEnd 		end);			/* new line end specification */
Set the end to use when drawing lines.

**Include:** graphics.h 

----------
#### GrSetLineJoin()
	void	GrSetLineJoin(
			GStateHandle	gstate,			/* subject GState */
			LineJoin 		join);			/* new line join specification */
Set the line join to use when drawing corners.

**Include:** graphics.h 

----------
#### GrSetLineMaskCustom()
	void	GrSetLineMaskCustom(
			GStateHandle	gstate,			/* subject GState */
			const DrawMask	* dm);			/* new line draw mask */
Set the drawing mask used when drawing lines.

**Include:** graphics.h 

----------
#### GrSetLineMaskSys()
	void	GrSetLineMaskSys(
			GStateHandle 		gstate,			/* subject GState */
			SystemDrawMask 		sysDM);			/* the new system line mask */
Set the drawing mask used when drawing lines.

**Include:** graphics.h 

----------
#### GrSetLineStyle()
	void	GrSetLineStyle(
			GStateHandle	 	gstate,			/* subject GState */
			LineStyle 			style,			/* new line style */
			word				skipDistance,	/* skip distance to first pair */
			const DashPairArray	* dpa,			/* dash definition */
			word				numPairs);		/* number of pairs */
Set the style, or "dottedness," to use when drawing lines.

**Include:** graphics.h 

----------
#### GrSetLineWidth()
	void	GrSetLineWidth(
			GStateHandle 		gstate,			/* subject GState */
			WWFixedAsDWord 		width);			/* new line width */
Set the line width to use when drawing lines.

**Include:** graphics.h 

----------
#### GrSetMiterLimit()
	void	GrSetMiterLimit(
			GStateHandle 		gstate,			/* subject GState */
			WWFixedAsDWord 		limit);			/* new miter limit */
Set the miter limit to use when drawing mitered corners.

**Include:** graphics.h 

----------
#### GrSetMixMode()
	void	GrSetMixMode(
			GStateHandle	gstate,				/* subject GState */
			MixMode 		mode);				/* new mix mode */
Set the GState's mix mode, used to determine what happens when something 
is drawn on top of an existing drawing.

**Include:** graphics.h 

----------
#### GrSetNullTransform()
	void	GrSetNullTransform(
			GStateHandle	gstate);			/* subject GState */
Clear the coordinate transformation. Most applications will actually want to 
replace the coordinate transformation with the default transformation using 
**GrSetDefaultTransform()**.

**Include:** graphics.h 

----------
#### GrSetPalette()
	void	GrSetPalette(
			GStateHandle 	gstate,			/* subject GState */
			SetPalType 		type,			/* SPT_DEFAULT or SPT_CUSTOM */
			const RGBValue 	*buffer,		/* array of palette entries */
			word			index, 			/* First element to change */
			word			numEntries);	/* number of entries in array */
Set one or more entries in a palette, a window's color lookup table.

**Include:** graphics.h 

----------
#### GrSetPaletteEntry()
	void	GrSetPaletteEntry(
			GStateHandle	gstate,		/* subject GState */
			word			index,		/* index in palette to set */
			word			red,		/* new RGB color values for entry */
			word			green,
			word			blue);
Set one entry in a palette, a GState's color lookup table.

**Include:** graphics.h 

----------
#### GrSetPath()
	void	GrSetPath(
			GStateHandle 	gstate,				/* subject GState */
			MemHandle  		pathGString);		/* handle of path's block */
Takes the passed GState's path with the path encoded in the block with the 
passed handle. To get such a handle, call **GrGetPath()**

**Include:** graphics.h 

----------
#### GrSetPrivateData()
	void	GrSetPrivateData(
			GStateHandle	gstate,				/* subject GState */
			word			dataAX,				/* data to set */
			word			dataBX,
			word			dataCX,
			word			dataDX);
Set the private data for a GState.

**Include:** graphics.h 

----------
#### GrSetStrokePath()
	void	GrSetStrokePath(
			GStateHandle	gstate);			/* subject GState */
Replace a GState's path with the path resulting from stroking the original 
path. Note that this stroked path may be drawn, but may not be used for 
clipping.

**Include:** graphics.h 

----------
#### GrSetSubscriptAttr()
	void 	GrSetSubscriptAttr(
			GStateHandle 		gstate,			/* subject GState */
			ScriptAttrAsWord 	attrs);			/* new subscript percentages */
Get the attributes used when drawing subscript characters.

**Include:** font.h 

----------
#### GrSetSuperscriptAttr()
	void 	GrSetSuperscriptAttr(
			GStateHandle 		gstate,		/* subject GState */
			ScriptAttrAsWord 	attrs);		/* new superscript percentages */
Get the attributes used when drawing superscript characters.

**Include:** font.h 

----------
#### GrSetTextAttr()
	void	GrSetTextAttr(
			GStateHandle		gstate,		/* subject GState */
			const	TextAttr	* ta);		/* pointer to text attributes */
Set all attributes used when drawing characters and text strings.

**Include:** graphics.h 

----------
#### GrSetTextColor()
	void	GrSetTextColor(
			GStateHandle	gstate,			/* subject GState */
			ColorFlag		flag,			/* color flag */
			word			redOrIndex,		/* palette index or red RGB value */
			word			green,			/* green RGB value or zero */
			word			blue);			/* blue RGB value or zero */
Set the color used when drawing text.

**Include:** graphics.h 

----------
#### GrSetTextColorMap()
	void	GrSetTextColorMap(
			GStateHandle		gstate,			/* subject GState */
			ColorMapMode 		colorMap);		/* new color mapping mode */
Set the mode used when trying to draw text in an unavailable color.

**Include:** graphics.h 

----------
#### GrSetTextMaskCustom()
	void	GrSetTextMaskCustom(
			GStateHandle		gstate,			/* subject GState */
			const DrawMask		* dm);			/* pointer to custom mask */
Set the drawing mask used when drawing text.

**Include:** graphics.h 

----------
#### GrSetTextMaskSys()
	void	GrSetTextMaskSys(
			GStateHandle		gstate,			/* subject GState */
			SystemDrawMask 		sysDM);			/* new system draw mask */
Set the drawing mask used when drawing text.

**Include:** graphics.h 

----------
#### GrSetTextMode()
	void	GrSetTextMode(
			GStateHandle	gstate,				/* subject GState */
			TextMode 		bitsToSet,			/* TextMode flags to set */
			TextMode 		bitsToClear);		/* TextMode flags to clear */
Set the text mode associated with a GState. Using this routine, it is possible 
to change the vertical offset used when drawing text.

**Include:** graphics.h 

----------
#### GrSetTextPattern()
	void 	GrSetTextPattern(
			GStateHandle 		gstate,			/* subject GState */
			GraphicPattern 		pattern);		/* new graphic pattern for text */
Set the graphic pattern used when drawing text.

**Include:** graphics.h 

----------
#### GrSetTextSpacePad()
	void	GrSetTextSpacePad(
			GStateHandle		gstate,			/* subject GState */
			WWFixedAsDWord		padding);		/* new space padding */
Set the space pad used when drawing text strings.

**Include:** graphics.h 

----------
#### GrSetTextStyle()
	void	GrSetTextStyle(
			GStateHandle	gstate,				/* subject GState */
			TextStyle 		bitsToSet,			/* TextStyle flags to set */
			TextStyle		bitsToClear);		/* TextStyle flags to clear */
Set the style to use when drawing text.

**Include:** graphics.h 

----------
#### GrSetTrackKern()
	void	GrSetTrackKern(
			GStateHandle	gstate,			/* subject GState */
			word			tk);			/* degree of track kerning */
Set the track kerning to use when drawing text strings.

**Include:** graphics.h 

----------
#### GrSetTransform()
	void	GrSetTransform(
			GStateHandle		gstate,			/* subject GState */
			const TransMatrix 	* tm);			/* new transformation matrix */
Set the GState's coordinate transformation.

**Include:** graphics.h 

----------
#### GrSetVMFile()
	void	GrSetVMFile(
			GStateHandle	gstate,			/* subject GState */
			VMFileHandle 	vmFile);		/* new transformation matrix */
Update the VM file associated with a GState (this may apply when working 
with certain kinds of bitmaps and GStrings).

**Include:** graphics.h 

----------
#### GrSetWinClipPath()
	void	GrSetWinClipPath(
			GStateHandle		gstate,			/* subject GState */
			PathCombineType		params,			/* how paths are combined */
			RegionFillRule		rule);			/* ODD_EVEN or WINDING */
Restrict the window's clipping region by intersecting it with the passed path.

**Include:** graphics.h 

----------
#### GrSetWinClipRect()
	void	GrSetWinClipRect(
			GStateHandle		gstate,		/* subject GState */
			PathCombineType		flags,		/* how paths are combined */
			sword				left,		/* new clipping rectangle bounds */
			sword				top,
			sword				right,
			sword				bottom);
Restrict the window's clipping region by intersecting it with the passed 
rectangle.

**Include:** graphics.h 

----------
#### GrSqrRootWWFixed()
	WWFixedAsDWord GrSqrRootWWFixed(
			WWFixedAsDWord	i);			/* number to get the square root of */
Compute the square root of a fixed point number.

**Include:** graphics.h 

----------
#### GrTestPath()
	Boolean	GrTestPath(
			GStateHandle	gstate,			/* subject GState */
			GetPathType		ptype);			/* Type of path to check for */
Determine whether the GState has a path of the specified type.

**Include:** graphics.h 

----------
#### GrTestPointInPath()
	Boolean	GrTestPointInPath(
			GStateHandle	gstate,				/* subject GState */
			word			xPos,				/* point to test */
			word			yPos,
			RegionFillRule	rule);				/* ODD_EVEN or WINDING */
Determine whether the passed point falls in the interior of the GState's path.

**Include:** graphics.h 

----------
#### GrTestPointInPolygon()
	Boolean	GrTestPointInPolygon(
			GStateHandle	gstate,			/* subject GState */
			RegionFillRule	rule,			/* ODD_EVEN or WINDING */
			Point			* list,			/* array of points in polygon */
			word			numPoints,		/* number of points in array */
			sword			xCoord,			/* coordinates of point to test */
			sword			yCoord);
Determine whether the passed point lies in the interior of the passed 
polygon.

**Include:** graphics.h 

----------
#### GrTestPointInReg()
	Boolean 	GrTestPointInReg( 
			const Region	* reg,			/* pointer to region */
			sword 			x,				/* coordinates of point to test */
			sword 			y,
			Rectangle		*boundingRect);	/* returned bounding rectangle,
											 * if point in region */
Determine whether a point lies within the passed region. If the point is not 
in the region, the return value is *true*.

**Include:** graphics.h 

----------
#### GrTestRectInReg()
	TestRectReturnType GrTestRectInReg( 
			const Region	* reg		/* pointer to region */
			sword			left,		/* bounds of rectangle to be tested */
			sword			top,
			sword			right,
			sword			bottom);
Determine whether a rectangle lies within the clip region.

**Structures:** 

	typedef ByteEnum TestRectReturnType;
		TRRT_OUT,			/* rectangle completely out of region */
		TRRT_PARTIAL,		/* rectangle partially in region */
		TRRT_IN 			/* rectangle completely in region */

**Include:** graphics.h 

----------
#### GrTextWidth()
	word	GrTextWidth(
			GStateHandle	gstate,			/* subject GState */
			const Chars		* str,			/* text string to check */
			word			size);			/* maximum number of
											 * characters to check */
Compute the space the passed text string would require in a line of text. Use 
**GrGetTextBounds()** to determine the area necessary to render the text.

**Include:** graphics.h 

----------
#### GrTextWidthWWFixed()
	WWFixedAsDWord 	GrTextWidthWWFixed( /* returns width << 16 */
			GStateHandle	gstate,			/* subject GState */
			const Chars		* str,			/* text string to check */
			word			size)			/* maximum number of
											 * characters to check */
Compute the spacing the passed text string would require in a line of text, 
accurate to a fraction of a point. Use **GrGetTextBounds()** to determine the 
area necessary to render the text.

**Include:** graphics.h 

----------
#### GrTransform()
	XYValueAsDWord 	GrTransform(
			GStateHandle	gstate,			/* subject GState */
			sword 			xCoord,			/* coordinates to transform */
			sword 			yCoord);
Apply the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrTransformDWFixed()
	void	GrTransformDWFixed(
			GStateHandle	gstate,			/* subject GState */
			PointDWFixed	* coord);		/* coordinates to transform */
Apply the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrTransformDWord()
	void 	GrTransformDWord(
			GStateHandle	gstate,			/* subject GState */
			sdword			xCoord,			/* coordinates to transform */
			sdword			yCoord,
			PointDWord		* deviceCoordinates);	/* pointer to returned 
													 *device coordinates */
Apply the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrTransformWWFixed()
	void	GrTransformWWFixed(
			GStateHandle	gstate,				/* subject GState */
			WWFixedAsDWord	xPos,				/* coordinates to transform */
			WWFixedAsDWord	yPos,
			PointWWFixed	* deviceCoordinates);	/* pointer to returned 
													 *device coordinates */
Apply the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrUDivWWFixed()
	WWFixedAsDWord GrUDivWWFixed(
			WWFixedAsDWord		dividend,
			WWFixedAsDWord		divisor);
Compute an unsigned division of two fixed point numbers.

**Include:** graphics.h 

----------
#### GrUntransform()
	XYValueAsDWord GrUnTransformCoord(
			GStateHandle	gstate,			/* subject GState */
			sword			xCoord,			/* coordinates to untransform */
			sword			yCoord);
Apply the reverse of the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrUntransformDWFixed()
	void	GrUnTransCoordDWFixed(
			GStateHandle	gstate,			/* subject GState */
			PointDWFixed	* coord);		/* coordinates to untransform */
Apply the reverse of the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrUntransformDWord()
	void	GrUnTransformExtCoord(
			GStateHandle	gstate,			/* subject GState */
			sdword			xCoord,			/* coordinates to untransform */
			sdword			yCoord,
			PointDWord		* documentCoordinates);	/* pointer to returned
													 *device coordinates */
Apply the reverse of the device's transformation to the passed point.

**Include:** graphics.h 

----------
#### GrUntransformWWFixed()
	void	GrUnTransCoordWWFixed(
			GStateHandle		gstate,			/* subject GState */
			WWFixedAsDWord		xPos,			/* coordinates to untransform */
			WWFixedAsDWord		yPos,
			PointWWFixed		* documentCoordinates);	/* pointer to returned
														 *device coordinates */
Apply the reverse of the device's transformation to the passed point.

**Include:** graphics.h 

[Routines E-F](rroute_f.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Routines H-L](rrouth_l.md)