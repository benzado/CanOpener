require 'socket'

# Don't buffer output; keeps STDOUT and STDERR in sync.
$stdout.sync = true; $stdout.flush
$stderr.sync = true; $stderr.flush

URL = ENV['URL']
FROM_APP = ENV['FROM_APP']
AVAILABLE_APPS = ENV['AVAILABLE_APPS'].split(/:/) rescue []
RUNNING_APPS = ENV['RUNNING_APPS'].split(/:/) rescue []

class App
    def initialize(bundle_id)
        @bundle_id = bundle_id
    end

    def available?
        AVAILABLE_APPS.include? @bundle_id
    end

    def running?
        RUNNING_APPS.include? @bundle_id
    end

    def use
        $stdout.puts "Use: #{@bundle_id}"
    end

    def to_s
        @bundle_id
    end
end

# Well-known Browsers
Chrome = App.new('com.google.Chrome')
Safari = App.new('com.apple.Safari')
TorBrowser = App.new('org.mozilla.tor browser')
VLC = App.new('org.videolan.vlc')
# TODO: Firefox
# TODO: OmniWeb
# TODO: Opera

# Test Suite
%r{^http://example\.com/(.+)$}.match(URL) do |m|
    $stderr.puts "Test Routines Activated"

    $stderr.puts "ARGV:"
    ARGV.each { |arg| $stderr.puts "- #{arg}" }
    
    $stderr.puts "ENV:"
    ENV.each { |name, value| $stderr.puts "- #{name}=#{value}" }

    case m[1]
    when 'exitCode' then exit 1
    when 'noUse' then exit 0
    when 'unknownApp' then puts 'Use: unknownApp'
    when 'invalidURL' then puts 'URL: not a valid URL'
    when 'availableApps'
        AVAILABLE_APPS.each { |app| $stdout.puts "Use: #{app}" }
    when 'runningApps'
        RUNNING_APPS.each { |app| $stdout.puts "Use: #{app}" }
    end
    exit 0
end
