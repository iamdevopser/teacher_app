// Jenkins — declarative pipeline; requires Docker pipeline plugin or agent with this image
pipeline {
  agent {
    docker {
      image 'ghcr.io/cirruslabs/flutter:stable'
    }
  }
  options {
    timestamps()
  }
  stages {
    stage('Dependencies') {
      steps {
        sh 'flutter pub get'
      }
    }
    stage('Build Web') {
      steps {
        sh 'flutter build web --release'
      }
    }
  }
}
