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
.ie t \s+2swat\s0\\$1
.el \fBswat\fP\\$1
..
'\"
.de c4
.ie t \s-2Com43\s0\\$1
.el \fBCom43\fP\\$1
..
.ds LF DRAFT
.ds RF DRAFT
.RP
.TL
Swat -- The Manual
.AU
Adam de Boor
.AB
You've seen the TV show, you've used the program, now
comes.\|.\|.\|The Manual. This document will attempt to describe, in
30,000 words or less, how to use and program
.sw .
The first section describes how to invoke
.sw
and what things need to be set up for you to use it. The second
section describes
.sw 's
command language TCL (pronounced ``tickle'') and its peculiarities.
Following that is a description of the format of expressions in
.sw .
Then come descriptions of the commonly-used commands in
.sw ,
as well as other things available from the command line (if that's not
a ``hook,'' I don't know what is).  The final section deals with the
facilities available for writing your own TCL procedures for
programming
.sw .
.AE
.xH Introduction
.PP
.sw ,
as I'm sure you're aware, is the PC GEOS debugger.  It consists of two
parts: the main program, which runs on UNIX and with which you
interact, and a (small) stub program that it uses to access the PC and
generally keep track of things. Because it is running on UNIX, you can
access your source files very easily. Also because it is running on
UNIX, you need two serial lines \*- one going to your terminal and one
going to your PC. More on this later.
.PP
.sw
gets its symbol information from two sources: the .map file that
link86 puts out, and a .tcl file produced by a program called
``asap''\**.
.FS
No, the name doesn't stand for anything. Neither does
.sw
for that matter.
.FE
The creation of these two files is taken care of by the Makefiles you
use, but I figured you should know about them so you don't remove them
in some misguided, civic-minded effort to save space.
.xH 2 Getting Started
.PP
As I mentioned before, you need two terminal lines in this system. In
order to arbitrate between 
.sw ,
which wants to use the line for passing raw data back and forth, and
.c4 ,
which is the terminal-emulator/file transfer program you will be (are)
using to connect the PC to UNIX, you need to be running yet another
program called ``pcwin.'' This other program has the rather nice side
effect of giving you three extra ``windows'' in which you can work
while using the PC as a terminal, but I won't go into that here. For
the purposes of this discussion, it serves mostly as a means to
provide
.sw
the free access to the PC that it requires.
.PP
To load the stub onto your PC, you must have
.c4
on it first. Start it up and log in, then type
.DS I
% \fBpcsend -d/pcgeos /usr/public/swat.exe\fP
.DE
assuming you're putting your pcgeos stuff in \epcgeos, of course. If
you need to download the entire pcgeos system, go to
\fB/staff/pcgeos/Installed\fP and the command
.DS I
% \fBsend -d/pcgeos pc\fP
.DE
if you're using a PC with a hercules card or
.DS I
% \fBsend -d/pcgeos at\fP
.DE
if you're using an AT with an EGA, will send all the files you need
.I except the fonts.
For the fonts, you need to create a \fBfonts\fP directory in your
\fB\epcgeos\fP directory, then go to \fB/staff/pcgeos/FontData\fP and
type
.DS I
% \fBpcsend -d/pcgeos/fonts *.fnt\fP
.DE
.PP
You'll need to know the name of the device to which your PC is
talking, so execute ``tty'' and take note. Once this is accomplished,
you can start up pcwin, then start PC GEOS by typing SysReq-Shift-s
(or ScrollLock-Shift-s on a PC). This will start up 
.sw 's
debugging stub, which will in turn get the kernel up and running.
.PP
Some folks will need to invoke the stub by hand (e.g. if
.c4
is talking to UNIX over COM1 instead of the usual COM2). To do this,
you must get back to the DOS prompt by typing SysReq-q (ScrollLock-q
on a PC), then just type \fBswat\fP, giving the necessary, unusual
arguments. The flags the stub understands are: 
.RS
.IP \fB/s\fP
Doesn't allow the kernel to start running. Useful if you need to debug
something in the kernel's initialization code (if this is the only
flag you need to give, use SysReq-Ctrl-s in
.c4 ).
.IP \fB/c:\fP\fIn\fP
Specifies some other com port to use than COM2. \fIn\fP is \fB1\fP,
\fB2\fP, \fB3\fP or \fB4\fP (these last two aren't supported yet and
\fB2\fP is useless).
.IP \fB/b\fP
Instructs the stub to run at its alternate baud rate. On a PC, this is
19.2Kb. On an AT, this is 9600. The stub will choose the fastest rate
it thinks the machine can handle when it starts up, but this may be
wrong for some machines, hence this flag.
.RE
.PP
Once you've got PC GEOS going on the PC, you can start up 
.sw
on UNIX. In order for
.sw
to talk to the PC, it needs to be told the device to use. There are
two ways to do this. The simple way is to say:
.DS L
% \fBswat -t\fP\fIxx\fP
.DE
where \fIxx\fP is the last two letters of the terminal device name you
found before starting pcwin. The other way is by means of the
\fBPTTY\fP environment variable. This variable contains the full name
of the terminal to which your PC is attached (e.g. ``/dev/ttyi2'').
Doing things this way has three benefits:
.Bp
You don't have to type -t\fIxx\fP all the time.
.Bp
If everyone does it this way, you don't have to keep asking ``What
terminal's your PC on'' whenever you want to show someone a bug.
.Bp
Doing so allows you to invoke ``pcsend'' and ``pcget'' from your other
terminal, as that's what the variable was originally invented for.
.LP
I've just set the variable in my ~/.cshrc file like this:
.DS I
if (! $?PTTY) setenv PTTY /dev/ttyi2
.DE
This will prevent the variable from being overwritten if I ``su'' to
my account on someone else's terminal.
.PP
So, now you've set up your \fBPTTY\fP variable (hint hint) and typed
\fBswat\fP. What's next? The thing will spin for a while, reading in
symbol information (if you don't want it to, you can give
.sw
the \fB-b\fP flag and it will only load in the symbols as it needs
them. Only drawback is it will only recognize threads and applications
as it encounters them).
Finally, it will give you a prompt that looks something like
.DS L
swat (kernel) 1 =>
.DE
and you're ready to debug.
.PP
Before continuing, I should probably tell you how to exit.  Well,
there are three ways: one (``quit'') exits
.sw
and kills PC GEOS at the same time (usually). Another (``quit cont'')
exits, but lets PC GEOS continue running. The final way (``quit
leave'') exits
.sw
and keeps PC GEOS halted. I'm probably the only one who'll use
anything but plain ``quit'', but they're there if you want them.
.PP
One last thing, then I really will shut up about this. When you quit
PC GEOS, if you used the SysReq-Shift-s stuff from 
.c4 ,
you will be automatically reconnected to UNIX.  If you don't get any
response, it's probably because pcwin needs a kick (if you just need
to download stuff, you're better off setting your \fBPTTY\fP variable
(nudge nudge) and using ``pcsend'' from your other terminal). You'll
need to find its process ID, then give it a signal 31 (like this:
``kill -31 \fIpid\fP''). On with the show.
.xH 2 SWAT Helps Those Who Help Themselves
.PP
Arguably, one of the nicest features of
.sw
is its ability to decode the call stack so you know where you are and
where you came from. Since PC GEOS doesn't use a frame pointer (not
enough registers) so common in high-level languages, the stack must be
decoded heuristically. The heuristic itself is simple: work up the
stack, assuming each thing in turn is the return address, and see if
there's a call to the current function in the right place to give that
return address. If so, we've found the top of the frame. In addition,
once the top of the frame is found,
.sw
will look for any registers the function might have pushed onto the
stack and record where they are so it can tell you what the register's
value was in earlier frames. To do all this, however, there are
certain rules you need to follow:
.RS
.Bp
All procedures should be declared PUBLIC so if you're executing in the
function,
.sw
knows it.
.Bp
If you're going to save registers in a function, do it at the
very beginning.
.sw
will look for a prologue\**
.FS
You don't need to worry about this much. In high-level languages, bp
points to the top of the stack frame (the data on the stack specific
to the current function), while [bp] is the top of the caller's stack
frame. Since we don't establish actual stack frames in this way
(except in rare circumstances), this doesn't matter much. But it may
in the future. What's the Boy Scout's motto? Right.
.FE
like
.DS I
.ta \w'push  'u
push	bp
mov	bp, sp
sub	sp, #  ; This may come before the mov
.DE
such as is used by high-level languages, then continue examining
instructions as long as they are register PUSH instructions \*- the
first non-push instruction will terminate the search. The address at
which each register was pushed is recorded and used should the
register's value in an earlier frame be sought.
.Bp
``Falling through'' or jumping into another function isn't a good
idea. The \fBFALL_THRU\fP and \fBGOTO\fP macros (and their companions
\fBFALL_THRU_FAR\fP and \fBGOTO_FAR\fP for falling or jumping into a
FAR procedure), located in ``globlmac.def'' in the Kernel directory,
will do a call/return to the function if error checking is enabled
(\fBERROR_CHECK\fP is \fBTRUE\fP [set by including
\fB\-DDO_ERROR_CHECKING\fP in calls to masm86 in your Makefile]), or
fall into/jump to the function if error checking is disabled. Refer to
the comments in ``globalmac.def'' for more info and exact usage.
.Bp no
If you can't afford the call/return cost even in an error-checking
version, another solution is to make the procedures into a single
large procedure, though this is only feasible if the individual pieces
aren't actually called.
.Bp
Follow the symbol-typing rules in codeConv.doc so you get as much type
information to
.sw
as possible.
.RE
.xH 2 Initialization Files
.PP
If you've got breakpoints you always want set (e.g. at ``FatalError''
in the kernel), or aliases to set up, there are two places you can put
them, both of them files called ``.swat''. The first one to be sought
and read resides in your home directory. This is where I put things I
always want done (like that breakpoint at ``FatalError''). The other
file is in the directory in which you invoked
.sw .
This is meant for patient-specific breakpoints, aliases, etc. These
files are read, in the order mentioned, just before the first prompt is
issued, so as to give you a chance to override anything that's gone before.
.xH TCL
.PP
TCL\**
.FS
This one stands for ``\fBT\fPool \fBC\fPommand \fBL\fPanguage'' \*- I
didn't write it.
.FE
is a cross between lisp and the Bourne and C shells and provides a large
part of the power of
.sw \*-
most of the user-interface is programmed in TCL, for example.
.PP
TCL is a fairly simple language with but one
data-type: strings. All commands, arguments to commands, command
results and variable values are strings. Where commands require
numeric arguments or return numeric results, the arguments and results
are passed as strings. Many commands expect their string arguments to
have a certain form, but this interpretation is up to the
individual command.
.xH 2 Command Strings
.PP
A TCL command string consists of one or more commands separated by
newlines. Each command string is a collection of fields separated by
whitespace. The first field must be the name of a command, while the
remaining fields are arguments to the command. For example,
.DS I
var a 22
.DE
has three fields: the first, \fBvar\fP, is the name of a TCL command;
the last two, \fBa\fP and \fB22\fP, will be passed as arguments to the
var command. These arguments are passed as given (as literal
strings). Individual commands may interpret the strings they are given
in any way they choose. The var command, for example, treats its
first argument as the name of a variable and its second argument as a
string value to assign to that variable.
.xH 2 Using Braces
.PP
Normally, each argument field ends at the next whitespace character,
but curly braces (``{'' and ``}'') may be used to group arguments in
different ways. If an argument field begins with a left brace,
the argument isn't terminated by whitespace or a newline \*- it ends
at the \fImatching\fP right brace. TCL will strip off the outermost
layer of braces before passing the argument to the command. For
example, in the command
.DS I
var a {xyz a {b c d}}
.DE
the var command will receive two arguments: \fBa\fP and \fBxyz a
{b c d}\fP. If the matching right brace isn't on the same line, the
newline(s) between it and the left-brace are included in the argument
(along with any other characters between the two). In many cases, an
argument field to one command consists of a TCL command string that
will be executed later. Braces allow complex command structures to be
built up without confusion. For example, the eval command takes
one argument, which is a command string. eval simply invokes the
TCL interpreter to execute the command string. Thus
.DS I
eval {
	var a 22
	var b 33
}
.DE
will assign the string \fB22\fP to \fBa\fP and the string \fB33\fP to \fBb\fP.
.PP
Braces in TCL act like quotation marks in most other languages in that
they prevent any special interpretation of the characters between the
left brace and the matching right brace. When an argument is in
braces, none of the substitutions normally performed (described in the
section on programming
.sw )
is made \*- all TCL does is strip off the outer layer of braces and
pass the contents to the command.
.PP
Note that braces are only significant in a field if the \fIfirst
character\fP of the field is a left brace. Otherwise, neither left nor
right braces will be treated specially.
.xH 2 Why Should I Care?
.PP
There are various commands that will take only one argument to be an
address expression, but you may need to insert spaces into the
expression (e.g. if you need to give the address a specific type).
I'll discuss address expressions in greater detail later, but when you
need to place spaces in an argument, you'll need to enclose the thing
in braces.
.xH 2 Variable Substitution
.PP
The dollar sign (\fB$\fP) may be used as a special shorthand form for
substituting variables as long as the argument isn't enclosed in
braces. The characters after the $, up to the first character that
isn't a number, letter or underscore, are taken as a variable name and
the string value of that variable is substituted for the name. If the
dollar sign is followed by a left curly brace, the variable name
consists of all the characters up to the next right curly brace. For
example, if the variable \fBfoo\fP has the value \fBtest\fP, then the
command
.DS I
var a $foo.c
.DE
is equivalent to
.DS I
var a test.c
.DE
and
.DS I
var a abc${foo}biff
.DE
is equivalent to the command
.DS I
var a abctestbiff
.DE
.PP
Variable substitution doesn't occur in arguments that are enclosed in
braces: the dollar sign and variable name are passed through in the
argument verbatim.
.xH 2 Backslash Substitution
.PP
Backslashes may be used to insert non-printing characters into command
fields and also to insert braces, brackets and dollar signs into
fields without their being interpreted specially. The backslash
sequences understood by TCL are:
.DS I
.ta +\w'\e<space>   'u
.nf
\fB\eb\fP	backspace (octal 10)
\fB\ee\fP	escape (octal 33)
\fB\en\fP	newline (octal 12)
\fB\er\fP	return (octal 15)
\fB\ef\fP	form-feed (octal 14)
\fB\e{\fP	Left brace (needed for unbalanced \fB{\fP inside a
	quoted argument)
\fB\e}\fP	Right brace (same for \fB}\fP)
\fB\e[\fP	Open bracket
\fB\e]\fP	Close bracket
\fB\e\fP\fIspace\fP	Space, but doesn't terminate argument
\fB\e\e\fP	Backslash
\fB\eC\fP\fIx\fP	Control-\fIx\fP (\fIx\fP & 037) for any ASCII \fIx\fP except \fBM\fP.
\fB\eM\fP\fIx\fP	Meta-\fIx\fP (\fIx\fP | 0200)
\fB\eCM\fP\fIx\fP	Control-Meta-\fIx\fP
\fB\e\fP\fIddd\fP	Up to three octal digits giving the ASCII value for
	the character.
.DE
.xH Address Expressions
.PP
Any command that deals with memory in any way takes the address to use
in the form of an address expression. I call them address expressions
because they're not full-fledged expressions in the sense people are
used to (from high-level languages and all). Rather, they give an
address and the type of data at that address (rather than the type of
the expression).
.PP
An address expression looks sort of like an operand in assembly
language, except all you can do to symbols is add and subtract.
In its simplest form, an address expression is just
.DS I
\fIsymbol\fP
.DE
as long as the symbol implies both a segment and an offset. A
.I symbol
can be either a symbol name or a symbol path, which looks like one of
these:
.DS I
\fIpatient\fP\fB::\fP\fIname\fP
\fImodule\fP\fB::\fP\fIname\fP
\fIpatient\fP\fB::\fP\fImodule\fP\fB::\fP\fIname\fP
.DE
A symbol path is used when there's more than one symbol of a given
name and you need the one that's not the first one found, or if you
need one defined in a different application and don't want to
switch to the other patient (e.g. if you're in the kernel thread and
need the field of a structure defined in the user-interface \*- all
this will become clearer by the end of this manual).
.PP
You can also add or subtract constants from a symbol (subtracting two
symbols in the same segment gives a constant. Just remember that
addition and subtraction are evaluated left to right and you can't add
labels). The type of the expression is the type of the symbol.
.PP
If the symbol is a structure variable, you can refer to its fields as
in the assembler, e.g.
.DS I
applVars.coreSize
.DE
In such a case, the type of the expression is the type of the field
being referenced. Fields can be applied to any expression, be it a
constant, a register or a symbol with a totally different type.
.PP
You can also use registers or straight numbers, as in:
.DS I
0x147d:si
.DE
For now, the default radix for numbers in these expressions is
decimal. All C and MASM radix specifiers are supported, however. In
addition, when entering a hex number using MASM syntax, you don't need
to begin it with a 0 \*- 
.sw
will figure it out.
.PP
As you probably noticed, you can also specify the address as
.DS I
\fIsegment\fP\fB:\fP\fIoffset\fP
.DE
.I Segment
can be a constant, register, module, group or a handle ID given as
.DS I
\fB^h\fP\fIid\fP
.DE
where
.I id
is a constant or register and \fB^h\fP is just that, \fB^\fP followed
by \fBh\fP.
.PP
It is also possible to use the contents of memory anywhere a constant
is allowed by using the `*' and '^' operators, as in
.DS I
\fB*\fP\fIexpr\fP
\fIexpr\fP\fB^\fP
.DE
\fIexpr\fP should either have no type (involves no symbols), have type
byte, word or dword (if \fIexpr\fP has no type, it is treated as
having type word), or be a pointer of some form. For byte and word
expressions, the result has the offset found in that byte/word, but
its segment is the same as that for \fIexpr\fP.
.PP
If the expression is a dword, the memory is taken to contain a FAR
pointer and the expression's value is that pointer. The type of such
indirection (either near or far) is undefined. Note that if \fIexpr\fP
has no segment, the memory reference is absolute. If \fIexpr\fP refers
to a pointer, the result has the type of the thing pointed to. The
type of indirection performed depends on the type of pointer. The
various types are detailed in Spec/codeConv.doc, so I won't go into
them here, except to say that, like indirecting through a word,
expressions that indirect through an lmem or near pointer have the
same segment as the pointer itself.
.PP
The difference between the \fB*\fP and \fB^\fP operators lies in their
precedence, as indicated below (\fB^\fP binds more strongly than
\fB*\fP, so you can use it, for instance, to extract a handle ID from
a variable for use with the \fB^l\fP operator, described below).
.PP
One other operator exists to make life easier when dealing with
objects: \fB^l\fP takes an address expression composed of a global
memory handle id (as the segment) and a local memory handle id (as the
offset) and figures the actual address of the memory pointed to by
that combination. Thus if, as is usual with objects, you've got a
handle ID in BX (0d30h located at 7fe0h, say) and the local memory
handle c4h (whose chunkAddr is 130h) in SI, \fB^lbx:si\fP will refer
to address 7fe0h:130h.
.PP
The possible operators in an address expression are thus ranked as
follows (from highest precedence to lowest):
.DS C
^h
\&.
^
+ -
^l
:
*
.DE
Parentheses may be used to alter the order of evaluation in the normal
manner.
.PP
The other component of an address expression is the type of data
stored at the address. In some cases (when you use symbols or fields),
the type is implicit in the expression. In others, however, you need
to supply the type. This is done by placing the name of the desired
type at the start of the expression, followed by a space (so the
expression will require {}'s for most commands). Thus
.DS I
VisInstance ^lbx:si
.DE
will treat the memory at the address as a \fBVisInstance\fP structure.
.DS I
*(dword cs:36h)
.DE
will use the four bytes at \fBcs:36h\fP as a FAR pointer and result in
an expression whose address is that pointer and whose type is undefined.
.xH 2 Value History
.PP
.sw
also has something known as the ``value history'' (``address history''
for purists) that is accessed in address expressions by preceding the
number of the element in the history to be accessed with an @ sign,
e.g.
.DS I
@23
.DE
Addresses are entered into the value history by the \fBprint\fP
command, which is described below. A history element can be used in
almost any part of an address expression (except where a constant is
expected) and is typically used to indirect through one of the fields
of a structure just printed.
.PP
History elements can also be referenced in a relative way, with
\fB@\fP referring to the most-recently-printed item, \fB@-1\fP
referring to the item before that, and so on.
.PP
The history holds the most-recent 50 items.
.xH Common Commands
.PP
While
.sw
has over 100 commands you can use, most of them exist only to give
access to
.sw 's
internal data structures, allowing you to define your own commands.
This section describes the most commonly-used commands and what they
do. For most of these commands, you can type just an unique
abbreviation (e.g. \fBc\fP for ``cont''). Some must be typed exactly,
so more-often used commands can have shorter abbreviations. Those
commands that must be typed exactly are followed by a dagger, like
this: \(dg
.PP
In this documentation and in usage messages, the following conventions
have been more or less followed:
.IP ()
enclose a set of alternatives. The alternatives are separated by |'s
.IP []
usually enclose optional elements, except in fairly obvious cases
where they imply a character class (e.g. for the ``frame'' command)
.IP <>
enclose "non-terminals", i.e. a type of argument, rather than a
string to be typed as shown (e.g. \fB<addr>\fP means an address
expression, whereas \fB(addr|biff)\fP means either the string \fBaddr\fP
or the string \fBbiff\fP).
.LP
`*' following one of these constructs means 0 or more of the thing, while `+'
means 1 or more.
.PP
Several convenience features (sounds like something for an appliance,
doesn't it?) are available to you from
.sw 's
command line. 
.PP
.sw
can complete a symbol much as the C Shell does for files. Typing
control-D in the middle of a symbol (doesn't understand about symbol
paths yet) will give you a list of the symbols for which all the
characters back to the first non-symbol character (not a letter, number,
underscore, `@' or `?') are a prefix. Typing escape will insert as
many characters from the possible symbols as are common among them. If
the prefix matches more than one symbol,
.sw
will beep at you when it has completed it as far as it can. Finally,
typing control-] allows you to cycle through the possible completions
for the prefix.
.PP
.sw
also maintains a history of the lines that have scrolled off the top
of the main window. This buffer defaults to holding 1000 lines, but
this can be increased or decreased at need. You can move around in the
buffer using most of the regular cursor-motion control characters from
``vi'' (you can't use the arrow keys, though). In case you're not
familiar with ``vi'', the characters are as follows (in this case, `^'
means `control'):
.RS
.sp \n(PDu
.nr @p \n(PD
.nr PD 0
.IP ^B
Goes back a single screen.
.IP ^F
Goes forward a screen.
.IP ^U
Goes back half a screen.
.IP ^D
Goes forward half a screen.
.IP ^Y
Goes back a single line.
.IP ^E
Goes forward a single line.
.nr PD \n(@p
.RE
.LP
If you type any character but these six while examining the scroll
buffer, 
.sw
will return you to the bottom (the prompt), accepting the character
you typed as input.
.PP
Lastly, certain commands allow you to type just <return>,
.sw
to repeat them. Those that do are so noted in the descriptions below.
.PP
Now for the commands themselves.
'\" ==============================================
.xH 2 apropos [-k] \fIpattern\fP+
.PP
This will tell you what help topics match a set of patterns (as you
may have noticed, there's a rather large number of them; this is one
way to narrow down your search). The pattern consists of wildcards
just as are used for filenames in the shell. To refresh your memory,
.RS
.nr q \w'\fB[\fP\fIchars\fP\fB]\fP   'u
.IP \fB*\fP \nqu
means zero or more of any character.
.IP \fB?\fP \nqu
means any single character.
.IP \fB[\fP\fIchars\fP\fB]\fP \nqu
means any single character in the set \fIchars\fP, which can be
specified as single characters (\fBc\fP, e.g.), a range of characters
(\fB0-9\fP), or a combination of the two (\fB-+0-9\fP). If `\-' is to
be in the set, it must be given first. Finally, if the first character
of the set is `^', the sense is reversed \*- it will match any single
character \fInot\fP in the set.
.RE
.PP
Normally, this will compare the given patterns against the actual
topic names. If the first argument is \fB-k\fP, though, the search
will be made in the descriptions themselves, rather than their names.
In this case, one of the patterns need only appear somewhere in the
description for the topic name to be shown (i.e. each \fIpattern\fP is
converted into \fB*\fP\fIpattern\fP\fB*\fP for the search).
'\" ==============================================
.xH 2 alias [\fIword\fP [\fIcommand\fP]]
.PP
Allows you to define commands in terms of other commands without going
to the full extent of writing a TCL command procedure. It takes two
arguments. The first is the word to alias (when invoked, the word must
be typed exactly, unlike most commands in
.sw ),
and the second is the string to which it should be aliased.  The
pseudo-variables $1, $2, ..., $\fIn\fP may be used to interpolate the
1st, 2nd, ..., nth argument to the alias. $\fIn\fP-\fIm\fP will
interpolate arguments \fIn\fP through \fIm\fP. If \fIm\fP is missing,
all arguments from \fIn\fP to the end will be interpolated. $* will
interpolate all the arguments, while $# will interpolate the actual
number of arguments.  This substitution only occurs in the alias
itself, not within any procedures the alias calls.  If you don't use
any of the $\fIn\fP constructs, all the arguments will be appended to
the resulting command before it is executed.
.PP
If no alias string is given, the alias for the given word is printed.
If no word is given, all aliases are printed.
'\" ==============================================
.xH 2 assign \fIaddress\fP \fIvalue\fP
.PP
Used to modify memory or registers. This takes two arguments. The
first is either an address expression or a register to which the value
is to be assigned. The second is similarly an address expression, but
only the necessary part of it is used (and its type is ignored). Thus,
you can say things like
.DS I
swat (kernel) 1 => \fBassign ip InitGeos+4\fP
.DE
and the offset part of \fBInitGeos+4\fP will be assigned to the
register \fBip\fP. Similarly
.DS I
assign (^lbx:si).Inst_class VisClass
.DE
will assign the segment and offset of \fBVisClass\fP to the
\fBInst_class\fP field (a double-word) of the indicated object
instance. If the address has no type, 
.sw
assumes it takes a word.
'\" ==============================================
.xH 2 attach
.PP
Re-establishes the link to the PC, reading the symbols for any patient
that changed since you detached from the PC.
'\" ==============================================
.xH 2 backtrace [\fInumFrames\fP]
.PP
This is the function that prints out the current call stack. It takes
a single argument (the maximum number of frames to print). Both
\fBw\fP and \fBwhere\fP are aliased to this by the system.
'\" ==============================================
.xH 2 brk \fIargs\fP
.PP
This is the interface to
.sw 's
breakpoint system and is meant to be used both when programming
.sw
and from the keyboard. As such, it is structured a bit differently
than most other commands, taking one of a series of subcommands, as:
.DS I
\fBbrk\fP \fIsubcommand\fP \fIother args\fP
.DE
The available subcommands are:
.RS
.IP "\fBset\fP \fIaddr\fP \fIcommand\fP
Sets a breakpoint at the given address to execute the given TCL
command(s). \fIcommand\fP is passed straight to ``eval.'' Before it is
evaluated, the variable \fBbreakpoint\fP is set to the name of the
breakpoint being taken. If no \fIcommand\fP is given, the breakpoint
is always taken. Otherwise, the machine stops only if the result
of the command is non-zero. The breakpoint will only stop threads
belonging to the current patient. A breakpoint is identified by a
string of the form \fBbrk\fP\fIn\fP, where \fIn\fP is an unique integer.
.IP "\fBaset\fP \fIaddr\fP \fIcommand\fP
Like \fBset\fP, but the breakpoint is set for all threads.
.IP "\fBtset\fP \fIaddr\fP \fIcommand\fP
Like \fBset\fP, but the breakpoint is removed the next time the machine
stops.
.IP "\fBclear\fP \fIbreak\fP*
Removes the given breakpoint(s), which may be specified either as
\fBbrk\fP\fIn\fP tokens (as displayed by the \fBlist\fP subcommand and
returned when you set the breakpoint) or a number (the \fIn\fP in
\fBbrk\fP\fIn\fP). If no breakpoints are given, clears all breakpoints
for the current patient. Asks for confirmation before doing so.
Both \fBdel\fP and \fBdelete\fP are aliased to this.
.IP "\fBenable\fP \fIbreak\fP*
Enables the given breakpoint(s). If already enabled, this has no
effect. If no breakpoints are given, all breakpoints for the current
patient are enabled. Both \fBen\fP and \fBenable\fP are aliased to this.
.IP "\fBdisable\fP \fIbreak\fP*
Disable the given breakpoint(s). Has no effect if already disabled. If
no breakpoints are given, disables all breakpoints for the current
patient. Both \fBdis\fP and \fBdisable\fP are aliased to this.
.IP "\fBlist\fP          "
Lists all breakpoints, where they are set and if they are enabled. The
\fBj\fP command is aliased to this by the system.
.RE
.LP
If no recognizable subcommand is given, \fBset\fP is assumed. In this
case, the first argument is taken to be the address and the (optional)
second argument to be the command to execute. As before, if the second
argument is missing, the breakpoint is made unconditional.
'\" ==============================================
.xH 2 bytes [(\fIaddr\fP|nil) [\fInumBytes\fP]]
.PP
Displays memory as a series of bytes, both in hexadecimal and in
ASCII. The first argument is the address at which to start the
display. If no argument is given, or the argument is \fBnil\fP, the
display starts just after the last location accessed using either
\fBbytes\fP, \fBwords\fP, \fBibrk\fP or \fBlisti\fP since the machine last
stopped. If you haven't accessed memory using these commands since the
machine stopped, the address defaults to \fBcs:ip\fP. The second
argument is the number of bytes to display, which defaults to 16.
.PP
If you enter just <return> for the next command, you will be shown the
next \fInumBytes\fP bytes.
'\" ==============================================
.xH 2 call \(dg \fIfunction\fP ((\fIreg/var\fP|push) \fIvalue\fP)*
.PP
Issues a call to a function in the current thread's context (the
thread need not be awake, but it can't be an application thread that's
retreated into the kernel). First argument is the function to call
(which must be an actual function symbol, not an address expression
[i.e. \fBTimerGetCount\fP is ok, but \fBWinMoveResize+5\fP is not]).
Successive arguments are pairs to be passed to the ``assign'' command
(\fIvariable/register\fP \fIvalue\fP) with the exception that if the
\fIvariable\fP is \fBpush\fP the \fIvalue\fP (a word) is pushed onto
the stack before the return address. The current registers are saved
away before the call is made, but any variables modified by the called
function will remain modified.
.PP
If the function being called is a NEAR function, the thread must
already be executing in the function's segment. If the function's
module isn't loaded,
.sw
will attempt to load it.
.PP
When the call completes, you will be left in a sub-interpreter (the
prompt grows a \fInumber\fP\fB:\fP to its left to tell you at what
level you're operating) from which you can examine the results of the
call. When you type \fBbreak\fP, the previous registers will be
restored and you'll be returned to the next level up (usually the top,
unless you're really twisted).
.PP
If the call doesn't complete successfully (the machine stops for some
other reason), the saved registers are discarded and you are warned
that bad things may happen. In particular, 
.sw
won't be able to decode the stack above the function you called. If
you allow the machine to continue, it will eventually get back on
track unless the function you called actually messes with any
important registers, in which case you're out of luck.
.PP
Be careful when calling functions that cause the thread to exit.
.PP
Other threads are allowed to run while the call is being made.
'\" ==============================================
.xH 2 cont
.PP
Continues the machine and waits for it to stop again.
'\" ==============================================
.xH 2 dbg \(dg [\fIdbgFlag\fP]
.PP
Sets/gets 
.sw 's
internal debug flag. When the flag is set, various pieces of debugging
information (e.g. what is happening to the blocks in which
.sw
has expressed an interest) are printed. In addition, if you should be
asked
.DS I
Do you want to abort?[yn](y)
.DE
while the debug flag is set,
.sw
will dump core if you answer yes. This returns the current state of
the flag.
'\" ==============================================
.xH 2 detach [(cont|leave)]
.PP
Detaches from the PC, destroying PC GEOS unless either \fBcont\fP or
\fBleave\fP is specified. If \fBcont\fP is given, GEOS is allowed to
continue from where it left off. If \fBleave\fP is given, the PC
remains stopped.
'\" ==============================================
.xH 2 display (del|list|\fInumLines\fP \fIcommand\fP)
.PP
Used to create a window whose contents are updated each time the
machine stops. The first argument is the number of lines required,
while the second is the command to execute to update the window. In
addition, if the first argument is \fBlist\fP, the currently-active
windows are listed. If the first argument is \fBdel\fP, the given
windows are deleted (a window is identified by the number on the line
printed by the \fBlist\fP subcommand). This only works when using 
.sw
with an interface that supports windows.
'\" ==============================================
.xH 2 down [\fInumFrames\fP]
.PP
Shifts the current frame down the given number of frames, displaying
the instruction to be executed next in that frame. 
.sw 's
working directory is shifted to be the one in which the executable
(.exe or .geo file) of the patient to which the code belongs was
found. In addition, 
.sw
notices when registers are pushed (if the pushing is done at the start
of the function) and records their resting place so it can tell you
the value of a register in an earlier frame. Thus changing the current
frame may change the value of some registers.
'\" ==============================================
.xH 2 echo \(dg [-n] \fIstring\fP*
.PP
Takes as many arguments as you want and prints them (separated by
spaces) to the current window. A newline is issued at the end of the
arguments unless the first argument is \fB-n\fP.
'\" ==============================================
.xH 2 exec \(dg \fIarg\fP*
.PP
Takes its arguments as a shell command to execute, executes it and
returns its output (this means you can't redirect the output to a
file). Useful mostly for things like ``rm'' or editing a variable
with ``sed''.
'\" ==============================================
.xH 2 expr \(dg \fIexpression\fP
.PP
This is another TCL primitve that can be useful. It takes a normal,
C-like expression and returns the result. It doesn't know about
symbols or anything, but by combining it with the \fBread-reg\fP
command, you can extend the power (what there is of it) of address
expressions. For example,
.DS I
bytes ds:[expr {([read-reg bx]+3)*14}]
.DE
'\" ==============================================
.xH 2 exit \(dg [\fIcode\fP]
.PP
Takes an (optional \*- defaults to 0) exit code as an argument and
calls ``ThreadExit'' with it. This be a dangerous thing to do.
'\" ==============================================
.xH 2 finish [\fIframeNum\fP]
.PP
Lets the machine run until it finishes executing the given frame (or
the current one if none given). Frames are referred to by the number
printed for them by the \fBbacktrace\fP command.
'\" ==============================================
.xH 2 format \(dg \fIformat-string\fP \fIarg\fP*
.PP
Still another useful TCL primitive. Its first argument is a format
string like that used for the C function \fBsprintf\fP. Other
arguments are formatted according to the format string. Thus
.DS I
format %x 4286
.DE
will give you 4286 formatted as a hexadecimal number.
'\" ==============================================
.xH 2 frame \fIframeNum\fP
.PP
Takes a frame number as its argument and sets the current frame to the
indicated one. Also, if the argument is \fBinfo\fP,
.sw
will tell you various things about the current frame, such as from
where it is getting the values for various registers while in that
frame.
'\" ==============================================
.xH 2 func [\fIfunction\fP]
.PP
If given no argument, returns the name of the function in the current
frame. Otherwise makes the first frame (from the top of the stack)
executing the given function be the current frame.
'\" ==============================================
.xH 2 geosfiles \(dg
.PP
This is a simple procedure that prints out the kernel's file-handle
table.
'\" ==============================================
.xH 2 go \fIbreak-addr\fP*
.PP
Continues the machine as for \fBcont\fP, but also takes any number of
addresses and sets temporary breakpoints for the current patient at
them. When the machine next stops, the breakpoints are removed. E.g.
.DS I
go HandleExit MyDocDraw
.DE
will continue the machine after setting breakpoints at HandleExit and
MyDocDraw. When the machine stops again, the breakpoints will vanish
(unless, of course, you've got permanent breakpoints there).
'\" ==============================================
.xH 2 gloss \(dg \fIterm\fP
.PP
Looks up a term in the PC GEOS glossary, printing out any and all
definitions for the \fIterm\fP (which may contain spaces, as in
\fBcore block\fP). Also gives synonyms, the spec file in which the
term is more extensively defined, an example of the term's use, and
related terms it might be helpful to look up.
'\" ==============================================
.xH 2 help [\fItopic\fP [\fIdocumentation\fP]]
.PP
Provides you with help. If you don't give it any arguments, it prints
the (long) list of topics it knows. If you give it a single argument,
it prints the help stored for that topic. If you give it two
arguments, it registers the second as the help for the first so if you
type ``help \fItopic\fP'', the \fIdocumentation\fP will be printed.
'\" ==============================================
.xH 2 history (\fInumCmds\fP|set \fInumSaved\fP)
.PP
Prints a list of recently-execute commands, as for the C shell (the
history mechanisms are almost identical). The number of commands saved
can be changed by giving the first argument as \fBset\fP \*- the
second argument is the number of commands to save.
'\" ==============================================
.xH 2 hwalk [-pef] [(\fIpid\fP|\fIpatient-name\fP)]
.PP
A command procedure that prints out the state of active memory
handles. Flags, if given, are grouped together in the first argument.
The available flags and their meanings are:
.RS
.IP \fBp\fP
Prints the nextPtr and prevPtr fields for each handle.
.IP \fBe\fP
Performs error-checking, making sure the heap is consistent.
.IP \fBf\fP
Does a fast traversal, not bothering to try and figure the type of
each block.
.RE
.PP
If a \fIpid\fP (handle ID of a process) or a \fIpatient-name\fP is
given, only those handles for the given patient are printed.
'\" ==============================================
.xH 2 ibrk \fIstart-addr\fP
.PP
This is an interactive front-end to the \fBbrk\fP command (all
commands that are ``interactive'' in this way begin with the letter
`i'). It takes a starting address (same as for \fBbytes\fP command if
no address given) and displays instructions starting at that point. After
each instruction you have a choice of commands:
.RS
.IP "\fBn\fP or \fIreturn\fP" 2
Advances to the next instruction.
.IP \fBp\fP 2
Goes back to the preceding instruction. If it hasn't been to the
previous instruction, it applies a simple heuristic to find it.
Sometimes that heuristic fails, however, showing you garbage or
displaying the same instruction over and over again,
in which case you should use.\|.\|.
.IP \fBP\fP 2
Picks up where the preceding \fBp\fP left off, trying to find an
instruction that will fit in the same manner.
.IP \fBb\fP 2
Sets a breakpoint for the current patient at the instruction and exits.
.IP \fBa\fP 2
Sets a breakpoint for all patients at the instruction.
.IP \fBt\fP 2
Sets a temporary breakpoint for the current patient.
.IP \fBB\fP 2
Like \fBb\fP, but prompts for a command to execute when the breakpoint
is hit. If the result of the command is non-zero, the machine remains
stopped.
.IP \fBA\fP 2
Like \fBa\fP, but prompts for a command, as above.
.IP \fBT\fP 2
Like \fBt\fP, but prompts for a command.
.IP \fBq\fP 2
Exits without setting a breakpoint.
.RE
.PP
If you enter just <return> for the next command, \fBibrk\fP will pick
up where you left off.
'\" ==============================================
.xH 2 istep [\fIdefault-cmd\fP]
.PP
Interactive single stepping. Like \fBibrk\fP, it prints the
instruction about to be executed, then prompts for a command. Accepts
a single argument, which is the command to execute if \fIreturn\fP is
hit.  The possible commands are:
.RS
.IP \fBq\fP 2
Stops stepping, returning to command level without executing the
printed instruction.
.IP \fBc\fP 2
Stops stepping, allowing the machine to continue. Returns to command
level when the machine stops again.
.IP \fBn\fP 2
Continues to the next instruction, skipping procedure calls and
repeated string instructions. Note that if the current instruction is
actually a procedure call or repeated string instruction, this may
allow other threads to run, which is not true of just a single step.
The breakpoint set will only be taken when the thread has returned to
the same frame in which it was executing when the breakpoint was set.
I.e. if you give the \fBn\fP command inside a recursive function, it
won't stop in the recursive call unless it hits some other breakpoint.
.IP "\&" 2
This command can also be used to step over software interrupts.
.IP \fBf\fP 2
Finishes out the current stack frame.
.IP \fBs\fP 2
Executes the current instruction. This will step into the interrupt
routine if the instruction executed is a software interrupt.
.IP \fBg\fP 2
Like the \fBgo\fP command, prompts for places at which to set
temporary breakpoints, then allows the machine to continue, returning
to \fBistep\fP when the machine stops (unless it stops in some other
thread). Unfortunately, there's no symbol completion and you can't
change your mind \*- once you've given the \fBg\fP command, you're
committed.
.RE
.PP
If you perform \fBistep\fP while
.sw 's
idea of the current patient differs from the PC's, \fBistep\fP will
wait for the current patient to wake up before showing you the first
instruction to be executed.
'\" ==============================================
.xH 2 listi [(\fIaddr\fP|nil) [\fInumInst\fP]]
.PP
Displays memory as machine instructions. Takes the same sort of
arguments as the \fBbytes\fP command, which see. Unfortunately, you
can't invoke this as just \fBlist\fP as that's the name of a (useful)
TCL primitive. For this reason, \fBl\fP and \fBli\fP have been aliased
to this by the system.
.PP
If you enter just <return> for the next command, the next
\fInumInst\fP instructions will be displayed for your edification.
'\" ==============================================
.xH 2 ls \fIarg\fP*
.PP
Like the UNIX command, but takes a bit longer. Remember that 
.sw
changes to the directory in which it found the patient whose function
is active in the current frame.
'\" ==============================================
.xH 2 phandle \fIhandle-id\fP
.PP
Given a global handle ID, prints pertinent information about the
handle with that ID (the information is taken entirely from the PC \*-
not from
.sw 's
data structures).
'\" ==============================================
.xH 2 pmake \(dg [\fIflags\fP]
.PP
Executes pmake for the current patient.
'\" ==============================================
.xH 2 print [-xdocCaApP] \fIaddress-expression\fP
.PP
Prints the value of a variable/address expression. If the expression
has no type and no segment (eg it's a register), the offset is printed
both in hex and in decimal. If it has no type, but does have a
segment, it is printed as \fIsegment\fP:\fIoffset\fP, both in hex.
Otherwise, the data are fetched from the PC and formatted
appropriately. Four variables control how data are formatted. They
are:
.RS
.IP \fBbytesAsChar\fP
If non-zero, all bytes are printed both as characters and integers (or
as characters only if the byte is in an array).
.IP \fBdwordIsPtr\fP
If non-zero, all double-words are assumed to be far pointers and are
printed as \fIsegment\fP:\fIoffset\fP.
.IP \fBintFormat\fP
This is a printf-like string used to print integers (bytes, words or
dwords).
.IP \fBalignFields\fP
If non-zero, the values for the fields of a structure are lined up.
.IP \fBnoStructEnum\fP
If zero, the names of all structure or enumerated types will be
preceded by \fBstruct\fP or \fBenum\fP, respectively. This defaults to
non-zero (the type name is given unembellished).
.RE
.PP
You can use these four variables to set your general preferences. In
addition, \fBprint\fP accepts several flags that allow you to change
their values on the fly:
.RS
.sp \n(PDu
.nr @p \n(PD
.nr PD 0
.IP \fBx\fP
print integers in hex.
.IP \fBd\fP
print integers in decimal.
.IP \fBo\fP
print integers in octal.
.IP \fBc\fP
sets bytesAsChars true.
.IP \fBC\fP
sets bytesAsChars false.
.IP \fBa\fP
sets alignFields true.
.IP \fBA\fP
sets alignFields false.
.IP \fBp\fP
sets dwordIsPtr true.
.IP \fBP\fP
sets dwordIsPtr false.
.nr PD \n(@p
.RE
.LP
These flags may only be given (grouped together if multiple flags are
given) if preceded by a `-' as the first argument.
.PP
If the expression to print contains the most-recent history token
(\fB@\fP), \fBprint\fP will set itself to repeat should you type just
<return>, thus allowing you to work down a linked list quickly.
'\" ==============================================
.xH 2 ps [-pht]
.PP
Prints status information from
.sw 's
internal data structures. Takes a single flag, which is \fB\-p\fP to
print out processes, \fB\-t\fP to print out threads, and \fB\-h\fP to
print out the handles in which
.sw
is interested.
'\" ==============================================
.xH 2 pthread \fIhandle-id\fP
.PP
Takes a thread's handle ID as its argument and prints out information
about that thread from the PC's memory.
'\" ==============================================
.xH 2 quit \(dg [(cont|leave)]
.PP
If no argument is given, exits
.sw ,
causes PC GEOS to exit to MS-DOS as well (most of the time), and gives
pcwin the required kick to let you reconnect to UNIX from the PC, if
desired.  If the first (and only) argument is \fBcont\fP, PC GEOS is
allowed to continue while
.sw
exits. Finally, if the argument is \fBleave\fP, the PC remains halted
right where it was.
allows the PC to continue (the PC can be stopped again by
reinvoking
.sw ).
'\" ==============================================
.xH 2 ref \(dg [\fIfunction\fP]
.PP
Looks up and prints a shortened version of the procedure header for
the given function. If no function is given, the function in the
current frame is used. The procedure header must conform to one of the
two standards set forth in Doc/Forms/pheader[12].
'\" ==============================================
.xH 2 regs
.PP
Prints out the values of all registers in the current frame.
'\" ==============================================
.xH 2 regwin
.PP
Creates a 2-line window to display the registers each time the machine
stops. Registers that have changed since the last stop are
highlighted. The current flags aren't shown. You can use the
``display'' command to remove the window.
'\" ==============================================
.xH 2 ret [\fIfunction\fP]
.PP
Allows the machine to continue until the patient has returned from the
first frame executing the function given as the argument. If no
argument given, the top-most frame is assumed (in this case, \fBret\fP
functions the same as \fBfinish\fP).
'\" ==============================================
.xH 2 save \(dg \fInumLines\fP
.PP
Lines that scroll off the top of the main window are saved in a scroll
buffer whose length defaults to 1000 lines. It may be
enlarged or shrunk using this command \*- the number of lines it
should be is given as the argument.
'\" ==============================================
.xH 2 smatch \fIclass\fP \fIpattern\fP
.PP
Prints all symbols of a specific type matching a pattern. The type is
the first arg and consists of a mix of the following, separated by
`|'s:
.RS
.nr @p \n(PD
.nr PD 0
.nr q \w'\fBmodule   \fP'u
.IP \fBvar\fP \nqu
variables
.IP \fBmodule\fP \nqu
modules
.IP \fBfunc\fP \nqu
functions/procedures
.IP \fBlabel\fP \nqu
labels
.IP \fBtype\fP \nqu
type definitions (structures, records, eg)
.IP \fBenum\fP \nqu
enumerated constants
.IP \fBabs\fP \nqu
absolute symbols (public constants)
.IP \fBany\fP \nqu
any of the above.
.nr PD \n(@p
.RE
.LP
The second argument is the pattern to match and may contain regular
shell wildcard characters.
'\" ==============================================
.xH 2 spawn \fIpatient-name\fP [\fIbreak-addr\fP]
.PP
Waits for a thread or process for a patient of a given name to be
spawned, then sets a breakpoint for the patient at an address and
allows the machine to continue. The first argument is the patient to
wait for (it is actually a pattern to which `*' is appended so you
needn't try to figure out the exact name of the patient in which
you're interested). The second argument is the address at which to set
the breakpoint (which is temporary). If no second argument is given,
the machine is stopped as soon as a new thread/process of the given
name is started. You are left with the new thread as the current
thread (though this may not reflect reality).
'\" ==============================================
.xH 2 step
.PP
Non-interactive version of \fBistep\fP \*- just executes a single
instruction and returns.
'\" ==============================================
.xH 2 switch [([\fIpatient\fP][:\fIthreadNum\fP]|\fIthread-id\fP)]
.PP
Switches 
.sw 's
focus of attention to another patient or thread.  Takes a single
argument of the form \fIpatient\fP\fB:\fP\fIthread-num\fP or
\fIthreadID\fP. With the first form, \fB:\fP\fIthread-num\fP is
optional \*- if the patient has threads, the first thread is selected.
To switch to another thread of the same patient, give just
\fB:\fP\fIthread-num\fP.  You can also switch to a patient/thread by
specifying the thread handle ID.  \fBNOTE\fP: The switch doesn't
happen on the PC \*- just inside
.sw .
If you don't give an argument, it switches to the actual
current thread in the PC.
'\" ==============================================
.xH 2 sysfiles \(dg
.PP
Prints all the files open in the entire MS-DOS system. Likely to be
the same as that printed by \fBgeosfiles\fP.
'\" ==============================================
.xH 2 threadstat
.PP
Prints the status of the threads based on GEOS's own data structures,
not
.sw 's.
This includes all known threads, the run queue, and threads blocked
the dos, heap and geode semaphores.
'\" ==============================================
.xH 2 unalias \fIword\fP*
.PP
Removes an alias (or aliases). Can also be used to delete a TCL procedure.
'\" ==============================================
.xH 2 up [\fInumFrames\fP]
.PP
The opposite of \fBdown\fP...but you knew that.
'\" ==============================================
.xH 2 var \(dg (\fIvarName\fP|(\fIvarName\fP \fIvalue\fP)+)
.PP
Sets TCL variables. The arguments come in pairs. The first is the name
of the variable to set and the second is the string to which to set
it. If only one argument is given, \fBvar\fP returns the value of the
variable.
'\" ==============================================
.xH 2 vi [\fIarg\fP+]
.PP
Takes arguments as in UNIX. If no arguments given, edits the file
containing the function in the current frame, positioning the cursor
at the start of that function.
'\" ==============================================
.xH 2 wakeup [([\fIpatient\fP][:\fIthreadNum\fP]|\fIthread-id\fP)] 
.PP
Takes an argument as for the \fBswitch\fP command and waits for that
thread to wake up. If you don't give an argument, it waits for the
current thread to wake up. If the current thread is already awake,
this happens to be the same as ``finish''.
'\" ==============================================
.xH 2 whatis (\fIsymbol\fP|\fIexpression\fP)
.PP
Takes a symbol on which to elaborate, or an expression whose type is
desired and provides detailed information on same.
'\" ==============================================
.xH 2 words [(\fIaddr\fP|nil) [\fInumWords\fP]]
.PP
Displays memory as words. Takes arguments as for the \fBbytes\fP
command, but rounds the address down to an even address (warns you if
it does this). The words are displayed only in hex.
.PP
If you type <return> for the next command, you will be shown the next
\fInumWords\fP words in memory.
.xH Programming SWAT
.PP
This section isn't meant to be an introduction to TCL (for that I've
got another document), but rather to tell the interested reader about
the data structures in
.sw ,
structures you'll need to use to add neat commands of your own.
.xH 2 Design
.PP
The functions with which
.sw
provides the programmer are called ``primitives'' by Those In The
Know. This name is not merely to be different \*- they're called
primitives because they're primitive. In most cases you'll need to
tie several of them together in order to get the information you want.
Happily, this sort of thing is supported well by TCL.
.xH 2 The Data Structures
.PP
There are six major data structures active in
.sw ,
all of which are exported to you in the form of tcl primitives. All
these primitives work in pretty much the same way: each has a series
of subcommands, given as its first argument. One of these
subcommands is used to map from a string or address into a token for
an element of the data structure, which token then gets passed to the
other subcommands to access the different portions of the structure.
For example, the \fBsymbol\fP primitive allows you to map a name or an
address to a symbol token by means of its \fBfind\fP and \fBfaddr\fP
subcommands. You can then use its \fBname\fP subcommand to find the
name of the symbol, etc.
.PP
I won't explain all the subcommands, as they are sufficiently
explained in the on-line help for the primitives. Rather, in the next
six sections, I will simply tell you of the different pieces of the
different structures and how they fit together. Onward.
.xH 3 Symbols
.PP
The \fBsymbol\fP primitive accesses symbols, as I'm sure you'd
guessed. A symbol in
.sw
has several parts:
.RS
.Bp
A class that indicates what sort of symbol the structure describes.
.Bp
A pointer to the module in which symbol resides (called a symbol's
scope. Modules themselves reside in something called the global
scope).
.Bp
A set of data specific to the class of symbol described.
.RE
.PP
The various classes, the types of symbols they define, and the pieces
of data specific to the class, as returned by the various \fBget\fP
subcommands, are as follows:
.nr q \w'\fBmodule   \fP'u
.IP \fBmodule\fP \nqu
Resource segments are described by symbols of this class, the name of
the symbol being the name of the segment (as given to StartResource).
The only data stored with a module symbol is the token for the patient
to which the symbol belongs. Patient tokens are described later.
.IP \fBtype\fP \nqu
This beast is used for any named type in the patient. For instance,
each STRUC directive in your program creates a symbol of this class
whose name is the name of the structure. Likewise for RECORDs and
enumerated types. The datum stored with the symbol is the token for
the actual description of the type itself (described below). However, the
token for a symbol of this class may be used in place of the type
token it contains. As a general rule, anywhere you can use a type
token, you can use a token for a type-class symbol.
.IP \fBvar\fP \nqu
Refers to any labels in the patient that address data, rather than
program code. A var symbol has three pieces of data: the type of the
variable (as a type token), the class of the variable, and an address
that is specific to the variable class. A variable can be of any of
five variable-classes (only two of which are currently used, however):
.RS
.nr qq \w'\fBregparam   \fP'u
.IP \fBstatic\fP \n(qqu
This is the class of almost all variables. The address is simply the
offset of the variable within its segment.
.IP \fBregister\fP \n(qqu
A few variable symbols have this variable-class (e.g. \fBax\fP). Its
address is its register number, as defined by
.sw
(when you set the data for such a thing, however, you don't need to
give the number \*- you can actually give the register name).
.IP \fBlocal\fP \n(qqu
This is for variables local to a function. Its address is the offset
from the frame pointer\**
.FS
The frame pointer is just BP when it's been set by the prologue
mentioned earlier.
.FE
(or the stack pointer on entry to the function if the function has no
frame pointer). The code for this is completely untested.
.IP \fBparam\fP \n(qqu
This is like \fBlocal\fP except the offset is usually positive, while
the offset for a \fBlocal\fP variable is usually negative.
.IP \fBregparam\fP \n(qqu
This puppy's like \fBregister\fP, but it implies that the thing is a
parameter to a function. Since function symbols don't keep track of
their local variables or anything like that, these three ain't too
useful.
.RE
.IP \fBfunc\fP \nqu
Labels that are followed by \fBproc\fP, rather than a colon, are of
this class. They contain three pieces of data: whether the function is
near or far, the offset of the function's start within its segment,
and the name of the file (relative to the application's .geo file) in
which the function resides.
.IP \fBlabel\fP \nqu
These are much like \fBfunc\fP symbols, in that they refer to code,
but they have only the label-type (\fBnear\fP or \fBfar\fP) and the
label's offset into its segment as data.
.IP \fBenum\fP \nqu
This is the class used for the members of an enumerated type (as
declared with the \fBEnum\fP macro in your source code). Its two data
are its value and the type token for the type that contains the
symbol.
.IP \fBabs\fP \nqu
All global symbolic constants that aren't in an enumerated type have
this class. It contains only the value of the constant.
.IP \fBfield\fP \nqu
Used for structure fields and stores the token for the type of which
the field is a part.
'\"=============================
.xH 3 Type Descriptions
.PP
All structured (i.e. not a byte, word or dword) types are described by
a sort of graph that's known as a type description. Like symbols, each
node in the graph has a class and some class-specific data.  There's
some extra flexibility built into the type descriptions so they can
accomodate other languages, thus some of the data aren't actually used
in our system.  The various classes are:
.nr q \w'\fBpointer   \fP'u
.IP \fBchar\fP \nqu
Only one node in the graph has this class. Things of this type are
bytes that contain an ascii code.
.IP \fBint\fP \nqu
This class encompasses the standard types
.B byte ,
.B word ,
.B dword ,
.B sbyte ,
.B short ,
.B long ,
and
.B int .
The node contains the size of the integer (in bytes) and whether it's
signed.
.IP \fBstruct\fP \nqu
Used for structures and records, nodes of this class contain the size of the
structure (in bytes) and a list of the fields in the structure. Each
field has for pieces of data associated with it: the name, the offset
from the start of the structure \fIin bits\fP, the size of the field
(also in bits) and a token for the type of the field. The offset and
width are kept in terms of bits to accomodate records easily.
.IP \fBenum\fP \nqu
The type to which an enumerated constant belongs is described by a
node of this class. The node contains the names and values of all the
members of the type.
.IP \fBarray\fP \nqu
Array types are created by things like:
.DS I
foo	dw	20 dup(?)
.DE
An array is described by four data, only two of which will actually
vary in this system. The first is the token for the base type of the
array, the second is the lower bound of the index (always 0), the third, the
upper bound (inclusive, so the above array would have a 19), the final
one is the token for the index type (always \fB[type int]\fP).
.IP \fBpointer\fP \nqu
Used for variables that point to other things. Contains two pieces of
data: the type of pointer (\fBnear\fP, \fBlmem\fP, \fBseg\fP,
\fBhandle\fP or \fBfar\fP) and a token for the type of thing pointed
to.
.IP \fBvoid\fP \nqu
The big empty nothingness. Pointers to routines are pointers to this
type, as are pointers for which the type pointed to isn't given.
.br
'\" Print the table o' contents
.TC
