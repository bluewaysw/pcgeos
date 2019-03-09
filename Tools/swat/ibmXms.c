/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PCGEOS
MODULE:		swat - patient dependent module- profile
FILE:		ibmXms.c

AUTHOR:		Ian Porteous, Oct 19, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/19/94   	Initial version.

DESCRIPTION:
	

	$Id: ibmXms.c,v 1.6 97/04/18 16:05:04 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef lint
static char *rcsid =
"$Id: ibmXms.c,v 1.6 97/04/18 16:05:04 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cache.h"
#include "cmd.h"
#include "ibmInt.h"
#include "rpc.h"
#include "ui.h"
#include "type.h"
#include "var.h"
#include "value.h"
#include <compat/stdlib.h>
#include <compat/file.h>


/***********************************************************************
 *				IbmXmsRead
 ***********************************************************************
 * SYNOPSIS:	    Call the swat stub to read from xms memory
 * CALLED BY:	    
 * RETURN:	    data read if successful
 *                  NULL if not successful
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	IP	10/18/94   	Initial Revision
 *
 ***********************************************************************/

Boolean IbmXmsRead (unsigned long size, unsigned short xmsHandle, \
	    unsigned long xmsOffset, unsigned short xmsAddrOffset, byte *rdata)
{
    struct     ReadXmsMemArgs ra; 

    /* 
     * the size of the transfer must be word aligned
     */
    ra.RXMA_size         = size;
    ra.RXMA_sourceHandle = xmsHandle;
    ra.RXMA_sourceOffset = xmsOffset;

    /*
     * This is the offset of the variable xmsAddr in the dgroup of the kernel.
     * xmsAddr contains the address of the function to access xms memory.
     */
    ra.RXMA_procOffset   = xmsAddrOffset;
	
    if (Rpc_Call(RPC_READ_XMS_MEM, sizeof(ra), typeReadXmsMemArgs, &ra,
		 size, NullType, (Opaque)rdata) != RPC_SUCCESS)
	return FALSE;
    else
	return TRUE;
    
}	/* End of IbmXmsRead.	*/



/***********************************************************************
 *				IbmXmsReadCmd
 ***********************************************************************
 * SYNOPSIS:	    Control the data caching parameters
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Probably.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	IP	10/13/94	Initial Revision
 *
 ***********************************************************************/
DEFCMD(xmsread,IbmXmsRead,TCL_EXACT,0,swat_prog,
"Usage:\n\
    xmsread <xms handle>, <xms nextHandle>, <xms offset>, <sizeOfXmsPage, \n\
            <xmsAddr offset>, <type>, <size>\n\
")
{
    byte   *rdata;
    unsigned long   offset, sizeOfXmsPage;
    unsigned short  handle, xmsAddrOffset, size;
    Type    type;
    Boolean success;

    handle = atoi(argv[1]);
    offset = atol(argv[3]);
    sizeOfXmsPage = atol(argv[4]);
    xmsAddrOffset = atoi(argv[5]);
    size = atoi(argv[7]);

    if (argc >= 7) {
	/*
	 * first get the size of the entry
	 */
	size += (size % 2);
	rdata = (byte *)malloc(sizeof(byte)*size);
	/*
	 * It is possible that the entry crosses the boundary between xms 
	 * page boundaries.  So deal with it, if it occurs.
	 */
	if ((size + xmsAddrOffset) < sizeOfXmsPage) {
	    success = IbmXmsRead(size,handle,offset,xmsAddrOffset,rdata);
	} else {
	    int bytesLeftOnPage;

	    bytesLeftOnPage = sizeOfXmsPage - xmsAddrOffset;
	    success = IbmXmsRead(bytesLeftOnPage,handle,offset,xmsAddrOffset, rdata);
	    success = IbmXmsRead(size - bytesLeftOnPage,handle,offset,xmsAddrOffset, \
		       rdata+bytesLeftOnPage);
	}
	if (success) {
	    type = Type_ToToken(argv[6]);
	    if (swap) {
		Var_SwapValue(VAR_FETCH,type,size,rdata);
	    }
	    Tcl_Return(interp, Value_ConvertToString(type, (Opaque)rdata),
		       TCL_DYNAMIC);
	} else {
	    Tcl_RetPrintf(interp, "done", TCL_DYNAMIC);
	}
	free(rdata);
    } else {
	Tcl_RetPrintf(interp, "done", TCL_DYNAMIC);
    }
    return(TCL_OK);	
}


/***********************************************************************
 *				IbmXms_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize profile commands
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ian	10/19/94	Initial Revision
 *
 ***********************************************************************/
void
IbmXms_Init(void)
{
    Cmd_Create(&IbmXmsReadCmdRec);
}    
