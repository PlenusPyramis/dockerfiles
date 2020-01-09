// In the Jenkins job Github plugin settings, click the Add button, add `Advanced clone behaviours`, then checkmark `fetch tags`.
pipeline {
    agent {
        docker { image 'python:3.7-buster' }
    }
    stages {
        stage("Gather vars") {
            steps{
                script {
                    env.TAG_NAME = sh(returnStdout: true, script: "git tag --points-at HEAD").trim()
                    release_tool_url = "https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2"
                }
                echo "commit: ${GIT_COMMIT}"
                echo "tag: ${TAG_NAME}"
            }
        }
        stage("Release docker_configurator") {
            when { tag "docker_configurator-v*" }
            steps {
                script {
                    release_version = env.TAG_NAME.replace("docker_configurator-","")
                    zip_artifact="docker_configurator-${release_version}-Linux.zip"
                    exe_artifact="docker_configurator-${release_version}-Linux/docker_configurator"
                }
                echo "New release version: ${release_version}"
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
                    sh """
                    set -e
                    TMP=\$(mktemp -d)
                    cd \$TMP
                    wget ${release_tool_url}
                    tar xfvj linux-amd64-github-release.tar.bz2
                    install bin/linux/amd64/github-release /usr/local/bin/
                    """

                    sh """
                    set -e
                    cd scripts/docker_configurator
                    pip install virtualenv
                    virtualenv -p python3 env
                    . env/bin/activate
                    pip install -r requirements.txt
                    python setup.py build
                    if [ ! -f dist/${zip_artifact} ]; then
                        echo "Release artifact does not exist: dist/${zip_artifact}"
                        exit 1
                    fi
                    unzip dist/${zip_artifact} -d dist/
                    github-release release \
                       --user PlenusPyramis \
                       --repo dockerfiles \
                       --tag docker_configurator-${release_version} \
                       --name docker_configurator-${release_version} \
                       --description ""
                    github-release upload \
                        --user PlenusPyramis \
                        --repo dockerfiles \
                        --tag docker_configurator-${release_version} \
                        --name docker_configurator \
                        --file dist/${exe_artifact}
                    """
                }
            }
        }
    }
}
