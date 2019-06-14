# Docker test environment

1. Fetch the test branch: `git fetch origin docker-tests`
2. Create a Git worktree for the test code: `git worktree add docker-tests docker-tests`. This will create a directory `docker-tests/`
3. The script `docker-tests.sh` will create a Docker container, and apply this role from a playbook `<test.yml>`. The Docker images are configured for testing Ansible roles and are published at <https://hub.docker.com/r/bertvv/ansible-testing/>. There are images available for several distributions and versions. The distribution and version should be specified outside the script using environment variables:

    ```
    export IPVAGRANT=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    docker run -d openio/sds
    export SDS_DOCKER_ID=$(docker ps -aq)
    while ! docker exec -ti ${SDS_DOCKER_ID} openio container create travis_container --oio-ns OPENIO --oio-account travis_project; do sleep 1; done
    curl https://github.com/open-io/ansible-role-openio-gridinit/blob/master/library/gridinitcmd.py --create-dirs -o library/gridinitcmd.py
    ```
    ```
    USR=xxx PASS=yyy ANSIBLE_VERSION=2.5 DISTRIBUTION=centos VERSION=7  ./docker-tests/docker-tests.sh
    USR=xxx PASS=yyy ANSIBLE_VERSION=2.5 DISTRIBUTION=ubuntu VERSION=16.04  ./docker-tests/docker-tests.sh
		SUT_ID=$(docker ps -qa | head -n 1) ./docker-tests/functional-tests.sh
    ```

    The specific combinations of distributions and versions that are supported by this role are specified in `.travis.yml`.
