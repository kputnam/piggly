#!/usr/bin/env ruby
STDOUT.sync = true
newest = Time.now - 3600 * 12

# TODO: re-run any failed tests
while sleep 2 do
  specs   = Dir['spec/**/*_spec.rb']
  changes = Dir['lib/piggly/**/*.*'].concat(specs).select{|f| File.mtime(f) > newest }
  changes -= %w(lib/piggly/parser/parser.rb)
  
  unless changes.empty?
    newest = changes.map{|f| File.mtime(f) }.max
    rerun  = changes.select{|f| specs.include? f }
    
    # run all of the specs if the only files that changed were not specs
    rerun  = specs if rerun.empty?
    
    $stdout.puts "Changes:\n  " + rerun.join("\n  ")
    $stdout.write "Forking spec..."

    if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
      STDOUT.reopen('spec.html')
      Process.waitpid (spawn 'ruby', '-I', 'spec', '-S', 'rspec', '-fh', *rerun)

      STDERR.reopen(File::NULL)
      STDOUT.reopen(File::NULL)
      Process.waitpid(spawn 'explorer', 'spec.html')
    else
      Process.waitpid(spawn do
        STDOUT.reopen('spec.html')
        exec 'ruby', '-I', 'spec', '-S', 'rspec', '-fh', *rerun
      end)

      Process.waitpid(spawn do
        STDERR.reopen('/dev/null')
        STDOUT.reopen('/dev/null')
       #exec "opera", "-noraise", "-activetab", "spec.html" }
        exec "open", "spec.html"
      end)
    end

    $stdout.puts "done"
  end
end
