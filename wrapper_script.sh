#!/bin/bash

set -m

# Start the first script that comes with gitlab image in background, as it never ends, it waits for all child process sigterm,
# We can not run our script after checking it's exit status.

/assets/wrapper &

# Start the second script now
/db_user_creation.sh

#Bring the first process to foreground
fg %1
