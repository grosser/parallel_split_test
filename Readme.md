Split a big test file into multiple chunks and run them in parallel

Install
=======
    gem install parallel_split_test

Usage
=====

### 1: prepare your databases
To use 1 database per test-process, add this to your `config/database.yml`<br/>

```Yaml
test:
  database: yourproject_test<%= ENV['TEST_ENV_NUMBER'] %>
```

 - `TEST_ENV_NUMBER` is '' for the first process and 2 for the 2nd, it reuses your normal test database
 - Optionally install [parallel_tests](https://github.com/grosser/parallel_tests) to get database helper tasks like `rake parallel:prepare`


### 2: find a slow/big test file

```Ruby
# spec/xxx_spec.rb
require "spec_helper"

describe "X" do
  it {sleep 5}
  it {sleep 5}
  it {sleep 5}
end
```

### 3: run
```Bash
parallel_split_test spec/xxx_spec.rb [regular test options]
```

Output
======

```Bash
parallel_split_test spec/xx_spec.rb

Running examples in 2 processes
.

Finished in 5 seconds
1 example, 0 failures
..

Finished in 1 seconds
2 examples, 0 failures

Summary:
1 example, 0 failures
2 examples, 0 failures
Took 10.06 seconds with 2 processes
```

TIPS
====
 - use `-o/--out` to get unified/clean output from all processes
 - set number of processes to use with `PARALLEL_SPLIT_TEST_PROCESSES` environment variable

TODO
====
 - Cucumber support
 - Test::Unit / Minitest support

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/parallel_split_test.png)](https://travis-ci.org/grosser/parallel_split_test)
