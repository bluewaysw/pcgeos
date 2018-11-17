/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Dynamically sized table management.
 * FILE:	  table.h
 *
 * AUTHOR:  	  Adam de Boor: Mar  9, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/ 9/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for use of the Table module. A Table is simply an
 *	efficient (I hope) way to store many pieces of identically-sized
 *	data. It is used, e.g., for holding Symbol's and code. The table
 *	extends as necessary to hold all its components.
 *
 *
 * 	$Id: table.h,v 1.9 91/04/26 12:28:17 adam Exp $
 *
 ***********************************************************************/
#ifndef _TABLE_H_
#define _TABLE_H_

#include    <stdio.h>

typedef void	*Table;

/*
 * Structure for use with Table_EnumFirst and Table_EnumNext
 */
typedef struct {
    Table   	table;
    int	    	num;
    void    	*chunk;
    void    	*next;
}	Table_Enum;

/*
 * Create a table whose elements are eltSize bytes long. Each piece of the
 * table originally contains eltsPerChunk pieces of eltSize bytes.
 */
extern Table	Table_Init(int eltSize, int eltsPerChunk);
/*
 * Delete numElts elements from the table starting with element pos (0-origin)
 */
extern void 	Table_Delete(Table table, int pos, int numElts);
/*
 * Insert numElts blank elements before element pos.
 */
extern void 	Table_Insert(Table table, int pos, int numElts);
/*
 * Return the number of elements stored in the table.
 */
extern int  	Table_Size(Table table);
/*
 * Write all elements into the given VM block in the output file.
 */
extern int  	Table_Write(Table table, VMBlockHandle block);
/*
 * Store the given elements into the table starting at the indicated position.
 * If the table isn't that long, nothing is stored and NULL is returned. Over-
 * writes anything already there. Returns the address of first stored
 * element. As long as no elements are inserted or deleted, this address
 * will remain valid. If pos is TABLE_END, the elements are added to the
 * current end of the table. This is the only way other than Table_Insert
 * to extend the table.
 */
#define TABLE_END   -1
extern void 	*Table_Store(Table table, int numElts, void *eltPtr, int pos);
extern void 	*Table_StoreZeroes(Table table, int numElts, int pos);
/*
 * Extract elements from a table.
 */
extern void 	Table_Fetch(Table table, int numElts, void *eltPtr, int pos);
/*
 * Look up the position of element pos in the table.
 */
extern void 	*Table_Lookup(Table table, int pos);
/*
 * Begin enumerating the elements of a table
 */
extern void 	*Table_EnumFirst(Table table, Table_Enum *te);
/*
 * Continue enumerating the elements of a table
 */
extern void 	*Table_EnumNext(Table_Enum *te);

#endif /* _TABLE_H_ */
