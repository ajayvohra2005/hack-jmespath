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

use function json_decode;
use type HackJmesPath\{Parser, AstRuntime};

<<__EntryPoint>>
function ast_runtime_example(): void {
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

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
  var_dump($result);

  $result = $runtime->search("people[].[name, state.name]", $data);
  var_dump($result);
  
  $result = $runtime->search("sort_by(people, &age)[].age", $data);
  var_dump($result);
}