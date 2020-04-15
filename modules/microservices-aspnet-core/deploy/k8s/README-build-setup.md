# Azure Cloud Shell setup

1. Initial set up
2. Set up a build environment on the cloud

## 1. Initial set up

1. Fork the repo <https://github.com/dotnet-architecture/eShop-Learn> in your GitHub Account

2. Connect to the Azure Cloud Shell (bash) while logged in with your subscription on the Azure portal.

3. Clone your repo
  ```bash
  cd clouddrive
  mkdir source
  cd source
  git clone https://github.com/{your-github-account}/eShop-Learn.git
  ```

### 2. Set up a build environment on the cloud

This step is optional. You need this if you want to build and push your images from the Azure Cloud Shell. You can also do it on your local development machine, if you have Docker-CE installed.

To set up the build environment **on the cloud** you must perform these steps:

1. Create a Docker VM
2. Install docker-compose in the Azure Cloud Shell

#### 2.1 Create a Docker VM

Run the script:

```bash
./create-docker-vm.sh
```

**IMPORTANT:** You might get prompted to log in into your subscription from the browser with a message similar to this one:

```
Microsoft Azure: To sign in, use a web browser to open the page https://microsoft.com/devicelogin
and enter the code XXXXXXXXX to authenticate.
```

When the script finishes you should get a message similar to this:

```txt
Created VM "docker-vm-YYYYMMDDHHMMSS###".

Environment variables
---------------------
export ESHOP_IDTAG=YYYYMMDDHHMMSS###
export ESHOP_DOCKERVM=docker-vm-YYYYMMDDHHMMSS###
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://###.###.###.###:####"
export DOCKER_CERT_PATH="/home/xxxxxxx/.docker/machine/machines/docker-vm-YYYYMMDDHHMMSS###"
export DOCKER_MACHINE_NAME="docker-vm-YYYYMMDDHHMMSS###"

Run the following commands to update the environment
eval $(cat ../../../create-docker-vm-exports.txt)
source ~/.bashrc
```

Now run the following commands to update the environment variables and enable the Docker VM from the Azure Cloud Shell:

```bash
eval $(cat ../../../create-docker-vm-exports.txt)
source ~/.bashrc
```

#### 2.2 Install docker-compose

You have to install docker-compose in the the Azure Cloud Shell, to build the eShop-Learn images and publish to ACR.

Just run the following script:

```bash
./install-docker-compose.sh
```

When the script finishes you should get a message similar like this:

```txt
docker-compose installed.

run the following command to enable docker-compose in the PATH
source ~/.bashrc
```

Now run the command to enable docker-compose:

```bash
source ~/.bashrc
```


