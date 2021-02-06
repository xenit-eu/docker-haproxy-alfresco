node {

    stage 'Checkout'
    checkout scm

    // env.GIT_BRANCH is null !!!
    //  so workaround:
    //def gitBranch = sh(returnStdout: true, script: "git branch | grep '^*' | cut -d' ' -f 2").trim()
    def gitBranch = env.BRANCH_NAME // https://issues.jenkins-ci.org/browse/JENKINS-30252

    println "********** GIT_BRANCH: [${gitBranch}]"
    println "********** BUILD_NUMBER: [" + env.BUILD_NUMBER + "]"

    def buildNr = env.BUILD_NUMBER

    try {
        stage 'Build & Publishing'
        sh "./gradlew pushDockerImage -PbuildNumber=${buildNr} -PgitBranch=${gitBranch}"

    } catch (err) {
        currentBuild.result = "FAILED"
    }

}

