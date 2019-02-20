/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:28 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hidefs.h,v $
 *    $State: Exp $
 */
#include <stdio.h>
#include <ctype.h>

#define FALSE		0
#define TRUE		1

/*
 *    Internal buffer size.
 */
#define INTERNAL_BUFSIZ		 BUFSIZ		/* good enough for now	*/

/*
 *    Types of history substitutions
 */
#define SU_THIS			0	/* current line		!	*/
#define SU_LAST			1	/* last line		!!	*/
#define SU_LSEARCH		2	/* line search		!ho	*/
#define SU_NUMBER		3	/* numbered search	!33	*/
#define SU_SEARCH		4	/* word search		!?foo	*/
#define SU_LASTFIRST		5	/* last on last line	!^	*/
#define SU_LASTLAST		6	/* last on last line	!$	*/
#define SU_LASTALL		7	/* last on last line	!*	*/
#define SU_RELATIVE		8	/* relative numbered 	!-3	*/
#define SU_NOSEARCH		9	/* no search subc alone	! 	*/

/*
 *    The standard special characters
 */
#define STD_ESC			'\0'
#define STD_SQUOT		'\''
#define STD_DQUOT		'"'
#define STD_BQUOT		'`'

/*
 *    The standard history substitution character
 */
#define STD_SUBC		'!'
#define STD_LASTC		'^'


#define FM_ERROR		-1	/* could not expand	*/
#define FM_HIST			0	/* had history subs	*/
#define FM_CLEAN		1	/* no history subs	*/
