# getting-started
This repo includes scripts and associated resources to help install Amplify Security. 
Amplify Security installs into your project repo as a two step
process. First, access to the repo should be given
to the Amplify Security GitHub App. This is usually done when
you install the GitHub App into your organization or user. Second,
the Amplify Secure Pipeline GitHub Action must be configured
in the repo. This is done by committing the amplify.yml file contained in this 
repo to `.github/workflows/amplify.yml`. This repo also contains an install script that 
automates the second part of the installation process for multiple repos at a time.

## Using the Install Script
The install script install_amplify.sh automates committing the GitHub Action to 
multiple repos at a time. The script relies on a configuration file, `config.json`, to know
which repos it should install the Amplify Secure Pipeline GitHub Action into.
An example configuration file is provided at `example_config.json`. You may manually
configure the script if you like, but the recommended way to use the script is to have
the Amplify Security Platform generate a dynamically configured install package.
This can be done from the Projects page of our application.

### Requirements
The script requires the following in order to run successfully:
- The package `jq`
- The ability to clone your git repos without a password (usually this is done via SSH keys)

### Usage
To run the script, extract the zip package and execute the install script with your GitHub organization name:
```
unzip install_amplify.zip
./install_amplify.sh amplify-security
```

### What it does
The install script will clone each configured
repository locally, checkout or create any
configured feature branch, commit the Amplify
Secure Pipeline GitHub Action, and push the
commit.

## A note about Branch Protection
Many repos in GitHub that you will want to install Amplify Security in will have
branch protection enabled. This means that
our install script cannot push the Amplify Secure
Pipeline Action directly to your trunk (`master` or `main`). In this case, the Amplify Security Platform will push the install commit to
a configurable feature branch. To finalize
the installation you will need to open a PR to merge the commit to trunk.

## Configuration
The configuration file is a JSON array of repos that the install script will install
Amplify in. Each entry in the array should contain the following config options:
| Config Option | Description |
| ------------- | ----------- |
| `repo` | GitHub repo name |
| `file_dest` | Destination of the installed GitHub Action file |
| `action` | GitHub Action file to install |
| `commit_message` | Commit message of Action file install |
| `branch` | Optional feature branch name for commit |