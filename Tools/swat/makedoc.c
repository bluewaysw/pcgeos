/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- Documentation extractor
 * FILE:	  makedoc.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 12, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/12/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	An auxiliary program to extract documentation strings and classes
 *	from .tcl and .c files for use by the help system.
 *
 *	The output has entries of the form
 *	    \177\ntopic.class\nstring-len:string\n
 *	string-len is the length of the string converted to ascii.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: makedoc.c,v 4.9 97/04/18 16:11:43 dbaumann Exp $";
#endif lint

#include <config.h>

#include "swat.h"
#include <stdio.h>
#include <ctype.h>
#include <compat/file.h>
#include <fileUtil.h>
  
char	    *docString = NULL;	/* Space for doc string. Expands to be
				 * largest of all doc strings. */
int	    docSize = 0;    	/* Size of docString currently */


/***********************************************************************
 *				ScanTclFile
 ***********************************************************************
 * SYNOPSIS:	    Look through a .tcl file for defcommand, defdsubr and
 *	    	    defvar commands, printing their documentation to
 *		    stdout in the proper format.
 * CALLED BY:	    main.
 * RETURN:	    0 on error.
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
int
ScanTclFile(char    *file)
{
    FileType   	f;
	
    int	    	line = 1;
    int         returnCode = FALSE;
    int	        c;

    returnCode = FileUtil_Open(&f, file, O_RDONLY|O_TEXT, SH_DENYWR, 0);
    if (returnCode == FALSE) {
	perror(file);
	return (0);
    }

    /*
     * This thing recognizes the following constructs:
     *
     *	\n[defcommand <name> {<args>} <class>\n{<doc>}
     *	\n[defdsubr <name> {<args>} <class>\n{<doc>}
     *	\n[defvar <name> <val> <class>\n{<doc>}
     *
     * <doc> should be in proper list format (i.e. any curly-braces
     * appropriately escaped). Note that to create an undocumented
     * variable, you should not enclose the defvar in brackets.
     */
    do {
	int 	    skipArgs=1;
	
	if ((c = FileUtil_Getc(f)) == '[' &&
	    (c = FileUtil_Getc(f)) == 'd' &&
	    (c = FileUtil_Getc(f)) == 'e' &&
	    (c = FileUtil_Getc(f)) == 'f')
	{
	    
	    switch(FileUtil_Getc(f)) {
	    case 'c':
		switch (FileUtil_Getc(f)) {
		    case 'm':
			if ((c = FileUtil_Getc(f)) != 'd' ||
			    ((c = FileUtil_Getc(f)) != ' ' &&
			     (c != '\t')))
			{
			    goto skip_line;
			}
			break;
		    case 'o':
			if ((c = FileUtil_Getc(f)) != 'm' ||
			    (c = FileUtil_Getc(f)) != 'm' || (c = FileUtil_Getc(f)) != 'a' ||
			    (c = FileUtil_Getc(f)) != 'n' || (c = FileUtil_Getc(f)) != 'd' ||
			    ((c = FileUtil_Getc(f)) != ' ' &&
			     c != '\t'))
			{
			    goto skip_line;
			}
			break;
		    default:
			goto skip_line;
		}
		break;
	    case 'v':
		if ((c = FileUtil_Getc(f)) != 'a' || (c = FileUtil_Getc(f)) != 'r' ||
		    ((c = FileUtil_Getc(f)) != ' ' && c != '\t'))
		{
		    goto skip_line;
		}
		break;
	    case 'h':
		if ((c = FileUtil_Getc(f)) != 'e' || (c = FileUtil_Getc(f)) != 'l' ||
		    (c = FileUtil_Getc(f)) != 'p' ||
		    ((c = FileUtil_Getc(f)) != ' ' && c != '\t'))
		{
		    goto skip_line;
		}
		skipArgs = 0;
		break;
	    default:
		goto skip_line;
	    }


	    /*
	     * Put out start-of-topic character.
	     */
	    putchar('\177');
	    /*
	     * Deal with strange people who put extra space between the command
	     * and the name.
	     */
	    while (isspace(c = FileUtil_Getc(f))) {
		;
	    }
	    /*
	     * Copy the name
	     */
	    do {
		if (c == EOF) {
		    fprintf(stderr, "file \"%s\", line %d: eof in name\n",
			    file, line);
		    return(0);
		}
		putchar(c);
	    } while (!isspace(c = FileUtil_Getc(f)));

	    /*
	     * Print class separator
	     */
	    putchar('.');
	    if (skipArgs) {
		/*
		 * Skip over the args/value
		 */
		switch(FileUtil_Getc(f)) {
		case '{':
		{
		    /*
		     * List format -- skip to matching close brace
		     */
		    int levels = 0;
		    
		    while (levels >= 0) {
			switch(FileUtil_Getc(f)) {
			case '\\':
			    FileUtil_Getc(f); /* Skip following character */
			    break;
			case '{':
			    levels++; /* Up nesting level */
			    break;
			case '}':
			    levels -= 1; /* Reduce nesting level */
			    break;
			case EOF:
			    fprintf(stderr,
				    "file \"%s\", line %d: eof in args/value\n",
				    file, line);
			    return(0);
			}
		    }
		    c = FileUtil_Getc(f);
		    break;
		}
		default:
		    /*
		     * Just skip a word
		     */
		    while (!isspace(c = FileUtil_Getc(f))) {
			if (c == EOF) {
			    fprintf(stderr,
				    "file \"%s\", line %d: eof in args/value\n",
				    file, line);
			    return(0);
			}
		    }
		    break;
		}
	    }
	    /*
	     * Skip over any space or newline between the arg list and the
	     * help class list
	     */
	    while (isspace(c)) {
		c = FileUtil_Getc(f);
	    }
		
	    /*
	     * Copy the class out
	     */
	    while (c != EOF && c != '\n') {
		putchar(c);
		c = FileUtil_Getc(f);
	    }
	    if (c == EOF) {
		fprintf(stderr, "file \"%s\", line %d: eof in class\n",
			file, line);
		return(0);
	    } else {
		line++;
	    }
	    if (FileUtil_Getc(f) != '{') {
		fprintf(stderr,
			"file \"%s\", line %d: doc doesn't begin with {\n",
			file, line);
		return(0);
	    } else {
		char    *cp;
		int 	len;
		int 	levels;

		cp = docString; len = 0; levels = 0;

		while (levels >= 0) {
		    switch(c = FileUtil_Getc(f)) {
		    case '\n':
			line++;
			break;
		    case '{':
			levels++;
			break;
		    case '}':
			if (--levels < 0) {
			    /*
			     * Don't store final }
			     */
			    continue;
			}
			break;
		    case '\\':
			if ((c = FileUtil_Getc(f)) == '\n') {
			    /*
			     * Ignore escaped newline
			     */
			    continue;
			} else {
			    *cp++ = '\\';
			    len++;
			    if (len == docSize) {
				docString = (char *)realloc(docString,
							    2 * docSize);
				cp = docString + docSize;
				docSize *= 2;
			    }
			}
			break;
		    }
		    /*
		     * Store the character away, resizing docString as nec'y
		     */
		    *cp++ = c;
		    len++;
		    if (len == docSize) {
			docString = (char *)realloc(docString,
						    2 * docSize);
			cp = docString + docSize;
			docSize *= 2;
		    }
		}
		*cp = '\0';
		printf("\n%d:%s\n", len, docString);
		/*
		 * Fall through to skip to the end of the line.
		 */
	    }
	}
    skip_line:
	while ((c != '\n') && (c != EOF)) {
	    c = FileUtil_Getc(f);
	}
	if (c == '\n') {
	    line++;
	}
    } while(c != EOF);
    (void)FileUtil_Close(f);
    return(1);
}
	    

/***********************************************************************
 *				ScanCFile
 ***********************************************************************
 * SYNOPSIS:	    Read through a .c file looking for DEFCMD declarations
 *	    	    and extracting the documentation from same.
 * CALLED BY:	    main
 * RETURN:	    0 if error.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
int
ScanCFile(char	*file)
{
    FileType    f; 
    int	    	line = 1;
    int         returnCode;
    int         c;

    returnCode = FileUtil_Open(&f, file, O_RDONLY|O_TEXT, SH_DENYWR, 0);
    if (returnCode == FALSE) {
	perror(file);
	return(0);
    }

    /*
     * This thing recognizes the following constructs:
     *
     *	\nDEFCMD(<name>, *<func>, *<flags> *, *<cmds>,<class>,\n"<doc>")
     *	\nDEFCMDNOPROC(<name>, *<func>, *<flags> *, *<cmds>,<class>,\n"<doc>")
     *
     * <doc> should be in proper string format (i.e. each line ends in an
     * escaped newline). When reading <doc>, the following escapes are
     * acted on: \(, \n, \", \\ and \t. Escaped newlines are deleted.
     */
    do {
	int 	    c2;
	
	if ((c = FileUtil_Getc(f)) == 'D' &&
	    (c = FileUtil_Getc(f)) == 'E' &&
	    (c = FileUtil_Getc(f)) == 'F' &&
	    (c = FileUtil_Getc(f)) == 'C' &&
	    (c = FileUtil_Getc(f)) == 'M' &&
	    (c = FileUtil_Getc(f)) == 'D' &&
	    (((c = FileUtil_Getc(f)) == '(') ||
	     (c == ' ' &&
	      (c2 = FileUtil_Getc(f)) == '(') ||
	     (c == 'N' &&
	      (c = FileUtil_Getc(f)) == 'O' &&
	      (c = FileUtil_Getc(f)) == 'P' &&
	      (c = FileUtil_Getc(f)) == 'R' &&
	      (c = FileUtil_Getc(f)) == 'O' &&
	      (c = FileUtil_Getc(f)) == 'C' &&
	      ((c = FileUtil_Getc(f)) == '(' ||
	       (c == ' ' &&
		(c2 = FileUtil_Getc(f)) == '(')))))
	{
	    int	    i;

	    /*
	     * Put out start-of-topic character.
	     */
	    putchar('\177');
	    /*
	     * Copy the name
	     */
	    while (!isspace(c = FileUtil_Getc(f)) && (c != ',')) {
		if (c == EOF) {
		    fprintf(stderr, "file \"%s\", line %d: eof in name\n",
			    file, line);
		    return(0);
		}
		putchar(c);
	    }
	    /*
	     * Print class separator
	     */
	    putchar('.');
	    /*
	     * Assume there's a list of possible topics and always place a
	     * left brace at the start of the class list. It can't hurt...
	     */
	    putchar('{');
	    
	    /*
	     * Skip over the function,flags and commands. If the name ended
	     * in a comma, we've only got to skip three commas, otherwise we've
	     * got to skip the end-of-name comma too (as we've not reached
	     * it yet).
	     */
	    i = (c == ',') ? 3 : 4;
	    while (i > 0) {
		if ((c = FileUtil_Getc(f)) == ',') {
		    i--;
		} else if (c == EOF) {
		    fprintf(stderr,
			    "file \"%s\", line %d: eof skipping to class\n",
			    file, line);
		    return(0);
		} else if (c == '\n') {
		    line++;	/* weirdness */
		}
	    }

	    /*
	     * Skip any leading space
	     */
	    while(isspace(c) && c != EOF) {
		if (c == '\n') {
		    line++;
		}
		c = FileUtil_Getc(f);
	    }
	    if (c == EOF) {
		fprintf(stderr, "file \"%s\", line %d: eof before class\n",
			file, line);
		return(0);
	    }
	    
	    /*
	     * Copy the class out
	     */
	    while ((c = FileUtil_Getc(f)) != ',' && c != EOF) {
		if (c == '|') {
		    c = ' ';
		}
		putchar(c);
	    }
	    if (c == EOF) {
		fprintf(stderr, "file \"%s\", line %d: eof in class\n",
			file, line);
		return(0);
	    }
	    /*
	     * Close the class list out.
	     */
	    putchar('}');
	    /*
	     * Skip following newline.
	     */
	    while ((c = FileUtil_Getc(f)) != '\n' && c != EOF) {
		;
	    }
	    if (c == EOF) {
		fprintf(stderr,
			"file \"%s\", line %d: eof before doc string\n",
			file, line);
		return(0);
	    } else {
		line++;
	    }
	    
	    if (FileUtil_Getc(f) != '"') {
		fprintf(stderr,
			"file \"%s\", line %d: doc doesn't begin with \"\n",
			file, line);
		return(0);
	    } else {
		char    *cp;
		int 	len;
		int 	done = 0;

		cp = docString; len = 0;

		while (!done) {
		    switch(c = FileUtil_Getc(f)) {
		    case '\n':
			line++;
			break;
		    case '"':
			done = 1;
			continue;
		    case '\\':
			switch(c = FileUtil_Getc(f)) {
			case '\n':
			    /*
			     * Ignore escaped newline
			     */
			    line++;
			    continue;
			case 'n':
			    c = '\n';
			    break;
			case 't':
			    c = '\t';
			    break;
			case '"':
			case '\\':
			case '(':
			    break;
			default:
			    *cp++ = '\\';
			    len++;
			    if (len == docSize) {
				docString = (char *)realloc(docString,
							    2 * docSize);
				cp = docString + docSize;
				docSize *= 2;
			    }
			}
			break;
		    }
		    /*
		     * Store the character away, resizing docString as nec'y
		     */
		    *cp++ = c;
		    len++;
		    if (len == docSize) {
			docString = (char *)realloc(docString,
						    2 * docSize);
			cp = docString + docSize;
			docSize *= 2;
		    }
		}
		*cp = '\0';
		printf("\n%d:%s\n", len, docString);
		/*
		 * Fall through to skip to the end of the line.
		 */
	    }
	}
	while ((c != '\n') && (c != EOF)) {
	    c = FileUtil_Getc(f);
	}
	if (c == '\n') {
	    line++;
	}
    } while(c != EOF);
    (void)FileUtil_Close(f);
    return(1);
}
	
volatile void
main(argc, argv)
    int	    argc;
    char    **argv;
{
    int	    i;
    extern volatile void exit(int);

    /*
     * Initialize space for document string
     */
    docSize = 128;
    docString = (char *)malloc(docSize);

    for (i = 1; i < argc; i++) {
	char	*cp = argv[i] + strlen(argv[i]);

	if (strcmp(cp-4, ".tcl") == 0) {
	    if (!ScanTclFile(argv[i])) {
		exit(1);
	    }
	} else {
	    if (!ScanCFile(argv[i])) {
		exit(1);
	    }
	}
    }
    exit(0);
}
    
/*
 * Local Variables:
 * compile-command: "gcc -o makedoc -g -O makedoc.c"
 * end:
 */
