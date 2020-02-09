## 2.2 Routines E-F

----------
#### ECCheckBounds
Verifies that a pointer is in bounds (**ds** is a valid segment and **si** is a valid 
offset).

**Pass:**  
ds:si - Pointer to be checked.

**Returns:**  
Nothing. Calls **FatalError** if pointer is out of bounds.

**Destroyed:**  
Nothing.

**Library:** ec.def

----------
#### ECCheckClass
Checks that the pointer actually points at a class definition.

**Pass:**  
es:di - Class pointer.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckDriverHandle
Checks that the passed handle actually references a valid driver.

**Pass:**  
bx - Driver handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckEventHandle
Checks that the passed handle references a valid **EventHandle**.

**Pass:**  
bx - Event handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckGeodeHandle
Checks that the passed handle actually references a valid geode.

**Pass:**  
bx - Geode handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckGStateHandle
Makes sure the passed handle actually references a valid GState.

**Pass:**  
di - GState handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckLibraryHandle
Makes sure the passed handle actually references a valid library.

**Pass:**  
bx - Library handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckLMemHandle
Ensures that the passed handle references a valid, sharable local memory 
block.

**Pass:**  
bx - Handle of local memory block.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing.

**Library:** ec.def

----------
#### ECCheckLMemHandleNS
Ensures that the passed handle references a valid local memory block, 
ignoring issues of sharing.

**Pass:**  
bx - Handle of local memory block.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing.

**Library:** ec.def

----------
#### ECCheckLMemObject
Makes sure that the given pointer points to an object within an object block. 
Will not allow the pointer to point to a Process object. (If it does, this routine 
will call **FatalError**.)

**Pass:**  
*ds:si - Segment:chunk handle to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckLMemOD
Makes sure that the given optr points to an object within an object block. Will 
not allow the pointer to point to a Process object.

**Pass:**  
bx:si - The optr of the object to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckLMemODCXDX
Checks that the passed **cx:dx** is a valid optr to an LMem-based object (not a 
Process).

**Pass:**  
cx:dx - The optr to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### ECCheckMemHandle
Checks the validity of a passed global memory handle.

**Pass:**  
bx - Memory handle to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckMemHandleNS
Checks the validity of the passed memory handle, ignoring sharing violation 
errors (when a block should be sharable but is not).

**Pass:**  
bx - Memory handle to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved. Interrupts left in the same state as when the 
routine was called.

**Library:** ec.def

----------
#### ECCheckObject
Ensures that the locked object is valid. This routine can check both local 
memory objects and Process objects.

**Pass:**  
ds - If the "object" is a Process object, **ds** points to dgroup.  
*ds:si - Segment:chunk handle of object to validate.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckOD
Ensures that the optr passed references an object. This routine considers 
Process objects valid, unlike **ECCheckLMemOD**.

**Pass:**  
bx:si - The optr of the object to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckODCXDX
Checks to see if the passed **cx:dx** is a valid optr.

**Pass:**  
cx:dx - The optr to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### ECCheckProcessHandle
Checks that the passed handle actually references a valid Process.

**Pass:**  
bx - Process handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckQueueHandle
Checks that the passed handle actually references a valid event queue.

**Pass:**  
bx - Queue handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckResourceHandle
Checks that the passed handle actually references a valid resource (device).

**Pass:**  
bx - Resource handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckSegment
Checks that the passed segment value actually points to a locked block.

**Pass:**  
ax - Segment address to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckThreadHandle
Checks that the passed handle actually references a valid thread.

**Pass:**  
bx - Thread handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ECCheckUILMemOD
Checks that the passed optr references a valid UI-run object (not a Process).

**Pass:**  
bx:si - The optr to be checked.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### ECCheckUILMemODCXDX
Checks that the passed cx:dx is a valid optr pointing to a UI-run object in an 
object block (not a Process).

**Pass:**  
cx:dx - The optr to check.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing.

**Library:** ui.def

----------
#### ECCheckWindowHandle
Checks that the passed handle actually references a valid window.

**Pass:**  
bx - Window handle.

**Returns:**  
Nothing. Calls **FatalError** if assertions fail.

**Destroyed:**  
Nothing. Flags are preserved.

**Library:** ec.def

----------
#### ElementArrayAddElement
Add an element to a given element array. If the element already exists, its 
reference count will be incremented.

**Pass:**  
*ds:si - Segment:chunk handle of the element array's chunk.  
cx:dx - Address of element to add.  
ax - Size of the element, if variable-sized element array.  
bx:di - Address of a callback routine; pass zero in both registers to 
invoke a straight binary-value comparison.  
bp - Value to pass to the callback routine.

**Returns:**  
CF - Set if the element was newly added, clear if the reference 
count was incremented for an existing element.  
ax - Element number of the newly added element.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
es:di - Address of element to be added.  
ds:si - Address of comparison element.  
cx - Size of the elements; sizes will be identical, or 
the callback will not be called.  
ax - Value passed initially in bp to 
**ElementArrayAddElement**.  
**Return:**  
CF - Set if the elements are equal.  
**May Destroy:** ax, bx, cx, dx

**Library:** chunkarr.def

**Warning:** This routine may resize or move chunks or blocks; therefore, you must 
dereference all stored pointers after a call to this routine.

----------
#### ElementArrayAddReference
Increments the reference count for an element in an element array.

**Pass:**  
*ds:si - Address of the locked element array.  
ax - Element number of the subject element.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ElementArrayCreate
Creates a new element array in the specified chunk. The new array will have 
no elements.

**Pass:**  
ds - Global handle of the block that will contain the array.  
bx - Size of each element; pass zero for variable-sized elements.  
cx - Size of the header; pass zero to get the default size.  
si - Chunk handle of the chunk in which the array will be 
created.  
al - A record of **ObjChunkFlags** to pass to **LMemAlloc**.

**Returns:**  
*ds:si - Address of the new, locked element array.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

**Warning:** This routine may resize or move chunks or blocks on the heap; therefore, all 
stored pointers must be dereferenced.

----------
#### ElementArrayDelete
Deletes an element regardless of its reference count.

**Pass:**  
*ds:si - Segment:chunk handle of the element array.  
ax - Element number of element to be deleted.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** chunkarr.def

----------
#### ElementArrayElementChanged
Checks to see if a recently changed element is now equal to another element 
If the element is now a duplicate, it will be combined with the other element, 
and the other element's reference count will be incremented.

**Pass:**  
*ds:si - Segment:chunk handle of the element array.  
ax - Element number of the changed element.  
bx:di - Address of a callback comparison routine. Pass zero in both 
registers to invoke straight binary comparison.  
bp - Value to pass to the callback routine (in **ax**).

**Returns:**  
ax - The new element number of the changed element.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
es:di - Address of the changed element.  
ds:si - Address of a comparison element.  
cx - Size of elements; both will be identical size, 
or the callback will not be called.  
ax - Value for callback routine passed in bp to 
**ElementArrayElementChanged**.  
**Return:**  
CF	Set if elements are equal, clear otherwise.  
**May Destroy:** ax, bx, cx, dx

**Library:** chunkarr.def

----------
#### ElementArrayGetUsedCount
Returns the number of elements in the array that actually hold data.

**Pass:**  
*ds:si - Segment:chunk handle of the element array.  
bx:di - Address of a callback routine to make qualification more 
explicit. Pass zero in **bx** to use no callback routine.  
cx, dx - Data passed through to callback routine.

**Returns:**  
ax - Number of "used" elements as determined by the callback.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
*ds:si - Segment:chunk of the element array.  
ds:di - Address of element being processed.  
cx, dx - Data passed through, as modified by the last 
calling of the callback routine.  
**Return:**  
CF - Set if the element qualifies as "used." Clear 
otherwise.  
**May Destroy:** ax, bx, cx, dx, si, di

**Library:** chunkarr.def

----------
#### ElementArrayRemoveReference
Removes a reference to the specified element, removing the element itself if 
the reference count drops to zero.

**Pass:**  
*ds:si - Segment:chunk handle of the element array.  
ax - Element number of subject element.  
bx:di - Address of routine to call if the reference count drops to zero.  
cx - Value to pass to callback routine (in **ax**).

**Returns:**  
CF - Set if element removed, clear otherwise.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ax - Value passed in cx to 
ElementArrayRemoveReference.  
ds:di - Address of the element to be removed.  
**Return:**  
Nothing.  
**May Destroy:** ax, bx, cx, dx

**Library:** chunkarr.def

----------
#### ElementArrayTokenToUsedIndex
Returns the index of an element with respect to used elements in the array, 
given its token.

**Pass:**  
*ds:si - Segment:chunk handle of the element array.  
ax - Token.  
bx:di - Address of a callback routine to make qualification more 
explicit. Pass zero in **bx** to use no callback routine.  
cx, dx - Data passed through to callback routine.

**Returns:**  
ax - Index of the element with respect to used elements in the 
array.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
*ds:si - Segment:chunk of the element array.  
ds:di - Address of element being processed.  
cx, dx - Data passed through, as modified by the last 
calling of the callback routine.  
**Return:**  
CF - Set if the element qualifies as "used."  
**May Destroy:** ax, bx, cx, dx, si, di

**Library:** chunkarr.def

----------
#### ElementArrayUsedIndexToToken
Returns the token of an element given its index with respect to used elements 
in the array.

**Pass:**  
*ds:si - Segment:chunk handle of the element array.  
ax - Index into used list of element array.  
bx:di - Address of a callback routine to make qualification more 
explicit. Pass zero in **bx** to use no callback routine.  
cx, dx - Data passed through to callback routine.

**Returns:**  
CF - Set if a valid token was found. Clear if not found.  
ax - Token of the element, if found.
If not found, **ax** will be returned CA_NULL_ELEMENT.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
*ds:si - Segment:chunk of the element array.  
ds:di - Address of element being processed.  
cx, dx - Data passed through, as modified by the last 
calling of the callback routine.  
**Return:**  
CF - Set if the element passed qualifies as "used."  
**May Destroy:** ax, bx, cx, dx, si, di

**Library:** chunkarr.def

----------
#### FatalError
Indicates that a fatal error has been encountered within an application. Note 
that it is impossible to return from a fatal error. This routine is meant to 
identify what precipitated the fatal error.

**Pass:**  
ax - Error code (this code is application-specific and must be 
custom-defined).

**Returns:**  
Not applicable

**Destroyed:**  
Not applicable

**Library:** ec.def

----------
#### FileAddStandardPathDirectory
Adds the specified directory to the standard path table.

**Pass:**  
ds:dx - Pointer to a null-terminated path string.  
ax - **StandardPath** to add  
bx - **FileAddStandardPathFlags**

**Returns:**  
CF - Set if an error was encountered  
ax - **FileError** (if CF is set) ERROR_PATH_NOT_FOUND

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileClose
Close an open file.

**Pass:**  
al - **FileAccessFlags** record. Only FILE_NO_ERRORS is used by 
this routine; other flags in the record *must* be cleared.  
bx - File handle of the file to be closed.

**Returns:**  
CF - Set if an error occurred.  
ax - Error code (**FileError**) if error occurred.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCommit
Commits a file to the disk by forcing all changes to be written out.

**Pass:**  
al - **FileAccessFlags** record. Only FILE_NO_ERRORS is used by 
this routine; other flags in the record *must* be cleared.  
bx - File handle of the file to be closed.

**Returns:**  
CF - Set if an error occurred.  
ax - Error code (**FileError**) if error occurred.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileComparePaths
Compares two paths, returning their relationship.

**Pass:**  
cx - Disk handle of disk containing the first path.  
ds:si - Address of the first null-terminated path name.
Pass **ds** = 0 for a null path.  
dx - Disk handle of disk containing the second path.  
es:di - Address of the second null-terminated path name.
Pass **es** = 0 for a null path.

**Returns:**  
al - Value of PathCompareType:  
PCT_EQUAL  
PCT_SUBDIR  
PCT_UNRELATED  
PCT_ERROR

**Destroyed:**  
Nothing.

**Library:** file.def

**Warning:** Neither path may contain a trailing backslash. Also, this routine does not 
deal with links; call **FileConstructActualPath** on each path if you suspect 
either involves links.

----------
#### FileConstructActualPath
Similar to **FileConstructFullPath**, this routine also replaces links with 
their actual targets. It creates a full path string from the passed information.

**Pass:**  
dx - Non-zero value to prepend drive name and colon to the path.  
bx - Disk handle or path identifier:

- bx = 0  
Prepend the current path and use the current 
disk handle.
- bx = **StandardPath** value  
Prepend the logical path for the standard
path, returning the top-level disk handle.
- bx = disk handle  
Passed path is an absolute path; the disk
handle will be used only if **dx** is non-zero.

ds:si - Address of the *tail* of the path string being constructed. If **bx** 
is non-zero and not a **StandardPath** value, this path must 
be absolute.  
es:di - Address of buffer into which the constructed path will be 
written.  
cx - Size of the buffer pointed to by **es:di**.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - A **FileError** error code if CF set.  
es:di - Address of the terminating null of the constructed path.  
bx - Disk handle of the disk for the path.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileConstructFullPath
Constructs a full path given a standard path constant and a path relative to 
the standard path. This routine does not resolve links; instead, use 
**FileConstructActualPath**.

**Pass:**  
dx - Non-zero value to prepend drive name and colon to the path.  
bx - Disk handle or path identifier:

- bx = 0  
Prepend the current path and use the current
disk handle.
- bx = **StandardPath** value  
Prepend the logical path for the standard
path, returning the top-level disk handle.
- bx = disk handle  
Passed path is an absolute path; the disk
handle will be used only if **dx** is non-zero.

ds:si - Address of the *tail* of the path string being constructed. If bx 
is non-zero and not a **StandardPath** value, this path must 
be absolute.  
es:di - Address of buffer into which the constructed path will be 
written.  
cx - Size of the buffer pointed to by **es:di**.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - A **FileError** error code if CF set.  
es:di - Address of the terminating null of the constructed path.  
bx - Disk handle of the disk for the path.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCopy
Copies a source file into a destination file. If the destination file does not 
already exist, it will be created. Any existing destination file with the same 
name will be truncated and overwritten.

**Pass:**  
ds:si - Address of the null-terminated source file name. Or, pass 
zero in **ds** and the file handle of an open source file in **si**.  
cx - Source file's disk handle. If zero, the disk handle of the 
thread's current path will be used. If a disk handle is 
provided, the path *must* be absolute.  
es:di - Address of null-terminated destination file name.  
dx - Destination file's disk handle. If zero, the disk handle of the 
thread's current path will be used. If a disk handle is 
provided, the path *must* be absolute.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Zero if successful, error code if error:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
ERROR_TOO_MANY_OPEN_FILES  
ERROR_ACCESS_DENIED  
ERROR_SHORT_READ_WRITE

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCopyExtAttributes
Copies all the extended file attributes from an open file into another named 
file.

**Pass:**  
bx - File handle of open source file.  
ds:dx - Address of null-terminated name of destination file.

**Returns:**  
CF - Set on error, clear otherwise.  
ax - Error code if error; destroyed otherwise.

**Destroyed:**  
ax, if not returned.

**Library:** file.def

----------
#### FileCopyLocal
Copies the source file to the destination file. If the destination file does not 
exist, this routine will create it; if the destination file already exists, it will be 
truncated to accommodate the new source.

This routine copies a file to a local standard path directory even if a file of the 
same name exists in the remote directory.

**Pass:**  
ds:si - Address of the null-terminated source file name. Or, pass 
zero in **ds** and the file handle of an open source file in **si**.  
cx - Source file's disk handle. If zero, the disk handle of the 
thread's current path will be used. If a disk handle is 
provided, the path *must* be absolute.  
es:di - Address of null-terminated destination file name.  
dx - Destination file's disk handle. If zero, the disk handle of the 
thread's current path will be used. If a disk handle is 
provided, the path *must* be absolute.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Zero if successful, error code if error:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
ERROR_TOO_MANY_OPEN_FILES  
ERROR_ACCESS_DENIED  
ERROR_SHORT_READ_WRITE

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCopyPathExtAttributes
Copies the extended attributes of a file to another file without opening either 
file.

**Pass:**  
cx - Source file's disk handle.  
ds:si - Address of the null-terminated source file name.  
dx - Destination file's disk handle.  
es:di - Address of null-terminated destination file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - **FileError** code if CF is set.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCreate
Creates a new file or truncates an existing file.

**Pass:**  
ah - Record of **FileCreateFlags**:  
FCF_NATIVE  
Set to force the file to use the native format of the system on 
which it's created. There is little reason for a GEOS 
application to set this flag. If this flag is used, the file already 
exists in a different format, and FCF_MODE (below) is not set 
to FILE_CREATE_ONLY, then an error will occur 
(ERROR_FILE_FORMAT_MISMATCH).  
FCF_MODE  
This bitfield may contain one of three values:  
FILE_CREATE_TRUNCATE to truncate an existing file.
FILE_CREATE_NO_TRUNCATE to create a new file or to abort.
FILE_CREATE_ONLY to create a new file or fail if a file of the 
same name already exists.  
al - Record of **FileAccessFlags** requesting at least write access.  
cx - Record of **FileAttrs** for the new file if it is created anew.  
ds:dx - Address of the null-terminated file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - File handle if successful. If CF set, **ax** will contain an error 
code.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCreateDir
Creates a new directory.

**Pass:**  
ds:dx - Address of null-terminated path name to create.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - If CF set, error code:  
ERROR_PATH_NOT_FOUND  
ERROR_ACCESS_DENIED

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileCreateTempFile
Creates a temporary file with a unique name.

**Pass:**  
ah - **FileCreateFlags**; only FCF_NATIVE is used here.  
al - **FileAccessFlags** for the temporary file.  
cx - **FileAttrs** for the temporary file.  
ds:dx - Address of the null-terminated directory in which to create 
the file. Add 14 (fourteen) extra null bytes at the end of the 
path name to be replaced by the file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - File handle of the temporary file, if successful.
Error code (**FileError**) if CF set.  
ds:dx - Address of the file's path, if successful.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileDelete
Deletes the specified file.

**Pass:**  
ds:dx - Address of null-terminated file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code if CF set:  
ERROR_FILE_NOT_FOUND  
ERROR_ACCESS_DENIED  
ERROR_FILE_IN_USE

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileDeleteDir
Deletes a directory and all the files and subdirectories within it.

**Pass:**  
ds:dx - Address of null-terminated path to be deleted.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - FileError code if CF set:  
ERROR_PATH_NOT_FOUND  
ERROR_IS_CURRENT_DIRECTORY  
ERROR_ACCESS_DENIED  
ERROR_DIRECTORY_NOT_EMPTY

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileDeleteStandardPathDirectory
Deletes the specified directory from the standard path table.

**Pass:**  
ds:dx - Address of null-terminated path to be deleted.  
ax - The **StandardPath** that this particular path was added as.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - FileError code if CF set:  
ERROR_PATH_NOT_FOUND

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileDuplicateHandle
Duplicates the passed handle, returning a new handle referring to the same 
file.

**Pass:**  
bx - File handle to duplicate.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - New handle, if successful. If CF set, an error code:  
ERROR_TOO_MANY_OPEN_FILES

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileEnum
Enumerates all files in a directory, calling a callback routine for each. This 
routine receives its parameters on the stack; the parameter structure is not 
returned on the stack but is instead popped during the routine's execution.

**Pass:**  
ss:sp - On the stack, a FileEnumParams structure.  
*FEP_searchFlags*  
A **FileEnumSearchFlags** record indicating 
the types of files and directories to match.  
*FEP_returnAttrs*  
A far pointer to an array of attributes to be 
returned.  
*FEP_returnSize*  
Size of each entry in the *FEP_returnAttrs* 
buffer.  
*FEP_matchAttrs*  
A far pointer to an array of **FileExtAttrDesc** 
attributes to be matched by **FileEnum**.  
*FEP_bufSize*  
Number of structures the return buffer may 
hold. Defaults to FE_BUFSIZE_UNLIMITED.  
*FEP_skipCount*  
Number of matches to skip before adding 
entries to the return buffer. Allows 
consecutive enumerations of all files in a 
directory.  
*FEP_callback*  
Address of a callback routine to be called for 
each file that passes the other filters.  
*FEP_callbackAttrs*  
A far pointer to a list of supplemental 
attributes (**FileExtAttrDesc** structures) 
that don't or can't appear in *FEP_matchAttrs*.  
*FEP_cbData1*  
*FEP_cbData2*  
Two separate dwords of data that is passed 
along to the callback routine.  
*FEP_headerSize*  
Amount of space to reserve at the start of the 
returned buffer if FESF_LEAVE_HEADER set.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code (**FileError**) if CF set on return.  
bx - Memory handle of buffer created, if any. If no files were 
found, or if an error occurred, no buffer is returned and **bx** is 
returned a null handle (zero).  
cx - Number of matching files returned in the buffer in **bx**.  
dx - Number of matching files that would not fit in the passed 
buffer in **bx**. The maximum buffer size is passed in the 
*FEP_bufSize* parameter in the **FileEnumParams** structure. 
If *FEP_bufSize* is zero, **dx** will contain the number of 
matching files in the directory upon return.  
buffer - The buffer returned in bx will contain structures of the type 
requested in *FEP_returnAttrs* for all the matching files.  
di - The updated real skip count if FESF_REAL_SKIP passed;
Register preserved if FESF_REAL_SKIP not passed.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ds - Segment of **FileEnumCallbackData** 
structure, an array of **FileExtAttrDesc** 
structures indicating the attributes to be 
retrieved for each matching file.  
bp - Inherited stack frame, which must be passed 
to any **FileEnum** helper routines called by 
the callback routine.

**Library:** fileEnum.def

----------
#### FileEnumLocateAttr
Locates an extended attribute within an array of **FileExtAttrDesc** 
structures. This routine usually acts as a "helper" of **FileEnum** callback 
routines.

**Pass:**  
ax - **FileExtendedAttribute** value indicating the attribute to be 
found (FEA_MULTIPLE not allowed here).  
ds:si - Address of array to search.  
es:di - Address of attribute's name, if FEA_CUSTOM passed in ax.

**Returns:**  
CF - Set if the attribute was not found, clear if it was.  
es:di - Address of the attribute, if CF clear on return. If the file does 
not have the given attribute, **es**:di.FEAD_value.segment 
will be zero.

**Destroyed:**  
es, di if attribute searched for was not found.

**Library:** fileEnum.def

----------
#### FileEnumPtr
This routine performs an enumeration identical to **FileEnum** except that it 
accepts a pointer to a **FileEnumParams** structure rather than needing all 
of the parameters passed on the stack. It is, therefore, somewhat simpler to 
call.

**Pass:**  
ds:si - Address of **FileEnumParams** structure. See **FileEnum** for 
a description of these elements.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code (**FileError**) if CF set on return.  
bx - Memory handle of buffer created, if any. If no files were 
found, or if an error occurred, no buffer is returned and **bx** is 
returned a null handle (zero).  
buffer - The buffer returned in bx will contain structures of the type 
requested in *FEP_returnAttrs* for all the matching files.  
cx - Number of matching files returned in the buffer in **bx**.  
dx - Number of matching files that would not fit in the passed 
buffer in **bx**. The maximum buffer size is passed in the 
*FEP_bufSize* parameter in the **FileEnumParams** structure. 
If *FEP_bufSize* is zero, **dx** will contain the number of 
matching files in the directory upon return.  
di - The updated real skip count if FESF_REAL_SKIP passed;
Register preserved if FESF_REAL_SKIP not passed.

**Destroyed:**  
Nothing.

**Callback Routine Specifications:**  
**Passed:**  
ds - Segment of **FileEnumCallbackData** 
structure, an array of **FileExtAttrDesc** 
structures indicating the attributes to be 
retrieved for each matching file.  
bp - Inherited stack frame, which must be passed 
to any **FileEnum** helper routines called by 
the callback routine.

**Library:** fileEnum.def

----------
#### FileEnumWildcard
Checks if the virtual name of the current file matches the pattern passed to 
**FileEnum** in *FEP_cbData1*. In this case, *FEP_cbData1* is cast to a far pointer 
to the name string. This routine acts as a **FileEnum** "helper" routine.

**Pass:**  
ds - Segment of **FileEnumCallbackData** structure.  
ss:bp - Inherited stack frame including:  
*FEP_cbData1*  
Address of name pattern to match.  
*FEP_cbData2.low*  
Non-zero if the matching should be 
case-insensitive.

**Returns:**  
CF - Clear if the FEA_NAME attribute of the file matches the name 
pointed to by *FEP_cbData1*. Set if they don't match.

**Destroyed:**  
Nothing.

**Library:** fileEnum.def

----------
#### FileGetAttributes
Retrieves a file's attributes.

**Pass:**  
ds:dx - Address of the null-terminated file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code if CF set:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
cx - FileAttrs record of the file if successful.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileGetCurrentPath
Returns the thread's current directory. If the directory is a standard path, the 
returned disk handle (**bx**) will actually be a **StandardPath** constant and the 
buffer will contain a relative path. To retrieve a full path, use 
**FileConstructFullPath** instead, passing **dx** a non-zero value and **bp** the 
value of -1.

**Pass:**  
ds:si - Address of a locked or fixed buffer into which the path will be 
written.  
cx - Size of the buffer, or zero if only the disk handle should be 
returned.

**Returns:**  
bx - Disk handle of the disk on which the current path resides. If 
the current path is a standard path, this will be the 
**StandardPath** constant rather than the disk handle.  
ds:si - Buffer stores the address of the null-terminated path string. 
If a standard path is returned in bx, this will be relative to 
that standard path. Otherwise, it is an absolute path.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileGetCurrentPathIDs
Returns an array of **FilePathID** structures for the current path. These IDs 
may be used in handling file change notification messages.

**Pass:**  
ds - Segment of LMem block in which to allocate the array.

**Pass:**  
CF - Set if error; clear otherwise.  
ax - **FileError** if CF set.  
ax - Chunk handle of array (if CF clear).  
ds - Fixed up.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileGetDateAndTime
Returns the modification date and time of an open file.

**Pass:**  
bx - File handle of open file.

**Returns:**  
cx - **FileTime** record indicating last modification time.  
dx - **FileDate** record indicating last modification date.

**Destroyed:**  
ax

**Library:** file.def

----------
#### FileGetDiskHandle
Retrieves the disk handle of an open file.

**Pass:**  
bx - File handle of an open file.

**Returns:**  
bx - Disk handle of the file's disk (or zero if file is open on a 
device).

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileGetHandleExtAttributes
Retrieves one or more extended attributes of the specified open file. This 
routine is similar to **FileGetPathExtAttributes** except that the file must 
be open.

**Pass:**  
bx - File handle of the open file.  
ax - **FileExtendedAttribute** specifying the attribute to get.  
es:di - Address of a locked or fixed buffer into which the attribute 
will be fetched. Alternatively, an array of **FileExtAttrDesc** 
structures, if ax is FEA_MULTIPLE. To retrieve custom 
attributes, you must use FEA_MULTIPLE and an appropriate 
**FileExtAttrDesc** structure.  
cx - Size of the buffer pointed to by **es:di**, or the number of 
entries if **es:di** points to an array of **FileExtAttrDesc** 
structures.

**Returns:**  
CF - Set if one or more attributes could not be retrieved, either 
because the file system does not support them or because the 
file did not have them. Even if CF is set on return, those 
attributes that could be retrieved are retrieved.  
ax - Error code if CF is set:  
ERROR_ATTR_NOT_SUPPORTED  
ERROR_ATTR_SIZE_MISMATCH  
ERROR_ATTR_NOT_FOUND  
ERROR_ACCESS_DENIED

**Destroyed:**  
Nothing. (**ax** destroyed if CF clear).

**Library:** file.def

----------
#### FileGetPathExtAttributes
Retrieves one or more extended attributes from the file whose path is 
specified. This routine is similar to **FileGetHandleExtAttributes** but 
specifies the file by its path rather than its handle.

**Pass:**  
ds:dx - Address of the null-terminated name of the file or directory 
to have its attributes returned.  
ax - **FileExtendedAttribute** value indicating the attribute to 
retrieve.  
es:di - Address of a locked or fixed buffer into which the attributes 
will be returned. If ax is passed as FEA_MULTIPLE, this will 
point to an array of **FileExtAttrDesc** structures. To retrieve 
custom attributes, you must use FEA_MULTIPLE and an 
appropriate **FileExtAttrDesc** structure.  
cx - Size of the buffer in **es:di**, or the number of 
**FileExtAttrDesc** structures in the array there.

**Returns:**  
CF - Set if one or more attributes could not be retrieved, either 
because the file system does not support them or because the 
file did not have them. Even if CF is set on return, those 
attributes that could be retrieved are retrieved.  
ax - Error code if CF is set:  
ERROR_FILE_NOT_FOUND  
ERROR_ATTR_NOT_SUPPORTED  
ERROR_ATTR_SIZE_MISMATCH  
ERROR_ATTR_NOT_FOUND

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileLockRecord
Locks a region of a file. The region may later be unlocked with 
**FileUnlockRecord**. This routine does not keep other threads from using or 
writing to the file; it only keeps others from locking the same region.

**Pass:**  
bx - File handle of open file.  
cx:dx - 32-bit start offset of region.  
si:di - 32-bit ending offset of region.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code if CF set: ERROR_ALREADY_LOCKED.

**Destroyed:**  
Nothing. (**ax** destroyed if CF clear).

**Library:** file.def

----------
#### FileMove
Moves a file or subdirectory from one place in the file system to another. Some 
file systems will allow directories to be moved across volumes, but other file 
systems will return an error in this case. Files, however, will always be 
moved (assuming the file name does not already exist and the destination 
directory is writable).

**Pass:**  
ds:si - Address of the null-terminated source file name.  
cx - Disk handle of the source disk. If a null handle is passed, the 
thread's current path is used and **ds:si** is assumed to point 
to a path extension relative to the current directory. If a disk 
handle is passed, the path in **ds:si** *must* be absolute.  
es:di - Address of the null-terminated destination file name.  
dx - Disk handle of the destination disk. If a null handle is passed, 
the thread's current path is used and **es:di** is assumed to 
point to a path extension relative to the current directory. If 
a disk handle is passed, the path in **es:di** *must* be absolute. 

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code if CF set on return:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
ERROR_TOO_MANY_OPEN_FILES  
ERROR_ACCESS_DENIED  
ERROR_SHORT_READ_WRITE (not enough space on dest.)  
ERROR_DIFFERENT_DEVICE  
ERROR_INSUFFICIENT_MEMORY

**Destroyed:**  
Nothing.

**Library:** file.def

**Warning:** This routine does not do an optimal move if links are involved in either the 
source or destination. To fix this, call **FileConstructActualPath** on either 
or both paths before calling **FileMove**.

----------
#### FileOpen
Opens an existing file.

**Pass:**  
al - **FileAccessFlags** record indicating the opening mode.  
ds:dx - Address of the null-terminated file name.

**Returns:**  
CF - Set if error, clear if the file was opened successfully.  
ax - If CF is clear, the file handle of the opened file. The 
*HF_otherInfo* field of the handle contains either the youngest 
handle to the same file or zero if no other handles are open to 
the file.  
If CF set, error code:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
ERROR_TOO_MANY_OPEN_FILES  
ERROR_SHARING_VIOLATION  
ERROR_WRITE_PROTECTED

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileOpenAndRead
Opens a file and reads its contents into a memory block.

**Pass:**  
ax - **FileOpenAndReadFlags**.  
ds:dx - Address of null-terminated file name.

**Returns:**  
CF - Set if error, clear otherwise.

ax - If CF is clear, memory handle of filled buffer. If CF is set, a 
**FileError** is returned in **ax**.

bx - (If CF is clear) file handle.

cx - (If CF is clear) buffer size of buffer pointed at by ax.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileParseStandardPath
Constructs the best combination of a **StandardPath** constant and a relative 
path. If the file system on which GEOS resides is case-insensitive, then the 
passed path must be in all upper case for it to be properly recognized.

**Pass:**  
es:di - Address of null-terminated path string to parse.  
bx - Disk handle of disk on which the path resides. Passing a null 
handle in bx indicates the drive name is specified in the path.

**Returns:**  
ax - **StandardPath** constant. SP_NOT_STANDARD_PATH 
indicates no standard path is applicable.  
es:di - Address of the null-terminated string representing the 
remainder of the path (relative to standard path in **ax**). No 
leading slash is returned.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FilePos
Sets an open file's read/write position.

**Pass:**  
al - **FilePosMode** indicating how to set the position:  
FILE_POS_START for start of file  
FILE_POS_RELATIVE for current read/write position  
FILE_POS_END for end of file  
bx - File handle of open file.  
cx:dx - 32-bit offset at which to put the read/write position. This 
offset will be added to the appropriate file position as 
determined by the **FilePosMode** passed in **al**.

**Returns:**  
dx:ax - New 32-bit read/write position. This number is absolute with 
respect to the start of the file.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileRead
Reads a number of bytes from an open file.

**Pass:**  
al - **FileAccessFlags**. Only FILE_NO_ERRORS is valid for this 
routine; all others must be clear.  
bx - File handle of the open file.  
cx - Number of bytes to read from the file.  
ds:dx - Address of a locked or fixed buffer into which to read the data.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - If CF set, an error code (otherwise destroyed):  
ERROR_SHORT_READ_WRITE if hit end of file  
ERROR_ACCESS_DENIED if file could not be opened  
cx - Total number of bytes read into the buffer.  
ds:dx - Address of the filled buffer containing the data.

**Destroyed:**  
Nothing. (ax is destroyed if CF is set.)

**Library:** file.def

----------
#### FileRename
Renames the specified file. This routine may not be used for moving a file to 
a new directory; use **FileMove** for that purpose.

**Pass:**  
ds:dx - Address of the current null-terminated file name.  
es:di - Address of the new null-terminated file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax	Error code (**FileError**) if CF set:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
ERROR_ACCESS_DENIED  
ERROR_INVALID_NAME

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileResolveStandardPath
Given a path and the current directory (set to a **StandardPath**), searches 
the sub-directories of the standard path and returns both the full path of the 
desired file and its disk handle.

**Pass:**  
ds:dx - Address of the null-terminated path to find.  
es:di - Address of a locked or fixed buffer into which the resulting 
full path will be written.  
cx - Size of the buffer in **es:di**.  
ax - **FRSPFlags** record:  
FRSPF_ADD_DRIVE_NAME  
Set if the drive name should be prepended to the returned 
path name.  
FRSPF_RETURN_FIRST_DIR  
Set if the routine should assume the desired path exists in 
the first existing directory along the standard path.

**Returns:**  
CF - Set if file not found, clear otherwise.  
bx - Disk handle if CF is clear; destroyed if CF is set.  
al - **FileAttrs** record of found file or directory.  
es:di - Address of the null at the end of the absolute path.

**Destroyed:**  
ah, cx (bx if CF is set)

**Library:** file.def

----------
#### FileSetAttributes
Sets a file's FileAttrs record.

**Pass:**  
cx - New attributes record (FileAttrs):  
FILE_ATTR_NORMAL for normal file  
FILE_ATTR_READ_ONLY for read-only file  
FILE_ATTR_HIDDEN for hidden file  
FILE_ATTR_SYSTEM for a system file  
ds:dx - Address of null-terminated file name.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code if CF set:  
ERROR_FILE_NOT_FOUND  
ERROR_PATH_NOT_FOUND  
ERROR_ACCESS_DENIED

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileSetCurrentPath
Sets the current directory of the calling thread.

**Pass:**  
bx - Disk handle of the path, or a **StandardPath** constant. Pass 
zero (null handle) for the current disk handle. If a 
**StandardPath** constant is passed, the path specified in 
**ds:dx** is taken relative to that standard path.  
ds:dx - Address of a null-terminated path. The path may or may not 
contain the drive name, and it may be relative or absolute. If 
the path contains the drive name, **bx** should be passed as 
zero.The drive name in the path will be ignored.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - **FileError** code if CF set on return:
ERROR_PATH_NOT_FOUND  
bx - Disk handle of new current path if bx passed as zero.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileSetDateAndTime
Sets an open file's modification date and time attributes.

**Pass:**  
bx - File handle of open file.  
cx - **FileTime** record indicating new modification time.  
dx - **FileDate** record indicating new modification date.

**Returns:**  
CF - Set if error, otherwise clear.  
ax - Error code if CF returned set:  
ERROR_ACCESS_DENIED

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileSetHandleExtAttributes
Sets one or more of an open file's extended attributes, given the file's handle. 
This is similar to **FileSetPathExtAttributes** except it specifies the file by 
its handle rather than its name.

**Pass:**  
bx - Handle of the open file.  
ax - **FileExtendedAttribute** indicating the attribute(s) to set.  
es:di - Address of a buffer containing either the value of the 
extended attribute specified in **ax**, or an array of 
**FileExtAttrDesc** structures (if **ax** is FEA_MULTIPLE).  
cx - Size of the buffer in **es:di**, or the number of entries if it is an 
array of structures.

**Returns:**  
CF - Set if one or more attribute could not be set, either because 
the file system does not support is or the file can not have it. 
CF will be clear on a successful operation.  
ax - Error code if CF set on return (destroyed if CF is clear):  
ERROR_ATTR_NOT_SUPPORTED  
ERROR_ATTR_SIZE_MISMATCH  
ERROR_ACCESS_DENIED

**Destroyed:**  
Nothing. (ax is destroyed if CF is clear.)

**Library:** file.def

----------
#### FileSetPathExtAttributes
Sets one or more of a file's extended attributes, given the file's path. This is 
similar to **FileSetHandleExtAttributes** except it specifies the file by its 
name rather than its handle.

**Pass:**  
ds:dx - Address of the null-terminated file or directory name.  
ax - **FileExtendedAttribute** indicating the attribute(s) to set.  
es:di - Address of a buffer containing the value of the attribute 
indicated in **ax**, or an array of **FileExtAttrDesc** structures 
if **ax** is FEA_MULTIPLE.  
cx - Size of the buffer in **es:di**, or the number of structures in the 
array if **ax** is FEA_MULTIPLE.

**Returns:**  
CF - Set if one or more attributes could not be set, either because 
the file system does not support it or the file can not have it. 
If successful, CF will be returned clear.  
ax - **FileError** if CF returned set.  
ERROR_FILE_NOT_FOUND  
ERROR_ATTR_NOT_SUPPORTED  
ERROR_ATTR_SIZE_MISMATCH  
ERROR_ACCESS_DENIED

**Destroyed:**  
Nothing. (ax is destroyed if CF is returned clear.)

**Library:** file.def

----------
#### FileSetStandardPath
Changes the thread's current directory to one of the standard system paths.

**Pass:**  
ax - **StandardPath** value indicating the new directory.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileSize
Returns the size of an open file, in bytes.

**Pass:**  
bx - File handle of open file.

**Returns:**  
dx:ax - 32-bit size of file, in bytes.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileStdPathCheckIfSubDir
Checks if the given **StandardPath** constant is actually a subdirectory of 
another **StandardPath**.

**Pass:**  
bp - First **StandardPath** value; checks is this is a potential 
parent directory.  
bx - Second **StandardPath** value; checks if **bx** is a subdirectory 
of **bp**.

**Returns:**  
ax - Zero if bx is a subdirectory of **bp**, non-zero otherwise.

**Destroyed:**  
Nothing.

**Library:** file.def

----------
#### FileTruncate
Truncates the given file to the passed length.

**Pass:**  
al - **FileAccessFlags**; only FILE_NO_ERRORS is accepted. The 
other flags *must* be cleared (zero).  
bx - File handle of open file to truncate.  
cx:dx - 32-bit desired length of the file, in bytes.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code (**FileError**) if CF set on return.  
File read/write position will be at the passed **cx:dx** upon return.

**Destroyed:**  
cx, dx

**Library:** file.def

----------
#### FileUnlockRecord
Unlocks a region of an open file previously locked with **FileLockRecord**.

**Pass:**  
bx - File handle of open file.  
cx:dx - 32-bit position of start of region to unlock.  
si:di - 32-bit region length.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code (**FileError**) if CF set on return.

**Destroyed:**  
Nothing. (ax is destroyed if CF is clear.)

**Library:** file.def

----------
#### FileWrite
Writes a string of bytes from a buffer to an open file.

**Pass:**  
al - **FileAccessFlags**; only FILE_NO_ERRORS is accepted. The 
other flags *must* be clear (zero).  
bx - File handle of the open file to be written to.  
ds:dx - Address of the locked or fixed buffer containing the bytes to 
be written to the file.  
cx - Number of bytes in the buffer to be written.

**Returns:**  
CF - Set if error, clear otherwise.  
ax - Error code (**FileError**) if CF returned set:  
ERROR_SHORT_READ_WRITE (possibly disk full)  
ERROR_ACCESS_DENIED (file not writable)  
cx - Number of bytes successfully written to the file.

**Destroyed:**  
Nothing. (ax is destroyed if CF is clear.)

**Library:** file.def

**Warning:** **FileWrite** will not truncate the file; it will only overwrite the bytes already 
there or append bytes to the end of the file.

----------
#### FloatAsciiToFloat
Converts a number represented in an ASCII text format into a GEOS FP 
number. The routine recognizes two flags:

**Pass:**  
al - **FloatAsciiToFloatFlags**.
FAF_PUSH_RESULT pushes the result onto the FP stack.
FAF_STORE_NUMBER stores the result in the address passed 
in **es:di**.  
cx - Number of characters in the string that the routine should 
concern itself with.  
ds:di - String in this format:  
"[+-] dddd.dddd [Ee] [+-] dddd"

**Returns:**  
CF - Set if error, clear otherwise.  
es:di - Buffer filled in if FAF_STORE_NUMBER was passed in **al**.

**Destroyed:**  
Nothing.

**Warning:** There can be at most a single decimal point in the passed string. Any spaces 
or thousands separators are ignored. The string is assumed to be legal; no 
error-checking on the string is performed.

**Library:** math.def

----------
#### FloatComp
Compares the top two FP numbers on the current floating point stack.

**Pass:**  
ds - Floating point segment. 

**Returns:**  
Flags are set by what may be considered the assembly instruction:

	cmp	X1,X2

where X2 is the top FP number on the stack and X1 is the FP number 
immediately beneath it.  
The top two FP numbers compared are returned intact.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatCompAndDrop
Compares the top two FP numbers on the current floating point stack.

**Pass:**  
ds - Floating point segment.

**Returns:**  
Flags are set by what may be considered the assembly instruction:

	cmp	X1,X2

where X2 is the top FP number on the stack and X1 is the FP number 
immediately beneath it. 
The top two FP numbers are popped off the stack.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatCompESDI
Compares the top number of the FP stack with a number pointed at by 
**es:di**. 

**Pass:**  
ds - The floating point stack segment.

**Returns:**  
Flags are set by what may be considered the assembly instruction:

	cmp	es:di, ds:si

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatCompPtr
Compares the top two FP numbers.

**Pass:**  
ds:si - Address of first number.  
es:di - Address of second number.

**Returns:**  
Flags are set by what may be considered the assembly instruction:

	cmp	es:di, ds:si

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatDateNumberGetMonthAndDay
Given a GEOS date number, extracts the month and day.

**Pass:**  
A GEOS data number on the FP stack.

**Returns:**  
bl - month.  
bh - day.  
The GEOS date number is popped off the FP stack.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatDwordToFloat
Converts a signed double-word integer into a floating point number. The 
floating point number is placed on the FP stack.

**Pass:**  
dx:ax - Signed double-word integer.

**Returns:**  
Nothing. (The FP number is on top of the FP stack.)

**Destroyed:**  
ax, dx

**Library:** math.def

----------
#### FloatEq0
Checks whether the number on top of the FP stack is equivalent to zero.

**Pass:**  
Nothing. The number checked is on top of the FP stack for the current thread.

**Returns:**  
CF - Set if true; clear otherwise. The number on the FP stack is 
popped off.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatExit
Frees the floating point stack for the current thread.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatFloatToAscii
Converts a GEOS floating point number into an ASCII string. The FP number 
on top of the FP stack is operated on unless 
*FFA_stackFrame*.FFA_FROM_ADDR is passed a value of 1.

**Pass:**  
ss:bp - an *FFA_stackFrame* stack frame.  
es:di - Destination address for the string to be written. This buffer 
must be either FLOAT_TO_ASCII_NORMAL_BUF_LEN or 
FLOAT_TO_ASCII_HUGE_BUFFER_LEN.

(If *FFA_stackFrame*.FFA_FROM_ADDR is equal to 1:  
ds:si - Location of FP number to convert.

**Returns:**  
cx - Number of characters in the string (excluding the 
null-terminator). If cx is equal to zero, then the string 
produced a NAN, either "underflow," "overflow," or "error."

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatFloatToAscii_StdFormat
Converts an FP number into an ASCII string using the format passed in al. 
This routine provides a means of converting a GEOS FP number into an ASCII 
string without having to set up the *FFA_stackFrame* required in 
**FloatFloatToAscii**.

Numbers are rounded away from 0.
E.g. if the number of fractional digits desired is equal to 1:  
0.56 is rounded to 1  
-0.56 is rounded to -1

Commas only apply to the integer portion of fixed and percentage format 
numbers. I.e. in scientific formats, the fractional and exponent portions of 
numbers will contain no commas even if FFAF_USE_COMMAS is passed.

**Pass:**  
ax - **FloatFloatToAsciiFormatFlags**  
Flags permitted:  
FFAF_FROM_ADDR=1  
Use the FP number at the address specified by **ds:si**.  
FFAF_FROM_ADDR=0  
Use the FP number on top of the FP stack. The number will 
be popped.  
FFAF_SCIENTIFIC=1  
Returns number in the form x.xxxE+xxx in accordance 
with information passed in **bh** and **bl**.  
FFAF_SCIENTIFIC=0  
Returns number in the form xxx.xxx in accordance with 
information passed in **bh** and **bl**.  
FFAF_PERCENT set  
Returns number in the form xxx.xxx% in accordance with 
information passed in **bh** and **bl**.  
FFAF_USE_COMMAS  
FFAF_NO_TRAIL_ZEROS

bh - Number of significant digits desired (must be greater than or 
equal to one). Fixed format numbers that require more digits 
than available will be forced to use scientific notation.

bl - Number of fractional digits (number of digits following the 
decimal point) desired.

ds:si - (If FFAF_FROM_ADDR is equal to 1 in **ax**):
Address of the FP number to convert.

es:di - Destination address for the string.

**Returns:**  
cx - Number of characters in the string. If **cx** = 0 the string 
produced was NAN, either "underflow," "overflow," or "error."

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatGeos80ToIEEE32
Converts a GEOS 80 bit FP number into a 32 bit IEEE-standard FP number.

**Pass:**  
Nothing. The number on top of the FP stack is converted.

**Returns:**  
dx:ax - 32 bit number.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatGeos80ToIEEE64
Converts a GEOS FP number into a 64 bit IEEE-standard FP number and 
pushes it onto the FP stack.

**Pass:**  
es:di - Location to store the 64 bit IEEE FP number.

**Returns:**  
CF - Set if an error occurred; clear otherwise.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatGetDateNumber
Creates a GEOS date number for the given date.

**Pass:**  
ax - year (1900 through 2099 are valid)  
bl - month (1 through 12)  
bh - day (1 through 31)

**Returns:**  
CF - Set if error; clear otherwise. The date number is placed on the 
FP stack if CF is clear.  
al - Error code (FLOAT_GEN_ERR) if CF set.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatGetDaysInMonth
This utility routine calculates the number of days in a month when also given 
its year.

**Pass:**  
ax - year (1900 through 2099)  
bl - month (1 through 12)

**Returns:**  
bh - Number of days in the month.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatGetStackDepth
Returns the current depth (in number of elements) of the floating point stack.

**Pass:**  
Nothing.

**Returns:**  
ax - Stack depth.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatGetTimeNumber
Calculates a GEOS time number given integral time data. GEOS time 
numbers are consecutive decimal values that correspond to times from 
midnight (0.000000) through 11:59:59 PM (0.999988).

**Pass:**  
ch - hours (0 through 23)  
dl - minutes (0 through 59)  
dh - seconds (0 through 59)

**Returns:**  
CF - Set if error; clear otherwise. The time number is placed on 
the FP stack if CF is clear.  
al - Error code (if CF is set) (FLOAT_GEN_ERR).

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatGt0
Checks whether the number on top of the FP stack is greater than zero.

**Pass:**  
Nothing. The number checked is on top of the FP stack for the current thread.

**Returns:**  
CF - Set if true; clear otherwise. The number on the FP stack is 
popped off.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatIEEE32ToGeos80
Converts a 32 bit IEEE-standard FP number into a GEOS 80 bit FP number.

**Pass:**  
dx:ax - 32 bit FP number.

**Returns:**  
Nothing. The converted number is placed on the FP stack.

**Destroyed:**  
ax, dx

**Library:** math.def

----------
#### FloatIEEE64ToGeos80
Converts a 64 bit IEEE-standard FP number into a GEOS 80 bit FP number.

**Pass:**  
es - Floating point stack segment  
ds:si - IEEE 64 bit FP number.

**Returns:**  
Nothing. The converted number is placed on the FP stack

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatInit
Initializes a floating point stack for the current thread. This routine allocates 
a block of memory for this purpose and makes note of it in 
**ThreadPrivateData**.

**Pass:**  
ax - Floating point stack size (in number of elements).  
bl - **FloatStackType** enumerated type indicating how to handle 
the exhaustion of the floating stack space:  
FLOAT_STACK_GROW  
FLOAT_STACK_WRAP  
FLOAT_STACK_ERROR

**Returns:**  
bx - Handle of the floating point stack. (Normal applications will 
not need this handle; this is used by co-processor libraries.)

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatLt0
Checks whether the number on top of the FP stack is less than zero.

**Pass:**  
Nothing. The number checked is on top of the FP stack for the current thread.

**Returns:**  
CF - Set if true; clear otherwise. The number on the FP stack is 
popped off.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatPick
Selects an FP number on the floating point stack, copies it, and pushes it on 
top of the FP stack. The entire stack is pushed in the process. For example, 
**FloatPick** passed with a value of 3 would copy the contents of the third 
number on the FP stack onto the top of the stack.

**Pass:**  
bx - Integer stack location of the FP number to copy (1 being the 
top FP number on the stack).  
ds - FP stack segment.

**Returns:**  
Nothing.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatPopNumber
Pops a floating point number off the FP stack into a passed location.

**Pass:**  
es:di - Address of location to store the FP number (5 words).

**Returns:**  
CF - Set if error; clear otherwise.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatPushNumber
Pushes an FP number onto the top of the FP stack for the current thread 
from a passed buffer. The number must be already set up in 80 bit, FP 
format.

**Pass:**  
ds:si - Address of GEOS 80 bit FP number.

**Returns:**  
CF - Set if error; clear otherwise.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatRandomize
Primes the random number generator, in preparation for a call to 
**FloatRandom** or **FloatRandomN**. If **FloatRandomize** is passed the 
flag RGIF_USE_SEED, the routine must also pass a developer supplied seed.

**Pass:**  
al - RandomGenInitFlags:  
RGIF_USE_SEED  
RGIF_GENERATE_SEED  
cx:dx - Seed (if RGIF_USE_SEED is passed in al).  
ds - Floating point stack segment.

**Returns:**  
Nothing.

**Destroyed:**  
ax, dx

**Library:** math.def

----------
#### FloatRoll
Pushes a selected FP number onto the top of the stack, removing it from its 
previous location in the process. **FloatRoll** passed with a value of 3 would 
move the FP number in the third stack position onto the top of the stack, 
pushing the stack in the process. All FP numbers below the extracted 
number remain unaffected by this routine.

**Pass:**  
bx - Position of number on FP stack to "roll."  
ds - Floating point stack segment.

**Returns:**  
Nothing.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatRollDown
Performs the inverse operation of **FloatRoll**, popping the top stack value 
into a specified location on the stack. **FloatRollDown** passed with a value 
of 3 would move the FP number on top of the stack into the third stack 
location, shifting the stack in the process.

**Pass:**  
Nothing.

**Returns:**  
CF - Set if error: clear otherwise.  
al - **FloatErrorType** if CF set.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatRound
Rounds the top FP stack number to a given number of decimal places. 
**FloatRound** passed with zero as an argument rounds the top FP number 
to the nearest integer, rounding up if greater than or equal to .5, rounding 
down if less than .5.

**Pass:**  
Nothing.

**Returns:**  
CF - Set if error: clear otherwise.  
al - FloatErrorType if CF set.

**Destroyed:**  
ax

**Library:** math.def

----------
#### FloatSetStackDepth
Sets the depth of the FP stack.

**Pass:**  
ax - Stack depth.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatSetStackPointer
Sets the floating point stack pointer to a previous position saved with 
**FloatGetStackPointer**. This routine must be passed a value that is 
greater than or equal to the current value of the stack pointer. (I.e. you 
must be throwing something, or nothing, away.)

**Pass:**  
ax - Desired value of the stack pointer.

**Returns:**  
CF - Clear if successful; dies in EC code if unsuccessful.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatSetStackSize
Sets the size of the FP stack.

**Pass:**  
Nothing.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing.

**Library:** math.def

----------
#### FloatStringGetDateNumber
Parses a string containing a date and returns its date number.

**Pass:**  
es:di - String to parse.

**Returns:**  
CF - Set if error; clear otherwise.  
al - (If CF is set) error code (FLOAT_GEN_ERR).  
ax - **DateTimeFormat** used.

**Destroyed:**  


**Library:** math.def

----------
#### FloatStringGetTimeNumber
Parses a string containing a time and returns its time number.

**Pass:**  
es:di - String to parse.

**Returns:**  
CF - Set if error; clear otherwise.  
al - (If CF is set) error code (FLOAT_GEN_ERR).

**Destroyed:**  


**Library:** math.def

----------
#### FloatWordToFloat
Converts a signed integer (word value) into a GEOS 80 bit floating point 
number on the FP stack.

**Pass:**  
ax - Signed integer.

**Returns:**  
Nothing.

**Destroyed:**  
ax, dx

**Library:** math.def

----------
#### FlowCheckKbdShortcut
Determines whether the key-press event maps to a shortcut.

**Pass:**  
ds:si - Pointer to a shortcut table.  
ax - Number of entries in the shortcut table.  
cl, ch - **Character**, **CharacterSet** (as passed by 
MSG_META_KBD_CHAR).  
dl, dh - **CharFlags**, **ShiftState** (as passed by 
MSG_META_KBD_CHAR).  
bp - Scan code:**ToggleState** (as passed by 
MSG_META_KBD_CHAR).

**Returns:**  
CF - Set if a keyboard shortcut match was found.  
si - Offset into table where shortcut was found.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

----------
#### FlowDispatchSendOnOrDestroyClassedEvent
This utility routine relays a classed routine.

**Pass:**  
*ds:si - Object instance data.  
ax - Message to send.  
cx - Handle of classed event. If Class is null, event should be sent 
directly to optr passed in **bx:bp**.  
dx - Other data to send on.  
bx:bp - Optr to relay message to if the current object isn't of the 
proper class to handle the message. If this optr is null and 
event can't be handled by the current object, then the event 
will be destroyed.  
di - MessageFlags for data to send on (MF_CALL also passed on to 
**ObjDispatchMessage**, if used, in order to allow for return 
data).

**Returns:**  
CF - Clear if no destination, otherwise returned as per 
**ObjMessage**.  
ax, cx, dx, bp - If MF_CALL was passed and the call was completed, then 
these will hold the message's return values.  
ds - Update to point at segment of same block as on entry if 
MF_FIXUP_DS was set and destination found.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

**Warning:**  
This routine may resize LMem or object blocks, moving them on the heap and 
invalidating stored segment pointers to them.

----------
#### FlowGetTargetAtTargetLevel
This routine retrieves the target within the current level of the target 
hierarchy.

**Pass:**  
*ds:si - Object instance data.  
ax - TargetLevel of object in ***ds:si**.  
bx - Offset to Master part.  
di - Offset to targetExcl field of type **HierarchicalGrab** in 
instance data of object in ***ds:si**.  
cx - **TargetLevel** searching for.

**Returns:**  
cx:dx - If the passed object is the object being searched for, then this 
will be the object instance data. If this object is not the one 
being searched for and there is no target below this node, 
then this will be zero. Otherwise, this will be the instance 
data of the object below this node that contains the target.  
ax:bp - If the passed object is the object being searched for, then this 
will be the class pointer for the object. If this is not the object 
being searched for and there is no target below this node, 
then this will be zero. Otherwise, this will be the class pointer 
of the target below this node.  
ds - Updated to point to the segment of the same block as on 
entry.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

**Warning:**  
This routine may resize LMem or object blocks, moving them on the heap and 
invalidating stored segment pointers to them.

----------
#### FlowGetUIButtonFlags
Returns the current **UIButtonFlags**.

**Pass:**  
Nothing.

**Returns:**  
al - **UIButtonFlags** structure.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

----------
#### FlowReleaseGrab
Releases the grab of the current OD if it matches that passed. The object is 
sent a MSG_META_LOST_..._EXCL (if specified) and the OD and data word are 
zeroed out to indicate that there is no current grab.

**Pass:**  
*ds:si - Object instance data.  
ax - Number of "gained grab" message to send (e.g. 
MSG_META_GAINED_MOUSE_EXCL). This message will be 
sent to the object gaining the grab, and the next higher 
message number will be sent to the object losing the grab. 
Because of the way these messages are set up, this will be the 
corresponding "lost grab" message (e.g. 
MSG_META_LOST_MOUSE_EXCL)  
bx - Offset to Master part holding BasicGrab structure (zero if no 
master parts).  
di - Offset to BasicGrab structure.  
cx:dx - Number of bytes in the buffer to be written.

**Returns:**  
CF	Set if grab OD changed and messages were sent.  
ds 	Updated to point at segment of same block as on entry.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

**Warning:**  
This routine may resize LMem or object blocks, moving them on the heap and 
invalidating stored segment pointers to them.

----------
#### FlowRequestGrab
This routine grants the grab to the OD passed if there is no active grab. If the 
OD passed matches that in existence then the data word is updated and no 
message is sent.

**Pass:**  
*ds:si - Object instance data.  
ax - Number of "gained grab" message to send (e.g. 
MSG_META_GAINED_MOUSE_EXCL). This message will be 
sent to the object gaining the grab, and the next higher 
message number will be sent to the object losing the grab. 
Because of the way these messages are set up, this will be the 
corresponding "lost grab" message (e.g. 
MSG_META_LOST_MOUSE_EXCL)  
bx - Offset to Master part holding BasicGrab structure (zero if no 
master parts).  
di - Offset to BasicGrab structure.  
cx:dx - Number of bytes in the buffer to be written.  
bp  - Data to be placed in BG_data field.

**Returns:**  
CF - Set if grab OD changed and messages were sent.  
ds - Updated to point at segment of same block as on entry.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

**Warning:**  
This routine may resize LMem or object blocks, moving them on the heap and 
invalidating stored segment pointers to them.

----------
#### FlowTranslatePassiveButton
This routine translates a MSG_META_PRE_PASSIVE_BUTTON or 
MSG_META_POST_PASSIVE_BUTTON to a generic message.

**Pass:**  
ax - Message, either MSG_META_PRE_PASSIVE_BUTTON or 
MSG_META_POST_PASSIVE_BUTTON.  
cx, dx - Mouse position (not used here, but left intact through call).  
bp - **UIFunctionsActive:ButtonInfo** as passed in bp in above 
messages.  
cx - Number of bytes in the buffer to be written.

**Returns:**  
ax, cx, dx, bp - Set up to send translated message (e.g. ax will be changed to 
the appropriate message number).

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

----------
#### FlowUpdateHierarchicalGrab
Update exclusive based on passed message.

**Pass:**  
*ds:si - Object instance data.  
ax - Number of "gained grab" message to implement (e.g. 
MSG_META_GAINED_SYS_FOCUS_EXCL).  
bx - Offset to Master part.

di - Offset to HierarchicalGrab structure.  
bp - Base message for level exclusive (e.g. 
MSG_META_GAINED_-EXCL). This message will be sent to 
the requesting object if it gains the exclusive. The next higher 
message (MSG_META_LOST_-_EXCL, thanks to the way 
these messages are ordered) will be sent when the object 
eventually loses the grab. The message number plus two 
(MSG_META_GAINED_SYS_-_EXCL) is sent out after the 
"gained" message to the object that gains the system 
exclusive. If the HGF_SYS_EXCL but is set in this node, then 
the message plus three (MSG_META_LOST_SYS_-_EXCL) is 
sent out before the "lost" message to any object losing the 
system exclusive.

**Returns:**  
ds - Updated to point at segment of same block as on entry.

**Destroyed:**  
Nothing.

**Library:** uiInputC.def

**Warning:**  
This routine may resize LMem or object blocks, moving them on the heap and 
invalidating stored segment pointers to them.

[Routines A-D](asma_d.md) <-- [Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Routines G-G](asmg_g.md)