# 1 Goc Keywords

----------
#### @alias
    @alias(<protoMsg>) <messageDef>;

The @alias keyword is used for messages which take conditional parameters in 
an assembly handler. For example, if the assembly handler takes a word 
parameter normally and a dword only if a certain flag is set, you will need to 
have two C messages with the two different parameters. The @alias keyword 
allows this. Its arguments are shown below:

*protoMsg* - The name of the existing message that the alias will reference.

*messageDef* - The new message definition. This is a standard message 
definition as would follow the @message keyword.

    @message void MSG_MY_MSG(word par);
    @alias(MSG_MY_MSG) void MSG_MY_SECOND_MSG(dword par);

**See Also:** @message

----------
#### @call
    <ret> = @call [,<flags>] [{<cast_ret>}] \
    <obj>::[{<cast_par>}]<msg>(<param>*);

The @call keyword sends the specified message to the specified object and 
makes the caller wait until the message is processed before continuing. The 
arguments of @call are shown below:

*ret* - A variable for receiving the return value of the message as 
defined by @message. This has the same usage as a typical 
function return value.

*flags* - Flags that determine how the message affects the recipient's 
event queue. The allowable flags are shown below. (The comma 
is required before each flag.) 

*cast_ret* - A message to cast the message return value to. When Goc 
determines what type of value should be returned, it uses the 
return value of the *cast_ret* message if this field is used. The curly 
braces are required around this field.

*obj* - The name of the recipient object, or a variable representing the 
optr of the recipient.

*cast_par* - A message to cast the message parameters to. When Goc 
determines what type of values should be passed to the message, 
should be returned, it uses the parameters of the *cast_par* 
message if this field is used. The curly braces are required around 
this field.

*msg* - The name of the message to be sent, or an expression 
representing the message number. If an expression is used, you 
must cast the message to a certain type with the cast parameter.

*param* - Expressions or constants passed to the message. Parameters 
passed to messages are specified in the same way as if they were 
being passed directly to a function or routine in C.

The flags allowed with @call are shown below:

**forceQueue**  
This flag will cause the message to be placed in the recipient's 
event queue, even if it could have been handled by a direct call.

**checkDuplicate**  
This flag makes the kernel check if a message of the same name 
is already in the recipient's event queue. For this flag to work, 
*forceQueue* must also be passed. Note that due to implementation 
constraints, events will be checked from last to first rather than 
from first to last.

**checkLastOnly**  
This flag works like *checkDuplicate*, above, except that it checks 
only the last message in the event queue.

**replace**  
This flag modifies *checkDuplicate* and *checkLastOnly* by 
superseding the duplicate (old) event with the new one. The new 
event will be put in the duplicate's position in the event queue. If 
a duplicate is found but the replace flag is not passed, the 
duplicate will be dropped and the new event will be put at the end 
of the queue.

**insertAtFront**  
This puts the message at the front of the recipient's event queue. 
Note that this flag will supersede the *replace* flag.

**canDiscardIfDesperate**  
This flag indicates that this event may be discarded if the system 
is running extremely low on handles and requires more space 
immediately.

Additionally, @call alows the use of several special expressions in place of the 
recipient:

**self** - Send the message to the object issuing the @call command. e.g.

    @call self::MSG_VIS_DRAW(flags, gstate);
**process** - Send the message to the object's associated Process object. e.g.

    @call process::MSG_HELLO_RESPOND();
**application** - Send the message to the object's associated GenApplication 
object.

    attr = @call application::MSG_GEN_GET_ATTRIBUTES();
**@genParent** - Send the message to the object's generic parent in a generic 
object tree.

**@visParent** - Send the message to the object's visible parent in a visible object 
tree.

If you need to send a message to an object's superclass, use the @callsuper 
keyword rather than @call.

    gstate = @call myObj::MSG_META_CUT();
    retVal = @call {MSG_MY_MSG} myObj::MSG_OTHER_MSG();
    retVal = @call myObj::MSG_MY_MSG(10, param1);

**See Also:** @send, @callsuper, @message, @method, @object

----------
#### @callsuper
    <ret> = @callsuper [{<cast_ret>}] \
    <obj>::<class>::[{<cast_par>}]<msg>(<param>*) [<flags>]+;

    @callsuper;

The @callsuper keyword does two things: The most useful is to pass a received 
message on to the superclass to ensure default behavior is preserved; the 
second, and less used, acts just like @call but sends the message to the 
recipient's superclass rather than the recipient's class. This is rarely used but 
can be used if only default behavior is required of the message. Its arguments 
are shown below:

*ret* - Same as @call.

*obj* - Same as @call.

*cast_ret* - Same as @call.

*class* - The name of the object's superclass that should receive the 
message. It is possible to send the message to the highest 
superclass.

*cast_par* - Same as @call.

*msg* - Same as @call.

*param* - Same as @call.

*flags* - Same as @call.

    (void) @callsuper myObj::MySupClass::MSG_MY_MSG();

**See Also:** @call, @send, @message, @method

----------
#### @chunk
    @chunk  <type> <name> [= <init>];

The @chunk keyword declares a resource chunk containing data of some kind. 
Data can be of any GEOS or C data type or structure, including a string of 
characters. The chunk must be declared between the resource delimiters 
@start and @end. Its arguments are described below:

*type* - The data type or structure type of the chunk.

*name* - The name of the chunk - how it will be referenced by other 
entities.

*init* - Initializer data, if any, to initialize the chunk to.

If you will need to access the chunk from another executable file, you must 
declare it in the other file with @extern. Objects are declared with @object.

    typedef struct {
        int     a;
        int     b;
    } MyStruct;

    char    MyString[8];

    @start MyDataResource, data, notDetachable;
    @chunk word         MyWordChunk;
    @chunk MyStruct     MyMSChunk = {5, 10};
    @chunk MyString     MyStringChunk = "My string";
    @end;

**See Also:** @start, @end, @object, @extern

----------
#### @chunkArray
    @chunkArray     <stype> <aname> [= {<init>}];

The @chunkArray keyword declares a Chunk Array, a special kind of chunk. Only 
uniform-element-size chunk arrays may be declared with this keyword. It has 
the following arguments:

*stype* - This is the type of each element in the Chunk Array. It may be 
any standard C or Goc type, or any derived type.

*aname* - This is the name of the Chunk Array.

*init* - You may declare the initializer values for a chunk array. If you do 
not set any initial values, the Chunk Array will be created with 
no elements.

    @chunkArray int     someints;

    @chunkArray dword   somedwords = {123456789, 
                                        6021023, 
                                        31415926};

**See Also:** @chunk, @elementArray

----------
#### @class
    @class  <cname>, <super> [, master [, variant]];

The @class keyword begins a class definition. All instance data and messages 
for the class are declared between @class and @endc. The arguments of @class 
are listed below:

*cname* - Name of the class being declared.

*super* - Name of the superclass.

*master* - Use of this term designates this class as a master class.

*variant* - Use of this term designates this class as a variant class.

    @class MyTriggerClass, GenTriggerClass;
    @endc

    @class MyMasterVarClass, MetaClass, master, variant;
    @endc

**See Also:** @endc, @classdecl

----------
#### @classdecl
    @classdecl <cname> [, neverSaved];

The @classdecl keyword defines a given class structure in memory. Every new 
class that will be used by an application must appear in an @classdecl 
declaration. The arguments for this keyword are shown below:

*cname* - The name of the class being declared.

*neverSaved* - Using this term indicates that objects of this class are never 
saved along with state information.

    @classdecl MyTriggerClass;
    @classdecl MyProcessClass, neverSaved;

**See Also:** @class

----------
#### @composite
    @instance @composite <iname> = <linkFieldName>;

The @composite keyword appears as a subcommand of @instance. It is a type 
of instance data - it indicates that an object of this class can have several 
children and that the @composite instance data field will be an optr to the first 
of its children. The arguments of the @composite keyword are given below:

*iname* - The name of the instance data field.

*linkFieldName* - The name of the @link instance data field for this class.

    @class GenTrigWithKidsClass, GenTriggerClass;
        /* GI_link is the GenClass sibling link field. */
        @instance @composite GTWKI_comp = GI_link;
    @endc

**See Also:** @instance, @link

----------
#### @default
    <fname> = @default [<op> [~]<attr>]*; /* to use default value of
                                            instance data field */

    @default <varRoot> = <super>; /* to specify default superclass of 
                                    a variant class */

    @default <fname> = <value>; /* to specify a default value for an instance
                                    data field defined by a superclass. */

    <fname> = @default;

The @default keyword can be used in several ways: to specify the default value 
of an instance data field, to represent the default value of an object's instance 
data field, or to specify the default superclass of a variant class. It may also be 
used when defining a class to specify a default value to use with an instance 
data field defined by a superclass.

The @default keyword is most commonly used when modifying default instance 
data values of bitfield-type fields. The defaults are set in the @class definition 
and may be modified in the @object declaration. The arguments of @default are 
shown below:

*fname* - The name of the instance data field. Typically, this is a record.

*op* - A bitwise operator character. If setting certain bits, use the OR 
operator (|); if removing certain bits, use the AND operator (&).

*attr* - The name of the attribute bit to set or remove. If removing 
attribute bits, place the logical NOT character (~) in front of the 
attribute.

    @object GenPrimaryClass MyPrimary {
        GI_states = @default & ~GENS_MAXIMIZED;
        GI_attrs = @default | GENA_TARGETABLE;
    }

The @default keyword can also be used to specify the default superclass of a 
variant class. In this case, it has the following arguments:

*varRoot* - The name of the variant class, with the word "Class" removed. 
(e.g. the root of "MyVariantClass" is "MyVariant".)

*super* - The default superclass for this variant class.

To specify a class' default value for an instance data field when that instance 
data field is defined by a superclass, @default has the following arguments:

*fname* - The name of the instance data field.

*value* - The class' default value for the field.

To represent an object's default value for an instance data field, @default has 
the following arguments:

*fname* - The name of the instance data field.

**See Also:** @object, @instance, @class

----------
#### @define
    @define <mname>[(<pdef>)] <macro>

The @define directive defines a Goc macro. You can define C macros with the 
\#define directive; macros that use Goc operators, keywords, or code must be 
defined with @define. Similarly, macros defined with @define must be later 
used with the "@" marker preceeding them; otherwise, the Goc processor will 
scan over the macro and will not evaluate it. The arguments of @define are 
listed below:

*mname* - The macro name. This can be used later as @mname to invoke 
the macro.

*pdef* - The optional parameter definition, as with C macros.

*macro* - The macro.

    @define MyChunk(a) @chunk char[] a = "text";
    @define MyText(a,b) @chunk char[] a = "b";

    /* You can later use these macros as follows: */
    @MyChunk(Text1)
    @MyText(Text2, newText)

    /* This will evaluate to the following: */
    @chunk char[] Text1 = "text";
    @chunk char[] Text2 = "newText";

----------
#### @deflib
    @deflib <libName>

Most Goc libraries will have a **.goh** header file. This file should begin with a 
@deflib directive. This will see to it that no library header file is included more 
than once in a given compilation. The file must end with an @endlib directive. 
The @deflib directive takes the following argument:

*libName* - This is the name of the header file, with the **.goh** extension 
stripped off. For example, if the library's header file is 
**hellolib.goh**, the file would begin with

    @deflib     hellolib

**See Also:** @endlib

----------
#### @dispatch
    @dispatch [noFree] [{<cast>}] <nObj>::<nMsg>::<event>;

The @dispatch keyword sends a previously-encapsulated message to the 
specified object. This keyword is analogous to @send; use @dispatchcall if the 
event must be processed immediately. The encapsulated event must have been 
defined with @record. The arguments of @dispatch are given below:

*noFree* - A flag indicating the event will not be freed after it is handled.

*cast* - A message to cast the parameters to.

*nObj* - An override recipient object for the event. Encapsulated 
messages can store recipients; this will override the stored value. 
If no override is desired, specify this as null.

*nMsg* - An override message to be sent. Encapsulated messages can 
store the message number to be sent; this will override the stored 
value. If no override is desired, specify this as null.

*event* - The name of the encapsulated event, defined earlier with 
@record.

    @dispatch null::null::myEvent;
    @dispatch newObject::null::myEvent;
    @dispatch null::MSG_NEW_MSG::myEvent;

**See Also:** @record, @send, @dispatchcall

----------
#### @dispatchcall
    <ret> = @dispatchcall [noFree] [{<cast>}] <nObj>::<nMsg>::<event>;

The @dispatchcall keyword sends a previously-encapsulated message to the 
specified object. This keyword is analogous to @call; use @dispatch if the event 
can be sent with no return values. The encapsulated event must have been 
defined with @record. The arguments of @dispatchcall are given below:

*ret* - A variable to receive the returned value.

*noFree* - A flag indicating the event will not be freed after it is handled.

*cast* - A message to cast the parameters and return value to.

*nObj* - An override recipient object for the event. Encapsulated 
messages can store recipients; this will override the stored value. 
If no override is desired, specify this as null.

*nMsg* - An override message to be sent. Encapsulated messages can 
store the message number to be sent; this will override the stored 
value. If no override is desired, specify this as null.

*event* - The name of the encapsulated event, defined earlier with 
@record.

    retVal = @dispatchcall null::null::myEvent;
    retVal = @dispatchcall newObject::null::myEvent;
    (void) @dispatchcall null::MSG_NEW_MSG::myEvent;

**See Also:** @record, @send, @dispatchcall

----------
#### @elementArray
    @elementArray   <stype> <aname> [= {<init>}];

The @elementArray keyword declares an Element Array, a special kind of Chunk Array. 
It has the following arguments:

*stype* - This is the type of each element in the Element Array. It may be 
any standard C or Goc type, or any derived type.

*aname* - This is the name of the Element Array.

*init* - You may declare the initializer values for a chunk array. If you do 
not set any initial values, the Element Array will be created with 
no elements.

**See Also:** @chunk, @chunkArray

----------
#### @end
    @end    <segname>

The @end keyword denotes the end of a resource block definition that had been 
started with @start. Its one argument is the name of the resource segment.

    @start MenuResource;
    @end

**See Also:** @start, @header, @object, @chunk

----------
#### @endc
    @endc

The @endc keyword denotes the end of a class definition begun with @class. It 
has no arguments.

**See Also:** @class

----------
#### @endif
    @endif

The @endif directive denotes the end of a block of conditionally-compiled code. 
It is used with @if, @ifdef, and @ifndef.

**See Also:** @if, @ifdef, @ifndef

----------
#### @endlib
    @endlib

Most Goc libraries will have a .goh header file. This file should end with an 
@endlib directive. This will see to it that no library header file is included more 
than once in a given compilation. The file must begin with an @deflib directive.

**See Also:** @deflib

----------
#### @exportMessages
    @exportMessages <expname>, <num>;

The @exportMessages keyword sets aside a number of message spots so the 
messages may be declared elsewhere. This allows users of the class to declare 
messages that are guaranteed to be unique across all subclasses. Exported 
messages are declared with the @importMessage keyword. The arguments of 
@exportMessages are shown below:

*expname* - Name of the range being exported.

*num* - Number of message spots to be exported.

    @exportMessages MetaUIMessages, 50;
    @exportMessages MyExportedMessages, 12;

**See Also:** - @importMessage, @reserveMessages, @message

----------
#### @extern
    @extern <type> <name>;
    @extern method <cname>, <manme>+

The @extern keyword allows code in a given compilation session to access 
objects, chunks, monikers, and methods defined in another compilation 
session. The compiler will assume the element exists and will be linked by the 
Glue linker. If Glue is unable to locate and link the external resource element, 
it will respond with an error. The arguments of @extern are given below:

*type* - The type of resource element being referenced. This must be one 
of *object*, *chunk*, *visMoniker*, or *method*.

*name* - The name of the element being referenced.

    @extern chunk MyChunk;
    @extern object MyBlueTrigger;
    @extern visMoniker GAL_visMoniker;

If @extern is being used to declare a method which is in a different file from the 
class declaration, it has the following arguments:

*cname* - The name of the class for which the method is defined.

*mname+* - The name of the message which invokes the method. As with 
normal method declarations, there must be at least one message 
which invokes the method.

Some confusion has arisen about when to use @extern. The following notes 
will hopefully prove useful.

##### Classes
Your class' definition should not be broken up over files. If you wish to keep 
your class definition in a file separate from your other code, this file should be 
a **.goh** file.

If your class is *declared* (@classdecl) in a file other than where it is *defined* 
(@class), then the declaring file should @**include** the defining file.

Normally the declaring file contains all method definitions for the class. If any 
method definitions are in another file, then both files will need an @**extern** 
keyword like so:

In file containing class declaration:

    @extern method MyClass, MSG_MY_DO_SOMETHING;

In file containing method code:

    @extern method MyClass, MSG_MY_DO_SOMETHING(word myArg)
    { /* Method code here */ }

##### Object Trees

All objects declared in a static tree (e.g. your application's generic tree) should 
be in the same source file. If they are in different files, then they may be joined 
into a single tree only by dynamically adding objects from one file as children 
to objects of the other.

Note that if one file contains a tree of objects, then you may incorporate the 
whole tree by simply dynamically adding the top object in the file to the main 
tree. You won't have to add each object individually.

If an object declared in one source file will send a message to an object in 
another source file, you must include an @**extern** line in the source file 
containing the sending object: 

    @extern object ReceivingObjectName;

The message itself should be sent in the following manner (with variations 
possible if you will be using @**call**, passing arguments, or what have you):

    optr ROOptr;
    ROOptr = GeodeGetOptrNS(@ReceivingObjectName);
    @send ROOptr::MSG_DO_SOMETHING(0, 0);

**See Also:** @chunk, @object, @visMoniker

----------
#### gcnList
    gcnList(<manufID>,<lname>) = <oname> [, <oname>]*;

The gcnList keyword, which does not have the keyword marker @ preceeding 
it, puts the listed objects onto the specified notification list. GCN lists are 
specified by both manufacturer ID and list type. The arguments of the gcnList 
keyword are given below:

*manufID* - The manufacturer ID number of the GCN list type. Often this will 
be MANUFACTURER_ID_GEOWORKS.

*lname* - The list type, or list name, of the GCN list.

*oname* - A listing of all the objects that will be included on the GCN list. 
Separate objects with commas.

    @object GenApplicationClass HelloApp = {
        GI_comp = HelloPrimary;
        gcnList(MANUFACTURER_ID_GEOWORKS, GAGCNLT_WINDOWS) =
                                        HelloPrimary;
    }

**See Also:** @object

----------
#### @genChildren
    @send @genChildren::<msg>(<params>);

Any composite object in a generic object tree (therefore a subclass of 
**GenClass**) can send a message that will be dispatched at once to all of its 
children. Note that any message sent with @genChildren as the destination 
must be dispatched with the @**send** keyword and therefore can have no return 
value and can not pass pointers in its parameters.

----------
#### @genParent
    [@send | @call]@genParent::<msg>(<params>);

Any composite object in a generic object tree (therefore a subclass of 
GenClass) can use the @genParent address to send a message to its **generic** 
parent. This can be used with either @send or @call.

----------
#### @gstring
    @gstring <gsname> = {[<command> [, <command>]+]}

The @gstring keyword lets you declare a GString in Goc source code.

*gsname* - The name of the chunk which will contain the GString.

*command* - This may be any command which could be put in a GString.

----------
#### @header
    @header <type> [= <init>];

The @header keyword sets the header of an object or data resource segment to 
a custom structure. The structure must begin with an LMemBlockHeader or 
ObjLMemBlockHeader. The arguments of @header are given below:

*type* - The name of the structure set as the new header type.

*init* - Any initializer data for the fields added to your structure.

    typedef struct {
        LMemBlockHeader  meta;
        int     a;
        int     b;
    } MyLMemBlockHeader;
    @start MyDataResource, data, notDetachable;
    @header MyLMemBlockHeader = 10, 12;
    @end;

**See Also:** @start, @end, @object, @chunk

----------
#### @if
    @if (<cond>)

The @if directive denotes the beginning of a conditionally-compiled block of 
code. If the expression detailed in *cond* equates to *true*, then the code between 
the @if directive and the first corresponding @endif directive will be compiled 
with the rest of the code.

*cond* - The expression determining whether the code is to be compiled or 
not. This expression is based on numerical values, names of 
macros, and Boolean operators (|| and &&).

    @if 0
        /* code not compiled */
    @endif

    @if MyMacro
        /* code compiled if MyMacro is defined */
    @endif

    @if defined(MyMacro) || MY_CONDITION
        /* code compiled either if MyMacro is defined or
         * if MY_CONDITION is non-zero */
    @endif

**See Also:** @ifdef, @ifndef, @endif

----------
#### @ifdef
    @ifdef <item>

The @ifdef directive is similar to the @if directive in use, except the condition 
it evaluates is based solely on whether the *item* is defined or not (if *item* is 
defined, the following code is compiled).

**See Also:** @if, @ifndef, @endif

----------
#### @ifndef
    @ifndef <item>

The @ifndef directive is similar to the @ifdef directive in use, except the 
condition it evaluates is based solely on whether *item* is not defined (if *item* is 
not defined, the following code is compiled).

**See Also:** @if, @ifdef, @endif

----------
#### @importMessage
    @importMessage <expname>, <messageDef>;

The @importMessage keyword declares a message with a reserved message 
number set aside earlier by @exportMessages. The arguments of this keyword 
are given below:

*expname* - Name of the range exported with @exportMessages.

*messageDef* - Standard message definition - exactly the same as would follow 
the @message keyword for message declaration.

    @importMessage MyExportedMessages, word MSG_MY_MSG(
                        byte param1, byte param2);

**See Also:** @exportMessages, @reserveMessages, @message

----------
#### @include
    @include <fname>

The @include directive is used to include Goc files into a code file. It is similar 
to the #include directive in C. Its only argument is a file name (*fname*) enclosed 
in either angled brackets or quotation marks. If you use quotation marks, the 
compiler will look first in the file's own directory; if you use angled brackets, it 
will look first in the standard include directories.

    @include <stdapp.goh>
    @include <uitsctrl.goh>
    @include "Art/mkrGenDoc"

----------
#### @instance
    @instance <insType> <iname> = <default>;

The @instance keyword declares an instance data field for a class. This 
keyword will appear between the class delimeters @class and @endc. Its 
arguments are shown below:

*insType* - The data type of the instance data field. Must be a valid C data 
type or data structure. (Note - special types may also be used; see 
discussion below.)

*iname* - The name of the instance data field.

*default* - The default value of the field if it is not declared explicitly in the 
instance of the class.

The Goc preprocessor allows the use of several special types of instance data 
fields. To use these special types, insert the proper keyword (type name) in 
place of the *insType* argument above and do not include a default value for the 
field (*default*). The possible special types and their meanings are given in the 
list below (see the individual keyword entries for more detail):

@**composite** - This field will point to the first child in an object hierarchy. Note 
that this keyword has a special format. Rather than being 
allowed a default value, set the *default* argument in the 
declaration to be the same as the name of the corresponding 
@link field. This is important; otherwise, your program will not 
compile properly.

@**link** - This field will point to the next sibling object in an object 
hierarchy or will point to the parent.

@**visMoniker** - This field will contain a visual moniker or a pointer to a visual 
moniker resource chunk.

@**kbdAccelerator** - This field will contain a keyboard accelerator character.

Note that if you want to declare instance data fields for variable-sized data, you 
should use the @vardata keyword rather than @instance.

    @instance int               myInteger = 10;

    typedef struc {
        int     a;
        int     b;
    } MyStruc;
    @instance MyStruc           strucField = {7, 11};

    @instance @visMoniker       GI_moniker;

    @instance @link             VI_link;
    @instance @composite        VCI_comp = VI_link;

    @instance @kbdAccelerator   GI_kbdAcc;

**See Also:** @vardata, @visMoniker, @link, @composite, @kbdAccelerator

----------
#### @kbdAccelerator
    @instance @kbdAccelerator <iname>;

The @kbdAccelerator keyword follows @instance to create an instance data 
field that will contain a keyboard accelerator. The *iname* argument is the name 
of the instance data field.

    @instance @kbdAccelerator GI_kbdAcc;

**See Also:** @instance

----------
#### @link
    @instance @link <iname>;

The @link keyword follows @instance to define a link instance data field 
pointing to the object's next sibling in the object hierarchy. The *iname* 
argument is the name of the instance data field. Note that the name of the link 
field must be set as the default value of the corresponding @composite field.

    @instance @link GI_link;
    @instance @composite GI_comp = GI_link;

**See Also:** @instance, @composite

----------
#### @message
    @message    <retType> <mname>([@stack] <param>*);

The @message keyword defines a message and its parameters and return 
values. This keyword will appear within a class definition (i.e., between @class 
and @endc). The message defined with @message will automatically be valid 
for the class for which it is defined as well as for subclasses of that class. The 
arguments of this keyword are shown below:

*retType* - The data type of the value returned by this message. This must 
be a standard C or GEOS data type or pointer.

*mname* - The name of the message. Typically, this will be the prefix "MSG_" 
followed by a shortened version of the class name, followed by a 
short name for the message.

*@stack* - This keyword may be used if the message might be sent from 
assembly language code instead of Goc. It indicates that the 
arguments will be passed on the stack; the handler will pop them 
off the stack in reverse order from the way they are listed in the 
declaration.

*param** - The parameters for this message, of which there may be none or 
several. All the parameters must appear inside the parentheses. 
Parameters are defined in a similar manner as for functions and 
routines; each one consists of a data type followed by the name of 
the parameter of that type.

    message void MSG_TRIGGER_PUSHED(int push1);
    @message word MSG_MY_MSG(byte firstParam, word secParam,
                            long thirdParam);

**See Also:** @method, @reserveMessages, @exportMessages, @importMessage, @record

----------
#### @method
    @method [<hname>,] <cname>, <mname>+ [{<code>}];

The @method keyword begins definition of a method (message handler). Its 
arguments are listed below:

*hname* - The method name, if any. If no method name is given, one will be 
created by removing "Class" from the class name and "MSG_" 
from the message name and concatenating the two.

*cname* - The name of the class to which the method belongs. Each method 
belongs to only one class.

*mname+* - The name(s) of the message(s) handled by this method. There 
must be at least one message which invokes this method. There 
may be more than one, as long as they all have the same 
parameters.

*code* - Goc procedural code to handle the message. If there is no code, 
*hname* is assumed to be the name of an existing routine which 
should be used as the method.

    @method   MyClass, MSG_MY_MSG {
        /* method code goes here */
    }

    @method   MyClassMethod, MyClass, MSG_MY_MSG {
        /* method code goes here */
    }

**See Also:** - @message

----------
#### @noreloc
    @noreloc <iname>;

The @noreloc keyword specifies that an instance data field (defined in the 
previous program statement) is not relocatable. Normally optr fields are 
assumed to be relocatable and will be automatically relocated by the system 
when shutting down and coming back from a shutdown; by means of the 
@noreloc, this automatic behavior can be turned off for a given field.

----------
#### @object
    @object <class> <name> <flags>* = {
        [<fieldName> = <init>;]*
        [<varName> [= <init>];]*
    }

The @object keyword defines an object in an object resource block. It must 
appear between @start and @end. Its arguments are defined below:

*class* - The name of the class of the object.

*name* - The name of the object.

*flags* - Flags associated with the object; currently only *ignoreDirty* is 
supported. When set, this flag indicates that changes to the 
object should not be saved to a state file. Note, however, that 
*ignoreDirty* should never be set for generic objects.

*fieldName* - The name of an instance data field defined with @instance. Any 
number of such fields may be specified.

*varName* - The name of an instance data field defined with @vardata. Any 
number of such fields may be specified.

*init* - Initializer data for a normal instance data field or for the extra 
data of a variable data field. If a variable data field has no extra 
data, no initializer should be specified.

Many fields may be specified in the object declaration. Each field reference 
must be defined in a class in the object's class ancestry. Additionally, not all 
fields must be set. If a field is not specified within the @object declaration, the 
field will be set to its default value as defined by the class.

    @start MyObjectResource;

    @object GenTriggerClass MyTrigger ignoreDirty = {
        GI_visMoniker = "MyTrigger's Moniker";
    }
    @object GenApplicationClass MyApp = {
        GI_comp = MyPrimary;
        gcnList(MANUFACTURER_ID_GEOWORKS, GAGCNLT_WINDOWS) =
                            MyPrimary;
    }
    @object GenPrimaryClass MyPrimary = {
        GI_comp = MyMenu, MyInteraction, MyView;
        GI_visMoniker = "My Primary's Moniker";
    }
    @object MyClass NewObject = {
        NO_instance1 = 1;
        NO_instance6 = `C';
    }

    @end

**See Also:** @start, @end, @extern, @class, @instance, @vardata

----------
#### @optimize
    @optimize

This directive may be placed at the top of a **.goh** file. The directive instructs 
Goc to generate a specially processed **.poh** file which contains all the 
information of the **.goh** file, but is somewhat faster to compile. This **.poh** file is 
automatically regenerated if the corresponding **.goh** file has been changed 
since the last compilation.

----------
#### @protominor
    @protominor <prototypeName>

When creating a new version of an existing library, use the @**protominor** 
keyword to declare new messages and variable data fields for a class. Suppose 
your original class declaration looked like so:

        @class MyClass, SuperClass;
            @message void MSG_M_DO_THIS(void);
            @vardata void TEMP_M_DONE_FLAG;
        @endc

Having released this version of your class, you wished to release another 
version in which this class handled another message. You wanted to specify 
that this new message would only work with this new version of the library. 
This would be set up like so:

    @class MyClass, SuperClass;
        @message void MSG_M_DO_THIS(void);
        @vardata void TEMP_M_DONE_FLAG;

    @protominor MyVersion20
    @message void MSG_M_DO_THAT(void);
    @endc

To do the equivalent version control with routines, use the **incminor** .gp file 
directive.

----------
#### @prototype
    @prototype <messageDef>;

The @prototype keyword allows multiple messages to have the same pass and 
return parameters. Use @prototype to define the pass and return values, then 
use @message to declare the messages that have these parameters. The 
messages defined with @message will have different message numbers and 
will invoke different methods. The *messageDef* argument is a standard 
message definition.

    @prototype word MSG_MY_PROTO(byte param1);

    @message(MSG_MY_PROTO) MSG_MY_MSG;
    @message(MSG_MY_PROTO) MSG_MY_SECOND_MSG;

**See Also:** @alias, @message

----------
#### @record
    <event> = @record <obj>::<msg>(<param>*);

The @record keyword encapsulates an event for later use with @dispatch or 
@dispatchcall. The arguments of @record are as follows:

*event* - The name of the event. This name will be used with @dispatch 
and @dispatchcall later.

*obj* - The name of the object, or an expression representing the object 
that will receive the message. This may be set to *null* to indicate 
that the recipient will be determined when the message is sent.

*msg* - The name of the message, or an expression representing the 
message that will be sent. This may be set to *null* to indicate that 
the message will be determined when it it sent.

*param* - This is a list of parameters that will be sent with the message 
when it is dispatched.

    myEvent = @record myObj::MSG_VIS_VUP_CREATE_GSTATE();

**See Also:** @dispatch, @dispatchcall, @call, @send

----------
#### @reloc
    @reloc  <iname>, [(<count>, <struct>)] <ptrType>;
    @reloc  <iname>, <fn>, [(<count>, <struct>)] <ptrType>;

The @reloc keyword designates an instance data field that contains data 
requiring relocation on startup. Note that this does not include instance fields 
declared with the @composite and @link fields, but it does include any handle 
or pointer fields you may have. Note that there are two different formats for the 
use of @reloc. The first represents a normal instance field; the second 
represents a variable data instance field (see @vardata). This is *not* used with 
@instance or @vardata but stands alone.

The arguments of @reloc are shown below:

*iname* - The name of the relocatable instance data field.

*count* - If the instance variable is an array of relocatable data or 
structures containing relocatable fields, this is the number of 
elements in the array.

*struct* - If the relocatable data is an array of structures, this represents 
the name of the field within each structure that requires 
relocation.

*ptrType* - This is the type of pointer in the relocatable field. This must be 
one of *optr* (object pointer), *ptr* (far pointer), or *handle*.

*fn* - This is the name of the field within the extra data of the variable 
data. If no extra data will be associated with this relocatable 
field, then put a zero (0) rather than a field name.

    @reloc MO_myHandle, handle;
    @reloc MO_myVarHandle, 0, handle;
    @reloc MO_myTable, (10, MyStruct), ptr;

**See Also:** @instance, @vardata

----------
#### _reloc
    @method [<hname>,] <cname>, _reloc { <code>};

The _reloc keyword is used to write relocation handlers for classes, if you need 
to relocate-unrelocate instance data when it's either read in or saved to state.

The arguments of _reloc are show below:

*code* - Code to execute when the object block is loaded in or saved out to 
state, in which case instance data may need to be relocated or 
unrelocated by hand.    

----------
#### @reserveMessages
    @reserveMessages <number>;

The @reserveMessages keyword reserves the given number of message spots. 
Messages are numbered sequentially according to the order of their 
declaration; this keyword allows one or more numbers to be skipped in the 
numbering process, allowing application upgrades without making earlier 
versions obsolete. The single argument is the number of message spots to skip.

    @reserveMessages 25;

**See Also:** @exportMessages, @importMessage, @message

----------
#### @send
    @send   [<flags>+] [(<cast_ret>)] <obj>::[{<cast_par>}]<msg>(<param>*);

The @send keyword sends a given message to the specified object. The message 
will be sent and the sender's thread will continue executing without waiting for 
a response. If return values or synchronization is important, use the @call 
keyword. The parameters of @send are shown below:

*flags* - Flags that determine how the message affects the recipient's 
event queue. The allowable flags are shown below. (The comma 
is required before each flag.)

*cast_ret* - A message to cast the message return value to. When Goc 
determines what type of value should be returned, it uses the 
return value of the *cast_ret* message if this field is used. The curly 
braces are required around this field.

*obj* - The name of the recipient object, or an optr to the object.

*cast_par* - A message to cast the message parameters to. When Goc 
determines what type of values should be passed to the message, 
should be returned, it uses the parameters of the *cast_par* 
message if this field is used. The curly braces are required 
around this field.

*msg* - The name of the message to be sent, or an expression 
representing the message number. If an expression is used, you 
must cast the message to a certain type with the cast argument .

*param* - Expressions or constants passed to the message. Parameters 
passed to messages are specified in the same way as if they were 
being passed directly to a function or routine in C. Note that 
pointers may *not* be passed with @send but handles may; if you 
must pass a pointer, use @call.

The flags allowed with @send are shown below:

**forceQueue**  
This flag will cause the message to be placed in the recipient's 
event queue, even if it could have been handled by a direct call.

**checkDuplicate**  
This flag makes the kernel check if a message of the same name 
is already in the recipient's event queue. For this flag to work, 
forceQueue must also be passed. Note that due to implementation 
constraints, events will be checked from last to first rather than 
from first to last.

**checkLastOnly**  
This flag works like checkDuplicate, above, except that it checks 
only the last message in the event queue.

**replace**  
This flag modifies checkDuplicate and checkLastOnly by 
superseding the duplicate (old) event with the new one. The new 
event will be put in the duplicate's position in the event queue. If 
a duplicate is found but the replace flag is not passed, the 
duplicate will be dropped and the new event will be put at the end 
of the queue.

**insertAtFront**  
This puts the message at the front of the recipient's event queue. 
Note that this flag will supersede the replace flag.

**canDiscardIfDesperate**  
This flag indicates that this event may be discarded if the system 
is running extremely low on handles and requires more space 
immediately.

    @send, forceQueue MyObj::MSG_MY_MSG(10, x);
    @send MyObj::MSG_SET_ATTR(attributesParam);

**See Also:** @call, @callsuper, @message, @method

----------
#### @specificUI
    <fname> = [@specificUI] <mod>* <key>;

The @specificUI keyword is used when setting a keyboard accelerator instance 
field in an object declaration. It tells the UI to allow the use of the keystrokes 
specified, even if they are normally reserved for the specific UI. The keyword 
itself takes no arguments; those shown are for the **GenClass** instance data 
field *GI_kbdAccelerator*. These are

*fname* - The name of the instance data field defined with @instance.

*mod* - Modifier keys; must be one or more of *control, ctrl, shift, alt.*

*key* - The accelerator character. Must be either a numeric value of a 
keyboard key or a letter enclosed in single quotation marks.

    @object MyClass MyObject {
        GI_kbdAccelerator = ctrl shift `k';
    }

**See Also:** GenClass, @kbdAccelerator, @instance

----------
#### @stack
    @message    <retType> <mname>([@stack] <param>*);

This keyword may be used if the message might be sent from assembly 
language code instead of Goc. It indicates that the arguments will be passed on 
the stack; the handler will pop them off the stack in reverse order from the way 
they are listed in the declaration.

**See Also:** @message

----------
#### @start
    @start  <segname> [, <flags>];

The @start keyword indicates the beginning of a resource block. The end of the 
block is denoted by the keyword @end. The arguments of @start are listed 
below:

*segname* - The name of the resource segment.

*flags* - Optional flags. The flag data, when set, indicates the block will 
be a data resource rather than an object resource. The flag 
*notDetachable*, when set, indicates the block should not be saved 
to a state file.

    @start MenuResource;
    @end

    @start MyDataResource, data, notDetachable;
    @end

**See Also:** @end, @header, @object, @chunk

----------
#### @uses
    @uses <class>;

If you know that a variant class will always be resolved to be a subclass of some 
particular class, you can declare this with the @uses keyword. This will let the 
variant class define handlers for the "used" superclass. The keyword uses the 
following argument:

*class* - A class which will always be a superclass of the defined variant 
class.

**Warnings:** You must make sure that the variant class's inheritance is always resolved 
such that the used class is one of its ancestor classes.

**See Also:** @class

----------
#### @vardata
    @vardata    <type> <vname>;

The @vardata keyword creates a vardata data type for a class. Each type 
created with @vardata can be simply the name of the type, or it can have 
additional data (a single structure). The arguments of @vardata are given below:

*type* - This is the data type or structure type of the data field. If no extra 
data is to be associated with this field, then put the word void in 
place of a type.

*vname* - This is the name of the variable data instance field.

    @vardata        dword       MY_FIRST_VAR_DATA;

    typedef struc {
        int     a;
        int     b;
    } MyStruc;

    @vardata        MyStruc     MY_SECOND_VAR_DATA;
    @vardata        void        MY_THIRD_VAR_DATA;

**See Also:** @vardataAlias, @instance

----------
#### @vardataAlias
    @vardataAlias (<origName>) <newType> <newName>;

The @vardataAlias keyword allows you to set up variable data fields with 
varying amounts of extra data. That is, a single variable data field in the 
instance chunk could have two different sizes and two different names. The 
arguments of @vardataAlias are listed below:

*origName* - The name of the original variable data field defined with 
@vardata.

*newType* - The new type or structure associated with this variable data 
field. If no extra data is to be associated with this alias, then put 
the word void instead of a type.

*newName* - The new name of the variable data field that uses the new type.

    /* defined in GenTriggerClass */
    @vardata word ATTR_GEN_TRIGGER_ACTION_DATA;

    /* A special GenTrigger that uses a different data
     * type is defined in the application: */
    @object GenTriggerClass MyTrigger = {
        GTI_actionMsg = MSG_MY_APPS_MESSAGE;
        GTI_destination = process;
        @vardataAlias (ATTR_GEN_TRIGGER_ACTION_DATA)
                    dword ATTR_MY_TRIGGER_SPECIAL_DATA;

**See Also:** @vardata, @instance

----------
#### @visChildren
    @send @visChildren::<msg>(<params>);

Any composite object in a visible object tree (therefore a subclass of 
**VisCompClass**) can send a message that will be dispatched at once to all of its 
children. Note that any message sent with @visChildren as the destination 
must be dispatched with the @**send** keyword and therefore can have no return 
value.

----------
#### @visParent
    @send @visParent::<msg>(<params>);

Any object in a visible tree can use @**visParent** as the destination of an @call 
command. The message will be sent to the object's parent in the visible object 
tree. The remainder of the command is the same as a normal @**call**.

----------
#### @visMoniker
    @instance @visMoniker <iname>;

The @visMoniker keyword follows @instance to create an instance data field 
for a visual moniker. The iname argument is the name of the instance data 
field.

    @instance @visMoniker GI_visMoniker;

**See Also:** @instance, **GenClass**

[Table of Contents](../routines.md) &nbsp;&nbsp; --> [Parameters File Keywords](rgp.md)