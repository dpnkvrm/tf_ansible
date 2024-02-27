pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/dpnkvrm/tf_ansible.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Get AWS credentials from Jenkins
                    def awsCredentials = credentials('aws-credentials')

                    dir('terraform') {
                        // Set AWS credentials as environment variables
                        withAWS(credentials: awsCredentials, region: 'us-east-1') {
                            // Execute Terraform commands
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'

                            // Extract SSH key from Terraform output
                            def sshKey = sh(script: 'terraform output ssh_private_key', returnStdout: true).trim()

                            // Save the SSH key to a file in the parent directory
                            writeFile file: '../aws.pem', text: sshKey
                        }
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
