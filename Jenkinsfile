pipeline {
    agent any
    stages {
        stage("Release docker_configurator") {
            when { tag "docker_configurator-v*" }
            steps {

                echo "this is a new release for tag: ${tag}"
            }
        }
    }
}