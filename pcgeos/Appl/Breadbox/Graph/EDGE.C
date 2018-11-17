/********************************************************************
 *
 *  Copyright (c) 1996 Ken Sievers -- All rights reserved.
 *  Portions Copyright (c) 1996 Blue Marsh Softworks
 *
 * Program     : Graph
 * Module      : Edge, EdgeList, and EdgeNumList routines
 * File        : edge.c
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
 *      This file contains all the routines for the edge, edgelist
 *      and edgenumlist data types.
 *
 *******************************************************************/


//  *****  Included System Header Files  *****
#include    "graph.h"




//  *****  Global Variables  *****
// Defined in GRAPH.C
extern AdjMatrix theGraph;




//*******************************************************************
//                 Edge Operations on AdjMatrix
//*******************************************************************


/********************************************************************
 *                 AMAddEdge
 ********************************************************************
 * SYNOPSIS:     Add an edge to the graph.
 * PARAMETERS:   V1 - First endpoint of edge.
 *               V2 - Second endpoint of edge.
 *               directed - TRUE if directed edge
 * RETURNS:      nothing
 * STRATEGY:     Calculate the edges cost and add the entry to
 *               the edge matrix. Also add an entry in the edge
 *               list portion of the graph.
 * ERRORS:       Will not add if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/14/96  Commented out drawing code
 *       NF      04/20/96  Set the from and to vertices
 *******************************************************************/

void AMAddEdge( VertexNumber V1, VertexNumber V2, boolean directed ) {

   if ( ( V1 < theGraph.AM_vertexCount ) &&
        ( V2 < theGraph.AM_vertexCount ) ) {
      theGraph.AM_costs[V1][V2] =
          PointCalcEdgeCost(
              theGraph.AM_vertices[V1].V_point,
              theGraph.AM_vertices[V2].V_point );
/* We're not using from and to because they are difficult
 * to maintain when you delete vertices from the graph. */
//      theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_fromVertex = V1;
//      theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_toVertex = V2;
//      theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_cost = 0;

      if ( ( directed ) &&
           ( theGraph.AM_costs[V2][V1] == EDGE_MAX_COST ) ) {
         theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_state =
             ES_DIRECTED;
      }
      else {
         theGraph.AM_costs[V2][V1] = theGraph.AM_costs[V1][V2];
         theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_state = 0;
         theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_state = 0;
/* We're not using from and to because they are difficult
 * to maintain when you delete vertices from the graph. */
//         theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_fromVertex = V2;
//         theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_toVertex = V1;
//         theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_cost = 0;
      }

      theGraph.AM_edgeCount++;
/* Handled by portability driver.
      drawLine( theGraph.AM_vertices[V1].V_point.P_x,
                theGraph.AM_vertices[V1].V_point.P_y,
                theGraph.AM_vertices[V2].V_point.P_x,
                theGraph.AM_vertices[V2].V_point.P_y,
                C_BLACK );
*/
   }
   else {
      ErrorMessage( "Invalid input to AMAddEdge()" );
   }

} /* AMAddEdge */




/********************************************************************
 *                 AMAddEdgeNoCheck
 ********************************************************************
 * SYNOPSIS:     Add an edge to the graph without checking for
 *               errors. Used by the file read routine.
 *               Does not assign a cost to the edge.
 * PARAMETERS:   V1 - First endpoint of edge.
 *               V2 - Second endpoint of edge.
 *               directed - TRUE if directed edge
 * RETURNS:      nothing
 * STRATEGY:     Add the entry to the edge matrix and list. Do not
 *               try to calculate the edge cost, since the vertices
 *               may not exist yet.
 * ERRORS:       Does not check. See synopsis.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/22/96  Initial version
 *******************************************************************/

void AMAddEdgeNoCheck( VertexNumber V1,
                       VertexNumber V2,
                       boolean directed ) {

/* We're not using from and to because they are difficult
 * to maintain when you delete vertices from the graph. */
//   theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_fromVertex = V1;
//   theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_toVertex = V2;
//   theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_cost = 0;

   if ( ( directed ) &&
        ( theGraph.AM_costs[V2][V1] == EDGE_MAX_COST ) ) {
      theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_state =
          ES_DIRECTED;
   }
   else {
      theGraph.AM_edges[V1 * VERTEX_MAX_COUNT + V2].E_state = 0;
      theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_state = 0;
/* We're not using from and to because they are difficult
 * to maintain when you delete vertices from the graph. */
//      theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_fromVertex = V2;
//      theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_toVertex = V1;
//      theGraph.AM_edges[V2 * VERTEX_MAX_COUNT + V1].E_cost = 0;
   }

   theGraph.AM_edgeCount++;
/* Handled by portability driver.
   drawLine( theGraph.AM_vertices[V1].V_point.P_x,
             theGraph.AM_vertices[V1].V_point.P_y,
             theGraph.AM_vertices[V2].V_point.P_x,
             theGraph.AM_vertices[V2].V_point.P_y,
             C_BLACK );
*/

} /* AMAddEdgeNoCheck */




/********************************************************************
 *                 AMGenerateRandomEdges
 ********************************************************************
 * SYNOPSIS:     Generate n random edges and add them to the
 *               graph.
 * PARAMETERS:   n - Number of edges to generate
 * RETURNS:      nothing
 * STRATEGY:     Call AMAddEdge n times, using the BetterRandom
 *               routine to provide random vertices to use as
 *               endpoints.
 * ERRORS:       Will not generate if graph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/24/96  Initial version
 *******************************************************************/
void AMGenerateRandomEdges( EdgeNumber n ) {
  VertexNumber i;
  VertexNumber from;
  VertexNumber to;

  if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
    BetterRandom( 1, TRUE );
    i = 0;
    while ( i < n ) {
      from = BetterRandom( theGraph.AM_vertexCount - 1, FALSE );
      to = BetterRandom( theGraph.AM_vertexCount - 1, FALSE );
      AMAddEdge( from, to, TRUE );
      i++;
    }
  }
  else {
    ErrorMessage( "Graph is corrupt in AMGenerateRandomEdges()" );
  }
} /* AMGenerateRandomEdges */




/********************************************************************
 *                 AMGetAdjacentEdges
 ********************************************************************
 * SYNOPSIS:     Return a list of the edges connected to the given
 *               vertex.
 * PARAMETERS:   V - Vertex to get edges from
 *               enl - List of adjacent edges
 * RETURNS:      enl is filled with list of adjacent edges
 * STRATEGY:     Search edge matrix for edges that are have this
 *               vertex as one of their endpoints.
 * ERRORS:       Returns empty list if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/21/96  Not used
 *******************************************************************/
/*
void AMGetAdjacentEdges( VertexNumber V, EdgeNumList * enl ) {

   VertexNumber i;

   enl->ENL_count = 0;

   if ( V < theGraph.AM_vertexCount ) {
      for( i = 0; i < VERTEX_MAX_COUNT; i++ ) {

         if ( ( theGraph.AM_costs[V][i] > 0 ) &&
              ( theGraph.AM_costs[V][i] < EDGE_MAX_COST ) ) {
            enl->ENL_edges[enl->ENL_count] = i;
            enl->ENL_count += 1;
         }
      }
   }

} /* AMGetAdjacentEdges */




/********************************************************************
 *                 AMGetEdgeFromVertex
 ********************************************************************
 * SYNOPSIS:     Get the from-vertex given an edge number.
 * PARAMETERS:   eN - Edge number to get the from-vertex of.
 * RETURNS:      The vertex number
 * STRATEGY:     Take the quotient of the edge number and the
 *               row size to get the from vertex. This is just like
 *               finding the row number of an entry in a 2D matrix
 *               when you know the position in the matrix.
 * ERRORS:       Returns VERTEX_INVALID_NUM if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/16/96  Initial version
 *******************************************************************/

VertexNumber AMGetEdgeFromVertex( EdgeNumber eN ) {

  if ( eN < EDGE_INVALID_NUM ) {
    return( eN / VERTEX_MAX_COUNT );
  }
  else {
    ErrorMessage( "Invalid input to AMGetEdgeFromVertex()" );
    return( VERTEX_INVALID_NUM );
  }

} /* AMGetEdgeFromVertex */




/********************************************************************
 *                 AMGetEdgeNumber
 ********************************************************************
 * SYNOPSIS:     See if there is an edge between two vertices and
 *               return the edge number.
 * PARAMETERS:   V1 - First endpoint of edge.
 *               V2 - Second endpoint of edge.
 * RETURNS:      Edge number (EDGE_INVALID_NUM if no edge exists)
 * STRATEGY:     Check to see if the edge matrix entry is valid,
 *               for the two endpoints, and if so return the
 *               edge number.
 * ERRORS:       Returns EDGE_INVALID_NUM if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/16/96  Initial version
 *       NF      04/22/96  Change EDGE_INVALID_NUM to EDGE_MAX_COST
 *                         since it would almost always fail the
 *                         comparison.
 *******************************************************************/

EdgeNumber AMGetEdgeNumber( VertexNumber V1,
                            VertexNumber V2 ) {
   EdgeNumber e;

   e = EDGE_INVALID_NUM;
   if ( ( V1 < theGraph.AM_vertexCount ) &&
        ( V2 < theGraph.AM_vertexCount ) ) {
      if ( ( theGraph.AM_costs[V1][V2] > 0 ) &&
           ( theGraph.AM_costs[V1][V2] < EDGE_MAX_COST ) ) {
         e = V1 * VERTEX_MAX_COUNT + V2;
      }
   }
   else {
      ErrorMessage( "Invalid input to AMGetEdgeNumber()" );
   }

   return( e );

} /* AMGetEdgeNumber */




/********************************************************************
 *                 AMGetEdgeNumState
 ********************************************************************
 * SYNOPSIS:     Return the state of a given edge.
 * PARAMETERS:   e - Edge to check
 * RETURNS:      State of the edge
 * STRATEGY:     Return the value in the appropriate edge field.
 * ERRORS:       Returns 0 if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/16/96  Initial version
 *******************************************************************/

EdgeState AMGetEdgeNumState( EdgeNumber e ) {

   if ( e < EDGE_INVALID_NUM ) {
      return( theGraph.AM_edges[e].E_state );
   }
   else {
      ErrorMessage( "Invalid input to AMGetEdgeNumState()" );
      return( 0 );
   }
} /* AMGetEdgeNumState */




/********************************************************************
 *                 AMGetEdgeToVertex
 ********************************************************************
 * SYNOPSIS:     Get the to-vertex given an edge number.
 * PARAMETERS:   eN - Edge number to get the to-vertex of.
 * RETURNS:      The vertex number
 * STRATEGY:     Take the modulus of the edge number with the size
 *               of the row in the matrix. This is just like trying
 *               to find the column number of an entry in a 2D
 *               matrix when you know the position in the matrix.
 * ERRORS:       Returns VERTEX_INVALID_NUM if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/16/96  Initial version
 *******************************************************************/

VertexNumber AMGetEdgeToVertex( EdgeNumber eN ) {

  if ( eN < EDGE_INVALID_NUM ) {
    return( eN % VERTEX_MAX_COUNT );
  }
  else {
    ErrorMessage( "Invalid input to AMGetEdgeToVertex()" );
    return( VERTEX_INVALID_NUM );
  }
} /* AMGetEdgeToVertex */




/********************************************************************
 *                 AMGetSelectedEdges
 ********************************************************************
 * SYNOPSIS:     Return a list of edgees that are selected.
 * PARAMETERS:   enl - List of selected edges
 * RETURNS:      enl filled with list of selected edges
 * STRATEGY:     Check each edge to see if it's selected
 *               and if so, add it to the list. Return the list.
 * ERRORS:       Nothing to check
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/17/96  Initial version
 *******************************************************************/

void AMGetSelectedEdges( EdgeNumList * enl ) {

   int i;

   enl->ENL_count = 0;

   for ( i = 0; i < EDGE_MAX_COUNT; i++ ) {

      if ( AMGetEdgeNumState( i ) & ES_SELECTED ) {
         enl->ENL_edges[enl->ENL_count] = i;
         enl->ENL_count += 1;
      }
   }

} /* AMGetSelectedEdges */




/********************************************************************
 *                 AMLocateEdge
 ********************************************************************
 * SYNOPSIS:     Find the edge number given two endpoints specified
 *               by x,y coordinates.
 * PARAMETERS:   x1 - X position for first endpoint
 *               y1 - Y position for first endpoint
 *               x2 - X position for second endpoint
 *               y2 - Y position for second endpoint
 *               directed - TRUE if edge is directed
 * RETURNS:      Edge that is closest. (EDGE_INVALID_NUM if no
 *               edge found)
 * STRATEGY:     Call AMLocateVertex for each endpoint and see
 *               if an edge exists between them.
 * ERRORS:       Returns EDGE_INVALID_NUM if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/22/96  Removed for loop which caused problems
 *                         with locating the correct vertices.
 *******************************************************************/

EdgeNumber AMLocateEdge( int x1, int y1, int x2, int y2 ) {

   EdgeNumber   E;
   VertexNumber vertex1;
   VertexNumber vertex2;

   E = EDGE_INVALID_NUM;
   if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {

      vertex1 = AMLocateVertex( x1, y1 );
      vertex2 = AMLocateVertex( x2, y2 );

      if ( ( vertex1 < VERTEX_MAX_COUNT ) &&
           ( vertex2 < VERTEX_MAX_COUNT ) ) {
         E = vertex1 * VERTEX_MAX_COUNT + vertex2;
      }
   }
   else {
      ErrorMessage( "Graph corrupt in AMLocateEdge()" );
   }
   return( E );

} /* AMLocateEdge */




/********************************************************************
 *                 AMRemoveEdge
 ********************************************************************
 * SYNOPSIS:     Remove an edge from the graph.
 * PARAMETERS:   E - Edge to remove
 *               directed - TRUE if edge is directed
 * RETURNS:      nothing
 * STRATEGY:     Get the two endpoints of the edge and set the
 *               edge matrix entry to zero.
 * ERRORS:       Will not remove if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/25/96  Checked for invalid vertex numbers
 *******************************************************************/

void AMRemoveEdge( EdgeNumber en, boolean directed ) {

   VertexNumber V1;
   VertexNumber V2;

   if ( en < EDGE_INVALID_NUM ) {
      V1 = AMGetEdgeFromVertex( en );
      V2 = AMGetEdgeToVertex( en );
      if ( ( V1 < VERTEX_INVALID_NUM ) &&
           ( V2 < VERTEX_INVALID_NUM ) ) {
// Handled by portability driver.
//         drawLine( theGraph.AM_vertices[V1].V_point.P_x,
//                   theGraph.AM_vertices[V1].V_point.P_y,
//                   theGraph.AM_vertices[V2].V_point.P_x,
//                   theGraph.AM_vertices[V2].V_point.P_y,
//                   C_WHITE );
         theGraph.AM_costs[V1][V2] = EDGE_MAX_COST;
         if ( !directed ) {
            theGraph.AM_costs[V2][V1] = EDGE_MAX_COST;
         }

/* We're not using from and to because they are difficult
 * to maintain when you delete vertices from the graph. */
//         theGraph.AM_edges[en].E_fromVertex = VERTEX_INVALID_NUM;
//         theGraph.AM_edges[en].E_toVertex = VERTEX_INVALID_NUM;
//         theGraph.AM_edges[en].E_cost = 0;
         theGraph.AM_edges[en].E_state = 0;
         theGraph.AM_edgeCount--;
      }
      else {
         ErrorMessage( "Invalid vertex in AMRemoveEdge()" );
      }
   }
   else {
      ErrorMessage( "Invalid input to AMRemoveEdge()" );
   }

} /* AMRemoveEdge */




/********************************************************************
 *                 AMRemoveEdgeList
 ********************************************************************
 * SYNOPSIS:     Remove some edges from the graph given the
 *               list of edges to remove. Assumes they are all
 *               directed edges.
 * PARAMETERS:   enl - List to remove
 * RETURNS:      nothing
 * STRATEGY:     Start a for loop for the number of edges in the
 *               list and remove them by calling AMRemoveEdge.
 * ERRORS:       Will not remove if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/17/96  Initial version
 *******************************************************************/

void AMRemoveEdgeList( EdgeNumList * enl ) {

   int i;

      /*
       * Assume that the edges are directed, as the
       * AMGetSelectedEdges does not check for directedness.
       */
   if ( enl->ENL_count <= EDGE_MAX_COUNT ) {
      for ( i = 0; i < enl->ENL_count; i++ ) {

         AMRemoveEdge( enl->ENL_edges[i], TRUE );

      }
   }
   else {
      ErrorMessage( "Invalid input to AMRemoveEdgeList()" );
   }

} /* AMRemoveEdgeList */




/********************************************************************
 *                 AMSelectAllEdges
 ********************************************************************
 * SYNOPSIS:     Selects all the edges at once.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Start a for loop that sets the appropriate bit
 *               in the E_state field of every edge in the graph.
 * ERRORS:       Nothing to check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/18/96  Initial version
 *******************************************************************/

void AMSelectAllEdges( void ) {
      /* Current working edge number. */
   EdgeNumber curEdge;

   for ( curEdge = 0;
         curEdge < EDGE_MAX_COUNT;
         curEdge++ ) {
      theGraph.AM_edges[curEdge].E_state |= ES_SELECTED;
   }

} /* AMSelectAllEdges */




/********************************************************************
 *                 AMSetEdgeNumState
 ********************************************************************
 * SYNOPSIS:     Set the state of a given edge.
 * PARAMETERS:   e - Edge to change state of
 *               s - New state for edge
 * RETURNS:      nothing
 * STRATEGY:     Set the value in the appropriate edge field.
 * ERRORS:       Will not set if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/16/96  Initial version
 *******************************************************************/

void AMSetEdgeNumState( EdgeNumber e, EdgeState s ) {
      /* Used to get the two possible entries when
       * edge is not directed. */
   VertexNumber toVert, fromVert;
      /* Two possible entries of an undirected edge. */
   EdgeNumber e1, e2;

      /*
       * If the state is directed,
       *   set the one edge state.
       * If the state is not directed,
       *   get from and to vertices, then find both
       *   edges and change both states.
       */
   if ( e < EDGE_INVALID_NUM ) {
      if ( s & ES_DIRECTED ) {
         theGraph.AM_edges[e].E_state = s;
      }
      else {
         toVert = AMGetEdgeToVertex( e );
         fromVert = AMGetEdgeFromVertex( e );
         if ( ( toVert < theGraph.AM_vertexCount ) &&
              ( fromVert < theGraph.AM_vertexCount ) ) {
            e1 = AMGetEdgeNumber( toVert, fromVert );
            e2 = AMGetEdgeNumber( fromVert, toVert );
            if ( ( e1 < EDGE_INVALID_NUM ) &&
                 ( e2 < EDGE_INVALID_NUM ) ) {
               theGraph.AM_edges[e1].E_state = s;
               theGraph.AM_edges[e2].E_state = s;
            }
         }
      }
   }
   else {
      ErrorMessage( "Invalid input to AMSetEdgeNumState()" );
   }

} /* AMSetEdgeNumState */




/********************************************************************
 *                 AMUnselectAllEdges
 ********************************************************************
 * SYNOPSIS:     Unselects all the edges at once.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Start a for loop that clears the appropriate bit
 *               in the E_state field of every edge in the graph.
 * ERRORS:       Nothing to check
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       NF      04/18/96  Initial version
 *******************************************************************/

void AMUnselectAllEdges( void ) {
      /* Current working edge number. */
   EdgeNumber curEdge;

   for ( curEdge = 0;
         curEdge < EDGE_MAX_COUNT;
         curEdge++ ) {
      theGraph.AM_edges[curEdge].E_state &= ~ES_SELECTED;
   }

} /* AMUnselectAllEdges */

