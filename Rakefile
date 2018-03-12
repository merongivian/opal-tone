require 'bundler'
Bundler.require
Bundler::GemHelper.install_tasks

require 'open-uri'

desc 'update js dependencies'
task :update_js do
  js_lib_url = 'https://tonejs.github.io/build/Tone.js'
  js_lib_dest = File.join(File.dirname(__FILE__), './opal/vendor/tone.js')
  open(js_lib_url) do |f|
    File.write(js_lib_dest, f.readlines.join)
  end
end
