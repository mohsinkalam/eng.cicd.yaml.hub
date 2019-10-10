Code migration
One YAML one repo
Map legacy repos to C4 components first

## Merge git repositories

We have a script that can merge several git repositories into one Trilogy GitHub repository.

Method is described in this post - https://saintgimp.org/2013/01/22/merging-two-git-repositories-into-one-repository-without-losing-file-history/ 

### Prerequsites

1. Empty repository where merge result will be committed. It is important to have it empty, otherwise it will lead to unpredictable results because it merges content of each repository to the repository root.

2. Config file file with repositories and appropriate folders, so on each line we should have "git url" (ssh, not http) and "folder" to move code divided by **space**. Don't forget to put empty line to the end of the file! Example:

```
git@github.com:trilogy-group/slisys-beacon-assets.git slisys-beacon-assets
git@github.com:trilogy-group/slisys-beacon-server.git slisys-beacon-server

```

### Run 

```
./merge-git-repos.sh git@github.com:trilogy-group/your-new-repo.git /path/to/config/file
```
