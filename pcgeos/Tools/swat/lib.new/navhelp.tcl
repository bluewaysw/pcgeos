#####################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Swat System library -- on-line help
# FILE:		navhelp.tcl
# AUTHOR:	Lawrence Hosken, Jul 22, 1993
#
# COMMANDS:
#	Name			Description
#	____			___________
#	(No real commands, but the following help topics:)
#	swat_navigation		Node in help tree
#	address_expressions	Using ^h, ^v, ::, etc.
#	address_history		Using @1, @2, @3, etc.
#	command_abbreviation	Using pob, po, Ctrl-D, etc.
#	command_correction	Using ^ to fix typos
#	command_history		Using !!, !h, !$, !etc.
# 	main_buffer		Scrolling the main buffer
#	mouse_usage		Cut and Paste
#	rc_file			Working with SWAT.RC files
#
# DESCRIPTION:
#	Some swat help topics useful for beginners.  Text taken from
#	the paper technical documentation.
#
#	$Id: navhelp.tcl,v 1.3.14.1 97/03/29 11:26:50 canavese Exp $
#
###############################################################

[defhelp swat_navigation top
{Information useful for getting around in Swat}]

[defhelp address_expressions top.swat_navigation
{
Address expressions are used as arguments to any Swat command that 
accesses memory. For example, the pobject command takes an address 
expression as an argument and prints out information about the object at 
that address. An address expression can be a symbol name, which is just the 
name of a pointer, or a symbol path. A symbol path looks like one of the 
following:

<patient>::<name>
<module>::<name>
<patient>::<module>::<name>

The symbol path is used when there is more than one symbol of a given name 
or if a symbol of a different application is needed. A symbol can be 
represented in a variety of ways: the name of an object, a field of a 
structure, a register/number combination, a number from the address history, 
an element of an array, nested Tcl commands, or a Tcl variable.  Array 
indexing is used as follows:

<addr> [<n>]

which will return the zero-based element n from the given addr, even if addr 
is not an array.

Another important way of representing the symbol is as a segment:offset pair. 
Here, the segment is a constant, a register, a module, or a handle ID given 
as ^h<id> where id is a constant or register.

There are several operators which are used to make memory examination 
and manipulation easier in Swat. These operators are shown below (in order 
of highest precedence to lowest):

^h
 The carat-h is used to dereference a memory handle when representing 
 an address as a handle:offset pair (this is also known as a "heap pointer" 
 representation) or when accessing a particular block of memory. It is 
 often used in the situation when a memory handle is in one register (such 
 as BX) and the offset is in another register (such as SI). This is similar 
 to the ^l operator (below), but it requires an offset into the block rather 
 than  a chunk handle. The ^h operator is used thus (the two commands will 
 give the same information if the specified registers contain the specified 
 values):

 [hello3:0] 6 => pobj ^h43d0h:0022h
 [hello3:0] 7 => pobj ^hBX:SI


.
 The period is used to access a field in a structure. For example, if a 
 visible object is located at ^hBX:SI, you could retrieve its top bound with 
 the following command:

 [hello3:0] 8 => print ^h43d0h:0022h.VI_bounds.R_top


+ -
 The addition and subtraction operators are used to add and subtract 
 symbols to and from other symbols and constants. If two symbols in the 
 same segment are subtracted, a constant will be the result.


^l
 The carat-l is used to dereference an optr, a pointer in the form 
 handle:chunk-handle (this is also known as a "local memory pointer"). 
 This is similar to the ^h operator, but ^l requires a chunk handle rather 
 than an offset. If an optr is stored in CX:DX, for example, the ^l operator 
 could be used to dereference it as follows:

 [hello3:0] 11 => pobj ^lCX:DX
 [hello3:0] 12 => pobj ^l0x43d0:0x022


:
 The colon is the segment/offset operator, used to separate the segment 
 and offset in a segment:offset pair.

 [hello3:0] 13 => pobj ^lCX:DX
 [hello3:0] 14 => pobj ^l0x43d0:0x022
 [hello3:0] 15 => pobj INTERFACE:HelloView


*
 The asterisk is a pointer-dereferencing operator, as in the C programming 
 language:

 [hello3:0] 16 => print SubliminalTone
 @5: SubliminalTone = 7246h

 [hello3:0] 17 => print *(&SubliminalTone)

 @6: *(&SubliminalTone) = 7246h


^v
 The carat-v is the virtual memory operator, used to get to the base of a 
 block that is in a Virtual Memory file given the file handle and VM block 
 handle. The correct usage of the ^v operator is:

 ^v<file>:<VM_block>

Much of the time the type of data stored at the address given by the address 
expression is implicit in the expression. Sometimes in ambiguous situations 
(using code as data), however, the type of data must be explicitly stated in
the address expression. This is done by indicating the type of the data 
followed by a space and then a normal address expression. For example, in 
the expression

 dword ds:14h

the data at ds:14h will be treated as a double word.
}]

[defhelp main_buffer top.swat_navigation
{
The main buffer is the area of Swat in which the swat prompt
(e.g. "(geos:0) 5 =>"), your typed commands, and the output
of where most of those commands appear.

To scroll the main buffer, use Ctrl-u (up), Ctrl-d (down), 
Ctrl-y (back one line), Ctrl-e (forward one line), 
Ctrl-b (backward page) and Ctrl-f (forward page).
}]

[defhelp mouse_usage top.swat_navigation
{
You can use the mouse to capture and paste text.  To capture text in
any buffer, click and drag with the left mouse button.  To capture a
word, double click the left mouse button.  To paste captured text to 
the Swat prompt line, press the right mouse button.
}]

[defhelp command_history top.swat_navigation
{
By pressing Ctrl-p several times, you can call previous commands up to 
the Swat prompt. If you go past the command that you want, use Ctrl-n 
to go forward in the history.

The `!' character followed by a number repeats that command in the 
command history. (The standard Swat prompt includes a command 
number which may be used for this.) e.g. !184 will execute the 184th 
command of this session.
The `!' character followed by a string will repeat the most recent 
command whose beginning is the same as the passed string. That is !b 
might invoke brk list if that was the most recent command that began 
with "b".

Typing "!!" will repeat the previous command; "!$" is the last argument of 
the previous command.
}]
[defhelp command_correction top.swat_navigation 
{
To repeat the previous command, but changing a piece of it, use the ^ 
command. This comes in handy when you've made a typo trying to enter 
the previous command.

 (geos:0) 185 => wurds
 Error: invoked "wurds", which isn't a valid command name

 (geos:0) 186 => ^u^o
 words
 Addr:	 	 +0   +2   +4   +6   +8   +a   +c   +e
 4b4bh: e800 01b1 0e00 60f6 0016 9800 6e02 a900

 (geos:0) 187 => ddwords
 Error: invoked "ddwords", which isn't a valid command name

 (geos:0) 188 => ^d
 dwords
 Addr:  +0       +4       +8       +c
 4b59h: 1d0aa900 001c400d 294bd000 6c0a8000
}]
[defhelp address_history top.swat_navigation
{
Swat has an address history which is composed of tokens for address 
expressions previously used by commands such as print or pobj. The 
elements in the history can be accessed by typing @<number> where the 
number argument is the number of the item in the history. These 
elements can replace a full address expression (except constants) and are 
often used when traversing through fields of a previously printed 
structure. The default history keeps track of the last 50 items. 

  (geos:0) 8 => gentree -i

  GenPrimaryClass (@1, ^l44a0h:001eh) "MESS #1"
   GenViewClass (@2, ^l44a0h:0020h)
   GenValueClass (@3, ^l44a0h:0026h)
   GenValueClass (@4, ^l44a0h:0028h)

  (geos:0) 9 => pinst @3
  class = ui::dgroup::GenValueClass
  master part: Gen_offset(53) -- ui::GenValueInstance
  @5: {ui::GenValueInstance (^h17568:1170)+53} = {
	...rest of object's instance data...
  } 
  (geos:0) 10 =>
}]
[defhelp command_abbreviation top.swat_navigation
{
Swat's command abbreviation feature provides a powerful shortcut. Many 
commands can be specified by their first few characters up to and 
including the letter that makes them distinct from all other commands. 
For example, the pobject command can be specified pobj, pob, or even 
po, but not by just p because there are other commands (such as print) 
beginning with the letter p. To get a list of all commands with a given 
prefix, type the prefix at the Swat prompt, then type Ctrl-D. To 
automatically complete a command name use the Escape key (if the 
prefix is unambiguous) or Ctrl-] to scroll through the list of possible 
command completions.
}]

[defhelp rc_file top.swat_navigation
{
If there are certain Swat commands that need to always be executed 
when Swat is run, then they can be placed in an initialization file.  

An initialization file contains a list of commands that 
will be executed just before the first prompt in Swat.
The initialization file should be called SWAT.RC. Swat will look in the 
directory from which it was invoked for such a file. If it doesn't find one 
there, it will look for a file named SWAT.RC in a directory named in the 
HOME environment variable

  srcwin 15
  regwin
  save 500
  spawn mess1

This example shows a sample initialization file which sets up windows to 
display the source code and current register values, set the length of the 
save buffer to 500 lines, and continue running swat until the mess1 
application has been loaded, at which point execution will automatically stop.
}]
