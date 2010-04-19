dir = File.dirname(__FILE__)

Dir["#{dir}/**/*_spec.rb"].each do |spec|
  require spec
end
