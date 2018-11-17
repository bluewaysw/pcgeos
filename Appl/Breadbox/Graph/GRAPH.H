/********************************************************************
 *
 *  Copyright (c) 1996 Ken Sievers -- All rights reserved.
 *  Portions Copyright (c) 1996 Blue Marsh Softworks
 *
 * Program    : Graph
 * File       : graph.h
 *
 * Programers : Joe Barbara,     jab315@psu.edu
 *              Tom Denn,        tomtom4828@aol.com
 *              Nathan Fiedler,  nfiedler@aol.com
 *              Ken Sievers,     sievers@epix.net
 *              Lee Stover,      lxs137@psu.edu
 *
 * Compiler   : Borland C++
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
 *
 * DESCRIPTION:
 *      This header file contains all the ADT definitions for an
 *      Adjancy Matrix. This includes the point, vertex, edge, and
 *      graph functions and data structures.
 *
 *******************************************************************/


//  *****  Constants  *****

   // Constants pertaining to vertices.
#define VERTEX_MAX_COUNT   50
#define VERTEX_INVALID_NUM VERTEX_MAX_COUNT

   // Constants pertaining to edges.
#define EDGE_MAX_COST    32767
#define EDGE_MAX_COUNT   VERTEX_MAX_COUNT * VERTEX_MAX_COUNT
#define EDGE_INVALID_NUM EDGE_MAX_COUNT

   // Define the TRUE and FALSE constants.
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE -1
#endif

   // Contants for the displaying of the vertices.
#define VERTEX_WIDTH  30
#define VERTEX_RADIUS VERTEX_WIDTH / 2
   // Constants for the displaying of the edges.
#define EDGE_THICKNESS 2
   // Constants for the displaying of the directed edges.
#define EDGE_ARROW_WIDTH  10
#define EDGE_ARROW_HEIGHT 20




//  *****  External Variables  *****

extern char chCharacter_g;




//  *****  Basic Data Structures  *****

typedef char boolean; // TRUE/FALSE type

//  *****  Color Type & Definitions  *****

typedef int ElementColor;

#define C_BLACK         0
#define C_BLUE          1
#define C_GREEN         2
#define C_CYAN          3
#define C_RED           4
#define C_VIOLET        5
#define C_BROWN         6
#define C_LIGHT_GRAY    7
#define C_DARK_GRAY     8
#define C_LIGHT_BLUE    9
#define C_LIGHT_GREEN  10
#define C_LIGHT_CYAN   11
#define C_LIGHT_RED    12
#define C_LIGHT_VIOLET 13
#define C_YELLOW       14
#define C_WHITE        15

   // Basic graph element color.
#define C_NORMAL   C_BLACK
   // Selected edge
#define C_SELECTED C_YELLOW
   // Current edge being visited in operations.
#define C_CURRENT  C_BLUE
   // Second edge being visited in dual operations.
#define C_CURRENT2 C_RED
   // Already visited edges.
#define C_VISITED  C_GREEN
   // Second edge in already visited dual operations.
#define C_VISITED2 C_VIOLET




/********************************************************************
 * ADT point
 ********************************************************************
 * This holds the x and y position of the point.
 *******************************************************************/
typedef int Cost; // Cost of edge or vertex.

typedef struct {

   unsigned int P_x; // X position
   unsigned int P_y; // Y position

} Point_t;

Cost PointCalcEdgeCost( Point_t P1, Point_t P2 );




/********************************************************************
 * ADT vertex
 ********************************************************************
 * Stores the x,y pair, the state and the cost of a vertex.
 *******************************************************************/
typedef unsigned int VertexNumber; // Vertex ID #

typedef unsigned int Degree; // Degree for an undirected vertex

typedef int VertexState;

#define VS_SELECTED 0x80  // Means vertex is highlighted.
#define VS_KNOWN    0x40  // Means vertex has been visited.

typedef struct {

   Point_t     V_point;     // X, Y coordinates
   VertexState V_state;     // State of the vertex
//   Degree      V_degreeIn;  // Edges entering vertex.
//   Degree      V_degreeOut; // Edges leaving vertex.
//   Degree      V_degree;    // Edges entering and leaving vertex.
   Cost        V_cost;      // Cost to make this vertex.

} Vertex;

//void VertexDraw( Vertex V, ElementColor c );




/********************************************************************
 * ADT Vertex List
 ********************************************************************
 * Stores an array of vertices and an count of how many are
 * currently used.
 *******************************************************************/

typedef struct {

   Vertex       VL_vertices[ VERTEX_MAX_COUNT ];
   VertexNumber VL_count;

} VertexList;

//void VertexListDraw( VertexList * V, ElementColor c );




/********************************************************************
 * ADT Vertex Number List.
 ********************************************************************
 * Stores an array of vertex numbers and an index of how many are
 * currently used.  This acts as a list of pointers to the Adjacency
 * Matrix.
 *******************************************************************/

typedef struct {

   VertexNumber VNL_vertices[ VERTEX_MAX_COUNT ];
   VertexNumber VNL_count;

} VertexNumList;

void VertexNumListAddNumber( VertexNumList * VL, VertexNumber V );
boolean VertexNumListIsVertexInList( VertexNumList * VL, VertexNumber V );
boolean VertexNumListRemoveNumber( VertexNumList * VL, VertexNumber V );



/********************************************************************
 * ADT Edge
 ********************************************************************
 * Stores the state of each edge.
 *******************************************************************/
typedef unsigned int EdgeNumber; // Edge ID #

typedef int EdgeState;

#define ES_SELECTED 0x80  // Means edge is highlighted.
#define ES_DIRECTED 0x40  // Means edge is directional.

typedef struct {

//   VertexNumber E_fromVertex; // Vertex starting this edge.
//   VertexNumber E_toVertex;   // Vertex ending this edge.
//   Cost         E_cost;       // Cost of this edge.
   EdgeState    E_state;      // State of this edge.

} Edge;




/********************************************************************
 * ADT Edge Number List
 ********************************************************************
 * Stores an array of edge numbers and an index of how many are
 * currently used.  This acts as a list of pointers to the Adjancy Matrix.
 *******************************************************************/

typedef struct {

   EdgeNumber ENL_edges[ EDGE_MAX_COUNT ];
   EdgeNumber ENL_count;

} EdgeNumList;

void EdgeNumListDoubleDraw( EdgeNumList E1, ElementColor c1,
                            EdgeNumList E2, ElementColor c2 );
void EdgeNumListDraw( EdgeNumList E, ElementColor c );




/********************************************************************
 * ADT Adjacency Matrix
 ********************************************************************
 * Stores the list of vertices, edge cost matrix, and list
 * of edges.
 *******************************************************************/

typedef struct {

   // A list of vertices containing vertex information.
   Vertex       AM_vertices[ VERTEX_MAX_COUNT ];
   // Number of vertices in the list.
   VertexNumber AM_vertexCount;
   // Edge Matrix containing the costs.
   Cost         AM_costs[ VERTEX_MAX_COUNT ][ VERTEX_MAX_COUNT ];
   // List of edges containing other edge information.
   Edge         AM_edges[ EDGE_MAX_COUNT ];
   // Number of valid edges in list and matrix.
   EdgeNumber   AM_edgeCount;

} AdjMatrix;


// *****  Graph Operations for an Adjacency Matrix.  *****
// Defined in GRAPH.C

void AMInitializeGraph( void );
void AMMakeCompleteGraph( void );
void AMMakeSelectedComplete( void );


// *****  Search Operations for an Adjacency Matrix.  *****
// Defined in GRAPH.C

boolean BFS( VertexNumber  startVertex,
             VertexNumber  goalVertex,
             EdgeNumList * bfs_edgelist );
boolean DFS( VertexNumber  startVertex,
             VertexNumber  goalVertex,
             EdgeNumList * dfs_edgelist );


// *****  MST Operations for an Adjacency Matrix.  *****
// Defined in GRAPH.C

void Kruskal( EdgeNumList * eNL );
void Prim( VertexNumber startVertex, EdgeNumList * eNumList );


// *****  File I/O for an Adjacency Matrix  *****
// Defined in GRAPH.C

void writeAdjList( /* FILE */ unsigned fileName );
void writeAdjMatrix( /* FILE */ unsigned fileName );
void readAdjList( /* FILE */ unsigned fileName );
void readAdjMatrix( /* FILE */ unsigned fileName );


// *****  Drawing functions for an Adjacency Matrix  *****
// Defined in GRAPH.C

void AMDrawDoubleEdgeList( EdgeNumList * E1, EdgeNumList * E2 );
void AMDrawDoubleEdgeListInSeries( EdgeNumList * E1, EdgeNumList * E2 );
void AMDrawEdge( Edge E, EdgeNumber e, ElementColor c );
void AMDrawEdgeList( EdgeNumList * E );
void AMDrawEdgeNum( EdgeNumber eN, ElementColor c );
void AMDrawGraph( void );
void AMDrawVertexNum( VertexNumber V, ElementColor c );


// *****  Vertex Operations for an Adjacency Matrix.  *****
// Defined in VERTEX.C

VertexNumber AMAddVertex( Point_t newPt );
void AMGenerateRandomVertices( VertexNumber n );
void AMGetAdjacentVertices( VertexNumber v, VertexNumList * vnl );
void AMGetSelectedVertices( VertexNumList * vlist );
VertexState AMGetVertexState( VertexNumber v );
VertexNumber AMLocateVertex( int x, int y );
void AMRemoveVertex( VertexNumber V );
void AMSelectAllVertices( void );
void AMSetVertexState( VertexNumber v, VertexState s );
void AMUnselectAllVertices( void );


// *****  Vertex List Operations for an Adjacency Matrix.  *****
// Defined in VERTEX.C

//void AMReadVertexList( char * fileName );
void AMRemoveVertexList( VertexNumList * vnl );


// *****  Edge Operations for an Adjacency Matrix.  *****
// Defined in EDGE.C

void AMAddEdge( VertexNumber V1, VertexNumber V2, boolean directed );
void AMAddEdgeNoCheck( VertexNumber V1, VertexNumber V2, boolean directed );
void AMGenerateRandomEdges( EdgeNumber n );
//void AMGetAdjacentEdges( VertexNumber V, EdgeNumList * enl );
VertexNumber AMGetEdgeFromVertex( EdgeNumber eN );
EdgeNumber AMGetEdgeNumber( VertexNumber V1, VertexNumber V2 );
EdgeState AMGetEdgeNumState( EdgeNumber e );
VertexNumber AMGetEdgeToVertex( EdgeNumber eN );
void AMGetSelectedEdges( EdgeNumList * enl );
EdgeNumber AMLocateEdge( int x1, int y1, int x2, int y2 );
void AMRemoveEdge( EdgeNumber en, boolean directed );
void AMRemoveEdgeList( EdgeNumList * enl );
void AMSelectAllEdges( void );
void AMSetEdgeNumState( EdgeNumber e, EdgeState s );
void AMUnselectAllEdges( void );


// *****  Other Operations for an Adjacency Matrix.  *****

boolean ShortestPath( VertexNumber startVertex,
                      VertexNumber goalVertex,
                      EdgeNumList * eNumList,
                      EdgeNumList * path );





//************************************************************************
//                         UNION & FIND.
//************************************************************************
// Defined in SUPPORT.C

typedef int DISJ_SET[ VERTEX_MAX_COUNT + 1 ];
typedef unsigned int set_type;
typedef unsigned int element_type;

set_type find( element_type x, DISJ_SET S );
void initializeSet( DISJ_SET S );
void set_union( DISJ_SET S, set_type root1, set_type root2 );
void set_union_by_height( DISJ_SET S, set_type root1, set_type root2 );




/************************************************************************
 *                 Supporting Functions
 ********************************************************************
 * Written to make Graph work in alternate environments. When porting
 * to other systems, modify these routines.
 ************************************************************************/
// Defined in GRAPH.C

int abs( int x );
long BetterRandom( long max, boolean randomize );
double fabs( double x );
char getch( void );

// Defined in PROCESS.GOC

void drawLine( int x1, int y1, int x2, int y2, EdgeState es,
               ElementColor c, Cost cost );
void drawNode( int x, int y, ElementColor c, VertexState s, int n );
void ErrorMessage( unsigned char * errorString );
void FileReadEOL( unsigned fileHan );
unsigned FileReadInt( unsigned fileHan );
void FileWriteEOL( unsigned fileHan );
void FileWriteInt( unsigned fileHan, unsigned int i );
long TimeGetMinSec( void );

