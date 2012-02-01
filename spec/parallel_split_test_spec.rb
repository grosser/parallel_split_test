require 'spec_helper'

describe ParallelSplitTest do
  it "has a VERSION" do
    ParallelSplitTest::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe "cli" do
    def run(command, options={})
      result = `#{command} 2>&1`
      message = (options[:fail] ? "SUCCESS BUT SHOULD FAIL" : "FAIL")
      raise "[#{message}] #{result} [#{command}]" if $?.success? == !!options[:fail]
      result
    end

    def write(path, content)
      run "mkdir -p #{File.dirname(path)}" unless File.exist?(File.dirname(path))
      File.open(path, 'w'){|f| f.write content }
      path
    end

    def parallel_split_test(x)
      run "PARALLEL_SPLIT_TEST_PROCESSES=2 ../../bin/parallel_split_test #{x}"
    end

    def time
      start = Time.now.to_f
      yield
      Time.now.to_f - start
    end

    let(:root) { File.expand_path('../../', __FILE__) }

    before do
      run "rm -rf spec/tmp ; mkdir spec/tmp"
      Dir.chdir "spec/tmp"
    end

    after do
      Dir.chdir root
    end

    describe "printing version" do
      it "prints version on -v" do
        parallel_split_test("-v").strip.should =~ /^[\.\da-z]+$/
      end

      it "prints version on --version" do
        parallel_split_test("--version").strip.should =~ /^[\.\da-z]+$/
      end
    end

    describe "printing help" do
      it "prints help on -h" do
        parallel_split_test("-h").should include("Usage")
      end

      it "prints help on --help" do
        parallel_split_test("-h").should include("Usage")
      end

      it "prints help on no arguments" do
        parallel_split_test("").should include("Usage")
      end
    end

    describe "running tests" do
      it "runs in different processes" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it "a" do
            puts "it-ran-a-in-\#{ENV['TEST_ENV_NUMBER'].to_i}-"
          end
        end

        describe "Y" do
          it "b" do
            puts "it-ran-b-in-\#{ENV['TEST_ENV_NUMBER'].to_i}-"
          end
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb"

        processes = ["a","b"].map do |process|
          rex = /it-ran-#{process}-in-(\d)-/
          result.should =~ rex
          result.match(rex)[1]
        end

        processes.sort.should == ['0','2']
      end

      it "runs faster" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it { sleep 1  }
        end

        describe "Y" do
          it { sleep 1  }
        end
        RUBY

        time{ parallel_split_test "xxx_spec.rb" }.should < 2
      end
    end
  end
end
