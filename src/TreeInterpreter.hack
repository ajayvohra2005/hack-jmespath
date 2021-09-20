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

use namespace HH\Lib\Vec;
use namespace HH\Lib\Str;
use namespace HH\Lib\C;

/*
* This class interpretes the abstract synatx tree for given json data.
*/
class TreeInterpreter
{

    /**
     * Visit the AST nodes and interpret the tree for the given data.
     * 
     * @param ASTNode $node root node of the AST for the parsed JMESPath expression
     * @param mixed $data Json data
     */
    public function visit(ASTNode $node, mixed $data): mixed
    {
        return $this->visitNode($node, $data);
    }

    private function visitNode(ASTNode $node, mixed $data): mixed
    {
          $retval = null;

          switch ($node->get_type()) {

            case 'field':
                if($data is KeyedContainer<_, _>) {
                    $node_v = $node->get_value()[0] as arraykey;
                    $retval = idx($data,$node_v);
                }
                break;

            case 'subexpression':
                $retval =  $this->visitNode($node->get_children()[1],
                    $this->visitNode($node->get_children()[0], $data) );
                break;

            case 'index':
                if($data is KeyedContainer<_, _>) {
                    $idx = $node->get_value()[0] as int;
                    if ($idx < 0 ) {
                        $idx += C\count($data);
                    }
                    $retval = idx($data, $idx);
                }
                break;

            case 'projection':
                $left = $this->visitNode($node->get_children()[0], $data);
                $valid_projection = true;

                switch($node->get_from()) {
                    case 'object':
                        if (!Utils::is_object($left)) {
                            $valid_projection = false;
                        }
                        break;
                    case 'array':
                        if (!Utils::is_array($left)) {
                            $valid_projection = false;
                        }
                        break;
                    default:
                        if (!Utils::is_array($left) || !Utils::is_object($left)) {
                            $valid_projection = false;
                        }
                }
                if($valid_projection && $left is KeyedContainer<_, _>) {
                    $collected = vec[];

                    foreach($left as  $val) {
                        $result = $this->visitNode($node->get_children()[1], $val);
                        if ($result !== null) {
                            $collected[] = $result;
                        }
                    }

                    if($collected) {
                        $retval = $collected;
                    }
                }
                
                break;

            case 'flatten':
                $skipElement = vec[];
                $data = $this->visitNode($node->get_children()[0], $data);

                if (Utils::is_array($data) && $data is KeyedContainer<_,_>) {
                    $merged = vec[];
                    foreach ($data as $values) {
                        // Only flatten a vec, but not dict
                        if ($values is vec<_>) {
                            $merged = Vec\concat($merged, $values);
                        } elseif ($values !== $skipElement) {
                            $merged[] = $values;
                        }
                    }

                    if($merged) {
                        $retval = $merged;
                    }
                }
                
                break;

            case 'literal':
                $retval = $node->get_value()[0];
                break;

            case 'current':
                $retval = $data;
                break;

            case 'or':
                $result = $this->visitNode($node->get_children()[0], $data);
                $retval = $result is nonnull ? $result : $this->visitNode($node->get_children()[1], $data);
                break;

            case 'and':
                $result = $this->visitNode($node->get_children()[0], $data);
                $retval = $result is nonnull  ? $this->visitNode($node->get_children()[1], $data): $result;
                break;

            case 'not':
                $retval = !$this->visitNode($node->get_children()[0], $data);
                break;

            case 'pipe':
                $retval = $this->visitNode($node->get_children()[1],
                    $this->visitNode($node->get_children()[0], $data)
                );
                break;

            case 'multi_select_list':
                if($data is nonnull) {
                    $collected = vec[];
                    if ($data is KeyedContainer<_,_>) {
                        foreach ($node->get_children() as $child) {
                            $collected[] = $this->visitNode($child, $data);
                        }
                    }
                    if($collected) {
                        $retval = $collected;
                    }
                }
                break;

            case 'multi_select_hash':
                if($data is nonnull) {
                    $collected = dict[];
                    if ($data is KeyedContainer<_,_>) {
                        foreach ($node->get_children() as $child) {
                            $child_v = $child->get_value()[0] as arraykey;
                            $collected[$child_v] = $this->visitNode($child->get_children()[0], $data);
                        }
                    }

                    if ($collected) {
                        $retval = $collected;
                    }
                }
                break;

            case 'comparator':
                $left = $this->visitNode($node->get_children()[0], $data);
                $right = $this->visitNode($node->get_children()[1], $data);
                if ($node->get_value()[0] == '==') {
                    $retval = ($left == $right);
                } elseif ($node->get_value()[0] == '!=') {
                    $retval = ($left != $right);
                } else {
                    $retval = self::relativeCmp($left, $right, $node->get_value()[0]);
                }
                break;

            case 'condition':
                $retval = Utils::is_valid($this->visitNode($node->get_children()[0], $data))
                    ? $this->visitNode($node->get_children()[1], $data)
                    : null;
                break;

            case 'function':
                $args = vec[];
                foreach ($node->get_children() as $child) {
                    $args[] = $this->visitNode($child, $data);
                }
                
                $fn = $node->get_value()[0] as string;
                $retval = FnInvoker::invoke($fn, $args);
                break;

            case 'slice':
                $start = $node->get_value()[0] as int;
                $stop = $node->get_value()[1] as int;
                $step = $node->get_value()[2] as int;

                $retval = self::slice($data, $start, $stop, $step);
                break;

            case 'expref':
                $apply = $node->get_children()[0];
                $retval = (mixed $value): mixed ==> $this->visit($apply, $value);
                FnInvoker::addExpression($retval);
                break;

            default:
                throw new \InvalidArgumentException("visitNode: Unknown node type: {$node->get_type()}");
        }

        return $retval;
    }

    private static function relativeCmp(mixed $left, mixed $right, mixed $cmp): bool
    {
        $left = $left as num;
        $right = $right as num;
        $cmp = $cmp as string;

        switch ($cmp) {
            case '>': return $left > $right;
            case '>=': return $left >= $right;
            case '<': return $left < $right;
            case '<=': return $left <= $right;
            default: throw new \InvalidArgumentException("relativeCmp: Invalid comparison operator: $cmp");
        }
    }

    public static function slice(mixed $subject, int $start, int $stop, int $step): mixed
    {
        $retval = null;
 
        if ($subject is string) {
            $retval = self::sliceString($subject, $start, $stop, $step);
        } elseif (Utils::is_array($subject) && $subject is KeyedContainer<_,_>) {
            $retval = self::sliceArray($subject, $start, $stop, $step);
        } else {
            throw new \InvalidArgumentException("slice: subject must be string, or array");
        }
        
        return $retval;
    }

    private static function normalizeSlice(int $length, inout int $start, inout int $stop, int $step): void
    {

        if ($step === 0) {
            throw new \InvalidArgumentException('slice step cannot be 0');
        }

        if($start == 0 && $step < 0) {
            $start = $length - 1;
        } elseif ($start < 0) {
            $start = $length + $start;
            if($start < 0) {
                $start = 0;
            } 
        } 

        if ($stop == 0) {
            if($step > 0) {
                $stop = $length;
            } else {
                $stop = -1;
            }
        } elseif($stop < 0) {
            $stop = $length + $stop;
            if($stop < -1) {
                $stop = -1;
            } 
        } elseif($stop > $length) {
            $stop = $length;
        }
        
    }

    private static function sliceString(string $subject, int $start, int $stop, int $step): string
    {
        $len = Str\length($subject);

        self::normalizeSlice($len, inout $start, inout $stop, $step);
       
        $result = '';
        $chars = Str\chunk($subject);

        if ($step > 0) {
            for ($i = $start; $i < $stop; $i += $step) {
                $result .= $chars[$i];
            }

        } else {
            for ($i = $start; $i > $stop; $i += $step) {
                $result .= $chars[$i];
            }
        }

        return $result;

    }

    private static function sliceArray(KeyedContainer<arraykey, mixed> $subject, int $start, int $stop, int $step): vec<mixed>
    {
        $len = C\count($subject);

        self::normalizeSlice($len, inout $start, inout $stop, $step);
       
        $result = vec[];

        if ($step > 0) {
            for ($i = $start; $i < $stop; $i += $step) {
                $result[] = $subject[$i];
            }

        } else {
            for ($i = $start; $i > $stop; $i += $step) {
                $result[] = $subject[$i];
            }
        }

        return $result;

    }
}
