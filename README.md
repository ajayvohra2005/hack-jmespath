# hack-jmespath

## Overview

This [Hack](http://hacklang.org) package allows one to search and extract elements from a JSON document using [JMESPath](http://jmespath.org) query language. 

## Installation

* Git clone this repository
* Install [composer](https://getcomposer.org/)
* In the root directory of this repository, run the command
  
        composer install

## Running Tests
After installation, run the following command in the root directory of this repository:

        ./vendor/bin/hacktest tests/
    
## Example Code

Below is a an example for searching a json document using a JMESPath query expression:

```
use namespace HackJmesPath;

<<__EntryPoint>>
function jmespath_example(): void {
  require_once(__DIR__.'/../vendor/autoload.hack');
  \Facebook\AutoloadMap\initialize();

    $json = '{
        "people": [
        {
            "name": "Jeff",
            "age": 33,
            "state": {"name": "up"}
        },
        {
            "name": "Bill",
            "age": 51,
            "state": {"name": "down"}
        },
        {
            "name": "Luna",
            "age": 42,
            "state": {"name": "up"}
        }
        ]
    }';

    $espression = "sort_by(people, &age)[].name";
    $result = HackJmesPath\jmespath_search($espression, $json);

    var_dump($result);
}
```

which produces the following expected output:

```
vec(3) {
  string(4) "Jeff"
  string(4) "Luna"
  string(4) "Bill"
}
```

## More Examples

See [```tests/TreeInterpreterTest.hack```](tests/TreeInterpreterTest.hack) for a complete list of test cases, and more examples. 

## Decoding JSON Data Types

JSON 'object' type must be represented by a [Hack\dict](https://docs.hhvm.com/hack/arrays-and-collections/introduction) object. The ```stdClass``` is not supported for a JSON 'object'. This means if you use the Hack built-in function ```json_decode()```, the second argument in the function call must be ```true``` so that associative arrays are used.

## JMESPath Query Language

Please refer to the in-depth [JMESPath Tutorial](https://jmespath.org/tutorial.html) to learn about JMESPath json query language.

## Acknowledgements
The [JMESPath package for PHP](https://github.com/jmespath/jmespath.php) in-part inspired this code. See individual source files for copyright acknowledgement.

