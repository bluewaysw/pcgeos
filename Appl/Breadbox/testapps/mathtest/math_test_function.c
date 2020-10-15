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

Boolean test_datatypesize() {
    
    Boolean result = TRUE;
    
    result = result && sizeof(float) == 4;
    result = result && sizeof(double) == 8;
    //Yeah, that's right. Under Watcom a long double is 8 byte large.
    result = result && sizeof(long double) == 8;
    
    return result;
}

Boolean test_function_float() {

  Boolean result = TRUE;
  float float_1 = 1.0;
  float float_2 = 2.0;
  float float_result;

  float_result = float_1 + float_2;
  result = result && (float_result == 3.0);

  float_result = float_1 - float_2;
  result = result && (float_result == -1.0);

  float_result = float_2 - float_1;
  result = result && (float_result == 1.0);

  float_result = float_2 * float_1;
  result = result && (float_result == 2.0);

  float_result = float_2 / float_1;
  result = result && (float_result == 2.0);

  float_result = float_1 / float_2;
  result = result && (float_result == .5);

  return result;
}

Boolean test_function_double() {

  Boolean result = TRUE;
  double double_1 = 1.0;
  double double_2 = 2.0;
  double double_result;

  double_result = double_1 + double_2;
  result = result && (double_result == 3.0);

  return result;
}

Boolean test_function_push_pop() {
    
    Boolean result = TRUE;
    long double ld_0 = 0;
    long double ld_1 = 1.2345;
    long double ld_2 = 2.3456;
    long double ld_3;

    //fp-stack is empty
    result |= result && FloatDepth() == 0;

    FloatPushNumber(&ld_0);
    result |= result && FloatDepth() == 1;

    FloatPushNumber(&ld_1);
    result |= result && FloatDepth() == 2;

    FloatPushNumber(&ld_2);
    result |= result && FloatDepth() == 3;

    FloatPopNumber(&ld_3);
    result |= result && FloatDepth() == 2;
    result |= result && ld_3 == ld_2;

    FloatPopNumber(&ld_3);
    result |= result && FloatDepth() == 1;
    result |= result && ld_3 == ld_1;

    FloatPopNumber(&ld_3);
    result |= result && FloatDepth() == 0;
    result |= result && ld_3 == ld_0;
    
    return result;
}

Boolean test_function_compESDI() {

  Boolean result = TRUE;

  long double ld_0 = 0;
  long double ld_1 = 0;

  FloatPushNumber(&ld_0);
  result |= result && FloatCompESDI(&ld_1) == 0;
  result |= result && FloatDepth() == 1;

  ld_1 = 1.0;
  result |= result && FloatCompESDI(&ld_1) > 0;
  result |= result && FloatDepth() == 1;

  ld_1 = -1.0;
  result |= result && FloatCompESDI(&ld_1) < 0;
  result |= result && FloatDepth() == 1;

  return result;
}

/*
void setFloat(float* f) {
    float* f2;
    float abc = 10.0f;

    f2 = &abc;

    *f = 100.0f;
}
*/
