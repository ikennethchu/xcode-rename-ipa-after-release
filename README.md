# xcode-rename-ipa-after-release
This is a ruby script keep watching the build folder and rename the ipa file with application info.

You may config the name by change name.conf

# Usage:

* Xcode -> Build Phases -> add Run Script -> add the following command in the script box
* ./script/rename_watcher.rb BUILD_FOLDER >> LOG_PATH 2>&1 &
* e.g: ./script/rename_watcher.rb ./build >> ./script/rename.log 2>&1 &
