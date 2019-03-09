.de xH
.nr @Q 0
.ds @T
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
.if \\n(@S==-5 .nr @S 0
.nr PD 0
.NH \\*(@T
\\*(@R
.XS \\n(PN \\n(@S
\\*(SN \\*(@R
.XE
.nr PD \\n(@P
..
.RP
.TL
Swat -- Command/Variable Documentation
.AU
Adam de Boor
.AI
Berkeley Softworks
2150 Shattuck Ave, Penthouse
Berkeley, CA 94704
.AB
This is a formatted version of Swat's documentation file. As such, it is
rather terse and sometimes obscure.
.AE
'\"
'\"	ABORT
'\"
.xH "abort (obscure)"
.LP
Dumps core (DEBUGGING ONLY)
'\"
'\"	ADDR-PARSE
'\"
.xH "addr-parse (prog)"
.LP
Parses the address expression given as its sole argument into its
components, returning a list {\fIhandle\fP \fIoffset\fP \fItype\fP} where \fIhandle\fP is
a handle token, as returned by the "handle" command, \fIoffset\fP is a decimal
number, and \fItype\fP is a type token, as returned by "type". Returns nil if
there's an error in the expression.
'\"
'\"	ALIAS
'\"
.xH "alias (top)"
.LP
Causes the first argument to execute the second and succeeding
arguments. The pseudo-variables $1, $2, ..., $n may be used to
interpolate the 1st, 2nd, ..., nth argument to the alias. $n-m will
interpolate arguments n through m. If m is missing, all arguments from
n to the end will be interpolated. $* will interpolate all the
arguments, while $# will interpolate the actual number of arguments.
This substitution only occurs in the alias itself, not within any
procedures the alias calls. If you don't use any of the $n constructs,
all the arguments will be appended to the resulting command before it
is executed.
'\"
'\"	ALIGNFIELDS
'\"
.xH "alignFields (variable.output)"
.LP
If non-zero, the values for all fields in a structure will be lined up when
printed, making it easier to scan them
'\"
'\"	ALLOC
'\"
.xH "alloc (obscure)"
.LP
Prints Swat's memory allocation statistics to the file given as the first
argument.
'\"
'\"	ASET
'\"
.xH "aset (prog.lisp)"
.LP
Sets an element of an array (list). First arg \fIarray\fP is the name of the
array variable. Second arg \fIind\fP is the index at which to store (0-origin), and
third arg \fIval\fP is the value to put there.
'\"
'\"	ASSIGN
'\"
.xH "assign (memory|prog.memory)"
.LP
Performs an assignment to a patient variable or register. The first
argument is the variable or register to be assigned and the second
argument is the value to assign to it (which may be a regular address
expression). If the first expression doesn't indicate a type, "word"
is assumed. Only byte, word or dword types are supported
'\"
'\"	ASSOC
'\"
.xH "assoc (prog.list|prog.lisp)"
.LP
Given a \fIlist\fP of the form {{\fIkey\fP \fIval\fP} {\fIkey\fP \fIval\fP} ...} and a \fIkey\fP for which to
search, returns the {\fIkey\fP \fIval\fP} element whose \fIkey\fP matches the given one. If no
such element, returns nil. The name derives from the list being an
"associative" list, associating a key with a value.
'\"
'\"	ATTACH
'\"
.xH "attach (top)"
.LP
Re-attach to the PC. If any geode has changed since you detached from
the PC, the symbols for it are re-read.
'\"
'\"	AUTOLOAD
'\"
.xH "autoload (prog.load|prog.file)"
.LP
This command allows the first invocation of a command to automatically
force the transparent reading of a file of TCL commands. It takes 3 or 5
arguments -- the command, an integer telling if the command needs to be
typed exactly as given to be invoked, the file that should be read to define
the command (this should probably be absolute) and an optional documentation
class and string for the command. This need only be given if the file being
loaded isn't part of the system library (doesn't have its documentation
strings extracted when Swat is build).
'\"
'\"	BACKTRACE
'\"
.xH "backtrace (stack|top)"
.LP
Print all active stack frames for the patient. If an argument is given, it is
the number of frames to print.
'\"
'\"	BEEP
'\"
.xH "beep (prog.output)"
.LP
Alert the user to something. If the terminal supports a visible bell, does
that. Otherwise uses an audible one.
'\"
'\"	BREAK-TAKEN
'\"
.xH "break-taken (prog.breakpoint)"
.LP
Returns 1 if the patient stopped because of a breakpoint and 0 otherwise.
If an argument is given, it is taken to be the desired value of the
breakpoint-taken flag.
'\"
'\"	BREAK
'\"
.xH "break (prog.tcl.loop|top)"
.LP
break out of current loop or interpreter
'\"
'\"	BRK
'\"
.xH "brk (top|breakpoint|prog.breakpoint)"
.LP
Allows the user to set breakpoints in the patient. It accepts several
subcommands:
.IP "set \fIaddr\fP \fIcommand\fP
Sets a breakpoint at the given address to execute the given TCL
command(s). \fIcommand\fP is passed straight to "eval". Before it is
evaluated, the variable "breakpoint" is set to the name of the
breakpoint being taken. If no \fIcommand\fP is given, the breakpoint
is always taken. Otherwise, the machine stops only if the result
of the command is non-zero. The breakpoint will only stop threads
belonging to the current patient. A breakpoint is identified by a
string of the form "brk\fIn\fP", where \fIn\fP is an unique integer.
.IP "aset \fIaddr\fP \fIcommand\fP
Like "set", but the breakpoint is set for all threads.
.IP "tset \fIaddr\fP \fIcommand\fP
Like "set", but the breakpoint is removed the next time the machine
stops.
.IP "clear \fIbreak\fP*
Removes the given breakpoint(s). If no breakpoint is given, clears
all breakpoints for the current patient. Asks for confirmation
before doing so.
.IP "enable \fIbreak\fP*
Enables the given breakpoint(s). If it is already enabled, this has
no effect. If no breakpoint is given, all breakpoints for the current
patient are enabled.
.IP "disable \fIbreak\fP*
Disable the given breakpoint(s). Has no effect if already disabled.
If no breakpoint is given, disables all breakpoints for the current
patient.
.IP "address \fIbreak\fP
Returns the address at which the given breakpoint was set
.IP "list [\fIaddr\fP]
Lists all breakpoints, where they are set and if they are enabled.
If \fIaddr\fP is given, returns the numbers of all breakpoints set at
the given address.
.IP "isset \fIaddr\fP
Returns non-zero if a breakpoint is set at the given address.
.IP "cond \fIbreak\fP [\fIcriteria\fP]
Adds/changes/deletes the criteria for the given breakpoint. If no
\fIcriteria\fP are given, the breakpoint is made unconditional
.IP "cmd \fIbreak\fP [\fIcommand\fP]
Adds/changes/deletes the command executed when the breakpoint is
encountered. If no \fIcommand\fP is given, any existing command is
deleted and the breakpoint is always taken.
.LP
If no recognizable subcommand is given, "set" is assumed.
'\"
'\"	BYTEASCHAR
'\"
.xH "byteAsChar (variable.output)"
.LP
If non-zero, all byte variables will have their values converted into
ascii characters. For single-byte variables, both the ascii and the hex
value will be printed. For multi-byte variables, only the characters will
be shown. This has been superseded by the "char" type, but remains for the
hell of it
'\"
'\"	BYTES
'\"
.xH "bytes (memory)"
.LP
Examine memory as bytes. First argument is address to examine. If it is
not given or is "nil", the next address (the one after the most-recently
examined memory location) is used. Second argument is number of bytes to
examine. This defaults to 16.
'\"
'\"	CALL-PATIENT
'\"
.xH "call-patient (prog.call)"
.LP
Internal routine to actually perform a call. Returns non-zero if the call
completed successfully. The previous machine state is still preserved, so
the caller must invoke discard-state or restore-state, as it sees fit. Args
are as for "call"
'\"
'\"	CALL
'\"
.xH "call (top)"
.LP
Call a function in the current thread. First argument is the function to
call. If it is a \fBnear\fP function, the thread must already be executing in
the function's segment. Following arguments are in pairs:
.DS I
\fIvariable/register\fP \fIvalue\fP
.DE
These pairs are passed to the "assign" command, which see. As a special case,
if the variable is "push", the value (a word) is pushed onto the stack and
will be popped when the call completes (if it completes successfully).
All current registers are preserved and restored when the call is complete.
Variables are not.
.LP
Once the call has completed, you are left in a sub-interpreter to examine
the state of the machine. Type "break" to get back to the top level.
.LP
If the machine stops for any other reason than the call's completion, the
saved register state is discarded and you are left wherever the machine
stopped. You will not be able to get a stack trace above the called function,
but if the call eventually completes, and no registers have actually been
modified, things will get back on track ok.
.LP
You may not call a function from a thread that has retreated into the kernel.
This function also will not allow you to call ThreadExit. Use the "exit"
function to do that.
'\"
'\"	CAR
'\"
.xH "car (prog.list|prog.lisp)"
.LP
Returns the first element of the list
'\"
'\"	CASE
'\"
.xH "case (prog.tcl.conditional)"
.LP
Similar to the Bourne Shell's case statement, this takes a \fIstring\fP and pairs
of \fIpattern\fP \fIcommand\fP arguments. Each \fIpattern\fP is made up of one or more patterns
as for the shell (using *, ? and [], though you should be sure to quote any
[]'s you use). Patterns in a \fIpattern\fP argument are separated with |'s. If
one of the patterns is the string "default", the \fIcommand\fP for that pattern
is used if none of the other patterns matches. The \fIstring\fP may be followed by
the argument "in" if desired, but it is not required.
'\"
'\"	CATCH
'\"
.xH "catch (prog.tcl.error)"
.LP
Execute \fIcommand\fP catching any errors. Optional second arg \fIvar\fP is name of
variable into which string result of \fIcommand\fP is placed. Returns the code
returned by the command, i.e. 0 if command succeeded, non-zero if not
'\"
'\"	CBRK
'\"
.xH "cbrk (breakpoint|prog.breakpoint)"
.LP
Allows the user to set fast conditional breakpoints in the patient. This
command is very similar to the "brk" command, except a conditional
breakpoint differs from a breakpoint set with the "brk" command in that the
condition is evaluated on the PC, thus speeding the operation up enormously.
There are a limited number of conditional breakpoints that may be set in
the PC (currently 8), so they should be used mostly for heavily-travelled
areas of code (e.g. inner loops or things like EnterGraphics in the kernel).
.LP
Since the condition is checked on the PC, its scope is limited to seeing how
word registers compare to a given set of values. Not all registers need to be
checked, of course.
.LP
In the following descriptions, \fIcriteria\fP stands for a series of one or
more arguments of the form \fIregister\fP\fIop\fP\fIvalue\fP. \fIregister\fP is one of
the machine's word-sized registers, or the pseudo-register "thread",
corresponding to the current thread's handle. \fIop\fP is one of 10 comparison
operators: = (equal), != (not equal), > (unsigned greater-than), < (unsigned
less-than), >= (unsigned greater-or-equal), <= (unsigned less-or-equal), +>
(signed greater-than), +< (signed less-than), +>= (signed greater-or-equal).
These correspond to the 8086 instructions JE, JNE, JA, JB, JAE, JBE, JG, JL,
JGE and JLE, respectively. \fIvalue\fP is a standard Swat address expression.
The resulting offset is the value with which the register will be compared
when the breakpoint is hit.
.LP
If the breakpoint is patient-specific, the condition ss=\fIaddr-of-core-block\fP
is automatically established.
.LP
The available subcommands are:
.IP "set \fIaddr\fP \fIcriteria\fP
Sets a breakpoint at the given address to be taken only when the
given criteria are met. The breakpoint is patient-specific, meaining
the \fIcriteria\fP contains an implicit ss=\fIsegment-of-core-block\fP for
the current patient.
.IP "aset \fIaddr\fP \fIcriteria\fP
Like "set", but the breakpoint is set for all threads.
.IP "tset \fIaddr\fP \fIcriteria\fP
Like "set", but the breakpoint is removed the next time the machine
stops.
.IP "clear \fIbreak\fP*
Removes the given breakpoint(s). If no breakpoint is given, clears
all conditional breakpoints for the current patient. Asks for
confirmation before doing so.
.IP "enable \fIbreak\fP*
Enables the given breakpoint(s). If it is already enabled, this has
no effect. If no breakpoint is given, all breakpoints for the current
patient are enabled.
.IP "disable \fIbreak\fP*
Disable the given breakpoint(s). Has no effect if already disabled.
If no breakpoint is given, disables all breakpoints for the current
patient.
.IP "address \fIbreak\fP
Returns the address at which the given breakpoint was set
.IP "list
Lists all conditional and non-conditional breakpoints, where they are
set and if they are enabled.
.IP "isset \fIaddr\fP
Returns non-zero if a breakpoint is set at the given address.
.IP "cmd \fIbreak\fP [\fIcommand\fP]
Allows you to attach a TCL command to be evaluated when the breakpoint
is actually taken. If \fIcommand\fP is absent, any existing command is
removed.
.IP "cond \fIbreak\fP [\fIcriteria\fP]
Changes the criteria for the breakpoint. If \fIcriteria\fP is missing,
the breakpoint becomes a standard breakpoint with nothing being
checked on the PC.
.LP
If no recognizable subcommand is given, "set" is assumed.
'\"
'\"	CDR
'\"
.xH "cdr (prog.list|prog.lisp)"
.LP
Returns all but the first element of \fIlist\fP as a list
'\"
'\"	COLUMNS
'\"
.xH "columns (prog.output)"
.LP
Returns the number of columns available for output on the screen.
'\"
'\"	COMPLETION
'\"
.xH "completion (prog)"
.LP
Returns the unique prefix for the given list of names
'\"
'\"	CONCAT
'\"
.xH "concat (prog.tcl.list|prog.list|prog.string)"
.LP
Concatenates multiple list arguments into a single list. E.g.
.DS I
concat a b {c d e} {f {g h}}
.DE
yields the list
.DS I
a b c d e f {g h}
.DE
see also "list"
'\"
'\"	CONDENSESMALL
'\"
.xH "condenseSmall (variable.output)"
.LP
If non-zero, small (< 4 bytes) structures are printed on a single line
with each component considered as a signed integer
'\"
'\"	CONDENSESPECIAL
'\"
.xH "condenseSpecial (variable.output)"
.LP
If non-zero, causes special PC GEOS structures (rectangles and output
descriptors, to name a couple) to be printed specially so as to present
more information in less space
'\"
'\"	CONT
'\"
.xH "cont (top)"
.LP
Continue the machine. If waitForPatient is non-zero, waits for the machine to
stop again.
'\"
'\"	CONTINUE-PATIENT
'\"
.xH "continue-patient (prog.patient)"
.LP
Continues the current patient. If optional first arg is non-zero, timer
interrupts (and thus forced context switches) will be disallowed
'\"
'\"	CONTINUE
'\"
.xH "continue (prog.tcl.loop)"
.LP
Go back to start of containing loop
'\"
'\"	CURRENT-LEVEL
'\"
.xH "current-level (prog.input)"
.LP
Returns the nesting of command interpreters. 1 is the top-most.
'\"
'\"	CURRENT-REGISTERS
'\"
.xH "current-registers (prog.thread|prog.patient)"
.LP
Returns a list of the registers for the current thread.
'\"
'\"	CYCLES
'\"
.xH "cycles (profile)"
.LP
Count instruction cycles from now until the given address is reached. Prints
out each instruction as it is executed, along with the cycles it took. If
no address is given, executes until a breakpoint is hit.
'\"
'\"	DBG
'\"
.xH "dbg (obscure)"
.LP
Sets or returns the state of Swat's internal debug flag. If arg is given, it
must be numeric and is assigned to 'debug'. Returns the current state of the
flag.
'\"
'\"	DCACHE
'\"
.xH "dcache (prog)"
.LP
Control the data cache. If no argument given, prints statistics about
the cache usage and hit ratio. Parameters are as follows:
.nr q \w'length \fIn\fP   'u
.IP "bsize \fIn\fP" \nqu
Set block size to \fIn\fP bytes. This \fBmust\fP be a power two. Setting the
size to 0 turns off caching. Resets the cache statistics and flushes
all data currently in the cache.
.IP "length \fIn\fP" \nqu
Set the maximum number of blocks in the cache to \fIn\fP. The length
must be greater than 0. To turn off caching, set the block size to 0.
Resets the cache statistics, but only flushes data if there are more
than \fIn\fP blocks in the cache.
.IP "stats" \nqu
Prints statistics on the cache usage and hit ratio.
.IP "params" \nqu
Returns the list {\fIbsize\fP \fIlength\fP} giving the two parameters
that control the data cache.
.IP "on" \nqu
Re-enable data caching.
.IP "off" \nqu
Turn off data caching.
'\"
'\"	DCALL
'\"
.xH "dcall (profile)"
.LP
dcall displays calls to a given routine.  Invoking dcall with no arguments
causes dcall to be disabled. Usage: dcall \fIroutineName\fP
'\"
'\"	DEBUG
'\"
.xH "debug (prog.debug)"
.LP
Sets a breakpoint at the start of any tcl command. Execution will stop at
the command to enable you to examine the state of things. The breakpoint can
be removed using undebug.
'\"
'\"	DEBUGONERROR
'\"
.xH "debugOnError (prog.debug)"
.LP
If non-zero and an uncaught error is detected by the interpreter, the
function indicated by the "debugger" variable is invoked
'\"
'\"	DEBUGONRESET
'\"
.xH "debugOnReset (prog.debug)"
.LP
If non-zero and ^\ is typed or you answer 'n' to the 'Do you want to abort?'
prompt, causes the function indicated by the "debugger" variable to be
invoked
'\"
'\"	DEBUGGER
'\"
.xH "debugger (prog.debug)"
.LP
Name of the command when things go wrong. The function is passed two
arguments: a condition and the current result string from the interpreter.
The condition is "enter" if entering a command whose debug flag is set, "exit"
if returning from a frame whose debug flag is set, "error" if an error occurred
and the "debugOnError" variable is non-zero, "quit" if quit (^\) is typed and
the "debugOnQuit" variable is non-zero, or "other" for some other cause
(e.g. "debug" being invoked from within a function).
.LP
Execution continues when the function returns. The result of the function
replaces the previous result for the interpreter.
'\"
'\"	DEFCOMMAND
'\"
.xH "defcommand (prog.def|prog.proc|prog.tcl.proc)"
.LP
Arguments are \fIcmd\fP \fIargs\fP \fIhelpclass\fP \fIhelp\fP \fIbody\fP. \fIcmd\fP \fIargs\fP \fIbody\fP are used to create
a new command procedure, while \fIhelp\fP is the documentation string registered
for the command. \fIhelpclass\fP is the class(es) under which to file \fIhelp\fP. Refer
to "help" for more information. This command is used to defined new Swat
commands.
'\"
'\"	DEFDSUBR
'\"
.xH "defdsubr (prog.def|prog.proc|prog.tcl.proc)"
.LP
Arguments are \fIcmd\fP \fIargs\fP \fIhelpclass\fP \fIhelp\fP \fIbody\fP. \fIcmd\fP \fIargs\fP \fIbody\fP are used to create
a new subroutine procedure, while \fIhelp\fP is the documentation string registered
for the subroutine. \fIhelpclass\fP is the class(es) under which to file \fIhelp\fP.
Refer to "help" for more information. This command is used to defined new
Swat subroutines.
'\"
'\"	DEFHELP
'\"
.xH "defhelp (prog.def|prog.help)"
.LP
Defines the help string for an internal node of the help tree. May not
be used to override the help for a command whose documentation resides in
the DOC file, sorry.
'\"
'\"	DEFSUBR
'\"
.xH "defsubr (prog.proc|prog.tcl.proc|prog.def)"
.LP
Like "proc", except the procedure's name must be typed exactly to invoke it,
unlike procedures defined with "proc" or "defcommand", for which an unique
abbreviation is sufficient
'\"
'\"	DEFSYS
'\"
.xH "defsys (prog.proc|prog.tcl.proc|prog.def)"
.LP
Like "defsubr", except it inherits all the variables of its caller, unlike
with "proc" or any other procedure-definition command whose procedures have
their own local scope and can access variables at the global scope only -- not
those in their caller's local scope. Any new variables are created in the
called procedure's scope and go away upon its return.
'\"
'\"	DEFVAR
'\"
.xH "defvar (prog.def|prog.var)"
.LP
This is used in script files to define variables that are to be global.
The first argument is the variable to define and the second is its default
value. If the variable doesn't already have a value, this default value is
assigned to it. The optional third and fourth arguments are the help class
and documentation string, respectively. Refer to defcommand for more info.
'\"
'\"	DETACH
'\"
.xH "detach (top)"
.LP
Detaches Swat from the PC, allowing it to continue on its merry way.
You can re-attach to the PC (possibly after downloading new applications
or a new kernel) using the "attach" command. Takes the same arguments
as "quit".
'\"
'\"	DISCARD-STATE
'\"
.xH "discard-state (prog.thread|prog.patient)"
.LP
Discards the most-recently-saved state for the current thread, as saved
by "save-state".
'\"
'\"	DISPLAY
'\"
.xH "display (window)"
.LP
Creates a window \fImaxlines\fP high for executing the given command each time
the machine halts. First arg may also be "list", in which case all active
displays are listed, or "del", in which case the given display is deleted (the
display may be given by number or by the token returned when the display was
created). The command to execute for the display must be given as a single
argument.
'\"
'\"	DOSMEM
'\"
.xH "dosMem (dos)"
.LP
Travels along DOS's chain of memory blocks, providing info about each
'\"
'\"	DOSSTATE
'\"
.xH "dosState (dos)"
.LP
Print out the state of the caller of the current DOS function
'\"
'\"	DOWN
'\"
.xH "down (stack|top)"
.LP
Shifts the current frame down the given number of frames, or 1 if no number
given. "down" means towards the top of the stack.
'\"
'\"	DWORDISPTR
'\"
.xH "dwordIsPtr (variable.output)"
.LP
If non-zero, indicates that all dword-sized variables should be assumed to
be generic far pointers and be printed in segment:offset format, rather than
as one big 32-bit integer. Superseded by the various ptr types, but....
Defaults to 1.
'\"
'\"	ECHO
'\"
.xH "echo (prog.output)"
.LP
Prints its arguments, separated by spaces. If the first argument is -n, no
newline is printed. The arguments are printed separated by spaces.
'\"
'\"	ECHO
'\"
.xH "echo (prog.output)"
.LP
Prints its arguments, separated by spaces. If the first argument is -n, no
newline is printed.
'\"
'\"	ELIST
'\"
.xH "elist (output)"
.LP
Displays pending events
'\"
'\"	ERROR
'\"
.xH "error (prog.tcl.error)"
.LP
Generate an error with single argument \fImessage\fP telling what's wrong
'\"
'\"	EVAL
'\"
.xH "eval (prog.tcl)"
.LP
Evaluate the given \fIbody\fP and return the result
'\"
'\"	EVENT
'\"
.xH "event (prog.event)"
.LP
Much of Swat's function is driven by events that it dispatches internally
from various places. As some of these events signal happenings that could
be of interest to a Swat programmer, they are made available via this
command. Options for this command are:
.nr q \w'create   'u
.IP "handle \fIeventName\fP \fIhandler\fP [\fIdata\fP]" \nqu
The \fIhandler\fP procedure is invoked each time an event of type
\fIeventName\fP is dispatched. The handler receives two arguments:
an event-specific piece of data, and the \fIdata\fP given in this
command. A handler procedure should be declared:
proc \fIhandler\fP {arg data} {\fIbody\fP}
Returns an \fIevent-name\fP for later use in deleting it.
The \fIhandler\fP should return one of "EVENT_HANDLED",
"EVENT_NOT_HANDLED" or "EVENT_STOP_HANDLING". If it
returns "EVENT_STOP_HANDLING", the event will not be
dispatched to any other handlers of that event.
.IP "delete \fIevent\fP" \nqu
Deletes the event handler with the given name, as returned by
an "event handle" command.
.IP "dispatch \fIeventName\fP \fIarg\fP" \nqu
Dispatches the given event with the piece of data to all
handlers of that event. If \fIeventName\fP is a pre-defined event
type, \fIarg\fP will be converted to the appropriate type before
being dispatched, else it is passed as a string.
.IP "create" \nqu
Returns a number that represents a new event type. Handlers may
then be defined for and events dispatched of the new type.
.IP "list" \nqu
Lists all tcl-registered events by their event-names and the
handler function
.LP
Events currently defined are:
.nr q \w'CONTINUE   'u
.IP FULLSTOP \nqu
Generated when patient stops for a while. Argument is
string telling why the patient stopped.
.IP CONTINUE \nqu
Generated just before the patient is continued. The
argument is "full" if going to full speed, "half" if going to full
speed without having really stopped, and "step" if just going to
execute a single instruction.
.IP TRACE \nqu
Generated when the execution of a source line completes
and the patient is in line-trace mode.
.IP START \nqu
Generated when a new patient/thread is created. Argument
is name of patient involved.
.IP STACK \nqu
Current stack frame has changed. No argument (though 0x0 is
still passed).
.IP DETACH \nqu
Detaching from the PC. arg is always 0x0.
.IP RESET \nqu
Returning to top level. arg is always 0x0.
.IP ATTACH \nqu
Attached to PC. arg is always 0x0.
'\"
'\"	EXEC
'\"
.xH "exec (top|prog.tcl)"
.LP
Invokes a shell to execute \fIcommand\fP passing it the rest of the arguments.
The output of the command is captured and returned as the result of the
exec. If one of the arguments is <, neither it nor the following argument is
given to the command. Rather, the following argument is given to the command
as its input. This can be used, e.g. to pass the contents of a variable to
"sort" to have them sorted. exec returns the code with which \fIcommand\fP
exited, if it's one of those known to TCL. If the code is unknown, an error
is generated
'\"
'\"	EXIT
'\"
.xH "exit (top)"
.LP
Causes the current thread to exit. Optional argument is the status to return
to its parent, which defaults to 0
'\"
'\"	EXPLODE
'\"
.xH "explode (prog.proc|prog)"
.LP
Breaks a string into a list of its component letters. Useful for parsing
command switches.
'\"
'\"	EXPR
'\"
.xH "expr (top|prog.tcl)"
.LP
Evaluates the expression given as an argument. This can contain most C
operators, as well as TCL variables and commands (in [], of course). Returns
the value of the expression. Hex and octal numbers are specified as in C.
MASM radix characters are not supported.
'\"
'\"	FHANDLE
'\"
.xH "fhandle (kernel|output|file)"
.LP
Print out a file handle. Single argument \fInum\fP is the handle's ID number (if you
want it in hex, you'll have to indicate that with the usual radix specifiers
at your disposal)
'\"
'\"	FIELD
'\"
.xH "field (prog.list|prog.memory)"
.LP
Assuming first argument \fIlist\fP is a structure-value list from the "value"
command, return the value for field \fIname\fP in the structure.
'\"
'\"	FILE
'\"
.xH "file (prog.tcl)"
.LP
Performs an operation on a file or file name:
.IP "file \fIname\fP dirname
Returns the directory portion of \fIname\fP. If \fIname\fP
has no directory portion, returns "."
.IP "file \fIname\fP executable
Returns non-zero if \fIname\fP is executable by the user.
.IP "file \fIname\fP exists
Returns non-zero if \fIname\fP is an existing file.
.IP "file \fIname\fP expand
Expands any home directory spec and returns the result.
.IP "file \fIname\fP extension
Returns all characters after and including the last "." in the \fIname\fP.
Returns empty if there's no "." in \fIname\fP.
.IP "file \fIname\fP isdirectory
Returns non-zero if \fIname\fP is an existing directory.
.IP "file \fIname\fP isfile
Returns non-zero if \fIname\fP is an existing file.
.IP "file \fIname\fP owner
Returns non-zero if \fIname\fP is owned by the user.
.IP "file \fIname\fP readable
Returns non-zero if \fIname\fP is readable by the user.
.IP "file \fIname\fP rootname
Returns all characters up to but not including the last "." in \fIname\fP.
.IP "file \fIname\fP tail
Returns all of the characters in \fIname\fP after the last slash, or \fIname\fP, if
it contains no slashes.
.IP "file \fIname\fP writable
Returns non-zero if \fIname\fP is writable by the user.
'\"
'\"	FILL
'\"
.xH "fill (memory)"
.LP
Fills memory with a constant value. Usage is:
.DS I
fill (b[yte]|w[ord]) \fIaddr\fP \fIlength\fP \fIvalue\fP
.DE
\fIaddr\fP, \fIlength\fP and \fIvalue\fP are all standard address expressions. Both the
segment and offset of \fIaddr\fP are used as the start of the memory area to be
filled. For \fIlength\fP and \fIvalue\fP, only the offset portion is used. \fIlength\fP
gives the number of bytes or words to fill and \fIvalue\fP is the value that is
to be stored. If \fIaddr\fP is handle relative, \fIlength\fP may not go outside the
handle.
'\"
'\"	FINDLOCALSANDINSTVARS
'\"
.xH "findLocalsAndInstVars (output)"
.LP
If non-zero, when instructions are printed with the value(s) of their
argument(s) (e.g. by istep), Swat will try to locate the proper local variable,
if the instruction is referencing a negative offset from BP, or instance
variable, if the instruction is referencing a non-negative offset from
BX, BP, SI or DI. In order for Swat to find a local variable, the variables
for the function must be contained within a structure whose name is formed
by taking the uppercase letters from the function name and adding
"_StackFrame", E.g. the local variables for "IntSquare" should be in the
structure IS_StackFrame. Similarly, those for E_CalcLines should be in
ECL_StackFrame
'\"
'\"	FINISH
'\"
.xH "finish (stack)"
.LP
Finish the current frame, or frame n (number given by "backtrace"), if given.
Simply allows the machine to run until it exits the selected frame.
'\"
'\"	FINISHFRAME
'\"
.xH "finishframe (prog.stack)"
.LP
Finishes out the frame given as an argument. For this to work, Swat must be
able to decode the next frame down the stack (the given frame's caller), as
it simply fetches that frame and the address in it and sets a breakpoint
at that address. Caller should dispatch the FULLSTOP event... Returns
non-zero if interrupted.
'\"
'\"	FLUSH-OUTPUT
'\"
.xH "flush-output (prog.output)"
.LP
Flushes any pending output
'\"
'\"	FOR
'\"
.xH "for (prog.tcl.loop)"
.LP
This is a looping command similar to the for statement in C. It takes four
arguments: start, test, next and body. start, next and body are regular
TCL commands, while test is an expression as for the "expr" command. start is
executed at the beginning, then for each iteration:
.IP \(bu 2
test is evaluated. If it is 0, the loop is finished.
.IP \(bu 2
the body is evaluated,
.IP \(bu 2
next is evaluated
.LP
The loop can be exited prematurely using the "break" command
'\"
'\"	FOREACH
'\"
.xH "foreach (prog.tcl.loop)"
.LP
Takes three arguments: \fIvar\fP, \fIlist\fP and \fIbody\fP. \fIvar\fP is an iteration variable that
is filled with each of the elements of \fIlist\fP in turn with \fIbody\fP being executed
for each iteration.
'\"
'\"	FORMAT
'\"
.xH "format (prog.tcl|top)"
.LP
Much like the C function sprintf(3) (type "man 3 sprintf" from the shell for
more information). The only difference is that %c takes a decimal number that
is the ASCII code for a character and produces the proper character. Other
arguments are converted into the proper C data type before being passed to
sprintf for formatting. This can be used to convert numbers to hex or octal.
'\"
'\"	FRAME
'\"
.xH "frame (stack|prog.stack)"
.LP
Command used to decode and access stack frames in the patient, as well as
set the current stack frame. Frames are refered to using tokens of the form
"frame\fIn\fP" as returned by several of the subcommands. The subcommands are:
.IP "top
Decodes and returns a token for the frame at the top of the current
stack..
.IP "cur
Returns a token for the currently-selected stack frame
.IP "next \fIframe\fP
Decodes and returns a token for the next frame up from \fIframe\fP
.IP "get \fIaddress\fP
Decodes and returns a token for the frame at the given address
.IP "function [args] [\fIframe\fP]
Returns the name of the function active in \fIframe\fP. If \fIframe\fP isn't
given, the current frame is used. If the third argument is "args",
the function's arguments are also provided as lists of the
form {\fIargName\fP \fIvalue\fP}
.IP "funcsym [\fIframe\fP]
Returns the symbol token for the given (or current) frame's function
.IP "scope [\fIframe\fP]
Returns the full name of the active scope in \fIframe\fP. If \fIframe\fP is
absent, the current frame is used.
.IP "line [\fIframe\fP]
If possible, returns a string of the form "\fIfile\fP \fIline\fP" with the
source file and line number in which the function in the frame is
executing. If there is no line-mapping information for that
function, an error is generated. If no \fIframe\fP is given, the current
is used.
.IP "register \fIregName\fP [\fIframe\fP]
Returns, as a decimal number, the contents of the register with
the given name in \fIframe\fP. Again, if no frame is given, the current
is used. All registers but "pc" are returned as decimal. "pc" is
returned as cs:ip where both cs and ip are in hex, preceded by 0x
.IP "copy \fIframe\fP
Duplicate a frame for long-term manipulation. All other frames
returned by this command are invalidated when the PC is continued.
If you need to keep a frame around for reference, however, it should
be copied in this fashion. You will only be able to use it while
it's valid (the patient hasn't exited it), of course.
.IP "delete \fIframe\fP
Deletes the frame represented by the given token. Only needed for
frames that have been copied.
.IP "[(+|-|#)]\fInumber\fP
Adjusts the current frame up (if the first character is +), down (if
the first character is -), or absolutely (if the first character is
# or a digit). Frames are numbered from 0. Setting the frame also
changes to the scope active in the new frame. Generates a STACK event.
.IP "set \fIframe\fP
Sets the current frame to be the given one. Generates a STACK event
'\"
'\"	FUNC
'\"
.xH "func (stack)"
.LP
Sets or gets the current function. If no argument is given, returns the
function in the current stack frame. If an argument is given, sets the current
frame to be the first from the top that is for that function. If the patient
isn't active, or there's no frame for the function, this function returns an
error
'\"
'\"	FWALK
'\"
.xH "fwalk (kernel|file)"
.LP
Print out the status of all open file handles.
The letters in the 'Flags' column mean the following:
.DS I
.ta \w'RW   'u
RW	deny RW
R	deny R
W	deny W
N	deny none
rw	access RW
r	access R
w	access W
.DE
'\"
'\"	GC
'\"
.xH "gc (top)"
.LP
Implements a simple garbage collector to scavenge unreferenced symbols
'\"
'\"	GEOSFILES
'\"
.xH "geosfiles (kernel)"
.LP
Prints out all the files opened by GEOS
'\"
'\"	GET-ADDRESS
'\"
.xH "get-address (prog.memory)"
.LP
Used by the various memory-access commands. Takes one argument, \fIaddr\fP, being
the address argument for the command. Typically, the command is declared as
.DS I
[defcommand cmd {{addr nil}} ... ]
.DE
allowing the address to be unspecified. This function will return the given
address if it was, else it will return the last-accessed address (stored in
the global lastAddr variable as a 3-tuple from addr-parse) in the form of
an address expression. If no address is recorded (lastAddr is nil), cs:ip will
be used.
'\"
'\"	GETENV
'\"
.xH "getenv (prog)"
.LP
Returns the value for an environment variable. Returns the empty string for
undefined variables, in keeping with TCL traditions.
'\"
'\"	GLOBAL
'\"
.xH "global (prog.tcl.var)"
.LP
Declares the argument variables to be global. For the duration of the
procedure in which it is executed, the global values of the variables will be
used and/or modified. Without this, all variables are local and go away when
the procedure finishes.
'\"
'\"	GLOSS
'\"
.xH "gloss (reference)"
.LP
``gloss \fIregexp\fP'' prints out the glossary definition of
\fIregexp\fP, which is a regular expression (or just a word) that is
given to SED.
'\"
'\"	GO
'\"
.xH "go (breakpoint|top)"
.LP
Takes as many address expressions as desired for arguments and sets
breakpoints at all of them. These breakpoints will be removed when the machine
stops 
.ul
AND ARE ONLY ACTIVE FOR THE CURRENT PATIENT.
After the breakpoints are set, the machine is continued in the usual fashion.
'\"
'\"	HANDLE
'\"
.xH "handle (prog)"
.LP
This command offers access to the structures Swat uses to track memory
and thread allocation on the PC. Tokens returned by this command should
be regarded as temporary and should not be used across continuations of the
PC. Anyway, there are several options to this command:
.IP "lookup \fIid\fP
\fIid\fP is the handle ID to look up. The default radix is decimal, as
usual, but all the regular radix characters are understood. This
returns a token you should use in getting information about the
handle.
.IP "find \fIaddress\fP
\fIaddress\fP is a typical Swat-format address expression. This also
returns a token you can use to get information.
.IP "all
Returns a list of all the known handle ID's
.IP "segment \fIhandle\fP
Returns the segment address of the handle (in decimal -- all numbers
returned by this command are in decimal).
.IP "size \fIhandle\fP
Returns the number of bytes allocated to the handle.
.IP "state \fIhandle\fP
Returns an integer indicating the state of the handle. The bits are:
.DS I
.ta \w'0x00040 Discarded   'u +\w'0x00004 Discardable   'u
0xf8000 Type	0x00800 LMem	0x00400 Kernel
0x00200 Attached	0x00100 Process	0x00080 Resource
0x00040 Discarded	0x00020 Swapped	0x00010 Shared
0x00008 Fixed	0x00004 Discardable	0x00002 Swapable
0x00001 Resident
.DE
Handle types (stored in the \fIType\fP field) are:
.DS I
.ta \w'0x800000 Stack Event   'u +\w'0xc00000 VM File   'u
0x08000 Memory	0x60000	Timer	0x70000 Event stack data
0x80000 Stack Event	0x90000	Event	0xa0000 Saved block
0xb0000 VM Header	0xc0000	VM File	0xd0000 File
0xe0000 Thread	0xf0000	GSeg
.DE
.IP "owner \fIhandle\fP
Returns the handle token for the owner of the handle.
.IP "patient \fIhandle\fP
Returns a token for the patient to which the handle is assigned.
This may be passed to the "patient" command to obtain more info.
.IP "other \fIhandle\fP
Returns the handle's otherInfo field. NOTE: This isn't necessarily
the otherInfo field from the PC. For resource handles, e.g., it's
the sym token of the module for the handle.
.IP "id \fIhandle\fP
Returns the ID number of the handle (in decimal).
.IP "isthread \fIhandle\fP
Returns 1 if the handle is a thread handle.
.IP "iskernel \fIhandle\fP
Returns 1 if the handle is a kernel handle (one of the predefined 7,
not one whose owner happens to be the kernel).
.IP "isfile \fIhandle\fP
Returns 1 if the handle is a file handle.
.IP "isvm \fIhandle\fP
Returns 1 if the handle is a vm handle.
.IP "isgseg \fIhandle\fP
Returns 1 if the handle is a gseg handle.
.IP "ismem \fIhandle\fP
Returns 1 if the handle is a memory handle.
.IP "interest \fIhandle\fP \fIproc\fP [\fIdata\fP]
Registers interest in a handle. Returns an interest token to be used
when the \fBnointerest\fP subcommand is invoked.  When a handle's
state changes, \fIproc\fP is called with the handle as its first
argument, the state change as its second argument, and \fIdata\fP as
its third.  The state change is one of:
.RS
.nr q \w'swapout   'u
.IP swapin \nqu
Block swapped in from disk/memory.
.IP load \nqu
Resource freshly loaded from disk.
.IP swapout \nqu
Block swapped to disk/memory.
.IP discard \nqu
Block discarded.
.IP resize \nqu
Block changed size and maybe moved.
.IP move \nqu
Block moved on heap.
.IP free \nqu
Block has been freed.
.IP fchange \nqu
Block's Han_flags changed.
.RE
.IP "\&"
When the block is freed, there is no need to call ``handle nointerest''
as the interest record is deleted.
.IP "nointerest \fIinterest\fP
Deletes the given interest record for the handle (the handle is
implied by the \fIinterest\fP token passed).
'\"
'\"	HANDLES
'\"
.xH "handles (kernel|heap)"
.LP
Prints out info for all in-use handles
'\"
'\"	HBRK
'\"
.xH "hbrk (breakpoint)"
.LP
Usage:	"hbrk <location> (byte|word) (match|mismatch) <value>"
.LP
Emulates a hardware breakpoint by checking at every method call to
see if a location in memory has been written to, and breaks when it happens,
telling you between which two routines the write occurred.  The information
and the return stack will hopefully guide you to the offending line of code.
.LP
Examples:
.IP "hbrk scrollTab+10 byte match 0
Continues, printing method handlers, until a zero is written at scrollTab+10.
.IP "hbrk OLScrollButton+3 word mismatch 0x654f
Goes until the word at OLScrollButton+3 is destroyed. Hex numbers require the
0x format.
.LP
The command creates two breakpoints.  Remove these to get rid of the 
hardware breakpoint.
'\"
'\"	HELP-FETCH-LEVEL
'\"
.xH "help-fetch-level (prog.help)"
.LP
Returns a list of the topics available at a given level in the help tree
'\"
'\"	HELP-FETCH
'\"
.xH "help-fetch (prog.help)"
.LP
Returns the help string for a path.
'\"
'\"	HELP-GET
'\"
.xH "help-get (prog.help)"
.LP
Returns a list of all help strings registered for a topic. Note this
is different from help-fetch, which can only return one string based
on a help path.
'\"
'\"	HELP-HELP
'\"
.xH "help-help (obscure)"
.LP
Available commands:
.IP "show \fItopic\fP
Print the help for the given topic. If it has subtopics,
provides a menu of those subtopics for you to examine.
.IP "find \fIpattern\fP
Locate all help topics matching a pattern.
.IP "up
Go back up one level in the help tree.
.IP "..
Same as "up"
.IP "goto \fIlevel\fP
Go to a specific level in the help tree.
.IP "menu
Show the menu for the current level.
.IP "\fItopic\fP
an implicit "show \fItopic\fP"
.LP
Just as symbols may be completed by typing escape, control-] or control-D,
topics may be completed in the same ways with the same characters (escape
finishes out the topic, if possible, or finishes as much as is common among
the possibilities and beeps when it becomes helpless; control-] cycles through
the possible choices; control-D prints out a table of the possibilities).
.LP
In this documentation and in usage messages, the following conventions have
been more-or-less followed:
.IP "()
enclose a set of alternatives. The alternatives are separated by |'s
.IP "[]
usually enclose optional elements, except in fairly obvious cases
where they imply a character class (e.g. for the "frame" command).
.IP "<>
enclose "non-terminals", i.e. a type of argument, rather than a
string that's to be typed as shown (e.g. "\fIaddr\fP" means an address
expression, whereas "(addr|biff)" means either the string "addr" or
the string "biff").
.LP
`*' following one of these constructs means 0 or more of the thing, while `+'
means 1 or more.
'\"
'\"	HELP-IS-LEAF
'\"
.xH "help-is-leaf (prog.help)"
.LP
See if \fIpath\fP leads to a leaf node in the help tree (i.e. it has
no subtopics). Returns 1 if so, 0 otherwise.
'\"
'\"	HELP-MINASPECT
'\"
.xH "help-minAspect (variable)"
.LP
If non-zero, contains the minimum aspect ratio to be maintained when
displaying tables in the help browser. The ratio is expressed as the fraction
.DS C
entries_per_column*10/number_of_columns
.DE
E.g. a minimum ratio of 1.5 would be 15 (since we don't do floating-point)
'\"
'\"	HELP-SCAN
'\"
.xH "help-scan (prog.help)"
.LP
Given a \fIpattern\fP, expands it to be *\fIpattern\fP* and matches it against all
strings registered in the hash table, returning the names of those topics
whose documentation matches.
'\"
'\"	HELP-VERBOSE
'\"
.xH "help-verbose (variable)"
.LP
If non-zero, performs verbose prompting, which can be annoying after a while
'\"
'\"	HELP
'\"
.xH "help (reference)"
.LP
This is the user-level access to the on-line help facilities for Swat. If
given a topic (e.g. "brk") as its argument, it will print all help strings
defined for the given topic (there could be more than one if the same name is
used for both a variable and a procedure, for instance). If invoked without
arguments, it will enter a browsing mode, allowing the user to work his/her
way up and down the documentation tree
'\"
'\"	HISTORY
'\"
.xH "history (top)"
.LP
This command manipulates the history list. Options are:
.IP "\fIn\fP
Prints the most-recent \fIn\fP commands
.IP "set \fIsize\fP
Sets the number of commands saved
.IP "subst \fIstr\fP
Performs history substitution on \fIstr\fP and enters it into the history queue.
.IP "cur
Returns the current history number.
If no argument is given, all saved commands are printed.
'\"
'\"	HWALK
'\"
.xH "hwalk (kernel|heap)"
.LP
Print out the status of all blocks on the heap. Takes two optional arguments.
First argument is a collection of flags, beginning with '-', from the following
set:
.IP "p
print prevPtr and nextPtr as well.
.IP "e
do error-checking on the heap.
.IP "f
fast print-out -- doesn't try to figure out the type of the block.
.LP
Second argument is the patient whose blocks are to be printed (either a name
or a core-block's handle ID). The default is to print all the blocks on the
heap.
.LP
The letters in the 'Flags' column mean the following:
.nr @p \n(PD
.nr PD 0
.IP "s
sharable
.IP "S
swapable
.IP "D
discardable
.IP "L
contains local memory heap
.IP "d
discarded (by LMem module: discarded blocks don't appear here)
.IP "a
attached (notice given to Swat whenever state changes)
.nr PD \n(@p
'\"
'\"	IBRK
'\"
.xH "ibrk (breakpoint|top)"
.LP
Set a breakpoint interactively. At each instruction, you have several options:
.IP "q
Quit back to the command level.
.IP "n
Go to next instruction (this also happens if you just hit return).
.IP "p
Go to previous instruction.
.IP "P
Look for a different previous instruction.
.IP "^D
Go down a "page" of instructions. The size of the page is controlled
by the global variable ibrkPageLen. It defaults to 10.
.IP "^U
Go up a "page" of instructions.
.IP "b
Set an unconditional breakpoint at the current instruction and
 go back to command level.
.IP "a
Like 'b', but the breakpoint is set for all patients.
.IP "t
Like 'b', except the breakpoint is temporary and will be
removed the next time the machine stops.
.IP "B
Like 'b', but can be followed by a command to execute when the
breakpoint is hit.
.IP "A
Like 'B', but for all patients.
.IP "T
Like 'B', but breakpoint is temporary.
'\"
'\"	IBRKPAGELEN
'\"
.xH "ibrkPageLen (var)"
.LP
Number of instructions to skip when using the ^D and ^U commands of ibrk
'\"
'\"	IF
'\"
.xH "if (prog.tcl.conditional)"
.LP
This is TCL's conditional and has the form
.DS C
if \fItest\fP [then] \fItruebody\fP [elif \fItest\fP [then] \fItruebody\fP [elif ...]] [[else] \fIfalsebody\fP]
.DE
While the "then" and "else" keywords are optional, the "elif" keywords
must be given if additional conditional clauses are needed. If a
\fItruebody\fP is empty, and the test evaluated non-zero, if will
return the result of the test.
'\"
'\"	IMEM
'\"
.xH "imem (memory)"
.LP
Examine/modify memory interactively. First argument is address at which to
start display. Optional second argument is initial display mode. The
display mode governs how the data at the current address are displayed.
Each mode causes the data to be displayed in 2-3 different formats, so
as to provide you with as much information as possible. The modes and the
things they display are:
.DS I
.ta \w'Name  'u +\w'dword  'u +\w'segment:offset  'u +\w'Assembly lang.  'u
Name	Size	1st format	2nd format	3rd format\l'|0\(ul'
b	byte	Hexadecimal	Signed decimal	ASCII character
w	word	Hexadecimal	Unsigned dec.	Signed decimal
d	dword	segment:offset	signed dec.	Symbol
i	var.	Hex bytes	Assembly lang.
.DE
.LP
After the data are displayed, you may type in a single-character command from
the following set:
.IP "b, w, d, i
Sets the display mode to the given one and redisplays the data at the
current address.
.IP "n, \fIreturn\fP
Advances to the next data item (the size of the item currently
displayed determines where the next item is found)
.IP "p
Returns to the preceeding data item. Again, the item chosen depends on
the display mode. When displaying instructions, a heuristic is applied
to locate the preceeding instruction. If it chooses the wrong one, use
the P command to make it search again.
.IP "\fIspace\fP
Clears the data display and allows you to enter a new value
appropriate to the current display mode. 
.ul
This command is not valid in `i' mode.
The \fBassign\fP command is used to perform the assignment, so
the same rules apply as for it, with the exception of '- and "-quoted
strings. A string with 's around it ('hi mom') has its characters
poked into memory starting at the current address. A string with "s
around it ("Swat.exe") likewise has its characters poked into memory,
with the addition of a null byte at the end.
.IP "q
Return to command level. The last address accessed is recorded for use
by the other memory-access commands.
.IP "^D
Display a ``page'' of successive memory elements in the current mode.
.IP "^U
Display a ``page'' of preceeding memory elements in the current mode.
.LP
For ^D and ^U, the size of a ``page'' is kept in the global variable
\fBimemPageLen\fP and defaults to 10.
'\"
'\"	IMEMPAGELEN
'\"
.xH "imemPageLen (var)"
.LP
Number of elements to display when imem is given the ^D or ^U command.
'\"
'\"	INDEX
'\"
.xH "index (prog.list|prog.tcl|prog.string)"
.LP
Takes two arguments \fIvalue\fP and \fIindex\fP and returns the \fIindex\fPth field of \fIvalue\fP.
If an optional third argument "chars" is given, each character in \fIvalue\fP is
considered a field. Otherwise, \fIvalue\fP is treated as a list and divided into
fields accordingly.
'\"
'\"	INFO
'\"
.xH "info (prog.tcl)"
.LP
Provides information about things, as:
.nr q \w'cmdcount   'u
.IP "arglist \fIprocname\fP" \nqu
Returns the list of arguments and default values for the procedure.
The list looks as the list originally given for the procedure did
(whitespace excepted).
.IP "args \fIprocname\fP [\fIpattern\fP]" \nqu
Returns the list of arguments for the procedure, or those matching the
given patterin, if given.
.IP "body \fIprocname\fP" \nqu
Returns the body of the procedure
.IP "cmdcount" \nqu
Returns the total number of commands executed by the interpreter
.IP "commands [\fIpattern\fP]" \nqu
Returns all known commands, if no pattern given, else only returns
those that match the given pattern.
.IP "default \fIprocname\fP \fIarg\fP \fIvarname\fP" \nqu
\fIprocname\fP is the name of a TCL procedure, and \fIarg\fP is the name of
one of its arguments. If the argument has a default value, that value
is placed in the variable \fIvarname\fP and 1 is returned, else 0.
.IP "globals" \nqu
Returns a list of the names of all global variables
.IP "locals" \nqu
Returns a list of the names of local variables, including procedure
arguments.
.IP "procs" \nqu
Returns a list of all TCL command procedures
.IP "vars" \nqu
Returns a list of all currently-visible variables.
'\"
'\"	INT
'\"
.xH "int (misc)"
.LP
Set or print the state of the two interrupt controllers while the machine is
stopped. If no arguments are given, the current state is printed. Arguments,
if given, come in pairs -- an interrupt level and its desired state.
An interrupt level can be specified either using their names or as
.DS C
\fIcontroller\fP:\fInumber\fP
.DE
\fIcontroller\fP is either 1 or 2, and \fInumber\fP ranges from 0 to 7. The interrupts
and their numbers are:
.DS I
.ta \w'HardDisk  'u +\w'2:0  'u
Timer	1:0	System timer. Probably dangerous to enable.
Keybd	1:1	Keyboard input.
Slave	1:2	This is how devices on controller 2 interrupt.
		Disabling this disables them all.
Com2	1:3	This is the port usually used by Swat, so it can't
		be disabled.
Com1	1:4	The other serial port -- usually the mouse.
LPT2	1:5	The second parallel port
Floppy	1:6	Floppy-disk drive
LPT1	1:7	First parallel port
Clock	2:0	Real-time clock
Net	2:1	Network interfaces (?)
FPA	2:5	Coprocessor
HardDisk	2:6	Hard-disk drive
.DE
'\"
'\"	INTFORMAT
'\"
.xH "intFormat (variable.output)"
.LP
Contains the printf format string used to print integers. Defaults to %x
'\"
'\"	INTR
'\"
.xH "intr (misc)"
.LP
Catch, ignore or deliver an interrupt on the PC. First argument is the
interrupt number. Optional second argument is "catch" to catch delivery of the
interrupt, "ignore" to ignore the delivery, or "send" to send the interrupt
(the machine will keep going once the interrupt has been handled). If no second
argument is given, the interrupt is delivered
'\"
'\"	IO
'\"
.xH "io (memory)"
.LP
Allows you to access I/O ports on the PC. If first arg is "w", a full
16-bit access is performed (either read or write). Next (first, if 8-bit
access) argument is the port number to access (default radix is decimal).
Optional final argument is the value to store in the port (radix is also
decimal). NOTE: The stub handles accesses to ports 21h and a1h specially,
so it may not track the actual behaviour of the interrupt controllers,
as the stub does NOT emulate the 8059.
'\"
'\"	IRQ
'\"
.xH "irq (prog)"
.LP
Sets/Clears/Gets the interrupt-pending flag used by the system. If no
argument given, returns the flag as a 1 or a 0. If argument is non-zero
or "set", sets the flag. If argument 0 or "clear", flag is cleared.
'\"
'\"	ISTEP
'\"
.xH "istep (step|top)"
.LP
Step the patient instruction by instruction, printing the arguments of the
instruction at each step and waiting for a response from the user of what to
do next:
.IP "q
Stops stepping. Returns to command level.  Hitting the spacebar or
escape also works.
.IP "c
Stops stepping -- lets the patient continue.
.IP "n
Continues to the next instruction, skipping procedure calls, repeated
string instructions, and software interrupts. Only stops when the
machine returns to the right context (i.e. the stack pointer and
current thread are the same as they are when the 'n' command was
given).
.IP "N
Like n, but stops whenever the breakpoint is hit, whether you're in
the same frame or not.
.IP "m
Goes to the next method called.  Doesn't work when the method is not
handled anywhere (sorry, I forgot).
.IP "f
Finishes out the current stack frame.
.IP "s
Steps one instruction.
.IP "g
Executes the 'go' command with the rest of the line as arguments.
.LP
If only return is pressed, the default command is executed. This may
be (but need not be) specified as an argument to this function.  If
the current patient isn't the actual current thread, this will wait
for the patient to wake up before single-stepping it.
'\"
'\"	LASTCOMMAND
'\"
.xH "lastCommand (prog.input|variable.input)"
.LP
The command currently being executed. Set by top-level-read
'\"
'\"	LENGTH
'\"
.xH "length (prog.list|prog.string|prog.tcl.list)"
.LP
Returns the length of a list. If second arg "chars" is given, the number of
characters in the list is returned
'\"
'\"	LINK
'\"
.xH "link (obscure)"
.LP
Links the first patient as a library of the second. This only works if
both patients are active. It persists across detach/attach sequences as
long as the second patient isn't re-downloaded. If only one patient is
given, it is linked as a library of the current patient. Cycles are not
allowed. I.e. don't link your application as a library of the UI -- it
won't work...or if it does, it will make Swat die.
'\"
'\"	LIST
'\"
.xH "list (prog.list|prog.tcl.list)"
.LP
Creates a list of its arguments. For example
.DS I
list a b {c d e} {f {g h}}
.DE
produces
.DS I
a b {c d e} {f {g h}}
.DE
as opposed to "concat", which produces
.DS I
a b c d e f {g h}}
.DE
'\"
'\"	LISTI
'\"
.xH "listi (memory)"
.LP
Examine memory as instructions. First argument is address to examine. If it is
not given or is "nil", the next address (the one after the most-recently
examined memory location) is used. Second argument is number of instructions to
print. This defaults to 10.
'\"
'\"	LOAD
'\"
.xH "load (prog.load|prog.file)"
.LP
Load a file of TCL commands. If the file cannot be found as given, it
is looked for in all the directories mentioned in the "load-path"
variable. This variable is initialized from the SWATPATH environment
variable, which is in the form \fIdir1\fP:\fIdir2\fP:...:\fIdirn\fP. The Swat
library directory is appended to this path, so you needn't include it
yourself. The file need not end in ".tcl". The directories may contain
standard C-Shell ~ syntax.
'\"
'\"	LS
'\"
.xH "ls (misc)"
.LP
List the current directory. -C flag automatically passed (otherwise the output
wouldn't be in columns). Other flags you have to give yourself.
'\"
'\"	MAP
'\"
.xH "map (prog.list)"
.LP
Applies a command expression to the successive elements of one or more
lists, binding each element in turn to a variable and evaluating the
expression. The results of evaluating the expression are merged into a
list in the same order as the elements of the lists to which the expression
is applied. All lists must have the same number of elements. The usage is:
.DS I
map \fIvarlist\fP \fIlist1\fP \fIlist2\fP...\fIlistn\fP \fItcl-command-list\fP
.DE
Thus,
.DS I
map {a b c} {l1a l1b} {l2a l2b} {l3a l3b} {format {%s %s %s} $c $a $b}
.DE
would result in the list
.DS I
{{l3a l1a l2a} {l3b l1b l2b}}
.DE
'\"
'\"	MAP-METHOD
'\"
.xH "map-method (ui|object)"
.LP
Map a method number to a method name. First argument is the number.
Second argument is either a class name or the address of an object.
.LP
When called from a program, the second argument should be the name of
the class from which to start the search, and the third argument should be
the object for which the the method name is being sought, so variant
classes can be handled, or 0 to indicate that variant classes either won't
occur or aren't to be handled.
'\"
'\"	MAPCONCAT
'\"
.xH "mapconcat (prog.list)"
.LP
Applies a command expression to the successive elements of one or more
lists, binding each element in turn to a variable and evaluating the
expression. The results of evaluating the expression are merged into a
string in the same order as the elements of the lists to which the
expression is applied. All lists must have the same number of elements. The
usage is:
.DS I
mapconcat \fIvarlist\fP \fIlist1\fP \fIlist2\fP...\fIlistn\fP \fItcl-command-list\fP
.DE
Thus,
.DS I
mapconcat {a b c} {1a 1b} {2a 2b} {3a 3b} {format {%s %s %s} $c $a $b}
.DE
would result in the string
.DS I
{3a 1a 2a3b 1b 2b}
.DE
'\"
'\"	NEXT
'\"
.xH "next (step|breakpoint)"
.LP
Execute a single instruction, skipping over any calls, repeated instructions,
or software interrupts. Does not protect against recursion, however, so the
breakpoint set may be taken in an instance of the current function different
than the one in which you executed this command.
'\"
'\"	NOSTRUCTENUM
'\"
.xH "noStructEnum (variable.output)"
.LP
If non-zero, prevents fields that are structures or enums from having the
words "struct" or "enum" placed in front of them, making for more compact
output. Defaults to 1
'\"
'\"	NULL
'\"
.xH "null (prog|prog.list|prog.lisp)"
.LP
Determines if its argument is nil (the string "nil" or the empty string),
returning non-zero if so
'\"
'\"	OBJTREE
'\"
.xH "objtree (kernel|output)"
.LP
Prints out an object tree starting with the root specified.  Prints out the
type of object, its bounds, and the location of the instance data.
'\"
'\"	PATCH
'\"
.xH "patch (top|breakpoint)"
.LP
Patch assists in creating breakpoints that invisibly make small
changes to code.  This can help the programmer find several bugs without
remaking and redownloading. Patch is also useful for creating tracing
breakpoints, since it accepts regular TCL commands, thus allowing you
to print out data structures or registers when execution reaches a
certain point.
.LP
There are several ways of invoking patch:
.RS
.IP "patch \fIaddr\fP
Sets a patch at the given address
.IP "patch
Sets a patch at the most-recently accessed address, as set by the most-recent
memory-access command (\fBbytes\fP, \fBwords\fP, \fBlisti\fP, \fBimem\fP, ...)
.IP "patch del \fIaddr\fP*
Removes patches at the given address(es). If no address is given, all known
patches are removed.
.RE
.LP
When creating a patch, you are prompted for its contents, each line
of which comes from the following command set:
.DS B
.ta \w'mcall \fIaddress\fP \fIregs\fP   'u +\w'pop nothing (sp=sp+2)   'u
\kqform	meaning	examples\l'|\nqu_'
\fIreg\fP = \fIvalue\fP	assign \fIvalue\fP to \fIreg\fP	ax = bx    dl = 5
push (\fIreg\fP|\fIvalue\fP)	push value	push ax    push 45
pop (\fIreg\fP|\fIvalue\fP)	pop value	pop ax     pop 45
pop	pop nothing (sp=sp+2)	pop
jmp \fIaddress\fP	change ip	jmp UI_Attach+45
scall \fIaddress\fP \fIregs\fP	call routine (save)	call MemLock ax 3
mcall \fIaddress\fP \fIregs\fP	call routine (modify)	call MemLock ax 3
xchg \fIreg\fP \fIreg\fP	swap two registers	xchg ax bx
set \fIflag\fP	set condition flag	set CF     set ZF
reset \fIflag\fP	reset condition flag	reset CF   reset ZF
if \fIflag\fP	if flag set then ...	if CF
if !\fIflag\fP	if flag reset then ...	if !ZF
if \fIexpr\fP	if expr then...	if foo == 4
else
endif
$	Terminate input
a	Abort
\fIany other\fP	tcl command	echo $foo
.DE
.LP
\fIflag\fP is taken from the set
.B TF ,
.B IF ,
.B DF ,
.B OF ,
.B SF ,
.B ZF ,
.B PF ,
.B AF ,
or
.B CF
and \fImust\fP be in upper-case.
.LP
The \fBscall\fP command has no effect on the current registers (not even
for purposes of return values), while the \fBmcall\fP command modifies whatever
registers the called function modifies. See the ``call'' documentation for the
format of \fIregs\fP.
'\"
'\"	PATIENT
'\"
.xH "patient (prog)"
.LP
This command provides access to information about a patient. For those
subcommands for which the \fIpatient\fP is optional, the current patient will
be used if no patient handle is given.
.LP
Possible options are:
.IP "name [\fIpatient\fP]
Returns the name of the patient.
.IP "fullname [\fIpatient\fP]
Returns the full permanent name with extension and padding spaces.
.IP "threads [\fIpatient\fP]
Returns a list of the thread tokens (\fBnot\fP handle ID's) for the patient.
.IP "resources [\fIpatient\fP]
eturns a list of the handle tokens for the resources of the current or given
patient. Again, these are \fBnot\fP the handle ID's, but the
Swat-internal tokens for use in the ``handle'' command.
.IP "path [\fIpatient\fP]
Returns the path to the patient's executable.
.IP "data [\fIpatient\fP]
Returns a list ``{\fIname\fP} {\fIfullname\fP} {\fIthread#\fP}''
.IP "all
Returns a list of tokens for all patients in the system.
.IP "find \fIname\fP
Takes the name of a patient to find (not its permanent name, but its
name in Swat) and returns the patient token for it.
'\"
'\"	PHANDLE
'\"
.xH "phandle (kernel|output)"
.LP
Print out a handle. Single argument \fInum\fP is the handle's ID number (if you
want it in hex, you'll have to indicate that with the usual radix specifiers
at your disposal)
'\"
'\"	PMAKE
'\"
.xH "pmake (misc)"
.LP
Recompile the current patient. Doesn't download the thing, though
'\"
'\"	POBJECT
'\"
.xH "pobject (output)"
.LP
Given the address of an object, prints it out in the proper format. For this
to work, the object's class definition must end in "Class" and the instance
structure type must end in "Instance", with both having the same prefix
(i.e. "BinClass" and "BinInstance" -- "BiffClass" and "BinInstance" would be
bad). Note also that the class record must have been declared public or this
will locate the wrong class.
'\"
'\"	PREG
'\"
.xH "preg (output)"
.LP
Print out the region at the given address. If first arg is -g, the region
is printed as a series of x's and spaces (useful only for small regions).
If no address given, uses the last-accessed address (as per "bytes" and
"words"). Sets the last address to the first byte after the region definition.
'\"
'\"	PRENUM
'\"
.xH "prenum (output)"
.LP
Prints a value as an element of an enumerated type. First argument is
the name of the enumerated type. Second argument is the value to map
to an element of the type.
'\"
'\"	PRECORD
'\"
.xH "precord (output)"
.LP
Print a value as if it were a record, decomposing it into the
individual bit-fields of the record. First argument is the name of the
record type, second is the value to print.
'\"
'\"	PRINT
'\"
.xH "print (output)"
.LP
Prints the value of an expression. The expression may span multiple
arguments (i.e. you don't need to put {}'s around it). An expression is
usually an address that has a type or that is given a type by casting. The
contents of memory of the given type at that address is what's printed. If
the expression has no type, its offset part is printed in both hex and
decimal. This is used for printing registers, eg.
.LP
If the first argument begins with '-', it is taken to contain flags that
control how the value is printed.  Multiple flags may be given in the same
argument (in fact, this only pays attention to the first argument). The
flags are:
.IP "x
integers (bytes, words, dwords if dwordIsPtr false) printed in hex
.IP "d
integers printed in decimal
.IP "o
integers printed in octal
.IP "c
bytes printed as characters (byte arrays printed as strings, byte
variables/fields printed as character followed by integer equivalent)
.IP "C
bytes treated as integers
.IP "a
align structure fields
.IP "A
Don't align structure fields
.IP "p
dwords are far pointers
.IP "P
dwords aren't far pointers
.LP
These flags operate on the following TCL variables:
.IP "intFormat
A printf format string for integers
.IP "byteAsChar
Treat bytes as characters if non-zero
.IP "alignFields
Align structure fields if non-zero
.IP "dwordIsPtr
DWord's are far pointers if non-zero
.IP "noStructEnum
If non-zero, doesn't print the "struct" or "enum" before the name of a
structured/enumerated type -- just gives the type name.
.IP "printRegions
If non-zero, prints what a Region * points to (bounds and so on).
.IP "condenseSpecial
If non-zero, condense special structures (Rectangles
and OutputDescriptors for now) to one line.
'\"
'\"	PRINTREGIONS
'\"
.xH "printRegions (variable.output)"
.LP
If non-zero, causes "print" to attempt to parse any region it finds,
printing out the size and bounds and type of region. Default value is 1
'\"
'\"	PRINTSTOP
'\"
.xH "printStop (variable.misc)"
.LP
If non-zero causes the current PC and the reason for stopping to be printed
each time the machine comes to a complete stop
'\"
'\"	PROC
'\"
.xH "proc (prog.proc|prog.tcl.proc|prog.def)"
.LP
This is used to define a new TCL procedure. It takes three arguments: the
name of the procedure, a list of arguments for it, and the body of it, which
will be evaluated when the command is invoked. The argument list is a list
of variable names or {\fIvar\fP \fIdefault\fP} pairs (these may be mixed, though it's
not very useful to place an arg with a default value before one with no
default in a list). The number of arguments given to the command must exactly
match the number of arguments in the list except in two cases:
.IP \(bu 2
if every unspecified argument has a default value, fewer may be given
.IP \(bu 2
if the last argument in the list is "args", more args may be given.
The excess arguments are bound into a list and assigned to the args
variable for the procedure. This allows for procedures that take a
variable number of arguments.
.LP
Procedures return values via the "return" command, which see.
'\"
'\"	PROMPT
'\"
.xH "prompt (prog.input)"
.LP
Print the value of the  prompt  variable and flush output. $prompt may
contain a single %s, which will be changed to be the name of the current
patient.
'\"
'\"	PROMPT
'\"
.xH "prompt (variable.input)"
.LP
Contains a format string for the command prompt. A single %s is replaced by
the name of the current patient. A single ! is replaced by the number of the
current command in the command history. These escapes may only be used once.
Note that to get a % in the prompt, you must use %% or you will get an error
'\"
'\"	PROTECT
'\"
.xH "protect (prog.tcl.error)"
.LP
Takes two commands as arguments and makes sure the second one gets executed
even if the first returns an error or executes return-to-top-level.
'\"
'\"	PS
'\"
.xH "ps (misc)"
.LP
Print out system status. Only one of the following flags may be given:
.IP "-p
Prints out info on all patients.
.IP "-t
Prints out info on all threads.
.IP "-h
Prints out info on all handles.
'\"
'\"	PSCOPE
'\"
.xH "pscope (obscure)"
.LP
Prints out all symbols in the given scope, or the current scope if
none given. If the scope is ".", the current scope is also used. If
the scope is "..", the parent of the current scope is used.
'\"
'\"	PTHREAD
'\"
.xH "pthread (kernel|output)"
.LP
Prints out information about thread ID
'\"
'\"	QUIT
'\"
.xH "quit (top)"
.LP
Causes the debugger to exit. If the argument "cont" is given, geos is
allowed to continue. If the argument "leave" is given, however, geos
remains stopped. If some other argument, or no argument, is given, it exits
to MS-DOS (if you're lucky).
'\"
'\"	RANGE
'\"
.xH "range (prog.list|prog.string|prog.tcl.list)"
.LP
This is used to extract pieces of a \fIvalue\fP (its first arg). The second and
third args \fIfirst\fP and \fIlast\fP specify what part of the value is to be extracted.
If the optional fourth arg is "chars", the \fIvalue\fP is treated as a string and
its fields are characters. Otherwise \fIvalue\fP is treated as a list. Fields are
numbered from 0. If \fIlast\fP is "end", the part extracted extends from the FIRSTth
field through the end of \fIvalue\fP, inclusive.
'\"
'\"	READ-CHAR
'\"
.xH "read-char (prog.input)"
.LP
Reads a single character from the user. In shell mode, this will
actually read an entire line and return just the first character...In
full-screen mode, optional first argument tells whether to
echo the read character. If non-zero, the character will be echoed once it's
read (this is the default).
'\"
'\"	READ-LINE
'\"
.xH "read-line (prog.input)"
.LP
Reads a single line of input from the user. If optional argument \fIcmd\fP is
non-zero, the line is interpreted as a TCL command and will not be returned
until all braces/brackets are balanced. The final newline is stripped.
Optional second argument is input to be placed in the buffer first.
'\"
'\"	READ-REG
'\"
.xH "read-reg (prog.patient|prog.thread|patient|thread)"
.LP
Returns the current value for register \fIreg\fP as a decimal number
'\"
'\"	READ-SFT
'\"
.xH "read-sft (prog.obscure)"
.LP
Returns as a list of structure-values all files in the System File Table in
order
'\"
'\"	REF
'\"
.xH "ref (reference)"
.LP
``ref routineName'' prints out the routine header for a function. If
no function is given, the function active in the current stack frame
is used. This command locates the function using a tags file, so that
tags file should be kept up-to-date
'\"
'\"	REGS
'\"
.xH "regs (top)"
.LP
Print out the current registers in a nice format. This includes the flags,
and the instruction at the current CS:IP
'\"
'\"	REGWIN
'\"
.xH "regwin (window)"
.LP
Turns on continuous display of registers
'\"
'\"	REQUIRE
'\"
.xH "require (prog|prog.load)"
.LP
require is used to ensure that a particular function is loaded. It takes
one or two arguments. The first is the function that must be resident,
while the second is a file from which to load it. If the command isn't
defined and a file isn't given, the name of the function will be used as
the file. E.g.
.DS
require call
.DE
will cause the filename ``call'' to be given to ``load'' for reading.
This command is mostly useful for functions that are not set up to autoload.
'\"
'\"	REPEATCOMMAND
'\"
.xH "repeatCommand (prog.input|variable.input)"
.LP
The command to execute should the user type only a newline. Set to nil by
top-level-read. A command that wishes to be repeated should set this to the
appropriate value (usually based on the value of lastCommand)
'\"
'\"	RESTORE-STATE
'\"
.xH "restore-state (prog.patient|prog.thread)"
.LP
Restores the most-recently saved set of registers for the current thread.
These registers are saved using the "save-state" command.
'\"
'\"	RET
'\"
.xH "ret (stack)"
.LP
Return from the function given as an argument. If no argument given, return
from the one at the top of the stack. Note this doesn't forcibly return from
the function, it merely lets the patient run until the function is done. q.v.
"finish"
'\"
'\"	RETURN-TO-TOP-LEVEL
'\"
.xH "return-to-top-level (prog)"
.LP
Returns to the top-level interpreter, unwinding all intermediate calls.
'\"
'\"	RETURN
'\"
.xH "return (prog.proc)"
.LP
This is used to return from a procedure, as defined by "proc" or one of the
"def" commands. If given an argument, that is the value returned by the
procedure. Otherwise, the empty string is returned.
'\"
'\"	RPC-DBG
'\"
.xH "rpc-dbg (obscure)"
.LP
Sets or returns the state of Swat's internal rpc debug flag. If arg is
given, it must be numeric and is assigned to 'debug'. Returns the current
state of the flag.
'\"
'\"	SAVE-STATE
'\"
.xH "save-state (prog.patient|prog.thread)"
.LP
Records the state of the current thread (its registers) for later
restoration by "restore-state".
'\"
'\"	SAVE
'\"
.xH "save (window)"
.LP
`save \fInumber\fP' sets the number of lines that are to be stored in the save\
buffer, which holds the most recent \fIN\fP lines of text.
.LP
`save \fIfilename\fP' writes the current contents of the save buffer to the
named file, overwriting the file's previous contents. Note that if just a
bare filename (no path) is specified, the current directory, as determined
by the current stack frame, is used.
.LP
In either case (or if no argument is given), save returns the greatest number
of lines that will be saved in the save buffer.
'\"
'\"	SCAN
'\"
.xH "scan (prog.string)"
.LP
This parses fields from an input string as does sscanf(3) (which see). The
only difference is %c produces a decimal number, not a character. Usage is
.IP "scan \fIstring\fP \fIformat\fP \fIVAR1\fP \fIVAR2\fP ...
'\"
'\"	SCOPE
'\"
.xH "scope (obscure)"
.LP
Change to a different scope. ".." changes to the parent of the
current scope. Note this does not change the current stack frame, but
only the scope used by such commands as "whatis" for symbol lookup,
thus all expressions are evaluated using symbols from the scope in the
current frame, NOT that set by this command.
'\"
'\"	SET-ADDRESS
'\"
.xH "set-address (prog.memory)"
.LP
Set the last-accessed address recorded for memory-access commands. Single
argument is an address expression to be used by the next memory-access
command (except via <return>). This allows a user to examine memory in
one mode, then switch to a different one to view the same data in a
different format.
'\"
'\"	SET-MASKS
'\"
.xH "set-masks (prog.obscure)"
.LP
Sets the interrupt masks used while the stub is active. First argument is
mask for controller 1, second, for controller 2.
'\"
'\"	SET-REPEAT
'\"
.xH "set-repeat (prog.input)"
.LP
Sets the command to be repeated, using a template string and the lastCommand
variable. The variables $0...$n substitute the fields 0...n from the
lastCommand variable, with the final result being placed in repeatCommand
to be executed should the user type just return.
'\"
'\"	SHOWCALLS
'\"
.xH "showcalls (profile)"
.LP
showcalls displays calls to various parts of PC GEOS.  The flags to showcalls
determine the types of calls displayed.  Invoking showcalls with no arguments
causes showcalls to be disabled.  Flags must be all given in the first argument
such as "showcalls -vl"
.IP "-v
Show calls to the video driver
.IP "-l
Show local memory init-heap, alloc, relloc, free, compact
.IP "-m
Show global memory alloc, free, realloc
.IP "-o
Show ObjSendOutput(Regs), Obj(Grab)CallInstance, Obj(Grab)CallClass
.IP "-e
Show ProcSend(Custom)Event
.IP "-w
Show WinOpen, WinClose, WinMoveResize, WinChangePriority,
WinStartUpdate WinEndUpdate
.IP "-d
Show dispatching of threads
.IP "-g
Show geometry manager resizing things
.IP "-r
Show region calculation calls
'\"
'\"	SLEEP
'\"
.xH "sleep (prog)"
.LP
Suspends Swat for a given number of seconds, or until a keyboard interrupt
occurs, whichever comes first. Input from the PC continues to be processed,
so a FULLSTOP event will be generated if the machine stops, but this command
won't return until the time has elapsed. The time is given as a real number
(e.g. 1.5) being the number of seconds for which to pause. Returns non-zero
if slept for the entire time.
'\"
'\"	SMATCH
'\"
.xH "smatch (top)"
.LP
Look for symbols of a given class by pattern. First argument \fIpattern\fP is the
pattern for which to search (it's a standard Swat pattern using shell wildcard
characters). Optional second argument \fIclass\fP is the class of symbol for which
to search and is given directly to the "symbol match" command. Defaults to
"any".
'\"
'\"	SORT
'\"
.xH "sort (prog.list)"
.LP
Sorts a list. Takes three optional flags: -n (treat elements as numbers,
with the usual radix specifiers possible), -r (sort in descending order) and
-u (make elements unique). Final argument is list to sort. Returns the
sorted list.
'\"
'\"	SOURCE
'\"
.xH "source (prog.load|prog.file)"
.LP
Reads the given file as a series of TCL commands. If the file can't be found,
".tcl" is appended to it and another attempt is made to read it.
'\"
'\"	SPAWN
'\"
.xH "spawn (thread|patient)"
.LP
Set a temporary breakpoint in a not-yet-existent process/thread,
waiting for a new one to be created. First argument is the permanent
name of the process to watch for.  Second argument is address
expression of where to place the breakpoint.  If no second argument is present,
the machine will be stopped and Swat will return to the command level.
.LP
This can also be used to catch the spawning of a new thread.
.LP
If the machine stops before the breakpoint can be set, you'll have to
do this again.
'\"
'\"	STEP-PATIENT
'\"
.xH "step-patient (prog.patient)"
.LP
Make the system execute a single instruction. No other thread will be
allowed to run, as the timer interrupt will be left off, so you shouldn't
allow the thread to context switch. Returns once the step is complete.
'\"
'\"	STEP
'\"
.xH "step (step)"
.LP
Make the patient execute a single machine instruction. If waitForPatient is
non-zero, waits for the machine to stop again. BEWARE: This doesn't do any
of the checks for special things (XchgTopStack, software interrupts, etc.)
performed by the s command in istep.
'\"
'\"	STOP-CATCH
'\"
.xH "stop-catch (prog.event)"
.LP
Execute the argument TCL clause, preventing a FULLSTOP event from being
dispatched (with associated return to the top level of the interpreter)
should the PC stop during the clause's execution. Returns the value of
the final command in the clause.
'\"
'\"	STOP-PATIENT
'\"
.xH "stop-patient (prog.patient)"
.LP
Stop the PC without going back to the top-level interpreter loop.
'\"
'\"	STREAM
'\"
.xH "stream (prog.load|prog.file)"
.LP
This command allows you to read and write files from TCL. Once a stream
is open, all access to it is via the token that the open subcommand returns.
The available subcommands are:
.IP "open \fIfile\fP \fImode\fP
\fImode\fP is one of r (read-only), w (write-only and truncate), a
(append), r+ (read/write, no truncate), w+ (read/write and truncate).
\fIfile\fP is any filename, but remember that the working directory varies
with the current stack frame.
.IP "read (line|list|char) \fIstream\fP
reads a line, list or character from a stream.
.IP "print \fIstring\fP \fIstream\fP
prints a string to the given stream so it can be read back in using
the "read list" subcommand. I.e. if the string is "foo biff", it
will be written to the stream as "{foo biff}\n".
.IP "write \fIstring\fP \fIstream\fP
writes the string to the stream, but doesn't parse backslash
sequences -- the string is written as-is.
.IP "rewind \fIstream\fP
zhurdd ehsyz?
.IP "seek (\fIposn\fP|+\fIincr\fP|-\fIdecr\fP|end) \fIstream\fP
Change the current position of the stream. \fIposn\fP sets it to
an absolute position. +\fIincr\fP advances the pointer, -\fIincr\fP
moves it back. end moves to the end. Returns the final position or
-1 if seek is improper or can't be performed.
.IP "state \fIstream\fP
Returns one of error, eof, or ok.
.IP "eof \fIstream\fP
Predicate to simplify things -- returns 1 if end-of-file has been
reached.
.IP "close \fIstream\fP
Shuts down a stream.
.IP "flush \fIstream\fP
For writable streams only: writes all buffered data to the stream
.LP
Streams are a somewhat limited commodity -- be sure to use "protect" to
ensure the closing of the stream should an error occur.
'\"
'\"	STRING
'\"
.xH "string (prog.string)"
.LP
Four options are available with this command:
.IP "string compare STR1 STR2
Compares STR2 to STR2 character-by-character, returning -1, 0 or 1
depending on whether STR1 is lexicographically less than, equal to,
or greater than STR2
.IP "string first STR1 STR2
Searches STR2 for a STR1 If found, returns the index of the first
character in the first such match. If not found, returns -1
.IP "string last STR1 STR2
Searches STR2 for the last occurrence of STR1. Returns the index of
the first character of the last such match. If none found, returns -1.
.IP "string match STR1 STR2
Takes STR2 to be a pattern as for filename wildcarding in the shell
and sees if STR1 matches that pattern. Returns non-zero if so.
'\"
'\"	SWITCH
'\"
.xH "switch (top|prog.thread)"
.LP
Switches between applications/threads. Takes a single argument of the form
\fIpatient\fP:\fIthread-num\fP or \fIthreadID\fP. With the first form, :\fIthread-num\fP is
optional -- if the patient has threads, the first thread is selected.
To switch to another thread of the same patient, give just :\fIthread-num\fP.
You can also switch to a patient/thread by specifying the thread handle ID.
NOTE: The switch doesn't happen on the PC -- just inside Swat.
.LP
If you don't give an argument, it switches to the actual current
thread in the PC.
'\"
'\"	SYM-DEFAULT
'\"
.xH "sym-default (top)"
.LP
Sets the patient to use when parsing an address expression should a symbol
not be defined in the current patient. You can use this if you're just going
to be debugging a single patient but its code might be called by another
patient and you want to have access to the symbols of the non-current one.
'\"
'\"	SYMBOL
'\"
.xH "symbol (prog)"
.LP
Used to access the symbol table. There are 8 types of symbols accessible
via this command. The classes, and the type of data stored with each, are:
.RS
.nr r \w'module   'u
.IP var \nru
All variables are of this type. It has a type (such as returned
by the "type" command), a storage class and an address. Each
storage class gives a different meaning to the address:
.RS
.nr q \w'regparam   'u
.IP static \nqu
Most variables are of this class. The address is
simply the offset into the variable's resource
segment
.IP register \nqu
The machine registers are of this class. The
address is the register number.
.IP local \nqu
For variables local to a function. The address
is the offset from the frame pointer (top of the
stack frame if no frame pointer in use).
.IP param \nqu
Same as local, but passed by callers.
.IP regparam \nqu
Like register, but passed by callers.
.RE
.IP module \nru
Resource segments/modules have symbols of this type. They contain
other symbols and nothing more.
.IP func \nru
Functions (proc's). These have two pieces of data: whether they
are near or far, and their offset in their segment.
.IP label \nru
Near and far labels. Same data as a function.
.IP type \nru
Used for named types. Only data are the type token describing the
type itself. These symbols may be freely interchanged with type
tokens.
.IP enum \nru
A named constant in an enumerated type.
.IP abs \nru
Also not well supported, though they may be used in address
expressions. An independent named constant.
.IP field \nru
A field in a structure. Contains only the structure type of
which the thing is a part.
.RE
.LP
The subcommands are many:
.nr q \w'fullname   'u
.IP scope \nqu
Returns a token for the module containing the given symbol.
.IP enter \nqu
Enters the symbol (2d arg) into a module (3d arg).
.IP name \nqu
Returns the name of a symbol.
.IP fullname \nqu
Returns the fully-qualified name of the symbol.
.IP class \nqu
Returns the class of the symbol.
.IP make \nqu
Creates an empty symbol of the given class (2d arg) and name
(3d arg). The symbol must later be entered if you want to
find it again.
.IP find \nqu
Takes two arguments: the allowed class(es) and the name. More
than one class may be specified by separating the classes
with |'s. The class "any" may also be given. Returns "nil"
if no appropriate symbol can be found.
.IP faddr \nqu
Takes two arguments: the allowed class(es), as above, and
an address expression.
.IP match \nqu
Takes the allowed classes (as for "find") and a wildcard
pattern as arguments. Returns a list of symbol tokens whose
names match the pattern (the list is empty if no symbols
matches the pattern). The pattern may not (yet) involve
a symbol-path.
.IP vset \nqu
Takes four args: symbol, type, storage class and address. The
symbol must be a var symbol. If the storage class is static,
the address may be any regular address expression. If it is
register, the address is a machine-register name. If it is
local or param, it is expected to be an integer. The address
may be given as nil if it is unknown.
.IP vget \nqu
Returns the three data for the given variable symbol as a
list: {\fItype\fP \fIstorage-class\fP \fIaddr\fP}
.IP fset \nqu
Sets the data for a func-class symbol. Four arguments:
.DS I
\fIsym\fP (near|far) \fIaddr\fP \fIfilename\fP
.DE
.IP lset \nqu
Sets the data for a label-class symbol: \fIsym\fP (near|far) \fIaddress\fP
.IP fget \nqu
Returns the list {(near|far) \fIaddr\fP \fIfilename\fP} for a
func-class symbol.
.IP lget \nqu
Returns a list {(near|far) \fIaddr\fP} for the label-class symbol.
.IP tset \nqu
Sets the type token for a type symbol. Two args are the symbol and the type
.IP tget \nqu
Returns the type token for a type symbol.
.IP aset \nqu
Sets the value for an abs symbol. Argument is an integer.
.IP aget \nqu
Returns the value of an abs symbol.
.IP mget \nqu
Returns the patient token for the owner of the module symbol.
.IP eset \nqu
Sets the constant and type for an enum symbol (args in that
order.
.IP eget \nqu
Returns the constant and source type for an enum symbol.
.IP Fget \nqu
Returns the type token stored with a field-class symbol.
'\"
'\"	SYMBOLCOMPLETION
'\"
.xH "symbolCompletion (variable.input)"
.LP
If non-zero, enables symbol completion in the command reader. An escape causes
the reader to supply the longest common prefix of all symbols that begin with
what you've typed so far. If the prefix begins more than one symbol, it will
beep to tell you this. If you type control-D, the reader will print out all the
possible completions. Typing control-] causes it to cycle through the possible
symbols, in alphabetical order
'\"
'\"	SYSFILES
'\"
.xH "sysfiles (kernel)"
.LP
Prints out all open files in the system in tabular form.
'\"
'\"	SYSTEM
'\"
.xH "system (prog.external)"
.LP
Cause a shell to execute the first argument. The shell used is the
bourne shell, so tilde's aren't expanded. Doesn't return until the
command completes and the output isn't saved anywhere.
'\"
'\"	SYSFILES
'\"
.xH "sysfiles (kernel)"
.LP
Prints out all open files in the system in tabular form..
'\"
'\"	TABLE
'\"
.xH "table (prog)"
.LP
`table' is used to create, manipulate and destroy hash tables. The entries
in the table are keyed on strings and contain strings, as you'd expect from
TCL. The following subcommands are available:
.IP "create [\fIinitBuckets\fP]
Creates a new table and returns a token for it, to be used in all
future calls to this command. The optional parameter, \fIinitBuckets\fP,
specifies the initial number of buckets the table should contain.
The table will expand to maintain hashing efficiency should the need
arise, so this isn't a number that need be carefully chosen. If you
don't give a number, or the number is zero, a default of 16 is used.
.IP "destroy \fItable\fP
Frees up all memory associated with the table. The token should
never again be used.
.IP "enter \fItable\fP \fIkey\fP \fIvalue\fP
Enters \fIvalue\fP in \fItable\fP under the given \fIkey\fP. Any data
previously entered under \fIkey\fP are lost.
.IP "lookup \fItable\fP \fIkey\fP
Searches \fItable\fP for the data stored under \fIkey\fP. If no data are
stored, returns \fBnil\fP, else the data themselves.
.IP "remove \fItable\fP \fIkey\fP
Removes any data stored in \fItable\fP under \fIkey\fP.
'\"
'\"	TCL-DEBUG
'\"
.xH "tcl-debug (prog.debug)"
.LP
Access to interpreter internals for debugger
'\"
'\"	THREAD
'\"
.xH "thread (prog|prog.thread)"
.LP
Returns information about a thread. A thread token can be obtained via the
"patient threads" command or "handle other" on a thread handle. The
options are:
.IP "id \fIthread\fP
Returns the handle ID of the thread.
.IP "register \fIthread\fP \fIregname\fP
Returns the contents of the register for the thread.
.IP "handle \fIthread\fP
Returns the handle token for the thread.
.IP "endstack \fIthread\fP
Returns the bottom of the stack for the thread.
.IP "number \fIthread\fP
Returns the number of the thread in its own universe (e.g. the
application thread is thread 0)
.IP "all
Returns a list of tokens for all known threads.
'\"
'\"	THREADSTAT
'\"
.xH "threadstat (kernel)"
.LP
Print info about all threads in the system
'\"
'\"	TIMINGPROCESSOR
'\"
.xH "timingProcessor (variable)"
.LP
The processor for which to generate cycle counts. One of 8086, 8088 or 80286
'\"
'\"	TMEM
'\"
.xH "tmem (kernel)"
.LP
Trace memory usage. Catches calls to DebugMemory, printing out the parameters
passed
'\"
'\"	TOP-LEVEL
'\"
.xH "top-level (prog.input)"
.LP
Top-level command loop. Calls the function "top-level-read" and evaluates
the line it returns, printing out the result. Loops infinitely or until
"break" is executed.
'\"
'\"	TOP-LEVEL-READ
'\"
.xH "top-level-read (prog.input)"
.LP
This is the main command input loop, handling command history and
symbol completion. If you don't need these things, use the
\fBread-line\fP command instead.
.LP
top-level-read accepts three optional arguments in the following order:
.DS I
.ta \w'Argument   'u +\w'$prompt   'u
\kqArgument	Default	Meaning\l'\nqu_'
prompt	$prompt	The template to use for issuing the prompt. See the ``prompt''
		variable/command documentation.
line	empty	Initial line contents. The user is allowed to edit these
		characters, but the caller must actually print them for the
		user to know they're there.
history	1	Non-zero if should perform standard command-history
		substitution on the line before returning it.
.DE
'\"
'\"	TYPE
'\"
.xH "type (prog)"
.LP
Creates, destroys and returns tokens for type descriptions. Possible sub-
commands are:
.IP "word, byte, dword, qword, tbyte, sbyte, short, long, int, void
Returns a token for the appropriate basic type.
.IP "make array \fIlength\fP \fIbase-type\fP
Creates a type for an array of \fIlength\fP \fIbase-type\fP elements
.IP "make pstruct \fIfield\fP \fItype\fP \fIfield\fP \fItype\fP ...
Creates a "packed structure" where the fields follow immediately
after each other. \fIfield\fP is the name of the field and \fItype\fP is its
type, which is a token returned by this command (i.e. "word" isn't
acceptable, you should use "[type word]")
.IP "make struct \fIfield\fP \fItype\fP \fIbit-offset\fP \fIbit-length\fP ...
Creates a structure whose fields needn't be packed together or a
multiple of a byte long -- can be used to create a RECORD, e.g. --
but if so, the structure MAY NOT be more than a word long and must
consist entirely of such bit-fields. If you must have mixed fields,
create one of these and nest it inside another structure type.
\fIfield\fP is again the field name, while \fItype\fP is the base type in
which the field sits (either [type byte] or [type word]). \fIbit-
offset\fP is the offset from the start of the byte/word in bits, while
\fIbit-length\fP is the length of the field, again in bits.
.IP "make (nptr|fptr|sptr|lptr|hptr|optr) \fItype\fP
Creates a type that's a pointer to the given one.
nptr is a near pointer, fptr is a far pointer, sptr is a segment-only
pointer, lptr is an lmem handle, hptr is a global handle, optr is
an object pointer (local and global handles in low and high words,
respectively).
.IP "make enum
Creates a type to which enums may be added (using 'symbol make enum')
.IP "delete \fItype\fP
Deletes a previously-defined type. This should be done whenever
possible to avoid wasted memory.
.IP "size \fItype\fP
Returns the size of the type in bytes.
.IP "class \fItype\fP
Returns the class of the type: char, int, struct, enum, array,
pointer.
.IP "name \fItype\fP \fIvarname\fP \fIexpand\fP
Returns the formatted name of a type. \fIvarname\fP is the name of the
variable to which the type belongs (placed at the proper point in the
result). If \fIexpand\fP is non-zero, structure types are expanded to
display their fields.
.IP "aget \fIarray-type\fP
Returns a four-element list containing the token for the base type of
the array, the lower bound for the array's index, the upper bound
for the index and the token for the index's type.
.IP "fields \fIstruct-type\fP
Returns a list of four-tuples {name offset length type}, one for each
field in the structure. offset and length are BIT offsets from the
start of the structure.
.IP "members \fIenum-type\fP
Returns a list of {name value} pairs for the members of the
enumerated type.
.IP "pget \fIptr-type\fP
Returns the type of pointer (near, far, seg, lmem, handle) and the
type to which it points.
.IP "emap \fInum\fP \fItype\fP
Maps a constant \fInum\fP to the proper member of the enumerated \fItype\fP
.IP "signed \fItype\fP
Returns non-zero if the type is signed.
.IP "field \fItype\fP \fIoffset\fP
Returns a string of the form \fIfield\fP.\fIfield\fP... that is the smallest
field in the, possibly nested, structure \fItype\fP that covers the
byte \fIoffset\fP bytes from the start of the structure.
'\"
'\"	UNALIAS
'\"
.xH "unalias (top)"
.LP
Removes any alias for its argument. See "alias" for more information
'\"
'\"	UNASSEMBLE
'\"
.xH "unassemble (prog.memory)"
.LP
Disassembles instruction at an address. If no address is given, or the
address is the constant "nil", the value of the pc is used. If a second
argument is given and non-zero, the arguments to the instruction are decoded
as well. The result is a 4-element list of the format:
.DS I
{\fIsymbolic address\fP} {\fIinstruction\fP} {\fIsize\fP} {\fIargs\fP}
.DE
If the arguments aren't requested, {args} will be empty
'\"
'\"	UNDEBUG
'\"
.xH "undebug (prog.debug)"
.LP
Removes a breakpoint from a tcl command.
'\"
'\"	UP
'\"
.xH "up (stack|top)"
.LP
Given an argument n, shifts the current frame up n frames. If no argument is
given, makes the next frame up the stack (where "up" is away from the top) be
the current frame.
'\"
'\"	VALUE
'\"
.xH "value (prog.patient|prog.memory)"
.LP
Primitives for accessing and altering values in the patient. Usage is:
.IP "fetch \fIaddress\fP \fItype\fP
Returns an appropriately-formatted list of the value. All integers are
in decimal. If \fItype\fP is a structure, the list is an assoc list of
{\fIfield-name\fP \fItype\fP \fIvalue\fP} pairs. If \fItype\fP is an
array, it is a list of the elements, properly formatted. Else, the
list is just the single value at the given address. If \fIaddress\fP
has an implied type (i.e. it uses a variable symbol), \fItype\fP may
be omitted.
.IP "store \fIaddress\fP \fItype\fP \fIdata\fP
\fIaddress\fP and \fItype\fP are as above (if \fItype\fP is to be omitted, it
should be given as "nil". \fIdata\fP is a list formatted as above.
This is not yet implemented. To change memory from a program, you must
use the \fBassign\fP command.
.IP "hfetch \fInum\fP
Return the {handle offset type} list for the \fInum\fPth element of the
value history.
.IP "hstore \fIaddr-list\fP
Store the {handle offset type} list \fIaddr-list\fP in the value history,
returning the number under which it was stored.
.IP "hset \fInumberSaved\fP
Set the number of values saved in the value history. Starts out at 50
and may be extended indefinitely. At least one value must be saved, however.
'\"
'\"	VAR
'\"
.xH "var (prog.tcl.var|top)"
.LP
Accepts a variable name and an optional value as arguments. If no value is
given, returns the value of the variable (if the variable isn't defined,
returns the empty string). The value of a variable may also be found using
a $ construct. In this case, however, the variable name must begin with a
letter and may consist only of letters, digits and underscores. If a value is
given, that value is assigned to the variable. If invoked in a procedure on a
variable that has not been declared global (using the "global" command), this
applies to the \fIlocal\fP variable of the given name. Multiple variables may be
assigned "in parallel" by giving successive variable name/value pairs as
arguments.
'\"
'\"	VI
'\"
.xH "vi (top)"
.LP
Invoke "vi" using the given arguments. If none given, and the source file
in which the patient is executing is known, edit that file. If the source file
isn't known, does a "vi -t \fIfunction-name\fP" where \fIfunction-name\fP is the name
of the function in the current frame.
'\"
'\"	VIF
'\"
.xH "vif (misc)"
.LP
VI the given function.
'\"
'\"	WAIT
'\"
.xH "wait (prog.patient)"
.LP
Waits for the patient to stop executing, for whatever reason. Returns 0
if the patient halted naturally and 1 if it was interrupted.
'\"
'\"	WAITFORPATIENT
'\"
.xH "waitForPatient (variable.obscure)"
.LP
If non-zero, the command-level patient-continuation commands (step, next
and cont, e.g.) will wait for the machine to stop before returning. Otherwise,
they will return right away and you will have to use stop-patient to make
the machine stop. This isn't fully tested and should only be set 0 in
very weird circumstances
'\"
'\"	WAKEUP-THREAD
'\"
.xH "wakeup-thread (prog.thread)"
.LP
Subroutine to actually wake up a thread. Argument \fIwho\fP is as for the "switch"
command. Returns non-zero if the wakeup was successful and zero if the machine
stopped for some other reason.
'\"
'\"	WAKEUP
'\"
.xH "wakeup (thread|patient)"
.LP
Wait for a given patient/thread to wake up. \fIwho\fP is of the same form as the
argument to the "switch" command, ("help switch" to find out more). Leaves
you stopped in the kernel in the desired thread's context unless something
else causes the machine to stop before the patient/thread wakes up. \fIwho\fP
defaults to the current thread.
'\"
'\"	WCLEAR
'\"
.xH "wclear (prog.window)"
.LP
Clears the current window to blanks
'\"
'\"	WCREATE
'\"
.xH "wcreate (prog.window)"
.LP
Create a window of the given height and return a token for it. The window
is placed just above the command window, if there's room. If there aren't
that many lines free on the screen, an error is returned.
'\"
'\"	WDELETE
'\"
.xH "wdelete (prog.window)"
.LP
Delete the given window. All windows below it move up and the command window
enlarges.
'\"
'\"	WHATIS
'\"
.xH "whatis (symbol)"
.LP
Describes an expression, giving its type in detail. The expression may be a
complex expression, a symbol or a type name.
'\"
'\"	WHY
'\"
.xH "why (misc)"
.LP
Returns the enumerated constant for the error code in AX
'\"
'\"	WINVERSE
'\"
.xH "winverse (prog.window|prog.output)"
.LP
Sets the inverse-mode of the current window (whether newly-echoed characters
are displayed in inverse video) on or off, depending on its argument (1 is on
as usual).
'\"
'\"	WMOVE
'\"
.xH "wmove (prog.window)"
.LP
Moves the cursor for the current window. Takes two arguments: the new x
position and the new y position. These positions may be absolute (0-origin)
or relative (begin with + or -). If you attempt to move outside the current
window, an error is generated. Returns the new cursor position as {\fIx\fP \fIy\fP}.
'\"
'\"	WORDS
'\"
.xH "words (memory)"
.LP
Examine memory as words. First argument is address to examine. If it is
not given or is "nil", the next address (the one after the most-recently
examined memory location) is used. Second argument is number of words to
examine. This defaults to 8.
'\"
'\"	WPOP
'\"
.xH "wpop (prog.window)"
.LP
Revert the current window to what it was before.
'\"
'\"	WPROC
'\"
.xH "wproc (prog)"
.LP
Writes a command procedure \fIname\fP out to the file \fIfile\fP. If optional third
arg \fIappend\fP is non-zero, the procedure will be appended to the file. Otherwise
it will overwrite the file. This does not know if a procedure is a subroutine.
'\"
'\"	WPUSH
'\"
.xH "wpush (prog.window)"
.LP
Switch to a new window, saving the old current-window. Use wpop to go back
to the previous window. All I/O goes through the current window.
'\"
'\"	WREFRESH
'\"
.xH "wrefresh (prog.window)"
.LP
Synchronizes the current window with the screen. This need only be performed
if you don't echo a newline, as echoing a newline refreshes the current
window.
'\"
'\"	WTOP
'\"
.xH "wtop (window)"
.LP
Sets where windows go. If argument is non-zero, windows go at the top of the
screen and work down. Else windows go at the bottom of the screen and work up
'\"
'\"	XREF
'\"
.xH "xref (reference)"
.LP
``xref routineName'' prints out a cross reference for the given kernel
function.  If no function is given, the function active in the current
frame is used.
.TC
