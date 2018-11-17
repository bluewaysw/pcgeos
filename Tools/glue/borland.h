/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  borland.h
 * FILE:	  borland.h
 *
 * AUTHOR:  	  Adam de Boor: Dec 16, 1991
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/16/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for Borland-format symbol and type information
 *	encoded in a microsoft/intel-format object file.
 *
 *	All types and symbols are stored in COMENT records. Some of them
 *	come at well-defined places in the object file, but everything
 *	else is "flexible", i.e. a pain in the butt to deal with, as you
 *	must save everything and process it only when you've got it all,
 *	or perform partial-processing. Not fun.
 *
 *	Anyway, the type of symbol/type/etc. record is defined by the
 *	"comment class" in the COMENT record. To refresh your memory,
 *	a COMENT record looks like this:
 *	    record type	    0x88
 *	    record length   word
 *	    comment attrs   byte
 *	    comment class   byte
 *	    data    	    bytes, number defined by overall record length
 *	    checksum	    byte
 *
 *	We never see the checksum, of course, as MSObj deals with that
 *	cruft.
 *
 *	Names, when Borland is in C++ mode, get horribly mangled for
 *	whatever reason (having to do with having multiple methods for
 *	a class, the right one of which is chosen depending on the
 *	arguments passed, I believe) so they say @<name>$<argtypes>.
 *
 *	Lord knows how one deals with this cruft in a debugger.
 *
 * 	$Id: borland.h,v 1.6 93/02/22 12:59:42 adam Exp $
 *
 ***********************************************************************/
#ifndef _BORLAND_H_
#define _BORLAND_H_

/*
 * Pre-defined Borland type indices
 */
#define BT_NAMELESS 	    0	    	/* Type used for nameless bitfields */
#define BT_VOID	    	    1
#define BT_CHAR	    	    2   	/* signed character */
#define BT_SHORT    	    4   	/* signed word */
#define BT_LONG	    	    6   	/* signed dword */
#define BT_BYTE	    	    8   	/* unsigned character */
#define BT_WORD	    	    10  	/* unsigned word */
#define BT_DWORD    	    12  	/* unsigned dword */
#define BT_FLOAT    	    14  	/* 4-byte floating-point */
#define BT_DOUBLE   	    15  	/* 8-byte floating-point */
#define BT_LONG_DOUBLE	    16  	/* 10-byte floating-point */
#define BT_PASC_FLOAT	    17  	/* Pascal 6-byte floating-point */
#define BT_PASC_BOOL	    18  	/* Pascal boolean */
#define BT_PASC_CHAR	    19  	/* Pascal character */
#define BT_SIGNED_RANGE	    21  	/* 8-byte signed range (?) */
#define BT_UNSIGNED_RANGE   22	    	/* 8-byte unsigned range (?) */
#define BT_TBYTE    	    23	    	/* 10-byte real */

#define BT_LAST_PREDEF	    23	    	/* Any type index above this is
					 * defined in a COMENT record in
					 * the object file...somewhere */

/*
 * Comment classes and their associated data.
 *
 * An index type is the standard OMF index format (1 byte if < 128, 2 bytes
 * in funky order if >= 128; use MSObj_GetIndex to extract it)
 *
 * A string is stored as counted-ascii, not null-terminated ascii.
 */

/*
 * Defines the type of an external symbol. Externals are placed one per
 * EXTDEF record in the object file. This record specifies the type index
 * for the preceding external:
 *	- type index (index)
 *	- (3.0) source file index where defined
 *	- (3.0) line number where defined, if source file index non-zero
 */
#define BCC_EXTERNAL_TYPE   0xe0

/*
 * Defines the type of a public symbol. Publics are placed one per PUBDEF
 * record in the object file. This record specifies the type index for the
 * preceding public:
 *	- type index (index)
 *	- frame pointer flags (byte); if symbol is a function with a valid BP,
 *	  bit 3 is set and the upper four bits are the number of words between
 *	  the saved BP and the return address (local stack size)
 *	- (3.0) source file index where defined
 *	- (3.0) line number where defined, if source file index non-zero
 */
#define BCC_PUBLIC_TYPE	    0xe1

/*
 * Defines the members of a structure. Usually all the members are placed in
 * a single record, but the members of a structure may be broken across multiple
 * BCC_STRUCT_MEMBERS records if they cannot all fit in an 8K (?) record. In
 * pre-3.0 files, the records for the members of a structure always come
 * immediately before the record for the structure itself. For 3.0 or later,
 * the record comes after the structure type and any record that refers to
 * the structure type...Lord only knows why.
 *
 * With the exception of special "new offset" records, there are no offsets
 * given for structure members, as they can be determined from the types of
 * the fields themselves. When the compiler adds padding, it will always
 * put out a nameless member of the appropriate size (in bits or bytes) to
 * bring the definition up to the offset (bit or byte) of the next field.
 *
 *	- flags:
 *	    0x60    	static member (?)
 *	    0x50    	conversion (?some C++ thing: "operator int()", e.g.)
 *	    0x48    	member function. low 2 bits can be:
 *	    	    	0x01	destructor
 *	    	    	0x02	constructor
 *	    	    	0x03	static member function
 *	    	    	0x04	virtual member function
 *	    anything else:
 *	    	    	bit 7	    set if this is the last member of the
 *	    	    	    	    structure
 *	    	    	bit 6	    set if this record specifies a new
 *	    	    	    	    offset from which to start, for the next
 *	    	    	    	    field.
 *	    	    	bits 0-5    width of the field in bits, if field is
 *	    	    	    	    a bitfield; 0 if it's not a bitfield
 * if the field doesn't specify a new offset:
 *	- member name (string). unnamed (pad) members have a name of length
 *	  0.
 *	- member type (index)
 * if the field specifies a new offset:
 *	- new byte offset for following member (dword), with offsets of
 *	  following members being calculated accordingly.
 */
#define BCC_STRUCT_MEMBERS  0xe2
#define BSM_STATIC_MEMBER   	0x60
#define BSM_CONVERSION	    	0x50
#define BSM_MEMBER_FUNCTION 	0x48
#define BSM_IS_MEMBER_FUNCTION(flags)	(((flags) & 0xfc)==BSM_MEMBER_FUNCTION)
#define BSMMF_DESTRUCTOR    	    0x01
#define BSMMF_CONSTRUCTOR   	    0x02
#define BSMMF_STATIC_MEMBER 	    0x03
#define BSMMF_VIRTUAL_MEMBER	    0x04

#define BSM_MEMBER_WIDTH        0x3f
#define BSM_NEW_OFFSET	    	0x40
#define BSM_LAST_MEMBER	    	0x80

/*
 * Type definition (oh joy). A single type is defined in each type-definition
 * record. The format of the type record depends on the TID byte (see below).
 * There is no requirement on any particular ordering of these type records.
 * It is possible to have a type record early in the file that uses a type
 * defined later in the file (meaning we've got to get all the types in
 * before we can convert them to our normal form, unless we delay a few of
 * them...)
 *
 * Anyway, the format:
 *	- index of the type being defined (index). Always greater than
 *	  BT_LAST_PREDEF
 *	- name of the type (string). Supposedly these are used only for
 *	  struct/union/enum tags.
 *	- size of the type, in bytes (word)
 *	- the TID giving us a clue as to what the type is (byte)
 *	- remaining part varies and is defined with each TID given below.
 */
#define BCC_TYPEDEF 	0xe3

#define BTID_VOID   	    0x00    /* Void:
				     *	- nothing
				     */
#define BTID_LSTR   	    0x01    /* BASIC Literal string:
				     *	- nothing
				     */
#define BTID_DSTR   	    0x02    /* BASIC Dynamic string:
				     *	- nothing
				     */
#define BTID_PSTR   	    0x03    /* Pascal string:
				     *	- maximum length (byte)
				     */
#define BTID_SCHAR   	    0x04    /* 1-byte signed int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_SINT   	    0x05    /* 2-byte signed int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_SLONG   	    0x06    /* 4-byte signed int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_SQUAD   	    0x07    /* 8-byte signed int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_UCHAR   	    0x08    /* 1-byte unsigned int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_UINT   	    0x09    /* 2-byte unsigned int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_ULONG   	    0x0a    /* 4-byte unsigned int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_UQUAD   	    0x0b    /* 8-byte unsigned int range:
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_PCHAR   	    0x0c    /* 1-byte unsigned int range (Pascal
				     * character, so no arithmetic allowed):
				     *	- parent type index (index)
				     *	- lower bound (dword)
				     *	- upper bound (dword)
				     */
#define BTID_FLOAT   	    0x0d    /* IEEE 32-bit real:
				     *	- nothing
				     */
#define BTID_TPREAL   	    0x0e    /* Turbo Pascal real (6-byte):
				     *	- nothing
				     */
#define BTID_DOUBLE   	    0x0f    /* IEEE 64-bit real:
				     *	- nothing
				     */
#define BTID_LDOUBLE   	    0x10    /* IEEE 80-bit real:
				     *	- nothing
				     */
#define BTID_BCD4   	    0x11    /* 4-byte BCD:
				     *	- nothing
				     */
#define BTID_BCD8   	    0x12    /* 8-byte BCD:
				     *	- nothing
				     */
#define BTID_BCD10   	    0x13    /* 10-byte BCD:
				     *	- nothing
				     */
#define BTID_BCDCOB   	    0x14    /* COBOL BCD:
				     *	- position of the decimal point (byte)
				     */
#define BTID_NEAR   	    0x15    /* near pointer:
				     *	- index of type pointed to (index)
				     *	- segment base (byte):
				     *	    0x00    unspecified
				     *	    0x01    ES
				     *	    0x02    CS
				     *	    0x03    SS
				     *	    0x04    DS
				     *	    0x05    FS
				     *	    0x06    GS
				     */
#define BTID_FAR   	    0x16    /* far pointer:
				     *	- index of type pointed to (index)
				     *	- pointer arithmetic (byte):
				     *	    0x00    segment adjustment not nec'y
				     *	    0x01    segment adjustments needed
				     *		    to avoid offset wrap.
				     */
#define BTID_SEG   	    0x17    /* segment pointer:
				     *	- index of type pointed to (index)
				     *	- extra byte
				     */
#define BTID_NEAR386   	    0x18    /* 32-bit near pointer:
				     *	- index of type pointed to (index)
				     *	- segment base (byte):
				     *	    0x00    unspecified
				     *	    0x01    ES
				     *	    0x02    CS
				     *	    0x03    SS
				     *	    0x04    DS
				     *	    0x05    FS
				     *	    0x06    GS
				     */
#define BTID_FAR386   	    0x19    /* 48-bit far pointer:
				     *	- index of type pointed to (index)
				     *	- pointer arithmetic (byte):
				     *	    0x00    segment adjustment not nec'y
				     *	    0x01    segment adjustments needed
				     *		    to avoid offset wrap.
				     */
#define BTID_CARRAY   	    0x1a    /* C array (0-based):
				     *	- element type (index)
				     * dimension is determined by dividing type
				     * size by element size.
				     */
#define BTID_VLARRAY   	    0x1b    /* Very Large array (0-based):
				     *	- high 16 bits of array size (word);
				     *	  merged with usual word of type size to
				     *	  form dword of type size.
				     *	- element type (index)
				     * dimension again determined by dividing
				     * dword type size by element size
				     */
#define BTID_PARRAY   	    0x1c    /* Pascal array:
				     *	- element type (index)
				     *	- index type (index)
				     * dimension determined by elements of the
				     * index type.
				     */
#define BTID_ADESC   	    0x1d    /* BASIC array descriptor:
				     *	- nothing
				     */
#define BTID_STRUCT   	    0x1e    /* Structure:
				     *	- (3.0) index of member record
				     *	  describing first member. This is a
				     *	  1-origin value counting all members
				     *	  (and new offset elements) in all
				     *	  BCC_STRUCT_MEMBERS and
				     *	  BCC_ENUM_MEMBERS records in the
				     *	  file.
				     */
#define BTID_UNION   	    0x1f    /* Union:
				     *	- (3.0) index of member record
				     *	  describing first member. This is a
				     *	  1-origin value counting all members
				     *	  (and new offset elements) in all
				     *	  BCC_STRUCT_MEMBERS and
				     *	  BCC_ENUM_MEMBERS records in the
				     *	  file.
				     */
#define BTID_VLSTRUCT  	    0x20    /* Very Large Structure:
				     *	- high 16 bits of type size (word)
				     *	- (3.0) index of member record
				     *	  describing first member. This is a
				     *	  1-origin value counting all members
				     *	  (and new offset elements) in all
				     *	  BCC_STRUCT_MEMBERS and
				     *	  BCC_ENUM_MEMBERS records in the
				     *	  file.
				     */
#define BTID_VLUNION   	    0x21    /* Very Large Union:
				     *	- high 16 bits of type size (word)
				     *	- (3.0) index of member record
				     *	  describing first member. This is a
				     *	  1-origin value counting all members
				     *	  (and new offset elements) in all
				     *	  BCC_STRUCT_MEMBERS and
				     *	  BCC_ENUM_MEMBERS records in the
				     *	  file.
				     */
#define BTID_ENUM   	    0x22    /* Enumerated type:
				     *	- parent type (index) 0 => int
				     *	- lower bound (signed word)
				     *	- upper bound (signed word)
				     *	- (3.0) index of the first member of the
				     *	  enumerated type. This is a 1-origin
				     *	  value counting all members (and
				     *	  new offset elements) in all
				     *	  BCC_STRUCT_MEMBERS and
				     *	  BCC_ENUM_MEMBERS records in the
				     *	  file.
				     */
#define BTID_FUNCTION  	    0x23    /* Function/procedure:
				     *	- return type (index)
				     *	- language modifier (byte):
				     *	    0x00    near C function
				     *	    0x01    near Pascal function
				     *	    0x02    unused
				     *	    0x03    unused
				     *	    0x04    far C function
				     *	    0x05    far Pascal function
				     *	    0x06    unused
				     *	    0x07    interrupt
				     *	- varargs (byte). 1 if function accepts
				     *	  variable # of args, 0 otherwise.
				     */
#define BTID_LABEL   	    0x24    /* Label:
				     *	- distance (byte). 0 if near, 1 if far.
				     */
#define BTID_SET   	    0x25    /* Pascal Set:
				     *	- parent type (index)
				     */
#define BTID_TFILE   	    0x26    /* Pascal text file:
				     *	- nothing
				     */
#define BTID_BFILE   	    0x27    /* Pascal binary file:
				     *	- record type (index)
				     */
#define BTID_BOOL   	    0x28    /* Pascal boolean:
				     *	- nothing
				     */
#define BTID_PENUM   	    0x29    /* Pascal enumerated type (no arithmetic):
				     *	- parent type (index)
				     *	- lower bound (signed word)
				     *	- upper bound (signed word)
				     */
#define BTID_PWORD   	    0x2a    /* pword (some MASM thing I've forgotten):
				     *	- nothing
				     */
#define BTID_TBYTE   	    0x2b    /* 10-byte integer, usually an encoded real:
				     *	- nothing
				     */
#define BTID_SPECIALFUNC    0x2d    /* Member/duplicate function:
				     *	- return type (index)
				     *	- language modifier (byte):
				     *	    0x00    near C function
				     *	    0x01    near Pascal function
				     *	    0x02    unused
				     *	    0x03    unused
				     *	    0x04    far C function
				     *	    0x05    far Pascal function
				     *	    0x06    unused
				     *	    0x07    interrupt
				     *	- other flags (byte):
				     *	    bit 0   set if member function
				     *	    bit 1   set if duplicate function
				     *	    bit 2   set if operator function
				     *	    bit 3   set if local function
				     *	- class, if member function (index)
				     *	- offset in virtual table (word), if
				     *	  member function
				     *	- mangled name (string), if non-local
				     *	  member function
				     * "this" should appear as a local symbol
				     * in the second inner scope of a member
				     * function (not in the outermost,
				     * parameter, scope)
				     */
#define BTID_CLASS   	    0x2e    /* C++ class:
				     *	- class index (index), as separate from
				     *	  the type index, I think.
				     */
#define BTID_MEMBERPTR 	    0x33    /* Type pointed to by a class member ptr:
				     *	- type pointed to (index)
				     *	- class to which member belongs (index),
				     *	  supposedly the class index, not type
				     *	  index...
				     */
#define BTID_NREF   	    0x34    /* Near reference (parameter passed by
				     * reference, I think, not value):
				     *	- type pointed to (index)
				     *	- extra byte (byte), always 0
				     */
#define BTID_FREF   	    0x35    /* Far reference (parameter passed by
				     * reference, I think, not value):
				     *	- type pointed to (index)
				     *	- extra byte (byte), always 0
				     */

/*
 * Defines the members of an enumerated type. Usually all the members are
 * placed in a single record, but they may be broken across multiple
 * BCC_ENUM_MEMBERS records if they cannot all fit in an 8K record. All the
 * records for the members of an enumerated type come immediately
 * before the BCC_TYPEDEF record for the type itself.
 *
 * Each element of the record has the form:
 *	- flag (byte), 0x80 if this is the last member, 0 otherwise.
 *	- member name (string)
 *	- member value (word)
 */
#define BCC_ENUM_MEMBERS    0xe4
#define BEM_LAST_MEMBER	    	0x80

/*
 * Open a new variable scope. For each BCC_BEGIN_SCOPE, there is a corresponding
 * BCC_END_SCOPE. The nesting of scopes is indicated by the nesting of
 * BCC_BEGIN_SCOPE and BCC_END_SCOPE records. Symbols are entered into a scope
 * by placing BCC_LOCALS records between the BCC_BEGIN_SCOPE and BCC_END_SCOPE
 * records.
 *	- code segment in which the scope is valid (index)
 *	- offset in segment at which symbols in the scope are born (word)
 *
 * The first scope of a function contains its parameters, and its second
 * contains the variables local to the procedure and valid throughout its
 * execution.
 */
#define BCC_BEGIN_SCOPE	    0xe5

/*
 * Enter symbols into a variable scope. More than one symbol can be defined in
 * each record, and all are attached to the most-recent unclosed scope.
 *
 * If no recent scope, the variables are static ones declared in the global
 * scope.
 *
 * Each element of the record has the form:
 *	- symbol name (string)
 *	- symbol type (index)
 *	- symbol class (byte)
 *	- other class-dependent data
 *	- (3.0) index of source file where thing defined
 *	- (3.0) line number of definition, if source index non-zero
 */
#define BCC_LOCALS  	    0xe6
#define BSC_STATIC  	    	0x00	/* A static variable:
					 *  - containing group (index), if any
					 *  - containing segment (index)
					 *  - offset (word)
					 */
#define BSC_ABSOLUTE	    	0x01	/* A variable in an absolute segment:
					 *  - containing segment (index); the
					 *    segment must be an absolute one
					 *  - offset (word)
					 */
#define BSC_AUTO    	    	0x02	/* Local (auto) variable:
					 *  - signed offset from BP (word)
					 */
#define BSC_PASVAR  	    	0x03	/* Pascal VAR parameter:
					 *  - signed offset from BP (word);
					 *    this location on the stack points
					 *    to the actual value.
					 */
#define BSC_REGVAR  	    	0x04	/* Register variable:
					 *  - register id (byte)
					 * registers are in standard Intel
					 * order (ax,cx,dx,bx,sp,bp,si,di)
					 */
#define BR_BYTE_REG_START   8	    /* al, cl, dl, bl, ah, ch, dh, bh */
#define BR_WORD_REG_START   0	    /* ax, cx, dx, bx, sp, bp, si, di */
#define BR_DWORD_REG_START  0x18    /* eax, ecx, edx, ebx, esp, ebp, esi, edi */
#define BR_SEG_REG_START    0x10    /* es, cs, ss, ds, fs, gs */
#define BR_LAST_REG 	    0x1f

#define BSC_CONSTANT	    	0x05	/* A constant:
					 *  - value (dword)
					 */

#define BSC_TYPEDEF 	    	0x06	/* A typedef:
					 *  - nothing extra
					 */
#define BSC_TAG 	    	0x07	/* A struct/union/enum tag:
					 *  - nothing extra
					 */
#define BSC_PARAM  	    	0x0a	/* Parameter:
					 *  - signed offset from BP (word);
					 *    for Pascal "VAR" parameters, this
					 *    location on the stack points to
					 *    the actual value.
					 */

#define BSC_REGPARAM  	    	0x0c	/* Register Parameter:
					 *  - register id (byte)
					 */

#define BSC_FUNCTION	    	0x18	/* Static function:
					 *  - group (index)
					 *  - segment (index)
					 *  - offset (word)
					 */
#define BSC_GLOBAL_FUNCTION    	0x28	/* Global function:
					 *  - group (index)
					 *  - segment (index)
					 *  - offset (word)
					 * WHY IS THIS HERE? It's put out by
					 * Turbo Assembler, which has already
					 * put out a PUBDEF and a
					 * BCC_PUBLIC_TYPE record for the damn
					 * thing. There doesn't seem to be any
					 * more information...
					 */
#define BSC_OPTIMIZED	    	0x08	/* Variable's been optimized:
					 *  - # entries in range list (index)
					 *  - entries of this form:
					 *  	- start of range (word); offset
					 *	  from outermost enclosing
					 *	  scope (i.e. proc start)
					 *  	- end of range (word)
					 *  	- regular local symbol
					 *	  record
					 */

/*
 * End of a variable scope.
 *	- offset after which the variables in the scope are invalid (word)
 */
#define BCC_END_SCOPE	    0xe7

/*
 * Indicate what source file the following line numbers are for.
 *	- source-file index for the file (index)
 *	- if index is 0:
 *	    - path of the source file (string)
 *	    - modification time for the file (dword) in DOS-normal form
 */
#define BCC_SOURCE_FILE	    0xe8

/*
 * Source-dependency definition. Indicates the path of a single file used
 * to create the object file. At least one of these must precede the first
 * non-comment record, other than THEADR, in the object file.
 *	- modification time for the file (dword)
 *	- path of the source file (string). If found via -I, the appropriate
 *	  path is prepended to that in the #include directive.
 */
#define BCC_DEPENDENCY	    0xe9

/*
 * Compiler options used to create the file:
 *	- source language (byte)
 *	- flags (byte)
 */
#define BCC_COMPILER_DESC   0xea

#define BCDL_UNSPEC 	    	0x00	/* Language unspecified */
#define BCDL_C	    	    	0x01
#define BCDL_PASCAL 	    	0x02
#define BCDL_BASIC  	    	0x03
#define BCDL_ASSEMBLY	    	0x04
#define BCDL_C_PLUS_PLUS    	0x05

#define BCDF_UNDERSCORES    	0x08	/* Set if underscores were prepended
					 * to C language source symbols */
#define BCDF_MODEL  	    	0x07	/* Memory model used: */
#define BMM_TINY    	    	    0x00
#define BMM_SMALL   	    	    0x02
#define BMM_MEDIUM  	    	    0x04
#define BMM_COMPACT 	    	    0x06
#define BMM_LARGE   	    	    0x08
#define BMM_HUGE    	    	    0x0a
#define BMM_32B_SMALL	    	    0x0c
#define BMM_32B_MEDIUM	    	    0x0e
#define BMM_32B_COMPACT	    	    0x10
#define BMM_32B_LARGE	    	    0x12

/*
 * Alternate method of defining the type for external symbols. These come
 * wherever they feel like, though I think they're still after the symbol
 * they reference. They can contain definition for more than one symbol, though
 * I've not seen one that way yet.
 *
 * Each record contains:
 *	- name of the external symbol being defined (string)
 *	- type of the symbol (index)
 *	- (3.0) index of source file where thing defined
 *	- (3.0) line number of definition, if source index non-zero
 */
#define BCC_EXTERNAL_BY_NAME	0xeb

/*
 * Alternate method of defining the type for public symbols. These come
 * wherever they feel like, though I think they're still after the symbol
 * they reference. They can contain definition for more than one symbol, though
 * I've not seen one that way yet.
 *
 * Each record contains:
 *	- name of the public symbol being defined (string)
 *	- type of the symbol (index)
 *	- frame pointer flags (byte); if symbol is a function with a valid BP,
 *	  bit 3 is set and the upper four bits are the number of words between
 *	  the saved BP and the return address (local stack size)
 *	- (3.0) index of source file where thing defined
 *	- (3.0) line number of definition, if source index non-zero
 */
#define BCC_PUBLIC_BY_NAME	0xec

/*
 * Class/overload definition
 */
#define BCC_CLASS_DEF	    	0xed

/*
 * Profiling coverage information, defining the start and end of basic
 * blocks within the code.
 *
 * Each record contains:
 *	- index of segment for which the following offsets are defined
 *	- array of words, with each word being the start of a basic block
 *	  (and, correspondingly, the exclusive end of the previous basic block).
 *	  the number of words is implied by the length of the object record.
 */
#define BCC_BASIC_BLOCKS    	0xee

/*
 * Debug information version number.
 *
 * Record contains:
 *	- major version # (byte)
 *	- minor version # (byte)
 */
#define BCC_VERSION 	    	0xf9

/*
 * REMAINING RECORDS ARE FOR 32-BIT OBJECT FILES OR C++, WHICH WE DON'T SUPPORT
 * YET....
 */


#endif /* _BORLAND_H_ */
