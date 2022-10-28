## 1 Driver Development

There are three kinds of geode: applications, libraries, and drivers. Most
programmers will only write applications. A few will write libraries, either
for their own use or for other programmers’. A very few will write device drivers.

GEOS fully supports writing device drivers in assembly language. (It is
possible to write some drivers in C , but this is not recommended, due to speed
requirements.) Often, writing a driver for a new device is much like writing
a driver for an existing, older device of the same kind; e.g. writing a driver for
a new bus mouse is much like writing a driver for any other bus mouse. For
this reason, many GEOS device drivers share a lot of code; e.g. most of the
mouse drivers use a standard suite of routines, perhaps modified slightly for
the particular mouse.

The SDK contains examples of mouse, power, pcmcia, and sound drivers; by
examining them, you should be able to see how a driver is put together, and
how to rewrite one of those drivers for a new device. These examples are
located in the \OMNIGO\DRIVER\DDK directory.

### 1.1 Driver Basics

One of the advantages of the GEOS operating system is that it insulates
application developers from many of the low-level hardware chores. GEOS
does this by breaking up geodes into several types.

Most programmers write applications; these are the most visible geodes.
Users interact directly with applications; as a general rule, they only interact
indirectly with non-application geodes.

Applications use libraries. All applications use the GEOS kernel, which
functions as a kind of “system library”. Most applications use many other
libraries as well. Libraries can have many functions. For example, object
libraries define classes for applications to use, and many code libraries
provide suites of pre-written routines that applications can use as needed.
There is another role libraries play, though: they serve as an intermediary
between applications and drivers.

Drivers provide the nuts-and-bolts interface between GEOS and the
computer’s devices and peripherals. Drivers take care of such tasks as
writing data to the screen, sending information to the printer, and handling
input from the mouse and keyboard. Drivers do not, as a rule, interact
directly with applications or with the user. Instead, the kernel and other
libraries act as intermediaries between the drivers (and their associated
hardware) and the applications.

Each kind of driver (mouse, printer, power management, etc.) has certain
functions it is expected to fulfill. From the point of view of a library using a
printer driver, for example, all printer drivers should look and act more or
less the same. Thus, a driver will have close constraints on its interface with
other parts of GEOS.

#### 1.1.1 Driver Behavior

In some ways, drivers behave differently from other geodes. One major
difference is that for some drivers, running speed is a much higher priority
than it is for most applications or libraries. A mouse driver, for example, has
to handle mouse movements as quickly as possible, to keep from slowing
down the rest of the system every time the user moves the mouse. For this
reason, drivers tend to be written differently than other geodes. Most geodes
are concerned with making their running size as small as possible; a driver
is more likely to tolerate a larger size to get faster response. (This depends,
of course, on the driver. A print driver, for example, doesn’t need to be nearly
as efficient as a video driver.)

Drivers may also disable interrupts to perfrom their functions. They are the
only geodes permitted to do this. However, drivers should do this only when
absolutely necessary. Very few GEOS system routines may be called with
interrupts disabled. In practice, you should re-enable interrupts before
making any system calls.

Drivers tend to use fixed memory more often than other geodes do. A driver’s
strategy routine (described below) and interrupt handlers must all be in fixed
memory; any other timing-critical routines may also be in fixed resources.

#### 1.1.2 Driver Structure

A driver usually provides two communication structures. One is the interface
it provides to the GEOS system, either through a library or a GEOS
application; the other is its contact with whatever device it drives.

The driver’s interface to the system is called the strategy routine. Whenever
the system or a library needs to interact with a driver, it calls the strategy
routine; it passes in a code number saying what it needs to have the driver
do. This code is used by a jump table to call an appropriate routine in the
driver. The strategy routine must be in a fixed code resource.

A driver’s interface with its device will depend on what kind of device it’s
driving. Most often, a driver will receive and handle interrupts from its
device. It does this by registering an interrupt handler with the GEOS kernel.
The interrupt handler must also be in a fixed code resource.

#### 1.1.3 Extended Drivers

Some drivers can handle a number of similar, but distinct, devices. These
drivers are known as extended drivers. An extended driver must provide
certain extra information about itself to the system. Furthermore, it must
provide certain extra functionality to the kernel.

When an extended driver is loaded, it is told which of its various devices it is
intended to drive.

### 1.2 Defining a Basic Driver

Every driver, of whatever type, has a few components in common. The driver
stores information about itself in a certain, rigidly defined way; that way, the
system can get information about the driver in a direct manner.

The driver must have a strategy routine that performs certain specific
functions. Some of these functions are similar for all drivers of whatever
type; these are listed in this section. Others are specific for a type of driver;
these will be listed in the chapter pertaining to that type of driver.
Driver Development

#### 1.2.1 The Driver’s .GP File

A driver is a geode. As such, it will be compiled as any other geode, and
contains a geode parameters file. The geode parameters file looks somewhat
different than an application .gp file, however. A driver’s geode parameters
file should exhibit the following characteristics:

+ name should end with the .drvr suffix. This name must be unique across
all drivers, applications, and libraries.
+ type should be declared as driver. The driver may also be declared system and single.

Marking a geode as driver results in the setting of GA_DRIVER in the
geode’s GeodeAttrs field. This instructs the system to call the driver’s
DR_INIT and DR_EXIT functions as appropriate.

system indicates that the kernel relies upon the driver; it should remain
loaded as long as possible if the system is shutting down. (This has
ramifications for your DR_EXIT routine, discussed in [“The
DriverFunction Type”](#1242-the-driver-function-type).)

Most drivers will also want to be marked single, though if a library loads
a driver using GeodeUseDriver(), the driver will behave as
single-launchable regardless.

+ library should declare any libraries that this driver needs to load. For
example, a PCMCIA driver needs to include the pcmcia library.
+ The resource that contains the driver’s strategy routine, if it is not within
dgroup, needs to be declared as fixed, code, shared, and read-only. Most
other resources should be movable, if possible.

For information about any specific kind of driver, see the appropriate chapter,
if available, and check the device’s driver include file in
\OMNIGO\INCLUDE\INTERNAL. All device include file names end with
dr.def; for example, all mouse drivers must include the file mousedr.def.

#### 1.2.2 Information about the Driver

DriverTable, DriverInfoStruct, DriverAttrs, DriverType

As mentioned before, a driver contains one common routine entry point: its
strategy routine. All functions executed by the driver are accessed through
this routine. The driver does this by interpreting the function code passed to
this strategy routine and executing another routine (through use of a jump
table) upon determining what the driver should do. The address of this
common strategy routine is contained within a DriverTable structure.

The DriverTable must reside in fixed memory. In most cases, this is
accomplished by placing the table within dgroup. However, on XIP systems
where dgroup needs to be marked discardable, the table should reside in a
read-only, fixed, code resource. (In the unlikely case that your dgroup
consists almost entirely of just a driver table, it is fine to leave the table in
dgroup and leave it non-discardable.)

The name DriverTable is significant. The linker searches for this table, and
locates the strategy routine in this manner. The first item within your
DriverTable must be a DriverInfoStruct structure. This structure
contains certain basic information about the driver, including the location of
the strategy routine.

The DriverInfoStruct has the following definition:
~~~
	DriverInfoStruct struct
		DIS_strategy			fptr.far
		DIS_driverAttributes	DriverAttrs
		DIS_driverType			DriverType
		DriverInfoStruct ends
~~~
*DIS _strategy*  
This is the address of the strategy routine. The strategy routine
must be in a fixed code resource.

*DIS _driverAttributes*  
This field contains a DriverAttrs record. It specifies (in
general terms) what kind of device the driver handles. It also
specifies whether the driver is an extended driver.

*DIS _driverType*  
This field has a member of the DriverType enumerated type.
It specifies specifically what kind of device the driver drives.  

The *DIS _driverAttributes* field contains a DriverAttrs record. This record
has the following fields:
~~~
	DriverAttrs record
		DA_FILE_SYSTEM:1,
		DA_CHARACTER:1,
		DA_HAS_EXTENDED_INFO:1,
		:13
	DriverAttrs end
~~~
``DA_FILE_SYSTEM``  
The driver is for file access.

``DA_CHARACTER``  
The driver is for a character-oriented device.

``DA_HAS_EXTENDED_INFO``  
The driver is an extended driver; it provides extra information
and extra functionality (described below).  

The *DIS _driverType* field contains a member of the DriverType enumerated
type. This type specifies what kind of driver this is. The type has the
following members:
~~~
	DRIVER_TYPE_VIDEO
	DRIVER_TYPE_INPUT
	DRIVER_TYPE_MASS_STORAGE
	DRIVER_TYPE_STREAM
	DRIVER_TYPE_FONT
	DRIVER_TYPE_OUTPUT
	DRIVER_TYPE_LOCALIZATION
	DRIVER_TYPE_FILE_SYSTEM
	DRIVER_TYPE_PRINTER
	DRIVER_TYPE_SWAP
	DRIVER_TYPE_POWER_MANAGEMENT
	DRIVER_TYPE_TASK_SWITCH
	DRIVER_TYPE_NETWORK
	DRIVER_TYPE_SOUND
	DRIVER_TYPE_PAGER
	DRIVER_TYPE_PCMCIA
	DRIVER_TYPE_FEP
	DRIVER_TYPE_MAILBOX_DATA
	DRIVER_TYPE_MAILBOX_TRANSPORT
	DRIVER_TYPE_SOCKET
	DRIVER_TYPE_SCAN
	DRIVER_TYPE_OTHER_PROCESSOR
	DRIVER_TYPE_MAILBOX_RECEIVE
	DRIVER_TYPE_MODEM
	DRIVER_TYPE_CONNECT_TRANSLATE
	DRIVER_TYPE_CONNECT_TRANSFER
~~~

Code Display 1-1 A Sample DriverTable
~~~
;----------------------------------------------------------------------
; dgroup data
;----------------------------------------------------------------------
idata segment
    ; First, the driver info structure. Note that we name this structure as
    ; “DriverTable.”
DriverTable DriverInfoStruct <
    MyStrategyRoutine,
    <
        0,    ; not a DA_FILE_SYSTEM device driver
        0,    ; not a DA_CHARACTER device
        0,    ; no extended information
    >,
    DRIVER_TYPE_PCMCIA
>
    ; declare the table as public to prevent Esp from generating a warning.

public DriverTable
    ; Place any other initialized data here
idata ends

udata segment
    ; Place your uninitialized data here
udata ends
~~~

#### 1.2.3 Extended Drivers

If the driver is an extended driver (i.e., if the DA_HAS_EXTENDED_INFO bit
in the DIS _driverAttributes field is set), the device must use a slightly
different information structure. Instead of using a DriverInfoStruct, it
must begin its dgroup segment (or fixed, read-only, code resource) with a
DriverExtendedInfoStruct. The DriverExtendedInfoStruct has the
following definition:
~~~
	DriverExtendedInfoStruct struct
		DEIS_common        DriverInfoStruct
		DEIS_resource      hptr.DriverExtendedInfoTable
	DriverExtendedInfoStruct ends
~~~	
This structure’s first field is a regular DriverInfoStruct, so the segment
still begins with a DriverInfoStruct and a strategy routine, as is required.
The other field should contain the handle of a sharable lmem segment that
contains the driver’s DriverExtendedInfoTable.

Extended drivers must have a DriverExtendedInfoTable structure. This
structure, with its associated data, is generally put in its own resource, a
sharable LMem heap. The resource need not (indeed, should not) be fixed.
The DriverExtendedInfoTable structure must be at the beginning of the
resource. The DriverExtendedInfoTable structure has the following
definition:
~~~
	DriverExtendedInfoTable struct
		DEIT_common        LMemBlockHeader
		DEIT_numDevices    word
		DEIT_nameTable     nptr.lptr.char
		DEIT_infoTable     nptr.word
	DriverExtendedInfoTable ends
~~~
*DEIT_common*  
This is the standard LMem block header structure. You must
initialize this to “{}”. Do not attempt to fill in this field
yourself; Esp will fill in this field appropriately.

*DEIT_numDevices*  
This is the number of different devices supported by this driver.

*DEIT_nameTable*  
This is a near pointer to an array of chunk handles. Each chunk
handle is the handle of a chunk containing the name of a
supported device as a null-terminated string. There must be
*DEIT_numDevices* different entries in the table.

*DEIT _infoTable*  
This field contains a near pointer to an array of words. Each
word contains driver-specific information for each device. The
nature of this information depends on what kind of device
driver this is; the data kept in this word is discussed in Code
Display 1-2.

For example, suppose you are writing an extended driver that supports three
different sound cards. You might set up your driver’s informational
structures like this:

Code Display 1-2 A Driver’s Informational Structures
~~~
;----------------------------------------------------------------------
; dgroup data
;----------------------------------------------------------------------

idata segment

; First, the driver info structure. This is an extended driver, so we use the
; DriverExtendedInfoStruct:

DriverTable DriverExtendedInfoStruct <
    <MySoundStrategy,              ; the strategy routine
     mask DA_HAS_EXTENDED_INFO,;   ; the DriverAttrs record
     DRIVER_TYPE_SOUND>,           ; The DriverType
    MySoundExtendedInfoSegment>

idata ends

;----------------------------------------------------------------------
; Extended info segment
;----------------------------------------------------------------------
MySoundExtendedInfoSegment segment lmem LMEM_TYPE_GENERAL

; First, the DriverExtendedInfoTable. This must be at the beginning of the resource.

MySoundExtendedDriverInfoTable DriverExtendedInfoTable <
    {},                            ; The LMemBlockHeader;
                                   ; Esp will fill this in
    length MySoundBoardNames,      ; The number of boards supported
    offset MySoundBoardNames,      ; near-pointer to table of chunk handles
    offset MySoundBoardInfoTable   ; near-pointer to table of data words
    >

; Now, a table of chunk handles. The chunks contain the names of the different
; boards supported.

MySoundBoardNames      lptr.char   FooSound1_0,
                                   FooSound2_0,
                                   Knockoff1_2
                       lptr.char   0

; Now, the names themselves.

LocalDefString FooSound1_0    <'FooCo Soundarama 1.0', 0>
                                   ; The string must be null-terminated
LocalDefString FooSound2_0    <'FooCo Soundarama 2.0', 0>
LocalDefString Knockoff1_2    <'KnockOff SoundClone 1.2', 0>

; And the data words.

MySoundBoardInfoTable word
               SoundWordOfData <1,1,1,>,
               SoundWordOfData <1,1,1,>,
               SoundWordOfData <1,1,1,>

MySoundExtendedInfoSegment ends
~~~
The drivers for some kinds of devices must be extended drivers.
Furthermore, some devices require you to use a certain special InfoStruct,
the first field of which is a DriverExtendedInfoStruct or
DriverInfoStruct. For example, if you are writing a mouse driver, you must
begin its driver table segment with a MouseDriverInfoStruct, the first
field of which is a DriverExtendedInfoStruct.

#### 1.2.4 The Strategy Routine

Every driver must have a strategy routine. This routine is called by the GEOS
kernel and by libraries. The strategy routine is passed a code telling it what
it should do. The strategy routine acts accordingly. Generally, the strategy
routine contains a jump table; it calls a different routine, using the passed
code as an offset into the jump table. (All the passed codes are even numbers,
to facilitate jumping through a table of near-pointers.)

##### 1.2.4.1 What Functions Must Be Handled?

''DriverFunction, DriverExtendedFunction''

The strategy routine must be in a fixed resource. As noted above in
[“Information about the Driver”](#122-information-about-the-driver), you should put a pointer to the
routine in the driver’s DriverInfoStruct.

The strategy routine is always passed at least one argument, in the di
register. This argument value specifies what the strategy routine should do.
(Other arguments may be passed, depending on what is in di; the return
value also depends on the passed value of di.) di may contain one of the
following four things:

+ A member of the DriverFunction enumerated type, the most elemental
of all driver functions. This type contains four values: DR_INIT , DR_EXIT ,
DR_SUSPEND , and DR_UNSUSPEND . All drivers must be able to handle
these four functions. (The DriverFunction type is discussed below in
“The DriverFunction Type” on page 20.)
Driver Development

+ A member of the DriverExtendedFunction enumerated type. These
will only be sent to extended drivers. This type contains two values:
DRE_TEST_DEVICE and DRE_SET_DEVICE . All extended drivers must be
able to handle these functions. (The DriverExtendedFunction type is
discussed below in “The DriverExtendedFunction Type” on page 24.)

+ A function type specific to the kind of device-driver this is. (For example,
PCMCIA drivers should handle the PCMCIAFunction codes.) Different
types of drivers, of course, need to handle different functions. Mouse
drivers, for example, have to handle different functions than print
drivers do. The device-specific codes are discussed in the chapter relating
to those drivers.

+ An escape code. If the high bit of di is set, an escape code is being sent.
Different drivers will react to this in different ways. Some drivers will not
have to handle escape codes at all.

##### 1.2.4.2 The DriverFunction Type

DR_INIT, DR_EXIT, DR_SUSPEND, DR_UNSUSPEND

Every driver, of whatever type, must handle the four functions specified by
the DriverFunction type. Even if a device driver wishes to do nothing upon
receipt of an event, it must at least handle the function code itself. These
functions are bound to the even integers from zero to six. Each of these
functions has its own pass and return conventions.
___
+ ``DR_INIT``  
This is sent to the driver when it is first loaded. Typically, a driver will set up
whatever interrupt handlers it may have. You might also wish to load any
state variables that the driver needs  

__Pass:__  
  - di -> DR_INIT (= 0).
  - cx -> value of di passed to GeodeLoad. If the driver was not loaded through GeodeLoad, the value in this register is undefined.  
  - dx -> value of bp passed to GeodeLoad. If the driver was not loaded through GeodeLoad, the value in this register is  undefined.  
  
__Returns:__
  - CF -> Set if initialization failed; the system will then automatically unload the driver.

__Destroyed:__  
  - Allowed to destroy ax, cx, dx, ds, es, di, si, bp  

__Include:__
driver.def

___
+ ``DR_EXIT``  
This is sent to the driver when it is being unloaded. Typically, drivers
unregister any interrupt handlers they may have set up.  
If the driver is a system driver (i.e., system is set within its geode parameters
file) then the handler for this function, and any information that handler
needs, must reside in fixed memory. This allows the driver to be unloaded at
the last possible moment.

__Pass:__
  - di -> DR_EXIT (= 2).

__Returns:__
  - Nothing.

__Destroyed:__  
  - Allowed to destroy ax, bx, cx, dx, ds, es, di, si.

__Include:__  
driver.def

___
+ ``DR_SUSPEND``  
This is sent to the driver if GEOS is attempting to task-switch out. The driver
may refuse to suspend itself.

__Pass:__
  - di -> DR_SUSPEND (=4).
  - cx:dx -> Pointer to a buffer of length DRIVER_SUSPEND_ERROR_BUFFER_SIZE (defined in driver.def as 128 bytes).

__Returns:__
  - CF -> Set if the driver refuses to suspend. The driver should then write a null-terminated explanatory message, using the standard GEOS character set, to the buffer pointed to by cx:dx.

__Destroyed:__
  - Allowed to destroy ax, di.

__Include:__
driver.def

___
+ ``DR_UNSUSPEND``  
This is sent to the driver if GEOS is being task-switched back into memory.

__Pass:__
  - di -> DR_UNSUSPEND (=6).

__Returns:__
  - Nothing.

__Destroyed:__
  - Allowed to destroy ax, di.

__Include:__
driver.def

##### 1.2.4.3 Writing the Strategy Routine

As noted, the strategy routine is the single entry point upon which a driver
executes code. That routine determines what the driver needs to do, and calls
the appropriate function from that point.

Code Display 1-3 A Sample Strategy Routine
~~~
DefPFunction macro routine, constant
.assert     ($-pfuncs) eq constant*2,  <Routine is not in the right slot!>
.assert     (type routine eq far),     <Routine is not declared far!>
            fptr.far       routine
            endm

Resident     segment       resource

pfuncs       label         fptr.far
             ;
             ;Handle the basic four DriverFunction types
             ;
DefPFunction               MyInit,         DR_INIT
DeFPFunction               MyExit,         DR_EXIT
DefPFunction               MySuspend,      DR_SUSPEND
DefPFunction               MyUnsuspend,    DR_UNSUSPEND
             ;
             ; If this is an extended driver, they would appear here
             ; Otherwise, begin the enumerations peculiar to this driver
             ;
DefPFunction               MyCustomRoutine DR_MYDRIVER_CUSTOM_ROUTINE
             ;
             ; Write the strategy routine itself
             ;
MyStrategy   proc far
             uses ds, es
             .enter

             ; Make sure we can handle the function
             cmp         di, MyFunction
             jae         fail
             test        di, 1
             jnz         fail
             ; check whether the function code is odd (invalid)
             ; Now call the appropriate driver routine. Load DS and ES with our dgroup
             ; for future use

	     segmov      ds, dgroup, ax
             mov         es, ax
             shl         di
             pushdw      cs:[pfuncs][di]
             call        PROCCALLFIXEDORMOVABLE_PASCAL
done:
             .leave
             ret
fail:
             stc                       ; set carry if we can’t support
             jmp         done
MyStrategy   endp

MyDoNothing  proc        far

             clc
             ret

MyDoNothing  endp

Resident     ends

Init         segment resource
MyInit       proc        far
             ; Handle DR_INIT
MyInit       endp

MyExit       proc        far
             ; Handle DR_EXIT
MyExit       endp

Init         ends
~~~

##### 1.2.4.4 The DriverExtendedFunction Type

``DRE_TEST_DEVICE, DRE_SET_DEVICE, DevicePresent, EnumerateDevice``  
All extended drivers must be able to handle the two functions specified by the
DriverExtendedFunction type. These are defined in the file driver.def.
Because these types are enumerated following the DriverFunction types,
they contain a value of either 8 or 10.

This file also provides a useful macro for extended drivers,
EnumerateDevice. This macro locks the block containing the extended
driver info, and searches through the name table for the device string passed.
This is very useful for handling functions.

___
+ ``DRE_TEST_DEVICE``  
This function instructs the driver to test whether the device needing to be
driven is one which is actually able to run, and is present on the system. The
null-terminated string name of the device is passed. The strategy routine
should return a member of the DevicePresent enumerated type. There are
four possible return values:
  + DP_NOT_PRESENT  
    Driver knows that the device is not there.
  + DP_CANT_TELL  
    Driver isn’t sure whether the device is there.
  + DP_PRESENT  
    Driver knows that the device is there.
  + DP_INVALID_DEVICE  
    The string passed does not contain the name of a device supported by the driver.  

__Pass:__  
  - di -> DRE_TEST_DEVICE (= 8).  
  - dx:si -> Pointer to null-terminated string containing the name of the device.  

__Returns:__
  - ax -> A member of the DevicePresent enumerated type.
  - CF -> Set if ax = DP_INVALID_DEVICE , clear otherwise.

__Tips & Tricks:__
  - The EnumerateDevice macro is useful for checking if the string is the
name of a supported device. You may use the returned table index to
reference another table of test routines.

___
+ ``DRE_SET_DEVICE``  
This function informs the driver which of its devices it is to support.

__Pass:__
  - di -> DRE_SET_DEVICE (= 10).
  - dx:si -> Pointer to a null-terminated string containing the name of the device.

__Returns:__ 
  - Nothing.

__Destroyed:__
  - Allowed to destroy di.

__Tips & Tricks:__
  - The EnumerateDevice macro is useful for checking if the string is the
name of a supported device. You may use the returned table index to
reference another table of test routines.

___
+ ``EnumerateDevice``  
``EnumerateDevice <infoRes>``  
This macro checks if a string contains the name of a device supported by the
driver. If it does, the macro locks the resource containing the driver’s extended information.

__Pass:__
  - infoRes -> Name of the resource containing the driver’s extended information.
  - dx:si -> Pointer to null-terminated string containing name of device.

__Returns:__
  - CF -> Clear if passed string matches name of device supported by
the driver; set otherwise.
  - ax -> If CF is set, ax contains DP_INVALID_DEVICE ; otherwise, ax
is destroyed.
  - bx -> Handle of resource containing extended information.
  - es -> If CF is clear, es contains segment address of locked block
containing extended information; otherwise, es is destroyed.
  - di -> If CF is clear, di contains the device’s place in the driver’s
information table. The first device has a “place” of zero, the
next device is two, the next is four, etc.
If CF is set, di is destroyed.

__Destroyed:__
  - cx, ds

__Warning:__ 
  - If the macro succeeds in matching the string to a device, it will lock the block
containing the driver’s extended information and return the block’s segment
address in es. Be sure to unlock this block when you’re done with it.

#### 1.2.5 Escape Codes

``DriverEscCode``  
Some kinds of drivers may be passed escape codes. An escape code is passed
to the strategy routine in di, just like a function code. All escape codes have
the sign bit set; they can thus be easily distinguished from other function
codes, which have the sign bit cleared.
~~~
etype word, 8000h, 1
~~~
How a driver responds to an escape code depends on what kind of device the
driver controls. Each kind of device has its own conventions for handling
escape sequences, if it handles them at all.
