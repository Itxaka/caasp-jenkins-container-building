/*
This pipeline requires:
 - docker # to build images
 - golang # self-explained
 - python-pip # for tern
 - python-virtualenv # for tern
 - trivy binary in PATH # for vulnerabitily check
 - github.com/jstemmer/go-junit-report go module in PATH # for go test to xml output
 - github.com/axw/gocov/gocov go module in path  # for go coverage to xml output
 - github.com/AlekSi/gocov-xml go module in path # for go coverage to xml output
*/

def setupVirtualenv() {
 sh(script: "virtualenv --python=python3 ${WORKSPACE}/virtualenv", label: "Create virtualenv")
}

def runCommandWithVirtualenv(cmd, label) {
  sh(script: "source ${WORKSPACE}/virtualenv/bin/activate; ${cmd}", label:label)
}

pipeline {
    environment {
        golangImage = ''
        skubaImage = ''

    }

    agent { node { label "itxaka-test" } }


    stages {
        stage('Environment preparation') {
            steps {
                setupVirtualenv()
                runCommandWithVirtualenv('pip -q install tern', 'Install requirements')
            }
        }
        stage('Checkout skuba') {
            steps {
                checkout([$class: 'GitSCM',
                branches: [[name: "v${env.SKUBA_VERSION}"]],
                extensions: [[$class: 'WipeWorkspace'], [$class: 'RelativeTargetDirectory', relativeTargetDir: 'skuba']],
                userRemoteConfigs: [[url: env.SKUBA_GIT_URL, credentialsId: 'github-token',, refspec: "+refs/heads/*:refs/remotes/origin/* +refs/pull/*/head:refs/remotes/origin/pr/*"]]])
            }
        }
        stage('Run Skuba Tests') {
            steps {
                 dir('skuba') {
                    sh(script: 'make lint', label: 'make lint')
                    sh(script: 'go test -v -coverprofile=coverage.out ./{cmd,pkg,internal}/... 2>&1 | /home/jenkins/go/bin/go-junit-report > ../unit-report.xml', label: 'make test-unit')
                    sh(script: '/home/jenkins/go/bin/gocov convert coverage.out | /home/jenkins/go/bin/gocov-xml > ../go-coverage.xml')
                }
            }
        }
        stage('Build Go Container') {
            steps {
                script {
                    golangImage = docker.build("golang:${env.GOLANG_VERSION}", "-f golang.Dockerfile --build-arg GOLANG_VERSION=${env.GOLANG_VERSION} .")
                }
            }
        }
        stage('Build Skuba Container') {
            steps {
                script {
                    skubaImage = docker.build("skuba:${env.SKUBA_VERSION}", "-f skuba.Dockerfile --build-arg GOLANG_IMAGE=${golangImage.imageName()} .")
                }
            }
        }
        stage('Gather licenses') {
            steps {
                runCommandWithVirtualenv("tern report -f html -i ${skubaImage.imageName()} -o tern-report.html", "tern")
            }
        }
        stage('Check vulnerabilities') {
            steps {
                script {
                    sh("trivy image --format template --template 'junit.tpl' -o trivy-report.xml ${skubaImage.imageName()}")
                }
            }
        }
        stage('Push image') {
            steps {
                script {
                    echo "Stage"
                }
            }
        }

    }
    post {
        success {
            script {
                sh("docker images > images.out")
                archiveArtifacts(artifacts: "images.out", allowEmptyArchive: true)
                archiveArtifacts(artifacts: "unit-report.xml", allowEmptyArchive: true)
                archiveArtifacts(artifacts: "trivy-report.xml", allowEmptyArchive: true)
                archiveArtifacts(artifacts: "go-coverage.xml", allowEmptyArchive: true)
                archiveArtifacts(artifacts: "tern-report.html", allowEmptyArchive: true)
                junit 'unit-report.xml'
                junit 'trivy-report.xml'
                cobertura autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: 'go-coverage.xml', conditionalCoverageTargets: '70, 0, 0', enableNewApi: true, failUnhealthy: false, failUnstable: false, lineCoverageTargets: '80, 0, 0', maxNumberOfBuilds: 0, methodCoverageTargets: '80, 0, 0', onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false
                publishHTML([allowMissing: true, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '.', reportFiles: 'tern-report.html', reportName: 'Tern report', reportTitles: ''])
            }
        }
    }
}
