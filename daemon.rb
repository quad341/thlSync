#!/usr/bin/ruby

# This script watches modifications on the Hit List directory looking for
# changes for the database

require 'osx/foundation'
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
include OSX
require 'set'
require 'optparse'
require 'ostruct'

#constants
PATH = "/Users/quad341/Library/Application Support/The Hit List/The Hit List Library.thllibrary"
KILLFILE = "/tmp/killthldaemon"

#initial variables
start_time = Time.now.to_i #current time in seconds for comparing to the kill time

#callback function from the watch
fsevents_cb = proc do  |stream, ctx, numEvents, paths, marks, eventIDs|
   paths.regard_as('*') #fixes encoding it seems
   numEvents.times do |n|
      puts paths[n]
   end
end
#ref: http://developer.apple.com/mac/library/documentation/Darwin/Reference/FSEvents_Ref/FSEvents_h/index.html#//apple_ref/c/func/FSEventStreamCreate
stream = FSEventStreamCreate(
  KCFAllocatorDefault,
  fsevents_cb,
  nil,
  [PATH],
  KFSEventStreamEventIdSinceNow,
  1.0, # latency, in seconds
  KFSEventStreamCreateFlagNoDefer)

die "Failed to create the FSEventStream" unless stream

FSEventStreamScheduleWithRunLoop(
  stream,
  CFRunLoopGetCurrent(),
  KCFRunLoopDefaultMode)

ok = FSEventStreamStart(stream)
die "Failed to start the FSEventStream" unless ok

while File.stat(KILLFILE).mtime.to_i < start_time do
   FSEventStreamFlushSync(stream)
   puts "waiting to die..."
   sleep 1
end

FSEventStreamStop(stream)
FSEventStreamInvalidate(stream)
FSEventStreamRelease(stream)

puts "it works dave"
