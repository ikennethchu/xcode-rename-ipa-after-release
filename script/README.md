Usage:

Xcode -> Build Phases -> add Run Script -> add the following command in the script box
./script/rename_watcher.rb BUILD_FOLDER >> LOG_PATH 2>&1 &
e.g:  ./script/rename_watcher.rb ./build >> ./script/rename.log 2>&1 &


