# webMethods DevOps sample framework

## Overview

This project is a framework that aims to implement both continuous integration and docker image creation for Integration Server (with Process Engine)

## Architecture

![Deployment architecture](/resources/img/architecture.png)

## Requirements

* Docker : engine 19.03.2 or above

* Jenkins : 2.190 or above with following plug-ins and dependencies

```
scm-api
git-client
git
blueocean
pipeline-utility-steps
pipeline-rest-api
ssh-credentials
jdk-tool
ws-cleanup
antisamy-markup-formatter
```

* webMethods installation : 10.5 or above

   * Integration Server (with MSR license) : this instance is used to create Docker base and package images
   * Integration Server (with IS license) : with Asset Build Environment and WmDeployer installed, this instance is used for build and deploy purpose

## Supported assets

The following assets can be deployed with this framework : 

* BPM : Process models
* IS : Integration server packages and configurations files (as supported by Asset Build environment)
* UM : Universal Messaging assets
* MWS : My webMethods server assets (Portlet, War...)

## Configuration

### Jenkins global configuration

Jenkins should be running with the same user as the webmethods components in order to avoid permission issues

Add the different credentials that will be used by the framework (Jenkins > Credentials > Add Credentials) : 

* Create a credential for the repository where the framework is located
* Create a credential for each asset repository (A single credential can be used, if authentication information is the same for the different repositories)

### Update Jenkinsfile

After check-in of the framework a on git repository, the following variables need to be updated in Jenkinsfile : 

```
def repoUtilsUrl = <GIT_REPOSITORY_URL>
def repoUtilsBranch = <GIT_BRANCH>
def repoUtilsCredential = <GIT_CREDENTIAL>
```

Where :

* GIT_REPSOITROY_URL : git repository url where the framework is located
* GIT_BRANCH : git repository branch to checkout
* GIT_CREDENTIAL : git credential ID as configured in the Jenkins instance

These information will be used to checkout and populate the parameters fields for the job by reading the properties files located in "parameters" folder.

### Update build.properties

In order to configure the environment update build.properties file located in "properties" folder. 

#### Workspace 

Define a CICD workspace root folder with the following properties

```
dir.workspace=<DIRECTORY_WS>
```

Jenkins pipeline will create automatically all subdirectories  : 

* source : source code checkout folder
* builds : composites repository folder (generated by Asset Build Environment)
* archive : archived build folder
* logs : build output logs folder

#### Git repositories 

Adding a git repository (containing assets to build) consists on updating the following properties : 

```
repo.url.<MODULE>=<GIT_REPOSITORY_URL>
repo.credential.<MODULE>=<GIT_CREDENTIAL>
dir.<MODULE>=<DIRECTORY_ASSET>
```

Where :

* GIT_REPSOITROY_URL : git repository url where the assets are located
* GIT_CREDENTIAL : git credential ID as configured in the Jenkins instance
* DIRECTORY_ASSET : assets checkout folder
* MODULE : Module name as defined in "parameters/module.properties" file

Folders structure can be updated according to your needs, for example :

```
## IS (packages and config directory)
dir.asset.is=esb
## BPM (Process models projects)
dir.asset.bpm=bpm
## UM (realm export)
dir.asset.um=um/UniversalMessaging
## MWS (CAF)
dir.asset.mws=mws
```

Which corresponds to an assets repository having the following structure

```
ROOT_FOLDER/
           esb
             /config
             /package1
             ...
             /packageN
           bpm
             /ProcessProject1
             ...
             /ProcessProjectN
           um
             /UniversalMessaging/reaml_export.xml
           mws
             /PortletProject1
             ...
             /PortletProjectN
```

#### Integration Server (Build) configuration

Update the following properties used to invoke Integration Server having Asset Build Environment and WmDeployer installed : 

```
dir.install.build=<SAG_INSTALL_DIR>
dir.install.deployer=<SAG_DEP_PATH>
deployer.host=<DEP_HOST>
deployer.port=<DEP_PORT>
deployer.user=<DEP_USER>
deployer.pwd=<DEP_PWD>
```

Where :

* SAG_INSTALL_DIR : root installation directory
* SAG_DEP_PATH : relative path to WmDeployer root directory (IntegrationServer/instances/<INSTACE>/packages/WmDeployer)
* DEP_HOST|PORT|USER|PWD : WmDeployer parameters

#### Target servers configuration

Update the following properties used to connect to the different components: 

```
target.alias.<COMPONENT>=<TARGET_ALIAS>
target.host.<COMPONENT>=<TARGET_HOST>
target.port.<COMPONENT>=<TARGET_PORT>
target.user.<COMPONENT>=<TARGET_USER>
target.pwd.<COMPONENT>=<TARGET_PWD>
target.version.<COMPONENT>=<TARGET_VERSION>
```

Where COMPONENT can have the following values : 


* is : Integration Server target
* bpm : Process Engine target
* um : Universal Messaging target
* mws : My webMethods server target

#### Docker image build configuration

Update properties used for Docker base and package image build : 

```
dir.install.run=<SAG_INSTALL_DIR>
docker.file.base=<DOCKER_BASE_FILE>
docker.file.package=<DOCKER_PAKCAGE_FILE>
```

Where :

* SAG_INSTALL_DIR : root installation directory used to create base, package images
* DOCKER_BASE_FILE : Base docker file name (must be created before job execution with is_container.sh script)
* DOCKER_PAKCAGE_FILE : Package docker file name (will be created and deleted during pipeline execution)

### Jenkins job 

Create a Jenkins job (New item > Pipeline) and under Pipeline define the following 

```
Definition : Pipeline script from SCM
Definition > SCM : git
Definition > SCM > Repositories > Repository URL : <GIT_REPOSITORY_URL>
Definition > SCM > Repositories > Credentials : <GIT_CREDENTIAL>
Definition > SCM > Branches to build : <GIT_BRANCH>
Definition > Script Path : <PATH_SCRIPT>
```
Where :

* GIT_REPSOITROY_URL : git repository url where the framework is located
* GIT_BRANCH : git repository branch to checkout
* GIT_CREDENTIAL : git credential ID as configured in the Jenkins instance
* PATH_SCRIPT : relative path to Jenkins file (e.g : build/Jenkinsfile)

## Running Jenkins job 

Run created job by providing inputs parameters :

* CREATE_BASE_IMAGE : create or not a base image (true|false)
* DOCKER_IMAGE_BASE : docker base image name
* CREATE_PACKAGE_IMAGE : create or not a package image (true|false)
* DOCKER_IMAGE_PACKAGE : docker package image name
* BUILD_VERSION : build version (will be appended to both base and package image name)
* MODULE : module to build (values defined in parameters/module.properties file)
* BRANCH : module branch to build (values defined in parameters/branches.properties file)
* ENABLE_IS_BUILD : Integration server build (true|false)
* ENABLE_BPM_BUILD : Process models build (true|false)
* ENABLE_MWS_BUILD : My webMethods Server build (true|false)
* ENABLE_UM_BUILD : Universal Messaging build (true|false)

## Pipeline workflow

![Pipeline workflow](/resources/img/workflow.png)

Depending on parameters provided as inputs, below stages will be executed :

1. Prepare workspace : always
2. Create IS base image : when CREATE_BASE_IMAGE = true
3. Checkout source code : any of ENABLE_xxx_BUILD = true
4. Build source code : any of ENABLE_xxx_BUILD = true
5. Deploy source code : any of ENABLE_xxx_BUILD = true
6. Create IS package image : CREATE_PACKAGE_IMAGE = true && (ENABLE_IS_BUILD = true || ENABLE_BPM_BUILD = true) 


_______________
DISCLAIMER
These tools are provided as-is and without warranty or support. Users are free to use, fork and modify them.