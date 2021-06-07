pipeline {
  agent { label 'master' }
  options {
    buildDiscarder logRotator(numToKeepStr: '10')
    skipDefaultCheckout true
    copyArtifactPermission '*'
  }
  stages {
    stage('SourceTar') {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: "${GIT_BRANCH}"]], extensions: [], userRemoteConfigs: [[credentialsId: '76beeb87-031b-44c0-9de8-1b99fca8ddd9', url: 'git@github.com:mariadb-corporation/MariaDBEnterprise.git']]])
        echo "GIT_BRANCH is ${GIT_BRANCH}"
        echo "GIT_COMMIT is ${GIT_COMMIT}"
        sh "cmake . -DBUILD_CONFIG=enterprise 2>&1 | tee src-cmake.log"
        sh "make dist"
        archiveArtifacts artifacts: "mariadb-enterprise-*.tar.gz, src-cmake.log", fingerprint: true
      }
    }
  }
}
