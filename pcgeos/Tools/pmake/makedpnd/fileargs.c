/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fileargs.c

AUTHOR:		Josh Putnam, Jun 15, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	6/15/92   	Initial version.

DESCRIPTION:
	routines so that tools can read their arguments from files
	due to dos limitations on the length of command lines.

	$Id: fileargs.c,v 1.7 96/06/13 17:24:42 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#include <ctype.h>
#include <compat/string.h>
#include <stdio.h>

#include <compat/stdlib.h>
#include <malloc.h>

/* forward declarations */
static char *LoadFileIntoMemory(FILE *);
static void LexArgs(char *argBuf, int *argcPtr, char ***argvPtr);

#include <assert.h>



/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		name of file to read args from, pointer to argc, ptr to argv

RETURN:		argc and argv go into contents of ptr.

DESTROYED:	

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

void GetFileArgs (char *file,int *argcPtr,char ***argvPtr)
{
  FILE *argfile;
  char *argBuf;

  if((argfile = fopen((file),"r")) == NULL){
    fprintf(stderr,"Fatal Error: can't open argfile %s\n",file);
    exit(1);
  }else{
    argBuf = LoadFileIntoMemory(argfile);
    LexArgs(argBuf,argcPtr,argvPtr);
    fclose(argfile);
  }
}	/* End of GetFileArgs.	*/




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadFileIntoMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return a dynamically allocated char * with a stream's contents.

CALLED BY:	main

PASS:		FILE * of file

RETURN:		char *

DESTROYED:	Nothing.

PSEUDO CODE/STRATEGY:	allocate (as needed)and stuff buffer

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/





#define BUF_INC 256

static char  *LoadFileIntoMemory (FILE *argfile)
{
  int bufInsp = 0, bufSize = BUF_INC;
  int cc;
  char *x = (char *)malloc(BUF_INC);

    
  /* 
   * invariants: 
   *   bufInsp == place to insert next char 
   *   bufSize == size of allocated block 
   */
  for(;;){
    cc = fread(x+bufInsp,1,BUF_INC,argfile); /** fill buf, maintain bufInsp **/
    bufInsp += cc;

    if(bufInsp == bufSize){                 /** grow buf, maintain bufSize.**/
      x = (char *)realloc(x,bufSize + BUF_INC);
      bufSize += BUF_INC;       
      if(!x){
	fprintf(stderr,"Fatal Error: Virtual Memory Exhausted\n");
	exit(2);
      }

    }


    if(cc != BUF_INC){
      if(ferror(argfile)){
	fprintf(stderr,"error reading argument file\n");
	exit(-2);
      }else{
	x[bufInsp] = '\0';                 /** terminate string with a null **/
	assert(strlen(x) < bufSize);
	return x;
      } 
    }
  }  
}





/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountUnwantedChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the number of unwanted chars before the next token
        e.g.  for ' ','\t','\n'  return 1.
	
	
 	      IF IT BECOMES NECESSARY TO HACK "\\\N", WE JUST CHANGE
	      THIS ROUTINE TO RETURN 2.

CALLED BY:	LexArgs

PASS:		char * to arg buffer

RETURN:		count 

DESTROYED:	Nothing.

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static int CountUnwantedChars(char *argBuf)
{
  int x = 0;
  while(argBuf[x] && isspace(argBuf[x]))
    x++;
  return x;
}




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TerminateArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  Slice the current token out of the buffer by adding a null 
           after it.  

CALLED BY:	

PASS:		

RETURN:    If the token is the last token, return the index of the null
	   byte, else return the index of the byte after the null.

DESTROYED/SPECIAL EFFECTS: 
      
           A token delimiter byte in the arg buffer will get set to null.

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

static int     TerminateArg(char *argBuf)
{
  int x = 0, result;

  while(argBuf[x] && !isspace(argBuf[x])){
    x++;
  }
  result = (argBuf[x] == '\0')? x : (x+1);
  argBuf[x] = '\0';

  return result;
}


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LexArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	break up a string into little strings, 
                set argc and argv to the count of the args, and have
		the ptrs in argv point to the args. 

CALLED BY:	

PASS:		arg string (a char *), ptr to argc and ptr to argv

RETURN:		nothing

DESTROYED:	arg string

PSEUDO CODE/STRATEGY:	

CHECKS:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#define ARG_INC 5
static void LexArgs(char *argBuf,int *argcPtr, char ***argvPtr)
{
  char **argv = (char **) calloc(ARG_INC,sizeof(char *));
  int argvSize = ARG_INC;
  int   curArg = 0;
  
  /*
   * invariants:
   *    curArg is the insertion point of the next arg (starts at 1)
   *    skip over the command itself
   *    argvSize is the size of argv in (char *).
   */

  for(curArg = 1,argv[1] = argBuf;;curArg++){
    if(curArg == argvSize){
      argv = (char **) realloc((void *)argv,
			       (curArg + ARG_INC) * sizeof(char *));
      if(!argv){
	fprintf(stderr,"Fatal Error: Virtual Memory Exhausted\n");
	exit(2);
      }
      argvSize += ARG_INC;
    }

    /* we don't use strtok to lex the args because we may need to         */
    /* read escaped newlines as a single space later == need more control */
    

    argBuf += CountUnwantedChars(argBuf);

    /* check to see if at last arg */
    if(!*argBuf){
      argv[curArg] = NULL;
      *argvPtr = argv;
      *argcPtr = curArg;
      return;
    }
    argv[curArg] = argBuf;
    argBuf += TerminateArg(argBuf);
  }
}




 
