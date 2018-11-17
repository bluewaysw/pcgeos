/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Definitions for Obj module
 * FILE:	  object.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 25, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/25/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for users of the Obj functions.
 *
 *
 * 	$Id: object.h,v 1.16 92/08/11 15:45:25 adam Exp $
 *
 ***********************************************************************/
#ifndef _OBJECT_H_
#define _OBJECT_H_

extern void    	    Obj_DefineClass(SymbolPtr	class,
				    Expr    	*flags,
				    Expr    	*initRoutine);
extern SymbolPtr    Obj_DeclareClass(ID	    	className,
				     SymbolPtr	superClass,
				     int    	flags);
extern void 	    Obj_EnterHandler(SymbolPtr	class,
				     SymbolPtr	handler,
				     SymbolPtr	method,
				     Expr   	*expr,
				     int    	callType);
extern TypePtr	    Obj_ClassType(SymbolPtr sym);
extern void 	    Obj_EnterDefault(SymbolPtr	class,
				     SymbolPtr	handler,
				     Expr   	*expr,
				     int    	callType);
extern void 	    Obj_EnterReloc(SymbolPtr	class,
				   SymbolPtr	handler,
				   Expr	    	*expr);
extern void 	    Obj_NoReloc(SymbolPtr   class,
				SymbolPtr   varData,
				Expr	    *expr);
extern void 	    Obj_ExportMessages(SymbolPtr    class,
				       ID   	    rangeName,
				       Expr 	    *length);
extern void 	    Obj_CheckVarDataBounds(SymbolPtr	class);
extern void 	    Obj_CheckMessageBounds(SymbolPtr	class);

#define OBJ_DYNAMIC 	    	0   /* Method may only be called dynamically
				     * via a message */
#define OBJ_DYNAMIC_CALLABLE	1   /* Method may be called dynamically or
				     * by a direct call or jump, but not
				     * staticly */
#define OBJ_STATIC  	    	2   /* Method may always be called staticly */
#define OBJ_PRIVSTATIC	    	3   /* Method may only be called staticly from
				     * within the defining geode */
#define OBJ_STATIC_MASK	    	3   /* Bits that indicate static/dynamic */

#define OBJ_EXTERN  	    	4   /* Set if method is external, meaning the
				     * class record is elsewhere and an
				     * external-method declaration takes place
				     * there; this is the procedure itself. */
/*
 * Strings to place after the class name (minus any trailing "Class") for
 * the various pieces of the object's type definitions:
 *	OBJ_INSTANCE_SUFFIX 	Structure containing the class's instance
 *	    	    	    	data.
 *	OBJ_META_INST_SUFFIX	First field in same, which contains all
 *	    	    	    	the instance data for the superclass,
 *	    	    	    	if class not a master.
 *	OBJ_BASE_SUFFIX	    	Structure containing the offsets to the
 *	    	    	    	various parts of the instance data (as
 *	    	    	    	determined by the master classes).
 *	OBJ_META_BASE_SUFFIX	First field in same, which contains the
 *	    	    	    	Base structure for the superclass.
 *	OBJ_BASE_OFF_SUFFIX 	Next field in Base. Contains offset to
 *	    	    	    	class's instance data. Used only if a class
 *	    	    	    	is a master class.
 *	OBJ_METHODS_SUFFIX  	Enumerated type to contain method constants
 *	OBJ_STATE_SUFFIX    	Structure containing the class's state
 *	    	    	    	block.
 *	OBJ_META_STATE_SUFFIX	First field in same, containing the
 *	    	    	    	superclass's state block.
 *	OBJ_STATE_VAR_PREFIX	String to prepend to an instance variable name
 *	    	    	    	to obtain a state variable name.
 *	OBJ_VARDATA_SUFFIX  	Enumerated type containing the vardata
 *	    	    	    	tags for a class.
 *
 *	OBJ_LONGEST_SUFFX   	Longest of all these, for sizing temporary
 *	    	    	    	buffer when creating things.
 */
#define OBJ_INSTANCE_SUFFIX 	"Instance"
#define OBJ_META_INST_SUFFIX	"_metaInstance"

#define OBJ_BASE_SUFFIX	    	"Base"
#define OBJ_META_BASE_SUFFIX	"_metaBase"
#define OBJ_BASE_OFF_SUFFIX 	"_offset"

#define OBJ_METHODS_SUFFIX_R1  	"Methods"
#define OBJ_METHODS_SUFFIX  	"Messages"

#ifdef OBJ_HAS_STATE
#define OBJ_STATE_SUFFIX    	"State"
#define OBJ_META_STATE_SUFFIX	"_metaState"
#define OBJ_STATE_VAR_PREFIX	"S"
extern void 	    Obj_DeclareStateVar(ID  	    name,
					SymbolPtr   class,
					TypePtr	    type,
					Expr	    *value);
#endif

#define OBJ_VARDATA_SUFFIX  	"VarData"

#define OBJ_LONGEST_SUFFIX  	"_metaInstance"

/*
 * Name of type defining the class record
 */
#define OBJ_CLASS_TYPE_R1    "ClassStruc"
#define OBJ_CLASS_TYPE	    "ClassStruct"

#endif /* _OBJECT_H_ */
