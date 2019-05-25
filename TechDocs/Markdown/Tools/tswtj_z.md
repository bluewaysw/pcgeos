### 4.3 Swat Reference J-Z

----------

### keyboard

**Usage:**  
`keyboard [<object>]`

**Examples:**  
`keyboard`  
print keyboard hierarchy from system object down

`keyboard -i`  
print keyboard hierarchy from implied grab down

`keyboard ^l4e10h:20h`  
print keyboard hierarchy from ^l4e10h:20h down.

**Synopsis:**  
Prints the keyboard hierarchy below an object.

**Notes:**

+ If no object is specified, the system object is used. 

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. 

    This variable defaults to false. 

**See Also:**  
target, focus, mouse, model, pobject.

----------

### keyboardobj

**Usage:**  
keyboardobj

**Examples:**  
`keyboardobj`  
return object with keyboard grab

`pobj [keyboardobj]`  
do a **pobject** on the object with the keyboard grab (equivalent  
to "pobj -kg").

**Synopsis:**  
Returns the object with the keyboard grab.

**See Also:**  
target, focus, mouse, keyboard, mouseobj.

----------

### lastCommand

**Usage:**  
$lastCommand

**Examples:** 
`var repeatCommand $lastCommand`  
Set the current command as the command to execute next time.

**Synopsis:**  
$lastCommand stores the text of the command currently being executed.

**Notes:**  
This variable is set by top-level-read. Setting it yourself will have no effect, 
unless you call set-address or some similar routine that looks at it. 

**See Also:**  
repeatCommand, top-level-read.

----------

### length

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### lhwalk

**Usage:**  
`lhwalk [<address>]`

**Examples:**  
`lhwalk 1581h`  
list the lm heap at 1581h:0

**Synopsis:**  
Prints out information about a local memory heap.

**Notes:**  
The address argument is the address of the block to print. The default is 
the block pointed to by DS.

**See Also:**  
hwalk, objwalk

----------

### link

**Usage:**  
`link <library> [<patient>]`

**Examples:**  
`link motif`  
Makes the library "motif" a library of the current patient as far 
as Swat is concerned.

**Synopsis:**  
Allows you to link a patient to act as an imported library of another patient, 
even though the other patient doesn't actually import the patient. This is 
useful only for symbol searches.

**Notes:**

+ sym-default is a much better way to have Swat locate symbols for 
libraries that are loaded by **GeodeUseLibrary()**. 

+ Cycles are not allowed. I.e. don't link your application as a library of the 
UI, as it won't work-or if it does, it will make Swat die. 

+ The link persists across detach/attach sequences so long as the <patient> 
isn't recompiled and downloaded. 

+ If you don't give `<patient>`, then the current patient will be the one made 
to import `<library>` 

+ Both `<library>` and `<patient>` are patient names, not tokens.

**See Also:**  
help-fetch.

----------

### list

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### listi

**Usage:**  
`listi [<address>] [<length>]`

**Examples:**  
`l`  
disassemble at the current point of execution

`listi geos::Dispatch`  
disassemble at the kernel's dispatch routine

`listi DocClip:IsOut`  
disassemble at the local label

`listi cs:ip 20`  
disassemble 20 instructions from the current point of execution

**Synopsis:**  
Disassemble at a memory address.

**Notes:**

+ The `<address>` argument is the address to examine. If not specified, the 
address after the last examined memory location is used. If no address 
has be examined then CS:IP is used for the address.

+ The `<length>` argument is the number of instructions to list. It defaults 
to 16.

+ Pressing `<Return>` after this command continues the list.

**See Also:**  
istep, sstep, skip, where.

----------

### load

**Usage:**  
`load <file>`

**Synopsis:**  
Load a file of Tcl commands.

+ If the file cannot be found as given, it is looked for in all the directories 
mentioned in the "load-path" variable. This variable is initialized from 
the SWATPATH environment variable, which is in the form 
`<dir1>:<dir2>:...:<dirN>`.

+ The Swat library directory is appended to this path so you need not 
include it yourself. The file need not end in ".tcl".

+ When searching, *file*, *file.tcl*, and *file.tlc* are searched for. If load finds a 
*file.tlc* file, that file will be used only if it is more recent than any 
corresponding *file.tcl* or *file* file.

----------

### loadapp

Load an application from swat. Single argument is the file name of the 
application to launch (application must reside in the appl subdirectory of the 
GEOS tree). 

The application is opened in normal application mode. Note that the 
application will not be loaded until you continue the machine, as the loading 
is accomplished by sending a message to the UI.

----------

### loadgeode

Load a geode from swat. Mandatory first argument is the name of the file to 
load (with path from top-level GEOS directory, using / instead of \ as the path 
separator). 

Second and third arguments are the data words to pass to the geode. The 
second argument is passed to the geode in cx, while the third argument is 
passed in dx.

Both the second and third arguments are optional and default to 0. They 
likely are unnecessary.

----------

### locals

**Usage:**  
`locals [<func>]`

**Examples:**  
`locals`  
Print the values of all local variables and arguments for the 
current frame.

`locals WinOpen`  
Print the names of all local variables for the given function. No 
values are printed.

**Synopsis:**  
Allows you to quickly find the values or names of all the local variables of a 
function or stack frame.

**See Also:**  
print, frame info

----------

### localwin

**Usage:**  
`localwin [<numlines>]`

**Examples:**  
`localwin`  
Display local variables in a 10-line window

`localwin 15`  
Display local variables in a 15-line window

`localwin off`  
Turn off the local variable display

**Synopsis:**  
Turn on or off the continuous display of local variables.

**Notes:**

+ Passing an optional numerical argument turns on display of that size. 
The default size is 10 lines. 

+ Only one local variable display may be active at a time.

----------

### loop

Simple integer loop procedure. Usage is:

	loop <loop-variable> <start>,<end> [step <step>] <body>	

`<start>`, `<end>`, and `<step>` are integers. `<body>` is a string for Tcl to 
evaluate. If no `<step>` is given, 1 or -1 (depending as `<start>` is less than or 
greater than `<end>`, respectively) is used. `<loop-variable>` is any legal Tcl 
variable name.

----------

### map

**Usage:**  
`map <var-list> <data-list>+ <body>`

**Examples:**  
`map {i j} {a b} {c d} {list $i $j}`  
Executes the command "list $i $j" with i and j assigned to 
successive elements of the lists {a b} and {c d}, respectively, 
merging the results into the list {{a c} {b d}}

**Synopsis:**  
This applies a command string to the successive elements of one or more lists, 
binding each element in turn to a variable and evaluating the command 
string. The results of all the evaluations are merged into a result list.

**Notes:**

+ The number of variables given in `<var-list>` must match the number of 
`<data-list>` arguments you give.

+ All the `<data-list>` arguments must have the same number of elements.

+ You do not specify the result of the `<body>` with the "return" command. 
Rather, the result of `<body>` is the result of the last command executed 
within `<body>`.

**See Also:**  
foreach, mapconcat.

----------

### mapconcat

**Usage:**  
`mapconcat <var-list> <data-list>+ <body>`

**Examples:**  
`mapconcat {i j} {a b} {c d} {list $i $j}`  
Executes the command "list $i $j" with i and j assigned to 
successive elements of the lists {a b} and {c d}, respectively, 
merging the results into a string.

----------

### map-method



**Usage:**  
`map-method <number> <object>`  
`map-method <number> <class-name> [<object>]`

**Examples:**  
`map-method ax ^lbx:si`  
Prints the name of the message in ax, from the object at 
^lbx:si's perspective.

`map-method 293 GenClass`  
Prints the name of message number 293 from GenClass's 
perspective.

**Synopsis:**  
Maps a message number to a human-readable message name, returning that 
name. This command is useful both for the user and for a Tcl procedure.

**Notes:**

+ When called from a Tcl procedure, the `<class-name>` argument should be 
the fullname of the class symbol (usually obtained with the obj-class 
function), and `<object>` should be the address of the object for which the 
mapping is to take place. If no `<object>` argument is provided, 
map-method will be unable to resolve messages defined by one of the 
object's superclasses that lies beyond a variant superclass. 

+ If no name can be found, the message number, in decimal, is returned. 

+ The result is simply returned, not echoed. You will need to echo the result 
yourself if you call this function from anywhere but the command line. 

**See Also:**  
obj-class.

----------

### mcount

**Usage:**  
`mcount [<args>]`

**Examples:**  
`mcount`  
start the method count or print the count

`mcount reset`  
restart the method count

`mcount stop`  
stop the method count

`mcount MyAppRecalcSize`  
count messages handled by MyAppRecalcSize

**Synopsis:**  
Keep a count of the methods called.

**Notes:**  
The args argument may be one of the following:

"nothing" - start the method count or print the current count  
"reset" - reset the count to zero  
"stop" - stop the method count and remove it's breakpoint  
"message handler" - start the method count for a particular method

**See Also:**  
mwatch, showcalls.

----------

### memsize

**Usage:**  
`memsize [<memory size>]`

**Examples:**  
`memsize`

`memsize 512`

**Synopsis:**  
Change the amount of memory that GEOS thinks that it has.

**Notes:**

+ The `<memory size>` argument is the size to make the heap. If none is 
specified then the current memory size is returned.

+ Memsize can only be run at startup, before the heap has been initialized. 
Use this right after an `att -s'.

+ Memsize accounts for the size of the stub.

----------

### methods

**Usage:**  
`methods <class>`  
`methods <object>`  
`methods <flags>`

**Examples:**  
`methods -p`  
Print out methods defined for process

`methods ui::GenDocumentClass`  
Print out GenDocumentClass methods

`methods 3ffch:072fh`  
Print out methods for class at addr

`methods -a`  
Print methods of top class of app obj

**Synopsis:**  
Prints out the method table for the class specified, or if an object is passed, 
for the overall class of the object. Useful for getting a list of candidate 
locations to breakpoint.

----------

### model

**Usage:**  
`model [<object>]`

**Examples:**  
`model`  
print model hierarchy from system object down

`model -i`  
print model hierarchy from implied grab down

`model ^l4e10h:20h`  
print model hierarchy from ^l4e10h:20h down.

**Synopsis:**  
Prints the model hierarchy below an object.

**Notes:**

+ If no object is specified, the system object is used. 

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ Remember that the object you start from may have the model exclusive 
within its part of the hierarchy, but still not have the exclusive because 
something in a different part of the tree has it. 

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. 

	This variable defaults to false. 

**See Also:**  
target, focus, mouse, keyboard, pobject.

----------

### modelobj

**Usage:**  
`modelobj`

**Examples:**  
`modelobj`  
print model hierarchy from system object down

`pobj [modelobj]`  
Do a pobject on the object with the model grab (the equivalent 
of a "pobj -m").

**Synopsis:**  
Returns the object with the model grab.

**See Also:**  
target, focus, model, focusobj, targetobj.

----------

### mouse

**Usage:**  
`mouse [<object>]`

**Examples:**  
`mouse`  
print mouse hierarchy from system object down

`mouse -i`  
print mouse hierarchy from implied grab down

`mouse ^l4e10h:20h`  
print mouse hierarchy from ^l4e10h:20h down.

**Synopsis:**  
Prints the mouse hierarchy below an object.

**Notes:**

+ If no object is specified, the system object is used. 

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. 

    This variable defaults to false. 

**See Also:**  
target, focus, model, keyboard, pobject.

----------

### mouseobj

**Usage:**  
`mouseobj`

**Examples:**  
`mouseobj`  
return object with mouse grab

`pobj [mouseobj]`  
do a pobject on the object with the mouse grab (equivalent to 
"pobj -mg").

**Synopsis:**  
Returns the object with the mouse grab.

**See Also:**  
target, focus, mouse, keyboard, keyboardobj.

----------

### mwatch

**Usage:**  
`mwatch <msg>+`  
`mwatch add <msg>+`  
`mwatch list`  
`mwatch clear`

**Examples:**  
`mwatch MSG_VIS_DRAW MSG_METAQUIT`  
watch these messages

`mwatch add MSG_META_START_SELECT`  
watch this message also

`mwatch`  
clear all message watches

**Synopsis:**  
Display all deliveries of a particular message.

**Notes:**

+ The msg argument is which messages to watch. Those specified replace 
any messages watched before. If none are specified then any messages 
watched will be cleared.

+ You may specify up to eight messages to be watched (fewer if you have 
other conditional breakpoints active). See cbrk for more information 
about conditional breakpoints.

+ "mwatch clear" will clear all message watches. 

+ "mwatch add" will add the specified messages to the watch list. 

+ "mwatch list" will return a list of breakpoints that have been set by 
previous calls to mwatch.

**See Also:**  
objwatch, objbrk, objmessagebrk, procmessagebrk.

----------

### next

**Usage:**  
`next`

**Examples:**  
`next`  
execute the next assembly instruction without entering it

`n`  

**Synopsis:**  
Execute the patient by a single assembly instruction, skipping over any calls, 
repeated instructions, or software interrupts.

**Notes:**  
next does not protect against recursion, so when the breakpoint for the 
next instruction is hit, the frame of execution may be one lower.

**See Also:**  
step, istep.

----------

### noStructEnum

**Usage:**  
`var noStructEnum [(0|1)]`

**Examples:**  
`var noStructEnum 1`  
Don't put "struct" or "enum" before the data type for variables 
that are structures or enumerated types.

**Synopsis:**  
Structure fields that are structures or enumerated types normally have 
"struct" or "enum" as part of their type description. This usually just clutters 
up the display, however, so this variable shuts off this prepending.

**Notes:**  
The default value of this variable is one.

**See Also:**  
print.

----------

### null

**Usage:**  
`null <val>`

**Examples:**  
`null $sym`  
Sees if the symbol token stored in $sym is the empty string or 
"nil."

**Synopsis:**  
Checks to see if a string is either empty or "nil," special values returned by 
many commands when something isn't found or doesn't apply. Returns 
non-zero if `<val>` is either of these special values.

**Notes:**  
The notion of "nil" as a value comes from lisp.

**See Also:**  
index, range

----------

### objbrk

**Usage:**  
`objbrk [<obj address>] [<message>]`

**Examples:**  
`objbrk ds:si MSG_VIS_DRAW`  
break when a MSG\_VIS_DRAW reaches the object

`objbrk -p`  
Break when any message is sent to the process object.

**Synopsis:**  
Break when a particular message reaches a particular object.

**Notes:**

+ If you do not give a `<message>` argument after the `<obj>` argument, the 
machine will stop when any message is delivered to the object.

+ `<obj>` is the address of the object to watch.

+ The `<objbrk>` argument to "objbrk del" is the token/number returned 
when you set the breakpoint.

**See Also:**  
objwatch, objmessagebrk, mwatch.

----------

### obj-class

**Usage:**  
`objclass <obj-addr>`

**Examples:**  
`var cs [obj-class ^lbx:si]`  
Store the symbol token for the class of the object ^lbx:si in the 
variable $cs.

**Synopsis:**  
Figures out the class of an object, coping with unrelocated object blocks and 
the like.

**Notes:**

+ The value return is a symbol token, as one would pass to the "symbol" 
command. Using "symbol name" or "symbol fullname" you can obtain the 
actual class name. 

+ We decide whether to relocate the class pointer ourselves based on the 
LMF\_RELOCATED bit in the LMBH\_flags field of the object block's header. 
There are times, e.g. during the call to MSG\_META_RELOCATE for an 
object, when this bit doesn't accurately reflect the state of the class 
pointer and we will return an error when we should not. 

**See Also:**  
symbol.

----------

### objcount

**Usage:**  
`objcount [-q] [-X] [-Y] [-b #] [-o #] [-p #]`

**Examples:**  
`objcount`  
count all objects

`objcount -p welcome`  
count all objects owned by welcome

`objcount -o *desktop::DiskDrives`  
count this one object

`objcount -b 0x3270`  
count all objects in this block.

**Synopsis:**  
Count up instances of various objects on the heap.

**Notes:**

+ The first argument specifies the options:

    **q** - quiet operation - no progress output (not applicable with X, Y)  
    **o #** - check only object #  
    **b #** - check ONLY block #  
    **p #** - check only blocks for patient #  
    **c #** - check only objects of class #  
    **C #** - check only objects of top-level class #  
    **X** - show general verbose inf  o
    **Y** - show search verbose info

+ Output fields:

    **direct** - number of direct instances of this class  
    **indirect** - number if indirect instance of this class (i.e object's superclass
is this class)  
    **size** - total size of instance data for this class (excludes instance data 
inherited from superclass)

+ Status output:

    **.** - processing heap block  
    **,** - processing matching object's top-level class  
    **;** - processing matching object's non-top-level class

**See Also:**  
hwalk, objwalk, lhwalk.

----------

### obj-foreach-class

**Usage:**  
`obj-foreach-class <function> <object> [<args>]`

**Examples:**  
`obj-foreach-class foo-callback ^lbx:si`  
calls foo-callback with each class in turn to which the object 
^lbx:si belongs.

**Synopsis:**  
Processes all the classes to which an object belongs, calling a callback 
procedure for each class symbol in turn.

**Notes:**

+ `<function>` is called with the symbol for the current class as its first 
argument, `<object>` as its second, and the arguments that follow `<object>` 
as its third and subsequent arguments. 

+ `<function>` should return an empty string to continue up the class tree. 

+ obj-foreach-class returns whatever `<function>` returned, if it halted 
processing before the root of the class tree was reached. It returns the 
empty string if `<function>` never returned a non-empty result.

**See Also:**  
obj-class.

----------

### objmessagebrk

**Usage:**  
`objmessagebrk [<address>]`

**Examples:**  
`objmessagebrk MyObj`  
break whenever a message is sent to MyObj

`objmessagebrk`  
stop intercepting messages

**Synopsis:**  
Break whenever a message is sent to a particular object via ObjMessage.

**Notes:**

+ The `<address>` argument is the address to an object to watch for 
messages being sent to it. If no argument is specified then the watching 
is stopped.

+ This breaks whenever a message is sent (before they get on the message 
queue. This enables one to track identical messages to an object which 
can be removed.

**See Also:**  
objwatch, mwatch, procmessagebrk, pobject.

----------

### objwalk

**Usage:**  
`objwalk [<address>]`

**Examples**:  
`objwalk`  

**Synopsis:**  
Prints out information about an object block.

**Notes:**  
The `<address>` argument is the address of the block to print. The default 
is the block pointed at by DS.

**See Also:**  
lhwalk, pobject

----------

### objwatch

**Usage:**  
`objwatch [<address>]`

**Examples:**  
`objwatch ds:si`  
watch the messages which reach the object at DS:SI

`objwatch MyObject`  
watch the messages which reach MyObject

`objwatch`  
Watch the messages which reach the process object.

**Synopsis:**  
Display message calls that have reached a particular object.

**Notes:**	

+ The `<address>` argument is the address of the object to watch.

+ This returns the token of the breakpoint being used to watch message 
deliveries to the object. Use the "brk" command to enable, disable, or turn 
off the watching of the object.

**See Also:**  
brk, mwatch, objmessagebrk, procmessagebrk, pobject.

----------

#### omfq

**Usage:**  
`omfq <message> <object> <args>*` 

**Examples:**  
`omfq MSG_META_QUIT *HelloApp"`  
Sends MSG\_META_QUIT to the *HelloApp object.

**Synopsis:**  
Forces a message for an object onto its event queue.

**Notes:**

+ This command calls ObjMessage, passing it 
di=mask MF\_FORCE_QUEUE. 

+ `<args>` is the set of additional parameters to pass to ObjMessage. It 
consists of `<variable/register>` `<value>` pairs, which are passed to the 
"assign" command. As a special case, if the variable is "push", the value 
(a word) is pushed onto the stack and is popped when the message has 
been queued. 

+ The registers active before you issued this command are always restored, 
regardless of whether the call to ObjMessage completes successfully. 
This is in contrast to the "call" command, which leaves you where the 
machine stopped with the previous state lost. 

**See Also:**  
call.

----------

### pappcache

**Usage:**  
`pappcache`

**Examples:**  
`pappcache`  
Print out current state of the app-cache

**Synopsis:**  
Prints out the current state of the system application cache, for systems 
operating in transparent launch mode.

**Notes:**  
Specifically, this command prints out:

+ Applications in the cache (First choice for detaching)

+ Top full-screen App (Not detached except by another full screen app)

+ Desk accessories (detached only as last resort)

+ Application geodes in the process of detaching

----------

### patch

**Usage:**  
`patch [<addr>]`  
`patch del <addr>*`

**Synopsis:**``
Patch assists in creating breakpoints that invisibly make small changes to 
code. This can help the programmer find several bugs without remaking and 
redownloading.

**Notes:**	

+ If you give no `<addr>` when creating a patch, the patch will be placed at 
the most-recently accessed address, as set by the command that 
most-recently accessed memory (e.g. bytes, words, listi, imem, etc.)

+ When creating a patch, you are prompted for its contents, each line of 
which comes from the following command set: (see Table 4-2)

----------

**Table 4-2 Patch Command Set**

	Form					Meaning					Example

	<reg> = <value>			assign value to reg		ax = bx		dl = 5
	push <reg>|<value>		push value				push ax		push 45
	pop <reg>|<value>		pop value				pop ax		pop 45
	pop						pop nothing (sp=sp+2)	pop
	jmp <address>			change ip				jmp UI_Attach+45
	scall <address> <regs>	call routine (save)		scall MemLock ax = 3
	mcall<address> <regs>	call routine (modify)	mcall MemLock ax = 3
	xchg <reg> <reg>		swap two registers		xchg ax bx
	set <flag>				set condition flag		set CF		set ZF
	reset <flag>			reset condition flag	reset CF	reset ZF
	if <flag>				if flag set then -	 	if CF
	if !<flag>				if flag reset then -	if !ZF
	if <expr>				if expr then -			if foo == 4
	else
	endif
	ret						make function return	ret
	$						terminate input
	a						abort
	<other>					tcl command				echo $foo
	<flag> is taken from the set TF, IF, DF, OF, SF, ZF, PF, AF, CF and must be in upper-case.

+ The "scall" command has no effect on the current registers (not even for purposes of return values), while the "mcall" command changes whatever registers the function called modifies. See the "call" documentation for the format of `<regs>`.

----------

### patchin

Patchin undoes the work of patchout.

----------

### patchout

This command causes a RET to be placed at the start of a routine.

----------

### patient

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### patient-default

**Usage:**  
`patient-default [<geode-name>]`

**Examples:**  
`patient-default hello2`  
Makes "hello2" the default patient.

`patient-default`  
Prints the names of the current default patient.

**Synopsis:**  
Specifies the default patient. The send and run commands will use this as 
the default patient to operate on if none is passed to them.

----------

### pbitmap

**Usage:**  
`pbitmap <address>`

**Synopsis:**  
Print a bitmap graphically.

**Notes:**

+ The address argument is the address of the Bitmap or CBitmap 
structure.

+ Color bitmaps are printed with a letter representing the color as well. 
The letters are index from the string (kbgcrvnAaBGCRVYW).

----------

### pbody

**Usage:**  
`pbody [<address>]`

**Examples:**  
`pbody`  
prints the GrObjBody given a GrObj block at DS.

`pbody ^hbx`  
Prints the GrObjBody given a GrObj block whose handle is BX.

**Synopsis:**  
Finds the GrObjBody-prints its OD and its instance data.

**Notes:**  
If no arguments are given, then DS is assumed to point to an object block 
containing GrObjects.

----------

### pcarray

**Usage:**  
`pcarray [-eth] [<address>]`

**Examples:**  
`pcarray`  
Print the chunk array at *DS:SI (header only)

`pcarray es:di`  
Print the chunk array at ES:DI (header only)

`pcarray -e`  
Print the chunk array at *DS:SI and print the elements in the 
array

`pcarray -tMyStruct`  
Print the chunk array at *DS:SI and print the elements where 
the elements are of type MyStruct

`pcarry -tMyStruct -TMyExtraStruct`  
Like above, but data after MyStruct is printed as an array of 
MyExtraStruct structures.

`pcarray -e3`  
Print the chunk array at *DS:SI and print the third element

`pcarray -hMyHeader`  
Print the chunk array at *DS:SI (header only) where the header 
is of type MyHeader

**Synopsis:**  
Print information about a chunk array.

**Notes:**

+ The flags argument can be any combination of the flags "e", "t", and "h". 
The "e" flag prints all elements. If followed by a number (e.g. "-e3"), then 
only the third element will be printed.

+ The `t' flag specifies the elements' type. It should be followed
 immediately by the element type. You can also use "-tgstring" if
 the elements are GString Elements.

+ The `h' flag specifies the header type. It should be followed immediately 
by the element type. 

+ The \`l' flag specifies how many elements to print. It can be used in 
conjunction with the `e' flag to print a range of element numbers. 

+ The `H' flag suppresses printing of the header. 

+ All flags are optional and may be combined.

+ The address argument is the address of the chunk array. If not specified 
then *ds:si is used.

----------

### pcbitmap

**Usage:**  
`pcbitmap <address> <width> <height> [<no space flag>]`

**Examples:**  
`pcbitmap *ds:si 64 64 t`  
print the bitmap without spaces

**Synopsis:**  
Print out a one-bit deep packbits-compacted bitmap.

**Notes:**

+ The `<address>` argument is the address to the bitmap data.

+ The `<width>` argument is the width of the bitmap in pixels.

+ The `<height>` argument is the height of the bitmap in pixels.

+ The `<no space flag>` argument removes the space normally printed 
between the pixels. Anything (like "t") will activate the flag.

**See Also:**  
pncbitmap.

----------

### pcelldata

**Usage:**  
`pcelldata [<addr>]`  

**Examples:**  
`pcelldata *es:di`  
Print cell data for cell at *es:di.

**Synopsis:**  
Prints data for a spreadsheet data.

**Notes:**  
If no address is given, *es:di is used.

**See Also:**  
content, pcelldeps.

----------

### pcelldeps

**Usage:**  
`pcelldeps <filehan> [<addr>]`

**Examples:**  
`pcelldeps 4be0h *es:di`  
 print dependencies of cell in file 4be0h.

**Synopsis:**  
Prints dependencies for a cell in the spreadsheet.

**Notes:**  
If no address is given, *es:di is used.

**See Also:**  
content, pcelldata.

----------

### pclass

**Usage:**  
`pclass [<address>]`

**Examples:**  
`pclass`  
prints the class of *DS:SI

`pclass ^l4ac0h:001eh`  
Print the class of the object at the given address.

**Synopsis:**  
Print the object's class.

**Notes:**  
The `<address>` argument is the address of the object to find the class of. 
This defaults to *DS:SI.

----------

### pdb

Produces useful information about a DBase block. For now, only information 
about the map block of the DBase file is produced. First arg H is the SIF\_FILE 
or SIG\_VM handle's ID. Second arg B is the VM block handle for which 
information is desired.

----------

### pdisk

**Usage:**  
`pdisk <disk-handle>`

**Examples:**  
`pdisk 00a2h`  
Prints information about the disk whose handle is 00a2h.

**Synopsis:**  
Prints out information about a registered disk, given its handle.

**Notes:**  
The Flags column is a string of single-character flags with the following 
meanings:

**w** - The disk is writable.  
**V** - The disk is always valid, i.e. it's not removable.  
**S** - The disk is stale. This is set if the drive for the disk has been deleted.  
**u** - The disk is unnamed, so the system has made up a name for it.

**See Also:**  
diskwalk, drivewalk.

----------

### pdrive

**Usage:**  
`pdrive <drive-handle>`  
`pdrive <drive-name>`  
`pdrive <drive-number>`

**Examples:**  
`pdrive si`  
Print a description of the drive whose handle is in SI

`pdrive al`  
Print a description of the drive whose number is in AL

`pdrive C`  
Print a description of drive C

**Synopsis:**  
Provides the same information as "drivewalk," but for a single drive, given 
the offset to its DriveStatusEntry structure in the FSInfoResource.

**Notes:**  
This is intended for use by implementors of IFS drivers, as no one else is 
likely to ever see a drive handle.

**See Also:**  
drivewalk.

----------

### penum

**Usage:**  
`penum <type> <value>`

**Examples:**  
`penum FatalErrors 0`  
print the first FatalErrors enumeration

**Synopsis:**  
Print an enumeration constant given a numerical value.

**Notes:**

+ The `<type>` argument is the type of the enumeration.

+ The `<value>` argument is the value of the enumeration in a numerical 
format.

**See Also:**  
print, precord.

----------

### pevent

**Usage:**  
`pevent <handle>`

**Examples:**  
`pevent 39a0h`  
Print event with handle.

**Synopsis:**  
Print an event given its handle.

**See Also:**  
elist, eqlist, eqfind, erfind.

----------

### pflags

**Usage:**  
`pflags`

**Synopsis:**  
Prints the current machine flags (carry, zero, etc.).

**See Also:**  
setcc, getcc.

----------

### pfont

**Usage:**  
`pfont [-c] [<address>]`

**Examples:**  
`pfont`  
print bitmaps of the characters of the font in BX.

`pfont -c ^h1fd0h`  
list the characters in the font at ^h1fd0h.

**Synopsis:**  
Print all the bitmaps of the characters in a font.

**Notes:**

+ The "-c" flag causes pfont to list which characters are in the font and any 
special status (i.e. NOT BUILT).

+ The `<address>` argument is the address of the font. If none is specified 
then ^hbx is used.

**See Also:**  
fonts, pusage, pfontinfo.

----------

### pfontinfo

**Usage:**  
`pfontinfo <font ID>`

**Examples:**  
`pfontinfo FID_BERKELEY`

**Synopsis:**  
Prints font header information for a font. Also lists all sizes built.

**Notes:**  
The `<font ID>` argument must be supplied. If not known, use `fonts -u' to 
list all the fonts with their IDs.

**See Also:**  
fonts, pfont.

----------

### pgen

**Usage:**  
`pgen <element> [<object>]`

**Examples:**  
`pgen GI_states @65`  
print the states of object 65

`pgen GI_visMoniker`  
print the moniker of the object at *DS:SI

`pgen GI_states -i`  
print the states of the object at the implied grab

**Synopsis:**  
Print an element of the generic instance data.

**Notes:**

+ The `<element>` argument specifies which element in the object to print

+ The `<object>` argument is the address to the object to print out. It 
defaults to *DS:SI and is optional. The `-i' flag for an implied grab may be 
used.

**See Also:**  
gentree, gup, pobject, piv, pvis.

----------

### pgs

**Usage:**  
`pgs <address>`

**Examples:**  
`pgs`  
List the graphics string at DS:SI

`pgs ^hdi`  
List the graphics string whose handle is in DI, starting at the 
current position.

`pgs -s ^hdi`  
List the graphics string whose handle is in DI, starting at the 
beginning of the graphics string.

`pgs -l3 ^hdi`  
List three elements of the graphics string whose handle is in 
DI, starting at the current position.

**Synopsis:**  
List the contents of a graphics string.

**Notes:**

+ The `<address>` argument is the address of a graphics string. If none is 
specified then DS:SI is used as a pointer to a graphics string.

+ The passed address may also be the base of a gstate (e.g. "^hdi"). In this 
case, the gstring that is associated with the gstate will be printed.

+ The -s option can be used to specify that the gstring should be listed from 
the beginning of the string. By default, gstrings will be listed starting at 
the current position.

+ The -g option can be used to specify that the passed address is the 
address of a GrObj (GStringClass) object - the gstring for that object will 
be listed.

**See Also:**  
pbitmap.

----------

### phandle

**Usage:**  
`phandle <handle ID>`

**Examples:**  
`phandle 1a8ch`  
print the handle 1a8ch

**Synopsis:**  
Print out a handle.

**Notes:**

+ The `<handle ID>` argument is just the handle number. Make sure that the 
proper radix is used.

+ The size is in paragraphs.

**See Also:**  
hwalk, lhwalk.

----------

### pharray

**Usage:**  
`pharray [<flags>] [<vmfile> <dirblk>]`

**Examples:**  
`pharray`  
Print the huge array at ^vbx:di (header only)

`pharray dx cx`  
Print the huge array at ^vdx:cx (header only)

`pharray -e`  
Print the huge array at ^vbx:di and print the elements in the 
array

`pharray -tMyStruct`  
Print the huge array at ^vbx:di and print the elements where 
the elements are of type MyStruct

`pharray -e3`  
Print the huge array at ^vbx:di and print the third element

`pharray -h`  
Print the header of the HugeArray at ^vbx:di, using the default 
header type (HugeArrayDirectory).

`pharray -hMyHeader`  
Print the huge array at ^vbx:di (header only) where the header 
is of type MyHeader

`pharray -d`  
Print the directory elements of a HugeArray

`pharray -e5 -l8`  
Print 8 HugeArray elements starting with number 5

**Synopsis:**  
Print information about a huge array.

**Notes:**

+ The flags argument can be any combination of the flags \`e', \`t', and `h'.  
+ The 
`e' flag prints all elements. If followed by a number "-e3", then only the 
third element is printed. 

+ The `t' flag specifies the elements' type. It should be followed immediately 
by the element type. You can also use "gstring", in which case the 
elements will be interpreted as GString Elements. 

+ The `h' flag specifies the header type. It should be followed immediately 
by the element type. If no options are specified, then 
"-hHugeArrayDirectory" is used. If any other options are specified, then 
the printing of the header is disabled. So, for example, if you want both 
the header and the third element, use "-h -e3". 

+ The `d' flag specifies that the HugeArray directory entries should be 
printed out. 

+ The `l' flag specified how many elements to print.

+ The `s' flag requests that a summary table be printed.

	All flags are optional and may be combined. 

+ The address arguments are the VM file handle and the VM block handle 
for the directory block. If nothing is specified, then bx:di is used

----------

### pini

**Usage:**  
`pini [<category>]`

**Examples:**  
`pini Lights Out`  
Print out the contents of the Lights Out category in each .ini 
file

`pini`  
Print out each currently loaded .ini file.

**Synopsis:**  
Provides you with the contents of the .ini files being used by the current 
GEOS session.

**Notes:**  
`<category>` may contain spaces and other such fun things. In fact, if you 
attempt to quote the argument (e.g. "pini {Lights Out}"), this will not find the 
category.

----------

### pinst

**Usage:**  
`pinst [<address>]`

**Examples:**  
`pinst`  
print the last master level of instance data of the object at 
*DS:SI

`pinst *MyObject`  
print the last master level of instance data of MyObject.

`pinst -i`  
print the last master level of the windowed object at the mouse 
pointer.

**Synopsis:**  
Print out all the instance data to the last level of the object.

**Notes:**

+ The `<address>` argument is the address of the object to examine. If not 
specified then pinst will use a default address. If you are debugging a C 
method, then the oself value will be used. Otherwise, *DS:SI is assumed 
to be an object.

+ This command is useful for classes you've created and you are not 
interested in the data in the master levels which pobject would display.

+ The following special values are accepted for `<address>`:

    **-a** - the current patient's application object  
    **-i** - the current "implied grab": the windowed object over which the
mouse is currently located.  
    **-f** - the leaf of the keyboard-focus hierarchy  
    **-t** - the leaf of the target hierarchy  
    **-m** - the leaf of the model hierarchy  
    **-c** - the content for the view over which the mouse is currently 
located  
    **-kg** - the leaf of the keyboard-grab hierarchy  
    **-mg** - the leaf of the mouse-grab hierarchy
+ pinst prints out the same information as "pobj l".

**See Also:**  
pobject, piv.

----------

### piv

**Usage:**  
`piv <master> <iv> [<address>]`

**Examples:**  
`piv Vis VCNI_viewHeight`  
print Vis.VCNI_viewHeight at *DS:SI

**Synopsis:**  
This prints out the value of the instance variable specified.

**Notes:**

+ The `<master>` argument expects the name of a master level. The name 
may be found using pobject to print the levels, and then using the name 
that appears after "master part:" and before the "_offset".

+ The `<iv>` argument expects the name of the instance variable to print.

+ The `<address>` argument is the address of the object to examine. If not 
specified then *DS:SI assumed to be an object.

+ This command is useful for when you know what instance variable you 
want to see but don't want to wade through a whole pobject command.

**See Also:**  
pobject, pinst.

----------

### plines

**Usage:**  
`plines <start> [<obj-address>]`

**Examples:**  
`plines 12`  
Print lines starting at line 12.

`plines 12 ^l6340h:0020h`  
Print lines starting at line 12 of object at given address.

**Synopsis:**  
Print information about the lines in a text object.

**Notes:**  
The printed line-starts are *not* correct.

**See Also:**  
ptext.

----------

### plist

Prints out a list of structures stored in an lmem chunk. It takes two 
arguments, the structure type that makes up the list, and the lmem handle 
of the chunk. e.g. plist FontsInUseEntry ds:di

----------

### pncbitmap

**Usage:**  
`pncbitmap <address> <width> <height> [<no space flag>]`

**Examples:**  
`pncbitmap *ds:si 64 64 t`  
print the bitmap without spaces

**Synopsis:**  
Print out a one-bitdeep noncompacted bitmap.

**Notes:**

+ The `<address>` argument is the address to the bitmap data.

+ The `<width>` argument is the width of the bitmap in pixels.

+ The `<height>` argument is the height of the bitmap in pixels.

+ The `<no space flag>` argument removes the space normally printed 
between the pixels. Anything (like `t') will activate the flag.

**See Also:**  
pcbitmap.

----------

### pnormal

**Usage:**  
`pnormal [-v]`

**Examples:**  
`pnormal -v`  
Print out verbose information about the current normal 
transfer item.

**Synopsis:**  
Prints out information about the current "normal" transfer item on the 
clipboard.

**Notes:**  
If you give the "-v" flag, this will print out the contents of the different 
transfer formats, rather than just an indication of their types. 

**See Also:**  
pquick, print-clipboard-item.

----------

### pobjarray

**Usage:**  
`pobjarray [<address>]`

**Examples:**  
`pobjarray`  
Print the array of ODs at *ds:si.

**Synopsis:**  
Print out an array of objects.

**See Also:**  
pbody.

----------

### pobject

**Usage:**  
`pobject [<address>] [<detail>]`

**Examples:**  
`pobj`  
print the object at *ds:si from Gen down if Gen is one of its 
master levels; else, print all levels

`pobj *MyGenObject`  
print MyGenObject from Gen down

`pobj Gen`  
print the Gen level for the object at *ds:si

`pobj last`  
print the last master level for the object at *ds:si

`pobj *MyObject`  
 all print all levels of MyObject

`pobj -i sketch`  
print the master level headings of the windowed object at the 
mouse pointer

`pobj *MyObject FI_foo`  
 print the FI_foo instance variable for MyObject

`pobj HINT_FOO`  
print the HINT_FOO variable data entry for the object at *ds:si

`pobj v`  
print the variable data for the object at *ds:si

**Synopsis:**  
Print all or part of an object's instance and variable data.

**Notes:**

+ The `<address>` argument is the address of the object to examine. If not 
specified then oself is used, unless the current function is written in 
assembly, in which case *DS:SI.

+ The following flag values are accepted in lieu of an address:

    **-a** - the current patient's application object  
    **-i** - the current "implied grab": the windowed object over which the 
mouse is currently located.  
    **-f** - the leaf of the keyboard-focus hierarchy  
    **-t** - the leaf of the target hierarchy  
    **-m** - the leaf of the model hierarchy  
    **-c** - the content for the view over which the mouse is currently 
located  
    **-kg** - the leaf of the keyboard-grab hierarchy  
    **-mg** - the leaf of the mouse-grab hierarchy

+ The *detail* argument specifies what information should be printed out 
about the object. If none is specified, all levels of the object from the Gen 
level down will be printed if Gen is one of the object's master levels; else, 
the whole object will be printed.

+ The following values are accepted for *detail*:

    **all (or a)** - all master levels  
    **last (or l)** - last master level only  
    **sketch (or s)** - master level headings only  
    **vardata (or v)** - vardata only  
    a master level name  
    an instance variable name  
    a variable data entry name

**See Also:**  
pinst, piv, pvardata.

----------

### pobjmon

**Usage:**  
`pobjmon [<address>] [<text only>]`

**Examples:**  
`pobjmon`  
print the VisMoniker from the gentree object at *DS:SI

**Notes:**

+ The `<address>` argument is the address of an object with a VisMoniker. 
If none is specified then *DS:SI is used.

+ The `<text only>` argument returns a shortened description of the 
structure. To set it use something other than `0' for the second argument.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

**See Also:**  
pvismon, pobject, vistree, gup, gentree, impliedgrab, systemobj.

----------

### pod

**Usage:**  
`pod <address>`

**Examples:**  
`pod ds:si`

**Synopsis:**  
Print in output descriptor format (^l<handle>:<chunk>) the address passed.

**Notes:**  
The address argument is the address of an object.

----------

### ppath

**Usage:**  
`ppath (current|docClip|winClip) [<gstate>]`

**Examples:**  
`ppath`  
print the current path of the GState in ^hdi

`ppath docClip ^hgstate`  
print the document clip path of the GState with handle gstate.

`ppath winClip ds`  
print the window clip path of the GState in the DS register.

**Synopsis:**  
Print the structure of a path.

**Notes:**  
Unique abbreviations for the path to be printed are allowed.

----------

### pquick

**Usage:**  
`pquick [-v]`

**Examples:**  
`pquick -v`  
Print out verbose information about the current quick transfer 
item.

**Synopsis:**  
Prints out information about the current "quick" transfer item on the 
clipboard.

**Notes:**  
If you give the "-v" flag, this will print out the contents of the different 
transfer formats, rather than just an indication of their types.

**See Also:**  
pnormal, print-clipboard-item.

----------

### precord

**Usage:**  
`precord <type> <value> [<silent>]`

**Examples:**  
`precord GSControl c0h`  
print the GSControl record with the top two bits set

**Synopsis:**  
Print a record using a certain value.

**Notes:**	

+ The `<type>` argument is the type of the record.

+ The `<value>` argument is the value of the record.

+ The `<silent>` argument will suppress the text indicating the record type 
and value. This is done by passing a non zero value like `1'. This is useful 
when precord is used by other functions.

**See Also:**  
print, penum.

----------

### preg

**Usage:**  
`preg [-g] <addr>`

**Examples:**  
`preg *es:W_appReg`  
Prints the application-defined clipping region for the window 
pointed to by es.

`preg -g ds:si`  
Prints a "graphical" representation of the region beginning at 
ds:si

**Synopsis:**  
Decodes a graphics GEOS region and prints it out, either numerically, or as a 
series of x's and spaces.

**Notes:**

+ This command can deal with parameterized regions. When printing a 
parameterized region with the -g flag, the region is printed as if it were 
unparameterized, with the offsets from the various PARAM constants 
used as the coordinates.

+ If no address is given, this will use the last-accessed address (as the 
"bytes" and "words" commands do). It sets the last-accessed address, for 
other commands to use, to the first byte after the region definition.

----------

### print

**Usage:**  
`print <expression>`

**Examples:**  
`print 56h`  
print the constant 56h in various formats

`print ax - 10`  
print ax less 10 decimal

`print ^l31a0h:001eh`  
print the absolute address of the pointer

**Synopsis:**  
Print the value of an expression.

**Notes:**

+ The `<expression>` argument is usually an address that has a type or that 
is given a type by casting and may span multiple arguments. The 
contents of memory of the given type at that address is what's printed. If 
the expression has no type, its offset part is printed in both hex and 
decimal. This is used for printing registers, for example.

+ The first argument may contain the following flags (which start with `-'):

    **x** - integers (bytes, words, dwords if dwordIsPtr false) printed in 
hex  
    **d** - integers printed in decimal  
    **o** - integers printed in octal c bytes printed as characters (byte 
arrays printed as strings, byte variables/fields printed as 
character followed by integer equivalent)  
    **C** - bytes treated as integers  
    **a** - align structure fields  
    **A** - Don't align structure fields  
    **p** - dwords are far pointers  
    **P** - dwords aren't far pointers  
    **r** - parse regions  
    **R** - don't try to parse regions

+ These flags operate on the following Tcl variables:

    **intFormat** - A printf format string for integers.  
    **bytesAsChar** - Treat bytes as characters if non-zero.  
    **alignFields** - Align structure fields if non-zero.  
    **dwordIsPtr** - DWords are far pointers if non-zero.  
    **noStructEnum** - If non-zero, doesn't print the "struct", "enum" or "record" before 
the name of a structured/enumerated type -- just gives the type 
name.  
    **printRegions** - If non-zero, prints what a Region points to (bounds and so on).  
    **condenseSpecial** - If non-zero, condense special structures (Rectangles, 
OutputDescriptors, ObjectDescriptors, TMatrixes and all 
fixed-point numbers) to one line.

+ This does not print enumerations. Use penum for that.

**See Also:**  
precord, penum, _print.

----------

### print-cell

**Usage:**  
`print-cell [row column <cfp ds:si>]`

**Examples:**  
`print-cell 1 1`  
print the cell <1,1>

`print-cell 1 2 *ds:si`  
print the cell <1,2> given *DS:SI

**Synopsis:**  
Print information about a cell

**See Also:**  
print-row, print-row-block, print-cell-params, print-column-element

----------

### print-cell-params

**Usage:**  
`print-cell-params [<address>]`

**Examples:**  
`print-cell-params`  
print the CellFunctionParameters at ds:si.

`print-cell-params ds:bx`  
print the CellFunctionParameters at ds:bx.

**Synopsis:**  
Print a CellFunctionParameters block.

**See Also:**  
print-row, print-column-element, print-row-block, print-cell.

----------

### print-clipboard-item

**Usage:**  
`print-clipboard-item [-v] <vmfile> <vmblock>`  
`print-clipboard-item [-v] <memhandle>`  
`print-clipboard-item [-v] <addr>`  

**Examples:**  
`print-clipboard-item bx`  
Print out info about the transfer item whose memory handle is 
in the BX register.

**Synopsis:**  
Prints out information about a transfer item.

**Notes:**

+ If you give the "-v" flag, this will print out the contents of the different 
transfer formats, rather than just an indication of their types. 

+ The -v flag will not work unless the transfer item is in a VM file.

**See Also:**  
pnormal, pquick.

----------

### print-column-element

**Usage:**  
`print-column-element [<address>]`

**Examples:**  
`print-column-element`  
Print the **ColumnArrayElement** at ds:si.

`print-column-element ds:bx`  
print the **ColumnArrayElement** at ds:bx 

**Synopsis:**  
Print a single **ColumnArrayElement** at a given address.

----------

### print-db-group

**Usage:**  
`print-db-group file group`

**Examples:**  
`print-db-group ax bx`  
print the group at bx/ax.

**Synopsis:**  
Print information about a dbase group block.

**See Also:**  
print-db-item.

----------

#### print-db-item

**Usage:**  
`print-db-item file group item`

**Examples:**  
`print-db-item bx ax di`  
print the item at bx/ax/di

**Synopsis:**  
Print information about a single dbase item

**See Also:**  
print-db-group

----------

### print-eval-dep-list

**Usage:**  
`print-eval-dep-list [<addr>]`

**Examples:**  
`print-eval-dep-list es:0`  
Print dependency list at ES:0.

**Synopsis:**  
Prints a dependency list used for evaluation.

**See Also:**  
content, pcelldeps.

----------

### printNamesInObjTrees

**Usage:**  
`var printNamesInObjTrees (0|1)`

**Examples:**  
`var printNamesInObjTrees 1`  
Sets "gentree," "vistree," etc. commands to print object names 
(where available).

**Synopsis:**  
Determines whether object names are printed (where available) rather than 
class names when using the following commands: vistree, gentree, focus, 
target, model, mouse, keyboard.

**Notes:**  
The default value for this variable is zero.

**See Also:**  
gentree, vistree, focus, target, model, mouse, keyboard.

----------

### print-obj-and-method

**Usage:**  
`print-obj-and-method <handle> <chunk> <message> [<cx> [<dx> [<bp> [<class>]]]]`

**Examples:**  
`print-obj-and-method [read-reg bx] [read-reg si]`  
Prints a description of the object ^lbx:si with the value stored 
and a hex representation.

`print-obj-and-method $h $c $m [read-reg cx] [read-reg dx] [read-reg bp]`  
Prints a description of the object ^l$h:$c and the name of the 
message whose number is in $c. This is followed by the three 
words of data in cx, dx, and bp.

**Synopsis:**  
Prints a nicely formatted representation of an object, with option message, 
register data, label, hex address, & carriage return. The class indication may 
also be overriden.

**Notes:**

+ You may specify anywhere from 0 to 5 arguments after the message 
number. These are interpreted as the value of the message, the registers 
CX, DX and BP, and the symbol token of the class to print, respectively. 

+ All arguments must be integers, as this is expected to be called by 
another procedure, not by the user, so the extra time required to call 
getvalue would normally be wasted. (The user should call pobj, gup, or 
other such functions for this sort of print out.)

**See Also:**  
mwatch, map-method, objwatch.

----------

### printRegions

**Usage:**  
`var printRegions [(0|1)]`

**Examples:**  
`var printRegions 1`  
If a structure contains a pointer to a region, "print" will 
attempt to determine its bounding box.

**Synopsis:**  
Controls whether "print" parses regions to find their bounding rectangle.

**Notes:**  
The default value for this variable is one.

**See Also:**  
print, condenseSpecial.

----------

### print-row

**Usage:**  
`print-row [<address *DS:SI>]`

**Examples:**  
`print-row`  
print the row at *DS:SI

`print-row ds:si`  
print the row at DS:SI

**Synopsis:**  
Print a single row in the cell file given a pointer to the row.

**See Also:**  
print-column-element, print-cell-params, print-row-block, print-cell

----------

### print-row-block

**Usage:**  
`print-row-block [<address ds>]`

**Examples:**  
`print-row-block`  
print the row-block at DS:0

`print-row-block es`  
print the row-block at ES:0 

**Synopsis:**  
Print a row-block.

**See Also:**  
print-row, print-cell-params, print-column-element, print-cell.

----------

### printStop

**Synopsis:**  
This variable controls how the current machine state is printed each time the 
machine comes to a complete stop. Possible values:

**asm** - Print the current assembly-language instruction, complete 
with the values for the instruction operands.  
**src** - Print the current source line, if it's available. If the source line 
is not available, the current assembly-language instruction is 
displayed as above.  
**why** - Print only the reason for the stopping, not the current machine 
state. "asm" and "src" modes also print this.  
**nil** - Don't print anything. 

----------

### proc

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### procmessagebrk

**Usage:**  
`procmessagebrk [<handle>]`

**Examples:**  
`procmessagebrk MyObj`  
break whenever a message is sent to MyObj

`procmessagebrk`  
stop intercepting messages

**Synopsis:**  
Break whenever a message is sent to a particular process via ObjMessage.

**Notes:**

+ The `<handle>` argument is the handle to a process to watch for messages 
being sent to it. If no argument is specified then the watching is stopped. 
The process' handle may be found by typing "ps -p". The process's handle 
is the number before the process's name.

+ This command breaks whenever a message is sent (before they get on the 
message queue. This enables one to track identical messages to a process 
which can be removed.

**See Also:**  
objwatch, mwatch, objmessagebrk, pobject.

----------

### protect

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### ps

**Usage:**  
`ps [<flags>]`

**Examples:**  
ps -t`  
list all threads in GEOS.

**Synopsis:**  
Print out GEOS' system status.

**Notes:**  
The flags argument may be one of the following:

**-t** - Prints out info on all threads. May be followed by a list of 
patients whose threads are to be displayed.

**-p** - Prints out info on all patients. May be followed by a list of 
patients to be displayed.

**-h** - Prints out info on all handles. May be followed by a list of 
patients whose handles are to be displayed.

The default is `-p'.

**See Also:**  
switch, sym-default.

----------

### pscope

**Usage:**  
`pscope [<scope-name> [<sym-class>]]`

**Examples:**  
`pscope WinOpen`  
Prints out all the local labels, variables, and arguments within 
the WinOpen() procedure

**Synopsis:**  
This prints out all the symbols contained in a particular scope.

**Notes:**

+ This can be useful when you want to know just the fields in a structure, 
and not the fields within those fields, or if you know the segment in which 
a variable lies, but not its name. Admittedly, this could be overkill.

+ *sym-class* can be a list of symbol classes to restrict the output. For 
example, "pscope Filemisc proc" will print out all the procedures within 
the Filemisc resource.

**See Also:**  
whatis, locals.

----------

### psize

**Usage:**  
`psize <structure>`

**Examples:**  
`psize FontsInUseEntry`

**Synopsis:**  
Print the size of the passed structure.

----------

### pssheet

**Usage:**  
`pssheet [-isSfrcvd] <address>`

**Examples:**  
`pssheet -s ^l3ce0h:001eh`  
print style attributes.

`pssheet -f -i 94e5h:0057h`  
print file info from instance data.

**Synopsis:**  
Prints out information about a spreadsheet object.

**Notes:**

+ If you are in the middle of debugging a spreadsheet routine and have a 
pointer to the Spreadsheet instance, the "-i" flag can be used to specify 
the object using that pointer. 

+ If you simply have the OD of the spreadsheet object, use that. 

+ Alternatively, you can do: `pssheet <flags> [targetobj]`

**See Also:**  
content, targetobj.

----------

### psup

**Usage:**  
`psup [<object>]`

**Examples:**  
`psup`  
print superclasses of object at *ds:si.

`psup -i`  
print superclasses of object under mouse.

`psup ^l4e10h:20h`  
print superclasses of object at ^l4e10h:20h.

**Synopsis:**  
Prints superclasses of an object.

**Notes:**  
If no object is specified, *ds:si is used.

**See Also:**  
is-obj-in-class.

----------

### ptext

**Usage:**  
`ptext [-lsrtcegR] <address>`

**Synopsis:**  
Prints out a text object

**Notes:**  
The flag may be one of the following:

**-c** - Print out the characters (the default).

**-e** - print out elements in addition to runs.

**-l** - print out line and field structures.

**-s** - print out char attr structures.

**-r** - print out para attr structures.

**-g** - print out graphics structures.

**-t** - print out type structures.

**-R** - print out region structures.

----------

### pthread

**Usage:**  
`pthread <id>`

**Examples:**  
`pthread 16c0h`  
Prints information about the thread whose handle is 16c0h.

**Synopsis:**  
Provides various useful pieces of information about a particular thread 
including its current priority and its current registers.

**Notes:**  
`<id>` is the thread's handle ID, as obtained with the "ps -t" or "threadstat" 
command.

**See Also:**  
os, threadstat.

----------

### ptimer

**Usage:**  
`ptimer <handle>`

**Examples:**  
`ptimer bx`  
Print out information about the timer whose handle is in the 
BX register.

**Synopsis:**  
Prints out information about a timer registered with the system: when it will 
fire, what it will do when it fires, etc.

**Notes:**  
`<handle>` may be a variable, register, or constant.

**See Also:**  
twalk, phandle.

----------

### ptrans

**Usage:**  
`ptrans [<flags>] [<address>]`

**Examples:**  
`ptrans`  
print the normal transform for the object at *ds:si.

`ptrans -s`  
print the sprite transform for the GrObj object at *ds:si. 

`ptrans ^lbx:cx`  
print the normal transform for the object whose OD is ^lbx:cx.

**Synopsis:**  
Prints the ObjectTransform data structure as specified.

**Notes:**

+ The -s flag can be used to print the "sprite" transform (the "sprite" is the 
shape's outline which is drawn to give feedback to the user when said 
user is moving/rotating/etc. the GrObj).

+ `<address>` defaults to *ds:si 

**See Also:**  
pobject.

----------

### ptreg

**Usage:**  
`ptreg <start> [<obj-addr>]`

**Examples:**  
`ptreg 12`  
Print lines for region 12

`ptreg 12 ^lcx:dx`  
Print lines for region 12 of object ^lcx:dx 

**Synopsis:**  
Print information about the lines in a region.

**See Also:**  
ptext.

----------

### pusage

**Usage:**  
`pusage [<address>]`

**Examples:**  
`pusage`  
print the usage of characters in the font

**Synopsis:**  
List the characters in a font and when they were last used.

**Notes:**  
The `<address>` argument is the address of a font. If none is given then 
^hbx is used.

**See Also:**  
fonts, pfont, pfontinfo, plist.

----------

### pvardata

**Usage:**  
`pvardata [<entry>]`

**Examples:**  
`pvardata ds:si`  
Prints vardata of object at *ds:si

`pvardata -i`  
Prints vardata of object with implied grab.

**Notes:**  
The address argument is the address of an object with variable data. The 
default is *ds:si.

----------

### pvardentry

**Usage:**  
`pvardentry <address> <object>`

**Examples:**  
`pvardentry ds:bx *ds:si`

**Notes:**

+ The address argument is the address of a variable data entry in an 
object's variable data storage area. The default is ds:bx. 

+ The `<object>` argument is required to determine the name of the tag for 
the entry, as well as the type of data stored with it.

----------

### pvis

**Usage:**  
`pvis <element> [<object>]`

**Examples:**  
`pvis VI_bounds @65`  
print the bounds of object 65

`pvis VI_optFlags`  
print the flags of the object at *DS:SI

`pvis VI_attrs -i`  
print the attributes of the object at the implied grab

**Synopsis:**  
Print an element of the visual instance data.

**Notes:**

+ The `<element>` argument specifies which element in the object to print

+ The `<object>` argument is the address to the object to print out. It 
defaults to *DS:SI and is optional. The `-i' flag for an implied grab may be 
used.

**See Also:**  
vistree, vup, pobject, piv, pgen.

----------

### pvismon

**Usage:**  
`pvismon [<address>] [<text only>]`

**Examples:**  
`pvismon`  
print the moniker at *DS:SI

`pvismon -i 1`  
print a short description of the implied grab object.

**Synopsis:**  
Print a visual moniker structure at an absolute address.

**Notes:**

+ The `<address>` argument is the address to an object in the visual tree. 
This defaults to *DS:SI. The `-i' flag for an implied grab may be used.

+ The `<text only>` argument returns a shortened description of the 
structure. Pass a non-zero value to turn on this flag.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

**See Also:**  
pobjmon, pobject, vistree, gup, gentree, impliedgrab, systemobj.

----------

### pvmb

**Synopsis:**  
Prints out the VMBlockHandle for a VM block given the file handle H and the 
VM block handle B.

----------

### pvmt

**Usage:**  
`pvmt [-p] [-a] [-s] [-c] (<handle> | <segment>)`

**Examples:**  
`pvmt bx`  
Print out all used blocks for the open VM file whose file handle 
is in BX.

`pvmt -as ds`  
Print out all blocks for the open VM file the segment of whose 
header block is in DS.

**Synopsis:**  
Prints out a map of the VM block handles for a VM file.

**Notes:**

+ The -p flag will only print out blocks that have the Preserve flag set. 
Useful for examining object blocks in GeoCalc files, for example. 

+ The -a flag causes pvmt to print out all block handles, not just those that 
have been allocated. The other two types of block handles are "assigned" 
(meaning they're available for use, but currently are tracking unused 
space in the file) and "unassigned" (they're available for use). 

+ The -s indicates the final argument is a segment, not a file handle. This 
is used only if you're inside the VM subsystem of the kernel. 

+ The -c flag requests a count of the different types of blocks at the end of 
the printout.

+ The blocks are printed in a table with the following columns:

    **han** - VM block handle (in hex)

    **flags** - D if the block is dirty,  
    C if the block is clean,  
    \- if the block is non-resident,  
    L if the block is LMem,  
    B if the block has a backup,  
    P if the preserve handle bit is set for the block,  
    ! if the block is locked

    **memhan** - Associated memory handle. Followed by "(d)" if the memory for 
the block was discarded but the handle retained. Followed by 
(s) if the memory has been swapped out.

    **block type** - The type of block:  
    VMBT\_USED a normal in-use block,  
    VMBT\_DUP an in-use block that has been backed up or allocated since 
the last call to VMSave()  
    VMBT\_BACKUP a place-holder to keep track of the previous version 
of a VMBT\_DUP block. The uid is the VM block handle to which 
the file space used to belong.  
    VMBT\_ZOMBIE a block that has been freed since the last VMSave(). 
The handle is preserved in case of a VMRevert() (a 
VMBT_BACKUP block retains the file space).

**uid** - The "used ID" bound to the block.

**size** - Number of bytes allocated for the block in the file.

**pos** - The position of those bytes in the file.

**See Also:**  
pgs.

----------

### pvsize

**Usage:**  
`pvsize [<object>]`

**Examples:**  
`pvsize`  
print the dimensions of the visual object at *ds:si.

**Synopsis:**  
Print out the dimensions of a visual object.

**Notes:**

+ The object argument is the address to the object to print out. It defaults 
to *ds:si and is optional. The `-i' flag for an implied grab may be used.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

----------

### pwd

**Usage:**  
`pwd`

**Examples:**  
`pwd`

**Synopsis:**  
Prints the current working directory for the current thread.

**See Also:**  
dirs, stdpaths.

----------

### quit

**Usage:**  
`quit [<options>]`

**Examples:**  
`quit cont`  
continue GEOS and quit swat

`quit det`  
detach from the PC and quit swat.

**Synopsis:**  
Stop the debugger and exit.

**Notes:**

+ The `<option>` argument may be one of the following:  
*continue*: continue GEOS and exit swat;  
*leave*: keep GEOS stopped and exit swat.

+ Anything else causes swat to detach and exit.

**See Also:**	detach.

----------

### range

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### read-char

**Usage:**  
`read-char [<echo>]`

**Examples:**  
`read-char 0`  
Read a single character from the user and don't echo it.

**Synopsis:**  
Reads a character from the user.

**Notes:**  
If `<echo>` is non-zero or absent, the character typed will be echoed.

**See Also:**  
read-line.

----------

### read-line

**Usage:**  
`read-line [<isTcl> [<initial input> [<special chars>]]]`

**Examples:**  
`read-line`  
reads a single line of text.

`read-line 1`  
reads a Tcl command.

`read-line 1 {go}`  
reads a Tcl command that starts with "go "

`read-line 1 {} {\e\4}`  
reads a Tcl command, considering escape and control-d cause 
for immediate return, regardless of whether braces and 
brackets are balanced

**Synopsis:**  
Reads a single line of input from the user. If optional argument is non-zero, 
the line is interpreted as a Tcl command and will not be returned until all 
braces/brackets are balanced. The final newline is stripped. Optional second 
argument is input to be placed in the buffer first. This input must also be 
on-screen following the prompt, else it will be lost.

**Notes:**

+ If `<isTcl>` is non-zero, the input may span multiple lines, as read-line will 
not return until all braces and brackets are properly balanced, according 
to the rules of Tcl. This behavior may be overridden by the `<special 
chars>` argument.

+ If `<initial input>` is given and non-empty, it is taken to be the initial 
contents of the input line and may be edited by the user just as if s/he had 
typed it in. The string is not automatically displayed; that is up to the 
caller.

+ `<special chars>` is an optional string of characters that will cause this 
routine to return immediately. The character that caused the immediate 
return is left as the last character of the string returned. You may use 
standard backslash escapes to specify the characters. This will return 
even if the user is entering a multi-line Tcl command whose braces and 
brackets are not yet balanced.

+ The user's input is returned as a single string with the final newline 
stripped off.

**See Also:**  
top-level-read

----------

### read-reg

**Usage:**  
`read-reg <register>`

Examples:**  
`read-reg ax`  
return the value of AX

`read-reg CC`  
return the value of the conditional flags

**Synopsis:**  
Return the value of a register in decimal.

**Notes:**``
The `<register>` argument is the two letter name of a register in either 
upper or lower case.

**See Also:**  
frame register, assign, setcc, clrcc.

----------

### regs

**Usage:**  
`regs`

**Synopsis:**  
Print the current registers, flags, and instruction.

**See Also:**  
assign, setcc, clrcc, read-reg.

----------

### regwin

**Usage:**  
`regwin [off]`

**Examples:**  
`regwin`  
`regwin off`

**Synopsis:**  
Turn the continuous display of registers on or off.

**Notes:**

+ If you give the optional argument "off", you will turn off any active 
register display.

+ If you give no argument, the display will be turned on.

+ Only one register display may be active at a time.

**See Also:**  
display.

----------

### repeatCommand

**Usage:**  
`var repeatCommand <string>`

**Examples:**  
`var repeatCommand [list foo nil]`  
Execute the command "foo nil" if the user just hits <Enter> at 
the next command prompt.

**Synopsis:**  
This variable holds the command Swat should execute if the user enters an 
empty command. It is used by all the memory-referencing commands to 
display the next chunk of memory, and can be used for other purposes as well.

**Notes:**

+ *repeatCommand* is emptied just before **top-level-read** returns the 
command the interpreter should execute and must be reset by the 
repeated command if it wishes to continue to be executed when the user 
just hits `<Enter>`. 

+ The text of the current command is stored in *lastCommand*, should you 
wish to use it when setting up *repeatCommand*. 

**See Also:**  
target, focus, mouse, keyboard.

----------

### require

**Usage:**  
`require <name> [<file>]`

**Examples:**  
`require fmtval print`  
Ensure the procedure "fmtval" is defined, loading the file 
"print.tcl" if it is not.

**Synopsis:**  
This ensures that a particular function, not normally invoked by the user but 
present in some file in the system library, is actually loaded.

**Notes:**  
If no `<file` is given, a file with the same name (possibly suffixed ".tcl") as the 
function is assumed.

**See Also:**  
autoload.

----------

### restore-state

**Usage:**  
`restore-state`

**Examples:**  
`restore-state`  
Set all registers for the current thread to the values saved by 
the most recent save-state.

**Synopsis:**  
Pops all the registers for a thread from the internal state stack.

**Notes:**

+ This is the companion to the "save-state" command.

+ All the thread's registers are affected by this command.

**See Also:**  
save-state.

----------

### ret

**Usage:**  
`ret [<function name>]`

**Examples:**  
`ret`  
`ret ObjMessage`

**Synopsis:**  
Return from a function and stop.

+ The `<function name>` argument is the name of a function in the patient's 
stack after which swat should stop. If none is specified then Swat returns 
from the current function.

+ The function returned from is the first frame from the top of the stack 
which calls the function (like the "finish" command).

+ This command does not force a return. The machine continues until it 
reaches the frame above the function.

**See Also:**  
finish, backtrace.

----------

### return

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### return-to-top-level

**Usage:**  
`return-to-top-level`

**Examples:**  
`return-to-top-level`  
Returns to the top-level interpreter.

**Synopsis:**  
Forces execution to return to the top-level interpreter loop, unwinding 
intermediate calls (protected commands still have their protected clauses 
executed, but nothing else is).

**See Also:**  
top-level, protect.

----------

### rs

**Usage:**  
`rs`

**Examples:**  
`rs`  
restart GEOS without attaching

**Synopsis:**  
Restart GEOS without attaching.

**See Also:**  
att, attach.

----------

### run

**Usage:**  
`run [<patient-name>]`

**Examples:**  
`run uki`  
Run the application with patient name "uki".

`run -e uki`  
run EC Uki

`run -n uki`  
run non-EC Uki

`run -p games\ukiec.geo`  
run games\ukiec.geo

`run`  
run the default patient, as specified by the patient-default 
command.

**Synopsis:**  
"Runs" an application by loading it via a call to **UserLoadApplication()** and 
stopping when the app reaches the GenProcess handler for 
MSG\_META_ATTACH. Return patient created, if any (In the examples shown, 
this would be "uki").

**Notes:**

+ May be used even if stopped inside the loader, in which case GEOS will be 
allowed to continue starting up,  and the specified app run after GEOS is 
Idle. 

+ If the machine stops for any other reason other than the call's completion, 
you are left wherever the machine stopped.

**See Also:**  
patient-default, send, spawn, switch.

----------

### rwatch

**Usage:**  
`rwatch [(on|off)]`

**Examples:**  
`rwatch on`  
Watch text-recalculation as it happens

`rwatch off`  
Turn output off

`rwatch`  
See what the status is

**Synopsis:**  
Displays information about text recalculation. Specifically designed for 
tracking bugs in the rippling code.

**See Also:**  
ptext.

----------

### save

**Usage:**  
`save (<#lines>|<filename>)`

**Examples:**  
`save 500`  
Save the last 500 lines that scroll off the screen.

`save /dumps/puffball`  
Save the contents of the entire scroll buffer to the file "puffball".

**Synopsis:**  
Controls the scrollback buffer Swat maintains for its main command window.

**Notes:**

+ If the argument is numeric, it sets the number of lines to save (the default 
is 1,000). 

+  If the argument is anything else, it's taken to be the name of a file in 
which the current buffer contents (including the command window) 
should be saved. If the `<filename>` is relative, it is taken relative to the 
directory in which the executable for the patient to which the current 
stack frame's function belongs is located. If the file already exists, it is 
overwritten.

----------

### save-state

**Usage:**  
`save-state`

**Examples:**  
`save-state`  
Push the current register state onto the thread's state stack.

**Synopsis:**  
Records the state of the current thread (all its registers) for later restoration 
by "restore-state".

**Notes:**

+ Swat maintains an internal state stack for each thread it knows, so 
calling this has no effect on the target PC. 

+ This won't save any memory contents, just the state of the thread's 
registers.

**See Also:**  
restore-state, discard-state.

----------

### sbwalk

**Usage:**  
`sbwalk [<patient>]`

**Examples:**  
`sbwalk`  
list the saved blocks of the current patient.

`sbwalk geos`  
list the saved blocks of the GEOS patient.

**Synopsis:**	List all the saved blocks in a patient.

**Notes:**  
The `<patient>` argument is any GEOS patient. If none is specified then 
the current patient is used.

----------

### scan

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### scope

**Usage:**  
`scope [<scope-name>]`

**Examples:**  
`scope`  
Returns the name of the current auxiliary scope.

**Synopsis:**  
This changes the auxiliary scope in which Swat looks first when trying to 
resolve a symbol name in an address expression.

**Notes:**

+ This command isn't usually typed by users, but it is the reason you can 
reference local labels after you've listed a function unrelated to the 
current one. 

+ You most likely want to use the set-address Tcl procedure, rather than 
this command. 

+ If `<scope-name>` is "..", the auxiliary scope will change to be the lexical 
parent of the current scope. 

**See Also:**  
set-address, addr-parse, whatis.

----------

### screenwin

**Usage:**  
`screenwin`

**Synopsis:**  
Print the address of the current top-most screen window.

----------

### send

**Usage:**  
`send [-enpr] <geode-name>`

**Examples:**  
`send icon`  
send EC Icon Editor if running in EC mode; send non-EC Icon 
Editor if running in non-EC mode.

`send -r icon`  
send appropriate icon editor, then run it. (See documentation 
for "run" above.)

`send -e icon`  
send EC Icon editor.

`send -n icon`  
send non-EC Icon Editor

`send -p c:/pcgeos/appl/icon/icon.geo`  
send c:/pcgeos/appl/icon/icon.geo

`send`  
send the default patient (as set by the patient-default 
command).

**Synopsis:**  
Send a geode from the host to target machine.

----------

### send-file

**Usage:**  
`send-file <file> <targfilename>`

**Examples:**  
`send-file /pcgeos/appl/sdk/mess1/mess1.geo WORLD/soundapp.geo`  
Send the mess1.geo file on the host machine to the WORLD 
directory of the host machine, where it will be called 
soundapp.geo.

**Synopsis:**  
Sends a file from the host machine to the target.

----------

### set-address

Set the last-accessed address recorded for memory-access commands. Single 
argument is an address expression to be used by the next memory-access 
command (except via `<return>`).

----------

### setcc

**Usage:**  
`setcc <flag> [<value>]`

**Examples:**  
setcc c`  
set the carry flag

`setcc z 0`  
clear the zero flag

**Synopsis:**  
Set a flag in the computer.

**Notes:**

+ The first argument is the first letter of the flag to set. The following is a 
list of the flags:

    **t** - trap  
    **i** - interrupt enable  
    **d** - direction  
    **o** - overflow  
    **s** - sign  
    **z** - zero  
    **a** - auxiliary carry  
    **p** - parity  
    **c** - carry

+ The second argument is the value to assign the flag. It defaults to one but 
may be zero to clear the flag.

**See Also:**  
clrcc, compcc.

----------

### set-masks

**Usage:**  
`set-masks <mask1> <mask2>`

**Examples:**  
`set-masks 0xff 0xff`  
Allow no hardware interrupts to be handled while the machine 
is stopped.

**Synopsis:**  
Sets the interrupt masks used while the Swat stub is active. Users should use 
the "int" command.

**Notes:**

+ `<mask1>` is the mask for the first interrupt controller, with a 1 bit 
indicating the interrupt should be held until the stub returns the 
machine to GEOS. `<mask2>` is the mask for the second interrupt 
controller. 

+ These masks are active only while the machine is executing in the stub, 
which usually means only while the machine is stopped.

**See Also:**  
int.

----------

### set-repeat

Sets the command to be repeated using a template string and the 
lastCommand variable. The variables $0-$n substitute the fields 0-n from 
the lastCommand variable. The final result is placed in repeatCommand 
which will be executed should the user type Enter.

----------

### set-startup-ec

**Usage:**  
`set-startup-ec [<args>]`

**Examples:**  
`set-startup-ec +vm`  
 turn on VM error checking when starting up

`set-startup-ec none`  
 turn off all ec code when starting up

**Synopsis:**  
Executes the "ec" command upon startup, to allow one to override the default 
error checking flags.

**See Also:**  
ec.

----------

### sftwalk

**Usage:**  
`sftwalk`

**Examples:**  
`sftwalk`

**Synopsis:**  
Print the SFT out by blocks.

**Notes:**  
This is different than sysfiles in that it shows less details of the files and 
instead shows where the SFT blocks are and what files are in them.

**See Also:**  
sysfiles, geosfiles, fwalk.

----------

### showcalls

**Usage:**  
`showcalls [<flags>] [<args>]`

**Examples:**  
`showcalls -o`  
show all calls using ObjMessage and ObjCall*

`showcalls -ml`  
show all calls changing global and local memory

`showcalls`  
stop showing any calls

**Synopsis:**  
Display calls to various parts of GEOS.

**Notes:**

+ The `<flags>` argument determines the types of calls displayed. Multiple 
flags must all be specified in the first argument such as `showcalls -vl`. If 
no flags are passed then showcalls stops watching. The flags may be any 
of the following:

    **-p** - Modify all other flags to work for the current patient only  
    **-b** - Monitors vis builds  
    **-s** - Monitors shutdown: MSG\_DETACH, DETACH\_COMPLETE, ACK, DETACH_ABORT  
    **-d** - Show dispatching of threads  
    **-e** - Show FOCUS, TARGET, MODAL, DEFAULT, etc. exclusive grabs 
& releases  
    **-g** - Show geometry manager resizing things (all sizes in hex)  
    **-l** - Show local memory create, destroy, relocate  
    **-m** - Show global memory alloc, free, realloc  
    **-o** - Show **ObjMessage()** and ObjCall-()  
    **-w** - Show **WinOpen(), WinClose(), WinMoveResize(), 
WinChangePriority()**.  
    **-N** - Show navigation calls (between fields, and between windows)

+ The`<args>` argument is used to pass values for some of options.

**See Also:**  
mwatch, objwatch.

----------

### showMethodNames

**Usage:**  
`var showMethodNames`

**Synopsis:**  
If this variable is non-zero, Swat prints out the names of the method in the 
AX register when unassembling a message call.

----------

###skip

**Usage:**  
`skip [<number of instructions>]`

**Examples:**  
`skip`  
skip the current instruction

`skip 6`  
skip the next six instructions

**Synopsis:**  
Skip one or more instructions.

**Notes:**  
The `<number of instructions>` argument defaults to one if not specified.

**See Also:**  
istep, sstep, patch.

----------

### sleep

**Usage:**  
`sleep <seconds>`

**Examples:**  
`sleep 5`  
Pauses Swat for 5 seconds.

**Synopsis:**``
This pauses Tcl execution for the given number of seconds, or until the user 
types Ctrl-C.

**Notes:**

+ Messages from the PC continue to be processed, so a FULLSTOP event will 
be dispatched if the PC stops, but this command won't return until the 
given length of time has elapsed. 

+ `<seconds>` is a real number, so "1.5" is a valid argument. 

+ Returns non-zero if it slept for the entire time, or 0 if the sleep was 
interrupted by the user.

----------

### slist

**Usage:**  
`slist [<args>]`

**Examples:**  
`slist`  
list the current point of execution

`slist foo.asm::15`  
list foo.asm at line 15

`slist foo.asm::15,45`  
list foo.asm from lines 15 to 45

**Synopsis:**  
List source file lines in swat.

**Notes:**

+ The args argument can be any of the following:

    `<address>` - Lists the 10 lines around the given address

    `<line>` - Lists the given line in the current file

    `<file>::<line>` - Lists the line in the given file

    `<line1>,<line2>` - Lists the lines between line1 and line2, inclusive, in the current file

    `<file>::<line1>,<line2>` - Lists the range from `<file>`

+ The default is to list the source lines around CS:IP.

**See Also:**  
listi, istep, regs.

----------

### smatch

**Synopsis:**  
Look for symbols of a given class by pattern. First argument `<pattern>` is the 
pattern for which to search (it's a standard Swat pattern using shell wildcard 
characters). Optional second argument `<class>` is the class of symbol for 
which to search and is given directly to the "symbol match" command. 
Defaults to "any".

----------

### source

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### sort

**Usage:**  
`sort [-r] [-n] [-u] <list>`

**Examples:**  
`sort -n $ids`  
Sorts the list in $ids into ascending numeric order.

**Synopsis:**  
This sorts a list into ascending or descending order, lexicographically or 
numerically.

**Notes:**

+ If "-r" is given, the sort will be in descending order. 

+ If "-u" is given, duplicate elements will be eliminated. 

+ If "-n" is given, the elements are taken to be numbers (with the usual 
radix specifiers possible) and are sorted accordingly. 

+ The sorted list is returned.

**See Also:**  
map, foreach, mapconcat.

----------

### spawn

**Usage:**  
`spawn <processName> [<addr>]`

**Synopsis:**  
Set a temporary breakpoint in a not-yet-existent process/thread, waiting for 
a new one to be created. First argument is the permanent name of the process 
to watch for. Second argument is an address expression specifying where to 
place the breakpoint. If no second argument is present, the machine will be 
stopped and Swat will return to the command level when the new thread is 
spawned by GEOS.

**Notes:**

+ This can also be used to catch the spawning of a new thread.

+ If the machine stops before the breakpoint can be set, you'll have to do 
this again.

----------

### src

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### srcwin

**Usage:**  
`srcwin <numLines>`

**Examples:**  
`srcwin 6`  
Show 6 lines of source context around CS:IP

`srcwin 0`  
Show no source lines, i.e. turn the display off.

**Synopsis:**  
Set the number of lines of source code to be displayed when the target 
machine stops.

Notes:  
Only one source display may be active at a time.

**See Also:**  
display, regwin, search.

----------

### sstep

**Usage:**  
`sstep [<default command>]`

**Examples:**  
`ss`  
enter source step mode

`sstep n`  
enter source step mode, `<ret>` does a next command

**Synopsis:**  
Step through the execution of the current patient by source lines. This is **THE** 
command for stepping through high-level (e.g., C) code.

+ The `<default>` command argument determines what pressing the 
`<Return>` key does. By default, `<Return>` executes a step command. Any 
other command listed below may be substituted by passing the letter of 
the command.

+ Sstep steps through the patient line by line, printing where the 
instruction pointer is and what line is to be executed Sstep waits for the 
user to type a command which it performs and then prints out again 
where sstep is executing.

+ This is a list of sstep commands:

    **q**, `<Esc>`," " - Stops sstep and returns to command level.  
    **b** - Toggles a breakpoint at the current location.  
    **c** - Stops sstep and continues execution.  
    **n** - Continues to the next source line, skipping procedure calls, 
repeated string instructions, and software interrupts. Only 
stops when the machine returns to the right context (i.e. the 
stack pointer and current thread are the same as they are when 
the "n" command was given).  
    **l** - Goes to the next library routine.  
    **N** - Like n, but stops whenever the breakpoint is hit, whether 
you're in the same frame or not.  
    **M** - Goes to the next message called. Doesn't work when the 
message is not handled anywhere.  
    **f** - Finishes out the current stack frame.  
    **s**, `<Ret>` - Steps one source line  
    **S** - Skips the current instruction  
    **J** - Jump on a conditional jump, even when "Will not jump" 
appears. This does not change the condition codes.  
    **g** - Executes the "go" command with the rest of the line as 
arguments.  
    **e** - Executes a Tcl command and returns to the prompt.  
    **R** - References either the function to be called or the function 
currently executing.  
    **h**, **?** - A help message.

+ Emacs will load in the correct file executing and following the lines where 
sstep is executing if its server is started and if ewatch is on in swat. If 
ewatch is off emacs will not be updated.

+ If the current patient isn't the actual current thread, sstep waits for the 
patient to wake up before single-stepping it.

**See Also:**  
istep, listi, ewatch.

----------

### stdpaths

**Usage:**  
`stdpaths`

**Examples:**  
`stdpaths`

**Synopsis:**  
Print out all paths set for standard directories

**See Also:**  
pwd, dirs.

----------

### step

**Usage:**  
`step`

**Examples:**  
`step`  
execute the next instruction

`s`

**Synopsis:**  
Execute the patient by a single machine instruction.

**Notes:**

+ If waitForPatient is non-zero, step waits for the machine to stop again.

+ This doesn't do any of the checks for special conditions (XchgTopStack, 
software interrupts, etc.) performed by the "s" command in istep.

**See Also:**  
istep, next.

----------

### step-patient

**Usage:**  
`step-patient`

**Examples:**  
`step-patient`  
Execute a single instruction on the target PC.

**Synopsis:**  
Causes the PC to execute a single instruction, returning only when the 
instruction has been executed.

**Notes:**

+ Unlike the continue-patient command, this command will not return 
until the machine has stopped again.

+ No other thread will be allowed to run, as timer interrupts will be turned 
off while the instruction is being executed.

**See Also:**  
help-fetch.

----------

#### step-until

**Usage:**  
`step-until expression [byte|word]`

**Examples:**  
`step-until ax=0`  
Single-step until ax is zero.

`step-until ds:20h!=0 byte`  
Single-step until byte at ds:20h is non-zero

`step-until ds:20h!=0 word`  
Single-step until word at ds:20h is non-zero

`step-until c=0`  
Single-step until the carry is clear

`step-until ax!=ax`  
Step forever

This command causes Swat to step until a condition is met.

**Notes:**  
Useful for tracking memory or register trashing bugs.

**See Also:**  
step-while 

----------

### stop

**Usage:**  
`stop in <class>::<message> [if <expr>]`  
`stop in <procedure> [if <expr>]`  
`stop in <address-history-token> [if <expr>]`  
`stop at [<file>:]<line> [if <expr>]`  
`stop <address> [if <expr>]`

**Examples:**  
`stop in main`  
`stop in @3`  
`stop at /staff/pcgeos/Loader/main.asm:36 if { joe_local ==22}`  
`stop at 25`  
`stop MemAlloc+3 if {ax==3}`

**Synopsis:**  
Specify a place and condition at which the machine should stop executing. 
This command is intended primarily for setting breakpoints when debugging 
a geode created in C or another high-level language, but may also be used 
when debugging assembly-language geodes.

**Notes:**

+ "stop in" will set a breakpoint at the beginning of a procedure, 
immediately after the procedure's stack frame has been set up.

+ "stop at" will set a breakpoint at the first instruction of the given source 
line. If no `<file>` is specified, the source file for the current stack frame is 
used.

+ If a condition is specified, by means of an `if <expr>` clause, you should 
enclose the expression in {}'s to prevent any nested commands, such as a 
"value fetch" command, from being evaluated until the break-point is hit.

+ For convenience, "stop in" also allows address-history tokens. This is 
useful when used in conjunction with the "methods" command.

**See Also:**  
brk, ibrk

----------

### stop-catch

**Usage:**  
`stop-catch <body>`

**Examples:**  
`stop-catch {go ProcCallModuleRoutine}`  
Let machine run until it reaches **ProcCallModuleRoutine()**, 
but do not issue a FULLSTOP event when it gets there.

**Synopsis:**  
Allows a string of commands to execute without a FULLSTOP event being 
generated while they execute.

**Notes:**  
Why is this useful? A number of things happen when a FULLSTOP event is 
dispatched, including notifying the user where the machine stopped. This is 
inappropriate in something like "istep" or "cycles" that is single-stepping the 
machine, for example.

**See Also:**  
event, continue-patient, step-patient.

----------

### stop-patient

**Usage:**  
`stop-patient`

**Examples:**  
`stop-patient`  
Stops the target PC.

**Synopsis:**  
Stops the target PC, in case you continued it and didn't wait for it to stop on 
its own.

**Notes:**  
This is different from the "stop" subcommand of the "patient" command.

**See Also:**  
continue-patient.

----------

### stream

**Usage:**  
`stream open <file> (r|w|a|r+|w+)`  
`stream read (line|list|char) <stream>`  
`stream print <list> <stream>`  
`stream write <string> <stream>`  
`stream rewind <stream>`  
`stream seek (<posn>|+<incr>|-<decr>|end) <stream>`  
`stream state <stream>`  
`stream eof <stream>`  
`stream close <stream>`  
`stream flush <stream>`  
`stream watch <stream> <what> <procName>`  
`stream ignore <stream>`

**Examples:**  
`var s [stream open kmap.def w]`  
Open the file "kmap.def" for writing, creating it if it wasn't 
there before, and truncating any existing file.

`stream write $line $s`  
Write the string in $line to the open stream.

**Synopsis:**  
This allows you to read, write, create, and otherwise manipulate files on the 
host machine from Swat.

**Notes:**

+ Subcommands may be abbreviated uniquely. 

+ Streams are a precious resource, so you should be sure to always close 
them when you are done. This means stream access should usually be 
performed under the wings of a "protect" command so the stream gets 
closed even if the user types Ctrl+C. 

+ Swat's current directory changes as you change stack frames, with the 
directory always being the one that holds the executable file for the 
patient to which the function in the current frame belongs. If the `<file>` 
given to "stream open" isn't absolute, it will be affected by this. 

+ The global variable file-init-dir contains the absolute path of the 
directory in which Swat was started. It can be quite useful when forming 
the `<file>` argument to "stream open".

+ The second argument to "stream open" is the access mode of the file. The 
meanings of the 5 possible values are:

    **r** - read-only access. The `<file>` must already exist.  
    **w** - write-only access. If `<file>` doesn't already exist, it will be 
created. If it does exist, it will be truncated.  
    **a** - append mode. The file is opened for writing only. If `<file>` 
doesn't already exist, it will be created. If it does exist, writing 
will commence at its end.  
    **r+** - read/write. The `<file>` must already exist. A single read/write 
position is maintained, and it starts out at the start of the file.  
    **w+** - read/write. If `<file>` doesn't already exist, it will be created. If it 
does exist, it will be truncated. A single read/write position is 
maintained, and it starts out at the start of the file.

+ "stream read" can read data from the stream in one of three formats:

    **line** - Returns all the characters from the current position up to the 
first newline or the end of the file, whichever comes first. The 
newline, if seen, is placed at the end of the string as \n. Any 
other non-printable characters or backslashes are similarly 
escaped.  
    **list** - Reads a single list from the stream, following all the usual 
rules of Tcl list construction. If the character at the current 
read position is a left brace, this will read to the matching right 
brace, bringing in newlines and other whitespace. If there is 
whitespace at the initial read position, it is skipped. Standard 
Tcl comments before the start of the list are also skipped over 
(so if the first non-whitespace character encountered is #, the 
characters up to the following newline or end-of-file will also be 
skipped).  
    **char** - This reads a single character from the stream. If the character 
isn't printable ASCII, it will be returned as one of the regular 
Tcl backslash escapes.

If there's nothing left to read, you will get an empty string back.

+ "stream write" writes the string exactly as given, without interpreting 
backslash escapes. If you want to include a newline or something of the 
sort in the string, you'll need to use the "format" command to generate 
the string, or place the whole thing in braces and have the newlines in 
there literally. 

+ While the syntax for "stream print" is the same as for "stream write", 
there is a subtle difference between the two. "stream write" will write the 
string as it's given, while "stream print" is intended to write out data to 
be read back in by "stream read list". Thus the command  
`stream write {foo biff} $s`  
would write the string "foo biff" to the stream. In contrast,  
`stream print {foo biff} $s`  
would write "{foo biff}" followed by a newline.

+ To ensure that all data you have written has made it to disk, use the 
"stream flush" command. Nothing is returned. 

+ "stream rewind" repositions the read/write position at the start of the 
stream. "stream seek" gives you finer control over the position. You can 
set the stream to an absolute position (obtained from a previous call to 
"stream seek") by passing the byte number as a decimal number. You can 
also move forward or backward in the file a relative amount by specifying 
the number of bytes to move, preceded by a "+", for forward, or a "-", for 
backward. Finally, you can position the pointer at the end of the file by 
specifying a position of "end". 

+ "stream seek" returns the new read/write position, so a call of "stream 
seek +0 $s" will get you the current position without changing anything. 
If the seek couldn't be performed, -1 is returned. 

+ "stream state" returns one of three strings: "error", if there's been some 
error accessing the file, "eof" if the read/write position is at the end of the 
file, or "ok" if everything's fine. "stream eof" is a shortcut for figuring if 
you've reached the end of the file. 

+ "stream close" shuts down the stream. The stream token should never be 
used again. 

+ "stream watch" and "stream ignore" are valid only on UNIX and only 
make sense if the stream is open to a device or a socket. "stream watch" 
causes the procedure `<procName>` to be called whenever the stream is 
ready for the access indicated by `<what>`, which is a list of conditions 
chosen from the following set:  
**read** - the stream has data that may be read.  
**write** - the stream has room for data to be written to it.  
When the stream is ready, the procedure is called:  
`<procName> <stream> <what>`  
where `<what>` is the list of operations for which the stream is ready.

**See Also:**  
protect, source, file.

----------

### string

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### switch

**Usage:**  
`switch <thread-id>`  
`switch [<patient>] [:<thread-num>]`

**Examples:**  
`switch 3730h`  
Switches swat's current thread to be the one whose handle ID 
is 3730h.

`switch :1`  
Switches Swat's current thread to be thread number 1 for the 
current patient.

`switch parallel:2`  
Switches Swat's current thread to be thread number 2 for the 
patient "parallel"

`switch write`  
Switches Swat's current thread to be thread number 0 (the 
process thread) for the patient "write"

`switch`  
Switches Swat's current thread to be the current thread on the 
PC.

**Synopsis:**  
Switches between applications/threads.

**Notes:**

+ Takes a single argument of the form `<patient>:<thread-num>` or 
`<threadID>`. With the first form, `:<thread-num>` is optional -- if the 
patient has threads, the first thread is selected. To switch to another 
thread of the same patient, give just `:<thread-num>`. You can also switch 
to a patient/thread by specifying the thread handle ID. NOTE: The switch 
doesn't happen on the PC-just inside swat.

+ If you don't give an argument, it switches to the actual current thread in 
the PC.

----------

### symbol

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### symbolCompletion

**Usage:**  
`var symbolCompletion [(0|1)]`

**Examples:**  
`var symbolCompletion 1`  
Enable symbol completion in the top-level command reader.

**Synopsis:**  
This variable controls whether you can ask Swat to complete a symbol for you 
while you're typing a command. Completion is currently very slow and 
resource-intensive, so you probably don't want to enable it.

**Notes:**

+ Even when symbolCompletion is 0, file-name, variable-name, and 
command- name completion are always enabled, using the keys 
described below. 

+ When completion is enabled, three keys cause the interpreter to take the 
text immediately before the cursor and look for all symbols that begin 
with those characters. The keys are:

    **Ctrl+D** - Produces a list of all possible matches to the prefix.

    **Escape** - Completes the command as best possible. If the characters 
typed so far could be the prefix for more than one command, 
Swat will fill in as many characters as possible.

    **Ctrl+]** - Cycles through the list of possible symbols, in alphabetical 
order.

**See Also:**  
top-level-read.

----------

### sym-default

**Usage:**  
`sym-default [<name>]`

**Examples:**  
`sym-default motif`  
Make swat look for any unknown symbols in the patient named 
"motif" once all other usual places have been searched.

**Synopsis:**  
Specifies an additional place to search for symbols when all the usual places 
have been searched to no avail.

**Notes:**

+ The named patient need not have been loaded yet when you execute this 
command.

+ A typical use of this is to make whatever program you're working on be 
the sym-default in your .swat file so you don't need to worry about 
whether it's the current one, or reachable from the current one, when the 
machine stops and you want to examine the patient's state.

+ If you don't give a name, you'll be returned the name of the current 
sym-default.

----------

### sysfiles

**Usage:**  
`sysfiles`

**Examples:**  
`sysfiles`

**Synopsis:**  
Print out all open files from DOS's system file table.

**Notes:**  
Normally SFT entries that aren't in-use aren't printed. If you give the 
optional argument "all", however, all SFT entries, including those that aren't 
in-use, will be printed.

**See Also:**  
geosfiles, sftwalk, fwalk.

----------

### systemobj

**Usage:**  
`systemobj`

**Examples:**
`gentree [systemobj]`  
print the generic tree starting at the system's root

`pobject [systemobj]`  
print the system object

**Synopsis:**  
Prints out the address of the uiSystemObj, which is the top level of the 
generic tree.

**Notes:**  
This command is normally used with gentree as shown above to print out 
the whole generic tree starting from the top.

**See Also:**  
gentree, impliedgrab.

----------

### table

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### target

**Usage:**  
`target [<object>]`

**Examples:**  
`target`  
print target hierarchy from the system object down

`target -i`  
print target hierarchy from implied grab down

`target ^l4e10h:20h`  
print target hierarchy from ^l4e10h:20h down

`target [content]`  
print target hierarchy from content under mouse.

**Synopsis:**  
Prints the target hierarchy below an object.

**Notes:**

+ If no argument is specified, the system object is used. 

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ Remember that the object you start from may have the target within its 
part of the hierarchy, but still not have the target because something in 
a different part of the tree has it. 

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. 

    This variable defaults to false. 

**See Also:**  
focus, model, mouse, keyboard, pobject.

----------

### targetobj

**Usage:**  
`targetobj`

**Examples:**  
`targetobj`  
return object with target

`pobj [targetobj]`  
do a pobject on the target object (equivalent to "pobj -t").

**Synopsis:**  
Returns the object with the target.

**See Also:**  
target, focus, focusobj, modelobj.

----------

### tbrk

**Usage:**  
`tbrk <addr> <condition>*`  
`tbrk del <tbrk>+`  
`tbrk list`  
`tbrk cond <tbrk> <condition>*`  
`tbrk count <tbrk>`  
`tbrk reset <tbrk>`  
`tbrk address <tbrk>`

**Examples:**  
`tbrk ObjCallMethodTable`  
Count the number of times ObjCallMethodTable() is called.

`tbrk count 2`  
Find the number of times tally breakpoint number 2 was hit.

`tbrk reset 2`  
Reset the counter for tbrk number 2 to 0.

`tbrk list`  
Print a list of the set tally breakpoints and their current counts.

**Synopsis:**  
This command manipulates breakpoints that tally the number of times they 
are hit without stopping execution of the machine-the breakpoint is noted 
and the machine is immediately continued. Such a breakpoint allows for 
real-time performance analysis, which is nice.

**Notes:**

+ If you specify one or more `<condition>` arguments when setting the tally 
breakpoint, only those stops that meet the conditions will be counted. 

+ The *condition* argument is exactly as defined by the "brk" command, q.v..

+ When you've set a tally breakpoint, you will be returned a token of the 
form `tbrk<n>`, where `<n>` is some number. You use this token, or just 
the `<n>`, if you're not a program, wherever `<tbrk>` appears in the Usage 
description, above. 

+  There are a limited number of tally breakpoints supported by the stub. 
You'll know when you've set too many.

+ "tbrk address" returns the address at which the tbrk was set, as a 
symbolic address expression.

**See Also:**  
brk, cbrk.

----------

### tcl-debug

**Usage:**  
`tcl-debug top`  
`tcl-debug next <tcl-frame>`  
`tcl-debug prev <tcl-frame>`  
`tcl-debug args <tcl-frame>`  
`tcl-debug getf <tcl-frame>`  
`tcl-debug setf <tcl-frame> <flags>`  
`tcl-debug eval <tcl-frame> <expr>`  
`tcl-debug complete <tcl-frame>`  
`tcl-debug next-call`

**Examples:**  
`var f [tcl-debug top]`  
Sets $f to be the frame at which the debugger was entered.

`var f [tcl-debug next $f]`  
Retrieves the next frame down (away from the top) the Tcl call 
stack from $f.

**Synopsis:**  
This provides access to the internals of the Tcl interpreter for the Tcl 
debugger (which is written in Tcl, not C). It will not function except after the 
debugger has been entered.

**See Also:**  
debug.

----------

### text-fixup

**Usage:**

**1** - Run geos under swat, run swat on the development system  
**2** - Run GeoWrite  
**3** - Open the GeoWrite file that needs fixing  
**4** - Set the breakpoint in swat:  
 `patch text::CalculateRegions => text-fixup`  
This will set a breakpoint at the right spot  
**5** - Turn on the error-checking code in swat:  
`ec +text`  
**6** - Enter a `<space>` into the document. This forces recalculation which will 
cause **CalculateRegions()** to be called which will cause text-fixup to be 
called.  
If it worked, this code should patch together the file. If it's not, you'll get a 
FatalError right now.  
**7** - Turn off the ec code and disable the fixup breakpoint.  
`ec none`  
`dis <breakpoint number>`  
`continue`  
**8** - Delete the space and save the file. 

To do another file, you can just enable the breakpoint once the new file is open 
and turn on the ec code.

**Synopsis:**  
Helps fix up trashed GeoWrite documents.

----------

### thaw

**Usage:**  
`thaw [<patient>]`  
`thaw :<n>`  
`thaw <patient>:<n>`  
`thaw <id>`

**Examples:**  
`thaw`  
Thaw the current thread.

`thaw term`  
Allows the application thread for "term" to run normally

`thaw :1`  
Allows thread #1 of the current patient to run normally 

`thaw 16c0h`  
Allows the thread whose handle is 16c0h to run normally.

**Synopsis:**  
Thawing a thread restores its priority to what it was before the thread was 
frozen.

**See Also:**  
freeze.

----------

### thread

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### threadname

**Usage:**  
`threadname <id>`

**Examples:**  
`threadname 21c0h`  
Returns the name of the thread whose handle id is 21c0h.

**Synopsis:**  
Given a thread handle, produces the name of the thread, in the form 
`<patient>:<n>`

**Notes:**  
If the handle is not one of those swat knows to be for a thread, this returns 
the string "unknown."

**See Also:**  
thread, patient.

----------

### threadstat

**Usage:**  
`threadstat`

**Examples:**  
`threadstat`  

**Synopsis:**  
Provides information about all threads and various thread queues and 
synchronization points in the system.

**See Also:**  
ps.

----------

### timebrk

**Usage:**  
`timebrk <start-addr> <end-addr>+`  
`timebrk del <timebrk>+`  
`timebrk list`  
`timebrk time <timebrk>`  
`timebrk reset <timebrk>`

**Examples:**  
`timebrk LoadResourceData -f`  
Calculate the time required to process a call to 
**LoadResourceData()**.

`timebrk time 2`  
Find the amount of time accumulated for timing breakpoint 
number 2.

`timebrk reset 2`  
Reset the counter for timebrk number two to zero.

`timebrk list`  
Print a list of the set timing breakpoints and their current 
counts and time. 

**Synopsis:**  
This command manipulates breakpoints that calculate the amount of time 
executing between their starting point and a specified ending point. The 
breakpoints also record the number of times their start is hit, so you can 
figure the average amount of time per hit.

**Notes:**

+ You can specify a place at which timing should end either as an address 
or as "-f". If you use "-f", timing will continue until the finish of the 
routine at whose start you've placed the breakpoint. Such a breakpoint 
may only be set at the start of a routine, as the stub hasn't the 
wherewithal to determine what the return address is at an arbitrary 
point within the function. 

+ You may specify more than one ending point. Timing will stop when 
execution reaches any of those points. 

+ When you've set a timing breakpoint, you will be returned a token of the 
form `timebrk<n>`, where `<n>` is some number. You use this token, or 
just the `<n>`, if you're not a program, wherever `<timebrk>` appears in the 
Usage description, above. 

**See Also:**  
brk, cbrk, tbrk.

----------

### timingProcessor

**Usage:**  
`var timingProcessor [i86|i88|i286|V20]`

**Synopsis:**  
The processor for which to generate cycle counts.

----------

### tmem

**Usage:**  
`tmem`

**Examples:**  
`tmem`  
turn on memory tracing.

**Synopsis:**  
Trace memory usage.

**Notes:**  
The tmem command catches calls to DebugMemory, printing out the 
parameters passed (move, free, realloc, discard, swapout, swapin, modify).

----------

### top-level

**Usage:**  
`top-level`

**Examples:**  
`top-level`  
Begin reading and interpreting Tcl commands in a nested 
interpreter.

**Synopsis:**  
This is the top-most read-eval-print loop of the Swat Tcl interpreter.

**Notes:**  
This command will only return if the user issues the "break" command. 
Otherwise it loops infinitely, reading and executing and printing the results 
of Tcl commands. 

**See Also:**  
top-level-read.

----------

### tundocalls

**Usage:**  
`tundocalls [-acPCrR]`

**Examples:**  
`tundocalls -a`  
Print out all text undo calls

`tundocalls -r`  
Print run undo calls

`tundocalls -R`  
Print replace undo calls

`tundocalls -c`  
Print info when undo information is created

`tundocalls -cP`  
Print info about para attributes only

`tundocalls -cC`  
Print info about char attributes only

`tundocalls`

**Synopsis:**  
Prints out information about each undo call made to the text object.

**See Also:**  
ptext, showcalls.

----------

### twalk

**Usage:**  
`twalk`

**Examples:**  
`twalk`  
print all the timers in the system.

`twalk -o ui`  
print all the timers in the system for the ui thread.

`twalk -a`  
print all the timers with the "real" data for the time for time 
remaining rather than maintaining a total.

**Synopsis:**  
List all the timers in GEOS.

----------

### type

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### unalias

**Usage:**  
`unalias <name>+`

**Examples:**  
`unalias p`  
Removes "p" as an alias for print.

**Synopsis:**  
This removes an alias.

**Notes:**  
In fact, this actually can be used to delete any command at all, including 
Tcl procedures and Swat built-in commands. Once they're gone, however, 
there's no way to get them back.

**See Also:**  
alias.

----------

### unassemble

**Usage:**  
`unassemble [<addr> [<decode-args>]]`

**Examples:**  
`unassemble cs:ip 1`  
Disassemble the instruction at CS:IP and return a string that 
shows the values of the arguments involved.

**Synopsis:**  
This decodes data as machine instructions and returns them to you for you 
to display as you like. It is not usually typed from the command line.

**Notes:**

+ The return value is always a four-element list:  
`{<symbolic-addr> <instruction> <size> <args>}`  
where `<symbolic-addr>` is the address expressed as an offset from some 
named symbol, `<instruction>` is the decoded instruction (without any 
leading whitespace), `<size>` is the size of the instruction (in bytes) and 
`<args>` is a string displaying the values of the instruction operands, if 
`<decode-args>` was given and non-zero (it is the empty string if 
`<decode-args>` is missing or 0). 

+ If `<addr>` is missing or "nil", the instruction at the current frame's CS:IP 
is returned.

**See Also:**  
listi.

----------

### unbind-key

**Usage:**  
`unbind-key <ascii_value>`

**Examples:**  
`unbind-key \321`  
Unbinds scroll-down key on host machine.

**Synopsis:**  
Unbinds the passed ASCII value.

**See Also:**  
alias, bind-key, get-key-binding.

----------

### undebug

**Usage:**  
`undebug <proc-name>+`

**Examples:**  
`undebug fooproc`  
Cease halting execution each time "fooproc" is executing.

**Synopsis:**  
Removes a Tcl breakpoint set by a previous "debug" command.

**See Also:**  
debug.

----------

### up

**Usage:**  
`up [<frame offset>]`

**Examples:**  
`up`  
move the frame one frame up the stack

`up 4`  
move the frame four frames up the stack

**Synopsis:**  
Move the frame up the stack.

**Notes:**

+ The `<frame offset>` argument is the number of frame to move up the 
stack. If none is specified then the current frame is moved up one frame.

+ This command may be repeated by pressing <Return>.

**See Also:**  
backtrace, down.

----------

### value

**Usage:**  
`value fetch <addr> [<type>]`  
`value store <addr> <value> [<type>]`  
`value hfetch <num>`  
`value hstore <addr-list>`  
`value hset <number-saved>`

**Examples:**  
`value fetch ds:si [type word]`  
Fetch a word from ds:si

`value store ds:si 0 [type word]`  
Store 0 to the word at ds:si

`value hfetch 36`  
Fetch the 36th address list stored in the value history.

`value hstore $a`  
Store the address list in $a into the value history.

`value hset 50`  
Keep track of up to 50 address lists in the value history. 

**Synopsis:**  
This command allows you to fetch and alter values in the target PC. It is also 
the maintainer of the value history, which you normally access via 
`@<number>` terms in address expressions.

**Notes:**

+ "value fetch" returns a value list that contains the data at the given 
address. If the address has an implied data type (it involves a named 
variable or a structure field), then you do not need to give the `<type>` 
argument. 

	All integers and enumerated types are returned in decimal. 32-bit 
pointers are returned as a single decimal integer whose high 16 bits are 
the high 16 bits (segment or handle) of the pointer. 16-bit pointers are 
likewise returned as a single decimal integer. 

	Characters are returned as characters, with non-printable characters 
converted to the appropriate backslash escapes (for example, newline is 
returned as \n). 

	Arrays are returned as a list of value lists, one element per element of the 
array. 

	Structures, unions and records are returned as a list of elements, each of 
which is a 3-element list: `{<field-name> <type> <value>}` `<field-name>` is 
the name of the field, `<type>` is the type token for the type of data stored 
in the field, and `<value>` is the value list for the data in the field, 
appropriate to its data type. 

+ You will note that the description of value lists is recursive. For example, 
if a structure has a field that is an array, the `<value>` element in the list 
that describes that particular field will be itself a list whose elements are 
the elements of the array. If that array were an array of structures, each 
element of that list would again be a list of `{<field-name> <type> 
<value>}` lists. 

+ The "field" command is very useful when you want to extract the value 
for a structure field from a value list.

+ As for "value fetch", you do not need to give the `<type>` argument to
"value store" if the `<addr>` has an implied data type. The `<value>` 
argument is a value list appropriate to the type of data being stored, as 
described above. 

+ "value hstore" returns the number assigned to the stored address list. 
These numbers always increase, starting from 1. 

+ If no address list is stored for a given number, "value hfetch" will 
generate an error. 

+ "value hset" controls the maximum number of address lists the value 
history will hold. The value history is a FIFO queue; if it holds 50 entries, 
and the 51st entry is added to it, the 1st entry will be thrown out.

**See Also:**  
addr-parse, assign, field.

----------

### var

This is a Tcl primitive. See "Tool Command Language," Chapter 5.

----------

### varwin

**Usage:**  
`varwin <num-lines> <var-name>`

----------

### view

**Usage:**  
`view [<args>]`

**Examples:**  
`view foo.goc`  
Bring up foo.goc in the source window.

**Synopsis:**  
View a file in Swat.

**See Also:**  
view-line, view-default, srcwin.

----------

### view-default

**Usage:**  
`view-default [patient]`

**Examples:**  
`view-default spool`  
 sets the default view to the spool patient.

`view-default`  
 turns off the view default.

**Synopsis:**  
If the view-default is set the view command will automatically look for source 
files from that patient. If it's not set then the view command will look for files 
from the current patient.

**See Also:**  
view, view-line, srcwin.

----------

### view-size

**Usage:**  
`view-size <number-of-lines>`

**Examples:**  
`view-size 10`  
Makes the view window 10 lines high.

**See Also:**  
view, view-line, view-default, srcwin.

----------

### vistree

**Usage:**  
`vistree [<address>] [<instance field>]`

**Examples:**  
`vistree`  
print the visual tree starting at *DS:SI

`vistree -i`  
print the visual tree under the mouse

`vistree @23 VI_optFlags`  
print the visual tree with opt flags

`vistree *uiSystemObj`  
starts the visual tree at the root of the system.

**Synopsis:**  
Print out a visual tree.

**Notes:**

+ The `<address>` argument is the address to an object in the generic tree. 
This defaults to *DS:SI. The "-i" flag for an implied grab may be used.

 +The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

 +The `<instance field>` argument is the offset to any instance data within 
the VisInstance which should be printed out.

+ The variable "printNamesInObjTrees" can be used to print out the actual 
app-defined labels for the objects, instead of the class, where available. 
This variable defaults to false.

**See Also:**  
vup, gentree, impliedgrab, pobject.

----------

### vup

**Usage:**  
`vup [<address>] [<instance field>]`

**Examples:**  
`vup`  print the visual object at *DS:SI and its ancestors

`vup @23 VI_optFlags`  
print the states of object @23 and its ancestors

`vup -i`  
print the visual object under the mouse and the object's 
ancestors

**Synopsis:**  
Print a list of the object and all of its visual ancestors.

**Notes:**

+ The `<address>` argument is the address to an object in the visual tree. 
This defaults to *DS:SI. The "-i" flag for an implied grab may be used.

+ The special object flags may be used to specify `<object>`.  For a list of these 
flags, see pobject.

+ The `<instance field>` argument is the offset to any instance data within 
the GenInstance which should be printed out.

**See Also:**  
vistree, gup, gentree, impliedgrab, pobject.

----------

### wait

**Usage:**  
`wait`

**Examples:**  
`wait`  
Wait for the target PC to halt.

**Synopsis:**  
This is used after the machine has been continued with "continue-patient" to 
wait for the machine to stop again. Its use is usually hidden by calling "cont" 
or "next".

**Notes:**

+ This returns 0 if the patient halted naturally (because it hit a 
breakpoint), and 1 if it was interrupted (by the user typing Ctrl+C to 
Swat). 

+ Most procedures won't need to use this function.

**See Also:**  
brk, ibrk

----------

### waitForPatient

**Usage:**  
`var waitForPatient [(1|0)]`

**Examples:**  
`var waitForPatient 0`  
Tells Swat to return to the command prompt after continuing 
the machine.

**Synopsis:**  
Determines whether the command-level patient-continuation commands 
(step, next, and cont, for example) will wait for the machine to stop before 
returning.

**Notes:**

+ The effect of this is to return to the command prompt immediately after 
having issued the command. This allows you to periodically examine the 
state of the machine without actually halting it. 

+ The output when the machine does stop (e.g. when it hits a breakpoint) 
can be somewhat confusing. Furthermore, this isn't fully tested, so it 
should probably be set to 0 only in somewhat odd circumstances.

**See Also:**  
step, next, cont, int.

----------

### wakeup

Wait for a given patient/thread to wake up. WHO is of the same form as the 
argument to the "switch" command, ("help switch" to find out more). Leaves 
you stopped in the kernel in the desired thread's context unless something 
else causes the machine to stop before the patient/thread wakes up. WHO 
defaults to the current thread.

----------

### wakeup-thread

Subroutine to actually wake up a thread. Argument WHO is as for the 
"switch"command. Returns non-zero if the wakeup was successful and zero if 
the machine stopped for some other reason.

----------

### wclear

**Usage:**  
`wclear`

**Synopsis:**  
Clears the current window.

----------

### wcreate

**Usage:**  
`wcreate <height>`

**Synopsis:**  
Create a window of the given height and return a token for it. The window is 
placed just above the command window, if there's room. If there aren't that 
many lines free on the screen, an error is returned.

----------

### wdelete

**Usage:**  
`wdelete <window>`

**Synopsis:**  
Delete the given window. All windows below it move up and the command 
window enlarges.

----------

### whatat

**Usage:**  
`whatat [<address>]`

**Examples:**  
`whatat`  
name of variable at *DS:SI

`whatat ^l2ef0h:002ah`  
name of variable at the specified address

**Synopsis:**  
Print the name of the variable at the address.

**Notes:**

+ The `<address>` argument specifies where to find a variable name for. The 
address defaults to *DS:SI.

+ If no appropriate variable is found for the address, `*nil*` is returned.

**See Also:**  
pobject, hwalk, lhwalk.

----------

### whatis

**Usage:**  
`whatis (<symbol>|<addr>)`

**Examples:**  
`whatis WinColorFlags`

**Synopsis:**  
This produces a human-readable description of a symbol, giving whatever 
information is pertinent to its type.

**Notes:**

+ For type symbols (e.g. structures and enumerated types), the description 
of the type is fully displayed, so if a structure has a field with an 
enumerated type, all the members of the enumerated type will be printed 
as well. Also all fields of nested structures will be printed. If this level of 
detail isn't what you need, use the "pscope" command instead.

+ It's not clear why you'd need the ability to find the type of an 
address-expression, since those types always come from some symbol or 
other, but if you want to type more, you certainly may.

----------

### where

Common alias for "backtrace"

----------

### why

**Usage:**  
`why`

**Examples:**  
`why`

**Synopsis:**  
Print a description of why the system crashed.

**Notes:**

+ This must be run from within the frame of the FatalError function. 
Sometimes GEOS is not quite there. In this case, step an instruction or 
two and then try the "why" command again.

+ This simply looks up the enumerated constant for the error code in AX in 
the "FatalErrors" enumerated type defined by the geode that called 
FatalError. For example, if a function in the kernel called FatalError, AX 
would be looked up in geos::FatalErrors, while if a function in your 
application called FatalError, this function would look it up in the 
FatalErrors type defined by your application. Each application defines 
this enumerated type by virtue of having included **ec.def** or **ec.goh**.

+ For certain fatal errors, additional information is provided by invoking 
the command `<patient>::<error code name>`, if it exists.

**See Also:**  
regs, backtrace, explain.

----------

### wintree

**Usage:**  
`wintree <window handle> [<data field>]`

**Examples:**  
`wintree ^hd060h`  
print a window tree starting at the handle d060h

**Synopsis:**  
Print a window tree starting with the root specified.

**Notes:**

+ The `<window address>` argument is the address to a window.

+ The `<data field>` argument is the offset to any instance data within a 
window (like W_ptrFlags).

**See Also:**  
vistree, gentree.

----------

### winverse

**Usage:**  
`winverse`

**Synopsis:**  
Sets the inverse-mode of the current window (whether newly-echoed 
characters are displayed in inverse video) on or off, depending on its 
argument (1 is on).

----------

### wmove

**Usage:**  
`wmove [(+|-)] <x-coord> [(+|-)] <y-coord>`

**Synopsis:**  
Moves the cursor for the current window. Takes two arguments: the new x 
position and the new y position. These positions may be absolute or relative 
(absolute positions begin with + or -). If you attempt to move outside the 
current window, an error is generated. This command returns the new cursor 
position as {x y}.

----------

### words

**Usage:**  
`words [<address>] [<length>]`

**Examples:**  
`words`  
lists 8 words at DS:SI

`words ds:di 16`  
lists 16 words starting at DS:DI

**Synopsis:**  
Examine memory as a dump of words.

**Notes:**

+ The `<address>` argument is the address to examine. If not specified, the 
address after the last examined memory location is used. If no address 
has been examined then DS:SI is used for the address.

+ The `<length>` argument is the number of bytes to examine. It defaults to 
8.

+ Pressing `<Return>` after this command continues the list.

**See Also:**  
bytes, dwords, imem, assign.

----------

### wpop

**Usage:**  
`wpop`

**Synopsis:**  
Revert the current window to its previously pushed value.

----------

### wpush

**Usage:**  
`wpush <window>`

**Synopsis:**  
Switch to a new window, saving the old current-window. Use wpop to go back 
to the previous window. All I/O goes through the current window.

----------

### wrefresh

**Usage:**  
`wrefresh`

**Synopsis:**  
Synchronizes the current window with the screen. This need only be 
performed if you don't echo a newline, as echoing a newline refreshes the 
current window.

----------

### wtop

**Usage:**  
`wtop <flag>`

**Synopsis:**  
Sets where windows go. If argument is non-zero, windows go at the top of the 
screen and work down. Else windows go at the bottom of the screen and work 
up

----------

[Swat Reference A-I](tswta_i.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Tool Command Language](ttcl.md)