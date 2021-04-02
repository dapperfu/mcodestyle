pipeline {
  agent any
  stages {
    stage('matlab') {
      steps {
        runMATLABCommand 'run(\'mcodestyle\')'
      }
    }

  }
}