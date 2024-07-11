#!/bin/bash

# Add timestamp at the beginning of each logged line
echo_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> log.txt
}

trap cleanup SIGINT

# Cleanup on script termination in case user wants to terminate the script abruptly (CTRL+C).
cleanup() {
    echo_log "Script terminated."
    echo "Script terminated."
    exit 1
}

# Clear the log file at the beginning
echo "" > log.txt


# Part to handle user input and process files with various checks as well for the respective files
files=()
while :; do
    read -r -p "Please input the name of a file to be analyzed (or press Enter to finish): " file
    if [ -z "$file" ]; then
        break
    fi
    if [[ " ${files[*]} " == *" $file "* ]]; then
        echo "File $file has already been given as input, input something else or press Enter to end."
        continue
    fi
    if [[ "$file" != *.csv ]]; then
        echo "File $file does not have a .csv extension. Please provide a .csv file."
        continue
    fi
    if [ ! -f "$file" ]; then
        echo "File $file does not exist. Please try again."
        continue
    fi
    lines=$(wc -l < "$file")
    if [ "$lines" -le 30 ]; then
        echo "File $file has insufficient entries. Please provide a different file or adjust the current one to have at least 30 rows and try again."
        continue
    fi
    files+=("$file")
done

num_files=${#files[@]}
if [ "$num_files" -lt 2 ]; then
    echo "Please provide at least two files to proceed."
    exit 1
fi

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo_log "File $file not found/ does not exist."
        echo "Please input the name of an existing file."
        continue
    fi

#Beautify the log so differemt files can be seen easier
    echo_log "
///////////////////////////////////////////////////////
Processing $file
///////////////////////////////////////////////////////
"

    start=$((RANDOM % (lines - 29) + 1)) # selects a random number, makes sure there ar at least 29 left and starts with the next line
    data=$(awk "NR >= $start && NR < $start + 30" "$file")

    mapfile -t prices < <(echo "$data" | awk -F, '{print $3}')
    mapfile -t timestamps < <(echo "$data" | awk -F, '{print $2}')
    mapfile -t stock_ids < <(echo "$data" | awk -F, '{print $1}')

# Calculate Average
    total=0
    count=${#prices[@]}
    for value in "${prices[@]}"; do
        total=$(awk -v total="$total" -v value="$value" 'BEGIN {print total + value}')
    done
    average=$(awk -v total="$total" -v count="$count" 'BEGIN {print total / count}')

# Standard deviation calculation - SUM of sqrt{[Stock price - the average)^2]/number of entries}
    total=0
    for value in "${prices[@]}"; do
        diff=$(awk -v value="$value" -v average="$average" 'BEGIN {print value - average}')
        sq_diff=$(awk -v diff="$diff" 'BEGIN {print diff * diff}')
        total=$(awk -v total="$total" -v sq_diff="$sq_diff" 'BEGIN {print total + sq_diff}')
    done
    stddev=$(awk -v total="$total" -v count="$count" 'BEGIN {print sqrt(total / count)}')

    echo_log "Start line: $start"
    echo_log "Average: $average"
    echo_log "Standard Deviation: $stddev"

# Get the outlier definition -> average + 2 * stddev + average for top threshold OR 2 * stddev - average for bottom one
    threshold=$(awk -v stddev="$stddev" 'BEGIN {print 2 * stddev}')
    top_threshold=$(awk -v average="$average" -v threshold="$threshold" 'BEGIN {print average + threshold}')
    bottom_threshold=$(awk -v average="$average" -v threshold="$threshold" 'BEGIN {print average - threshold}')

# Log the threshold values
    echo_log "Top Threshold: $top_threshold"
    echo_log "Bottom Threshold: $bottom_threshold"
    echo_log "find_outliers: average=$average, stddev=$stddev, threshold=$threshold, top_threshold=$top_threshold, bottom_threshold=$bottom_threshold"

    outlier_count=0
    outlier_lines=""

# Creates the csv file prefix based on the file that was given as input
    csv_file="${file%.csv}_outliers.csv"
    echo "Stock-ID,Timestamp,Actual Price,Mean,Deviation,% Deviation" > "$csv_file"


# Goes through all stock prices and checks for outliers based on the top/ bot thresholds. If outliers are detected
# , then it logs the info and appends them in their respective files. Begins counting the number of outliers
for i in "${!prices[@]}"; do
    value="${prices[$i]}"
    deviation=$(awk -v value="$value" -v average="$average" 'BEGIN {print value - average}')
    abs_deviation=$(awk -v deviation="$deviation" 'BEGIN {if (deviation < 0) {print -deviation} else {print deviation}}')
    percent_deviation=$(awk -v abs_deviation="$abs_deviation" -v average="$average" 'BEGIN {print (abs_deviation / average) * 100}')
    if (( $(awk -v value="$value" -v top_threshold="$top_threshold" -v bottom_threshold="$bottom_threshold" 'BEGIN {print (value > top_threshold || value < bottom_threshold)}') )); then
        echo_log "Outlier found: Value=$value, Deviation=$deviation, % Deviation=$percent_deviation"
        outlier_lines+="${stock_ids[$i]},${timestamps[$i]},${prices[$i]},$average,$deviation,$percent_deviation\n"
        echo "${stock_ids[$i]},${timestamps[$i]},${prices[$i]},$average,$deviation,$percent_deviation" >> "$csv_file"
        ((outlier_count++))
    fi
done


# If 0 outliers counted above, logs below message, else it will log in the log.txt
    if [ $outlier_count -eq 0 ]; then
        echo_log "No outliers found in $file."
    else
        echo -e "$outlier_lines" | while IFS= read -r line; do
            echo_log "Outlier data: $line"
        done
    fi


# Beautify so we can see the end of a processed file in the log.txt file
    echo_log "Total outliers found in $file: $outlier_count"
    echo_log "
///////////////////////////////////////////////////////
Finished processing $file
///////////////////////////////////////////////////////
"
done



# Print outliers on screen based on the log.txt file
grep -E 'Processing|Outlier found' log.txt | awk '
/Processing/ {
    if (NR > 1) {
        if (outliers > 0) {
            printf "\nOutliers: %d found in %s\n%s\n", outliers, file, outlier_lines
        } else {
            printf "\nNo outliers found in file: %s\n", file
        }
    }
    file = $2
    sub(/^Processing /, "", file)
    outliers = 0
    outlier_lines = ""
}
/Outlier found/ {
    outliers++
    outlier_lines = outlier_lines "\n" $0
}
END {
    if (outliers > 0) {
        printf "\nOutliers: %d found in %s\n%s\n", outliers, file, outlier_lines
    } else {
        printf "\nNo outliers found in file: %s\n", file
    }
}'
