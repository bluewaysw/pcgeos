COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Esp Test Suite
FILE:		object.asm

AUTHOR:		Adam de Boor, Sep  3, 1989

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 3/89		Initial revision


DESCRIPTION:
	This file is designed to exercise the Object-oriented extensions
	in Esp. It should produce the following messages when assembled:
		
warning: file "object.asm", line 115: private instance variable MI_private used outside class MetaClass
warning: file "object.asm", line 117: private method METHOD_MaC_PRIVATE used outside class MasterClass

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;
;		       DECLARE CLASS STRUCTURE
;
; The name "ClassStruc" is expected by Esp for use when referencing a class
; record as a variable.
;------------------------------------------------------------------------------

ClassFlags	record	CLASSF_MASTER_CLASS:1, 	    ;start of master group\
			CLASSF_VARIANT_CLASS:1,	    ;superclass varies\
			CLASSF_DISCARD_ON_SAVE:1,   ;nuke data if saved\
			CLASSF_CALL_TO_RELOCATE:1,  ;contact class for rel\
			CLASSF_CALL_TO_UNRELOCATE:1,;ditto for unrel\
			:3			    ;unused

ClassStruc		struc
    Class_superClass	fptr.ClassStruc	?	;Class's superclass
    Class_masterOffset	dsw		?	;Offset to master class data
    Class_methodCount	dsw		?	;Number of methods defined
    Class_instanceSize	dsw		?	;Size to allocate instance
    Class_initRoutine	fptr.far	0	;Class initialization routine
    Class_relocTable	nptr		?	;Ptr to relocation info
    Class_flags		ClassFlags	<>	;Flags for the class
    Class_stateSize	dsb		?	;Size of state space for class
    Class_methodTable	label		word	;Start of method table
ClassStruc		ends

;------------------------------------------------------------------------------
;
;			  DECLARE METACLASS
;
; Note that MetaBase must be defined before MetaClass can be declared, since
; MetaClass has no superclass from which its base structure can be deduced.
;------------------------------------------------------------------------------
MetaBase	struc
    MB_class	fptr.ClassStruc
MetaBase	ends

; Declare "MetaClass" to be a top-level class (superClass == 0)
MetaClass	class	0
    ;
    ; Base must come first -- Esp won't add it.
    ;
    MI_base	MetaBase	<>
    ;
    ; A public instance variable
    ;
    MI_biff	word

    ;
    ; A public method that can be called staticly
    ;
METHOD_BIFF	method	static

		private
    ;
    ; A private instance variable, accessible w/o warning only from within
    ; a method belonging to MetaClass or one of its descendants
    ;
    MI_private	db	?
MetaClass	endc

;------------------------------------------------------------------------------
;
;			  DECLARE MASTERCLASS
;
; This is a master class immediately below Meta for the purpose of testing
; relocation tables, state structures, and private methods.
;------------------------------------------------------------------------------
MasterClass	class	MetaClass, master
		state
    MaI_public	hptr	3 dup(?)
		endstate
METHOD_MaC_PUBLIC method

		private
METHOD_MaC_PRIVATE method

		public
    MaI_wheee	sptr
    		optr		; Nameless instance variable :)
MasterClass	endc

biff 		segment para public 'CODE'

main		proc far
		mov	si, ds:[si]
		mov	al, ds:[si].MI_private	;generate warning about private
						; instance variable
		mov	ax, METHOD_MaC_PRIVATE	;generate warning about private
						; method
		ret
main		endp

;
; MetaClass definitions
;
		MetaClass		; Define MetaClass

MC_Biff		method MetaClass, METHOD_BIFF
		mov	si, ds:[si]
		mov	al, ds:[si].MI_private
		ret
MC_Biff		endm

;
; MasterClass definitions -- test multiple-method/handler
;
	MasterClass
MaC_Biff	method MasterClass, METHOD_BIFF
		mov	si, ds:[si]
		mov	al, ds:[si].MI_private
		ret
MaC_Biff	endm

MaC_Misc 	method MasterClass, METHOD_MaC_PUBLIC, METHOD_MaC_PRIVATE
		mov	si, ds:[si]
		mov	ax, ds:[si].MaI_public[0]
		mov	bx, ds:[si].MaI_public[2]
		mov	cx, ds:[si].MaI_public[4]
		ret
MaC_Misc	endm


MasterSubClass	class	MasterClass
    MSI_field	word
    MSI_next	optr
METHOD_MS_OPEN	method	private static
MasterSubClass	endc

MasterSubClass mask CLASSF_CALL_TO_RELOCATE or mask CLASSF_CALL_TO_UNRELOCATE
	       
		method	MaC_Biff, MasterSubClass, METHOD_BIFF
;
; VariantClass definitions -- test class flags, hellish relocations, and
; class initialization routine.
;
;
; Relocation hell
;
RelocHell	struc
    RH_a	hptr	2 dup(?)
    RH_b	sptr	2 dup(?)
    RH_c	optr	2 dup(?)
    RH_d	fptr	2 dup(?)
RelocHell	ends

VariantClass	class	MasterClass, master, variant
    VC_hell	RelocHell	3 dup(<>)
VariantClass	endc

		VariantClass	mask CLASSF_DISCARD_ON_SAVE, VC_Init

VC_Init	proc	far
		ret
VC_Init		endp

biff 	ends
