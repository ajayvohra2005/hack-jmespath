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

use type HackJmesPath\{AstRuntime, Parser};

use function Facebook\FBExpect\expect;
use type Facebook\HackTest\{DataProvider, HackTest};


class TreeInterpreterTest extends HackTest
{

    public function testIdentifier(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = dict["a" => dict["b" => dict["c" => dict["d" => "value"]]]];
        $result = $runtime->search("a", $data);
        expect($result)->toBeSame($data["a"]);
    }

    public function testSubexpression(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = dict["a" => dict["b" => dict["c" => dict["d" => "value"]]]];
        $result = $runtime->search("a.b.c.d", $data);
        expect($result)->toBeSame("value");
    }

    public function testIndexexpression(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = vec["a" , "b", "c", "d"];
        $result = $runtime->search("[1]", $data);
        expect($result)->toBeSame("b");
    }

    public function testComplex1(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = dict[
            "a" => dict[
                "b" => dict[
                    "c" => vec[
                        dict["d" => vec[0, vec[1, 2] ] ],
                        dict["d" => vec[3, 4] ]
                    ]
                ]
            ]
        ];

        $result = $runtime->search("a.b.c[0].d[1][0]", $data);
        expect($result)->toBeSame(1);
    }

    public function testSlice1(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = vec[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        $result = $runtime->search("[5:10]", $data);
        expect($result)->toBeSame(vec[5,6,7,8,9]);
    }

    public function testSlice2(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = vec[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        $result = $runtime->search("[:5]", $data);
        expect($result)->toBeSame(vec[0,1,2,3,4]);
    }

    public function testSlice3(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = vec[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        $result = $runtime->search("[::2]", $data);
        expect($result)->toBeSame(vec[0,2,4,6,8]);
    }

    public function testSlice4(): void
    {
        $runtime = new AstRuntime(new Parser());
        $data = vec[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        $result = $runtime->search("[::-1]", $data);
        expect($result)->toBeSame(vec[9,8,7,6,5,4,3,2,1,0]);
    }

    public function testWildCardExpression(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
                    "people": [
                        {"first": "James", "last": "d"},
                        {"first": "Jacob", "last": "e"},
                        {"first": "Jayden", "last": "f"},
                        {"missing": "different"}
                    ],
                    "foo": {"bar": "baz"}
                }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("people[*].first", $data);
        expect($result)->toBeSame(vec["James","Jacob","Jayden"]);
    }

    public function testSliceExpression(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
                    "people": [
                        {"first": "James", "last": "d"},
                        {"first": "Jacob", "last": "e"},
                        {"first": "Jayden", "last": "f"},
                        {"missing": "different"}
                    ],
                    "foo": {"bar": "baz"}
                }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("people[:2].first", $data);
        expect($result)->toBeSame(vec["James","Jacob"]);
    }

    public function testObjectProjection(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "ops": {
                "functionA": {"numArgs": 2},
                "functionB": {"numArgs": 3},
                "functionC": {"variadic": true}
            }
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("ops.*.numArgs", $data);
        expect($result)->toBeSame(vec[2,3]);
    }

    public function testFlattenProjections(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "reservations": [
                {
                    "instances": [
                        {"state": "running"},
                        {"state": "stopped"}
                    ]
                },
                {
                    "instances": [
                        {"state": "terminated"},
                        {"state": "running"}
                    ]
                }
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("reservations[*].instances[*].state[]", $data);
        expect($result)->toBeSame(vec[ "running", "stopped", "terminated","running"]);
    }

    public function testFilterProjections(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "machines": [
                {"name": "a", "state": "running"},
                {"name": "b", "state": "stopped"},
                {"name": "b", "state": "running"}
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("machines[?state=='running'].name", $data);
        expect($result)->toBeSame(vec["a","b"]);
    }

    public function testPipeExpressions(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "people": [
                {"first": "James", "last": "d"},
                {"first": "Jacob", "last": "e"},
                {"first": "Jayden", "last": "f"},
                {"missing": "different"}
            ],
            "foo": {"bar": "baz"}
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("people[*].first | [0]", $data);
        expect($result)->toBeSame("James");
    }

    public function testMultiSelectList(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "people": [
                {
                    "name": "a",
                    "state": {"name": "up"}
                },
                {
                    "name": "b",
                    "state": {"name": "down"}
                },
                {
                    "name": "c",
                    "state": {"name": "up"}
                }
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("people[].[name, state.name]", $data);
        expect($result)->toBeSame(vec[ vec["a","up"], vec["b","down"], vec["c","up"]]);
    }

    public function testMultiSelectHash(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "people": [
                {
                    "name": "a",
                    "state": {"name": "up"}
                },
                {
                    "name": "b",
                    "state": {"name": "down"}
                },
                {
                    "name": "c",
                    "state": {"name": "up"}
                }
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("people[].{Name: name, State: state.name}", $data);
        expect($result)->toBeSame(vec[
            dict[
                "Name" => "a",
                "State" => "up"
            ],
            dict[
                "Name" => "b",
                "State" => "down"
            ],
            dict[
                "Name" => "c",
                "State" => "up"
            ] ]);
    }

    public function testLengthFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "people": [
                {
                    "name": "a",
                    "state": {"name": "up"}
                },
                {
                    "name": "b",
                    "state": {"name": "down"}
                },
                {
                    "name": "c",
                    "state": {"name": "up"}
                }
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("length(people)", $data);
        expect($result)->toBeSame(3);
    }

    public function testContainsFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "myarray": [
                "foo",
                "foobar",
                "barfoo",
                "bar",
                "baz",
                "barbaz",
                "barfoobaz"
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("myarray[?contains(@, 'foo') == `true`]", $data);
        expect($result)->toBeSame(vec["foo","foobar","barfoo","barfoobaz"]);
    }

    public function testAbsFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": -1, "bar": "2"}';
            
        $data = json_decode($json, true);
        $result = $runtime->search("abs(foo)", $data);
        expect($result)->toBeSame(1);
    }

    public function testAvgFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '[10, 15, 20]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("avg(@)", $data);
        expect($result)->toBeSame((float)15);
    }

    public function testCeilFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '[10.2, 15.1, 20.3]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("ceil(avg(@))", $data);
        expect($result)->toBeSame(16);
    }

    public function testEndsWithFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "myarray": [
                "foo",
                "foobar",
                "barfoo",
                "bar",
                "baz",
                "barbaz",
                "barfoobaz"
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("myarray[?ends_with(@, 'foo') == `true`]", $data);
        expect($result)->toBeSame(vec["foo", "barfoo"]);
    }

    public function testStartsWithFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "myarray": [
                "foo",
                "foobar",
                "barfoo",
                "bar",
                "baz",
                "barbaz",
                "barfoobaz"
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("myarray[?starts_with(@, 'bar') == `true`]", $data);
        expect($result)->toBeSame(vec["barfoo", "bar", "barbaz", "barfoobaz"]);
    }


    public function testFloorFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '[10.2, 15.1, 20.3]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("floor(avg(@))", $data);
        expect($result)->toBeSame(15);
    }

    public function testJoinFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
            "myarray": [
                "foo",
                "bar"
            ]
        }';
            
        $data = json_decode($json, true);
        $result = $runtime->search("join(`, `, myarray)", $data);
        expect($result)->toBeSame("foo, bar");
    }

    public function testKeysFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": "baz", "bar": "bam"}';
            
        $data = json_decode($json, true);
        $result = $runtime->search("keys(@)", $data);
        expect($result)->toBeSame(vec["foo", "bar"]);
    }

    public function testMapFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"array": [{"foo": "a"}, {"foo": "b"}, {}, [], {"foo": "f"}]}';
            
        $data = json_decode($json, true);
        $result = $runtime->search("map(&foo, array)", $data);
        expect($result)->toBeSame(vec["a", "b", null, null, "f"]);
    }

    public function testMaxFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '[10.1, 15, 87, -2.0]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("max(@)", $data);
        expect($result)->toBeSame(87);
    }

    public function testMaxByFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
                    "people": [
                        {
                        "name": "a",
                        "age": 33,
                        "state": {"name": "up"}
                        },
                        {
                        "name": "b",
                        "age": 51,
                        "state": {"name": "down"}
                        },
                        {
                        "name": "c",
                        "age": 42,
                        "state": {"name": "up"}
                        }
                    ]
                }';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("max_by(people, &age).age", $data);
        expect($result)->toBeSame(51);
    }

    public function testMinFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '[10.1, 15, 87, -2.0]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("min(@)", $data);
        expect($result)->toBeSame(-2.0);
    }

    public function testMinByFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
                    "people": [
                        {
                        "name": "a",
                        "age": 33,
                        "state": {"name": "up"}
                        },
                        {
                        "name": "b",
                        "age": 51,
                        "state": {"name": "down"}
                        },
                        {
                        "name": "c",
                        "age": 42,
                        "state": {"name": "up"}
                        }
                    ]
                }';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("min_by(people, &age).age", $data);
        expect($result)->toBeSame(33);
    }

    public function testMergeFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '[{"a": "x", "b": "y"}, {"b": "override", "c": "z"}]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("merge(@)", $data);
        expect($result)->toBeSame(dict["a" => "x", "b" => "override", "c" => "z"]);
    }

    public function testNonNullFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"a": null, "b": null, "c": [], "d": "foo"}';
            
        $data = json_decode($json, true);
        $result = $runtime->search("not_null(a, b, `null`, d, c)", $data);
        expect($result)->toBeSame("foo");
    }

    public function testReverseFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '["a", "b", "c", 1, 2, 3]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("reverse(@)", $data);
        expect($result)->toBeSame(vec[3, 2, 1, "c", "b", "a"]);
    }

    public function testSortFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '["b", "a", "c"]';
            
        $data = json_decode($json, true);
        $result = $runtime->search("sort(@)", $data);
        expect($result)->toBeSame(vec["a", "b", "c"]);
    }

    public function testSortByFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
                    "people": [
                        {
                        "name": "a",
                        "age": 33,
                        "state": {"name": "up"}
                        },
                        {
                        "name": "b",
                        "age": 51,
                        "state": {"name": "down"}
                        },
                        {
                        "name": "c",
                        "age": 42,
                        "state": {"name": "up"}
                        }
                    ]
                }';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("sort_by(people, &age)[].age", $data);
        expect($result)->toBeSame(vec[33, 42, 51]);
    }

    public function testSumFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{
                    "people": [
                        {
                        "name": "a",
                        "age": 33,
                        "state": {"name": "up"}
                        },
                        {
                        "name": "b",
                        "age": 51,
                        "state": {"name": "down"}
                        },
                        {
                        "name": "c",
                        "age": 42,
                        "state": {"name": "up"}
                        }
                    ]
                }';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("sum(sort_by(people, &age)[].age)", $data);
        expect($result)->toBeSame(126.0);
    }

    public function testToArrayFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": "bar"}';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("to_array(@)", $data);
        expect($result)->toBeSame(vec[dict["foo" => "bar"]]);
    }

    public function testToStringFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": 20}';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("to_string(foo)", $data);
        expect($result)->toBeSame("20");
    }

    public function testToNumberFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": "20"}';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("to_number(foo)", $data);
        expect($result)->toBeSame((float)20);
    }

    public function testTypeFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": "bar"}';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("type(@)", $data);
        expect($result)->toBeSame("object");
    }

    public function testValuesFunction(): void
    {
        $runtime = new AstRuntime(new Parser());
        $json = '{"foo": "baz", "bar": "bam"}';
                    
        $data = json_decode($json, true);
        $result = $runtime->search("values(@)", $data);
        expect($result)->toBeSame(vec["baz", "bam"]);
    }

}
