.if n \{\
.ds [. \f1\s-2\u
.ds .] \d\s+2\fP
'\}
'\"
'\" xH is a macro to provide numbered headers that are automatically stuffed
'\" into a table-of-contents, properly indented, etc. If the first argument
'\" is numeric, it is taken as the depth for numbering (as for .NH), else
'\" the default (1) is assumed.
'\"
'\" @P The initial paragraph distance.
'\" @Q The piece of section number to increment (or 0 if none given)
'\" @R Section header.
'\" @S Indent for toc entry
'\" @T Argument to NH (can't use @Q b/c giving 0 to NH resets the counter)
.de xH
.nr @Q 0
.ds @T
'\" This stuff exercises a bug in nroff. It used to read
'\" .ie \\$1, but if $1 was non-numeric, nroff would process the
'\" commands after the first in the true body, as well as the
'\" false body. Why, I don't know. The bit with @U is a kludge, and
'\" the initial assignment of 0 is necessary
.nr @U 0
.nr @U \\$1
.ie \\n(@U>0  \{\
.	nr @Q \\$1
.	ds @T \\$1
.	ds @R \\$2 \\$3 \\$4 \\$5 \\$6 \\$7 \\$8 \\$9
'\}
.el .ds @R \\$1 \\$2 \\$3 \\$4 \\$5 \\$6 \\$7 \\$8 \\$9
.nr @S (\\n(@Q-1)*5
.nr @P \\n(PD
.ie \\n(@S==-5 .nr @S 0
.el .nr PD 0
.NH \\*(@T
\\*(@R
.XS \\n(PN \\n(@S
\\*(SN \\*(@R
.XE
.nr PD \\n(@P
..
'\"
.de Bp
.ie !\\n(.$ .IP \(bu 2
.el .IP "\&" 2
..
'\"
.po .8i
.nr PO .8i
.ll 6.5i
.nr LL 6.5i
'\"
.de sw
.ie t \fBSwat\fP\\$1
.el \fBSwat\fP\\$1
..
'\"
.de c4
.ie t \s-2Com43\s0\\$1
.el \fBCom43\fP\\$1
..
.ds LF DRAFT
.ds RF DRAFT
.am GS
.ds gT \\$2
..
.de GE
.ls
.in
.if \\n(g7 .fi
.if !\\*(gT \{\
.	ft B
.	ps +2
.	sp .25i
.	ce
\&\\*(gT
.	ft
.	ps
\}
.if t .sp .6
..
.TL
Swat's PC-Resident Stub
.AU
Adam de Boor
.AI
Berkeley Softworks
2150 Shattuck Ave, Penthouse
Berkeley, CA 94704
Near the copy room
.AB
This document describes the workings of the stub
.sw
uses to decode and monitor the state of the system. It was written
based on the current version of the stub, which runs in low memory
and uses a single serial line for communication.
.AE
.xH Introduction
.PP
In order to debug OS/90 and its applications,
.sw
employs a stub, running on the PC, as a sort of agent by which it
decodes, modifies and monitors the state of the system.
.PP
The responsibilities of the stub are many:
.RS
.Bp
Report the state of the machine when it stops.
.Bp
Continue the machine in several different manners:
.RS
.Bp
single step: execute an instruction and report new register/thread state.
.Bp
single step, install breakpoint, and continue. Used to skip over an active
breakpoint.
.Bp
continue the machine w/ or w/o timer interrupt enabled.
.RE
.Bp
Report state changes in memory blocks.
.Bp
Report state changes in threads/processes/libraries/drivers.
.Bp
Return necessary info for given handle, or for handle covering a
given address.
.Bp
Read/Write/Fill memory, either in a handle-relative manner, or at
an absolute address. If handle-relative and the block is swapped,
causes the kernel to bring the block in from where ever it's stored.
.Bp
Return the complete state of the system when initially contacted.
.Bp
Read/Write registers for any thread, when possible.
.Bp
Cause the system to exit.
.Bp
Stop the machine at any point.
.Bp
Provide for the interception of all 256 interrupts.
.Bp
Mask out certain interrupts while the machine is stopped.
.Bp
Handle simple conditional breakpoints.
.RE
.LP
Most of these things, and the actions the OS/90 kernel takes to
facilitate them, are described in later sections.
.PP
The stub communicates with 
.sw
over a serial line using a Remote Procedure Call (RPC) model. Briefly,
a remote procedure call acts like a regular procedure call \*- the
procedure is passed arguments and returns results and the calling
procedure doesn't continue executing until the called procedure
returns those results \*- but can be executing somewhere other than
the calling procedure...a different processor, a different machine, whatever.
.PP
In a full-blown RPC system, the machine doing the calling (the client)
has what's known as a stub procedure that looks like the real thing,
but whose responsibility is to package the arguments up in some
fashion and send them to the real procedure. The called procedure (the
server) has a similar stub procedure that takes the packaged
arguments, unpackages them and performs the call on the real
procedure, packaging up the results and sending them back, where the
client's stub unpackages them and returns them as if it had actually
done the work. The important point is that neither the calling
procedure nor the remote one knows anything about the remote call.
As far as the caller is concerned, the procedure it calls is the one
that's doing the work. As for the procedure that's called on the
remote machine, it thinks the call originated locally.
This gives us a model like figure 1.
.GS C "Figure 1"
pointscale on
height 3i
file rpc.g
.GE
.LP
The ``Data Link'' labeled in the figure can be pretty much anything.
Typically, it's a network. In
.sw 's
case, it's a serial line.
.PP
But who said
.sw
uses a full-blown RPC system? Actually, all the parts of
.sw
that participate in the communication are well aware of the existence of
the RPC system, though that is likely to change as the MPDE develops.
But enough about RPC systems. On to the stub itself.
.NH
Internal Organization
.PP
The stub's code is organized into five modules:
.RS
.Bp
The entry point and interrupt support code.
.Bp
The interface between the kernel and the stub.
.Bp
The stub's RPC system and server procedures that don't directly
interact with the the kernel or its data structures.
.Bp
The communications function by which the RPC system accesses the data link.
.Bp
The managing of fast conditional breakpoints.
.RE
.LP
By far the largest module is the interface to the kernel. The
individual pieces are described in later pieces, but certain general
information needs to be imparted now.
.xH 2 "What Happens When the Machine Stops"
.PP
There are two things the stub must do whenever it stops the operation
of the OS/90 system: (1) save the current system state and (2) notify
.sw
that the machine has stopped and why and in what state it is at the time.
.PP
The current state is saved in a state block on the stub's own stack.
It uses its own stack to avoid altering the system's state in any way
(in the case of intercepted interrupts, it has no choice but to use 3
words \*- for CS, IP and the flags \*- on the current stack). The
state block contains all the registers at the time of the stop, the
thread that was running, and the masks from the two (one on a base PC)
interrupt controllers. Once the state is saved, the stub's own context
is brought in.
.PP
In order to maintain control of the machine, part of the context is
new masks for the interrupt controllers. Two invariants, as far as
these masks go, are that the timer interrupt is always disabled (to
avoid a forced context switch in the timer interrupt code) and the
interrupt for the stub's serial line is always enabled. Beyond that,
the bits masked depend on what
.sw
has told it to mask and on what interrupts were in service when the
switch to the stub's context was made.
.PP
This last is required because the stub places the 8259 in a mode known
as the Special Mask Mode. The mode itself has the useful property of
breaking down the priority structure the controller normally
maintains (only higher-priority interrupts allowed to come in
while an interrupt is being serviced). While this makes for a nicely
controlled environment, ensuring that vital interrupts (e.g.  the
timer interrupt) can come in no matter what's running while less
important or demanding interrupts (as from a printer) can be
serviced when it's convenient, it has the unfortunate effect of making
it impossible to debug any interrupt code whose interrupt is at a
higher priority than that enjoyed by the serial line the stub is
using.
.PP
Special Mask Mode bases its decision of when to transmit an interrupt
to the processor solely on the state of the mask flags \*- if the flag
is 0 and an interrupt at that level is pending, it gets sent to the
processor. This allows you to set a breakpoint in the keyboard
interrupt code without the stub freezing up. There is a down side,
however, in that most drivers for MS-DOS don't expect the controller
to be in this state.
.PP
Back up a moment. Since the controller doesn't process the IRET
instruction for the interrupt it has delivered, the interrupt code
must somehow explicitly acknowledge the completion of the interrupt so
the controller can know to allow another interrupt at that (or a
lower) level to come in. Normally, this is done by issuing a
``non-specific'' end-of-interrupt command to the controller. It's
called ``non-specific'' because it conveys no information as to the
level of interrupt that is at an end. In the normal case, since the
interrupt hierarchy is strictly maintained, all the controller has to
do is clear the in-service flag for the highest-priority interrupt
that's currently in-service, since that's the only thing that could
possibly be running (think about it).
.PP
In Special Mask Mode, however, the hierarchy is gone, so the
controller has no idea what flag to clear when it's given the
non-specific end-of-interrupt command. As a result, it clears nothing.
Bad choice. The problem has shown up mostly in mouse drivers, which
tend to interrupt while the stub is doing some processing. The problem
is, when the mouse driver issues its end-of-interrupt, nothing
happens, so control comes back to the stub and no further interrupts
from the mouse are recognized, since the last one is still
``in-service,'' as far as the controller is concerned.
.PP
There is a way out however, a way out that is practised by all the
interrupt-driven drivers currently in OS/90. This escape hatch is
provided by the ``specific'' end-of-interrupt command, which encodes
the level of interrupt for which the end is being declared. This takes
more work on the part of the interrupt handler and supporting code,
but it keeps the device from freezing up, so it's well worth it.
.PP
Anyway, because the controller bases its decision solely on the mask
flags, if there's a breakpoint in an interrupt routine, and the device
is still asserting its interrupt request (the handler has yet to
acknowledge the interrupt to the device), then if that interrupt
weren't masked off by the stub, the interrupt would be taken again,
which wouldn't be good. In normal mode, of course, this problem
doesn't occur, since the controller refuses to deal with interrupts at
the same or lower priority. This, then, is the reason why the stub
loads the controller register with a mask consisting of those
interrupts that
.sw
has told it are to be masked, and those that are currently in-service.
.PP
All this saving and restoring of state is taken care of by two
functions named, no surprise,
.B SaveState
and
.B RestoreState .
The former expects SS:SP to point to a three-word FLAGS:CS:IP frame,
as produced by an interrupt (several functions in the kernel interface
manufacture this frame, but that's something for later.\|.\|.\|),
while the latter produces such a frame in the same place. All returns
to normal operation, therefore, are accomplished via an IRET instruction.
.PP
An important aspect of these two functions is that they work together
to allow the stub to be re-entrant. The stub's stack can hold more
than a single state block (and the call depth for the stub rarely
exceeds four levels). Unlike DOS and BIOS, although the stub switches
to its own stack when switching to its own context, the SP it uses is
not static. Rather, it is kept in the variable
.B last_SP ,
which is updated by
.B RestoreState
after all registers have been restored.
.B SaveState ,
in its turn, places the state block just below this address each time,
with the result that if the stub is re-entered after having been
interrupted (e.g. if there's a breakpoint in the mouse interrupt
handler and interrupts from the mouse are enabled), the new state
block will be placed just below the old (with whatever return
addresses, etc., may have been pushed between the two). Since the
stub's stack is of a limited size (256 bytes, as of this writing),
this process cannot continue for ever, but it is sufficient to allow
me, e.g., to use the stub to single-step and debug itself.
.xH 2 "Other Interrupt Support Code"
.PP
As noted before, one of the facilities the stub provides is the
ability to intercept any of the possible 256 interrupts. By default, whenever
.sw
has attached the system, the stub intercepts the following interrupts:
.DS B
.ta \w'Number  'u
Number	Name
0	Divide by zero
1	Single step complete/debug trap
2	Non-maskable interrupt
3	Software breakpoint
4	Overflow interrupt
5	Bound error
6	Illegal instruction
7	Coprocessor absent
10	Invalid task-state segment
13	General protection fault (unless using bus mouse)
.DE
.LP
Several other of the interrupts below 16 have meaning to the 80286
processor, but they interfere with PC device interrupts (thanks, IBM),
so they are allowed to go by.
.PP
The actual interceptors are laid out in a 2Kb table beginning at
.B InterruptHandlers .
Each entry in the table contains 8 bytes, the first three of which are
a near call to the function
.B IRQCommon .
The next byte is the interrupt number, with the previous handler for
the interrupt following in the final four bytes.
.PP
.B IRQCommon ,
as you can probably tell, is the common code for interrupt requests.
It pops its return address off the stack and uses it to locate the
reason for the stop (since the return address points to the interrupt
number so carefully stored in the table). It then calls
.B SaveState
to switch into the proper context. Once it's in the stub context, it
builds out an
.B RPC_HALT
message to be delivered to
.sw .
On the way, if the halt was caused by an INT 3 instruction, it
contacts the conditional breakpoint module to see if it should really
stop the machine. Once the decision has been made to keep the machine
stopped, the message is sent to
.sw
and the stub enters a polling mode upon receipt of the reply message.
The continuation of the machine occurs only when an explicit ``continue''
message is received.
.PP
One additional service performed by 
.B IRQCommon
when an INT 3 trap occurs is the decrementing of the IP stored in the
state block and sent up to
.sw .
This prevents
.sw
from having to write all the registers back to the PC when it's done
dealing with the breakpoint (since the registers will have been
dirtied by the need to decrement IP in order to skip over the
breakpoint), thus speeding the execution of slow conditional
breakpoints substantially (more than 16 ms).
.xH 2 "Kernel \o'\(<-\(->' Stub Interface"
.PP
To allow
.sw
to truly debug the entire system, the state of the system must be
monitored fairly closely. Rather than have the stub place appropriate
breakpoints at points in the code where state changes occur, plucking
the info it needed from the registers and variables, we decided to lay
the burden of notification on the kernel itself. This was mostly to
avoid the logistical and bug-prone nightmare that maintaining the
breakpoint locations would have been.
.PP
The interface to the stub is thus a set of three ``procedures'' in the
kernel.  In order to deal with bugs that only show up in a
non-error-checking version of the kernel, the procedures and the calls
to them are always present. For this reason, the procedures are near
functions that are each five bytes long. When
.sw
is not attached, the procedures consist of only an immediate near
return, allowing for the minimum overhead (as opposed to having the
various parts of the kernel calling through a far pointer vector, as
might seem the logical choice). When
.sw
is attached, however, the stub places a far jump to its three routines
in these procedures. Since the stub knows where it loaded the kernel,
the lack of a segment in the return address poses no problems.
.PP
Two of the three calls deal with state changes in memory blocks:
.B DebugLoadResource
and
.B DebugMemory .
Each memory handle has a bit (\fBHF_DEBUG\fP) in its
.B Han_flags
byte that is dedicated to the stub for its own use. Regardless of
the state of the bit, the kernel will call these two functions. The
stub, however, uses the bit to tell if
.sw
is interested in knowing of changes to the block \*- if the bit is
clear, there's no need to tell
.sw
of the change, thus saving the round-trip time that is required for
the RPC. The bit itself is set and cleared using the
.B RPC_ATTACH_MEM
and
.B RPC_DETACH_MEM
calls, respectively. This is under
.sw 's
control, however; the stub never sets the bit of its own volition,
though the
.B HF_DEBUG
bits for all known handles are cleared whenever
.sw
attaches to or detaches from the system (in order to avoid sending
unwanted notifications).
.PP
The third procedure monitors the state of threads, processes,
libraries and drivers in the system and is described below.
.xH 3 DebugMemory
.PP
This is the procedure called by the kernel for most changes to memory
blocks. It is passed several things in registers: 
.RS
.IP AL
Contains a code indicating the type of change. The possibilities are:
.TS
tab(&) ;
l l l s.
Code&RPC Number&Description
_
DEBUG_REALLOC&RPC_BLOCK_REALLOC&Block resized and moved
DEBUG_DISCARD&RPC_BLOCK_OUT&Block discarded (data thrown away)
DEBUG_SWAPOUT&RPC_BLOCK_OUT&Block swapped out (to disk or extended memory)
DEBUG_SWAPIN&RPC_BLOCK_IN&Block brought back in from backing store
DEBUG_MOVE&RPC_BLOCK_MOVE&Block's data shifted in memory
DEBUG_FREE&RPC_BLOCK_FREE&Block and handle freed
DEBUG_MODIFY&none&The block's flags/owner changed.
.TE
.IP BX
Contains the ID of the affected handle.
.IP DS
Points to the kernel's data segment. This is only to allow a quick
test of the
.B HF_DEBUG
bit to avoid the overhead of saving and restoring the current state
for ``uninteresting'' state changes.
.RE
.PP
Each of the possible function codes is mapped to its own remote
procedure number (save for DEBUG_DISCARD and DEBUG_SWAPOUT which share
the RPC_BLOCK_OUT call) and the data
.sw
will need to process the RPC is stored in the
.B rpc_ToHost
variable for transmission to
.sw .
Once a reply to the RPC is received, meaning that whatever action
.sw
needed to take in reaction to the state change (e.g. the re-setting of
a breakpoint) has been taken,
the stub returns to the kernel.
.PP
A special case to the test for the
.B HF_DEBUG
flag is made for any kernel handles (any handle with an ID of 16
or lower), since they don't have a real handle structure that the stub
could consult to determine if
.sw
is to be notified. There are three circumstances under which the stub will
be passed a kernel handle ID:
.RS
.IP (1)
At the beginning of the boot procedure, all the kernel initialization
code is moved up to high memory.
.B BootGeos
calls
.B DebugMemory
with the new address of the initialization code, saying that handle
``2'' (\c
.sw 's
designation for the
.B kinit
segment) has moved to the given address.
.IP (2)
Similarly, when initialization is complete, the kernel calls
.B DebugMemory
to tell it that handle ``2'' has been discarded.
.IP (3)
When the handle table is initialized, the kernel's data segment
(handle ID ``16'') is ``enlarged,'' with a corresponding call to 
.B DebugMemory ,
function code
.B DEBUG_REALLOC .
.RE
.xH 3 DebugLoadResource
.PP
This procedure is called by the kernel whenever a block that had been
discarded is brought into memory from its file. This is a separate
procedure because of the peculiar things the stub must do to make sure
the world is consistent for
.sw .
The problem is that, when this procedure is called, the handle's
address hasn't yet been stored into the handle (the kernel isn't ready
to tell the world it can lock the block down). However, the writing of
memory in a handle-relative way (as is required by the setting of
breakpoints, a typical action for
.sw
to take upon learning that a code resource has been loaded) requires
the address field of the handle to point to its data. To this end, the
stub temporarily stores the new address into the handle before making the
.B RPC_RES_LOAD
call to
.sw ,
after which it restores the address field to what it was before (this
restoration relies on the way the
.B RPC_CONTINUE
procedure is handled, but more on that when I describe the RPC system
in detail).
.PP
The parameters the kernel passes to the stub are:
.RS
.IP BX
Handle whose data were just loaded in and relocated.
.IP AX
Segment address at which the data are located
.IP ES
Kernel's data segment (for testing
.B HF_DEBUG )
.RE
.xH 3 DebugProcess
.PP
.B DebugProcess
might better be called ``DebugMisc'' as it isn't limited to just
process changes. It is called in any of the following circumstances:
.RS
.Bp
A thread is created or exits.
.Bp
A driver is loaded or discarded.
.Bp
A library is loaded or discarded.
.Bp
A process (as distinct from a thread) exits.
.RE
.LP
As for
.B DebugMemory ,
AL contains a function code upon entry to this procedure. Other
registers contain various things, depending on the function code.
Unlike
.B DebugMemory ,
however, the call is always passed on to
.sw .
The codes and their respective arguments and RPC's are as follows.
.SH
DEBUG_EXIT_THREAD and DEBUG_EXIT_PROC
.PP
Passed the handle of the dead thread in BX and the thread's exit
status (if DEBUG_EXIT_PROC) in DX, invokes the
.B RPC_DEATH
procedure in
.sw ,
passing it the contents of BX and DX, even though DX is undefined for
DEBUG_EXIT_THREAD.
The processing for the two types of exit is similar enough to make
this worthwhile.
.sw
is able to tell the difference between a random thread exiting and the
final thread for a process exiting and discards the passed DX in the
former case. The kernel guarantees that the passed thread handle will
not be referenced after the call. 
.SH
DEBUG_CREATE_THREAD
.PP
Passed the handle of the new thread in BX and the kernel's data
segment in DS, invokes the
.B RPC_SPAWN
procedure in
.sw ,
passing it the new thread handle, the owner of the thread, and the
SS:SP for the new thread as arguments. These last three arguments are
extracted from the thread handle itself. If the new thread is a
process's main thread, the passed SS will be 0 (that's what the kernel
stores in the handle). SP is ignored in this case.
.SH
DEBUG_LOAD_DRIVER or DEBUG_LOAD_LIBRARY
.PP
Passed the segment of the driver/library's core block in DS, invokes the
.B RPC_SPAWN
procedure in
.sw ,
passing it the handle for the thing (as gotten from DS:0) as the owner
and the current thread as the ``new thread'' handle. Both SS and SP
are passed as 0 (this is how
.sw
knows it's a driver/library being loaded).
.SH
DEBUG_EXIT_DRIVER or DEBUG_EXIT_LIBRARY
.PP
Passed the segment of the driver/library's core block in DS, invokes the
.B RPC_DEATH
procedure in
.sw ,
passing it the handle for the thing (as gotten from DS:0) as the
thread handle, and the current thread as the exit status. In the case of
.B DEBUG_EXIT_DRIVER ,
the low bit of the ``thread handle'' will be set.
.sw
figures the difference between a thread exiting and a driver/library
exiting by examining the kind of handle passed as the thread.
.br
.TC
