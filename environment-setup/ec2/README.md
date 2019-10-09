
### What does the script do?
It's a shell scripts that setups ec2 instance with given parameters

##### If the machine exists
It checks if it is running or not and power it on if it isn't running.

##### If the machine doesn't exist
It creates a new machine with specified parameters. 
Then power it on, assign DNS and wait for until statuses are OK.

##### Sample execution
.\ec2.sh -c XXXXXX -d XXXXXX -k XXXXX


Run .\ec2.sh -h to see help
