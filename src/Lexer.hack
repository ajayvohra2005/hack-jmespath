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
use namespace HH\Lib\C;

use function fb_utf8_strlen;
use function json_decode_with_error;

/* A type to represent a scanned lexical token */
type Token = shape('type' => string, 'value' => mixed, 'pos' => int);

/*
 * This class scans the input JMESPath query expression and tokenizes the input expression
 */

class Lexer
{
    /* Token constants */
    const string T_DOT = 'dot';
    const string T_STAR = 'star';
    const string T_COMMA = 'comma';
    const string T_COLON = 'colon';
    const string T_CURRENT = 'current';
    const string T_EXPREF = 'expref';
    const string T_LPAREN = 'lparen';
    const string T_RPAREN = 'rparen';
    const string T_LBRACE = 'lbrace';
    const string T_RBRACE = 'rbrace';
    const string T_LBRACKET = 'lbracket';
    const string T_RBRACKET = 'rbracket';
    const string T_FLATTEN = 'flatten';
    const string T_IDENTIFIER = 'identifier';
    const string T_NUMBER = 'number';
    const string T_QUOTED_IDENTIFIER = 'quoted_identifier';
    const string T_UNKNOWN = 'unknown';
    const string T_PIPE = 'pipe';
    const string T_OR = 'or';
    const string T_AND = 'and';
    const string T_NOT = 'not';
    const string T_FILTER = 'filter';
    const string T_LITERAL = 'literal';
    const string T_EOF = 'eof';
    const string T_COMPARATOR = 'comparator';

    /* DFA state constants */
    const int STATE_IDENTIFIER = 0;
    const int STATE_NUMBER = 1;
    const int STATE_SINGLE_CHAR = 2;
    const int STATE_WHITESPACE = 3;
    const int STATE_STRING_LITERAL = 4;
    const int STATE_QUOTED_STRING = 5;
    const int STATE_JSON_LITERAL = 6;
    const int STATE_LBRACKET = 7;
    const int STATE_PIPE = 8;
    const int STATE_LT = 9;
    const int STATE_GT = 10;
    const int STATE_EQ = 11;
    const int STATE_NOT = 12;
    const int STATE_AND = 13;

    /* DFA state transition table */
    private static dict<string, int> $dfaTable = dict[
        '<'  => self::STATE_LT,
        '>'  => self::STATE_GT,
        '='  => self::STATE_EQ,
        '!'  => self::STATE_NOT,
        '['  => self::STATE_LBRACKET,
        '|'  => self::STATE_PIPE,
        '&'  => self::STATE_AND,
        '`'  => self::STATE_JSON_LITERAL,
        '"'  => self::STATE_QUOTED_STRING,
        "'"  => self::STATE_STRING_LITERAL,
        '-'  => self::STATE_NUMBER,
        '0'  => self::STATE_NUMBER,
        '1'  => self::STATE_NUMBER,
        '2'  => self::STATE_NUMBER,
        '3'  => self::STATE_NUMBER,
        '4'  => self::STATE_NUMBER,
        '5'  => self::STATE_NUMBER,
        '6'  => self::STATE_NUMBER,
        '7'  => self::STATE_NUMBER,
        '8'  => self::STATE_NUMBER,
        '9'  => self::STATE_NUMBER,
        ' '  => self::STATE_WHITESPACE,
        "\t" => self::STATE_WHITESPACE,
        "\n" => self::STATE_WHITESPACE,
        "\r" => self::STATE_WHITESPACE,
        '.'  => self::STATE_SINGLE_CHAR,
        '*'  => self::STATE_SINGLE_CHAR,
        ']'  => self::STATE_SINGLE_CHAR,
        ','  => self::STATE_SINGLE_CHAR,
        ':'  => self::STATE_SINGLE_CHAR,
        '@'  => self::STATE_SINGLE_CHAR,
        '('  => self::STATE_SINGLE_CHAR,
        ')'  => self::STATE_SINGLE_CHAR,
        '{'  => self::STATE_SINGLE_CHAR,
        '}'  => self::STATE_SINGLE_CHAR,
        '_'  => self::STATE_IDENTIFIER,
        'A'  => self::STATE_IDENTIFIER,
        'B'  => self::STATE_IDENTIFIER,
        'C'  => self::STATE_IDENTIFIER,
        'D'  => self::STATE_IDENTIFIER,
        'E'  => self::STATE_IDENTIFIER,
        'F'  => self::STATE_IDENTIFIER,
        'G'  => self::STATE_IDENTIFIER,
        'H'  => self::STATE_IDENTIFIER,
        'I'  => self::STATE_IDENTIFIER,
        'J'  => self::STATE_IDENTIFIER,
        'K'  => self::STATE_IDENTIFIER,
        'L'  => self::STATE_IDENTIFIER,
        'M'  => self::STATE_IDENTIFIER,
        'N'  => self::STATE_IDENTIFIER,
        'O'  => self::STATE_IDENTIFIER,
        'P'  => self::STATE_IDENTIFIER,
        'Q'  => self::STATE_IDENTIFIER,
        'R'  => self::STATE_IDENTIFIER,
        'S'  => self::STATE_IDENTIFIER,
        'T'  => self::STATE_IDENTIFIER,
        'U'  => self::STATE_IDENTIFIER,
        'V'  => self::STATE_IDENTIFIER,
        'W'  => self::STATE_IDENTIFIER,
        'X'  => self::STATE_IDENTIFIER,
        'Y'  => self::STATE_IDENTIFIER,
        'Z'  => self::STATE_IDENTIFIER,
        'a'  => self::STATE_IDENTIFIER,
        'b'  => self::STATE_IDENTIFIER,
        'c'  => self::STATE_IDENTIFIER,
        'd'  => self::STATE_IDENTIFIER,
        'e'  => self::STATE_IDENTIFIER,
        'f'  => self::STATE_IDENTIFIER,
        'g'  => self::STATE_IDENTIFIER,
        'h'  => self::STATE_IDENTIFIER,
        'i'  => self::STATE_IDENTIFIER,
        'j'  => self::STATE_IDENTIFIER,
        'k'  => self::STATE_IDENTIFIER,
        'l'  => self::STATE_IDENTIFIER,
        'm'  => self::STATE_IDENTIFIER,
        'n'  => self::STATE_IDENTIFIER,
        'o'  => self::STATE_IDENTIFIER,
        'p'  => self::STATE_IDENTIFIER,
        'q'  => self::STATE_IDENTIFIER,
        'r'  => self::STATE_IDENTIFIER,
        's'  => self::STATE_IDENTIFIER,
        't'  => self::STATE_IDENTIFIER,
        'u'  => self::STATE_IDENTIFIER,
        'v'  => self::STATE_IDENTIFIER,
        'w'  => self::STATE_IDENTIFIER,
        'x'  => self::STATE_IDENTIFIER,
        'y'  => self::STATE_IDENTIFIER,
        'z'  => self::STATE_IDENTIFIER,
    ];

    /* valid characters in an identifier */
    private keyset<string> $validIdentifier = keyset[
        'A', 'B', 'C', 'D', 'E',
        'F', 'G', 'H', 'I', 'J',
        'K', 'L', 'M', 'N', 'O',
        'P', 'Q', 'R', 'S', 'T',
        'U', 'V', 'W', 'X', 'Y',
        'Z', 'a', 'b', 'c', 'd',
        'e', 'f', 'g', 'h', 'i',
        'j', 'k', 'l', 'm', 'n',
        'o', 'p', 'q', 'r', 's',
        't', 'u', 'v', 'w', 'x',
        'y', 'z', '_', '0', '1',
        '2', '3', '4', '5', '6',
        '7', '8', '9',
    ];

    /* valid chracters in a number */
    private keyset<string> $numbers = keyset[
        '0', '1', '2', '3', '4',
        '5', '6', '7', '8', '9'
    ];

    private dict<string, string> $simpleTokens = dict[
        '.' => self::T_DOT,
        '*' => self::T_STAR,
        ']' => self::T_RBRACKET,
        ',' => self::T_COMMA,
        ':' => self::T_COLON,
        '@' => self::T_CURRENT,
        '(' => self::T_LPAREN,
        ')' => self::T_RPAREN,
        '{' => self::T_LBRACE,
        '}' => self::T_RBRACE,
    ];

    /**
     * Tokenizes the input JMESpath query expression, and returns a vector of tokens
     *
     * @param string $input JMESPath query expression to tokenize
     *
     * @return vec<Token> a vector of tokens
     */
    public function tokenize(string $input): vec<Token>
    {
        $tokens = vec<Token>[];

        if ($input === '') {
            $tokens[] = shape(
                'type'  => self::T_EOF,
                'pos'   => (int)fb_utf8_strlen($input),
                'value' => ''
            );
            return $tokens;
        }

        $chars = Str\chunk($input);
        $it = new \ArrayIterator($chars);

        while ($it->valid()) {

            if (!C\contains_key(self::$dfaTable, $it->current())) {
                $tokens[] = shape(
                    'type'  => self::T_UNKNOWN,
                    'pos'   => (int) $it->key(),
                    'value' => $it->current()
                );
                $it->next();
                continue;
            }

            $state = self::$dfaTable[$it->current()];

            if ($state === self::STATE_SINGLE_CHAR) {

                $tokens[] = shape(
                    'type'  => $this->simpleTokens[$it->current()],
                    'pos'   => (int)$it->key(),
                    'value' => $it->current()
                );
                $it->next();

            } elseif ($state === self::STATE_IDENTIFIER) {

                $start = (int)$it->key();
                $buffer = '';
                do {
                    $buffer .= $it->current();
                    $it->next();
                } while ($it->valid() && C\contains($this->validIdentifier, $it->current()));
                $tokens[] = shape(
                    'type'  => self::T_IDENTIFIER,
                    'value' => $buffer,
                    'pos'   => $start
                );

            } elseif ($state === self::STATE_WHITESPACE) {
                $it->next();
            } elseif ($state === self::STATE_LBRACKET) {

                $position = (int)$it->key();
                $it->next();
                if ($it->current() === ']') {
                    $it->next();
                    $tokens[] = shape(
                        'type'  => self::T_FLATTEN,
                        'pos'   => $position,
                        'value' => '[]'
                    );
                } elseif ($it->current() === '?') {
                    $it->next();
                    $tokens[] = shape(
                        'type'  => self::T_FILTER,
                        'pos'   => $position,
                        'value' => '[?'
                    );
                } else {
                    $tokens[] = shape(
                        'type'  => self::T_LBRACKET,
                        'pos'   => $position,
                        'value' => '['
                    );
                }

            } elseif ($state === self::STATE_STRING_LITERAL) {

                $t = $this->inside($it, "'", self::T_LITERAL);
                $val = $t['value'];
                if($val  is string) {
                    $t['value'] = Str\replace($val, "\\'", "'" );
                }
                $tokens[] = $t;

            } elseif ($state === self::STATE_PIPE) {
                $tokens[] = $this->matchOr($it, '|', '|', self::T_OR, self::T_PIPE);
            } elseif ($state == self::STATE_JSON_LITERAL) {

                $token = $this->inside($it, '`', self::T_LITERAL);
                if ($token['type'] === self::T_LITERAL) {
                    $val = $token['value'];
                    if($val  is string) {
                        $token['value'] = Str\replace($val, '\\`', '`');
                    }
                    $token = $this->parseJson($token);
                }
                $tokens[] = $token;

            } elseif ($state == self::STATE_NUMBER) {

                $start = (int)$it->key();
                $buffer = '';
                do {
                    $buffer .= $it->current();
                    $it->next();
                } while ($it->valid() && C\contains($this->numbers, $it->current()));
                $tokens[] = shape(
                    'type'  => self::T_NUMBER,
                    'value' => $buffer,
                    'pos'   => $start
                );

            } elseif ($state === self::STATE_QUOTED_STRING) {

                $token = $this->inside($it, '"', self::T_QUOTED_IDENTIFIER);
                if ($token['type'] === self::T_QUOTED_IDENTIFIER) {
                    $val = $token['value'];
                    if($val  is string) {
                        $token['value'] = '"' . $val  . '"';
                    }
                    $token = $this->parseJson($token);
                }
                $tokens[] = $token;

            } elseif ($state === self::STATE_EQ) {

                $tokens[] = $this->matchOr($it, '=', '=', self::T_COMPARATOR, self::T_UNKNOWN);

            } elseif ($state == self::STATE_AND) {

                $tokens[] = $this->matchOr($it, '&', '&', self::T_AND, self::T_EXPREF);

            } elseif ($state === self::STATE_NOT) {

                $tokens[] = $this->matchOr($it, '!', '=', self::T_COMPARATOR, self::T_NOT);

            } else {

                $tokens[] = $this->matchOr($it, $it->current(), '=', self::T_COMPARATOR, self::T_COMPARATOR);

            }
        }

        return $tokens;
    }

    private function matchOr(\ArrayIterator<string> $it, string $current, string $expected, string $type, string $orElse): Token
    {
        
        $it->next();
        if ($it->valid() && $it->current() === $expected) {
            $it->next();
            $position = (int) $it->key();
            return shape(
                'type'  => $type,
                'pos'   => $position - 1,
                'value' => $current . $expected
            );
        }
        

        $position = (int) $it->key();
        return shape(
            'type'  => $orElse,
            'pos'   => $position - 1,
            'value' => $it->current()
        );
    }

    private function inside(\ArrayIterator<string> $it, string $delim, string $type): Token
    {
        $position = (int) $it->key();

        if($it->valid()) {
            $it->next();
        }
        $buffer = '';

        while ($it->valid() && $it->current() !== $delim) {
            if ($it->current() === '\\') {
                $buffer .= '\\';
                $it->next();
            }
            if (! $it->valid()) {
                return shape(
                    'type'  => self::T_UNKNOWN,
                    'value' => $buffer,
                    'pos'   => $position
                );
            }
            $buffer .= $it->current();
            $it->next();
        }

        if(! $it->valid()) {
            return shape(
                'type'  => self::T_UNKNOWN,
                'value' => $buffer,
                'pos'   => $position
            );
        }

        $it->next();
        return shape('type' => $type, 'value' => $buffer, 'pos' => $position);
    }

    private function parseJson(Token $token): Token
    {
        $error = null;
        $val = $token['value'] as string;
        $value = json_decode_with_error($val, inout $error, true);
        
        if($error is nonnull && $error[0]) {
            $error = null;
            $value = json_decode_with_error('"' . $val . '"', inout $error, true);
            
            if ($error is nonnull && $error[0]) {
                $token['type'] = self::T_UNKNOWN;
            } else {
                $token['value'] = $value;
            }
        } else {
            $token['value'] = $value;
        }
      
        return $token;
    }
}
