@Library('ci-library') _

def props

pipeline {
  parameters {
    string(name: 'SRC_JOB_NAME', defaultValue: '10.6e-RPM-DEV', trim: true)
    string(name: 'SRC_JOB_NUMBER', defaultValue: '179', trim: true)
  }
  agent none
//  environment {}
  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
  }
  stages {
    stage('Install packages') {
      matrix {
        axes {
          axis {
            name 'label'
            values 'rhel-7', 'rhel-8'
          }
        }
        agent { label "${label}" }
        options { skipDefaultCheckout() }
        stages {
          stage('Install ES') {
            steps{
              timestamps {
                timeout(activity: true, time: 1200, unit: 'SECONDS') {
                  copyArtifacts filter: 'build.properties, pkglist.txt', fingerprintArtifacts: true, flatten: true, projectName: "${SRC_JOB_NAME}/label=${label}", selector: specific("${SRC_JOB_NUMBER}")
                  script {
                    props = readProperties  file: 'build.properties'
                    setBuildName(props['GIT_BRANCH'], props['GIT_COMMIT'])
                    createRepoConfig("${label}", props[''])
                  }

                }
              }
            }
          }
        }
      }
    }
  }
}
