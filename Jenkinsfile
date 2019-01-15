pipeline {
  agent any
  environment {
    PYTHONUNBUFFERED = '1'
    ANSIBLE_FORCE_COLOR = 'true'
    ANSIBLE_VERSION = '2.5.9'
    SLACK_NOTIFY = true
    SLACK_ROOM = '#github'
    OS_TESTED = 'centos7 xenial bionic'
    DESTROY_INSTANCE = true
    OS_TENANT = 'openioci'
    OS_FLAVOR = 'c2.m2'
  }
  stages {
    stage('Python virtualenv') {
      // prepare python environment
      steps {
        sh '''# Virtualenv
            rm -rf venv
            virtualenv venv
            . ./venv/bin/activate
            pip install --upgrade pip
            pip install \'ansible==\'${ANSIBLE_VERSION}
            #pip install openstacksdk
            #pip install shade
            pip install yamllint
            pip install ansible-lint'''
      }
    }
    stage('Prepare VM request for openstack') {
      environment {
        GITHUB_TOKEN = credentials('TokenGithub')
      }
      steps {
        sh "git clone https://${GITHUB_TOKEN}@github.com/open-io/ansible-playbook-openstack-instances.git plays/os_instances"
        withCredentials([usernamePassword(credentialsId: 'ID_OPENSTACK', usernameVariable: 'os_user', passwordVariable: 'os_pass')]) {
          sh '''
          cat << EOF > plays/os_instances/.openstackrc
export OS_USERNAME=${os_user}
export OS_PASSWORD=${os_pass}
export OS_AUTH_URL="http://192.168.1.99:5000/v2.0/"
export OS_TENANT_NAME="${OS_TENANT}"
export OS_KEYNAME="jenkins"
EOF
            '''
        }
        script {
          INSTANCES_BASENAME = sh(returnStdout: true, script: "date +%s | sha256sum | base64 | head -c 8")
          /* If you don't use container, prefer spawn a specific OS instead of centos7
          Use : ${INSTANCES_BASENAME}_\${i}_01 image=\${i} disks="{'rootvol': 11}" flavor=${OS_FLAVOR} */
          sh """
          for i in ${OS_TESTED}; do cat << EOF > plays/os_instances/inventory_\${i}.ini
[openioci]
${INSTANCES_BASENAME}_\${i}_01 image=centos7 disks="{'rootvol': 11}" flavor=${OS_FLAVOR}
EOF
done
          """
        }
      }
    }
  }
  post {
    always {
      // delete instances
      dir("plays/os_instances") {
        sh """
        . ${WORKSPACE}/venv/bin/activate > /dev/null 2>&1
        . ${WORKSPACE}/plays/os_instances/.openstackrc > /dev/null 2>&1

        for i in ${OS_TESTED}; do
          ./instances.play -i inventory_\${i}.ini -e 'status=absent'
        done
        """
      }
      // delete workspace
      cleanWs()
    }
    failure {
      script {
          if (params.SLACK_NOTIFY == true) {
          slackSend(channel: "${SLACK_ROOM}", color: '#AA0000', message: "Build ${env.BUILD_NUMBER} of ${env.JOB_NAME} ${currentBuild.result} (<${env.BUILD_URL}|Open>)")
        }
      }
    }
    success {
      script {
        if (params.SLACK_NOTIFY == true) {
          slackSend (channel: "${SLACK_ROOM}", color: '#008800', message: "Build Success - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) is ${currentBuild.result}.")
        }
      }
    }
  }
}
