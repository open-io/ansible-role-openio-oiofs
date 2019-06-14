#! /usr/bin/env bats

# Variable SUT_ID should be set outside this script and should contain the ID
# number of the System Under Test.

# Tests
@test 'Path is mounted' {
  run bash -c "docker exec -ti ${SUT_ID} df -h"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ "/mnt1/oiofs-OPENIO-travis_project-travis_container" ]]
}

@test 'gridinit resource is UP' {
  run bash -c "docker exec -ti ${SUT_ID} gridinit_cmd status OPENIO-oiofs-OPENIO-travis_project-travis_container"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ "UP" ]]
}  

@test 'put a file into the volume' {
  run bash -c "docker exec -ti ${SUT_ID} cp /etc/machine-id /mnt1/oiofs-OPENIO-travis_project-travis_container/"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
}


@test 'Object is present on SDS' {
  sleep 1
  run bash -c "docker exec -ti ${SUT_ID} openio account show travis_project --oio-ns OPENIO -c objects -f json"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ '[{"Field": "objects", "Value": 1}]' ]] || [[ "${output}" =~ '"objects": 1' ]]
}

@test 'delete the file' {
  run bash -c "docker exec -ti ${SUT_ID} rm -f /mnt1/oiofs-OPENIO-travis_project-travis_container/machine-id"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
}


@test 'Object is absent on SDS' {
  sleep 1
  run bash -c "docker exec -ti ${SUT_ID} openio account show travis_project --oio-ns OPENIO -c objects -f json"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ '[{"Field": "objects", "Value": 0}]' ]] || [[ "${output}" =~ '"objects": 0' ]]
}
