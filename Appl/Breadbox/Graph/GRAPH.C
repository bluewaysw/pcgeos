/********************************************************************
 *
 *  Copyright (c) 1996 Ken Sievers -- All rights reserved.
 *  Portions Copyright (c) 1996 Blue Marsh Softworks
 *
 * Program     : Graph
 * Module      : Graph and drawing routines
 * File        : graph.c
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
 *      This file contains all the ADT functions for an adjacency
 *      matrix, as well as the drawing functions.
 *
 *******************************************************************/


//  *****  Included System Header Files  *****

//#include   <stdlib.h>
//#include    <stdio.h>
/* NF - No conio library in GEOS.
#include    <conio.h>   // getch(); */
//#include     <math.h>
#include    <ctype.h> // for toupper

#include    "graph.h"
#include    "queue.h" // Queue ADT for BFS
#include    "stack.h" // Stack ADT for DFS




//  *****  Global Variables  *****
AdjMatrix theGraph;




//*******************************************************************
//                 Adjacency Matrix Operations
//*******************************************************************

//*******************************************************************
//               GRAPH FUNCTIONS
//*******************************************************************

/********************************************************************
 *                 AMInitializeGraph
 ********************************************************************
 * SYNOPSIS:     Initalize the Adjanency Matrix.
 * PARAMETERS:   Adjacency Matrix
 * RETURNS:      nothing
 * STRATEGY:     Initalize the graph by assigning costs to every
 *               entry in the edge matrix.
 * ERRORS:       Nothing to check
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/14/96  Initial version
 *******************************************************************/

void AMInitializeGraph( void ) {

   int i;
   int j;

   theGraph.AM_vertexCount = 0;
   theGraph.AM_edgeCount = 0;

   for ( i = 0; i < VERTEX_MAX_COUNT; i++ ) {

      theGraph.AM_vertices[i].V_point.P_x = 0;
      theGraph.AM_vertices[i].V_point.P_y = 0;
      theGraph.AM_vertices[i].V_state     = 0;
      theGraph.AM_vertices[i].V_cost      = 0;

      for ( j = 0; j < VERTEX_MAX_COUNT; j++ ) {
         theGraph.AM_costs[i][j] = EDGE_MAX_COST;
      }
   }

   for ( i = 0; i < EDGE_MAX_COUNT; i++ ) {
// See EDGE.C for why we are not using these.
//      theGraph.AM_edges[i].E_fromVertex = VERTEX_INVALID_NUM;
//      theGraph.AM_edges[i].E_toVertex = VERTEX_INVALID_NUM;
//      theGraph.AM_edges[i].E_cost = 0;
      theGraph.AM_edges[i].E_state = 0;
   }

} /* AMInitializeGraph */




/********************************************************************
 *                 AMMakeCompleteGraph
 ********************************************************************
 * SYNOPSIS:     Make the graph complete.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Make the graph complete by assigning valid costs
 *               to every entry in the edge matrix
 * ERRORS:       Does nothing if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/20/96  Changed to use the existing primitives
 *******************************************************************/

void AMMakeCompleteGraph( void ) {

   int i;
   int j;

   if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
      for( i = 0; i < theGraph.AM_vertexCount; i++ ) {
         for( j = 0; j < theGraph.AM_vertexCount; j++ ) {
            // Add a directed edge bewteen vertices i and j
            // which will really make the edge undirected
            // because we're doing it for all possible edges.
            AMAddEdge( i, j, TRUE );
         }
      }
   }
   else {
      ErrorMessage( "Graph corrupt in AMMakeCompleteGraph()" );
   }

} /* AMMakeCompleteGraph */




/********************************************************************
 *                 AMMakeSelectedComplete
 ********************************************************************
 * SYNOPSIS:     Make the selected vertices complete.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Make the selected vertices complete
 *               by assigning costs to thier
 *               entry in the edge matrix.
 * ERRORS:       Does nothing if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       NF      04/20/96  Changed to use the existing primitives
 *******************************************************************/

void AMMakeSelectedComplete( void ) {

  int i;
  int j;

  if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
    for( i = 0; i < theGraph.AM_vertexCount; i++ ) {
      for( j = ( i + 1 ); j < theGraph.AM_vertexCount; j++ ) {

        // Add an edge if the two endpoints are selected.
        // Make it an undirected edge.
        if ( ( theGraph.AM_vertices[i].V_state & VS_SELECTED ) &&
             ( theGraph.AM_vertices[j].V_state & VS_SELECTED ) ) {
          AMAddEdge( i, j, FALSE );
        }
      }
    }
  }
  else {
    ErrorMessage( "Graph corrupt in AMMakeSelectedComplete()" );
  }

} /* AMMakeSelectedComplete */




/********************************************************************
 *                 SEARCH FUNCTIONS
 *******************************************************************/


/********************************************************************
 *                 BFS
 ********************************************************************
 * SYNOPSIS:     Perform the Breath First Search on the graph.
 * PARAMETERS:   startVertex - Vertex to start searching
 *               goalVertex - Vertex to find
 *               bfs_edgelist - List of edges returned here
 * RETURNS:      bfs_edgelist filled with visited edges
 * STRATEGY:     Used to calculate the Edge Num: the number of
 *               vertices used in the adjacency matrix plus one,
 *               times the row number, plus the column number.
 *               ( ( theGraph.AM_vertices.VL_count + 1 )
 *                 * row # ) + column #
 * ERRORS:       Does not check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       TD      04/22/96  Initial version
 *******************************************************************/

boolean BFS( VertexNumber  startVertex,
             VertexNumber  goalVertex,
             EdgeNumList * bfs_edgelist )
{
   VertexNumber  row;           /* Row of adjacency matrix */
   VertexNumber  col;           /* Column of adjacency matrix */
   boolean       found = FALSE; /* Goal vertex found */
   ptrToQueueType queue;        /* Queue data type. */

   /*Initalize EdgeNumList Vertex counter=0 (ie Empty)*/
   bfs_edgelist->ENL_count = 0;

   queue = MakeEmptyQueue();
   /*Check if verticies are ever the same*/
   if ( startVertex != goalVertex )
      {  /* If not, set all KNOWN and SELECTED bits to false. */
      for ( row = 0; row < theGraph.AM_vertexCount; row++ )
         {
         theGraph.AM_vertices[row].V_state &= ~VS_KNOWN;
         } /* end loop to set graph to not visited */

      /*Set FRONT and REAR to to point to the first element of the Q*/
      /*Put starting vertex number on the Q*/
      Enqueue( queue, startVertex );

      /*While there are still verticies to explore...ie the Queue
      * is not empty and the goal node has not been found,
      * enqueue next one and look at all it's neighbors*/
      while ( !IsEmptyQueue( queue ) && !found )
         {
         /*Calculate row to which the vertex in the Q[front] has
         * its neighboors listed under */
         Dequeue( queue, &row );
         theGraph.AM_vertices[row].V_state |= VS_KNOWN;

         /*Set col to start at first column of matrix*/
         /* This is where we look for the adjacent vertices
          * and add them to the queue. */
         col = 0;
         while ( ( col < theGraph.AM_vertexCount ) && !found )
            {
            /*If it is a valid vertex and not been selected yet,
            * enqueue its neighboors*/
            if ( ( theGraph.AM_costs[row][col] > 0 ) &&
                 ( theGraph.AM_costs[row][col] < EDGE_MAX_COST ) &&
                 ( ( theGraph.AM_vertices[col].V_state & VS_KNOWN ) == 0 ) )
               {

               /*Check if goal vertex found, add it to the
               * vertex list if you did*/
               if ( col == goalVertex )
                  {
                  found = TRUE;
                  }
               else
                  {
                  Enqueue( queue, col );
                  }/*End IF*/
               bfs_edgelist->ENL_edges[bfs_edgelist->ENL_count] =
                   row * VERTEX_MAX_COUNT + col;
               bfs_edgelist->ENL_count++;
               } // end if
               /*Regardless, advance column counter*/
            col++;
            } /* END WHILE col < = AM_vertexCount */

         } /* END WHILE  !isemptyqueue */

      } /* end if startVertex!= goalVertex */
   else
      {
      found = TRUE;
      }
   FreeQueue( queue );
   return( found );
}/*BFS*/





/********************************************************************
 *                 DFS
 ********************************************************************
 * SYNOPSIS:     Perform the Depth First Search on the graph.
 * PARAMETERS:   startVertex - Vertex to start searching
 *               goalVertex - Vertex to find
 *               dfs_edgelist - Returns edge list of visited edges
 * RETURNS:      TRUE if goal found
 * STRATEGY:     Used to calculate the Edge Num: the number of
 *               vertices used in the adjacency matrix plus one,
 *               times the row number, plus the column number.
 *               ( ( theGraph.AM_vertexCount + 1 )
 *                 * row # ) + column #
 * ERRORS:       Does not check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       LS      04/16/96  Initial version
 *       NF      04/24/96  Updateded Names and stack functions
 *       KS      04/24/96  Trouble shot algorithm
 *******************************************************************/

boolean DFS( VertexNumber  startVertex,
             VertexNumber  goalVertex,
             EdgeNumList * dfs_edgelist ) {

   VertexNumber   r,         // Current row of matrix being examined.
                  c,         // Current column of matrix.
                  parent[VERTEX_MAX_COUNT];
   VertexNumList  vNL;

   ptrToStackType dfs_stack; // Stack ADT

   int            i;
   boolean        isFound;   // TRUE if goalVertex has been found.

      /*
       * Initialize the edgelist, found flag, and the stack.
       */
   dfs_edgelist->ENL_count = 0;
   vNL.VNL_count = 0;
   isFound = FALSE;
   dfs_stack = MakeEmptyStack();

   if ( startVertex != goalVertex )
   {
      for ( r = 0; r < theGraph.AM_vertexCount; r++ ) {
         theGraph.AM_vertices[r].V_state &= ~VS_KNOWN;
         parent[r] = VERTEX_INVALID_NUM;
      } /* end loop to set all vertices to unvisited */

      Push( dfs_stack, startVertex );
      parent[startVertex] = startVertex;

      while ( !IsEmptyStack( dfs_stack ) && !isFound )
      {
         Pop( dfs_stack, &r );
         theGraph.AM_vertices[r].V_state |= VS_KNOWN;
         if ( r != parent[r] ) {
           dfs_edgelist->ENL_edges[dfs_edgelist->ENL_count] =
               parent[r]*VERTEX_MAX_COUNT+r;
           dfs_edgelist->ENL_count++;
         }

         if ( r == goalVertex ) {
            isFound = TRUE;
         }

         c = 0;
         while ( ( c < theGraph.AM_vertexCount ) && !isFound )
         {
            if ( ( theGraph.AM_costs[r][c] > 0 ) &&
                 ( theGraph.AM_costs[r][c] < EDGE_MAX_COST ) &&
                 ( ( theGraph.AM_vertices[c].V_state & VS_KNOWN ) == 0 ) )
            {
               vNL.VNL_vertices[vNL.VNL_count] = c;
               vNL.VNL_count += 1;

               if ( parent[c] == VERTEX_INVALID_NUM  ) {
                  parent[c] = r;
               }

            } /* end if edge & not visited */
            c++;
         } /* end while c < = theGraph.AM_vertices.VerticesUsed */

         while (vNL.VNL_count) {
            Push( dfs_stack, vNL.VNL_vertices[vNL.VNL_count-1] );
            vNL.VNL_count--;
         }

      } /* end while i > = 0 */

   } /* end if startVertex != goalVertex */
   else {
      isFound = TRUE;
   }

   FreeStack( dfs_stack );

   return (isFound);

} /* DFS */



/********************************************************************
 *                 MST FUNCTIONS
 *******************************************************************/


/********************************************************************
 *                 Kruskal
 ********************************************************************
 * SYNOPSIS:     Perform Kruskal's MST algorithm on the graph.
 * PARAMETERS:   eNL - List of edges in MST
 * RETURNS:      eNL filled with edges in MST
 * STRATEGY:
 * ERRORS:       Does not check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 * XXX - Does not create a connected MST
 *******************************************************************/

void Kruskal( EdgeNumList * eNL ) {

   EdgeNumList   tempENL;

   DISJ_SET      set;
   unsigned      Uset,
                 Vset;

   VertexNumber  V1, V2, V3, V4;

   EdgeNumber    currentEdge,
                 smallestEdge;

   Cost          smallestCost,
                 temp;

   int           i, j,
                 index;

   // *****  Initialize parameters.  *****

   initializeSet( set );
   eNL->ENL_count    = 0;
   tempENL.ENL_count = 0;
   index             = 0;


   // *****  Load the Edge List from the Adjacency Matrix.  *****

   for( i = 0; i < theGraph.AM_vertexCount; i++ ) {
      for( j = 0; j < theGraph.AM_vertexCount; j++ ) {

         // Do not add edges with < 0 or > EDGE_MAX_COST.
         if ( ( theGraph.AM_costs[i][j] > 0 ) &&
              ( theGraph.AM_costs[i][j] < EDGE_MAX_COST ) ) {
           tempENL.ENL_edges[tempENL.ENL_count] =
               i * VERTEX_INVALID_NUM + j;
           tempENL.ENL_count++;
         }

      }
   }

   // *****  Sort the Edge List by Cost.  *****

   for ( i = 0; i < tempENL.ENL_count; i++ ) {

      V1 = AMGetEdgeFromVertex( tempENL.ENL_edges[i] );
      V2 = AMGetEdgeToVertex( tempENL.ENL_edges[i] );

      smallestEdge = i;
      smallestCost = theGraph.AM_costs[V1][V2];

      for ( j = i + 1; j < tempENL.ENL_count; j++ ) {

         V3 = AMGetEdgeFromVertex( tempENL.ENL_edges[j] );
         V4 = AMGetEdgeToVertex( tempENL.ENL_edges[j] );

         if ( theGraph.AM_costs[V3][V4] < smallestCost ) {
            smallestEdge = j;
            smallestCost = theGraph.AM_costs[V3][V4];
         }

      } //  end for loop

      temp = tempENL.ENL_edges[smallestEdge];
      tempENL.ENL_edges[smallestEdge] = tempENL.ENL_edges[i];
      tempENL.ENL_edges[i] = temp;

   } //  end for loop

   // *****  Build Kruskal's MST.  *****

   while( ( eNL->ENL_count < theGraph.AM_vertexCount - 1 ) &&
          ( index < tempENL.ENL_count ) ) {

      currentEdge = tempENL.ENL_edges[index];

      V1 = AMGetEdgeFromVertex( tempENL.ENL_edges[index] );
      V2 = AMGetEdgeToVertex( tempENL.ENL_edges[index] );

      index++;

      Uset = find( V1, set );
      Vset = find( V2, set );

      // Are the 2 Vertices in separate sets?
      if( Uset != Vset ) {

         // Accept the edge.
         eNL->ENL_edges[eNL->ENL_count] = currentEdge;
         eNL->ENL_count++;

         set_union_by_height( set, Uset, Vset );

      } // if
   } // while

} /* Kruskal */



/********************************************************************
 *                 Prim
 ********************************************************************
 * SYNOPSIS:     Perform Prim's MST algorithm on the graph.
 * PARAMETERS:   startVertex - Vertex to begin MST
 *               eNumList - List of edges in MST
 * RETURNS:      eNumList filled with edges in MST
 * STRATEGY:     From the starting point it calculates the distance
 *               to all the other points and selects the edge with
 *               the minimum distance. The vertex at the end of the
 *               edge is added to the visited vertex list. Repeats
 *               this process always moving from the selected
 *               vertices to the non-selected vertices. It stops
 *               when all of the vertices have been selected.
 * ERRORS:       Does not check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *******************************************************************/

void Prim( VertexNumber startVertex, EdgeNumList * eNumList ) {

   VertexNumList vNumList;   // List of unselected vertices.

   /* Shortest distance from the set of accepted vertices
    * to the unselected set of vertices. */
   Cost          dist[VERTEX_MAX_COUNT];

   // The edge number corrosponding to the above distance.
   EdgeNumber    edge[VERTEX_MAX_COUNT];

   VertexNumber  V,
                 Vold,
                 next;       // The next vertex in the vertex num list to check
   Cost          lowestCost; // The current lowest distance.

   int           i,
                 index;      // Needed for disjoint graphs.

   // *****  Initialize the Edge List.  *****

   eNumList->ENL_count = 0;


   // *****  Load the Vertex, Distance & Edge  Lists.  *****

   for ( i = 0; i < theGraph.AM_vertexCount; i++ ) {
      vNumList.VNL_vertices[i] = i;
      dist[i] = EDGE_MAX_COST;
      edge[i] = EDGE_INVALID_NUM;
   }
   vNumList.VNL_count = theGraph.AM_vertexCount;
   index = vNumList.VNL_count;


   // *****  Set & Remove the Starting Vertex.  *****

   V = startVertex;
   VertexNumListRemoveNumber( &vNumList, V );

   // *****  Build Prim's MST.  *****

   while( index ) {

      // Calculate the new distances.
      for( i = 0; i < vNumList.VNL_count; i++ ) {

         next = vNumList.VNL_vertices[i];
         if ( theGraph.AM_costs[V][next] < dist[next] ) {

            dist[next] = theGraph.AM_costs[V][next];
            edge[next] = V * VERTEX_MAX_COUNT + next;
         }

      }  //  end for

      Vold = V;
      dist[V] = 0;  // V is in the set of accepted vertices.

      // Find the next clostest vertex by compareing the current distance
      // of the remaining vertices and then setting V equal to it.
      lowestCost = EDGE_MAX_COST;
      for ( i = 0; i < vNumList.VNL_count; i++ ) {
         next = vNumList.VNL_vertices[i];
         if ( dist[next] < lowestCost ) {
            V = next;
            lowestCost = dist[V];
         }
      }

      if (V == Vold){
         index = 0;
      }
      else{

         eNumList->ENL_edges[eNumList->ENL_count] = edge[V];
         eNumList->ENL_count++;
         VertexNumListRemoveNumber( &vNumList, V );
         index--;

      }

   }  //  end while loop

}  //  end Prim's




/********************************************************************
 *                   OTHER OPERATIONS
 *******************************************************************/


/********************************************************************
 *                 ShortestPath
 ********************************************************************
 * SYNOPSIS:     Find the shortest path between two points.
 * PARAMETERS:   startVertex - Vertex to begin MST
 *               endVertex - Goal vertex
 *               eNumList - List of edges visited
 *               path - The shortest path
 * RETURNS:      TRUE if shortest path found
 * STRATEGY:     Basically uses the Prim algorithm for finding the
 *               MST and then picks the shortest path between the
 *               two vertices.
 * ERRORS:       Does not check.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *      JB,KS    04/24/96  Initial version
 * XXX - Fails on some cases
 *******************************************************************/

boolean ShortestPath( VertexNumber startVertex,
                      VertexNumber goalVertex,
                      EdgeNumList * eNumList,
                      EdgeNumList * path ) {

   VertexNumList vNumList;   // List of unselected vertices.
   EdgeNumList   eNL;        // List of unselected vertices.

   /* Shortest distance from the set of accepted vertices
    * to the unselected set of vertices. */
   Cost          dist[VERTEX_MAX_COUNT];

   // The edge number corrosponding to the above distance.
   EdgeNumber    edge[VERTEX_MAX_COUNT];

   // The parent vertex closest to the current vertex.
   // Needed to backtrack the path.
   VertexNumber  closestParent[VERTEX_MAX_COUNT];

   VertexNumber  V,
                 Vold,
                 next;       // The next vertex in the vertex num list to check
   Cost          lowestCost; // The current lowest distance.

   int           i,
                 index;      // Needed for disjoint graphs.

   boolean       found = FALSE;

   // *****  Initialize the Edge List.  *****

   eNumList->ENL_count = 0;
   path->ENL_count = 0;
   eNL.ENL_count = 0;


   // *****  Load the Vertex, Distance, Edge & Closest Parent Lists.  *****

   for ( i = 0; i < theGraph.AM_vertexCount; i++ ) {
      vNumList.VNL_vertices[i] = i;
      dist[i] = EDGE_MAX_COST;
      edge[i] = EDGE_INVALID_NUM;
      closestParent[i] = VERTEX_INVALID_NUM;
   }
   vNumList.VNL_count = theGraph.AM_vertexCount;
   index = vNumList.VNL_count;


   // *****  Set & Remove the Starting Vertex.  *****

   V = startVertex;
   VertexNumListRemoveNumber( &vNumList, V );

   // *****  Build Prim's MST.  *****

   while( index && !found ) {

      // Calculate the new distances.
      for( i = 0; i < vNumList.VNL_count; i++ ) {

         next = vNumList.VNL_vertices[i];
         if ( theGraph.AM_costs[V][next] < dist[next] ) {

            dist[next] = theGraph.AM_costs[V][next];
            edge[next] = V * VERTEX_MAX_COUNT + next;
         }

      }  //  end for

      Vold = V;
      dist[V] = 0;  // V is in the set of accepted vertices.

      // Find the next clostest vertex by compareing the current distance
      // of the remaining vertices and then setting V equal to it.
      lowestCost = EDGE_MAX_COST;
      for ( i = 0; i < vNumList.VNL_count; i++ ) {
         next = vNumList.VNL_vertices[i];
         if ( dist[next] < lowestCost ) {
            V = next;
            lowestCost = dist[V];
         }
      }

      if (V == Vold){
         index = 0;
      }
      else{

         eNumList->ENL_edges[eNumList->ENL_count] = edge[V];
         eNumList->ENL_count++;
         VertexNumListRemoveNumber( &vNumList, V );
         index--;

         closestParent[V] = AMGetEdgeFromVertex(edge[V]);;
         if ( V == goalVertex ){
            found = TRUE;
         }

      }

   }  //  end while loop

   // Backtrack the closest parent to create a path.
   while ( V != startVertex ) {
      eNL.ENL_edges[eNL.ENL_count] = AMGetEdgeNumber( closestParent[V], V );
      eNL.ENL_count++;
      V = closestParent[V];
   }
   eNL.ENL_count--;

   // Reverse the path to make it a forward path.
   while ( eNL.ENL_count + 1 ){
      path->ENL_edges[path->ENL_count] = eNL.ENL_edges[eNL.ENL_count];
      path->ENL_count++;
      eNL.ENL_count--;
   }

   return( found );
}  //  end Shortest Path




/********************************************************************
 *                   FILE I/O FUNCTIONS
 *******************************************************************/


/********************************************************************
 *                 readAdjList
 ********************************************************************
 * SYNOPSIS:     Reads a text file containing a Adjacency List.
 * PARAMETERS:   fileHan - File to read from
 * RETURNS:      nothing
 * STRATEGY:     Store the x,y of the new point at the end of the
 *               vertex list in the Adjacency Matrix and bump
 *               up the vertex count.
 * ERRORS:       Will not read if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/17/96  Initial version
 *       NF      04/22/96  Renamed vNum to eNum and used as an edge
 *                         number in calling AMAddEdge.
 *******************************************************************/

void readAdjList( /* FILE * */ unsigned fileHan ) {

   int          i, j,
                numVertices;
   Point_t      newPt;
   EdgeNumber   eNum;

   // Read input size (number of vertices in file).
// This is the DOS routine used originally.
//   fscanf ( fileHan, "%ld", &numVertices);
   numVertices = FileReadInt( fileHan );
// This is the portability driver routine we're using now.
   FileReadEOL( fileHan );

   if ( numVertices <= VERTEX_MAX_COUNT ) {

      // Initialize existing graph. We should not be adding
      // to the existing graph. That's not how user would expect.
      AMInitializeGraph();

      //  *****  Add vertices to the Adjacency Matrix  *****
      for( i = 0; i < numVertices; i++ ) {

//         fscanf ( fileHan, "%ld%ld", &newPt.P_x, &newPt.P_y);
         newPt.P_x = FileReadInt( fileHan );
         newPt.P_y = FileReadInt( fileHan );

         AMAddVertex( newPt );

         // Add directed edges to the graph.
         // Give them a default cost, since AMAddEdgeNoCheck
         // will not calculate an edge cost.
         for( j=0; j < numVertices; j++ ){

//            fscanf ( fileHan, "%ld", &eNum);
            eNum = FileReadInt( fileHan );

            if ( eNum < EDGE_INVALID_NUM ) {
               AMAddEdgeNoCheck( i, j, TRUE );
               theGraph.AM_costs[i][j] = 10;
            }
         }
         FileReadEOL( fileHan );

      }  //  end for
   }
   else {
      ErrorMessage( "Graph corrupt in readAdjList()" );
   }

} /* readAdjList */




/********************************************************************
 *                 readAdjMatrix
 ********************************************************************
 * SYNOPSIS:     Reads a text file containing a Adjacency Matrix.
 * PARAMETERS:   fileHan - File to read from
 * RETURNS:      nothing
 * STRATEGY:     Store the x,y of the new point at the end of the
 *               vertex list in the Adjacency Matrix and bump
 *               up the vertex count.
 * ERRORS:       Will not read if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/17/96  Initial version
 *       NF      04/19/96  Corrected the row index on edge access
 *******************************************************************/

void readAdjMatrix( /* FILE * */ unsigned fileHan ) {

   int          i, j;
   VertexNumber numVertices;
   Point_t      newPt;
   Cost         newEdgeCost;

   // Read input size (number of vertices).
//   fscanf ( fileHan, "%ld", &numVertices );
   numVertices = FileReadInt( fileHan );
   FileReadEOL( fileHan );

   if ( numVertices <= VERTEX_MAX_COUNT ) {

      // Initialize existing graph. We should not be adding
      // to the existing graph. That's not how user would expect.
      AMInitializeGraph();

      //  *****  Add vertices to the Adjacency Matrix  *****
      for ( i = 0; i < numVertices; i++ ) {

//         fscanf ( fileHan, "%ld%ld", &x, &y);
         newPt.P_x = FileReadInt( fileHan );
         newPt.P_y = FileReadInt( fileHan );

         AMAddVertex ( newPt );

         // Add directed edges to the graph using the
         // cost stored in the file. If you call AMAddEdge
         // the function will calculate a new cost so we
         // must set the cost after adding.
         for ( j = 0; j < numVertices; j++ ) {

            newEdgeCost = FileReadInt( fileHan );
            if ( ( newEdgeCost > 0 ) &&
                 ( newEdgeCost < EDGE_MAX_COST ) ) {
               AMAddEdgeNoCheck( i, j, TRUE );
//               fscanf ( fileHan, "%ld", &theGraph.AM_costs[i][j] );
               theGraph.AM_costs[i][j] = newEdgeCost;
            }

         }
         FileReadEOL( fileHan );

      }  //  end for
   }
   else {
      ErrorMessage( "Graph corrupt in readAdjMatrix()" );
   }

} /* readAdjMatrix */




/********************************************************************
 *                 writeAdjList
 ********************************************************************
 * SYNOPSIS:     Reads a text file containing a Adjacency Matrix.
 * PARAMETERS:   fileHan - File to read from
 * RETURNS:      nothing
 * STRATEGY:     Store the x,y of the point and the edge costs
 *               in the Adjacency Matrix and decroment
 *               the vertex count.
 * ERRORS:       Will not write if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/17/96  Initial version
 *******************************************************************/

void writeAdjList( /* FILE * */ unsigned fileHan ) {

   int i, j,
       numVertices;
//   EdgeNumber eN;

   if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
      // Write the output size.
      numVertices = theGraph.AM_vertexCount;
//      fprintf ( fileHan, "%ld", &numVertices );
      FileWriteInt( fileHan, numVertices );
      FileWriteEOL( fileHan );


      // Write out the vertices to the file.
      for ( i = 0; i < numVertices; i++ ) {

/*      fprintf ( fileHan, "%4ld %4ld",
                  &theGraph.AM_vertices[i].V_point.P_x,
                  &theGraph.AM_vertices[i].V_point.P_y); */
         FileWriteInt( fileHan, theGraph.AM_vertices[i].V_point.P_x );
         FileWriteInt( fileHan, theGraph.AM_vertices[i].V_point.P_y );

         // Write out the edge numbers to the file.
         // Won't write out non-existent edges.
         for ( j = 0; j < numVertices; j++ ) {

            if ( ( theGraph.AM_costs[i][j] > 0 ) &&
                 ( theGraph.AM_costs[i][j] < EDGE_MAX_COST ) ) {
//               eN = ( i * VERTEX_MAX_COUNT + j );
//               fprintf ( fileHan, "%4ld", &eN );
               FileWriteInt( fileHan, ( i * VERTEX_MAX_COUNT + j ) );
            }
            else {
               FileWriteInt( fileHan, EDGE_INVALID_NUM );
            }

         }
         FileWriteEOL( fileHan );

      }  //  end for
   }
   else {
      ErrorMessage( "Graph corrupt in writeAdjList()" );
   }

} /* writeAdjList */




/********************************************************************
 *                 writeAdjMatrix
 ********************************************************************
 * SYNOPSIS:     Writes a Adjacency Matrix to a text file.
 * PARAMETERS:   fileHan - File to write to
 * RETURNS:      nothing
 * STRATEGY:     Write the x,y of the point and the edge costs
 *               in the Adjacency Matrix to the file and decrement
 *               the vertex count.
 * ERRORS:       Will not write if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      04/17/96  Initial version
 *******************************************************************/

void writeAdjMatrix( /* FILE * */ unsigned fileHan ) {

  int i, j,
      numVertices;

  if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {
    // Write the output size.
    numVertices = theGraph.AM_vertexCount;
// This is the DOS routine used originally.
//    fprintf ( fileHan, "%ld", &numVertices);

// This is the portability driver routine that we're using now.
    FileWriteInt( fileHan, numVertices );
    FileWriteEOL( fileHan );


    //  *****  Write vertices and edges to file  *****
    for ( i = 0; i < numVertices; i++ ) {

/*
      fprintf ( fileHan, "%4ld %4ld",
               &theGraph.AM_vertices[i].V_point.P_x,
               &theGraph.AM_vertices[i].V_point.P_y);
*/
      FileWriteInt( fileHan, theGraph.AM_vertices[i].V_point.P_x );
      FileWriteInt( fileHan, theGraph.AM_vertices[i].V_point.P_y );

      //  *****  Write edges to file  *****
      for ( j = 0; j < numVertices; j++ ) {

/*
         fprintf ( fileHan, "%4ld",
                  &theGraph.AM_costs[theGraph.AM_vertexCount][j] );
*/
/* NF - Changed to correct the row index */
         FileWriteInt( fileHan, theGraph.AM_costs[i][j] );

      } // end for j
      FileWriteEOL( fileHan );

    } //  end for i
  }
  else {
    ErrorMessage( "Graph corrupt in writeAdjMatrix()" );
  }

} /* writeAdjMatrix */




/********************************************************************
 *                   SCREEN DRAWING FUNCTIONS
 *******************************************************************/


/********************************************************************
 *                 AMDrawDoubleEdgeList
 ********************************************************************
 * SYNOPSIS:     Draws two lists of edges simultaneously.
 * PARAMETERS:   E1 - First edge list to draw
 *               E2 - Second edge list to draw
 * RETURNS:      nothing
 * STRATEGY:     Similar to AMDrawEdgeList, accept that it accounts
 *               for the fact that the lists may not be of equal
 *               length.
 * ERRORS:       Will not draw if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       KS      04/14/96  Removed AMDrawEdge
 *       NF      04/17/96  Cleaned up the keyboard checking code
 *******************************************************************/

void AMDrawDoubleEdgeList( EdgeNumList * E1, EdgeNumList * E2 ) {

  int  index1,
       index2;
  char ch;

  index1 = 0,
  index2 = 0;
  ch = 'B';

  if ( ( E1->ENL_count <= EDGE_MAX_COUNT ) &&
       ( E2->ENL_count <= EDGE_MAX_COUNT ) ) {
    while ( ( index1 < E1->ENL_count ) ||
            ( index2 < E2->ENL_count ) ) {

      if ( index1 < E1->ENL_count ) {
        AMDrawEdgeNum( E1->ENL_edges[index1], C_CURRENT );
        index1++;
      }

      if ( index2 < E2->ENL_count ) {
        AMDrawEdgeNum( E2->ENL_edges[index2], C_CURRENT2 );
        index2++;
      }

      if ( toupper( ch ) != 'A' ) {
        ch = getch();
      }

      AMDrawEdgeNum( E1->ENL_edges[index1-1], C_VISITED );
      AMDrawEdgeNum( E2->ENL_edges[index2-1], C_VISITED2 );
    } // end while
  }
  else {
    ErrorMessage( "Invalid input to AMDrawDoubleEdgeList()" );
  }

} /* AMDrawDoubleEdgeList */




/********************************************************************
 *                 AMDrawDoubleEdgeListInSeries
 ********************************************************************
 * SYNOPSIS:     Draws two lists of edges by first drawing the one
 *               and then draw the other one.
 * PARAMETERS:   E1 - First edge list to draw
 *               E2 - Second edge list to draw
 * RETURNS:      nothing
 * STRATEGY:     Similar to AMDrawEdgeList, accept that it accounts
 *               for the fact that the lists may not be of equal
 *               length.
 * ERRORS:       Will not draw if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       KS      04/14/96  Removed AMDrawEdge
 *       NF      04/17/96  Cleaned up the keyboard checking code
 *       KS      04/24/96  Converted to do lists series
 *******************************************************************/

void AMDrawDoubleEdgeListInSeries( EdgeNumList * E1, EdgeNumList * E2 ) {

  int  index1,
       index2;
  char ch;

  index1 = 0,
  index2 = 0;
  ch = 'B';

  // Step through the first list.
  if ( E1->ENL_count <= EDGE_MAX_COUNT ) {
    while ( index1 < E1->ENL_count ) {

      if ( index1 < E1->ENL_count ) {
        AMDrawEdgeNum( E1->ENL_edges[index1], C_CURRENT );
        index1++;
      }

      if ( toupper( ch ) != 'A' ) {
        ch = getch();
      }

      AMDrawEdgeNum( E1->ENL_edges[index1-1], C_VISITED );
    } // end while
  }
  else {
    ErrorMessage( "Invalid input to AMDrawDoubleEdgeListInSeries()" );
  }

  // Automaticaly run through the second list.
  if ( E2->ENL_count <= EDGE_MAX_COUNT ) {
    while ( index2 < E2->ENL_count ) {

      if ( index2 < E2->ENL_count ) {
        AMDrawEdgeNum( E2->ENL_edges[index2], C_CURRENT2 );
        index2++;
      }

      /* if ( toupper( ch ) != 'A' ) {
        ch = getch();
      }  */

      AMDrawEdgeNum( E2->ENL_edges[index2-1], C_VISITED2 );
    } // end while
  }
  else {
    ErrorMessage( "Invalid input to AMDrawDoubleEdgeListInSeries()" );
  }

} /* AMDrawDoubleEdgeListInSeries */




/********************************************************************
 *                 AMDrawEdge
 ********************************************************************
 * SYNOPSIS:     Draw a single edge.
 * PARAMETERS:   E - Edge to draw
 *               e - Edge number corresponding to E
 *               c - Color to draw it in
 * RETURNS:      nothing
 * STRATEGY:     Call drawLine.
 * ERRORS:       Will not draw if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       KS      04/16/96  Not used in this version
 *       NF      04/20/96  It saves code to use this routine
 *******************************************************************/

void AMDrawEdge( Edge E, EdgeNumber e, ElementColor c ) {
  VertexNumber from, to;

  from = AMGetEdgeFromVertex( e );
  to = AMGetEdgeToVertex( e );
  if ( ( from < VERTEX_INVALID_NUM ) &&
       ( to < VERTEX_INVALID_NUM ) ) {
    drawLine( theGraph.AM_vertices[from].V_point.P_x,
              theGraph.AM_vertices[from].V_point.P_y,
              theGraph.AM_vertices[to].V_point.P_x,
              theGraph.AM_vertices[to].V_point.P_y,
              E.E_state, c,
              theGraph.AM_costs[from][to] );
  }
  else {
    ErrorMessage( "Invalid input to AMDrawEdge()" );
  }

} /* AMDrawEdge */




/********************************************************************
 *                 AMDrawEdgeList
 ********************************************************************
 * SYNOPSIS:     Draw a list of edges.
 * PARAMETERS:   E - List of edges to draw
 *               c - Color to draw them in
 * RETURNS:      nothing
 * STRATEGY:     For each edge in the list, find its vertices,
 *               determine if the edge is directed, then call
 *               AMDrawEdge. Wait for user to press a key for
 *               step-by-step drawing. If user presses a, then
 *               to automatically and fill in the rest of the list.
 * ERRORS:       Will not draw if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       KS      04/14/96  Removed AMDrawEdge
 *       NF      04/20/96  Restored use of AMDrawEdge
 *******************************************************************/

void AMDrawEdgeList( EdgeNumList * E ) {

   int     i;
   char    ch;

   ch = 'B';

   if ( E->ENL_count <= EDGE_MAX_COUNT ) {
      for ( i = 0; i < E->ENL_count; i++ ) {

         AMDrawEdge( theGraph.AM_edges[E->ENL_edges[i]],
                     E->ENL_edges[i], C_CURRENT );

         if ( toupper( ch ) != 'A' ) {
            ch = getch();
         }

         AMDrawEdge( theGraph.AM_edges[E->ENL_edges[i]],
                     E->ENL_edges[i], C_VISITED );

      }  //  end for
   }
   else {
      ErrorMessage( "Invalid input to AMDrawEdgeList()" );
   }

} /* AMDrawEdgeList */




/********************************************************************
 *                 AMDrawEdgeNum
 ********************************************************************
 * SYNOPSIS:     Draw an edges.
 * PARAMETERS:   eN - Edge to draw
 *               c - Color to draw them in
 * RETURNS:      nothing
 * STRATEGY:     For the edge number look up its edge in the matrix
 *               and call AMDrawEdge with that edge.
 * ERRORS:       Will not draw if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       KS      04/14/96  Removed AMDrawEdge
 *******************************************************************/

void AMDrawEdgeNum( EdgeNumber eN, ElementColor c ) {

   if ( eN < EDGE_INVALID_NUM ) {
      AMDrawEdge( theGraph.AM_edges[eN], eN, c );
   }
   else {
      ErrorMessage( "Invalid input to AMDrawEdgeNum()" );
   }

} /* AMDrawEdgeNum */




/********************************************************************
 *                 AMDrawGraph
 ********************************************************************
 * SYNOPSIS:     Draw the entire graph.
 * PARAMETERS:   none
 * RETURNS:      nothing
 * STRATEGY:     Draw all the edges first, then draw the vertices
 *               so that the vertices will cover over the ends
 *               of the edges.
 * ERRORS:       Will not draw if theGraph is corrupt.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *       KS      04/14/96  Removed AMDrawEdge
 *******************************************************************/

void AMDrawGraph( void ) {

   int i,j;

   if ( theGraph.AM_vertexCount <= VERTEX_MAX_COUNT ) {

      // Draw the edges.
      for ( i = 0; i < theGraph.AM_vertexCount; i++ ) {
        for ( j = 0; j < theGraph.AM_vertexCount; j++ ) {

          // See if there's an edge and if so draw it.
          if ( ( theGraph.AM_costs[i][j] > 0 ) &&
               ( theGraph.AM_costs[i][j] < EDGE_MAX_COST ) ) {
            if ( theGraph.AM_edges[i*VERTEX_MAX_COUNT+j].E_state &
                    ES_DIRECTED ) {
              AMDrawEdgeNum( ( i * VERTEX_MAX_COUNT + j ), C_BLACK );
            }
            else {
              if ( i < j ) {
                AMDrawEdgeNum( ( i * VERTEX_MAX_COUNT + j ), C_BLACK );
              }
            }
          }
        }
      }

      // Draw the vertices.
      for ( i = 0; i < theGraph.AM_vertexCount; i++ ) {
         AMDrawVertexNum( i, C_BLACK );
      }
   }
   else {
      ErrorMessage( "Graph corrupt in AMDrawGraph()" );
   }

} /* AMDrawGraph */




/********************************************************************
 *                 AMDrawVertexNum
 ********************************************************************
 * SYNOPSIS:     Draw a vertex on the screen.
 * PARAMETERS:   V - Vertex to draw
 *               c - Color to draw in
 * RETURNS:      nothing
 * STRATEGY:     Call drawNode.
 * ERRORS:       Will not draw if invalid input.
 * REVISION HISTORY:
 *      Name     Date      Description
 *      ----     ----      -----------
 *       KS      03/14/96  Initial version
 *******************************************************************/

void AMDrawVertexNum( VertexNumber V, ElementColor c ) {

   if ( V < VERTEX_INVALID_NUM ) {
      drawNode( theGraph.AM_vertices[V].V_point.P_x,
                theGraph.AM_vertices[V].V_point.P_y,
                c, theGraph.AM_vertices[V].V_state, V );
   }
   else {
      ErrorMessage( "Invalid input to AMDrawVertexNum()" );
   }

} /* AMDrawVertexNum */

