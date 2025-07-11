## 20 Parse Library

The Parse Library was originally created to provide a parser for a 
spreadsheet language. However, it will also fit the needs of a programmer 
who wants to implement a language based on mathematical expressions.

The Parse Library takes an expression as text, converts it to an expression 
using tokens, and evaluates the expression. When finished, it converts the 
result back into text and returns it. The Parse Library recognizes a special 
grammar and set of expressions that include an interface to the Cell Library's 
data structures. Therefore, you can use the Cell and Parse Libraries together 
to form the basic underlying engine of a spreadsheet application.

Applications will generally not use the Parse library directly; instead, they 
will use higher-level constructs like the Spreadsheet library (see 
"Spreadsheet Objects," Chapter 20 of the Object Reference Book). Thus, most 
programmers can just read [Parse Library Behavior](#201-parse-library-behavior). 
The few programmers who will be using the parse library directly can read 
[Coding with the Parse Library](#203-coding-with-the-parse-library). This chapter often says that "the 
application" must do something: the application pass a callback routine to 
the parser, for example. If you use a higher-level interface, most of this will 
be taken care of for you; for example, the spreadsheet library takes care of 
the bookkeeping chores associated with the Parse Library.

You may want to familiarize yourself with how compilers work before you 
read this section. In particular, you should understand how scanners use 
regular expressions to translate raw text into token streams; and you should 
be familiar with the parsing of context-free grammars. A good book to look at 
is Compilers: Principles, Techniques, and Tools by Aho, Sethi, and Ullman 
(a.k.a. "The Red Dragon Book").

### 20.1 Parse Library Behavior

The Parse Library takes a string of characters and evaluates it. In many 
ways, it acts like a compiler; it translates a string into tokens, evaluates the 
tokens, and returns the result. It can also reverse the process, translating a 
sequence of tokens into the equivalent text string. Finally, it can simplify a 
string of tokens, performing arithmetic simplifications and calling functions. 
The parse library provides many useful functions; furthermore, applications 
can define their own functions.

The different functions are separated into different parts of the parse library. 
The parse library contains the following basic sections:

+ Scanner
The scanner reads a text string and converts it into a series of tokens. It 
does not keep track of the context of the tokens. Its behavior is partially 
determined by the localization settings; for example, it uses the 
localization setting to tell whether the decimal separator is a period, a 
comma, or some other character or string. It is called by the parser; it is 
not used independently.

+ Parser
The parser interprets the stream of tokens returned by the scanner. It 
initializes the scanner and uses it to read tokens from the input strings; 
it also makes sure that the string of tokens is legally formatted. It does 
not do any type-checking.

+ Evaluator
The evaluator simplifies a token string. It does this by replacing 
arithmetic expressions with their results, by making function calls, by 
reading current values of cells, and by replacing identifiers with their 
values. The result is another token string; usually this string consists of 
a single token (a number or string).

+ Formatter
The formatter translates a token string into a text string. It is used to 
display the evaluator's output. Its behavior is influenced by the 
localization settings.

For example, suppose an application used the parse library to evaluate the 
string "(5*6)+SUM(A2:C6)". The following steps would be taken:

1. The parser would parse the string. It would do this by calling the scanner 
to read tokens from the string. It would then parse the token sequence to 
see that it evaluated to a well-formed expression. (It would not do any 
simplifying or type-checking.)

2. The evaluator would simplify the expression. It would reduce the token 
sequence for "(5*6)" to the single token for "30". It would then call the 
SUM function, passing it the specifier for the range of cells "A2:C6". The 
SUM function would check the type of its arguments, then perform the 
appropriate action (in this case, adding the values of the cells together). 
The SUM function would return a value (e.g., it might return 999.9). The 
evaluator would thus be able to simplify the entire token sequence to the 
single token for the number 1029.9.

3. When the application needed to display the result, it would call the 
formatter. The formatter would check the localization settings, finding 
out what the thousands separator and decimal point character are. It 
would create the string "1,029.9".

Token strings are usually more compact than the corresponding text strings. 
There are several reasons for this; for example, cell references are much more 
compact, functions are specified by an ID number instead of a string, and 
white space is removed. When translated into a token string, it is only three 
bytes long: one token byte to specify that this is a number, and two data bytes 
to store the value of the number. For this reason, applications which use the 
parse library will generally not store the text entered by the user; instead, 
they can store the equivalent token string, and use the formatter to display 
the string when necessary.

The parse library routines often need to request information from the calling 
application or instruct it to perform a task. For example, when the Parser 
encounters a name, it needs to get a name ID from the calling application. For 
this reason, every Parse Library routine is passed a callback routine. The 
library routine calls this callback routine when necessary, passing a code 
indicating what action the callback routine should take. The beginning 
section will just describe this in general terms; for example, "the Evaluator 
uses the callback to find out the value of a cell." The advanced section 
provides a more detailed explanation.

#### 20.1.1 The Scanner

The scanner translates a text string into a sequence of tokens. The tokens 
can then be processed by the parser. Every token is associated with some data.

The scanner can be treated as a part of the parser. It is never used 
independently; instead, the parser is called on to parse a string, and the 
parser calls the scanner to translate the string into tokens.

The scanner does not keep track of tokens after it processes them. For this 
reason, it will not notice if, for example, parentheses are not balanced. It 
returns errors only if it is passed a string which does not scan as a sequence 
of tokens.

##### 20.1.1.1 Scanner Tokens

The scanner recognizes the tokens listed below. Note that applications will 
never directly encounter the scanner tokens; the tokens translates them into 
parser tokens before returning them. A complete list of parser tokens (with 
their names) is given in [section 20.1.2.2](#20112-strings).

|Token             |Description|
|:-----------------|-----------|
|NUMBER            |This is some kind of numerical constant. The format in the string is determined by the localization settings. The data section of the token is a floating-point number (even if the string contained an integer).|
|STRING            |This is a sequence of characters surrounded by "double-quotes." All characters within double quotes are translated into their ASCII equivalents, with the exceptions noted below in [section 20.1.1.2](#20112-strings). The data section is a pointer to the ASCII string specified.|
|CELL              |This is a reference to a cell in a database. The format is described in [section 20.1.1.3](#20113-cell-references). |
|END_OF_EXPRESSION |The scanner returns this token when it has examined and translated an entire text string and reached its end.|
|OPEN_PAREN        |This is simply a left parenthesis character, i.e. "(". There is no data section associated with this token.  |
|CLOSE_PAREN       |This is simply a right parenthesis character, i.e. ")". There is no data section associated with this token. |
|OPERATOR          |This is a unary or binary operator. The operators are described in [section 20.1.1.4](#20114-operators). The data section specifies which operator was encountered.|
|LIST_SEPARATOR    |This is a comma, i.e. ",". It is used to separate arguments to functions. There is no data section associated with this token.|
|IDENTIFIER        |This is a sequence of characters, not in quotation marks, which does not match the format for cell references. Identifiers may be functions (built-in or application-defined) or variables; see [section 20.1.1.5](#20115-identifiers). The data section is a string containing the identifier.|

##### 20.1.1.2 Strings

The string passed to the scanner may, itself, contain strings. These inner 
strings are not further analyzed; rather, their contents are associated with 
the string token. Strings are delimited by double-quotes. All characters 
within the double-quotes are copied directly into the token's data, with the 
exception of the backslash, i.e. "\". This character signals that the character 
(or characters) which immediately follow it are to be interpreted literally. 
Backslash-codes include the following:

|Code |Decription|
|:----|:---------|
|\"   |This code represents a double-quote character (i.e. ASCII 0x22, or "); it indicates that the double-quote should be copied into the string, instead of read as a string delimiter.|
|\n   |This code represents a newline control code (i.e. ASCII 0x0A, or control-J).  |
|\t   |This code represents a hard-tab control code (i.e. ASCII 0x09, or control-I). |
|\f   |This code represents a form-feed control code (i.e. ASCII 0x0C, or control-L).|
|\b   |This code represents a backspace control code (i.e. ASCII 0x10, or control-H).|
|\\   |This code represents a backslash character (i.e. ASCII 0x5C, or "\").         |
|\nnn |This code is a literal octal value. The backslash must be followed by three digits, making up an octal integer in the range 0-177o (i.e. 0-255). The byte specified is inserted directly into the string. Thus, for example, "\134" is functionally identical to "\\".|

##### 20.1.1.3 Cell References

The parse library is often used in conjunction with cell files; for example, the 
spreadsheet objects use the two libraries together. For this reason, the 
scanner recognizes cell references. Cell references are described by the 
regular expression [A-Z]+[0-9]+; that is, one or more capital letters, followed 
by one or more digits. The capital letters indicate the cell's column. The first 
column (the column with index 0) is indicated by the letter A; column 1 is B, 
column 2 is C, and so on, up to column 25 (which is Z). Column 26 is AA, 
followed by AB, AC, and so on to AZ (column 51); this column is followed by 
BA, and so on, to the largest column, IV (column 255). The rows are indicated 
by number, with the first row having number 1.

The data portion of a cell reference token is a **CellReference** structure. This 
structure records the row and column indices of the cell; the scanner 
translates the cell reference to these indices. For more information about the 
cell library, see the Cell Library section in "Database Library," Chapter 19 of 
the Concepts Book.

When the evaluator needs to get the value of a cell, it calls a callback routine, 
passing the cell's **CellReference** structure. The application is responsible 
for looking up the cell's value and returning it to the evaluator. If you manage 
a cell file with a Spreadsheet object, this work is done for you; the 
Spreadsheet will be called by the evaluator, returning the values of cells as 
needed. (The spreadsheet returns zero for empty or unallocated cells.)

Note that while the cell library numbers both rows and columns starting 
from zero, the Parse library numbers rows starting from one. This is because 
historically, spreadsheets have had the first row be row number 1. Therefore, 
if the parser encounters a reference to cell A1, it will translate this into a cell 
reference which specifies row zero, column zero.

##### 20.1.1.4 Operators

The scanner recognizes a number of built-in operators. Neither the scanner 
nor the parser does any simplification or evaluation of operator expressions; 
this is done by the evaluator. All operators are represented by the token 
SCANNER_TOKEN_OPERATOR. The token has a one-byte data section, which 
is a member of the enumerated type **OperatorType**; this value specifies 
which operator was encountered. This section begins with a listing of 
currently supported operators in order of precedence, from highest 
precedence to lowest; this is followed by a detailed description of the 
operators. All operators listed here will always be supported; other operators 
may be added in the future.

Note that neither the scanner nor the parser does any evaluation of 
arguments. All type-checking is done at evaluation time. Thus, if parse the 
text "(3 * "HELLO")", the parser will not complain; the evaluator, however, 
will return a "bad argument type" error.

Table 20-1 lists the operators in order of precedence. 
Highest-precedence operators are listed first. Operators with the same 
precedence are listed together; a blank line implies a drop in precedence. 
Operators of the same precedence level are grouped from left to right; that is, 
"1 - 2 - 3" is the same as "(1 - 2) - 3".

|Operator |Description                     |
|:--------|:-------------------------------|
|:        |range separator                 |
|...      |range separator (alternate form)|
| ||
|#        |range intersection              |
| ||
|-        |unary negation                  |
|%        |unary percent                   |
|^        |exponentiation                  |
|*        |multiplication                  |
|/        |division                        |
| ||
|%        |modulo division                 |
| ||
|+        |addition                        |
|-        |subtraction                     |
|&        |string concatenation            |
| ||
|=        |Boolean or string equality      |
|<>       |Boolean or string inequality    |
|<        |Boolean or string less-than     |
|<=       |Boolean or string less-than-or-equal-to
|>        |Boolean or string greater-than
|>=       |Boolean or string greater-than-or-equal-to

**Table 20-1** Parse Library Operators

 **:** This is a range separator. The range separator is a binary infix 
operator. The parser recognizes expressions of the format 
Cell1:Cell2 as describing a rectangular range of cells, with the 
two specified cells being diagonally opposite corners. The data 
portion of this token is the constant OP_RANGE_SEPARATOR.

 **...** This is another range separator. It is functionally identical to 
the colon operator. The data portion of this token is the 
constant OP_RANGE_SEPARATOR. (The formatter will turn this 
back into a colon.)

 **-**  This can be either of two different operators. It can be a 
negation operator. This is a unary prefix operator which 
reverses the arithmetic sign of the operand. It can also be a 
subtraction operator. This is a binary infix operator. The parser 
determines which operator is represented. For example, in 
"(-1)", the hyphen is a negation operator; in "(1-2)", it is a 
subtraction operator. The data portion of this token is either 
OP_NEGATION or OP_SUBTRACTION; the scanner assigns the 
neutral OP_SUBTRACTION_NEGATION, and the parser decides 
(from context) which value is appropriate.

 **%** This can be either of two operators. It can be a percent operator. 
This is a unary postfix operator which divides its operand by 
100; that is, "50%" evaluates to 0.5. It can also be a modulo 
arithmetic operator. This is a binary infix operator which 
returns the remainder when its first operand is divided by its 
second operand; that is, "11%4" evaluates to 3.0. The parser 
determines which operator is represented. The data portion of 
this token is either OP_PERCENT or OP_MODULO; the scanner 
assigns the neutral OP_PERCENT_MODULO, and the parser 
decides (from context) which constant is appropriate.

 **^** This is the exponentiation operator. It is a binary infix 
operator; it raises its first operand to the power of the second 
operand (e.g. "2^3" evaluates to 8.0). The data portion of this 
token is the constant OP_RANGE_EXPONENTIATION.

 **\*** This is the multiplication operator. It is a binary infix operator. 
It multiplies the two operands. The data portion of this token 
is the constant OP_MULTIPLICATION.

 **/** This is the division operator. It is a binary infix operator. It 
divides the first operand by the second. The data portion of this 
token is the constant OP_ DIVISION. The constant 
OP_DIVISION_GRAPHIC is functionally equivalent; however, 
the formatter will display the operator as "".

 **\+** This is the addition operator. It is a binary infix operator. It 
adds the two operands. The data portion of this token is the 
constant OP_RANGE_ADDITION.

Several Boolean operators are also provided. In every case, if a Boolean 
expression is true, it evaluates to 1.0; if it is false, it evaluates to 0.0. (There 
is no Boolean negation operator; however, there is a Boolean negation 
function, NOT, which returns 1.0 if its argument is zero, and otherwise 
returns zero.) Boolean operators may be used for numbers or strings. They 
work in the conventional way for numbers. Strings are "equal" if they are 
identical. One string is said to be "less than" another if it comes first in lexical 
order. The parse library uses localized string comparison routines to compare 
strings; thus, the local lexical ordering is automatically used. (For more 
information, see [Localization](clocal.md)).

 **=** This is the equality operator. It is a binary infix operator. An 
expression evaluates to 1.0 if both operands evaluate to 
identical values. The data portion of this token is the constant 
OP_EQUAL.

 **<>** This is the inequality operator. It is a binary infix operator. An 
expression evaluates to 1.0 if the two operands evaluate to 
different values. The data portion of this token is 
OP_NOT_EQUAL. The constant OP_NOT_EQUAL_GRAPHIC is 
functionally equivalent; however, the formatter will display the 
operator as "".

 **>** This is the "greater-than" operator. It is a binary infix operator. 
It returns 1.0 if the first operand evaluates to a larger number 
than the second operand. The data portion of this token is 
OP_GREATER_THAN.

 **<** This is the "less-than" operator. It is a binary infix operator. It 
returns 1.0 if the first operand evaluates to a smaller number 
than the second operand. The data portion of this token is 
OP_LESS_THAN.

 **>=** This is the "greater-than-or-equal-to" operator. It is a binary 
infix operator. It returns 1.0 if the first operator evaluates to a 
number that is greater than or equal to the value of the second 
operand. The data portion of this token is 
OP_GREATER_THAN_OR_EQUAL. The constant 
OP_GREATER_THAN_OR_EQUAL_GRAPHIC is functionally 
equivalent; however, the formatter will display the operator as "".

 **<=** This is the "less-than-or-equal-to" operator. It is a binary infix 
operator. It returns 1.0 if the first operator evaluates to a 
number that is less than or equal to the value of the second 
operand. The data portion of this token is 
OP_LESS_THAN_OR_EQUAL. The constant 
OP_LESS_THAN_OR_EQUAL_GRAPHIC is functionally 
equivalent; however, the formatter will display the operator as "≤".

Some special-purpose operators are also provided:

 **&** This is the "string-concatenation" operator. It is a binary infix 
operator. The arguments must be strings. The result is a single 
string, composed of all the characters of the first string 
(without its null terminator) followed by all the characters of 
the second string (with its null terminator); for example, 
("Franklin" & "Poomm") evaluates to "FranklinPoomm". The 
data portion of this token is OP_STRING_CONCAT.

 **#** This is the "range-intersection" operator. It is a binary infix 
operator. Both arguments must be cell ranges. The result is the 
range of cells which falls in both of the operand cell ranges. 
Note that cell ranges must be rectangular; there is, therefore, 
no "range-union" operator. The data portion of this token is 
OP_RANGE_INTERSECTION.

##### 20.1.1.5 Identifiers

Any unbroken alphanumeric character sequence which does not appear in 
quotes, and which is not in the format for a cell reference, is presumed to be 
an identifier. Identifiers serve two roles: they may be function names, or they 
may be labels.

The scanner merely notes that an identifier has been found; it does not take 
any other action. The parser will find out what the identifier signifies. If the 
identifier's position indicates that it is a function (but the name is not that of 
a built-in function), the parser will prompt its caller for a pointer to a callback 
routine which will perform this function. If its position indicates that it is an 
identifier, the parser will request the value associated with the identifier; 
this may be a string, a number, or a cell reference.

#### 20.1.2 The Parser

Applications will never call the scanner directly. Instead, if they access the 
parse library directly (instead of through the spreadsheet objects), they will 
call the parser and pass it a string, and the parser will in turn call the 
scanner to process the string into tokens. This section will not discuss how to 
call the parser, since few applications will need to do that; it will instead 
describe the general workings of the parser.

The parser translates a well-formed string into a sequence of tokens. It calls 
the scanner to read tokens from the string. It then uses a context-free 
grammar to make sure the string is well formed. The context-free grammar 
is described below. The scanner outputs a sequence of parser tokens. The 
parser tokens are almost identical to the scanner tokens, with a few 
exceptions; those exceptions are noted below.

The parser is passed a callback routine. The parser calls this routine when it 
needs information about a token; for example, if it encounters a function it 
does not recognize, it calls the callback to get a pointer to the function. The 
details of this are provided in the advanced section.

If the parser is not passed a well-formed expression, or if it is unable to 
successfully parse the string for some other reason, it returns an error code. 
The error codes are described at length in the advanced section.

##### 20.1.2.1 The Parser's Grammar

The parser uses a context-free grammar to make sure the string is 
well-formed. The grammar is listed below. The basic units of the grammar 
are listed in ALL-CAPS; higher-level units are listed in italics. The string 
must parse to a well-formed expression.

expression:     
>'(' expression ')'  
NEG_OP expression  
IDENTIFIER '(' function_args ')'  
base_item more_expression

more_expression:
>\<empty>  
PERCENT_OP more_expression  
BINARY_OP expression

function_args:
>\<empty>  
arg_list

arg_list:
>expression  
expression ',' arg_list

base_item:      
>NUMBER  
STRING  
CELL_REF  
IDENTIFIER

##### 20.1.2.2 Parser Tokens

The parser does not return scanner tokens; instead, it returns a sequence of 
parser tokens. The parser tokens are almost directly analogous to the 
scanner tokens. However, a few additional token types are added. 

The parser tokens have the same structure as the scanner tokens. The first 
field is a constant specifying what type of token this is. The second field 
contains specific information about the token; this field may be blank. The 
parser has the following types of tokens:

|Token                         |Description                                  |
|:-----------------------------|:--------------------------------------------|
|PARSER_TOKEN_NUMBER           |This is the same as the scanner NUMBER token.|
|PARSER_TOKEN_STRING           |This is the same as the scanner STRING token.|
|PARSER_TOKEN_CELL             |This is the same as the scanner CELL token.  |
|PARSER_TOKEN_END_OF_EXPRESSION|This is the same as the scanner END_OF_EXPRESSION token.|
|PARSER_TOKEN_OPEN_PAREN       |This usually replaces the scanner OPEN_PAREN token. However, it is not used if the parenthesis is delimiting function arguments; it is only used if the parenthesis is changing the order of evaluation.|
|PARSER_TOKEN_CLOSE_PAREN      |This usually replaces the scanner CLOSE_PAREN token. However, it is not used if the parenthesis is delimiting function arguments; it is only used if the parenthesis is changing the order of evaluation.|
|PARSER_TOKEN_NAME             |This replaces some occurrences of the scanner IDENTIFIER token; specifically, those where the identifier is not a function name. The data portion is the number for that name.|
|PARSER_TOKEN_FUNCTION         |This replaces some occurrences of the scanner IDENTIFIER token, specifically those in which the identifier is a function name. The data portion is the function ID number.|
|PARSER_TOKEN_CLOSE_FUNCTION   |This replaces some occurrences of the scanner CLOSE_PAREN token; specifically, those where the closing parenthesis delimits function arguments.|
|PARSER_TOKEN_ARG_END          |The parser inserts this token after every argument to a function call; thus, it replaces occurrences of SCANNER_TOKEN_LIST_SEPARATOR, and also occurs after the last argument to a function.|
|PARSER_TOKEN_OPERATOR         |This is the same as the parser's OPERATOR token. The data section is an operator constant, as described above in "Operators" on page 748. Note the parser replaces occurrences of OP_PERCENT_MODULO with either OP_PERCENT or OP_MODULO, as appropriate; similarly, it replaces OP_SUBTRACTION_NEGATION with either OP_SUBTRACTION or OP_NEGATION.|

When the parser encounters an identifier that is in the appropriate place for 
a function name (that is, an identifier followed by a parenthesized argument 
list), it does not write an identifier token. Instead, it writes a "function" 
token, which has a one-word data section. This section is the function ID 
(described in [section 20.2](#202-parser-functions)). If the function's name is not one of a 
built-in function, it will call the application's callback routine to find out what 
the function's ID number is; the evaluator will pass this ID when it needs to 
have the function called.

When the parser encounters an identifier, it asks its caller for an ID number 
for the identifier. It can then store the ID number instead of the entire string. 
The evaluator will use this ID number when requesting the value of the 
identifier. The formatter will use the ID number when requesting the original 
identifier string associated with the ID number.

When the parser encounters a scanner parenthesis token, it does not 
necessarily translate it into a parser parenthesis token. This is because 
parentheses fulfill two separate roles: they specify the order of evaluation, 
and they delimit function arguments. When the parser encounters 
parenthesis tokens which specify order of evaluation, it translates them into 
parser parenthesis tokens. If, however, it encounters argument-delimiting 
parentheses, it does not need to translate them literally; after all, the 
presence of a function token implies that it will be followed by an argument 
list. Thus, the parser does not need to copy the parenthesis tokens. Instead, 
it copies the tokens of the argument list. When it reaches a list separator, it 
replaces that with an "end-of-argument" token; when it reaches the closing 
parenthesis for the function call, it replaces that with a "close-function" 
token.

##### 20.1.2.3 An Example of Scanning and Parsing

Suppose that you call the parser on the text string 
"3 + SUM(6.5, 3 ^ (4 - 1), C5...F9)". The parser will evaluate the string, one 
token at a time. When it needs to process a token, it will call the scanner to 
return the next token in the string. It will then replace these tokens with 
parser tokens, and write out the sequence of tokens to its output buffer.

For simplicity, this example treats the scanner as if it scanned the entire text 
stream at once, and returned the entire sequence of tokens to the scanner. In 
this case, the scanner would translate the text into the following sequence of 
tokens:

|Token          |Data                   |Comment                               |
|:--------------|:----------------------|:-------------------------------------|
|NUMBER         |3.0                    |All numbers are floats                |
|OPERATOR       |OP_ADDITION            |                                      |
|IDENTIFIER     |"SUM"                  |                                      |
|OPEN_PAREN     |                       |delimits function args                |
|NUMBER         |6.5                    |                                      |
|LIST_SEPARATOR |                       |                                      |
|NUMBER         |3.0                    |                                      |
|OPERATOR       |OP_EXPONENTIATION      |                                      |
|OPEN_PAREN     |                       |                                      |
|NUMBER         |4.0                    |                                      |
|OPERATOR       |OP_SUBTRACTION_NEGATION|Parser figures out which operator this is|
|NUMBER         |1.0
|CLOSE_PAREN    |
|LIST_SEPARATOR |
|CELL           |C5                     |Actually stored as "4,2"; row index 4, column index 2
|OPERATOR       |OP_RANGE_SEPARATOR
|CELL           |F9
|CLOSE_PAREN    |
|END_OF_EXPRESSION|||

The parser reads these tokens, one at a time, and writes out an analogous 
sequence of parser tokens:

|Token          |Data                   |Comment                               |
|:--------------|:----------------------|:-------------------------------------|
|NUMBER         |3.0                    |All numbers are floats                |
|OPERATOR       |OP_ADDITION            |
|FUNCTION       |FUNCTION_ID_SUM        |
|NUMBER         |6.5                    |
|END_OF_ARG     |                       |
|NUMBER         |3.0                    |
|OPERATOR       |OP_EXPONENTIATION      |
|OPEN_PAREN     |                       |
|NUMBER         |4.0                    |
|OPERATOR       |OP_SUBTRACTION         |
|NUMBER         |1.0                    |
|CLOSE_PAREN    |
|END_OF_ARG     |
|CELL           |C5                     |Actually stored as "4,2"; row index 4, column index 2
|OPERATOR       |OP_RANGE_SEPARATOR     |
|CELL           |F9
|END_OF_ARG     |
|CLOSE_FUNCTION |
|END_OF_EXPRESSION

The application does not need to save the original text string. Instead, it can 
save the buffer containing the parser tokens, and use the formatter to 
translate the token sequence back into a character string.

#### 20.1.3 Evaluator

The evaluator simplifies a token string returned by the parser. If the input 
token sequence was well-formed (as are all token sequences generated by the 
Parser), the evaluator will produce a token sequence consisting of two tokens: 
a single "result" token (which may be an error token), followed by the 
"end-of-expression" token. It does this by doing two main things: simplifying 
arithmetic expressions, and making function calls. 

The evaluator maintains two stacks, an Operator stack and an Argument 
stack. It reads the tokens from beginning to end. Each time it reads a token, 
it takes an action; this may involve pushing something onto a stack, or 
processing some of the tokens on the tops of the stacks.

If an error occurs, the parser may take two different actions. Some errors are 
pushed on the argument stack; these may be handled by functions. For 
example, if the result of an expression is too large to be represented, the 
evaluator will just push PSEE_FLOAT_POS_INFINITY on the argument stack. 
Any function or operator which is passed an error code as an argument can 
either handle the error, propagate the error, or return a different error. For 
example, if the division operator is passed PSEE_FLOAT_POS_INFINITY as 
the divisor, it will simply return zero.

The actual evaluation of tokens is straightforward. The evaluator pops the 
top token from the Operator stack. This is either a function or an operator. If 
the token is an operator, the evaluator pops either one or two arguments from 
the top of the argument stack, takes the appropriate action, and pushes the 
result on the argument stack. If the token is a function, the evaluator calls 
the function directly, passing it a pointer to the argument stack and the 
number of arguments to the function call. The function is responsible for 
popping off all of the arguments and pushing the return value on the 
argument stack.

Special actions have to be taken if an operand or argument is a cell reference. 
If the cell is an argument to a function, or an operand (and the operator is not 
a range-separator or range-intersection), the evaluator will call its callback 
routine to get the value contained by the cell; this value will be put on the 
argument stack in place of the cell reference. If the operand is a 
range-separator or range-intersection, the cells or ranges will be combined 
into a single range, which is pushed on the Argument stack.

The evaluator reads tokens, one at a time, from the buffer provided by the 
parser. For each token it takes an appropriate action:

**OPEN_PAREN**  
Push an OPEN_PAREN token on the Operator stack.

**CLOSE_PAREN**  
Evaluate tokens from the Operator stack until an 
OPEN_PAREN reaches the top of the operator stack; then pop 
the OPEN_PAREN off the stack.

**OPERATOR**  
If the top token on the Operator stack is an OPERATOR of 
higher precedence than this OPERATOR, then evaluate top of 
Operator stack. Repeat until top of operator stack is either not 
an operator, or is an operator of lower precedence. Finally, push 
the operator token on the operator stack.

**FUNCTION**  
Push FUNCTION token on the Operator stack. The evaluator 
FUNCTION token contains the function ID and the number of 
arguments to the function (starting at zero).

**CLOSE_FUNCTION**  
Call function on top of Operator stack, passing it the pointer to 
the Argument stack and the number of arguments to the 
function call. (The arguments will be on the top of the 
argument stack.) The function should pop the arguments off 
the Argument stack, then push the return value (or error code) 
on the Argument stack.

**ARG_END**  
Evaluate the Operator stack until a FUNCTION token is at the 
top of the Operator stack; then increment the argument count 
of that function.

**NUMBER**  
Push number on Argument stack. (Actually, what is pushed is 
a reference to the thread's floating-point stack, which contains 
the number itself.)

**STRING**  
Push string on Argument stack.

**CELL_REF**  
Push the cell reference on the Argument stack.

**NAME**  
Call the callback function to find the value associated with the 
name; act on the value appropriately.

**END_OF_EXPRESSION**  
Evaluate the Operator stack until it is empty; the result will be 
on the top of the Argument stack.

#### 20.1.4 Formatter

In order to display a token sequence, you must call the Formatter. The 
formatter is very straightforward. It is passed a buffer containing a token 
sequence; it returns a character array containing the result. The formatter 
makes use of the localization routines to format the result according to the 
local language and the user's Preferences settings.

If the token sequence consists of an error token, the formatter will generate 
an appropriate error string.

### 20.2 Parser Functions

The Parse library provides many built-in functions. Furthermore, each 
application can define its own functions. Every function is associated with a 
function ID number. Built-in functions have ID numbers assigned to them in 
the library code; application-defined functions are given ID numbers by the 
application. ID numbers are word-sized unsigned integers. All built-in 
("internal") functions have ID numbers which are less than the constant 
FUNCTION_ID_FIRST_EXTERNAL_FUNCTION_BASE; all application-defined 
("external") functions have ID numbers which are greater than this constant.

When the Parser reads an identifier token whose position indicates that it is 
a function, it converts the identifier to a function token (containing a function 
ID). The parser first checks to see if the identifier is the name of a built-in 
function. If so, it looks up the function's ID number and stores it in the 
function token.

If the identifier is not the name of a built-in function, the Parser calls the 
application's callback routine to get the function's ID number. The application 
must assign each function a word-sized ID which is greater than or equal to 
the constant FUNCTION_ID_FIRST_EXTERNAL_FUNCTION_BASE. This 
constant is defined as 0x8000, which leaves  ID numbers available.

When the Evaluator needs to evaluate a function, it checks to see if the 
function is external or internal. If the function is internal, it looks up the 
functions address and calls it. If the function is external, it calls the 
application's callback routine and passes the function ID. In either case, it 
passes a pointer to the argument stack and the number of arguments. The 
function is responsible for popping all the arguments off the stack and 
pushing the result. It can also push an error message on the stack. All of this 
is discussed at length in the advanced section.

#### 20.2.1 Internal Functions

The Parse library provides many internal functions, and more are 
continually being added. Any application which uses the parse library 
automatically makes use of these functions. Some of these functions take a 
single argument; others take a set number of arguments or a variable 
number.

A listing of currently available functions follows, along with a short 
description of each one.

| Function | Description                                |
|:---------|:-------------------------------------------|
|ABS       |Absolute value                              |
|ACOS      |Arc-cosine                                  |
|ACOSH     |Hyperbolic arc-cosine                       |
|AND       |Boolean AND                                 |
|ASIN      |Arc-sine                                    |
|ASINH     |Hyperbolic arc-sine                         |
|ATAN      |Arc-tangent                                 |
|ATAN2     |Four-quadrant arc-tangent                   |
|ATANH     |Hyperbolic arc-tangent                      |
|AVG       |Average of arguments                        |
|CHAR      |Translates character-set code into character|
|CHOOSE    |Finds value in list at specified offset     |
|CLEAN     |Removes control characters from a string    |
|CODE      |Translates character into character-set code|
|COLS      |Returns # of columns in range               |
|COS       |Cosine                                      |
|COSH      |Hyperbolic cosine                           |
|CTERM     |Returns time for an investment to reach a specified value|
|DDB       |Depreciation over a period                  |
|DEGREES   |Converts radians to degrees                 |
|ERR       |Returns error PSEE_GEN_ERR                  |
|EXACT     |Tests if two strings match                  |
|EXP       |Exponentiation                              |
|FACT      |Factorial                                   |
|FALSE     |Returns false (0.0)                         |
|FIND      |Returns position in string where substring first occurs|
|FV        |Future value of investment                  |
|HLOOKUP   |Finds a value in a horizontal lookup table  |
|IF        |IF(<cond>,x,y) = x if <cond> is true, else y (like C's "<cond> ? x : y")|
|INDEX     |Finds value at specified offset in a range  |
|INT       |Rounds to next lowest integer               |
|IRR       |Internal rate of return                     |
|ISERR     |True if argument is error                   |
|ISNUMBER  |True if argument is number                  |
|ISSTRING  |True if argument is string                  |
|LEFT      |Returns first characters in string          |
|LENGTH    |Returns length of string                    |
|LN        |Natural log                                 |
|LOG       |Log to base 10                              |
|LOWER     |Converts string to all-lowercase            |
|MAX       |Returns largest of arguments                |
|MID       |Returns characters from middle of string    |
|MIN       |Returns smallest of arguments               |
|MOD       |Modulo arithmetic                           |
|N         |Returns value of first cell in range        |
|NA        |Returns error PSEE_NA                       |
|NPV       |Returns net present value of future cash flows|
|OR        |Boolean OR                                  |
|PI        |Returns 3.1415926...                        |
|PMT       |Calculates # of payments to pay off a debt  |
|PRODUCT   |Returns product of arguments                |
|PROPER    |Converts string to "proper capitalization"  |
|PV        |Calculates present value of an investment   |
|RADIANS   |Converts radians to degrees                 |
|RANDOM    |Generates random number between 0 and 1     |
|RANDOMN   |Generates random integer below a specified ceiling|
|RATE      |Calculates interest rate needed for investment to reach specified value|
|REPEAT    |Returns string made of repeated argument string|
|REPLACE   |Replaces characters in a string             |
|RIGHT     |Returns last characters in a string         |
|ROUND     |Rounds number to specified precision        |
|ROWS      |Returns number of rows in range             |
|SIN       |Sine                                        |
|SINH      |Hyperbolic-sine                             |
|SLN       |Calculates straight-line depreciation       |
|SQRT      |Square-root                                 |
|STD       |Calculates standard deviation               |
|STDP      |Standard deviation of entire population     |
|STRING    |Converts number into string                 |
|SUM       |Returns sum of arguments                    |
|SYD       |Sum-of-years'-digits depreciation           |
|TAN       |Tangent (sine/cosine)                       |
|TANH      |Hyperbolic tangent (sinh/cosh)              |
|TERM      |Returns number of payments needed to reach future value|
|TRIM      |Removes leading, trailing, and consecutive spaces from a string|
|TRUE      |Returns TRUE (1.0)                          |
|TRUNC     |Removes fractional part; rounds towards zero|
|UPPER     |Converts all letters in string to uppercase |
|VALUE     |Converts string to number                   |

#### 20.2.2 External Functions

Applications which use the Parse library may write their own functions. 
Whenever the formatter encounters a function name which it does not 
recognize, it calls the application to get an ID for the function. When the 
evaluator needs to evaluate that function, it calls the application, passing the 
arguments and the function ID. The application should return a single value. 
If it cannot produce a value, it should return an error code. The error codes 
are described in [section 20.3.2](#2032-evaluating-a-token-sequence).

### 20.3 Coding with the Parse Library

This section describes how to use the Parser directly, instead of using 
intermediaries (like the Spreadsheet library). Most applications will not need 
to use these routines.

#### 20.3.1 Parsing a String

ParserParseString()

To parse a string, all you do is call **ParserParseString()**. This routine takes 
three arguments: A pointer to a null-terminated string, a pointer to a buffer, 
and a pointer to a **ParserReturnStruct**. This structure contains a pointer 
to a callback routine. **ParserParseString()** parses the string into a 
sequence of tokens and writes the tokens to the buffer. Whenever the parser 
encounters an identifier, it calls the callback routine and requests an ID 
number for the identifier. Similarly, when the parser encounters a function 
whose name it does not recognize, it calls the callback routine to get a 
function ID number. The ID numbers are stored in the token sequence. 

The Parser can return the following errors:

**PSEE_BAD_NUMBER**  
The string contained a badly-formatted number.

**PSEE_BAD_CELL_REFERENCE**  
The string contained a badly-formatted cell reference.

**PSEE_NO_CLOSE_QUOTE**  
The string contained an opening quote with no matching 
closing quote.

**PSEE_COLUMN_TOO_LARGE**  
The string contained a cell whose column index was out of 
bounds (greater than 255).

**PSEE_ROW_TOO_LARGE**  
The string contained a cell whose row index was out of bounds.

**PSEE_ILLEGAL_TOKEN**  
The string contained a character sequence which was not a legal token.

**PSEE_TOO_MANY_TOKENS**  
The expression was too complex.

**PSEE_EXPECTED_OPEN_PAREN**  
A function call lacked an open-parenthesis.

**PSEE_EXPECTED_CLOSE_PAREN**  
A function call lacked a close-parenthesis.

**PSEE_BAD_EXPRESSION**  
The string contained a badly-formed expression.

**PSEE_EXPECTED_END_OF_EXPRESSION**  
An expression ended improperly.

**PSEE_MISSING_CLOSE_PAREN**  
Parentheses were mismatched.

**PSEE_UNKNOWN_IDENTIFIER**  
An identifier or external function name was encountered, and 
the callback routine would not provide an ID for it.

**PSEE_GENERAL**  
General parser error.

#### 20.3.2 Evaluating a Token Sequence

ParserEvalExpression()

To format an expression, call **ParserEvalExpression()**. This routine is 
passed a token sequence; it evaluates it and writes the result, another token 
sequence, to a passed buffer. It calls a supplied callback routine to perform 
the following tasks:

+ Return the value of a specified cell

+ Return the value associated with a given identifier, specified by ID number

+ Evaluate an external function, given the arguments and the function ID number

The evaluator produces a sequence two tokens long, including the 
"end-of-expression" token. The first token might be an error token. Two 
errors are so serious that if they occur, the evaluation is immediately halted 
and the error is returned:

**PSEE_OUT_OF_STACK_SPACE**  
The evaluator ran out of stack space. Evaluation was halted 
when this occurred.

**PSEE_NESTING_TOO_DEEP**  
The nesting grew too deep for the evaluator. Evaluation was 
halted when this occurred.

The following errors may be propagated; that is, if an expression returns an 
error, that error would be passed, as a value, to outer expressions. For 
example, if the evaluator were evaluating 
"SUM(1, (PROD(1, 2, "F. T. Poomm"))", PROD would return 
PSEE_WRONG_TYPE, since it expects numeric arguments. SUM, in turn, 
would be passed two arguments: the number 1 and the error 
PSEE_WRONG_TYPE. That function might, in turn, propagate the error 
upward, return a different error, or return a non-error value. (SUM, as it 
happens, would propagate the error; that is, it would return PSEE_WRONG_TYPE.)

**PSEE_ROW_OUT_OF_RANGE**  
A cell's row index was out of range.

**PSEE_COLUMN_OUT_OF_RANGE**  
A cell's column index was out of range.

**PSEE_FUNCTION_NO_LONGER_EXISTS**  
The callback routine did not recognize the function ID for an 
external function.

**PSEE_BAD_ARG_COUNT**  
A function was passed the wrong number of arguments.

**PSEE_WRONG_TYPE**  
A function was passed an argument of the wrong type.

**PSEE_DIVIDE_BY_ZERO**  
A division by zero was attempted.

**PSEE_UNDEFINED_NAME**  
The callback would not provide a value for an identifier ID.

**PSEE_CIRCULAR_REF**  
A circular reference occurred. This error will only occur if it is 
returned by the callback routine.

**PSEE_CIRCULAR_DEP**  
The value is dependant on a cell whose value is PSEE_CIRCULAR_REF.

**PSEE_CIRC_NAME_REF**  
The expression uses a name which is defined circularly.

**PSEE_NUMBER_OUT_OF_RANGE**  
The result was a number which could not be expressed as a float.

**PSEE_GEN_ERR**  
General error; this is returned when no other error code is appropriate.

**PSEE_NA**  
The value for a cell was not available.

**PSEE_FLOAT_POS_INFINITY**  
A float routine returned the error FLOAT_POS_INFINITY.

**PSEE_FLOAT_NEG_INFINITY**  
A float routine returned the error FLOAT_NEG_INFINITY.

**PSEE_FLOAT_GEN_ERR**  
A float routine returned the error FLOAT_GEN_ERR.

**PSEE_TOO_MANY_DEPENDENCIES**  
The formula contained too many levels of dependency. This is 
generally returned by the callback routine; the Parse library 
routines do not return this error, they merely propagate it.

The application may also define its own error codes, beginning with the 
constant PSEE_FIRST_APPLICATION_ERROR. All internal functions, and all 
operators, always propagate application-defined errors.

#### 20.3.3 Formatting a Token Sequence

ParserFormatExpression()

The routine **ParserFormatExpression()** is passed a token buffer; it 
returns a character string. The formatter uses the localization routines to 
format numbers. The formatter also formats error codes as appropriate error 
messages. These error messages are stored in a localizable resource, so the 
formatter library will produce error messages in the appropriate language.

If the formatter encounters a token ID or an external function ID, it will call 
the callback routine to find out what character sequence is associated with 
that ID number. If it encounters an application-defined error code, it will 
request an appropriate error string. Applications should store these error 
strings in localizable resources; this will simplify translating the application 
into another language.

[Database Library](cdb.md) <-- &nbsp;&nbsp; [table of contents](../concepts.md) &nbsp;&nbsp; --> [Using Streams](cstream.md)
