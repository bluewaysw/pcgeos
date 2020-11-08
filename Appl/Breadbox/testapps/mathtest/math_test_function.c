/*
 * Copyright 2020   Jirka Kunze
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
#include "math_test_function.h"
#include <math.h>
#include <string.h>

#define MAX_TEXT_LEN      30
#define MAX_DIGITS        10

Boolean test_datatypesize() {
    
    Boolean result = TRUE;
    
    result &= sizeof(float) == 4;
    result &= sizeof(double) == 8;
    //Yeah, that's right. Under Watcom a long double is 8 byte large.
    result &= sizeof(long double) == 8;
    
    return result;
}

Boolean test_function_float() {

  Boolean result = TRUE;
  float float_1 = 1.0;
  float float_2 = 2.0;
  float float_result;

  float_result = float_1 + float_2;
  result &= (float_result == 3.0);

  float_result = float_1 - float_2;
  result &= (float_result == -1.0);

  float_result = float_2 - float_1;
  result &= (float_result == 1.0);

  float_result = float_2 * float_1;
  result &= (float_result == 2.0);

  float_result = float_2 / float_1;
  result &= (float_result == 2.0);

  float_result = float_1 / float_2;
  result &= (float_result == .5);

  return result;
}

Boolean test_function_double() {

  Boolean result = TRUE;
  double double_1 = 1.0;
  double double_2 = 2.0;
  double double_result;

  double_result = double_1 + double_2;
  result &= (double_result == 3.0);

  return result;
}

Boolean test_function_push_pop() {
    
    Boolean result = TRUE;
    long double ld_0 = 0;
    long double ld_1 = 1.2345;
    long double ld_2 = 2.3456;
    long double ld_3;

    //fp-stack is empty
    result &= FloatDepth() == 0;

    FloatPushNumber(&ld_0);
    result &= FloatDepth() == 1;

    FloatPushNumber(&ld_1);
    result &= FloatDepth() == 2;

    FloatPushNumber(&ld_2);
    result &= FloatDepth() == 3;

    FloatPopNumber(&ld_3);
    result &= FloatDepth() == 2;
    result &= ld_3 == ld_2;

    FloatPopNumber(&ld_3);
    result &= FloatDepth() == 1;
    result &= ld_3 == ld_1;

    FloatPopNumber(&ld_3);
    result &= FloatDepth() == 0;
    result &= ld_3 == ld_0;
    
    return result;
}

Boolean test_function_compESDI() {

  Boolean result = TRUE;

  long double ld_0 = 0;
  long double ld_1 = 0;

  FloatPushNumber(&ld_0);
  result &= FloatCompESDI(&ld_1) == 0;
  result &= FloatDepth() == 1;

  ld_1 = 1.0;
  result &= FloatCompESDI(&ld_1) > 0;
  result &= FloatDepth() == 1;

  ld_1 = -1.0;
  result &= FloatCompESDI(&ld_1) < 0;
  result &= FloatDepth() == 1;

  return result;
}

Boolean test_funktion_floatFloatToAscii_StdFormat() {

  Boolean result = TRUE;
  long double ld = 1.2345;
  char resultStr[MAX_TEXT_LEN];

  FloatFloatToAscii_StdFormat(resultStr, &ld, FFAF_FROM_ADDR, 2, 5); 

  return result;
}

Boolean test_function_floatFormatNumber() {

  Boolean result = TRUE;
  char numAscii[MAX_TEXT_LEN];
  long double ld = 1.125;

  FloatFormatNumber(FORMAT_ID_FIXED_WITH_COMMAS,
				  NullHandle,
				  NullHandle,
				  &ld,
				  numAscii);

  result &= strcmp( numAscii, "1.125");

  return result;
}
