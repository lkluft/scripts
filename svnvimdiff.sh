#!/bin/sh
# https://evilshit.wordpress.com/2013/09/03/how-to-make-diffs-of-svn-and-git-files-with-vimdiff/

# Configure your favorite diff program here.
DIFF="vim -d"

# Subversion provides the paths we need as the sixth and seventh parameters.
LEFT=${6}
RIGHT=${7}

# Call the diff command (change the following line to make sense for your merge
# program).
$DIFF $LEFT $RIGHT

# Return an errorcode of 0 if no differences were detected, 1 if some were.
# Any other errorcode will be treated as fatal.
