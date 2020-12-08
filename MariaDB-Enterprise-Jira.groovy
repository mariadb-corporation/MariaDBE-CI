//
def failedTestsArray = []
def jiraSite = 'MariaDB'
def emailTo = 'platform-qa@mariadb.com, elenst@mariadb.com, serg@mariadb.com, roel.vandepaar@mariadb.com'
def emailFrom = 'platform-qa@mariadb.com'
def emailBody
def emailSubj
def mtrJobs = ['MTR-NORMAL', 'MTR-PSPROTO', 'MTR-EXTRA', 'MTR-ENGINES', 'MTR-BIGTEST', 'MTR-GALERA']
//
pipeline {
  parameters {
    string defaultValue: '10.2e', description: '', name: 'ES_VERSION', trim: true
  }
  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')
  }
  agent { label 'master'  }
  environment {
    JIRA_SITE = "${jiraSite}"
  }
  stages {
    stage('Process Test results') {
      steps {
        script {
          mtrJobs.each { mtrJob ->
            def jobName = "${params.ES_VERSION}-${mtrJob}"
            println "Processing ${jobName}..."
            cleanWs()
            copyArtifacts filter: '*.xml', fingerprintArtifacts: true, projectName: "${jobName}", selector: lastCompleted()
            def xmlFiles = findFiles(glob: '**/*.xml')
            xmlFiles.each { reportFile ->
              println "Processing ${reportFile.path}"
              def platform = reportFile.path.split('/')[-2].split(',')[-1].split('=')[-1]
              def buildType = reportFile.path.split(',')[0].split('=')[1]
              def rootNode = new XmlParser().parse(env.WORKSPACE + '/' + reportFile.path.toString())
              rootNode.children().each { testSuite ->
                println "=> Processing testsuite: ${platform}/${buildType} - ${testSuite['@name']}"
                def failedTests = []
                failedTests = testSuite.children().findAll { testcase -> testcase['@status'] == "MTR_RES_FAILED" }
                if(failedTests.size() > 0) {
                  println "\t Failures found!"
                  failedTests.each { failedTest ->
                    def fullTestName = testSuite['@name']+'.'+failedTest['@name']
                    println "\t Failed test: ${fullTestName}"
                    if(!failedTestsArray.contains(fullTestName)){ failedTestsArray.add(fullTestName) }
                  } // if(failedTests.size() > 0)
                } // if(failedTests.size() > 0)
              } // rootNode.children().each
            } // xmlFiles.each {
          } // mtrJobs.each
        } // script
      } // steps
    } //stage
    stage('Check Jira issues') {
      steps {
        println "Checking the issues against Jira..."
        script {
          failedTestNumber = failedTestsArray.size()
          if ( failedTestNumber > 0) {
            emailSubj = "Test result summary for ${env.ES_GIT_BRANCH} branch"
            emailBody = "Tested version: ${env.FULL_VERSION} from ${env.ES_GIT_BRANCH}<br/>"
            emailBody += "Git revision: ${env.ES_GIT_COMMIT}<br/>"
            emailBody += "MultiJob URL: ${env.METABUILD_URL}<br/>"
            emailBody += "Aggregated test report: ${env.METABUILD_URL}testReport/<br/>"
            emailBody += "Jira Site: https://jira.mariadb.org/<br/><br/>"

            emailBody += "The following <b>${failedTestNumber}</b> test failures were discovered during run:<br/><br/>"
            failedTestsArray.sort().each { failedTest ->
              emailBody += "<i>* ${failedTest}</i><br/>"
          // perform Jira search for failed test and report found issues
              def jiraQuery =  "(project = MDEV or project = MENT) and (status != Closed) AND summary ~ \"${failedTest}\""
              def loggedIssuesSearch = jiraJqlSearch jql: jiraQuery, failOnError: true //, fields: ['key', 'summary']
          // echo loggedIssuesSearch.data.toString()
              if (loggedIssuesSearch != null) {
                def issues = loggedIssuesSearch.data.issues
                if(issues.size() == 0) { // no issues found
                  emailBody += "<h3>!!! NO OPEN ISSUES FOUND for ${failedTest}!!!</h3><br/>"
                  emailBody += "<h3>Please create new issue or reopen existing if any!</h3><br/>"
                }else{
                  issues.each { issue ->
                    emailBody += "*** Found <a href=https://jira.mariadb.org/browse/${issue['key']}>${issue['key']}</a> ${issue.fields['summary']}<br/>"
                  }
                } // issues found
              }
              emailBody += "<br/>"
            }
            mail from: emailFrom, to: emailTo, subject: emailSubj, body: emailBody, mimeType: 'text/html'
          }
        } // script
      } // steps
    } // stage
  } // stages
} // pipelene
































