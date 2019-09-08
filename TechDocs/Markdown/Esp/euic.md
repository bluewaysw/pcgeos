## 4 The UI Compiler

Assembly language is, by nature, very low-level. It does not ordinarily 
provide support for object-oriented programming. GEOS has had to add 
special features to its assembly language to fully support OOP.

You have seen some of this support already. The GEOS kernel manages 
objects, and provides routines for sending messages. Applications can call 
special routines to create, manipulate, or destroy objects. However, most 
applications will need to have many objects created before they start 
running. In particular, most applications will need to have many UI objects 
created before they start running. You can also declare new object classes in 
a UIC file, though you only have to do that if you will want to create objects 
from those classes at compile-time.

This is where the User-Interface Compiler (UIC) comes in. With UIC, you can 
specify in your source code what objects need to be created when the 
application is launched. All these objects will be created at compile time, and 
stored in the executable file. When the application is launched, the objects 
will be there, ready to be used.

The UIC is most commonly used to create user-interface objects. It can, 
however, create any kind of object, of any class (whether a GEOS system class, 
or a class you define yourself). It can also create other chunks that might be 
kept in an object-block (e.g. Vis monikers). 

For assembly reference information about the various GEOS classes, see the 
PCGEOS\INCLUDE\*.DEF and *.UIH files.

### 4.1 UIC Overview

Essentially, UIC reads files written in Espire, a special object-specification 
language, and writes special GEOS object-assembly files. These files (which 
have a .rdf suffixes) are automatically included when the executable is 
compiled.

When you write an application in assembly, you can specify objects by putting 
them in a UIC source file. This file's name should be <geodename>.ui. When 
you run **mkmf**, it will automatically set up the makefile to include the proper 
calls to UIC. When you compile the application, the .rdf file will be generated 
and incorporated in the application.

UIC incorporates the C preprocessor. This means you can use the standard C 
preprocessing directives.In particular, you can write UIC header files, and 
include them in a .uih file with the **#include** directive. These header files 
customarily have the suffix .uih. Every .ui file must include the standard 
GEOS header file generic.uih; this file contains UI information about all the 
standard GEOS Gen and Vis classes.

Comments follow the C convention; i.e. they begin with /* and end with */. 
As in C, newlines are treated as whitespace, not as statement terminators.

Some of the conventions of .ui (and .uih) files are different from elsewhere in 
GEOS. First of all, the names of all classes are shortened; they do not contain 
the word "class". For example, in a .uih file, **GenTriggerClass** would be 
called just "GenTrigger".

Also, in a .ui file, the names of instance data fields are truncated; the initial 
capital letters, followed by an underscore, are removed. For example, the 
class **GenTriggerClass** has a field named GTI_destination; in a .ui file, this 
field would be called just "destination". This convention is followed with all 
GEOS classes; you should follow it with any classes you create. (If you're ever 
unsure what the Espire field-name is for a class, you can look in the class's 
.uih file in PCGEOS\INCLUDE\OBJECTS.

Finally, the names of flags in an instance data record have different 
conventions. In C and assembly files, the name of a flag would begin with the 
initials of the instance data field, followed by the name of the flag, in capital 
letters. For example, in assembly, the **GenClass** record GI_attrs has a field 
named GA_READ_ONLY. The corresponding field in a .ui file would be called 
"readOnly". Members of enumerated types have similarly altered names. For 
example, in assembly, a field might be called MET_AN_ENUM_VALUE; if the 
type were declared in a .uih file, the member would be called 
"anEnumValue".

### 4.2 Declaring Classes

You can create new classes by specifying them in your .ui file. You do this by 
writing special Espire directives; these tell Esp how to create objects of that 
class. These directives are often put in a .uih file which is included by the 
application's .ui file.

You don't always have to do this for every class. In particular, you don't have 
to declare your process class in the .uih file; and you don't have to declare a 
class if you will not need to create objects of that class at compile-time. 
However, if you will want to create objects from the class's subclass at 
compile time, you must declare both the class and the subclass in your .uih 
file.

If you specify a class in your .uih file, you must still declare it in your regular 
assembly code, as described in [section 2.4 of chapter 2](ebasics.md#24-defining-classes).

The class specification begins with a line like this:

~~~
class <classRoot> = <superClassRoot> [, master] [,variant]{
~~~

**classRoot**  
This is the name of the class you are declaring, without the 
word "class". For example, if you are declaring 
MyTriggerClass, the <classRoot> would be MyTrigger.

**superClassRoot**  
This is the name of the class's superclass, again without the 
word "class"; e.g. if the superclass is GenTriggerClass, this 
would be GenTrigger.

If the class is a master class or a variant class, you must specify that on this 
line, e.g.

~~~
class	MyMasterVis = Vis, variant {
~~~

would be the first line in the specification for master class 
**MyMasterVisClass**, which is subclassed from **VisClass**.

After the top line, you specify all the instance data fields for the class. You 
may also change default values for fields inherited from the class's 
superclass. 

#### 4.2.1 Declaring Fields

You must list all the instance data fields that are added with that subclass. 
The basic format for specifying a field is:

~~~
<fieldRoot> = <fieldType> : <defaultValue>
~~~

**fieldRoot**  
This is the name of the instance data field, without the 
acronym of the class (as discussed in [section 4.1](#41-uic-overview)). 
For example, if the field is called MCI_aField in the MASM file, 
it would be called "aField" here.

**fieldType**  
This may be a simple type or a defined type. Simple types are 
the same as in MASM, except that they end with "Comp"; for 
example, the MASM type "byte" corresponds to the Espire type 
"byteComp".

**defaultValue**  
This optional field specifies the default value of the instance 
data field. If you create an object of this class in a .ui file and 
do not specify a value for the field, the default value will be used.

For example, in MASM code, the class **GenViewControlClass** has a field 
with the following definition:

~~~
GVCI_scale			word	100
~~~

The Espire definition of the class, in a .uih file, has this corresponding line:

~~~
scale = wordComp : 100
~~~

The default value can also be an expression:

~~~
myField = byteComp : (3 * 20)
~~~

If the field contains an enumerated type, the format is this:

~~~
<fieldRoot> = enumComp <size> [(<first> [, <step>])]
	{ <member>, <member>...} : <default;
~~~

**fieldRoot**  
This is the name of the instance data field, without the 
acronym of the class (as discussed in [section 4.1](#41-uic-overview)). 
For example, if the field is called MCI_aField in the MASM file, 
it would be called "aField" here.

**size**  
This is the size of the enumerated type. It may be byte, word, or dword.

**first**  
If this is present, it specifies the value of the first member of the 
enumerated type. The default first value is zero.

**step**  
If this is present, it specifies the step between successive 
members of the enumerated type. The default step is one.

**member**  
This is the name of a member of the enumerated type. The 
name is altered from its assembly form, as noted in [section 4.1](#41-uic-overview); 
for example, if the member's name in assembly is 
its name in Espire will be "blueEnum". You must list all 
members of the enumerated type, in the same order in which 
they appear in the type's assembly specification.

**default**
This specifies the default value of the instance field.

If the field contains an record, the format is this:

~~~
<fieldRoot> = bitFieldComp <size> 
	{<field>, <field>...} 
	: <default>, <default>...;
~~~

**fieldRoot**  
This is the name of the instance data field, without the 
acronym of the class (as discussed in [section 4.1](#41-uic-overview)). 
For example, if the field is called MCI_aField in the MASM file, 
it would be called "aField" here.

**size**  
This is the size of the record. It may be byte, word, or dword.

**field**  
This is the name of the flag. The name is changed from the 
MASM form, as noted above. For example, if the flag (in MASM) 
is called MBF_A_BITFIELD_FLAG, in Esp it would be called 
"aBitfieldFlag".

**default**  
This may be one or more flags in the record. By default, the 
flags listed here will set, and all the other flags will be cleared.

A field may be more than one bit wide. If a filed in the record is specified like 
this:

~~~
<field>:<width>
~~~

then width will be the width of the field in bytes. Fields in a record may also 
contain a range of enumerated values. The field would be specified like this:

~~~
<field>:<width>={<value>, <value>...}
~~~

Each value would be a possible setting for that field.

If a field is more than one bit wide, you specify its default value with 
"<fieldname> <value>"; the value may be either an integer, or the 
enumerated type specified for that field. If you do not specify a default value, 
the field will default to zero.

For example, the object **GenDocumentControl** has a field with the 
following definition:

~~~
dcAttributes = bitFieldComp word {
	multipleOpenFiles, 
	mode:2 = {viewer, sharedSingle,
		sharedMultiple},
	dosFileDenyWrite, vmFile, native,
	supportsSaveAsRevert, documentExists,
	currentTask:4 = {none, new, open, 
		useTemplate, saveAs, dialog},
	doNotSaveFiles } 
: mode sharedSingle, vmFile, supportsSaveAsRevert, 
currentTask new;
~~~

In this case, each field in the record is one bit wide, except for mode, which is 
two bits wide, and currentTask, which is four bits wide. By default, mode is 
set to sharedSingle (i.e. 1), and currentTask is set to new (i.e. 1); the flags 
vmFile and supportsSaveAsRevert are set; and all other flags are cleared.

#### 4.2.2 Changing a Default Value

When you create a class, you may wish to change the default values of 
instance fields inherited from a superclass. The format for doing this is:

~~~
default <fieldRoot>				= <value>;
~~~

**fieldRoot**  
This is the name of the instance data field, as given in the 
superclass's Espire declaration.

**value**  
This is the new default value for that field. As noted, if you 
want the default value to be interpreted by MASM, you should 
surround it in quotes, like so:

~~~
default		superField = "6 * SOME_MASM_CONSTANT";
~~~

If the field is a record, you may wish to turn on or off some of the flags, while 
leaving the rest unchanged. You can do that with a line like this:

~~~
default <recordRoot> = default + <flagName>, - <flagname>... ;
~~~

**recordRoot**  
This is the name of the instance data field, as given in the 
superclass's Espire declaration.

**flagName**  
This is the flag to turn on or off. If the flag is preceded by a "+", 
the flag's default value will be set; if it is preceded by a "-", its 
default value will be clear.

For example, the line

~~~
default superRecord = default +aFlag, -anotherFlag;
~~~

changes the default value of the superclass's field superRecord. In the 
subclass's superRecord field, aFlag is now on by default, and anotherFlag is 
off. All the other flags have the same default values as they have in the 
superclass.

---
Code Display 3-1 Modifying a Superclass
~~~
/* We are creating a subclass of GentriggerClass. This class will have a new 
 * field, and will change the default values of one of GenTriggerClass's fields.
 */

#include "generic.uih" /* This has the Espire definition of GenTriggerClass */

Class MyTrigger = GenTrigger {

/* Change the default values of a fields: */
    genStates = default + enabled;

/* And add a new field */
    myDatum = wordComp : 0;

}

/* The .def file would have the corresponding Esp class definition; this would be 
 * something like:

MyTriggerClass class GenTriggerClass

    MTI_myDatum word

MyTriggerClass endc
~~~

### 4.3 Creating Objects and Chunks

The whole point of the UIC is that it lets you create objects in your geode's 
source code, instead of having to instantiate them at run-time. You can 
specify whole object-blocks, with a complete set of parent-child linkages, in 
your source file; the compiler will turn these into GEOS blocks.

Besides specifying objects, you can specify other chunks that should go in an 
object block. For example, you may want to put some text into a chunk in an 
object block; that way, a resource editor can modify the text (if e.g. you are 
translating the application for another country). You may also set up data 
resources, i.e. LMem heaps that contain chunks, but no objects.

#### 4.3.1 Setting Up a Resource

start, end

Every object must be in an object block. Non-object chunks may be in object 
blocks, or they may be in non-object resources (i.e. LMem heaps). You can 
create these resources with the **start** and **end** directives. Every object in a 
.ui file must be between a **start** and the corresponding **end**.

The **start** and **end** directives have the following format:

~~~
start <resourceName> [, <resourceFlag>];
/* object definitions... */
end <resourceName>;
~~~

**resourceName**  
This is the name of the resource. The first time you "start" that 
resource, UIC outputs control information for the LMem heap. 
You may start and stop a resource several times in a .ui file.

**resourceFlag**  
This is one of the three words "data", "ui", or "app". "data" 
indicates that the block contains only non-object chunks. "ui" 
indicates that the resource is an object block which should be 
run by the user-interface thread. "app" indicates that the 
resource is an object block which should be run by the 
application thread.

A single resource may "start" and "end" many times in a .ui file. Thus, you 
can group your object declarations in whichever order is clear or convenient, 
instead of being forced to group them by resource.

#### 4.3.2 Creating Objects

Creating objects in Espire is simple. You just specify the name of the object, 
and the initial settings for any fields which do not have the default settings. 
The UIC translates this into appropriate Esp directives.

The basic format of an object definition is:

~~~
<objName> = <className> [<ObjChunkFlag>]* {
    /* instance data...*/
}
~~~

**objName**	 
This is the name of the object.

**className**  
This is the name of the object's class, as defined in the .uih file.

**ObjChunkFlag**  
This may be one or more flags of the ObjChunksFlags bitfield, 
specified with Espire conventions. This is typically either 
vardataReloc or ignoreDirty, or both.

The object's class must have been defined in a .uih file, which must have been 
included. If it is a GEOS standard class, you can simply include the file 
generic.uih.

You need not specify all instance data fields for the object. If you do not 
specify a field, the field will have its default value.

To initialize a field, put in a line like

~~~
<fieldName> =			<value>;
~~~

**fieldName**  
This is the name of the instance data field, as specified in the 
class's Espire specification.

**value**  
If this is a value which must be interpreted by Esp (not UIC), 
surround it with "double quotes". For example, suppose the 
field's value is a constant which is only known by the assembler 
(perhaps because it's defined in a .def file). You would then 
surround the constant with double quotes:

~~~
myField		= "MFC_CONSTANT_QUUX_FACTOR";
~~~

You can turn on or off certain bits in a record, while leaving the rest of the 
flags in their default settings. You do this in much the same way you do it 
when specifying classes, i.e. 

<record> = default + <flagName>, - <flagname>... ;

**record**  
This is the name of the instance data field, as given in the 
class's Espire declaration.

**flagName**  
This is the flag to turn on or off. If the flag is preceded by a "+", 
the flag's default value will be set; if it is preceded by a "-", its 
default value will be clear.

For example, the line

~~~
aRecord = default +aFlag, -anotherFlag;
~~~

specifies that the field aRecord should have its default settings, except that 
the field aFlag should be set, and anotherFlag should be cleared.

##### 4.3.2.1 Setting Up Parent-Child Links

Gen and Vis objects are arranged in a hierarchy of children. GEOS 
implements this with special linkings to the first child and the next sibling. 
However, you need not be concerned with this. To set up an object's children, 
you need only use the Espire children directive.

To specify an object's children, put the following line in the object's data:

~~~
children = <childName> [, <childName>]*;
~~~

**childName**  
These are the names of the children, in order, separated by commas.

UIC automatically sets up the parent's and children's links to each other in 
the proper way.

##### 4.3.2.2 Hints and Vardata

You may specify an object's hints and other vardata in the .ui file. You can do 
this by putting the "hints" directive in the instance-data section. This 
directive has the following format:

~~~
hints = {
	<hintOrVardataName> [{ <value> }]

	/* repeat as necessary... */
}
~~~

**hintOrVardataName**  
This is the name of the hint or vardata field, as specified in the 
class's assembly definition.

**value**  
This field is optional. If the vardata field takes a value, you may 
specify it here. Everything between the curly braces is written 
to the .rdf file, i.e. it is not interpreted by the UIC.

#### 4.3.3 Creating Chunks

Chunks are very much like objects. They may be placed in an object block, 
and referenced by name. They may also be placed in LMem data blocks.

To create a chunk which contains a string, use this format:

~~~
chunk <chunkName>			= "Text...";
~~~

**chunkName**  
This is the name of the chunk. The name can be used as an optr 
to the chunk.

UIC will create a chunk containing the text as a null-terminated string.

If a chunk contains some other kind of data, the format is this:

~~~
chunk <chunkName>			= {
	<dataType>		<value>
/* repeat as necessary */
}
~~~

**chunkName**  
This is the name of the chunk. The name can be used as an optr 
to the chunk.

**dataType**  
This is the type of data. This is a standard Esp data type, not 
an Espire type. It may also be an application-defined structure, 
record, etc.

**value**  
This is the value of the data. It is specified as in Esp.

Note that the initializers are evaluated in Esp, not in UIC. They should be 
specified as if they were Esp global variables, as described in [section 2.3.1 of 
chapter 2](ebasics.md#231-data-types).

Sometimes you will want an object's instance data field to contain an optr to 
a chunk created just for that field. If the chunk doesn't need a name, and is 
used only by that object, you can define the chunk in that instance field's 
initializer, like so:

~~~
<field> = chunk {

/* chunk data */

}
~~~

or

~~~
<field> = chunk "String..."
~~~

**field**  
This is the name of the instance data field. This field must be 
able to contain an optr.

The chunk is created in the same resource as the object. The chunk is 
unnamed, and the field will contain an optr to the chunk. That is, the Espire 
code

~~~
AnObject = MyVis {

chunkPtr = chunk {
	dw	1, 2, 3, 4
}

}
~~~

is almost functionally identical to 

~~~
AnObject = MyVis {
chunkPtr = MyChunk;
}

chunk MyChunk = {
	dw	1, 2, 3, 4
}
~~~

The only difference is that in the second example, the name MyChunk 
evaluates to an optr to the chunk. (This allows you to examine the chunk by 
name in Swat.)

#### 4.3.4 Creating VisMonikers

**VisMoniker**s are created much the way they are in Goc. As in Goc, a 
**VisMoniker** may be a single moniker, or a list of monikers; if it is, the system 
will choose whichever moniker is most appropriate for the specific UI and monitor.

If the moniker is a simple text moniker, the format is

~~~
visMoniker <monikerName> = "Text moniker";
~~~

**monikerName**  
This is the name of the moniker. The name can be used as an 
optr to the moniker.

This creates a simple text moniker. To create a more elaborate moniker, with 
special attributes, use this format:

~~~
visMoniker <monikerName> = {
	[<attr>		= <initializer>;]*
	"Text moniker"; /* This is optional */
}
~~~

**monikerName**  
This is the name of the moniker. The name can be used as an 
optr to the moniker.

**attr**  
This is the name of a VisMoniker attribute. These are described 
in ["Visual Monikers" in "GenClass," Chapter 2 of the Object 
Reference Book](../Objects/ogen.md).

**initializer**  
This is the value to which the field should be set.

If a field in an object is of type VisMonikerComp, it may be initialized with 
the name of a VisMoniker, or you may create a VisMoniker on the fly, like 
this:

~~~
<fieldName> = "Text moniker";
~~~

or 

~~~
<fieldName> = {

	/* Attributes & initializers */
}
~~~

**fieldName**  
This is the name of the instance data field. The field must be of 
type VisMonikerComp.

UIC will automatically create a chunk with the specified VisMoniker, and 
set the instance data field to point to that chunk.

You may wish to have an instance data field contain a list of VisMonikers. 
GEOS will then automatically use whichever moniker is most appropriate. To 
do so, initialize the instance data field like this:

~~~
<fieldName> = list {
	<monikerName> [, <monikerName>]*
}
~~~

**fieldName**  
This is the name of the instance data field. The field must be of 
type **VisMonikerComp**.

**monikerName**  
This is the name of a **VisMoniker**. The moniker may be in the 
same or a different resource.

[Routine Writing](erout.md) <-- &nbsp;&nbsp; [table of contents](../esp.md) &nbsp;&nbsp; --> [Mixing C and Assembly](emixing.md)
