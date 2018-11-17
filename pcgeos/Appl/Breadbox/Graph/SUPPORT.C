/********************************************************************
 *
 *  Copyright (c) 1996 Ken Sievers -- All Rights Reserved.
 *  Portions Copyright (c) 1996 Blue Marsh Softworks
 *
 * Program     : Graph
 * Module      : Support routines
 * File        : support.c
 *
 * Programmers : Joe Barbara,     jab315@psu.edu
 *               Tom Denn,        tomtom4828@aol.com
 *               Nathan Fiedler,  nfiedler@aol.com
 *               Ken Sievers,     sievers@epix.net
 *               Lee Stover,      lxs137@psu.edu
 *
 * Compiler    : Borland C++
 *
 * REVISION HISTORY:
 *      Name   Date      Description
 *      ----   ----      -----------
 *       KS    12/04/95  Initial version
 *       KS    03/14/96  Prototype
 *       KS    03/14/96  Working version
 *       KS    03/29/96  GEOS version
 *       KS    04/16/96  Changed struct returns to passing pointers.
 *       NF    04/16/96  Changed naming convention
 *       NF    04/18/96  Added new functions (search on 4/17 and 4/18)
 *      KS,NF  04/19/96  Added file read/write routines
 *
 * DESCRIPTION:
 *      This file contains all the support routines, such as abs,
 *      fabs, BetterRandom, and getch. Also has the union-find ADT.
 *
 *******************************************************************/


//  *****  Included System Header Files  *****

//#include   <stdlib.h>
//#include    <stdio.h>
/* NF - No conio library in GEOS.
#include    <conio.h>   // getch(); */
//#include     <math.h>

#include    "graph.h"




//*******************************************************************
//                    UNION & FIND
//*******************************************************************


/********************************************************************
 *                 find
 ********************************************************************
 * SYNOPSIS:     Find the root of the element.
 * PARAMETERS:   x - Element to find root of
 *               S - Set to search in
 * RETURNS:      Root of element
 * STRATEGY:     If entry is negative, it is the root. Else, call
 *               ourselves recursively until we find the root.
 *               This automatically shortens the height of the
 *               tree through the recursion.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *******************************************************************/
set_type find( element_type x, DISJ_SET S ) {

   if ( S[x] <= 0 ) {
      return( x );
   }
   else {
      return( S[x] = find( S[x], S ) );
   }

} /* find */




/********************************************************************
 *                 initializeSet
 ********************************************************************
 * SYNOPSIS:     Initialize the disjoint set ADT.
 * PARAMETERS:   S - Set to initialize
 * RETURNS:      nothing
 * STRATEGY:     Fill the entries with zero to mark them as not
 *               valid.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *******************************************************************/
void initializeSet( DISJ_SET S ) {

   int i;

   for( i = VERTEX_MAX_COUNT; i > 0; i-- ) {
      S[i] = 0;
   }
} /* initializeSet */




/********************************************************************
 *                 set_union
 ********************************************************************
 * SYNOPSIS:     Join two trees together.
 * PARAMETERS:   S - Set to work with
 *               root1 - Root of first tree
 *               root2 - Root of second tree
 * RETURNS:      nothing
 * STRATEGY:     Make the root of the first tree the root of the
 *               second tree.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *******************************************************************/
void set_union( DISJ_SET S, set_type root1, set_type root2 ) {

   S[root2] = root1;
} /* set_union */




/********************************************************************
 *                 set_union_by_height
 ********************************************************************
 * SYNOPSIS:     Join two trees based on height, where the smaller
 *               tree will be made a branch of the larger tree.
 * PARAMETERS:   S - Set to work with
 *               root1 - Root of first tree
 *               root2 - Root of second tree
 * RETURNS:      nothing
 * STRATEGY:     If second tree is deeper, make it the root of the
 *               first tree. Else, if the two trees are of equal
 *               depth, make the first tree the root of the second
 *               tree and update the depth appropriately.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *******************************************************************/
void set_union_by_height( DISJ_SET S, set_type root1, set_type root2 ) {

   if ( S[root2] < S[root1] ) {       /* root2 is deeper set */
      S[root1] = root2;               /* make root2 new root */
   }
   else {
      if ( S[root2] == S[root1] ) {   /* same height, so update */
         S[root1]--;
      }
      S[root2] = root1;               /* make root1 new root */
   }
} /* set_union_by_height */




//*******************************************************************
//              OTHER SUPPORTING FUNCTIONS
//*******************************************************************


/********************************************************************
 *                 abs
 ********************************************************************
 * SYNOPSIS:     Returns the absolute value of the given integer.
 * PARAMETERS:   x - Integer to make absolute
 * RETURNS:      Absolute value of x
 * STRATEGY:     If x is positive, simply return it. If it is
 *               negative return its inverse.
 * ERRORS:       Nothing to check
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/20/96  Initial version
 *******************************************************************/
int abs( int x ) {

  if ( x >= 0 ) {
    return( x );
  }
  else {
    return( 0 - x );
  }
} /* abs */




/********************************************************************
 *                 BetterRandom
 ********************************************************************
 * SYNOPSIS:     Calculates a new random number based on the seed
 *               value.
 * PARAMETERS:   max - Largest possible return value
 *               randomize - TRUE to randomize seed value.
 * RETURNS:      New random number between 0 and max.
 * STRATEGY:     Uses the algorithm from Data Structures and
 *               Algorithm Analysis by Mark Allen Weiss, p389.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/19/96  Initial version
 *       NF      04/26/96  Fixed the problem that caused stupenduous
 *                         crashes on machines with math processors.
 *******************************************************************/
long BetterRandom( long max, boolean randomize ) {
  long        tempSeed; /* Used to check if number is negative. */
  static long Seed = 1; /* Seed value, saved each time. */

  if ( randomize ) {
    Seed = TimeGetMinSec();
  }
  tempSeed = 48271L * ( Seed % 44488L ) - 3399L * ( Seed / 44488L );
  if ( tempSeed >= 0L ) {
    Seed = tempSeed;
  }
  else {
    Seed = tempSeed + 2147483647L;
  }
     /* Do some type-casting here to prevent coprocessor crash. */
  return( (long)((double)Seed * (double)max / (double)2147483647L ) );
} /* BetterRandom */




/********************************************************************
 *                 fabs
 ********************************************************************
 * SYNOPSIS:     Returns the absolute value of the given double.
 * PARAMETERS:   x - Double to make absolute
 * RETURNS:      Absolute value of x
 * STRATEGY:     If x is positive, simply return it. If it is
 *               negative return its inverse.
 * ERRORS:       Nothing to check
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/20/96  Initial version
 *******************************************************************/
double fabs( double x ) {

  if ( x >= 0.0 ) {
    return( x );
  }
  else {
    return( 0.0 - x );
  }
} /* fabs */




/********************************************************************
 *                 getch
 ********************************************************************
 * SYNOPSIS:     Return the character entered by the user now.
 *               This does not queue the characters. Each time
 *               getch is called the queue will be flushed and
 *               started over again.
 * PARAMETERS:   none
 * RETURNS:      Character user entered right now
 * STRATEGY:     Set the character buffer to zero, then wait for it
 *               to become non-zero. Return the value. This is fed
 *               by the GenView object (view.goc) in the method
 *               for MSG_META_KBD_CHAR.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/11/96  Initial version
 *******************************************************************/
char getch( void ) {

  chCharacter_g = '\0';
  while( chCharacter_g == '\0' ) {
  }
  return( chCharacter_g );
} /* getch */

