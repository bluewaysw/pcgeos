/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Segment/Group tracking
 * FILE:	  segment.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 20, 1989
 *
 * ROUTINES:
 *	Name	  	    	Description
 *	----	  	    	-----------
 *	Seg_AddSegment	    	Add another segment to the segment table
 *	Seg_AddGroup	    	Add another group to the group table
 *	Seg_EnterGroupMember	Set the nth member of a group
 *	Seg_Find    	    	Locate a segment by name and class
 *	Seg_FindGroup	    	Locate a group by name.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/20/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to deal with the internal segment descriptors.
 *
 *	NOTE: There are various things in this program that depend on
 *	the 0th segment being the global segment (the one with no
 *	data into which symbols declared outside of any segment are
 *	placed). THIS MODULE DOES NOTHING TO ASSURE THIS. It is the
 *	responsibility of the Pass1 functions to make sure the first
 *	segment added for any object module is the global one. This won't
 *	have any effect for the second and later modules, but it will
 *	establish the proper ordering when the first module is loaded.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: segment.c,v 3.9 95/04/18 13:07:07 jon Exp $";
#endif lint


#include    "glue.h"
#include    "sym.h"

#include    <objfmt.h>   /* For segment type codes */


SegDesc	    **seg_Segments; 	/* All known segments. Enlarged at need */
SegInfo	    *seg_Info;	    	/* one entry per segment */
int	    seg_NumSegs=0;    	/* Number of valid segment pointers in
				 * seg_Segments */
SegDesc	    **seg_SubSegs;  	/* Array of segments that have been subsumed
				 * by the groups that contain them. The
				 * descriptors are still required for file
				 * positioning, however, so we keep them */
int	    seg_NumSubSegs=0;	/* Number of subsumed segments */

GroupDesc   **seg_Groups;   	/* All known groups. Enlarged at need */
int	    seg_NumGroups=0;	/* Number of valid pointers in seg_Groups */

SegDesc	    *seg_FarCommon=0;	/* Segment in which to allocate far communal
				 * variables */
SegDesc	    *seg_NearCommon=0;	/* Segment in which to allocate near communal
				 * variables */

SegAlias    *seg_Aliases = NULL;
int	    seg_NumAliases = 0;


/***********************************************************************
 *				Seg_AddAlias
 ***********************************************************************
 * SYNOPSIS:	    Add a segment alias to the list of known aliases.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 4/91		Initial Revision
 *
 ***********************************************************************/
void
Seg_AddAlias(SegAlias *sa)
{
    SegAlias	*newsa;



    newsa = (SegAlias *)malloc((seg_NumAliases + 1) * sizeof(SegAlias));
    if (seg_NumAliases != 0) {
	bcopy(seg_Aliases, &newsa[1], seg_NumAliases * sizeof(SegAlias));
	free((char *)seg_Aliases);
    }
    seg_Aliases = newsa;
    seg_NumAliases += 1;
    seg_Aliases[0] = *sa;
}

/***********************************************************************
 *				SegFindAlias
 ***********************************************************************
 * SYNOPSIS:	    Find a segment alias, if one's around.
 * CALLED BY:	    Seg_AddSegment, Seg_AddGroup, Seg_Find, Seg_FindGroup
 * RETURN:	    SegAlias *, if found, or NULL if not
 * SIDE EFFECTS:    none.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/ 4/91		Initial Revision
 *
 ***********************************************************************/
static SegAlias *
SegFindAlias(ID	    name,
	     ID	    class)
{
    SegAlias	*sa;
    int	    	i;

    for (sa = seg_Aliases, i = seg_NumAliases; i > 0; i--, sa++) {
	if ((sa->name == name) && (sa->class == class)) {
	    return(sa);
	}
    }
    return((SegAlias *)NULL);
}


/***********************************************************************
 *				Seg_AddSegment
 ***********************************************************************
 * SYNOPSIS:	    Record another/Locate a segment
 * CALLED BY:	    Pass1 functions
 * RETURN:	    The descriptor for the segment
 * SIDE EFFECTS:    seg_Segments may be extended
 *
 * STRATEGY:
 *	Any private segment automatically gets a new descriptor.
 *	If segment not private, search the array of segments for one with
 *	same name and class.
 *	    If found, verify parameters match, giving error if not.
 *	    If not found, look for any segment with the same class.
 *	    	If found, insert new descriptor after last with that class
 *	    	If not found, add descriptor to the end
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/22/89	Initial Revision
 *
 ***********************************************************************/
SegDesc *
Seg_AddSegment(const char *file,	    /* Object file in which segment was
				     * defined. Used mostly for distinguishing
				     * private segments. THIS STRING MAY NOT
				     * BE ALTERED */
	       ID 	name,	    /* Segment name from output string table */
	       ID 	class,	    /* Class name from output string table */
	       int  	type,	    /* Segment type (SEG_* from objfmt.h) */
	       int  	align,	    /* Alignment (mask of bits that MBZ) */
	       int  	flags)	    /* Segment flags (see objfmt.h) */
{
    int	    	    i;
    int	    	    j;
    SegDesc 	    *sd;    	    /* Current segment */
    SegDesc 	    *lastClass;	    /* Last segment with same class */
    int	    	    lastClassIndex; /* Index of same */
    SegDesc 	    **osegs;	    /* Old array of segment descriptors */
    char            *segName;       /* Place to store char* of name */
    SegAlias	    *sa;
    int             isClassSeg = 0;

    /*
     * If this segment's name starts with "_BOGUS", then we assume it
     * is the protoMinor segment, and we want to set its combine type
     * to SEG_LIBRARY, on adam's recommendation.
     *
     * If the thing starts with "_CLASSSEG_", we'll strip it off and mark
     * the thing as a resource.
     */
    if(name) {
	segName = ST_Lock(symbols, name);
printf("add_seg %s\n", segName);
	if (!(strncmp(segName, "_BOGUS", sizeof("_BOGUS") - 1))) {
	    type = SEG_LIBRARY;
	} else if (!(strncmp(segName, "_CLASSSEG_", sizeof("_CLASSSEG_") - 1))) {
	    type = SEG_RESOURCE;
	    isClassSeg = 1;
	}
	ST_Unlock(symbols, name);
    }

    sa = SegFindAlias(name, class);

    if (sa != NULL) {
	if (sa->aliasMask & SA_NEWNAME) {
	    name = sa->newName;
	}
	if (sa->aliasMask & SA_NEWCLASS) {
	    class = sa->newClass;
	}
	if (sa->aliasMask & SA_NEWCOMBINE) {
	    type = sa->newCombine;
	}
	if (sa->aliasMask & SA_NEWALIGN) {
	    align = sa->newAlign;
	}
    }

    lastClass = NULL;
    lastClassIndex = -1;

    if (type != SEG_PRIVATE) {
	for (i = 0; i < seg_NumSegs; i++) {
	    sd = seg_Segments[i];

	    if (sd->class == class) {
		/*
		 * Class matches, at least. Remember this one as the last
		 * segment with the same class so we can insert the new
		 * record, if such we make, after it as the microsoft linker
		 * does.
		 */
		lastClass = sd;
		lastClassIndex = i;

		if (sd->name == name) {
		    /*
		     * Wheee. Name match too. They must be the same! Gosh!
		     * Sorry. I lost it for a moment there. -ahem- Make sure
		     * the segment parameters match between the two, bitching
		     * to the user and returning NULL if not. If they do match,
		     * however, just return the current descriptor -- our job
		     * is done.
		     */
		    SegDesc *retval = sd;

		    if (sd->alignment != align) {
			Notify(NOTIFY_ERROR,
			       "%s: alignment mismatch (%d vs. %d) for segment %i, class %i",
			       file, align, sd->alignment, name, class);
			retval = NULL;
		    }
		    if (sd->combine != type) {
			Notify(NOTIFY_ERROR,
			       "%s: segment type mismatch for %i",
			       file, name);
			retval = NULL;
		    }
		    return(retval);
		}
	    }
	}
    } else {
	/*
	 * Look for any segments with the same class so we can put this one
	 * after the last one, as we ought.
	 *
	 * XXX: Look for segment in same file w/same name and class? I know
	 * MS and GEOS object support doesn't require this, but...burn that
	 * bridge if we get to it, I guess.
	 */
	for (i = 0; i < seg_NumSegs; i++) {
	    sd = seg_Segments[i];
	    if (sd->class == class) {
		if (sd->name == name && sd->combine != type) {
		    Notify(NOTIFY_ERROR,
			   "%s: segment type mismatch for %i",
			   file, name);
		    return(NULL);
		}
		lastClass = sd;
		lastClassIndex = i;
	    }
	}
    }

    /*
     * Need to allocate a new segment descriptor and initialize it.
     */
    sd = (SegDesc *)calloc(1, sizeof(SegDesc));
    sd->name = 	    name;
    sd->type =	    S_SEGMENT;
    sd->class =	    class;
    sd->combine =   type;
    sd->alignment = align;
    sd->syms =	    Sym_Create(symbols);
    sd->file =	    file;
    sd->flags =	    flags;
    sd->typeNext =  -1;
    sd->nodata =    FALSE;
    sd->isClassSeg = isClassSeg;

    /*
     * To deal with the insertion that may be necessary, we don't do just a
     * realloc of the old array (besides, we can't realloc a NULL, so we'd need
     * a special case for the first segment, and I hate special cases).
     * Instead, we allocate a new array and copy the old pointers in one at a
     * time (this is still reasonably fast, since we're just copying pointers).
     * If there was a segment with the same class, when we reach the last one
     * with that class, we stick the new descriptor in before looping to fetch
     * the next old segment, thus performing the necessary insertion.
     */
    osegs = seg_Segments;
    seg_Segments = (SegDesc **)malloc(sizeof(SegDesc *) * (seg_NumSegs + 1));
    if (seg_Info == (SegInfo *)NULL)
    {
	seg_Info = (SegInfo *)malloc(sizeof(SegInfo));
	seg_Info[0].segID = NullID;
    }
    else
    {
	seg_Info = (SegInfo *)realloc((void *)seg_Info,
				      sizeof(SegInfo) * (seg_NumSegs + 1));
	seg_Info[seg_NumSegs].segID = NullID;
    }
    for (i = j = 0; i < seg_NumSegs; i++) {
	seg_Segments[j++] = osegs[i];

	if (i == lastClassIndex) {
	    seg_Segments[j++] = sd;
	}
    }

    /*
     * If no other segment with the given class, the new one hasn't been added
     * yet, though there's room for it.
     */
    if (lastClassIndex == -1) {
	seg_Segments[j++] = sd;
    }

    /*
     * Set seg_NumSegs to the new number of segments and free the old array.
     */
    seg_NumSegs += 1;
    free((char *)osegs);

    /*
     * Return the new descriptor.
     */
    return(sd);
}

/***********************************************************************
 *				Seg_AddGroup
 ***********************************************************************
 * SYNOPSIS:	    Record another/Locate a segment
 * CALLED BY:	    Pass1 functions
 * RETURN:	    The group descriptor or NULL if mismatch
 * SIDE EFFECTS:    seg_Groups may be extended
 *
 * STRATEGY:
 *	Groups are global entities and must contain the same number of
 *	segments in each object file, as well as containing the same
 *	segments. This latter part is checked in Seg_EnterGroupMember.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/22/89	Initial Revision
 *
 ***********************************************************************/
GroupDesc *
Seg_AddGroup(const char *file,	    /* File defining the group */
	     ID	    	name)	    /* Group name from output string table */
{
    int	    	    i;
    GroupDesc	    *gd;
    SegAlias	    *sa;

    sa = SegFindAlias(name, NullID);

    if ((sa != NULL) && (sa->aliasMask & SA_NEWNAME)) {
	name = sa->newName;
    }

    for (i = 0; i < seg_NumGroups; i++) {
	gd = seg_Groups[i];

	if (gd->name == name) {
	    /*
	     * Got it.
	     */
	    return(gd);
	}
    }

    /*
     * Allocate a new descriptor and a minimal segs array; the beast will
     * be enlarged as segments are added to the group.
     */
    gd = (GroupDesc *)calloc(1, sizeof(GroupDesc));
    gd->segs = (SegDesc **)malloc(sizeof(SegDesc *));

    /*
     * All other fields are filled in later.
     */
    gd->name = 	    name;
    gd->type =	    S_GROUP;

    /*
     * Enlarge the group descriptor array.
     */
    if (seg_NumGroups == 0) {
	seg_Groups = (GroupDesc **)malloc(sizeof(GroupDesc *));
    } else {
	seg_Groups =
	    (GroupDesc **)realloc((void *)seg_Groups,
				  (seg_NumGroups+1)*sizeof(GroupDesc *));
    }

    /*
     * Place the new group at the end.
     */
    seg_Groups[seg_NumGroups++] = gd;

    /*
     * Return the new descriptor to the caller.
     */
    return(gd);
}



/***********************************************************************
 *				Seg_EnterGroupMember
 ***********************************************************************
 * SYNOPSIS:	    Add a segment to a group at the indicated position.
 * CALLED BY:	    Pass1 functions
 * RETURN:	    Nothing
 * SIDE EFFECTS:    gd->segs[num] overwritten
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/22/89	Initial Revision
 *
 ***********************************************************************/
void
Seg_EnterGroupMember(const char *file,	/* Object file defining the group,
					 * in case of error */
		     GroupDesc	*gd,	/* Group descriptor */
		     SegDesc	*sd)	/* Descriptor for segment. */
{
    int	    i;
    int	    lastClass;

    assert(gd && sd);

    if (sd->group) {
	if (sd->group != gd) {
	    Notify(NOTIFY_ERROR,
		   "%s: segment %i already part of group %i, cannot be part of group %i too",
		   file, sd->name, sd->group->name, gd->name);
	}
	return;
    }
    lastClass = -1;
    for (i = 0; i < gd->numSegs; i++) {
	assert (gd->segs[i] != sd);

	if (gd->segs[i]->class == sd->class) {
	    /*
	     * Class of the current segment matches the one being added. Record
	     * its index as the possible insertion point for the new segment.
	     */
	    lastClass = i;
	} else if (lastClass != -1) {
	    /*
	     * Class doesn't match, but it did for the previous segment. Since
	     * a segment will always be inserted after one with the same class,
	     * this means the new segment cannot be part of this group yet,
	     * so we break out now. i is the slot in which to place the
	     * new segment.
	     */
	    break;
	}
    }

    /*
     * Make room for another pointer in the member array.
     */
    gd->numSegs += 1;
    gd->segs = (SegDesc **)realloc((void *)gd->segs, gd->numSegs*sizeof(SegDesc *));

    /*
     * Mark the segment as belonging to this group.
     */
    sd->group = gd;

    /*
     * Now ripple the following pointers up, inserting the new member in its
     * rightful place.
     */
    while (i < gd->numSegs) {
	SegDesc	*tmp = gd->segs[i];

	gd->segs[i] = sd;
	sd = tmp;
	i++;
    }

}


/***********************************************************************
 *				Seg_Find
 ***********************************************************************
 * SYNOPSIS:	    Locate a segment.
 * CALLED BY:	    Pass 2 functions
 * RETURN:	    The SegDesc * for it.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	This thing has to locate both real segments (in seg_Segments) and
 *	any segments that have been replaced by their group (in seg_SubSegs)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/89	Initial Revision
 *
 ***********************************************************************/
SegDesc *
Seg_Find(const char *file,  	/* Object file name for finding PRIVATE
				 * segments */
	 ID 	    name,   	/* Segment name */
	 ID 	    class)  	/* Class name */
{
    int	    	    i;
    SegAlias	    *sa;

    sa = SegFindAlias(name, class);
    if (sa != NULL) {
	if (sa->aliasMask & SA_NEWNAME) {
	    name = sa->newName;
	}
	if (sa->aliasMask & SA_NEWCLASS) {
	    class = sa->newClass;
	}
    }

    /*
     * Check regular segments first.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];

	if ((sd->name == name) && (sd->class == class))
	{
	    if ((sd->combine != SEG_PRIVATE) || (sd->file == file)) {
		return(sd);
	    }
	}
    }

    /*
     * Check for subsumed segments.
     */
    for (i = 0; i < seg_NumSubSegs; i++) {
	SegDesc	    *sd = seg_SubSegs[i];

	if ((sd->name == name) && (sd->class == class))
	{
	    if ((sd->combine != SEG_PRIVATE) || (sd->file == file)) {
		return(sd);
	    }
	}
    }

    return(NULL);
}


/***********************************************************************
 *				Seg_FindGroup
 ***********************************************************************
 * SYNOPSIS:	    Locate a group descriptor by name.
 * CALLED BY:	    Pass 2 functions
 * RETURN:	    The GroupDesc * for it, if it exists, OR a SegDesc *
 *	    	    if the group was transformed into a segment.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	As noted in the RETURN section, a group can be transformed into
 *	a segment for some output file types, so if the thing isn't
 *	in the seg_Groups array, we look for a segment descriptor with
 *	a null class in seg_Segments.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/89	Initial Revision
 *
 ***********************************************************************/
GroupDesc *
Seg_FindGroup(const char *file,	    /* Object file (for...?) */
	      ID    	name)	    /* Name of group */
{
    int	    	i;
    SegAlias	*sa;

    sa = SegFindAlias(name, NullID);
    if ((sa != NULL) && (sa->aliasMask & SA_NEWNAME)) {
	name = sa->newName;
    }

    for (i = 0; i < seg_NumGroups; i++) {
	GroupDesc   *gd = seg_Groups[i];

	if (gd->name == name) {
	    return(gd);
	}
    }

    for (i = 0; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];

	if ((sd->name == name) && (sd->class == NullID)) {
	    return((GroupDesc *)sd);
	}
    }

    /*
     * Check for subsumed segments.
     */
    for (i = 0; i < seg_NumSubSegs; i++) {
	SegDesc	    *sd = seg_SubSegs[i];

	if ((sd->name == name) && (sd->class == NullID))
	{
	    if ((sd->combine != SEG_PRIVATE) || (sd->file == file)) {
		return((GroupDesc *)sd);
	    }
	}
    }

    return(NULL);
}


/***********************************************************************
 *				Seg_FindPromotedGroup
 ***********************************************************************
 * SYNOPSIS:	    Given a subsumed segment, locate the real segment to
 *	    	    which the segment's group was promoted.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    SegDesc * of the subsumer
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/13/91		Initial Revision
 *
 ***********************************************************************/
SegDesc *
Seg_FindPromotedGroup(SegDesc	*sd)
{
    ID  	name = sd->group->name;
    int 	i;

    assert(sd->type == S_SUBSEGMENT);

    for (i = 0; i < seg_NumSegs; i++) {
	if (seg_Segments[i]->name == name) {
	    return (seg_Segments[i]);
	}
    }

    abort();
}
