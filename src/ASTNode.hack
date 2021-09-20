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

use function strval;

/*
 * This class represents a node in the abstract syntax tree (AST) obtained by parsing 
 * a JMESPath query expression
 */

class ASTNode
{
    private string $type = Lexer::T_UNKNOWN;
    private vec<mixed> $value;
    private string $from;
    private vec<ASTNode> $children;
   
    /**
     * Constructor
     *
     * @param string $type The type of this node
     * @param vec<mixed> $value a vector to contain value for this node
     * @param string $from the from for this node, typically, an array or an object
     * @param vec<ASTNode> $children a vector of chlidren of this node
     */
    public function __construct(string $type, 
        vec<mixed> $value = vec[], 
        string $from= '',
        vec<ASTNode> $children = vec[])
    {
        $this->type = $type;
        $this->value = $value;
        $this->from = $from;
        $this->children = $children;
    }

    public function get_type(): string 
    {
        return $this->type;
    }

    public function get_children(): vec<ASTNode> 
    {
        return $this->children;
    }

    public function get_value(): vec<mixed>
    {
        return $this->value;
    }

    public function get_from(): string 
    {
        return $this->from;
    }

    public function add_child(ASTNode $child): void 
    {
        $this->children[] = $child;
    }

    public function __toString(string $prefix=''): string
    {
        $json =  "$prefix'node': {\n";
    
        $v = '';
        foreach ($this->get_value() as  $val) {
            $v = $v . strval($val) . ";";
        }
        
        $json .= "$prefix 'type': '{$this->get_type()}',\n".
            "$prefix 'value': '$v',\n".
            "$prefix 'from': '{$this->get_from()}',\n";


        $json .= "$prefix 'children': {\n";
        foreach ($this->children as $key => $value) {
            $json .= $value->__toString($prefix.'  ');
        }
        $json .= "$prefix }\n";
        
        $json .= "$prefix}\n";
        
        return $json;
    }
}