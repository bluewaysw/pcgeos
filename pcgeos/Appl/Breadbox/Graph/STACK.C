/********************************************************************
 *
 *    Copyright 1995 (C) Blue Marsh Softworks -- All rights reserved
 *
 * PROJECT:      Abstract Data-Types
 * MODULE:       Stack ADT
 * FILE:         stack.c
 *
 * AUTHOR:       Nathan Fiedler
 *
 * REVISION HISTORY:
 *      Name   Date      Description
 *      ----   ----      -----------
 *       NF    02/05/95  Initial version of pancake stack.
 *       NF    04/13/95  Changed to a Queue ADT.
 *       NF    10/06/95  Changed to a Stack ADT.
 *
 * DESCRIPTION:
 *      An implementation of a simple stack data structure. See the
 *      header file for changes needed to adapt to your specific
 *      data type.
 *
 *      To use this module, add it to your project file in
 *      Borland's Project Manager. Also make sure to #include
 *      the stack.h header file.
 *
 *******************************************************************/

/********************************************************************
 *                 Headers
 *******************************************************************/
    #include <stdio.h>
    #include <stdlib.h>
    #include "graph.h"
    #include "stack.h"

/********************************************************************
 *                 MakeEmptyStack
 ********************************************************************
 * SYNOPSIS:     Creates a new, empty stack.
 * PARAMETERS:   ( void )
 * RETURNS:      ptrToStackType - Pointer to newly created stack.
 * STRATEGY:     Simply creates an empty stack data structure.
 *******************************************************************/
ptrToStackType MakeEmptyStack
  (
  void
  )
{
  ptrToStackType S; /* Temporary stack pointer. */

     /*
      * Allocate memory for stack data structure.
      * If there's an error, exit to DOS.
      * Initialize head pointer and number of elements.
      * Return pointer to new stack.
      */
  S = malloc( sizeof( stackType ) );
  S->head = NULL;
  S->numElements = 0;
  return( S );
} /* MakeEmptyStack */

/********************************************************************
 *                 FreeStack
 ********************************************************************
 * SYNOPSIS:     Frees all the nodes of the stack and then frees the
 *               stack itself.
 * PARAMETERS:   void ( ptrToStackType S )
 * STRATEGY:     First free each of the nodes by calling Pop until
 *               there are no more items, then free the stack.
 *******************************************************************/
void FreeStack
  (
  ptrToStackType S /* Pointer to stack to free. (in) */
  )
{
  sDataType x; /* Temporary (Don't attempt to correct the
               * compiler warning.) */

    /*
     * Pop until the stack is empty.
     * Free the stack data structure.
     */
  while ( !IsEmptyStack( S )) {
    Pop( S, &x );
  }
  free( S );
} /* FreePStack */

/********************************************************************
 *                 IsEmptyStack
 ********************************************************************
 * SYNOPSIS:     Checks if the stack is empty.
 * PARAMETERS:   ( ptrToStackType S )
 * RETURNS:      boolean - TRUE if stack is empty.
 * STRATEGY:     Checks S->numElements = 0 and returns result.
 *******************************************************************/
boolean IsEmptyStack
  (
  ptrToStackType S /* Pointer to stack to free. (in) */
  )
{
  return( S->numElements == 0 );
} /* IsEmptyPStack */

/********************************************************************
 *                 Push
 ********************************************************************
 * SYNOPSIS:     Pushes the data onto the stack, placing it at the
 *               front of the list.
 * PARAMETERS:   void ( ptrToStackType S,
 *                      sDataType       x )
 * STRATEGY:     Allocates a new node type and places the data into
 *               the data field of that node.
 *******************************************************************/
void Push
  (
  ptrToStackType S, /* Pointer to stack to push onto. (in) */
  sDataType       x  /* Data to push. (in) */
  )
{
  ptrToSNodeType ptr; /* Temporary pointer */

     /*
      * Allocate memory for stack element.
      * If there's an error, exit to DOS.
      * Copy data into stack element.
      */
  ptr = malloc( sizeof( sNodeType ) );
  ptr->data = x;

     /*
      * Add node to front of list.
      * Increment number of elements on stack.
      */
  ptr->next = S->head;
  S->head = ptr;
  S->numElements++;
} /* Push */

/********************************************************************
 *                 Pop
 ********************************************************************
 * SYNOPSIS:     Pops the top element from the stack.
 * PARAMETERS:   void ( ptrToStackType S,
 *                      sDataType *     x )
 * STRATEGY:     Pops the top element from the stack and
 *               returns it, first checking to see if the stack is
 *               empty.
 *******************************************************************/
void Pop
  (
  ptrToStackType S, /* Pointer to stack to pop from. (in) */
  sDataType *     x  /* Data to pop. (out) */
  )
{
  ptrToSNodeType ptr; /* Temporary pointer */

     /*
      * Check if stack is empty. If so, display message.
      * Else, extract data from top element and remove
      * it from the list, maintaining the list pointers.
      */
  if ( !IsEmptyStack( S ) ) {
    *x = S->head->data;
       /*
        * Set pointer to head.
        * Advance head to next element.
        * Free the old head element.
        * Decrement the number of elements on the stack.
        */
    ptr = S->head;
    S->head = ptr->next;
    free( ptr );
    S->numElements--;
  }
} /* Pop */

/********************************************************************
 *                 TopOfStack
 ********************************************************************
 * SYNOPSIS:     Returns value of the top element from the stack.
 * PARAMETERS:   void ( ptrToStackType S,
 *                      sDataType *     x )
 * STRATEGY:     Returns the value of the element at the top of
 *               the stack.
 *******************************************************************/
void TopOfStack
  (
  ptrToStackType S, /* Pointer to stack. (in) */
  sDataType *     x  /* Data to return. (out) */
  )
{
  if ( !IsEmptyStack( S ) ) {
    *x = S->head->data;
  }
} /* TopOfStack */

/********************************************************************
 *                 SizeOfStack
 ********************************************************************
 * SYNOPSIS:     Returns the number of elements on the stack.
 * PARAMETERS:   ( ptrToStackType S )
 * RETURNS:      int - Number of elements on stack.
 * STRATEGY:     Returns the value of S->numElements.
 *******************************************************************/
int SizeOfStack
  (
  ptrToStackType S /* Pointer to stack. (in) */
  )
{
  return( S->numElements );
} /* SizeOfStack */

