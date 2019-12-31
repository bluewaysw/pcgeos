# 1 Parameters File Keywords

Keywords used in the .gp file of a geode are shown in 
alphabetical order in this section. These keywords 
define how the Glue linker will link the geode.

----------
#### appobj
	appobj	<name>
The **appobj** field indicates the name of the application object. All geodes with 
*appl* set under **type** (see below) must have an **appobj** entry. The *name* 
argument should be the name of the object of **GenApplicationClass** specified 
in the application's **.goc** file.

----------

#### class
	class	<name>
The **class** field specifies the name of the object class to be bound to the geode's 
process thread. This field has significance only if **process** is specified in the 
geode's **type** field (see below). This should be the same as the **ProcessClass** 
object designated in the **.goc** file (see the Hello World sample for an example 
of this connection). Note that this class binding will only be for the geode's first 
(primary) thread.

----------
#### driver
	driver	<name> [noload]
This field specifies another driver that is used by this geode. The *noload* flag 
indicates that the used driver does not need to be loaded when the geode is first 
launched. Most applications and libraries will not use exported routines from 
drivers, so few geodes will use this field. (Notable exceptions are those geodes 
that access serial and parallel ports-those geodes will include the serial or 
parallel driver.)

----------
#### entry
	entry	<name>
This field is used by library geodes. The *name* argument is the name of the 
library routine to be called by the kernel when the library is loaded or unloaded 
and when a program using the library is loaded or unloaded.

----------
#### exempt
	exempt	<library-name>
If you wish to exempt a certain library from Glue's platform checking, call it 
out with the exempt keyword. Glue will not complain if you then use parts of 
the library not normally available with platforms named in your **platform** 
statement.

----------
#### export
	export	<name> [as <name2>]
This field identifies routines usable by geodes other than the one being 
compiled; these routines are "exported" for use by other programs. Both forms 
create entry point symbols for the routines. The first *name* argument must be 
the actual name of the routine. If the second, optional, *name2* argument is 
included, then other programs will call that routine using the second name 
rather than the original. This allows a routine to have a different global name 
than that used by its creator geode.

This field is also used to export classes defined in a **.goc** or **.goh** file. See Hello 
World for an example of this usage.

----------
#### incminor
	incminor [<name>]
The **incminor** directive is used at the end of a library's **.gp** file before new 
routines are added (after a release of the library has already been made). After 
this release, new **export** and **publish** directives will be put after this **incminor** 
directive. The **incminor** directive causes two things: First, the geode's minor 
protocol number gets incremented by one. Second, any geode that uses your 
library will depend only on the higher minor protocol number if it actually uses 
one or more of the entry points exported after the **incminor** directive.

Any number of **incminor** directives may be used in a given **.gp** file. The major 
and the base minor numbers still come from a **.rev** file, if one exists.

The *name* argument is optional; it may be used in conjunction with the 
**protominor** compiler directive. Glue will know that the structures marked with 
the **protominor** label should be associated with the revision represented by the 
**incminor** directive.

----------
#### library
	library	<name> [noload]
This field specifies another library that is used by this geode. The *noload* flag 
indicates that the used library does not need to be loaded when the geode is 
first launched (though symbolic information will be loaded in any case). Note 
that every geode must have the line

	library geos

included in the **.gp** file. Most will also have the following line:

	library ui

Any number of used libraries may be specified.

----------
#### load
	load	<name> ["<class>"] as [<name2>] [<align>] [<combine>]\ ["<class2>"]

The **load** field is used when you want to alter the way a segment is linked for 
your geode. This is especially useful, for example, when integrating another 
company's runtime routines into your application or library; their segments 
may correspond to specifications other than yours.

Every segment read in has a given name, class, alignment, and combination 
type. These are described below (the **load** parameters appear after):

**name** - This is the actual name of the segment being loaded in. Segments 
with the same name are treated as one continuous segment.

**class** - Segments with the same class name are always loaded together 
into memory regardless of their order in the geode's source code. 
Class names in the load directive must always be enclosed in 
quotation marks.

**align** - This specifies the alignment type of the segment-on what type 
of address the segment can start. Possible alignment settings are 
byte, word, double word, paragraph, and page.

**combine** - Segments with the same name may appear in different code 
modules. The *combine* parameter specifies how these segments 
are to be combined when loaded. The combine type may be one of 
the following (see your assembly reference manual for more 
information): COMMON, PRIVATE, PUBLIC, STACK, or 
RESOURCE.

The parameters for load are listed below. Only the first is necessary, to inform 
Glue which segment is to undergo the alterations. For an example of using the 
load statement, see below.

**name** - This represents the actual original name of the segment. It is a 
necessary parameter so Glue knows which segment's linkage is 
to be altered.

**class** - This is the original class name of the segment. It must be 
enclosed in quotation marks if given. If you do not need to change 
the class, this parameter is unnecessary.

**name2** - This is the new name of the segment, if any.

**align** - This specifies the new align type of the segment, if any.

**combine** - This specifies the new combine type of the segment, if any.

**class2** - This specifies a new class name for the segment, if any is 
required. If you do not need to change the class, this parameter 
is unnecessary. The new class must be in quotation marks.

Examples:

	load _NAME_ "CODE" as CODE word public

	load _NAME_ "CODE" as DATASEG para common "DATA"

----------
#### longname
	longname "<string>"
The **longname** field designates a 32-character name for the geode. This name 
will be displayed with the geode's icon by GeoManager; all geodes should be 
given a long name.

----------
#### name
	name	<pname>.<ext>
The **name** field in the parameters file gives the geode a permanent name which 
will be used by both the Glue linker and the Swat debugger. Every geode must 
have a permanent name. Note that the *pname* argument must be no more than 
eight characters, and the *ext* argument must be no more than four. 
Additionally, the *ext* argument may not be "appl," as that is reserved.

When Glue is linking an error-checking geode, it drops the fourth character of 
*ext* and adds "ec" to the end of *pname*.

----------
#### nosort
	nosort
This keyword should appear before the list of resources. Normally glue will sort 
the geode's resources to optimize their arrangement. This keyword turns off 
that sorting. If you will generate .GYM (generic symbol) files for your geode, you 
should use the nosort option, as it will be important that all versions of your 
geode order their resources in the same way. If you won't generate .GYM files, 
you probably don't want to use this option.

----------
#### platform
	platform <name>
The platform directive specifies that the Geode is compatible with the named 
system. This gives a sign of how backwards-compatible the application is. If 
multiple platforms are specified, Glue will make sure that the major protocol 
numbers for each of the libraries it finds within the platforms match. Having 
done that, it will use the smallest minor protocol number it can find for each 
library to ensure compatibility across all platforms.

If a reference is ever made to an entry point in a library that would cause the 
executable to depend upon a later version of the library than specified in the 
platform file, glue will complain. For example, if the specified platform used 
GrObj version 534.1 and glue found a reference to an entry point that didn't 
exist until GrObj 534.3 (i.e., an entry point exported following 3 'incminor's in 
grobj.gp), glue will spit out an error message like: 

	error: file "somegeode.gp", line 59: Usage of 
	NewGrObjRoutine requires grobj minor protocol 3, but 
	platform files only allow minor protocol 1

If the new routine happens to be a "published" routine, glue will copy it into the 
geode in an effort to avoid the error.

----------
#### publish
	publish <name>
Normally, If a geode is required to run (via platform specifications) with a 
version of a library that doesn't contain one of the entry points required by the 
geode, glue will notify the user of the inconsistency, and the link will fail. 
However, if that entry point happens to be a published routine, glue will 
actually copy the routine into the geode and switch the call over to the newly 
copied routine to remove the dependency on the library routine. Glue does this 
by copying any routines marked "publish" in a library's .gp file into the .ldf file, 
then copying them out into whatever other geodes needs when those geodes are 
linked. Routines are marked "publish" by replacing the word "export" with the 
word "publish" in the .gp file, like so:

	publish PublishedRoutinei

The published routines appear in .ldf files in individual segments named after 
the routine (e.g. _PUBLISHED_PublishedRoutine), each containing a routine, 
also named after the published routine (e.g., 
_PUBLISHED__PUBLISHED_PublishedRoutine) You'll know one of these 
routines has been linked into your geode by examining the resource summary 
output by glue: 

	Resource 					Size # Relocs
	-------------------------------------------------
	CoreBlock 							0 		0
	dgroup 								240 	8
	_PUBLISHED_GROBJCALCCORNERS 		53 		1
	_PUBLISHED_GROBJBODYPROCESSALLGR 	94 		2
	TEST2_E 							478 	27
	INTERFACE 							652 	1
	CHANGETEXTDIALOG 					232 	1
	APPRESOURCE 						416 	1

----------
#### resource
	resource <name> (read-only|preload|discardable|fixed|conforming|shared|\
			 code|data|lmem|discard-only|swap-only|ui-object|object|\
			 no-swap|no-discard)+
The **resource** field indicates to Glue that the geode uses the named resource. 
Not all resources used by a geode must be declared here, however. (Resources 
are described in more detail in "GEOS Programming," Chapter 5.) Resources 
must be designated with the proper attributes, all of which are listed below:

(none) - If no attribute is specified, the resource named becomes a private 
data resource for the geode.

**read-only** - The resource block may not be modified by the program.

**preload** - The resource block should be loaded when the geode is first 
launched.

**discardable** - The resource block may be discarded from memory if necessary.

**fixed** - The resource block should reside in fixed memory.

**conforming** - The resource block, if containing code, may be called from a lower 
privilege level. If containing data, it may be accessed from a 
lower privilege level. (This applies only in protected mode and is 
not currently implemented.)

**shared** - The resource block may be used by other geodes. (Note: It is an 
error to specify *code* and *shared* without *read-only*.)

**code** - The resource block contains executable code.

**data** - The resource block contains data only. If a data resource is 
designated *read-only* and not fixed, it is assumed to be 
discardable.

**lmem** - The resource block consists of a local memory heap. This implies 
the attribute *data* (above), though not the condition pertaining to 
being discardable.

**discard-only** - The resource block should not be swapped but may be discarded. 
This is useful for initialization code.

**swap-only** - The resource block should not be discarded but may be swapped.

**ui-object** - The resource block contains objects to be run by the UI. This *
implies *lmem*, shared*, and *no-discard*. All blocks for a geode 
designated *ui-object* will be run in a UI thread created specifically 
for the geode's UI objects.

**object** - The resource block contains objects that are to be run by the 
application's process thread rather than by the UI. This implies 
*lmem* and *no-discard*.

**no-swap** - The resource block will not be swapable.

**no-discard** - The resource block will not be discardable.

Because most resources are code resources, standard code does not have to be 
declared in the parameters file. Code resources default to *code*, *read-only*, and 
*shared*. However, if the resource is named in the **.gp** file, the default is 
overridden in favor of the settings presented. This fact is useful primarily 
when programming in assembly-in C, code resources are not declared 
explicitly.

The Hello World sample application uses only standard code resources 
(undeclared) and UI resources (designated *ui-object*). Some other examples are 
listed below:

- Shared data

		resource <name> data shared

- Initialization code

		resource <nm> code shared read-only preload no-swap

- Common code used by several geodes (this is the default)

		resource <name> code shared read-only

- Self-modifying code (strongly discouraged)

		resource <name> code

----------
#### stack
	stack	<number>
The **stack** field designates the size of the application's stack in bytes. The 
default stack size is 2000 bytes. This field is not necessary for geodes unless 
they require a different size stack (the Hello World sample uses a slightly 
smaller stack size for example only). The **stack** field is valid only for geodes 
with a process aspect.

----------
#### tokenchars
	tokenchars "<string>"
This is one of two fields that identifies a unique token in GeoManager's token 
database file (see **tokenid**, below). The **tokenchars** field must be a string of 
four characters that identifies the geode's token. Note that these characters 
also appear in the geode file's extended attributes.

----------
#### tokenid
	tokenid	<number>
This is the other of two fields that identifies a unique token in GeoManager's 
token database file (see **tokenchars**, above). It must be a number 
corresponding to the programmer's manufacturer ID number. Note that this 
number also appears in the geode file's extended attributes.

----------
#### type
	type	(process|driver|appl|library)+ [single] [system] [uses-coproc]\
			[needs-coproc] [has-gcm] [c-api]
The **type** field in the parameters file designates certain characteristics of the 
geode being compiled. These attributes correspond to the **GeodeAttrs** type 
and determine how the Glue linker will put the geode together. The attributes 
are as follows:

**process** - This attribute indicates the geode has its own thread. 
Applications should always have process specified in the type 
field.

**driver** - This attribute indicates the geode has a driver aspect.

**appl** - This attribute indicates the geode has an application aspect.

**library** - This attribute indicates the geode has a library aspect.

**single** - This geode may only have one copy running at a time. Some 
applications may allow multiple copies to be running at once; 
they should not specify single as a type attribute.

**system** - This attribute is set for drivers that must be exited specially and 
must always be exited. For example, a swap driver has special 
exit conditions that must always be met and is therefore a system 
driver.

**uses-coproc** - This attribute is set if the geode will make use of a math 
coprocessor if one is available. Note that if the geode with this 
attribute set is a library, all applications that use the library will 
inherit the property. This attribute is used to indicate that the 
coprocessor's state must be saved during a context switch.

**needs-coproc** - This attribute indicates that the geode must have a math 
coprocessor to run. (This implies *uses-coproc*, above).

**has-gcm** - This attribute indicates that the application being compiled has 
a GCM (appliance) version. This information is used by Welcome 
to locate all GCM applications.

**c-api** - This attribute indicates the library entry points are written in C 
so the kernel must call them with C calling conventions.

----------
#### usernotes
	usernotes "<string>"
This field specifies text to be put in the **.geo** file's usernotes field. The text must 
be within quotation marks and can be up to 100 characters long. It must 
contain no line breaks. This can be useful for containing copyright notices in 
the executable files. The user can read the text in the usernotes by using 
GeoManager's File/Get Info command.

[Table of Contents](../asmref.md) &nbsp;&nbsp; --> [Routines](asma_d.md)