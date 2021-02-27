#!/bin/bash

date -u

current_downloads_dir=${current_downloads_dir}
complete_downloads_dir=${complete_downloads_dir}
movies_dir=${movies_dir}
tv_dir=${tv_dir}
holding_file=${holding_file}

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

required_arguments=($current_downloads_dir $complete_downloads_dir $movies_dir $tv_dir)

for argument in ${required_arguments[@]} ; do
    if [ ! -d $argument ]; then
        echo "directory does not exist: '$argument'"
        exit 1
    fi
done

completed_downloads_count=`find $complete_downloads_dir -mindepth 1 -maxdepth 1 -type d | wc -l`

if [ $completed_downloads_count -gt 0 ] ; then # if the number of directories in the completed downloads directory
    for completed_download in `find $complete_downloads_dir -mindepth 1 -maxdepth 1 -type d` ; do # foreach directory in the completed downlaods directory
        completed_download_name=`basename $completed_download` # get download name

        if [ -f "$holding_file"]; then # if holding file exists
            if grep -q "$completed_download_name" "$holding_file"; then # if the holding file contains the download name
                echo "skipping $completed_download_name as it is already being moved by another process" # echo
                continue # skip the current download
            fi
        fi

        directory_download_would_be_in_if_it_was_still_downloading=$(printf %q "$current_downloads_dir/$completed_download_name") # 
        # echo $downloading_folder
        if [ ! -d $directory_download_would_be_in_if_it_was_still_downloading ] ; then # if the directory the download would be in if it was still downloading dow not exist
            if [ `ls -R $completed_download | grep -E '[sS][0-9]{1,2}?[eE][0-9]{1,2}' | wc -l` -gt 0 ]; then # if the download contains files that follow the tv show naming convention
                destination_dir=$tv_dir # destination directory is tv directory
            else
                destination_dir=$movies_dir # destination directory is movies directory
            fi
        else
            echo "Skipping '$completed_download' as it is still being copied from '$current_downloads_dir' to '$complete_downloads_dir'" # echo
            continue # skip download
        fi


        directory_download_should_move_to=$(printf %q $destination_dir/$completed_download_name) # directory for download to be moved to
        if [ -d $directory_download_should_move_to ]; then # if a directory for the download already exists 
            completed_download_dir_file_count=`find $completed_download -type f | wc -l` # number of files in the completed download directory
            destination_dir_file_count=`find $directory_download_should_move_to -type f | wc -l` # number of directories in the directory the download will move to

            echo "$completed_download : $completed_download_dir_file_count $destination_dir_file_count" # echo
            if [ $completed_download_dir_file_count -gt 0 ] && [ $destination_dir_file_count == 0 ] ; then # if the directory the download should move to contains no files but the completed download dir does
                rm -rf $directory_download_should_move_to # delete the directory the download should move to
                echo "deleted '$directory_download_should_move_to'"
            elif [ $completed_download_dir_file_count == 0 ] && [ $destination_dir_file_count -gt 0 ] ; then # if the directory the download should move to contains files but the completed download dir does not
                rm -rf $complete_downloads_dir # delete the completed download directory
                echo "deleted '$complete_downloads_dir'"
                continue
            else
                echo "manual intervention required for $completed_download_name"
                continue
            fi
        fi

        echo "$completed_download_name" >> $holding_file # append download name to holding file
        escaped_completed_download_name=$(printf %q "$completed_download_name") # format download name for regex usage
        mv $completed_download $destination_dir # move download to desired destination
        sed -i "/^$completed_download_name$/d" $holding_file # delete download name from holding file

        echo "moved '$completed_download' to '$destination_dir'"
    done
else
    echo "No completed downloads to process"
    exit 0
fi


