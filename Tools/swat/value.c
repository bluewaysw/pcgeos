/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- value formatting/fetching/storing
 * FILE:	  value.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 29, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Value_HistoryStore  Store an address tuple in the value history
 *	Value_HistoryFetch  Fetch an address tuple from the value history
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/29/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for the formatting, printing, fetching and storing of
 *	values (mostly from the tcl level). Also the maintenance of the
 *	value-history.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: value.c,v 4.20 97/04/18 17:01:29 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cache.h"
#include "cmd.h"
#include "event.h"
#include "expr.h"
#include "private.h"
#include "sym.h"
#include "type.h"
#include "ui.h"
#include "value.h"
#include "var.h"
#include "file.h"
#include "cmdNZ.h"
#include <compat/stdlib.h>
#include <compat/string.h>
#include <buf.h>
#include <ctype.h>

static Cache	    history;
static int	    nextHistNum;
extern char wrongNumArgsString[];

typedef struct {
    int	    	number;   	    /* History number */
    Handle	handle;		    /* Handle of address */
    Address	offset;		    /* Offset of address */
    Type	type;	    	    /* Type of element */
} ValueHistRec, *ValueHistPtr;


/***********************************************************************
 *				ValueHistoryInterest
 ***********************************************************************
 * SYNOPSIS:	    Interest procedure for handles stored in the
 *	    	    history
 * CALLED BY:	    Handle module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If status is HANDLE_FREE, the entry is nuked from
 *	    	    the history.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 3/89		Initial Revision
 *
 ***********************************************************************/
static void
ValueHistoryInterest(Handle 	    handle,
		     Handle_Status  status,
		     Opaque 	    data)
{
    Cache_Entry	    entry = (Cache_Entry)data;

    if (status == HANDLE_FREE) {
	/*
	 * Remove the history entry from the history. ValueHistoryDestroy
	 * will unregister interest.
	 */
	Cache_InvalidateOne(history, entry);
    }
}
/*-
 *-----------------------------------------------------------------------
 * ValueHistoryDestroy --
 *	Callback function for history cache to free up memory associated
 *	with a history entry.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The data associated with the history entry are freed.
 *
 *-----------------------------------------------------------------------
 */
static void
ValueHistoryDestroy(Cache    	cache,
		    Cache_Entry	entry)
{
    ValueHistPtr  	histPtr;

    histPtr = (ValueHistPtr)Cache_GetValue(entry);

    assert(VALIDTPTR(histPtr, TAG_VALUE));

    if (histPtr->handle != NullHandle) {
	Handle_NoInterest(histPtr->handle,
			  ValueHistoryInterest,
			  (Opaque)entry);
    }

    free((char *)histPtr);
}

/*-
 *-----------------------------------------------------------------------
 * Value_HistoryStore --
 *	Store a new element in the history list.
 *
 * Results:
 *	The number under which the value was stored.
 *
 * Side Effects:
 *	A previous history element may be booted.
 *
 *-----------------------------------------------------------------------
 */
int
Value_HistoryStore(Handle   handle,
		   Address  offset,
		   Type	    type)
{
    ValueHistPtr  	histPtr;
    Cache_Entry	  	entry;

    histPtr = (ValueHistPtr)malloc_tagged(sizeof(ValueHistRec), TAG_VALUE);
    histPtr->number = nextHistNum;
    histPtr->handle = handle;
    histPtr->offset = offset;
    histPtr->type = type;

    entry = Cache_Enter(history, (Address)histPtr->number,
			(Boolean *)NULL);

    Cache_SetValue(entry, histPtr);

    /*
     * If handle given, register interest in it so we're told if the
     * thing is freed. This allows us to purge bogus entries from
     * the value history.
     */
    if (handle != NullHandle) {
	Handle_Interest(handle, ValueHistoryInterest, (Opaque)entry);
    }
    
    return (nextHistNum++);
}

/*-
 *-----------------------------------------------------------------------
 * Value_HistoryFetch --
 *	Find the value and type of a history member.
 *
 * Results:
 *	TRUE if the requested element is in the history.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Value_HistoryFetch(int	    number, 	    /* Number of element to fetch. 0
					     * if should fetch most-recent one
					     */
		   Handle   *handlePtr,	    /* Place to store handle */
		   Address  *offsetPtr,	    /* Place to store offset */
		   Type	    *typePtr)	    /* Place to store type */
{
    Cache_Entry	  	entry;
    ValueHistPtr	histPtr;

    /*
     * Adjust number if it's 0
     */
    if (number <= 0) {
	number = nextHistNum - 1 + number;
    }
    
    entry = Cache_Lookup(history, (Address)number);
    if (entry == NullEntry) {
	return(FALSE);
    } else {
	histPtr = (ValueHistPtr)Cache_GetValue(entry);
	
	assert(VALIDTPTR(histPtr,TAG_VALUE));
	*handlePtr = histPtr->handle;
	*offsetPtr = histPtr->offset;
	*typePtr = histPtr->type;
	return(TRUE);
    }
}

typedef struct {
    Buffer  buf;    	/* Buffer into which to format it */
    genptr  value;    	/* Base of structure being formatted */
} ValueCmdData;

typedef struct {
    const char **fields;/* Broken-down list of fields */
    int	    fieldNum;	/* Field being unformatted */
    genptr  value;  	/* Base of structure */
} ValueCmdUndata;

static Boolean ValueCmdFormatField(Type, const char *, int, int, Type, ClientData);
static Boolean ValueCmdFormatUnionField(Type, const char *, int, int, Type, ClientData);
static Boolean ValueCmdUnformatField(Type, const char *, int, int, Type, ClientData);
				   

/***********************************************************************
 *				ValueCmdFormat
 ***********************************************************************
 * SYNOPSIS:	    Format an individual value into a buffer
 * CALLED BY:	    ValueCmdFormatField, ValueCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Yeah
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/88	Initial Revision
 *
 ***********************************************************************/
static void
ValueCmdFormat(Buffer  	buf,
	       genptr	value,
	       Type 	type)
{
    switch(Type_Class(type)) {
	case TYPE_STRUCT:
	{
	    ValueCmdData	vcd;
	    
	    vcd.buf = buf;
	    vcd.value = value;
	    
	    Type_ForEachField(type, ValueCmdFormatField,
			      (Opaque)&vcd);
	    break;
	}
	case TYPE_UNION:
	{
	    /*
	     * This is a little different from that for a structure as 
	     * we have to swap and unswap the data for each type of field.
	     */
	    ValueCmdData	vcd;
	    
	    vcd.buf = buf;
	    vcd.value = value;
	    
	    Type_ForEachField(type, ValueCmdFormatUnionField,
			      (Opaque)&vcd);
	    break;
	}
	case TYPE_ARRAY:
	{
	    int 	top;
	    Type	base;
	    int 	bsize;
	    genptr	vp;
	    int 	i;
	    
	    Type_GetArrayData(type, (int *)0, &top, (Type *)0, &base);
	    bsize = Type_Sizeof(base);
	    
	    for (i = 0, vp = value; i <= top; i++, vp += bsize) {
		Buf_AddByte(buf, (Byte)'{');
		ValueCmdFormat(buf, vp, base);
		if (i != top) {
		    Buf_AddBytes(buf, 2, (Byte *)"} ");
		} else {
		    Buf_AddByte(buf, (Byte)'}');
		    break;
		}
	    }
	    break;
	}
	case TYPE_FLOAT:
    	{
	    int 	size = Type_Sizeof(type);
	    union {
		long double l;
		double 	    d;
		float	    f;
		byte	    b[10];
	    }	    	val;
	    char	aval[320]; /* this is the size of the internal
				    * buffer used by sprintf */
	    
	    /*
	     * Convert the fetched value into something we can manipulate.
	     * NOTE: We cannot simply cast "value" into a pointer of the
	     * appropriate type, as the thing may not be properly
	     * aligned for the current machine.
	     */
	    if (size > 10) {
		strcpy(aval, "Infinity");
	    } else {
		double  d;

		bcopy(value, val.b, size);

		/* just print everything as a double as sprintf doesn't
		 * know about long doubles
		 */
		if (size == 4) {
		    d = val.f;
		} else if (size == 8) {
		    d = val.d;
		} else {
		    d = val.l;
		}
		if (d > 1000000000L) {
		    /* if this thing is this big, just put it into 
		     * exponential form for easier reading 
		     */
		    sprintf(aval, "%e", d);
		} else {
		    sprintf(aval, "%f", d);
		}
	    }
	    Buf_AddBytes(buf, strlen(aval), (Byte *)aval);
	    break;
	}
	case TYPE_CHAR:
	{
	    unsigned char    c = *(unsigned char *)value;

	    switch(c) {
		case '\\':
		    Buf_AddBytes(buf, 2, (Byte *)"\\\\");
		    break;
		case '{':
		    Buf_AddBytes(buf, 2, (Byte *)"\\{");
		    break;
		case '}':
		    Buf_AddBytes(buf, 2, (Byte *)"\\}");
		    break;
		case '\n':
		    Buf_AddBytes(buf, 2, (Byte *)"\\n");
		    break;
		case '\b':
		    Buf_AddBytes(buf, 2, (Byte *)"\\b");
		    break;
		case '\r':
		    Buf_AddBytes(buf, 2, (Byte *)"\\r");
		    break;
		case '\f':
		    Buf_AddBytes(buf, 2, (Byte *)"\\f");
		    break;
		case '\033':
		    Buf_AddBytes(buf, 2, (Byte *)"\\e");
		    break;
		default:
		    if (!isprint(c)) {
			char	b[5];

			sprintf(b, "\\%03o", c);
			Buf_AddBytes(buf, 4, (Byte *)b);
		    } else {
			Buf_AddByte(buf, c);
		    }
	    }
	    break;
	}
	case TYPE_INT:
	default:
	{
	    int 	size = Type_Sizeof(type);
	    int 	val;
	    int 	mask;
	    char	aval[16];
	    
	    /*
	     * Convert the fetched value into something we can manipulate.
	     * NOTE: We cannot simply cast "value" into a pointer of the
	     * appropriate type, as the thing may not be properly
	     * aligned for the current machine.
	     */
	    if (size == 1) {
		val = *(char *)((signed char *)value);
	    } else if (size == 2) {
		if (swap) {
		    val = (((signed char *)value)[0] << 8) |
			(((signed char *)value)[1] & 0xff);
		} else {
		    val = (((signed char *)value)[1] << 8) |
			(((signed char *)value)[0] & 0xff);
		}
	    } else {
		if (swap) {
		    val = (((signed char *)value)[0] << 24) |
			    ((((signed char *)value)[1] & 0xff) << 16) |
			    ((((signed char *)value)[2] & 0xff) << 8) |
			    (((signed char *)value)[3] & 0xff);
		} else {
		    val = (((signed char *)value)[3] << 24) |
			    ((((signed char *)value)[2] & 0xff) << 16) |
			    ((((signed char *)value)[1] & 0xff) << 8) |
			    (((signed char *)value)[0] & 0xff);
		}
	    }
	    
	    mask = (1 << (size * 8)) - 1;
	    /*
	     * On the sparc (and possibly others), a shift count of 32
	     * is considered a shift count of 0. This will give us 1 - 1
	     * or a 0 mask, which isn't good...
	     */
	    if (mask) {
		val &= mask;
	    } else {
		mask = -1;
	    }
	    if (Type_IsSigned(type)) {
		/*
		 * Trim the integer to be the appropriate size and then,
		 * if the high bit is set, sign extend the beast to the
		 * full length of an integer before printing it.
		 */
		if (val & (mask & ~(mask >> 1))) {
		    val |= ~mask;
		}
		sprintf(aval, "%d", val);
	    } else {
		sprintf(aval, "%u", (val & mask));
	    }
	    Buf_AddBytes(buf, strlen(aval), (Byte *)aval);
	    break;
	}
    }
}	

/***********************************************************************
 *				ValueCmdFormatField
 ***********************************************************************
 * SYNOPSIS:	    Format a field of a structure into a 3-tuple.
 * CALLED BY:	    ValueCmd/ValueCmdFormat via Type_ForEachField
 * RETURN:	    0
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:	    Install the first two elements of the tuple,
 *	    	    preceeded by a {, as required by tcl.
 *	    	    Call ValueCmdFormat to format the value.
 *	    	    Tack on the final } and return.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/88	Initial Revision
 *
 ***********************************************************************/
static Boolean
ValueCmdFormatField(Type    	stype,
		    const char 	*fname,
		    int	    	offset,
		    int	    	length,
		    Type    	ftype,
		    ClientData	data)
{
    ValueCmdData    *vcd = (ValueCmdData *)data;
    char    	    tname[48];

    Buf_AddByte(vcd->buf, (Byte)'{');
    if (*fname != '\0') {
	Buf_AddBytes(vcd->buf, strlen(fname), (Byte *)fname);
    } else {
	Buf_AddBytes(vcd->buf, 2, (Byte *)"{}");
    }

    sprintf(tname, " {%s} {", Type_ToAscii(ftype));
    Buf_AddBytes(vcd->buf, strlen(tname), (Byte *)tname);

    if ((length != Type_Sizeof(ftype) * 8) || (offset & 0x7)) {
	/*
	 * If it's not of a byte-divisible length and on a byte boundary, we
	 * have to extract the field into our own thing of the appropriate
	 * size (so when we pass its address, we're actually pointing to the
	 * beast, not to some unimportant higher bytes...), then format that
	 * according to the field's type.
	 */
	Boolean	isSigned = Type_IsSigned(ftype);
	
	if (Type_Class(ftype) != TYPE_INT) {
	    switch(Type_Sizeof(ftype)) {
		case 1:
		{
		    byte	val;

		    val = (byte)Var_ExtractBits(vcd->value, offset, length,
						isSigned);
		    ValueCmdFormat(vcd->buf, (genptr)&val, ftype);
		    break;
		}
		case 2:
		{
		    word	val;

		    val = (word)Var_ExtractBits(vcd->value, offset, length,
						isSigned);
		    if (Type_IsRecord(ftype)) {
			/*
			 * Need to be in the target byte order if it's a record
			 */
			Var_SwapValue(VAR_STORE, type_Word, 2, (genptr)&val);
		    }
		    
		    ValueCmdFormat(vcd->buf, (genptr)&val, ftype);
		    break;
		}
		default:
		case 4:
		{
		    dword	val;

		    val = (dword)Var_ExtractBits(vcd->value, offset, length,
						 isSigned);
		    ValueCmdFormat(vcd->buf, (genptr)&val, ftype);
		    break;
		}
	    }
	} else {
	    unsigned	val;
	    char	aval[8];

	    val = Var_ExtractBits(vcd->value, offset, length, isSigned);
	    if (isSigned) {
		sprintf(aval, "%d", val);
	    } else {
		sprintf(aval, "%u", val);
	    }
	    Buf_AddBytes(vcd->buf, strlen(aval), (Byte *)aval);
	}
    } else {
	ValueCmdFormat(vcd->buf, vcd->value + (offset/8), ftype);
    }
    Buf_AddBytes(vcd->buf, 3, (Byte *)"}} ");

    return(0);
}


/***********************************************************************
 *				ValueCmdFormatUnionField
 ***********************************************************************
 * SYNOPSIS:	    Format a field of a union into a 3-tuple.
 * CALLED BY:	    ValueCmd/ValueCmdFormat via Type_ForEachField
 * RETURN:	    0
 * SIDE EFFECTS:    yeah.
 *
 * STRATEGY:	    Swap the union according to the type of the current
 *	    	    field Install the first two elements of the tuple,
 *	    	    preceeded by a {, as required by tcl.
 *	    	    Call ValueCmdFormat to format the value.
 *	    	    Tack on the final }
 *	    	    Swap the union back and return.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/88	Initial Revision
 *
 ***********************************************************************/
static Boolean
ValueCmdFormatUnionField(Type    	stype,
			 const char    	*fname,
			 int	    	offset,
			 int	    	length,
			 Type    	ftype,
			 ClientData	data)
{
    ValueCmdData    *vcd = (ValueCmdData *)data;
    char    	    tname[48];

    Buf_AddByte(vcd->buf, (Byte)'{');
    if (*fname != '\0') {
	Buf_AddBytes(vcd->buf, strlen(fname), (Byte *)fname);
    } else {
	Buf_AddBytes(vcd->buf, 2, (Byte *)"{}");
    }

    sprintf(tname, " {%s} {", Type_ToAscii(ftype));
    Buf_AddBytes(vcd->buf, strlen(tname), (Byte *)tname);

    if (length != Type_Sizeof(ftype) * 8) {
	/*
	 * If it's not of a byte-divisible length, we have to extract the
	 * field into our own thing of the appropriate size (so when we
	 * pass its address, we're actually pointing to the beast, not to
	 * some unimportant higher bytes...), then format that according
	 * to the field's type.
	 */
	Boolean 	isSigned = Type_IsSigned(ftype);

	if (Type_Class(ftype) != TYPE_INT) {
	    switch(Type_Sizeof(ftype)) {
		case 1:
		{
		    byte	val;

		    val = (byte)Var_ExtractBits(vcd->value, offset, length,
						isSigned);
		    ValueCmdFormat(vcd->buf, (genptr)&val, ftype);
		    break;
		}
		case 2:
		{
		    word	val;

		    val = (word)Var_ExtractBits(vcd->value, offset, length,
						isSigned);
		    ValueCmdFormat(vcd->buf, (genptr)&val, ftype);
		    break;
		}
		default:
		case 4:
		{
		    dword	val;

		    val = (dword)Var_ExtractBits(vcd->value, offset, length,
						 isSigned);
		    ValueCmdFormat(vcd->buf, (genptr)&val, ftype);
		    break;
		}
	    }
	} else {
	    unsigned	val;
	    char	aval[8];

	    val = (unsigned)Var_ExtractBits(vcd->value, offset, length,
					    isSigned);
	    if (isSigned) {
		sprintf(aval, "%d", val);
	    } else {
		sprintf(aval, "%u", val);
	    }
	    Buf_AddBytes(vcd->buf, strlen(aval), (Byte *)aval);
	}
    } else {

	if (swap) {
	    Var_SwapValue(VAR_FETCH, ftype, length/8, vcd->value+(offset/8));
	}
	ValueCmdFormat(vcd->buf, vcd->value + (offset/8), ftype);
	if (swap) {
	    Var_SwapValue(VAR_STORE, ftype, length/8, vcd->value+(offset/8));
	}
    }

    Buf_AddBytes(vcd->buf, 3, (Byte *)"}} ");

    return(0);
}


/***********************************************************************
 *				Value_ConvertToString
 ***********************************************************************
 * SYNOPSIS:	    Convert a hunk of data from the patient into a
 *	    	    string based on the type of data.
 * CALLED BY:	    ValueCmd, EXTERNAL
 * RETURN:	    A dynamically allocated string holding the value
 *	    	    as a TCL list.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
char *
Value_ConvertToString(Type  	type,	    /* Type of data to convert */
		      Opaque	value)	    /* Data to convert */
{
    Buffer	buf;
    char    	*retval;

    buf = Buf_Init(0);
    ValueCmdFormat(buf, value, type);
    Buf_AddByte(buf, (Byte)0);
    retval = (char *)Buf_GetAll(buf, (int *)NULL);
    Buf_Destroy(buf, FALSE);
    return(retval);
}

/***********************************************************************
 *				ValueCmdUnformat
 ***********************************************************************
 * SYNOPSIS:	    Parse out a unit from the string, storing it in the
 *	    	    buffer passed.
 * CALLED BY:	    Value_ConvertFromString, ValueCmdUnformatField, self
 * RETURN:	    non-zero if happy, zero if malformed string
 *	    	    on error, a message is left in the system-wide tcl
 *	    	    interpreter's return value, in case we were called
 *	    	    by a tcl function.
 * SIDE EFFECTS:    Buffer overwritten
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
static int
ValueCmdUnformat(Type       type,	/* Type of data in string */
		 const char *str,   	/* String to parse */
		 Opaque	    value)  	/* Buffer for storage */
{
    switch(Type_Class(type)) {
	case TYPE_STRUCT:
	{
	    /*
	     * XXX: Do fieldname-keyed storage instead of linear? Would make
	     * life easier, but what to do with uninitialized fields?
	     */
	    ValueCmdUndata	vcu;
	    int	    	    	nfields;
	    
	    if (Tcl_SplitList(interp, str, &nfields, (char ***)&vcu.fields) !=
		TCL_OK)
	    {
		return(0);
	    }

	    vcu.fieldNum = 0;
	    vcu.value = value;
	    
	    Type_ForEachField(type, ValueCmdUnformatField,
			      (Opaque)&vcu);

	    free((char *)vcu.fields);
	    /*
	     * If didn't make it all the way through, one of the fields was
	     * malformed, so return 0.
	     */
	    if (vcu.fieldNum != nfields) {
		return(0);
	    }
	    break;
	}
	case TYPE_ARRAY:
	{
	    int 	top;
	    Type	base;
	    int 	bsize;
	    genptr	vp;
	    int 	i;
	    int	    	nels;
	    char    	**els;
	    
	    Type_GetArrayData(type, (int *)0, &top, (Type *)0, &base);
	    bsize = Type_Sizeof(base);

	    /*
	     * Break the string down to its component pieces and make sure we
	     * were given the right number of them.
	     */
	    if (Tcl_SplitList(interp, str, &nels, &els) != TCL_OK) {
		return (0);
	    }
	    if (nels != top+1) {
		free((char *)els);
		Tcl_Return(interp, "incorrect number of elements for array",
			   TCL_STATIC);
		return(0);
	    }
	    
	    /*
	     * Unformat the individual pieces, stopping if we get an error
	     * back for any of them.
	     */
	    for (i = 0, vp = value; i <= top; i++, vp += bsize) {
		if (!ValueCmdUnformat(base, els[i], (Opaque)vp)) {
		    free((char *)els);
		    return(0);
		}
	    }

	    free((char *)els);
	    break;
	}
	case TYPE_CHAR:
	{
	    if (*str == '\\') {
		int 	n;

		*(unsigned char *)value = Tcl_Backslash(str, &n);
		/*
		 * If character escape didn't consume the entire string,
		 * we consider it an error.
		 */
		if (str[n] != '\0') {
		    Tcl_RetPrintf(interp, "\"%s\" not valid character escape",
				  str);
		    return(0);
		}
	    } else {
		/*
		 * Store the character away as given.
		 */
		*(unsigned char *)value = *str;
	    }
	    break;
	}
	case TYPE_INT:
	default:
	{
	    int 	size = Type_Sizeof(type);
	    int 	val;
	    char    	*endStr;
	    
	    val = cvtnum(str, &endStr);
	    if (*endStr != '\0') {
		/*
		 * If number not the whole thing, it's an error
		 */
		Tcl_RetPrintf(interp, "\"%s\" not valid scalar", str);
		return(0);
	    }

	    /*
	     * Store the converted value away, based on the size of the
	     * data type we're storing.
	     * NOTE: We cannot simply cast "value" into a pointer of the
	     * appropriate type, as the thing may not be properly
	     * aligned for the current machine.
	     */
	    if (swap) {
		/*
		 * Native order big-endian: lsb goes up high.
		 */
		((byte *)value)[size-1] = val;
		if (size > 1) {
		    val >>= 8;
		    ((byte *)value)[size-2] = val;
		    if (size > 2) {
			val >>= 8;
			((byte *)value)[size-3] = val;
			if (size > 3) {
			    val >>= 8;
			    ((byte *)value)[size-4] = val;
			}
		    }
		}
	    } else {
		/*
		 * Native order little-endian: lsb goes down low
		 */
		*(byte *)value = val;
		if (size > 1) {
		    val >>= 8;
		    ((byte *)value)[1] = val;
		    if (size > 2) {
			val >>= 8;
			((byte *)value)[2] = val;
			if (size > 3) {
			    val >>= 8;
			    ((byte *)value)[3] = val;
			}
		    }
		}
	    }
	    break;
	}
	case TYPE_VOID:
	    break;
	case TYPE_UNION:
	    Tcl_Return(interp, "cannot store unions (yet?)", TCL_STATIC);
	    return(0);
    }

    return(1);
}


/***********************************************************************
 *			ValueCmdUnformatField
 ***********************************************************************
 * SYNOPSIS:	    Convert a field of a structure given in ascii to binary.
 * CALLED BY:	    ValueCmdUnformat via Type_ForEach
 * RETURN:	    0 if ok, non-zero if unhappy with the string.
 * SIDE EFFECTS:    The buffer given in the ValueCmdUndata is overwritten.
 *	    	    vcu->fieldNum is incremented
 *
 * STRATEGY:
 *
 *	XXX: Should this insist on matching field names?
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
static Boolean
ValueCmdUnformatField(Type    	    stype,
		      const char    *fname,
		      int	    offset,
		      int	    length,
		      Type    	    ftype,
		      ClientData    data)
{
    ValueCmdUndata  *vcu = (ValueCmdUndata *)data;
    char    	    **els;
    int	    	    nels;
    int	    	    retval = 0;

    /*
     * Break the value into its proper three-part list.
     */
    if (Tcl_SplitList(interp, vcu->fields[vcu->fieldNum], &nels, &els)!=TCL_OK)
    {
	/*
	 * Stop traversal -- leaving fieldNum unincremented will signal our
	 * displeasure.
	 */
	return(1);
    }
    
    /*
     * Make sure list contains the right number of elements.
     */
    if (nels != 3) {
	Tcl_Return(interp, "structure field must be described by a 3-list",
		   TCL_STATIC);
	free((char *)els);
	return(1);
    }
    
    /* XXX: Compare field names? types? */
    
    if (length != Type_Sizeof(ftype) * 8) {
	/*
	 * If it's not of a byte-divisible length, we have to store the
	 * field specially. Value must be a lone integer.
	 */
	char	*endStr;
	word	val;

	val = cvtnum(els[2], &endStr);
	if (*endStr != '\0') {
	    Tcl_RetPrintf(interp, "\"%s\" improperly formed bit-field",
			  els[2]);
	    retval = 1;
	} else {
	    Var_InsertBits(vcu->value, offset, length, val);
	}
    } else {
	retval = !ValueCmdUnformat(ftype, els[2], vcu->value + (offset/8));
    }

    if (!retval) {
	vcu->fieldNum += 1;
    }
    
    free((char *)els);

    return(retval);
}

    

/***********************************************************************
 *			Value_ConvertFromString
 ***********************************************************************
 * SYNOPSIS:	    Convert a structured string, as produced by
 *	    	    Value_ConvertToString, into a block of binary data
 *	    	    for shipment to the pc.
 * CALLED BY:	    ValueCmd, EXTERNAL
 * RETURN:	    Pointer to the data buffer allocated. The data are
 *	    	    stored in our native byte-order
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
Opaque
Value_ConvertFromString(Type	    type,   	/* Type describing string */
			const char  *str)   	/* String to convert */
{
    int	    size = Type_Sizeof(type);
    Opaque  value = (Opaque)malloc_tagged(size, TAG_DVAL);

    if (!ValueCmdUnformat(type, str, value)) {
	/*
	 * Malformed string -- return NULL to indicate error
	 */
	free((char *)value);
	value = NullOpaque;
    }

    return(value);
}


/***********************************************************************
 *				ValueCmd
 ***********************************************************************
 * SYNOPSIS:	    Implementation of the Tcl "value" command
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK or TCL_ERROR
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/88	Initial Revision
 *
 ***********************************************************************/
#define VALUE_FETCH	(ClientData)0
#define VALUE_STORE 	(ClientData)1
#define VALUE_HFETCH	(ClientData)2
#define VALUE_HSTORE	(ClientData)3
#define VALUE_HSET	(ClientData)4
#define VALUE_LOG       (ClientData)5
static const CmdSubRec	valueCmds[] = {
    {"fetch",	VALUE_FETCH,	1, 2, "<address> [<type>]"},
    {"store",	VALUE_STORE,	2, 3, "<address> <value> [<type>]"},
    {"hfetch",	VALUE_HFETCH,	1, 1, "<number>"},
    {"hstore",	VALUE_HSTORE,	1, 1, "<addr-list>"},
    {"hset",	VALUE_HSET,	1, 1, "<numberSaved>"},
    {"log",     VALUE_LOG,      2, 3,  "<address> <stream> [<type>]"},
    {NULL,	(ClientData)NULL,		0, 0, NULL}
};
DEFCMD(value,Value,0,valueCmds,swat_prog.patient|swat_prog.memory,
"Usage:\n\
    value fetch <addr> [<type>]\n\
    value store <addr> <value> [<type>]\n\
    value hfetch <num>\n\
    value hstore <addr-list>\n\
    value hset <number-saved>\n\
    value log <addr> <stream> <type>]\n\
\n\
Examples:\n\
    \"value fetch ds:si [type word]\"	Fetch a word from ds:si\n\
    \"value store ds:si 0 [type word]\"	Store 0 to the word at ds:si\n\
    \"value hfetch 36\"	    	    	Fetch the 36th address list stored\n\
					in the value history.\n\
    \"value hstore $a\"	    	    	Store the address list in $a into\n\
					the value history.\n\
    \"value hset 50\" 	    	    	Keep track of up to 50 address lists\n\
					in the value history.\n\
    \"value log ds:si $s [type word]\"  Fetch a word from ds:si and dump the binary \n\
                                        data to stream $s \n\
\n\
Synopsis:\n\
    This command allows you to fetch and alter values in the target PC. It is\n\
    also the maintainer of the value history, which you normally access via\n\
    @<number> terms in address expressions.\n\
\n\
Notes:\n\
    * \"value fetch\" returns a value list that contains the data at the\n\
      given address. If the address has an implied data type (it involves\n\
      a named variable or a structure field), then you do not need to give the\n\
      <type> argument.\n\
\n\
      All integers and enumerated types are returned in decimal. 32-bit\n\
      pointers are returned as a single decimal integer whose high 16 bits are\n\
      the high 16 bits (segment or handle) of the pointer. 16-bit pointers\n\
      are likewise returned as a single decimal integer.\n\
\n\
      Characters are returned as characters, with non-printable characters\n\
      converted to the appropriate backslash escapes (for example, newline\n\
      is returned as \\n).\n\
\n\
      Arrays are returned as a list of value lists, one element per element\n\
      of the array.\n\
\n\
      Structures, unions and records are returned as a list of elements,\n\
      each of which is a 3-element list: {<field-name> <type> <value>}\n\
      <field-name> is the name of the field, <type> is the type token for\n\
      the type of data stored in the field, and <value> is the value list\n\
      for the data in the field, appropriate to its data type.\n\
\n\
    * You will note that the description of value lists is recursive.\n\
      For example, if a structure has a field that is an array, the <value>\n\
      element in the list that describes that particular field will be itself\n\
      a list whose elements are the elements of the array. If that array were\n\
      an array of structures, each element of that list would again be a list\n\
      of {<field-name> <type> <value>} lists.\n\
\n\
    * The \"field\" command is very useful when you want to extract the value\n\
      for a structure field from a value list.\n\
\n\
    * As for \"value fetch\", you do not need to give the <type> argument to\n\
      \"value store\" if the <addr> has an implied data type. The <value>\n\
      argument is a value list appropriate to the type of data being stored,\n\
      as described above.\n\
\n\
    * \"value hstore\" returns the number assigned to the stored address list.\n\
      These numbers always increase, starting from 1.\n\
\n\
    * If no address list is stored for a given number, \"value hfetch\" will\n\
      generate an error.\n\
\n\
    * \"value hset\" controls the maximum number of address lists the value\n\
      history will hold. The value history is a FIFO queue; if it holds\n\
      50 entries, and the 51st entry is added to it, the 1st entry will be\n\
      thrown out.\n\
\n\
    * \"value log\" has the same functionality as value fetch except that data fetched \n\
        from the PC are dumped into the stream as raw binary data. \n\
\n\
See also:\n\
    addr-parse, assign, field\n\
")
{
    switch((int)clientData) {
    case VALUE_STORE:
    case VALUE_FETCH:
    case VALUE_LOG:
	{
        genptr	    value;
	GeosAddr    addr;
	Type	    type;
	int 	    typeIndex;

	if (!Expr_Eval(argv[2], NullFrame, &addr, &type, TRUE)) {
	    Tcl_Error(interp, "value: couldn't parse address");
	}

	if (clientData == VALUE_STORE || clientData == VALUE_LOG) {
	    typeIndex = 4;
	} else {
	    typeIndex = 3;
	}

	if (argc > typeIndex) {
	    static struct {
	    	char	*typeName;
		Type	*typeDesc;
	    } predefs[] = {
	    	{"byte",	&type_Byte},
		{"word",	&type_Word},
		{"dword",	&type_DWord},
		{"sbyte",	&type_SByte},
		{"short",	&type_Short},
		{"long",	&type_Long},
		{"char",	&type_Char},
		{"wchar",	&type_WChar},
		{"sword",    	&type_Short},
		{"sdword",   	&type_Long}
	    };
	    type = Type_ToToken(argv[typeIndex]);

	    if (Type_IsNull(type)) {
		/*
		 * KLUDGE: check to see if it's a predefined type. The proper
		 * way to do this is with a nested "type" command, but
		 * people insist on just being able to ask for a "word",
		 * so rather than listening to complaints, I've decided
		 * to just put this here.
		 *
		 * 3/30/92: conduct this search *first* as a lot of Tcl
		 * code now uses just "word" or whatever and the speed
		 * difference is incredibly noticeable. -- ardeb
		 */
		int 	i;

		for (i = Number(predefs)-1; i >= 0; i--) {
		    if (!ustrcmp(argv[typeIndex], predefs[i].typeName)) {
			type = *predefs[i].typeDesc;
			break;
		    }
		}
	    }

	    if (Type_IsNull(type)) {
		Sym 	sym = Sym_Lookup(argv[typeIndex], SYM_TYPE,
					 curPatient->global);

		if (!Sym_IsNull(sym)) {
		    type = Sym_GetTypeData(sym);
		}
	    }

	    if (Type_IsNull(type)) {
		Tcl_RetPrintf(interp, "value: %s: invalid type",
			      argv[typeIndex]);
		return(TCL_ERROR);
	    }
	}
	if (Type_IsNull(type)) {
	    Tcl_Error(interp, "value: need type of data to fetch/store");
	}

	if (clientData == VALUE_STORE) {
	    value = Value_ConvertFromString(type, argv[3]);
	    if (value == NULL) {
		Tcl_Error(interp, "value store: couldn't convert string");
	    }
	    Var_Store(type, value, addr.handle, addr.offset);
	} else {
	    if (!Var_FetchAlloc(type, addr.handle, addr.offset, &value)) {
		Tcl_Return(interp, "value: couldn't fetch data", TCL_STATIC);
		return(TCL_ERROR);
	    }
	    if (clientData == VALUE_FETCH) {
		Tcl_Return(interp, Value_ConvertToString(type, value), TCL_DYNAMIC);
	    } else {
		int   size;
		Stream *stream = 0;

		stream = (Stream *)atoi(argv[3]);
		if (!VALIDTPTR(stream,TAG_STREAM)) {
		    Tcl_RetPrintf(interp, "%s: not a stream", argv[3]);
		    return(TCL_ERROR);
		}
		size = Type_Sizeof(type);
		if (stream->type == STREAM_SOCKET) {
		    if (write(stream->sock, (char*)value, size) < size) {
			stream->sockErr = TRUE;
		    } 
		} else {
		    (void)fwrite((char*)value, size, 1, stream->file);
		    }
	    }
	}
	free((char *)value);
	break;
    }
  case VALUE_HFETCH:
    {
	Handle	handle;
	Address	offset;
	Type	type;
	
	if (!Value_HistoryFetch(atoi(argv[2]), &handle, &offset, &type)) {
	    Tcl_RetPrintf(interp, "%s: not in value history", argv[2]);
	    return(TCL_ERROR);
	} else {
	    Tcl_RetPrintf(interp, "%d %d {%s}", handle, offset,
			  Type_ToAscii(type));
	}
	break;
    }
  case VALUE_HSTORE:
    {
	Handle	handle;
	Address	offset;
	Type	type;
	char	**fields;
	int 	nfields;
	
	if (Tcl_SplitList(interp, argv[2], &nfields, &fields) != TCL_OK) {
	    return(TCL_ERROR);
	}
	if (nfields != 3) {
	    Tcl_Error(interp, "value hstore: <addr-list> needs three fields");
	}
	/*
	 * Convert the three fields individually. Note that atoi("nil") yields
	 * 0, so there's no need to deal with it specially.
	 */
	handle = (Handle)atoi(fields[0]);
	offset = (Address)atoi(fields[1]);
	type = Type_ToToken(fields[2]);

	free((char *)fields);
	Tcl_RetPrintf(interp, "%d", Value_HistoryStore(handle, offset, type));
	break;
    }
    case VALUE_HSET:
    {
	int	length = cvtnum(argv[2], NULL);

	if (length >= 1) {
	    Cache_SetMaxSize(history, length);
	    return(TCL_OK);
	} else {
	    Tcl_Error(interp, "value hset: history must contain at least one entry");
	}
    }
    }
    return(TCL_OK);
}
		


/*-
 *-----------------------------------------------------------------------
 * Value_Init --
 *	Initialize our data for this patient.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A ValuePrivRec is created and attached to the patient.
 *
 *-----------------------------------------------------------------------
 */
void
Value_Init(void)
{
    nextHistNum = 1;

    history = Cache_Create(0, 50, CACHE_ADDRESS, ValueHistoryDestroy);

    Cmd_Create(&ValueCmdRec);
}









