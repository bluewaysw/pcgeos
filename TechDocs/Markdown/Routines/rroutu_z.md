## 3.7 Routines U-Z
----------
#### UserAddAutoExec()
    void    UserAddAutoExec(
            const char *        appName);

This routine adds an application to the list of those, like Welcome, that are 
automatically started by the UI when it loads. It is passed one argument:

*appName* - This is a pointer to a null-terminated string containing the 
name of the application. The application must be in 
SP_APPLICATION or SP_SYS_APPLICATION.

**Include:** ui.goh

----------
#### UserCreateDialog()
    optr    UserCreateDialog(
            optr    dialogBox);

This routine duplicates a template dialog box, attaches the dialog box to an 
application object, and sets it fully GS_USABLE so that it may be called with 
**UserDoDialog()**. Dialog boxes created in such a manner should be removed 
and destroyed with **UserDestroyDialog()** when no longer needed.

*dialogBox* - Optr to template dialog box (within a template object block). 
The block must be sharable, read-only and the top 
GenInteraction called with this routine must not be linked into 
any generic tree. The optr returned is a created, fully-usable 
dialog box.

**See Also:** UserDestroyDialog()

----------
#### UserCreateInkDestinationInfo()
    MemHandle   UserCreateInkDestinationInfo(
            optr                dest,
            GStateHandle        gs,
            word                brushSize,
            GestureCallback     *callback);

This routine creates an **InkDestinationInfo** structure to be returned with 
MSG_META_QUERY_IF_PRESS_IS_INK. The callback routine must be 
declared _pascal.

**Include:** ui.goh

**Structures:** 

    typedef Boolean _pascal GestureCallback (
        Point *arrayOfInkPoints, 
        word numPoints, 
        word numStrokes);

----------
#### UserDestroyDialog()
    void    UserDestroyDialog(
            optr    dialogBox);

This routine destroys the passed dialog box, usually created with 
**UserCreateDialog()**. This routine may only be used to destroy dialog boxes 
occupying a single block; the block must also hold nothing other than the 
dialog box to be destroyed. It is for this reason that it is wise to only use this 
routine to destroy dialogs created with **UserCreateDialog()**.

**See Also:** UserCreateDialog()

----------
#### UserDoDialog()
    InteractionCommand UserDoDialog(
            optr    dialogBox);

**UserDoDialog()** brings a pre-instantiated dialog box on-screen, blocking 
the calling thread until the user responds to the dialog. You must pass the 
optr of a GIV_DIALOG Interaction that is set both 
GIA_INITIATED_VIA_USER_DO_DIALOG and GIA_MODAL. 

This routine returns the **InteractionCommand** of the particular response 
trigger selected by the user. This **InteractionCommand** may be either a 
predefined type (such as IC_YES) or a custom one defined using 
IC_CUSTOM_START.

The pre-defined **InteractionCommands** are:

    IC_NULL
    IC_DISMISS
    IC_APPLY
    IC_RESET
    IC_OK
    IC_YES
    IC_NO
    IC_STOP
    IC_EXIT
    IC_HELP
    IC_INTERACTION_COMPLETE

This routine may return IC_NULL for those cases in which a system 
shutdown causes the dialog to be dismissed before the user has entered a 
response. 

**Warnings:** This routine blocks the calling thread until the dialog box receives a 
MSG_GEN_GUP_INTERACTION_COMMAND. Since the application thread is 
blocked, it cannot be responsible for sending this message or for handling 
messages from the response triggers. 

**See Also:** UserStandardDialog(), UserStandardDialogOptr()

----------
#### UserGetInterfaceLevel()
    UIInterfaceLevel UserGetInterfaceLevel(void)

This routine returns the current **UIInterfaceLevel**. This is a word-sized 
enumerated type. It has the following values:

    UIIL_NOVICE
    UIIL_BEGINNING_INTERMEDIATE
    UIIL_ADVANCED_INTERMEDIATE
    UIIL_ADVANCED
    UIIL_GURU

**Include:** ui.goh

----------
#### UserLoadApplication
    extern  GeodeHandle UserLoadApplication(
            AppLaunchFlags      alf,
            Message             attachMethod,
            MemHandle           appLaunchBlock,
            char                *filename,
            StandardPath        sPath,
            GeodeLoadError      *err);

Loads an application.  Changes to standard application directory before 
attempting GeodeLoad on filename passed. Stores the filename being 
launched into the AppLaunchBlock, so that information needed to restore 
this application instance will be around later if needed.

----------
#### UserRemoveAutoExec()
    void    UserRemoveAutoExec(
            const char *        appName);

This routine removes an application from the list of those to be launched on 
start-up. It is passed one argument:

*appName* - This is a pointer to a null-terminated string containing the 
name of the application.

**Include:** ui.goh

----------
#### UserStandardDialog()
    word    UserStandardDialog(
            char *                  helpContext,
            char *                  customTriggers,
            char *                  arg2,
            char *                  arg1,
            char *                  string,
            CustomDialogBoxFlags    dialogFlags);

**UserStandardDialog()** creates and displays either a custom dialog box or 
one of several pre-defined standard dialog boxes. 

Most often, you will use this routine to create a custom dialog box that 
conforms to a standardized dialog. In this case, pass the 
**CustomDialogType** of SDBT_CUSTOM as the routine's first argument. You 
must then supply other parameters to create the custom dialog box.

If instead you wish to use one of the pre-defined **CustomDialogType** types, 
you should pass that type as the first argument to this routine. Some of these 
standard types require you to pass string parameters. Other arguments 
should be passed as null.

For custom dialog boxes you must pass a **CustomDialogType** 
(CDT_WARNING, CDT_NOTIFICATION, CDT_QUESTION, or CDT_ERROR). 
This chooses the proper icon glyph to display within the dialog box. (For 
example, a CDT_WARNING dialog might contain a large exclamation-point 
glyph.) Make sure that you use CDBF_DIALOG_TYPE_OFFSET to pass this 
value.

You should also pass a valid **GenInteractionType**. In most cases, this will 
be either GIT_NOTIFICATION, GIT_AFFIRMATION, or 
GIT_MULTIPLE_RESPONSE. Make sure that you use 
CDBF_INTERACTION_TYPE_OFFSET to pass this value.

Also pass the routine a string to display to the user. This string may be either 
text or graphics based.

If the **CustomDialogType** is GIT_MULTIPLE_RESPONSE, you must also set 
up a Response Trigger Table with several trigger parameters.

----------
#### UserStandardDialogOptr()
    word    UserStandardDialogOptr(
            char                    *helpContext,
            optr                    customTriggers,
            optr                    arg2,
            optr                    arg1,
            optr                    string
            CustomDialogBoxFlags    dialogFlags);

**UserStandardDialogOptr()** performs the same functionality as 
**UserStandardDialog()** except that optrs to strings and string parameters 
are passed instead of fptrs. This is useful for localized strings in resource 
blocks.

**See Also:** UserStandardDialog(), UserDoDialog() 

----------
#### UserStandardSound()
    void    UserStandardSound(
            StandardSoundType       type,
            ...);

This routine plays a simple sequence of notes. It can be used to play a 
standard system sound, a single custom tone, or a sequence of tones.

The routine takes a variable number of arguments. The first argument is a 
member of the **StandardSoundType** enumerated type. This argument 
specifies what kind of tone or tones will be played. Depending on the 
**StandardSoundType** passed, zero, one, or two additional arguments may 
be needed. **StandardSoundType** contains the following members:

SST_ERROR  
This is the sound played when an "Error" dialog comes up. No 
further arguments are needed.

SST_WARNING  
This is a general warning sound. No further arguments are 
needed.

SST_NOTIFY  
This is a general notification sound. No further arguments are 
needed.

SST_NO_INPUT  
This is the sound played when a user's input is not going 
anywhere (e.g. when he clicks the mouse outside a modal dialog 
box).

SST_KEY_CLICK  
This is the sound produced when the keyboard is pressed, or 
when the user clicks on a floating keyboard. No further 
arguments are required.

SST_CUSTOM_SOUND  
Play a custom sampled sound. This requires one more 
argument, the memory handle of the sound to be played.

SST_CUSTOM_BUFFER  
Play a custom buffer of instrumental sound. This requires one 
further argument, a pointer to the memory block containing 
the sound buffer. Note that the "tempo" value used to play this 
buffer will be one tick per thirty-second note, probably much 
faster than you would otherwise expect.

SST_CUSTOM_NOTE  
By passing this argument, you can have a single custom note 
played. You must provide one further argument, the handle of 
the note (such as returned by **SoundAllocNote()**).

----------
#### UtilAsciiToHex32()
    Boolean UtilAsciiToHex32(
            const char *        string,
            dword *             value);

This routine converts a null-terminated ASCII string into a 32-bit integer. 
The string may begin with a hyphen, indicating a negative number. Aside 
from that, the string may contain nothing but numerals until the null 
termination. It may not contain whitespace.

If the routine is successful, it will return *false* and write an equivalent signed 
long integer to **value*. If it fails, it will return *true* and write a member of the 
UtilAsciiToHexError enumerated type to **value*. This type contains the 
following members:

UATH_NON_NUMERIC_DIGIT_IN_STRING  
This string contained a non-numeric character before the 
trailing null (other than the allowed leading hyphen).

UATH_CONVERT_OVERFLOW  
The string specified a number to large to be expressed as a 
signed 32-bit integer.

**Include:** system.h

----------
#### UtilHex32ToAscii()
    word    UtilHex32ToAscii(
            char *                      buffer,
            sdword                      value, 
            UtilHexToAsciiFlags         flags);

This routine converts a 32-bit unsigned integer to its ASCII representation 
and writes it to the specified buffer. It returns the length of the string (not 
counting the nulll termination, if any). The routine is passed the following 
arguments:
*buffer* - This is a pointer to a character buffer. The buffer must be long 
enough to accommodate the largest string; that is, there must 
be ten bytes for the characters, plus one for the trailing null (if 
necessary).

*value* - This is the value to convert to ASCII.

*flags* - This is a record of **UtilHexToAscii** flags. The following flags 
are available:

UHTAF_INCLUDE_LEADING_ZEROS  
Pad the string with leading zeros to a length of ten total 
characters.

UHTAF_NULL_TERMINATE  
Add a null to the end of the string. If this flag is set, the buffer 
must be at least 11 bytes long. If it is clear, the buffer may be 
ten bytes long.

**Include:** system.h

----------
#### VarDataFlagsPtr()
    VarDataFlags    VarDataFlagsPtr(
            void *  ptr);

This macro fetches the flags of a variable data type when given a pointer to 
the extra data for the type. The flags are stored in a **VarDataFlags** record. 
Only the flags VDF_EXTRA_DATA and/or VDF_SAVE_TO_STATE will be 
returned.

**Include:** object.h

**Warnings:** You must pass a pointer to the beginning of the vardata entry's extra data 
space.

----------
#### VarDataSizePtr()
    word    VarDataSizePtr(
            void *  ptr);

This macro fetches the size of a variable data entry when given a pointer to 
the extra data for the type.

**Include:** object.h

**Warnings:** You must pass a pointer to the beginning of the vardata entry's extra data 
space.

----------
#### VarDataTypePtr()
    word    VarDataTypePtr(
            void *  ptr);

This macro fetches the type of a variable data entry when given a pointer to 
the extra data of the entry. The type is stored in a **VarDataFlags** record. All 
flags outside the VDF_TYPE section will be cleared.

**Include:** object.h

**Warnings:** You must pass a pointer to the beginning of the vardata entry's extra data 
space.

----------
#### VisObjectHandlesInkReply()
    void    VisObjectHandlesInkReply(void);

----------
#### VisTextGraphicCompressGraphic()
    extern VMChain VisTextGraphicCompressGraphic(
            VisTextGraphic      *graphic,
            FileHandle          sourceFile,
            FileHandle          destFile,
            BMFormat            format,
            word                xRes, 
            word                yRes);

This routine compresses the bitmaps in a VisTextGraphic.

----------
#### VMAlloc()
    VMBlockHandle   VMAlloc(
            VMFileHandle    file,           
            word            size,       /* Size of a file in bytes */
            word            userID);    /* ID # to associate with block */

This routine creates a VM block. The block is not initialized. Before you use 
the block, you must lock it with **VMLock()**. If you pass a size of zero bytes, 
the VM block will be given an entry in the VM handle table, but no space in 
memory or in the file will be used; a global memory block will have to be 
assigned with **VMAttach()**.

**Include:** vm.h

**See Also:** VMAllocLMem(), VMAttach()

----------
#### VMAllocLMem()
    VMBlockHandle   VMAllocLmem(
            VMFileHandle    file,               
            LMemType        ltype,          /* Type of LMem heap to create */
            word            headerSize      /* Size to leave for LMem header,
                                             * pass zero for standard header */

This routine allocates a VM block and initializes it to contain an LMem heap. 
You must pass the type of LMem heap to create. If you want a fixed data 
space, you must pass the total size to leave for a header (including the 
**LMemBlockHeader**); otherwise, pass a zero header size, indicating that 
only enough space for an **LMemBlockHeader** should be left. You do not 
need to specify a block size, since the heap will automatically expand to 
accommodate chunk allocations.

The block's user ID number is undefined. You will need to lock the block with 
**VMLock()** before accessing the chunks.

**Include:** vm.h

**Be Sure To:** When you access chunks, remember to pass the block's global memory handle 
to the LMem routines (not the block's VM handle).

**See Also:** LMemInitHeap(), VMAlloc(), VMAttach()

----------
#### VMAttach()
    VMBlockHandle   VMAttach(
            VMFileHandle        file,
            VMBlockHandle       vmBlock,
            MemHandle           mh);

This routine attaches an existing global memory block to a VM block. It is 
passed the following arguments:

*file* - The file's **VMFileHandle**.

*vmBlock* - The handle of the VM block to which the memory block should 
be attached. Any data associated with that block will be lost. If 
you pass a null **VMBlockHandle**, a new VM block will be 
allocated.

*mh* - The handle of the global memory block to attach.

The routine returns the handle of the VM block to which the memory block 
was attached.

If you attach to a pre-existing VM block, its user ID will be preserved. If you 
create a new block (by passing a null *vmBlock* argument), the user ID will be 
undefined.

**Include:** vm.h

----------
#### VMCheckForModifications()
Boolean VMCheckForModifications(
            VMFileHandle        file);

This routine returns *true* if the VM file has been dirtied or updated since the 
last full save.

**Include:** vm.h

----------
#### VMClose()
    word    VMClose(
            VMFileHandle        file,
            Boolean             noErrorFlag);

This routine updates and closes a VM file. If it is successful, it returns false. 
If it fails, it returns a member of the **FileError** enumerated type. Note that 
the routine closes the file even if it could not successfully update the file; in 
this case, any changes since the last update will be lost. For this reason, it is 
safest to call **VMUpdate()** first, then (after the file has been successfully 
updated) call **VMClose()**.

If *noErrorFlag* is true, **VMClose()** will fatal-error if it could not successfully 
update and close the file.

**Include:** vm.h

----------
#### VMCompareVMChains()
    Boolean VMCompareVMChains(
            VMFileHandle        sourceFile,
            VMChain             sourceChain,
            VMFileHandle        destFile,
            VMChain             destChain);

This routine compares two VM chains or DB items. It returns *true* if the two 
are identical; otherwise it returns *false*.

**Include:** vm.h

----------
#### VMCopyVMBlock()
    VMBlockHandle   VMCopyVMBlock(
            VMFileHandle        sourceFile,
            VMBlockHandle       sourceBlock,
            VMFileHandle        destFile);

This routine creates a duplicate of a VM block in the specified destination file 
(which may be the same as the source file). It returns the duplicate block's 
handle. The duplicate will have the same user ID as the original block.

**Include:** vm.h

----------
#### VMCopyVMChain()
    VMChain     VMCopyVMChain(
            VMFileHandle        sourceFile,
            VMChain             sourceChain,
            VMFileHandle        destFile);

This routine creates a duplicate of a VM chain (or DB item) in the specified 
destination file (which may be the same as the source file). It returns the 
duplicate's **VMChain** structure. All blocks in the duplicate will have the 
same user ID numbers as the corresponding original blocks.

**Include:** vm.h

----------
#### VMDetach()
    MemHandle   VMDetach(
            VMFileHandle    file,
            VMBlockHandle   block,
            GeodeHandle     owner);     /* Pass zero to have block owned by 
                                         * current thread's owner */

This routine detaches a global memory block from a VM block. If the VM block 
is not currently in memory, **VMDetach()** allocates a memory block and 
copies the VM block into it. If the VM block is dirty, **VMDetach()** will update 
the block to the file before detaching it.

**Include:** vm.h

----------
#### VMDirty()
    void    VMDirty(
            MemHandle       mh);

This routine marks a locked VM block as dirty.

**Include:** vm.h

----------
#### VMFind()
    VMBlockHandle   VMFind(
            VMFileHandle        file,
            VMBlockHandle       startBlock,
            word                userID);

This routine finds a VM block with the specified user ID number. If the second 
argument is **NullHandle** the routine will return the matching block with the 
lowest handle. If the second argument is non-null, it will return the first 
matching block whose handle is larger than the one passed (in numerical 
order).

**Include:** vm.h

----------
#### VMFree()
    void    VMFree(
            VMFileHandle        file,
            VMBlockHandle       block);

This routine frees the specified VM block. If a global memory block is 
currently attached to the VM block, it is freed too.

**Include:** vm.h

----------
#### VMFreeVMChain()
    void    VMFreeVMChain(
            VMFileHandle        file,
            VMChain             chain);

This routine frees the specified VM chain or DB item. If a chain is specified, 
all blocks in the chain will be freed.

**Include:** vm.h

----------
#### VMGetAttributes()
    word    VMGetAttributes(
            VMFileHandle        file);

Each VM file contains a set of **VMAttributes** flags. These determine how the 
VM manager will treat the file. This routine returns the current flags.

**Include:** vm.h

**Tips and Tricks:** When the Document Control objects create files, they automatically initialize 
the attributes appropriately.

**See Also:** VMSetAttributes()

----------
#### VMGetDirtyState()
    word    VMGetDirtyState(
            VMFileHandle        file);

This routine finds out if a file has been dirtied. It returns a word-sized value. 
The upper byte of the return value is non-zero if the file has not been dirtied 
since the last save, auto-save, or update; the lower byte is non-zero if the file 
has not been dirtied since the last save. Thus, if the return value is zero, the 
file must be updated.

**Include:** vm.h

**Tips and Tricks:** **VMUpdate()** is optimized for updating clean files. For this reason, it is faster 
to call **VMUpdate()** than it is to first check the dirty state, then call 
**VMUpdate()** only if the file is dirty.

----------
#### VMGetMapBlock()
    VMBlockHandle   VMGetMapBlock(
            VMFIleHandle        file);

This routine returns the VM block handle of the file's map block.

**Include:** vm.h

----------
#### VMGrabExclusive()
    VMStartExclusiveReturnValue VMGrabExclusive(
            VMFileHandle        file,
            word                timeout,
            VMOperation         operation,
            VMOperation *       currentOperation);

This routine gets exclusive access to a VM file for this thread.

**Include:** vm.h

----------
#### VMInfo()
    Boolean VMInfo(
            VMFileHandle        file,
            VMBlockHandle       block,
            VMInfoStruct *      info

This routine writes the memory handle, block size, and user ID number of the 
block. It returns *false* if the handle is invalid or free.

**Include:** vm.h

----------
#### VMLock()
    void *  VMLock(
            VMFileHandle        file,
            VMBlockHandle       block,
            MemHandle*          mh);

This routine locks a VM block into the global heap. It returns the block's base 
address.

**Include:** vm.h

----------
#### VMMemBlockToVMBlock()
    VMBlockHandle   VMMemBlockToVMBlock(
            MemHandle           mh,
            VMFileHandle*       file);

This routine gets the VM block and file handles for a specified memory block. 
It returns the VM block handle and copies the VM file handle into **file*.

The memory handle passed must be the handle of a block which is attached 
to a VM file. If it is not, the results are undefined.

**Include:** vm.h

----------
#### VMModifyUserID()
    void    VMModifyUserID(
            VMFileHandle        file,
            VMBlockHandle       block,
            word                userID);

This routine changes a VM block's user ID number.

**Include:** vm.h

----------
#### VMOpen()
    VMFileHandle    VMOpen(
            char *          name,           /* Name of file to open/create */
            VMAccessFlags   flags,
            VMOpenType      mode,
            word            compression);   /* Compression threshold percentage 
                                             * passed as an integer */

This routine opens or creates a VM file. It returns the handle of the opened 
file. If it is unable to open the file, it sets the error value for 
**ThreadGetError()**. **VMOpen()** looks for the file in the thread's working 
directory (unless a temporary file is being created, as described below). The 
routine takes four arguments:

*name* - A pointer to a string containing the name of the file to open. 
The file will be opened in the thread's current working 
directory. If a temporary file is being opened, this buffer should 
contain the full path of the directory in which to create the file, 
followed by fourteen null bytes (counting the string-ending 
null). **VMOpen()** will write the name of the temporary file in 
those trailing nulls.

*flags* - This specifies what kind of access to the file you need. The flags 
are described below.

*mode* - This specifies how the file should be opened. The types are 
described below.

*compression* - The compression threshold percentage, passed as an integer. 
For example, to set a compression threshold of 50%, pass the 
integer `50'. When the percentage of used space in the file drops 
below the compression threshold, the VM manager will 
automatically compress the file. To use the system default 
threshold, pass a threshold of zero. The compression threshold 
is set only when the file is created; this argument is ignored if 
an existing file is opened.

The **VMAccessFlags** specify what kind of access to the file the caller wants. 
The following flags are available:

VMAF_FORCE_READ_ONLY  
If set, the file will be opened read-only, even if the default would 
be to open the file read/write. Blocks in read-only files cannot 
be dirtied, and changes in memory blocks will not be updated 
to the disk VM blocks.

VMAF_FORCE_READ_WRITE  
If set, the file will be opened for read/write access, even if the 
default would be to open the file for read-only access.

VMAF_SHARED_MEMORY  
If set, the VM manager should try to use shared memory when 
locking VM blocks; that is, the same memory block will be used 
for a given VM block no matter which thread locks the block.

VMAF_FORCE_DENY_WRITE  
If set, then open the file deny-write; that is, no other threads 
will be allowed to open the file for read/write access.

VMAF_DISALLOW_SHARED_MULTIPLE  
If this flag is set, files with the file attribute 
GFHF_SHARED_MULTIPLE cannot be opened.

VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION  
If set, the block-level synchronization mechanism of the VM 
manager is assumed to be sufficient; the more restrictive 
StartExclusive/EndExclusive mechanism is not used. This is 
primarily intended for system software.

You must also specify how the file should be opened. To do this, you pass a 
member of the **VMOpenType** enumerated type. The following types are 
available:

VMO_TEMP_FILE  
If this is passed, the file will be a temporary data file. When you 
create a temporary file, you pass a directory path, not a file 
name. The path should be followed by fourteen null bytes, 
including the string's terminating null. The system will choose 
an appropriate file name and add it to the path string.

VMO_CREATE_ONLY  
If this is passed, the document will be created. If a document 
with the specified name already exists in the working directory, 
**VMOpen()** will return an error condition.

VMO_CREATE  
If this is passed, the file will be created if it does not already 
exist; otherwise it will be opened.

VMO_CREATE_TRUNCATE  
If this is passed, the file will be created if it does not already 
exist; otherwise, it will be opened and truncated (all data 
blocks will be freed).

VMO_OPEN  
Open existing file. If file does not exist, return an error 
condition.

If for any reason **VMOpen()** is unable to open the requested file, it will 
returns a null file handle. It will also set the error value for 
**ThreadGetError()**. The possible error conditions are:

VM_FILE_EXISTS  
**VMOpen()** was passed VMO_CREATE_ONLY, but the file 
already exists.

VM_FILE_NOT_FOUND  
**VMOpen()** was passed VMO_OPEN, but the file does not exist.

VM_SHARING_DENIED  
The file was opened by another geode, and access was denied.

VM_OPEN_INVALID_VM_FILE  
**VMOpen()** was instructed to open an invalid VM file (or a 
non-VM file).

VM_CANNOT_CREATE  
**VMOpen()** cannot create the file (but it does not already exist).

VM_TRUNCATE_FAILED  
**VMOpen()** was passed VMO_CREATE_TRUNCATE; the file 
exists, but could not be truncated.

**VM_WRITE_PROTECTED**  
**VMOpen()** was passed VMAF_FORCE_READ_WRITE, but the 
file was write-protected.

**Include:** vm.h

**Tips and Tricks:** If you use the document control objects, they will take care of opening files as 
necessary; you will not need to call **VMOpen()**.

**See Also:** FileOpen()

----------
#### VMPreserveBlocksHandle()
    void    VMPreserveBlocksHandle(
            VMFileHandle        file,
            VMBlockHandle       block);

Keep the same global memory block with this VM block until the block is 
explicitly detached or the VM block is freed.

**Include:** vm.h

----------
#### VMReleaseExclusive()
    void VMReleaseExclusive(
            VMFileHandle        file);

This routine releases a thread's exclusive access to a VM file.

**Include:** vm.h

----------
#### VMRevert()
    void    VMRevert(
            VMFileHandle        file,);

This routine reverts a file to its last-saved state.

**Include:** vm.h

----------
#### VMSave()
    void    VMSave(
            VMFileHandle        file);

This routine updates and saves a file, freeing all backup blocks.

**Include:** vm.h

----------
#### VMSaveAs()
    VMFileHandle VMSaveAs(
            VMFileHandle        file,
            const char          *name,
            VMAccessFlags       flags.
            VMOpenTypes         mode,
            word                compression);

This routine saves a file under a new name. The old file is reverted to its 
last-saved condition.

**Include:** vm.h

----------
#### VMSetAttributes()
    word    VMSetAttributes(
            VMFileHandle    file,
            VMAttributes    attrToSet,      /* Turn these flags on... */
            VMAttributes    attrToClear);   /* after turning these flags off */

This routine changes a VM file's **VMAttributes** settings. The routine returns 
the new attribute settings.

**Include:** vm.h

**Tips and Tricks:** When the Document Control objects create files, they automatically initialize 
the attributes appropriately.

**Warnings:** If you turn off VMA_BACKUP, make sure you do it right after a save or revert 
(when there are no backup blocks).

**See Also:** VMGetAttributes()

----------
#### VMSetExecThread()
    void    VMSetExecThread(
            VMFileHandle        file,
            ThreadHandle        thread);

Set which thread will execute methods of all objects in the file.

**Include:** vm.h

----------
#### VMSetMapBlock()
    void    VMSetMapBlock(
            VMFileHandle        file,
            VMBlockHandle       block);

This routine sets the map block for a VM file. 

**Include:** vm.h

----------
#### VMSetReloc()
    void    VMSetReloc(
            VMFileHandle    file,
            void (*reloc)   (VMFileHandle       file,
                             VMBlockHandle      block,
                             MemHandle          mh,
                             void               *data,
                             VMRelocTypes       type));

This routine sets a data-relocation routine for the VM file.

**Include:** vm.h

----------
#### VMUnlock()
    void    VMUnlock(
            MemHandle       mh);

This routine unlocks a locked VM block. Note that the block's global memory 
handle is passed (not its VM handle).

**Include:** vm.h

----------
#### VMUpdate()
    word    VMUpdate(
            VMFileHandle        file);

This routine updates dirty blocks to the disk.

**Include:** vm.h

**Tips and Tricks:** **VMUpdate()** is optimized for updating clean files to the disk. Therefore, it is 
faster to call **VMUpdate()** whenever you think it might be necessary, than it 
is to check the dirty state and then call **VMUpdate()** only if the file is 
actually dirty.

----------
#### VMVMBlockToMemBlock()
    MemHandle   VMVMBlockToMemBlock(
            VMFileHandle        file,
            VmBlockHandle       block);

This routine returns the global handle of the memory block attached to a 
specified VM block. If no global block is currently attached, it will allocate and 
attach one.

**Include:** vm.h

----------
#### WinAckUpdate()
    void    WinAckUpdate(
            WindowHandle        win);

This routine acknowledges that the application has received 
MSG_META_EXPOSED for the specified window, but chooses not to do any 
updating.

**Include:** win.h

----------
#### WinApplyRotation()
    void    WinApplyRotation(
            WindowHandle        win,
            WWFixedAsDWord      angle,
            WinInvalFlag        flag);

This routine applies the specified rotation to the window's transformation 
matrix.

**Include:** win.h

----------
#### WinApplyScale()
    void    WinApplyScale(
            WindowHandle        win,
            WWFixedAsDWord      xScale,
            WWFixedAsDWord      yScale,
            WinInvalFlag        flag);

This routine applies the specified scale factor to the window's transformation 
matrix.

**Include:** win.h

----------
#### WinApplyTranform()
    void    WinApplyTransform(
            WindowHandle            win,
            const TransMatrix *     tm,
            WinInvalFlag            flag);

This routine concatenates the passed transformation matrix with the 
window's transformation matrix. The result will be the window's new 
transformation matrix.

**Include:** win.h

----------
#### WinApplyTranslation()
    void    WinApplyTranslation(
            WindowHandle        win,
            WWFixedAsDWord      xTrans,
            WWFixedAsDword      yTrans,
            WinInvalFlag        flag);

This routine applies the specified translation to the window's transformation 
matrix.

**Include:** win.h

----------
#### WinApplyTranslationDWord()
    void    WinApplyExtTranslation(
            WindowHandle        win,
            sdword              xTrans,
            sdword              yTrans,
            WinInvalFlag        flag);

This routine applies the specified translation to the window's transformation 
matrix. The translations are specified as 32-bit integers.

**Include:** win.h

----------
#### WinChangeAck()
    WindowHandle WinChangeAck(
            WindowHandle        win,
            sword               x,
            sword               y,
            optr *              winOD);
            Include:            win.h

----------
#### WinChangePriority()
    void    WinChangePriority(
            WindowHandle        win,
            WinPassFlags        flags,
            word        layerID);

This routine changes the priority for the specified window.

**Include:** win.h

----------
#### WinClose()
    void    WinClose(
            WindowHandle        win);

This routine closes and frees the specified window.

**Include:** win.h

----------
#### WinDecRefCount()
    void    WinDecRefCount(
            WindowHandle        win);

This routine is part of the window closing mechanism.

----------
#### WinEnsureChangeNotification()
    void    WinEnsureChangeNotification(void);

**Include:** win.h

----------
#### WinGeodeGetInputObj()
    optr    WinGeodeGetInputObj(
            GeodeHandle     obj);

This routine fetches the optr of the input object for the specified geode. If 
there is no such object, it returns a null optr.

**Include:** win.h

----------
#### WinGeodeGetParentObj()
    optr    WinGeodeGetParentObj(
            GeodeHandle     obj);

This routine fetches the optr of the parent object of the specified geode. If 
there is no such object, it returns a null optr.

**Include:** win.h

----------
#### WinGeodeSetActiveWin()
    void    WinGeodeSetActiveWin(
            GeodeHandle         gh,
            WindowHandle        win);

This routine sets the active window for the specified geode.

**Include:** win.h

----------
#### WinGeodeSetInputObj()
    void    WinGeodeSetInputObj(
            GeodeHandle     gh,
            optr            iObj);

This routine sets the input object for the specified geode.

**Include:** win.h

----------
#### WinGeodeSetParentObj()
    void    WinGeodeSetParentObj(
            GeodeHandle     gh,
            optr            pObj);

This routine sets the parent object for the specified geode.

**Include:** win.h

----------
#### WinGeodeSetPtrImage()
    void    WinGeodeSetPtrImage(
            GeodeHandle     gh,
            optr            ptrCh);

This routine sets the pointer image for the specified geode.

**Include:** win.h

----------
#### WinGetInfo()
    dword   WinGetInfo(
            WindowHandle        win,
            WinInfoTypes        type,
            void *              data);

This routine retrieves the private data from a GState.

**Include:** win.h

----------
#### WinGetTransform()
    void    WinGetTransform(
            WindowHandle        win,
            TransMatrix *       tm);

This routine retrieves the transformation matrix for the specified window. It 
writes the matrix to *tm.

**Include:** win.h

----------
#### WinGetWinScreenBounds()
    void    WinGetWinScreenBounds(
            WindowHandle        win,
            Rectangle *         bounds);

This routine returns the bounds of the on-screen portion of a window 
(specified in screen co-ordinates). It writes the bounds to **bounds*.

**Include:** win.h

----------
#### WinGrabChange()
    Boolean WinGrabChange(
            WindowHandle        win,
            optr                newObj);

This routine allows an object to grab pointer events. It returns zero if it was 
successful; otherwise it returns non-zero.

**Include:** win.h

----------
#### WinInvalReg()
    void    WinInvalReg(
            WindowHandle        win,
            const Region *      reg,
            word                axParam,
            word                bxParam,
            word                cxParam,
            word                dxParam);

This routine invalidates the specified region or rectangle.

**Include:** win.h

----------
#### WinMove()
    void    WinMove(
            WindowHandle        win,
            sword       xMove,
            sword       yMove,
            WinPassFlags        flags);

This routine moves a window. If the WPF_ABS bit of *flags* is set, the window's 
new position is specified relative to its parent's position. If it is clear, the 
window's new position is specified relative to its current position.

**Include:** win.h

----------
#### WinOpen()
    WindowHandle WinOpen(
            Handle          parentWinOrVidDr,
            optr            inputRecipient,
            optr            exposureRecipient,
            WinColorFlags   colorFlags,
            word            redOrIndex,
            word            green,
            word            blue,
            word            flags,
            word            layerID,
            GeodeHandle     owner,
            const Region *  winReg,
            word            axParam,
            word            bxParam,
            word            cxParam,
            word            dxParam);

This routine allocates and initializes a window and (optionally) an associated 
GState.

**Include:** win.h

----------
#### WinReleaseChange()
    void    WinReleaseChange(
            WindowHandle        win,
            optr        obj);

This routine releases an object's grab on the change OD.

**Include:** win.h

----------
#### WinResize()
    void    WinResize(
            WindowHandle        win,
            const Region *      reg,
            word                axParam,
            word                bxParam,
            word                cxParam,
            WinPassFlags        flags);

This routine resizes a window. It can move it as well.

**Include:** win.h

----------
#### WinScroll()
    void    WinScroll(
            WindowHandle        win,
            WWFixedAsDWord      xMove,
            WWFixedAsSWord      yMove,
            PointWWFixed *      scrollAmt);

This routine scrolls a window.

**Include:** win.h

----------
#### WinSetInfo()
    void    WinSetInfo(
            WindowHandle        win,
            WinInfoType         type,
            dword               data);

This routine sets some data for the specified window.

**Include:** win.h

----------
#### WinSetNullTransform()
    void    WinSetNullTransform(
            WindowHandle        win,
            WinInvalFlag        flag);

This routine changes a window's transformation matrix to the null (or 
identity) matrix.

**Include:** win.h

----------
#### WinSetPtrImage()
    void    WinSetPtrImage(
            WindowHandle            win,
            WinSetPtrImageLevel     ptrLevel,
            optr                    ptrCh);

This routine sets the pointer image within the range handled by the specified 
window.

**Include:** win.h

----------
#### WinSetTransform()
    void    WinSetTransform(
            WindowHandle            win,
            const TransMatrix *     tm,
            WinInvalFlag            flag);

This routine replaces the window's transformation matrix with the one 
passed in **tm*.

**Include:** win.h

----------
#### WinSuspendUpdate()
    void    WinSuspendUpdate(
            WindowHandle        win);

This routine suspends the sending of update messages to the window. The 
messages will be sent when **WinUnSuspendUpdate()** is called.

**Include:** win.h

----------
#### WinTransform()
    XYValueAsDWord  WinTransform(
            WindowHandle        win,
            sword               x,
            sword               y);

This routine translates the passed document coordinates into screen 
coordinates.

**Include:** win.h

----------
#### WinTransformDWord()
    void    WinTransformDWord(
            WindowHandle        win,
            sdword              xCoord,
            sdword              yCoord,
            PointDWord *        screenCoordinates);

This routine translates the passed document coordinates into screen 
coordinates. The translated coordinates are written to **screenCoordinates*.

**Include:** win.h

----------
#### WinUnSuspendUpdate()
    void    WinUnSuspendUpdate(
            WindowHandle        win);

This routine cancels a previous **WinSuspendUpdate()** call.

**Include:** win.h

----------
#### WinUntransform
    XYValueAsDWord  WinUntransform(
            WindowHandle        win,
            sword               x,
            sword               y);

This routine translates the passed screen coordinates into document 
coordinates.

**Include:** win.h

----------
#### WinUnTransformDWord()
    void    WinTransformDWord(
            WindowHandle        win,
            sdword              xCoord,
            sdword              yCoord,
            PointDWord *        documentCoordinates);

This routine translates the passed screen coordinates into document 
coordinates. The translated coordinates are written to 
**documentCoordinates*.

**Include:** win.h

----------
#### WWFixedToFrac
    word    WWFixedToFrac(WWFixed wwf)

This macro lets you address the fractional portion of a **WWFixed** value. It is 
legal to use this to assign a value to the fractional portion; that is,

    WWFixedToFrac(myWWFixed) = 5;

is perfectly legal.

**Include:** geos.h

----------
#### WWFixedToInt
    word    WWFixedToInt(WWFixed wwf)

This macro lets you address the intetgral portion of a **WWFixed** value. It is 
legal to use this to assign a value to the integral portion; that is,

    WWFixedToInt(myWWFixed) = 5;

is perfectly legal.

**Include:** geos.h

[Routines Q-T](rroutq_t.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Data Structures](rstra_e.md)