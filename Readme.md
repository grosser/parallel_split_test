Split a big test file into multiple chunks and run them in parallel

Install
=======
    sudo gem install parallel_split_test
Or

    rails plugin install git://github.com/grosser/parallel_split_test.git

Usage
=====
    # spec/xxx_spec.rb
    require "spec_helper"

    describe "X" do
      it {sleep 5}
    end

    describe "Y" do
      it {sleep 5}
    end

    describe "Z" do
      it {sleep 5}
    end

    parallel_split_test spec/xxx_spec.rb [regular rspec options]

Output
======

    time ./bin/parallel_split_test spec/xx_spec.rb
    .

    Finished in 5 seconds
    1 example, 0 failures
    ..

    Finished in 1 seconds
    2 examples, 0 failures

    real  0m11.015s
    user  0m0.908s
    sys  0m0.080s


TIPS
====
 - set number of processes to use with `PARALLEL_SPLIT_TEST_PROCESSES` environment variable

TODO
====
 - combine exit status (1 + 0 == 1)
 - support a single group with multiple sub-groups
 - Test::Unit support
 - Cucumber support

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/parallel_split_test.png)](http://travis-ci.org/grosser/parallel_split_test)
