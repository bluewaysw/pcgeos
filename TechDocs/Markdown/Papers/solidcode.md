
# Writing Solid Code in GEOS

This file describes strategies for writing code that is as stable as possible. It was written in the
1990s and adopted for the freeGEOS project in 2026. Some of the following explanations refer to ESP
code, but also apply similarly to GOC code.

## Contents

- [Writing Solid Code in GEOS](#writing-solid-code-in-geos)
  - [Contents](#contents)
  - [Use Compiler Warnings](#use-compiler-warnings)
  - [Use EC Code to Do Parameter Checking](#use-ec-code-to-do-parameter-checking)
  - [Simplify and Solidify Your Code](#simplify-and-solidify-your-code)
  - [Write EC Code to Verify Data Structures.](#write-ec-code-to-verify-data-structures)
  - [Code with Testing and Error Detection in Mind](#code-with-testing-and-error-detection-in-mind)


## Use Compiler Warnings

Enable all compiler warnings, and pay attention to them

- Do not install code that triggers warnings.
- Compiler warnings exist to warn you of possible problems. You should pay attention
to compiler warnings. If you get a warning, you should change your code so that the
warning is not triggered.
- If you have warnings about unreferenced variables, comment out the variables, or,
  in ESP code, use the `ForceRef` macro to force a reference to the variable in question.

## Use EC Code to Do Parameter Checking

The kernel is rife with EC code. Take advantage of it. None of the EC..() routines or
EC macros are included in the non-EC version, so they don't take up any memory or time there.

- All of the graphics routines validate the
graphics-state handle which is passed in `DI`. The memory routines validate the
handles passed in `BX`. This code allows bugs to be caught early, when the mistake
is an obvious one. Without this sort of EC code, these bugs would be caught much
later when some obscure side effect shows up.
- You should take the same approach with your own code. If you are writing an API
that other developers will use, you *should* provide EC code that validates the
parameters which are passed to your API-level routines.
- If you are writing modules of an application, or are creating APIs for internal
use, you should seriously consider scheduling time to write EC code to validate
what is passed to these internal APIs.
- Use assertions to validate function arguments.

## Simplify and Solidify Your Code

- Use assertions to detect "impossible" conditions
- EC code can be valuable internally, not only for situations where you wish to
validate parameters to functions, but also internally to verify that the data you
are using is correct. This sort of thing can help you locate bugs where bad
pointers or corrupted data might cause problems:

                mov     cx, ds:[di].OI_ruleCount
        ruleLoop:
        EC <    cmp     cx, MAXIMUM_RULE_COUNT          >
        EC <    ERROR_A RULE_COUNT_TOO_LARGE            >

  This code example will catch the possibility of the instance data being uninitialized, or
  somehow corrupted. It will catch the case where the pointer DS:DI is somehow not correct,
  perhaps because the object or heap moved due to some earlier action. Finally, it will verify
  that actions within the loop do not cause CX to be corrupted.

  Remember, not all bugs will cause corruption of data or a crash. It is possible that a
  bad value in CX might only cause some delay, or possibly an attempt to interpret bad data.

## Write EC Code to Verify Data Structures.
- Do not wait for bugs to happen.
- Use EC code to validate your internal data structures.
- Maintain debug information to allow for stronger error checking.
- Create thorough subsystem checks, and use them often.

  These are all extremely important if you are writing a subsystem that is responsible for managing
  data structures. For example, our system includes code to validate an entire text object and
  the various related data structures, the entire system heap, an entire lmem heap, and so on.
  These have proved invaluable in tracking down difficult problems.

  If you write this code at the same time that you are creating your data-management routines, it
  can help you from the very beginning, and it will take less effort to code and maintain the
  data-structure validation routines.

  It is OK to keep around extra data in order to help you verify your own data structures, as
  long as this data does not exist in the non-EC version. It is important to keep this data
  separate. For instance, it is more appropriate to keep a separate array of extra EC data
  than it is to add fields to a data structure, but only in the EC code.

  This is especially true if you are dealing with data which will be saved to a file. You want
  to be able to use the same files in the EC and non-EC versions of your code.

- Use second algorithms to verify the results of your primary algorithms

  Sometimes it may make sense to keep a totally separate "brain-dead" algorithm around to
  verify that your highly optimized approach is truly working correctly. For instance,
  it may make sense to add EC code to a sorting algorithm that actually verifies that
  the entries end up sorted.

- Design with Testing and Error Detection in Mind

  Spend time to carefully design your tests

  Your test code is important. Spend as much time designing and documenting your test code 
  as you would in designing and debugging the systems which this code will test.

- Strive to implement transparent integrity checks

  Checking the integrity of your data structures will give you, and the users of your code, 
  confirmation that your code is working as expected. In a database program I wrote, it was 
  possible for a sequence of actions to corrupt a database item other than the one the user
  was looking at—a random scribbling bug.

  If I had used integrity-checking code, I would have identified this bug at the time it 
  happened rather than spending weeks tracking a problem that did not actually make itself
  apparent until much later.

- Do not apply normal constraints to EC code

  Trade size and speed for error detection.

  EC code is not a part of your product. If it makes the code larger and slower, that is 
  fine. The only exception is when it makes the code so large and slow that it is completely 
  unusable. A slowdown of 50% in the EC version may be perfectly acceptable.

- Use well-defined data types

  Esp and GOC provides the ability to create meaningful enumerated types, structures, 
  and records. Take advantage of these to produce code which is more readable and which gives 
  a clearer indication of what you mean.

## Code with Testing and Error Detection in Mind

- Destroy garbage so that it cannot be accidentally used later

  Currently the system will do this with the main heap and the lmem heap. If you are maintaining
  your own local data-structure heap, you should consider destroying data when it is freed so
  that it will not be mistaken for useful data later.

- Write comments that emphasize potential hazards

- Once you have done a good job designing and documenting your code, you should make sure that
  you take the time to focus on what can go wrong. This should start in the design phase:

  - What happens if the file does not exist?

    This should continue through coding. During the coding phase, you should take care to 
    document, in your code, the potential problems that the code is handling. This will 
    allow other people who will be working in your code to understand the problems that they 
    will need to deal with.

  - Always ask: "Can this variable or expression overflow or underflow?"

    In our system, overflow and underflow are rare, but there are frequently problems associated
    with signed versus unsigned values. In particular, in ESP, making the mistake of using 
    jg instead of ja can result in your code failing miserably when an index becomes >= 0x8000.

    It is very rare that you will want to use signed comparisons or branches, so pay close
    attention to your code in the cases where you do.

- Implement "the task" just once

  If you find yourself writing multiple copies of roughly the same code, you should be examining
  your algorithm more closely.

- Handle your special cases just once.

  If you find yourself implementing a routine that contains several special actions for a certain
  case, spend the time to examine your approach to see if you can get rid of the special case.
  The simpler the code—that is, the fewer the special cases — the easier it will be to debug.

- Get rid of extraneous ```if``` statements

  Where ever possible, reduce the number of decisions your code must make.

  Code with lots of branches is harder to debug. You must step through both paths to verify
  that it works, and even worse, it can create several new paths through your whole code body.

  Where possible, remove if/then structures. Table lookups are great for this, and there 
  may be other approaches that work. Code that does not branch is incredibly easy to debug. 
  Try to write as much of it as you can.
