#!/bin/bash

SPRITESHEET_DIR=$PWD/resources/spritesheets
OUTPUT_DIR=./output
OUTPUT_DIR_FINAL=./output_final
types=( male adult )

all_type=(child female male muscular pregnant skeleton teen zombie adult)
ignored_types=(child female muscular pregnant skeleton teen zombie thin cape)

exceptions=(beards cape neck torso shield thin muscular)

init() {
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    rm -rf "$OUTPUT_DIR_FINAL"
    mkdir -p "$OUTPUT_DIR_FINAL"
}

main() {
    init
    find "$SPRITESHEET_DIR" -type d   \( -exec sh -c 'find "$1" -mindepth 1 -maxdepth 1 -type d -print0 | grep -cz "^" >/dev/null 2>&1' _ {} \; -o -print \) | while read -r folder
    do
        move_file "$folder"
    done
    cleanup_output
    create_final_dir
}

cleanup_output() {
    find "$OUTPUT_DIR" -type d -mindepth 2 -exec bash -c "echo -ne '{} '; find '{}' -type f | wc -l" \; | awk '$NF==1{print $1}' | while read  -r folder
    do
        local only_file=$(ls "$folder")
        if [[ $only_file == *".png" ]]; then
            mv "$folder/$only_file" "${folder}_$only_file"
            rm -rf "$folder"
        fi
    done
}

move_file() {
    folder=$1
    file_path=${folder/$SPRITESHEET_DIR\//}

    for type in "${ignored_types[@]}"; do
        if [[ "$file_path" == *"/$type"* ]]; then
            return
        fi
    done

    files_count=$(ls -l "$folder" | wc -l)
    if [ "$files_count" = "2" ]; then
        file=$folder/$(ls "$folder")
    elif [ -f "$folder/white.png" ]; then
        file=$folder/white.png
    elif [ -f "$folder/fur_white.png" ]; then 
        file=$folder/fur_white.png
    elif [ -f "$folder/silver.png" ]; then 
        file=$folder/silver.png
    elif [ -f "$folder/steel.png" ]; then 
        file=$folder/steel.png
    elif [ -f "$folder/gray.png" ]; then 
        file=$folder/gray.png
    elif [ -f "$folder/ashplatinum.png" ]; then 
        file=$folder/ashplatinum.png
    elif [ -f "$folder/white_white.png" ]; then 
        file=$folder/white_white.png
    elif [ -f "$folder/white_silver.png" ]; then 
        file=$folder/white_silver.png
    else
        >&2 echo "error: $folder"
        return
    fi

    file_path=${file_path}/white.png

    new_file_path=$OUTPUT_DIR/$file_path
    new_file_path=${new_file_path/\/male/}
    new_file_path=${new_file_path/\/universal/}
    new_file_path=${new_file_path/\/adult/}
    new_file_path=${new_file_path/\/thin/}
    new_file_path=${new_file_path/behind/bg}
    new_file_path=${new_file_path/background/bg}
    new_file_path=${new_file_path/foreground/fg}
    new_file_path=$(dirname "$new_file_path").png
    base_folder="$(dirname "$new_file_path")"
    # if [ ! -d "$base_folder" ]; then
        mkdir -p "$base_folder"
        cp "$file" "$new_file_path"
    # fi
}

create_final_dir() {
    # physical
    move_to_final_dir body body
    move_to_final_dir head/heads head
    move_to_final_dir hair hair
    move_to_final_dir beards/beard beards

    # equipment
    move_to_final_dir cape cape
    move_to_final_dir feet feet
    move_to_final_dir torso torso
    move_to_final_dir torso/armour torso
    move_to_final_dir torso/clothes torso
    move_to_final_dir torso/jacket torso
    move_to_final_dir legs legs
    move_to_final_dir hat/helmet hat

}

move_to_final_dir() {
    mkdir -p "$OUTPUT_DIR_FINAL/$2"
    mv $OUTPUT_DIR/$1/*.png "$OUTPUT_DIR_FINAL/$2"
}

main