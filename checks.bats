#! /usr/bin/env bats

# Variable SUT_ID should be set outside this script and should contain the ID
# number of the System Under Test.

# Tests
@test 'Path is mounted' {
  run bash -c "docker exec -ti ${SUT_ID} df -h"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ "/mnt/oiofs-1/mnt" ]]
}

@test 'gridinit resource is UP' {
  run bash -c "docker exec -ti ${SUT_ID} gridinit_cmd status OPENIO-oiofs-mnt_oiofs_1_mnt"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ "UP" ]]
}  

@test 'put a file into the volume' {
  run bash -c "docker exec -ti ${SUT_ID} cp /etc/machine-id /mnt/oiofs-1/mnt"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
}


@test 'Object is present on SDS' {
  run bash -c "docker exec -ti ${SUT_ID} openio container show travis_container --oio-account travis_project --oio-ns OPENIO -c objects -f yaml"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ "Field: objects, Value: '1'" ]]
}

@test 'delete the file' {
  run bash -c "docker exec -ti ${SUT_ID} rm -f /mnt/oiofs-1/mnt/machine-id"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
}


@test 'Object is absent on SDS' {
  run bash -c "docker exec -ti ${SUT_ID} openio container show travis_container --oio-account travis_project --oio-ns OPENIO -c objects -f yaml"
  echo "output: "$output
  echo "status: "$status
  [[ "${status}" -eq "0" ]]
  [[ "${output}" =~ "Field: objects, Value: '0'" ]]
}
