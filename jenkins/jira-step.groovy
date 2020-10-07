pipeline {
    agent { label 'master'  }
    stages {
        stage('Process Test results') {
            steps {
                echo "it works"
                cleanWs()
                copyArtifacts filter: '*.xml', fingerprintArtifacts: true, projectName: "${COMPLETED_JOB}", selector: lastCompleted()
                script {
                    def xmlFiles = findFiles(glob: '**/*.xml')
                    xmlFiles.each { reportFile ->
                        echo ("Processing " + reportFile.path)
                        def platform = reportFile.path.split('/')[-2].split(',')[-1].split('=')[-1]
                        echo ("Platform is " + platform)
                        def report = new XmlParser().parse(env.WORKSPACE + '/' + reportFile.path.toString())
                        def failedTests = report.'**'.testcase.findAll { testcase -> testcase.@status == "MTR_RES_FAILED" }
                        if (failedTests.size() > 0) {
                            failedTests.each { test ->
                                def testcase = test['@classname'] + "."+ test['@name']
                                def jiraQuery =  'project = "TEST PROJECT" AND summary ~ ' + testcase
                                def loggedIssuesSearch = jiraJqlSearch jql: jiraQuery, site: 'MariaDB', fields: ['key', 'summary'], failOnError: true, maxResults: 3
                                if (loggedIssuesSearch != null){
                                    def issues = loggedIssuesSearch.data.issues
                                    if(issues.size() == 0){
                                        echo "Creating new ticket"
                                        def newIssue = [fields: [ // id or key must present for project.
                                                    project: [key: 'TEST'],
                                                    summary: 'Failed test in Jenkins-CI: ' + testcase ,
                                                    description: "Test failure observed during MTR run:\n\n{noformat}" + test.failure.text() + "{noformat}",
                                                    // id or name must present for issueType.
                                                    issuetype: [name: 'Bug']]]
                                        response = jiraNewIssue issue: newIssue, site: 'MariaDB'
                                        echo response.successful.toString()
                                        echo response.data.toString()
                                    }else{
                                        def key = issues[0].key
                                        echo "Found " + key
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
