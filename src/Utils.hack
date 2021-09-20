/*
 *  Copyright (c) 2021 Ajay Vohra, https://github.com/ajayvohra2005/hack-jmespath.git 
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 *  This source code is licensed under the MIT license found in the
 *  LICENSE file in the root directory of this source tree.
 *
 */
 
namespace HackJmesPath;

use namespace HH;

use function is_callable;

class Utils
{
  /**
   * Filter the container for given generic type T
   *
   * @param Container<mixed> $container container with mixed values
   *
   * @return  vec<T> Return a vector of generic type T
   */
  public static function filterContainer<<<__Enforceable>> reify T>(Container<mixed> $container): vec<T> {
    $ret = vec<T>[];

    foreach ($container as $elem) {
      if ($elem is T) {
        $ret[] = $elem;
      } 
    }
    return $ret;
  }

  /**
   * Filter the traversable container for given generic type T
   *
   * @param Traversable<mixed> $container container with mixed values
   *
   * @return  vec<T> Return a vector of generic type T
   */
  public static function filterTraversable<<<__Enforceable>> reify T>(Traversable<mixed> $container): vec<T> {
    $ret = vec<T>[];

    foreach ($container as $elem) {
      if ($elem is T) {
        $ret[] = $elem;
      } 
    }
    return $ret;
  }

  /**
   * Is it JMESPath eexpression function
   *
   * @param mixed $v is it a JMESPath expression function
   *
   * @return  bool Return true if it is a callable JMESPath expression function
   */
  public static function is_expression(mixed $v): bool
  {
    return HH\is_fun($v) || $v is \Closure || is_callable($v);
  }

  /**
   * Is it a JSON 'object'
   *
   * @param mixed $obj is it a JMESPath 'object'
   *
   * @return  bool Return true if it is a JSON 'object'
   */
  public static function is_object(mixed $obj): bool
  {
    $retval = false;

    $i = 0;

    // if a Hack dict has contiguous 'int' keys starting from 0,
    // we map the Hack dict to the json 'array' type, else to 'object' type
    // stdClass is not supported as Json object type
    if(HH\is_dict($obj) && ($obj is KeyedContainer<_,_>)) {
      foreach ($obj as $key => $value) {
        if ( !($key is int) || $key !== $i) {
          $retval = true;
          break;
        } else {
          $i++;
        }
      }
    }

    return $retval;
  }

  /**
   * Is it a JSON 'array'
   *
   * @param mixed $value is it a JMESPath 'array'
   *
   * @return  bool Return true if it is a JSON 'array'
   */
  public static function is_array(mixed $value): bool
  {
    return HH\is_any_array($value);
  }

  public static function jmes_type(mixed $v): string
  {
    $jt = null;

    if($v is null) {
      $jt = 'null';
    } else if($v is bool) {
      $jt = "boolean";
    } elseif ($v is string) {
      $jt = "string";
    } elseif ($v is num || $v is float || $v is int) {
      $jt = "number";
    } elseif( self::is_object($v)) {
      // it is important that we check for object before we check for array
      $jt = "object";
    } elseif (self::is_array($v)) {
      $jt = "array";
    } elseif (Utils::is_expression($v)) {
      $jt = "expression";
    } else {
       throw new \InvalidArgumentException('array|object|string|number|boolean|null');
    }

    return $jt;
  }

  /**
   * Is the value valid
   * 
   * @param mixed $v value
   *
   * @return Return true if the value is a boolean true, or is nonnull
   */
  public static function is_valid(mixed $v): bool {
    if($v is bool) {
      return $v;
    } else {
      return $v is nonnull;
    }
  }
}