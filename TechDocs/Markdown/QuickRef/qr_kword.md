# 1 GOC Keywords

	@alias(<protoMsg>) <messageDef>;
	<ret> = @call [,<flags>+] [{<cast>}]
		<obj>::[{cast2}] <msg>(<params>*);

	@callsuper();

	@callsuper <obj>::<class>::<msg>(<params>*) [<flags>,];

	@chunk <type> <name> [ = <init> ];

	@chunkArray <stype> <aname> [ = {<init>} ];

	@class	<cname>, <super> [, master [, variant]];

	@classdecl <cname> [, <cflags>];

	@default

	@define <macro> <definition>

	@deflib <libname>

	@dispatch [noFree] <nObj>::<nMsg>::<event>;
	<ret> = @dispatchCall [noFree] [(<cast>)]
							<nobj>::<nMsg>::<event>;

	@elementArray <stype> <arrayname> [={<init}];

	@end <segname>

	@endc

	@endif

	@endlib

	@exportMessages <expName>, <num>;

	@extern method <class> <message>+;

	@extern [chunk|object|visMoniker] <name>;

	gcnList(<manufID>, <ltype>) = [<oname>, ]* <oname>

	(@genChildren, @genParent) shortcuts for @call and @send

	@gstring <sname> = { <gstringDef> };

	@header <type> [ = <init> ];

	@if <condition>

	@ifdef <flag>

	@ifndef <flag>

	@importMessage <expName>, <messageDef>;

	@include [<<headerfile>>| "<headerfile>"]

	@instance <insType> <iname> [ = <default>];

	@instance @activeList <iname> [ = <default>];

	@instance @composite <iname> [ = <linkName>];

	@instance @kbdAccelerator <iname> 
							[ = [@specificUI] <default>];

	@instance @link <iname> [ = <default>];

	@instance @visMoniker <iname> [ = <default>];

	@message <retType> <mname>([@stack] <param>*);

	@method [ <hname>, ] <cname>, <mname>+;

	@object <class> <name> <flags>* = {
			<fieldName> = <init>;*
			<varName> [ = <init> ];
			}

	@optimize

	@prototype <messageDef>;

	<event> = @record <obj>::<msg>(<params>*);

	@reloc <iname>, [ (<count>, <struct>), ] <ptrType>;

	@reloc <vname>, <fn>, [(<count>, <struct>),] <ptrType>;

	@reserveMessages <num>;

	@send [,<flags>+] <obj>::<msg>(<params>*);

	@start <segname> [ , <flags> ];

	@vardata <type> <vname>;

	@vardataAlias (<origName>) <newType> <newName>;

	(@visChildren, @visParent) shortcuts for @call and @send

[Table of Contents](../quickref.md) &nbsp;&nbsp; --> [2 Classes: Arc - GenTrigger](qr_clas1.md)
