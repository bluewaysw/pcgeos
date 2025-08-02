## 2.4 Routines H-L

----------
#### HandleModifyOwner
Modifies the owner of a block. If passed a process handle, changes the parent 
process instead of the owner.

**Pass:**  
bx - Handle of block to modify.  
ax - Handle of block's new owner.

**Returns:**  
Nothing.

**Destroyed:**  
ax

**Library:** heap.def

----------
#### HandleP
Sets a semaphore on the passed block. This provides the caller with exclusive 
access to the block if all other processes use the **HandleP/HandleV** 
mechanism. The *HM_otherInfo* field of the block is used for the semaphore 
and must not be used for any other purpose.

*HM_otherInfo* stores the state of the semaphore. If the block is not owned, 
this value is 1. If this block is owned but no threads are waiting, this value is 
zero. Otherwise, *HM_otherInfo* stores the handle of the first thread waiting 
to access the block.

**HandleP** and **HandleV** can be used both on memory handles and file 
handles. 

**Pass:**  
bx - Handle of block to own.

**Returns:**  
bx - Handle of block owned.

**Destroyed:**  
Nothing.

**Library:** heap.def

----------
#### HandleV
Releases a semaphore on the given block.

**Pass:**  
bx - Handle of block to release.

**Returns:**  
bx - Handle of block released.

**Destroyed:**  
Nothing. (Flags preserved.)

**Library:** heap.def

----------
#### HugeArrayAppend

Appends element(s) to the tail end of a Huge Array. If elements are of fixed 
size, this routine may append several elements. If elements are of variable 
size, this routine appends one element to the tail end of the Huge Array.

**Pass:**  
bx - VM file handle of the Huge Array.  
di - VM block handle of the Huge Array.  
cx - Number of elements to append (if elements are of fixed size) 
or size of new element (if elements are variable sized and only 
one element is being appended).  
bp.si - Fptr to buffer holding element data. If **bp** = 0 then allocate 
space but do not initialize the data.

**Returns:**  
dx:ax - New element number. If multiple elements are appended, 
this is the number of the first element.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayCompressBlocks
Compress all the free space out of VM blocks containing a HugeArray data.

**Pass:**  
bx.di - VM File and Block handle of the huge array.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayContract
Deletes element(s) in a Huge Array. The elements may be of fixed or variable 
size but must already be locked down. Elements will be deleted starting at 
the element location passed.

**Pass:**  
ds:si - Pointer to the locked Huge Array element.  
cx - Number of elements to delete.

**Returns:**  
ds:si - Pointer to same element number. (**ds** may have changed.)  
ax - Number of elements available through the pointer. If **ax** = 0 
the Huge Array is now empty.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayCreate
Creates a Huge Array. Allocates a VM block for the directory block, initializes 
the directory block header and allocates enough VM blocks for any initial 
elements.

**Pass:**  
bx - VM file handle in which to create the array.  
cx - Number of bytes to allocate per element. Pass zero if 
elements are of variable size.  
di - Size to allocate for the Huge Array directory block's header. 
Pass zero if no additional space beyond that of 
**HugeArrayDirectory** is needed. If you want to have 
additional space, make sure the size is at least as large as the 
size of **HugeArrayDirectory** plus the size of the additional 
information.

**Returns:**  
di - Huge Array handle (VM block handle).

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayDelete
Locks down a Huge Array VM block and deletes element(s) starting at the 
passed element number.

**Pass:**  
bx - VM file handle of Huge Array.  
di - VM block handle of Huge Array.  
cx - Number of elements to delete.  
dx:ax - Element number. New element(s) will be deleted starting at 
this number.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayDestroy
Destroys a Huge Array. This routine frees all blocks in the Huge Array.

**Pass:**  
bx - VM file handle of Huge Array to destroy.  
di - VM block handle of the Huge Array to destroy.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayDirty
Marks a VM block containing an element in a Huge Array dirty

**Pass:**  
ds - Pointer to a locked Huge Array element.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayEnum
Calls a callback routine for multiple elements within a Huge Array. Pass this 
routine the element to start at, the number of elements to call the routine on, 
and the address of the callback routine. The Index number of elements is a 
zero-based integer.

The callback routine may not do anything which would invalidate any 
pointers to the Huge Array. For example, it may not allocate, delete, or resize 
any of the elements. The callback routine should restrict itself to examining 
elements and altering them without resizing them.

**Pass:**  
ax, cx, dx, bp, es - Set for callback

**Pass on stack:**  
 - VM file handle of the Huge Array  
 - VM block handle of the Huge Array  
 - Pointer to a Boolean callback routine  
 - Index of first element to start enumerations on.  
 - Number of elements to enumerate (or -1 to continue to the 
end of the array)

**Returns:**  
CF - Set if callback aborted, clear otherwise.  
ax, cx, dx, bp, es - Returned from callback.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ds:di - Pointer to element.  
(For fixed size elements):  
ax, cx, dx, bp, es - data passed to **HugeArrayEnum** (as 
changed by previous iterations of callback).  
(For variable sized elements):  
ax - element size.  
cx, dx, bp, es - data passed to **HugeArrayEnum**.  
**Return:**  
CF - Set if callback aborted, clear otherwise (as 
changed by previous iterations of callback).  
ax, cx, dx, bp, es - Data for next callback.  
**May Destroy:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayExpand
Insert element(s) into a locked Huge Array. Elements are inserted starting at 
the passed element position.

**Pass:**  
ds:si - Pointer to locked Huge Array element.  
cx - (For fixed size elements):  
 - Number of elements to insert.  
 - (For variable sized elements):  
 - Size of element at **ds:si**.  
bp.di - Fptr to buffer holding element data. If **bp** = 0 then allocate 
space but don't initialize data.

**Returns:**  
ds:si - Pointer to first new element added.  
ax - Number of consecutive elements available starting with 
returned pointer. (If **ax** = 0, pointer is invalid.)  
cx - Number of consecutive elements available before (and 
including) the requested element.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayGetCount
Retrieves the number of element(s) in a Huge Array.

**Pass:**  
bx - VM file handle of the Huge Array.  
di - VM block handle of the Huge Array.

**Returns:**  
dx.ax - Number of elements in the Huge Array.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayInsert
Locks down and insert element(s) into a HugeArray.

**Pass:**  
bx - VM file handle of the HugeArray.  
di - VM block handle of the HugeArray.  
cx - (For fixed size elements)  
 - Number of elements to insert  
 - (For variable sized elements)  
 - Size of new element.  
dx:ax - Element number. New element will be inserted before this 
one.  
bp.si - Fptr to buffer holding element data. If **bp** = 0 then allocate 
space but do not initialize data.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayLock
Locks down a HugeArray element. To unlock a locked HugeArray element, 
use **HugeArrayUnlock**.

**Pass:**  
bx - VM file handle of HugeArray.  
di - VM block handle of HugeArray.  
dx.ax - Element number to dereference.

**Returns:**  
ds:si - Pointer to requested element.  
ax - Number of consecutive elements available, starting with the 
returned pointer. If **ax** = 0, pointer is invalid.  
cx - Number of consecutive elements available before (and 
including) the requested element.  
dx - Size of the element.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayLockDir
Locks a HugeArray directory block.

**Pass:**  
bx - VM file handle of HugeArray.  
di - VM block handle of HugeArray.

**Returns:**  
ax - Segment address of directory block.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayNext
Locks and points to the next HugeArray element. 

**Pass:**  
ds:si - Pointer to element in block.

**Returns:**  
ds:si - Pointer to next element. This may be in a different block.  
ax - Number of consecutive elements available with returned 
pointer. Returns zero if we were at the last element in the 
array.  
dx - (For variable sized elements):  
 - Size of the element. Otherwise dx is undefined.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayPrev
Locks and points to the previous Huge Array element.

**Pass:**  
ds:si - Pointer to element in block.  

**Returns:**  
ds:si - Pointer to previous element. This may be in a different block.  
ds:di - Pointer to first element in block.  
ax - Number of elements available from first element in block to 
previous element. (For example, if **si** == **di**, then **ax** = 1.) 
Returns zero if we were at the first element in the array.  
dx - (For variable sized elements):  
 - Size of the element. Otherwise dx is undefined.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayReplace
Replace element(s) in a Huge Array.

**Pass:**  
bx - VM file handle of HugeArray.  
di - VM block handle of HugeArray.  
cx - (For fixed size elements)  
 - Number of elements to replace.  
 - (For variable sized elements)  
 - Size of new element.  
dx:ax - Element number. New element will be replaced starting with 
this one.  
bp.si - Fptr to buffer holding element data. If **bp** = 0 then replace all 
bytes with 0.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayResize
Resizes an array element. If the element is resized to a smaller size then data 
at the end of the element is truncated (and lost). If it gets larger, the new data 
is initialized to zero.

**Pass:**  
bx - VM file handle of HugeArray.  
di - VM block handle of HugeArray.  
dx:ax - Element number.  
cx - Size of new element.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### HugeArrayUnlock
Unlocks a previously locked Huge Array element. 

**Pass:**  
ds - Pointer to element block containing element.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing. (Flags preserved.)

**Library:** hugearr.def

----------
#### HugeArrayUnlockDir
Unlocks a previously locked block containing the **HugeArrayDirectory**.

**Pass:**  
ds - Pointer to block of **HugeArrayDirectory**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** hugearr.def

----------
#### IACPConnect
Establish a connection with one or all of the servers on a particular list.

**Pass:**  
es:di - **GeodeToken** for the list  
ax - **IACPConnectFlags**  
bx - handle of **AppLaunchBlock** if server is to be launched, 
should none be registered  
cx:dx - optr of client object, if IACPCF_CLIENT_OD_SPECIFIED set in 
**ax**.

**Returns:**  
CF - Set on error; clear on success.  
ax - Error code on error (either **IACPConnectError** or 
**GeodeLoadError**). Destroyed on success.  
bp - **IACPConnection** token.  
cx - Number of servers connected to.

**Destroyed:**  
bx, dx.

**Library:** iacp.def

----------
#### IACPCreateDefaultLaunchBlock
Utility routine to create an AppLaunchBlock to be given to IACPConnect. 
The block is initialized with the following defaults:

 - IACP will locate the application, given its token;  
 - The initial directory will be SP_DOCUMENT;  
 - There will be no initial data file;  
 - The application will determine the generic parent for itself;  
 - No one will be notified in event of an error; and  
 - No extra data is passed.

**Pass:**  
dx - mode in which server should be launched:  
MSG_GEN_PROCESS_OPEN_APPLICATION or 
MSG_GEN_PROCESS_OPEN_ENGINE .

**Returns:**  
CF - Clear if block created, set if couldn't allocate memory.  
dx - Handle of block containing **AppLaunchBlock**.

**Destroyed:**  
Nothing.

**Library:** iacp.def

----------
#### IACPFinishConnect
Complete the process of connecting. Called by the server when it's ready to 
accept messages from the client.

**Pass:**  
cx:dx - optr of server object  
bp - **IACPConnection** token

**Returns:**  
Nothing

**Destroyed:**  
Nothing

**Library:** iacp.def

----------
#### IACPGetDocumentID
Figure the 48-bit ID for a data file, dealing with links.

**Pass:**  
ds:dx - directory in which document resides  
bx - disk on which document resides  
ds:si - name of document    

**Returns:**  
CF - Set on error; clear on success.  
ax - **FileError** on error; disk handle on success.  
cx.dx - **FileID** on success; destroyed on error.

**Destroyed:**  
Nothing.

**Library:** iacp.def

----------
#### IACPGetServerNumber
Returns the number a server object is for a particular IACP connection, so 
the client can use the number to direct a message to a particular server.

**Pass:**  
bp - **IACPConnection** token  
cx:dx - optr server object

**Returns:**  
ax - Server number (zero if object isn't a server for the 
connection).

**Destroyed:**  
Nothing.

**Library:** iacp.def

----------
#### IACPLostConnection
Utility routine for server objects to handle 
MSG_META_IACP_LOST_CONNECTION

**Pass:**  
*ds:si - Server object  
bp - **IACPConnection** token 

**Returns:**  
Nothing

**Destroyed:**  
ax, cx, dx, bp, bx, di.

**Library:** iacp.def

----------
#### IACPProcessMessage
Utility routine to handle a MSG_META_IACP_PROCESS_MESSAGE. Can 
be bound as the method for this message for any class that might receive it.

**Pass:**  
cx - handle of message to send  
dx - **TravelOption** or -1 if message should be dispatched via 
**MessageDispatch**.  
bp - handle of message to send after **cx** is processed, or zero if no 
completion notification needed.  
*ds:si - server object

**Returns:**  
Nothing

**Destroyed:**  
ax, bx, cx, dx, bp, si, di

**Library:** iacp.def

----------
#### IACPRegisterDocument
Register a document as being open, specifying the server to which to connect 
to communicate about the document.

**Pass:**  
bx:si - optr of server object  
ax - disk handle  
cx.dx - **FileID** 

**Returns:**  
Nothing

**Destroyed:**  
Nothing

**Library:** iacp.def

----------
#### IACPRegisterServer
Register an object as a server for a particular list. Can also be used to change 
the mode in which the server is registered.

**Pass:**  
es:di - **GeodeToken** for the list  
^lcx:dx - server object  
al - **IACPServerMode** structure.  
ah - **IACPServerFlags** structure.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** iacp.def

----------
#### IACPSendMessage
Send a message through an IACP connection to all connected servers, or to 
the client, depending on which side is doing the sending.

**Pass:**  
bp - **IACPConnection** token  
bx - recorded message to send  
dx - **TravelOption**, -1 if recorded message contains the proper 
destination already  
cx - Recorded message to send on completion, zero if none  
ax - **IACPSide** doing the sending.

**Returns:**  
ax - Number of servers to which message was sent.

**Destroyed:**  
bx, cx, dx, both recorded messages.

**Library:** iacp.def

----------
#### IACPSendMessageToServer
Send a message through an IACP connection to a specific connected server.

**Pass:**  
bp - **IACPConnection** token  
bx - recorded message to send  
dx - **TravelOption**, -1 if recorded message contains the proper 
destination already  
cx - Recorded message to send on completion, zero if none  
ax - Server number.

**Returns:**  
ax - Number of servers to which message was sent (One or zero).

**Destroyed:**  
bx, cx, dx, both recorded messages.

**Library:** iacp.def

----------
#### IACPShutdown
Sever an IACP connection. MSG_META_IACP_LOST_CONNECTION is sent to 
the other side of the connection.

**Pass:**  
bp - IACPConnection to shut down  
cx:dx - optr of server object, or **cx** == 0 if client is shutting down.

**Returns:**  
Nothing.

**Destroyed:**  
ax.

**Library:** iacp.def

----------
#### IACPShutdownAll
Shutdown all connections open to or from an object.

**Pass:**  
cx:dx - optr of client or server object for which all connections are to 
be shutdown.

**Returns:**  
Nothing.

**Destroyed:**  
ax

**Library:** iacp.def

----------
#### IACPShutdownConnection
Utility routine to handle MSG_META_IACP_SHUTDOWN_CONNECTION, as 
generated by a call to **IACPLostConnection**.

**Pass:**  
*ds:si - server object  
bp - **IACPConnection** to shut down.   

**Returns:**  
Nothing.

**Destroyed:**  
ax, cx, dx, bp.

**Library:** iacp.def

----------
#### IACPUnregisterDocument
Indicate a document is closed. New-connection messages may still be queued 
based on the document having been registered, so the caller will need to 
handle those gracefully.

**Pass:**  
ax - disk handle  
cx:dx - **FileID**  
bx:si - optr of server  

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** iacp.def

----------
#### IACPUnregisterServer
Unregister an object as a server for a particular list.

**Pass:**  
es:di - **GeodeToken** for the list  
cx:dx - server object   

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** iacp.def

----------
#### ImpexCreateTempFile
Creates and opens a unique Metafile in the waste directory.

**Pass:**  
es:di - File name buffer (of size FILE_LONGNAME_BUFFER_SIZE).  
ax - IMPEX_TEMP_VM_FILE or IMPEX_TEMP_NATIVE_FILE.

**Returns:**  
es:di - File name buffer filled.  
bp - File handle.  
ax - **TransError** (or zero if no error).  
bx - Memory handle of error text if **ax** = TE_CUSTOM.

**Destroyed:**  
Nothing.

**Library:** impex.def

----------
#### ImpexDeleteTempFile
Closes and deletes a metafile in the waste directory.

**Pass:**  
ds:dx - File name buffer (of size FILE_LONGNAME_BUFFER_SIZE).  
bx - File handle.  
ax - IMPEX_TEMP_VM_FILE or IMPEX_TEMP_NATIVE_FILE.

**Returns:**  
ax - **TransError** (or zero if no error).  
bx - Memory handle of error text if **ax** = TE_CUSTOM.

**Destroyed:**  
Nothing.

**Library:** impex.def

----------
#### ImpexExportToMetafile
Converts a transfer format into a metafile.

**Pass:**  
bx - Handle of the metafile translation library to use.  
ax - Entry point number of library routine to call.  
dx:cx - VM chain containing transfer format.  
di - VM file handle of transfer format.  
bp - Handle of the metafile (open for read/write).  
ds - Additional data for metafile as needed.  
si - Additional data for metafile as needed.

**Returns:**  
ax - **TransError** (or zero if no error).  
bx - Memory handle of error text if **ax** = TE_CUSTOM.

**Destroyed:**  
Nothing.

**Library:** impex.def

----------
#### ImpexImportExportCompleted
Sends a message back to the Import/ExportControl object stating that the 
application has completed it's import or export operation.

**Pass:**  
ss:bp - **ImpexTranslationParams**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** impex.def

----------
#### ImpexImportFromMetafile
Converts a metafile into a transfer format.

**Pass:**  
bx - Handle of the metafile (open for reading).  
ax - Entry point number of library routine to call.  
di - VM file handle to hold transfer format.  
bp - Handle of metafile translation library to use.  
ds - Additional data for metafile as needed.  
si - Additional data for metafile as needed.

**Returns:**  
dx:cx - VM chain containing transfer format.  
ax - **TransError** (or zero if no error).  
bx - Memory handle of error text if **ax** = TE_CUSTOM.

**Destroyed:**  
Nothing.

**Library:** impex.def

----------
#### ImpexUpdateImportExportStatus
Apprise the user of the status of an import or export. This routine should only 
be called by translation libraries, and can be called at any time during the 
import/export process. If a translation library chooses not to call this 
function, the default import/export message will be displayed.

**Pass:**  
ds:si - String to display to user (NULL string to not display a new 
string)  
ax - Percentage completed so far (this value may range from zero 
to 100, or may be -1 to signal not to display any percentage)   

**Returns:**  
ax - *True* (i.e., non-zero) to continue import/export; *false* to stop 
import/export.

**Destroyed:**  
Nothing.

**Library:**    impex.def

----------
#### InitFileDeleteCategory
Deletes an entire category (and therefore all its associated keys) from the 
GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) to delete from the 
GEOS.INI file.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileDeleteEntry
Deletes a "key" entry from the GEOS.INI file. Only matching keys within the 
passed category will be deleted. Keys in other categories are unaffected.

**Pass:**  
ds:si - Category (null-terminated ASCII string) containing the key 
within the GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) to delete from the 
GEOS.INI file.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileDeleteStringSection
Deletes the specific string "blob" starting at the zero-based string number. 
"Blobs" are usually set off from each other in the GEOS.INI file with CR or LF 
characters.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of string within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of string within the 
GEOS.INI file.  
ax - Null-terminated string number "blob" to remove.

**Returns:**  
CF - Clear if successful, otherwise set.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileEnumStringSection
Calls the passed function on each matching string section within the 
GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of string within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of string within the 
GEOS.INI file.  
bp - **InitFileReadFlags** (IFRF_SIZE is of no importance).  
di:ax - Address (fptr) of callback routine.  
es - Additional data to pass to callback routine.  
bx - Additional data to pass to callback routine.

**Returns:**  
bx, es - Data from callback routine.  
CF  Clear if enumeration successful, set if failed.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:** (must be declared as far)  
**Passed:**  
ds:si - String section (null-terminated).  
dx - Section number.  
cx - Length of section.  
es - Additional data.  
bx - Additional data.  
**Return:**  
bx, es - Data returned from callback routine.  
CF - Clear to continue enumeration, set to stop 
enumeration.  
**May Destroy:**  
ax, cx, dx, di, si, bp, es

**Library:** initfile.def

----------
#### InitFileGetTimeLastModified
Returns the time (from system counter) when the GEOS.INI file was last 
written to.

**Pass:**  
Nothing.

**Returns:**  
cx:dx - System counter time when the GEOS.INI file was last written 
to.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileGrab
Grab exclusive access on the initfile routines, and use the passed buffer as a 
temporary init file.

**Pass:**  
ax - handle of memory block that will be used for init file 
reads/writes  
bx - file handle  
cx - size of file   

**Returns:**  
CF - Set on error; clear on success. Errors can occur when the init 
file contains non-ASCII characters or is not in a valid format.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileReadBoolean
Returns the Boolean value specified in the given category and key of the 
GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of data within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of data within the 
GEOS.INI file.

**Returns:**  
CF - Clear if successful.  
ax - (If CF = 0) ffffh = TRUE, 0 = FALSE.  
 - If CF != zero, then **ax** is unchanged.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileReadData
Locates the contents of the given category and key of the GEOS.INI file and 
returns a pointer to the associated data.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of data within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of data within the 
GEOS.INI file.  
bp - **InitFileReadFlags**. (If IFRF_SIZE = 0 then a buffer will be 
allocated for the string, otherwise IFRF_SIZE should contain 
the size of the buffer and **es:di** will contain the address of 
the buffer to fill.)  
es:di - (If IFRF_SIZE is non-zero) Buffer to place string into.

**Returns:**  
CF - Clear if successful.  
cx - Number of bytes retrieved (excluding null-terminator).  
bx - (If IFRF_SIZE = 0 was passed in **bp**) Memory handle to block 
containing entry; otherwise not defined.  
es:di - (If IFRF_SIZE was non-zero) Buffer filled.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileReadInteger
Returns the integer value specified in the given category and key of the 
GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of data within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of data within the 
GEOS.INI file.

**Returns:**  
CF - Clear if successful.  
ax - (If CF = 0) Integer value, otherwise unchanged.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileReadString
Locates the contents of the given category and key of the GEOS.INI file and 
returns a pointer to the associated string.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of data within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of data within the 
GEOS.INI file.  
bp - **InitFileReadFlags**. (If IFRF_SIZE = 0 then a buffer will be 
allocated for the string, otherwise IFRF_SIZE should contain 
the size of the buffer and **es:di** will contain the address of 
the buffer to fill.)  
es:di - (If IFRF_SIZE is non-zero) Buffer to place string into.

**Returns:**  
CF - Clear if successful.  
cx - Number of bytes retrieved (excluding null-terminator).  
bx - (If IFRF_SIZE = 0 was passed in bp) MemHandle to block 
containing entry; otherwise not defined.  
es:di - (if IFRF_SIZE was non-zero) Buffer filled.

**Destroyed:**  
bx (if not returned).

**Library:** initfile.def

----------
#### InitFileReadStringSection
Locates the contents of the given category and key of the GEOS.INI file, copies 
a specified section of the string, and returns a pointer to the copied string 
section.

**Pass:**  
ds:si - Category (null-terminated ASCII string) of data within the 
GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) of data within the 
GEOS.INI file.  
ax - Zero-based integer specifying the start of the string section 
"blob" to copy.  
bp - **InitFileReadFlags**. (If IFRF_SIZE = 0 then a buffer will be 
allocated for the string, otherwise IFRF_SIZE should contain 
the size of the buffer and **es:di** will contain the address of 
the buffer to fill.)  
es:di - (If IFRF_SIZE is non-zero) Buffer to place string into.

**Returns:**  
CF - Clear if successful.  
cx - Number of bytes retrieved (excluding null-terminator).  
bx - (If IFRF_SIZE = 0 was passed in  - ) Memory handle to block 
containing entry; otherwise not defined.  
es:di - (If IFRF_SIZE was non-zero) Buffer filled.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileRevert
Restores the GEOS.INI to its backed-up previous state.

**Pass:**  
Nothing.

**Returns:**  
CF - Clear if successful, set otherwise.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileSave
Saves the GEOS.INI file.

**Pass:**  
Nothing.

**Returns:**  
CF - Clear if successful, set otherwise.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileWriteBoolean
Writes out a Boolean value to the GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) to place the Boolean 
value within the GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) to place the Boolean value 
within the GEOS.INI file.  
ax - Boolean value. (Non-zero = TRUE, zero = FALSE.)

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileWriteData
Writes out a string of data (which may represent a null-terminated text 
string, a Boolean value, or an integer value) to the GEOS.INI file. You may 
instead use **InitFileWriteString**, **InitFileWriteInteger**, or 
**InitFileWriteBoolean**.

**Pass:**  
ds:si - Category (null-terminated ASCII string) to place the string of 
data within the GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) to place the string of data 
within the GEOS.INI file.  
es:di - Buffer containing the string of data to write out.  
bp - Size of buffer.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileWriteInteger
Writes out an integer to the GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) to place the integer 
of data within the GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) to place the integer of 
data within the GEOS.INI file.  
bp - Integer value.

**Returns:**  
CF - Clear if successful. Otherwise, set.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileWriteString
Writes out a string to the GEOS.INI file.

**Pass:**  
ds:si - Category (null-terminated ASCII string) to place the string of 
data within the GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) to place the string of data 
within the GEOS.INI file.  
es:di - Body (null-terminated ASCII string) to write out to the 
category and key of the GEOS.INI file.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InitFileWriteStringSection
Appends a string onto the end of a pre-existing GEOS.INI entry.

**Pass:**  
ds:si - Category (null-terminated ASCII string) to place the string of 
data within the GEOS.INI file.  
cx:dx - Key (null-terminated ASCII string) to place the string of data 
within the GEOS.INI file.  
es:di - String (null-terminated ASCII string) to append onto the end 
of the category and key entries of the GEOS.INI file entry.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** initfile.def

----------
#### InkCompress
Compress ink data from a VisInk object.

**Pass:**  
cx - Handle of block containing ink data (This will not be freed by 
**InkCompress**):  
 - word numPoints  
 - **InkPoint**  
 - **InkPoint**  
 - **InkPoint**  
 - ...  
bx - file in which to create DB Item  
ax:di - **DBItem** to hold data (pass 0:0 to create a new DBItem)   

**Returns:**  
ax.di - **DBItem** containing compressed ink data.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkDBGetDisplayInfo
Returns the current folder handle, note ID if any is selected and the page 
number within the note.

**Pass:**  
bx - File handle (or override).

**Returns:**  
ax.di - Folder handle.  
dx.cx - Note ID.  
bp  Page.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkDBGetHeadFolder
Returns the head (root) folder for the associated Ink DB file.

**Pass:**  
bx - File handle (or override).

**Returns:**  
ax.di - Folder handle.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkDBInit
Creates and initializes a new DB file for use by the Ink object. This routine 
must be called before calling any other Ink Database functions.

**Pass:**  
bx - Handle of file.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkDBSetDisplayInfo

Displays the contents of the passed Folder, Note, and Page display 
information, if applicable.

**Pass:**  
bx - File handle (or override).  
ax.di - Folder handle.  
dx.cx - Note ID.  
bp - Page.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkDecompress
Uncompresses compressed ink data so that it may be loaded to a VisInk 
object.

**Pass:**  
bx - File handle.  
ax:di - **DBItem** containing ink data.

**Returns:**  
bx**    **Block containing ink data or zero if out of memory.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderCreateSubFolder
Creates a new folder as a child of the passed folder.

**Pass:**  
ax.di - Folder ID of parent folder (or null:null if no parent).  
bx - File handle.

**Returns:**  
ax.di - New child folder.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderDelete
Deletes a folder. If the folder contains children, it recursively deletes all 
children.

**Pass:**  
ax.di - Folder to delete.  
bx - File handle (or override).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderDepthFirstTraverse
Performs a depth-first traversal of the folder tree, calling the passed routine 
with all encountered folders.

**Pass:**  
ax.di - Folder at top of tree.  
bx - File handle.  
cx:dx - Callback routine (fptr).  
bp - extra data to pass to callback routine.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderDisplayChildInList
Displays a note or folder's name in a GenDynamicList. This routine builds 
and sends a moniker to the passed list.

**Pass:**  
ax.di - Folder ID.  
bx - File handle.  
cx:dx - Optr of GenDynamicList.  
bp - Entry number of child we want to display in list.  
si - Non zero if you want to display folders (if this is zero, then the 
entry number will be based only on notes).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderGetChildInfo
Returns information on a folder's child, specifying whether the child is a 
folder or a note along with the child's ID number.

**Pass:**  
ax.di - Folder ID.  
bx - File handle.  
cx - Child number.

**Returns:**  
CF - Set if folder, clear if note.  
ax.di - Folder or note ID.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderGetChildNumber
Returns the child's number given its folder or note ID.

**Pass:**  
ax.di - Folder ID.  
bx - File handle.  
dx.cx - Note or subfolder.

**Returns:**  
ax - Child number.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderGetContents
Returns a chunk array containing all of the folder's subfolders and a chunk 
array containing all the folder's child notes.

**Pass:**  
bx - File handle.  
ax.di - Folder ID.

**Returns:**  
di,ax - Item/group of chunk array of subfolders.  
cx,dx - Item/group of chunk array of notes.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderGetNumChildren
Returns the number of children within the passed folder.

**Pass:**  
ax.di - Folder ID.  
bx - File handle.

**Returns:**  
cx - Number of subfolders.  
dx - Number of notes.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderMove
Moves a folder, attaching it below the passed parent folder.

**Pass:**  
bx - VM file handle.  
ax.di - Folder to move.  
cx.dx - New parent folder.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderSetTitle
Sets the title of a folder to use the passed text string.

**Pass:**  
ax.di - Folder ID.  bx - File handle.  

ds:si - Null terminated text string.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkFolderSetTitleFromTextObject
Sets the title of a folder from the entire text within the passed text object.

**Pass:**  
ax.di - Folder ID.  
bx - File handle.  
cx:dx - Optr of text object.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkGetDocCustomGString
Retrieves the custom GString field from the **InkDataFileMap** structure 

**Pass:**  
bx - File handle.

**Returns:**  
ax - GString handle.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkGetDocGString
Retrieves the background picture (in the form of a GString) of the Ink object. 
If this function returns a token indicating that the Ink object is using a 
custom GString, use **InkGetDocCustomGString**.

**Pass:**  
bx - File handle.

**Returns:**  
ax - GString handle.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkGetDocPageInfo
Retrieves the current page information for the Ink database.

**Pass:**  
ds:si - Pointer to hold the structure **PageSizeReport**.  
bx - File handle.

**Returns:**  
ds:si - **PageSizeReport** structure filled in.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkGetParentFolder
Returns the parent folder of the passed folder or note.

**Pass:**  
ax.di - Note or folder to retrieve the parent of.  
bx - File handle.

**Returns:**  
ax.di - Parent folder.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkGetTitle
Returns the title of the passed folder or note.

**Pass:**  
ax.di - Folder or note ID.  
bx - File handle (or override).  
ds:si - Destination buffer to place the title string.

**Returns:**  
ds:si - Buffer filled in.  
cx - Length of name including null terminator.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteCopyMoniker
Copies the icon and note name into a visMoniker structure. (May also be used 
to copy a folder's name into a visMoniker.)

**Pass:**  
di.cx - Title of the note (or folder).  
bx:si - Optr of output list.  
ax - 1 if a text note; 0 if an ink note. (-1 if a folder.)  
dx - Entry index.

**Returns:**  
Nothing.

**Destroyed:**  
ax, bx, cx, dx, si, di

**Library:** pen.def

----------
#### InkNoteCreate
Creates a note below the passed folder.

**Pass:**  
ax.di - Parent folder ID.  
bx - File Handle.

**Returns:**  
ax.di - Note ID.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteCreatePage
Creates a new page within a note.

**Pass:**  
ax.di - Note ID.  
bx - File handle (or override).  
cx - Page number to insert new page (or -1 to append page at end).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteDelete
Deletes the note and all references to it.

**Pass:**  
ax.di - Note to delete.  
bx - File handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteFindByKeywords
Retrieves a note by its associated keywords. Returns the first 20,000 or so 
notes that match the given keywords.

**Pass:**  
ds:si - Pointer to keywords to match.  
ax - Non-zero if you only want notes that contain all passed 
keywords (exact match).  
bx - File handle.

**Returns:**  
dx - Handle of block containing Note IDs of notes matching or zero 
if no notes match. Block is set up in the following format:  
 - **FindNoteHeader**<>  
 - Note ID  
 - Note ID  
 - Note ID etc.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteFindByTitle
Retrieves a note by its associated title. Returns the first 20,000 or so notes 
that match the given title.

**Pass:**  
ds:si - Pointer to string to match.  
al - **SearchOptions**.  
ah - Non-zero if we want to search the body.  
bx - File handle.

**Returns:**  
dx - Handle of block containing Note IDs of notes matching or zero 
if no notes match. Block is set up in the following format:  
 - **FindNoteHeader**<>  
 - Note ID  
 - Note ID  
 - Note ID etc.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteGetCreationDate
Returns the creation date of the passed note.

**Pass:**  
ax.di - Note.  
bx - File handle.

**Returns:**  
cx - Creation year.  
dl - Creation month.  
dh - Creation day.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteGetKeywords
Copies the keyword string used by the passed note into the passed 
destination address.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
ds:si - Destination for copied string.

**Returns:**  
ds:si - Filled in.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteGetModificationDate
Returns the date the passed note was last modified.

**Pass:**  
ax.di - Note ID.  
bx - File handle.

**Returns:**  
cx - Modification year.  
dl - Modification month.  
dh - Modification day.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteGetNoteType
Returns the note type (ink or text) in use by the passed note.

**Pass:**  
ax.di - Note ID.  
bx - File handle.

**Returns:**  
cx - Note type. (0: ink, 2: text)

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteGetNumPages
Returns the number of pages associated with the passed note.

**Pass:**  
ax.di - Note ID.  
bx - VM file handle.

**Returns:**  
cx - Total number of pages in a note.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteGetPages
Returns the DB item in which the note's information is stored. This DB item 
contains a chunk array of pages.

**Pass:**  
ax.di - Note ID.  
bx - File handle.

**Returns:**  
ax.di - DB item containing chunk array of pages. 

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteLoadPage
Loads an ink or text object from a page of a note.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
cx - Page number.  
dx.bp - Optr of ink or text object.  
si - Note type (0: ink, 2: text).

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteMove
Moves a note from one folder to another.

**Pass:**  
ax.di - Note to move.  
dx.cx - New parent folder.  
bx - File handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSavePage
Saves an ink or text object from the page of a note to the instance data of that 
object.

**Pass:**  
ax.di - Note ID.  
bx - File handle (or override).  
cx - Page number.  
dx:bp - Optr of ink or text object.  
si - Note type (0: ink, 2: text)

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSendKeywordsToTextObject
Replaces a text object's text with the passed note's keywords.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
cx:dx - Optr of text object.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSetKeywords
Sets the keywords of the passed note using the passed text string.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
ds:si - Pointer to text string.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSetKeywordsFromTextObject
Sets the keywords of the passed note using the text within a text object.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
cx:dx - Optr of text object.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSetModificationDate
Sets the modification date of the passed note. This allows you to update the 
note when writing changes.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
cx, dx - Modification date.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSetNoteType
Sets the note type (ink or text) in use by the passed note.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
cl - Note type (0: ink, 2:text)

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSetTitle
Sets the title in use by the passed note to the passed text string.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
ds:si - Null-terminated text string.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkNoteSetTitleFromTextObject
Sets the title in use by the passed note to the text within a text object.

**Pass:**  
ax.di - Note ID.  
bx - File handle.  
cx:dx - Optr of text object.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkSendTitleToTextObject
Sets the text within a text object to the text within the passed note or folder's 
title.

**Pass:**  
ax.di - Folder or note ID.  
bx - File handle  
cx:dx - Optr of text object.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkSetDocCustomGString
Sets the custom GString field (*IDFM_customGstring*) in an Ink object's 
**InkDataFileMap** field.

**Pass:**  
bx - File handle.  
ax - GString handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkSetDocGString
Sets the GString field (*IDFM_gstring*) in an Ink object's **InkDataFileMap** 
field.

**Pass:**  
bx - File handle.  
ax - GString handle.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** pen.def

----------
#### InkSetDocPageInfo
Sets the current page information in use by Ink database.

**Pass:**  
ds:si - Pointer to buffer to hold a **PageSizeReport** structure.  
bx - File handle.

**Returns:**  
ds:si - PageSizeReport structure.

**Destroyed:**  
Nothing.

**Library:**    pen.def

----------
#### LMemAlloc
Allocates space (a new chunk) on the local-memory heap. This routine may 
resize the LMem block, moving it on the heap, and invalidating stored 
segment pointers to it.

**Pass:**  
ds - Segment address of the heap.  
al - Object flags (**ObjChunkFlags**) if allocating an object block.  
cx - Amount of space to allocate.

**Returns:**  
CF - Set if an error is encountered.  
ax - Handle of the new chunk.  
ds - Segment address of the same heap block.  
es - Unchanged, unless **es** and **ds** were the same upon entry in 
which case they are the same on return.

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LMemContract
Compacts a local memory block. The local memory manager routines 
ordinarily take care of heap compaction. This routine compacts the heap 
manually and frees the unused heap space. The block is guaranteed to 
remain at the same address after using this routine (if the block is locked).

**Pass:**  
ds - Segment address of block to compact.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LMemDeleteAt
Deletes space from within the middle of a chunk on the local memory heap. 

**Pass:**  
ds - Segment address of the local memory heap.  
ax - Chunk.  
bx - Offset to begin deletion of data within the LMem chunk.  
cx - Number of bytes to delete.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LMemFree
Frees the space occupied by a local-memory chunk. This routine does not 
resize the block or shuffle any other chunks.

**Pass:**  
ax - Handle of chunk to free.  
ds - Segment address of local memory heap.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LMemInitHeap
Creates and initializes a local-memory heap block. This routine may resize 
the LMem block, moving it on the heap, and invalidating stored segment 
pointers to it. Where possible, you should try to use the higher-level routines: 
**MemAllocLMem**, **VMAllocLMem**, or **UserAllocObjBlock**.

**Pass:**  
ds - Segment of memory block to use as the heap.  
bx - Handle of same memory block.  
ax - Type of heap to create (**LMemType**).  
cx - Number of handles to allocate initially.  
dx - Offset within segment to the start of the heap.  
si - Amount of free space to allocate initially.  
di - **LocalMemoryFlags**.

**Returns:**  
ds - Segment of block passed (may have changed).  
es - Unchanged unless **es** and **ds** were the same upon entry in 
which case they are the same on return.

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LMemInsertAt
Inserts space within the middle of a chunk on the local memory heap. The 
new space is initialized to zeroes.

**Pass:**  
ds - Segment address of the local memory heap.  
ax - Chunk.  
bx - Offset to insert space.  
cx - Number of bytes to insert,

**Returns:**  
CF - Set if an error is encountered.  
ds - Segment of block passed (may have changed).

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LMemReAlloc
Changes the size of a chunk in a local memory heap.

**Pass:**  
ax - Handle of chunk.  
cx - New size to resize the chunk to.  
ds - Segment address of the local memory heap.

**Returns:**  
CF - Set if an error is encountered.  
ds - Segment of block passed (may have changed).  
es - Unchanged unless **es** and **ds** were the same upon entry in 
which case they are the same on return.  
ax - If LMem block has LMF_NO_HANDLES set, then this will be 
the chunk handle of the resized chunk.

**Destroyed:**  
Nothing.

**Library:** lmem.def

----------
#### LocalAsciiToFixed
This routine converts the ASCII expression of a number to a **WWFixed** 
number.

**Pass:**  
ds:di - String to evaluate (e.g. "12.345"). This routine does not 
handle exponents, and handles only four decimal digits.

**Returns:**  
dx.ax - **WWFixed** value. The **dx** register holds the integer portion of 
the number, **ax** holds the fraction.  
di - Updated to point after last character parsed.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCalcDaysInMonth
Return the number of days in the passed month/year.

**Pass:**  
ax - Year  
bl - Month

**Returns:**  
ch - Days in the month

**Destroyed:**  
Nothing

**Library:** localize.def

----------
#### LocalCmpChars
This routine does a lexical comparison of two characters, determining which 
comes first in alphabetic order. 

**Pass:**  
ax - "Source" character.  
cx - "Dest" character.

**Returns:**  
ZF - Set if characters were equal.

CF - Set if "source" character less (earlier) than "destination".  
 - if source = dest : if (z)  
 - if source != dest : if !(z)  
 - if source > dest : if !(c|z)  
 - if source < dest : if (c)  
 - if source >= dest : if !(c)  
 - if source <= dest : if (c|z)  

**Destroyed:**  
Nothing.

**Library:** localize.def

**Warning:** Don't use this routine if it would be more appropriate to use 
**LocalCmpStrings**. DBCS support requires special parsing of strings-you 
cannot compare them a character at a time.

----------
#### LocalCmpCharsNoCase
This routine does a lexical comparison of two characters, determining which 
comes first in alphabetic order. It will ignore case.

**Pass:**  
ax - "Source" character.  
cx - "Dest" character.

**Returns:**  
ZF - Set if characters were equal.  
CF - Set if "source" character less (earlier) than "destination".  
 - if source = dest : if (z)  
 - if source != dest : if !(z)  
 - if source > dest : if !(c|z)  
 - if source < dest : if (c)  
 - if source >= dest : if !(c)  
 - if source <= dest : if (c|z)  

**Destroyed:**  
Nothing.

**Library:** localize.def

**Warning:** Don't use this routine if it would be more appropriate to use 
LocalCmpStrings. DBCS support requires special parsing of strings-you 
cannot compare them a character at a time.

----------
#### LocalCmpStrings
This routine does a lexical comparison of two text strings, determining which 
comes sooner in alphabetic order.

**Pass:**  
ds:si - Pointer to string1.  
es:di - Pointer to string2.  
cx - Maximum number of characters to compare (0 for NULL 
terminated).

**Returns:**  
ZF - Set if strings were equal.  
CF - Set if string1 less (earlier) than string2.  
 - if string1 = string2 : if (z)  
 - if string1 != string2 : if !(z)  
 - if string1 > string2 : if !(c|z)  
 - if string1 < string2 : if (c)  
 - if string1 >= string2 : if !(c)  
 - if string1 <= string2 : if (c|z)  

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCmpStringsDosToGeos
Compares strings as does **LocalCmpStrings**, above, but one or both of the 
strings may be Dos text.

**Pass:**  
ds:si - Pointer to string1.  
es:di - Pointer to string2.  
cx - Maximum number of characters to compare (0 for NULL 
terminated).  
ax - **LocalCmpStringsDosToGeosFlags** to specify which 
strings are GEOS, as opposed to Dos, strings.  
bx - Default character-when there is no GEOS equivalent for a 
Dos character, this character will be substituted in its place.

**Returns:**  
ZF - Set if strings were equal.  
CF - et if string1 less (earlier) than string2.  
 - if string1 = string2 : if (z)  
 - if string1 != string2 : if !(z)  
 - if string1 > string2 : if !(c|z)  
 - if string1 < string2 : if (c)  
 - if string1 >= string2 : if !(c)  
 - if string1 <= string2 : if (c|z)  

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCmpStringsNoCase
Compares strings as does **LocalCmpStrings**, except that case is ignored.

**Pass:**  
ds:si - Pointer to string1.  
es:di - Pointer to string2.  
cx - Maximum number of characters to compare (0 for NULL 
terminated).

**Returns:**  
ZF - Set if strings were equal.  
CF - Set if string1 less (earlier) than string2.  
 - if string1 = string2 : if (z)  
 - if string1 != string2 : if !(z)  
 - if string1 > string2 : if !(c|z)  
 - if string1 < string2 : if (c)  
 - if string1 >= string2 : if !(c)  
 - if string1 <= string2 : if (c|z)  

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCmpStringsNoSpace
Compares two text strings as does **LocalCmpStrings**, except that spaces 
are ignored.

**Pass:**  
ds:si - Pointer to string1.  
es:di - Pointer to string2.  
cx - Maximum number of characters to compare (0 for NULL 
terminated). Note that this count does not include the spaces.

**Returns:**  
ZF - Set if strings were equal.  
CF - Set if string1 less (earlier) than string2.  
 - if string1 = string2 : if (z)  
 - if string1 != string2 : if !(z)  
 - if string1 > string2 : if !(c|z)  
 - if string1 < string2 : if (c)  
 - if string1 >= string2 : if !(c)  
 - if string1 <= string2 : if (c|z)

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCmpStringsNoSpaceCase
Compares two text strings as does **LocalCmpStrings**, except that spaces 
and case are ignored.

**Pass:**  
ds:si - Pointer to string1.  
es:di - Pointer to string2.  
cx - Maximum number of characters to compare (0 for NULL 
terminated). Note that this count does not include the spaces.

**Returns:**  
ZF - Set if strings were equal.  
CF - Set if string1 less (earlier) than string2.  
 - if string1 = string2 : if (z)  
 - if string1 != string2 : if !(z)  
 - if string1 > string2 : if !(c|z)  
 - if string1 < string2 : if (c)  
 - if string1 >= string2 : if !(c)  
 - if string1 <= string2 : if (c|z)

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCodePageToGeos
Converts Dos text to GEOS text. The Dos text may use any code page.

**Pass:**  
ds:si - Pointer to text string.  
cx - Maximum number of characters to convert (zero for a 
null-terminated string).  
bx - Code page to use.  
ax - Default character-when there is no GEOS equivalent for a 
code page character, this character will substitute.

**Returns:**  
CF - Set if had to use the default character.  
ds:si - Pointer to string converted to GEOS text.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCodePageToGeosChar
Convert a single Dos character to GEOS text. The character may be in any 
Dos code page.

**Pass:**  
ax - Character to map.  
bx - Default character-when there is no GEOS equivalent for a 
code page character, this character will be returned.  
cx - Code page to use.

**Returns:**  
ax - Mapped character.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCustomFormatDateTime

Format a date or time. If you call this directly then you will not be language 
independent. This routine is intended to be used by applications who do not 
wish to be language independent or by the higher level date formatting 
routines.

You only need valid information in the registers which will actually be 
referenced. I.e., if your format string has no month tokens, then the bl 
register will be ignored.

**Pass:**  
ds:si - Format string.  
es:di - Buffer to save formatted text in.  
ax - Year (0-9999).  
bl - Month (1-12).  
bh - Date (1-31).  
cl - Day(0-6).  
ch - Hours(0-23).  
dl - Minutes(0-59).  
dh - Seconds(0-59).

**Returns:**  
es:di - (Unchanged) pointer to buffer of formatted text.  
cx - Number of characters in formatted string.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalCustomParseDateTime

Parse a text string using a specific format string.

Any field for which there is not data specified will return containing -1. 

**Pass:**  
es:di - Pointer to string to parse.

ds:si - Format string to compare against.

**Returns:**  
CF - Set if valid date/time (if we were able to parse).  
ax - Year.  
bl - Month.  
bh - Date (1-31).  
cl - Day (0-6). (If we weren't able to parse, **cx** will be offset to 
start of the text that didn't match.)  
ch - Hours. (If we weren't able to parse, **cx** will be offset to start 
of the text that didn't match.)  
dl - Minutes.  
dh - Seconds.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalDistanceFromAscii
This routine extracts a distance value from an ASCII text string.

**Pass:**  
ds:di - ASCII string to convert.  
cl - **DistanceUnit**.  
ch - **MeasurementType**.

**Returns:**  
dx.ax - Value (zero if illegal).

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalDistanceToAscii
Construct an ASCII string from a distance value.

**Pass:**  
es:di - Buffer to hold ASCII string (must be at least 
LOCAL_DISTANCE_BUFFER_SIZE).  
dx.ax - Value to convert.  
cl - **DistanceUnit**.  
ch - **MeasurementType**.  
bx - **LocalDistanceFlags**.

**Returns:**  
cx - Length of string, including NULL.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalDosToGeos
This routine converts a Dos text string to GEOS text format.

**Pass:**  
ds:si - Pointer to text.  
cx - Maximum number of characters to convert (zero if string is 
NULL-terminated).  
ax - Default character. When there is no GEOS equivalent for a 
code page character, this character will substitute.

**Returns:**  
CF - Set if default character was used.  
ds:si - (Unchanged) pointer to converted text.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalDosToGeosChar
This routine converts a single Dos character to a GEOS character.

**Pass:**  
ax - Character to map.  
bx - Default character. (When there is no Geos equivalent for a 
code page character, this character will substitute.)

**Returns:**  
ax - Mapped character.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalDowncaseChar
This routine returns the lowercase equivalent of any character (if the 
character has no lower-case equivalent, the character will be returned 
untouched).

**Pass:**  
ax - Character to downcase.

**Returns:**  
ax - Downcased character.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalDowncaseString
This routine converts a string to all lower case.

**Pass:**  
ds:si - Pointer to string.  
cx - Maximum number of characters to convert (or zero for a 
null-terminated string).

**Returns:**  
ds:si - (Unchanged) pointer to converted string.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalFixedToAscii
This routine converts a **WWFixed** number to its ASCII string equivalent.

**Pass:**  
es:di - Buffer to hold result.  
dx.ax - Number to convert.  
cx - Number of digits of fraction.

**Returns:**  
es:di - (Unchanged) pointer to buffer holding string.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalFormatDateTime
This routine takes a date or time and a enumerated type describing how that 
time should be formatted and returns a text string containing the time/date 
information formatted nicely.

**Pass:**  
es:di - Pointer to buffer in which to place the formatted text.  
si - **DateTimeFormat**.  
ax - Year.  
bl - Month.  
bh - Date (1-31).  
cl - Day (0-6).  
ch - Hours.  
dl - Minutes.  
dh - Seconds.

**Returns:**  
es:di - (Unchanged) pointer to buffer containing string.  
cx - Number of characters in the formatted string. This does not 
include the NULL character at the end of the string.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalFormatFileDateTime
Like **LocalFormatDateTime**, except it works off a **FileDate** and a **FileTime** 
record

**Pass:**  
ax - **FileDate**  
bx - **FileTime**  
si - **DateTimeFormat**  
es:di - Buffer into which to format 

**Returns:**  
cx - Number of characters in formatted string, not including null 
terminator.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGeosToCodePage
Convert GEOS text string to Dos text using an arbitrary code page.

**Pass:**  
ds:si - Pointer to text string.  
cx - Maximum number of characters to convert (zero for a 
null-terminated string).  
bx - Code page to use.  
ax - Default character-when there is no code page equivalent for 
a GEOS character, this character will substitute.

**Returns:**  
CF - Set if had to use the default character.  
ds:si - (Unchanged) pointer to text string converted to Dos text.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGeosToCodePageChar
Convert one character of GEOS text to Dos text using an arbitrary code page.

**Pass:**  
ax - Character to convert.  
cx - Code page to use.  
bx - Default character-when there is no code page equivalent for 
a GEOS character, this character will be returned.

**Returns:**  
ax - Converted character.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGeosToDos
Concert a string of GEOS text to its Dos equivalent.

**Pass:**  
ds:si - Pointer to text.  
cx - Maximum number of characters to convert (zero for 
null-terminated).  
ax - Default character-when there is no code page equivalent for 
a GEOS character, this character will be returned. 

**Returns:**  
CF - Set if default character was used.  
ds:si - (Unchanged) pointer to converted text.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGeosToDosChar
Convert one character of GEOS text to its Dos text equivalent.

**Pass:**  
ax - Character to convert.  
cx - Code page to use.  
bx - Default character-when there is no code page equivalent for 
a GEOS character, this character will be returned.

**Returns:**  
ax - Converted character.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGetCodePage
This routine returns the value of the current code page.

**Pass:**  
Nothing.

**Returns:**  
bx - DosCodePage.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGetCurrencyFormat
This routine returns the information necessary to format currency text 
strings in the way preferred by the user.

**Pass:**  
es:di - Pointer to buffer in which to put currency symbol.

**Returns:**  
al - **CurrencyFormatFlags**.  
ah - Currency digits  
bx - Thousands separator (e.g. ",").  
cx - Decimal separator (e.g. ".").  
dx - List separator (e.g. ";").  
es:di - (Unchanged) pointer to buffer filled with currency symbol.

**Destroyed:**  
Nothing.

**Library:**    localize.def

----------
#### LocalGetDateTimeFormat
Returns the text string associated with a **TimeDateFormat**.

**Pass:**  
es:di - Pointer to buffer to hold format string. Should be prepared to 
hold string up to DATE_TIME_BUFFER_SIZE.  
si - **DateTimeFormat** in use by the format string.

**Returns:**  
es:di - (Unchanged) pointer to buffer filled with format string.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGetNumericFormat
This routine returns the information necessary to format currency text 
strings in the way preferred by the user.

**Pass:**  
Nothing.

**Returns:**  
al - CurrencyFormatFlags.

ah - Decimal digits.  
bx - Thousands separator (e.g. ",").  
cx - Decimal separator (e.g. ".").  
dx - List separator (e.g. ";").

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalGetQuotes
This routine returns the localized symbols to use as single or double quotes.

**Pass:**  
Nothing.

**Returns:**  
ax - Front single quote.  
bx - End single quote.  
cx - Front double quote.  
dx - End double quote.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalIsAlpha
This routine detects alphabetic characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is alphabetic.

**Library:** localize.def

----------
#### LocalIsAlphaNumeric
This routine detects alphabetic and numeric characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is alphanumeric.

**Library:** localize.def

----------
#### LocalIsCodePageSupported
Checks to see if the passed code page is a supported one.

**Pass:**  
ax - Code page to check.    

**Returns:**  
ZF - Set if supported; clear if not supported.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalIsControl
This routine detects control characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is a control character.

**Library:** localize.def

----------
#### LocalIsDateChar
This routine detects date characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is a digit, or part of the format string 
associated with DTF_SHORT.

**Library:** localize.def

----------
#### LocalIsDigit
This routine detects numeric characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is numeric.

**Library:** localize.def

----------
#### LocalIsDosChar
This routine detects characters which are members of the Dos character set.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is in the Dos character set.

**Library:** localize.def

----------
#### LocalIsGraphic
This routine detects characters that require some sort of drawing. Control 
characters are not graphic; neither are line-feeds or spaces. Letters, 
numbers, and punctuation marks are all good examples of graphic symbols.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is graphic.

**Library:** localize.def

----------
#### LocalIsHexDigit
This routine detects numeric characters, including those letters necessary for 
expressing hexadecimal numbers.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is a hexidecimal digit.

**Library:** localize.def

----------
#### LocalIsLower
This routine detects lower-case alphabetic characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is lower-case.

**Library:** localize.def

----------
#### LocalIsNumChar
This routine detects numeric characters, including the decimal separator.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is part of the number format.

**Library:** localize.def

----------
#### LocalIsPrintable
This routine detects printable characters (this includes all graphic 
characters and the space character).

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is printable.

**Library:** localize.def

----------
#### LocalIsPunctuation
This routine detects punctuation marks.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is a punctuation mark.

**Library:** localize.def

----------
#### LocalIsSpace
This routine detects white-space.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is a space.

**Library:** localize.def

----------
#### LocalIsSymbol
This routine detects symbol characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is a symbol.

**Library:** localize.def

----------
#### LocalIsTimeChar
This routine detects characters which are digits or part of the format string 
associated with DTF_HMS.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is part of a time string.

**Library:** localize.def

----------
#### LocalIsUpper
This routine detects upper-case alphabetic characters.

**Pass:**  
ax - Character to check.

**Returns:**  
ZF - Clear if character is upper-case.

**Library:** localize.def

----------
#### LocalLexicalValue
This routine returns the lexical value of a character, useful when sorting 
things into alphabetical order. Note that knowing the lexical value of just one 
character is not much use - lexical values are only meaningful when 
compared to one another.

**Pass:**  
ax - Character.

**Returns:**  
ax - Lexical order.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalLexicalValueNoCase
This routine returns the case-insensitive lexical value of a character, useful 
when sorting things into alphabetical order. Note that knowing the 
case-insensitive lexical value of just one character is not much use-lexical 
values are only meaningful when compared to one another.

**Pass:**  
ax - Character.

**Returns:**  
ax - Case-insensitive lexical order.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalParseDateTime
This routine parses a text string and extracts time or date information from 
it. Any field for which there is not data specified in the format string is 
returned containing -1.

**Pass:**  
es:di - Pointer to the string to parse.  
si - DateTimeFormat with which to parse string.

**Returns:**  
CF - Set if string is a valid date/time (i.e. if the string parsed 
correctly).  
ax - Year.  
bl - Month.  
bh - Date (1-31).  
cl - Day(0-6). (If string did not parse correctly, cx will be the 
offset to the start of the text that didn't match.)  
ch - Hours. (If string did not parse correctly, cx will be the offset 
to the start of the text that didn't match.)  
dl - Minutes.  
dh - Seconds.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalSetCurrencyFormat
This routine sets the currency format information. All items will be added to 
the .INI file.

**Pass:**  
al - **CurrencyFormatFlags**.  
ah - Currency digits.  
es:di - Pointer to string containing currency symbol.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalSetDateTimeFormat
Sets the localization date/time format in use by a **DateTimeFormatString**. 

**Pass:**  
es:di - Pointer to format string (of type **DateTimeFormatString**).  
si - New **DateTimeFormat**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalSetMeasurementType
This routine sets the measurement type. The correct value will be written to 
the .INI file.

**Pass:**  
al - **MeasurementType**.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalSetNumericFormat
This routine sets the fields used when formatting number strings. The 
correct values will be written to the .INI file.

**Pass:**  
al - NumberFormatFlags.  
ah - Decimal digits.  
bx - Thousands separator (e.g. ",").  
cx - Decimal separator (e.g. ".").  
dx - List separator (e.g. ";")

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalSetQuotes
This routine sets the localized single and double quotes.

**Pass:**  
ax - Front single quote.  
bx - End single quote.  
cx - Front double quote.  
dx - End double quote.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalStringLength
This routine computes the number of characters in a null-terminated text 
string. This routine allows for double byte character support.

**Pass:**  
es:di - Pointer to string.

**Returns:**  
cx - Number of characters in the string, not including the null.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalStringSize
This routine determines the number of bytes used to store a null-terminated 
text string.

**Pass:**  
es:di - Pointer to string.

**Returns:**  
cx - Number of bytes in the string (not counting the NULL).

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalUpcaseChar
This routine returns a character's upper-case equivalent.

**Pass:**  
ax - Character

**Returns:**  
ax - Upper-case character.

**Destroyed:**  
Nothing.

**Library:** localize.def

----------
#### LocalUpcaseString
This routine returns the all-caps equivalent of a text string.

**Pass:**  
ds:si - Pointer to string.  
cx - Maximum number of characters to convert (zero for NULL 
terminated).

**Returns:**  
ds:si - (Unchanged) pointer to upcased string.

**Destroyed:**  
Nothing.

**Library:** localize.def

[Routines G-G](asmg_g.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Routines M-Q](asmm_q.md)
