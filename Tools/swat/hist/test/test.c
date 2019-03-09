/*
 *    			RCS Control Information:
 *    $Author: wbaker $				
 *    $Date: 85/04/07 01:32:46 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /c/staff/wbaker/exp/src/lib/hist/test/test.c,v $
 *    $State: Exp $
 */
#include <stdio.h>

#include "hist.h"

main()
{
	char *ret;
	HIQUEUE *hq;

	if ((hq = hiQinit(100)) == NULL) {
	    printf("we have a problem here\n");
	    exit (0);
	}

	while (hiFGets(&ret, hq, stdin) != HI_EOF) {
	    if (hiErrno != HI_NOERROR)
		hiFError("error", stdout);
	    else
		puts(ret);
	}
}
