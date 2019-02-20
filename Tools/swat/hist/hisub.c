/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:19:08 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hisubthis.c,v $
 *    $State: Exp $
 */
#include "hidefs.h"
#include "hist.h"
#include "hiextern.h"

/*
 *    The purpose of thiUsE function is to substitute stuff on the current
 *    line.
 */
hiSubThis(space, size, type, hi, esc)
char *space;
int size;		/* size left in space			*/
char **type;		/* as yet unparsed history substitution	*/
HIST *hi;		/* current line's history		*/
char esc;		/* current escape character		*/
{
	register int loLimit,	/* lower upLimit		*/
		     upLimit;	/* can print so much	*/

	/*
	 *    Move *type over the ':' (which could be there) and over 
	 *    the colonSpecifier character so as not to leave it on the
	 *    line for later.   If you are wrong ( ! or !: cases), then
	 *    just undo the damage later.
	 */
	if (**type == ':') {
	    (*type)++;
	}
	switch (*(*type)++) {
	case '*':
	    /*
	     *    !:*    Just check to see if there is an argv[1]
	     */
	    loLimit = 1;
	    if (hi->argc < 2)
		return (hiErrno = HI_SUBC, -1);
	    upLimit = hi->argc;
	    break;
	case '-':
	    /*
	     *    !:-$   !:-*   !:-^   !:-n
	     */
	    loLimit = 0;
	    upLimit = 0;
	    switch (*(*type)++) {
	    case '*':
	    case '$':
		/*
		 *    !:-$      '$' always ok
		 *    !:-*	'*' always ok
		 */
		upLimit = hi->argc;
		break;
	    case '^':
		/*
		 *    !:-^	'^' bad only if argv[1] not there
		 */
		if (hi->argc < 2)
		    return (hiErrno = HI_TOOGREAT, -1);
	 	upLimit = 2;
		break;
	    case '0':
	    case '1':
	    case '2':
	    case '3':
	    case '4':
	    case '5':
	    case '6':
	    case '7':
	    case '8':
	    case '9':
		--(*type);	 	/* dec b/c of inc in switch () */
		upLimit = atoi(*type)+1;
		while (isdigit(**type))
		    (*type)++;
		if (upLimit > hi->argc)
		    return (hiErrno = HI_TOOGREAT, -1);
		break;
	    default:
		return (hiErrno = HI_SUBC, -1);
	    }
	    break;
	case '^':
	    /*
	     *    !:^    Just check to see that there is an argv[1]
	     */
	    if (hi->argc < 2)
		return (hiErrno = HI_TOOGREAT, -1);
	    loLimit = 1;
	    upLimit = 2;
	    break;
	case '$':
	    /*
	     *    !:$     Just check to see if there is any word at all
	     */
	    if ((upLimit = hi->argc) < 1)
		return(hiErrno = HI_SUBC, -1);
	    loLimit = upLimit-1;
	    break;
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	    /*
	     *    !:n-n   !:n	!:n*
	     */
	    --(*type);	 	/* dec b/c of inc in switch () */
	    /*
	     *    !:n  (at least)	check n for bounds
	     */
	    if ((loLimit = atoi(*type)) > hi->argc)
		return (hiErrno = HI_TOOGREAT, -1);
	    while (isdigit(**type))
		(*type)++;
	    upLimit = loLimit+1;	/* assume unless otherwise...	*/
	    /*
	     *    Looking after the n in !:n... here
	     */
	    switch (*(*type)++) {
	    case '*':
		/*
		 *    !:n*		'*' always ok.
		 */
		upLimit = hi->argc;
		break;
	    case '-':
		/*
		 *    !:n-n	check for n1 > n2,  n2 out of bounds
		 */
		upLimit = atoi(*type)+1;
		if (upLimit <= loLimit) 	/* remember the +1	*/
		    return (hiErrno = HI_MIXUP, -1);
		if (upLimit > hi->argc)
		    return (hiErrno = HI_TOOGREAT, -1);
		while (isdigit(**type))
		    (*type)++;
		break;
	    default:
		/*
		 *    !:n		always ok.
		 *
		 *    (*type)-- to back up from switch (*(*type)++)
		 */
		(*type)--;
		break;
	    }
	    break;
	default:
	    /*
	     *    !	or 	!:
	     *
	     *    Same as '*' because there is no word specifier.
	     */
	    (*type)--;				/* to back up from switch (*(*type)++)	*/
/*	    *type -= ((*type)[-1] != ':');	/* go back one if there was no ':'	*/
	    loLimit = 0;
	    upLimit = hi->argc;
	    break;
	}
	return (hiWrite(space, size, loLimit, upLimit, hi, esc));
}
