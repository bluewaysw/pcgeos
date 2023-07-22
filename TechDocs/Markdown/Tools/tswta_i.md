## 4 Swat Reference

This chapter is intended to provide documentation for the majority of useful 
Swat commands. The general structure of the descriptions in this chapter 
will be as follows:

**Usage:**	Shows the command and its various arguments and subcommands (if any).

**Examples:**	Examples of the command as it could be used.

**Synopsis:**	Summary of the command and its functions and results.

**Notes:**	Details about the subcommands, arguments, and other command features.

**See Also:**	Other related commands.

### 4.1 Notation

The descriptions of the Swat commands will follow the following notational 
conventions:

+ `command (alternative1|alternative2|...|alternativeN)`  
() The parentheses enclose a set of alternatives separated by a vertical 
line. For example, the expression `quit (cont|leave)` means that either 
quit cont or quit leave can be used.

+ `command [optional_argument]`  
[] The brackets enclose optional arguments to the command. For 
example, the command `alias [<word[<command>]>]` could have zero, 
one, or two arguments because the `<command>` and `<word>` arguments 
are optional. Another example would be the command `objwalk 
[<addr>]`, which may take zero arguments if it is meant to use the 
default address, and one argument if the user gives it a particular 
address to look at.

+ `command <type_of_argument>`  
< > The angled brackets enclose the type of an argument rather than the 
actual string to be typed. For example, `<addr>` indicates an address 
expression and `<argument`> indicates some sort of argument, but 
`(addr|type)` means either the string addr or the string type.

+ `*   +`  
An asterisk following any of the previous constructs indicates zero or 
more repetitions of the construct may be typed. An addition sign 
indicates one or more repetitions of the construct may be used. For 
example, `unalias word*` can be the unalias command by itself, or it can 
be followed by a list of words to be unaliased.

### 4.2 Swat Reference A-I

----------

### _print

**Usage:**  
`_print <expression>`

**Examples:**  
`_print ax-10` print ax less 10 decimal.

**Synopsis:**  
Print the value of an expression.

**Notes:**  
The difference between this command and the "print" command is a subtle 
one: if one of the arguments contains square-brackets, the Tcl interpreter will 
attempt to evaluate the text between the brackets as a command before 
_print is given the argument. If the text between the brackets is intended to 
be an array index, the interpreter will generate an error before the Swat 
expression evaluator has a chance to decide whether the text is a nested Tcl 
command or an array index.

 For this reason, this function is intended primarily for use by Tcl procedures, 
not by users.

**See Also:**  
print, addr-parse.

----------

### abort

**Usage:**  
`abort [<frame-number>]`  
`abort [<function>]`

**Examples:**  
`abort`	 abort executing the current frame.  
`abort 3` 	abort executing up through the third frame.  
`abort ObjMessage` abort executing up through first ObjMessage.

**Synopsis:**	 Abort code execution up through a given frame or routine. By "abort", we me 
"do not execute". This can be quite dangerous, as semaphores may not be 
ungrabbed, blocks not unlocked, flags not cleared, etc., leaving the state of 
objects, and if executing system code, possibly the system itself in a bad state. 
This command should only be used when the only alternative is to to detach 
(i.e. in a fatal error) as a way to possibly prolong the usefulness of the 
debugging session.

**Notes:**

+  If no argument is given, code through the current frame is aborted.
  
+  `<frame num>` are the numbers that appear at the left of the backtrace.

**See Also:**  
finish, backtrace, zip.

----------

### abortframe

**Usage:**  
`abortframe <frame-token>`

**Examples:**  
`abortframe $cur`
Abort all code execution through the frame whose token is in 
$cur.

**Synopsis:**  
Aborts code execution up through a particular stack frame. As no code is 
executed, the registers may be in a garbaged state.

**Notes:**	

+ The argument is a frame token, as returned by the "frame" command.

+ No FULLSTOP event is dispatched when the machine actually aborts 
executing in the given frame. The caller must dispatch it itself, using the 
"event" command. For information about FULLSTOP events, see the 
event Tcl command.

+ The command returns zero if the machine aborted executing in the given 
frame; non-zero if it was interrupted before that could happen. 

----------

### addr-parse

**Usage:**  
`addr-parse <addr> [<addr-only>]`

**Examples:**  
`addr-parse *ds:si` 
Parse the address "*ds:si" into its handle, offset and data-type 
components. In this case, the data-type will be "nil".

`addr-parse ILLEGAL_HANDLE 0` 
Figures the value for the enumerated constant 
"ILLEGAL_HANDLE". The handle for this non-address will be 
"value".

**Synopsis:**  
This command parses the address expression into its components, returning 
a list `{<handle> <offset> <type> }` as its value.

**Notes:**	

+ This will generate an error if there's an error parsing the `<addr>` 

+ `<handle>` is the token for the handle in which the address resides, or "nil" 
if the address is absolute. This token can be given to the "handle" 
command for further processing. 

+ `<offset>` is a decimal number and is the offset of the address within the 
block indicated by the <handle> token. If `<handle>` is "nil", this can be a 
32-bit linear address. 

+ `<type>` is a type token for the data at the given address, if any could be 
determined. For example the address "ds:bx" has no type, as it's just a 
memory reference, but "ds:bx.VDE_extraData" will have whatever type 
the structure field "VDE_extraData" possesses. This token can be passed 
to the "type" or "value" commands for further processing.

+ If the expression doesn't refer to data that can be fetched from the patient 
(e.g. "foo*3") `<handle>` will be returned as the string "value" instead of a 
normal handle token. `<offset>` is then a value-list for the resulting value, 
and `<type>` is the type description by means of which the value list can 
be interpreted. 

+ The optional `<addr-only>` argument is zero or non-zero to indicate the 
willingness or unwillingness, respectively, of the caller to receive a value 
list in return. If `<addr-only>` is absent or non-zero, any expression that 
can only be expressed as a value will generate an error. The single 
exception to this is if the expression involves pointer arithmetic. For 
example "pself+1" normally would be returned as a value list for a far 
pointer, as the result cannot be fetched from the PC. When `<addr-only>` 
is absent or non-zero, "addr-parse" pretends the expression was 
"*(pself+1)", allowing simple specification of an address by the user for 
those commands that just address memory.

+ The `<offset>` element of the returned list is very useful when you want to 
allow the user to give you anything, be it a register or a number or an 
enumerated constant or whatever. You can pass the argument you were 
given to `[index [addr-parse $arg] 1]` and end up with an appropriate 
decimal number. Be sure to pass `<addr-only>` as 0, however, or else you'll 
generate an error. 

**See Also:**  
value, handle, type.

----------

### addr-preprocess

**Usage:**  
`addr-preprocess <addr> <seg-var> <off-var>`

**Examples:**  
`addr-preprocess $args s o` 
Parse the address expression in $args, storing the segment 
portion in $s and the offset portion in $o in the current scope.

**Synopsis:**  
Preprocesses an address expression into a form that is easier to manipulate 
and faster to reparse.

**Notes:**	

+ `<seg-var>` is the name of a variable in the caller's scope in which the 
segment of the address is stored. It should be treated as opaque, as it may 
or may not be numeric. 

+ `<off-var>` is the name of a variable in the caller's scope in which the offset 
of the address is stored. This will always be numeric. 

+ Returns the 3-list returned by addr-parse, in case you have a use for the 
type token stored in the list. 

**See Also:**  
addr-parse.

----------

### addr-with-obj-flag

**Usage:**  
`addr-with-obj-flag`

**Examples:**  
`var addr [addr-with-obj-flag $addr]` 
If $addr is `-i`, returns the address of the current implied grab.

**Synopsis:**  
This is a utility routine that can be used by any command that deals with 
objects where the user may reasonably want to operate on the leaf object of 
one of the hierarchies, or the windowed object under the mouse. It can be 
given one of a set of flags that indicate where to find the address of the object 
on which to operate.

**Notes:**	

+ Special values accepted for `<address>`:

>**Value** - Returns address expression for-  
**-a** - the current patient's application object  
**-i** - the current "implied grab": the windowed object over which the 
mouse is currently located  
**-f** - the leaf of the keyboard-focus hierarchy  
**-t** - the leaf of the target hierarchy  
**-m** - the leaf of the model hierarchy  
**-c** - the content for the view over which the mouse is currently 
located  
**-kg** - the leaf of the keyboard-grab hierarchy  
**-mg** - the leaf of the mouse-grab hierarchy

+ If `<address>` is empty, this will return the contents of the local variable 
"oself" within the current frame, if it has one, or *ds:si 

+ If `<address>` isn't one of the above, this just returns `<address>`. 

**See Also:**  
impliedgrab, content, focusobj, targetobj, modelobj, keyboardobj, mouseobj.

----------

### alias

**Usage:**	`alias [<name> [<body>]]`

**Examples:**  
`alias p print` 
Execute "print" when the user types the command "p". Any 
arguments to "p" get passed to "print" in the order they were 
given.

 `alias while {for {} $1 {} $2}` 
Executes an appropriate "for" loop when the "while" command 
is executed with its two arguments: a test expression and a 
body of commands to execute. 

`alias` 	Prints all the defined aliases.

`alias while` 
Prints what the "while" command is aliased to.

**Synopsis:**  
This is a short-cut to allow you to make commands you commonly type easier 
to use, and to define simple new commands quickly.

**Notes:**	

+ If you give no arguments the current aliases are all displayed.

+ If you give a single argument, the name of an existing alias, the command 
that will be executed when you use the alias is printed.

+ The `<body>` string is usually in curly braces, as it usually involves 
whitespace and can contain newlines for the longer aliases.

+ You can use the pseudo-variables $1, $2, etc. in the <body> to represent 
the 1st, 2nd, etc. argument given when the alias is invoked. They are 
pseudo-variables as the "var" command will not operate on them, nor are 
they available to any procedure invoked by the alias.

+ You can also interpolate a range of the arguments using `$<start>-<end>`. 
If you do not give an `<end>`, then the arguments from `<start` to the last 
one will be interpolated.

+ `$*` will interpolate all the arguments.

+ `$#` will interpolate the actual number of arguments.

+ If you do not use any of these pseudo-variables, all the arguments given 
to the alias will be appended to the `<body>`.

+ Interpolation of the values for these pseudo-variables occurs regardless 
of braces in the `<body>`.

+ It is an error to specify an argument number when there are fewer than 
that many arguments given to the alias.

**See Also:**  
unalias.

----------

### alignFields

**Usage:**  
`var alignFields [(0|1)]`

**Examples:**  
`var alignFields 1"` 
Sets the "print" command to align the values for all the fields of 
a given structure.

**Synopsis:**  
Determines whether structure-field values follow immediately after the field 
name or if all values are indented to the same level. The "print" command 
and other display commands use this variable when formatting their output.

**Notes:**	

+ Having all values indented to the same level makes it easier for some 
people to locate a particular field in a structure. It is not without cost, 
however, in that Swat must determine the length of the longest field 
name before it can print anything. 

+ The default value for this variable is zero.

**See Also:**  
print.

----------

### antifreeze

**Usage:**  
`antifreeze <patient>`  
`antifreeze :<n>`  
`antifreeze <patient>:<n>`  
`antifreeze <id>`

**Examples:**  
`antifreeze term`
Promotes the application thread for "term" to be the 
"most-runnable"

`antifreeze :1`
Does likewise for thread #1 of the current patient

`antifreeze 16c0h` 
Does likewise the thread whose handle is 16c0h

`antifreeze`	Promotes the current thread to be the "most-runnable."

**See Also:**  
freeze 

----------

### antithaw

**Usage:**  
`antithaw <patient>`  
`antithaw :<n>`  
`antithaw <patient>:<n>`  
`antithaw <id>`

**Examples:**  
`antithaw term`
Allows the application thread for "term" to run normally.

`antithaw :1`
Allows thread #1 of the current patient to run normally.

`antithaw 16c0h` 
Allow the thread whose handle is 16c0h to run normally.

**See Also:**  
thaw

----------

### appobj

**Usage:**  
`appobj [<patient>]`

**Examples:**  
`pobj [appobj draw]` 
prints the GenApplication object for draw.

`pobj [appobj]`
prints the GenApplication object for the current application 
(equivalent to "pobj -a").

**Synopsis:**  
Returns the address of the GenApplication object for the given patient, or the 
current one if you give no patient.

**See Also:**  
impliedgrab.

----------

### apropos

**Usage:**  
`apropos [<string>]`

**Examples:**  
`apropos vis` 
Find all commands related to vis

`apropos text` 
Find all commands related to text 

**Synopsis:**  
Search the list of commands and command help for all entries containing 
`<string>`. Lists each command and its synopsis. 

**Notes:**  
`<string>` may actually be a pattern, as described in the help for the "string" 
command (under "string match"). It automatically has a leading and 
following * tacked onto it to cause it to match anywhere within a help string.

**See Also:**  
help.

----------

### aset

**Usage:**  
`aset <array-name> <index> <value>`

**Examples:**  
`aset foo $i $n`
Sets the $i'th element (counting from zero) of the value stored 
in the variable foo to $n.

**Synopsis:**  
Allows you to treat a list stored in a variable as an array, setting arbitrary 
elements of that array to arbitrary values.

**Notes:**	

+ `<array-name>` is the name of the variable, not the value of the variable 
to be altered.

+ This command returns nothing.

+ The index must be within the bounds of the current value for the 
variable. If it is out of bounds, aset will generate an error.

**See Also:**  
index.

----------

### assoc

**Usage:**  
`assoc <list> <key>`

**Examples:**  
`assoc $classes GenPrimaryClass`
Examines the sublists of $classes and returns the first one 
whose first element is the string GenPrimaryClass.

**Synopsis:**  
Searches an associative list to find an element with a particular key. The list 
is itself made up of lists, each of whose first element is a key.

**Notes:**	

+ A typical associative list is made of key/value pairs, like this:
 `{ {<key> <value>} {<key> <value>} ...}`

+ If an element is found whose `<key>` matches the passed <key>, the entire 
element is returned as the result. If no `<key>` matches, nil is returned.

**See Also:**  
car, cdr, range, list, delassoc.

----------
### assign

**Usage:**  
`assign <addr> <value>`

**Examples:**  
`assign ip ip+2` 	
Add 2 to the value of IP in the current frame.

`assign {word ds:si} 63h` 
Store 63h in the word at ds:si

**Synopsis:**  
Performs an assignment to a patient variable or register (but not to an 
element of the value history). The first argument is the variable or register 
to be assigned and the second argument is the value to assign to it (which 
may be a regular address expression). If the first expression doesn't indicate 
a type, "word" is assumed. Only **byte**, **word** or **dword** types are supported.

**Notes:**	

+ When assigning to an sptr, the value assigned will be the segment of the 
block indicated by the `<value>`, unless `<value>` is an absolute address (or 
just a number), in which case the low 16 bits of the offset will be used 
instead.

+ Similar behavior occurs when assigning to an fptr, except if the `<value>` 
is an absolute address, in which case the linear address in the offset 
portion of the `<value>` will be decomposed into a segment and an offset.

**See Also:**  
imem, value

----------

### att

**Usage:**  
`att [<args>]`

**Examples:**  
`att`	attach Swat to GEOS.

**Synopsis:**  
Attach Swat to GEOS.

**Notes:**  
The args argument can be one of the following:

**-s** - reboot GEOS with error checking, attach, and stop

**-sn** - reboot GEOS without error checking, attach, and stop

**-f** - restart GEOS with error checking and attach after a pause

**-r** - restart GEOS with error checking and attach

-**rn** - restart GEOS without error checking and attach

**See Also:**  
detach, quit.

----------

### attach

**Usage:**  
`attach [<boot>]`

**Examples:**  
`attach` attach to the target PC

**Synopsis:**  
Attach swat to the target PC.

**Notes:**  

+ The boot argument is "-b" to bootstrap and "+b" to not. Normally, Swat 
will try to read symbolic information about all running geodes; 
bootstrapping specifies that Swat should only read symbolic information 
for these geodes when it must. 

+ If you give no `<boot>` argument, swat will use the most-recent one.

+ By default, swat will locate the symbols for all geodes and threads active on the PC when it attaches.

+ If any geode has changed since you detached from the PC, its symbols are 
re-read.

**See Also:**  
att, detach, quit.

----------
### autoload

**Usage:**  
`autoload <function> <flags> <file> [<class> <docstring>]`

**Examples:**  
`autoload cycles 1 timing`  
load the file "timing.tcl" when the cycles command is first 
executed. The user must type the command completely.

`autoload print 2 print`  
load the file "print.tcl" when the print command is first 
executed. The user may abbreviate the command and the Tcl 
interpreter will not evaluate its arguments.

**Synopsis:**  
This command allows the first invocation of a command to automatically 
force the transparent reading of a file of Tcl commands.

**Notes:**  

+ autoload takes 3 or 5 arguments: the command, an integer with bit flags 
telling how the interpreter should invoke the command, the file that 
should be read to define the command (this may be absolute or on 
load-path) and an optional help class and string for the command.

+ The help class and string need only be given if the file to be loaded isn't 
part of the system library (doesn't have its help strings extracted when 
Swat is built).

+ The `<flags>` argument has the following bit-flags:

    `0` - User must type the command's name exactly. The command 
will be defined by "defsubr" or "defdsubr" when `<file>` is loaded.

    `1` - The interpreter will not evaluate arguments passed to the 
command. All arguments will be merged into a single string 
and passed to the command as one argument. The command 
will use the special "noeval" argument when it is defined.

**See Also:**  
defsubr, defdsubr, defcommand, proc.

----------

### backtrace



**Usage:**  
`backtrace [-r<reg>* ][<frames to list>]`

**Examples:**  
`backtrace` print all the frames in the patient

`backtrace -rax`
print all the frames and the contents of AX in each one.

`where 5` print the last five frames

`w 5"` print the last five frames

**Synopsis:**  
Print all the active stack frames for the patient.

**Notes:**

+ The `<frames to list>` argument is the number of frames to print. If not 
specified, then all are printed.

+ If a numeric argument is not passed to backtrace then it attempts to 
display method calls in the form:

    `MSG_NAME(cx, dx, bp) => className (^l####h:####h)`

    Here `<cx>`, `<dx>`, and `<bp>` are the values passed in these registers. 
`<className>` is the name of the class which handled the message. 
^l####h:####h is the address of the object (block, chunk handle) 
handling the message.

+ If a numeric argument is passed to backtrace then the attempt to decode 
the message is not done and the single line above expands into:

    `far ProcCallModuleRoutine(), geodesResource.asm:476`
`near ObjCallMethodTable(), objectClass.asm:1224`

    This is generally less useful, but sometimes it's what you need. 

**See Also:**  
up, down, func, where.

----------

### bindings



**Usage:**  
`bindings`

**Synopsis:**  
Shows all current key bindings

----------

### bind-key

**Usage:**  
`bind-key <ascii_value> <function>`

**Examples:**	
`bind-key \321 scroll_srcwin_down`  
Binds scroll-down key to the `scroll_srcwin_down` Tcl routine.

**Synopsis:**  
Binds an ASCII value to a function.

**See Also:**  
alias, unbind-key.

----------

### break

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### break-taken

**Usage:**  
`break-taken [<flag>]`

**Examples:**  
`break-taken`  
Returns 1 if the machine stopped because of a breakpoint.

`break-taken 0`  
Specify that no breakpoint was actually taken to stop the 
machine.

**Synopsis:**  
Obscure. This is used to determine if the machine stopped because a 
breakpoint was hit and taken.

**Notes:**  
Setting the break-taken flag is a rather obscure operation. It is useful 
primarily in complex commands that single-step the machine until a 
particular address is reached, or a breakpoint is taken when a breakpoint 
must be used to skip over a procedure call, or condense multiple iterations of 
an instruction with a REP prefix into 1. For an example of this use, refer to 
the "cycles" command. 

**See Also:**  
brk, irq.

----------

### brk

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### brkload

**Usage:**  
`brkload [<handle>]`

**Examples:**  
`brkload Interface`  
Stop the machine when the Interface resource is loaded or 
swapped in.

`brkload bx`  
Stop the machine when the resource whose handle ID is in BX 
is loaded or swapped in.

`brkload`  
Stop watching for the previously-specified resource to be 
loaded.

**Synopsis:**  
Stop the machine when a particular resource is loaded into memory.

**Notes:**

+ Only one brkload may be active at a time; registering a second one 
automatically unregisters the first. 

+ If you give no `<handle>` argument, the previously-set brkload will be 
unregistered.

**See Also:**  
handle.

----------

### byteAsChar

**Usage:**  
`var byteAsChar [(0|1)]`

Examples:  
`var byteAsChar 1`  
Print byte variables as characters.

**Synopsis:**  
Determines how unsigned character variables are printed: if set non-zero, 
they are displayed as characters, else they are treated as unsigned integers.

**Notes:**	

+ If $byteAsChar is 0, $intFormat is used. 

+ The default value for this variable is 0.

----------

### bytes

**Usage:**  
`bytes [<address>] [<length>]`

**Examples:**  
`bytes`  
lists 16 bytes at DS:SI

`bytes ds:di 32`  
lists 32 bytes at DS:SI

**Synopsis:**  
Examine memory as a dump of bytes and characters.

**Notes:**

+ The `<address>` argument is the address to examine. If not specified, the 
address after the last examined memory location is used. If no address 
has been examined then DS:SI is used for the address.

+ The `<length>` argument is the number of bytes to examine. It defaults to 
16.

+ Pressing `<Return>` after this command continues the list.

+ Characters which are not typical ASCII values are displayed as a period.

**See Also:**  
words, dwords, imem, assign.

----------

### cache

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### call

**Usage:**  
`call <function> [<function args>]`

**Examples:**  
`call MyFunc`  
`call MyDraw ax 1 bx 1 cx 10h dx 10h`  
`call FindArea box.bottom 5 box.right 5 push box`

**Synopsis:**  
Call a function in the current thread.

**Notes:**	

+ The `<function>` argument is the function to call. If it is a NEAR function, 
the thread must already be executing in the function's segment.

+ The function arguments are in pairs `<variable/register> <value>`. These 
pairs are passed to the "assign" command. As a special case, if the 
variable is "push", the value (a word) is pushed onto the stack and is 
popped when the call finishes (if it completes successfully).

+ All current registers are preserved and restored when the call is 
complete. Variables are not.

+ Once the call has completed, you are left in a sub-interpreter to examine 
the state of the machine. Type "break" to get back to the top level.

+ If the machine stops for any other reason than the call's completion, the 
saved register state is discarded and you are left wherever the machine 
stopped. You will not be able to get a stack trace above the called function, 
but if the call eventually completes, and no registers have actually been 
modified, things will get back on track.

+ You may not call a function from a thread that has retreated into the 
kernel. This function also will not allow you to call ThreadExit(). Use 
the "exit" function to do that.

**See Also:**  
assign, call-patient, patch.

----------

### call-patient

**Usage:**  
`call-patient <function> ((<reg>|push) <value>)*`

**Examples:**  
`call-patient MemLock bx $h`  
Locks down the block whose handle ID is in $h.

**Synopsis:**  
This is a utility routine, not intended for use from the command line, that will 
call a routine in the PC after setting registers to or pushing certain values. 

**Notes:**	

+ Returns non-zero if the call completed successfully. 

+ If the call is successful, the registers reflect the state of the machine upon 
return from the called routine. The previous machine state is preserved 
and can be retrieved, by invoking restore-state, or thrown away, by 
invoking discard-state. The caller must invoke one of these to clean up. 

+ Arguments after `<function>` are as for "call". 

+ If the called routine is in movable memory, this will lock the containing 
block down before issuing the call, as you'd expect. 

+ Calling anything that makes message calls while on the geos:0 thread is 
a hazardous undertaking at best.

**See Also:**  
call

----------

### car

**Usage:**  
`car <list>`

**Examples:**  
`car $args`  
Returns the first element of $args.

**Synopsis:**	Returns the first element of a list.

**Notes:**  
This is a lisp-ism for those most comfortable with that language. It can be 
more-efficiently implemented by saying `[index <list> 0]`

**See Also:**  
cdr.

----------
### case

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------
### catch

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------
### cbrk

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### cdr

**Usage:**  
`cdr <list>`

**Examples:**  
`cdr $args`  
Returns the remaining arguments yet to be processed.

**Synopsis:**  
Returns all but the first element of a list.

**Notes:**  
This is a lisp-ism for those most comfortable with that language. It can be 
more-efficiently implemented by saying `[range <list> 1 end]`

**See Also:**  
car

----------
### classes

**Usage:**  
`classes [<patient>]`

**Examples:**  
`classes`  
Print list of classes in current patient.

`classes myapp`  
Print list of classes in myapp patient.

**Synopsis:**  
Prints list of classes defined by the given patient.

**Notes:**  
Remember that "brk" will take address arguments of the form 
`<class>::<message>`, so you can use this function and set a breakpoint using 
"brk MyTextClass::MSG\_MY_TEXT\_MESSAGE". If you need a breakpoint 
that's limited to one object, use objbrk instead.

----------
### clrcc

**Usage:**  
`clrcc <flag> [<value>]`

**Examples:**  

`clrcc c`  
clear the carry flag

**Synopsis:**  
Clear a flag in the target computer.

**Notes:**  
The first argument is the first letter of the flag to clear. The following is a list 
of the flags:  
>**t** - trap  
**i** - interrupt enable  
**d** - direction  
**o** - overflow  
**s** - sign  
**z** - zero  
**a** - auxiliary carry  
**p** - parity  
**c** - carry

**See Also**:  
setcc, compcc, getcc.

----------
### columns



**Usage:**  
`columns`

**Examples:**  
`columns`  
Return the number of columns on the screen.

**Synopsis:**  
Retrieves the width of the screen, if known, to allow various commands (most 
notably "print") to size their output accordingly.

----------
### compcc



**Usage:**  
`compcc <flag>`

**Examples:**  
`compcc c`  
complement the carry flag

**Synopsis:**  
Complement a flag in the target computer.

**Notes:**  
The first argument is the first letter of the flag to complement. The following 
is a list of the flags:
>**t** - trap  
**i** - interrupt enable  
**d** - direction  
**o** - overflow  
**s** - sign  
**z** - zero  
**a** - auxiliary carry  
**p** - parity  
**c** - carry

This command is handy to insert in a patch to flip a flag bit.

**See Also:**  
setcc, clrcc.



----------
### completion

**Usage:**  
`completion <list-of-names>`

**Examples:**  
`completion {martial marital}`  
Returns "mar," the common prefix.

**Synopsis:**  
Figures the common prefix from a set of strings. Used for the various forms 
of completion supported by top-level-read.

**See Also:**  
top-level-read.

----------
### concat

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------
### condenseSmall

**Usage:**  
`var condenseSmall [(0|1)]`

**Examples:**  
`var condenseSmall 0`  
Force even small structures to be printed one field per line.

**Synopsis:**  
Controls whether "print" attempts to condense the output by printing small 
(< 4 bytes) structures (which are usually records in assembly language) as a 
list of `<name> = <int>`, where `<name>` is the field name and `<int>` is a signed 
integer.

**Notes:**  
The default value of this variable is one.

**See Also:**  
print, condenseSpecial.

----------
### condenseSpecial

**Usage:**  
`var condenseSpecial [(0|1)]`

**Examples:**  
`var condenseSpecial 0`  
Turns off the special formatting of various types of structures 
by "print".

**Synopsis:**	Controls the formatting of certain structures in more-intuitive ways than the 
bare structure fields.

**Notes:**

+ The default value of this variable is 1. 

+ The current list of structures treated specially are: Semaphore, 
Rectangle, Output Descriptor, TMatrix, BBFixed, WBFixed, 
WWFixed, DWFixed, WDFixed, DDFixed, FileDate, FileTime, 
FloatNum, SpecWinSizeSpec.

**See Also:**  
print, condenseSmall.

----------
### cont

**Usage:**  
`cont`

**Examples:**  
`cont`  
continue execution

`c`  
continue execution

**Synopsis:**  
Continue GEOS.

**Notes:**  
If the global variable *waitForPatient* is non-zero, this command waits for 
the machine to stop again before it returns.

**See Also:**  
go, istep, step, next, detach, quit.

----------

### content

**Usage:**  
`content`

**Examples:**  
`vistree [content]`  
 print the visual tree of the content of the view under the 
mouse.

**Synopsis:**  
Print the address of the content under the view with the current implied 
grab. 

**Notes:**  

+ This command is normally used with vistree to get the visual tree of a 
content by placing the mouse on the content's view window and issuing 
the command in the example. 

+ If the pointer is not over a GenView object, this is the same as the 
"impliedgrab" command.

**See Also:**  
systemobj, gentree, impliedgrab.

----------

###continue

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### continue-patient

**Usage:**  
`continue-patient`

**Examples:**  
`continue-patient`  
Allow the target machine to continue executing GEOS.

**Synopsis:**  
Tell the Swat stub to let the target machine continue where it left off.

**Notes:**  
This command does not wait for the machine to stop again before it returns; 
once the machine is running, you're free to do whatever you want, whether 
it's calling "wait" or examining memory periodically.

**See Also:**  
step-patient.

----------

###cup

**Usage:**  
`cup <class>`  
`cup <object>`  
`cup <flags>`

**Examples:**  
`cup ui::GenDocumentControlClass`  
Print class hierarchy of named class

`cup ^l2850h:0034h`  
Print class hierarchy of object

`cup -f`  
Print class hierarchy of focus object

`cup -p`  
Print class hierarchy of process

**Synopsis:**  
Walks up the class hierarchy, starting at a given class, printing each class 
encountered. May be passed an object, in which case the class of the object 
will be used as a starting place.

----------

### current-level

**Usage:**  
`current-level`

**Examples:**  
`var l [current-level]`  
Store the current interpreter nesting level in $l.

**Synopsis:**  
Returns the number of invocations of "top-level" (i.e. the main command 
input loop) currently active.

**Notes:**  

+ This is currently used only to modify the command prompt to indicate the 
current nesting level.

+ The top-most command loop is level one.

**See Also:**  
prompt, top-level.

----------
### current-registers

**Usage:**  
`current-registers`

**Examples:**  
`current-registers`  
Returns a list of the current registers for the current thread.

**Synopsis:**  
Returns all the registers for the current thread as a list of decimal numbers.

**Notes:**  

+ The mapping from element number to register name is contained in the 
global variable "regnums", which is an assoc-list whose elements contain 
the name of the register, then the element number. 

+ For your own consumption, the list is ordered ax, cx, dx, bx, sp, bp, si, di, 
es, cs, ss, ds, ip, flags. You should use the "regnums" variable when 
programming, however, as this may change at some point (e.g. to 
accommodate the additional registers in the 386).

----------

### cvtrecord

**Usage:**  
`cvtrecord <type> <number>`

**Examples:**  
`cvtrecord [symbol find type HeapFlags] 36`  
Return a value list for the number 36 cast to a HeapFlags 
record.

**Synopsis:**  
Creates a value list for a record from a number, for use in printing out the 
number as a particular record using fmtval.

**Notes:**  

+ `<type>` is a type token for a record (or a structure made up exclusively of 
bitfields). 

+ `<number>` must be an actual number suitable for the "expr" command. It 
cannot be a register or variable or some such. Use "getvalue" to obtain an 
integer from such an expression. 

+ Returns a value list suitable for "value store" or for "fmtval".

**See Also:**  
value, fmtval, expr, getValue.

----------

### cycles

**Synopsis:**  
Count instruction cycles from now until the given address is reached. Prints 
out each instruction as it is executed, along with the cycles it took. If no 
address is given, executes until a breakpoint is hit. Takes the following 
(optional) flags:

`-r` Print routines called, the total cycles for each routine, and a 
running total, not the cycles for each instruction.

`-i` Same as -r, but indents to show calling level. Not recommended 
for counting cycles over deeply nested routines.

`-I` Same as -i, except uses (#) to indicate call level

`-f` Stop counting when this routine finishes

`-n` Does not whine about interrupts being off

`-x <routine>` Step over calls to `<routine>`

`-x <routine>=<val`> Step over calls to `<routine>` and assume that the call takes 
`<val>` cycles for timing purposes

----------

### dcache

**Usage:**  
`dcache bsize <blockSize>`  
`dcache length <numBlocks>`  
`dcache stats`  
`dcache params`  
`dcache (on|off)`

**Examples:**  
`dcache bsize 16`  
Set the number of bytes fetched at a time to 16.

`dcache length 1024`  
Allow 1024 blocks of the current block size to be in the cache at 
a time.

`dcache off`  
Disables the Swat data cache.

**Synopsis:**  
Controls the cache Swat uses to hold data read from the target machine while 
the machine is stopped.

**Notes:**

+ Data written while the machine is stopped actually get written to the 
cache, not the PC, and the modified blocks are written when the machine 
is continued. 

+ The default cache block size is 32 bytes, with a default cache length of 64 
blocks. 

+ It is a very rare thing to have to turn the data cache off. You might need 
to do this while examining the changing registers of a memory-mapped 
I/O device. 

+ The `<blockSize>` must be a power of 2 and no more than 128. 

+ Changing the block size causes all cached blocks to be flushed (any 
modified cache blocks are written to the PC).

+ Changing the cache length will only flush blocks if there are more blocks 
currently in the cache than are allowed by the new length. 

+ The `dcache stats` command prints statistics giving some indication of 
the efficacy of the data cache. It does not return anything. 

+ The `dcache params` command returns a list `{<blockSize> <numBlocks>}` giving the current parameters of the data cache. There 
are some operations where you might want to adjust the size of the cache 
either up or down, but need to reset the parameters when the operation 
completes. This is what you need to do this.

**See Also:**  
cache.

----------

### dcall



**Usage:**  
`dcall [<args>]`

**Examples:**  
`dcall Dispatch`  
Display when the routine Dispatch is called

`dcall none`  
stop displaying all routines

**Synopsis:**  
Display calls to a routine.

**Notes:** 

+ The `<args>` argument normally is the name of the routine to monitor. 
Whenever a call is made to the routine its name is displayed.

+ If `none' or no argument is passed, then all the routines will stop 
displaying.

+ Dcall uses breakpoints to display routine names. By looking at the list of 
breakpoints you can see which routines display their names and you can 
stop them individually by disabling or deleting their breakpoints.

**See Also:**  
showcalls, mwatch.

----------
### debug

**Usage:**  
`debug <proc-name>*`

**Examples:**  
"debug"	Enter the Tcl debugger immediately.

`debug fooproc`  
Enter the Tcl debuffer when the interpreter is about to execute 
the command "fooproc".

**Synopsis:**  
This command is used when debugging Tcl commands. It sets a breakpoint 
at the start of any Tcl command. Also serves as a breakpoint in the middle of 
a Tcl procedure, if executed with no argument.

**Notes:** 

+ The breakpoint for <proc-name> can be removed using the "undebug" 
command. 

+ `<proc-name>` need not be a Tcl procedure. Setting a breakpoint on a 
built-in command is not for the faint-of-heart, however, as there are some 
commands used by the Tcl debugger itself. Setting a breakpoint on such 
a command will cause **instant death**.

**See Also:**  
undebug.

----------
### debugger

**Usage:**  
`var debugger [<command-name>]`

**Synopsis:**  
Name of the command when things go wrong. The function is passed two 
arguments: a condition and the current result string from the interpreter. 
The condition is "enter" if entering a command whose debug flag is set, "exit" 
if returning from a frame whose debug flag is set, "error" if an error occurred 
and the "debugOnError" variable is non-zero, "quit" if quit (^> is typed and 
the "debugOnReset" variable is non-zero, or "other" for some other cause (e.g. 
"debug" being invoked from within a function).

----------

### debugOnError

**Usage:**  
`var debugOnError [(0|1)]`

**Examples:**  
`var debugOnError 1`  
Turn on debugging when there's a Tcl error.

**Synopsis:**  
Enter debug mode when Swat encounters a Tcl error. 

**Notes:**

+ The 0|1 simply is a false|true to stop and debug upon encountering an 
error in a Tcl command. 

+ If an error is caught with the catch command, Swat will not enter debug 
mode. 

**See Also:**  
debugger.

----------

### defcmd

**Usage:**  
`defcmd <name> <args> <help-class> <help-string> <body>`

**Examples:**  
Look at almost any .tcl file in the system library for an example; a complete 
example set would be too large to give here.

**Synopsis:**  
This creates a new Tcl procedure with on-line help whose name the user may 
abbreviate when invoking.

**Notes:**

+ `<help-class>` is a Tcl list of places in which to store the `<help-string>`, 
with the levels in the help tree separated by periods. The leaf node for 
each path is added by this command and is `<name>`, so a command "foo" 
with the `<help-class>` "prog.tcl" would have its `<help-string>` stored as 
"prog.tcl.foo."

+ Because the name you choose for a procedure defined in this manner can 
have an impact on the unique abbreviation for another command, you 
should use this sparingly.

**See Also:**  
defcommand, proc, help. 

----------

### defcommand

**Usage:**  
`defcommand <name> <args> <help-class> <help-string> <body>`

**Examples:**  
Look at Swat Display 5-3, Swat Display 5-4, or almost any .tcl file in the 
system library for an example; a complete example set would be too large to 
give here.

**Synopsis:**  
This creates a new Tcl procedure with on-line help whose name must be given 
exactly when the user wishes to invoke it.

**Notes:**  
`<help-class>` is a Tcl list of places in which to store the `<help-string>`, with 
the levels in the help tree separated by periods. The leaf node for each path 
is added by this command and is `<name>`, so a command "foo" with the 
`<help-class>` "prog.tcl" would have its `<help-string>` stored as "prog.tcl.foo."

**See Also:**  
defcmd, proc, help.

----------

### defhelp

**Usage:**  
`defhelp <topic> <help-class> <help-string>`

**Examples:**  
`defhelp breakpoint top {Commands relating to the setting of breakpoints}`
Sets the help for "breakpoint" in the "top" category to the given 
string.

**Synopsis:**  
This is used to define the help string for an internal node of the help tree (a 
node that is used in the path for some other real topic, such as a command or 
a variable).

**Notes:**

+ This cannot override a string that resides in the /pcgeos/tcl/doc file.

+ You only really need this if you have defined your own help-topic category.

+ `<help-class>` is a Tcl list of places in which to store the <help-string>, 
with the levels in the help tree separated by periods. The leaf node for 
each path is added by this command and is `<name>`, so a command "foo" 
with the `<help-class>` "prog.tcl" would have its `<help-string>` stored as 
"prog.tcl.foo."

**See Also:**  
help.

----------

### defsubr

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### defvar

**Usage:**  
`defvar <name> <value> [<help-class> <help-string>]`

**Examples:**  
`defvar printRegions 0`  
Define "printRegions" as a global variable and give it the value 
zero, if it didn't have a value already.

**Synopsis:**  
This command is used in .tcl files to define a global variable and give it an 
initial value, should the variable not have been defined before.

**Notes:**

+ If the variable is one the user may want to change, give it on-line help 
using the `<help-class>` and `<help-string>` arguments.

+ `<help-class>` is a Tcl list of places in which to store the `<help-string>`, 
with the levels in the help tree separated by periods. The leaf node for 
each path is added by this command and is `<name>`, so a command "foo" 
with the `<help-class>` "variable.output" would have its `<help-string>` 
stored as "variable.output.foo."

**See Also:**  
var, help.

----------

### delassoc

**Usage:**  
`delassoc <list> <key> [<foundvar> [<elvar>]]`

**Examples:**  
`delassoc $val murphy`  
Returns $val without the sublist whose first element is the 
string "murphy."

**Synopsis:**  
Deletes an entry from an associative list.

**Notes:**

+  `<foundvar>`, if given, is the name of a variable in the caller's scope that 
is to be set non-zero if an element in `<list>` was found whose `<key>` 
matched the given one. If no such element was found (and therefore 
deleted), the variable is set zero.

+ `<elvar>`, if given, is the name of a variable in the caller's scope that 
receives the element that was deleted from the list. If no element was 
deleted, the variable remains untouched.

**See Also:**  
assoc.

----------
### detach

**Usage:**  
`detach [<options>]`

**Examples:**  
`detach cont`  
continue GEOS and quit swat

**Synopsis:**  
Detach swat from the PC.

**Notes:**  
The `<option>` argument may be one of the following: *continue*: continue 
GEOS and detach swat; *leave*: keep GEOS stopped and detach swat. 
Anything else causes swat to just detach.

**See Also:**  
attach, quit.

----------
### dirs

**Usage:**  
`dirs`

**Synopsis:**  
Prints the directory stack for the current thread.

**See Also:**  
pwd, stdpaths

----------
### discard-state

**Usage:**  
`discard-state`

**Examples:**  
`discard-state`  
Throw away the values for all the thread's registers as saved by 
the most recent call to save-state.

**Synopsis:**  
Throw away the state saved by the most-recent save-state command.

**Notes:**  
This is usually only used in response to an error that makes it pointless to 
return to the point where the save-state was performed.

**See Also:**  
save-state, restore-state.

----------
### diskwalk

**Usage:**  
`diskwalk <drive>`

**Examples:**  
`diskwalk F`  
Prints the disks registered in drive F.

`diskwalk`  
Prints all the disks registered with the system.

**Synopsis:**  
Prints out the information on registered disks.

**Notes:**  
The Flags column is a string of single-character flags with the following 
meanings:

>**w** - The disk is writable.  
**V** - The disk is always valid, i.e. it's not removable.  
**S** - The disk is stale. This is set if the drive for the disk has been 
deleted.  
**u** - The disk is unnamed, so the system has made up a name for it.

**See Also:**  
drivewalk, fsdwalk.

----------
### display

**Usage:**  
`display <lines> <command>`  
`display list`  
`display del <num>`

**Examples:**  
`display list`  
list all the commands displayed

`display 1 {piv Vis VCNI_viewHeight}`  
always display the view height

`display del 2`  
delete the second display command

**Synopsis:**  
Manipulate the display at the bottom of Swat's screen.

**Notes:**

+ If you give a numeric `<lines>` argument, the next argument, `<command`, 
is a standard Tcl command to execute each time the machine halts. The 
output of the command is directed to a window `<lines>` lines high, usually 
located at the bottom of the screen.

+ You can list all the active displays by giving "list" instead of a number as 
the first argument.

+ If the first argument is "del", you can give the number of a display to 
delete as the `<num>` argument. `<num>` comes either from the value this 
command returned when the display was created, or from the list of 
active displays shown by typing "display list".

**See Also:**  
wtop, wcreate.

----------
### doc

**Usage:**  
`doc [<keyword>]`

**Examples:**  
`doc MSG_VIS_OPEN"`  
Brings up technical documentation for MSG\_VIS_OPEN.

**Synopsis:**  
Finds technical documentation for `<keyword>`. If it finds multiple entries for 
the keyword in the documentation, hit `<Return>` or use doc-next and 
doc-previous to see the additional entries. The documentation retrieved is 
in ASCII form-figures will be missing, but the complete text appears.

**See Also:**  
doc-next, doc-previous.

----------
### doc-next

**Usage:**  
`doc-next`

**Examples:**  
`doc MSG_VIS_OPEN`  
Brings up technical documentation for MSG\_VIS_OPEN.

`doc-next`  
Brings up more technical documentation if available.

**Synopsis:**  
Finds additional technical documentation for `<keyword>`.

**See Also:**  
doc, doc-previous.

----------
### doc-previous

**Usage:**  
`doc-previous`

**Examples:**  
`doc MSG_VIS_OPEN`  
Brings up technical documentation for MSG\_VIS_OPEN.

`doc-next`  
Brings up more technical documentation if available.

`doc-previous`  
Brings back previous (in this case, the first) entry.

**Synopsis:**  
Finds additional technical documentation for `<keyword>`.

**See Also:**  
doc, doc-next.

----------
### dosMem

**Usage:**  
`dosMem`

**Examples:**  
`dosMem`

**Synopsis:**  
Traverse DOS' chain of memory blocks, providing information about each.

----------
### down

**Usage:**  
`down [<frame offset>]`

**Examples:**  
`down`  
move the frame one frame down the stack

`down 4`  
move the frame four frames down the stack

**Synopsis:**  
Move the frame down the stack.

**Notes:**

+ The frame offset argument is the number of frames to move down the 
stack. If no argument is given then the current frame is moved down one 
frame.

+ This command may be repeated by pressing <Return>.

**See Also:**  
backtrace, up.

----------
### drivewalk

**Usage:**  
`drivewalk`

**Examples:**  
`drivewalk`  
Prints the table of drives known to the system.

**Synopsis:**  
Prints out all disk drives known to the system, along with their current 
status.

**Notes:**

+ The Flags column is a string of single character flags with the following 
meanings:  
    `L` - The drive is accessible to the local machine only, i.e. it's not visible over a network.  
    `R` - The drive is read-only.  
    `F` - Disks may be formatted in the drive.  
    `A` - The drive is actually an alias for a path on another drive.  
    `B` - The drive is busy, performing some extended operation, such as formatting or copying a disk.  
    `r` - The drive uses disks that may be removed by the user.  
    `n` - The drive is accessed over the network.  
+ The Locks column can reflect one of three states:  
    `none` - The drive isn't being accessed by any thread.  
    `Excl` - The drive is locked for exclusive access by a single thread.  
    `<num>` - The drive is locked for shared access for a particular disk, whose handle is the number. This is followed by the volume name of the disk, in square brackets.

**See Also:**  
diskwalk, fsdwalk.

----------

### dumpstack

**Usage:**  
`dumpstack [<address>] [<length>]`

**Examples:**  
`dumpstack"`  
dump the stack at SS:SP

`ds ds:si 10`  
dump ten words starting at DS:SI

**Synopsis:**  
Dump the stack and perform some simple interpretation upon it.

**Notes:**

+ The `<address>` argument is the address of the list of words to dump. This 
defaults to SS:SP.

+ The `<length>` argument is the number of words to dump. This defaults to 
50.

+ This dumps the stack and tries to make symbolic sense of the values, in 
terms of handles, segments, and routines.

+ After doing a dumpstack, if you just hit return without entering a new 
command, by default you will see a continuation of the dumpstack.

**See Also:**  
backtrace.

----------

### dwordIsPtr

**Usage:**  
`var dwordIsPtr [(0|1)]`

**Examples:**  
`var dwordIsPtr 1`  
Tells "print" to print all double-word variables as if they were 
far pointers (segment:offset).

**Synopsis:**  
Controls whether dword (a.k.a. long) variables are printed as 32-bit unsigned 
integers or untyped far pointers.

**Notes:**

+ For debugging C code, a value of 0 is more appropriate, while 1 is best for 
debugging assembly language. 

+ The default value for this variable is 1.

**See Also:**  
intFormat, print.

----------

### dwords

**Usage:**  
`dwords [<address>] [<length>]`

**Examples:**  
`dwords`  
lists 4 double words at DS:SI

`dwords ds:di 8`  
lists 8 double words at DS:DI

**Synopsis:**  
Examine memory as a dump of double words (32 bit hex numbers).

**Notes:**

+ The `<address>` argument is the address to examine. If not specified, the 
address after the last examined memory location is used. If no address 
has be examined then DS:SI is used for the address.

+ The `<length>` argument is the number of dwords to examine. It defaults 
to 4.

+ Pressing `<Return>` after this command continues the list.

**See Also:**  
bytes, words, imem, assign.

----------

### ec

**Usage:**  
`ec [<args>]`

**Examples:**  
`ec`  
list the error checking turned on

`ec +vm`  
add vmem file structure checking

`ec all`  
turn on all error checking (slow)

`ec save none`  
save the current error checking and then use none

`ec restore`  
use the saved error checking flags

**Synopsis:**  
Get or set the error checking level active in the kernel.

**Notes:**

+ The following arguments may occur in any combination:

    `<flag>` - turn on `<flag>`

    `+<flag>` - turn on `<flag>`

    `-<flag>` - turn off `<flag>`

    `all` - turn on all error checking flags

    `ALL` - turn on all error checking flags

    `none` - turn off all error checking flags

    `sum <handle>` - turn on checksum checking for the memory block with the 
given handle ("ec sum bx"). The current contents of the block 
will be summed and that sum regenerated and checked for 
changes at strategic points in the system (e.g. when a call 
between modules occurs).

    `-sum` - turn off checksum checking

    `save` - save the current error checking

    `restore` - restore the saved error checking flags
 where `<flag>` may be one of the following:

    `analVM` - perform over-aggressive checking of vmem files

    `graphics` - graphics checking

    `heapFree` - heap free block checking

    `lmemFree` - lmem free area checking

    `lmemInternal` - internal lmem error checking

    `lmemObject` - lmem object checking

    `normal` - normal error checking

    `region` - region checking segment extensive

    `segment` - register checking

    `lmemMove` - force lmem blocks to move whenever possible

    `unlockMove` - force unlocked blocks to move whenever possible

    `vm` - vmem file structure checking

    `vmemDiscard` - force vmem blocks to be discarded if possible

+ If there isn't an argument, `ec' reports the current error checking flags.

+ Each time GEOS is run the ec flags are cleared. The saved flags are 
preserved between sessions. The ec flags may be saved and then restored 
after restarting GEOS so that the flag settings are not lost when 
restarting GEOS.

**See Also:**  
why.

----------

### echo

**Usage:**  
`echo [-n] <string>+`

**Examples:**  
`echo -n yes?`  
Prints "yes?" without a newline.

`echo hi mom`  
Prints "hi mom" followed by a newline.

**Synopsis:**  
Prints its arguments, separated by spaces.

**Notes:**  
If the first argument is "-n", no newline is printed after the arguments.

**See Also:**  
flush-output

----------

### elist

**Usage:**  
`elist [<patient>]`

**Examples:**  
`elist`  
list the events for the current thread and patient

`elist ui`  
list the events for the last thread of the ui patient

`elist :1`  
list the events for the first thread of the current patient

`elist geos:2`  
list the events for the second thread of the GEOS patient

**Synopsis:**  
Display all events pending for a patient.

**Notes:**  
The `<patient>` argument is of the form `patient:thread'. Each part of the 
patient name is optional, and if nothing is specified then the current patient 
is listed.

**See Also:**  
showcalls.

----------

### ensure-swat-attached

**Usage:**  
`ensure-swat-attached`

**Examples:**  
`ensure-swat-attached`  
Stop if Swat isn't attached to GEOS.

**Synopsis:**  
If Swat is not attached to GEOS, display an error and stop a command.

**Notes:**  
Use this command at the start of any other command that accesses the target 
PC. Doing so protects the user from the numerous warnings that can result 
from an attempt to read memory when not attached.

----------

### eqfind

**Usage:**  
`eqfind [-p]`

**Examples:**  
`eqfind`  
list all event queues in the system.

`eqfind -p`  
list and print all event queues in the system.

**Synopsis:**  
Display all event queues in the system.

**See Also:**  
elist, eqlist, erfind.

----------

### eqlist

**Usage:**  
`eqlist <queue handle> <name>`

**Examples:**  
`eqlist 8320 geos:2`  
show the event list for geos:2

**Synopsis:**  
Display all events in a queue.

**Notes:**

+ The queue handle argument is the handle to a queue.

+ The name argument is the name of the queue.

**See Also:**  
elist.

----------

### erfind

**Usage:**  
`erfind [-p]`

**Examples:**  
`erfind`  
list all recorded event handles in the system.

`erfind -p`  
list and print all recorded event handles in the system.

**Synopsis:**  
Display all record event handles in the system. These are events that have 
been recorded but not necessarily sent anywhere, so they will not appear in 
the queue of any thread.

**See Also:**  
elist, eqlist, eqfind, pevent.

----------

### error

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### eval

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### event

This is a Tcl primitive data structure. See "Tool Command Language," 
Chapter 5.

----------

### exec

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### exit

**Usage:**  
`exit <patient>`

**Examples:**  
`exit faxmon`  
Causes the faxmon application to exit.

**Synopsis:**  
Sends messages required to make an application quit.

**Notes:**  
This command does nothing when you're stopped at FatalError, as it will 
wait until the machine is idle before attempting to send MSG\_META_QUIT; 
continuing from FatalError will cause the system to exit.

**See Also:**  
run. 

----------

### exit-thread

**Usage:**  
`exit-thread [<exit-code>]`

**Examples:**  
`exit-thread`  
Exit the current thread, returning zero to its parent.

`exit-thread 1`  
Exit the current thread, returning one to its parent.

**Synopsis:**  
Exit the current thread.

**Notes:**

+ The exit code argument is the status to return to the current thread's 
parent, which defaults to zero. 

+ Do not invoke this function for an event-driven thread; send it a 
MSG\_META_DETACH instead. 

**See Also:**  
quit.

----------

### explain

**Usage:**	explain

**Examples:**	"explain"

**Synopsis:**	Print a more detailed description of why the system crashed, if possible.

**Notes:**

+ This must be run from within the frame of the **FatalError()** function. 
Sometimes GEOS is not quite there. In this case, step an instruction or 
two and then try the "why" command again.

+ This simply looks up the enumerated constant for the error code in the 
AX register in the **FatalErrors** enumerated type defined by the geode 
that called **FatalError()**. For example, if a function in the kernel called 
**FatalError()**, AX would be looked up in geos::FatalErrors, while if a 
function in your application called **FatalError()**, this function would 
look it up in the **FatalErrors** type defined by your application. Each 
assembly application defines this enumerated type by virtue of having 
included **ec.def**.

+ This command also relies on programmers having explained their 
FatalErrors when defining them.

+ For certain fatal errors, additional information is provided by invoking 
the command `<patient>::<error code name>`, if it exists.

----------

### explode

**Usage:**  
`explode <string> [<sep-set>]`

**Examples:**  
`explode $args  
Breaks the string stored in the variable "args" into a list of its 
individual letters.

`explode $file /`  
Breaks the string stored in the variable "file" into a list of its 
components, using "/" as the boundary between components 
when performing the split.

**Synopsis:**  
Breaks a string into a list of its component letters, allowing them to be 
handled quickly via a foreach loop, or the map or mapconcat commands.

**Notes:**  
This is especially useful for parsing command switches. 

**See Also:**  
foreach, index, range.

----------

### expr

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### fatalerr\_auto_explain

**Usage:**  
`var fatalerr_auto_explain [(0|1)]`

**Examples:**  
`var fatalerr_auto_explain 0`  
Turn off automatic generation of the explanation for any 
fatal-error hit.

**Synopsis:**  
Determines if the "why" command will automatically provide you with an 
explanation of any fatal error you encounter. If non-zero, they will be 
provided whenever **FatalError** is hit.

**Notes:**

+ Explanations are loaded from `<patient>`.fei files stored in the system Tcl 
library directory when an error in `<patient`> is encountered. 

+ You can also obtain an explanation of an error via the "explain" 
command.

----------

### fetch-optr

**Usage:**  
`fetch-optr <handle> <offset>`

**Examples:**  
`fetch-optr $h $o.GI_comp.CP_firstChild`  
Fetch the optr from the GI_comp.CP\_firstChild field of the 
object at ^h$h:$o.

**Synopsis:**  
Extracts an optr from memory, coping with the data in the block that holds 
the optr not having been relocated yet.

**Notes:**

+ `<offset>` is an actual offset, not a chunk handle, while `<handle>` is a 
handle ID, not a handle token. 

+ Returns a two-list `{<handle> <chunk>}`, where `<handle>` is the handle ID 
from the optr, and `<chunk>` is the chunk handle (low word) from the optr. 

+ We decide whether to relocate the optr ourselves based on the 
LMF\_RELOCATED bit in the LMBH\_flags field of the block's header. There 
are times, e.g. during the call to MSG\_META_RELOCATE for an object, 
when this bit doesn't accurately reflect the state of the class pointer and 
we will return an error when we should not.

----------

### fhandle

**Usage:**  
`fhandle <handle id`>

**Examples:**  
`fhandle 3290h`

**Synopsis:**  
Print out a file handle.

**Notes:**  
The <handle id> argument is the handle number. File handles are listed 
in the first column of the `fwalk' command.

**See Also:**  
fwalk.

----------

### field

**Usage:**  
`field <list> <field name>`

**Examples:**  
`field [value fetch ds:si MyBox] topLeft`  
return the offset of the topLeft field in MyBox

**Synopsis:**  
Return the value for the field's offset in the structure.

**Notes:**

+ The `<list`> argument is a structure-value list from the "value" command.

+ The `<field name>` argument is the field in the structure.

**See Also:**  
value, pobject, piv.

----------

### fieldwin

**Usage:**  
fieldwin

**Synopsis:**  
Print the address of the target machine's current top-most field window.

----------

### file

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### find

**Usage:**  
`find [-ir] <string> [<filename>]`

**Examples:**  
`find FileRead`  
Find next occurrence of string "FileRead" in currently viewed 
file 

`find FI_foo poof.goc"`  
 find first occurrence of string "FI_foo" in file poof.goc.

`find -ir myobject`  
case-insensitive reverse search for most recent occurrence of 
string "myobject" in currently viewed file

**Synopsis:**  
Finds a string in a file and brings the line with that string to the middle of 
Swat's source window.

**Notes:**

+ If no file argument is specified, find will find the next instance of the 
string in the already viewed file starting from the current file position. 

+ There must already be a source window displayed for find to work. 

+ Possible options to find are:

    `-r` - reverse search

    `-i` - case insensitive search

----------

### find-opcode

**Usage:**  
`find-opcode <addr> <byte>+`

**Synopsis:**  
Locates the mnemonic for an opcode and decodesit. Accepts the address from 
which the opcode bytes were fetched, and one or more opcode bytes as 
arguments. Returns a list of data from the opcode descriptor:

{name length branch-type args modrm bRead bWritten inst}

*length* is the length of the instruction.

*branch-type* is one of: 

`1` - none (flow passes to next instruction)

`j` - absolute jump

`b` - pc-relative jump (branch)

`r` - near return

`R` - far return

`i` - interrupt return

`I` - interrupt instruction

Any argument descriptor that doesn't match is to be taken as a literal. E.g. 
AX as a descriptor means AX is that operand.

modrm is the modrm byte for the opcode.

*bRead* is the number of bytes that may be read by the instruction, if one of its 
operands is in memory.

*bWritten* is the number of bytes that may be written by the instruction, if one 
of its operands is in memory.

*inst* is the decoded form of the instruction. If not enough bytes were given to 
decode the instruction, inst is returned as empty.

----------

### finish

**Usage:**  
`finish [<frame num>]`

**Examples:**  
`finish`  
finish executing the current frame

`finish 3`  
finish executing up to the third frame

**Synopsis:**  
Finish the execution of a frame.

**Notes:**	

+ The `<frame num>` argument is the number of the frame to finish. If none 
is specified then the current frame is finished up. The number to use is 
the number which appears in a backtrace.

+ The machine continues to run until the frame above is reached.

**See Also:**  
backtrace.

----------

### finishframe

**Usage:**  
`finishframe [<frame-token>]`

**Examples:**  
`finishframe $cur`  
Run the machine to continue until it has returned from a 
particular stack frame.

**Synopsis:**  
Allows the machine to continue until it has returned from a particular stack 
frame.

**Notes:**	

+ No FULLSTOP event is dispatched when the machine actually finishes 
executing in the given frame. The caller must dispatch it itself, using the 
"event" command.

+ The command returns zero if the machine finished executing in the given 
frame; non-zero if it was interrupted before that could happen. 

+ The argument is a frame token, as returned by the "frame" command.

**See Also:**  
event, frame, finish.

----------

### flagwin

**Usage:**  
`flagwin [<on>|off]`

**Synopsis:**  
Turns on or off a window providing a continuous display of the machine flags 
(e.g. zero, carry).

**See Also:**  
pflags.

----------

### flowobj

**Usage:**  
`flowobj`

**Examples:**  
`pobject [flowobj]`  
print out the flow object.

**Synopsis:**  
Prints out address of the uiFlowObj, which is the object which grabs the 
mouse.

**Notes:**  
This command is normally used with pobject to print out the object.

----------

### flush-output

**Usage:**  
`flush-output`

**Examples:**  
`flush-output`  
Forces pending output to be displayed.

**Synopsis:**  
Flushes any pending output (e.g. waiting for a newline) to the screen.

**See Also:**  
echo

----------

### fmtoptr

**Usage:**  
`fmtoptr <handle-id> <chunk>`

**Examples:**  
`fmtoptr 3160h o`  
Prints a description of the object whose address is ^l3160h:0 
(likely a thread/process).

**Synopsis:**  
Takes a global and a local handle and prints a description of the object 
described by that optr.

**Notes:**	

+ If the global handle is a thread or a process, the thread's name (process 
thread for a process handle) and the chunk handle (as an additional word 
of data for the message) are printed.

+ If the global handle is a queue handle, the queue handle and the chunk 
handle are printed, with a note that the thing's a queue.

+ If Swat can determine the object's class, the optr, full classname, and 
current far pointer are printed. In addition, if the chunk has its low bit 
set, the word "parent" is placed before the output, to denote that the optr 
likely came from a link and is the parent of the object containing the optr.

**See Also:**  
print.

----------

### fmtval

**Usage:**  
`fmtval <value-list> <type-token> <indent> [<tail> [<one-line>]]`

**Examples:**  
`fmtval [value fetch foo] [symbol find type FooStruct] 0`  
Prints the value of the variable foo, which is assumed to be of 
type FooStruct.

**Synopsis:**  
This is the primary means of producing nicely-formatted output of data in 
Swat. It is used by both the "print" and "_print" commands and is helpful if 
you want to print the value of a variable without entering anything into the 
value history.

**Notes:**	

+ `<value-list>` is the return value from "value fetch". You can, of course, 
construct one of these if you feel so inclined.

+ `<type-token>` is the token for the type-description used when fetching the 
value. 

+ `<indent>` is the base indentation for all output. When "fmtval" calls itself 
recursively, it increases this by 4 for each recursive call. 

+ `<tail>` is an optional parameter that exists solely for use in formatting 
nested arrays. It is a string to print after the entire value has been 
formatted. You will almost always omit it or pass the empty string.

+ `<one-line>` is another optional parameter used almost exclusively for 
recursive calls. It indicates if the value being formatted is expected to fit 
on a single line, and so "fmtval" should not force a newline to be output 
at the end of the value. The value should be 0 or 1.

**See Also:**  +print, _print, fmtoptr, threadname.

----------

### focus

**Usage:**  
`focus [<object>]`

**Examples:**  
`focus`  
print focus hierarchy from the system object down

`focus -i`  
print focus hierarchy from implied grab down

`focus^l4e10h:20h`  
print focus hierarchy from ^l4e10h:20h down

`focus [content]`  
print focus hierarchy from content under mouse.

**Synopsis:**  
Prints the focus hierarchy below an object.

**Notes:**	

+ If no argument is specified, the system object is used. 
+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ Remember that the object you start from may have the focus within its 
part of the hierarchy, but still not have the focus because something in a 
different part of the tree has it. 

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. This variable defaults to false.

**See Also:**  
target, model, mouse, keyboard, pobject.

----------

### focusobj

**Usage:**  
`focusobj`

**Examples:**  
`focusobj`  
print model hierarchy from system object down

`pobj [focusobj]`  
Do a pobject on the focus object (equivalent to "pobj -f").

**Synopsis:**  
Returns the object with the focus.

**See Also:**  
focus, target, model, targetobj, modelobj.

----------

### fonts

**Usage:**  
`fonts [<args>]`

**Examples:**  
`fonts`  
summarize general font usage

`fonts -u`  
list fonts currently in use

**Synopsis:**  
Print various font info.

**Notes:**	

+ The <args> argument may be any of the following:

    `-a` - list of fonts available

    `-d` - list of font drivers available

    `-u` - [`<ID>`] list of fonts currently in use. Optional font ID to match.

    `-s` - summary of above information

    If no argument is specified the default is to show the summary.

+ When using other commands you probably need to pass them the handle 
in *FIUE_dataHandle*. When you don't have the font's handle ready, the 
best way is to use "fonts -u" to find the font at the right point size and 
then grab the handle from there.

**See Also:**  
pfont, pfontinfo, pusage, pchar, pfontinfo.

----------

### for

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### foreach

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

#### format

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

n	fpstack

**Usage:**  
`fpstack`

**Examples:**  
`fpstack`  
Prints out the hardware and software floating point stacks for 
the patient.

**Synopsis:**  
Prints out the hardware and software floating point stacks for the patient. 

**See Also:**  
fpstack, pfloat.

----------

### fpu-state

**Usage:**  
`fpustate [<mode>]`

**Examples:**  
`fpustate`  
Print out the state of the coprocessor.

`fpustate w`  
Dumps actual words of the numbers.

**Synopsis:**  
Prints out the current state of the coprocessor, if any.

**See Also:**  
fpstack, pfloat.

----------

### frame

**Usage:**  
`frame top`  
`frame cur`  
`frame get <ss> <sp> <cs> <ip>`  
`frame next <frame>`  
`frame prev <frame>`  
`frame function [<frame>]`  
`frame funcsym [<frame>]`  
`frame scope [<frame>]`  
`frame info [<frame>]`   
`frame patient [<frame>]`  
`frame register <regName> [<frame>]`  
`frame set [<frame>]`  
`frame setreg <regName> <value> [<frame>]`  
`frame +<number>`  
`frame -<number>`  
`frame <number>`

**Examples:**  
`var f [frame top]`  
Fetches the token for the frame at the top of the current 
thread's stack and stores it in the variable "f"

`var f [frame next $f]`  
 Fetches the token for the next frame up the stack (away from 
the top) from that whose token is in $f

 `frame register ax $f`  
Returns the value of the AX register in the given frame.

`frame 1`  
Sets the current frame for the current thread to be the top-most 
one.

**Synopsis:**  
This command provides access to the stack-decoding functions of swat. Most 
of the subcommands deal with frame tokens, but a few also handle frame 
numbers, for the convenience of the user.

**Notes:**

+ Subcommands may be abbreviated uniquely.

+ Stack decoding works by a heuristic method, rather than relying on the 
presence of a created stack frame pointed to by BP in each function. 
Because of this, it can occasionally get confused. 

+ Frame tokens are valid only while the target machine is stopped and are 
invalidated when it is continued.

+ Each frame records the address on the stack where each register was 
most-recently pushed (i.e. by the frame closest to it on the way toward the 
top of the stack). Register pushes are looked for only at the start of a 
function in what can be considered the function prologue.

+ `frame register` and `frame setreg` allow you to get or set the value held 
in a register in the given frame. For `setreg`, `<value>` is a standard 
address expression, only the offset of which is used to set the register.

+ `frame register` returns all registers but "pc" as a decimal number. "pc" 
is formatted as two hex numbers (each preceded by "0x") separated by a 
colon.

+ `frame info` prints out information on where the register values for 
`frame register` and `frame setreg` are coming from/going to for the 
given or currently-selected frame. Because of the speed that can be 
gained by only pushing registers when you absolutely have to, there are 
many functions in GEOS that do not push the registers they save at their 
start, so Swat does not notice that they are actually saved. It is good to 
make sure a register value is coming from a reliable source before 
deciding your program has a bug simply because the value returned by 
`frame register` is invalid.

+ For any subcommand where the `<frame>` token is optional, the currently- 
selected frame will be used if you give no token.

+ `frame cur` returns the token for the currently-selected stack frame.

+ `frame set` is what sets the current frame, when set by a Tcl procedure.

+ `frame +<number>` selects the frame `<number>` frames up the stack 
(away from the top) from the current frame. `frame -<number>` goes the 
other way.

+ `frame <number>` selects the frame with the given number, where the 
top-most frame is considered frame number 1 and numbers count up 
from there.

+ `frame funcsym` returns the symbol token for the function active in the 
given (or current) frame. If no known function is active, you get "nil".

+ `frame scope` returns the full name of the scope that is active in the given 
(or current) frame. This will be different from the function if, for example, 
one is in the middle of an "if" that contains variables that are local to it 
only.

+ `frame function` returns the name of the function active in the given (or 
current) frame. If no known function is active, you get the CS:IP for the 
frame, formatted as two hex numbers separated by a colon.

+ `frame patient` returns the token for the patient that owns the function 
in which the frame is executing.

**See Also:**  
addr-parse, switch.

----------

### framewin

**Usage:**  
`framewin [del]`

**Examples:**  
`framewin`  
Creates a single-line window to display info about the current 
stack frame.

`framewin del`  
Deletes the window created by a previous `framewin`.

**Synopsis**:  
Creates a window in which the current stack frame is always displayed.

**Notes:**  
Only one frame window can be active at a time.

**See Also:**  
display, regwin, ewatch, srcwin

----------

### freeze

**Usage:**  
`freeze [<patient>]`  
`freeze :<n>`  
`freeze <patient>:<n>`  
`freeze <id>`

**Examples:**  
`freeze`  
Freezes the current thread.

`freeze term`  
Freezes the application thread for "term"

`freeze :1`  
Freezes thread #1 of the current patient

`freeze 16c0h`  
Freezes the thread whose handle is 16c0h.

**Synopsis**:  
Freezing a thread prevents a thread from running unless it's the only thread 
that's runnable in the entire system.

**Notes:**

+ A frozen thread is not dead in the water, as it will still run if nothing else 
is runnable. 

+ Freezing a thread is most useful when debugging multi-threaded 
applications where a bug appears to be caused by a timing problem or 
race condition between the two threads. Freezing one of the threads 
ensures a consistent timing relationship between the two threads and 
allows the bug to be reproduced much more easily. 

+ The freezing of a thread is accomplished by setting its base and current 
priorities to as high a number as possible (255) thereby making the 
thread the least-favored thread in the system. The previous priority can 
be restored using the `thaw` command.

**See Also:**  
thaw.

----------

### fullscreen

**Usage:**  
`fullscreen`

**Examples:**  
`fullscreen`

**Synopsis:**  
Prints the full screen hierarchy from the system object down.

----------

### func

**Usage:**  
`func [<func name>]`

**Examples:**  
`func`  
return the current function.

`func ObjMessage`  
set the frame to the first frame for ObjMessage.

**Synopsis:**  
Get the current function or set the frame to the given function.

**Notes:**

+ The `<func name>` argument is the name of a function in the stack frame 
of the current patient. The frame is set to the first occurrence of the 
function from the top of the stack.

+ If no `<func name>` argument is given then `func` returns the current 
function.

**See Also:**  
backtrace, up, down, finish.

----------

### fvardata

**Usage:**  
`fvardata <token> [<address>]`

**Examples:**  
`fvardata ATTR_VIS_TEXT_STYLE_ARRAY *ds:si`

**Synopsis:**  
Locates and returns the value list for the data stored under the given token 
in the vardata of the given object.

**Notes:**

+ If the data are found, returns a list `{<token> <data>}`, where `<data>` is a 
standard value list for the type of data associated with the specified 
token. 

+ Returns an empty list if the object has no vardata entry of the given type. 

+ If no `<address>` is given, the default is *ds:si.

----------

### fwalk

**Usage:**  
`fwalk [<patient>]`

**Examples:**  
`fwalk`  
list all open files.

`fwalk geos`  
list all open files owned by the GEOS patient.

**Synopsis:**  
Print the list of files open anywhere in the system.

**Notes:**

+ The patient argument may be used to restrict the list to a particular 
patient. The patient may be specified either as the patient name or as the 
patient's handle.

+ fwalk differs from sysfiles and geosfiles in that it deals primarily with 
GEOS data structures.

+ The `Other' column shows if there is a VM handle bound to the file.

+ The letters in the `Flags' column mean the following:

    `RW` - deny RW  
    `R` - deny R  
    `W` - deny W 
    `N` - deny none  
    `rw` - access RW  
    `r` - access R  
    `w` - access RW  
    `O` - override, used to override normal exclusion normally used by 
FileEnum() to check out file headers.  
    `E` - exclusive, used to prevent override. This is used by swap.geo

**See Also:**  
fhandle, geosfiles, sysfiles.

----------

### gc

**Usage:**  
`gc [(off|register|<extensive-heap-checking-flag>]`

**Synopsis:**  
Implements a simple garbage collector to scavenge unreferenced symbols 
and types. If given an argument other than "off" or "register," it turns on 
extensive heap checking, which slows things down enormously but ensures 
the heap is in good shape. The "gc register" command can be use to register 
a type created by "type make"as something that is being used for an extended 
period at the Tcl level, preventing the thing from being garbage-collected. 

----------

### gentree

**Usage:**  
`gentree [<address>] [<instance field>]`

**Examples:**  
`gentree`  
print the generic tree starting at *DS:SI

`gentree -i`  
print the generic tree under the mouse

`gentree [systemobj]`  
print the generic tree starting at the system's root

`gentree @23 GI_states`  
print the generic tree with generic states

`gentree *uiSystemObj`  
start the generic tree at the root of the system

**Synopsis:**  
Print a generic tree.

**Notes:**

+ The `<address>` argument is the address to an object in the generic tree. 
This defaults to *DS:SI. The `-i' flag for an implied grab may be used.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ The `<instance field>` argument is the offset to any instance data within 
the GenInstance which should be printed out.

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. 
This variable defaults to false.

**See Also:**  
gup, vistree, impliedgrab, systemobj, pobject.

----------

### geosfiles

**Usage:**  
`geosfiles`

**Examples:**  
`geosfiles`

**Synopsis:**  
Print out all the files for which I/O is currently pending in GEOS.

**Notes:**  
This looks at the same dos structure as sysfiles but this prints only those 
files also listed in GEOS' job file table.

**See Also:**  
sysfiles, sftwalk, fwalk.

----------

### geos-release

**Synopsis:**  
This variable contains the major number of the version of GEOS running on 
the target PC.

----------

### geowatch

**Usage:**  
`geowatch [<object>]`

**Examples:**  
`geowatch *MyObj`  
Display geometry calls that have reached the object MyObj

`geowatch`  
Display geometry calls that have reached *ds:si (asm) or oself 
(goc)

**Synopsis:**  
This displays geometry calls that have reached a particular object. Only one 
object at a time can be watched in this way.

**Notes:**

+ Two conditional breakpoints are used by this function (see cbrk). The 
tokens for these breakpoints are returned. 

+ The special object flags may be used to specify object.  For a list of these 
flags, see pobject.

**See Also:**  
objwatch, mwatch, cbrk, pobject.

----------

### get-address

Used by the various memory-access commands. Takes one argument, ADDR, 
being the address argument for the command. Typically, the command is 
declared as 

`[defcmd cmd { {addr nil}}...]`

allowing the address to be unspecified. This function will return the given 
address if it was, else it will return the last-accessed address (stored in the 
global *lastAddr* variable as a 3-tuple from addr-parse) in the form of an 
address expression. If no address is recorded (*lastAddr* is nil), the 
default-addr argument is used. If it is not specified then CS:IP will be used.

----------

### getcc

**Usage:**  
`getcc <flag>`

**Examples:**  
`getcc c`  
Get the carry flag.

**Synopsis:**  
Get a flag from the target machine.

**Notes:**  

+ The first argument is the first letter of the flag to get. The following is a 
list of the flags: 

    `t` - trap  
    `i` - interrupt enable  
    `d` - direction  
    `o` - overflow  
    `s` - sign  
    `z` - zero  
    `a` - auxiliary carry  
    `p` - parity  
    `c` - carry

+ This command is handy to run with a breakpoint to stop if a flag is set.

**See Also:**  
setcc, clrcc, compcc.

----------

### getenv

**Usage:**  
`getenv <NAME>`

**Examples:**  
`getenv PTTY`  
Fetches the value of the host machine's PTTY environment 
variable.

**Synopsis:**  
Returns the value for a variable defined in Swat's environment.

**Notes:**  
If the variable isn't defined, this returns the empty string.

**See Also:**  
var, string.

----------

### get-key-binding

**Usage:**  
`get-key-binding <char>`

**Examples:**  
`get-key-binding c`  
Gets key binding for the character c.

`get-key-binding \045`  
Gets key binding for the % key.

**Synopsis:**  
Gets key binding for given key.

**See Also:**  
alias, bind-key, unbind-key.

----------

### getvalue

**Usage:**  
`getvalue <expr>`

**Examples:**  
`getvalue MSG_META_DETACH`  
Returns the integer value of the symbol MSG\_META_DETACH.

**Synopsis:**  
This is a front-end to the "addr-parse" command that allows you to easily 
obtain the integer value of any expression. It's most useful for converting 
something the user might have given you to a decimal integer for further 
processing.

**Notes:**  
If the expression you give does not evaluate to an address (whose offset will 
be returned) or an integer, the results of this function are undefined.

**See Also:**  
addr-parse, addr-preprocess.

----------

### global

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### go

**Usage:**  
`go [<address expressions>]`

**Examples:**  
`go`  
`go drawLeftLine`

**Synopsis:**  
Go until an address is reached.

**Notes:**  
The `<address expressions>` argument is as many address expressions as 
desired for breakpoints. Execution is continued until a breakpoint is 
reached. These breakpoints are then removed when the machine stops 
and are only active for the current patient.

**See Also:**  
break, continue, det, quit.

----------

### grobjtree

**Usage:**  
`grobjtree [<address>] [<instance field>]`  

**Examples:**  
`grobjtree`  
Print the grobj tree starting at *ds:si

**Synopsis:**  
Print out a GrObj tree.

**Notes:**

+ The address argument is the address of a GrObj Body This defaults to 
*ds:si. 

+ To get the address of the grobj body, use the "pbody" or "target" 
commands. 

**See Also:**  
pbody.

----------

### gup

**Usage:**  
`gup [<address>] [<instance field>]`

**Examples:**  
`gup`  
print the generic object at *DS:SI and its ancestors

`gup @23 GI_states`  
print the states of object @23 and its ancestors

`gup -i`  
print the generic object under the mouse and the object's 
ancestors

**Synopsis:**  
Print a list of the object and all of its generic ancestors.

**Notes:**

+ The address argument is the address to an object in the generic tree. This 
defaults to *DS:SI. The `-i' flag for an implied grab may be used.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ The instance field argument is the offset to any instance data within the 
GenInstance which should be printed out.

**See Also:**  
gentree, vup, vistree, impliedgrab.

----------

### handle

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### handles

**Usage:**  
`handles [<flags>] [<patient>]`

Examples:  
`handles`  
`handles -f`  
`handles ui`  

**Synopsis:**  
Print all handles in-use.

**Notes:**	

+ The flags argument is a collection of flags, beginning with `-', from the 
following set:

    `s` - print summary only.  
    `e` - events only.  
    `p` - don't print prevPtr and nextPtr.  
    `f` - fast print-out - this doesn't try to figure out the block type.  
    `r` - reverse, i.e. starts at the end of the handle table.  
    `u` - print only those handles that are in-use.

+ The patient argument is a patient whose blocks are to be selectively 
printed (either a name or a core-block's handle ID). The default is to print 
all the blocks on the heap.

+ The following columns can appear in a listing:

    HANDLE - The handle of the block  
    ADDR - The segment address of the block  
    SIZE - Size of the block in bytes  
    PREV - The previous block handle (appears with the p flag)  
    NEXT - The next block handle (appears with the p flag)  
    FLAGS - The following letters appears in the FLAGS column:

    **s** - sharable,  
    **S** - swapable,  
    **D** - discardable,  
    **L** - contains local memory heap,  
    **d** - discarded (by LMem module: discarded blocks don't appear here),  
    **a** - attached (notice given to swat whenever state changes)

    LOCK - Number of times the block is locked or n/a if FIXED.  
    OWNER - The process which owns the block  
    IDLE - The time since the block has been accessed in minutes:seconds  
    OINFO - The otherInfo field of the handle (block type dependent)  
    TYPE - Type of the block, for example: R#1 (dgroup) resource number one

+ This only prints those handles in memory while `handles' prints all 
handles used.

+ The handles may be printed with lhwalk and phandle.

**See Also:**  
lhwalk, phandle, hgwalk.

----------

### handsum

**Usage:**  
`handsum`

**Examples:**  
`handsum`  
Summarize the use to which the handle table is being put.

**Synopsis:**  
This command analyzes the handle table and prints out a list of the number 
of handles being used by each geode, and for what purpose.

**Notes:**

+ The columns of the output are labeled somewhat obscurely, owing to 
horizontal-space constraints. The headings, and their meanings are:

    Res - Resource handles (i.e. handles for data stored in the geode's 
executable)  
    Mem - Non-resource memory handles  
    File - Open files  
    Thds - Threads  
    Evs - Recorded events  
    Qs - Event queues  
    Sems - Semaphores  
    EDat - Data for recorded events  
    Tim - Timers  
    SB - Saved blocks (handles tracking memory/resource handles whose contents will go to an application's state file)  
    VMF - VM files  

+ The "handles" command is good at printing out all the handles for a 
particular geode, but it's generally too verbose to use for the entire handle 
table. That's why this command exists. 

+ It's a good idea to issue the command "dcache length 4096" before 
executing this command, as it ensures the entire handle table will end up 
in Swat's data cache, for quick access if you want to use the "handles" 
command immediately afterward. 

----------

### hbrk

**Usage:**  
`hbrk <address> (byte|word) (match|mismatch) <value>`

**Examples:**  
`hbrk scrollTab+10 byte match 0`  
print message handlers until a zero is written at scrollTab+10.

`hbrk OLScrollButton+3 word mismatch 0x654f`  
Break when the word at OLScrollButton+3 is destroyed.

**Synopsis:**  
Break when a memory location changes.

**Notes:**	

+ The `<address>` argument is the address to watch for a change.

+ The (byte|word) argument indicates whether to watch a byte or a word 
for a change.

+ The (match|mismatch) argument indicates whether to break if the value 
at the address matches or mismatches the value hbrk is called with.

+ hbrk emulates a hardware breakpoint by checking at every message call 
to see if a location in memory has been written to. If so, swat breaks and 
tells between which two messages the write occurred. The information 
and the return stack will hopefully guide you to the offending line of code.

+ The command creates two breakpoints. Remove these to get rid of the 
hardware breakpoint.

**See Also:**  
brk, mwatch, showcalls.

----------

### heapspace

**Usage:**  
`heapspace <geode>`  
`heapspace total`  
`heapspace syslib`

**Examples:**  
`heapspace geomanager`  
print out "heapspace" value for geomanager

`heapspace total`  
print out maxTotalHeapSpace

`heapspace syslib`  
print out space being used by system libraries.

**Synopsis:**  
Prints out how much space the program requires on the heap. This value may 
then be used in a "heapspace" line of the program's .gp file. This command 
only determines present usage-to determine the most heapspace your geode 
will ever use requires that you make it allocate as much space as it ever will. 
This means pulling down all menus, opening all dialog boxes, and generally 
building out all UI gadgetry. The value this command prints is roughly the 
non-discardable heap usage by the app and any transient libraries that it 
depends on, plus an additional amount for thread activity.

----------

### help

**Usage:**  
`help [<command>]`

**Synopsis:**  
This is the user-level access to the on-line help facilities for Swat. If given a 
topic (e.g. "brk") as its argument, it will print all help strings defined for the 
given topic (there could be more than one if the same name is used for both a 
variable and a procedure, for instance). If invoked without arguments, it will 
enter a browsing mode, allowing the user to work his/her way up and down 
the documentation tree.

----------

### help-fetch

**Usage:**  
`help-fetch <topic-path>`

**Examples:**  
`help-fetch top.patient`

**Synopsis:**  
Fetches the help string for a given topic path in the help tree.

**Notes:**  
If there is more than one node with the given path in the help tree, only the 
string for the first node will be returned.

----------

### help-fetch-level

**Usage:**  
`help-fetch-level`

**Examples:**  
`help-fetch-level top.prog.obscure`  
Returns the topics within the "top.prog.obscure" level of the 
help tree.

**Synopsis:**  
Returns a list of the topics available at a given level in the help tree.

**Notes:**  
The result is a list of node names without leading path components.

**See Also:**  
help-fetch.

----------

### help-help

**Usage:**  
`help-help`

**Synopsis:**  
Provides help about using the help command (q.v.)

**See Also:**  
help.

----------

### help-is-leaf

**Usage:**  
`help-is-leaf <topic-path>`

**Examples:**  
`help-is-leaf top.prog`  
See if top.prog is a leaf node in the help tree (i.e. if it has no 
children).

**Synopsis:**  
Determines whether a given path refers to a help topic or a help category.

**Notes:**  
Returns one if the given path refers to a leaf node, zero if it is not.

**See Also:**  
help-fetch, help-fetch-level.

----------

### help-minAspect

**Usage:**  
`var help-minAspect [<ratio-times-ten>]`

**Synopsis:**  
If non-zero, contains the minimum aspect ratio to be maintained when 
displaying tables in the help browser. The ratio is expressed as the fraction

`entries_per_column*10/number_of_columns`

E.g. a minimum ratio of 1.5 would be 15. (We multiply by ten because Swat 
doesn't support floating point numbers.)

----------

### help-scan

**Usage:**  
`help-scan <pattern>`

**Examples:**  
`help-scan break`  
Looks for all nodes at any level of the help tree whose 
documentation includes the pattern "break".

**Synopsis:**  
Scans all nodes in the help tree for those whose documentation matches a 
given pattern.

**Notes:**  
The result is a list of topic-paths.

**See Also:**  
help-fetch.

----------

### help-verbose

**Usage:**  
`var help-verbose [0|1)]`

**Synopsis:**  
If non-zero, performs verbose prompting.

----------

### hex

**Usage:**  
`hex <number>`

**Examples:**  
`hex 034`  
print hex equivalent of octal 34.

`hex 12`  
print hex equivalent of decimal 12.

**Synopsis:**  
Print hexadecimal equivalent of a number.

----------

### hgwalk

**Usage:**  
`hgwalk`

**Examples:**  
`hgwalk`  
print statistics on all geodes

**Synopsis:**  
Print out all geodes and their memory usage.

----------

### history

**Usage:**  
`history [<args>]`

**Examples:**  
`history 10`  
Prints the last 10 commands entered via the "history subst" 
command.

`history subst $line`  
Performs history substitution on the string in $line, enters the 
result in the history queue and returns the result.

`var n [history cur]`  
Stores the number of the next string to be entered via "history 
subst" in the variable n.

`history set 50`  
Limit the number of entries in the queue to 50.

`history fetch 36`  
Returns the string entered as command number 36 in the 
history queue.

**Synopsis:**  
This command manipulates the history list. Options are:  
`<number>` - Prints the most-recent <number> commands  
`set <queue-size>` - Sets the number of commands saved  
`subst <str>` - Performs history substitution on `<str>` and enters it into the 
history queue.  
`cur` - Returns the current history number. If no argument is given, 
all saved commands are printed.  
`fetch <n>` - Returns the string entered as command number `<n>` in the 
history queue.  

**See Also:**  
top-level-read

----------

### hwalk

**Usage:**  
`hwalk [<flags>] [<patient>]`

**Examples:**  
`hwalk`  
display the heap

`hwalk -e`  
display the heap and perform error checking

`hwalk -r ui`  
display the heap owned by the ui in reverse order

**Synopsis:**  
Print the status of all blocks on the global heap.

**Notes:**

+ The `<flags>` argument is a collection of flags, beginning with "-", from the 
following set:

    `r` - print heap in reverse order (decreasing order of addresses)  
    `p` - print prevPtr and nextPtr as well.  
    `e` - do error-checking on the heap.  
    `l` - just print out locked blocks  
    `f` - fast print-out-this doesn't try to figure out the block type  
    `F` - print out only fixed (or pseudo-fixed) resources.  
    `c` - Print out only code resources (discardable or fixed non-lmem non-dgroup resources).  
    `s <num>` - start at block `<num>`

+ The patient argument is a patient whose blocks are to be selectively 
printed (either a name or a core-block's handle ID). The default is to print 
all the blocks on the heap.

+ The following columns can appear in a listing:

    HANDLE - The handle of the block  
    ADDR - The segment address of the block  
    SIZE - Size of the block in bytes  
    PREV - The previous block handle (appears with the p flag)  
    NEXT - The next block handle (appears with the p flag)  
    FLAGS - The following letters appears in the FLAGS column:

    **s** - sharable  
    **S** - swapable  
    **D** - discardable  
    **L** - contains local memory heap  
    **d** - discarded (by LMem module: discarded blocks don't appear here)  
    **a** - attached (notice given to swat whenever state changes)

    LOCK - Number of times the block is locked or n/a if FIXED.  
    OWNER - The process which owns the block  
    IDLE - The time since the block has been accessed in minutes:seconds  
    OINFO - The otherInfo field of the handle (block type dependent)  
    TYPE - Type of the block, for example:

    **R#1 (dgroup)** - Resource number one, named "dgroup"  
    **Geode** - Internal control block for a geode  
    **WINDOW, GSTATE,** - Internal structures of the given type  
    **GSTRING, FONT_BLK, FONT OBJ(write:0)** - Object block run by thread write:0  
    **VM(3ef0h)** - VM block from VM file 3ef0h

+ This only prints those handles in memory while `handles' prints all 
handles used.

+ The handles may be printed with lhwalk and phandle.

**See Also:**  
lhwalk, phandle, handles, hgwalk.

----------

### iacp

**Usage:**  
`iacp -ac`  
prints all connections

`iacp -l`  
prints all lists without connections

`iacp -d`  
prints all open documents

`iacp <obj>`  
prints all connections to which `<obj>` is party

----------

### ibrk

Set a breakpoint interactively. At each instruction, you have several options:

**q** - Quit back to the command level.  
**n** - Go to next instruction (this also happens if you just hit return).  
**p** - Go to previous instruction.  
**P** - Look for a different previous instruction.  
**^D** - Go down a "page" of instructions. The size of the page is 
controlled by the global variable ibrkPageLen. It defaults to 10.  
**^U** - Go up a "page" of instructions.  
**b** - Set an unconditional breakpoint at the current instruction and 
go back to command level.  
**a** - Like 'b', but the breakpoint is set for all patients.  
**t** - Like 'b', except the breakpoint is temporary and will be	 
removed the next time the machine stops.  
**B** - Like 'b', but can be followed by a command to execute when the 
breakpoint is hit.  
**A** - Like 'B', but for all patients.  
**T** - Like 'B', but breakpoint is temporary.

----------

### ibrkPageLen

**Usage:**  
`var ibrkPageLen [<number-of-lines>]`

**Synopsis:**  
Number of instructions to skip when using the ^D and ^U commands of ibrk.

----------

### if

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### ignerr

**Usage:**  
`ignerr`

**Examples:**  
`ignerr`  
ignore error and continue

`ignerr MyFunc::done`  
ignore error and continue at MyFunc::done.

**Synopsis:**  
Ignore a fatal error and continue.

**Notes:**

+ The address argument is the address of where to continue execution. If 
not specified then CS:IP is taken from the frame. 

+ The stack is patched so that execution can continue in the frame above 
the fatal error handling routine.

**See Also:**  
why, backtrace.

----------

### imem

**Usage:**  
`imem [<address>] [<mode>]`

**Examples:**  
`imem`  
enter imem mode at DS:SI

`imem ds:di`  
enter imem mode at DS:SI

**Synopsis:**  
Examine memory and modify memory interactively.

**Notes:**

+ The address argument is the address to examine. If not specified, the 
address after the last examined memory location is used. If no address 
has been examined then DS:SI is used for the address.

+ The mode argument determines how the memory is displayed and 
modified. Each of the four modes display the memory in various 
appropriate formats. The modes are:



----------
	Table 4-1 Memory Modes

	Mode	Size	1st column		2nd column		3rd column

	b		byte	hex byte		signed dec		ASCII character
	w		word	hex word		unsigned dec	signed decimal
	d		dword	segment:offset	signed dec		symbol
	i		???		hex bytes		assembler instr.

+ The default mode is swat's best guess of what type of object is at the 
address.

+ imem lets you conveniently examine memory at different locations and 
assign it different values. imem displays the memory at the current 
address according to the mode. From there you can move to another 
memory address or you can assign the memory a value.

+ You may choose from the following single-character commands:

    `b, w, d,i` - Sets the mode to the given one and redisplays the data.

    `n, j, <Return>` - Advances to the next data item. The memory address advances 
by the size of the mode.

    `p, k` - Returns to the preceding data item. The memory address 
decreases by the size of the mode. When displaying 
instructions, a heuristic is applied to locate the preceding 
instruction. If it chooses the wrong one, use the `P' command to 
make it search again.

    `<space>` - Clears the data display and allows you to enter a new value 
appropriate to the current display mode. The "assign" 
command is used to perform the assignment, so the same rules 
apply to it, with the exception of \`- and "- quoted strings. A 
string with \`s around it (`hi mom') has its characters poked into 
memory starting at the current address. A string with "s 
around it ("swat.exe") likewise has its characters poked into 
memory, with the addition of a null byte at the end. This 
command is not valid in instruction mode.

    `q` - quit imem and return to command level. The last address 
accessed is recorded for use by the other memory-access 
commands.

    `^D` - Display a "page" of successive memory elements in the current 
mode.

    `^U` - Display a "page" of preceding memory elements in the current 
mode.

    `h, ?` - This help list.

    For ^D and ^U, the size of a "page" is kept in the global variable imemPageLen, which defaults to 10.

**See Also:**  
bytes, words, dwords, assign.

----------

### imemPageLen

**Usage:**  
`var imemPageLen [<numlines>]`

**Synopsis:**  
Contains the number of elements to display when imem is given the ^D or 
^U command.

----------

### impliedgrab

**Usage:**  
`impliedgrab`

**Examples:**  
`gentree [impliedgrab]`  
print the generic tree under the mouse

**Synopsis:**  
Print the address of the current implied grab, which is the screen object 
grabbing the mouse.

**Notes:**  
This command is normally used with gentree to get the generic tree of an 
application by placing the mouse on application's window and issuing the 
command.

**See Also:**  
systemobj, gentree.

----------

### impliedwin

**Usage:**  
`impliedwin`

**Examples:**  
`wintree [impliedwin]`  
print the window tree of the window under the mouse

**Synopsis:**  
Print the address of the current implied window (the window under the 
mouse).

**Notes:**

+ Note that a window handle is returned.

+ This command is normally used with wintree. One may also use the print 
command if they properly cast the handle.

----------

### index

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### info

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### int

**Usage:**  
`int [<int level> <state>]`

**Examples:**  
`int`  
report the interrupt statuses

`int 1:1 on`  
allow keyboard interrupt while in swat

**Synopsis:**  
Set or print the state of the two interrupt controllers for when then machine 
is stopped in Swat.

**Notes:**

+ If no arguments are given, the current state is printed.

+ The `<int level>` argument is specified by their names or their numbers 
with the form `<controller>:<number>`. `<controller>` is either 1 or 2, and 
`<number>` ranges from 0 to 7. The interrupts and their numbers are:

    **Timer 1:0** - System timer. Probably dangerous to enable.  
    **Keybd 1:1** - Keyboard input.  
    **Slave 1:2** - This is how devices on controller 2 interrupt. Disabling this 
disables them all.  
    **Com2 1:3** - This is the port usually used by Swat, so it can't be disabled.  
    **Com1 1:4** - The other serial port -- usually the mouse.  
    **LPT2 1:5** - The second parallel port  
    **Floppy 1:6** - Floppy-disk drive  
    **LPT1 1:7** - First parallel port  
    **Clock 2:0** - Real-time clock  
    **Net 2:1** - Network interfaces (?)  
    **FPA 2:5** - Coprocessor  
    **HardDisk 2:6** - Hard-disk drive  

+ The `<state>` argument is either on or off.

----------

### intFormat

{% raw %}

**Usage:**  
`var intFormat [<format-string>]`

**Examples:**  
`var intFormat %d`  
Sets the default format for printing unsigned integers to 
decimal.

**Synopsis:**  
*$intFormat* contains the string passed to the "format" command to print an 
integer.

**Notes:**  
The default value is {%xh}, which prints the integer in hexadecimal, followed 
by an "h".

**See Also:**  
print, byteAsChar.

{% endraw %}

----------

### intr

Catch, ignore, or deliver an interrupt on the target PC. First argument is the 
interrupt number. Optional second argument is "catch" to catch delivery of 
the interrupt, "ignore" to ignore the delivery, or "send" to send the interrupt 
(the machine will keep going once the interrupt has been handled). If no 
second argument is given, the interrupt is delivered.

----------

### io

**Usage:**  
`io [w] <port> [<value>]`

**Examples:**  
`io 21h`  
Reads byte-sized I/O port 21h.

`io 20h 10`  
Writes decimal 10 to byte-sized I/O port 20h.

**Synopsis:**  
Provides access to any I/O port on the PC.

**Notes:**

+ If you give the optional first argument "w" then Swat will perform a 
16-bit I/O read or write, rather than the default 8-bit access. Be aware 
that most devices don't handle this too well. 

+ `<port>` must be a number (in any radix); it cannot be a register or other 
complex expression. 

+ If you don't give a `<value>`, you will be returned the contents of the I/O 
port (it will not be printed to the screen). 

----------

### irq

**Usage:**  
`irq`  
`irq (no|yes)`  
`irq (set|clear)`

**Examples:**  
`irq`  
Returns non-zero if an interrupt is pending.

`irq no`  
Disable recognition and acting on a break request from the 
keyboard.

`irq set`  
Pretend the user typed Ctrl-C.

**Synopsis:**  
Controls Swat's behavior with respect to interrupt requests from the 
keyboard.

**Notes:**

+ Swat maintains an interrupt-pending flag that is set when you type 
Ctrl+C (it can also be set or cleared by this command). It delays acting on 
the interrupt until the start of the next or the completion of the current 
Tcl command, whichever comes first. 

+ When given no arguments, it returns the current state of the 
interrupt-pending flag. This will only ever be non-zero if Swat is ignoring 
the flag (since the command wouldn't actually return if the flag were set 
and being paid attention to, as the interpreter would act on the flag to 
vault straight back to the command prompt). 

+ If given "no" or "yes" as an argument, it causes Swat to ignore or pay 
attention to the interrupt-pending flag, respectively. 

+ You can set or clear the flag by giving "set" or "clear" as an argument.

----------

### is-obj-in-class

**Usage:**  
`is-obj-in-class <obj-addr> <class-name>`

**Examples:**  
`is-obj-in-class ^l4e10h:1eh GenPrimaryClass`  
see if the object at ^l4e10h:1eh is in GenPrimaryClass.

**Synopsis:**  
Returns whether a given object in the specified class.

**Notes:**

+ Returns one if the object is in the specified class, zero otherwise. It will 
return one if the object's class is a subclass of the passed class.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

**See Also:**  
psup.

----------

### istep

**Usage:**  
`istep [<default command>]`

**Examples:**  
`is`  
enter instruction step mode

`istep n`  
enter instruction step mode, `<ret>` does a next command

**Synopsis:**  
Step through the execution of the current patient. This is THE command for 
stepping through assembly code.

**Notes:**	

+ The default command argument determines what pressing the `<Return>` 
key does. By default, `<Return`> executes a step command. Any other 
command listed below may be substituted by passing the letter of the 
command.

+ Istep steps through the patient instruction by instruction, printing 
where the ip is, what instruction will be executed, and what the 
instruction arguments contain or reference. Istep waits for the user to 
type a command which it performs and then prints out again where istep 
is executing.

+ This is a list of istep commands:

    `q, <Esc>, " "` - Stops istep and returns to command level.  
    `b` - Toggles a breakpoint at the current location.  
    `c` - Stops istep and continues execution.  
    `n` - 	Continues to the next instruction, skipping procedure calls, 
repeated string instructions, and software interrupts. Using 
this procedure, istep only stops when the machine returns to 
the right context (i.e. the stack pointer and current thread are 
the same as they are when the "n" command was given). 
Routines which change the stack pointer should use "N" 
instead.  
`o` - Like "n" but steps over macros as well.  
`l` - Goes to the next library routine.  
`N` - Like \`n', but stops whenever the breakpoint is hit, whether 
you're in the same frame or not.  
`O` - Like \`N' but steps over macros as well.  
`m, M` - Goes to the next method called. Doesn't work when the 
message is not handled anywhere.  
`F` - Finishes the current message.  
`f` - Finishes out the current stack frame.  
`s, <Return>` - Steps one instruction.  
`A` - Aborts the current stack frame.  
`S` - Skips the current instruction  
`B` - Backs up an instruction (opposite of "S").  
`J` - Jump on a conditional jump, even when "Will not jump" 
appears. This does not change the condition codes.  
`g` - Executes the \`go' command with the rest of the line as 
arguments.  
`e` - Executes a Tcl command and returns to the prompt.  
`r` - Lists the registers (uses the regs command)  
`R` - References either the function to be called or the function 
currently executing.  
`h, ?` - Displays a help message.

+ If the current patient isn't the actual current thread, istep waits for the 
patient to wake up before single-stepping it.

**See Also:**  
sstep, listi, ewatch.

----------

[Swat Introduction](tswatcm.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Swat Reference J-Z](tswtj_z.md)