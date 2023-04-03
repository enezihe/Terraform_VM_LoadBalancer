pipeline {
    agent any
    tools {
        terraform 'terraform'
    }
    

    stages {

        stage('Create Infrastructure for the App') {
              steps {
                sh 'az login --identity'
                echo 'Creating Infrastructure for the App on AZURE Cloud'
                sh 'terraform init'
                sh 'terraform apply --auto-approve'

            }
        }
        stage('Destroy the Infrastructure') {
            steps{
                timeout(time:5, unit:'DAYS'){
                    input message:'Do you want to terminate?'
                }
                sh 'terraform destroy --auto-approve'              
            }
        }
    }
} 