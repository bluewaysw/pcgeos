/********************************************************************
 *
 *    Copyright 1995 (C) Blue Marsh Softworks -- All rights reserved
 *
 * PROJECT:      Abstract Data-Types
 * MODULE:       Stack ADT Header file
 * FILE:         stack.h
 *
 * AUTHOR:       Nathan Fiedler
 *
 * REVISION HISTORY:
 *      Name   Date      Description
 *      ----   ----      -----------
 *       NF    10/06/95  Initial version
 *
 * DESCRIPTION:
 *      This is the header file for the stack.c program. Any
 *      program wishing to use the stack should include this
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
        * stack. Usually this is a number or a pointer to a node. */
    typedef EdgeNumber sDataType;

       /* Type for stack node. INTERNAL */
    typedef struct sNode {
      sDataType      data;
      struct sNode * next;
    } sNodeType, *ptrToSNodeType;

       /* Type for stack. INTERNAL */
    typedef struct {
      ptrToSNodeType head;
      int           numElements;
    } stackType, *ptrToStackType;

/********************************************************************
 *                 Prototypes
 *******************************************************************/
       /* Make a new, empty stack. */
    ptrToStackType MakeEmptyStack
      (
      void
      );

       /* Free all the elements on the stack,
        * and the stack data structure itself. */
    void FreeStack
      (
      ptrToStackType S /* Stack to free. */
      );

       /* Returns TRUE if there are no elements on the stack. */
    boolean IsEmptyStack
      (
      ptrToStackType S /* Stack to check. */
      );

       /* Add a new element to the back of the stack. */
    void Push
      (
      ptrToStackType S, /* Stack to add element to. */
      sDataType x        /* Element to add to stack. */
      );

       /* Remove the first element from the front of the stack. */
    void Pop
      (
      ptrToStackType S, /* Stack to remove element from. */
      sDataType * x      /* Data from the front of the stack. */
      );

       /* Return the data on the first element, without removing
        * the element from the stack. */
    void TopOfStack
      (
      ptrToStackType S, /* Stack to look at. */
      sDataType * x      /* Data from top of stack. */
      );

       /* Returns number of elements on stack. */
    int SizeOfStack
      (
      ptrToStackType S /* Pointer to stack. (in) */
      );

