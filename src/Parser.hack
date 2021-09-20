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

use function floatval;

class Parser
{
    /* EOF token */
    private static Token $eofToken = shape('type' => Lexer::T_EOF, 'value' => '', 'pos' => -1);

    /* Lexer to tokenize JMESPath query expression  */
    private Lexer $lexer;

    /* vector of scanned tokens */
    private vec<Token> $tokens;

    /* current scanned token */
    private Token $token;

    /* current token position */
    private int $tpos;

    /* JMESPath query expression */
    private string $expression;

    /* Current ASTNode */
    private ASTNode $currentNode;
   
    private static dict<string, int> $bp = dict[
        Lexer::T_EOF               => 0,
        Lexer::T_QUOTED_IDENTIFIER => 0,
        Lexer::T_IDENTIFIER        => 0,
        Lexer::T_RBRACKET          => 0,
        Lexer::T_RPAREN            => 0,
        Lexer::T_COMMA             => 0,
        Lexer::T_RBRACE            => 0,
        Lexer::T_NUMBER            => 0,
        Lexer::T_CURRENT           => 0,
        Lexer::T_EXPREF            => 0,
        Lexer::T_COLON             => 0,
        Lexer::T_PIPE              => 1,
        Lexer::T_OR                => 2,
        Lexer::T_AND               => 3,
        Lexer::T_COMPARATOR        => 5,
        Lexer::T_FLATTEN           => 9,
        Lexer::T_STAR              => 20,
        Lexer::T_FILTER            => 21,
        Lexer::T_DOT               => 40,
        Lexer::T_NOT               => 45,
        Lexer::T_LBRACE            => 50,
        Lexer::T_LBRACKET          => 55,
        Lexer::T_LPAREN            => 60,
    ];

    /* set of tokens that can appear after a dot token */
    private static keyset<string> $afterDot = keyset[
        Lexer::T_IDENTIFIER, 
        Lexer::T_QUOTED_IDENTIFIER, 
        Lexer::T_STAR, 
        Lexer::T_LBRACE, 
        Lexer::T_LBRACKET, 
        Lexer::T_FILTER, 
    ];

    private keyset<string> $led_tokens = keyset[
        "lbracket",
        "flatten",
        "dot",
        "or",
        "and",
        "pipe",
        "lparen",
        "filter",
        "comparator",
    ];

    private keyset<string> $nud_tokens = keyset[
        "identifier",
        "quoted_identifier",
        "current",
        "literal",
        "expref",
        "not",
        "lparen",
        "lbrace",
        "flatten",
        "filter",
        "star",
        "lbracket"
    ];
    
    /**
     * Constructor
     *
     * @param ?Lexer $lexer optional lexer
     */
    public function __construct(?Lexer $lexer=null)
    {
        $this->lexer = $lexer ? $lexer: new Lexer();
        $this->token = shape('type' => Lexer::T_UNKNOWN, 'value' => '', 'pos' => -1);
        $this->tokens = vec[];
        $this->tpos = -1;
        $this->expression = '';
        $this->currentNode = new ASTNode(Lexer::T_CURRENT);
    }

    /**
     * Parses a JMESPath query expression, and returns the abstract syntax tree root node
     *
     * @param string $expression JMESPath query expresion 
     * @return ASTNode parsed abstract syntax tree root node
     */
    public function parse(string $expression): ASTNode
    {
        $this->expression = $expression;
        $this->tokens = $this->lexer->tokenize($expression);
        $this->tpos = -1;
        $this->next();
        $result = $this->expr();

        if ($this->token['type'] === Lexer::T_EOF) {
            return $result;
        }

        throw $this->syntaxError('Did not reach the end of the token stream');
    }

    private function invoke_nud(): ASTNode
    {
        $retval = null;

        switch($this->token['type']) {
            case "identifier":
                $retval = $this->nud_identifier();
                break;
            case "quoted_identifier":
                $retval = $this->nud_quoted_identifier();
                break;
            case "current":
                $retval = $this->nud_current();
                break;
            case "literal":
                $retval = $this->nud_literal();
                break;
            case "expref":
                $retval = $this->nud_expref();
                break;
            case "not":
                $retval = $this->nud_not();
                break;
            case "lparen":
                $retval = $this->nud_lparen();
                break;
            case "lbrace":
                $retval = $this->nud_lbrace();
                break;
            case "flatten":
                $retval = $this->nud_flatten();
                break;
            case "filter":
                $retval = $this->nud_filter();
                break;
            case "star":
                $retval = $this->nud_star();
                break;
            case "lbracket":
                $retval = $this->nud_lbracket();
                break;
            default:
                $expected = Str\join($this->nud_tokens, ",");
                $message = "Unexpected \"{$this->token['type']}\" token (nud_{$this->token['type']}). Expected one of"
                    . " the following tokens: $expected";
                throw $this->syntaxError($message);
        }
        
        return $retval;
    }

    private function invoke_led(ASTNode $node): ASTNode
    {
        $retval = null;

        switch($this->token['type']) {
             case "lbracket":
                $retval = $this->led_lbracket($node);
                break;
            case "flatten":
                $retval = $this->led_flatten($node);
                break;
            case "dot":
                $retval = $this->led_dot($node);
                break;
            case "or":
                $retval = $this->led_or($node);
                break;
            case "and":
                $retval = $this->led_and($node);
                break;
            case "pipe":
                $retval = $this->led_pipe($node);
                break;
            case "lparen":
                $retval = $this->led_lparen($node);
                break;
            case "filter":
                $retval = $this->led_filter($node);
                break;
            case "comparator":
                $retval = $this->led_comparator($node);
                break;
            default:
                $expected = Str\join($this->led_tokens, ",");
                $message = "Unexpected \"{$this->token['type']}\" token (led_{$this->token['type']}). Expected one of"
                    . " the following tokens: $expected";
                throw $this->syntaxError($message);
        }

        return $retval;
    }

    private function expr(int $rbp = 0): ASTNode
    {
        $left = $this->invoke_nud();
        while ($rbp < self::$bp[$this->token['type']]) {
            $left = $this->invoke_led($left);
        }

        return $left;
    }

    private function nud_identifier(): ASTNode
    {
        $token = $this->token;
        $this->next();
        $val = $token['value'] as arraykey;
        return new ASTNode('field', vec[$val]);
    }

    private function nud_quoted_identifier(): ASTNode
    {
        $token = $this->token;
        $this->next();
        $this->assertNotToken(Lexer::T_LPAREN);
        $val = $token['value'] as arraykey;
        return new ASTNode('field', vec[$val]);
    }

    private function nud_current(): ASTNode
    {
        $this->next();
        return $this->currentNode;
    }

    private function nud_literal(): ASTNode
    {
        $token = $this->token;
        $this->next();
        $val = $token['value'];
        return new ASTNode('literal', vec[$val]);
    }

    private function nud_expref(): ASTNode
    {
        $this->next();
        return new ASTNode(Lexer::T_EXPREF, vec[], '', vec[$this->expr(self::$bp[Lexer::T_EXPREF])]
        );
    }

    private function nud_not(): ASTNode
    {
        $this->next();
        return new ASTNode(Lexer::T_NOT, vec[], '', vec[$this->expr(self::$bp[Lexer::T_NOT])]);
    }

    private function nud_lparen(): ASTNode
    {
        $this->next();
        $result = $this->expr(0);
        if ($this->token['type'] !== Lexer::T_RPAREN) {
            throw $this->syntaxError('Unclosed `(`');
        }
        $this->next();
        return $result;
    }

    private function nud_lbrace(): ASTNode
    {
        $validKeys = keyset[Lexer::T_QUOTED_IDENTIFIER, Lexer::T_IDENTIFIER];
        $this->next($validKeys);
        $pairs = vec[];

        do {
            $pairs[] = $this->parseKeyValuePair();
            if ($this->token['type'] == Lexer::T_COMMA) {
                $this->next($validKeys);
            }
        } while ($this->token['type'] !== Lexer::T_RBRACE);

        $this->next();

        return new ASTNode('multi_select_hash', vec[], '', $pairs);
    }

    private function nud_flatten(): ASTNode
    {
        return $this->led_flatten($this->currentNode);
    }

    private function nud_filter(): ASTNode
    {
        return $this->led_filter($this->currentNode);
    }

    private function nud_star(): ASTNode
    {
        return $this->parseWildcardObject($this->currentNode);
    }

    private function nud_lbracket(): ASTNode
    {
        $this->next();
        $type = $this->token['type'];
        if ($type == Lexer::T_NUMBER || $type == Lexer::T_COLON) {
            return $this->parseArrayIndexExpression();
        } elseif ($type == Lexer::T_STAR && $this->lookahead() == Lexer::T_RBRACKET) {
            return $this->parseWildcardArray();
        } else {
            return $this->parseMultiSelectList();
        }
    }

    private function led_lbracket(ASTNode $left): ASTNode
    {
        $nextTypes = keyset[Lexer::T_NUMBER, Lexer::T_COLON, Lexer::T_STAR];
        $this->next($nextTypes);
        switch ($this->token['type']) {
            case Lexer::T_NUMBER:
            case Lexer::T_COLON:
                return new ASTNode('subexpression', vec[], '',
                    vec[$left, $this->parseArrayIndexExpression()]);
            default:
                return $this->parseWildcardArray($left);
        }
    }

    private function led_flatten(ASTNode $left): ASTNode
    {
        $this->next();

        return new ASTNode('projection', vec[], 'array',
            vec[
                new ASTNode(Lexer::T_FLATTEN, vec[], '', vec[$left]),
                $this->parseProjection(self::$bp[Lexer::T_FLATTEN])
            ]
        );
    }

    private function led_dot(ASTNode $left): ASTNode
    {
        $this->next(self::$afterDot);

        if ($this->token['type'] == Lexer::T_STAR) {
            return $this->parseWildcardObject($left);
        }

        return new ASTNode('subexpression', vec[], '', 
            vec[$left, $this->parseDot(self::$bp[Lexer::T_DOT])]);
    }

    private function led_or(ASTNode $left): ASTNode
    {
        $this->next();
        return new ASTNode(Lexer::T_OR, vec[], '',vec[$left, $this->expr(self::$bp[Lexer::T_OR])]);
    }

    private function led_and(ASTNode $left): ASTNode
    {
        $this->next();
        return new ASTNode(Lexer::T_AND, vec[], '', vec[$left, $this->expr(self::$bp[Lexer::T_AND])]);
    }

    private function led_pipe(ASTNode $left): ASTNode
    {
        $this->next();
        return new ASTNode(Lexer::T_PIPE, vec[], '', vec[$left, $this->expr(self::$bp[Lexer::T_PIPE])]);
    }

    private function led_lparen(ASTNode $left): ASTNode
    {
        $args = vec[];
        $this->next();

        while ($this->token['type'] != Lexer::T_RPAREN) {
            $args[] = $this->expr(0);
            if ($this->token['type'] == Lexer::T_COMMA) {
                $this->next();
            }
        }

        $this->next();

        return new ASTNode('function', $left->get_value(), '',$args);
    }

    private function led_filter(?ASTNode $left=null): ASTNode
    {
        $this->next();
        $expression = $this->expr();
        if ($this->token['type'] != Lexer::T_RBRACKET) {
            throw $this->syntaxError('Expected a closing rbracket for the filter');
        }

        $this->next();
        $rhs = $this->parseProjection(self::$bp[Lexer::T_FILTER]);

        return new ASTNode('projection', vec[], 'array',
            vec[
                $left ? $left: $this->currentNode,
                new ASTNode('condition', vec[], '', vec[$expression, $rhs])
            ]
        );
    }

    private function led_comparator(ASTNode $left): ASTNode
    {
        $token = $this->token;
        $this->next();

        $val = $token['value'] as arraykey;
        return new ASTNode(Lexer::T_COMPARATOR, vec[$val], '',
            vec[$left, $this->expr(self::$bp[Lexer::T_COMPARATOR])]);
    }

    private function parseProjection(int $bp): ASTNode
    {
        $type = $this->token['type'];
        if (self::$bp[$type] < 10) {
            return $this->currentNode;
        } elseif ($type == Lexer::T_DOT) {
            $this->next(self::$afterDot);
            return $this->parseDot($bp);
        } elseif ($type == Lexer::T_LBRACKET || $type == Lexer::T_FILTER) {
            return $this->expr($bp);
        }

        throw $this->syntaxError('Syntax error after projection');
    }

    private function parseDot(int $bp): ASTNode
    {
        if ($this->token['type'] == Lexer::T_LBRACKET) {
            $this->next();
            return $this->parseMultiSelectList();
        }

        return $this->expr($bp);
    }

    private function parseKeyValuePair(): ASTNode
    {
        $validColon = keyset[Lexer::T_COLON];
        $key = $this->token['value'] as arraykey;
        $this->next($validColon);
        $this->next();

        return new ASTNode('key_val_pair', vec[$key], '', vec[$this->expr()]);
    }

    private function parseWildcardObject(?ASTNode $left=null): ASTNode
    {
        $this->next();

        return new ASTNode('projection', vec[], 'object',
            vec[$left ? $left: $this->currentNode, $this->parseProjection(self::$bp[Lexer::T_STAR])]
        );
    }

    private function parseWildcardArray(?ASTNode $left=null): ASTNode
    {
        $getRbracket = keyset[Lexer::T_RBRACKET];
        $this->next($getRbracket);
        $this->next();

        return new ASTNode('projection', vec[], 'array',
            vec[
                $left ? $left: $this->currentNode,
                $this->parseProjection(self::$bp[Lexer::T_STAR])
            ]
        );
    }

    private function parseArrayIndexExpression(): ASTNode
    {
        $matchNext = keyset[
            Lexer::T_NUMBER,
            Lexer::T_COLON,
            Lexer::T_RBRACKET
        ];

        $pos = 0;
        
        $parts = vec[0, 0, 1];
        $expected = $matchNext;

        do {
            if ($this->token['type'] == Lexer::T_COLON) {
                $pos++;
                $expected = $matchNext;
            } elseif ($this->token['type'] == Lexer::T_NUMBER) {
                $parts[$pos] = (int)$this->token['value'];
                $expected = keyset[Lexer::T_COLON, Lexer::T_RBRACKET];
            }
            $this->next($expected);
        } while ($this->token['type'] != Lexer::T_RBRACKET);

        $this->next();

        if ($pos === 0) {
            return new ASTNode('index', Vec\take($parts, 1));
        }

        if ($pos > 2) {
            throw $this->syntaxError('Invalid array slice syntax: too many colons');
        }

        return new ASTNode('projection', vec[], 'array',
            vec[new ASTNode('slice', $parts), $this->parseProjection(self::$bp[Lexer::T_STAR])]
        );
    }

    private function parseMultiSelectList(): ASTNode
    {
        $nodes = vec[];

        do {
            $nodes[] = $this->expr();
            if ($this->token['type'] == Lexer::T_COMMA) {
                $this->next();
                $this->assertNotToken(Lexer::T_RBRACKET);
            }
        } while ($this->token['type'] !== Lexer::T_RBRACKET);
        $this->next();

        return new ASTNode('multi_select_list', vec[], '', $nodes);
    }

    private function syntaxError(mixed $msg): SyntaxErrorException
    {
        return new SyntaxErrorException($msg, $this->token, $this->expression);
    }

    private function lookahead(): string
    {
        return (!idx($this->tokens, $this->tpos + 1))
            ? Lexer::T_EOF
            : $this->tokens[$this->tpos + 1]['type'];
    }

    private function next(?keyset<string> $match = null): void
    {
        if (!idx($this->tokens, $this->tpos + 1)) {
            $this->token = self::$eofToken;
        } else {
            $this->tpos += 1;
            $this->token = $this->tokens[$this->tpos];
        }

        if ($match && !C\contains($match, $this->token['type']) ) {
            throw $this->syntaxError($match);
        }
    }

    private function assertNotToken(string $type): void
    {
        if ($this->token['type'] == $type) {
            throw $this->syntaxError("Token {$this->tpos} not allowed to be $type");
        }
    }
}
