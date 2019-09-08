## 2 Esp Basics

Esp is an assembly language for 80x86 microprocessors. It is designed for 
creating applications, libraries, and drivers that will run under GEOS. As 
such, it is very similar to other common 80x86 assembly languages (such as 
MASM), but has special features and functionality to make it easier to write 
GEOS code.

To experienced MASM programmers, Esp code will be easy to read. Variable 
declarations will be slightly different, and there will be a few instructions 
(actually pseudo-ops) which look new. Nevertheless, Esp code will look very 
familiar. This chapter describes the stylistic differences between Esp and 
MASM.

This book assumes that you already know how to program in 80x86 assembly 
language.

### 2.1 The Purpose of Esp

Esp is mainly a superset of MASM. With the exception of a few special cases 
(which are noted in this chapter), MASM code can be ported intact to Esp 
programs without requiring major modifications. You should not find it hard 
to reuse your existing code.

Esp is, however, philosophically different from other assembly languages. It 
is designed for an object-oriented, multitasking environment. This means 
that it works with different assumptions from other assembly languages. 

### 2.2 Esp Ground Rules

There are certain rules you must follow when programming in Esp. These 
rules are imposed by the nature of GEOS.

If you violate these rules, the results are unpredictable. Error-checking code 
may find violations of these rules; however, this is not guaranteed. Therefore, 
you must be sure to follow the rules under all circumstances.

#### 2.2.1 GEOS is a Multitasking Environment

GEOS uses preemptive multitasking. It uses interrupts to halt each thread's 
execution when its allotted time slice ends. This has two major consequences 
for assembly programs. First, there are more interrupts being sent than you 
might expect. Second, if interrupts are disabled, this drastically degrades 
GEOS's performance; under almost no circumstances should a geode disable 
interrupts. In fact, under the GEOS API, only the kernel and drivers are 
permitted to disable interrupts; libraries and applications must leave 
interrupts enabled at all times.

Experienced MASM programmers will already know how to cope with 
interrupts, but it's worth reiterating the basic rules. The main thing to 
remember is that the interrupt handlers use the stack to save the state. The 
interrupt can occur after any instruction. Whenever you use an instruction 
which alters the stack, or makes assumptions about the stack, you should ask 
yourself what would happen if a context switch occurred right before or right 
after that instruction.

For example, suppose you want to read the top word on the stack into cx, but 
you want it to stay on the stack. The canonical way to do this would be the 
following:

~~~
pop	cx	; Read the value . . .
push	cx	; . . . and push it back.
~~~

This takes only two bytes and 27 cycles; this is fairly good for a memory 
reference. An overzealous optimizer might think, "Well, that word's still right 
there above the stack, so we don't have to push it back, do we?" He might 
write the following bad code:

~~~
pop	cx
sub	sp, 2	; THIS IS VERY BAD
~~~

"Aha," he might think, "This takes only 16 cycles!" Unfortunately, the code is 
extremely fragile. If a context switch occurs right after the pop, the interrupt 
handler will push all the registers onto the stack; this will overwrite the data 
at that location. The worst part is that this bug is intermittent; the code will 
work fine, as long as the context switch doesn't occur at that precise location. 
That means the bug can easily sneak through testing.

It bears repeating: Whenever you perform an unusual operation on the stack, 
ask yourself what would happen if a context switch occurred immediately 
before or immediately after the instruction.

#### 2.2.2 Upward and Downward Compatibility

GEOS is intended to run on a wide range of platforms, from 8088-based 
machines up through powerful desktop computers (80486s and beyond). 
Because of this, you should avoid writing code that makes assumptions about 
which processor is being used. Even if you know you're writing for a GEOS 
platform which uses a particular processor, you should write more flexible 
code; this will make it much easier to port the code across several GEOS 
platforms.

The main thing is to use only those instructions that are available on all 
80x86 machines. (This also means not using instruction variants which are 
available on only some machines; for example, you may not pass an 
immediate argument to shl). Do not try to access the 80386's 32-bit 
registers. 

A future version of GEOS may take advantage of protected mode in more 
powerful chips. Again, if you take certain precautions, your code will run 
unchanged under this version of GEOS. You must follow these rules:

+ Perform no arithmetic on segment register values. In protected mode, a 
segment register doesn't contain a physical segment address; rather, it 
contains an index (or selector) into a hardware segment descriptor table. 
Adding one to a segment register doesn't advance it 16 bytes, as in real 
mode; it changes it to a completely different selector.

+ Do not attempt to access interrupt vectors except through GEOS. Very 
few applications will need to do anything like this, anyway.

+ Do not try to use the sti, cli, in or out instructions in applications or 
libraries; they are privileged instructions under protected mode. Only 
drivers and the kernel may use these instructions.

+ Do not try to write self-modifying code. It is extremely difficult to do this 
under protected mode.

+ Do not try to use segment registers for temporary data storage. Under 
protected mode, the processor will complain if you load anything but a 
valid selector into a segment register.

There is currently no way for geodes to use a floating-point coprocessor 
directly. However, all GEOS floating-point routines will automatically use a 
floating-point coprocessor if one is present.

#### 2.2.3 Flags

GEOS makes certain assumptions about the flags.Your application must 
follow these if it is to work with GEOS properly.

The 80x86 flags are divided into two groups: status flags and control flags. 
There are five status flags: the overflow flag, the sign flag, the zero flag, the 
auxiliary-carry flag, and the carry flag (abbreviated as OF, SF, ZF, AF, and CF, 
respectively). Status flags provide information about the results of recent 
operations. For example, if the result of a subtraction operation is zero, the 
zero flag (ZF) is set. Routines are allowed to set and change these status flags 
at will. Even if a routine says that it destroys nothing, it is presumed to 
destroy all the status flags unless it specifically says "flags preserved." Some 
routines will return flags with meaningful settings; for example, many 
routines set CF to indicate an error, and clear it otherwise. In these cases, the 
routine's reference will describe all values returned in flags. By the same 
token, you may call routines with any settings you wish for the status flags, 
unless the routine specifically requires that the status flags have certain 
settings.

There are three control flags: the direction flag, the interrupt flag, and the 
trap flag (abbreviated as DF, IF, and TF, respectively). These flags change how 
the processor operates. Routines have much less leeway about how and 
whether to use these flags.

Most routines should leave interrupts enabled. In practice, only drivers will 
need to disable interrupts. Most kernel routines require that they be called 
with interrupts enabled. If a routine doesn't specifically say that it can be 
called with interrupts disabled, then it cannot be. This is not an issue for 
most programmers, since the GEOS API permits only drivers to disable 
interrupts.

All GEOS routines assume that the direction flag (DF) is cleared. Feel free to 
set this flag before using string instructions; however, you should make sure 
to clear DF before calling any kernel routine. Again, some routines may 
specifically permit you to call them with DF set; you should not assume this 
is the case unless the routine reference says so.

You should never change TF; this is used by the debugger.

### 2.3 Differences from MASM

Esp has a number of differences with other 80x86 assemblers. Some of these 
are entirely transparent to the programmer; these differences will not be 
detailed here.

The main algorithmic difference between Esp and MASM is that Esp only 
reads the source code once. As a result, MASM directives that rely on multiple 
passes are treated differently; for example, the IF1 and IF2 directives are 
both synonymous with IF.

In all cases where an algorithmic break is not involved, you can force Esp to 
use the MASM syntax and directives by passing the flag "-m".

#### 2.3.1 Data Types

Esp makes it easy to declare and define structures, records, enumerated 
types, and similar constructs. Its conventions are, however, slightly different 
from those of MASM; you should be aware of these differences.

##### 2.3.1.1 Constants

Esp's rules for constants are almost the same as MASM's. Esp is slightly more 
versatile. For example, hexadecimal constants may be specified with either 
the MASM convention or the C convention; that is, "123h" is exactly the same 
as "0x123". 

A single character surrounded by double quotes is parsed as the ASCII value 
of that character; for example,

~~~
LETTER_A		= "a"
~~~

is identical to 

~~~
LETTER_A		= 61h
~~~

You may use any of the standard C character escapes; these are listed in 
Table 2-2. Since "\" is the escape character, you have to use a 
doubled backslash to put a backslash in the character string; that is, "\\" 
specifies the single character 5Ch.

##### 2.3.1.2 Simple Types

Esp defines many standard data types beyond those provided by MASM. 
These types can be used alone, or they can serve as building blocks for 
structures. The types are listed in Table 2-1.

|Type      |Size |Description                                            |
|:---------|:----|:------------------------------------------------------|
|byte      |1    |Unsigned 8-bit integer (0 to 255); synonym is "db"     |
|sbyte     |1    |Signed 8-bit integer (-128 to 127); synonym is "sb"    |
|char      |1    |GEOS character; synonym is "dc"                        |
|word      |2    |Unsigned 16-bit integer (0 to 65,535)                  |
|sword     |2    |Signed 16-bit integer (-32,768 to 32,767)              |
|dword     |4    |Unsigned 32-bit integer (0 to 4,294,967,296)           |
|sdword    |2    |Signed 32-bit integer (-2,147,483,648 to 2,147,483,647)|
|nptr      |2    |Near pointer (i.e. offset address)                     |
|fptr      |4    |Far pointer (i.e. segment + offset)                    |
|hptr      |2    |Global handle                                          |
|lptr      |2    |Chunk handle (i.e. near pointer to a near pointer)     |
|optr      |4    |object descriptor; high word is hptr, low word is lptr |
|sptr      |2    |Segment address (or descriptor).                       |
**Table 2-1** Major Esp Data Types  
_These are the main Esp data types, with their size in bytes._

Swat can read symbolic information about the data types to display their 
values in the most useful format. For example, if you have an array of **bytes** 
containing the values 46h, 6Fh, 6Fh, 21h, Swat will display the hex values; 
but if the same values are **sbytes**, Swat will display them as signed, decimal 
integers (i.e. "70, 111, 111, 33"); and if they are declared as an array of 
**char**s, Swat will translate the values into ASCII characters (i.e "Foo!"). 
Similarly, Swat can use the information about a pointer's type to display its 
referent appropriately.

##### 2.3.1.3 Enumerated Types

Sometimes you will have a variable that indicates one of a number of 
conditions by holding an arbitrarily-chosen integer. For example, you may 
have variables that indicate a month, using a different integer to indicate 
each month. In these cases, it is best to create an enumerated type. 
Enumerated types let you use the values by name, making the code much 
easier to read. Furthermore, when you use Swat to examine a variable of an 
enumerated type, you will (by default) be shown the value's name instead of 
its numerical value; this makes debugging easier.

Esp gives you considerable control over enumerated types. You can declare 
how long the values will be, what the initial value should be, and by how 
much the values should be incremented. To define a new enumerated type, 
use a declaration of the format 

~~~
<typename> etype <size> [, <first> [, <step>]]
~~~

**typename**  
Any arbitrary name for the type. Usually this will begin with 
the application's name, to avoid conflicting with other 
enumerated type names. By convention, the type name is 
singular (i.e. "HelloColor", not "HelloColors").

**size**  
The size of values of this type. This may be either of the 
reserved words "word" or "byte".

**first**  
The value of the first member of the type. This defaults to zero.

**step**  
The increment between members of the type. This defaults to one.

Each member of the enumerated type is declared like this:

~~~
<name> enum <typename> [, <value>]
~~~

**name**  
The name of this member of the type. As a matter of 
convention, the name of each member of a type begins with an 
abbreviation of the type name; for example, a member of 
HelloColor might be named HC_BLUE.

**typename**   
The name of the enumerated type.

**value**  
The value of this member of the type. This defaults to the 
previous element's value plus the step specified in the type 
declaration.

For example, to declare an enumerated type for the months of the year, you 
might do this:

---
Code Display 2-1 Declaring an Enumerated Type
~~~
HelloMonth		etype byte, 1 		; One byte is enough to hold the twelve months.
				; We specify that the first month should have a
				; value of one, as is conventional.

HM_JANUARY		enum HelloMonth
HM_FEBRUARY		enum HelloMonth
HM_MARCH		enum HelloMonth		; and so on . . .
~~~

Note that members of the enumerated type need not be declared all at once. 
You can have other declarations, or even code, intervening. 

The name of the enumerated type will always evaluate to one step more than 
the last member of the enumerated type (that is, the last one before the use 
of the type's name; more members could be declared later). You can use this 
to verify that a value is in bounds for an enumerated type. For example, 
suppose you had the following enumerated type:

~~~
MyColor		etype byte 0, 2

MC_BLUE		enum MyColor ; MC_BLUE = 0
MC_RED		enum MyColor ; MC_RED = 2
MC_GREEN		enum MyColor ; MC_GREEN = 4
~~~

At this point, the name MyColor would evaluate to 6, i.e. MC_GREEN plus 
the step-value of two. If a routine expected to be passed a member of the 
MyColor enumerated type, it could check this by comparing the value to the 
value of MyColor.

##### 2.3.1.4 Structures

Esp lets you define structures. Structure declarations have the following 
format:

~~~
<StructureType>    	struct
    <FieldName>     <FieldType> [<DefaultValue>]
                    ;any number of these

<StructureType>			ends
~~~

**StructureType**  
This may be any valid, unique identifier.

**FieldName**  
This may be any valid, unique identifier.

**FieldType**  
This may be any previously-defined type. It may be a simple 
type, an array, a record, another structure, or any other type you wish.

**DefaultValue**  
This is the default value for this field of the structure.

The fields are declared from low to high. That is, the first field named is at 
the low end of the structure, and has the same address as the structure itself.

For example, you might declare a simple data structure like this:

~~~
MyDataStructure   struct
    MDS_aField       sbyte
    MDS_anotherField sword    -1
    MDS_oneLastField dword
MyDataStructure   ends
~~~

You can declare and initialize one of these structures much the same way as 
you would an array:

~~~
aStructure        MyDataStructure    <1,2,3>
~~~

This format is versatile. If you leave a space blank, it will automatically be 
initialized to the default value (or zero, if no default value was specified). If 
you don't put any values between the angle-brackets, the whole structure will 
be initialized to its default values. Thus,

~~~
aStructure        MyDataStructure    <>
~~~

is equivalent to

~~~
aStructure		MyDataStructure			<0, -1, 0>
~~~

One of the fields of a structure may be another structure. For example, you 
might make the following declaration:

~~~
MyOtherStructure			struct
	MOS_char1			char
	MOS_char2			char
	MOS_dataStruct			MyDataStructure
	MOS_signedLong			sdword
MyOtherStructure			ends
~~~

You might initialize the structure like this:

~~~
bigStruct    MyDataStructure    <'a', , <1,2,3>, -0xabcd123>
~~~

As noted above, the MOS_char2 field would be initialized to zero.

Esp evaluates a field name as the displacement from the start of the 
structure to the start of the field. For example, if MyStructure is defined as 
shown above, then MDS_aField would evaluate as zero, MDS_anotherField as 
one, and MDS_oneLastField as three. You can use these displacements to 
access fields by using the dot operator or the bracket operator. Both of these 
are addition operators for calculating effective addresses. Several 
displacements can be used sequentially. For example, suppose we declared 
bigStruct as shown above. We want to load the MDS_anotherField field from 
that structure into ax. If es:[di] was the address of the bigStruct 
variable, we could do the following:

~~~
mov	ax, es:[di].MOS_dataStruct.MDS_anotherField
~~~

Esp would figure out the displacement from the start of a 
MyOtherStructure to the MOS_dataStruct field; it would add this to the 
displacement from the start of a MyDataStructure to the MDS_int2 field, 
and use the combined displacement in the instruction, producing an 
equivalent machine instruction, e.g. 

~~~
mov	ax, es:[di].3
~~~

You can use the dot operator this way in any effective-address instruction.

##### 2.3.1.5 Unions

Esp supports unions as well as structures. A union is a variable that might, 
at different times, have values of different sizes or types.

A union is declared much like a structure. The basic format is:

~~~
<UnionType>			union
	<FieldName>		<FieldType> [<DefaultValue>]
				;any number of these

<UnionType>			ends
~~~

**UnionType**  
This may be any valid, unique identifier.

**FieldName**  
This may be any valid, unique identifier.

**FieldType**  
This may be any previously-defined type. It may be a simple 
type, an array, a record, a structure, or any other type you wish.

**DefaultValue**  
This is the default value for this field of the union.

Every field of the union begins at the base of the union, and the union is as 
large as its largest component field. For example,

~~~
MyUnion  union
	MU_sbyte    sbyte		-2
	MU_word     word		1234
MyUnion  ends
~~~

would declare a union with two fields. The union would be two bytes long.

Unions are initialized slightly differently from structures. You can initialize 
a union to all zeros by putting nothing between the angle brackets, e.g.

~~~
aVariable		MyUnion		<>
~~~

You can initialize the union to contain the default value for one of its 
components by putting the component's name between the angle brackets, 
e.g.

~~~
aVariable		MyUnion		<MU_sbyte>
~~~

would initialize the first byte of the union to 0xfd (i.e. -2), and clear the 
second byte. If you wish to override the default value, simply put the new 
value after the field name, like so:

~~~
aVariable		MyUnion		<MU_sbyte 12>
~~~

##### 2.3.1.6 Records

Sometimes you will need to store several pieces of information, each of which 
can be represented in less than a byte. One common situation is when you 
need to have several flags for an object. Each one of the flags is a boolean 
quantity, so it can be represented with one bit; it would be inefficient to store 
each flag in its own byte-sized variable.

Esp allows you to declare byte- or word-sized records. Each field of the record 
may be one or more bits long; multi-bit fields may hold values from an 
appropriately-sized enumerated type. A record declaration has the following 
format:

~~~
<recordname>			record
	[<fieldname> [<type>]] :<size> [= <value>]
	;...there may be many such lines

<recordname>			ends
~~~

**recordname**  
This is the name of the record. It usually begins with the 
geode's name, to ensure that the name won't conflict with a 
name in an included header file.

**fieldname**  
The name of the field. If a field has no name, you cannot 
directly access it; thus, nameless fields can be used to pad the 
record to byte- or word-length.

**type**  
If the field contains a member of an enumerated type, you 
should specify the type here.

**size**  
This is the size of the field in bits. The combined sizes of the 
fields should not be greater than sixteen.

**value**  
You may specify a default value here. If a variable of this record 
is declared without initializers, the field will be initialized to 
this value.

The fields are declared from high to low; that is, the first field declared 
occupies the high end of the record. However, the last field declared always 
has an offset of zero; that is, it is always at the extreme low end of the record. 
Thus, if the fields don't add up to a full byte or word, there will be unused bits 
at the high end of the record. The size of the record is equal to the total width 
of the fields, rounded up to the next byte.

In order to read a field from a record, you need to know the field's position in 
the record, and you need to know how long the field is. Esp gives you this 
information with the reserved words offset, mask, and width. 
"offset <fieldName>" is assembled into the field's offset from the low end 
of the record; that is, shifting the record to the right by this amount will bring 
the field to bit 0. "mask <fieldName>" is assembled into a byte or word, as 
appropriate, with all the bits in the specified field set, and all the other bits 
cleared. You can also take the mask of a record; "mask <recordName>" 
assembles to a mask with all bits in named fields turned on, and all other bits 
turned off. "width <fieldName>" assembles to the width of the field, in 
bits.

For example, suppose you define the record HelloRecord thus:

~~~
HelloRecord			record
	HR_A_FLAG:1
	HR_ZERO_TO_SEVEN:3
	HR_ANOTHER_FLAG:1
HelloRecord			ends
~~~

In this case, "mask HR_ZERO_TO_SEVEN" would assemble to 0eh, 
"offset HR_ZERO_TO_SEVEN" would assemble to 1, and 
"width HR_ZERO_TO_SEVEN" would assemble to 3. "mask HelloRecord" 
would assemble to 1Fh. If you wanted to load HR_zeroToSeven into ax, you 
would do the following (assuming es:[di] pointed to the record):

~~~
mov	ax, es:[di]		;load the record into ax
and	ax, mask HR_ZERO_TO_SEVEN
				; Clear the other fields
mov	cl, offset HR_ZERO_TO_SEVEN
shr	ax, cl
~~~

To test if a given flag (e.g. HR_aFlag) was set, you would simply do this:

~~~
test	es:[di], mask HR_zero
~~~

Note that in Esp, unlike MASM, you must use either mask or offset to 
access a field. If you use the name of the field without either of these 
keywords, Esp will generate an error. (You can return to default MASM 
behavior by assembling with the "-m" switch; in this case, "<fieldName>" 
will be considered equivalent to "offset <fieldName>".)

You can initialize a record in much the same way that you initialize a 
structure, i.e. by putting the values in angle-brackets. It is important to note 
that the initializers only initialize named fields; all unnamed fields are 
automatically initialized to zero. For example, suppose you declared 
GapRecord thus:

~~~
GapRecord		record
	GR_A_BIT:1
	GR_A_NYBBLE:4
	:2
	GR_ANOTHER_BIT:3
GapRecord ends
~~~

And then declared a variable thus:

~~~
instanceOfGR			GapRecord		<0x1,0xF,0x7>
~~~

instanceOfGR will be initialized to 0x03E7; the two bits between 
GR_A_NYBBLE and GR_ANOTHER_BIT will be initialized to zero.

You can also use the name of the record, combined with the initializer, as an 
immediate value. For example, the instruction

~~~
move	ax, GapRecord <0x1, 0xF, 0x3>
~~~

assembles equivalently to 

~~~
move	ax, 0x03E7
~~~

##### 2.3.1.7 Creating New Types

Esp overloads the TYPE operator as a type-creation directive. It is useful if 
you will be creating many arrays of exactly the same size. This is the format:

~~~
<TypeName>		TYPE	<n> dup(<BaseType>)
~~~

**TypeName**  
The name of the new type.

**n**  
The number of elements in the array.

**BaseType**  
The type of each element in the array.

Variables of this type will be initialized to all zeros, unless you specify an 
initial value with MASM's usual array-initializer (angle-bracket) syntax.

For example, you might store social-security numbers in arrays which are 
nine bytes long (with one byte per digit). In this case, you could make the 
following declaration:

~~~
SocSecNum		TYPE 9 dup(byte)
~~~

You could declare one of these variables and initialize it like this:

~~~
FranksSSN		SocSecNum <1,2,3,4,5,6,7,8,9>
~~~

---
Code Display 2-2 Data Structure Declaration Examples
~~~
COMMENT@-------------------------------------------------------------------
	This shows how you might combine various Esp types, and how you
	might use those declarations in code.
---------------------------------------------------------------------------@

;
; Types
;

MyColor		etype byte

MC_CLEAR		enum MyColor		; This defaults to zero
MC_BLACK		enum MyColor		; This is MC_CLEAR + 1, or one
MC_WHITE		enum MyColor		; 2...
MC_RED		enum MyColor
MC_BLUE		enum MyColor
MC_GREEN		enum MyColor

MyRecord		record
	MR_BIG:1
	MR_COLOR MyColor:8
	MR_POINTY:1
MyRecord		end

ShortString		TYPE	9 dup(char)

MyStructure		struct
	MS_number		sword
	MS_label		ShortString
	MS_record		MyRecord
MyStructure		ends

;
; Initialized Variables
;

idata	segment

AStructure		MyStructure		<-123, <"Foo!", 0>,
				(mask MR_BIG OR (MC_RED SHL offset MR_COLOR))>

idata	ends
~~~

#### 2.3.2 Symbols and Labels

Esp improves on MASM's rules for symbols and labels.

You can declare a local label in Esp. A local label's scope is limited to the 
procedure that contains it. Local labels in Esp have independent 
namespaces; that is, you might have several routines, each of which contains 
the label "done:"; whenever you use the label, Esp would understand it to be 
the version defined locally.

All labels inside of procedures are presumed to be local. If you want to use the 
label outside of the procedure, you should declare it thus:

~~~
<myLabel> label near
~~~

#### 2.3.3 Segments and dgroup

Geodes are divided into segments. Each segment is loaded into memory all at 
once, and accessed with a given segment address (hence the name). 

Segments should be declared in the .gp file just as they are for Goc geodes. 
You must also mark the beginning and end of each segment in the assembly 
source file. At the beginning of the segment, put a line like

~~~
<segmentName>	segment resource
~~~

At the end of the resource, put a line like 

~~~
<segmentName>	ends
~~~

You can enter and leave a segment multiple times. You can even do so in 
different code files, as long as the resource is not an LMem heap. The linker 
will combine the resources appropriately.

Every resource has a resource ID. This resource ID is determined at 
link-time; this means that a resource in a multi-launchable application will 
have the same ID in each copy of the application running.

##### 2.3.3.1 The dgroup Segment

Every geode is assigned a fixed memory resource for its global variables (and, 
if the geode has a process object, for the process thread's stack). This resource 
is known as **dgroup**. The **dgroup** segment is fixed and non-sharable. 
Variables in the **dgroup** will keep the same address throughout a session of 
GEOS.

The **dgroup** segment contains the process object's instance data. Whenever 
a message is sent to the process object, the **dgroup**'s segment address will 
automatically be loaded into **ds**. In general, the **dgroup** segment is used for 
most statically allocated, global variables. Because the segment contains the 
process object's stack, you should not try to change the segment's size or 
dynamically allocate space in it.

To declare a global variable, place it in the pseudo-segment **idata** or **udata**. 
The assembler combines these two pseudo-segments into the fixed, 
non-sharable **dgroup** segment. The **idata** pseudo-segment contains 
variables that must be initialized to non-zero values. All variables in **udata**, 
on the other hand, are automatically initialized to zero. They thus take up no 
space in the executable file, since their initial values need not be stored.

If the geode declares any new classes, the class declarations should be put in the 
**idata** pseudo-segment. This is discussed at length in ["Defining Classes"](#24-defining-classes).

---
Code Display 2-3 Declaring Global Variables
~~~
; Note that the geode will not have segments named idata or udata; these are 
; pseudo-segments, and are combined into dgroup by the assembler.

;---------------------------------------------------------------------------
;	Initialized Variables
;---------------------------------------------------------------------------

idata segment
	MyAppProcessClass	mask	CLASSF_NEVER_SAVED

	MyGlobalString		char	"Franklin Tiberius Poomm, Esq.",0

idata	ends

;---------------------------------------------------------------------------
;	Uninitialized Variables
;---------------------------------------------------------------------------

udata	segment

	MyEmptyArray		sword	20 dup (?)

udata	ends
~~~

##### 2.3.3.2 Accessing Segments

GetResourceHandleNS, GetResourceSegmentNS, handle, segment, 
GeodeGetResourceHandle, vSegment

Accessing a resource is slightly more complicated in GEOS than it is in 
traditional PC programming. A given resource may move around while it is 
not being accessed. For this reason, you must access non-fixed resources 
through handles.

All geode resources are GEOS memory blocks, as described in ["Memory 
Management", Chapter 15 of the Concepts Book](../Concepts/cmemory.md). This means that every 
resource has a global handle. You will often need to get the handle of a 
resource. For example, whenever you send a message to an object, you need 
to know the handle of the object's resource. If you want to access data in an 
unlocked, non-fixed resource, you will need to get the resource's handle so you 
can lock it.

One problem is that there may be several copies of a given resource in memory at 
a time. For example, if you write a multi-launchable application, every copy of 
that application running at a time will have its own [dgroup](#2331-the-dgroup-segment) 
segment. For this reason, you must use a special macro to get the handle of a 
non-sharable resource, namely [GetResourceHandleNS](#getresourcehandlens). This macro 
is passed the resource name of a segment; it returns the segment's global handle.

If you know that a resource is locked or fixed in memory, you can use 
[GetResourceSegmentNS](#getresourcesegmentns) to get the segment address directly. 
This macro is passed the resource name of a locked or fixed segment; it returns the 
segment's base address.

If you know that there is only one copy of a resource in memory, you can use 
a shorter and faster syntax to get the handle or segment. There are two 
common situations when you can be sure that there is only one copy of a 
resource: The application might be single-launchable, or the resource might 
be sharable (for example, code or read-only data). To get the handle of such a 
resource, use the Esp directive handle. For example, to load the handle of 
the HelloInitCode resource into bx, you would use

~~~
mov	bx, handle HelloInitCode
~~~

If you know that such a segment is locked or fixed in memory, you can get its 
segment address with the segment directive. For example, to load the 
segment address of the HelloInitCode resource into bx, you would use

~~~
mov	bx, segment HelloInitCode
~~~

If you know the resource ID of a segment, you can find out the segment's 
handle by calling [GeodeGetResourceHandle](#geodegetresourcehandle). This routine is passed the 
resource ID and returns the resource's global handle. The call is somewhat 
faster than the macro [GetResourceHandleNS](#getresourcehandlens), since the macro first 
determines the resource ID, then calls [GeodeGetResourceHandle](#geodegetresourcehandle). 
However, the call is slower than using the handle directive, so you should 
use that when appropriate.

Ordinarily, to find out the segment address of the [dgroup](#2331-the-dgroup-segment) segment, you 
would use [GetResourceSegmentNS](#getresourcesegmentns) or the segment directive. However, if 
you are running code from the process thread, you can take advantage of the 
fact that the process thread's stack is kept in the [dgroup](#2331-the-dgroup-segment) resource. This 
means that the dgroup segment address must be in ss. Thus, to load to 
segment address of [dgroup](#2331-the-dgroup-segment) into ds, you could just use

~~~
push	ss	; The segmov macro can also do this;
pop	ds	; see "segmov"
~~~

Remember, this only works if the code is being run by the process thread.

#### GetResourceHandleNS
---
~~~
GetResourceHandleNS <resource>, <reg16>
~~~
This macro finds the handle of a resource and loads it into a register.

**Pass:**  
_resource_ The name of the resource.  
_reg16_    A 16-bit general-purpose register (not a segment register).

**Returns:**  
_reg16_    Contains handle of resource.

**Destroyed:**  
Nothing.

#### GetResourceSegmentNS
---
~~~
GetResourceSegmentNS <resource>, <segreg> [, TRASH_BX]
~~~
This routine loads the segment address of a locked or fixed resource into ds 
or es. The macro is somewhat faster if you use the TRASH_BX option.

**Pass:**  
_resource_ The name of the resource.
_segreg_   This must be ds or es.

**Returns:**  
_segreg_   The segment address is loaded into this register.

**Destroyed:**  
If TRASH_BX is passed, bx is destroyed; otherwise nothing is destroyed.

#### GeodeGetResourceHandle
---
This routine is passed the resource ID of a resource. It returns the resource's 
handle.

**Pass:**  
**bx** Resource ID number.

**Returns:**  
**bx** Resource handle.

**Destroyed:**   
Nothing.

##### 2.3.3.3 Declaring Static Variables

Esp has slightly different conventions for declaring variables than MASM 
does. In Esp, you do not need to use the "db", dw", or "dd" reserved words 
when declaring variables (though you certainly may). Instead, you can 
simply use one of Esp's predefined data types, or define one of your own. The 
Esp syntax for declaring a variable is

~~~
[<variableName>]	<dataType>[.<typePointedTo>] [<initValue>]
~~~

**variableName**  
This may be any suitable label; acceptable names for variables 
are the same as in MASM.

**dataType**  
This may be one of the standard Esp data types (see Table 2-1 ). 
It may also be a structure or record, or any other geode-defined data type.

**typePointedTo**  
If **dataType** is a pointer, you can specify what data type it 
points to. If you do not, the pointer is untyped (i.e. it is a "void 
pointer").

**initValue**  
This may be any value appropriate for the data type.

To declare an array of any data type, simply use the following format:

~~~
[<variableName>]	<dataType>[.<typePointedTo>] <n>dup(<init>)
~~~

**variableName**  
This is actually the label of the first element in the array, i.e. 
the element at the lowest memory location.

**n**  
The number of elements in the array.

**init**  
The initial value of each element in the array. If you have an 
init value of "?", all bytes will be set to zero.

If you want to give each element a different initial value, you can use the 
following format:

~~~
[<variableName>]	<dataType> <initValue>, <initValue>...
~~~

In this case, each comma can be followed by any amount of whitespace or 
newlines. The last element in the array is simply the one not followed by a 
comma.

For example, to declare an array of words, one might use

~~~
myByteArray			word	1, 2, 3, 4
~~~

Note that if the variable is in the [udata](#2331-the-dgroup-segment) pseudo-segment, any specified 
initializers will generate a link-time error.

##### 2.3.3.4 Strings

Esp provides a special format for declaring arrays of byte-sized values 
(strings). A sequence of characters surrounded by single or double quotes is 
treated like a comma-separated sequence of the ASCII values. (No null 
terminator is added.) For example, 

~~~
myString char			"abc"
~~~

is functionally equivalent to 

~~~
myString char 			61h, 62h, 63h 
			; ASCII values of a,b,c
~~~

This is only valid if the data type is byte-sized (db, sb, or a synonym). If the 
data type is larger, all of the characters are written to one variable.

You can mix the two formats. For example, to declare a null-terminated 
string, you can use

~~~
myString char 		"abc", 0
~~~

Characters within a string are translated into their ASCII counterparts, with 
two exceptions, namely delimiter characters and escape sequences. The 
delimiter character marks the end of the string, except when it is doubled; in 
that case, it represents the delimiter character itself. For example, the 
declaration

~~~
myString char			"ab""cd"
~~~

is equivalent to

~~~
myString char			61h, 62h, 22h, 63h, 64h
			; 22h is ASCII for "
~~~

If the string is bound by double-quotes, single-quote characters are treated 
literally. If it is bound by single-quotes, double-quote characters are treated 
literally. For example,

~~~
myString char			"ab""cd'ef"
~~~

is equivalent to 

~~~
myString char			'ab"cd''ef'
~~~

Both of these describe strings which contain the following characters:

~~~
ab"cd'ef
~~~

Certain character sequences (called escape sequences) are used to specify 
special characters. Esp supports the full range of C escape sequences; these 
are shown in Table 2-2.

#### 2.3.4 Miscellaneous Enhancements

Many of Esp's features are general enhancements of MASM. Our engineers 
simply felt that a given behavior was useful or preferable to the ordinary 
MASM behavior. In most cases these changes are backwards-compatible; Esp 
simply adds new directives and pseudo-ops besides those provided with 
MASM. In a few cases, it changes the behavior of existing directives and 
pseudo-operatives. In these cases, you can usually force MASM behavior by 
passing the "-m" flag to Esp.

|Character Sequence |Description              |
|:------------------|:------------------------|
|\n                 |newline (ASCII 10)       |
|\r                 |return (ASCII 13)        |
|\b                 |backspace (ASCII 8)      |
|\f                 |formfeed (ASCII 12)      |
|\t                 |tab (ASCII 9)            |
|\\\                |backslash                |
|\'                 |Single-quote             |
|\"                 |Double-quote             |
|\000               |ASCII code in octal      |
|\x00               |ASCII code in hexadecimal|
**Table 2-2** Esp Escape Sequences

##### 2.3.4.1 Pseudo-Ops and Directives

Esp provides a wide range of pseudo-ops and directives. Some of these will be 
described in later chapters; a few of the most useful will be described here. 
This section also details those Esp instructions which are different from their 
MASM equivalents.

**call**

As noted earlier, Esp adds special functionality to the call instruction. The 
main change is that call automatically locks movable resources when 
necessary. This is transparent to the application.

call can also be used to call statically-defined methods. This is discussed at 
greater length in ["Messages", section 3.3.2 of chapter 3](erout.md#332-messages).

**push and pop**

As noted earlier, these instructions can take multiple operands. The 
operands to push are pushed from left to right; that is,

~~~
push ax, bx, [wordVariable]
~~~

expands to

~~~
push ax
push bx
push [wordVariable]
~~~

The operands to pop are popped from right to left. This means that you can 
pass arguments to push and pop in the same order, e.g.

~~~
push	ax, bx, cx, dx
call	MessyProcedure		; this trashes ax-dx
pop	ax, bx, cx, dx		; this restores them
~~~

**The TYPE Operator**

In Esp, TYPE <register> returns the size of the register (in bytes), not zero 
as in MASM. To find out if an operand is a register, use the .TYPE operator.

**The .TYPE Operator**

Under Esp, bit seven of the .TYPE return value is clear if the expression has 
local scope (i.e. it uses one or more symbols which are not available outside 
of the current assembly); if all symbols of the expression are of global scope, 
bit seven is set.

If you use .TYPE with a code-related expression, the high byte is set thus:

|Position |Meaning if set                          |
|:--------|:---------------------------------------|
|8 (10h)  |Procedure is near                       |
|9 (20h)  |Procedure contains ON_STACK symbols     |
|10       |Procedure may not be jumped to          |
|11       |Procedure may not be called             |
|12       |Procedure is a static method            |
|13       |Procedure is a private static method    |
|14       |Procedure is a dynamic method           |
|15       |Procedure is a method                   |
**Table 2-3** .TYPE high-byte return values

**LENGTH and SIZE**

The LENGTH and SIZE operators are used to find the number of elements in 
an array and the total size of the array in bytes, respectively. In MASM, these 
operators only work if a variable is declared with the dup directive. In Esp, 
these are more versatile. If several variables of the same class are declared 
on a single line after a label, they are treated as an array. For example, 
suppose you have the declaration

~~~
SomeNums		dw	1,2,3
~~~

MASM would not recognize that this is an array; it would therefore say that 
SomeNums has a LENGTH of one and a SIZE of two. Esp would treat this as an 
array, and would thus recognize that SomeNums has a LENGTH of three and a 
SIZE of six.

**.assert**

.assert is used to check assumptions about code. If the assumption is false, 
.assert prints an error message to **stderr** and halts assembly. If the 
assumption is true, assembly continues normally, and the object code is not 
affected. .assert has the following format:

~~~
.assert		<expression> [, <errorString>]
~~~

**expression**  
If this expression evaluates to zero, the assertion will fail, and 
assembly will halt.

**errorString**  
If the assertion fails, this string will be printed to **stderr**, along 
with the location of the assertion. If no string is specified, Esp 
will print "assertion failed".

For example, suppose you need to check whether al contains a certain value, 
such as MY_COLOR_WHITE. The canonical way to do this would be

~~~
cmp	al, MY_COLOR_WHITE
jz	itsWhite
~~~

You might know, however, that MY_COLOR_WHITE is the first member of the 
enumerated type, and has the value zero. You can take advantage of this to 
write more efficient code, since testing a register for zero-ness is faster than 
comparing it with an immediate value. On the other hand, this code would be 
fragile, since the enumerated type could be changed in the future. The 
solution is to use the .assert macro:

~~~
.assert		(MY_COLOR_WHITE EQ 0),				\
	<MY_COLOR_WHITE does not equal zero>

test	al, al		; Test if al = MY_COLOR_WHITE
			; (i.e. zero)

jz	itsWhite
~~~

You can also use the macro [CheckHack](#checkhack), described below, which 
automatically generates an appropriate error message.

**ornf, andnf, xornf**

Sometimes you will want to use the and, or, and xor macros solely for their 
effects on the destination operand; you won't care about the settings of the 
flags. In these cases, you can use "no-flags" variants, andnf, ornf, and 
xornf. Esp can take advantage of the fact that you don't care about the flags 
to optimize the instructions. For example, the instruction

~~~
ornf	cx, 0x0100
~~~

is assembled as

~~~
or	ch, 0x01
~~~

which is one byte shorter, but sets the flags differently than 
"or cx, 0x0100" would. For this reason, all the status flags have 
indeterminate values after a "no-flags" operation.

The "no-flags" instructions have another advantage: They document that the 
program doesn't care about the flag settings after the instruction, i.e. that the 
code is using the instruction solely for its effect on the destination operand.

**EQ, NE**

Esp lets you use the EQ and NE directives to compare strings or segments, as 
well as immediate values. Of course, the operands must be defined at 
assemble-time.

##### 2.3.4.2 Miscellaneous Macros

Esp comes with a tremendous number of predefined macros. Some of these 
perform common tasks in a roundabout, but more efficient, way. Others are 
clearer, self-documenting ways to perform common tasks. When you use Esp 
macros, you can take advantage of code that has been fine-tuned and checked 
until it's practically bulletproof.

All macros are defined in .def header files. Since these files are distributed 
with the SDK, you can examine the source code to see exactly what the 
macros do and how they work. You can use these macros as starting points 
for writing your own macros. Some of these are defined in specific libraries; 
they are usually defined in the library's .def file. This section contains more 
general-purpose macros, which are defined in geos.def.

**Assembly-Control Macros**

PrintMessage, ErrMessage, ForceRef, PrintE, CheckHack

Esp provides some macros which do not affect the final code at all. Instead, 
these macros produce useful side-effects during assembly.

One such macro is [PrintMessage](#printmessage). This macro prints a message to 
**stderr** when it is assembled; it does not have any effect on the object code. This is 
useful for leaving reminders for yourself. For example, an early version of a 
program might use an inefficient, brute-force technique to do something. You 
might then put in a reminder to yourself to improve the algorithm later:

~~~
call	MyStupidAndSlowSearchRoutine
PrintMessage <Remember to improve this algorithm!>
~~~

[PrintError](#printerror) is much like [PrintMessage](#printmessage), except that it 
also generates an .err directive, halting assembly.

You may sometimes make assumptions about data structures or values in 
order to write more efficient code. For example, you might rely on the fact 
that a given constant is equal to zero. In these circumstances, you should 
check the assumptions with the [CheckHack](#checkhack) macro. This macro evaluates 
an expression. If the expression evaluates to true (i.e. non-zero), assembly 
will proceed normally; otherwise, assembly will halt, and an appropriate 
message will be printed to **stderr**. This is functionally equivalent to using the 
.assert directive, but it is clearer.

For example, the code might be rewritten this way with the 
[CheckHack](#checkhack) macro:

~~~
CheckHack		<MY_COLOR_WHITE EQ 0>

test	al, al		; Test if al = MY_COLOR_WHITE
			; (i.e. zero)

jz	itsWhite
~~~

[ForceRef](#forceref) makes sure that there is a reference to a symbol. If you declare 
a symbol (such as a local variable) but never use it, Esp will generate a 
warning. You can suppress this warning by using the [ForceRef](#forceref) macro.

[PrintE](#printe) prints the value of an expression when it is assembled. It does not 
affect the object code in any way.

#### PrintMessage
---
~~~
PrintMessage < <string> >
~~~

This macro prints a message to **stderr** when it is assembled. It does not 
affect the object code in any way.

**Pass:**  
_string_ A string to print to **stderr**. The string should be surrounded 
by angle-brackets, not quotation marks.

**Include:**  
geos.def

#### PrintError
---
~~~
PrintError < <string> >
~~~

This macro prints a message to **stderr** when it is assembled, then generates 
a .err directive, halting assembly.

**Pass:**  
_string_ A string to print to **stderr**. The string should be surrounded 
by angle-brackets, not quotation marks.

**Include:**  
geos.def

#### ForceRef
---
~~~
ForceRef <symbol>
~~~

This macro forces a reference to a symbol. This prevents Esp from generating 
a "symbol not referenced" warning.

**Pass:**  
_symbol_	Any global or local symbol.

**Include:**  
geos.def

#### PrintE
---
~~~
PrintE < <string> > %( <expr> )
~~~

PrintE prints the value of an expression to **stderr**. It does not affect the 
assembled object code in any way.

**Pass:**  
_string_	A string to print to **stderr**. The string is surrounded by angle-brackets, not by quotation marks.
_expr_ An expression.

**Include:**  
geos.def

#### CheckHack
---
~~~
CheckHack 	<expr>
~~~

This macro checks to see if an expression is true. If the expression is false (i.e. 
evaluates to zero) at assemble-time, [CheckHack](#checkhack) prints an appropriate error 
message to **stderr** and generates a .err directive, halting assembly.

**Pass:**  
_expr_ An expression whose value is known at assemble-time.

**Include:**  
geos.def

##### 2.3.4.3 Useful Miscellaneous Macros

clr, tst, BitSet, BitClr, segmov, segxchg, CmpStrings, 
XchgTopStack

You will find that there are certain simple tasks you perform over and over 
again. For example, you will often find yourself clearing registers, or copying 
values from one segment register to another. Esp provides macros to perform 
many of these common tasks.

These macros are useful for two reasons. First of all, they are reliable and 
heavily-tested ways of performing common tasks as efficiently as possible.

Second, and more important, they are self-documenting. For example, 
suppose you need to clear ax. The fastest way to do this is 

~~~
xor ax, ax
~~~

However, this code is confusing. First of all, an inexperienced programmer 
would not immediately recognize that the instruction clears ax. Second, it's 
unclear what the programmer wants this instruction to do. On the one hand, 
perhaps the programmer is only interested in clearing ax; on the other, she 
may be relying on xor to set the flags appropriately. If you don't know exactly 
what the programmer wanted to do, it's hard to maintain the code.

On the other hand, if the programmer used the clr macro like this:

~~~
clr ax
~~~

the code becomes much clearer: The programmer wanted to clear ax, and 
does not care about the flags (since clr is documented as destroying the 
flags).

**clr**

Suppose you need to clear a memory location or a register. There are three 
different ways you might do this.

If you know that a register's value is zero, you can copy that register to the 
location to be cleared. This is the fastest way to clear any location.

If you need to clear a location and you don't have a convenient clear register, 
you can mov an immediate value of zero into it. This is the usual way to clear 
a memory location.

You can also clear a location by xor'ing it with itself. If the location is a 
register, this is faster than moving a zero into it. On the other hand, if the 
location is in memory, it is faster to move a zero into it.

The macro clr automatically chooses between these three techniques. It can 
take any number of byte- or word-sized arguments. It proceeds down the list 
from left to right. If the first argument is a register, clr clears this register 
by xor'ing it with itself. It then copies this register to all the other arguments 
to clr. If the first argument is a memory location, it moves a zero into this 
location, then starts over with the next argument.

Note that the xor technique changes the status flags; therefore, the status 
flags become undefined after use of clr. If you need to preserve the flags, 
move an immediate value of zero into each location, or save the flags on the 
stack.

#### clr
---
~~~
clr <location> [, <location>...]
~~~

This macro sets all of its arguments to zero, using the most efficient 
technique for each location.

**Pass:**  
_location_	A byte- or word-sized memory location or general-purpose register.

**Destroyed:**  
flags

**Tips & Tricks:**  
If any of the arguments is a register, put it at the head of the list. In 
particular, if any of the arguments is ax, put it at the head of the list, ahead 
of any other registers.

**Include:**  
geos.def

**tst and tst_clc**

You may often need to check a value to see if it's non-zero. There are two 
different efficient ways to do this.

If you are testing a register, the most efficient technique is to or the register 
with itself. This does not change the operand, and it sets ZF appropriately. 
On the other hand, if you are testing a memory location, the most efficient 
technique is to cmp the location with zero. This also sets the ZF appropriately. 
The tst macro chooses the appropriate technique for its operand.

Note that either one of these techniques will always clear CF. If you are 
taking advantage of this, you should use the synonymous macro tst_clc. 
This macro behaves identically to tst, but documents that the program 
relies on CF being cleared.

#### tst, tst_clc
---
~~~
tst	<location>

tst_clc	<location>
~~~

This macro tests a byte- or word-sized location to see if it is equal to zero.

**Pass:**  
_location_ A byte- or word-sized memory location or general-purpose register.

**Returns:**  
_ZF_ Set according to location's value.

_CF_ Cleared.

_SF_ Set according to the operand's value.

**Destroyed:**  
Other flags

**Tips & Tricks:**  
If you take advantage of the fact that this macro clears CF, you should 
document this by using the tst_clc version.

**Include:**  
geos.def

**Moving Values Between Segment Registers**

The mov instruction does not allow you to move values from one segment 
register directly to another. Esp provides the macro segmov to do this. This 
macro takes either two or three arguments. It can be called with two 
arguments, a source segment register and a destination segment register. In 
this case, segmov pushes the value from the source and pops it into the 
destination. It can also be called with a third argument, a general-purpose 
register. In this case, segmov uses the general-purpose register as an 
intermediate register. This makes the operation much faster, but destroys 
the value in the intermediate register; the instruction is also two bytes 
longer.

To exchange two segment registers, use segxchg. This macro pushes both 
segment registers, then pops them in the same order, thus exchanging their 
contents.

#### segmov
---
~~~
segmov	<destSeg>, <sourceSeg> [, <useReg>]
~~~

This macro copies a value from one segment register to another. If a 
general-purpose register is passed as a third argument, it will be used as an 
intermediate register, making the macro much faster, but two bytes longer.

**Pass:**  
_destSeg_, _sourceSeg_ Any segment registers.

**Returns:**   
_destSeg_ Set to equal sourceSeg.

**Destroyed:**  
_useReg_ (if passed).

All flags are preserved.

**Include:**  
geos.def

#### segxchg
---
~~~
segxchg	<seg1>, <seg2>
~~~

This routine exchanges the contents of two segment registers. It does not 
have any other effects.

**Pass:**  
_seg1_, _seg2_ A segment register.

**Returns:**  
_seg1_, _seg2_ Exchanged.

**Destroyed:**  
Nothing; all flags are preserved.

**Include:**  
geos.def

**Setting and Clearing Bits in a Record**

You will often find yourself setting and clearing bit flags in a record. Esp 
provides macros to do this for you. The macros are no more efficient than 
doing it by hand, but they are clearer to read.

To set a bit in a record, call [BitSet](#bitset). This macro is passed the location of the 
record and the name of the field to set (without the mask operator). It sets the 
bit by or'ing the two values. For example,

~~~
BitSet		myRecord, MR_A_FLAG
~~~

is equivalent to

~~~
ornf		myRecord, mask MR_A_FLAG
~~~

To clear a bit in a record, use the [BitClr](#bitclr) macro. This macro is passed the 
location of the record and the name of the field to clear (without the mask 
operator). It sets the bit by and'ing the destination with the bitwise not of 
the flag.

#### BitSet
---
~~~
BitSet	<location>, <fieldName>
~~~

This macro turns on all the bits in the specified field of a record.

**Pass:**  
_location_ The location containing the record; this may be a 
general-purpose register, or it may be in memory.

_fieldName_ The name of the field to set. All bits in this field will be set.

**Destroyed:**  
Flags are destroyed.

#### BitClr
---
~~~
BitClr	<location>, <fieldName>
~~~

This macro turns off all the bits in the specified field of a record.

**Pass:**  
_location_ The location containing the record; this may be a 
general-purpose register, or it may be in memory.

_fieldName_ The name of the field to clear. All bits in this field will be cleared.

**Destroyed:**  
Flags are destroyed.

##### 2.3.4.4 dword Macros

cmpdw, jgedw, jgdw, jledw, jldw, tstdw, pushdw, popdw, 
notdw, negdw, incdw, decdw, movdw, adddw, adcdw, subdw, 
clrdw, shrdw, sardw, shldw, saldw, xchgdw

The 80x86 chips provide instructions for performing arithmetic on byte- and 
word-sized operands. You may, however, be working with dword-sized (32-bit) 
values. Esp provides many macros for dealing with these values, whether 
they are in registers or in memory.

These macros are designed to look and behave much like their byte- and 
word-sized counterparts. However, there are often small differences between 
the macros and the instructions. For example, many dword macros set the 
flags slightly differently from the corresponding instructions. The reference 
entries detail any such differences. Remember, when in doubt, you can 
always look at the macro's source code.

### 2.4 Defining Classes

Every application defines at least one new class, its own process class. Most 
applications define several more classes in addition to the process class.

When you create a class, there are two things you must do. You must put the 
class's class structure in the application's [idata](#2331-the-dgroup-segment) segment; and you must 
define the class's messages and instance data fields. (You may also need to 
define special structures, enumerated types, etc., for the class.)

Note that if you wish to create instances of your class at compile time, you 
will have to do this in a .ui file, and you will have to write an Espire definition 
of your class (in the .ui file) which matches the Esp one. The "Espire" 
language and the User-Interface compiler are discussed in ["The UI 
Compiler", Chapter 4](euic.md).

#### 2.4.1 Defining a Class

Every class needs to be defined. The class's definition must be included once, 
and only once, in the compilation, before the class name is ever actually used 
(e.g. before you create the class structure). You can so this by putting the 
class definition high in the application's .asm file, or (if there are several 
.asm files) by putting it in a common .def file.

A class's definition has this basic format:

~~~
<className>			class <superClassName> \
			[, master [, variant]]
	; class's messages...
	; class's instance data fields...
	; class's vardata fields...
<className>			endc
~~~

**className**  
This is the name of the class you are defining.

**superClassName**  
This is the name of the class's immediate superclass.

For an example of a class definition, see Code Display 2-4.

##### 2.4.1.1 Defining a Class's Messages

In Esp, you specify very little when you define a class's messages. You simply 
specify the message name, without arguments or other information, like this:

~~~
<msgName>		message
~~~

**msgName**  
This is the name of the message.

When you send the message, it is your responsibility to load the correct 
arguments into the appropriate registers, or push them on the stack, as 
described in [section 3.3.2.2 of chapter 3](#3322-sending-messages); Esp will not do any type-checking.

You can export or import messages in Esp, much as you can in Goc (as 
described in [section 5.4.1.1 of "GEOS Programming," Chapter 5 of the Concepts Book](..//Concepts/ccoding.md#5411-defining-new-messages-for-a-class)). To export a range 
of message numbers, to be used by subclasses, you use this directive:

~~~
<messageRangeName>				export <numToExport>
~~~

**messageRangeName**  
This is the name of the message range to export. A subclass 
which wishes to use the exported range will use this name to 
import it.

**numToExport**  
This is the number of messages to export.

To "import" a message, i.e. define a message in a message range which was 
exported by your class's superclass, define the message like this:

~~~
<messageName>			message <exportedRangeName>
~~~

**exportedRangeName**  
This is the name of the message range exported by your class's 
superclass.

##### 2.4.1.2 Defining a Class's Instance Data Fields

To define a class's instance data fields, put lines with this format in your class 
definition:

~~~
<fieldName>			<fieldType> [<defaultValue>]
~~~

**fieldName**  
This is the name of the instance data field.

**fieldType**  
This is the type of the instance data field. It may be any 
standard or application-defined data type.

**defaultValue**  
This is the default value of the field when an object of this class 
in instantiated.

##### 2.4.1.3 Defining a Class's Vardata

To define a hint or vardata field for a class, put lines with this format in your 
class definition:

~~~
<varFieldName>		vardata		[<fieldType>]
~~~

**varFieldName**  
This is the name of the hint or vardata field.

**fieldType**  
This field is optional; it is the type of data associated with the 
vardata field. It may be any standard or application-defined 
data type.

#### 2.4.2 Creating a Class's Class Structure

Once you have defined a class, you must create its class structure. The class 
structure must be in fixed memory; therefore, it is generally placed in the 
application's [idata](#2331-the-dgroup-segment) "resource", which means it will be in the application's 
[dgroup](#2331-the-dgroup-segment) resource at run-time.

To create a class structure, put the following line in your application's [idata](#2331-the-dgroup-segment):

~~~
<className>			[mask <ClassFlag> [or mask <ClassFlag>]*]
~~~

**className**  
This is the name of the class.

**ClassFlag**  
This is a member of the **ClassFlags** record (e.g. CLASSF_NEVER_SAVED); you may 
have zero or more of these or'd together.

---
Code Display 2-4 Creating a Class
~~~
; Here we create a subclass of GenTriggerClass. Note that if we wanted to create 
; any of these objects at startup, we would have to put a corresponding definition 
; in the application's .ui file.

MyTriggerClass 		class GenTriggerClass

; Here are the class's messages:

MSG_MT_DO_SOMETHING_CLEVER				message
;
;	Pass:		cx = freeble factor
;			dx = coefficient of quux
;	Return:		ax = # of roads a man must walk down
;	Destroyed:		cx, dx

; Here are the class's new instance fields:

	MTI_fieldOne		byte
	MTI_fieldTwo		MyStruct		<0, 17, "Frank T. Poomm">

; Here are the object's vardata fields:

GT_MY_VARDATA_FIELD			vardata	lptr

MyTriggerClass		endc

; We also have to create the class's class structure. We do this in the idata 
; resource:

idata	segment

MyTriggerClass

idata	ends
~~~

#### 2.4.3 Defining your Process Class

Every application with a process thread needs to define a new process class 
for its process object. This is much like defining any other class. There are a 
couple of differences, however.

Process objects do not have vardata, and they do not have ordinary instance data. 
Notionally, all the variables in the [dgroup](#2331-the-dgroup-segment) segment are the process 
object's instance data. In fact, while you must create a class structure for the 
process object (as described in [section 2.4.1](#241-defining-a-class)), you do not need to 
define the process object (with class... endc) unless you are defining 
messages for your process class.

### 2.5 Error-Checking Code

ERROR_CHECK, ERROR, ERROR_C, ERROR_NC, ERROR_Z, ERROR_NZ...

Error-checking is as important in assembly code as in Goc. Esp provides 
error-checking facilities which are very much like those of Goc. It allows you 
to write code which will only be run by the error-checking version of your 
geode. It also provides many routines and macros which are useful for 
checking for errors.

There are two main ways to designate code "error-checking". If you want to 
declare a single line as "error-checking," you should bracket the line with 
"EC<...>", like this:

~~~
EC<	call	MyECValidationRoutine>
~~~

In the error-checking version of the code, this line will be included as an 
ordinary instruction; in the non-error-checking version, the line will be 
stripped out. (To include a line only in the non-error-checking version, 
bracket the line with "NEC<...>".)

When the compiler is compiling error-checking code, it defines the flag 
ERROR_CHECK to non-zero. You can use this to designate several lines as 
error-checking code:

~~~
if	ERROR_CHECK
	; bx should be non-zero; is it?
	pushf
	tst	bx
	jnz	noError
; if we reach this, it's an error
	ERROR MY_FATAL_ERROR_CODE
noError:		; not an error condition
	popf
endif
~~~

Esp also provides several macros for error-checking. There are a few macros 
and routines of general usefulness and they are documented here.

There are many macros which call [FatalError](#fatalerror), passing an error number. 
The most basic is ERROR. This macro is called with a single argument, 
namely an error number. It generates a fatal error; the error code is available 
for the debugger.

There are similar macros which call [FatalError](#fatalerror) if the flags are set in a 
particular way. For example, ERROR_C checks to see if the carry is set. If it is 
(that is, if a jc instruction would jump), ERROR_C calls ERROR with the 
specified code; otherwise, it continues normally. Conversely, ERROR_NC calls 
ERROR if CF is not set. For example, the code sample on page 56 could be 
written more clearly like this:

~~~
if	ERROR_CHECK
	; bx should be non-zero; is it?
	pushf
	tst	bx
	ERROR_Z MY_FATAL_ERROR_CODE
	popf
endif
~~~

There is an ERROR_ macro to correspond to every conditional jump 
instruction except jcxz. For example, there is an ERROR_GE; this macro calls 
[FatalError](#fatalerror) in those situations in which jge would jump. 

#### ERROR
---
~~~
ERROR	<errorNumber>
~~~

This macro generates a fatal error.

**Pass:**  
_errorNumber_ This is an error code for use by the debugger.

**Returns:**  
Nothing.

**Destroyed:**  
Everything.

**Include:**  
ec.def

#### ERROR_C, ERROR_NC, ERROR_Z, ERROR_NZ...
---
~~~
ERROR_x	<errorNumber>
~~~

These macros call ERROR if the status flags are set in a particular way. Each 
of these macros corresponds to a conditional jump instruction (ERROR_x 
corresponds to jx); the macro calls ERROR in those situations in which the 
corresponding conditional jump instruction would jump. (For example, 
ERROR_C calls ERROR in those situations in which jc would jump, i.e. when 
CF is set.) There is one such macro for every conditional jump instruction 
except jcxz.

**Pass:**  
_errorNumber_ This is an error code; it is passed to ERROR if the error condition occurs.

**Returns:**  
Nothing.

**Destroyed:**  
Nothing (unless the error condition occurs, in which case everything is destroyed).

**Include:**
ec.def

[Esp Basics](ebasics.md) <-- &nbsp;&nbsp; [table of contents](../esp.md) &nbsp;&nbsp; --> [Routine Writing](erout.md)
