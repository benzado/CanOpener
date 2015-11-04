#
# can_opener.rb
# Copyright 2015 Benjamin Ragheb
#
# This file is part of CanOpener.
#
# CanOpener is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CanOpener is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CanOpener.  If not, see <http://www.gnu.org/licenses/>.
#

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
    when 'longURL'
        puts 'Use: appA'
        puts 'Use: appB'
        puts 'URL: http://example.com/' + ('lol' * 100)
    end
    exit 0
end
