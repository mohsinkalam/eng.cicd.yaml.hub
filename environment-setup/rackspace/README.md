
### What does the script do?
It's a shell scripts that setups instance in rackspace with given parameters

##### If the machine exists
It checks if it is running or not and power it on if it isn't running.

##### If the machine doesn't exist
It creates a new machine with specified parameters. 
Then power it on, assign DNS and wait for until statuses are OK.

##### Sample execution
.\rackspace.sh -c XXXXXX -d XXXXXX -k XXXXX


Run .\rackspace.sh -h to see help
