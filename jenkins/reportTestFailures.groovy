/*
the logic for this pipeline is following:

===THIS MUST BE RUNNING FOR MAIN BRANCHES ONLY===

to run @daily if new changeset is pushed

* Build source tarball on Jenkins master
* record version, revision, branch
* Archive source tarball for reuse in next steps
* allocate matrix for all supported systems
* build debug and release configuration
* save cmake & make logs
* archive cmake & make logs
* archive binary tarball

* clean up workspace
* unpack binary tarball

* run MTR and save output - text log, xml, tarball for MYSQL_VARDIR if there are failures
* archive text log and xml + MYSQL_VARDIR if there are failed tests
* repeat 2 from above for all mtr tests - normal, big, galera, etc sequentially to do not spawn many VMs at once

JIRA STEP
* get a shared lockable resource
* determine if there are failed tests

process every failed test ->

if existing bug has not been found -> create new
create ->
  set summary,
  set single fix version,
  attach mtr log,
  add description ->
    this bug has been discovered on ${PLATFORM}, for ${VERSION}, r${REVISION}

    {code}
    MTR FAILURE HERE
    {code}
    link to directory with tarball, logs and tests
    link to build (automatic)

if existing bugs found ->
  check if there is a single open bug ->
    update it with comment if last comment is > 30d ago
    update it with comment if no comments
    do not include MTR FAILURE
    check if it's not closed
    if closed ->
      reopen
      set fix version if required
      add comment
        this bug is reproducible on ${PLATFORM}, for ${VERSION}, r${REVISION}
        {code}
          MTR FAILURE HERE
        {code}
        link to directory with tarball, logs and tests
        link to build (automatic)
  if no open bugs ->
    find one created by CI system and reopen
    if no such bugs -> create new one
*/

pipeline {
  agent none
  stages {
    stage('Build binaries') {
      steps {
        echo "Starting binaries build..."
      } // steps
    } // stage('Build binaries')
    stage('Run MTR tests') {
      steps {
        echo "Starting MTR tests..."
      } // steps
    } // stage('Run MTR tests')
    stage ('Update Jira issues') {
      steps {
        echo "Updating Jira issues..."
      } // steps
    } // stage ('Update Jira issues')
  } //stages
} //pipeline
