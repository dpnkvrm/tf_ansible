pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    stages {
         stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS_ACCESS_KEY_ID', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                        // Extract SSH key from Terraform output and save it to a file
                        sh 'terraform output pvt_key > ../aws.pem'
                    }
                }
            }
        }

        stage('Ansible Provisioning') {
            steps {
                dir('ansible') {
                    // Run Ansible playbook
                    sh 'ansible-playbook -i aws_ec2.yml web.yml'
                }
            }
        }
    }
}
