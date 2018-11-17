/********************************************************************
 *
 *    Copyright 1995 (C) Blue Marsh Softworks -- All rights reserved
 *
 * PROJECT:      COMP 412 CPU Scheduling Project
 * MODULE:       Queue ADT
 * FILE:         queue.c
 *
 * AUTHOR:       Nathan Fiedler
 *
 * REVISION HISTORY:
 *      Name   Date      Description
 *      ----   ----      -----------
 *       NF    02/05/95  Initial version of pancake stack
 *       NF    04/13/95  Changed to a Queue ADT
 *
 * DESCRIPTION:
 *      An implementation of a simple queue data structure. See the
 *      header file for the changes needed to adapt to your
 *      specific data type.
 *
 *      To use this module, add it to your project file in
 *      Borland's Project Manager. Also make sure to #include
 *      the queue.h header file.
 *
 *******************************************************************/

/********************************************************************
 *                 Headers
 *******************************************************************/
    #include <stdio.h>
    #include <stdlib.h>
    #include "graph.h"
    #include "queue.h"

/********************************************************************
 *                 MakeEmptyQueue
 ********************************************************************
 * SYNOPSIS:     Creates a new, empty queue.
 * PARAMETERS:   ( void )
 * RETURNS:      ptrToQueueType - Pointer to newly created queue.
 * STRATEGY:     Simply creates an empty queue data structure.
 *******************************************************************/
ptrToQueueType MakeEmptyQueue
  (
  void
  )
{
  ptrToQueueType Q; /* Temporary queue pointer. */

     /*
      * Allocate memory for queue data structure.
      * Initialize head and tail pointers.
      * Return pointer to new queue.
      */
  Q = malloc( sizeof( queueType ) );
  Q->Head = NULL;
  Q->Tail = NULL;
  return( Q );
} /* MakeEmptyQueue */

/********************************************************************
 *                 FreeQueue
 ********************************************************************
 * SYNOPSIS:     Frees all the nodes of the queue and then frees the
 *               queue itself.
 * PARAMETERS:   void ( ptrToQueueType Q )
 * STRATEGY:     First free each of the nodes by calling Dequeue until
 *               there are no more items, then free the queue.
 *******************************************************************/
void FreeQueue
  (
  ptrToQueueType Q /* Pointer to queue to free. (in) */
  )
{
  dataType x; /* Temporary (Don't attempt to correct the
               * compiler warning.) */

    /*
     * Dequeue until the queue is empty.
     * Free the queue data structure.
     */
  while ( !IsEmptyQueue( Q ) ) {
    Dequeue( Q, &x );
  }
  free( Q );
} /* FreePQueue */

/********************************************************************
 *                 IsEmptyQueue
 ********************************************************************
 * SYNOPSIS:     Checks if the queue is empty.
 * PARAMETERS:   ( ptrToQueueType Q )
 * RETURNS:      boolean - TRUE if queue is empty.
 * STRATEGY:     Checks Q->Head = NULL and returns result.
 *******************************************************************/
boolean IsEmptyQueue
  (
  ptrToQueueType Q /* Pointer to queue to free. (in) */
  )
{
  return( Q->Head == NULL );
} /* IsEmptyPQueue */

/********************************************************************
 *                 Enqueue
 ********************************************************************
 * SYNOPSIS:     Enqueues the data onto the queue, placing it at the
 *               end of the list.
 * PARAMETERS:   void ( ptrToQueueType Q,
 *                      dataType       x )
 * STRATEGY:     Allocates a new node type and places the data into
 *               the data field of that node.
 *******************************************************************/
void Enqueue
  (
  ptrToQueueType Q, /* Pointer to queue to enqueue to. (in) */
  dataType       x  /* Data to enqueue. (in) */
  )
{
  ptrToNodeType ptr; /* Temporary pointer */

     /*
      * Allocate memory for queue element.
      * If there's an error, exit to DOS.
      * Copy data into queue element.
      */
  ptr = malloc( sizeof( nodeType ) );
  ptr->data = x;

     /*
      * Add node to back of list.
      */
  ptr->next = NULL;
  if ( Q->Tail == NULL ) {
    Q->Head = ptr;
    Q->Tail = ptr;
  }
  else {
    Q->Tail->next = ptr;
    Q->Tail = ptr;
  }
} /* Enqueue */

/********************************************************************
 *                 Dequeue
 ********************************************************************
 * SYNOPSIS:     Dequeues the front element from the queue.
 * PARAMETERS:   void ( ptrToQueueType Q,
 *                      dataType *     x )
 * STRATEGY:     Dequeues the front element from the queue and
 *               returns it, first checking to see if the queue is
 *               empty.
 *******************************************************************/
void Dequeue
  (
  ptrToQueueType Q, /* Pointer to queue to dequeue from. (in) */
  dataType *     x  /* Data to dequeue. (out) */
  )
{
  ptrToNodeType ptr; /* Temporary pointer */

     /*
      * Check if queue is empty. If so, display message.
      * Else, extract data from first element and remove
      * it from the list, maintaining the list pointers.
      */
  if ( !IsEmptyQueue( Q ) ) {
    *x = Q->Head->data;
       /*
        * Set pointer to head.
        * Advance head to next element.
        * Set tail pointer appropriately.
        * Free the old head element.
        */
    ptr = Q->Head;
    Q->Head = ptr->next;
    if ( Q->Head == NULL ) {
      Q->Tail = NULL;
    }
    free( ptr );
  }
} /* Dequeue */

/********************************************************************
 *                 FrontOfQueue
 ********************************************************************
 * SYNOPSIS:     Returns value of the front element from the queue.
 * PARAMETERS:   void ( ptrToQueueType Q,
 *                      dataType *     x )
 * STRATEGY:     Returns the value of the element at the front of
 *               the queue.
 *******************************************************************/
void FrontOfQueue
  (
  ptrToQueueType Q, /* Pointer to queue. (in) */
  dataType *     x  /* Data to return. (out) */
  )
{

  if ( !IsEmptyQueue( Q ) ) {
    *x = Q->Head->data;
  }
} /* FrontOfQueue */

