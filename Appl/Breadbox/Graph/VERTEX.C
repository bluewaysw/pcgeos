/********************************************************************
 *
 *  Copyright (c) 1996 Ken Sievers -- All rights reserved.
 *  Portions Copyright (c) 1996 Blue Marsh Softworks
 *
 * Program     : Graph
 * Module      : Point, Vertex, and Vertex list routines
 * File        : vertex.c
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
 *      This file contains all the routines for the point, vertex,
 *      and vertex list data types.
 *
 *******************************************************************/


//  *****  Included System Header Files  *****

//#include   <stdlib.h> // srand, random
#include    <stdio.h> // Needed by math.h
// NF - No conio library in GEOS.
//#include    <conio.h>   // getch
#include     <math.h> // sqrt

#include    "graph.h"




//  *****  Global Variables  *****
// Defined in GRAPH.C
extern AdjMatrix theGraph;




//*******************************************************************
//                    Point Operations
//*******************************************************************

/********************************************************************
 *                 PointCalcEdgeCost
 ********************************************************************
 * SYNOPSIS:     The Euclidean distance between two points.
 * PARAMETERS:   P1 - First point
 *               P2 - Second point
 * RETURNS:      Distance between points
 * STRATEGY:     Use the formula z = sqrt( dx*dx + dy*dy )
 * ERRORS:       Garbage in/Garbage out
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/25/96  Corrected for overflow of integer math
 *******************************************************************/

Cost PointCalcEdgeCost( Point_t P1, Point_t P2 ) {
  double deltaX;
  double deltaY;
  double answer;

     /*
      * This is long and tedious but it works this way.
      * Otherwise the problem with selecting the wrong
      * vertex will come up again.
      */
  deltaX = (double)P1.P_x - (double)P2.P_x;
  deltaX *= deltaX;
  deltaY = (double)P1.P_y - (double)P2.P_y;
  deltaY *= deltaY;
  answer = deltaX + deltaY;
  answer = sqrt( answer );
  return ( answer );
} /* PointCalcEdgeCost */




/********************************************************************
 *                 Vertex Operations
 ********************************************************************

/********************************************************************
 *                 VertexDraw
 ********************************************************************
 * SYNOPSIS:     Draw a vertex on the screen.
 * PARAMETERS:   V - Vertex to draw
 *               c - Color to draw in
 * RETURNS:      nothing
 * STRATEGY:     Call drawNode.
 * ERRORS:       Nothing to check
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/21/96  Not used
 *******************************************************************/
/*
void VertexDraw( Vertex V, ElementColor c ) {

   drawNode( V.V_point.P_x, V.V_point.P_y, c, V.V_state );

} /* VertexDraw */




/********************************************************************
 *                 VertexNumList Operations
 *******************************************************************/

/********************************************************************
 *                 VertexNumListAddNumber
 ********************************************************************
 * SYNOPSIS:     Adds the given vertex number to the given
 *               vertex number list.
 * PARAMETERS:   VL - Vertex number list to remove V from
 *               V - Vertex number to add
 * RETURNS:      nothing
 * STRATEGY:     Check to see if the number is already in the list,
 *               and if not add the vertex number to the end of the
 *               list and increment the count.
 * ERRORS:       Will not add if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *      JB,NF    04/24/96  Initial version
 *******************************************************************/
void VertexNumListAddNumber( VertexNumList * VL, VertexNumber V ) {

   if ( ( V < VERTEX_INVALID_NUM ) &&
        ( VL->VNL_count <= VERTEX_MAX_COUNT ) ) {
      if ( !VertexNumListIsVertexInList( VL, V ) ) {
         VL->VNL_vertices[VL->VNL_count] = V;
         VL->VNL_count++;
      }

   }
   else {
      ErrorMessage( "Invalid input to VertexNumListAddNumber()" );
   }

} /* VertexNumListAddNumber */




/********************************************************************
 *                 VertexNumListIsVertexInList
 ********************************************************************
 * SYNOPSIS:     Checks if the given vertex number appears in the
 *               given vertex number list.
 * PARAMETERS:   VL - Vertex number list to search
 *               V - Vertex number to find
 * RETURNS:      TRUE if vertex number in list
 * STRATEGY:     Search the list using a while loop to find the
 *               matching vertex number.
 * ERRORS:       Returns FALSE on invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/16/96  Initial version
 *******************************************************************/
boolean VertexNumListIsVertexInList( VertexNumList * VL, VertexNumber V ) {

   VertexNumber i;
   boolean found;

   found = FALSE;
   if ( ( V < VERTEX_INVALID_NUM ) &&
        ( VL->VNL_count <= VERTEX_MAX_COUNT ) ) {
      i = 0;
      while ( i < VL->VNL_count ) {
         if ( V == VL->VNL_vertices[i] ) {
            found = TRUE;
         }
         i++;
      }
   }
   else {
      ErrorMessage( "Invalid input to VertexNumListIsVertexInList()" );
   }
   return( found );

} /* VertexNumListIsVertexInList */




/********************************************************************
 *                 VertexNumListRemoveNumber
 ********************************************************************
 * SYNOPSIS:     Removes the given vertex number from the given
 *               vertex number list.
 * PARAMETERS:   VL - Vertex number list to remove V from
 *               V - Vertex number to remove
 * RETURNS:      TRUE if vertex number was removed
 * STRATEGY:     Search the list using a while loop to find the
 *               matching vertex number. Then if it is found use
 *               another while loop to remove it.
 * ERRORS:       Returns FALSE on invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/23/96  Initial version
 *******************************************************************/
boolean VertexNumListRemoveNumber( VertexNumList * VL, VertexNumber V ) {

   VertexNumber i;
   boolean found;

   found = FALSE;
   if ( ( V < VERTEX_INVALID_NUM ) &&
        ( VL->VNL_count <= VERTEX_MAX_COUNT ) ) {
      i = 0;
      while ( ( i < VL->VNL_count ) && ( !found ) ) {
         if ( V == VL->VNL_vertices[i] ) {
            found = TRUE;
         }
         i++;
      }
      if ( found ) {

         i--;
         VL->VNL_count--;
         while ( i < VL->VNL_count ) {
            VL->VNL_vertices[i] = VL->VNL_vertices[i+1];
            i++;
         }

      }
   }
   else {
      ErrorMessage( "Invalid input to VertexNumListRemoveNumber()" );
   }
   return( found );

} /* VertexNumListRemoveNumber */




/********************************************************************
 *                 VertexList Operations
 *******************************************************************/

/********************************************************************
 *                 VertexListDraw
 ********************************************************************
 * SYNOPSIS:     Draw a list of vertices.
 * PARAMETERS:   V - List of vertices to draw
 *               c - Color to draw them in
 * RETURNS:      nothing
 * STRATEGY:     Use a for loop to draw the list of vertices,
 *               calling VertexDraw each time.
 * ERRORS:       Will not draw on invalid input
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/21/96  Not used
 *******************************************************************/
/*
void VertexListDraw( VertexList * VL, ElementColor c ) {

   VertexNumber i;

   //  *****  Draw Vertices  *****

   if ( VL->VL_count <= VERTEX_MAX_COUNT ) {
      for ( i = 0; i < VL->VL_count; i++ ) {
         VertexDraw( VL->VL_vertices[i], c );
      }
   }

} /* VertexListDraw */




/********************************************************************
 *                 Vertex Operations on an Adjacency Matrix
 *******************************************************************/

/********************************************************************
 *                 AMAddVertex
 ********************************************************************
 * SYNOPSIS:     Adds a new vertex to the graph.
 * PARAMETERS:   newPt - x,y of the new point
 * RETURNS:      Number of new vertex. (VERTEX_INVALID_NUM if list
 *               is full)
 * STRATEGY:     Store the x,y of the new point at the end of the
 *               vertex list, then draw it. Don't forget to bump
 *               up the vertex count, then return it to the caller.
 * ERRORS:       Returns VERTEX_INVALID_NUM when vertex list
 *               becomes full.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      03/29/96  Corrected counter increment
 *       NF      04/13/96  Had it return new vertex number
 *                         and clear the fields explicitly
 *******************************************************************/

VertexNumber AMAddVertex( Point_t newPt ) {

   VertexNumber i;

   i = theGraph.AM_vertexCount;
   if ( i < VERTEX_MAX_COUNT ) {
      theGraph.AM_vertices[i].V_point.P_x = newPt.P_x;
      theGraph.AM_vertices[i].V_point.P_y = newPt.P_y;
      theGraph.AM_vertices[i].V_state = 0;
//      theGraph.AM_vertices[i].V_degreeIn = 0;
//      theGraph.AM_vertices[i].V_degreeOut = 0;
      theGraph.AM_vertices[i].V_cost = 0;

/* NF - Let portability driver do this.
      VertexListDraw( &theGraph.AM_vertices, C_BLACK ); */

      theGraph.AM_vertexCount += 1;
      return( i );
   }
   else {
      return( VERTEX_INVALID_NUM );
   }

} /* AMAddVertex */




/********************************************************************
 *                 AMGenerateRandomVertices
 ********************************************************************
 * SYNOPSIS:     Create n random vertices.
 * PARAMETERS:   n - Number of new vertices to make
 * RETURNS:      nothing
 * STRATEGY:     Randomize the random number generator, then
 *               get two random values for x,y and create a new
 *               vertex. Do this n times.
 * ERRORS:       Will fill vertex list if number too large.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/15/96  Initial version
 *       NF      04/17/96  Corrected for crashing problem
 *******************************************************************/

void AMGenerateRandomVertices( VertexNumber n ) {
  VertexNumber i;
  Point_t      newPt;
  VertexNumber newVertex;

  BetterRandom( 1, TRUE );
  i = 0;
  newVertex = 0;
  while ( ( i < n ) && ( newVertex < VERTEX_MAX_COUNT ) ) {
    newPt.P_x = BetterRandom( 1000, FALSE );
    newPt.P_y = BetterRandom( 1000, FALSE );
    newVertex = AMAddVertex( newPt );
    i++;
  }
} /* AMGenerateRandomVertices */




/********************************************************************
 *                 AMGetAdjacentVertices
 ********************************************************************
 * SYNOPSIS:     Return a list of vertices attached to the given
 *               vertex.
 * PARAMETERS:   v - Vertex to get adjacent vertices of
 *               vnl - Empty VertexNumList to be filled in
 * RETURNS:      vnl is filled with list of adjacent vertices
 * STRATEGY:     Check each vertex to see if it's attached to this
 *               one and if so, add it to the list. Return the list.
 * ERRORS:       Returns empty list if v is invalid.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/17/96  Repalced return of struct with var
 *                         parameter
 *******************************************************************/

void AMGetAdjacentVertices( VertexNumber v, VertexNumList * vnl ) {

   VertexNumber i;

   vnl->VNL_count = 0;

   if ( v < theGraph.AM_vertexCount ) {
      for ( i = 0; i < VERTEX_MAX_COUNT; i++ ) {

         if ( ( theGraph.AM_costs[v][i] > 0 ) &&
              ( theGraph.AM_costs[v][i] < EDGE_MAX_COST ) ) {
            vnl->VNL_vertices[vnl->VNL_count] = i;
            vnl->VNL_count += 1;
         }
      }
   }
   else {
      ErrorMessage( "Invalid input to AMGetAdjacentVertices()" );
   }

} /* AMGetAdjacentVertices */




/********************************************************************
 *                 AMGetSelectedVertices
 ********************************************************************
 * SYNOPSIS:     Return a list of vertices that were selected.
 * PARAMETERS:   vlist - List of selected vertices
 * RETURNS:      vlist filled with list of selected vertices
 * STRATEGY:     Check each vertex to see if it's selected
 *               and if so, add it to the list. Build the list in
 *               order from lowest numbered vertex to highest.
 *               Return the list.
 * ERRORS:       Returns empty list if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/14/96  Initial version
 *******************************************************************/

void AMGetSelectedVertices( VertexNumList * vlist ) {

   VertexNumber i;

   vlist->VNL_count = 0;

      /*
       * It is important to build the list from lowest numbered
       * vertex to the highest numbered vertex. AMRemoveVertexList
       * uses this fact to remove a list a vertices.
       */
   if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
      for ( i = 0; i < theGraph.AM_vertexCount; i++ ) {

         if ( theGraph.AM_vertices[i].V_state & ES_SELECTED ) {
            vlist->VNL_vertices[vlist->VNL_count] = i;
            vlist->VNL_count += 1;
         }
      }
   }
   else {
      ErrorMessage( "Invalid input to AMGetSelectedVertices()" );
   }

} /* AMGetSelectedVertices */




/********************************************************************
 *                 AMGetVertexState
 ********************************************************************
 * SYNOPSIS:     Return the state of a given vertex.
 * PARAMETERS:   v - Vertex to check
 * RETURNS:      State of the vertex
 * STRATEGY:     Return the value in the appropriate vertex field.
 * ERRORS:       Returns 0 on invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/13/96  Initial version
 *******************************************************************/

VertexState AMGetVertexState( VertexNumber v ) {

   if ( v < theGraph.AM_vertexCount ) {
      return( theGraph.AM_vertices[v].V_state );
   }
   else {
      ErrorMessage( "Invalid input to AMGetVertexState()" );
      return( 0 );
   }

} /* AMGetVertexState */




/********************************************************************
 *                 AMLocateVertex
 ********************************************************************
 * SYNOPSIS:     Find a vertex in the graph that is the closest to
 *               the given x,y coordinates.
 * PARAMETERS:   x - X position of point to find
 *               y - Y position of point to find
 * RETURNS:      Number of closest vertex. (VERTEX_INVALID_NUM if
 *               missed)
 * STRATEGY:     Check each vertex and evaluate the cost from that
 *               vertex to the x,y point. Return the vertex with
 *               the smallest cost. If point too far away, return
 *               an invalid vertex number.
 * ERRORS:       Returns VERTEX_INVALID_NUM if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/13/96  Took out AMAddVertex code (see below)
 *******************************************************************/

VertexNumber AMLocateVertex( int x, int y ) {

   Point_t      newPt;
   VertexNumber closestVertex;
   VertexNumber curVertex;

   newPt.P_x = x;
   newPt.P_y = y;
   closestVertex = VERTEX_INVALID_NUM;

   if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
      for ( curVertex = 0;
            curVertex < theGraph.AM_vertexCount;
            curVertex++ ) {
         if ( PointCalcEdgeCost( newPt,
                  theGraph.AM_vertices[curVertex].V_point ) <
              VERTEX_WIDTH ) {
            closestVertex = curVertex;
            break;
         }

      }

/* NF - This is handled by portability driver.
      if ( closestVertex > VERTEX_MAX_COUNT ) {
         AMAddVertex( newPt );
         closestVertex = VERTEX_INVALID_NUM;
      }
*/
   }
   else {
      ErrorMessage( "Graph corrupted in AMLocateVertex()" );
   }
   return( closestVertex );

} /* AMLocateVertex */




/********************************************************************
 *                 AMRemoveVertex
 ********************************************************************
 * SYNOPSIS:     Remove a vertex from the graph given the index to
 *               the vertex.
 * PARAMETERS:   V - Number of vertex to remove
 * RETURNS:      nothing
 * STRATEGY:     Decrement the number of vertices. Move all the
 *               other vertices down one in the array. Remove the
 *               Vth row and column from the edge cost matrix.
 * ERRORS:       Will not remove if theGraph is correct or the
 *               input is invalid.
 * NOTES:        If you ever want to use the fromVertex and
 *               toVertex fields of the edge types, be sure to
 *               reassign those fields in this function.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/14/96  Replaced the use of V with i
 *      KS,NF    04/16/96  Corrected problem with criss-crossing
 *                         delete algorithm
 *       NF      04/17/96  Corrected problem on for loop parameters.
 *                         Wasn't copying everything and clearing
 *                         the edges.
 *       NF      04/20/96  Corrected the removal of the edges as
 *                         stored in theGraph.AM_edges
 *******************************************************************/

void AMRemoveVertex( VertexNumber V ) {

   VertexNumber i;
   VertexNumber j;

   theGraph.AM_vertexCount -= 1;

/* NF - Handled by portability driver.
   VertexDraw( V, C_WHITE ); */

   if ( ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) &&
        ( V <= theGraph.AM_vertexCount ) ) {
      for ( i = V; i < theGraph.AM_vertexCount; i++ ) {

         theGraph.AM_vertices[i].V_point.P_x =
             theGraph.AM_vertices[i+1].V_point.P_x;

         theGraph.AM_vertices[i].V_point.P_y =
             theGraph.AM_vertices[i+1].V_point.P_y;
/* Not used currently.
         theGraph.AM_vertices[i].V_degreeIn =
             theGraph.AM_vertices[i+1].V_degreeIn;

         theGraph.AM_vertices[i].V_degreeOut =
             theGraph.AM_vertices[i+1].V_degreeOut;
*/
         theGraph.AM_vertices[i].V_cost =
             theGraph.AM_vertices[i+1].V_cost;

         theGraph.AM_vertices[i].V_state =
             theGraph.AM_vertices[i+1].V_state;

      } // for i

      // Move rows up one to cover over deleted edges.
      for ( i = V; i < theGraph.AM_vertexCount; i++ ) {

         for ( j = 0; j <= theGraph.AM_vertexCount; j++ ) {
            theGraph.AM_costs[i][j] = theGraph.AM_costs[i+1][j];
            theGraph.AM_edges[i * VERTEX_MAX_COUNT + j] =
                theGraph.AM_edges[(i + 1) * VERTEX_MAX_COUNT + j];
         }
      }

      // Move columns left one to cover over deleted edges.
      for ( i = V; i < theGraph.AM_vertexCount; i++ ) {

         for ( j = 0; j <= theGraph.AM_vertexCount; j++ ) {
            theGraph.AM_costs[j][i] = theGraph.AM_costs[j][i+1];
            theGraph.AM_edges[j * VERTEX_MAX_COUNT + i] =
                theGraph.AM_edges[j * VERTEX_MAX_COUNT + i + 1];
         }
      }

      // Clear out the far right and bottom entries of edges.
      for ( i = 0; i <= theGraph.AM_vertexCount; i++ ) {
         AMRemoveEdge( i * VERTEX_MAX_COUNT +
                       theGraph.AM_vertexCount, FALSE );
      }
   } // if
   else {
      ErrorMessage( "Invalid input to AMRemoveVertex()" );
   }

} /* AMRemoveVertex */




/********************************************************************
 *                 AMRemoveVertexList
 ********************************************************************
 * SYNOPSIS:     Remove some vertices from the graph given the
 *               list of vertices to remove.
 * PARAMETERS:   V - List to remove
 * RETURNS:      nothing
 * STRATEGY:     Start a for loop for the number of vertices in the
 *               list and remove them by calling AMRemoveVertex.
 *               You must delete them in reverse order, from the
 *               highest numbered vertex to the lowest.
 * ERRORS:       Will not remove if input invalid.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/14/96  Initial version
 *       NF      04/15/96  Changed to remove in reverse order
 *******************************************************************/

void AMRemoveVertexList( VertexNumList * vnl ) {

   int i; // Don't try to make this unsigned or else the
          // for loop below will always be true.

   if ( vnl->VNL_count <= theGraph.AM_vertexCount ) {
      for ( i = ( vnl->VNL_count - 1 ); i >= 0; i-- ) {

         AMRemoveVertex( vnl->VNL_vertices[i] );

      }
   }
   else {
      ErrorMessage( "Invalid input to AMRemoveVertexList()" );
   }

} /* AMRemoveVertexList */




/********************************************************************
 *                 AMSelectAllVertices
 ********************************************************************
 * SYNOPSIS:     Selects all the vertices at once.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Use a for loop to set the appropriate bit in the
 *               V_state field of every vertex.
 * ERRORS:       Will not select if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/15/96  Initial version
 *******************************************************************/

void AMSelectAllVertices( void ) {
     /* Current working vertex number. */
  VertexNumber curVert;

  if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
    for ( curVert = 0;
          curVert < theGraph.AM_vertexCount;
          curVert++ ) {
       AMSetVertexState( curVert,
                         AMGetVertexState( curVert ) | VS_SELECTED );
    }
  }
  else {
      ErrorMessage( "Graph corrupt in AMSelectAllVertices()" );
  }

} /* AMSelectAllVertices */




/********************************************************************
 *                 AMSetVertexState
 ********************************************************************
 * SYNOPSIS:     Set the state of a given vertex.
 * PARAMETERS:   v - Vertex to change state of
 *               s - New state for vertex
 * RETURNS:      nothing
 * STRATEGY:     Set the value in the appropriate vertex field.
 * ERRORS:       Will not set if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/13/96  Initial version
 *******************************************************************/

void AMSetVertexState( VertexNumber v, VertexState s ) {

   if ( v < theGraph.AM_vertexCount ) {
      theGraph.AM_vertices[v].V_state = s;
   }
   else {
      ErrorMessage( "Invalid input to AMSetVertexState()" );
   }

} /* AMSetVertexState */




/********************************************************************
 *                 AMUnselectAllVertices
 ********************************************************************
 * SYNOPSIS:     Unselects all the vertices at once.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Use a for loop to clear the appropriate bit in
 *               the V_state field of every vertex.
 * ERRORS:       Will not unselect if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/15/96  Initial version
 *******************************************************************/

void AMUnselectAllVertices( void ) {
     /* Current working vertex number. */
  VertexNumber curVert;

  if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
    for ( curVert = 0;
          curVert < theGraph.AM_vertexCount;
          curVert++ ) {
      AMSetVertexState( curVert,
                        AMGetVertexState( curVert ) & ~VS_SELECTED );
    }
  }
  else {
    ErrorMessage( "Graph corrupt in AMUnselectAllVertices()" );
  }

} /* AMUnselectAllVertices */

