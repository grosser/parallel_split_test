require 'spec_helper'

describe ParallelSplitTest do
  it "has a VERSION" do
    expect(ParallelSplitTest::VERSION).to match(/^[\.\da-z]+$/)
  end

  describe ".best_number_of_processes" do
    before do
      ENV['PARALLEL_SPLIT_TEST_PROCESSES'] = nil
    end

    let(:count) { ParallelSplitTest.send(:best_number_of_processes) }

    it "uses ENV" do
      ENV['PARALLEL_SPLIT_TEST_PROCESSES'] = "5"
      expect(count).to eq(5)
    end

    it "uses physical_processor_count" do
      allow(Parallel).to receive(:physical_processor_count).and_return 6
      expect(count).to eq(6)
    end

    it "uses processor_count if everything else fails" do
      allow(Parallel).to receive(:physical_processor_count).and_return 0
      allow(Parallel).to receive(:processor_count).and_return 7
      expect(count).to eq(7)
    end
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

    def parallel_split_test(x, options={})
      run "PARALLEL_SPLIT_TEST_PROCESSES=#{options[:process_count] || 2} ../../bin/parallel_split_test #{x}", options
    end

    def time
      start = Time.now.to_f
      yield
      Time.now.to_f - start
    end

    let(:root) { File.expand_path('../../', __FILE__) }

    around do |example|
      dir = "spec/tmp#{ENV['TEST_ENV_NUMBER']}"
      run "rm -rf #{dir} ; mkdir #{dir}"
      Dir.chdir(dir, &example)
      run "rm -rf #{dir}"
    end

    describe "printing version" do
      it "prints version on -v" do
        expect(parallel_split_test("-v").strip).to match(/^[\.\da-z]+$/)
      end

      it "prints version on --version" do
        expect(parallel_split_test("--version").strip).to match(/^[\.\da-z]+$/)
      end
    end

    describe "printing help" do
      it "prints help on -h" do
        expect(parallel_split_test("-h")).to include("Usage")
      end

      it "prints help on --help" do
        expect(parallel_split_test("-h")).to include("Usage")
      end

      it "prints help on no arguments" do
        expect(parallel_split_test("")).to include("Usage")
      end
    end

    describe "running tests" do
      it "runs in different processes" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it "a" do
            puts "it-ran-a-in-\#{ENV['TEST_ENV_NUMBER']}-"
          end
        end

        describe "Y" do
          it "b" do
            puts "it-ran-b-in-\#{ENV['TEST_ENV_NUMBER']}-"
          end
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb"
        expect(result.scan('1 example, 0 failures').size).to eq(4)
        expect(result.scan(/it-ran-.-in-.?-/).sort).to eq(["it-ran-a-in--", "it-ran-b-in-2-"])
      end

      it "runs in different processes for many examples/processes" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          #{(0...3).to_a.map{|i| "it{ puts 'it-ran-"+ i.to_s+"-in-'+ENV['TEST_ENV_NUMBER'].to_s + '-' }" }.join("\n")}
          describe "Y" do
            #{(3...6).to_a.map{|i| "it{ puts 'it-ran-"+ i.to_s+"-in-'+ENV['TEST_ENV_NUMBER'].to_s + '-' }" }.join("\n")}
            describe "Y" do
              #{(6...9).to_a.map{|i| "it{ puts 'it-ran-"+ i.to_s+"-in-'+ENV['TEST_ENV_NUMBER'].to_s + '-' }" }.join("\n")}
            end
          end
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb", :process_count => 3
        expect(result.scan('3 examples, 0 failures').size).to eq(6)
        expect(result.scan(/it-ran-.-in-.?-/).size).to eq(9)
      end

      it "runs faster" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it { sleep 1.5  }
        end

        describe "Y" do
          it { sleep 1.5  }
        end
        RUBY

        expect(time{ parallel_split_test "xxx_spec.rb" }).to be < 3
      end

      it "splits based on examples" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          describe "Y" do
            it { sleep 1.5  }
            it { sleep 1.5  }
          end
        end
        RUBY

        result = nil
        expect(time{ result = parallel_split_test "xxx_spec.rb" }).to be < 3
        expect(result.scan('1 example, 0 failures').size).to eq(4)
      end

      it "sets up TEST_ENV_NUMBER before loading the test files, so db connections are set up correctly" do
        write "xxx_spec.rb", 'puts "ENV_IS_#{ENV[\'TEST_ENV_NUMBER\']}_"'
        result = parallel_split_test "xxx_spec.rb"
        expect(result.scan(/ENV_IS_.?_/).sort).to eq(["ENV_IS_2_", "ENV_IS__"])
      end

      it "fails when one of the processes fail" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it { sleep 0.1; raise }
          it { sleep 0.1  }
        end
        RUBY

        # test works because if :fail => true does not fail it raises
        result = parallel_split_test "xxx_spec.rb", :fail => true
        expect(result).to include('1 example, 1 failure')
        expect(result).to include('1 example, 0 failures')
      end

      it "fails when all processes fail" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it { sleep 0.1; raise }
          it { sleep 0.1; raise  }
        end
        RUBY

        # test works because if :fail => true does not fail it raises
        result = parallel_split_test "xxx_spec.rb", :fail => true
        expect(result.scan('1 example, 1 failure').size).to eq(4)
      end

      it "passes when no tests where run" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb"
        expect(result).to include('No examples found')
      end

      it "prints a summary before running" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb"
        expect(result).to include('Running examples in 2 processes')
      end

      it "prints a runtime summary at the end" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb"
        expect(result).to match(/Took [\d\.]+ seconds with 2 processes/)
      end

      it "omits summary when --no-summary is used" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb --no-summary"
        expect(result).not_to match(/Summary:/)
      end

      it "reprints all summary lines at the end" do
        write "xxx_spec.rb", <<-RUBY
        describe "X" do
          it {  }
          it { sleep 0.1  }
        end
        RUBY
        result = parallel_split_test "xxx_spec.rb"
        expect(result).to include("1 example, 0 failures\n1 example, 0 failures")
      end

      it "can use rspec options" do
        write "xxx_spec.rb", <<-RUBY
          describe "xxx" do
            it "yyy" do
            end
          end
        RUBY

        result = parallel_split_test "xxx_spec.rb --format html"
        expect(result).to include "</body>"
      end

      it "writes a unified --out" do
        write "xxx_spec.rb", <<-RUBY
          describe "xxx" do
            it "yyy" do
            end

            it "zzz" do
            end
          end
        RUBY
        result = parallel_split_test "xxx_spec.rb --format d --out xxx"

        # output does not show up in stdout
        expect(result).not_to include "xxx"
        expect(result).not_to include "yyy"

        # basic output is still there
        expect(result).to include "Running examples in"

        # recorded output is combination of both
        out = File.read("xxx")
        expect(out).to include "yyy"
        expect(out).to include "zzz"

        # parts are cleaned up
        expect(Dir["*-xxx"]).to eq([])
      end

      it "writes seperate files with --no-merge" do
        write "xxx_spec.rb", <<-RUBY
          describe "xxx" do
            it "yyy" do
            end

            it "zzz" do
            end
          end
        RUBY
        result = parallel_split_test "xxx_spec.rb --format d --out xxx --no-merge"
        # output does not show up in stdout
        expect(result).not_to include "xxx"
        expect(result).not_to include "yyy"

        # basic output is still there
        expect(result).to include "Running examples in"

        # two separate out files remain
        expect(Dir["*-xxx"]).to include "0-xxx"
        expect(Dir["*-xxx"]).to include "1-xxx"
      end
    end
  end
end
