## 3.2 Routines E-F
----------
#### EC()
    void    EC(line);

This macro defines a line of code that will only be compiled into the 
error-checking version of the geode. The *line* parameter of the macro is the 
actual line of code. When the EC version of the program is compiled, the line 
will be treated as a normal line of code; when the non-EC version is compiled, 
the line will be ignored.

----------
#### EC_BOUNDS()
    void    EC_BOUNDS(addr);

This macro adds an address check to the error-checking version of a program. 
When the EC version of the program is compiled, the address check will be 
included; when the non-EC version is compiled, the address check will be left 
out. The *addr* parameter is the address or pointer to be checked.

The macro expands to a call to **ECCheckBounds()** on the specified address 
or pointer. If the address is out of bounds, the program will stop with a call 
to **FatalError()**.

**See Also:** ECCheckBounds()

----------
#### EC_ERROR()
    void    EC_ERROR(code);

This macro inserts a call to **FatalError()** in the error-checking version of the 
program and does nothing to the non-EC version. When the program gets to 
this point, it will halt and put up an error message corresponding to the 
specified error *code*. If a condition should be checked before calling 
**FatalError()**, you can use EC_ERROR_IF() instead.

----------
#### EC_ERROR_IF()
    void    EC_ERROR_IF(test, code);

This macro inserts a conditional call to **FatalError()** in the error-checking 
version of a program; it does nothing for the non-EC version. The *test* 
parameter is a Boolean value that, if *true*, will cause the **FatalError()** call 
to be made. If test is *false*, **FatalError()** will not be called.

----------
#### EC_WARNING()
    EC_WARNING(word warningCode);

This macro generates a warning for the debugger when executed by 
error-checking code; it has no effect when in non-EC code.

**Include:** ec.h

----------
#### EC_WARNING_IF()
    EC_WARNING_IF(<expr>, word warningCode)

When this macro is executed in error-checking code, it tests <*expr*>; if  <*expr*> 
is non-zero, it generates a warning with code *warningCode* for the debugger.

In non-EC code, the macro has no effect (and <*expr*> is not evaluated).

**Include:** ec.h

----------
#### ECCheckBounds()
    void    ECCheckBounds(
            void    *address);

This routine checks to see if the given pointer is within bounds of the block 
into which it points. If assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckChunkArray()
    void    ECCheckChunkArray(
            optr    o);

This routine checks the validity of the specified chunk array. If the assertions 
fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckChunkArrayHandles()
    void    ECCheckChunkArrayHandles(
            MemHandle mh,
            ChunkHandle ch);

This routine checks the validity of the specified chunk array. If the assertions 
fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckClass()
    void    ECCheckClass(
            ClassStruct *class);

This routine checks that the given pointer actually references a class 
definition. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckDriverHandle()
    void    ECCheckDriverHandle(
            GeodeHandle gh);

This routine checks that the passed handle actually references a driver. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckEventHandle()
    void    ECCheckEventHandle(
            EventHandle eh);

This routine checks that the passed handle actually references a stored 
message. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckFileHandle()
    void    ECCheckFileHandle(
            FileHandle file);

This routine checks that the passed handle actually is a file handle and 
references a file. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckGeodeHandle()
    void    ECCheckGeodeHandle(
            GeodeHandle gh);

This routine checks that the passed handle references a loaded geode. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckGStateHandle()
    void    ECCheckGStateHandle(
            GStateHandle gsh);

This routine checks that the passed handle references a GState. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckHugeArray()
    void    ECCheckHugeArray(
            VMFileHandle        vmFile,
            VMBlockHandle       vmBlock);

This routine checks the validity of the passed Huge Array. If the block passed 
is not the directory block of a Huge Array, the routine fails.

**Include:** ec.h

----------
#### ECCheckLibraryHandle()
    void    ECCheckLibraryHandle(
            GeodeHandle gh);

This routine checks that the passed handle references a library. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemChunk()
    void    ECCheckLMemChunk(
            void * chunkPtr);

This routine checks the validity of the chunk pointed to by *chunkPtr*. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemHandle()
    void    ECCheckLMemHandle(
            MemHandle mh);

This routine checks that the passed handle is a memory handle and actually 
references a local memory block. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemHandleNS()
    void    ECCheckLMemHandleNS(
            MemHandle mh);

This routine checks that the passed handle is a local memory handle; unlike 
**ECCheckLMemHandle()**, however, it does not check sharing violations 
(when threads are illegally using non-sharable memory). If the assertions 
fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemObject()
    void    ECCheckLMemObject(
            optr    obj);

This routine checks the validity of an object to ensure that it is an object 
stored in an object block. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemObjectHandles()
    void    ECCheckLMemObjectHandles(
            MemHandle mh,
            ChunkHandle ch);

This routine checks the validity of an object to ensure that it is an object 
stored in an object block. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemOD()
    void    ECCheckLMemOD(
            optr    o);

This routine checks the validity of the given local-memory-based object. If 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckLMemODHandles()
    void    ECCheckLMemODHandles(
            MemHandle objHan,
            ChunkHandle objCh);

This routine checks the validity of the given local-memory-based object. If 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckMemHandle()
    void    ECCheckMemHandle(
            MemHandle mh);

This routine checks that the passed handle is a memory handle that 
references a memory block. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckMemHandleNS()
    void    ECCheckMemHandleNS(
            MemHandle mh);

This routine checks that the passed handle references a memory block; 
unlike **ECCheckMemHandle()**, however, it will not check for sharing 
violations (when a thread illegally accesses a non-sharable block). If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckObject()
    void    ECCheckObject(
            optr    obj);

This routine checks the validity of the given locked object. If the assertions 
fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckObjectHandles()
    void    ECCheckObjectHandles(
            Memhandle mh,
            ChunkHandle ch);

This routine checks the validity of the given locked object. If the assertions 
fail, a fatal error will occur.

----------
#### ECCheckOD()
    void    ECCheckOD(
            optr    obj);

This routine checks the validity of the given object. Unlike 
**ECCheckLMemObject()**, however, it allows optrs of Process objects to be 
specified. If assertions fail, a fatal error will occur.

----------
#### ECCheckODHandles()
    void    ECCheckODHandles(
            MemHandle objHan,
            ChunkHandle objCh);

This routine checks the validity of the given object. Unlike 
**ECCheckLMemObjectHandles()**, however, it allows processes to be 
specified. If assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckProcessHandle()
    void    ECCheckProcessHandle(
            GeodeHandle gh);

This routine checks that the passed handle actually references a process. If 
the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckQueueHandle()
    void    ECCheckQueueHandle(
            QueueHandle qh);

This routine ensures the passed handle references an event queue. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckResourceHandle()
    void    ECCheckResourceHandle(
            MemHandle mh);

This routine ensures that the passed handle references a geode resource. If 
the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckStack()
    void    ECCheckStack();

This routine checks to make sure the current stack has not overflown (and is 
not about to). This routine also enforces a 100-byte gap between the stack 
bottom and the stack pointer. If assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckThreadHandle()
    void    ECCheckThreadHandle(
            ThreadHandle th);

This routine checks that the passed handle actually references a thread. If 
the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECCheckWindowHandle()
    void    ECCheckWindowHandle(
            WindowHandle wh);

This routine checks that the passed handle actually references a window. If 
the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECLMemExists()
    void    ECLMemExists(
            optr    o);

This routine checks to see if the specified chunk exists. This routine should 
be called by applications to check the chunk handle's validity. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECLMemExistsHandles()
    void    ECLMemExistsHandles(
            MemHandle mh,
            ChunkHandle ch);

This routine checks to see if the specified chunk exists. This routine should 
be called by applications to check the chunk handle's validity. If the 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECLMemValidateHandle()
    void    ECLMemValidateHandle(
            optr    o);

This routine checks that the passed optr points to a local memory chunk. If 
the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECLMemValidateHandleHandles()
    void    ECLMemValidateHandleHandles(
            MemHandle mh,
            ChunkHandle ch);

This routine checks that the passed memory and chunk handles actually 
reference a local memory chunk. If the assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECLMemValidateHeap()
    void    ECLMemValidateHeap(
            MemHandle mh);

This routine does a complete error-check of the LMem heap. It is used 
internally and should not be needed by application programmers.

**Include:** ec.h

----------
#### ECMemVerifyHeap()
    void    ECMemVerifyHeap()

This routine makes sure the global heap is in a consistent state. If the 
assertions fail, a fatal error will occur. This routine should likely not be called 
by anything other than the EC kernel.

**Include:** ec.h

----------
#### ECVMCheckMemHandle()
    void    ECVMCheckMemHandle(
            MemHandle han);

This routine checks that the given memory handle is actually linked to a VM 
block handle. If assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECVMCheckVMBlockHandle()
    void    ECVMCheckVMBlockHandle(
            VMFileHandle file,
            VMBlockHandle block);

This routine checks the validity of the given VM file and block handles. If 
assertions fail, a fatal error will occur.

**Include:** ec.h

----------
#### ECVMCheckVMFile()
    void    ECVMCheckVMFile(
        VMFileHandle file);

This routine checks the validity of the given VM file handle. If assertions fail, 
a fatal error will occur.

**Include:** ec.h

----------
#### ElementArrayAddElement ()
    word    ElementArrayAddElement(
            optr    arr,            /* Handle of element array */
            void *  element,        /* Element to add (if necessary) */
            dword   callBackData,   /* This is passed to the Callback routine */
            Boolean _pascal (*callback) (void *elementToAdd, 
                        void *elementFromArray, dword valueForCallback));

This routine is used to add elements to an array. It is passed the address of a 
potential element. It compares the element with each member of an element 
array. If there are no matches, it adds the element to the array and sets the 
reference count to one. If there is a match, it increments the reference count 
of the matching element in the array and returns; it does not add the new 
element. When you pass the address of an element, make sure you pass the 
address of the data portion of the element (not the reference-count header).

You can pass a callback routine to **ElementArrayAddElement()**. 
**ElementArrayAddElement()** will call the callback routine to compare 
elements and see if they match. The callback routine should be declared 
_pascal. **ElementArrayAddElement()** passes the callback routine the 
address of the element you passed it, as well as the address of the 
data-portion of the element in the array (the part after the 
**RefElementHeader** structure). If the two elements match (by whatever 
criteria you use), return *true*; otherwise, return *false*. If you pass a null 
function pointer, the default comparison routine will be called, which checks 
to see if every data byte matches.

**Include:** chunkarr.h

**Tips and Tricks:** If you know the element is already in the array, you can increment its 
reference count by calling **ElementArrayAddReference()**.

**Be Sure To:** Lock the block on the global heap before calling (unless it is fixed).

**See Also:** ElementArrayAddReference()

----------
#### ElementArrayAddElementHandles()
    word    ElementArrayAddElementHandles(
            MemHandle       mh,             /* Global handle of LMem heap */
            ChunkHandle     chunk           /* Chunk handle of element array */
            void *          element,        /* Element to add */
            dword           callBackData,   /* Passed to the Callback routine */
            Boolean _pascal (*callback) (void *elementToAdd, 
                        void *elementFromArray, dword valueForCallback));

This routine is exactly like **ElementArrayAddElement()** above, except 
that the element array is specified by its global and chunk handles (instead 
of with an optr).

**Include:** chunkarr.h

**Tips and Tricks:** If you know the element is already in the array, you can increment its 
reference count by calling **ElementArrayAddReferenceHandles()**.

**Be Sure To:** Lock the block on the global heap before calling (unless it is fixed).

**See Also:** ElementArrayAddReferenceHandles()

----------
#### ElementArrayAddReference()
    void    ElementArrayAddReference(
            optr    arr,        /* optr to element array */
            word    token);     /* Index number of element */

This routine increments the reference count of a member of an element array. 

**Be Sure To:** Lock the block on the global heap before calling (unless it is fixed).

**See Also:** ElementArrayAddElement()

----------
#### ElementArrayAddReferenceHandles()
    void    ElementArrayAddReferenceHandles(
            MemHandle       mh,         /* Handle of LMem heap's block */
            ChunkHandle     ch,         /* Handle of element array */
            word            token);     /* Index number of element */

This routine is exactly like **ElementArrayAddReference()** above, except 
that the element array is specified by its global and chunk handles (instead 
of with an optr).

**Include:** chunkarr.h

----------
#### ElementArrayCreate()
    ChunkHandle ElementArrayCreate(
            MemHandle   mh,             /* Handle of LMem heap's block */
            word        elementSize,    /* Size of each element, or zero
                                         * for variable-sized */
            word        headerSize);    /* Header size (zero for default) */

This routine creates an element array in the indicated LMem heap. It creates 
an **ElementArrayHeader** structure at the head of the chunk. If you want 
to leave extra space before the start of the array, you can pass a larger header 
size; if you want to use the standard header, pass a header size of zero.

You can specify the size of each element. Remember that the first three bytes 
of every element in an element array are the element's **RefElementHeader**; 
structure, which contains the reference count; leave room for this when you 
choose a size. For arrays with variable-sized elements, pass a size of zero.

**Include:** chunkarr.h

**Tips and Tricks:** You may want to declare a structure for array elements; the first component 
should be a **RefElementHeader**. You can pass the size of this structure to 
**ElementArrayCreate()**.

If you want extra space after the **ElementArrayHeader**, you may want to 
create your own header structure, the first element of which is an 
**ElementArrayHeader**. You can pass the size of this header to 
**ElementArrayCreate()**, and access the data in your header via the 
structure.

**Be Sure To:** Lock the block on the global heap before calling this routine (unless it is 
fixed). If you pass a header size, make sure it is larger than 
**sizeof(ElementArrayHeader)**.

----------
#### ElementArrayCreateAt
    ChunkHandle     ElementArrayCreateAt(
            optr    arr,            /* optr of chunk for array */
            word    elementSize,    /* Size of each element, or zero
                                     * for variable-sized */
            word    headerSize);    /* Header size (zero for default) */

This routine is just like **ElementArrayCreate()** above, except that the 
element array is created in a pre-existing chunk. The contents of that chunk 
will be overwritten.

**Include:** chunkarr.h

**Warnings:** If the chunk isn't large enough, it will be resized. This will invalidate all 
pointers to chunks in that block.

----------
#### ElementArrayCreateAtHandles
    ChunkHandle     ElementArrayCreateAtHandles(
            MemHandle   mh,             /* Handle of LMem heap */
            ChunkHandle ch              /* Create array in this chunk */
            word        elementSize,    /* Size of each element, or zero
                                             * for variable-sized */
            word        headerSize);    /* Header size (zero for default) */

This routine is exactly like **ElementArrayCreateAt()** above, except that 
the element array is specified by its global and chunk handles (instead of 
with an optr).

**Include:** chunkarr.h

**Warnings:** If the chunk isn't large enough, it will be resized. This will invalidate all 
pointers to chunks in that block.

----------
#### ElementArrayDelete()
    void    ElementArrayDelete(
            optr    arr,        /* optr to element array */
            word    token);     /* index of element to delete */

This routine deletes an element from an element array regardless of its 
reference count. The routine is passed the element array's optr and the token 
for the element to delete.

Note that when an element is removed, it is actually resized down to zero size 
and added to a list of free elements. That way the index numbers of later 
elements are preserved.

**Include:** chunkarr.h

**Be Sure To:** Lock the block on the global heap before calling (unless it is fixed).

**See Also:** ElementArrayRemoveReference()

----------
#### ElementArrayDeleteHandles()
    void    ElementArrayDeleteHandles(
            MemHandle   mh,         /* Handle of LMem heap */
            ChunkHandle ch,         /* Chunk handle of element array */
            word        token);     /* Index of element delete */

This routine is exactly like **ElementArrayDelete()** above, except that the 
element array is specified by its global and chunk handles (instead of with an 
optr).

**Include:** chunkarr.h

**Be Sure To:** Lock the block on the global heap before calling (unless it is fixed).

**See Also:** ElementArrayRemoveReference()

----------
#### ElementArrayElementChanged()
    void    ElementArrayElementChanged(
            optr    arr,                /* optr to element array */
            word    token,              /* Index number of element */
            dword   callbackData,       /* This is passed along to callback */
            Boolean _pascal (*callback) /* Returns true if elements identical */
                        (void *     elementChanged,
                         void *     elementToCompare,
                         dword      valueForCallback));

This routine checks to see if an element is identical to any other elements in 
the same element array. This is used after an element has changed to see if 
it now matches another element. If the element matches another, it will be 
deleted, and the other element will have its reference count incremented.

The routine is passed an optr to the element array, the token of the element 
which is being checked, a dword of data (which is passed to the callback 
routine), and a pointer to a callback comparison routine. The callback routine 
itself is passed pointers to two elements and the *callbackData* argument 
passed to **ElementArrayElementChanged()**. The callback routine should 
be declared _pascal. If the two elements are identical, the callback should 
return *true* (i.e. non-zero); otherwise, it should return *false*.

If you pass a null function pointer, **ElementArrayElementChanged()** will 
do a bytewise comparison of the elements.

**Include:** chunkarr.h

----------
#### ElementArrayElementChangedHandles()
    void    ElementArrayElementChangedHandles(
            MemHandle       memHandle,      /* Handle of LMem heap's block */
            ChunkHandle     chunkHandle,    /* Chunk handle of element array */
            word            token,          /* Index number of element */
            dword           callbackData,   /* This is passed along to
                                             * callback */
            Boolean _pascal (*callback)     /* Returns true if elements identical */
                            (void *     elementChanged,
                             void *     elementToCompare,
                             dword      valueForCallback));

This routine is exactly like **ElementArrayElementChanged()** above, 
except that the element array is specified by its global and chunk handles 
(instead of with an optr).

**Include:** chunkarr.h

----------
#### ElementArrayGetUsedCount()
    word    ElementArrayGetUsedCount(
            optr    arr,            /* optr to element array */
            dword   callbackData,           /* This is passed to callback routine */
            Boolean _pascal (*callback)             /* return true to count this element */
                        (void * element, dword cbData));

This routine counts the number of active elements in an element array; that 
is, elements which have a reference count of one or greater. It can be 
instructed to count every element, or every element which matches certain 
criteria. The routine is passed three parameters: the optr of the chunk array, 
a dword which is passed to the callback routine, and a callback routine which 
determines whether the element should be counted. The callback 
routine,which should be declared _pascal, is passed the dword an a pointer 
to an element. It should return *true* if the element should be counted; 
otherwise, it should return *false*. To count every element, pass a null callback 
pointer.

**Include:** chunkarr.h

**See Also:** ElementArrayTokenToUsedIndex(), ElementArrayUsedIndexToToken()

----------
#### ElementArrayGetUsedCountHandles()
    void    ElementArrayGetUsedCountHandles(
            MemHandle   mh,             /* Handle of LMem heap's block */
            ChunkHandle ch,             /* Chunk handle of element array */
            dword       callbackData,   /* This is passed to callback routine */
            Boolean _pascal (*callback) /* return true to count this element */
                        (void * element, dword cbData));

This routine is exactly like **ElementArrayGetUsedCount()** above, except 
that the element array is specified by its global and chunk handles (instead 
of with an optr).

**Include:** chunkarr.h

----------
#### ElementArrayRemoveReference()
    void    ElementArrayRemoveReference(
            optr    arr,            /* optr of element array */
            word    token,          /* Index of element to unreference */
            dword   callbackData,   /* Passed to callback routine */
            void _pascal (*callback) (void *element, dword valueForCallback));
                    /* Routine is called if element is actually removed */

This routine decrements the reference count of the specified element. If the 
reference count drops to zero, the element will be removed. If an element is 
to be removed, **ElementArrayRemoveReference()** calls the callback 
routine on that element. The callback routine should perform any cleanup 
necessary; it is passed a pointer to the element and the *callbackData* 
argument. If you pass a null function pointer, no callback routine will be 
called.

Note that when an element is removed, it is actually resized down to zero size 
and added to a list of free elements. That way the index numbers of later 
elements are preserved.

**Be Sure To:** Lock the block on the global heap before calling (unless it is fixed).

**See Also:** ElementArrayDelete()

**Include:** chunkarr.h

----------
#### ElementArrayRemoveReferenceHandles()
    void    ElementArrayRemoveReferenceHandles(
            MemHandle   mh,             /* Handle of LMem heap */
            ChunkHandle ch,             /* Chunk handle of element array */
            word        token,          /* Index of element to unreference */
            dword       callbackData,   /* Passed to callback routine */
            void _pascal (*callback) (void *element, dword valueForCallback));
                    /* Routine is called if element is actually removed */

This routine is exactly like **ElementArrayRemoveReference()** above, 
except that the element array is specified by its global and chunk handles 
(instead of with an optr).

**Include:** chunkarr.h

----------
#### ElementArrayTokenToUsedIndex()
    word    ElementArrayTokenToUsedIndex(
            optr    arr,                /* Handle of element array */
            word    token,              /* Index of element to unreference */
            dword   callbackData,       /* Data passed to callback routine */
            Boolean _pascal (*callback) /* Return true to count this element */
                    (void *element, dword cbData));

This routine is passed the token of an element array. It translates the token 
into an index from some non-standard indexing scheme. The indexing 
scheme can either number the elements from zero, counting only those 
elements in use (i.e. those with a reference count greater than zero); or it can 
use a more restrictive scheme. If a callback routine is passed, the callback 
routine will be called for every used element; it should be declared _pascal 
and return *true* if the element should be counted. If a null callback pointer is 
passed, every used element will be counted.

**Include:** chunkarr.h

----------
#### ElementArrayTokenToUsedIndexHandles()
    word    ElementArrayTokenToUsedIndexHandles(
            MemHandle   mh,             /* Handle of LMem heap */
            ChunkHandle ch,             /* Chunk handle of element array */
            word        token,          /* Index of element to unreference */
            dword       callbackData,   /* Data passed to the
                                         * callback routine */
            Boolean _pascal (*callback) /* Return true to count this element */
                    (void *element, dword cbData));

This routine is exactly like **ElementArrayTokenToUsedIndex()** above, 
except that the element array is specified by its global and chunk handles 
(instead of with an optr).

**Include:** chunkarr.h

----------
#### ElementArrayUsedIndexToToken()
    word    ElementArrayUsedIndexToToken(
            optr    arr,                /* optr to element array */
            word    index,              /* Find token of element with this index */
            dword   callbackData,       /* This is passed to the callback routine */
            Boolean _pascal (*callback) /* Return true to count this element */
                    (void *element, dword cbData));

This routine takes an index into an element array from some non-standard 
indexing scheme. The routine finds the element specified and returns the 
element's token. The indexing scheme can either number the elements from 
zero, counting only those elements in use (i.e. those with a reference count 
greater than zero); or it can use a more restrictive scheme. If a callback 
routine is passed, the callback routine will be called for every used element; 
it should should be declared _pascal return *true* if the element should be 
counted. If a null callback pointer is passed, every used element will be 
counted.

If no matching element is found, **ElementArrayUsedIndexToToken()** 
returns CA_NULL_ELEMENT.

**Include:** chunkarr.h

----------
#### ElementArrayUsedIndexToTokenHandles()
    word    ElementArrayUsedIndexToTokenHandles(
            MemHandle   mh,             /* Handle of LMem heap's block */
            ChunkHandle     ch,         /* Handle of element array */
            word        index,          /* Find token of element with this index */
            dword       callbackData,   /* Data passed to the callback routine */
            Boolean _pascal (*callback) /* Return true to count this element */
                    (void *element, dword cbData));

This routine is exactly like **ElementArrayUsedIndexToToken()** above, 
except that the element array is specified by its global and chunk handles 
(instead of with an optr).

**Include:** chunkarr.h

----------
#### EvalExpression()
    int EvalExpression(
            byte    * tokenBuffer,      /* Pointer to the parsed expression */
            byte    * scratchBuffer,    /* Pointer to the base of a scratch buffer
                                         * consisting of two stacks: an argument
                                         * stack and an operator/function stack */
            byte    * resultsBuffer,    /* Pointer to a buffer to contain the
                                         * result of the evaluation */
            word    bufSize,            /* Size of the scratch buffer */
            CEvalStruct * evalParams);  /* Pointer to CEvalStruct structure */

This routine evaluates a stream of parser tokens. It is used by the evaluator 
portion of the parse library and will be used only rarely by applications.

**Include:** parse.h

----------
#### FatalError()
    void    FatalError(
            word errorCode);

This routine causes a fatal error, leaving *errorCode* for the debugger.

----------
#### FileClose()
    word    FileClose( /* returns error */
            FileHandle  fh,             /* File to close */
            Boolean     noErrorFlag);   /* Set if app. can't handle
                                         * errors */

This routine closes an open byte file. If the routine succeeds, it returns zero. 
If the routine fails and *noErrorFlag* is *false* (i.e., zero), **FileClose()** returns a 
member of the **FileError** enumerated type. If the routine fails and 
*noErrorFlag* is *true* (i.e., non-zero), the routine will fatal-error.

**Warnings:** The *noErrorFlag* parameter should be *true* only during debugging.

**Include:** file.h

----------
#### FileCommit()
    word    FileCommit( /* returns error */
            FileHandle  fh,
            Boolean     noErrorFlag);   /* set if can't handle errors */

**FileCommit()** forces the file system to write any cached information about 
a file to the disk immediately. If it is successful, it returns zero. If it fails, it 
returns an error code. If the routine fails and *noErrorFlag* is *true* (i.e. 
non-zero), the routine will fatal-error.

**Warnings:** The *noErrorFlag* parameter should be *true* only during debugging.

**Include:** file.h

----------
#### FileConstructFullPath()
    DiskHandle  FileConstructFullPath(
            char        * * buffer,     /* Path string is written here */
            word        bufSize,        /* Length of buffer (in bytes) */
            DiskHandle  disk,           /* Disk or standard path; null for 
                                         * current path */
            const char  * tail,         /* Path relative to handle */
            Boolean     addDriveLetter);    /* Should path begin with drive
                                             * name? */

This routine translates a GEOS directory specification into a complete path 
string. It writes the string into the passed buffer. The directory is specified 
by two arguments: The first, *disk*, is the handle of a disk; this may also be a 
standard path constant. (If a null handle is passed, the current working 
directory is used.) The second, *tail*, is a pointer to the character string 
representing the tail end of the path. **FileConstructFullPath()** appends 
this relative path to the location indicated by the disk handle. It then 
constructs a full path string, beginning with that disk's root directory, and 
writes it to the buffer passed. If *addDriveName* is *true* (i.e. non-zero), the 
path string will begin with the drive's name and a colon.

**Examples:** The following call to **FileConstructFullPath()** might yield these results:

----------
**Code Display 6-1 Sample call to FileConstructFullPath()**

    /* Here we find out the full path of a subdirectory of the DOCUMENT directory */

        DiskHandle  documentDisk;
        char        pathBuffer[256];    /* long enough for most paths */

        documentDisk = FileConstructFullPath(&pathBuffer,   /* pointer to pointer */
                    256,            /* Length of buffer */
                    SP_DOCUMENT,    /* This can be a disk or 
                                     * standard path */
                    "MEMOS\\JANUARY", /* In C strings, the
                                       * backslash must be
                                       * doubled */
                    TRUE);          /* Prepend drive name */

    /* If the standard paths are set up in the default configuration, "documentDisk"
     * would be the handle of the main hard drive, and pathBuffer would contain a
     * string like "C:\GEOWORKS\DOCUMENT\MEMOS\JANUARY" */

----------

**See Also:** FileParseStandardPath()

**Include:** file.h

----------
#### FileCopy()
    word    FileCopy( /* returns error */
            const char  * source,       /* Source path and file name */
            const char  * dest,         /* Destination path and file name */
            DiskHandle  sourceDisk,     /* These handles may be Standard */
            DiskHandle  destDisk);      /* Path constants, or null to indi- 
                                         * cate current working directory */

This routine makes a copy of a file. The source and destination are specified 
with path strings. Each string specifies a path relative to the location 
specified by the corresponding disk handle. If the handle is a disk handle, the 
path is relative to that disk's root. If the disk handle is a standard path 
constant, the path string is relative to that standard path. If the disk handle 
is null, the path is relative to the current working directory.

If **FileCopy()** is successful, it returns zero. Otherwise, it returns one of the 
following error codes:

ERROR_FILE_NOT_FOUND  
No such source file exists in the specified directory.

ERROR_PATH_NOT_FOUND  
An invalid source or destination path string was passed.

ERROR_ACCESS_DENIED  
You do not have permission to delete the existing copy of the 
destination file, or the destination disk or directory is not 
writable.

ERROR_FILE_IN_USE  
Some geode has the existing destination file open.

ERROR_SHORT_READ_WRITE  
There was not enough room on the destination disk.

**See Also:** FileMove()

**Include:** file.h

----------
#### FileCreate()
    FileHandle  FileCreate( /* sets thread's error value */
            const char      * name,         /* relative to working directory */
            FileCreateFlags flags,          /* see below */
            FileAttrs       attributes);    /* FileAttrs of new file */

This routine creates a byte file. The file may be a DOS file or a GEOS byte file. 
If the file is successfully opened, **FileCreate()** will return the file's handle; 
otherwise, it will return a null handle and set the thread's error value.

The second parameter is a word-length **FileCreateFlags** record. The lower 
byte of this field is a **FileAccessFlags** record. This specifies the file's 
permissions and exclusions. Note that you must request write or read/write 
permission when you create a file. The upper byte specifies how the file 
should be created. It contains the following possible values:

FILE_CREATE_TRUNCATE  
If a file with the given name exists, it should be opened and 
truncated; that is, all data should be deleted.

FILE_CREATE_NO_TRUNCATE  
If the file exists, it should be opened without being truncated.

FILE_CREATE_ONLY  
If the file exists, the routine should fail and set the thread's 
error value to ERROR_FILE_EXISTS.

FCF_NATIVE  
This flag is combined with one of the above flags if the file 
should be created in the device's native format; e.g. if it should 
be a DOS file instead of a GEOS file. The name passed must be 
an acceptable native file name. If a GEOS file with the specified 
name already exists, **FileCreate()** will fail with error 
condition ERROR_FILE_FORMAT_MISMATCH. Similarly, if the 
flag isn't set and a non-GEOS file with this name exists, 
**FileCreate()** will fail and return this error.

The third parameter, *attributes*, describes the **FileAttrs** record to be set for 
the new file.

If successful, **FileCreate()** returns the file's handle. If it is unsuccessful, it 
returns a null handle and sets the thread's error value. The following error 
values are commonly returned:

ERROR_PATH_NOT_FOUND  
A relative or absolute path was passed, and the path included 
a directory which did not exist.

ERROR_TOO_MANY_OPEN_FILES  
There is a limit to how many files may be open at once. If this 
limit is reached, **FileCreate()** will fail until a file is closed.

ERROR_ACCESS_DENIED  
Either the caller requested access which could not be granted 
(e.g. it requested write access when another geode had already 
opened the file with FILE_DENY_W), or the caller tried to deny 
access when that access had already been granted to another 
geode (e.g. it tried to open the file with FILE_DENY_W when 
another geode already had it open for write-access).

ERROR_WRITE_PROTECTED  
The caller requested write or read-write access to a file in a 
write-protected volume.

ERROR_FILE_EXISTS  
Returned if **FileCreate()** was called with FILE_CREATE_ONLY 
and a file with the specified name already exists.

ERROR_FILE_FORMAT_MISMATCH  
Returned if **FileCreate()** was called with 
FILE_CREATE_TRUNCATE or FILE_CREATE_NO_TRUNCATE 
and a file exists in a different format than desired; i.e. you 
passed FCF_NATIVE and the file already exists in the GEOS 
format, or vice versa.

**Examples:** An example of usage is shown below.

----------
**Code Display 6-2 Example of FileCreate() usage**

    /* Here we create a DOS file in the current working directory. If the file already
     * exists, we open the existing file and truncate it.
     */

        FileHandle      newFile;

        newFile =       FileCreate("NEWFILE.TXT",
                        ( (FILE_CREATE_TRUNCATE | FCF_NATIVE)
                         | (FILE_ACCESS_RW | FILE_DENY_RW)),
                        0); /* set no attribute bits */

----------
**See Also:** FileCreateTempFile(), FileOpen()

**Include:** file.h

----------
#### FileCreateDir()
    word    FileCreateDir( /* Returns error & sets thread's error value */
            const char * name);     /* Relative path of new directory */

This routine creates a new directory. The parameter is a path string; the path 
is relative to the current directory. The last element of the path string must 
be the directory to create.

If **FileCreateDir()** is successful, it returns zero and clears the thread's error 
value. Otherwise, it returns an error code and sets the thread's error value. 
The following errors are returned:

ERROR_PATH_NOT_FOUND  
The path string was in some way invalid; for example, it might 
have instructed **FileCreateDir()** to create the directory within 
a directory which does not exist.

ERROR_ACCESS_DENIED  
The thread is not able to create directories in the specified 
location, or a directory with the specified name already exists.

ERROR_WRITE_PROTECTED  
The volume is write-protected.

**See Also:** FileDeleteDir()

**Include:** file.h

----------
#### FileCreateTempFile()
    FileHandle FileCreateTempFile( /* Sets thread's error value */
            char        * dir,      /* directory, relative to working dir.;
                                     * file name replaces 14 trailing null
                                     * characters upon return */
            FileAttrs   attributes);

This routine creates and opens a temporary file in the directory specified. The 
routine automatically selects a name for the temporary file. No creation flags 
are needed, since the file will definitely be created anew and will be used only 
by this geode. The directory string must end with fourteen null bytes (enough 
to be replaced by the new file's name).

If **FileCreateTempFile()** is successful, it returns the file's handle as well as 
the string passed in *dir*, with the trailing null characters replaced by the file 
name. If it is unsuccessful, it returns a null handle and sets the thread's error 
value to a member of the **FileError** enumerated type.

**Tips and Tricks:** Temporary files are usually created in a subdirectory of SP_PRIVATE_DATA.

**See Also:** FileCreate()

**Include:** file.h

----------
#### FileDelete()
    word    FileDelete( /* returns error */
            const char  * name);   /* path relative to working directory */

This routine deletes a file. If it is successful, it returns zero; otherwise, it 
returns a **FileError**. Common errors include:

ERROR_FILE_NOT_FOUND  
No such file exists in the specified directory.

ERROR_WRITE_PROTECTED  
The volume is write-protected.

ERROR_PATH_NOT_FOUND  
An invalid path string was passed.

ERROR_ACCESS_DENIED  
You do not have permission to delete that file.

ERROR_FILE_IN_USE  
Some geode has that file open.

**Include:** file.h

----------
#### FileDeleteDir()
    word    FileDeleteDir( /* Returns error & sets thread's error value */
            const char * name);   /* Relative path of directory to delete */

This argument deletes an existing directory. The parameter is a string which 
specifies the directory's position relative to the current working directory. 
The last element of the path string must be the name of the directory to 
delete.

If **FileDeleteDir()** is successful, it returns zero and clears the thread's error 
value. Otherwise, it returns an error code and sets the thread's error value. 
The following errors are returned:

ERROR_PATH_NOT_FOUND  
The directory specified could not be found or does not exist.

ERROR_IS_CURRENT_DIRECTORY  
This directory is some thread's current directory, or else it is on 
some thread's directory stack.

ERROR_ACCESS_DENIED  
The thread does not have permission to delete the directory.

ERROR_WRITE_PROTECTED  
The volume is write-protected.

ERROR_DIRECTORY_NOT_EMPTY  
The directory specified is not empty. A directory must be empty 
before it can be deleted.

**See Also:** FileCreateDir()

**Include:** file.h

----------
#### FileDuplicateHandle()
    FileHandle FileDuplicateHandle( /* Sets thread's error value */
            FileHandle fh);

This routine duplicates the handle of an open file and returns the duplicate 
handle. The duplicate handle has the same read/write position as the 
original. Both handles will have to be closed for the file to be closed. If there 
is an error, **FileDuplicateHandle()** returns a null handle and sets the 
thread's error value.

**Include:** file.h

----------
#### FileEnum()
    word    FileEnum( /* returns number of files returned */
            FileEnumParams  * params,       /* described below */
            MemHandle       * bufCreated,   /* FileEnum will allocate a return-
                                             * buffer block & write its handle
                                             * here */
            word            * numNoFit);    /* Number of files not handled is
                                             * written here */

This routine is used to examine all the files in a directory. The routine can 
filter the files by whether they have certain extended attributes. It creates a 
buffer and writes information about the files in this buffer. This routine can 
be called in many different ways; for full details, see the section "FileEnum()" 
in the Concepts book.

**Structures:** **FileEnum()** uses several structures and enumerated types. They are shown 
below; the detailed description of the structures follows.

        /* Types, values, and structures passed
         * to the FileEnum() routine: */

    typedef enum /* word */ {
        FESRT_COUNT_ONLY,
        FESRT_DOS_INFO,
        FESRT_NAME,
        FESRT_NAME_AND_ATTR
    } FileEnumStandardReturnType;

    typedef enum /* word */ {
        FESC_WILDCARD
    } FileEnumStandardCallback;

        /* Types, values, and structures returned
         * by the FileEnum() routine: */

    typedef struct {
        FileAttrs           DFIS_attributes;
        FileDateAndTime     DFIS_modTimeDate;
        dword               DFIS_fileSize;
        FileLongName        DFIS_name;
        DirPathInfo         DFIS_pathInfo;
    } FEDosInfo;

    typedef struct _FileEnumCallbackData {
        FileExtAttrDesc     FECD_attrs[1];
    } FileEnumCallbackData;

    typedef struct _FileEnumParams {
        FileEnumSearchFlags         FEP_searchFlags;
        FileExtAttrDesc *           FEP_returnAttrs;
        word                        FEP_returnSize;
        FileExtAttrDesc *           FEP_matchAttrs;
        word                        FEP_bufSize;
        word                        FEP_skipCount;
        word _pascal (*FEP_callback) (struct _FileEnumParams *params,
                                 FileEnumCallbackData *fecd, 
                                 word frame);
        FileExtAttrDesc *           FEP_callbackAttrs;
        dword                       FEP_cbData1;
        dword                       FEP_cbData2;
        word                        FEP_headerSize;
    } FileEnumParams;

*Most of the information passed to* **FileEnum()** is contained in a 
**FileEnumParameters** structure. The fields of the structure are as follows:

*FEP_searchFlags*  
This is a byte-length flag field. The flags are of type 
**FileEnumSearchFlags** (described below). These flags specify 
which files at the current location will be examined by 
**FileEnum()**. They also specify such things as whether a 
callback routine should be used.

*FEP_returnAttrs*  
This is a pointer to an array of **FileExtAttrDesc** structures. 
The last structure should have its *FEA_attr* field set to 
FEA_END_OF_LIST. The array specifies what information will 
be returned by **FileEnum()**. The **FileExtAttrDesc** structure 
is used in a slightly different way than usual. Every file will 
have an entry in the return buffer; this entry will contain all 
the extended attribute information requested. Each 
**FileExtAttrDesc** structure will specify where in that entry its 
information should be written. The *FEAD_value* field should 
contain only an offset value; the extended attribute will be 
written at that offset into the entry. (You can specify an offset 
by casting an integer value to type **void** *.) The *FEAD_size* 
value specifies how long the return value can be. You can also 
request certain return values by setting *FEP_returnAttrs* to 
equal a member of the **FileEnumStandardReturnType** 
(again, by casting the **FileEnumStandardReturnType** 
value to type **void** *). The **FileEnumStandardReturnType** 
enumerated type is described later in this section.

*FEP_returnSize*  
This is the size of each entry in the returned buffer. If a 
standard return type or an array of **FileExtAttrDesc** 
structures was passed, each entry in the returned buffer will 
contain all the extended attribute information requested for 
that file.

*FEP_matchAttrs*  
This is a pointer to an array of **FileExtAttrDesc** structures. 
The last structure should have its *FEA_attr* field set to 
FEA_END_OF_LIST. **FileEnum()** will automatically filter out 
and ignore all files whose attributes do not match the ones 
specified by this array. For attributes that are word-sized 
records, *FEAD_value*.offset holds the bits that must be set, and 
*FEAD_value*.segment holds the bits that must be clear. For 
byte-sized flags, *FEAD_value*.offset.low contains the flags that 
must be set, and *FEAD_value*.offset.high contains flags that 
must be clear. Byte- and word-sized non-flag values are stored 
in *FEAD_value*.offset. For all other values, *FEAD_value* holds a 
pointer to the exact value to match, and *FEAD_size* specifies the 
length of that value (in bytes). If you do not want to filter out 
any files in the working directory, or if you will use the callback 
routine to filter the files, pass a null pointer in this field.

*FEP_bufsize*  
This specifies the maximum number of entries to be returned 
in the buffer. If you do not want to set a limit, pass the constant 
FEP_BUFSIZE_UNLIMITED. The buffer will be grown as 
necessary.

*FEP_skipCount*  
This contains the number of matching files to be ignored before 
the first one is processed. It is often used in conjunction with 
*FEP_bufSize* to examine many files a few at a time. For 
example, if you only wanted to examine ten files at a time, you 
would set *FEP_bufSize* to ten and *FEP_skipCount* to zero. 
**FileEnum()** would return the data for the first ten files which 
match the search criteria. After processing the returned data, 
if there were any files left over, you could call **FileEnum()** 
again, this time with *FEP_skipCount* set to ten; **FileEnum()** 
would handle the next ten matching files and return the data 
about them. In this way you could walk through all the 
matching files in the directory. Note that if the 
FileEnumSearchFlags bit FESF_REAL_SKIP is set (in 
*FEP_searchFlags*), the first files in the directory will be skipped 
*before* they are tested to see if they match. This is faster, since 
the match condition won't have to be checked for the first files 
in the directory.

*FEP_callback*  
This holds a pointer to a Boolean callback routine. The callback 
routine can check to see if the file matches some other arbitrary 
criteria. The callback routine is called for any files which match 
all the above criteria. It should be declared _pascal. It is passed 
three arguments: a pointer to the **FileEnumParams** 
structure, a pointer to the current stack frame (which is used 
by some assembly callback routines), and a pointer to an array 
of **FileExtAttrDesc** structures. These structures are all the 
attributes required either for return, matching, or callback (see 
*FEP_callbackAttrs* below), with the information for the current 
file filled in; you can search through them directly for the 
information you want, or you can call **FileEnumLocateAttr()** 
to search through this array. If the file should be accepted by 
**FileEnum()**, the callback should return *true*; otherwise it 
should return *false*. You can also instruct **FileEnum()** to use 
one of the standard callback routines by passing a member of 
the **FileEnumStandardCallback** enumerated type. In this 
case, *FEP_callbackAttrs* is ignored; **FileEnum()** will 
automatically pass the appropriate information to the callback 
routine. (Note that if the FESF_CALLBACK bit of the 
*FEP_searchFlags* field is not set, the *FEP_callback* field is 
ignored.)

*FEP_callbackAttrs*  
This is a pointer to an array of **FileExtAttrDesc** structures. 
The last structure should have its FEA_attr field set to 
FEA_END_OF_LIST. The array will be filled in with the 
appropriate information for each file before the callback 
routine is called. Note that if the FESF_CALLBACK bit of the 
*FEP_searchFlags* is not set, the *FEP_callbackAttrs* is ignored. If 
you do not need any attributes passed to the callback routine, 
set this field to be a null pointer.

FEP_cbData1, FEP_cbData2
These are dword-length fields. Their contents are ignored by 
**FileEnum()**; they are used to pass information to the callback 
routine. If you do not call a standard callback routine, you may 
use these fields any way you wish.

*FEP_headerSize*  
If the flag FESF_LEAVE_HEADER is set, **FileEnum()** will leave 
an empty header space at the beginning of the return buffer. 
The size of the header is specified by this field. If 
FESF_LEAVE_HEADER is clear, this field is ignored.

The first field of the **FileEnumParams** structure, *FEP_searchFlags*, is a 
word-length record containing **FileEnumSearchFlags**. The following flags 
are available:

FESF_DIRS - Directories should be examined by **FileEnum()**.

FESF_NON_GEOS - Non-GEOS files should be examined by **FileEnum()**.

FESF_GEOS_EXECS - GEOS executable files should be examined by **FileEnum()**.

FESF_GEOS_NON_EXECS - GEOS non-executable files (e.g., VM files) should be examined 
by **FileEnum()**.

FESF_REAL_SKIP - If a skip count of *n* is specified, the first *n* files will be skipped 
regardless of whether they matched the attributes passed. In 
this case, **FileEnum()** will return the number of files passed 
through in order to get enough files to fill the buffer; the return 
value can thus be the real-skip count for the next pass.

FESF_CALLBACK - **FileEnum()** should call a callback routine to determine 
whether a file should be accepted.

FESF_LOCK_CB_DATA - This flag indicates that the **FileEnumParams** fields 
*FEP_callback1* and *FEP_callback2* are far pointers to movable 
memory that must be locked before **FileEnum()** is called.

FESF_LEAVE_HEADER - If set, **FileEnum()** should leave an empty header space at the 
start of the return buffer. The size of this buffer is specified by 
the *FEP_headerSize* field.

The **FileEnumStandardReturnType** enumerated type has the following 
values; they are used in conjunction with the *FEP_returnAttrs* field of the 
**FileEnumParams** structure.

FESRT_COUNT_ONLY - **FileEnum()** will not allocate any memory and will not return 
data about files; instead, it will simply return the number of 
files which match the specified criteria.

FESRT_DOS_INFO - **FileEnum()** will return an array of **FEDosInfo** structures. 
These structures contain basic information about the file: its 
virtual name, size, modification date, DOS attributes, and path 
information (as a **DirPathInfo** record).

FESRT_NAME - **FileEnum()** will return an array of **FileLongName** strings, 
each one of which is FILE_LONGNAME_BUFFER_SIZE 
characters long; every one of these will contain a file's virtual 
name followed by a null terminator.

FESRT_NAME_AND_ATTR - **FileEnum()** will return an array of **FENameAndAttr** 
structures, each one of which contains a file's DOS attributes 
and virtual name.

The **FEDosInfo** structure includes a word-sized record (*DFIS_pathInfo*) 
which describes the file's position relative to the standard paths. It contains 
the following fields:

DPI_EXISTS_LOCALLY - This bit is set if the file exists in a directory under the primary 
tree.

DPI_ENTRY_NUMBER_IN_PATH - This is the mask for a seven-bit field whose offset is 
DPI_ENTRY_NUMBER_IN_PATH_OFFSET.

DPI_STD_PATH - This is the mask for an eight-bit field whose offset is 
DPI_STD_PATH_OFFSET. If the file is in a standard path, this 
field will contain a **StandardPath** constant for a standard 
path containing the file. This need not be the "closest" standard 
path; for example, if the file is in the "World" directory, this 
constant might nevertheless be SP_TOP.

**See Also:** FileEnumLocateAttr(), FileEnumWildcard()

**Include:** fileEnum.h

----------
#### FileEnumLocateAttr()
    void *  FileEnumLocateAttr( /* returns NULL if attr not found */
            FileEnumCallbackData*   fecd,   /* Passed to callback routine */
            FileExtendedAttribute   attr,   /* Search for this attribute */
            const char *            * name);    /* Attribute name (if second
                                                 * argument is FEA_CUSTOM) */

**FileEnum()** can be instructed to call a callback routine to decide which files 
to filter out. This callback routine is passed an array of **FileExtAttrDesc** 
structures. To find a particular extended attribute in this array, call 
**FileEnumLocateAttr()**. This routine will find the address of the value of 
the attribute desired, and return that address. If the attribute is not in the 
array, **FileEnumLocateAttr()** will return a null pointer.

**Include:** fileEnum.h

----------
#### FileEnumWildcard()
    Boolean FileEnumWildcard(
            FileEnumCallbackData    * fecd,     /* Passed to callback routine */
            word                    frame);     /* Inherited stack frame */

This routine is a utility used by **FileEnum()** and is rarely used by 
applications. It checks to see if the virtual name of the current file (the file 
currently being evaluated by **FileEnum()**) matches the pattern in the 
*FEP_cbData1* field of the **FileEnumParams** structure.

The *fecd* parameter is a pointer to the callback data of the **FileEnum()** 
routine. The frame parameter is a pointer to the **FileEnum()** stack frame: 
The first dword is the *FEP_cbData1* field, and the second is the *FEP_cbData2* 
field.

This routine returns *true* (non-zero) if the file name and pattern match. 
Otherwise, it returns *false*.

**Include:** fileEnum.h

----------
#### FileFromTransferBlockID()
    VMFileHandle     FileFromTransferBlockID(id);
            TransferBlockID id;

This macro extracts a VMFileHandle from a value of type **TransferBlockID**.

----------
#### FileGetAttributes()
    FileAttrs   FileGetAttributes( /* Sets thread's error value */
            const char * path);     /* file's path relative to current
                                     * working directory */

This routine returns the standard **FileAttrs** attributes for a file. The file may 
be a GEOS file or a plain DOS file. Note that you can also get a file's attributes 
by getting the file's FEA_FILE_ATTR extended attribute. If an error occurs, 
this routine sets the thread's error.

**See Also:** FileAttrs, FileSetAttributes()

**Include:** file.h

----------
#### FileGetCurrentPath()
    DiskHandle FileGetCurrentPath(
            char *  buffer,         /* Path string is written here */
            word    bufferSize);    /* Size of buffer in bytes */

This routine writes the current path string (without drive specifier) to the 
buffer provided. If the buffer is too small, it truncates the path to fit. It 
returns the handle of the disk containing the current path. If the current 
path was declared relative to a standard path, the standard path constant 
will be returned.

**Include:** file.h

----------
#### FileGetDateAndTime()
    FileDateAndTime     FileGetDateAndTime( /* sets thread's error value */
            FileHandle fh);

This routine finds out the time a file was last modified. This routine can be 
called on GEOS or non-GEOS files. Note that you can also find out the 
modification time of a file by checking the extended attribute 
FEA_MODIFICATION. If unsuccessful, it sets the thread's error value.

**See Also:** FileDateAndTime, FileSetDateAndTime()

**Include:** file.h

----------
#### FileGetDiskHandle()
    DiskHandle FileGetDiskHandle( /* sets thread's error value */
            FileHandle fh);

This routine returns the handle of the disk containing an open file. If 
unsuccessful, it sets the thread's error value.

**Include:** file.h

----------
#### FileGetHandleExtAttributes()
    word    FileGetHandleExtAttributes(
            FileHandle              fh,         /* open file's handle */
            FileExtendedAttribute   attr,       /* attribute to get */
            void                    * buffer,   /* attribute is written here */
            word                    bufSize);   /* length of buffer in bytes */

This routine gets one or more extended attributes of an open file. (To get the 
attributes of a file without opening it, call **FileGetPathExtAttributes()**.) If 
a single attribute is requested, the attribute will be written in the buffer 
passed. If several attributes are requested, *attr* should be set to 
FEA_MULTIPLE, and *buffer* should point to an array of **FileExtAttrDesc** 
structures. In this case, *bufSize* should be the number of structures in the 
buffer, not the length of the buffer. 

If **FileGetHandleExtAttributes()** is successful, it returns zero. Otherwise, 
it returns one of the following error codes:

ERROR_ATTR_NOT_SUPPORTED  
The file system does not recognize the attribute constant 
passed.

ERROR_ATTR_SIZE_MISMATCH  
The buffer passed was too small for the attribute requested.

ERROR_ATTR_NOT_FOUND  
The file does not have a value set for that attribute.

ERROR_ACCESS_DENIED  
You do not have read-access to the file.

**Tips and Tricks:** Note that the only way to recover a custom attribute is by passing 
FEA_MULTIPLE, and using a **FileExtAttrDesc** to describe the attribute.

**See Also:** FileGetPathExtAttributes()

**Include:** file.h

----------
#### FileGetPathExtAttributes()
    word    FileGetPathExtAttributes(
            const char              * path,     /* path relative to current
                                                 * working directory */
            FileExtendedAttribute   attr,       /* attribute to get */
            void                    * buffer,   /* attribute is written here */
            word                    bufSize);   /* length of buffer in bytes */

This routine gets one or more extended attributes of a GEOS file. If a single 
attribute is requested, the attribute will be written in the buffer passed. If 
several attributes are requested, *attr* should be set to FEA_MULTIPLE, and 
*buffer* should point to an array of **FileExtArtrDesc** structures. In this case, 
*bufSize* should be the number of structures in the buffer, not the length of the 
buffer.

If **FileGetPathExtAttributes()** is successful, it returns zero. Otherwise, it 
returns one of the following error codes:

ERROR_ATTR_NOT_SUPPORTED  
The file system does not recognize the attribute constant 
passed.

ERROR_ATTR_SIZE_MISMATCH  
The buffer passed was too small for the attribute requested.

ERROR_ATTR_NOT_FOUND  
The file does not have a value set for that attribute.

ERROR_ACCESS_DENIED  
You do not have read-access to the file.

**Tips and Tricks:** Note that the only way to recover a custom attribute is by passing 
FEA_MULTIPLE, and using a **FileExtAttrDesc** to describe the attribute.

**See Also:** FileGetHandleExtAttributes()

**Include:** file.h

----------
#### FileLockRecord()
    word    FileLockRecord(     /* returns error */
            FileHandle      fh,
            dword           filePos,    /* lock starting at this position... */
            dword           regLength); /* lock this many bytes */

This routine puts a lock on a part of a byte file. It first checks to make sure 
that there are no locks that overlap the region specified; if there are, it will 
fail and return ERROR_ALREADY_LOCKED. If there are no locks, it will place 
a lock on the region specified and return zero.

**Warnings:** Locking a region only prevents threads from locking part of the same region; 
it does not prevent them from reading from or writing to the region. If 
applications use this mechanism, they have to make sure to call 
**FileLockRecord** before trying to access a part of a file.

**See Also:** FileUnlockRecord(), HandleP()

----------
#### FileMove()
    word    FileMove( /* Returns error */
            const char      * source,   /* source path and file name */
            const char      * dest,     /* destination path and file name */
            DiskHandle      sourceDisk, /* These handles may be Standard */
            DiskHandle      destDisk);  /* Path constants, or null to indi- 
                                         * cate current working directory */

This routine moves a file from one location to another. The source and 
destination are specified with path strings. Each string specifies a path 
relative to the location specified by the corresponding disk handle. If the 
handle is a disk handle, the path is relative to that disk's root. If the disk 
handle is a standard path constant, the path string is relative to that 
standard path. If the disk handle is null, the path is relative to the current 
working directory.

If **FileMove()** is successful, it returns zero. Otherwise, it returns one of the 
following error codes and sets the thread's error value.

ERROR_FILE_NOT_FOUND  
No such source file exists in the specified directory.

ERROR_PATH_NOT_FOUND  
An invalid source or destination path string was passed.

ERROR_ACCESS_DENIED  
You do not have permission to delete the source file, or there is 
already a file with the same name as the destination file (and 
you do not have permission to delete it), or the destination disk 
or directory is not writable.

ERROR_FILE_IN_USE  
Either the source file is in use, or there is already a file with the 
same name as the destination file, and it is in use.

ERROR_SHORT_READ_WRITE  
There was not enough room on the destination disk.

**See Also:** FileCopy()

**Include:** file.h

----------
#### FileOpen()
    FileHandle FileOpen( /* sets thread's error value */
            const char          * name,     /* relative to working dir */
            FileAccessFlags     flags);     /* Permissions/exclusions */

This routine opens a file for bytewise access. The file may be a DOS file or a 
GEOS byte file. If the file is successfully opened, **FileOpen()** will return the 
file's handle; otherwise, it will return a null handle and set the thread's error 
value. Errors typically set by this routine are listed below:

ERROR_FILE_NOT_FOUND  
No file with the specified name could be found in the 
appropriate directory.

ERROR_PATH_NOT_FOUND  
A relative or absolute path had been passed, and the path 
included a directory which did not exist.

ERROR_TOO_MANY_OPEN_FILES  
There is a limit to how many files may be open at once. If this 
limit is reached, **FileOpen()** will fail until a file is closed.

ERROR_ACCESS_DENIED  
Either the caller requested access which could not be granted 
(e.g. it requested write access when another geode had already 
opened the file with FILE_DENY_W), or the caller tried to deny 
access when that access had already been granted to another 
geode (e.g. it tried to open the file with FILE_DENY_W when 
another geode already had it open for write-access).

ERROR_WRITE_PROTECTED  
The caller requested write or read-write access to a file in a 
write-protected volume.

**See Also:** FileCreate()

**Include:** file.h

----------
#### FileParseStandardPath()
    StandardPath FileParseStandardPath(
            DiskHandle      disk,
            const char      ** path);

This routine is passed a full path (relative to the passed disk or a standard 
path, if the disk handle is null) and finds the standard path which most 
closely contains that path. It updates the pointer whose address is passed so 
that it points to the trailing portion of the path string. For example, if you 
pass the path string "\GEOWORKS\DOCUMENT\MEMOS\APRIL", the 
pointer would be updated to point to the "\MEMOS\APRIL" portion, and the 
**StandardPath** SP_DOCUMENT would be returned. If the path passed does 
not belong to a standard path, the constant SP_NOT_STANDARD_PATH will 
be returned, and the pointer will not be changed.

**Include:** file.h

----------
#### FilePopDir()
    void    FilePopDir();

**FilePopDir()** pops the top directory off the thread's directory stack and 
makes it the current working directory.

**See Also:** FilePushDir()

**Include:** file.h

----------
#### FilePos()
    dword   FilePos( /* Sets thread's error value */
            FileHandle      fh,
            dword           posOrOffset,
            FilePosMode     mode);

This routine changes the current file position. The position can be specified 
in three ways, depending on the value of the *mode* argument:

FILE_POS_START  
The file position is set to a specified number of bytes after the 
start of the file. Passing this mode with an offset of zero will set 
the file position to the start of the file.

FILE_POS_RELATIVE  
The file position is incremented by a specified number of bytes; 
this number may be negative.

FILE_POS_END  
The file position is set to a specified number of bytes after the 
end of the file; it is usually passed with a negative number of 
bytes. Passing this mode with an offset of zero will set the file 
position to the end of the file.

**FilePos()** returns a 32-bit integer. This integer specifies the absolute file 
position after the move (relative to the start of the file).

**Tips and Tricks:** To find out the current file position without changing it, call **FilePos()** with 
mode FILE_POS_RELATIVE and offset zero.

**Include:** file.h

----------
#### FilePushDir()
    void    FilePushDir();

**FilePushDir()** pushes the current working directory onto the thread's 
directory stack. It does not change the current working directory.

**See Also:** FilePopDir()

**Include:** file.h

----------
#### FileRead()
    word    FileRead( /* sets thread's error value */
            FileHandle      fh,             /* handle of open file */
            void            * buf,          /* copy data to this buffer */
            word            count,          /* Length of buffer (in bytes) */
            Boolean         noErrorFlag);   /* Set if app can't
                                             * handle errors */

This routine copies data from a file into memory. It starts copying from the 
current position in the file. If possible, it will copy enough data to fill the 
buffer. If **FileRead()** reaches the end of the file, it sets the thread's error 
value to ERROR_SHORT_READ_WRITE. In any event, it returns the number 
of bytes copied. If an error occurs, **FileRead()** returns -1 and sets the 
thread's error value (usually to ERROR_ACCESS_DENIED). The current file 
position will be changed to the first byte after the ones which were read.

If the argument *noErrorFlag* is set to *true* (i.e. non-zero), **FileRead()** will 
fatal-error if an error occurs (including an ERROR_SHORT_READ_WRITE).

**Warnings:** Pass *noErrorFlag* *true* only during debugging.

**Include:** file.h

----------
#### FileRename()
    word    FileRename(
            const char * oldName,       /* Relative to working directory */
            const char * newName);      /* Name only, without path */

This routine changes a file's name. It cannot move a file to a different 
directory; to do that, call **FileMove()**. If the routine is successful, it returns 
zero; otherwise, it returns a **FileError**. Common errors include

ERROR_FILE_NOT_FOUND  
No such file exists in the specified directory.

ERROR_PATH_NOT_FOUND  
An invalid path string was passed.

ERROR_ACCESS_DENIED  
You do not have permission to delete that file, or it exists on a 
read-only volume.

ERROR_FILE_IN_US  
Some geode has that file open.

ERROR_INVALID_NAME  
The name was not a valid GEOS name; or the file is a non-GEOS 
file, and the name was not an appropriate native name.

**See Also:** FileMove()

**Include:** file.h

----------
#### FileResolveStandardPath()
    DiskHandle FileResolveStandardPath(
            char        ** buffer,              /* Write path here; update pointer
                         * to point to end of path */
            word        bufSize,                /* Size of buffer (in bytes) */
            const char *        path,               /* Relative path of file */
            FileResolveStandardPathFlags flags);                            /* Flags are described below */

This routine finds a file relative to the current location, then writes the full 
path to the file, starting at the root of the disk (*not* at a standard path). It 
writes the path to the passed buffer, updating the pointer to point to the null 
at the end of the path string; it also returns the handle of the disk. If it cannot 
find the file it returns a null path.

**Structures:** A record of **FileResolveStandardPathFlags** is passed to 
**FileResolveStandardPath()**. The following flags are available:

FRSPF_ADD_DRIVE_NAME  
The path string written to the buffer should begin with the 
drive name (e.g., "C:\GEOWORKS\DOCUMENT\MEMOS").

FRSPF_RETURN_FIRST_DIR  
**FileResolveStandardPath()** should not check whether the 
passed path actually exists; instead, it should assume that the 
path exists in the first directory comprising the standard path, 
and return accordingly.

**Include:** file.h

----------
#### FileSetAttributes()
    word    FileSetAttributes( /* returns error value */
            const char  * path,     /* file's path relative to current
                                     * working directory */
            FileAttrs   attr);      /* new attributes for the file */

This routine changes the standard DOS attributes of a DOS or GEOS file. Note 
that you can also change the attributes of a file by setting the extended 
attribute FEA_FILE_ATTR.

**See Also:** FileAttrs, FileGetAttrs()

**Include:** file.h

----------
#### FileSetCurrentPath()
    DiskHandle FileSetCurrentPath(
            DiskHandle      disk,       /* May be a standard path constant */
            const char      * path);    /* path string, null-terminated */

This routine changes the current path. It is passed two parameters: The first 
is the handle of the disk containing the new current path (this may be a 
standard path constant). The second is a null-terminated path string. It is 
specified with normal DOS conventions: directories are separated by 
backslashes; a period (".") indicates the current directory; and a pair of 
periods ("..") indicates the parent of the current directory. The string may not 
contain wildcard characters.

If *disk* is a disk handle, the path is relative to the root directory of that disk; 
if *disk* is a standard path constant, the path is relative to the standard path; 
if it is null, the path is relative to the current working directory. 
**FileSetCurrentPath()** returns the disk handle associated with the new 
current path; this may be a standard path constant. If 
**FileSetCurrentPath()** fails, it returns a null handle.

**Include:** file.h

----------
#### FileSetDateAndTime()
    word    FileSetDateAndTime( /* returns error */
            FileHandle          fh,             /* handle of open file */
            FileDateAndTime     dateAndTime);   /* new modification time */

This routine changes a file's last-modification time-stamp. This routine can 
be called on GEOS or non-GEOS files. Note that you can also change the 
modification time of a file by changing the extended attribute 
FEA_MODIFICATION. If unsuccessful, this routine returns an error and sets 
the thread's error value.

**See Also:** FileDateAndTime, FileGetDateAndTime()

**Include:** file.h

----------
#### FileSetHandleExtAttributes()
    word    FileGetPathExtAttributes( /* returns error */
            FileHandle              fh,         /* handle of open file */
            FileExtendedAttribute   attr,       /* attribute to get */
            const void              * buffer,   /* attribute is read from here */
            word                    bufSize);   /* length of buffer in bytes */

This routine sets one or more extended attributes of an open GEOS file. (To 
set the attributes of a file without opening it, call 
**FileSetPathExtAttributes()**.) If a single attribute is specified, the 
attribute's new value will be read from the buffer passed. If several attributes 
are to be changed, *attr* should be set to FEA_MULTIPLE, and *buffer* should 
point to an array of **FileExtAttrDesc** structures. In this case, *bufSize* should 
be the number of structures in the buffer, not the length of the buffer. 

If **FileSetHandleExtAttributes()** is successful, it returns zero. Otherwise, 
it sets the thread's error value and returns one of the following error codes:

ERROR_ATTR_NOT_SUPPORTED  
The file system does not recognize the attribute constant 
passed.

ERROR_ATTR_SIZE_MISMATCH  
The buffer passed was the wrong size for the attribute 
specified.

ERROR_ACCESS_DENIED  
The caller does not have write-access to the file.

ERROR_CANNOT_BE_SET  
The extended attribute cannot be changed. Such attributes as 
FEA_SIZE and FEA_NAME cannot be changed with the 
**FileSet...()** routines.

**Tips and Tricks:** Note that the only way to create or change a custom attribute is by passing 
FEA_MULTIPLE, and using a **FileExtAttrDesc** to describe the attribute.

**See Also:** FileSetPathExtAttributes()

**Include:** file.h

----------
#### FileSetPathExtAttributes()
    word    FileSetPathExtAttributes(
            const char              * path,     /* path relative to current
                                                 * working directory */
            FileExtendedAttribute    attr,      /* attribute to get */
            const void              * buffer,   /* attribute is read from here */
            word                    bufSize);   /* length of buffer in bytes */

This routine sets one or more extended attributes of a file. If a single 
attribute is specified, the attribute will be written in the buffer passed. If 
several attributes are to be changed, *attr* should be set to FEA_MULTIPLE 
and *buffer* should point to an array of **FileExtAttrDesc** structures. In this 
case, *bufSize* should be the number of structures in the buffer, not the length 
of the buffer.

If **FileSetPathExtAttributes()** is successful, it returns zero. Otherwise, it 
sets the thread's error value and returns one of the following error codes:

ERROR_ATTR_NOT_SUPPORTED  
The file system does not recognize the attribute constant 
passed.

ERROR_ATTR_SIZE_MISMATCH  
The buffer passed was the wrong size for the attribute 
specified.

ERROR_ACCESS_DENIED  
**FileSetPathExtAttributes()** returns this if any geode 
(including the caller) has the file open with "deny-write" 
exclusive access, or if the file is not writable.

ERROR_CANNOT_BE_SET  
The extended attribute cannot be changed. Such attributes as 
FEA_SIZE and FEA_NAME cannot be changed with the 
**FileSet...ExtAttributes()** routines.

**Tips and Tricks:** Note that the only way to create or change a custom attribute is by passing 
FEA_MULTIPLE, and using a **FileExtAttrDesc** to describe the attribute.

**See Also:** FileSetHandleExtAttributes()

**Include:** file.h

----------
#### FileSetStandardPath()
    void    FileSetStandardPath(
            StandardPath path);         /* StandardPath to set */

This routine changes the current working directory to one of the system's 
StandardPath directories. Pass a standard path.

**Include:** file.h

----------
#### FileSize()
    dword   FileSize(
            FileHandle fh);     /* handle of open file */

This routine returns the size of the open file specified.

**Include:** file.h

----------
#### FileTruncate()
    word    FileTruncate(
            FileHandle      fh,         /* handle of open file */
            dword           offset);    /* offset at which to truncate */

This routine truncates the specified file at the passed offset. The *offset* 
parameter can also be thought of as the desired file size.

**Include:** file.h

----------
#### FileUnlockRecord()
    word    FileUnlockRecord( /* returns error */
            FileHandle      fh,             /* handle of open file
            dword       filePos,                /* Release lock that starts here */
            dword       regLength);             /* and is this long */

This routine releases a lock on a part of a byte-file. The lock must have been 
previously placed with **FileLockRecord()**.

**See Also:** FileLockRecord(), HandleV()

**Include:** file.h

----------
#### FileWrite()
    word    FileWrite( /* sets thread's error value */
            FileHandle      fh,             /* handle of open file */
            const void      * buf,          /* Copy from here into file */
            word            count,          /* # of bytes to copy */
            Boolean         noErrorFlag);   /* Set if can't handle errors */

This routine copies a specified number of bytes from a buffer to the file. The 
bytes are written starting with the current position in the file; any data 
already at that location will be overwritten. **FileWrite()** returns the number 
of bytes written. If **FileWrite()** could not write all the data (e.g. if the disk 
ran out of space), it will set the thread's error value to 
ERROR_SHORT_READ_WRITE and return the number of bytes that were 
written. If it could not write the data to the file at all (e.g. if you do not have 
write-access to the file), it will return -1 and set the thread's error value to 
ERROR_ACCESS_DENIED. In any event, the file position will be changed to 
the first byte after the ones written.

If the argument *noErrorFlag* is set to *true* (i.e. non-zero), **FileWrite()** will 
fatal-error if an error occurs.

**Warnings:** Pass *noErrorFlag* *true* only during debugging.

**Include:** file.h

----------
#### FormatIDFromManufacturerAndType
    dword   FormatIDFromManufacturerAndType(mfr, type);
            ManufacturerIDs             mfr;
            ClipboardItemFormat             type;

This macro takes a manufacturer ID and a format type (e.g. CIF_TEXT) and 
combines them into a dword argument of the type 
**ClipboardItemFormatID**.

----------
#### free()
    void    free(
            void * blockPtr);       /* address of memory to free */

The **malloc()** family of routines is provided for Standard C compatibility. The 
kernel will allocate a fixed block to satisfy the geode's **malloc()** requests; it 
will allocate memory from this block. When the block is filled, it will allocate 
another fixed malloc-block. When all the memory in the block is freed, the 
memory manager will automatically free the block.

When a geode is finished with some memory it requested from **malloc()**, it 
should free the memory. That makes it easier for **malloc()** to satisfy memory 
request. It can free the memory by passing the address which was returned 
by **malloc()** (or **calloc()** or **realloc()**) when the memory was allocated. All of 
the memory will be freed.

The memory must be in a malloc-block assigned to the geode calling **free()**. 
If you want to free memory in another geode's malloc-block, call **GeoFree()**.

**Include:** stdlib.h

**Warnings:** Pass exactly the same address as the one returned to you when you allocated 
the memory. If you pass a different address, **free()** will take unpredictable 
actions, including possibly erasing other memory or crashing the system.

**See Also:** calloc(), malloc(), GeoFree(), realloc()

----------
#### FractionOf()
    word    FractionOf(
            WWFixedAsDWord      wwf);

This macro returns the fractional portion of a **WWFixedAsDWord** value.

**Include:** geos.h

[Routines A-D](rrouta_d.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Routines G-G](rroutg_g.md)