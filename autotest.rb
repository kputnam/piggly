#!/usr/bin/env ruby
STDOUT.sync = true
newest = Time.now - 3600 * 12

# TODO: re-run any failed tests
while sleep 2 do
  specs   = Dir['spec/**/*_spec.rb']
  changes = Dir['lib/piggly/**/*.*'].concat(specs).select{|f| File.mtime(f) > newest }
  
  unless changes.empty?
    newest = changes.map{|f| File.mtime(f) }.max
    rerun  = changes.select{|f| specs.include? f }
    rerun  = specs if rerun.empty?
    STDOUT.write "Changes:\n -" + rerun.join("\n -") + "\nForking spec... "
    Process.waitpid fork{ exec 'spec', '-fh:spec.html', '-L', 'mtime', *rerun }
    Process.waitpid fork{ STDERR.reopen('/dev/null'); STDOUT.reopen('/dev/null');
                         #exec "opera", "-noraise", "-activetab", "spec.html" }
                          exec "open", "spec.html" }
    STDOUT.puts "done"
  end
end
