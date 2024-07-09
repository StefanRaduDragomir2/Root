Backend – Identify outliers of timeseries data (Stock price)



Introduction
The code is written in Bash/ Shell and requires user input to run. Its purpose is to determine the Outliers from certain CSV files based on average and standard deviation.

Presentation
Prerequisites
	- Ensure the .csv files are in the same working directory as the script
	- Ensure the csv files are properly formatted beforehand
	- Make sure the file(s) have the proper permissions to be read/ executed


Execution:
- Execute the script: “./script.sh
- Input the files which you want to process
- Press “Enter” if the necessary number of files has been reached
- Assuming everything is successful, the script will print onscreen the number 	of outliers found (can be 0), data regarding each outlier and where it was 	found.
- The script will output a series of files at the end, a log.txt file containing data and for each processed file, there will be a Filename_outliers.csv file.

Features:

- Allow the user to input any number of CSV files
- Checks for duplicate files. If a file has already been added to the array, it will 	notify the user. (Help text printed)
- Checks the file to make sure it is a .csv file (Help text printed)
- Checks the file to make sure it exists (Help text printed)
- Checks the file to have at least 30 entries (Help text printed)
- Requires at least 2 files to proceed with execution (Help text printed)
- Cleanup in case user terminates the script abruptly (CTRL+C)


Sources


https://www.khanacademy.org/math/statistics-probability/summarizing-quantitative-data/variance-standard-deviation-population/a/calculating-standard-deviation-step-by-step
https://www.tutorialspoint.com/execute_bash_online.php
https://www.shellcheck.net/
https://www.linode.com/docs/guides/solving-real-world-problems-with-bash-scripts-a-tutorial/
https://linuxconfig.org/calculate-column-average-using-bash-shell


