/*
 *  Copyright (c) 2021 Ajay Vohra, https://github.com/ajayvohra2005/hack-jmespath.git 
 *  Copyright (c) 2014 Michael Dowling, https://github.com/mtdowling
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
use namespace HH\Lib\Str;
use namespace HH\Lib\Vec;
use namespace HH\Lib\C;
use namespace HH\Lib\Math;

use function json_encode;
use function floatval;
use function strval;

/**
 * Class for  JMESPath functions
 */
class FnInvoker
{
    /* container for storing safe expressions */
    private static vec<(function (mixed): mixed)> $safeExpressions = vec[];

    /**
     * Add a safe expression
     *
     * @param (function (mixed): mixed) $expr safe expression
     */
    public static function addExpression( (function (mixed): mixed) $expr): void
    {
        if($expr is nonnull) {
            self::$safeExpressions[] = $expr;
        }
    }

    /**
     * Clear all safe expressions
     *
     */
    public static function clearExpressions(): void
    {
        self::$safeExpressions = vec[];
    }

    /**
     * Remove the matching safe expression from stored safe expressions.
     * This creates a new container for safe expressions that does not contain
     * the removed expression.
     *
     * @param (function (mixed): mixed) $expr safe expression
     */
    public static function removeExpression( (function (mixed): mixed) $expr): void
    {
        if($expr is nonnull) {
            $pred = (mixed $e):bool  ==> ($e !== $expr);
            self::$safeExpressions = Vec\filter(self::$safeExpressions, $pred);
        }
    }

    private static function findSafeExpression(mixed $expr): ?(function (mixed): mixed) {
        $pred = (mixed $e):bool  ==> ($e === $expr);
        return C\find(self::$safeExpressions, $pred);
    }

    /**
     * Invoke a JMESPath function. This function uses a switch-case statement
     * to map the function to a class method. This is the recommended method
     * in Hack language.
     * 
     * @param string $fn JMESPath function name
     * @param vec<mixed> $args function arguments
     *
     * @return mixed result of invking the function
     */
    public static function invoke(string $fn, vec<mixed> $args): mixed
    {
        $retval = null;

        switch($fn) {
            case "abs":
                $retval = self::fn_abs($args);
                break;
            case "avg":
                $retval = self::fn_avg($args);
                break;
            case "contains":
                $retval = self::fn_contains($args);
                break;
            case "ceil":
                $retval = self::fn_ceil($args);
                break;
            case "ends_with":
                $retval = self::fn_ends_with($args);
                break;
            case "floor":
                $retval = self::fn_floor($args);
                break;
            case "join":
                $retval = self::fn_join($args);
                break;
            case "keys":
                $retval = self::fn_keys($args);
                break;
            case "length":
                $retval = self::fn_length($args);
                break;
            case "map":
                $retval = self::fn_map($args);
                break;
            case "max":
                $retval = self::fn_max($args);
                break;
    
            case "max_by":
                $retval = self::fn_max_by($args);
                break;
            
            case "merge":
                $retval = self::fn_merge($args);
                break;
            case "min":
                $retval = self::fn_min($args);
                break;

            case "min_by":
                $retval = self::fn_min_by($args);
                break;
            
            case "not_null":
                $retval = self::fn_not_null($args);
                break;
            case "reverse":
                $retval = self::fn_reverse($args);
                break;
            case "sort":
                $retval = self::fn_sort($args);
                break;
            case "sort_by":
                $retval = self::fn_sort_by($args);
                break;
            case "starts_with":
                $retval = self::fn_starts_with($args);
                break;
            case "sum":
                $retval = self::fn_sum($args);
                break;
            case "to_array":
                $retval = self::fn_to_array($args);
                break;
            case "to_number":
                $retval = self::fn_to_number($args);
                break;
            case "to_string":
                $retval = self::fn_to_string($args);
                break;
            case "type":
                $retval = self::fn_type($args);
                break;
            case "values":
                $retval = self::fn_values($args);
                break;
            default:
                 throw new \BadFunctionCallException("Call to undefined function $fn");
        }

        return $retval;
    }

    private static function fn_abs(vec<mixed>  $args): num
    {
        self::validate('abs', $args, vec[ vec['number']]);
        $v = $args[0];
        if ($v is num) {
            return Math\abs($v);
        } else {
            throw new \InvalidArgumentException("abs(number)");
        }
    }

    private static function fn_avg(vec<mixed> $args): ?float
    {
        $retval = null;
        self::validate('avg', $args, vec[ vec['array']]);
        
        $v = $args[0];
        self::validateArrayType("avg", $v, vec["number"]);

        if( $v is Container<_>) {
            $v = Utils::filterContainer<num>($v);
            $retval = Math\mean($v);
        } else {
            throw new \InvalidArgumentException("avg(array[number])");
        }
        
        return $retval;
    }

    private static function fn_contains(vec<mixed> $args): bool
    {
        self::validate('contains', $args, vec [ vec['string', 'array'], vec['any']]);

        $v1 = $args[0];
        $v2 = $args[1];

        $retval = false;

        if ($v1 is Traversable<_>) {
            $retval = C\contains($v1, $v2);
        } elseif ($v1 is string && $v2 is string) {
            $retval =  Str\contains($v1, $v2, 0);
        } else {
            throw new \InvalidArgumentException("contains(array|string, any)");
        }

        return $retval;

    }

    private static function fn_ceil(vec<mixed> $args): int
    {
        self::validate('ceil', $args, vec[ vec['number']]);

        $v = $args[0];
        if($v is num) {
            return (int)Math\ceil($v);
        } else {
            throw new \InvalidArgumentException("ceil(number)");
        }
    }

    private static function fn_ends_with(vec<mixed> $args): bool
    {
        self::validate('ends_with', $args, vec[ vec['string'], vec['string']]);

        $search = $args[0];
        $suffix = $args[1];

        if($search is string && $suffix is string) {
            return Str\ends_with($search, $suffix);
        } else {
            throw new \InvalidArgumentException("ends_with(string, string)");
        }
    }

    private static function fn_floor(vec<mixed> $args): int
    {
        self::validate('floor', $args, vec[ vec['number']]);

        $v = $args[0];
        if($v is num) {
            return (int)Math\floor($v);
        } else {
            throw new \InvalidArgumentException("floor(number)");
        }
    }

    private static function fn_join(vec<mixed> $args): ?string
    {
        self::validate('join', $args, vec[ vec['string'], vec['array']]);
        self::validateArrayType('join', $args[1], vec['string']);

        $glue = $args[0];
        $values = $args[1];

        $retval = null;

        if($values is Traversable<_> && $glue is string) {
            $v = Utils::filterTraversable<string>($values);
            $retval = Str\join($v, $glue);
        } else {
            throw new \InvalidArgumentException("join(string, array[string])");
        }

        return $retval;
    }

    private static function fn_keys(vec<mixed> $args): vec<mixed>
    {
        self::validate('keys', $args, vec[ vec['object']]);
        
        $retval = vec<mixed>[];
        $v = $args[0];

        if($v is KeyedContainer<_,_>) {
            $retval = Vec\keys($v);
        } else {
            throw new \InvalidArgumentException("keys(object)");
        }
        return $retval;
    }

     private static function fn_length(vec<mixed> $args): int
    {
        self::validate('length', $args, vec[ vec['string', 'array', 'object']]);

        $v = $args[0];
        $len = 0;

        if( $v is string) {
            $len=Str\length($v);
        } elseif ($v is Container<_>) {
            $len=C\count($v);
        }  else {
            throw new \InvalidArgumentException("length(string|array|object)");
        }

        return $len;
    }

     private static function fn_map(vec<mixed> $args): ?vec<mixed>
    {
        self::validate('map', $args, vec[ vec['expression'], vec['array'] ]);
        $retval = null;

        $expr = $args[0];
        $values = $args[1];

        if($values is Traversable<_> && Utils::is_expression($expr)) {
            $safe_expr = self::findSafeExpression($expr);
            if($safe_expr) {
                $retval = Vec\map($values, $safe_expr);
            }
        } else {
            throw new \InvalidArgumentException("map(expression->any->any, array[any])");
        }
        return $retval;
    }


    private static function fn_max(vec<mixed> $args): mixed
    {
        self::validate('max', $args, vec[ vec['array']]);

        $values = $args[0];
        self::validateArrayType('max', $values, vec['number', 'string']);

        $retval = null;
        
        $max_fn = ($a, $b) ==> ($a && ($a >= $b) ? $a: $b);

        if( $values is Traversable<_>) {
            $retval = C\reduce($values, $max_fn, null);
        } else {
            throw new \InvalidArgumentException("max(array[number]|array[string])");
        }
        
        return $retval;
    }

    private static function fn_max_by(vec<mixed> $args): mixed
    {
        self::validate('max_by', $args, vec[ vec['array'], vec['expression']]);
        $values = $args[0];

        $expr = $args[1];

        $retval = null;
        
        if( $values is Traversable<_> &&  Utils::is_expression($expr)) {
            $safe_expr = self::findSafeExpression($expr);
            if($safe_expr) {
                $max_by_fn = ($a, $b) ==> { 
                    $retval = null;
                    $ea = $a is nonnull ? $safe_expr($a): $a;
                    $eb = $b is nonnull ? $safe_expr($b): $b;
                    if ($a is null) {
                        $retval = $b;
                    } elseif ( $ea is num && $eb is num) {
                        $retval = $ea is nonnull && $ea >= $eb ? $a : $b;
                    } elseif (  $ea is string && $eb is string) {
                        $retval = $ea is nonnull && $ea >= $eb ? $a : $b;
                    } else {
                        throw new \InvalidArgumentException("max_by(array, expression->number|expression->string)");
                    }
                    return $retval;
                };
                $retval = C\reduce($values, $max_by_fn, null);
            }
        } else {
            new \InvalidArgumentException("max_by(array, expression->number|expression->string)");
        }
        
        return $retval;
    }
    

    private static function fn_merge(vec<mixed> $args): dict<arraykey, mixed>
    {
        if (!$args) {
            throw new \InvalidArgumentException("merge([object, [, object ...]])");
        }
        self::validate('merge', $args, vec[ vec['array']]);
    
        $values = $args[0];
        self::validateArrayType('merge', $values, vec['object']);
        $merged = dict<arraykey, mixed>[];

        if($values is Traversable<_> ) {
            foreach ($values as $obj) {
                if($obj is dict<_,_>) {
                    foreach ($obj as $key => $val) {
                        $merged[$key] = $val;
                    }
                } else {
                    new \InvalidArgumentException("merge([object, [, object ...]])");
                }
            }
        } else {
            new \InvalidArgumentException("merge([object, [, object ...]])");
        }

        return $merged;
    }

    private static function fn_min(vec<mixed> $args): mixed
    {
        self::validate('min', $args, vec[ vec['array']]);

        $values = $args[0];
        self::validateArrayType('min', $values, vec['number', 'string']);

        $retval = null;
        
        $min_fn = ($a, $b) ==> ($a && ($a <= $b) ? $a: $b);

        if( $values is Traversable<_>) {
            $retval = C\reduce($values, $min_fn, null);
        } else {
            throw new \InvalidArgumentException("min(array[number]|array[string])");
        }
        
        return $retval;
    }


    private static function fn_min_by(vec<mixed> $args): mixed
    {
        self::validate('min_by', $args, vec[ vec['array'], vec['expression']]);
        $values = $args[0];
        
        $expr = $args[1];

        $retval = null;

        if( $values is Traversable<_> && Utils::is_expression($expr )) {
            $safe_expr = self::findSafeExpression($expr);
            if($safe_expr) {
                $min_by_fn = ($a, $b) ==> { 
                    $retval = null;
                    $ea = $a is nonnull ? $safe_expr($a): $a;
                    $eb = $b is nonnull ? $safe_expr($b): $b;
                    if ($a is null) {
                        $retval = $b;
                    } elseif ( $ea is num && $eb is num) {
                        $retval = $ea is nonnull && $ea <= $eb ? $a : $b;
                    } elseif (  $ea is string && $eb is string) {
                        $retval = $ea is nonnull && $ea <= $eb ? $a : $b;
                    } else {
                        throw new \InvalidArgumentException("min_by(array, expression->number|expression->string)");
                    }
                    return $retval;
                };
                $retval = C\reduce($values, $min_by_fn, null);
            }

        } else {
            throw new \InvalidArgumentException("min_by(array, expression->number|expression->string)");
        }
        
        return $retval;
    }
    
     private static function fn_not_null(vec<mixed> $args): mixed
    {
        if (!$args) {
            throw new \InvalidArgumentException("not_null([any  [, any ...]])");
        }

        $retval = null;

        foreach ($args as  $value) {
            if($value is nonnull) {
                $retval = $value;
                break;
            }
        }
        
        return $retval;
    }

    private static function fn_reverse(vec<mixed> $args): mixed
    {
        self::validate('reverse', $args, vec[ vec['array', 'string']]);

        $v = $args[0];

        if ($v is Traversable<_>) {
            return Vec\reverse($v);
        } elseif ($v is string) {
            return Str\reverse($v);
        } else {
            throw new \InvalidArgumentException('reverse(string|array)');
        }
    }

    private static function fn_sort(vec<mixed> $args): vec<mixed>
    {
        self::validate('sort', $args, vec[ vec['array']]);
        
        $values = $args[0];
        self::validateArrayType('sort', $values, vec['number', 'string']);

        $retval = null;
        
        if( $values is Traversable<_>) {
            $retval = Vec\sort($values);
        } else {
            throw new \InvalidArgumentException("sort(array[number]|array[string])");
        }

        return $retval;
    }

    
    private static function fn_sort_by(vec<mixed> $args): vec<mixed>
    { 
        self::validate('sort_by', $args, vec[ vec['array'], vec['expression']]);

        $retval = vec<mixed>[];
        $values = $args[0];

    
        $expr = $args[1];
        if($values is Traversable<_> && Utils::is_expression($expr)) {
            $safe_expr = self::findSafeExpression($expr);
            if($safe_expr) {
                $retval = Vec\sort_by($values, $safe_expr);
            }
        } else {
            throw new \InvalidArgumentException("sort_by(array, expression->number|expression->string)");
        }
        return $retval;
    }
    
    private static function fn_starts_with(vec<mixed> $args): bool
    {
        self::validate('starts_with', $args, vec[ vec['string'], vec['string']]);

        $search = $args[0];
        $prefix = $args[1];

        if($search is string && $prefix is string) {
            return Str\starts_with($search, $prefix);
        } else {
            throw new \InvalidArgumentException("starts_with(string, string)");
        }
    }

    private static function fn_sum(vec<mixed> $args): float
    {
        self::validate('sum', $args, vec[ vec['array']]);

        $retval = 0.0;

        $values = $args[0];
        self::validateArrayType('sum', $values, vec['number']);

        if( $values is Traversable<_>) {
            $values = Utils::filterTraversable<num>($values);
            $retval = Math\sum_float($values);
        } else {
            throw new \InvalidArgumentException("sum(array[number])");
        }
        
        return $retval;
    }

    private static function fn_to_array(vec<mixed> $args): vec<mixed>
    {
        self::validate('to_array', $args, vec[ vec['any']]);
        $v = $args[0];

        if($v is vec<_>) {
            return $v;
        } else {
            return vec[$v];
        }
    }

    private static function fn_to_string(vec<mixed> $args): string
    {
        self::validateArity('to_string', C\count($args), 1);

        $v = $args[0];
        if ($v is string) {
            return $v;
        } elseif (!($v is \JsonSerializable) ) {
            return strval($v);
        }

        return json_encode($v);
    }

    private static function fn_to_number(vec<mixed> $args): float
    {
        self::validateArity('to_number', C\count($args), 1);
        return floatval($args[0]);
    }

    private static function fn_type(vec<mixed> $args): string
    {
        self::validateArity('type', C\count($args), 1);
        return Utils::jmes_type(($args[0]));
    }

    private static function fn_values(vec<mixed> $args): vec<mixed>
    {
        self::validate('values', $args, vec[ vec['object']]);
        $values  = vec[];

        $v = $args[0];

        if($v is dict<_,_>) {
            foreach ($v as $value) {
                $values[] = $value;
            }
        } else {
            throw new \InvalidArgumentException("values(object)");
        }

        return $values;
    }

    private static function typeError(string $from, string $msg): void
    {
        if (Str\search($from, ':', 0)) {
            $v = Str\split($from, ':');
            $fn = $v[0];
            $pos = ((int)$v[1]) as int;
            throw new \InvalidArgumentException(Str\format('Argument %d of %s %s', $pos, $fn, $msg));
        } else {
            throw new \InvalidArgumentException(Str\format('Type error: %s %s', $from, $msg));
        }
    }

    private static function validate(string $from, vec<mixed> $args, vec<vec<string>> $types=vec[]): void
    {
        self::validateArity($from, C\count($args), C\count($types));
        foreach ($args as $index => $value) {
            $types_i = HH\idx($types, $index);
            if ($types_i) {
                self::validateType("{$from}:{$index}", $value, $types_i);
            }
        }
    }

    private static function validateArity(string $from, int $given, int $expected): void
    {
        if ($given != $expected) {
            throw new \InvalidArgumentException(Str\format("%s() expects %d arguments, %d were provided", $from, $expected, $given));
        }
    }

    private static function validateType(string $from, mixed $value, vec<string> $types): void
    {
        if ($types[0] == 'any') {
            return;
        }

        $value_type = null;
        try {
            $value_type = Utils::jmes_type($value);
        } catch(\InvalidArgumentException $ex) {
            
        }
        if  ( $value_type is null || !C\contains($types, $value_type) ) {
            $msg = 'must be one of the following types: ' . Str\join($types, ', ');
            if($value_type is string) {
                $msg .= '. ' . $value_type . ' found.';
            }
    
            self::typeError($from, $msg);
        }
        
    }

    private static function validateArrayType(string $from, mixed $values, vec<string> $types): void
    {
        $prev_type = null;
        $i = 0;

        if($values is Traversable<_>) {
            foreach ($values as $value) {
                $value_type = Utils::jmes_type($value);
                $typeMatch = C\contains($types, $value_type) && ($i == 0 || $value_type === $prev_type);

                if (!$typeMatch) {
                    $msg = 'encountered a type error in array. The argument must be '
                        . 'an array of ' . Str\join( $types, '|') . ' types. '
                    . "Found type: {$value_type} at position: {$i}";
                    self::typeError($from, $msg);
                } 
                $i++;
                $prev_type = $value_type;
            }
        } else {
            $msg = 'not an array. The argument must be '. 'an array of ' . Str\join( $types, '|') . ' types. ';
            self::typeError($from, $msg);
        }
    }



}
