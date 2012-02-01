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

    time parallel_split_test spec/xxx_spec.rb [regular rspec options]

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
