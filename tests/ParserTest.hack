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
 
use namespace HackJmesPath;

use type HackJmesPath\{Parser, Lexer, SyntaxErrorException};

use function Facebook\FBExpect\expect;
use type Facebook\HackTest\{DataProvider, HackTest};

final class ParserTest extends HackTest
{
     /**
     * @expectedException SyntaxErrorException
     * @expectedExceptionMessage Syntax error at character 0
     */
    public function testMatchesFirstTokens():void 
    {
        $p = new Parser(new Lexer());
        expect(() ==> $p->parse('.bar'))
          ->toThrow(SyntaxErrorException::class, 'Syntax error at character 0');
    }

    /**
     * @expectedException SyntaxErrorException
     * @expectedExceptionMessage Syntax error at character 1
     */
    public function testThrowsSyntaxErrorForInvalidSequence(): void
    {
        $p = new Parser(new Lexer());
        expect(() ==> $p->parse('a,'))
          ->toThrow(SyntaxErrorException::class, 'Syntax error at character 1');
    }

    /**
     * @expectedException SyntaxErrorException
     * @expectedExceptionMessage Syntax error at character 2
     */
    public function testMatchesAfterFirstToken(): void
    {
        $p = new Parser(new Lexer());
        expect(() ==> $p->parse('a.,'))
          ->toThrow(SyntaxErrorException::class, 'Syntax error at character 2');
    }

     /**
     * @expectedException SyntaxErrorException
     * @expectedExceptionMessage Unexpected "eof" token
     */
    public function testHandlesEmptyExpressions(): void
    {
        $p = new Parser(new Lexer());
        expect(() ==> $p->parse(''))
          ->toThrow(SyntaxErrorException::class, 'Unexpected "eof" token');
    }

    <<DataProvider('invalidExpressionProvider')>>
    public function testHandlesInvalidExpressions(string $expr): void
    {
        $p = new HackJmesPath\Parser(new HackJmesPath\Lexer());
        expect(() ==> $p->parse($expr))
          ->toThrow(SyntaxErrorException::class, 'Syntax error at character -1');
    }

    public function invalidExpressionProvider(): vec<(string)>
    {
        return vec[
            tuple('='),
            tuple('<'),
            tuple('>'),
            tuple('|')
        ];
    }


}