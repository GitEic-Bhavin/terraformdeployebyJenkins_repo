pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after terraform plan executed ?')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/xyz.git'
            }
        }
        stage('Terraform plan') {
            steps {
                script {
                    sh 'terraform init'
                    sh 'terraform plan -out tfplan'
                    sh 'terraform show tfplan > tfplan.txt'
                }
                
            }
        }
        stage('Terraform Apply') {
            when {
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }
            steps{
                script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the terraform plan ?",
                    parameters [text(name: 'Plan', defaultValue: 'plan' ,  description: 'Please review the plan')]
                }
            }
        }
        stage('Apply') {
            steps {
                sh 'terraform apply -input=false tfplan'
            }
        }
        
    }
}