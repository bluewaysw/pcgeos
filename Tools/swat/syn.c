/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- Documentation extractor
 * FILE:	  syn.c
 *
 * AUTHOR:  	  Roger Flores: Apr 24, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/24/91	  rsf	    Initial version
 *
 * DESCRIPTION:
 *	An auxiliary program to extract usage and synopsis documentation 
 *	strings from .tcl and .c files for use by the help system.
 *
 *	Syn reads one file and prints to stdout.
 *
 *	An example of the output is:
 *
 *	    bytes [<address>] [<length>]
 *	    	Examine memory as a dump of bytes and characters.
 *
 *	where the first part is from the non-blank lines which follow
 *	a line starting with ?"Usage:" and the second, indented part is
 *	from the non-blank lines after a line starting with "Synopsis:".
 *	The indentation is performed by syn.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: syn.c,v 1.10 97/04/18 16:48:35 dbaumann Exp $";
#endif lint

#include <config.h>
#include <stdio.h>
#include <ctype.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <malloc.h>

#define LINE_LENGTH 1024
#define EVER ;;

typedef struct _Topic {
    char    *lines;
    int	    textlen;
    int	    keylen;
} Topic;

Topic	**topics;
int	numTopics = 0;

char line[LINE_LENGTH];


/***********************************************************************
 *				CleanLine
 ***********************************************************************
 * SYNOPSIS:	    Nuke backslash escapes from a line, including the
 *		    final backslash that escapes the literal newline
 * CALLED BY:	    GatherUsage, GatherSyn
 * RETURN:	    line buffer appropriately modified.
 * SIDE EFFECTS:    see above
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	rsf	12/ 5/91	Initial Revision
 *
 ***********************************************************************/

void
CleanLine(char *line)
{
    char    *src;
    char    *dest;

    for (dest = src = line; *src != '\0'; src++) {
	if (*src == '\\') {
	    switch (src[1]) {
		case 'n':
		case 'b':
		case 'f':
		case 'r':
		    /*
		     * Skip over the second character as well, as we don't
		     * want these funky characters in our output.
		     */
		    src++;
		case '\0':
		    /*
		     * Handle special-case of backslash at the end of the line
		     * by just continuing, so we recognize the end of the line
		     * without copying the backslash down.
		     */
		    continue;
	    }
	    /*
	     * Skip the src pointer forward to the escaped character so it
	     * gets copied in, rather than the backslash.
	     */
	    src++;
	}
	*dest++ = *src;
    }
    *dest = '\0';
}


/***********************************************************************
 *				AddLine
 ***********************************************************************
 * SYNOPSIS:	    Add a line to the end of the text for a topic.
 * CALLED BY:	    echoUsage, echoSyn
 * RETURN:	    nothing
 * SIDE EFFECTS:    the line is appended to the text in the topic.
 *		    if there was no text in the topic, keylen is set to
 *	    	    distance from the start of the passed string to the
 *	    	    first whitespace character.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/91	Initial Revision
 *
 ***********************************************************************/
void
AddLine(char	*string,
	Topic	*topic)
{
    int	    stringlen = strlen(string) + 1;

    if (topic->lines == NULL) {
	char	*cp;

	topic->lines = (char *)malloc(stringlen+1);
	for (cp = string; !isspace(*cp) && (*cp != '\0'); cp++) {
	    ;
	}
	topic->keylen = cp - string;
    } else {
	topic->lines = (char *)realloc(topic->lines,
				       topic->textlen + stringlen + 1);
    }

    if (topic->lines == NULL) {
	fprintf(stderr, "Virtual memory exhausted\n");
	exit(1);
    }
    sprintf(&topic->lines[topic->textlen], "%s\n", string);
    topic->textlen += stringlen;
}

/***********************************************************************
 *				AddTopic
 ***********************************************************************
 * SYNOPSIS:	    Add another topic to the array of known ones.
 * CALLED BY:	    main
 * RETURN:	    Topic * for new topic.
 * SIDE EFFECTS:    topics array is extended.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/91	Initial Revision
 *
 ***********************************************************************/
Topic *
AddTopic(void)
{
    Topic   *topic;
    
    topic = (Topic *)malloc(sizeof(Topic));
    if (topic == NULL) {
	fprintf(stderr, "Virtual memory exhausted\n");
	exit(1);
    }

    topic->lines = NULL;
    topic->textlen = 0;
    topic->keylen = 0;

    if (numTopics == 0) {
	topics = (Topic **)malloc(sizeof(Topic *));
    } else {
	topics = (Topic **)realloc((char *)topics,
				   (numTopics+1) * sizeof(Topic *));
    }
    
    if (topics == NULL) {
	fprintf(stderr, "Virtual memory exhausted\n");
	exit(1);
    }
    topics[numTopics++] = topic;

    return(topic);
}


/***********************************************************************
 *				CompareTopics
 ***********************************************************************
 * SYNOPSIS:	    Compare two topics to sort them into ascending
 *		    order.
 * CALLED BY:	    main via qsort
 * RETURN:	    <, =, or > 0 depending as t1 is <, =, or > t2
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/91	Initial Revision
 *
 ***********************************************************************/
int
CompareTopics(Topic 	**t1,
	      Topic 	**t2)
{
    int	    len;
    int	    result;

    len = (*t1)->keylen < (*t2)->keylen ? (*t1)->keylen : (*t2)->keylen;
    
    result = strncmp((*t1)->lines, (*t2)->lines, len);
    if (result == 0) {
	/*
	 * If equal up to the minimum of their lengths, return equal only
	 * if lengths are equal, else shorter string is "less" than the other.
	 */
	return((*t1)->keylen - (*t2)->keylen);
    } else {
	return (result);
    }
}
	

/***********************************************************************
 *				GatherUsage
 ***********************************************************************
 * SYNOPSIS:	    Read lines from the input that form the "Usage"
 *		    section of the documentation, stripping off all
 *		    leading whitespace.
 *
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    all lines up to the first blank line are placed in
 *	    	    the "lines" string of the passed topic.
 *	    	    topic->keylen will be set by AddLine.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	rsf	12/ 5/91	Initial Revision
 *
 ***********************************************************************/
void 
GatherUsage(Topic	*topic) 
{
    char *start;
    
    while (gets(line) != NULL) {
	CleanLine(line);
	for (start = line; isspace(*start) && (*start != '\0'); start++) {
	    ;
	}
	if (*start == '\0') {
	    break;
	}
	AddLine(start, topic);
    }
}


/***********************************************************************
 *				GatherSyn
 ***********************************************************************
 * SYNOPSIS:	    Read lines from the input that form the "Synopsis"
 *		    section of the documentation.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    all lines up to the first that begins with a non-
 *	    	    whitespace character are stuck in the "lines" string
 *		    of the passed topic.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/91	Initial Revision
 *
 ***********************************************************************/
void
GatherSyn(Topic  *topic) 
{
    while (gets(line) != NULL) {
	CleanLine(line);
	if (!isspace(line[0]) && (line[0] != '\0')) {
	    break;
	}
	AddLine(line, topic);
    }
}


volatile void
main()
{
    Topic   	*topic;

#if !defined(_WIN32)
    extern volatile void exit(int);
#endif

    topics = topic = NULL;
    
    /*
     * Read in everything from our stdin to the "topics" array.
     */
    while (gets(line) != NULL) {
	if (strncmp(&line[1], "Usage", 5) == 0) {
	    topic = AddTopic();
	    GatherUsage(topic);
	} else if ((strncmp(line, "Synopsis:", 8) == 0) && (topic != NULL)) {
	    GatherSyn(topic);
	}
    }

    /*
     * Now sort all the topics alphabetically and spew them forth.
     */
    if (topics != NULL) {
	int 	i;
	
	qsort(topics, 
	      numTopics, 
	      sizeof(topics[0]), 
#if !defined(_WIN32)
	      CompareTopics);
#else
	      (int (*) (const void*, const void*)) CompareTopics);
#endif

	for (i = 0; i < numTopics; i++) {
	    printf("%s", topics[i]->lines);
	}
    }
    
    exit(0);
}

