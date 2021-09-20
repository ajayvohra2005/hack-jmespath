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

use function Facebook\FBExpect\expect;
use type Facebook\HackTest\{DataProvider, HackTest};

final class LexerTest extends HackTest
{

    public function dataProvider(): vec< (string, string) >
    {
        return vec[
            tuple('0' , 'number'),
            tuple('1' , 'number'),
            tuple('2' , 'number'),
            tuple('3' , 'number'),
            tuple('4' , 'number'),
            tuple('5' , 'number'),
            tuple('6' , 'number'),
            tuple('7' , 'number'),
            tuple('8' , 'number'),
            tuple('9' , 'number'),
            tuple('-1' , 'number'),
            tuple('-1.5' , 'number'),
            tuple('109.5' , 'number'),
            tuple('.' , 'dot'),
            tuple('{' , 'lbrace'),
            tuple('}' , 'rbrace'),
            tuple('[' , 'lbracket'),
            tuple(']' , 'rbracket'),
            tuple(':' , 'colon'),
            tuple(',' , 'comma'),
            tuple('||' , 'or'),
            tuple('*' , 'star'),
            tuple('foo' , 'identifier'),
            tuple('"foo"' , 'quoted_identifier'),
            tuple('`true`' , 'literal'),
            tuple('`false`' , 'literal'),
            tuple('`null`' , 'literal'),
            tuple('`"true"`' , 'literal')
        ];
    }

    <<DataProvider('dataProvider')>>
    public function testTokenizesInput(string $input, string $type): void
    {
        $l = new HackJmesPath\Lexer();
        $tokens = $l->tokenize($input);
        expect($tokens[0]['type'])->toBeSame($type);
    }

    public function testTokenizesJsonLiterals(): void
    {
        $l = new HackJmesPath\Lexer();
        $tokens = $l->tokenize('`null`, `false`, `true`, `"abc"`, `"ab\\"c"`,'
            . '`0`, `0.45`, `-0.5`');
        expect($tokens[0]['value'])->toBeNull();
        expect($tokens[2]['value'])->toBeFalse();
        expect($tokens[4]['value'])->toBeTrue();
        expect('abc')->toBeSame($tokens[6]['value']);
        expect('ab"c')->toBeSame($tokens[8]['value']);
        expect(0)->toBeSame($tokens[10]['value']);
        expect(0.45)->toBeSame($tokens[12]['value']);
        expect(-0.5)->toBeSame($tokens[14]['value']);
    }


    public function testTokenizesJsonNumbers(): void
    {
        $l = new HackJmesPath\Lexer();
        $tokens = $l->tokenize('`10`, `1.2`, `-10.20e-10`, `1.2E+2`');
        expect(10)->toBeSame($tokens[0]['value']);
        expect(1.2)->toBeSame($tokens[2]['value']);
        expect(-1.02E-9)->toBeSame($tokens[4]['value']);
        expect(120.0)->toBeSame($tokens[6]['value']);
    }

    public function testCanWorkWithElidedJsonLiterals(): void
    {
        $l = new HackJmesPath\Lexer();
        $tokens = $l->tokenize('`foo`');
        expect('literal')->toBeSame($tokens[0]['type']);
        expect('foo')->toBeSame($tokens[0]['value']);
    }
}