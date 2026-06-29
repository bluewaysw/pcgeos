# Useful SWAT Commands

Use `help command` for more info.

## Getting Help

`help` — Enter interactive help mode  
`help command` — Display help for command  
`apropos keyword` — Summarize commands related to keyword  
`doc keyword` — Display technical docs for keyword  

## Scrolling SWAT Windows

### Main buffer

`Ctrl-f` / `Ctrl-d` / `Ctrl-e` — Scroll forward 1-pg/half-pg/1-line  
`Ctrl-b` / `Ctrl-u` / `Ctrl-y` — Scroll backward 1-pg/half-pg/1-line  

### Source window

`Page Up` / `↑` — Scroll forward 1-pg/1-line  
`Page Down` / `↓` — Scroll backward 1-pg/1-line  
`←` / `→` — Scroll left/right  

## Downloading & Running

`send patient` — Send patient geode to Target  
`run patient` — Run patient geode on Target  
`sw patient[.num]` — Switch to patient's thread num  
`patient-default` — Display current default patient  
`patient-default patient` — Set patient as default patient  
`sym-default` — Display current symbol default  
`sym-default patient` — Look for symbols in patient's sym file  
`spawn patient` — Stop Target when patient loaded  

## SWAT Session

`save file` — Save main buffer to file  
`save num` — Change size of main buffer  
`det` — Detach Host from Target  
`det cont` — Detach Host, leave Target running  
`att` — Attach Host to Target  
`quit` — Exit Host and Target  

## Viewing Source Code

`view file.goc` — Display source file in source window  
`line n` — Scroll window to line n  
`tag routine` — Scroll window to routine  
`find [-i] string` — Search [case-insensitive] for string  

## Windows

`srcwin [lines]` — Open source window [size lines]  
`varwin globalVar` — Display globalVar value  
`varwin var lines` — Resize varwin to lines lines  
`localwin` — Display local variable values  
`regwin` — Display register values  
`winCommand off` — Turn off display window  
`display [lines] [command]` — Continually display output of command  
`display del win` — Turn off display window win  

## Breakpoints

Click on a line # in the source window to toggle a breakpoint there.

`stop in routine` — Set breakpoint in routine  
`stop at [file.goc:]line` — Set breakpoint at line [of file.goc]  
`brk list` — Display breakpoint list  
`brk dis num` — Disable breakpoint num  
`brk en num` — Enable breakpoint num  
`brk del num` — Delete breakpoint num  

## Single-Stepping

`ss` — Enter single-step mode at GOC level  
`is` — Single-step at assembly level  

### Within single-step mode

`n` — Execute next source code line  
`s` — Execute (step) one instruction  
`S` — Skip current source line  
`f` — Finish executing current routine  
`c` — Continue execution  
`b` — Toggle breakpoint at current line  
`q` — Quit single-step mode  

## Stack Frames

`bt` — Display backtrace of stack frames  
`elist` — Display pending events for thread's queue  
`w` — Where (= backtrace + elist)  
`why` — Display FatalError associated with crash  
`explain` — Display more crash info, if available  
`fr num` — Switch to stack frame num  
`up [num]` — Move num frames up stack  
`down [num]` — Move num frames down stack  

## Addressing

Use these for `addr` in commands that follow.

`^hhandle` — Dereference handle to get address  
`^loptr` — Dereference optr to get address  
`*objName` — Get objName's address  
`@num` — Address history entry  
`-a` — Current patient's application  
`-f` — Object with focus  
`-t` — Object with target  
`[appobj]` — Current patient's application  
`[procobj]` — Current patient's process  

## Examining Memory & Variables

`whatis` — Display description of symbol  
`bytes addr num` — Display num mem bytes at addr  
`words addr num` — Display num words at addr  
`print [type] var` — Display value of var [typecast as type]  
`penum type n` — Display nth element of enumerated type  
`precord type n` — Print nth element of record type  
`assign var value` — Assign value to variable var  

## Global Memory

`ps [-h] patient` — Display [handle|thread] info for patient  
`handles patient` — Display patient's global handle table  
`phan handle` — Display info about handle  
`hwalk [patient]` — Display status of global blocks [for patient]  
`hgwalk [patient]` — Display tabulated memory stats [for patient]  
`heapspace <patient>` — Display current heap usage for patient  

## Local Memory

`lhwalk addr` — List chunks in lmem block at addr  
`pcarray addr` — Display chunk array at addr  

## Classes and Methods

`classes` — Display classes defined in current patient  
`cup class` — Display class hierarchy of class  
`methods class` — Display method table for class  
`methods -p` — Display method table of patient's process class  

## Examining Objects

`pobj addr` — Display instance data for object at addr  
`pobjmon addr` — Display visMoniker for Gen object at addr  
`gentree addr` — Display generic obj tree starting at addr  
`vistree addr` — Display visual obj tree starting at addr  
`gup addr` — Display up gentree, starting at addr  
`vup addr` — Display up vistree, starting at addr  
`objwalk addr` — Display info about obj block at addr  

## Message Delivery

`objbrk addr` — Break on any msg sent to addr  
`objbrk addr msg` — Break when msg sent to addr  
`objbrk list` — Display list of objbrk breakpoints  
`objbrk del num` — Delete objbrk breakpoint num  
`objwatch addr` — Display all msgs sent to addr  
`objwatch addr msg` — Display when msg sent to addr  
`brk list` — Display list of objwatches  
`del num` — Delete objwatch num  
`mwatch msg[, msg]` — Display delivery of msg[s]  
`mwatch add msg` — Add msg to watch  
`mwatch` — Clear all msg watches  

## Host/Target Control

`Ctrl-c` — Stop Target: return control to Host  
`c` — Continue: return control to Target  

## Miscellaneous Host Commands

`Ctrl-x` — Erase main buffer input line  
`Ctrl-p` — Scroll backward thru command history  
`Ctrl-n` — Scroll forward thru command history  
`!!` — Repeat last command  
`!string` — Repeat last command that began with string  
