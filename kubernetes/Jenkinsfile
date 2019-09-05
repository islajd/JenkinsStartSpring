def remote = [:]
remote.name = "ubuntu"
remote.allowAnyHosts = true
def ID
def IP
def STATE
node{
    withCredentials(
        [[
            $class: 'AmazonWebServicesCredentialsBinding',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            credentialsId: 'aws-client',  // ID of credentials in Jenkins
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
        stage("create EC2 instance"){
            sh 'aws configure set region us-east-2'
            ID = sh (script: 'aws ec2 run-instances --image-id ami-05c1fa8df71875112 --count 1 --instance-type t2.micro --key-name KEY_AWS --security-group-ids sg-d77dc5b4 --subnet-id subnet-a9541dd3 --region us-east-2 --query \'Instances[0].InstanceId\'',returnStdout: true)
        }
        stage("get the EC2 external ip"){
            remote.host = sh (script: "aws ec2 describe-instances --query \'Reservations[0].Instances[0].PublicIpAddress\' --instance-ids $ID",returnStdout: true)
        }
    }
    withCredentials([sshUserPrivateKey(credentialsId: 'KEY_AWS', keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'userName')]) {
      remote.user = userName
      remote.identityFile = identity
      stage("install awscli") {
            sh 'sudo apt-get update'
            sh 'sudo apt-get install awscli -y'
      }
      stage("install kops"){
            sh 'curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d \'\"\' -f 4)/kops-linux-amd64 ' 
            sh 'chmod +x kops-linux-amd64'
            sh 'sudo mv kops-linux-amd64 /usr/local/bin/kops'
      }
      stage("install kubectl"){
            sh 'curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl'
            sh 'chmod +x ./kubectl'
            sh 'sudo mv ./kubectl /usr/local/bin/kubectl'
      }
      withCredentials(
        [[
            $class: 'AmazonWebServicesCredentialsBinding',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            credentialsId: 'aws-client',  // ID of credentials in jenkins
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
            stage("create s3 bucket"){
                sh 'aws configure set region us-east-2'
                //sh 'aws s3 mb s3://k8s.xlajd.io'
            }
            stage("generate ssh-keygen"){
                sh 'sudo ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa -y'
            }
            stage("create cluster configurations"){
                sh 'sudo chmod -R 777 /root/'
                sh 'sudo chmod -R 777 /root/.ssh/'
                sh "kops create cluster k8s.xlajd.io --node-count 2 --zones us-east-2b \
                    --node-size t2.micro --master-size t2.micro \
                    --master-volume-size 8 --node-volume-size 8 \
                    --ssh-public-key /root/.ssh/id_rsa.pub \
                    --state s3://k8s.xlajd.io --dns-zone Z1C7GMSKIJLFNI --dns private --yes"
                sh 'sudo chmod -R 700 /root/.ssh/'
                sh 'sudo chmod -R 700 /root/'
            }
            stage("create the cluser"){
                sh 'kops update cluster k8s.xlajd.io --state s3://k8s.xlajd.io --yes'
            }
            stage('Wait for kubernetes to start') {
                waitUntil{
                    try{        
                        sh "kubectl get nodes"
                        return true
                    }catch (Exception e){
                        return false
                    }
                }
            }
            stage("configure the pod with test image"){
                sh 'kubectl run test --image=islajd/test:firsttry --port=8080'
                sh 'kubectl get pods'
            }
        }
    }
}
