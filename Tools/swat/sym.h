/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Sym-module definitions
 * FILE:	  sym.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Function, constant, type definitions for Sym module
 *
 *
* 	$Id: sym.h,v 4.8 96/05/20 18:51:31 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _SYM_H
#define _SYM_H

/*
 * Symbol classes for use during lookup.
 */
#define SYM_VAR	  	0x0001	    /* Variable of some sort */
#define SYM_MODULE	0x0002
#define SYM_FUNCTION	0x0004
#define SYM_TYPE  	0x0008
#define SYM_ENUM	0x0010
#define SYM_ABS		0x0020
#define SYM_LABEL   	0x0040
#define SYM_ONSTACK 	0x0080
#define SYM_FIELD   	0x0100
#define SYM_SCOPE   	0x0200
#define SYM_LOCALVAR	0x0400
#define SYM_PROFILE 	0x0800
#define SYM_NAMELESS	0x8000	    /* Accept "nameless" symbols too */
#define SYM_ANY	  	((word)0xffff)

typedef enum {
    SC_Static,	  	/* Variable always in one place */
    SC_Local,	  	/* Variable local to a stack frame */
    SC_Register,  	/* Variable stored in a register */
    SC_Parameter,  	/* Variable paramter to a function */
    SC_RegParam,  	/* Register parameter */
} StorageClass;	  /* sClass for variable data */

extern GeosAddr *Sym_GetCachedMethod(void);
extern Sym  	Sym_Lookup (const char *name, int class, Sym scope);
extern Sym  	Sym_LookupInScope (const char *name, int class, Sym scope);
extern Sym  	Sym_LookupAddr (Handle handle, Address addr, int class);
/* GENERIC ACCESSORS */
extern int  	Sym_Class (Sym sym);
extern Sym  	Sym_Scope (Sym sym, Boolean lexical);
extern Patient	Sym_Patient (Sym sym);
typedef Boolean (*sym_foreach_callback)(Sym sym, Opaque data) ;
extern void 	Sym_ForEach (Sym scope, int class,
			     sym_foreach_callback func,
			     Opaque data);
extern char 	*Sym_Name (Sym sym);
extern char 	*Sym_FullName (Sym sym);
extern char 	*Sym_FullNameWithPatient (Sym sym);
extern Boolean	Sym_IsNull(Sym sym);
extern Boolean	Sym_Equal(Sym sym1, Sym sym2);
extern char 	*Sym_ToAscii(Sym sym);
extern Sym  	Sym_ToToken(char *token);
extern int  	Sym_Type(Sym sym); /* For Type module */
extern void 	Sym_ToAddr(Sym sym, GeosAddr *addrPtr);

/* CLASS-SPECIFIC ACCESSORS */
extern void 	Sym_GetVarData (Sym sym, Type *typeptr,
				StorageClass *sClassPtr,
				Address *addrPtr );


extern Boolean 	Sym_IsFar (Sym sym);
extern Boolean 	Sym_IsWeird (Sym sym);
extern void 	Sym_GetFuncData (Sym sym, Boolean *isFarPtr, Address *addrPtr,
				 Type *retType);
extern void 	Sym_GetEnumData (Sym sym, int *valuePtr, Type *sourceTypePtr);
extern int  	Sym_GetAbsData (Sym sym);
extern char  	**Sym_GetOnStackData (Sym sym, int *numPtr);
extern void 	Sym_GetFieldData (Sym sym, int *offsetPtr, int *lengthPtr,
				  Type *fieldTypePtr, Type *sourceTypePtr);
extern Type 	Sym_GetTypeData (Sym sym);

extern void 	Sym_Init (Patient patient);
extern void 	Sym_Copy (Patient from, Patient to);
extern char    *Sym_IsKernelInternalRoutine(word offset);
extern word     Sym_KernelInternalNameToOffset(char *name);
extern Boolean  Sym_IsInternalWeird(Handle handle, word offset);
extern Boolean	Sym_IsResourceCallInt(Handle handle, word offset);
#endif /* _SYM_H */
