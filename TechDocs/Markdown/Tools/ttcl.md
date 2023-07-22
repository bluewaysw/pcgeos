## 5 Tool Command Language

Before using this chapter one should have a good understanding of how the 
Swat commands function "Swat Introduction," Chapter 3, and of how the 
GEOS system works as a whole.

This chapter is designed to provide information about the Tool Command 
Language, abbreviated Tcl, (the language in which Swat commands are 
written) so that new commands can be written and old commands modified. 
This chapter contains the following main sections:

+ Using This Chapter  
Discussion of the situations warranting the construction of a new 
command in the Tool Command Language.

+ Background and Description  
Discussion of history of Tool Command Language and general overview 
of the language.

+ Syntax and Structure  
Description of the syntax and structure of the Tool Command Language.

+ Commands  
List of all built-in commands for the language.

+ Coding  
Descriptions and examples of coding conventions, techniques, and tricks.

+ Installation  
Steps to take in order to be able to use a newly written command to help 
debug an application.

### 5.1 Using This Chapter

This chapter provides the information needed to write a new Swat command 
in Tcl. But, new commands need only be written in certain situations. Some 
of the situations in which it is advantageous to write a new Swat command 
in Tcl are:

+ There is a complex task that is being repeated often. For example, if one is 
continually examining a certain piece of data in memory but has to go 
through many steps to do so, then it is helpful to write a single command 
to perform all of the needed steps.

+ When a new data-structure is created for an application. For example, if 
one creates a look-up table for the application, then a Tcl command 
should be written to examine that table in particular.

The existing Swat commands should take care of the bulk of debugging, but 
sometimes an extra command can help.

### 5.2 Copyright Information

The following sections of this chapter fall under the copyright below: 
Background and Description, Syntax and Structure, and Commands.

Copyright © 1987 Regents of the University of California

Permission to use, copy, modify, and distribute this software and its 
documentation for any purpose and without fee is hereby granted, provided 
that the above copyright notice appear in all copies. The University of 
California makes no representations about the suitability of this software for 
any purpose. It is provided "as is" without express or implied warranty.

### 5.3 Background and Description

The Tool Command Language is abbreviated as Tcl and is pronounced 
"tickle". It was developed and written by Professor John Ousterhout at the 
University of California at Berkeley. Tcl is a combination of two main parts: 
a language and a library.

**Language** The Tcl language is a textual language intended primarily for 
issuing commands to interactive programs such as text editors, 
illustrators, shells, and most importantly debuggers. It has a 
set syntax and is programmable, thus allowing users to create 
more powerful commands than the built-in command set listed 
in "Swat Reference," Chapter 4.

**Library** Tcl also includes a library which can be imbedded in an 
application, as it is in Swat. This library includes a parser for 
the Tcl language, routines to implement the Tcl built-in 
commands, and procedures allowing an application to extend 
Tcl with additional commands.

### 5.4 Syntax and Structure

Tcl supports only one type of data: *strings*. All commands, all arguments to 
commands, all command results, and all variable values are strings. Where 
commands require numeric arguments or return numeric results, the 
arguments and results are passed as strings. Many commands expect their 
string arguments to have certain formats, but this interpretation is up to the 
individual commands. For example, arguments often contain Tcl command 
strings, which may get executed as part of the commands. The easiest way to 
understand the Tcl interpreter is to remember that everything is just an 
operation on a string. In many cases Tcl constructs will look similar to more 
structured constructs from other languages. However, the Tcl constructs are 
not structured at all; they are just strings of characters, and this gives them 
a different behavior than the structures they may look like.

Although the exact interpretation of a Tcl string depends on who is doing the 
interpretation, there are three common forms that strings take: *commands*, 
*expressions*, and *lists*. This section will have the following main parts:

+ Basic Command Syntax  
Description of the syntax common to all Tcl code: comments, argument 
grouping, command grouping, variable substitution, backslash 
substitution.

+ Expressions  
Details on interpretation of expressions by Tcl.

+ Lists  
Details on interpretation of lists by Tcl.

+ Command Results  
What type of results a command can return.

+ Procedures  
The structure and building of procedures in Tcl.

+ Variables  
Variable declaration and description.

#### 5.4.1 Basic Command Syntax

The Tcl language has syntactic similarities to both Unix and Lisp. However, 
the interpretation of commands is different in Tcl than in either of those 
other two systems. A Tcl command string consists of one or more commands 
separated by newline characters. Each command consists of a collection of 
fields separated by white space (spaces or tabs). The first field must be the 
name of a command, and the additional fields, if any, are arguments that will 
be passed to that command. For example, the command:

`var a 22`

has three fields: the first, var, is the name of a Tcl command, and the last two, 
a and 22, will be passed as arguments to the var command. The command 
name may refer to a built-in Tcl command, an application specific command, 
or a command procedure defined with the built-in proc command. 
Arguments are passed literally as text strings. Individual commands may 
interpret those strings in any fashion they wish. The var command, for 
example, will treat its first argument as the name of a variable and its second 
argument as a string value to assign to that variable. For other commands, 
arguments may be interpreted as integers, lists, file names, or Tcl commands.

##### 5.4.1.1 Comments

If the first non-blank character in a command is # (a number sign), then 
everything from the # up through the next newline character is treated as 
comment and discarded by the parser.

##### 5.4.1.2 Argument Grouping

Normally each argument field ends at the next white space (tabs or spaces), 
but curly braces ("{" and "}") may be used to group arguments in different 
ways. If an argument field begins with a left brace, then the argument is not 
terminated by white space; it ends at the matching right brace. Tcl will strip 
off the outermost layer of braces before passing the argument to the 
command. For example, in the command:

`var a {b c}`

the var command will receive two arguments: **a** and **b  c**. The matching right 
brace need not be on the same line as the left brace; in this case the newline 
will be included in the argument field along with any other characters up to 
the matching right brace. In many cases an argument field to one command 
consists of a Tcl command string that will be executed later; braces allow 
complex command structures to be built up without confusion. For example, 
the **eval** command takes one argument, which is a command string; **eval** 
invokes the Tcl interpreter to execute the command string. The command:

	eval {  
	    var a 22  
	    var b 33  
	}

will assign the value 22 to **a** and 33 to **b**.

Tcl braces act like quote characters in most other languages, in that they 
prevent any special interpretation of the characters between the left brace 
and the matching right brace.

When an argument is in braces, then command, variable, and backslash 
substitutions do not occur in the normal fashion; all Tcl does is to strip off the 
outer layer of braces and pass the contents to the command. Braces are only 
significant in a command field if the first character of the field is a left brace. 
Otherwise neither left nor right braces in the field will be treated specially 
(except as part of variable substitution).

##### 5.4.1.3 Command Grouping

Normally, each command occupies one line (the command is terminated by a 
newline character). Thus, the string:

`var a 22`  
`var b 33`

will be interpreted as two separate commands. However, brackets may be 
used to group commands in ways other than one-command-per-line. If the 
first character of a command is an open bracket, then the command is not 
terminated by a newline character; instead, it consists of all the characters 
up to the matching close bracket. Newline characters inside a bracketed 
command are treated as white space (they will act as argument separators 
for arguments that are not enclosed in braces). For example, the string:

`[var a`  
`22] [var b 33]`

will have the same effect as the previous example.

#####5.4.1.4 Command Substitution

If an open bracket occurs in any of the fields of a command, then command 
substitution occurs. All of the text up to the matching close bracket is treated 
as a Tcl command and executed immediately. The result of that command is 
substituted for the bracketed text. For example, consider the command:

`var a [var b]`

When the var command has only a single argument, it is the name of a 
variable and var returns the contents of that variable. In this case, if 
variable b has the value *test*, then the command above is equivalent to the 
command:

`var a test`

Brackets can be used in more complex ways. for example, if the variable **b** 
has the value *tmp* and the variable **c** has the value *val*, then the command:

`var a test[var b].[var c]`

is equivalent to the command:

`var a testtmp.val`

If a field is enclosed in braces then the brackets and the characters between 
them are not interpreted specially; they are passed through to the argument 
verbatim.

##### 5.4.1.5 Variable Substitution

The dollar sign ($) may be used as a special shorthand form for substituting 
variables. If $ appears in an argument that is not enclosed in braces then 
variable substitution will occur. The characters after the $, up to the first 
character that is not a number, letter, or underscore, are taken as a variable 
name and the string value of that variable is substituted for the name. Or, if 
the dollar sign is followed by an open curly brace, then the variable name 
consists of all the characters up to the next close curly brace. For example, if 
variable **outfile** has the value test, then the command:

`var a $outfile.c`

is equivalent to the command:

`var a test.c`

and the command:

`var a abc${outfile}tmp`

is equivalent to the command:

`var a abctesttmp`

Variable substitution does not occur in arguments that are enclosed in 
braces: the dollar sign and variable name are passed through to the 
argument verbatim.

The dollar sign abbreviation is simply a shorthand form. **$a** is completely 
equivalent to **[var a]**; it is provided as a convenience to reduce typing.

##### 5.4.1.6 Backslash Substitution

Backslashes may be used to insert non-printing characters into command 
fields and also to insert braces, brackets, and dollar signs into fields without 
them being interpreted specially as previously described. The backslash 
sequences understood by the Tcl interpreter are listed in Table 5-1. In each 
case, the backslash sequence is replaced by the given character.

For example, in the command:

`var a \{x\[\ yz\141`

the second argument to var is **{x[   yza** (note the "space" as part of the 
argument).

If a backslash is followed by something other than one of the options in 
Table 5-1, then the backslash is transmitted to the argument field without 
any special processing, and the Tcl scanner continues normal processing with 
the next character. For example, in the command:

`var \*a \\\{test`

the first argument will be \\*a and the second \\{test.


**Table 5-1 *Backslash Sequences***

----------

	Sequence		Replaced Value  
	\b				Backspace (octal 10)  
	\e				Escape (octal 33)  
	\n				Newline (octal 15)  
	\t				Tab (octal 11)  
	\{				Left brace ("{")  
	\}				Right brace ("}")  
	\[				Open bracket ("[")  
	\]				Close bracket ("]")  
	\<space>		Space (note: does not terminate the argument)  
	\\				Backslash ("\")  
	\Cx				Control-x for any ASCII x except M (see below)  
	\Mx				Meta-x for any ASCII x  
	\CMx			Control-meta-x for any ASCII x  
	\ddd			The digits ddd (one, two, or three of them) give the octal value of the character

----------

If an argument is enclosed in braces, then backslash sequences inside the 
argument are parsed but no substitution occurs. In particular, backslashed 
braces are not counted in locating the matching right brace that terminates 
the argument. for example, in the command:

`var a {\{abc}`

the second argument to var will be \\{abc.

The backslash mechanism is not sufficient to generate any argument 
structure; it only covers the most common cases. To produce particularly 
complicated arguments it will probably be easiest to use the format 
command along with command substitution.

#### 5.4.2 Expressions

The second major interpretation applied to strings in Tcl is as *expressions*. 
Several commands, such as **expr**, **for**, and **if**, treat some of their arguments 
as expressions and call the Tcl expression processor (Tcl_Expr) to evaluate 
them. A Tcl expression has C-like syntax and evaluates to an integer result. 
Expressions may contain integer values, variable names in $ notation (the 
variables' values must be integer strings), commands (embedded in brackets) 
that produce integer string results, parentheses for grouping, and operators. 
Numeric values, whether they are passed directly or through variable or 
command substitution, may be specified either in decimal (the normal case), 
in octal (if the first character of the value of the first character is 0 (zero)), or 
in hexadecimal (if the first two characters of the value are 0x). The valid 
operators are listed in Table 5-2 grouped in decreasing order of precedence.

**Table 5-2 Valid Operators**

----------

	Operators			Description  
	-   ~   !			Unary minus, bit-wise NOT, logical NOT  
	*   /   %			Multiply, divide, remainder  
	+   -				Add and subtract  
	<<   >>				Left and right shift  
	< >   <=   >=		Boolean less, greater, less than or equal, and greater than or equal. Each operator produces 1 if the condition is true, 0 otherwise  
	==   !=				Boolean equal and not equal  
	&					Bit-wise AND  
	^					Bit-wise exclusive OR  
	|					Bit-wise OR  
	&&					Logical AND  
	||					Logical OR

----------

See a C manual for more details on the results produced by each operator. All 
of the binary operators group left to right within the same precedence level. 
for example, the expression:

`(4*2)<7`

evaluates to zero. Evaluating the expression string:

`($a+3)<[var b]`

will cause the values of the variables **a** and **b** to be examined; the result will 
be 1 if **b** is greater than **a** by at least 3; otherwise the result will be 0.

In general it is safest to enclose an expression in braces when entering it in 
a command; otherwise, if the expression contains any white space then the 
Tcl interpreter will split it among several arguments. For example, the 
command:

`expr $a + $b`

results in three arguments being passed to **expr**: **$a**, **+**, and **$b**. In addition, 
if the expression is not in braces then the Tcl interpreter will perform 
variable and command substitution immediately (it will happen in the 
command parser rather than in the expression parser). In many cases the 
expression is being passed to a command that will evaluate the expression 
later (or even many times if, for example, the expression is to be used to 
decide when to exit a loop). usually the desired goal is to re-do the variable or 
command substitutions each time the expression is evaluated, rather than 
once and for all at the beginning. For an example of a mistake, the command:

`for {var i 1} $i<=10 {var i [expr $i+1]} {body-}`

is probably intended to iterate over all values of **i** from 1 to 10. After each 
iteration of the body of the loop, for will pass its second argument to the 
expression evaluator to see whether or not to continue processing. 
Unfortunately, in this case the value of **i** in the second argument will be 
substituted once and for all when the for command is parsed. If **i** was 0 before 
the for command was invoked then **for**'s second argument will be **0<=10** 
which will always evaluate to 1, even though **i**'s value eventually becomes 
greater than 10. In the above case the loop will never terminate. By placing 
the expression in braces, the substitution of **i**'s value will be delayed; it will 
be re-done each time the expression is evaluated, which is probably the 
desired result:

`for {var i 1} {$i<=10} {var i [expr $i+1]} {body-}`

#### 5.4.3 Lists

The third major way that strings are interpreted in Tcl is a *list*. A list is just 
a string with a list-like structure consisting of fields separated by white 
space. For example, the string:

`Al Sue Anne John`

is a list with four elements or fields. Lists have the same basic structure as 
command strings, except that a newline character in a list is treated as a field 
separator just like a space or tab. Conventions for braces and backslashes are 
the same for lists as for commands. For example, the string:

`a b\ c {d e {f g h}}`

is a list with three elements: **a**, **b** **c**, and **d e {f g h}**. Note the space between 
the b and c. Whenever an element is extracted from a list, the same rules 
about backslashes and braces are applied as for commands. Thus in the 
above example when the third element is extracted from the list, the result is:

`d e {f g h}`

(when the field was extracted, all that happened was to strip off the 
outermost layer of braces). Command substitution is never made on a list (at 
least, not by the list-processing commands; the list can always be passed to 
the Tcl interpreter for evaluation).

The Tcl commands **concat**, **foreach**, **index**, **length**, **list**, and **range** allow 
you to build lists, extract elements from them, search them, and perform 
other list-related functions.

#### 5.4.4 Command Results

Each command produces two results: a code and a string. The code indicates 
whether the command completed successfully or not, and the string gives 
additional information. The valid codes are defined as follows:

TCL_**OK**  
This is the normal return code, and indicates that the 
command completed successfully. The string gives the 
commands's return value.

TCL_**ERROR**  
Indicates that an error occurred; the string gives a message 
describing the error.

TCL_**RETURN**  
Indicates that the return command has been invoked, and that 
the current procedure should return immediately. The string 
gives the return value that procedure should return.

TCL_**BREAK**  
Indicates that the break command has been invoked, so the 
innermost loop should abort immediately. The string should 
always be empty.

TCL_**CONTINUE**  
Indicates that the continue command has been invoked, so the 
innermost loop should go on to the next iteration. The string 
should always be empty.

Tcl programmers do not normally need to think about return codes, since 
TCL_**OK** is almost always returned. If anything else is returned by a 
command, then the Tcl interpreter immediately stops processing commands 
and returns to its caller. If there are several nested invocations of the Tcl 
interpreter in progress, then each nested command will usually return the 
error to its caller, until eventually the error is reported to the top-level 
application code. The application will then display the error message for the 
user.

In a few cases, some commands will handle certain "error" conditions 
themselves and not return them upwards. For example, the **for** command 
checks for the TCL\_**BREAK** code; if it occurs, then **for** stops executing the 
body of the loop and returns TCL\_**OK** to its caller. The **for** command also 
handles TCL\_**CONTINUE** codes and the procedure interpreter handles 
TCL_**RETURN** codes. The **catch** command allows Tcl programs to catch 
errors and handle them without aborting command interpretation any 
further.

#### 5.4.5 Procedures

Tcl allows one to extend the command interface by defining procedures. A Tcl 
procedure can be invoked just like any other Tcl command (it has a name and 
it receives one or more arguments). The only difference is that its body is not 
a piece of C code linked into the program; it is a string containing one or more 
other Tcl commands. See the **proc** command for information on how to define 
procedures and what happens when they are invoked.

#### 5.4.6 Variables

Tcl allows the definition of variables and the use of their values either 
through $-style variable substitution, the var command, or a few other 
mechanisms. Variables need not be declared: a new variable will 
automatically be created each time a new variable name is used. Variables 
may be either global or local. If a variable name is used when a procedure is 
not being executed, then it automatically refers to a global invocation of the 
procedure. Local variables are deleted whenever a procedure exits. The 
global command may be used to request that a name refer to a global 
variable for the duration of the current procedure (somewhat analogous to 
**extern** in C).

### 5.5 Commands

The Tcl library provides the following built-in commands, which will be 
available to any application using Tcl. In addition to these built-in 
commands, there may be additional commands defined in Swat, plus 
commands defined as Tcl procedures.

#### 5.5.1 Notation

The descriptions of the Tcl commands will follow the following notational 
conventions:

+ `command (alternative1|alternative2|-|alternativeN)`  
() The parentheses enclose a set of alternatives separated by a vertical 
line. For example, the expression `quit (cont|leave)` means that either 
`quit cont` or `quit leave` can be used.

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
expression and `<argument>` indicates some sort of argument, but 
`(addr|type)` means either the string `addr` or the string `type`.

+ `*    +`  
An asterisk following any of the previous constructs indicates zero or 
more repetitions of the construct may be typed. An addition sign 
indicates one or more repetitions of the construct may be used. For 
example, `unalias word*` can be the `unalias` command by itself, or it can 
be followed by a list of words to be unaliased.

#### 5.5.2 Built-in Commands

The built-in Tcl commands are as follows:

----------

### bc

**Usage:**  
`bc list <proc>`  
`bc disasm <proc>`  
`bc compile <proc>`  
`bc fcompile <file> [<nohelp>]`  
`bc fload <file>`  
`bc fdisasm <file>`  
`bc debug [1|0]`

**Examples:**  
`bc compile poof`  
Compiles the body of the procedure "poof" and replaces the 
existing procedure with its compiled form.

`bc fcomp bptutils.tcl`  
Creates the file "bptutils.tlc" that contains a stream of compiled 
Tcl that will do exactly what sourcing bptutils.tcl does, except 
the resulting procedures will be compiled Tcl, not interpreted 
Tcl.

`bc fload bptutils.tlc`  
Loads a file containing a stream of compiled Tcl code.

**Synopsis:**  
The "bc" command allows you to create and examine compiled Tcl code. 
Compiled Tcl is not nearly as readable or changeable as interpreted Tcl code, 
but it's 30-50% faster.

**Notes:**  
The "list" subcommand doesn't work as yet. Eventually it will attempt to 
construct a more readable form of compiled code. For now, the raw opcodes 
will have to do.

**See Also:**  
source.

----------

### break

**Usage:**  
`break`

**Examples:**  
`break`  
Break out of the current loop.

**Synopsis:**  
Breaks out of the current loop or the current nested interpreter.

**Notes:**

+ Only the closest-enclosing loop can be exited via this command. 

+ This command may be invoked only inside the body of a loop command 
such as **for** or **foreach**. It returns a TCL_BREAK code to signal the 
innermost containing loop command to return immediately.

+ If you've entered a nested interpreter, e.g. by calling a function in the 
patient, use this to exit the interpreter and restore the registers to what 
they were before you made the call.

**See Also:**  
continue, for.

----------

### case

**Usage:**  
`case <string> [in] [<pat> <body>]+`

**Examples:**

    [case $c in  
        {[0-9]} {  
        # do something with digit  
    }  
        default {  
        # do something with non-digit  
    }  
    ]  
Do one of two things depending on whether the character in $c 
is a digit.

**Synopsis:**	Perform one of a set of actions based on whether a string matches one or more 
patterns.

**Notes:**

+ Compares each of the `<pattern>` arguments to the given `<string>`, 
executing `<body>` following the first `<pattern>` to match. `<pattern>` uses 
shell wildcard characters as for the string match command, but may also 
contain alternatives, which are separated by a vertical bar, thus allowing 
a `<body>` to be executed under one of several circumstances. In addition, 
if one `<pattern>` (or element thereof) is the string default, the associated 
`<body>` will be executed if none of the other patterns matches. For 
example, the following:

    [case $test in  
    a|b {return 1}  
    {default|[DE]a*} {return 0}  
    ?c {return -1}]

    will return 1 if variable **test** contains **a** or **b**, -1 if it contains a two-letter 
string whose second letter is **c**, and 0 in all other cases, including the ones 
where **test**'s first two letters are either **Da** or **Ea**.

+ Each `<pat>` argument is a list of patterns of the form described for the 
"string match" command. 

+ Each `<pat>` argument must be accompanied by a `<body>` to execute. 

+ If a `<pat>` contains the special pattern "default," the associated `<body>` 
will be executed if no other pattern matches. The difference between 
"default" and "\*" is a pattern of "*" causes the `<body>` to be executed 
regardless of the patterns in the remaining `<pat`> arguments, while 
"default" postpones the decision until all the remaining patterns have 
been checked.

+ You can give the literal "in" argument if you wish to enhance the 
readability of your code.

**See Also:**  
string, if.

----------

### catch

**Usage:**  
`catch <command> [<varName>]`

**Synopsis:**  
Executes a command, retaining control even if the command generates an 
error (which would otherwise cause execution to unwind completely).

**Notes:**

+ The **catch** command may be used to prevent errors from aborting 
command interpretation. **catch** calls the Tcl interpreter recursively to 
execute `<command>`, and always returns a TCL_OK code, regardless of 
any errors that might occur while executing `<command>`. The return 
value from catch is a decimal string giving the code returned by the Tcl 
interpreter after executing `<command>`. This will be zero (TCL_OK) if 
there were no errors in command; otherwise it will have a non-zero value 
corresponding to one of the exceptional return codes. If the `<varName>` 
argument is given, then it gives the name of a variable; **catch** will set the 
value of the variable to the string returned from command (either a 
result or an error message).

+ This returns an integer that indicates how `<command>` completed:

    **0** - Completed successfully; `$<varName>` contains the result of the 
command.

    **1** - Generated an error; `$<varName>` contains the error message.

    **2** - Executed "return"; `$<varName>` contains the argument passed 
to "return."

    **3** - Executed "break"; `$<varName>` is empty.

    **4** - Executed "continue"; `$<varName>` is empty.

**See Also:**  
protect.

----------

### concat

**Usage:**  
`concat <arg1>+`

**Examples:**  
`concat $list1 $list2`  
Merges the lists in $list1 and $list2 into a single list whose 
elements are the elements of the two lists.

**Synopsis:**  
Concatenates multiple list arguments into a single list.

**Notes:**

+ This command treats each argument as a list and concatenates them into 
a single list. It permits any number of arguments. For example, the 
command  
`concat a b {c d e} {f {g h}}`  
will return **a b c d e f {g h}** as its result.

+ There is a sometimes-subtle difference between this in the "list" 
command: Given two lists, "concat" will form a list whose n elements are 
the combined elements of the two component lists, while "list" will form 
a list whose 2 elements are the two lists. For example,
`concat a b {c d e} {f {g h}}`  
yields the list  
`a b c d e f {g h}`  
but  
`list a b {c d e} {f {g h}}`  
yields  
`a b {c d e} {f {g h}}`

**See Also:**  
list.

----------

### continue

**Usage:**  
`continue`

**Examples:**  
`continue`  
Return to the top of the enclosing loop.

**Synopsis:**  
Skips the rest of the commands in the current loop iteration, continuing at 
the top of the loop.

**Notes:**

+ Only the closest-enclosing loop can be continued via this command. 

+ The `<next>` clause of the "for" command is not part of the current 
iteration, i.e. it will be executed even if you execute this command.

+ This command may be invoked only inside the body of a loop command 
such as **for** or **foreach**. It returns a TCL_CONTINUE code to signal the 
innermost containing loop command to skip the remainder of the loop's 
body but continue with the next iteration of the loop. 

**See Also:**  
break, for.

----------

### defsubr

**Usage:**  
`defsubr <name> <args> <body>`

**Examples:**  
`defsubr poof {arg1 args} {return [list $arg1 $args]}`  
Defines a procedure poof that takes 1 or more arguments and 
merges them into a list of two elements.

**Synopsis:**  
This is the same as the "proc" command, except the new procedure's name 
may not be abbreviated when it is invoked.

**Notes:**  
Refer to the documentation for proc for more information.

----------

### error

**Usage:**  
`error <message>`

**Examples:**  
`error {invalid argument}`  
Generates an error, giving the not-so-helpful message "invalid 
argument" to the caller's caller.

**Notes:**

+ Unless one of the procedures in the call stack has executed a "catch" 
command, all procedures on the stack will be terminated with `<message>` 
(and an indication of an error) being the result of the final one so 
terminated. 

+ Any commands protected by the "protect" command will be executed.

**See Also:**  
return, catch.

----------

###eval

**Usage:**  
`eval <body>`

**Examples:**  
`eval $mangled_command`  
Evaluate the command contained in $mangled_command and 
return its result.

**Synopsis:**  
Evaluates the passed string as a command and returns the result of that 
evaluation.

+ eval takes one argument, which is a Tcl command (or collection of Tcl 
commands separated by newlines in the usual way). eval evaluates 
`<body>` by passing it to the Tcl interpreter recursively, and returns the 
result of the last command. If an error occurs inside `<body>` then eval 
returns that error. 

+ This command is useful when one needs to cobble together a command 
from arguments or what have you. For example, if one of your arguments 
is a list of arguments to pass to another command, the only way to 
accomplish that is to say something like `eval [concat random-command 
$args]`, which will form a list whose first element is the command to be 
executed, and whose remaining elements are the arguments for the 
command. "eval" will then execute that list properly.

+ If the executed command generates an error, "eval" will propagate that 
error just like any other command.

**See Also:**  
concat, list.

----------

### expr

**Usage:**  
`expr <expression> [float]`

**Examples:**  
`expr 36*25`  
Multiplies 36 by 25 and returns the result.

`expr $i/6 float`  
Divides the number in $i by 6 using floating- point arithmetic; 
the result is a real number.

`expr 7.2*10 float`  
Multiplies 7.2 by 10. Note that though the answer (72) is an 
integer, we need to pass the "float" keyword to make sure that 
the expression is interpreted correctly.

**Synopsis:**  
Evaluates an arithmetic expression and returns its value.

**Notes:**

+ Most C operators are supported with the standard operator precedence. 

+ If you use a Tcl variable in the expression, the variable may only contain 
a number; it may not contain an expression. 

+ The result of any Tcl command, in square brackets ("[ ]") must be a 
number; it may not be an expression. 

+ All the C and Esp radix specifiers are allowed. 

+ Bitwise and boolean operators (!, &, ^, |, &&, ||, >>, <<, ~) are not 
permitted when the expression is being evaluated using floating-point 
arithmetic.

----------

### file

**Usage:**  
`file dirname <name>`  
`file exists <name>`  
`file extension <name>`  
`file isdirectory <name>`  
`file isfile <name>`  
`file readable <name>`  
`file rootname <name>`  
`file tail <name>`  
`file writable <name>`  
`file match <pattern>`  
`file newer <name1> <name2>`

**Examples:**  
`file match /pcgeos/tcl/*.tcl`  
Looks for all files/directories in /pcgeos/tcl whose name ends 
with ".tcl".

`file isdir $path`  
See if the path stored in $path refers to a directory.

`file tail $path`  
Return the final component of the path stored in $path

**Synopsis:**  
Performs various checks and manipulations of file and directory names.

**Notes:**

+ The forward slash is the path separator for this command.

+ The predicate subcommands (executable, exists, isdirectory, isfile, 
owned, readable, and writable) all return 1 if the path meets the 
requirements, or 0 if it doesn't. 

+ "file match" takes a *pattern* made from the same components as are 
described for "string match". It is *not* the same as the standard DOS 
wildcarding, where "." serves to separate the root pattern from the 
extension pattern. For this command "\*.*" would match only files that 
actually have an extension. 

+ "file dirname" returns the directory portion of *name*. If *name* has no 
directory portion, this returns "." 

+ "file rootname" returns all leading directory components of name, plus 
the text before its extension, without the "." that separates the name from 
the extension. 

+ "file tail" returns all of the characters in name after the final forward 
slash, or name if it contains no forward slashes.

+ "file newer" returns 1 if *name1* was modified after *name2*. It returns 0 
otherwise.

**See Also**:  
string.

----------

### for

**Usage:**  
`for <start> <test> <next> <body>`

**Examples:**  
`for {var i 0} {$i < 10} {var i [expr $i+1]} {echo $i}`  
 Prints the numbers from 0 to 9.

**Synopsis:**  
This is Tcl's main looping construct. It functions similarly to the "for" in C.

**Notes:**

+ `<start>` is a Tcl command string (which may involve multiple commands 
over multiple lines, if desired) that is executed once at the very start of 
the loop. It is always executed. If it returns an error, or contains a "break" 
command, no part of the loop will execute. 

+ `<test>` is an arithmetic expression that is passed to the "expr" command. 
If the result is non-zero, the `<body>` is executed. 

+ `<next>` is a Tcl command string (which may involve multiple commands 
over multiple lines, if desired) that is executed at the end of each 
iteration before `<test>` is evaluated again. If it returns an error, or 
contains a "break" command, no part of the loop will execute. 

+ You can exit the loop prematurely by executing the "break" command in 
any of the three Tcl command strings (`<start>`, `<next>`, or `<body>`). 

+ So long as there's no error, "for" always returns the empty string as its 
result.

+ If a **continue** command is invoked within `<body>` then any remaining 
commands in the current execution of `<body>` are skipped; processing 
continues by invoking the Tcl interpreter on `<next>`, then evaluating 
`<test>`, and so on. If a **break** command is invoked within `<body>`, then 
the for command will return immediately. The operation of **break** and 
**continue** are similar to the corresponding statements in C. 

**See Also:**  
foreach, break, continue.

----------

### foreach

**Usage:**  
`foreach <varname> <list> <body>`

**Examples:**  
`foreach el $list {echo poof = $el}`  
Prints each element of the list $list preceded by the profound 
words "poof = "

**Synopsis:**  
This is a looping construct to easily iterate over all the elements of a list.

**Notes:**

+ `<body>` is evaluated once for each element in `<list>`. Before each 
evaluation, the next element is placed in the variable `<varName>`. 

+ You can exit the loop prematurely by executing the "break" command. 

+ As long as there's no error, "foreach" always returns the empty string.

+ The **break** and **continue** statements may be invoked inside `<body>`, 
with the same effect as in the **for** command.

----------

### format

Usage:  
`format <formatString> [<arg> ]*`

This command generates a formatted string in the same way as the C 
**sprintf** procedure (it uses **sprintf** in its implementation). `<formatString>` 
indicates how to format the result, using % fields as in **sprintf**, and the 
additional arguments, if any, provide values to be substituted into the result. 
All of the **sprintf** options are valid; see the sprintf procedure in a C manual 
for more details. Each `<arg>` must match the expected type from the % field 
in `<formatString>`; the **format** command converts each argument to the 
correct type (floating, integer, etc.) before passing it to **sprintf** for formatting. 
The only unusual conversion is for %c; in this case the argument must be a 
decimal string, which will then be converted to the corresponding ASCII 
character value. format does backslash substitution on its `<formatString>` 
argument, so backslash sequences in `<formatString>` will be handled 
correctly even if the argument is in braces. The return value from format is 
the formatted string.

----------

### global

**Usage:**  
`global <varname>+`

**Examples:**  
`global attached`  
When next the "attached" variable is fetched or set, get it from 
the global scope, not the local one.

**Synopsis:**  
Declares the given variables to be from the global scope.

**Notes:**

+ For the duration of the procedure in which this command is executed (but 
not in any procedure it invokes), the global variable of the given name 
will be used when the variable is fetched or set. 

+ If no global variable of the given name exists, the setting of that variable 
will define it in the global scope.

+ This command is ignored unless a Tcl procedure is being interpreted. If 
so, then it declares the given `<varname>`'s to be global variables rather 
than local ones. For the duration of the current procedure (and only while 
executing in the current procedure), any reference to any of the 
`<varname>` values will be bound to a global variable instead of a local 
one.

**See Also:**  
var.

----------

### if

**Usage:**

    if <test> [then] <trueBody>  
        (elif <test> [(then)] <trueBody>)*  
        [[else] <falseBody>]

**Examples:**  
`if {$v > 3} {echo yes} {echo no}`  
Prints "yes" if $v is greater than 3, else it prints "no".

`if {$v > 3} then {echo yes} else {echo no}`  
Ditto.

`if {$v > 3} then {echo yes} elif {$v == 3} {echo maybe} else {echo no}`

**Synopsis:**  
This is Tcl's conditional, as you'd expect from its name.

**Notes:**	

+ The "then" and "else" keywords are optional, intended to delineate the 
different sections of the command and make the whole easier to read. 

+ The "elif" keyword is mandatory if you want to perform additional tests. 

+ The `<expr>` arguments are normal Tcl expressions. If the result is 
non-zero, the appropriate `<truebody>` is executed. If none of the `<expr>` 
arguments evaluates non-zero, `<falsebody>` is executed. 

+ If a `<truebody>` is empty and the test evaluated non-zero, "if" will return 
the result of the test. Otherwise "if" returns the result from last 
command executed in whichever `<truebody>` or `<falsebody>` argument 
was finally executed. It returns an empty string if no `<expr>` evaluated 
non-zero and no `<falsebody>` was given.

+ The **if** command evaluates `<test>` as an expression in the same way that 
**expr** evaluates its argument. If the result is non-zero then `<trueBody>` 
is called by passing it to the Tcl interpreter. Otherwise `<falseBody>` is 
executed by passing it to the Tcl interpreter. `<falseBody>` is also optional; 
if it isn't specified then the command does nothing if `<test>` evaluates to 
zero. The return value from if is the value of the last command executed 
in `<trueBody>` or `<falseBody>` or the empty string if `<test>` evaluates to 
zero and `<falseBody>` isn't specified. Alternative test conditions can be 
added by adding `<elif>` arguments. 

**See Also:**  
expr.

----------

### index

**Usage:**  
`index <value> <index> [chars]`

**Examples:**  
`index {a b c} 1`  
Extracts "b" from the list.

`index {hi mom} 3 char`  
Extracts "m" from the string.

**Synopsis:**  
"index" is used to retrieve a single element or character from a list or string.

**Notes:**

+ Elements and characters are numbered from 0. 

+ If you request an element or character from beyond the end of the `<list>` 
or `<string>`, you'll receive an empty list or string as a result.

+ If the `<chars>` keyword isn't specified, then index treats `<value>` as a list 
and returns the `<index>`'th field from it. In extracting the field, index 
observes the same rules concerning braces and backslashes as the Tcl 
command interpreter; however, variable substitution and command 
substitution do not occur. If the `<chars>` keyword is specified (or any 
abbreviation of it), then `<value>` is treated as a string and the command 
returns the `<index>`'th character from it (or the empty string if there 
aren't at least `<index>+1` characters in the string). 

----------

### info

**Usage:**  
`info args <procname> [<pattern>]`  
`info arglist <procname>`  
`info body <procname>`  
`info cmdcount`  
`info commands [<pattern>]`  
`info default <procname> <arg> <varname>`  
`info globals [<pattern>]`  
`info locals [<pattern>]`  
`info procs [<pattern>]`  
`info vars [<pattern>]`  

**Examples:**  
`info args fmtval`  
Retrieves the names of the arguments for the "fmtval" 
command so you know in what order to pass things.

`info body print-frame`  
Retrieves the string that is the body of the 
"print-frame" Tcl procedure.

`info commands reg`  
Retrieves a list of commands whose names contain the 
string "reg".

**Synopsis:**`  
This command provides information about a number of data structures 
maintained by the Tcl interpreter.

**Notes:**

+ All the `<pattern>` arguments are standard wildcard patterns as are used 
for the "string match" and "case" commands. See "string" for a 
description of these patterns. 

+ "info args" returns the complete list of arguments for a Tcl procedure, or 
only those matching the `<pattern>`, if one is given. The arguments are 
returned in the order in which they must be passed to the procedure. 

+ "info arglist" returns the complete list of arguments, and their default 
values, for a Tcl procedure. 

+ "info body" returns the command string that is the body of the given Tcl 
procedure. 

+ "info cmdcount" returns the total number of commands the Tcl 
interpreter has executed in its lifetime.

+ "info commands" returns the list of all known commands, either built-in 
or as Tcl procedures, known to the interpreter. You may also specify a 
pattern to restrict the commands to those whose names match the 
pattern. 

+ "info default" returns non-zero if the argument named `<arg>` for the 
given Tcl procedure has a default value. If it does, that default value is 
stored in the variable whose name is `<varname>`. 

+ "info globals" returns the list of all global variables accessible within the 
current variable scope (i.e. only those that have been declared global with 
the "global" command, unless you issue this command from the 
command-line, which is at the global scope), or those that match the 
given pattern. 

+ "info locals" returns the list of all local variables, or those that match the 
given pattern.

+ "info procs" returns the list of all known Tcl procedures, or those that 
match the given pattern. 

+ "info vars" returns the list of all known Tcl variables in the current scope, 
either local or global. You may also give a pattern to restrict the list to 
only those that match.

**See Also:**  
proc, defcmd, defcommand, defsubr.

----------

### length

**Usage:**  
`length <value> [<chars>]`

**Examples:**  
`length $args`  
Returns the number of elements in the list $args

`length $str char`  
Returns the number of characters in the string $str

**Synopsis:**  
Determines the number of characters in a string, or elements in a list.

**Notes:**  
If `<chars>` isn't specified, **length** treats `<value>` as a list and returns the 
number of elements in the list. If `<chars>` is specified (or any abbreviation of 
it), then **length** treats `<value>` as a string and returns the number of 
characters in it (not including the terminating null character).

**See Also:**  
index, range.

----------

### list

**Usage:**  
`list <arg>+`

**Examples:**  
`list a b {c d e} {f {g h}}`  
Returns the list "a b {c d e} {f {g h}}"

**Synopsis:**  
Joins any number of arguments into a single list, applying quoting braces 
and backslashes as necessary to form a valid Tcl list.

**Notes:**

+ If you use the "index" command on the result, the 0th element will be the 
first argument that was passed, the 1st element will be the second 
argument that was passed, etc. 

+ The difference between "list" and "concat" is subtle. Given the above 
arguments, "concat" would return "a b c d e f {g h}".

+ This command returns a list comprised of all the `<args>`. It also adds 
braces and backslashes as necessary, so that the **index** command may be 
used on the result to re-extract the original arguments, and also so that 
**eval** may be used to execute the resulting list, with `<arg1>` comprising 
the command's name and the other `<args>` comprising its arguments. 

**See Also:**  
concat, index, range.

----------

### proc

**Usage:**  
`proc <name> <args> <body>`

**Examples:**  
`proc poof { {arg1 one} args} {return [list $arg1 $args]}`  
 Defines a procedure poof that takes 0 or more arguments and 
merges them into a list of two elements. If no argument is 
given, the result will be the list {one {}}

**Synopsis:**  
Defines a new Tcl procedure that can be invoked by typing a unique 
abbreviation of the procedure name.

**Notes:**

+ Any existing procedure or built-in command with the same name is 
overridden. 

+ `<name>` is the name of the new procedure and can consist of pretty much 
any character (even a space or tab, if you enclose the argument in braces). 

+ `<args>` is the, possibly empty, list of formal parameters the procedure 
accepts. Each element of the list can be either the name of local variable, 
to which the corresponding actual parameter is assigned before the first 
command of the procedure is executed, or a two-element list, the first 
element of which is the local variable name, as above, and the second 
element of which is the value to assign the variable if no actual 
parameter is given. 

+ If the final formal parameter is named "args", the remaining actual 
parameters from that position on are cobbled into a list and assigned to 
the local variable $args. This allows a procedure to receive a variable 
number of arguments (even 0, in which case $args will be the empty list). 

+ If the only formal parameter is "noeval", all the actual parameters are 
merged into a list and assigned to $noeval. Moreover, neither command- 
nor variable-substitution is performed on the actual parameters. 

+ The return value for the procedure is specified by executing the "return" 
command within the procedure. If no "return" command is executed, the 
return value for the procedure is the empty string.

+ Whenever the new command is invoked, the contents of `<body>` will be 
executed by the Tcl interpreter. `<args>` specifies the formal arguments to 
the procedure. It consists of a list, possibly empty, each of whose elements 
specifies one argument. Braces and backslashes may be used in the usual 
way to specify complex default values.

+ When `<name>` (or a unique abbreviation of same) is invoked, a local 
variable will be created for each of the formal arguments to the 
procedure; its value will be the value of corresponding argument in the 
invoking command or the argument's default value. Arguments with 
default values need not be specified in a procedure invocation. However, 
there must be enough actual arguments for all the formal arguments 
that don't have defaults, and there must not be any extra actual 
arguments (unless the "args" keyword was used). 

+ When `<body>` is being executed, variable names normally refer to local 
variables, which are created automatically when referenced and deleted 
when the procedure returns. One local variable is automatically created 
for each of the procedure's arguments. Global variables can only be 
accessed by invoking the **global** command.

+ The **proc** command itself returns the null string. 

**See Also:**  
defsubr, return.

----------

### protect

**Usage:**  
`protect <body> <cleanup>`

**Examples:**

	protect {  
       var s [stream open $file w]
       # do stuff with the stream
    } {
       catch {stream close $s}
    } 
Perform some random operations on a file making sure the 
stream gets closed, even if the user types control-C.

**Synopsis:**  
Allows one to ensure that clean-up for a sequence of commands will always 
happen, even if the user types control-C to interrupt the command.

**Notes:**

+ Since the interrupt can come at any time during the `<body>`, the 
`<cleanup>` command string should not rely on any particular variables 
being set. Hence the "catch" command used in the `<cleanup>` clause of 
the example. 

+ The `<cleanup>` clause will also be executed if any command in the `<body>` 
generates an error. 

**See Also:**  
catch.

----------

### range

**Usage:**  
`range <value> <first> <last> [chars]` 

**Examples:**  
`range {a b c} 1 end`  
Returns {b c} (element 1 to the end)

`range {hi mom} 3 end chars`  
Returns "mom"

**Synopsis:**  
Extracts a range of characters from a string, or elements from a list.

**Notes:**

+ If you give an ending index that is greater than the number of elements 
in the list (characters in the string), it will be adjusted to be the index of 
the last element (character). 

+ If you give a starting index that is greater than the number of elements 
in the list (characters in the string), the result will be the empty list 
(string). 

+ You can give `<end>` as "end" (without the quotation marks, of course) to 
indicate the extraction should go to the end of the list (string). 

+ The range is inclusive, so "range {a b c} 0 0" returns "a". 

+ Neither index may be less than 0 or "range" will generate an error.

+ Return a range of fields or characters from value.   If the chars keyword, 
or any abbreviation of it, is specified, then range treats `<value>` as a 
character string and returns characters `<first>` through `<last>` of it, 
inclusive. If `<last>` is less than `<first>` then an empty string is returned. 
Note: **range value first first** does not always produce the same results 
as **index value first** (although it often does for simple fields that are not 
enclosed in braces); it does, however, produce exactly the same results as 
**list [index value first]**.

**See Also:**  
index.

----------

### return

**Usage:**  
`return [<value>]`

**Examples:**  
`return $val`  
Returns the string in $val as the value for the current Tcl 
procedure.

**Synopsis:**  
Causes an immediate return from the current Tcl procedure, with or without 
a value.

**Notes:**

+ Every Tcl procedure returns a string for a value. If the procedure was 
called via command substitution (having been placed between square 
brackets as the argument to another command), the return value takes 
the place of the command invocation. 

+ Execution of the current procedure terminates immediately, though any 
`<cleanup>` clause for a containing "protect" command will still be 
executed. 

+ If no "return" command is invoked within a Tcl procedure, the procedure 
returns the empty string by default.

+ This command may be invoked only when a procedure call is in progress. 
It causes the current procedure to return immediately. If `<value>` is 
specified, it will be the return value from the procedure. Otherwise the 
current procedure will return the empty string.

**See Also:**  
error, proc, defsubr, defcommand, defcmd.

----------

### scan

**Usage:**  
`scan <string> <format> [<varname1> ]*`

**Examples:**  
`scan $input {my name is %s} name`  
Trims the leading string "my name is " from the string in 
$input and stores the rest of the string within the variable 
$name

**Synopsis:**  
"scan" parses fields from an input string, given the string and a format string 
that defines the various types of fields. The fields are assigned to variables 
within the caller's scope.

**Notes:**

+ The `<format>` string consists of literal text, which must be matched 
explicitly, and field definitions. The `<varName>` arguments are names of 
variables to which each successive field value is assigned. 

+ A single whitespace character (space or tab) will match any number of 
whitespace characters in the input string. Fields are specified as for the 
standard C library routine "sscanf":

    **%c** - A single character. The field value stored is the decimal number 
of the ASCII code for the character scanned. So if the character 
were a space, the variable would receive the string "32".  
    **%d** - A signed decimal integer is parsed and stored.  
    **%o** - An octal integer is parsed and stored, as a decimal number.  
    **%x** - A hexadecimal integer is parsed and stored, as a decimal 
number.  
    **%i** - A signed integer, following the standard C radix-specification 
standard, is parsed and stored as a decimal number.  
    **%f** - A floating-point number is parsed as a "float" and stored 
without exponent, unless the exponent is less than -4.  
    **%s** - A whitespace-terminated string is parsed and stored.  
    **%[<char-class>]** - A string consisting only of the characters in the given 
character class (see "string match" for details on character 
classes) is parsed and stored. The normal leading-whitespace 
skipping is suppressed.  
    **%%** - Matches a single percent sign in the input. 

+ If the % of a field specifier is followed by an *, the field is parsed as usual, 
consuming characters from the string, but the result is not stored 
anywhere and you should not specify a variable to receive the value. 

+ The maximum length of a field may be specified by giving a decimal 
number between the % and the field-type character. So "%10s" will 
extract out a string of at most 10 characters. 

+ There is currently a limit of 5 fields. 

**See Also:**	format.

----------

### source

**Usage:**  
`source <fileName>`

**Examples:**  
`source coolness`  
Evaluates all commands within the file "coolness.tcl" in the 
current directory.

**Synopsis:**  
Reads and evaluates commands from a file.

**Notes:**

+ If `<file`> has no extension and doesn't exist, "source" will append ".tcl" to 
the end and try and read that file.

+ The return value of source is the return value of the last command 
executed from the file. If an error occurs in executing the contents of the 
file, then the source command will return that error.

----------

### string

**Usage:**  
`string compare<string1> <string2> [no_case]`  
`string first<substring> <string> [no_case]`  
`string last<substring> <string> [no_case]`  
`string match<string> <pattern>`  
`string subst <string> <search> <replace> [global]` 

**Examples:**  
`if {[string c [index $args 1] all] == 0}`  
Do something if the 2nd element of the list in $args is the string 
"all".

`while {[string m [index $args 0] -*]}`  
Loop while the first element of the list in $args begins with a 
hyphen.

**Synopsis:**  
Examine strings in various ways.

**Notes:**

+ "string subst" searches `<string>` for occurrences of `<search>` and replaces 
them with `<replace>`. If 5th argument is given as "global" (it may be 
abbreviated), then all (non-overlapping) occurrences of `<search>` will be 
replaced. If 5th argument is absent, only the first occurrence will be 
replaced. 

+ "string compare" compares the two strings character-by-character. It 
returns -1, 0, or 1 depending on whether `<string1>` is lexicographically 
less than, equal to, or greater than `<string2>`. If the no_case parameter 
is passed than it does a case insensitive compare. 

+ "string first" searches `<string>` for the given `<substring>`. If it finds it, it 
returns the index of the first character in the first such match. If 
`<substring>` isn't part of `<string>`, it returns -1. If the no_case parameter 
is passed it does the search ignoring case. 

+ "string last" is much like "string first", except it returns the index of the 
first character of the last match for the `<substring>` within `<string>`. If 
there is no match, it returns -1. 

+ "string match" compares `<string>` against `<pattern>` and returns 1 if the 
two match, or 0 if they do not. For the strings to match, their contents 
must be identical, except that the following special sequences may 
appear in `<pattern>` with the following results:

    \* - Matches any sequence of characters, including none.  
    ? - Matches any single character  
    [<char-class>] - Matches a single character within the given set. The elements 
of the set are specified as single characters, or as ranges of the 
form `<start>-<end>`. Thus [0-9x] matches a single character 
that is a numeric digit or the letter x.  
    [^<char-class>] - Matches a single character not within the given set.  
    \\* - Matches an asterisk.  
    \? - Matches a question mark.  
    \[ - Matches an open-bracket.

**See Also:**  
case.

----------

### uplevel

**Usage:**  
`uplevel <level> <body>`  
`uplevel <function> <body>`

**Examples:**  
`uplevel print-frame {var found1}`  
Sets $found to 1 within the variables belonging to the nearest 
invocation of print-frame on the call stack.

`uplevel 0 {var foo-table}`  
Retrieves the value of the global variable foo-table.

`uplevel 1 {var found 1}`  
Sets $found to 1 within the scope of the procedure that called 
the one executing the "uplevel" command.

**Synopsis:**  
Provides access to the variables of another procedure for fairly specialized 
purposes.

**Notes:**

+ `<level>` is a signed integer with the following meaning:

    `> 0` - Indicates the number of scopes to go up. For example, if you say 
"uplevel 1 {var foo 36}", you would modify (or create) the 
variable "foo" in your caller's scope.  
    `<= 0` - Indicates the number of scopes to go down from the global one. 
"uplevel 0 `<body>` will execute <body> in the top-most scope, 
which means that no local variables are involved, and any 
variables created by the commands in `<body>` persist as global 
variables.

+ `<function>` is the name of a function known to be somewhere on the call 
stack. If the named function isn't on the call stack anywhere, "uplevel" 
generates an error. 

+ `<body>` may be spread over multiple arguments, allowing the command 
to be executed to use variables local to the current procedure as 
arguments without having to use the "list" command to form the `<body>`.

**See Also:**  
global.

----------

### var

**Usage:**  
`var <varname>`  
`var (<name> <value>)+`

**Examples:**  
`echo [var poof]`  
Prints the value stored in the variable "poof"

`var a b c d`  
Assigns the string "b" to the variable "a", and the string "d" to 
the variable "c".

`var yes $no no $yes`  
Exchanges the values of the "yes" and "no" variables 

**Synopsis:**  
This is the means by which variables are defined in Tcl. Less often, it is also 
used to retrieve the value of a variable (usually that's done via variable 
substitution).

**Notes:**

+ If you give only one argument, the value of that variable will be returned. 
If the variable has never been given a value, the variable will be created 
and assigned the empty string, then the empty string will be returned. 

+ You can set the value of a variable by giving the value as the second 
argument, after the variable name. No value is returned by the "var" 
command in this case. 

+ You can assign values to multiple variables "in parallel" by giving 
successive name/value pairs. 

+ If invoked in a procedure on a variable that has not been declared global 
(using the "global" command), this applies to the local variable of the 
given name, even if it has no value yet.

**See Also:**  
global.

### 5.6 Coding

This section provides information about the features and commands of Tcl 
that are important to know when using Swat, and the features and 
commands of Swat that are important to know when using Tcl. These 
features should be kept in mind while programming in Tcl because, if used 
properly, they make programming, debugging, and understanding existing 
commands much easier.This section will contain the following parts:

+ Swat Data Structures  
Descriptions of the major data structures and the commands that access 
them.

+ Examples

#### 5.6.1 Swat Data Structure Commands

`symbol, type, patient, handle, brk, cbrk, event, thread, 
src, cache, table`

This section contains information about Swat's built-in data structures and 
the commands that access them. These commands  examine and modify vital 
information about the state of GEOS while it is running under Swat. 

----------

### brk

**Usage:**  
`brk <addr> [<command>]`  
`brk pset <addr> [<command>]`  
`brk aset <addr> [<command>]`  
`brk tset <addr> [<command>]`  
`brk clear <break>*`  
`brk delete <break>*`  
`brk enable <break>*`  
`brk disable <break>*`  
`brk address <break>`  
`brk list [<addr>]`  
`brk debug [<flag>]`  
`brk isset <addr>`  
`brk cond <break> <condition>*`  
`brk cmd <break> [<command>]`  
`brk delcmd <break> [<command>]`

**Examples:**  
`brk WinOpen`  
Sets the machine to stop unconditionally when any thread calls 
WinOpen.

`brk pset WinOpen`  
Sets the machine to stop when any thread for the current 
patient calls WinOpen.

`brk tset WinOpen`  
 Sets the machine to stop when any thread for the current 
patient calls WinOpen, and deletes the breakpoint when the 
machine next stops.

`brk enable 1 3-5`  
Re-enables breakpoints 1, 3, 4, and 5

`brk clear 2-`  
Clears all breakpoints from number 2 onward.

`brk cond 3 cx=42`  
Sets breakpoint 3 to be conditional, stopping when the machine 
reaches the breakpoint's address with CX being 42.

`brk cond 2 (ss:0)!=1b80h`  
Sets breakpoint 2 to be conditional, stopping when the machine 
reaches the breakpoint's address with the word at ss:0 not 
being 1b80h. Note that the "ss" is the value of the ss register 
when the "brk cond" command is executed, not when the 
breakpoint is reached.

**Synopsis:**  
Allows you to specify that execution should stop when it reaches a particular 
point. These breakpoints can be conditional, and can execute an arbitrary Tcl 
command, which can say whether the machine is to remain stopped, or 
continue on its way.

**Notes:**

+ Once you've set a breakpoint, "brk" will return to you a token for that 
breakpoint that begins with "brk" and ends with a number. When you 
refer to the breakpoint, you can use either the full name (as you'll usually 
do from a Tcl procedure), or just the number.

+ Breakpoints have four attributes: the address at which they are set, the 
condition set on their being recognized, the Tcl command string to 
execute when they are recognized, and the Tcl command string to execute 
when they are deleted.

+ The condition is set either when the breakpoint is set, using the "cbrk" 
command, or after you've set the breakpoint, by invoking the "brk cond" 
command.

+ A breakpoint's condition is evaluated (very quickly) on the PC and can 
check only word registers (the 8 general registers, the three segment 
registers other than CS, and the current thread; each register may be 
checked only once in a condition) and a single word of memory. Each 
`<condition>` argument is of the form `<reg><op><value>`. `<reg>` is one of 
the 16-bit machine registers, "thread" (for the current thread), or the 
address of a word of memory to check, enclosed in parentheses. `<op>` is a 
relational operator taken from the following set:

    = - equal-to  
    != - not-equal-to  
    \> < >= <= - unsigned greater-than, less-than, greater-or-equal, and less-or-equal  
    +> +< +>= +<= - signed greater-than, less-than, greater-or-equal, and less-or-equal

`<value>` is a regular Swat address expression. If it is handle-relative, 
and the `<reg>` is one of the three non-CS segment registers, the condition 
will be for the segment of that handle and will change automatically as 
the handle's memory shifts about on the heap. Similar things will happen 
if you specify a number as the `<value>` for a segment register and the 
number is the current segment of a block on the heap. 

+ If you give no `<condition>` argument to the "brk cond" command, you will 
remove any condition the breakpoint might have, making it, therefore, 
unconditional. 

+ If a breakpoint is given an associated `<command>` string, it will be 
evaluated before the breakpoint is taken. If the result of the evaluation 
is an error, a non-numeric string, or a numeric string that's non-zero, the 
breakpoint will be taken. Otherwise, the machine will be allowed to 
continue (so long as no other breakpoint command or other part of Swat 
insists that it remain stopped). You can use this to simply print out 
information when execution reaches the breakpoint address without 
interrupting the machine's execution.

+ The global variable "breakpoint" contains the name of the breakpoint 
whose command is being evaluated while that command is being 
evaluated. 

+ You can change the command associated with a breakpoint with the "brk 
cmd" command. If you give no `<command>` argument, then no command 
will be executed and the breakpoint will always be taken, so long as any 
associated condition is also met. 

+ If a breakpoint has both a condition and a command, the command will 
not be executed until the condition has been met, unless there's another 
breakpoint at the same address with a different, or no, condition.

+ You can set a breakpoint to last only during the next continuation of the 
machine by calling "brk tset". The breakpoint thus set will be removed 
when next the machine comes to a full stop, regardless of why it stopped 
(i.e. if it hits a different breakpoint, the temporary breakpoint will still 
be removed). The breakpoint will only be taken if the thread executing 
when it is hit is owned by the patient that was current when the 
breakpoint was set.

+ Each `<break>` argument to the "brk clear", "brk enable" and "brk disable" 
commands can be either a single breakpoint token (or number), or a 
range of the form `<start>-<end>`, where either `<start>` or `<end>` may be 
absent. If `<start>` is missing, the command affects all breakpoints from 
number 1 to `<end>`. If `<end>` is missing, the command affects all 
breakpoints from `<start>` to the last one in existence.

+ If you give no `<break>` argument to "brk clear", "brk enable" or "brk 
disable", the command will apply to all breakpoints that are specific to 
the current patient, i.e. that were set with the "brk pset" command, 
unless the current patient is the kernel, in which case they will apply to 
all breakpoints that are specific to no patient (i.e. those set with the "brk 
aset" or `brk <addr>` commands).

+ "brk address" returns the address expression for where the breakpoint is 
set. This will usually be of the form `^h<handle-id>:<offset>`, with both 
`<handle-id>` and `<offset>` in hex (followed by an "h", of course). If the 
breakpoint is set at an absolute address, you will get back only a single 
hex number, being the linear address at which the breakpoint is set.

+ If you type "brk list" with no argument, Swat will print out a listing of the 
currently-active breakpoints. If you give an `<addr>` (address expression) 
argument, however, you'll be returned a list of the breakpoints set at the 
given address. If there are no breakpoints there, the list will be empty.

+ As a shortcut, you can invoke "brk isset" to see if any breakpoints are set 
at the given address, if you're not interested in which ones they are.

----------

### cache

**Usage:**  
`cache create (lru|fifo) <maxSize> [<flushProc>]`  
`cache destroy <cache> [flush|noflush]`  
`cache lookup <cache> <key>`  
`cache enter <cache> <key>`  
`cache invalone <cache> <entry>`  
`cache invalall <cache> [flush|noflush]`  
`cache key <cache> <entry>`  
`cache size <cache>`  
`cache maxsize <cache>`  
`cache setmaxsize <cache> <maxSize>`  
`cache getval <cache> <entry>`  
`cache setval <cache> <entry> <value>`

**Examples:**  
`var cache [cache create lru 10]`  
Creates a cache of 10 items that are flushed on a 
least-recently-used basis. The returned token is saved for later 
use.

`var entry [cache lookup $cache mom]`  
Sees if an entry with the key "mom" is in the cache and saves 
its entry token if so.

`echo mom=[cache getval $cache $entry]`  
Retrieves the value stored in the entry for "mom" and echoes it.

`cache invalone $cache $entry`  
Flushes the entry just found from the cache.

`cache destroy $cache`  
Destroys the cache.

**Synopsis:**  The cache command, as the name implies, maintains a cache of data that is 
keyed by strings. When a new entry is added to an already-full cache, an 
existing entry is automatically flushed based on the usage message with 
which the cache was created: lru (last recently used) or fifo (first in, first out). 
If lru, the least-recently-used entry is flushed; if fifo, the oldest entry is 
flushed.

**Notes:**	

+ Unlike the "table" command, the "cache" command returns tokens for 
entries, not their values. This allows entries to be individually flushed or 
their values altered.

+ If a `<flushProc>` is specified when the cache is created, the procedure will 
be called each time an entry is flushed from the cache. It will be called 
`<flushProc> <cache> <entry>` where `<cache>` is the token for the cache, 
and `<entry>` is the token for the entry being flushed.

+ If the maximum size of a full cache is reduced, entries will be flushed 
from the cache to bring it down to the new maximum size. The 
`<flushProc>` will be called for each of them.

+ If the values stored in the cache entries should not be freed when the 
cache is destroyed, pass "noflush" to "cache destroy". The default is to 
flush (and hence call the `<flushProc>`) all entries from the cache before it 
is destroyed.

+ If the values stored in the cache entries should not be freed when the 
cache is flushed, pass "noflush" to "cache invalall". The default is to call 
the `<flushProc>` for each entry in the cache before it is actually flushed.

+ If an entry is not found in the cache, "cache lookup" will return an empty 
string.

+ When an entry is created, "cache enter" returns a 2-list containing the 
entry token as its first element, and an integer, as its second element, 
that is either non-zero or 0, to tell if the entry is new or was already 
present, respectively.

----------

### cbrk

**Usage:**  
`cbrk <addr> <condition>*`  
`cbrk aset <addr> <condition>*`  
`cbrk tset <addr> <condition>*`  
`cbrk clear <break>*`  
`cbrk delete <break>*`  
`cbrk enable <break>*`  
`cbrk disable <break>*`  
`cbrk address <break>`  
`cbrk list [<addr>]`  
`cbrk debug [<flag>]`  
`cbrk isset <addr>`  
`cbrk cond <break> <condition>*`  
`cbrk cmd <break> [<command>]`  
`cbrk delcmd <break> [<command>]`

**Examples:**  
`cbrk WinOpen di=1b80h`  
Stops the machine when execution reaches WinOpen() with di 
set to 1b80h.

**Synopsis:**  
Allows you to set fast conditional breakpoints.

**Notes:**

+ All these subcommands function the same as for the "brk" command, 
with the exception of the "aset" and "tset" commands, which expect the 
condition for the breakpoint, rather than an associated command. 

+ There are a limited number of these sorts of breakpoints that can be set 
in the PC (currently 8), so they should be used mostly for 
heavily-travelled areas of code (e.g. inner loops, or functions like 
**ObjCallMethodTable()** in the kernel). 

+ For more information on the subcommands and the format of arguments, 
see the documentation for the "brk" command.

----------

### event

**Usage:**  
`event <subcommand>`

**Synopsis:**  
The event command provides access to Swat's internal events. The 
subcommands are as follows:

**`handle <eventName> <handler> [<data>]`**  
The `<handler>` procedure is invoked each time an event of type 
<`eventName>` is dispatched. The handler receives two arguments: an 
event-specific piece of data, and the given `<data>`. A handler procedure 
should be declared  
`proc <handler> {arg data} {<body>}`  
	The handle subcommand returns an <event> for later use in deleting it. 
The `<handler>` should return one of **event\_handled**, 
**event\_not\_handled**, or **event\_stop_handling**. If it returns 
**event\_stop\_handling**, the event will not be dispatched to any other 
handlers of the event.

**`delete <event>`**  
Deletes the given event handler given by the **event handle** command.

**`dispatch <eventName> <arg>`**  
Dispatches the given event with the given `<arg>` to all handlers of that 
event. If `<eventName>` is a pre-defined event type, `<arg>` will be 
converted to the appropriate type before being dispatched. Otherwise it 
is passed as a string.

**`create`**  
Returns a number that represents a new event type. Handlers may then 
be defined for and events dispatched of the new type.

**`list`**  
Lists all Tcl-registered events by event-name and handler function.

The events which are currently defined are:

FULLSTOP - 
Generated when patient stops for a while. Argument is string telling why 
the patient stopped.

CONTINUE - 
Generated just before the patient is continued. The argument is non-zero 
if going to single-step.

TRACE - Generated when the execution of a source line completes and the patient 
is in line-trace mode.

START - Generated when a new patient/thread is created. Argument is patient 
token of the patient involved.

STACK - Current stack frame has changed. The argument is non-zero if the stack 
change comes from a change in patients/threads or zero if the change 
comes from actually going up or down the stack in the current patient.

DETACH - Detaching from the PC. The argument is always zero.

RESET - Returning to the top level. The argument is always zero.

ATTACH - Attached to the PC. The argument is always zero.

RELOAD - Kernel was reloaded. The argument is always zero.

CHANGE - Current patient has changed. The argument is the token for the previous 
patient.

STEP - Machine has stepped a single instruction. The argument is the value to 
pass to **patient stop** if you wish the machine to stay stopped.

STOP - Machine has hit a breakpoint. The argument is the value to pass to 
**patient stop** if you wish the machine to stay stopped.

INT - Machine has hit some other interrupt that's being caught. The argument 
is the interrupt number. The machine will remain stopped unless it is 
continued with continue-patient.

----------

### handle

**Usage:**  
`handle lookup <id>`  
`handle find <address>`  
`handle all`  
`handle nointerest <interest-record>`  
`handle interest <handle> <proc> [<data>+]`  
`handle segment <handle>`  
`handle size <handle>`  
`handle state <handle>`  
`handle owner <handle>`  
`handle patient <handle>`  
`handle other <handle>`  
`handle id <handle>`  
`handle isthread <handle>`  
`handle iskernel <handle>`  
`handle isfile <handle>`  
`handle isvm <handle>`  
`handle ismem <handle>`  

**Examples:**  
`handle lookup [read-reg bx]`  
get the handle token for the handle whose ID is in the BX 
register.

`handle interest $h ob-interest-proc [concat si=$chunk $message]`  
call ob-interest-proc, passing the list {si=$chunk $message}, 
whenever the state of the handle whose token is in $h changes.

`handle patient $h`  
get the token for the patient that owns the handle whose token 
is in $h

`handle all`  
get the list of the ID's of all handles currently in Swat's handle 
table.

**Synopsis:**  
The "handle" command provides access to the structures Swat uses to track 
memory and thread allocation on the PC.

Notes:

+ As with most other commands that deal with Swat structures, you use 
this one by calling a lookup function (the "lookup" and "find" 
subcommands) to obtain a token that you use for further manipulations. 
A handle token is also returned by a few other commands, such as 
addr-parse.

+ Handle tokens are valid only until the machine is continued. If you need 
to keep the token for a while, you will need to register interest in the 
handle using the "interest" subcommand. Most handles tokens will 
simply be cached while the machine is stopped and flushed from the 
cache when the machine continues. Only those handles for which all 
state changes must be known remain in Swat's handle table. For 
example, when a conditional breakpoint has been registered with the 
stub using the segment of a handle, the condition for that breakpoint 
must be updated immediately should the memory referred to by the 
handle be moved, swapped or discarded. Keeping the number of tracked 
handles low reduces the number of calls the stub must make to tell Swat 
about handle-state changes.

+ The `<id>` passed to the "lookup" subcommand is an integer. Its default 
radix is decimal, but you can specify the radix to use in all the usual 
ways. The value returned is the token to use to obtain further 
information about the handle.

+ "handle size" returns the number of bytes allocated to the handle.

+ "handle segment" returns the handle's segment (if it's resident) in 
decimal, as it's intended for use by Tcl programs, not people.

+ "handle owner" returns the token of the handle that owns the given 
handle, not its ID.

+ "handle all" returns a list of handle ID numbers not a list of handle 
tokens. The list is only those handles currently known to Swat.

+ "handle interest" tells Swat you wish to be informed when the handle you 
pass changes state in some way. The procedure `<proc>` will be called with 
two or more arguments. The first is the token of the handle whose state 
has changed, and the second is the state change the handle has 
undergone, taken from the following set of strings:

    **swapin** - Block swapped in from disk/memory

    **load** - Resource freshly loaded from disk

    **swapout** - Block swapped to disk/memory

    **discard** - Block discarded

    **resize** - Block changed size and maybe moved

    **move** - Block moved on heap

    **free** - Block has been freed

    **fchange** - Block's **HeapFlags** changed

    Any further arguments are taken from the `<data>+` arguments provided 
when you expressed interest in the handle. This subcommand returns a 
token for an interest record that you pass to "handle nointerest" when you no 
longer care about the handle. When the block is freed (the state change is 
"free"), there is no need to call "handle nointerest" as the interest record is 
automatically deleted.

+ "handle state" returns an integer indicating the state of the handle. The 
integer is a mask of bits that mean different things:


**Table 5-3** *The State Subcommand: Block Information*

----------

	Mask		State			Mask		State  
	0xf8000		Type			0x00200		Attached  
	0x00040		Discarded		0x00008		Fixed  
	0x00001		Resident		0x00800		LMem  
	0x00100		Process			0x00020		Swapped  
	0x00004		Discardable		0x00400		Kernel  
	0x00080		Resource		0x00010		Shared  
	0x00002		Swapable

When the integer is AND-ed with the mask for Type (0xf8000), the following 
values indicate the following types of handles:

**Table 5-4** *The State Subcommand: Block Type*

----------

	Mask		State  
	0xe0000		Thread  
	0xb0000		Semaphore  
	0x80000		Event with stack data chain  
	0x70000		Stack data chain element  
	0xd0000		File  
	0xa0000		Saved block  
	0x08000		Memory  
	0xc0000		VM File  
	0x90000		Event  
	0x60000		Timer  
	0x40000		Event queue

+ "handle other" returns the handle's otherInfo field. Note: This isn't 
necessarily the otherInfo field from the PC. E.g., for resource handles, it's 
the symbol token of the module for the handle.

----------

### patient

**Usage:**  
`patient find <name>`  
`patient name [<patient>`  
`patient fullname [<patient>]`  
`patient data [<patient>]`  
`patient threads [<patient>]`  
`patient resources [<patient>]`  
`patient libs [<patient>]`  
`patient path [<patient>]`  
`patient all`  
`patient stop [<addr>]`

**Examples:**  
`patient find geos`  
Returns the patient token for the kernel, if it's been loaded yet.

`patient fullname $p`  
 Returns the permanent name for the patient whose token is 
stored in the variable p.

`patient stop $data`  
Tells the dispatcher of the STEP event that it should keep the 
machine stopped when the STEP event has been handled by 
everyone.

**Synopsis:**  
This command provides access to the various pieces of information that are 
maintained for each patient (geode) loaded by GEOS.

**Notes:**

+ Subcommands may be abbreviated uniquely.

+ Swat always has the notion of a "current patient", whose name is 
displayed in the prompt. It is this patient that is used if you do not 
provide a token to one of the subcommands that accepts a patient token.

+ "patient name" returns the name of a patient. The name is the non- 
extension portion of the geode's permanent name. It will have a number 
added to it if more than one instance of the geode is active on the PC. 
Thus, if two GeoWrites are active, there will be two patients in Swat: 
"write" and "write2".

+ "patient fullname" returns the full permanent name of the patient. It is 
padded with spaces to make up a full 12-character string. This doesn't 
mean you can obtain the non-extension part by extracting the 0th 
element of the result with the "index" command, however; you'll have to 
use the "range" command to get the first 8 characters, then use "index" to 
trim the trailing spaces off, if you want to.

+ "patient data" returns a three-element list: `{<name> <fullname> 
<thread-number>}` `<name>` and `<fullname>` are the same as returned by 
the "name" and "fullname" subcommands. `<thread-number`> is the 
number of the current thread for the patient. Each patient has a single 
thread that is the one the user looked at most recently, and that is its 
current thread. The current thread of the current patient is, of course, 
the current thread for the whole debugger.

+ "patient threads" returns a list of tokens, one for each of the patient's 
threads, whose elements can be passed to the "thread" command to 
obtain more information about the patient's threads (such as their 
numbers, handle IDs, and the contents of their registers).

+ "patient resources" returns a list of tokens, one for each of the patient's 
resources, whose elements can be passed to the "handle" command to 
obtain more information about the patient's resources (for example, their 
names and handle IDs).

+ "patient libs" returns a list of patient tokens, one for each of the patient's 
imported libraries. The kernel has all the loaded device drivers as its 
"imported" libraries.

+ "patient path" returns the absolute path of the patient's executable.

+ "patient all" returns a list of the tokens of all the patients known to Swat.

+ "patient stop" is used only in STEP, STOP and START event handlers to 
indicate you want the machine to remain stopped once the event has been 
dispatched to all interested parties. `<addr>` is the argument passed in 
the STEP and STOP events. A START event handler should pass 
nothing.

+ A number of other commands provide patient tokens. "patient find" isn't 
the only way to get one.

----------

### src

**Usage:**  
`src line <addr>`  
`src read <file> <line>`  
`src cache [<max>]`  
`src addr <file> <line> [<patient>]`

**Examples:**  
`src line cs:ip`  
Returns a two-list holding the source-line number, and the 
absolute path of the file in which it lies (not in this order), that 
encompasses CS:IP.

`src read /pcgeos/appl/sdk_c/hello/hello.goc 64`  
Reads the single given source line from the given file.

`src addr icdecode.c 279`  
Returns an address-list for the start of the code produced for 
the given line.

`src cache 10`  
Allow 10 source files to be open at a time. This is the default.

**Synopsis:**  
The "src" command allows the Tcl programmer to manipulate the source- line 
maps contained in all the geodes' symbol files.

**Notes:**

+ The "src line" commands returns its list as `{<file> <line>}`, with the `<file>` 
being absolute. If no source line can be found, the empty list is returned.

+ The `<file>` given to the "src read" command must be absolute, as the 
procedure using this command may well be wrong as to Swat's current 
directory. Typically this name will come from the return value of a "src 
line" command, so you needn't worry.

+ The line returned by "src read" contains no tabs and does not include the 
line terminator for the line (the `<lf>` for UNIX, or the `<cr><lf`> pair for 
MS-DOS).

+ "src addr" returns an address-list, as returned from "addr-parse", not an 
address expression, as you would pass to "addr-parse". If the `<file>` and 
`<line>` cannot be mapped to an address, the result will be the empty list.

+ The `<file>` given to "src addr" must be the name that was given to the 
assembler/compiler. This includes any leading path if the file wasn't in 
the current directory when the assembler/compiler was run.

+ "src cache" returns the current (or new) number of open files that are 
cached.

----------

### symbol

**Usage:**  
`symbol find <class> <name> [<scope>]`  
`symbol faddr <class> <addr>`  
`symbol match <class> <pattern>`  
`symbol scope <symbol>`  
`symbol name <symbol>`  
`symbol fullname <symbol>`  
`symbol class <symbol>`  
`symbol type <symbol>`  
`symbol get <symbol>`  
`symbol patient <symbol>`  
`symbol tget <symbol>`  
`symbol addr <symbol>`  
`symbol foreach <scope> <class> <callback> [<data>]`

**Examples:**  
`symbol find type LMemType"`  
Locate a type definition named LMemType

`symbol faddr proc cs:ip`  
Locate the procedure in which CS:IP lies.

`symbol faddr {proc label} cs:ip`  
Locate the procedure or label just before cs:ip.

`symbol fullname $sym`  
Fetch the full name of the symbol whose token is in the $sym 
variable.

`symbol scope $sym`  
Fetch the token of the scope containing the passed symbol. This 
will give the structure containing a structure field, or the 
procedure containing a local variable, for example.

**Synopsis:**  
Provides information on the symbols for all currently-loaded patients. Like 
many of Swat's commands, this operates by using a lookup function (the 
"find", "faddr", "match", or "foreach" subcommands) to obtain a token for a 
piece of data that's internal to Swat. Given this token, you then use the other 
subcommands (such as "name" or "get") to obtain information about the 
symbol you looked up.

**Notes:**

+ There are many types of symbols that have been grouped into classes 
that may be manipulated with this command. For a list of the symbol 
types and their meaning, type "help symbol-types". The type of a symbol 
can be obtained with the "symbol type" command.

+ The symbol classes are as follows:

	**type** - describes any structured type: typedef, struct, record, etype, 
union. Symbols of this class may also be used in place of type 
tokens (see the "type" command).

	**field** - describes a field in a structured type: field, bitfield.

	**enum** - describes a member of an enumerated type: enum, message.

	**const** - a constant defined with EQU: *const*.

	**var** - describes any variable symbol: var, chunk, locvar, class, 
masterclass, variantclass.

	**locvar** - describes any local variable symbol: locvar, locstatic.

	**scope** - describes any symbol that holds other symbols within it: 
module, proc, blockstart, struct, union, record, etype.

	**proc** - describes only proc symbols.

	**label** - describes any code-related symbol: label, proc, loclabel.

	**onstack** - describes only symbols created by the directive.

	**module** - describes only segment/group symbols.

	**profile** - describes a symbol that marks where profiling code was 
inserted by a compiler or assembler.

+ The `<class>` argument for the "find", "faddr" and "match" subcommands 
may be a single class, or a space-separated list of classes. For example, 
"symbol faddr {proc label} CS:IP" would find the symbol closest to CS:IP 
(but whose address is still below or equal to CS:IP) that is either a 
procedure or a label.

+ The "symbol find" command locates a symbol given its name (which may 
be a symbol path).

+ The "symbol faddr" command locates a symbol that is closest to the 
passed address.

+ A symbol's "fullname" is the symbol path, from the current patient, that 
uniquely identifies the symbol. Thus if a procedure-local variable belongs 
to the current patient, the fullname would be  
 `<segment>::<procedure>::<name>`  
 where `<segment>` is the segment holding the `<procedure>`, which is the 
procedure for which the local variable named <name> is defined.

+ You can force the prepending of the owning patient to the fullname by 
passing `<with-patient>` as a non-empty argument ("yes" or "1" are both 
fine arguments, as is "with-patient").

+ The "symbol get" commands provides different data for each symbol 
class, as follows:

	`var, locvar, chunk: {<addr> <sclass> <type>}`  
`<addr>` is the symbol's address as for the "addr" subcommand, 
`<sclass>` is the storage class of the variable and is one of static 
(a statically allocated variable), lmem (an lmem chunk), local (a 
local variable below the frame pointer), param (a local variable 
above the frame pointer), or reg (a register variable; address is 
the machine register number -- and index into the list returned 
by the "current-registers" command).

	`object class: {<addr> <sclass> <type> <flag> <super>}`  
first three elements same as for other variables. `<flag>` is 
"variant" if the class is a variant class, "master" if the class is a 
master class, or empty if the class is nothing special. `<super>` 
is the symbol token of the class's superclass.

	`label-class: {<addr> (near|far)}`  
`<addr>` is the symbol's address as for the "addr" subcommand. 
The second element is "near" or "far" depending on the type of 
label involved.

	`field-class: {<bit-offset> <bit-width> <field-type> <struct-type>}`  
`<bit-offset>` is the offset of the field from the structure/union/record's base 
expressed in bits. `<bit-width>` is the width of the field, in bits. 
`<field-type>` is the type for the field itself, while `<struct-type>` 
is the token for the containing structured type.

	`const: {<value>}`  
`<value>` is just the symbol's value.

	`enum-class: {<value> <etype>}`  
`<value>` is the symbol's value. `<etype>` is the enumerated type's 
symbol.

	`blockstart, blockend: {<addr>}`  
`<addr>` is the address bound to the symbol.

	`onstack: {<addr> <data>}`  
`<addr>` is the address at which the ON_STACK was declared. 
`<data>` is the arguments given to the ON_STACK directive.

	`module: {<patient>}`  
`<patient>` is the token for the patient owning the module.

+ A related command, "symbol tget" will fetch the type token for symbols 
that have data types (var-, field- and enum-class symbols).

+ "symbol addr" can be used to obtain the address of symbols that actually 
have one (var-, locvar- and label-class symbols). For locvar symbols, the 
address is an offset from the frame pointer (positive or negative). For var- 
and label-class symbols (remember that a procedure is a label-class 
symbols), the returned integer is the offset of the symbol within its 
segment.

+ "symbol patient" returns the token of the patient to which the symbol 
belongs.

+ "symbol foreach" will call the `<callback>` procedure for each symbol in 
`<scope>` (a symbol token) that is in one of the classes given in the list 
`<class>`. The first argument will be the symbol token itself, while the 
second argument will be `<data>`, if given. If `<data>` wasn't provided, 
`<callback>` will receive only 1 argument. `<callback>` should return 0 to 
continue iterating, or non-zero to stop. A non-integer return is assumed 
to mean stop. "symbol foreach" returns whatever the last call to 
`<callback>` returned.

+ By default, "symbol scope" will return the physical scope of the symbol. 
The physical scope of a symbol is the symbol for the segment in which the 
symbol lies, in contrast to the lexical scope of a symbol, which is where 
the name of the symbol lies. The two scopes correspond for all symbols 
but static variables local to a procedure. To obtain the lexical scope of a 
symbol, pass `<lexical>` as a non-zero number.

**See Also:**  
symbol-types, type

----------

### table

**Usage:**  
`table create [<initBuckets>]`  
`table destroy <table>`  
`table enter <table> <key> <value>`  
`table lookup <table> <key>`  
`table remove <table> <key>`

**Examples:**

`var kitchen [table create 32]`  
Create a new table with 32 hash buckets initially.

`table enter $t tbrk3 {1 2 3}`  
Enter the value "1 2 3" under the key "tbrk3" in the table whose 
token is stored in the variable t.

`table lookup $t tbrk4`  
Fetch the value, if any, stored under the key "tbrk4" in the table 
whose token is stored in the variable t.

`table remove $t tbrk3`  
Remove the data stored in the table, whose token is stored in 
the variable t, under the key "tbrk3"

`table destroy $t`  
Destroy the table $t and all the data stored in it.



----------
**Swat Display 5-1 The table Structure**

`(mess1:0) 159 => var yearTable [table create]`  
`(mess1:0) 160 => table enter $yearTable synclavier 1979`  
`(mess1:0) 161 => table enter $yearTable moog 1966`  
`(mess1:0) 162 => table lookup $yearTable synclavier
1979`  
`(mess1:0) 163 => var yearTable
1403188`  
`(mess1:0) 164 => table lookup 1403188 moog
1966`  
`(mess1:0) 165 => table remove $yearTable synclavier`  
`(mess1:0) 166 => table lookup $yearTable synclavier
nil`  
`(mess1:0) 167 => table destroy $yearTable`

----------

**Synopsis:**  
The "table" command is used to create, manipulate and destroy hash tables. 
The entries in the table are keyed on strings and contain strings, as you'd 
expect from Tcl.

**Notes:**

+ The `<initBuckets>` parameter to "table create" is set based on the 
number of keys you expect the table to have at any given time. The 
number of buckets will automatically increase to maintain hashing 
efficiency, should the need arise, so `<initBuckets>` isn't a number that 
need be carefully chosen. It's best to start with the default (16) or perhaps 
a slightly larger number.

+ If no data are stored in the table under `<key>`, "table lookup" will return 
the string "nil", for which you can test with the "null" command.

----------

### thread

**Usage:**  
`thread id <thread>`  
`thread register <thread> <regName>`  
`thread handle <thread>`  
`thread endstack <thread>`  
`thread number <thread>`  
`thread all`

**Examples:**  
`thread register $t cx`  
Fetches the value for the CX register for the given thread.

`thread number $t`  
Fetches number swat assigned to thread when it was first 
encountered.

----------
**Swat Display 5-2 The thread Structure**

`(mess1:0) 145 => patient threads
2667104`  
`(mess1:0) 146 => thread id 2667104
11184`  
`(mess1:0) 147 => thread all
767532 756068 1348520 1348868 1349216 1349748 1350236 1402096 1079392 2667104`  
`(mess1:0) 148 => thread handle 756068
880428`  
`(mess1:0) 149 => thread number 756068
0`

----------

**Synopsis:**  
Returns information about a thread, given its thread token. Thread tokens 
can be obtained via the "patient threads" command, or the "handle other" 
command applied to a thread handle's token.

**Notes:**

+ Subcommands may be abbreviated uniquely.

+ "thread id" returns the handle ID, in decimal, of the thread's handle. This 
is simply a convenience.

+ "thread register" returns the contents of the given register in the thread 
when it was suspended. All registers except "pc" are returned as a single 
decimal number. "pc" is returned as two hexadecimal numbers separated 
by a colon, being the cs:ip for the thread. Note that GEOS doesn't actually 
save the AX and BX registers when it suspends a thread, at least not 
where Swat can consistently locate them. These registers will always 
hold 0xadeb unless the thread is the current thread for the machine (as 
opposed to the current thread for swat).

+ "thread handle" returns the token for the thread's handle.

+ "thread endstack" returns the maximum value SP can hold for the 
thread, when it is operating off its own stack. Swat maintains this value 
so it knows when to give up trying to decode the stack. 

+ "thread number" returns the decimal number Swat assigned the thread 
when it first encountered it. The first thread for each patient is given the 
number 0 with successive threads being given the highest thread number 
known for the patient plus one. 

+ "thread all" returns a list of tokens for all the threads known to Swat (for 
all patients).

----------

### type

**Usage:**  
`type <basic-type-name>`  
`type make array <length> <base-type>`  
`type make pstruct (<field> <type>)+`  
`type make struct (<field> <type> <bit-offset> <bit-length>)+`  
`type make union (<field> <type>)+`  
`type make <ptr-type> <base-type>`  
`type delete <type>`  
`type size <type>`  
`type class <type>`  
`type name <type> <var-name> <expand>`  
`type aget <array-type>`  
`type fields <struct-type>`  
`type members <enum-type>`  
`type pget <ptr-type>`  
`type emap <num> <enum-type>`  
`type signed <type>`  
`type field <struct-type> <offset>`  
`type bfget <bitfield-type>`

**Examples:**  
`type word`  
Returns a type token for a word (2-byte unsigned quantity).

`type make array 10 [type char]`  
Returns a type token for a 10-character array.

`type make optr [symbol find type GenBase]`  
Returns a type token for an optr (4-byte global/local handle 
pair) to a "GenBase" structure.

**Synopsis:**  
Provides access to the type descriptions by which all PC-based data are 
manipulated in Swat, and allows a Tcl procedure to obtain information about 
a type for display to the user, or for its own purposes. As with other Swat 
commands, this works by calling one subcommand to obtain an opaque "type 
token", which you then pass to other commands.

**Notes:**

+ Type tokens and symbol tokens for type-class symbols may be freely 
interchanged anywhere in Swat.

+ There are 11 predefined basic types that can be given as the 
`<basic-type-name>` argument in "type `<basic-type-name>`". They are: 
**byte** (single-byte unsigned integer), **char** (single-byte character), 
**double** (eight-byte floating-point), **dword** (four-byte unsigned integer), 
**float** (four-byte floating-point), **int** (two-byte signed integer), **long** 
(four-byte signed integer), **sbyte** (single-byte signed integer), **short** 
(two-byte signed integer), **void** (nothing. useful as the base type for a 
pointer type), and **word** (two-byte unsigned integer)

+ Most type tokens are obtained, via the "symbol get" and "symbol tget" 
commands, from symbols that are defined for a loaded patient. These are 
known as "external" type descriptions. "Internal" type descriptions are 
created with the "type make" command and should be deleted, with "type 
delete" when they are no longer needed.

+ An internal structure type description can be created using either the 
"pstruct" (packed structure) or "struct" subcommands. Using "pstruct" is 
simpler, but you have no say in where each field is placed (they are placed 
at sequential offsets with no padding between fields), and all fields must 
be a multiple of 8 bits long. The "struct" subcommand is more complex, 
but does allow you to specify bitfields.

+ "type make pstruct" takes 1 or more pairs of arguments of the form 
`<field> <type>`, where `<field>` is the name for the field and `<type>` is a 
type token giving the data type for the field. All fields must be specified 
for the structure in this call; fields cannot be appended to an existing type 
description.

+ "type make struct" takes 1 or more 4-tuples of arguments of the form 
`<field> <type> <bit-offset> <bit-length>`. `<field>` is the name of the 
field, and `<type>` is its data type. `<bit-offset>` is the offset, in bits, from 
the start of the structure (starting with 0, as you'd expect). `<bit-length>` 
is the length of the field, in bits (starting with 1, as you'd expect). For a 
bitfield, `<type>` should be the field within which the bitfield is defined. 
For example, the C declaration:

	struct {

		word a:6;  
		word b:10;  
		word c;  
	}

    would result in the command "type make struct a [type word] 0 6 b [type 
word] 6 10 c [type word] 16 16", because a and b are defined within a word 
type, and c is itself a word.

+ "type make union" is similar to "type make pstruct", except all fields start 
at offset 0. Like "pstruct", this cannot be used to hold bitfields, except by 
specifying a type created via "type make struct" command as the `<type>` 
for one of the fields.

+ "type make array `<length> <base-type>`" returns a token for an array of 
`<length>` elements of the given `<base-type>`, which may be any valid type 
token, including another array type.

+ "type make `<ptr-type> <base-type>`" returns a token for a pointer to the 
given `<base-type>`. There are 6 different classes of pointers in GEOS:

    **nptr** - a near pointer. 16-bits. points to something in the same 
segment as the pointer itself.

    **fptr** - a far pointer. 32-bits. segment in high word, offset in the low.

    **sptr** - a segment pointer. 16-bits. contains a segment only.

    **lptr** - an lmem pointer. 16-bits. contains a local-memory "chunk 
handle". data pointed to is assumed to be in the same segment 
as the lptr itself, but requires two indirections to get to it.

    **hptr** - a handle pointer. 16-bits. a GEOS handle.

    **optr** - an object pointer. 32-bits. contains a GEOS memory handle in 
the high word, and a GEOS local-memory chunk handle in the 
low.

+ "type delete" is used to delete a type description created by "type make". 
You should do this whenever possible to avoid wasting memory.

+ Any type created by the "type make" command is subject to garbage 
collection unless it is registered with the garbage collector. If you need to 
keep a type description beyond the end of the command being executed, 
you must register it. See the "gc" command for details.

+ "type size" returns the size of the passed type, in bytes.

+ "type class" returns the class of a type, a string in the following set:

    **char** - for the basic "char" type only.

    **int** - any integer, signed or unsigned.

    **struct** - a structure, record, or union.

    **enum** - an enumerated type.

    **array** - an array, of course,

    **pointer** - a pointer to another type.

    **void** - nothingness. Often a base for a pointer.

    **function** - a function, used solely as a base for a pointer.

    **float** - a floating-point number.

+ Each type class has certain data associated with it that can only be 
obtained by using the proper subcommand.

+ "type aget" applies only to an array-class type token. It returns a 
four-element list: `{<base-type> <low> <high> <index-type>}` `<base-type>` 
is the type token describing elements of the array. `<low>` is the lower 
bound for an index into the array (currently always 0), `<high>` is the 
inclusive upper bound for an index into the array, and `<index-type>` is a 
token for the data type that indexes the array (currently always [type 
int]).

+ "type fields" applies only to a struct-class type token. It returns a list of 
four-tuples `{<name> <offset> <length> <type>}`, one for each field in the 
structure. `<offset>` is the bit offset from the start of the structure, while 
`<length>` is the length of the field, again in bits. `<type>` is the token for 
the data type of the field, and `<name>` is, of course, the field's name.

+ "type members" applies only to an enum-class type token. It returns a list 
of `{<name> <value>}` pairs for the members of the enumerated type. 

+ "type pget" applies only to a pointer-class type token. It returns the type 
of pointer ("near", "far", "seg", "lmem", "handle", or "object") and the 
token for the type to which it points.

+ "type bfget" returns a three-list for the given bitfield type: `{<offset> 
<width> <is-signed>}`

+ "type signed" returns non-zero if the type is signed. If the `<type>` is not 
an int-class type, it is considered unsigned.

+ "type emap" can be used to map an integer to its corresponding 
enumerated constant. If no member of the enumerated type described by 
`<type>` has the value indicated, "nil" is returned, else the name of the 
matching constant is returned.

+ "type field" maps an offset into the passed struct-class type into a triple 
of the form `{<name> <length> <ftype>}`, where `<name>` can be either a 
straight field name, or a string of the form `<field>.<field>...` with as many 
.`<field>` clauses as necessary to get to the smallest field in the nested 
structure `<type>` that covers the given byte `<offset>` bytes from the start 
of the structure. `<length>` is the bit length of the field, and `<ftype>` is its 
type.

+ "type name" produces a printable description of the given type, using C 
syntax. `<varname>` is the name of the variable to which the type belongs. 
It will be placed at the proper point in the resulting string. If `<expand>` 
is non-zero, structured types (including enumerated types) are expanded 
to display their fields (or members, as the case may be).

**See Also:**  
gc, symbol, symbol-types, value

#### 5.6.2 Examples

This section will contain a few examples of Tcl code for Swat commands, 
showing the use of some of included Tcl commands. A good way to view the 
code for a particular procedure is to type:

`info body <procname>`

on the Swat command line. This will print out the body of the given 
`<procname>` . One thing to watch out for, however, is the case when a 
procedure has not been loaded into Swat yet (i.e. it has not been used yet). If 
this is the case, Swat will have no information about the procedure and will 
thus print nothing. The command must be loaded into Swat either with the 
load command, or by just typing the command name which will usually 
autoload the command. (See section 5.7.) Then the `info body 
<procname>` command can be used.

Some code examples:

----------

**Swat Display 5-3 The Whatat Command**

	[defcommand whatat {addr} output
	{Given an address, print the name of the variable at that address}
	{
		var a [sym faddr var $addr]
		if {[null $a]}{
		 echo *nil*
	} else {
		echo [sym name $a]
	}
	}]

This example shows the code of the **whatat** command. Note the use of the **sym** (an abbreviation for 
symbol) command to find the address of the given variable `<addr>` of class `<var>`.

----------

**Swat Display 5-4 The Bytes Command**

	1	var addr [get-address $addr ds:si]
	2	var base [index [addr-parse $addr] 1]
	3	echo {Addr: +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +a +b +c +d +e +f}
	4	#fetch the bytes themselves
	5	var bytes [value fetch $addr [type make array $num [type byte]]]
	6	#
		# $s is the index of the first byte to display on this row, $e is the
		# index of the last one. $e can get > $num. The loop handles this case.
		#
		var s 0 e [expr 16-($base&0xf)-1]
		#
		# $pre can only be non-zero for the first line, so set it once here.
		# We'll set it to zero when done with the first line.
		# $post can be non-zero only for the last line, but we can't just
		# set it to zero and let the loop handle it, as the first may be the
		# last, so-
		#
		var pre [expr 16-($e-$s)-1]
		if {$e > $num} {
		var post [expr $e-($num-1)]
		} else {
		var post 0
		} 

		[for {var start [expr {$base&~0xf}]}
		{$s < $num}
		{var start [expr $start+16]}
		{
	28	#extract the bytes we want
	29	var bs [range $bytes $s $e]
	30	echo [format {%04xh: %*s%s%*s "%*s%s%*s"} $start
		[expr $pre*3] {}
		[map i $bs {format %02x $i}]
		[expr $post*3] {}
		$pre {}
		[mapconcat i $bs {
		if {$i >= 32 && $i < 127} {
		format %c $i
		} else {
		format .
		}
		}]
		$post {}]
		var s [expr $e+1] e [expr $e+16] pre 0
		if {$e >= $num} {
		var post [expr $e-($num-1)]
		}
		}]
		set-address $addr+$num-1
		set-repeat [format {$0 {%s} $2} $addr+$num]

This example shows the code for the **bytes** commands. Notice the use of the **type** command on the 
fifth line, and the **range** command on the twenty-ninth line.

----------

### 5.7 Using a New Command

Once a new command is written, it needs to be loaded into Swat so that it can 
be used. Depending on how the command is to be used, you may be interested 
in any of the following topics:

+ Compilation

+ Autoloading

+ Explicit loading

#### 5.7.1 Compilation

It is possible to byte-compile a Tcl script. The **bc** Tcl command creates a .TLC 
file containing compiled Tcl code-this code will run faster than normal Tcl 
code. When loading, Swat will load a .TLC file instead of a .TCL file where 
possible. Making changes to compiled Tcl functions involves changing the 
source code and re-compiling.

#### 5.7.2 Autoloading

If the development environment has been set up properly, there should 
already exist the **/pcgeos/Tools/swat/lib** directory on the workstation. This 
directory will contain all of the code files for the built-in Swat commands. To 
autoload a new command, copy its code file to the **/pcgeos/Tools/swat/lib** 
directory and add its name to the **autoload**.tcl file in the directory. This will 
load the command into Swat every time Swat is started. For example, say the 
command **blitzburp** has just been written to examine a new data structure. 
First, copy the file containing its code (say **blitz**.tcl) into the 
**/pcgeos/Tools/swat/lib** directory. Next, edit the **autoload**.tcl file and add 
one of the following lines:

`[autoload blitzburp 0 blitz]`

`[autoload blitzburp 1 blitz]`

This will ensure that **blitz.tcl** will be loaded when the command **blitzburp** 
is first used. The 0 indicates that the command must be typed exactly, and 
the 1 indicates that the interpreter will not evaluate arguments passed to the 
command. (See "Swat Reference," Chapter 4, for more information on the 
**autoload** command.)

#### 5.7.3 Explicit Loading

Another way to load a command into Swat is to use the **load** command from 
the Swat command line. This command is simply `load <path>/<filename>`. 
If no path is given, then the `<file>` is loaded from the directories specified in 
the load-path variable. The **load** command will load the given file (a Tcl 
procedure or subroutine) into Swat for subsequent use, and it is mostly used 
to load infrequently accessed files. (See "Swat Reference," Chapter 4, for 
more information on the **load** command.)

[Swat Reference J-Z](tswtj_z.md) <-- &nbsp;&nbsp; [Table of Contents](../tools.md) &nbsp;&nbsp; --> [Debug Utility](tdebug.md)