/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	GEOS Tools
* 	MODULE:							     
* 	FILE:		findlbdr.c				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	8/21/92		Initial version			     
*	mgroeb  5/21/00		Support for multiple products
*
*	DESCRIPTION: greps for driver and library directives
*	    	     in .gp files for the sake of depdencies
*								     
*	$Id: findlbdr.c,v 1.3 92/09/29 11:05:23 jimmy Exp $		     
*							   	     
*********************************************************************/

#include <config.h>

#include <stdio.h>
#include <compat/string.h>
#include <stdlib.h>
#include <ctype.h>
#include <direct.h>


/***********************************************************************
 *				ScanForGPDepends
 ***********************************************************************
 * SYNOPSIS:	    Look through a file for library and driver directives
 *
 * CALLED BY:	    main
 * RETURN:	    void
 * SIDE EFFCTS:     stuff outputed to .gp file
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/19/92		Initial Revision
 *
 ***********************************************************************/
static void
ScanForGPDepends(FILE *gp, FILE *depends)
{
    char      c;
    char      buf[128];
    char     *cp;

    /*
     * set the pointer to the end of the depends file, we will add the
     * new line at the bottom
     */
    while ((c = (char) getc(gp)) != EOF) {
	/*
	 * Skip to the first word of the line.
	 */
	while (isspace(c)) {
	    c = (char) getc(gp);
	}

	/*
	 * Read the first word of the line into buf.
	 */
	cp = buf;
	while (!isspace(c) && cp != &buf[sizeof(buf)-1]) {
	    *cp++ = c;
	    c     = (char) getc(gp);
	    if (c == EOF) {
		break;
	    }
	}
	*cp = '\0';

	if (strcmp(buf, "library") == 0 || strcmp(buf, "driver") == 0) {
	    /*
	     * First word is library or driver. Skip to the next word,
	     * which is the library or driver to be included.
	     */
	    while (isspace(c)) {
		c = (char) getc(gp);
		if (c == EOF) {
		    break;
		}
	    }
	    /*
	     * Add an ldf to the library/driver and write it to the file
	     */
	    cp = buf;
	    while (!isspace(c) && c != ';' && cp != &buf[sizeof(buf)-1]) {
		*cp++ = (char) /*toupper*/(c);
		c     = (char) getc(gp);
		if (c == EOF) {
			break;
		}
	    }
	    strcpy(cp, ".ldf ");
	    /*
	     * Since strlen does not count the null, it is not output
	     * to the file, which is what we want.
	     */
	    fwrite(buf, 1, strlen(buf), depends);
	}
	/*
	 * Skip to the end of the line or the end of the file, whichever
	 * comes first.
	 */
	while ((c != EOF) && (c != '\n')) {
	    c = (char) getc(gp);
	}
    }
}


/*********************************************************************
 *			main
 *********************************************************************
 * SYNOPSIS:         Add library and driver depends to a depends file
 *
 * CALLED BY:	     pmake
 * RETURN:           nothing
 * SIDE EFFECTS:     Line added to depends.mk file
 * STRATEGY:         
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------
 *	jimmy	8/21/92		Initial version			     
 *      TB      8/26/96         WIN32 Port
 *
 *********************************************************************/
void
main(int argc, char **argv)
{
    FILE *gp;
    FILE *depends;
    int	i;
    char product[256], *p;

    if (argc < 4) {
	fprintf(stderr, 
		"Usage: findlbdr <gpfile> <depends file> <targets>+\n");
	exit(1);
    }

    /*
     * Open .gp file.
     */
    gp = fopen(argv[1], "rt");
    if (gp == NULL) {
	fprintf(stderr, "findlbdr: ");
	perror(argv[1]);
	exit(1);
    }

    /*
     * Isolate relative pathname from .MK file and use it for
     * targets as well (for product-specific dependency files).
     */
    strcpy(product, argv[2]);
    p = strrchr(product, '/');
    if(!p) p = strrchr(product, '\\');
    if(p)
      *p = 0;
    else
      *product = 0;

    /*
     * Open depends file, so we can append lines to it.
     */
    depends = fopen(argv[2], "at");
    if (depends == NULL) {
	fprintf(stderr, "findlbdr: \"%s\": ", argv[2]);
	perror("");
	exit(1);
    }
    fseek(depends, 0L, SEEK_END);
    fputc('\n', depends);

    /*
     * The rest of the args should contain targets, so output those
     * to the file.
     */
    for (i = 3; i < argc; i++) {
        if(*product) {
          fwrite(product, 1, strlen(product), depends);
          fwrite("/", 1, 1, depends);
        }
        fwrite(argv[i], 1, strlen(argv[i]), depends);
	fputc(' ', depends);
    }

    fwrite(": ", 1, 2, depends);
    ScanForGPDepends(gp, depends);

    fclose(gp);
    fclose(depends);
    exit(0);
}
