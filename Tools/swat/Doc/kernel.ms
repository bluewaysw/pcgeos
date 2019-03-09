'\"
'\" This file contains the specification for the PC-side of the
'\" application debugger.
'\"
.po .5i
.nr PO .5i
.ll 7i
.nr LL 7i
.de Bp
.IP \(bu 2
..
.TL
Swat\o'\(<-\(->'PC Interface
.AU
Adam de Boor
.AB
This document describes the burdens placed on PCGEOS and any hardware
card we produce. It describes my design goals and a possible
implementation of them.
.AE
.NH
Introduction
.PP
I have had three goals in mind during the design of this interface:
.RS
.IP 1)
It should be as simple as possible so it is easy to debug and we can
be sure of its reliability and correctness.
.IP 2)
It should be usable by the application debugger that will run under
PCGEOS itself, so we don't have to rewrite it.
.IP 3)
It should be possible to debug the kernel using the same interface.
.RE
.PP
The interface for the UNIX-based debugger is split into two parts:
those that are in the PCGEOS kernel and those that are in
write-protected memory on a separate card. The functions in the former
class are those that are process-specific. The tracking of module
loading and heap block motion is an example of such functions. Those
in protected memory are for the access of memory and registers and the
like \*- functions that must be protected from a misbehaving
application (or kernel) to allow the system to be debugged even if the
kernel has been trashed.
.PP
The idea behind this separation is to keep knowledge of kernel
structures in the kernel and in the host-resident code, which is
written in C and in RAM and thus much easier to change in the event of
a kernel change.
.NH
In the Kernel
.PP
There are several events in the life of a process that are of
importance to a debugger and that are under kernel control. These
events are as follows:
.RS
.Bp
\fIThe loading of modules.\fP The debugger needs to
keep its map of the location of modules up-to-date so it can properly
map addresses to symbols and vice versa. The kernel's loader should
probably not install the kernel call addresses, since the debugger
will just have to overwrite them again anyway.
.Bp
\fIThe swapping and discarding of marked heap blocks.\fP\**
.FS
The marking can be accomplished by compressing the discardable,
swapable, discarded and swapped flag bits into three bits: resident
(set if block in memory), discard (if resident: discardable; if
non-resident: discarded), and swap (likewise). This frees one bit to be
used for a notify flag.
.FE
This is related to the loading and discarding of modules, but applies
to data blocks, and while the debugger must know about the loading and
discarding of all modules in the application, it need only know about
those heap blocks in which it has placed a hardware breakpoint (so the
breakpoint can be removed or moved when the block shifts to disk or in
memory).
.Bp
\fIThe spawning of a new thread.\fP For the debugger to manage
multiple threads of an application, it must know when a new one is
created.
.Bp
\fIThe termination of a thread or application.\fP The need for this is
obvious.
.RE
.LP
All of these events must result in a message being sent to the
debugger so it can take appropriate action. A thread is marked as
requiring this special attention by means of the low bit of the handle
signature byte. Threads will have this clear unless they are being
debugged.
.PP
Notification takes the form of a far call to a well-known location
with three parameters:
.RS
.Bp
The type of message (module in, module out, block in, block out, block
move, thread spawn, thread death, application death).
.Bp
Two words of data for the message. For module in and out, the module
number is the first word and the segment at which the module is being
loaded is the second. For block out, the first word is the handle,
while the second is non-zero if the block was discarded and zero if it
was swapped. For block in and move, the first word is the block
handle, while the second is the new segment address for the block.
For thread spawn, the first word is the handle of the new thread and
the second is that for the original.  For thread and application
death, the first is the handle of the dying thread/application. The
second is the exit code.
.RE
.PP
All other functions required by the debugger can be performed by
executing regular kernel calls from the installed card.
.NH
Card Play
.PP
The role of the debugger card is somewhat more difficult. In this
card, there must be code to:
.RS
.Bp
Install, remove and handle single-steps, hardware and software breakpoints,
where "handle" simply involves stopping the operating system in its
track and sending a message to the debugger.
.Bp
Handle a UART for serial transmission driven by interrupts (to allow
the debugger to halt the system without the user having to push a
button). The prefered speed for this UART is 19.2 Kbaud, though 9600
is acceptable.
.Bp
Read and write all parts of memory and I/O space. This implies that
should PC GEOS ever make use of the 286 and 386 protected modes, this
code will have to run at the highest privilege.
.Bp
Handle message calls from the kernel, as described above, by
delivering the message "offline" (i.e. it should not loop until the
characters are sent) thus allowing the kernel to continue as soon as possible.
.Bp
Read and write processor registers.
.Bp
Perform kernel calls on behalf of the debugger. The debugger itself is
responsible for making sure the kernel is in a state where the call
may be made as well as for fetching the results of the call, if any.
It might be easiest for Dispatch to check a flag and take a breakpoint
if the flag is set, thus allowing the debugger an easy way to make
sure the kernel is in a consistent state.
.RE
.PP
If I can figure out what the atron software is doing and how it is
manipulating the board, we can make use of it and its 1 Mb of on-board
RAM. If not...
.NH
Communications
.PP
All contact between the debugger and the PC is by means of a serial
line, to which the debugging stub described in section 3 is attached.
The protocol used is a simple RPC protocol. Each message contains a a
procedure number, the size of parameters being passed and the
parameters themselves. Each reply contains a status code, the number
of bytes of reply data and the reply data itself. The procedures,
their parameters and expected return values are given in the
following sections.
.PP
All integers (registers, eg.) are sent in the PC's byte-order and must
be swapped by the debugger if its byte order isn't little-endian.
.PP
The serial line is treated as a reliable delivery mechanism (i.e.
there are no acknowledgement messages for calls that expect no return
values and there are no retransmissions. This may need to change if I
find the lines aren't as reliable as I thought).
.NH 2
Breakpoint
.PP
Sent from the PC to the host when an INT 3 instruction is executed.
Pass all registers. Expects no reply.  The registers are passed so
expressions can be evaluated without the debugger having to specially
request them.
.NH 2
StepDone
.PP
Sent from the PC when a single-step trap is taken (interrupt level 2).
Passes the CS and IP of the fault. Expects no reply. The registers are
not passed since it is unlikely they will be needed.
.NH 2
Halt
.PP
Sent from the PC when some other fault is taken. Passes the CS and IP
of the fault. Expects no reply.
.NH 2
SysCall
.PP
Sent from the PC when any thread performs a system call. Passes the CS
and IP and thread handle of the running thread. Expects no reply.
.NH 2
ReadRegisters
.PP
Sent from the host. Passes nothing. Expects block of all registers in
reply. The registers are sent in a block because the overhead of
reading a few more bytes is nowhere near as significant as that
associated with the system calls and multiple messages needed to read
a register at a time.
.NH 2
WriteRegisters
.PP
Sent from the host. Passes a block of all the registers. Expects
nothing in reply.
.NH 2
ReadMemory
.PP
Sent from the host. Passes the segment, offset and number of bytes
desired. Multiple replies are used if more than 512 bytes are
requested. All replies save the last must contain 512 bytes. A single
ACK byte is sent from the host after each reply save the last.
.NH 2
WriteMemory
.PP
Sent from the host. Passes the segment, offset, number of bytes and
the bytes themselves. No more than 512 bytes will be written at a
time. Expects a zero-length reply (i.e. a status byte followed by two
bytes of 0).
.NH 2
Continue
.PP
Sent from the host. Instructs the PC to continue from the saved CS:IP.
Expects no reply.
.NH 2
ContinueFrom
.PP
Sent from the host after a SysCall message is received. Passes the CS
and IP to which control should go. All other registers should be
restored from wherever the PC saved them. This avoids the need to
read and write all registers on each system call. Expects no reply.
.NH 2
SingleStep
.PP
Sent from the host. The PC should execute a single instruction at the
saved CS:IP. Passes nothing and expects no reply.
.NH 2
ModuleLoad
.PP
Sent from the PC. Passes the module number and segment address of the
newly-loaded module. Expects no reply. The machine remains halted.
.NH 2
BlockLoad
.PP
Sent from the PC when a marked block is swapped into memory. Passes
the block's handle and the segment address of the block. Expects no
reply, but the PC must be continued by the debugger.
.NH 2
BlockMove
.PP
Sent from the PC when a marked block is relocated on the heap. Passes
the block's handle and the segment address of the block. Expects no
reply. The PC remains halted.
.NH 2
BlockOut
.PP
Sent from the PC when a marked block is discarded. Passes the block's handle.
and a byte that is non-zero if the block was discarded. Expects no
reply. The debugger must continue the machine.
.NH 2
Spawn
.PP
Sent from the PC when a thread spawns a new thread. Passes the old and
new thread handles. Expects no reply. The PC remains halted until
continued by the debugger.
.NH 2
ApplDeath
.PP
Sent from the PC when the application finishes. Passes the
application's main thread's handle and the application's termination
code. Expects no reply. PC remains halted.
.NH 2
ThreadDeath
.PP
Sent from the PC when a thread terminates. Passes the thread handle
and the thread's termination code. Expects no reply. PC stays halted.
.NH
Miscellaneous
.PP
Random thoughts and implementation notes based on this spec.
.IP 1)
The timer interrupt should be disabled whenever the machine is halted to avoid
the time spent in the stub being charged to the application being
debugged and resultant context switch when the thread is continued.
.IP 2)
The debugger must replace the kernel calls in a newly-loaded
application with calls to a routine in the stub that will deliver the
SysCall message so it has a record of the next instruction in the
application to be executed once the system call is complete.
