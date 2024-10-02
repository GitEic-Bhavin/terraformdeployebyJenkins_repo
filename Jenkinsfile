pipeline {
    agent any

   tools {
        terraform 'terraform'
        }

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after terraform plan executed ?')
    }

 	environment {
        	AWS_ACCESS_KEY_ID = credentials("AWS_ACCESS_KEY_ID")
        	AWS_SECRET_ACCESS_KEY = credentials("AWS_SECRET_ACCESS_KEY")
    	}

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/GitEic-Bhavin/terraformdeployebyJenkins_repo.git'
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
	stage('Destroy') {
            steps {
                sh 'terraform destroy --auto-approve'
            }
        }

        // stage('Apply') {
        //    steps {
        //        sh 'terraform apply -input=false tfplan'
        //    }
        //}
	//stage('Destroy') {
	//    steps {
	//	sh 'terraform destroy --auto-approve'
	//    }
	//}
        
    }
}
