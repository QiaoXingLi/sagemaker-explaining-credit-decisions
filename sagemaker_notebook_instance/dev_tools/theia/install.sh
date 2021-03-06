#!/bin/bash
set -e

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
## INSTALL THEIA IDE FROM SOURCE
EC2_HOME=/home/ec2-user
mkdir ${EC2_HOME}/theia && cd ${EC2_HOME}/theia
### begin by installing NVM, NodeJS v10, and Yarn
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.5/install.sh | bash
source ${EC2_HOME}/.nvm/nvm.sh
nvm install 10
nvm use 10
npm install -g yarn
### now compile Theia-IDE from source, retrieving the configuration package.json from GitHub
export NODE_OPTIONS=--max_old_space_size=4096
cp $parent_path/package.json ${EC2_HOME}/theia/package.json
yarn &
### Configure Theia defaults
THEIA_PATH=$PATH
mkdir ${EC2_HOME}/.theia
mkdir -p ${EC2_HOME}/SageMaker/.theia
cp $parent_path/launch.json ${EC2_HOME}/SageMaker/.theia/launch.json
echo '{"workbench.iconTheme": "theia-file-icons","terminal.integrated.inheritEnv": true}' > ${EC2_HOME}/.theia/settings.json
## CONFIGURE JUPYTER PROXY TO MAP TO THE THEIA IDE
JUPYTER_ENV=/home/ec2-user/anaconda3/envs/JupyterSystemEnv
source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
cat >>${JUPYTER_ENV}/etc/jupyter/jupyter_notebook_config.py <<EOC
c.ServerProxy.servers = {
  'theia': {
    'command': ['yarn', '--cwd', '/home/ec2-user/theia', 'start', '/home/ec2-user/SageMaker', '--port', '{port}'],
    'environment': {'PATH': '${THEIA_PATH}'},
    'absolute_url': False,
    'timeout': 30
  }
}
EOC
pip install jupyter-server-proxy pylint autopep8
jupyter serverextension enable --py --sys-prefix jupyter_server_proxy
source deactivate