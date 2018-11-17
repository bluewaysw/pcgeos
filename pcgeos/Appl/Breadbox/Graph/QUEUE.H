/********************************************************************
 *
 *    Copyright 1995 (C) Blue Marsh Softworks -- All rights reserved
 *
 * PROJECT:      COMP 412 CPU Scheduling Project
 * MODULE:       Queue ADT Header file
 * FILE:         queue.h
 *
 * AUTHOR:       Nathan Fiedler
 *
 * REVISION HISTORY:
 *      Name   Date      Description
 *      ----   ----      -----------
 *       NF    04/14/95  Initial version
 *
 * DESCRIPTION:
 *      This is the header file for the queue.c program. Any
 *      program wishing to use the Queue should include this
 *      header.
 *
 *******************************************************************/

/********************************************************************
 *                 Constants
 *******************************************************************/

/********************************************************************
 *                 Typedefs
 *******************************************************************/
       /* Type for element data.
        * Change this to whatever data you want stored in the
        * queue. Usually this is a number or a pointer to a node. */
    typedef VertexNumber dataType;

       /* Type for queue node. INTERNAL */
    typedef struct node {
      dataType      data;
      struct node * next;
    } nodeType, *ptrToNodeType;

       /* Type for queue. INTERNAL */
    typedef struct {
      ptrToNodeType Head;
      ptrToNodeType Tail;
    } queueType, *ptrToQueueType;

/********************************************************************
 *                 Prototypes
 *******************************************************************/
       /* Make a new, empty queue. */
    ptrToQueueType MakeEmptyQueue
      (
      void
      );

       /* Free all the elements on the queue,
        * and the queue data structure itself. */
    void FreeQueue
      (
      ptrToQueueType Q /* Queue to free. */
      );

       /* Returns TRUE if there are no elements on the queue. */
    boolean IsEmptyQueue
      (
      ptrToQueueType Q /* Queue to check. */
      );

       /* Add a new element to the back of the queue. */
    void Enqueue
      (
      ptrToQueueType Q, /* Queue to add element to. */
      dataType x        /* Element to add to queue. */
      );

       /* Remove the first element from the front of the queue. */
    void Dequeue
      (
      ptrToQueueType Q, /* Queue to remove element from. */
      dataType * x      /* Data from the front of the queue. */
      );

       /* Return the data on the first element, without removing
        * the element from the queue. */
    void FrontOfQueue
      (
      ptrToQueueType Q, /* Queue to look at. */
      dataType * x      /* Data from front of queue. */
      );

