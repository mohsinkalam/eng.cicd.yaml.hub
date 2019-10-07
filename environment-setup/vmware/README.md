# Prerequisites
Powershell must be installed and use it to run this script
This script was tested on Linux and Windows and theoretically it can work on Mac

# What does the script do?
It checks if the specified machine exists in VCenter or not.

# If the machine exists
It checks if it is running or not and power it on if it isn't running.

# If the machine doesn't exist
It creates a new machine with the same name ( cloned it from the specified template ). 
Then power it on and wait until it gets an IP address

# Sample execution
 .\check-create-machine.ps1 -VMWareUser XXXXXXX -VMWarePassword XXXXXX -VMWareServ
er 10.190.162.130 -MachineName Test_machine -EnvFolderName QA -ProjectFolderName "Xinet-Server" -Netwo
rkName "vxw-dvs-19-universalwire-543-sid-10454-NorthplainsDev-DMZ-10.26.52.0-24" -TemplateName "CentOS7-Template" -Clust
erName "Cons01-Dev01" -DatastoreClusterName "Datastore-Dev-Magnetic"
