#!/usr/bin/env ruby
require 'tempfile'
require 'fileutils'

# Catch signals
trap("SIGINT") { exit }

# Setup
# BUILD_FOLDER = ARGV[0]
BUILD_FOLDER = File.absolute_path(ARGV[0])
SCRIPT_WORKING_DIR = File.dirname(__FILE__)

puts "SCRIPT_WORKING_DIR: #{SCRIPT_WORKING_DIR}"

if BUILD_FOLDER.nil?
  puts "Usage: #{$0} BUILD_FOLDER"
  exit
end

# Kill watcher that still running
puts "$PROGRAM_NAME : #{$PROGRAM_NAME}"
system("ps -ef | grep #{$PROGRAM_NAME} | grep -v grep | grep -v #{Process.pid} | awk '{print $2}' | xargs kill")


# NewFileWatcher class
class NewFileWatcher
  EXTENSIONS = %w( ipa apk )

  def initialize(path)
    @directory = path
    @org_file_list = build_file_list
    @callbacks = {}
  end

  def build_file_list
    list = EXTENSIONS.map do |ext|
      Dir[File.join(@directory, "**", "*.#{ext}")]
    end

    list.flatten!
    list.collect do |file|
      [file, File.stat(file).mtime.to_i]
    end
  end

  # Register callback to run on new file created
  def on_create(&block)
    @callbacks[:new_file_created] = block

    # @callbacks(:new_file_created) = block
  end

  # Start the watcher to keep checking
  def start
    puts "Watcher RUNNING------------------->"
    loop do
      unless (diff = build_file_list - @org_file_list).empty?
        # sleep 0.5
        diff.each do |meta|
          @callbacks[:new_file_created].call(meta[0])
        end
        exit
      end
      sleep 0.5
    end
  end
end

# RenameScript class
class RenameScript
  def initialize(content)
    @file = Tempfile.new('renameScript')
    @file.write(content)
    @file.close
    FileUtils.chmod(0755, @file.path)
 end

  def run(*args)
    system("sh #{@file.path} #{args.join(" ")}")
  end
end

NAME_PATTERN = '"$BUILD_NAME"_v"$VERSION_NUMBER"_"$DATE"_"$SHA"'

rename_script_content = <<-RENAMESCRIPT
#!/bin/sh

echo "Script start time--->"`date`

# config rename pattern
echo "current path:"`pwd`
echo "SCRIPT_WORKING_DIR--->#{SCRIPT_WORKING_DIR}"

FILE_PATH="${1}"
echo "__FILE_PATH: $FILE_PATH"

if [ "${CONFIGURATION}" = "Release" ]; then
    echo "Is Release, perform action"
else
    echo "Not Release, cancel action"
    exit 0
fi

CONFIGURATION="${CONFIGURATION}"
FILE_NAME=$(basename "$FILE_PATH")
FILE_EXT="${FILE_NAME##*.}"
DIR="$(dirname "$FILE_PATH")"

echo "New file detected------------->"
echo "CONFIGURATION: $CONFIGURATION"
echo "FILE_PATH: $FILE_PATH"
echo "FILE_NAME: $FILE_NAME"
echo "FILE_EXT: $FILE_EXT"
echo "DIR: $DIR"

# enviroment variables
export BUILD_NAME=$PRODUCT_NAME
export VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${INFOPLIST_FILE}")
export BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}")

#working variables
export DATE=`date +%Y%m%d.%H%M`
export SHA=`echo $(git rev-parse HEAD) | cut -c 1-7`
echo "SHA: $SHA"

# NEW_FILE_NAME="$BUILD_NAME"_v"$VERSION_NUMBER"_"$DATE"_"$SHA"
# NEW_FILE_NAME=#{NAME_PATTERN}

# config rename pattern
. "#{SCRIPT_WORKING_DIR}/name.conf"

NEW_FILE_NAME="$RENAME_PATTERN"
NEW_FILE_NAME=${NEW_FILE_NAME// /_}
echo "NEW_FILE_NAME: $NEW_FILE_NAME"

echo "Going to change name..."
from="${FILE_PATH}"
to=$DIR/$NEW_FILE_NAME.$FILE_EXT

echo "from: ${from}"
echo "to: ${to}"

mv "${from}" "${to}"
echo "rename finished!"

NEW_FILE_DIR=$(dirname "${to}")
echo "NEW_FILE_DIR: $NEW_FILE_DIR"
open "$NEW_FILE_DIR"

echo "rename script finished!------------------------------<<<"
RENAMESCRIPT

# Execute watcher
newFileWatcher = NewFileWatcher.new(BUILD_FOLDER)
renameScript = RenameScript.new(rename_script_content)

newFileWatcher.on_create do |path|
  puts "detected path---> #{path}"
  renameScript.run("\"#{path}\"")
end

newFileWatcher.start
