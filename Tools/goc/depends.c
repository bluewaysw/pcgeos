/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	goc
MODULE:		depend info for goc @optimization
FILE:		depends.c

AUTHOR:		Josh Putnam, Dec 16, 1992

ROUTINES:
	Name			Description
	----			-----------
	Depends_GetResolved	get the resolved pathname for a file given
				the name from the string table for it.

	Depends_StoreInclude	Associate the given filename with the
				current file's include list (and depends file).

	Depends_FileUsesMacro	Record that the current file depends on the
				macro to come from this file.

	Depends_WriteDepends 	Write the depends for the current file.

	Depends_ShouldRemake	Tell if the current file needs remaking

	Depends_MarkOptimize	Mark a file as optimized

	Depends_WasOptimized	True iff file read and optimized already

	Depends_Init		Initialize depends module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	12/16/92   	Initial version.

DESCRIPTION:


	$Id: depends.c,v 1.6 96/07/08 17:36:36 tbradley Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#include "goc.h"
#include "scan.h"
#include <stdio.h>
#include <hash.h>
#include <compat/string.h>
#include <sys/types.h>    /* both needed for include optimization */
#include <sys/stat.h>
#include <assert.h>

#include "malloc.h"
#include "depends.h"

#define DPRINT(x) /* fprintf x */

Hash_Table	nonLocalSearchNames; /* just records FindFile results */

Hash_Table	fileInfo; /* associate file information that doesn't change */



#if defined(_MSDOS)          /* The system call exists for MetaWare and UNIX */
#define STAT _stat    /* The only difference is the name.  */
#else   /* unix or win32 */
#define STAT stat
#endif




#define  DependInitDependBuffers()  \
    depend_pathNameBuffer[0] =     \
    depend_nameBuffer[0] = '\0';

static char depend_pathNameBuffer[1024];
static char depend_nameBuffer[1024];




/*
 * Optimized .goh files have a file that keeps track of dependencies.
 * We record the name of the thing included and whether it is a local
 * include or not.
 */
typedef struct {
    enum {DEPEND_FILE_LOCAL,DEPEND_FILE_NON_LOCAL,DEPEND_MACRO} type;
    char 	*pathName;
    char	*name;
}Depend;


typedef struct{
    char	*includeName;
    char 	*pathName;
    Boolean	local;
}IncludeData;

typedef enum {
    UNDETERMINED = 0,
    NO_REMAKE_IS_UNOPT 	= 1,   /* normal .goh file. no remake */
    NO_REMAKE_IS_OPT 	= 2,   /* optimized .goh file.   should NOT remake */
    REMAKE_IS_OPT 	= 4,   /* optimized .goh file. should remake */
    BUSY		= 8,   /* allows us to detect @include cycles */
} MakeType;

typedef struct{
    IncludeData		*includes;
    int			numIncludes;
    Boolean 	optimize;
    Mac		**macros;
    unsigned 	numMacros;

    MakeType	makeStatus;
    time_t 	src_mtime;
    time_t	gph_mtime;

    Depend	*dependencies;
    int		numDepends;
    char	*lastDependFile;
}FileInfo;


/**** forward declarations ****/

Depend *DependsReadDependFile (char *file, int *numDepends);





/*************** optimization related types/macros *********************/











/***********************************************************************
 *				Depends_Init
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:	    Scan_Init
 * RETURN:
 * SIDE EFFECTS:    initialize hash table for local searches
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/17/92   	Initial Revision
 *
 ***********************************************************************/
void
Depends_Init (void)
{
    DPRINT((stderr,"initializing nonLocalSearchName hash table.\n"));
    Hash_InitTable(&nonLocalSearchNames, 16, HASH_ONE_WORD_KEYS, 5);
    Hash_InitTable(&fileInfo, 16, HASH_ONE_WORD_KEYS, 5);

}	/* End of Depends_Init.	*/



/***********************************************************************
 *				DependGetFileInfo
 ***********************************************************************
 * SYNOPSIS:	    get the info associated with a file, or new info zeroed out
 * CALLED BY:	    many things. think of this as a symbol maker routine
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/17/92   	Initial Revision
 *
 ***********************************************************************/
FileInfo *
DependGetFileInfo (char *name)
{
    Hash_Entry	*entry;
    Boolean	new;
    FileInfo 	*res;

    entry = Hash_CreateEntry(&fileInfo,name,&new);
    if(!new){
	res = (FileInfo *)Hash_GetValue(entry);
    }else {
	res = (FileInfo *)Hash_SetValue(entry,calloc(1,sizeof(FileInfo)));
	DPRINT((stderr,"new info for %s\n",name));
    }
    return res;
}	/* End of DependGetFileInfo.	*/


/***********************************************************************
 *				macroNotIncluded
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/21/92   	Initial Revision
 *
 ***********************************************************************/
int
macroNotIncluded(char *fileName,char *macroFileName)
{
    int i;
    FileInfo *fi = DependGetFileInfo(fileName);

    for(i = 0; i < fi->numIncludes ;i++){
	if(fi->includes[i].pathName == macroFileName){
	    return FALSE;
	}
	if(macroNotIncluded(fi->includes[i].pathName,macroFileName) == FALSE){
	    return FALSE;
	}
    }
    return TRUE;
}	/* End of macroNotIncluded.	*/



/***********************************************************************
 *				Depends_FileUsesMacro
 ***********************************************************************
 * SYNOPSIS: record any depends resulting from the current file invoking
 *           this macro
 * CALLED BY:	    scanner
 * RETURN:
 * SIDE EFFECTS:    justs adds the macro to a list. The macro may not
 *                  go into the depends file if it turns out to be @included
 * 		    indirectly or directly.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/16/92   	Initial Revision
 *
 ***********************************************************************/
void
Depends_FileUsesMacro (Mac *mac)
{
    FileInfo	*f;
    int 	i;


    if(curFile->name != mac->fileName
       && macroNotIncluded(curFile->name,mac->fileName)) {
	yywarning("uses macro '%s' from %s but never includes the file.",
		  mac->name,mac->fileName);


	/* check to see if its already in the list. search backwards */
	f  = (DependGetFileInfo(curFile->name));
	for(i = f->numMacros -1; i != -1; i--){
	    if(f->macros[i] == mac){
		return;
	    }
	}
	if(!f->numMacros){
	    f->macros = (Mac **)calloc(1, sizeof(Mac *));
	}else{
	    f->macros = (Mac **)realloc((char *) f->macros,
					(f->numMacros +1) * sizeof(Mac *));
	}
	f->macros[f->numMacros++] = mac;
    }
}   /* End of Depends_FileUsesMacro.	*/


/***********************************************************************
 *				Depends_StoreInclude
 ***********************************************************************
 * SYNOPSIS:	    record that curFile includes pathname, and record
 *			the name as given in the source file.
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:	    we need to record this for the depends file. If we change
 * 		the include directory path from one compile to another, we
 * 		we need to check to see that when our program sees
 * 		@include <foo> the file we check to see if its up to date
 * 		is the file we @included into our pre-goc'ed thing.
 *
 *		We still need this info if it is a localSearch
 * 		 	(@inlcude "foo"), because the file might not be found
 *			locally and might just turn out to be the same as
 * 			@include <foo>.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/21/92   	Initial Revision
 *
 ***********************************************************************/
void
Depends_StoreInclude(char *includeName,char *pathName,Boolean localSearch)
{
    int		i;
    FileInfo 	*f;

    f = DependGetFileInfo(curFile->name);
    for(i = f->numIncludes - 1; i != -1; i--){
	if(includeName == f->includes[i].includeName){
	    yywarning("same include %s in one file",includeName);
	    return;
	}
    }
    if(!f->includes){
	f->includes = (IncludeData *)malloc(sizeof(IncludeData));
    }else{
	f->includes = (IncludeData *)realloc((char *) f->includes,
					     (f->numIncludes+1) *
					     sizeof(IncludeData));
    }
    f->includes[f->numIncludes].includeName = includeName;
    f->includes[f->numIncludes].pathName = pathName;
    f->includes[f->numIncludes].local = localSearch;
    f->numIncludes++;
}






/***********************************************************************
 *				FindFile
 ***********************************************************************
 * SYNOPSIS:	  Find a file on our search path.
 * CALLED BY:	  yylex
 * RETURN:	  The path of the file (in dynamic memory)
 * SIDE EFFECTS:  sets *f to be the found file opened for reading, or
 *                closes the file if the FILE ** is NULL.
 *
 * STRATEGY:
 *           if its a local include and we allow local includes,
 *             search in the current directory for the file
 *             and return it if found
 *
 *          Otherwise, look for it using the directory path in the
 *          directories specified with -I on the command line.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh    8/92            locate file to include, use directory path
 *
 ***********************************************************************/
static char *
FindFile(char *file,Boolean searchCurrentDirFirst, FILE **resultFile)
{
    char    	name[1024];
    char	*result = NULL;
    char        *cp;
    int	    	i;
    FILE	*f = NULL;

    if(searchCurrentDirFirst && allowCurrentDirSearch){
	strcpy(name,curFile->name);     /* get the file we're in now */

	if((cp = strrchr(name,PATHNAME_SLASH)) == NULL){/* see if no dir before it */
	    if((f = fopen(file,"r"))!= NULL){    /* lookup file by itself   */
		strcpy(name,file);
		goto match;
	    } else{
		/* nothing. fallthrough and check with the dir path */
	    }
	}else {                     /* use path for current filename, but */
	    strcpy(cp+1,file);        /* append the new file to the end.    */
	    if((f = fopen(name,"r")) != NULL){
		result = String_EnterNoLen(name);
		goto match;                                 /* SUCCE SS */
	    }
	}
    }
    for (i = 0; i < numDirs; i++) {
	sprintf(name, "%s%c%s", dirs[i], PATHNAME_SLASH, file);
	if ((f = fopen(name, "r")) != 0) {
	    Hash_Entry 	*entry;
	    Boolean	new;

	    DPRINT((stderr,"%s->%s\n",file,name));
	    entry = Hash_CreateEntry(&nonLocalSearchNames,file,&new);
	    Hash_SetValue(entry,(result = String_EnterNoLen(name)));
	    break;
	}
    }
    if (i == numDirs) {
	return((char *)NULL);
    }                          /* FALLTHROUGH TO MATCH */

    match:   /* see if they want the FILE *.   */
    if(resultFile){
	*resultFile = f;
    }else{
	fclose(f);
    }
    return(result);
}


/***********************************************************************
 *				Depends_GetResolved
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/17/92   	Initial Revision
 *
 ***********************************************************************/
char *
Depends_GetResolved (char *name,Boolean localSearch, FILE **f)
{
    char 	*result;
    Hash_Entry	*entry;
    /*
     * If the search is not local, look in the hash table to see if we've
     * computed its path already.
     */
    if(!localSearch &&
       (entry = Hash_FindEntry(&nonLocalSearchNames,name)) &&
       (result = (char *)Hash_GetValue(entry))){
	DPRINT((stderr,"Depends_GetResolved: found %s,is %s\n",name,result));
	if(f){
	    *f = fopen(result, "r");
	}
    }else{
	result = FindFile(name,localSearch,f);
	DPRINT((stderr,"FindFile %s is %s,localsearch %s\n",name,result,
	       localSearch?"on":"off"));
    }
    return result;
}	/* End of Depends_GetResolved.	*/




/***********************************************************************
 *				DependCheckPrecomputedResult
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/23/92   	Initial Revision
 *
 ***********************************************************************/
static inline
Boolean
DependCheckPrecomputedResult (FileInfo *fi,char *f)
{
    if(fi->makeStatus == NO_REMAKE_IS_UNOPT && (curFile->name == f)){
	yywarning("File doesn't have a dependency or pre-processed file "
		  "so we assumed it was a non-optimized file and didn't "
		  "need remaking. Other optimized files that @include "
		  "this one MAY need to be remade (or your geode may "
		  "crash).Perhaps you should remove the .gph file (only) "
		  "and remake");
	fi->makeStatus = REMAKE_IS_OPT;
	return(TRUE);
    }else if(fi->makeStatus == BUSY){
	File 	*file;

	yywarning("%s depends on itself. E.g. it includes itself or it "
		  "defines a macro that its included files depend on. "
		  "The include stack is now:",f);
	for(file = curFile; file; file = file->next){
	    fprintf(stderr,"\t%s\n",file->name);
	}
	return(TRUE);
    }else if(curFile->name == f && fi->makeStatus == NO_REMAKE_IS_OPT){
	/* see if the macro's are all coming from the same place */
	/* if not, give a warning and return TRUE (optimized and remake) */
    }

    DPRINT((stderr,"returning based on previously determined status %s "
	    "for %s\n",
	    ((fi->makeStatus==NO_REMAKE_IS_OPT)?
	     "NO_REMAKE_IS_OPT":
	     ((fi->makeStatus==UNDETERMINED)?
	      "UNDETERMINED":
	      ((fi->makeStatus==NO_REMAKE_IS_UNOPT)?
	       "NO_REMAKE_IS_UNOPT":
	       ((fi->makeStatus==REMAKE_IS_OPT)?
		"REMAKE_IS_OPT":
		"")))),
	    f));
    return (fi->makeStatus==NO_REMAKE_IS_OPT ||
	    fi->makeStatus==NO_REMAKE_IS_UNOPT)?FALSE:TRUE;
}

/***********************************************************************
 *				DependStatFiles
 ***********************************************************************
 * SYNOPSIS:	    stat the files associated with path (e.g. foo.goh,
 *			foo.doh, foo.poh).
 *			Store the mtimes for the files in the FileInfo.
 * 			Read the depends and store in the FileInfo.
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/23/92   	Initial Revision
 *
 ***********************************************************************/
void
DependStatFiles (char *path,
		 FileInfo *fi,
		 int *srcStatResult,
		 int *genStatResult,
		 int *dependStatResult)
{
    struct STAT	srcFile, generatedFile,dependFile;
    char  	*dependFileName;

    if((*srcStatResult = STAT(path,&srcFile)) == 0)
	fi->src_mtime = srcFile.st_mtime;
    if((*genStatResult = STAT(Depends_GetFileName(path,FALSE),
			      &generatedFile)) == 0){
	fi->gph_mtime = generatedFile.st_mtime;
    }
    if((*dependStatResult = STAT(dependFileName =
				 Depends_GetFileName(path,TRUE),
				 &dependFile)) == 0 &&
       fi->dependencies == NULL ){
	fi->dependencies = DependsReadDependFile(dependFileName,
						 &fi->numDepends);
    }
}


/***********************************************************************
 *				DependRemoveDotDot
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	1/20/93   	Initial Revision
 *
 ***********************************************************************/
void
DependRemoveDotDot (char *s)
{
    /*char *cp = s;*/
/*
    for(;;){
	while(*cp != '.' && *cp != '\0')
	    cp++;
	if(*cp == '\0')
	    break;
	if

    }*/
}	/* End of DependRemoveDotDot.	*/



/***********************************************************************
 *				DependPathsDifferent
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	1/20/93   	Initial Revision
 *
 ***********************************************************************/
Boolean
DependPathsDifferent(char *new,char *old)
{
    char 	*temp1 = (char *)malloc(1+strlen(new));
    char 	*temp2 = (char *)malloc(1+strlen(old));
    Boolean	result;

    strcpy(temp1,new);
    strcpy(temp2,old);

#ifdef _MSDOS
    {
        char	*cp1, *cp2;

	for(cp1 = temp1; *cp1; cp1++){
	    *cp1 = toupper(*cp1);
	}
	for(cp2 = temp2; *cp2; cp2++){
	    *cp2 = toupper(*cp2);
	}
    }
#endif
	DependRemoveDotDot(temp1);
	DependRemoveDotDot(temp2);
	result = strcmp(temp1,temp2);

	free(temp1);
	free(temp2);
	return result;
}	/* End of DependPathsDifferent.	*/



/***********************************************************************
 *			   Depends_ShouldRemake
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/ 2/92   	Initial Revision
 *
 ***********************************************************************/
int
Depends_ShouldRemake (char *f)
{
    int			srcStatResult,genStatResult,dependStatResult;
    int 		result = 0;
    int			i;
    FileInfo 		*fi = DependGetFileInfo(f),*fi2;


    if(fi->makeStatus != UNDETERMINED){
	return DependCheckPrecomputedResult(fi,f);
    }
    assert(fi->src_mtime==0&&fi->gph_mtime==0&&fi->dependencies==NULL);

    DependStatFiles(f,fi,&srcStatResult,&genStatResult,&dependStatResult);


    /*
     * If we are checking the current file (which has the @optimize) and it
     * doesn't have either file, remake.
     */
    if((curFile->name == f) && (genStatResult || dependStatResult)){
	DPRINT(("remaking @optimized file %s. Missing depends or pre-goc'ed file\n",f));
	result = REMAKE_IS_OPT;
	goto done;
    }else if((curFile->name != f) && (genStatResult ^ dependStatResult)){
	/*
	 * if it's not the current file, but it has one but not both
	 * this means one file is missing.
	 */
	DPRINT((stderr,"remaking seemingly @optimized file %s.\n"
		"Missing either a .gdh or .gph file\n",f));
	result = REMAKE_IS_OPT;
	goto done;
    }else if((f != curFile->name) && genStatResult && dependStatResult){
	/* looks like it is just a normal .goh file */

	result = NO_REMAKE_IS_UNOPT;
	DPRINT((stderr,"%s is a normal .goh file. no remake.\n",f));
	goto done;
    }
    /* now we're guaranteed to have all three files. Check their dates. */
    if(fi->src_mtime > fi->gph_mtime){
	DPRINT((stderr,"source %s is newer than generated file\n",f));
	result = REMAKE_IS_OPT;
	goto done;
    }

    /* set things up so we don't circle forever on bad depends */
    fi->makeStatus = BUSY;

    for(i = 0; i < fi->numDepends; i++){

	time_t		timeToCompareWith;
	char		*depFileName;
	char		*macrosFile;


	/* if the macro's definition's file changed, warn */
	if(fi->dependencies[i].type == DEPEND_MACRO){
	    if(f == curFile->name &&
	       (macrosFile =
		Scan_MacroIsUndefForFromFile(fi->dependencies[i].name,
					     fi->dependencies[i].pathName))){
		yywarning("macro %s was defined in %s. Now comes from %s",
			  fi->dependencies[i].name,
			  fi->dependencies[i].pathName,
			  macrosFile);
		result = REMAKE_IS_OPT;
		goto done;
	    }else{
		depFileName = fi->dependencies[i].pathName;
	    }
	}else{
	    /* check the include depend */

	    depFileName = FindFile(fi->dependencies[i].name,
				   fi->dependencies[i].type ==
				   DEPEND_FILE_NON_LOCAL?FALSE:TRUE,
				   NULL);
	    if(DependPathsDifferent(depFileName,fi->dependencies[i].pathName)){
		yywarning("location of %s changed from %s to %s\n",
			  fi->dependencies[i].name,
			  fi->dependencies[i].pathName,
			  depFileName);
		result = REMAKE_IS_OPT;
		goto done;
	    }
	}
	/* see if this dependfile needs reamking */

	if((fi2 = DependGetFileInfo(depFileName))->makeStatus == UNDETERMINED){
	    if(Depends_ShouldRemake(depFileName)){
		result = REMAKE_IS_OPT;
		goto done;
	    }
	}

	if(fi2->makeStatus == REMAKE_IS_OPT){
	    result = REMAKE_IS_OPT;
	    goto done;
	}
	/* It is either NO_REMAKE_IS_OPT or NO_REMAKE_IS_UNOPT */
	/* figure out the date that matters: either the source or generated */
	timeToCompareWith =
	    (fi2->makeStatus==NO_REMAKE_IS_OPT) ?
		fi2->gph_mtime: fi2->src_mtime;

	/* see if our results are up to date */
	if(timeToCompareWith > fi->gph_mtime){
	    DPRINT((stderr,
		    "generated file for %s is older than dependency %s\n",
		    f,
		    depFileName));
	    result = REMAKE_IS_OPT;
	    goto done;
	}
    }
    result = NO_REMAKE_IS_OPT;
 done:

    fi->makeStatus = result;

    return((result == NO_REMAKE_IS_OPT || result== NO_REMAKE_IS_UNOPT)?
       FALSE:TRUE);
}


/***********************************************************************
 *				DependsReadDependFile
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/22/92   	Initial Revision
 *
 ***********************************************************************/
Depend *
DependsReadDependFile (char *path, int *numDepends)
{
    Depend	d,*result = NULL;
    int		dependCount  = 0;
    int		totalDepends = 0;
    int		local;
    int		bytesToCopy;
    FILE 	*f;
#define DEPEND_BLOCK_SIZE 5


    DPRINT((stderr,"reading depend file %s",path));
    if(!(f = fopen(path,"r"))){
	yyerror("can't open depends file");
	goto done;
    }
    while(fscanf(f,"%s",yytext) != EOF){
	switch(yytext[0]){
	case 'm':
	    fscanf(f,"%s",yytext);  	/* get the defining filename */
	    d.pathName = String_EnterNoLen(yytext);
	    fscanf(f,"%s",yytext);  	/* get the name of the macro */
	    d.name = String_EnterNoLen(yytext);
	    d.type = DEPEND_MACRO;
	    break;
	case 'f':
	    fscanf(f,"%d", &bytesToCopy);
	    fscanf(f,"%s",depend_nameBuffer+bytesToCopy);
	    d.name = String_EnterNoLen(depend_nameBuffer);

	    fscanf(f,"%d", &bytesToCopy);
	    fscanf(f,"%s",depend_pathNameBuffer+bytesToCopy);
	    d.pathName = String_EnterNoLen(depend_pathNameBuffer);

	    fscanf(f,"%d",&local);
	    d.type = local?DEPEND_FILE_LOCAL:DEPEND_FILE_NON_LOCAL;
	    break;
	default:
	    yyerror("bad depends file %s",path);
	    if(dependCount)
		free((char*) result);
	    result = NULL;
	    dependCount = 0;
	    goto done;
	}
	/* store in the new depend */
	if(dependCount == totalDepends){
	    if(totalDepends == 0){
		result = (Depend *)calloc(DEPEND_BLOCK_SIZE,
					  sizeof(Depend));
	    }else{
		result = (Depend *)realloc((char *) result,
					   (totalDepends +
					    DEPEND_BLOCK_SIZE)*
					   sizeof(Depend));
	    }
	    totalDepends += DEPEND_BLOCK_SIZE;
	}
	result[dependCount] = d;

	if(result[dependCount].type == DEPEND_MACRO){
	    DPRINT((stderr,"macro %s from %s\n",d.name,d.pathName));
	}else{
	    DPRINT((stderr,"included file %s->%s is %slocal\n",
		    d.name,
		    d.pathName,
		    d.type==DEPEND_FILE_LOCAL?"":"not "));
	}
	dependCount++;
    }
 done:
    fclose(f);
    *numDepends = dependCount;
    return result;
}	/* End of DependsReadDependFile.	*/


/***********************************************************************
 *				DependWriteIncludedFiles
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/21/92   	Initial Revision
 *
 ***********************************************************************/
void
DependWriteIncludedFiles (FILE *fdep, FileInfo *fi,Boolean topLevelCall)
{
    FileInfo	*temp;
    int 	i;

    int		similarCharsInName;
    int		similarCharsInPathName;
    char	*p1,*p2;

    /* see if we've put it out for this file already */
    for(i = 0; i < fi->numIncludes ;i++){
	temp = DependGetFileInfo(fi->includes[i].pathName);
	if(temp->lastDependFile != curFile->name){
	    temp->lastDependFile = curFile->name;

	    DPRINT((stderr,"dependency %s %s %d\n",
		    fi->includes[i].includeName,
		    fi->includes[i].pathName,
		    fi->includes[i].local));

	    /* count the number  characters that are the same in the name */
	    for(p1 = depend_nameBuffer, p2 = fi->includes[i].includeName;
		*p1 && *p2 && (*p1 == *p2);
		p1++,p2++);
	    similarCharsInName = p2 - fi->includes[i].includeName;
	    strcpy(depend_nameBuffer,fi->includes[i].includeName);

	    for(p1 = depend_pathNameBuffer, p2 = fi->includes[i].pathName;
		*p1 && *p2 && (*p1 == *p2);
		p1++,p2++);
	    similarCharsInPathName = p2 - fi->includes[i].pathName;
	    strcpy(depend_pathNameBuffer,fi->includes[i].pathName);

	    fprintf(fdep,"f %d %s %d %s %d\n",
		    similarCharsInName,
		    fi->includes[i].includeName + similarCharsInName,
		    similarCharsInPathName,
		    fi->includes[i].pathName + similarCharsInPathName,
		    fi->includes[i].local);
	}

    }
}	/* End of DependWriteIncludedFiles.	*/


/***********************************************************************
 *				DependWriteMacroFiles
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/21/92   	Initial Revision
 *
 ***********************************************************************/
void
DependWriteMacroFiles(FILE *fdepend,FileInfo *fi)
{
    int 	i;
    for(i = fi->numMacros -1; i != -1; i--){
	DPRINT((stderr,"macro %s %s\n",
		fi->macros[i]->name,
		fi->macros[i]->fileName));
	fprintf(fdepend,"m %s %s\n",
		fi->macros[i]->fileName,
		fi->macros[i]->name);
    }
}	/* End of DependWriteMacroFiles.	*/


/***********************************************************************
 *				DependsRecurseWriteDepends
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY: 	    Recursively dump depends, but stop
 *                  at other files that are @optimized. The recursive method
 * 		    of 'make' means that we don't have to list all the depends
 * 		    if the file is @optimized because we'll check it
 * 		    separately.
 *
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/21/92   	Initial Revision
 *
 ***********************************************************************/
void
DependsRecurseWriteDepends (char *name, FILE *fdepend)
{

    FileInfo 	*fi = DependGetFileInfo(name);
    int		i;

/* need to recurse for @included things */
/* we print the files first so the depend file is the files then the macros */

    DPRINT((stderr,"includes for %s\n",name));
    DependWriteIncludedFiles(fdepend,fi,TRUE);

    for(i = 0; i < fi->numIncludes; i++){
	if(!DependGetFileInfo(fi->includes[i].pathName)->optimize){
	    DependsRecurseWriteDepends(fi->includes[i].pathName,fdepend);
	}
    }

    DPRINT((stderr,"macros %s\n",name));
    DependWriteMacroFiles(fdepend,fi);

}	/* End of DependsRecurseWriteDepends.	*/


/***********************************************************************
 *				Depends_WriteDepends
 ***********************************************************************
 * SYNOPSIS:	    write the depends for a file
 * CALLED BY:	    scanner
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:	    Recursively dump depends for included files
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/22/92   	Initial Revision
 *
 ***********************************************************************/
void
Depends_WriteDepends(void)
{
    FILE 	*fdepend;


    fdepend 		= fopen(Depends_GetFileName(curFile->name,TRUE),
				"wb");
    DependInitDependBuffers();
    DependsRecurseWriteDepends(curFile->name,fdepend);
    fclose(fdepend);

}









/***********************************************************************
 *				Depends_MarkOptimize
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/21/92   	Initial Revision
 *
 ***********************************************************************/
void
Depends_MarkOptimize (void)
{
    DependGetFileInfo(curFile->name)->optimize = TRUE;
}	/* End of Depends_MarkOptimize.	*/



/***********************************************************************
 *				Depends_WasOptimized
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:	     Boolean
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/30/92   	Initial Revision
 *
 ***********************************************************************/
Boolean
Depends_WasOptimized (char *f)
{
    return(DependGetFileInfo(f)->optimize);
}	/* End of Depends_WasOptimized.	*/




/***********************************************************************
 *				Depends_GetFileName
 ***********************************************************************
 * SYNOPSIS:	    get the file path for a depends or pre-goc file
 * CALLED BY:	    scanner and this module
 * RETURN:	    pathname for the file, taking into account
 *                             a directory override
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	1/15/93   	Initial Revision
 *
 ***********************************************************************/
char  dependFileBuffer[1024];


char *directoryOverride = NULL;

char *
Depends_GetFileName (char *root, Boolean dependOrPreGoc)
{
    char 	*result;
    char 	*mutate = 1 + strrchr(root,'.');

    assert(*mutate == 'g');
    *mutate = dependOrPreGoc?'d':'p';

    if(directoryOverride){
	char *slash1 = strrchr(root,'/');
#if defined(_MSDOS) || defined(_WIN32)
	char *slash2 = strrchr(root,'\\');
	slash1 = (slash1 < slash2) ? slash2:slash1;
#endif
	if(slash1){
	    sprintf(dependFileBuffer,"%s/%s",directoryOverride,slash1+1);
	    result = String_EnterNoLen(dependFileBuffer);
	}else{
	    goto use_root;
	}
    }else{
    use_root:
	result = String_EnterNoLen(root);
    }
    *mutate = 'g';
    return result;
}	/* End of Depends_GetFileName.	*/
