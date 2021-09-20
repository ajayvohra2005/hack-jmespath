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

use namespace HH\Lib\Str;

use function max;

/*
 * This class represents a syntax error exception 
 * in a JMESPath json query language expression
 */

class SyntaxErrorException extends \InvalidArgumentException
{
    /**
     * Constructor
     *
     * @param expectedTypesOrMessage This is either a keyset of expected tokens, or a string message
     * @param token current token
     * @param expression JMESPath json query language expression
     */
    public function __construct(
        mixed $expectedTypesOrMessage,
        Token $token,
        string $expression
    ) {
        $message = "Syntax error at character {$token['pos']}\n"
            . $expression . "\n" . Str\repeat(' ', max($token['pos'], 0)) . "^\n";
        
        if ( $expectedTypesOrMessage is string) {
            $message .= $expectedTypesOrMessage;
        } else if ($expectedTypesOrMessage is keyset<_>) {
            $message .= $this->createTokenMessage($token,  $expectedTypesOrMessage);
        }
        
        parent::__construct($message);
    }

    private function createTokenMessage(Token $token, Traversable<arraykey> $valid): string
    {
        $expected = Str\join($valid, ",");
        return "Expected one of the following: $expected, found {$token['type']}";
    }
}
