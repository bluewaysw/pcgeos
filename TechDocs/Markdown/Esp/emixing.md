## E Mixing C and Assembly

You may sometimes wish to combine Goc and Esp code in a single application. 
There are two main times when you may want to do this. You may be writing 
an application in Goc, but find that the application is spending a lot of time 
in a few critical routines; in this case, you may be able to improve efficiency 
by rewriting those few routines in assembly. If you don't want to rewrite the 
rest of the application, you will have to write those routines so they can be 
called from C.

On the other hand, you may be writing a library that has a lot of 
time-consuming routines. In this case, you may find it worthwhile to rewrite 
the entire library in assembly, while preserving a Goc interface. That way, all 
the applications that use the library will be able to take advantage of the 
efficiency of assembly code. (For example, most GEOS system libraries are 
written in assembly.)

In particular, if you design a new object class that is being used by many 
different applications, it may be worthwhile to write a library which defines 
that class of object. You can write all the method code in assembly, while 
providing a Goc interface; this lets every application that uses the class take 
advantage of assembly's efficiency.

### E.1 Adding Esp Code to a Goc Geode

Most people will find it easiest to write applications in Goc. For most 
purposes, Goc is efficient enough; after all, whenever an application is 
running a system routine, or sending a message to a system-defined object, 
it is most likely executing assembly code.

However, some applications may have very computation-heavy, 
time-consuming routines. This can be exacerbated if the application is 
intended to run on a slower platform, or if the time-consuming routines 
cannot (for some reason) be compiled efficiently. In this case, you can 
sometimes improve efficiency significantly by rewriting just those routines in 
assembly language.

All the routines in any single code resource must be written in the same 
language (Goc or Esp). You will therefore have to segregate your Esp routines 
into one or more resources. Since you lose efficiency if resources are too small, 
it may be best to simply put all the Esp routines into a single resource. 
Simply write an assembly file with the routines; then declare all the routines 
in a C header file as "extern". mkmf will automatically generate appropriate 
instructions to compile and link the two resources.

You should write the Esp routines so they conform to C pass-and-return 
conventions. Ordinarily, we recommend that you write routines using the 
"pascal" convention. Under this convention, arguments are pushed on the 
stack in the same order that they are passed. For example, if the routine 
MyFunc() has the following declaration:

~~~
extern word 
    _pascal MyFunc(word firstVar, 
        byte    secondVar,
        dword   thirdVar);
~~~

then firstVar would be pushed on the stack first; next secondVar would be 
pushed (taking up a full word, even though it's only one byte long); then 
thirdVar would be pushed (first the high word, then the low word). When the 
assembly routine returned, it would simply load the return value into ax, and 
this value would be returned to the caller. (Byte-sized values are returned in 
al; dword-sized values are returned in dx:ax.)

If you use the pascal calling conventions, you can simply use Esp's techniques 
for declaring passed arguments; declare them in the same order as in the C 
declaration. For example, suppose the C declaration of MyFunc() is as 
shown above. In the assembly resource, you could write MyFunc() like this:

~~~
MyFunc proc far firstVar:word, secondVar:byte, thirdVar:dword

.enter

; routine code... return value ends up in ax

.leave

        ret

MyFunc endp
~~~

If you must have the routine use C calling conventions, remember that the 
arguments are passed in the opposite order they are declared. This is useful 
if the routine has a variable number of arguments, but in other situations, 
it's just a nuisance.

### E.2 Writing an Esp Library

You may wish to write a library in Esp whose routines can be called by either 
Goc or Esp code. This is very much like writing a library in Goc. Simply write 
all the exported routines to use pascal pass-and-return conventions. 
Remember to write both a Goc header file and an Esp header file; that way, 
an application can include whichever of these is appropriate. Make sure that 
both of these header files are maintained in tandem, and accurately reflect 
the state of the library.

If you are writing an object library, you will need to write an Espire header 
file (.uih), as well as the Goc and Esp header files. All three header files must 
be maintained in tandem. Espire is discussed in ["The UI Compiler", Chapter 4](euic.md).

[The UI Compiler](euic.md) <-- &nbsp;&nbsp; [table of contents](../esp.md) 

