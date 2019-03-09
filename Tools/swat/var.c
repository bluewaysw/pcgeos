/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Variable Storage and Fetchage :)
 * FILE:	  var.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Var_FetchString	    Fetch a null-terminated string
 *	Var_ExtractBits	    Extract bits from a fetched bitfield.
 *	Var_FetchBits	    Fetch bits from memory
 *	Var_FetchInt	    Fetch an integer.
 *	Var_FetchAlloc	    Fetch and allocate storage.
 *	Var_Fetch   	    Fetch into own storage.
 *	Var_StoreBits	    Store a bitfield
 *	Var_StoreInt	    Store a passed integer (not pointer to same!)
 *	Var_Store   	    Store a variable/buffer
 *	Var_SwapValue	    Byte-swap a buffer based on a type description.
 *	Var_Cast    	    Cast a buffer from one type to another.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for fetching, storing and byte-swapping variables.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: var.c,v 4.8 96/06/13 17:24:12 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "type.h"
#include "var.h"

typedef struct {
    genptr 	  	address;    	/* Base of value to swap */
    Var_SwapDirection	direction;
    Boolean 	    	hasBitField;	/* Set true if a bit-field is
					 * encountered. */
} VarSwapData;

/*-
 *-----------------------------------------------------------------------
 * VarSwapField --
 *	Swap a field of a structure.
 *
 * Results:
 *	=== 0.
 *
 * Side Effects:
 *	The field is swapped if necessary.
 *
 *-----------------------------------------------------------------------
 */
static int
VarSwapField(Type	    type,   	    /* Type from which field comes */
	     char	    *fieldName,	    /* Name of this field */
	     int	    offset, 	    /* Bit offset from start */
	     int	    length, 	    /* Length (bits) */
	     Type	    fieldType,	    /* Base type of field */
	     VarSwapData    *dataPtr)	    /* Swapping data (see above) */
{
    int	    size = Type_Sizeof(fieldType);
    
    /*
     * Make sure this field is not a bit-field -- we don't swap bit-fields
     * until their data are requested.
     */
    if (length == size * 8) {
	Var_SwapValue(dataPtr->direction, fieldType, size,
		      dataPtr->address + (offset / 8));
    }
    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * Var_SwapValue --
 *	Byte-swap a value in place.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The data are byte-swapped.
 *
 *-----------------------------------------------------------------------
 */
void
Var_SwapValue(Var_SwapDirection	direction,  /* Direction for swap */
	      Type		type,	    /* Type of data at address */
	      int		size,	    /* Size of data "     "    */
	      genptr		address)    /* Data to swap */
{
    switch(Type_Class(type)) {
	case TYPE_FLOAT: /* XXX: these things are IEEE-standard
			  * everywhere, so we can just treat the
			  * thing as a big integer... it's still
			  * gross, though */
	case TYPE_RANGE:
	case TYPE_ENUM:
	case TYPE_POINTER:
	case TYPE_INT: {
	    register int i, j;
	    register char temp;
	    char    *cp;

	    cp = (char *)address;
	    
	    for (i = 0, j = size - 1; i < j; i++, j--) {
		temp = cp[i];
		cp[i] = cp[j];
		cp[j] = temp;
	    }
	    break;
	}
	case TYPE_UNION:
	case TYPE_CHAR:
	    break;
	case TYPE_STRUCT: {
	    VarSwapData	    data;

	    data.address = address;
	    data.direction = direction;
	    data.hasBitField = FALSE;
	    
	    Type_ForEachField(type, VarSwapField, (Opaque)&data);

#if 0
	    if (data.hasBitField && size > 1) {
		/*
		 * The thing is a RECORD (a structure with at least one bit-
		 * field in it), swap the whole thing at once. Note that
		 * byte-sized RECORDs need no swapping.
		 */
		goto swap_int;
	    }
#endif		
	    break;
	}
	case TYPE_ARRAY: {
	    /*
	     * Figure number and type of elements and swap as
	     * necessary.
	     */
	    Type  baseType;
	    int	  bot, top;
	    int	  eltSize;
	    char  *cp = (char *)address;
	    
	    Type_GetArrayData(type, &bot, &top, (Type *)NULL, &baseType);
	    eltSize = Type_Sizeof(baseType);

	    switch(Type_Class(baseType)) {
		case TYPE_FLOAT: /* XXX: these things are IEEE-standard
				  * everywhere, so we can just treat the
				  * thing as a big integer... it's still
				  * gross, though */
		case TYPE_INT:
		case TYPE_POINTER:
		case TYPE_ENUM:
		case TYPE_RANGE: {
		    /*
		     * Swap these things here rather than recursing to speed
		     * up the process a bit.
		     */
		    register int i, j;
		    register char temp;
		    
		    while(top >= bot) {
			for (i = 0, j = eltSize - 1; i < j; i++, j--) {
			    temp = cp[i];
			    cp[i] = cp[j];
			    cp[j] = temp;
			}
			cp += eltSize;
			top--;
		    }
		    break;
		}
		case TYPE_STRUCT:
		    while(top >= bot) {
			Var_SwapValue(direction, baseType, eltSize,
					(genptr)cp);
			cp += eltSize;
			top--;
		    }
		    break;
	    }
	    break;
	}
	case TYPE_VOID:
	case TYPE_FUNCTION:
	case TYPE_EXTERNAL:
	case TYPE_BITFIELD:
	    break;
    }
}

/*-
 *-----------------------------------------------------------------------
 * Var_FetchString --
 *	Reads a null-terminated string from the patient at the given
 *	address.
 *	XXX: problems if sort-of hit end of address space.
 *
 * Results:
 *	The string in a dynamically-allocated buffer.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
char *
Var_FetchString(Handle	handle,
		Address	offset)
{
    char    	  	*buffer;
    char    	  	*cp;
    int			len;
    int			i;

#define BUFFER_INC	128    

    len = BUFFER_INC;
    cp = buffer = malloc_tagged(BUFFER_INC, TAG_VALUE);

    do {
	*cp = '\0';
	if (!Ibm_ReadBytes(BUFFER_INC, handle, offset, cp)) {
	    sprintf(cp, "(bad read)");
	    break;
	}
	for (i = BUFFER_INC; *cp != '\0' && i > 0; i--, cp++) {
	    /* void */ ;
	}
	if (i == 0) {
	    buffer = realloc_tagged(buffer, len + BUFFER_INC);
	    cp = buffer + len;
	    len += BUFFER_INC;
	}
	offset += BUFFER_INC;
    } while (i == 0);

    return(buffer);
}
    
/*-
 *-----------------------------------------------------------------------
 * Var_ExtractBits --
 *	Extracts the given number of bits from the appropriate offset in
 *	the data pointed to by value. THE VALUE IS IN LITTLE-ENDIAN ORDER
 *	XXX: dependency on sizeof(int) == 4
 *
 * Results:
 *	The bits, right-justified in the word.
 *
 * Side Effects:
 *	None
 *
 *-----------------------------------------------------------------------
 */
dword
Var_ExtractBits(genptr	base,	    /* Base of fetched data */
		int   	offset,	    /* Bit offset from the base */
		int   	length,	    /* Number of bits to extract */
		Boolean isSigned)
{
    dword    	  	v;

    /*
     * Advance to base byte...
     */
    base += (offset & ~0x7) / 8;
    offset &= 0x7;

    if (offset+length <= 8) {
	/*
	 * Field entirely w/in this byte -- no need to swap.
	 */
	v = *(byte *)base;
    } else if (offset+length <= 16) {
	/*
	 * Fetch the word out and swap it.
	 */
	v = (*(byte *)base & 0xff) | (((byte *)base)[1] << 8);
    } else {
	v = (*(byte *)base & 0xff) |
	    (((byte *)base)[1] << 8) |
		(((byte *)base)[2] << 16) |
		    (((byte *)base)[3] << 24);
    }
    /*
     * Extract the bits from the swapped dword.
     */
    v >>= offset;
    v &= (1 << length) - 1;
    
    if (isSigned && (v & (1 << (length-1)))) {
	/*
	 * Must sign-extend the thing.
	 */
	v |= ~(dword)((1 << length)-1);
    }
    return v;
}
/*-
 *-----------------------------------------------------------------------
 * Var_InsertBits --
 *	Inserts the given number of bits at the appropriate offset in
 *	the data pointed to by base.
 *	XXX: dependency on sizeof(int) == 4
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The passed buffer is modified.
 *
 *-----------------------------------------------------------------------
 */
void
Var_InsertBits(genptr	base,	    /* Base of buffer */
	       int   	offset,	    /* Bit offset from the base */
	       int   	length,	    /* Number of bits to insert */
	       dword	val)	    /* Value to insert */
{
    dword    	  	v;
    dword    	    	mask;

    /*
     * Advance to base byte...
     */
    base += (offset & ~0x7) / 8;
    offset &= 0x7;

    if (offset+length <= 8) {
	/*
	 * Field entirely w/in this byte -- no need to swap.
	 */
	v = *(byte *)base;
    } else if (offset+length <= 16) {
	/*
	 * Fetch the word out and swap it.
	 */
	v = (*(byte *)base & 0xff) | (((byte *)base)[1] << 8);
    } else {
	v = (*(byte *)base & 0xff) |
	    (((byte *)base)[1] << 8) |
		(((byte *)base)[2] << 16) |
		    (((byte *)base)[3] << 24);
    }

    /*
     * Form bitmask based on the offset and length
     */
    mask = ((1 << (length+offset)) - 1) & ~((1 << offset) - 1);

    /*
     * Merge the bits into the existing value
     */
    v &= ~mask;
    v |= ((val << offset) & mask);
    /*
     * Store away the combined value
     */
    *(byte *)base = v;
    if (offset+length > 8) {
	((byte *)base)[1] = v >> 8;
	if (offset + length > 16) {
	    ((byte *)base)[2] = v >> 16;
	    ((byte *)base)[3] = v >> 24;
	}
    }
}
/*-
 *-----------------------------------------------------------------------
 * Var_FetchBits --
 *	Fetches the given number of bits from the appropriate offset at
 *	the given address in the patient. The result is stored as an int
 *	in our byte-order in the given place.
 *	XXX: dependency on sizeof(int) == 4
 *
 * Results:
 *	None (except the bits).
 *
 * Side Effects:
 *	The passed buffer is overwritten.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Var_FetchBits(Handle 	handle,
	      Address 	base,
	      int   	offset,
	      int   	length,
	      Boolean	isSigned,
	      dword   	*valuePtr)
{
    byte    	    data[4];

    if (Ibm_ReadBytes(4, handle, base, (genptr)data)) {
	assert(offset+length <= 32);
	*valuePtr = Var_ExtractBits((genptr)data, offset, length, isSigned);
	return(TRUE);
    } else {
	return(FALSE);
    }
}


/***********************************************************************
 *				Var_StoreBits
 ***********************************************************************
 * SYNOPSIS:	    Store bits into a bitfield within a 32-bit integer
 * CALLED BY:	    GLOBAL
 * RETURN:	    TRUE if assignment successful
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/29/92		Initial Revision
 *
 ***********************************************************************/
Boolean
Var_StoreBits(Handle 	handle,
	      Address 	base,
	      int   	offset,
	      int   	length,
	      dword   	value)
{
    byte    	    data[4];

    if (Ibm_ReadBytes(4, handle, base, (genptr)data)) {
	assert(offset+length <= 32);
	Var_InsertBits((genptr)data, offset, length, value);
	return (Ibm_WriteBytes(4, (genptr)data, handle, base));
    } else {
	return(FALSE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Var_FetchInt --
 *	Fetch an integer of the given length from the patient at the
 *	patient's address. If it needs swapping, swap it. (Note this only
 *	assumes a complete byte-reversal, not any more-intricate swapping).
 *
 * Results:
 *	TRUE if the integer could be fetched and FALSE otherwise.
 *
 * Side Effects:
 *	The integer is read in from the patient and swapped as nec'y.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Var_FetchInt(int	size,
	     Handle 	handle,
	     Address	offset,
	     genptr 	swatAddress)
{
    register int  	i;
    register int  	j;
    register byte	temp;

    if (Ibm_ReadBytes(size, handle, offset, swatAddress)) {
	if (swap) {
	    byte    *cp = (byte *)swatAddress;

	    for (i = 0, j = size - 1; i < j; i++, j--) {
		temp = cp[i];
		cp[i] = cp[j];
		cp[j] = temp;
	    }
	}
	return(TRUE);
    } else {
	return(FALSE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Var_FetchAlloc --
 *	Fetch a value from the patient into our own data space and
 *	byte-swap it to match our own byte-ordering.
 *
 * Results:
 *	TRUE if the value could be fetched. Also, the address of the
 *	value in our own data space is stored in *swatAddressPtr. This
 *	value is dynamically-allocated and must be freed by the caller.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Var_FetchAlloc(Type	type,
	       Handle	handle,
	       Address	offset,
	       genptr	*swatAddressPtr)
{
    genptr 	  	swatAddress;

    swatAddress = (genptr)malloc_tagged((unsigned)Type_Sizeof(type),
					 TAG_VALUE);
    *swatAddressPtr = swatAddress;
    return(Var_Fetch(type, handle, offset, swatAddress));
}
/*-
 *-----------------------------------------------------------------------
 * Var_Fetch --
 *	Fetch a value from the patient into our own data space and
 *	byte-swap it to match our own byte-ordering.
 *
 * Results:
 *	TRUE if the value could be fetched. 
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Var_Fetch(Type 	    type,
	  Handle    handle,
	  Address   offset,
	  genptr    swatAddress)
{
    int	    size = Type_Sizeof(type);

    switch(Type_Class(type)) {
	case TYPE_RANGE:
	case TYPE_ENUM:
	case TYPE_POINTER:
	case TYPE_INT:
	case TYPE_UNION:
	case TYPE_CHAR:
	case TYPE_STRUCT:
	case TYPE_ARRAY:
	case TYPE_FLOAT:
	    if (!Ibm_ReadBytes(size, handle, offset, swatAddress))
	    {
		return(FALSE);
	    } else if (swap) {
		Var_SwapValue(VAR_FETCH, type, size, swatAddress);
	    }
	    return(TRUE);
	case TYPE_BITFIELD:
	{
	    unsigned	boffset, bwidth;
	    Type    	bType;
	    dword    	value;

	    bzero(swatAddress, size);

	    Type_GetBitFieldData(type, &boffset, &bwidth, &bType);
	    
	    if (!Var_FetchBits(handle, offset, boffset, bwidth, 
			       Type_IsSigned(bType),
			       &value))
	    {
		return(FALSE);
	    } else {
		byte	*bp;
		
		/*
		 * Now copy the bytes in our native order into the passed
		 * buffer.
		 */
		bp = (byte *)&value;
		if (swap) {
		    /*
		     * big-endian: drop most-sigificant bytes...
		     */
		    bp += sizeof(dword)-size;
		}
		bcopy(bp, swatAddress, size);
	    }
	    return(TRUE);
	}
	case TYPE_VOID:
	    Warning("Var_Fetch: fetching VOID?");
	    return(FALSE);
	case TYPE_FUNCTION:
	    Warning("Var_Fetch: fetching FUNCTION?");
	    return(FALSE);
	case TYPE_EXTERNAL:
	    Warning("Var_Fetch: fetching EXTERNAL?");
	    return(FALSE);
	default:
	    Warning("Var_Fetch: fetching UNKNOWN?");
	    return(FALSE);
    }
}
    
/*-
 *-----------------------------------------------------------------------
 * Var_StoreInt --
 *	Store an integer of the given length to the patient at the
 *	patient's address. If it needs swapping, swap it. (Note this only
 *	assumes a complete byte-reversal, not any more-intricate swapping).
 *
 * Results:
 *	TRUE if the integer could be written and FALSE otherwise.
 *
 * Side Effects:
 *	The integer is swapped IN PLACE and written to the patient.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Var_StoreInt(int	size,
	     int	integer,
	     Handle 	handle,
	     Address	offset)
{
    register genptr	swatAddress;
    int	    	    	one = 1;

    swatAddress = (genptr)&integer;
    /*
     * If we're on a big endian machine (may they all rot), we need to offset
     * the address of the integer so we're actually pointing at the part in which
     * we're interested.
     */
    if (*(char *)&one == 0) {
	swatAddress += sizeof(int) - size;
    }
    
    if (swap) {
	register char	temp;
	char *cp = (char *)swatAddress;
	int i, j;

	for (i = 0, j = size - 1; i < j; i++, j--) {
	    temp = cp[i];
	    cp[i] = cp[j];
	    cp[j] = temp;
	}
    }
    return (Ibm_WriteBytes(size, swatAddress, handle, offset));
}

/*-
 *-----------------------------------------------------------------------
 * Var_Store --
 *	Store a piece of data in the given type into the patient at
 *	the appropriate address after byte-swapping it in-place.
 *
 * Results:
 *	TRUE if the data could be stored.
 *
 * Side Effects:
 *	The data may be byte-swapped.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Var_Store(Type	    type,
	  genptr    swatAddress,
	  Handle    handle,
	  Address   offset)
{
    int	    	  	size;

    size = Type_Sizeof(type);
    
    switch(Type_Class(type)) {
	case TYPE_RANGE:
	case TYPE_ENUM:
	case TYPE_POINTER:
	case TYPE_INT:
	case TYPE_UNION:
	case TYPE_CHAR:
	case TYPE_STRUCT:
	case TYPE_ARRAY:
	case TYPE_FLOAT:
	    if (swap) {
		Var_SwapValue(VAR_STORE, type, size, swatAddress);
	    }
	    return (Ibm_WriteBytes(size, swatAddress, handle, offset));
	case TYPE_VOID:
	    Warning("Var_Store: storing VOID?");
	    return(FALSE);
	case TYPE_FUNCTION:
	    Warning("Var_Store: storing FUNCTION?");
	    return(FALSE);
	case TYPE_EXTERNAL:
	    Warning("Var_Store: storing EXTERNAL?");
	    return(FALSE);
	case TYPE_BITFIELD:
	{
	    unsigned	boffset, length;
	    byte    	*bp = (byte *)swatAddress;
	    dword   	value;

	    Type_GetBitFieldData(type, &boffset, &length, (Type *)NULL);

	    switch(size) {
		case 1:
		    value = *bp;
		    break;
		case 2:
		    if (swap) {
			value = bp[1] | (bp[0] << 8);
		    } else {
			value = bp[0] | (bp[1] << 8);
		    }
		    break;
		case 3:
		    if (swap) {
			value = bp[2] | (bp[1] << 8) | (bp[0] << 16);
		    } else {
			value = bp[0] | (bp[1] << 8) | (bp[2] << 16);
		    }
		    break;
		case 4:
		    if (swap) {
			value = bp[3] | (bp[2] << 8) | (bp[1] << 16) |
			    (bp[0] << 24);
		    } else {
			value = bp[0] | (bp[1] << 8) | (bp[2] << 16) |
			    (bp[3] << 24);
		    }
		    break;
		default:
		    Warning("Var_Store: bitfield larger than 4 bytes?");
		    return(FALSE);
	    }
	    return (Var_StoreBits(handle, offset, boffset, length, value));
	}
	default:
	    Warning("Var_Store: storing UNKNOWN?");
	    return(FALSE);
    }
}

	
/*-
 *-----------------------------------------------------------------------
 * Var_Cast --
 *	Cast from one type of value to another. Note we depend on the
 *	compiler to perform appropriate sign extensions. Note also that
 *	we use our own types for the various types in the patient on the
 *	assumption that Var_Fetch and Var_Store will perform appropriate
 *	conversions.
 *	XXX: There are various bogus aspects to this process. Mostly,
 *	we use our own representations for the conversions, yet we allocate
 *	the space based on the representation in the patient. If these are
 *	ever allowed to be different, we're dead meat.
 *
 * Results:
 *	The address of the new dynamically-allocated value.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
genptr
Var_Cast(genptr     data,
	 Type	    srcType,
	 Type	    dstType)
{
    genptr 	  	newData;
    int	    	  	newSize;
    int			oldSize;
    int			i;
    int			one=1;

#define BIGENDIAN() (*(char *)&one == 0)

    newSize = Type_Sizeof(dstType);
    oldSize = Type_Sizeof(srcType);
    
    newData = (genptr)calloc_tagged(1, newSize, TAG_VALUE);

    switch (Type_Class(srcType)) {
	case TYPE_CHAR: {
	    /*
	     * Source type is a character, thus data is a char *. First
	     * extract the character into C and switch on the type to which
	     * it is to be cast.
	     */
	    char C = *(char *)data;
	    
	    switch(Type_Class(dstType)) {
		case TYPE_CHAR:
		    /*
		     * No cast really nec'y, but copy the datum anyway
		     */
		    *(char *)newData = C;
		    break;
		case TYPE_POINTER:
		    /*
		     * Cast to a pointer causes sign extension.
		     */
		    if (oldSize == newSize) {
		    	*(char **)newData = (char *)C;
		    } else {
			memset(newData, '\0', newSize);
		    }
		    break;
		case TYPE_ENUM: {
		    /*
		     * An enum is like a subrange except it has a different
		     * accessor function to get the permissible values.
		     * XXX: What about sparse enums?
		     */
		    int	    top, bot;

		    Type_GetEnumData(dstType, &bot, &top);

		    if (C < bot) {
			C = bot;
		    }
		    if (C > top) {
			C = top;
		    }
		    goto cast_char_to_int;
		}
		case TYPE_RANGE: {
		    /*
		     * A subrange. We assume the range is of integers. This
		     * may not be true in the future. Anyway, make sure the
		     * character is within bounds, then assign it to the
		     * destination as for integers.
		     */
		    int	    top, bot;

		    Type_GetRangeData(dstType, &bot, &top, (Type *)NULL);
		    if (C < bot) {
			C = bot;
		    }
		    if (C > top) {
			C = top;
		    }
		    /*FALLTHRU*/
		}
		case TYPE_INT:
		    /*
		     * Casting to some type of integer. First we need to 
		     * figure out the appropriate type in our world to which
		     * to cast the character by comparing the destination type
		     * with the predefined integer types. If the destination
		     * is none of these types, we must perform any sign
		     * extension ourselves, placing the character in the
		     * appropriate byte of the destination based on our own
		     * byte-order.
		     */
		cast_char_to_int:
		    
		    if (Type_Equal(dstType, type_Int)) {
			assert(Type_Sizeof(type_Int) == 2);
			*(short *)newData = C;
		    } else if (Type_Equal(dstType, type_Short)) {
			*(short *)newData = C;
		    } else if (Type_Equal(dstType, type_Long)) {
			*(long *)newData = C;
		    } else if (Type_Equal(dstType, type_UnsignedInt)) {
			assert(Type_Sizeof(type_UnsignedInt) == 2);
			*(unsigned short *)newData = C;
		    } else if (Type_Equal(dstType,type_UnsignedShort)) {
			*(unsigned short *)newData = C;
		    } else if (Type_Equal(dstType, type_UnsignedLong)) {
			*(unsigned long *)newData = C;
		    } else if (BIGENDIAN()) {
			/*
			 * First place byte in highest-addressed byte of
			 * destination, then sign extend.
			 */
			((char *)newData)[newSize - 1] = C;
			if ((C & 0x80) && Type_IsSigned(dstType)) {
			    /*
			     * C was negative -- fill higher-order (lower-
			     * address) bytes with 0xff to sign extend.
			     */
			    for (i = 0; i < newSize - 1; i++) {
				((char *)newData)[i] = 0xff;
			    }
			}
		    } else {
			/*
			 * First place byte in lowest-addressed byte of
			 * destination, then sign extend.
			 */
			*(char *)newData = C;
			if ((C & 0x80) && Type_IsSigned(dstType)) {
			    /*
			     * C is negative -- fill higher-order (higher-
			     * address) bytes with 0xff to sign extend
			     */
			    for (i = 1; i < newSize; i++) {
				((char *)newData)[i] = 0xff;
			    }
			}
		    }
		    break;
		case TYPE_FLOAT:
		    /*
		     * Cast to a floating-point value.
		     */
		    if (Type_Equal(dstType, type_LongDouble)) {
			*(long double *)newData = C;
		    } else if (Type_Equal(dstType, type_Double)) {
			*(double *)newData = C;
		    } else if (Type_Equal(dstType, type_Float)) {
			*(float *)newData = C;
		    } else {
			Warning("Casting to unknown FLOAT type");
		    }
	    }
	    break;
	}
	case TYPE_ENUM:
	case TYPE_RANGE:
	case TYPE_INT: {
	    /*
	     * Casting from an int. First fetch the value itself as an
	     * unsigned long (the greatest common denominator), then figure
	     * out to what we are casting it. There should be no sign-
	     * extension problems here, as the things are supposed to be
	     * promoted to "long" before being changed to "unsigned", according
	     * to K&R, that is...
	     */
	    unsigned long   UL;

	    if (Type_Equal(srcType, type_Int)) {
		assert(Type_Sizeof(type_Int) == 2);
		UL = *(short *)data;
	    } else if (Type_Equal(srcType, type_Short)) {
		UL = *(short *)data;
	    } else if (Type_Equal(srcType, type_Long)) {
		UL = *(long *)data;
	    } else if (Type_Equal(srcType, type_UnsignedInt)) {
		assert(Type_Sizeof(type_UnsignedInt) == 2);
		UL = *(unsigned short *)data;
	    } else if (Type_Equal(srcType, type_UnsignedShort)) {
		UL = *(unsigned short *)data;
	    } else if (Type_Equal(srcType, type_UnsignedLong) ||
		       (oldSize == sizeof(UL)))
	    {
		UL = *(unsigned long *)data;
	    } else if (BIGENDIAN()) {
		UL = 0;
		if (oldSize < sizeof(UL)) {
		    bcopy(data, (char *)&UL + sizeof(UL) - oldSize, oldSize);
		} else {
		    Warning("Cannot cast from int larger than unsigned long");
		    break;
		}
	    } else if (oldSize < sizeof(UL)) {
		UL = 0;
		bcopy(data, (char *)&UL, oldSize);
	    } else {
		Warning("Cannot cast from int larger than unsigned long");
		break;
	    }
	    
	    switch (Type_Class(dstType)) {
		case TYPE_CHAR:
		    *(char *)newData = UL;
		    break;
		case TYPE_ENUM:
		case TYPE_RANGE:
		case TYPE_INT:
		    /*
		     * Make compiler do the conversions for us...
		     */
		    if (Type_Equal(dstType, type_Int)) {
			assert(Type_Sizeof(type_Int) == 2);
			*(short *)newData = UL;
		    } else if (Type_Equal(dstType, type_Short)) {
			*(short *)newData = UL;
		    } else if (Type_Equal(dstType, type_Long)) {
			*(long *)newData = UL;
		    } else if (Type_Equal(dstType, type_UnsignedInt)) {
			assert(Type_Sizeof(type_UnsignedInt) == 2);
			*(unsigned short *)newData = UL;
		    } else if (Type_Equal(dstType, type_UnsignedShort)){
			*(unsigned short *)newData = UL;
		    } else if (Type_Equal(dstType, type_UnsignedLong)){
			*(unsigned long *)newData = UL;
		    } else if (BIGENDIAN()) {
			bcopy((char *)&UL + sizeof(UL) - newSize,
			      newData,
			      newSize);
		    } else {
			bcopy((char *)&UL, newData, newSize);
		    }
		    break;
		case TYPE_POINTER:
		    if (oldSize == newSize) 
		    {
			int	    ptype;
			Type        btype;

			Type_GetPointerData(dstType, &ptype, &btype);
			switch (ptype)
			{ 
			    case TYPE_PTR_HANDLE:
		    	    	*(void **)newData = Handle_Lookup((word)UL);
				break;
			    case TYPE_PTR_NEAR:
				*(void **)newData = 0;
				break;
			}
		    } else {
			memset(newData, '\0', newSize);
		    }
/*		    *(void **)newData = (void *)UL;*/
		    break;
		case TYPE_FLOAT:
		    if (Type_Equal(dstType, type_LongDouble)) {
			if (Type_IsSigned(srcType)) {
			    *(long double *)newData = (long)UL;
			} else {
			    *(long double *)newData = UL;
			}
		    } else if (Type_Equal(dstType, type_Double)) {
			if (Type_IsSigned(srcType)) {
			    *(double *)newData = (long)UL;
			} else {
			    *(double *)newData = UL;
			}
		    } else if (Type_Equal(dstType, type_Float)) {
			if (Type_IsSigned(srcType)) {
			    *(float *)newData = (long)UL;
			} else {
			    *(float *)newData = UL;
			}
		    } else {
			Warning("Casting to unknown FLOAT type");
		    }
		    break;
	    }
	    break;
	}
	case TYPE_POINTER: {
	    assert (0);
#if 0
	    void  	*P = *(void **)data;

	    switch (Type_Class(dstType)) {
		case TYPE_CHAR:
		    *(char *)newData = (char)P;
		    break;
		case TYPE_INT:
		    if (Type_Equal(dstType, type_Int)) {
			*(int *)newData = (int)P;
		    } else if (Type_Equal(dstType, type_Short)) {
			*(short *)newData = (short)P;
		    } else if (Type_Equal(dstType, type_Long)) {
			*(long *)newData = (long)P;
		    } else if (Type_Equal(dstType, type_UnsignedInt)) {
			*(unsigned int *)newData = (unsigned int)P;
		    } else if (Type_Equal(dstType, type_UnsignedShort)){
			*(unsigned short *)newData = (unsigned short)P;
		    } else if (Type_Equal(dstType, type_UnsignedLong)) {
			*(unsigned long *)newData = (unsigned long)P;
		    } else if (BIGENDIAN()) {
			bcopy((char *)&P + sizeof(P) - newSize,
			      newData,
			      newSize);
		    } else {
			bcopy((char *)&P, newData, newSize);
		    }
		    break;
		case TYPE_ENUM: {
		    /*
		     * Force the pointer to be within the bounds of the
		     * enumerated type, then assign it as an integer.
		     */
		    int	    top, bot;
		    int	    I = (int)P;
		    
		    Type_GetEnumData(dstType, &bot, &top);
		    
		    if (I < bot) {
			I = bot;
		    }
		    if (I > top) {
			I = top;
		    }
		    *(int *)newData = I;
		    break;
		}
		case TYPE_RANGE: {
		    int top, bot;
		    int I = (int)P;

		    /*
		     * XXX: Check base type
		     */
		    Type_GetRangeData(dstType, &bot, &top, (Type *)NULL);
		    if (I < bot) {
			I = bot;
		    }
		    if (I > top) {
			I = top;
		    }
		    
		    if (newSize == sizeof(unsigned long)) {
			*(unsigned long *)newData = I;
		    } else if (newSize == sizeof(unsigned short)) {
			*(unsigned short *)newData = I;
		    }
		    break;
		}
		case TYPE_POINTER:
		    /*
		     * A pointer is a pointer is a pointer...
		     */
		    *(void **)newData = P;
		    break;
	    }
#endif
	    break;
	}
	case TYPE_FLOAT: {
	    long double	D;

	    if (Type_Equal(srcType, type_LongDouble)) {
		D = *(long double *)data;
	    } else if (Type_Equal(srcType, type_Double)) {
		D = *(double *)data;
	    } else if (Type_Equal(srcType, type_Float)) {
		D = *(float *)data;
	    } else {
		Warning("Var_Cast: unknown floating point type");
		return(FALSE);
	    }

	    switch(Type_Class(dstType)) {
		case TYPE_ENUM:
		case TYPE_RANGE:
		case TYPE_INT:
		    if (Type_Equal(dstType, type_Int)) {
			assert(Type_Sizeof(type_Int) == 2);
			*(short *)newData = (int)D;
		    } else if (Type_Equal(dstType, type_Short)) {
			*(short *)newData = (short)D;
		    } else if (Type_Equal(dstType, type_Long)) {
			*(long *)newData = (long)D;
		    } else if (Type_Equal(dstType, type_UnsignedInt)) {
			assert(Type_Sizeof(type_UnsignedInt) == 2);
			*(unsigned short *)newData = (unsigned int)D;
		    } else if (Type_Equal(dstType, type_UnsignedShort)){
			*(unsigned short *)newData = (unsigned short)D;
		    } else if (Type_Equal(dstType, type_UnsignedLong)) {
			*(unsigned long *)newData = (unsigned long)D;
		    } else if (BIGENDIAN()) {
			long 	I = (long)D;
			
			bcopy((char *)&I + sizeof(I) - newSize,
			      newData,
			      newSize);
		    } else {
			long 	I = (long)D;
			
			bcopy((char *)&I, newData, newSize);
		    }
		    break;
		case TYPE_POINTER:
		    assert(0);
/*		    *(void **)newData = (void *)(int)D;*/
		    break;
		case TYPE_CHAR:
		    *(char *)newData = (char)D;
		    break;
		case TYPE_FLOAT:
		    if (Type_Equal(dstType, type_LongDouble)) {
			*(long double *)newData = (long double)D;
		    } else if (Type_Equal(dstType, type_Double)) {
			*(double *)newData = (double)D;
		    } else if (Type_Equal(dstType, type_Float)) {
			*(float *)newData = (float)D;
		    }
		    break;
	    }
	    break;
	}
    }

    return(newData);
}
