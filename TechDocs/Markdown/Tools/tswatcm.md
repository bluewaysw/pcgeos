## 3 Swat Introduction

Most programmers are familiar with the process of debugging code. Many, 
however, will not be familiar with the issues of debugging programs in an 
entirely object-oriented, multithreaded system in which memory is often 
sharable by multiple programs. Because this type of system presents not only 
incredible power but also a new class of potential bugs, the GEOS tool kit 
provides a new class of symbolic debugger.

Swat is more than just a debugging program; it is an extensible debugging 
environment which you can tailor to your needs. Because all Swat commands 
are programmed in a special language called Tool Command Language (Tcl), 
you can write your own commands or extend existing commands. Tcl was 
originally developed by Professor John Ousterhout at the University of 
California in Berkeley, California. Swat itself was developed during a project 
headed by professor Ousterhout for a distributed multiprocessing operating 
system; Geoworks gained permission from the university to use and modify 
Swat. Since then, we have tailored it for use with GEOS; thus, it is the most 
appropriate debugger for any GEOS programmer.

Swat is essentially a system debugger, as opposed to an application debugger. 
This is an important distinction, due to the multithreaded nature of 
individual GEOS applications-each application may have more than one 
thread, and a system debugger greatly eases the debugging process for such 
applications. Swat also has many other features that make it preferable to 
other debuggers:

+ Ideal for multithreaded environment
Because Swat was initially designed for debugging multithreaded 
system software, it is ideal for use on multithreaded applications in the 
GEOS environment.

+ Extremely flexible
Nearly every part of Swat you will use is written in Tcl. Swat allows you 
to create your own commands or extend existing commands by using the 
Tcl language; you can examine, print, and modify just about any data 
structure using various Tcl commands. For large applications and 
projects, the customization this offers can be a tremendous asset.

+ Extensive access to data structures
You can examine any byte in the test PC's memory while Swat is 
attached. You can examine any basic or complex data structure. For 
example, the "pobject" command ("print object") prints the entire 
instance data of the specified object. You can specify memory locations 
with symbols, registers, addresses, pointers, or a number of other ways.

+ Easy modification of code and data
Using Tcl commands, you can change the contents of a register or 
memory location. You can also create patches to be executed at certain 
points in your program; this speeds up debugging by reducing the 
fix-compile-download-attach-debug cycle to a simple fix-debug cycle.

+ Interactive single-step facility
By using Swat's single-step command, you can execute a single 
instruction at a time. Swat shows you all the inputs going in to the 
instruction so you can more easily keep track of what's going on.

+ Facilities for watching messages and objects
Swat has several "watch" facilities. For example, you can let GEOS 
continue executing while watching a particular object; Swat will display 
all messages sent to the object, along with the data passed. You can also 
watch a particular message; Swat will display the destination and passed 
data each time the message is sent.

+ On-line help system
Swat commands are documented on-line. The help facility is available 
from the basic Swat command prompt, and you can use it either as an 
interactive help shell or to get help on one particular topic. The doc 
function allows you to look up GEOS reference material in an ASCII 
version of the GEOS SDK technical documentation.

Swat also offers many other features that both novices and experts will use. 
As you gain familiarity with Swat while using Swat with the sample 
applications and with your own programs, you will discover your own 
preferred methods of debugging.

### 3.1 DOS Command Line Options

To use Swat, you must have the pccom tool running on the target machine. 
You may then invoke Swat on the development machine. Swat takes the 
following command-line flags:

**-e**  Start up the non-error-checking version of the loader on the 
target machine.

**-h**  Displays a usage line.

**-k**  Use a non-standard kernel file. 

**-n**  Start up the non-error-checking version of GEOS on the target 
machine.

**-r**  Start up the error-checking version of GEOS on the target 
machine.

**-s**  Start up the error-checking loader on the target machine.

**-D**  You will only need to use this flag if debugging Swat.

If you have set up your communications incorrectly, Swat will have problems. 
(Often these problems don't show up when sending or receiving files; Swat 
demands more from the communications programs than pcsend and pcget.)

One common problem arises when other devices are generating interrupts 
which are not being successfully masked out. If, for instance, you have a 
network card which is operating on IRQ 2, you must make sure that either 
the pccom tool or else Swat is called with the /i:a option. Swat will intercept 
IRQ level 5 by default. To determine what number to pass with the /i, take the 
IRQ level, add 8, and express the result in hexadecimal.

If Swat complains that it is "timing out" on some operation, you may have 
your communication speed set too high. Try changing the baud rate field in 
PTTY to a lower value. 

Normally, Swat insists that any geodes it examines should have their 
symbolic information in the appropriate subdirectory of your root PCGEOS 
development directory-the possible subdirectories are Appl, Library, Driver, 
and Loader. To ask Swat to look in different places for these sorts of files, 
change the SWAT.CFG file in your PCGEOS\BIN directory. You may also 
specify a fifth directory in which to look for geodes. You may specify absolute 
pathnames in this file; if you give relative paths, they will be assumed to start 
at the directory specified with your ROOT_DIR variable.

### 3.2 Notation

The rest of this chapter is devoted to interacting with Swat once you have it running. Most of this is done by means of commands typed at a prompt. Some Swat commands may have subcommands, some may have flag options, and 
some combine the two. Others may have special options; all, however, are 
documented with the following conventions.

+ `command (alternative1|alternative2|...|alternativeN)`  
The parentheses enclose a set of alternatives separated by vertical lines 
(in C, the bitwise OR operator character). For example, the expression 
`quit (cont|leave)` means that either `quit cont` or `quit leave` can be 
used.

+ `command <type_of_argument>`  
The angled brackets enclose the type of an argument rather than the 
actual string to be typed. For example, `<addr>` indicates an address 
expression and `<argument>` indicates some sort of argument.

+ `command [optional_argument]`  
The brackets enclose optional arguments to the command. For example, 
the command `alias [<word>[<command>]]` could have zero, one, or 
two arguments because the command and word arguments are optional. 
Another example would be the command `objwalk [<addr>]`, which may 
take zero arguments if it is meant to use the default address or one 
argument if the user gives it a particular address to look at.

+ `* +`  
An asterisk following any of the previous constructs indicates zero or 
more repetitions of the construct may be typed. A plus sign indicates one 
or more repetitions of the construct may be used. For example, `unalias <word>*`
can be the `unalias` command by itself, or it can be followed by 
a list of words to be unaliased.

### 3.3 Address Expressions

Address expressions are used as arguments to any Swat command that 
accesses memory. For example, the `pobject` command takes an address 
expression as an argument and prints out information about the object at 
that address. An address expression can be a symbol name, which is just the 
name of a pointer, or a symbol path. A symbol path looks like one of the 
following:

    <patient>::<name>
    <module>::<name>
    <patient>::<module>::<name>

The symbol path is used when there is more than one symbol of a given name 
or if a symbol of a different application is needed. A symbol can be 
represented in a variety of ways: the name of an object, a field of a structure, a register/number combination, a number from the address history, an element of an array, nested Tcl commands, or a Tcl variable. Array indexing is used as follows:

    <addr> [<n>]

which will return the zero-based element *n* from the given *addr*, even if *addr* is not an array.

Another important way of representing the symbol is as a *segment:offset* pair. In this, the segment is a constant, a register, a module, or a handle ID given as `^h<id>` where *id* is a constant or register.

Some examples of address expressions are shown in Table 3-1.

----------
**Table 3-1** Address Expressions

    Type                            Example

    name of object                  Icon1
    field of structure              applVars.Core
    number/register combination     0x1ef0:si
    number/register combination     1ef0h:si

----------

There are several operators which are used to make memory examination 
and manipulation easier in Swat. These operators are shown below (in order 
of highest precedence to lowest):

+ `^h`  
The *carat-h* is used to dereference a memory handle when representing 
an address as a *handle:offset* pair (this is also known as a "heap pointer" representation) or when accessing a particular block of memory. It is often used in the situation when a memory handle is in one register (such as BX) and the offset is in another register (such as SI). This is similar to the ^l operator (below), but it requires an offset into the block rather than a chunk handle. The *^h* operator is used thus (the two commands will give the same information if the specified registers contain the specified values):

        [hello3:0] 6 => pobj ^h43d0h:0022h
        [hello3:0] 7 => pobj ^hBX:SI


+ `.`  
The *period* is used to access a field in a structure. For example, if a visible object is located at `^hBX:SI`, you could retrieve its top bound with the following command:

        [hello3:0] 8 => print ^h43d0h:0022h.VI_bounds.R_top

+ `+ -`  
The addition and subtraction operators are used to add and subtract 
symbols to and from other symbols and constants. If two symbols in the 
same segment are subtracted, a constant will be the result.

+ `^l`  
The *carat-l* is used to dereference an optr, a pointer in the form 
*handle:chunk-handl*e (this is also known as a "local memory pointer"). 
This is similar to the `^h` operator, but `^`l requires a chunk handle rather than an offset. If an optr is stored in CX:DX, for example, the `^l` operator could be used to dereference it as follows:

        [hello3:0] 11 => pobj ^lCX:DX
        [hello3:0] 12 => pobj ^l0x43d0:0x022

+ `:`
The *colon* is the segment/offset operator, used to separate the segment 
and offset in a *segment:offset pair*.

        [hello3:0] 13 => pobj ^lCX:DX
        [hello3:0] 14 => pobj ^l0x43d0:0x022
        [hello3:0] 15 => pobj INTERFACE:HelloView

+ `*`
The *asterisk* is a pointer-dereferencing operator, as in the C programming 
language:

        [hello3:0] 16 => print SubliminalTone
        @5: SubliminalTone = 7246h

        [hello3:0] 17 => print *(&SubliminalTone)

        @6: *(&SubliminalTone) = 7246h

+ `^v`
The *carat-v* is the virtual memory operator, used to get to the base of a 
block that is in a Virtual Memory file given the file handle and VM block 
handle. The correct usage of the `^v` operator is:

        ^v<file>:<VM_block>

Much of the time the type of data stored at the address given by the address expression is implicit in the expression. Sometimes in ambiguous situations (using code as data), however, the type of data must be explicitly stated in the address expression. This is done by indicating the type of the data followed by a space and then a normal address expression. For example, in the expression

    dword ds:14h

the data at `ds:14h` will be treated as a double word.

### 3.4 On-line Help

Swat provides on-line help, both for looking up Swat topics and GEOS 
reference material.

To get help on a specific Swat command, you simply type the following, where 
the command is the argument.

`[hello3:0] 7 => help <cmd>`

To use Swat's interactive, menu-based help system, simply type the 
following:

`[hello3:0] 8 => help`

The menu-based system provides a tree of help topics which are organized 
into subjects. If you are looking for Swat commands having to do with a 
subject not covered in the help tree, you might try using the **apropos** 
command.

To get information about a GEOS topic, use the doc functions.

----------
#### apropos

    apropos [<string>]

The **apropos** command searches the list of commands and command help for 
all entries containing `<string>`. It lists each command and its synopsis. The string may actually be a partial word.

----------
#### doc, doc-next, doc-previous
    doc [<keyword>]
    doc-next
    doc-previous

The **doc** command looks for information in the technical documentation 
relevant to the passed keyword. The keyword may be any GEOS symbol. The 
**doc** command finds one or more places in the SDK technical documentation 
where the keyword is mentioned. It will display one place-to view the 
others, use the **doc-next** and **doc-previous** command. The documentation will appear in the source window. As when viewing source code using **srcwin**, you can scroll the view using the <Page Up> and <Page Down> and 
arrow keys.

----------
#### help

    help [<command>]

There are two different ways to use the **help** command. The first is to enter the interactive help mode using the **help** command with no arguments, and the second is to use the help command with a particular command as an argument.

#### Interactive help mode
The interactive help mode consists of a tree of commands and topics 
identified by different numbers. If one of the numbers is typed, 
information about that particular topic or command is displayed. Some 
of the topics have their own subtrees (indicated by the ellipses following 
the topic heading) which follow the same numbering format. The 
interactive help mode is used when looking for a certain style of 
command but the name of the command is not known (see Swat 
Display 3-1).

----------

**Swat Display 3-1 The Help Tree**  

        (geos:0) 198 => help

        top-most level of the help tree:
 
        0 FINISH            6 memory...             12 step...
        1 advanced...       7 object...             13 support...
        2 breakpoint...     8 print...              14 swat_navigation...
        3 crash...          9 running...            15 window...
        4 file...           10 source...
        5 heap...           11 stack...

        Type "help" for help, "menu" to redisplay the menu, "0" to exit.
        Type a topic (or its number) to display it.
        help:top>

----------



    help <command>

When **help** is typed with another command as an argument, information 
about that command is displayed (the same information as in the 
interactive help mode). This command is frequently used in order to get 
fast help on a particular command. (See Swat Display 3-2.)

----------
**Swat Display 3-2 The help Command**

        (geos:0) 200 => help help
        Help for help:
        Functions for manipulating/accessing the help tree
        ==============================================================================
        This is the user-level access to the on-line help facilities for Swat. If
        given a topic (e.g. "brk") as its argument, it will print all help strings
        defined for the given topic (there could be more than one if the same name is
        used for both a variable and a procedure, for instance). If invoked without
        arguments, it will enter a browsing mode, allowing the user to work his/her
        way up and down the documentation tree
        ==============================================================================
        (geos:0) 201 =>


----------



### 3.5 Essential Commands

This section covers the function and usage of some of the most important 
Swat commands. These commands fall into the following command groups:

+ Cycle of Development  
Sending down a new copy of a geode and running it.

+ Attaching and Detaching Swat  
The commands used to control the link between Swat and GEOS.

+ Setting Breakpoints and Code Stepping  
The commands used to stop the execution of an application's code at 
pre-determined points and then examine the code, line by line if 
necessary.

+ Examination of Memory  
The commands used to examine memory from individual bytes to whole 
structures such as generic trees and objects.

+ Other Important Commands  
Other commands which are important to know but do not fit into the 
aforementioned groups.

A complete list of the Swat commands is contained in the Reference chapter.

#### 3.5.1 Cycle of Development

    send, run, exit, patient-default

These commands come in handy whenever you've edited and recompiled your 
application. You'll want to exit the application on the target machine. Use the 
send command to **send** down the new, compiled version of your application. 
Then use the **run** command to start up the program.

----------
**send**

    send [<geode-name>]

To send the latest compiled version of your program, type "send" followed by 
the application's patient name (the first part of the field on the "name" line of 
the .gp file). 

----------
**run**  

    run [<geode-name>]

To run your geode on the target machine, type "run" followed by the 
application's patient name (the first part of the field on the "name" line of the 
.gp file).

---------
**exit**  

    exit <geode-name>

To exit a running application, type "exit" followed by the application's patient 
name. The exit command won't work if your application has encountered a 
fatal error.

----------
**patient-default**  

    patient-default [<geode-name>]

Use this command to set a default patient to use with the **send** and **run** 
commands. The send and run commands will operate on this patient if they 
are not passed arguments.

#### 3.5.2 Attaching and Detaching

    attach, att, detach, quit, cont, Ctrl-C

This group of commands controls the state of the connection between Swat 
and GEOS when Swat is running. The **attach** and **att** commands are used to 
establish the connection while **detach** and **quit** are used to sever it. The 
most frequently used commands in this group are **att** with the **-r** flag and 
**detach**. Some related commands contained in the Reference are **go**, **istep**, 
**sstep**, and **next**.

The following is a typical but simplified debugging cycle using **detach** and 
**att**. It assumes you have already attached for the first time.

+ When a bug is encountered, determine where and what the bug is, then 
detach Swat by typing **detach**.

+ Edit the application to fix the bug, recompile it and download it to the 
target machine.

+ Re-attach Swat to the target PC using the **att** command by typing 
Scrolllock-Shift-s on the target machine and typing **att** on the host 
machine.

+ Continue debugging the application.

+ Repeat the detach, edit, attach, debug cycle until all of the bugs are fixed.

By themselves, the commands shown below can not do much except open and 
close the communication lines between GEOS and Swat. More commands to 
examine and modify the application's code as it runs are needed to start 
actual debugging.

----------
**Swat Display 3-3 Detaching and Attaching**

    (geos:0) 202 => det cont
    PC detached
    (loader:0) 203 => att
    Re-using patient geos
    Re-using patient ms4
    Re-using patient vidmem
    Re-using patient swap
    Re-using patient xms
    Re-using patient disk
    Re-using patient kbd
    Re-using patient nimbus
    Re-using patient stream
    Re-using patient sound
    Re-using patient standard
    Re-using patient ui
    Re-using patient styles
    Re-using patient color
    Re-using patient ruler
    Re-using patient text
    Re-using patient motif
    Re-using patient vga
    Re-using patient spool
    Re-using patient serial
    Re-using patient msSer
    Re-using patient nonts
    Re-using patient welcome
    Re-using patient shell
    Re-using patient manager
    Re-using patient math
    Re-using patient borlandc
    Re-using patient mess1
    Thread 1 created for patient geos
    Thread 2 created for patient geos
    Thread 0 created for patient ui
    Thread 0 created for patient spool
    Thread 0 created for patient welcome
    Thread 0 created for patient manager
    Thread 1 created for patient manager
    Thread 0 created for patient mess1
    Attached to PC
    Stopped in 0070h:0005h, address 0070h:0005h
    DOS+773: JMP DOS+2963
    (geos:0) 204 =>

    In this example, we use the det cont command so that GEOS will keep running. We then re-attach 
    with att. In the intervening time, the two machines are independent, and the serial line is unused. 
    We could have taken advantage of this to send down a new copy of some application (as long as that 
    application was not running on the target machine).



----------
**att**  
    att 

The **att** command is similar to the **attach** command, but has no bootstrap 
argument (as explained below).

----------
**attach**  
    attach [(+b|-b)]

This command is used to attach Swat to the target PC when the Swat stub is 
already invoked. The -b argument is to bootstrap and the **+b** argument is not 
to bootstrap. Bootstrapping means that Swat will search for the symbol files 
of all of the geodes and threads as they are encountered rather than all at the 
beginning. This saves some time if you've just detached and need to 
re-attach, using only a few geodes while debugging. If no argument is given, 
the most recent bootstrap setting is used. The default bootstrap setting is **+b**.

----------
**cont**  
    cont

The **cont** command continues the execution of GEOS after it has been 
stopped for some reason such as at a breakpoint or fatal error or by control-C. 
This command is often aliased as the letter **c**.

----------
**detach**  
    detach [(cont|leave)]

The **detach** command will detach Swat from the target PC. By itself, the 
**detach** command will detach Swat and exit GEOS. This command is usually 
used after a bug is encountered and the source code needs to be modified and 
recompiled (see Swat Display 3-3).

+ **cont** - The **cont** option will just detach Swat and allow GEOS to continue to run 
normally. This option is used when the debugging process is finished but 
GEOS is still needed to do other things (such as word processing) and you 
may need to re-attach later for further debugging.

+ **leave** - The **leave** option will detach Swat but keep GEOS stopped wherever it 
was when the **detach leave** command was given. This command is 
useful for passing debugging control to someone remotely logged in to the 
workstation or when Swat can not continue for some reason.

----------
**quit**  
    quit [(cont|leave)]

The **quit** command is only used when Swat needs to be exited for good. It will 
detach Swat (if necessary), exit from Swat on the development station, and 
exit from GEOS.

+ **cont** - The **cont** option exits Swat on the development station but allows GEOS 
to continue running normally on the target PC. This option is used when 
the debugging process is finished but GEOS is still needed to do other 
things such as word processing.

+ **leave** - The leave option will exit Swat but will keep GEOS stopped wherever it 
was when the quit leave command was given.

----------
**Ctrl-C**  
    Ctrl-C

The **Control-C** command is the command used to stop the execution of GEOS 
at any point. This command is executed by holding down the Ctrl key and 
pressing the c key. It is used to stop GEOS in order to set a breakpoint, 
examine memory, or to get a command line prompt.


#### 3.5.3 Breakpoints and Code Stepping

The commands in this group are used to stop at specified breakpoints in an 
application's code and then step through the code line by line if necessary. 
These commands are often used with each other to examine critical areas in 
the application source code.

**3.5.3.1   Breakpoints**

    stop, brk, go, cbrk, spawn

The **stop**, **brk** and **cbrk** commands are used to set breakpoints. The 
breakpoint commands have many subcommands controlling the actions and 
attributes of a particular breakpoint.

The **cbrk** command sets breakpoints to be evaluated by the Swat stub; **brk** 
sets them to be evaluated by Swat. The Swat stub can evaluate the conditions 
much faster than Swat, but **cbrk** has certain limitations: only a limited 
number of breakpoints can be set using **cbrk**, and these breakpoints can only 
compare registers when the breakpoint is hit with a given set of criteria.

----------
**stop**

    stop in <class>::<message> [if <expr>]
    stop in <procedure> [if <expr>]
    stop in <address-history-token> [if <expr>]
    stop at [<file:]<line> [if <expr>]
    stop <address> [if <expr>]

This is the main command to use when setting breakpoints in C programs. 
The "stop in" command will set a breakpoint at the beginning of a procedure, 
immediately after the procedure's stack frame has been set up. The "stop at" 
command will set a breakpoint at the first instruction of the given source 
line. If no `<file>` is specified, the source file for the current stack frame is 
used. If a condition is specified by means of an "if <expr>" clause, you should 
enclose the expression in curly braces to prevent any nested commands, such 
as a "value fetch" command, from being evaluated until the breakpoint is hit.

----------
**brk***

    brk [<sub-command>]

The **brk** (breakpoint) command is used for setting nearly all breakpoints in 
an application's code. The simplest way to use it is to type **brk** with a single 
*addr* argument. The address is usually a routine name for a suspect 
procedure, and when the breakpoint is reached the code-stepping commands 
can be used to examine it carefully. The **brk** command can also create 
conditional breakpoints which will only be taken if certain conditions are 
satisfied. Once set, a breakpoint is given an integer number which can be 
obtained using the **list** subcommand (see Swat Display 3-4).

    brk <addr> [<command>]

The **brk** command without any subcommands sets an unconditional 
breakpoint at the address specified in *addr*. If the *command* argument is 
passed, the given swat command will be carried out when the breakpoint 
is hit.

    brk delete <break>*

Deletes the given breakpoint(s), just as **clear**, above.

    brk enable <break>*

Enables the given breakpoint(s). Has no effect on previously enabled 
breakpoints. If no breakpoint is given, all breakpoints for the current 
patient are enabled.

    brk disable <break>*

Disables the given breakpoint(s). It has no effect on previously disabled 
breakpoints. If no breakpoint is given, it disables all breakpoints for the 
current patient.

    brk list [<addr>]

Lists all the breakpoints, whether they are enabled, where they are set, 
their conditions, and what actions they will take if encountered. If *addr* 
is given, it returns the breakpoint numbers of all breakpoints set at the 
given address.

----------
**Swat Display 3-4 Breakpoints**

    (geos:0) 4 => brk list
    Num S Address Patient Command/Condition
    1   E loader::kcode::LoaderError all echo Loader death due to [penum
                        LoaderStrings [read-reg ax]]
                        expr 1
    2   E kcode::FatalError all
                        why
                        assign kdata::errorFlag 0
                        expr 1
    3   E kcode::WarningNotice all why-warning
    4   E kcode::CWARNINGNOTICE all why-warning
    (geos:0) 5 => stop in Mess1Draw
    brk5
    (geos:0) 6 => brk list
    Num S Address Patient Command/Condition
    1   E loader::kcode::LoaderError all echo Loader death due to [penum
                        LoaderStrings [read-reg ax]]
                        expr 1
    2   E kcode::FatalError all
                        why
                        assign kdata::errorFlag 0
                        expr 1
    3   E kcode::WarningNotice all why-warning
    4   E kcode::CWARNINGNOTICE all why-warning
    5   E <ss1::MESS1_TEXT::Mess1Draw+10 all halt
    (geos:0) 7 => brk dis brk4
    (geos:0) 8 => brk list
    Num S Address Patient Command/Condition
    1   E loader::kcode::LoaderError all echo Loader death due to [penum
                        LoaderStrings [read-reg ax]]
                        expr 1
    2   E kcode::FatalError all
                        why
                        assign kdata::errorFlag 0
                        expr 1
    3   E kcode::WarningNotice all why-warning
    4   D kcode::CWARNINGNOTICE all why-warning
    5   E <ss1::MESS1_TEXT::Mess1Draw+10 all halt
    (geos:0) 9 =>
    
----------

**go**  
    go [<address-expressions>]

The go command sets a one-time breakpoint and resumes execution on the 
target PC. The net effect of this is to let the target go until it hits a given 
address, then stop.

----------
**cbrk**  
    cbrk [<sub-command>]

The **cbrk** (conditional breakpoint) command is used to set fast conditional 
breakpoints. This command is very similar to the **brk** command above, 
except that the condition is evaluated by the Swat stub-this increases the 
speed of the evaluation. There are, however, certain restrictions on the **cbrk** 
command: only a limited number of breakpoints can be set (eight), and the 
scope of the evaluation is limited to comparing word registers (or a single 
word of memory) to a given set of values.

In the following descriptions, **criteria** stands for a series of one or more 
arguments of the form:

    <register> <op> <value>

*register*  
One of the machine's registers or "thread," which corresponds 
to the current thread's handle.

*op*  
One of the following ten comparison operators: = (equal), != (not 
equal), > (unsigned greater-than), < (unsigned less-than), >= 
(unsigned greater-or-equal), <= (unsigned less-or-equal), +> 
(signed greater-than), +< (signed less-than), +>= (signed 
greater-or-equal), +<= (signed greater-or-equal). These 
correspond to the 8086 instructions JE, JNE, JA, JB, JAE, JBE, 
JG, JL, JGE, JLE, respectively.

*value*  
A standard Swat address expression. The resulting offset is the 
value with which the register will be compared when the 
breakpoint is hit.

    cbrk <addr> <criteria>*

The basic cbrk command sets a fast conditional breakpoint at the address 
specified in *addr*.

    cbrk cond <break> <criteria>*

Changes the criteria for the breakpoint. If no *criteria* is given the 
breakpoint becomes a standard, unconditional breakpoint.

----------
**spawn**  
    spawn <patient-name> [<addr>]

The **spawn** command is used to set a temporary breakpoint in a process or 
thread which has not yet been created. The arguments are

*patient-name*  
The permanent name, without extension, as specified by the 
name directive in the **.gp** file; this is the name of the patient in 
which to set a temporary breakpoint. A unique abbreviation is 
sufficient for this argument.

*addr*  
A particular address at which to place the breakpoint. If no 
address is given, Swat will stop as soon as the given geode is 
loaded.

This command is used to stop the geode before any of its code can be run, 
allowing breakpoints to be set in the desired routines. If you could not stop 
the machine in this manner, the application could hit a buggy routine before 
a breakpoint could be set in that routine. The **spawn** command can also be 
used to catch the spawning of new threads which is useful to keep track of 
the threads being used by an application (see Swat Display 3-5).

----------
**Swat Display 3-5 The spawn Command**

    (geos:1) 12 => spawn mess1 Mess1Draw
    Re-using patient math
    Re-using patient borlandc
    Re-using patient mess1
    Thread 0 created for patient mess1
    Interrupt 3: Breakpoint trap
    Stopped in Mess1Draw, line 211, "C:\PCGEOS/Appl/SDK_C/MESS1/MESS1.GOC"
    Mess1Draw(GStateHandle gstate)              /* GState to draw to */
    (mess1:0) 13 =>
    


**3.5.3.2   Code Stepping**

    srcwin, istep, sstep

Once an application is stopped at a breakpoint and you want to examine the 
code line by line, you can use the commands **istep** (instruction step) and 
*sstep* (source step). These enter the instruction step mode or source step mode 
to examine and execute the application code line by line.

The subcommands for both **istep** and sstep are nearly the same and are used 
for actions including stepping to the next line, skipping the next instruction, 
or exiting the step mode and continuing the execution of the application. The 
**istep** and **sstep** commands are very similar except that **istep** is used when 
stepping through assembly source code (thus stepping through instructions), 
and **sstep** is used for stepping through C source code.

----------
**srcwin**

    srcwin <numlines> [view]

The srcwin command will display the source code surrounding the presently 
executing code any time execution is stopped. The presently executing line 
will be highlighted. You may set breakpoints with the mouse by clicking on 
the line numbers which appear to the side. To scroll the srcwin buffer use the 
arrow keys, the <PgUp> key, and the <PgDn> key.

----------
**istep, sstep**

    istep [<default subcommand>]
    sstep [<default subcommand>]

These two commands are used to single-step through code, executing one or 
more instructions at a time. The *default subcommand* argument determines 
the action taken by Swat when the Return key is pressed. For example, the 
command

    [hello3:0] 7 => istep n

will enter instruction step mode, and subsequently pressing the Return key 
will have the same effect as pressing **n**. If no default command is given, 
pressing Return has the same effect as pressing **s**.

The subcommands to the **istep** and **sstep** commands are

**s** (single step)  
Step one instruction. This is the most frequently used subcommand.

**n, o** (next, over)  
Continue to the next instruction but do not display any procedure calls, 
repeated string instructions, or software interrupts. They will stop when 
GEOS returns to the same frame as the previous displayed instruction. 
The frame is the same when the stack pointer and current thread are the 
same as when the **n** subcommand was given. o differs from n in that it 
executes all instructions in a macro without further interpretation and 
can only be used with **istep**. If a breakpoint other than for the next 
instruction is hit, it will take effect as long as the above conditions are 
met.

**N, O** (Next, Over)  
These are like **n** and **o** but will stop whenever a breakpoint is hit even if 
the frame is different. **O** will execute all instructions in a macro without 
further interpretation, and it can only be used with **istep**. If a breakpoint 
other than one for the next instruction is hit, it will take effect as long as 
the above conditions are met.

**q, Esc, <space>** (quit)  
These stop **istep/sstep** and return to the command level. These 
subcommands are used when a point in the code is reached where 
another command needs to be used-to examine memory, for example.

**c** (continue)  
This exits **istep** and continues the execution of the application. When 
GEOS next stops, Swat will return to the command prompt.

**M** (message)  
This will continue until the next handled message is received. When the 
handler is invoked, Swat will return to step mode. This subcommand is 
often used with the **ObjMessage()** and **ObjCallInstanceNoLock()** 
assembly routines.

**F** (finish message)  
This finishes the current message, stops when execution returns to a 
frame that is not part of the kernel, and remains in step mode.

**f** (finish frame)  
This finishes the current stack frame, stops, and remains in step mode.

**S** (skip instruction)  
This skips the current instruction, does not execute it, and goes on to the 
next instruction in step mode.

#### 3.5.4 Examining and Modifying Memory

The commands in this section all deal with the examination, manipulation, 
or modification of the memory used by an application. Memory from 
individual bytes to complex data structures such as objects can be displayed 
and examined. These commands fall into the following groups:

+ Simple Memory Examination.
Examination of bytes, words, and double words with no modification.

+ Complex Memory Examination
Examination of structures such as objects, generic trees, and handle 
tables with no modification.

+ Memory Examination with Modification
Examination of memory with modification if desired. Some commands 
are used only for memory modification.

The commands in this section are often used with each other and with the 
code-stepping and breakpoint commands in order to pinpoint bugs in an 
application's code. Breakpoints can be set, code can be stepped through, and 
then the memory that the code uses can be examined.

Some related commands defined in the Reference chapter are **down**, **func**, 
**handles**, **hgwalk**, **impliedgrab**, **penum**, **phandle**, **pinst**, **piv**, **precord**, 
**skip**, **systemobj**, **up**, and **where.**

**3.5.4.1   Simple Memory Examination**

    bytes, words, dwords, frame, backtrace, why, listi

The commands in this group are used to look at simple blocks of memory 
without modification. They are defined fully in the entries below.

----------
**bytes, words, dwords**

    bytes [<addr>] [<length>]
    words [<addr>] [<length>]
    dwords [<addr>] [<length>]

The **bytes**, **words**, and **dwords** commands are essentially the same except 
that each looks at a different sized piece of memory. These commands will 
display the memory as a pointer to a dump of bytes, words, or dwords using 
the given or most recent (if no address is given) address.

The **bytes** command additionally displays the dump as its ASCII character 
representation, if any. These three commands are used to examine memory 
on a very basic level and are useful only if the user knows what the bytes, 
words, or dwords should or should not be and so can spot any problems. For 
example, if a certain character string such as "Application" is supposed to be 
stored at the address given by *fileType* and the command

    [hello3:0] 11 => bytes fileType

dumps the characters "noitacilppA", then there is most likely a problem.

These commands will automatically use the given *addr* as a pointer to the 
memory to be examined. If Return is hit many times in a row, the result will 
be to examine adjacent pieces of memory. (See Swat Display 3-6.)

----------

**Swat Display 3-6 The words Command**

    (mess1:0) 15 => words themeSongBuf
    Addr: +0 +2 +4 +6 +8 +a +c +e
    0040h: 0004 0000 0049 0000 0004 0001 0083 0000
    (mess1:0) 16 => words
    Addr: +0 +2 +4 +6 +8 +a +c +e
    004eh: 0000 0006 0004 0028 0000 0001 020b b800
    (mess1:0) 17 => !!
    words
    Addr: +0 +2 +4 +6 +8 +a +c +e
    005ch: b800 000c 0020 0002 0001 0000 0001 020b
    (mess1:0) 18 => !!
    words
    Addr: +0 +2 +4 +6 +8 +a +c +e
    006ah: 020b b800 000c 0010 0002 0001 000a 0010 

*Here the **words** command examines a buffer in memory. When this command is repeated without 
arguments, it will display memory continuing where the last command left off. Note the use of the 
!! command to repeat the previous command.*


----------

**backtrace, frame**

    backtrace [<frames to list>]
    frame <subcommand>

The **backtrace** and **frame** commands are used to examine data that has 
been pushed onto the stack. An application may crash in a routine that is 
correctly written but has been passed bad data.

The **backtrace** command prints out a list of all the active frames for the 
current patient. Then the user can choose a particular frame to examine 
using one of the **frame** subcommands. The **frame** command is used to access 
frames that have been pushed onto the stack, where a *frame* is the 
information for a routine that needs to be saved when it calls another 
routine.

The **frame** and **backtrace** commands can be used together to print the 
active frames with **backtrace** and then access data in these frames with 
**frame**. However, most of the **frame** subcommands expect a token for a 
frame, not the frame number given by the backtrace command. To get this 
token, the **top**, **cur** and **next** subcommands are used. Then the other **frame** 
subcommands can be used with the token to further examine the **frame** data 
(see Swat Display 3-7). See "Swat Reference," Chapter 4, for more details on 
the **frame** command.

----------

**Swat Display 3-7 Backtrace and Frame commands**

    Death due to SOUND_BAD_EVENT_COMMAND
    Execution died in patient sound:
    SoundHandleTimerEvent+63: MOV AX, 7 (0007h)
    *** No explanation available ***
    Interrupt 3: Breakpoint trap
    Stopped in FatalError, address 1844h:0163h
    SoundHandleTimerEvent+63: MOV AX, 7 (0007h)
    (mess1:0) 2 => backtrace
      1: near FatalError(), 1844h:0163h
      2: far AppFatalError(), 1844h:0163h
    * 3: far SoundHandleTimerEvent(), 2cb2h:003fh
      4: far SoundLibDriverPlaySimpleFM(), 6247h:0062h
      5: far ResourceCallInt(), 1844h:1492h
      6: far SoundLibDriverStrategy(), 2cb2h:0ab2h
      7: near SoundCallLibraryDriverRoutine(), 629ch:00feh
      8: far SoundPlayMusic(), 629ch:0028h
      9: far ResourceCallInt(), 1844h:1492h
      10: far SOUNDPLAYMUSICNOTE(mh = ^h42b0h (at 753ch), priority = 1eh, tempo = 4h
    , flags = 80h), 62d6h:00f3h
      11: far ResourceCallInt(), 1844h:1492h
      12: far Mess1Draw(), MESS1.GOC:307
      13: far MESS1PROCESSMETA_EXPOSED(win = 3a60h, message = 69 (invalid), oself =
    3ee0h:0000h), MESS1.GOC:362
      14: far ResourceCallInt(), 1844h:1492h
    MSG_META_EXPOSED (3a60h 0000h 0000h) sent to Mess1ProcessClass (^l20f0h:0h)
      16: near ObjCallMethodTableSaveBXSI(), 1844h:9ea5h
      17: far SendMessage(), 1844h:9d9bh
      18: far ObjMessage(), 1844h:1d9ch
      19: far MessageDispatchDefaultCallBack(), 1844h:1c72h
      20: far MessageProcess(callBack = 1844h:1c68h (geos::kcode::MessageDispatchDef
    aultCallBack)), 1844h:1c15h
      21: far MessageDispatch(), 1844h:1b31h
      22: far ThreadAttachToQueue(), 1844h:bd2ch
    (mess1:0) 3 => frame 12
    Mess1Draw+302: MOV AX, 100 (0064h) 

----------

**3.5.4.2   Complex Memory Examination**

    print, hwalk, lhwalk, objwalk, pobject, gentree, vistree, 
    vup, gup

The commands in this group are used to examine complex data structures in 
GEOS.

----------

**print**

    print <expression>

The **print** command is used to print out the value of the given *expression* 
argument. The *expression* argument is normally some sort of typed address. 
When there is no type for the *expression*, then its offset is printed.

The power of this command lies in its ability to print any type at any address; 
thus, it is used frequently to print out the values of important expressions 
such as registers or variables. The **print** command also takes many flags 
which control the way in which the value of the *expression* is displayed such 
as in decimal or hexadecimal. See the Reference chapter for more 
information on the flags for the **print** command.

----------

**hwalk**

    hwalk [<patient>]

Use the **hwalk** (heap walk) command to display blocks on the global heap. 
Its output can be tailored in various ways according to how the **flags** are set. 
If a *patient* is given, then **hwalk** will only print the blocks owned by that 
patient. There are many fields in the listing such as the handle, address, and 
type of each block. By examining these fields, the user can get an overall 
sense of how the global heap is being managed, whether any block looks too 
big or too small, and what the handles of important blocks are. (See Swat 
Display 3-8.)

----------
**Swat Display 3-8 The hwalk Command**

    (mess1:0) 6 => hwalk mess1
    HANDLE ADDR SIZE FLAGS LOCK OWNER IDLE  OINFO                       TYPE
    ----------------------------------------------------------------
    20f0h 41ebh 2272 FIXED  n/a mess1  n/a     1h                       R#1 (dgroup)
    4160h 58eah  448 sDS  a   1 mess1 105eh    1h                       R#2 (MESS1_TEXT)
    3a60h 59adh  784 s SL     0 mess1  0:03    1h                       WINDOW
    4bb0h 6176h  560 s SL     0 mess1  0:05    1h                       WINDOW
    3970h 6232h  336 s SL     0 mess1  0:03    1h                       GSTATE
    3ee0h 633ch  160 s S  a   0 mess1  0:05 49c0h                       Geode
    4950h 63beh 1280 s SL     0 mess1  0:05 49c0h                       OBJ(mess1:0)
    4340h 640eh 1328   SL     0 mess1  0:05 49c0h                       R#3 (INTERFACE)
    42b0h 753ch   96 s S      4 mess1 1249h    1h                     
    4bd0h 7542h   96 s S      0 mess1  0:01    1h   
    41b0h 89d4h  896   SL     0 mess1  0:05 49c0h                       R#4 (APPRESOURCE)
    4270h 99e1h   32 s S      0 mess1  0:05     1h
    
    Total bytes allocated: 8288
    (mess1:0) 7 =>

----------

**lhwalk, objwalk**

    lhwalk [<addr>]
    objwalk [<addr>]

The **lhwalk** (local heap walk) command is used to display information about 
a local memory heap, and the **objwalk** command is used to print out 
information about an object block. After using **hwalk** to locate a specific 
block, **lhwalk** or **objwalk** can be used to print out information about that 
particular block. These commands also print out fields of information which 
include the local handle, the address, size, and type of data or object. See the 
Reference chapter for more information on the fields printed by **lhwalk** and 
**objwalk**. (See Swat Display 3-9.)

----------

**Swat Display 3-9 The objwalk Command**

    (mess1:0) 11 => objwalk ^h4340h
     
    Heap at 640eh:0 (^h4340h), Type = LMEM_TYPE_OBJ_BLOCK
    In use count = 3, Block size = 1328, Resource size = 59647 para (192 bytes)
     
    HANDLE ADDRESS  SIZE FLAGS CLASS (NAME)
    ------ -------  ---- ----- ------------
     001ch     56h      1eh  ---  *flags*
     001eh     76h      c1h  D RO GenPrimaryClass (Mess1Primary)
     0020h    1aah      ceh  D RO GenViewClass (Mess1View)
     0022h    166h      32h ID  O OLGadgetAreaClass
     0024h    19ah       eh  I
     0026h    492h      6bh  D  O GenValueClass
     0028h    2deh      6bh  D  O GenValueClass
     002ah    37eh      a6h ID  O GenInteractionClass
     002ch    44ah      46h ID  O OLMenuBarClass
     002eh    13ah       bh ID
     0030h    426h      22h ID  O OLMenuButtonClass
     
    Free handles = 17, null handles = 0
    Objects = 8, 4 of them marked ignoreDirty
     
    (mess1:0) 12 =>


----------
**pobject**

    pobject [<addr>] [<print level>]

The **pobject** (print object) command (often abbreviated **pobj**) is used to print 
out the entire instance data chunk of an object. You can use **gentree**, 
**vistree**, or **hwalk** and **objwalk** to get the handles for an object; once you 
have them, use **pobj** with the handles, as follows:

    [hello3:0] 7 => pobj ^l0x43d0:0x0022

will print out the instance data chunk specified by that optr.

Any valid address expression, such as a dereferenced object name, may be 
used as an *addr*. Additionally, the print level can be changed to print just the 
headings to each of the master levels and an address history number. The 
**pobject** command is used to verify that the object is behaving correctly and 
that its instance variables (if any) are correct. (See Swat Display 3-10.)

----------

**Swat Display 3-10 The pobject Command**

    [lesink:0] 10 => pobj ^l4710h:0020h
    *UpTextView::UpTextViewClass (@7, ^l4710h:0020h)
    master part: Gen_offset(123) -- UpTextViewInstance
    @8: {UpTextViewInstance (^h18192:622)+123} = {
        MetaBase Gen = {
            ClassStruct _far *MB_class = 360ah:162fh (motif::dgroup::OLPaneClass)
        }
        LinkPart GI_link = {
            dword LP_next = 4710h:001fh
        }
        CompPart GI_comp = {
            dword CP_firstChild = 4710h:002ah
        }
        word GI_visMoniker = 0h
        word GI_kbdAccelerator = 0h
        byte GI_attrs = 2h
        byte GI_states = c0h
        PointDWFixed GVI_origin = {
            DWFixed PDF_x = {0.000000}
            DWFixed PDF_y = {0.000000}
        }
        RectDWord GVI_docBounds = {
            long RD_left = 0
            long RD_top = 0
            long RD_right = +480
            long RD_bottom = +480
        }
        PointDWord GVI_increment = {
            long PD_x = +20
            long PD_y = +15
        }
        PointWWFixed GVI_scaleFactor = {
            WWFixed PF_x = {1.000000}
            WWFixed PF_y = {1.000000}
        }
        ColorQuad GVI_color = {
            CQ_redOrIndex = fh, CQ_info = 0h, CQ_green = 0h, CQ_blue = 0h
        }
        word GVI_attrs = 10h
        byte GVI_horizAttrs = 88h
        byte GVI_vertAttrs = 88h
        byte GVI_inkType = 0h
        dword GVI_content = 4710h:0024h
        dword GVI_horizLink = 0000h:0000h
        dword GVI_vertLink = 0000h:0000h
    }
    Variable Data:
             *** No Variable Data ***
    [lesink:0] 11 =>



In addition to printing information about the object at a given address, 
pobject can print information about certain objects in the application if 
passed certain flags:

**pobject -i**  Prints information about the windowed object under the mouse 
pointer.

**pobject -c**  Prints information about the content for the view over which 
the mouse is located.

There are more flags available, and it is also possible to ask for more or less 
instance data information. See the full reference for this command for 
details.

----------

**gentree**

    gentree [<addr>] [<instance field>]

The **gentree** (generic tree) command prints out a generic tree from the given 
*addr* and *instance field*. The *addr* must be the address of an object in the 
generic tree, and the *instance field* must be the offset into the Generic master 
part of the instance chunk or any instance data within the Generic master 
level which is to be printed. This command is used primarily to ensure correct 
structure of a generic tree and its instance data and to find a particular object 
in the generic tree.The **-i** (implied grab) option is used to find an object by 
placing the mouse over the window in which the object resides and typing the 
following:

    [hello3:0] 7 => gentree -i

The default address that **gentree** examines is contained in *DS:SI. (See Swat 
Display 3-11.) To examine objects more closely, pass the handles displayed by 
**gentree** to the **pobject** command.

----------
**vistree**

    vistree [<addr>] [<instance field>]

The **vistree** (visual tree) command prints out a visual tree from the given 
*addr* and *instance field*. The *addr* must be the address of an object in the 
visual tree, and the *instance field* must be the offset into the Vis master part 
of the object's instance data which is to be printed. This command is 
primarily used to examine the on-screen layout of the application and to 
ensure correct structure of the visual tree and its instance data. The **vistree** 
command can use the **-i** option (implied grab), which will use the window that 
the mouse is over as the first visual object in the printed tree. The default 
address that **vistree** examines is contained in *DS:DI. To examine objects 
more closely, pass the handles displayed by **vistree** to the **pobject** command.

----------
**gup**

    gup [<addr>] [<instance field>]

The **gup** (Generic UPward query) command is used to go up the generic tree 
from a particular object specified by the *addr* argument, the default *DS:SI, 
or the -i option. The -i option (implied grab) uses the windowed object under 
the mouse as the object from which to start the upward query. This command 
is used primarily to ensure correct generic class hierarchy and to determine 
the field of the given object.

----------

**Swat Display 3-11 Gentree and Gup**

    (mess1:0) 19 => gentree -i
     
    GenViewClass (@5, ^l4340h:0020h)
     GenValueClass (@6, ^l4340h:0026h)
     GenValueClass (@7, ^l4340h:0028h)
     
    (mess1:0) 20 => gup @5
     
    GenViewClass (@11, ^l4340h:0020h)
    GenPrimaryClass (@12, ^l4340h:001eh) "MESS #1"
    GenApplicationClass (@13, ^l41b0h:0024h) *** Is Moniker List ***
    GenFieldClass (@14, ^l4080h:001eh)
    GenSystemClass (@15, ^l2460h:0020h)
     
    (mess1:0) 21 => gentree ^l4340h:001eh
     
    GenPrimaryClass (@16, ^l4340h:001eh) "MESS #1"
     GenViewClass (@17, ^l4340h:0020h)
     GenValueClass (@18, ^l4340h:0026h)
     GenValueClass (@19, ^l4340h:0028h) 



----------

**vup**

    vup [<addr>] [<instance field>]

The **vup** (Visual UPward query) command is used to examine the visual 
ancestors of a particular object given by the *addr* argument, the default 
*DS:SI, or the **-i** option. The **vup** command can be used with the **-i** option 
(implied grab) to use the windowed object under the mouse as the object from 
which to start the upward query. This command is used primarily to ensure 
correct visual class hierarchy and to determine the field of the given object.

**3.5.4.3   Memory Examination with Modification**

    assign, imem

The commands in this group are used to modify memory without detaching 
Swat and editing the application code. They are often used in conjunction 
with **istep**, **sstep**, and **pobject** to fix any small errors while the code is 
executing rather than detaching, modifying the actual code, and recompiling. 
These fixes are temporary, and you must change the source code to enact the 
real bug fixes.

----------

**assign**

    assign <addr> <value>

The **assign** command will assign the given *value* to the given *addr*, which can 
only have type **byte**, **word**, or **dword**. Both memory locations and registers 
may be assigned new values. This command is used to correct minor 
mistakes or test differing values at run-time without having to recompile.

----------

**imem**

    imem [<addr>] [<mode>]

The **imem** (inspect memory) command combines examination and 
modification of memory into one command. It can be used to search through 
areas of memory and modify problem areas selectively. The command is used 
to print out memory starting at either the given *addr* or at the default DS:SI 
in one of the following modes:

**b** (bytes)   Displays the memory in terms of bytes.

**w** (words)   Displays the memory in terms of words.

**d** (double words) Displays the memory in terms of double words.

**i** (instructions) Displays the memory in terms of instructions.

There are many subcommands to **imem** which are executed in the same 
manner as those for **istep** and **sstep**. These subcommands are as follows:

**b, w, d, i**  These will reset the mode to the given letter and redisplay the data in 
that mode.

**n, j, `<return>`** (next, jump)
This will advance to the next piece of data using the appropriate step size 
(dependent upon the display mode).

**p, k, P** (previous)
This will retreat to the preceding piece of data. While in instruction 
mode, if the displayed instruction is wrong, try again with the **P** 
subcommand.

**`<space>`**   This will clear the data being displayed and allow you to enter a new 
value in accordance with the current mode. This is exactly like the 
**assign** command except for singly and doubly quoted strings. A singly 
quoted string such as `hello' will have its characters entered into memory 
starting at the current address with no null byte at the end. A doubly 
quoted string such as "good-bye" will be entered into memory at the 
current address with the addition of a null byte at the end of the string. 
This subcommand may not be used in instruction mode.

**q** (quit)    Quits the **imem** mode and returns to the command level.

**Ctrl-d**  Control-d (down) displays ten successive memory elements in the current 
display mode.

**Ctrl-u**  Control-u (up) displays ten of the preceding memory elements in the 
current display mode.

### 3.5.5 Other Important Commands

    alias, mwatch, objwatch, save, switch, sym-default, why

These commands are important to know but do not readily fall into any of the 
previous categories. This section will discuss each of these commands in 
relation to the debugging process.

----------

**alias**

    alias [<name> [<body>]]

This command is normally used to abbreviate a long command or series of 
commands with one single, descriptive command. If no arguments are given, 
then alias will just give a list of all the aliases and the commands they alias. 
The **alias** command is a convenient shortcut for oft used commands or for 
commands that take a long time to type.

If only one argument is given, then **alias** will try to match that argument to 
the command it is aliased to. For example, if the **print** command is aliased 
to **p**, then **alias p** will return **print** as a result. If two arguments are given, 
then **alias** will cause *argument1* to be allowed as an alternative to typing 
*argument2*. For example, if the command **print** were to be aliased as **p**, the 
**alias** command would be used as below:

    [hello:0] 5 => alias p print

Typing **p** will now have the same effect in Swat as typing **print**.

----------

**mwatch**

    mwatch [<message>+]

The **mwatch** (message watch) command watches a particular message and 
displays all deliveries of that message without stopping GEOS. This 
command can help to verify that a particular message is getting sent to all 
the right places and is not sent to any of the wrong places. Up to eight 
messages can be watched at once, and the **mwatch** command with no 
arguments clears all watched messages. Note that some message handlers 
will relay a message on to a superclass' handler; this may make it appear that 
the message is being delivered again, though this is not the case. (See Swat 
Display 3-12.)

----------

**Swat Display 3-12 The mwatch Command**

    (ui:0) 30 => mwatch MSG_VIS_DRAW MSG_META_EXPOSED
    (ui:0) 31 => c
    MSG_VIS_DRAW, ^l2860h:001eh, GenInteractionClass
     cx = 3f80h, dx = 0000h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:001eh, GenInteractionClass
     cx = 3f80h, dx = 0000h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:001eh, GenInteractionClass
     cx = 3f80h, dx = 0016h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:001eh, GenInteractionClass
     cx = 3f80h, dx = 0016h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:002ch, OLGadgetAreaClass
     cx = 3f80h, dx = 3950h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:002ch, OLGadgetAreaClass
     cx = 3f80h, dx = 3950h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:002ch, OLGadgetAreaClass
     cx = 3f80h, dx = 007ch, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:002ch, OLGadgetAreaClass
     cx = 3f80h, dx = 007ch, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:0020h, GenTextClass
     cx = 3f80h, dx = 3950h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:0020h, GenTextClass
     cx = 3f80h, dx = 3950h, bp = 3950h
    MSG_VIS_DRAW, ^l2860h:0020h, GenTextClass
     cx = 3f80h, dx = 3950h, bp = 3950h



----------

**objwatch**

    objwatch [<addr>]

The **objwatch** (object watch) command is used for displaying the messages 
that have reached a particular object. It is useful for verifying that messages 
are being sent to the object at addr. If no argument is given, then any current 
**objwatch** is turned off. (See Swat Display 3-13.)

----------

**Swat Display 3-13 The objwatch Command**

    (mess1:0) 2 => objwatch Mess1View
    brk5
    (mess1:0) 3 => c
    MSG_META_MOUSE_PTR, ^l44a0h:0020h, GenViewClass
     cx = 00afh, dx = 0013h, bp = 0000h
    MSG_META_MOUSE_PTR, ^l44a0h:0020h, GenViewClass
     cx = 00afh, dx = 0013h, bp = 0000h
    MSG_META_WIN_UPDATE_COMPLETE, ^l44a0h:0020h, GenViewClass
     cx = 4b90h, dx = 0000h, bp = 0000h
    MSG_META_MOUSE_PTR, ^l44a0h:0020h, GenViewClass
     cx = 00b0h, dx = 0013h, bp = 0000h
    MSG_META_RAW_UNIV_LEAVE, ^l44a0h:0020h, GenViewClass
     cx = 44a0h, dx = 0020h, bp = 4b90h
    MSG_VIS_DRAW, ^l44a0h:0020h, GenViewClass
     cx = 4b80h, dx = 23c0h, bp = 23c0h
    MSG_VIS_COMP_GET_MARGINS, ^l44a0h:0020h, GenViewClass
     cx = 4b80h, dx = 23c0h, bp = 0000h
    MSG_VIS_DRAW, ^l44a0h:0020h, GenViewClass
     cx = 4b80h, dx = 0163h, bp = 23c0h
    MSG_META_WIN_UPDATE_COMPLETE, ^l44a0h:0020h, GenViewClass
     cx = 4b90h, dx = 0000h, bp = 0000h



----------

**save**

    save <filename>

The **save** command, when passed a file name, saves the contents of Swat's 
main buffer to that file. Thus this command dumps Swat output to a file.

----------

**switch**

    switch [(<patient>:<thread-num>|<threadID>)]

The **switch** command is used to switch between applications or threads in 
Swat but does not physically change threads on the target PC. This allows the 
transfer of debugging control between threads of the same patient. If no 
argument is given, then **switch** will change to the thread executing when 
GEOS was halted. Another way to switch threads is to type the name of the 
patient on the command line. If a patient has more than one thread, type the 
name of the patient, a space, and then the thread number. To change thread 
numbers within a geode, type a colon followed by the thread number to 
change to (e.g. ":1")

----------

**sym-default**

    sym-default [<patient>]

The **sym-default** (symbol default) command is used to set the default 
patient to use when parsing an address expression which is not defined in the 
current patient. For example, if a breakpoint is hit in the kernel and an object 
in the application code needs to be examined, Swat will know to use the 
application as a patient and not the kernel. This command is useful when 
debugging a single patient, the most common way to debug. If no patient 
argument is given, then the name of the default patient will be displayed.

This command is normally aliased to **sd**.

----------
**why**

    why

The **why** command prints the error code for an occurrence of a fatal error. 
This command is useful because it can give a good idea of why GEOS crashed.


### 3.6 Additional Features

This section covers the features of Swat that make it easier to use when 
debugging an application.

+ Mouse support
You can use the mouse to capture and paste text in the main Swat buffer. 
Capture text by click-dragging with the left mouse button. Pressing the 
right mouse button pastes the captured text to the Swat prompt line. 

+ Navigating the Main Buffer
To scroll the main buffer, use Ctrl-u (up), Ctrl-d (down), Ctrl-y (back one 
line), Ctrl-e (forward one line), Ctrl-b (backward page) and Ctrl-f 
(forward page).

+ Command History
By pressing Ctrl-p several times, you can call previous commands up to 
the Swat prompt. If you go past the command that you want, use Ctrl-n 
to go forward in the history.
The `!' character followed by a number repeats that command in the 
command history. (The standard Swat prompt includes a command 
number which may be used for this.) e.g. !184 will execute the 184th 
command of this session.
The `!' character followed by a string will repeat the most recent 
command whose beginning is the same as the passed string. That is !b 
might invoke **brk list** if that was the most recent command that began 
with "b".
Typing "!!" will repeat the previous command; "!$" is the last argument of 
the previous command.

+ Command Correction
To repeat the previous command, but changing a piece of it, use the ^ 
command. This comes in handy when you've made a typo trying to enter 
the previous command. 

----------

**Swat Display 3-14 Command Correction Using ^**

    (geos:0) 185 => wurds
    Error: invoked "wurds", which isn't a valid command name
    
    (geos:0) 186 => ^u^o
    words
    Addr:        +0   +2   +4   +6   +8   +a   +c   +e
    4b4bh: e800 01b1 0e00 60f6 0016 9800 6e02 a900
    
    (geos:0) 187 => ddwords
    Error: invoked "ddwords", which isn't a valid command name
    
    (geos:0) 188 => ^d
    dwords
    Addr:  +0       +4       +8       +c
    4b59h: 1d0aa900 001c400d 294bd000 6c0a8000



+ Address History
Swat has an address history which is composed of tokens for address 
expressions previously used by commands such as print or pobj. The 
elements in the history can be accessed by typing `@<number>` where the 
number argument is the number of the item in the history. These 
elements can replace a full address expression (except constants) and are 
often used when traversing through fields of a previously printed 
structure. The default history keeps track of the last 50 items. (See Swat 
Display 3-15.)

----------

**Swat Display 3-15  The Address History**

    (geos:0) 8 => gentree -i
    
    GenPrimaryClass (@1, ^l44a0h:001eh) "MESS #1"
     GenViewClass (@2, ^l44a0h:0020h)
     GenValueClass (@3, ^l44a0h:0026h)
     GenValueClass (@4, ^l44a0h:0028h)
    
    (geos:0) 9 => pinst @3
    class = ui::dgroup::GenValueClass
    master part: Gen_offset(53) -- ui::GenValueInstance
    @5: {ui::GenValueInstance (^h17568:1170)+53} = {
     GenInstance GenValue_metaInstance = {
     MetaBase Gen_metaInstance = {
     ClassStruct _far *MB_class = 3573h:1867h (motif::dgroup::OLScrollbarClass)
     }
     LinkPart GI_link = {
     void _optr LP_next = ^l44a0h:0028h (ui::dgroup::GenValueClass@6244h:02deh)
     }
     CompPart GI_comp = {
     void _optr CP_firstChild = null
     }
     void _lptr GI_visMoniker = null
     KeyboardShortcut GI_kbdAccelerator = {
     KS_PHYSICAL = 0
     KS_ALT = 0
     KS_CTRL = 0
     KS_SHIFT = 0
     KS_CHAR_SET = 0
     KS_CHAR = C_NULL
     }
     GenAttrs GI_attrs = {}
     GenStates GI_states = {GS_USABLE, GS_ENABLED}
     }
     WWFixed GVLI_value = {0.000000}
     WWFixed GVLI_minimum = {0.000000}
     WWFixed GVLI_maximum = {0.007324}
     WWFixed GVLI_increment = {0.000229}
     GenValueStateFlags GVLI_stateFlags = {GVSF_INDETERMINATE}
     GenValueDisplayFormat GVLI_displayFormat = GVDF_INTEGER
     void _optr GVLI_destination = ^l44a0h:0020h (ui::dgroup::GenViewClass@6244h:01aah)
     word GVLI_applyMsg = 681ah
    } 
    (geos:0) 10 =>



+ Abbreviations
Another shortcut available in Swat is the abbreviation feature. Many 
commands can be specified by their first few characters up to and 
including the letter that makes them distinct from all other commands. 
For example, the **pobject** command can be specified **pobj**, **pob**, or even 
**po**, but not by just **p** because there are other commands (such as **print**) 
beginning with the letter **p**. To get a list of all commands with a given 
prefix, type the prefix at the Swat prompt, then type Ctrl-D. To 
automatically complete a command name use the Escape key (if the 
prefix is unambiguous) or Ctrl-] to scroll through the list of possible 
command completions.

+ Initialization Files
If there are certain Swat commands that always need to be executed 
when Swat is run, then they can be placed in an initialization file. (See 
Swat Display 3-16) An initialization file contains a list of commands that 
will be executed just before the first prompt in Swat.
The initialization file should be called SWAT.RC. Swat will look in the 
directory from which it was invoked for such a file. If it doesn't find one 
there, it will look for a file named SWAT.RC in a directory named in the 
HOME environment variable

----------

**Swat Display 3-16 An Initialization File**

    srcwin 15
    regwin
    save 500
    patient-default mess1
    run
    
This example shows a sample initialization file which sets up windows to display the source code 
and current register values, set the length of the save buffer to 500 lines, and continue running swat 
until the mess1 application has been loaded, at which point execution will automatically stop.

[System Configuration](tconfig.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Swat Reference](tswta_i.md)