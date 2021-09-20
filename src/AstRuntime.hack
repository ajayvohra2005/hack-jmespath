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
use namespace HH\Lib\C;

/*
 * Class for abstract synatx tree runtime
 */
class AstRuntime
{
    /* maximum cached entries in the internal JMESPath-expression -> ASTNode  map */
    const MAX_CACHE_ENTRIES = 1024;

    private static ?AstRuntime $runtime;

    private Parser $parser;
    private TreeInterpreter $interpreter;

    /* internal cache to store frequently used JMESPath expressions */
    private dict<string, ASTNode> $cache = dict[];

    /**
     * If needed, create a singleton instance of ASTRuntime.
     *
     * @return AstRuntime return the singleton instance of this class
     */
    public static function get_runtime(): AstRuntime
    {
        if(self::$runtime is null) {
            self::$runtime = new AstRuntime(new Parser());
        }

        return self::$runtime;
    }

    /**
     * Constructor
     * 
     * @param ?Parser $p optional parser 
     */
    public function __construct(?Parser $p) {
        $this->interpreter = new TreeInterpreter();
        $this->parser = $p is nonnull ? $p : new Parser();
    }

    /**
     * Search and return the matching elements from the given data 
     * using the JMESPath json query language expression.
     *
     * @param string $expression JMESPath json query language expression
     * @param mixed  $data       JSON Data to search. This data should be similar 
     *                           to data returned from json_decode($json, true)
     *                           using associative arrays, rather than objects.
     *
     * @return mixed Return the matching elements, or null
     */
    public function search(string $expression, mixed $data): mixed
    {
        $cached = HH\idx($this->cache, $expression);

        if ($cached is null) {
        
            if (C\count($this->cache) >= self::MAX_CACHE_ENTRIES) {
                $this->cache = dict[];
            }
            $this->cache[$expression] = $this->parser->parse($expression);
        }

        return $this->interpreter->visit($this->cache[$expression], $data);
    }
}
