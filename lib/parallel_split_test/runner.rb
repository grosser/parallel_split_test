require 'parallel_split_test/command_line'
require 'fileutils'
require 'hpricot'
require "rexml/document"

# a cleaned up version of the RSpec runner, e.g. no drb support
module ParallelSplitTest
  class Runner < RSpec::Core::Runner
    def self.run(args, err=$stderr, out=$stdout)
      trap_interrupt

      @args = args

      ParallelSplitTest.choose_number_of_processes
      out.puts "Running examples in #{ParallelSplitTest.processes} processes"

      report_execution_time(out) do
        ParallelSplitTest::CommandLine.new(args).run(err, out)
      end
    ensure
      RSpec.reset
    end

    def self.report_execution_time(out)
      start = Time.now.to_f
      result = yield
      runtime = Time.now.to_f - start
      out.puts "Took %.2f seconds with #{ParallelSplitTest.processes} processes" % runtime
      merge_output
      result
    end

    def self.merge_output

      return if @args.index("--out").nil?

      # Choose merge strategy based on format
      if !@args.index("--format").nil?
        case @args[@args.index("--format") + 1]
        when "JUnit"
          junit_merge
        else
          basic_merge
        end
      else
        basic_merge
      end

    end

    def self.junit_merge

      output       = @args[@args.index("--out")+1]
      path_defined = output.rindex("/")
      folder       = path_defined.nil? ? "." : output[0...(output.rindex("/"))]
      file         = path_defined.nil? ? output : output[(output.rindex("/"))+1..output.length]

      errors   = 0
      failures = 0
      skipped  = 0
      tests    = 0
      time     = 0
      cases    = []

      xml_files = []
      Dir.entries(folder).each do |element|
        xml_files << element if element.start_with?(file)
      end

      xml_files.each do |xml_file|

        # Collect the test cases
        temp = File.new("#{folder}/#{xml_file}")
        hdoc = Hpricot::XML(temp)
        (hdoc/:testcase).each { |testcase| cases << testcase }

        # Add up the attributes
        temp = File.new("#{folder}/#{xml_file}")
        xdoc = REXML::Document.new temp
        xdoc.elements.each("testsuite") do |element|
          errors   += element.attributes["errors"].to_i
          failures += element.attributes["failures"].to_i
          skipped  += element.attributes["skipped"].to_i
          tests    += element.attributes["tests"].to_i
          time     += element.attributes["time"].to_f
        end

        File.delete("#{folder}/#{xml_file}")

      end

      # Write the final merged results.xml
      results = File.new("#{output}", "w")
      results.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
      results.write("<testsuite errors=\"#{errors}\" failures=\"#{failures}\" skipped=\"#{skipped}\" tests=\"#{tests}\" time=\"#{time}\">\n")
      results.write("  <properties/>\n")
      cases.each { |tc| results.write("  #{tc}\n") }
      results.write("</testsuite>")
      results.close

    end

    def self.basic_merge

      output       = @args[@args.index("--out")+1]
      path_defined = output.rindex("/")
      folder       = path_defined.nil? ? "." : output[0...(output.rindex("/"))]
      file         = path_defined.nil? ? output : output[(output.rindex("/"))+1..output.length]

      generic_files = []
      Dir.entries(folder).each do |element|
        generic_files << element if element.start_with?(file)
      end

      File.open("#{output}","w"){|f|f.puts generic_files.map{|nm|IO.read nm}}
      generic_files.each{|f|File.delete(f) if f != output}

    end

  end
end