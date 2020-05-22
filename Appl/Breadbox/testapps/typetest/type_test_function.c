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
 
#include "type_test_function.h"
#include <math.h>

Boolean test_datatype_float() {

  Boolean result = TRUE;
  float toFill = 0.0;
  
  fill_float(&toFill, (float) 1111.5);
  result = result && (toFill == (float) 1111.5);
  
  return result;
}

Boolean test_datatype_double() {

  Boolean result = TRUE;
  double toFill = 0.0;
  
  fill_double(&toFill, (double) 1111.5);
  result = result && (toFill == (double) 1111.5);
  
  return result;
}

Boolean test_datatype_longdouble() {

  Boolean result = TRUE;
  long double toFill = 0.0;
  
  fill_longdouble(&toFill, (long double) 1111.5);
  result = result && (toFill == (long double) 1111.5);
  
  return result;
}

void fill_float(float* toFill, float f) {
    *toFill = f;
}

void fill_double(double *toFill, double d) {
    *toFill = d;
}

void fill_longdouble(long double *toFill, long double ld) {
    *toFill = ld;
}

