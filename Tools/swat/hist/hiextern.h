/*
 *    			RCS Control Information:
 *    $Author: adam $				
 *    $Date: 91/03/22 01:18:33 $
 *
 *    $Revision: 1.1 $		
 *    $Source: /staff/pcgeos/Tools/swat/hist/RCS/hiextern.h,v $
 *    $State: Exp $
 */

extern char *index(),
	    *malloc();

extern hiSplit(),		/* split up a line into argvs	*/
       hiFmtLine(),		/* fmt a line with a history	*/
       hiSubThis(),		/* substitute from this line	*/
       hiFree(),		/* free the history list	*/
       hiWrite(),		/* write stuff for substitute	*/
       hiPuth();		/* put a line in a HIQUEUE	*/

extern HIST *hiFindLine(),	/* find a line with a word	*/
	    *hiWordLine(),	/* find a line with a string	*/
	    *hiNumLine();	/* number of a line		*/
