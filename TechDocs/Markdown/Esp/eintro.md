## 1 Introduction to Esp

This software development kit is geared towards C programmers. The SDK is 
based around the GEOS-specific language Goc, which is based on C. Very few 
programmers will ever need to use anything else. However, a few 
programmers will want to write the most efficient code possible; for their 
benefit, this SDK lets you program in Esp, the GEOS assembly language.

Only experienced GEOS programmers should attempt to program in 
assembly. Furthermore, the SDK is not intended to teach assembly language; 
you should be familiar with 80x86 assembly before you attempt to program 
in Esp.

### 1.1 What is Esp?

Esp is an 80x86 assembly language specially designed for GEOS 
programming. In many ways, it is very similar to other common 80x86 
assemblers (such as MASM). On a low level, inside a routine, Esp code looks 
very much like MASM code (though it provides some extra features). 
However, on a higher level, Esp resembles MASM much less, and resembles 
Goc much more.

Esp incorporates support for the GEOS object-oriented programming 
environment. It provides routines to let you send messages and manipulate 
objects. Furthermore, all GEOS kernel routines and system libraries may be 
called from either Goc or Esp code. Thus, programming in Esp is very much 
like programming in Goc. The routines are written in a different language, 
but they fit together into a program in much the same way that Goc routines 
do.

In addition to Esp, this SDK provides a special User-Interface Compiler 
(UIC). The UIC generates object-blocks for assembly applications. It reads 
source files written in the GEOS-specific language Espire, and creates special 
resources that Glue can incorporate into GEOS applications. If you write 
applications in assembly language, you will use the UIC to create objects and 
object blocks at compile time.

Many of the sample applications provided with this SDK have been written 
twice: once in Goc (in the APPL/SDK_C directory), and once in Esp (in the 
APPL/SDK_ASM directory). These sample applications are an excellent way to 
familiarize yourself with Esp; you can see how the same task is accomplished 
in Goc and Esp. In particular, they will let you compare Esp and Goc 
techniques for creating structures and classes, and compare Goc and Espire 
techniques for creating objects and classes.

### 1.2 Should I Use Esp?

Not everyone will want to use Esp. For many programmers, assembly 
language is much harder to use than high-level languages like Goc. You may 
not find the gains in program efficiency worth this extra effort.

There are some cases when you should consider using Esp. Firstly, if you are 
very familiar with 80x86 assembly language, and feel as comfortable with it 
as with C, you may prefer to write your programs in Esp. Once you've written 
a few programs, you may find Esp as easy a language to work with as Goc.

Secondly, if you are writing computation-intensive programs, you may find 
that they are running too slowly (especially if you are writing them for GEOS 
platforms with less processing power). In these cases, you may wish to 
rewrite the programs in Esp. Alternatively, you may choose to put the most 
memory-intensive routines in special "Esp resources"; you can write those 
routines in Esp, while writing the rest of the application in Goc.

Thirdly, if you are writing a library that will be used by many different 
applications, you may wish to write that library in Esp. If it is a routine 
library, you will merely need to write Esp routines that conform to C 
pass-and-return conventions; then any application, whether written in Goc 
or in Esp, will be able to call those routines. Similarly, if the library defines 
new object classes, you can write the message handlers in Esp; any 
application that uses those objects will be able to take advantage of the added 
efficiency of Esp, even if the application is written in Goc.

### 1.3 Roadmap to the Esp Book

The Esp book is fairly short. This is because its main role is to help you 
integrate knowledge you already have. You should already know how to 
program for GEOS, and how to program in non-GEOS assembly language for 
the 80x86; this book tells you how to combine this knowledge, and describes 
the special features of Esp.

The book has the following chapters:

1. [Introduction to Esp (this chapter)](eintro.md)  
This chapter gives a brief overview of Esp, the GEOS assembly 
language, and of this book.

2. [Esp Basics](ebasics.md)  
This chapter describes the basic syntactic differences between 
Esp and other 80x86 assembly languages (such as MASM). It 
also describes the basic ground rules for programming in 
assembly in the GEOS environment.

3. [Routine Writing](erout.md)  
This chapter describes how to write routines in Esp. It 
discusses Esp's special features that make routine-writing 
simpler and more uniform, by taking care of such chores as 
creating local variables, managing stack frames, etc. It also 
discusses how to write handlers and send messages in Esp.

4. [The UI Compiler](euic.md)  
This chapter describes the GEOS User-Interface Compiler 
(UIC), a special utility that compiles Esp object blocks. You will 
need to use UIC if you are writing an Esp application that has 
any objects created at compile-time.

The book also contains an appendix which describes, briefly, how to 
incorporate Esp resources into a Goc application.

When you are ready to start programming, you will want to consult the 
Assembly Reference for Esp API of GEOS routines and structures and to 
consult the PCGEOS\INCLUDE\*.DEF and *.UIH files for assembly 
information about GEOS object classes. To find out a message's pass and 
return parameters, see the class's .def file; for more generic information 
about a message, you can see its (Goc) reference entry in the Objects book.

&nbsp;&nbsp; [table of contents](../esp.md) &nbsp;&nbsp; --> [Esp Basics](ebasics.md)

