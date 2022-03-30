
# ALIAS

# Kubectl
alias k 'kubectl'
alias kg 'kubectl get'
alias kgp 'kubectl get pods'
alias kall "watch -n 1 $HOME/code/scripts/k_get_all"
alias kgpw "watch -n 3 kubectl get pods"
alias kgpw1 "watch -n 1 kubectl get pods"
alias ogpw "watch -n 3 oc get pods"
alias ogpw1 "watch -n 1 oc get pods"
alias kbsh "kubectl run -i --rm --tty debug --image=vicenteherrera/kubectl-utils --restart=Never -- sh"
alias kbsha "kubectl exec --stdin --tty debug -- sh"
alias kbmysql "kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword"
alias kevents "kubectl get events --sort-by=.metadata.creationTimestamp"
alias kren "kubectl config rename-context (kubectl config current-context)"

# AWS
alias aws_id "aws sts get-caller-identity"
alias aws_cfg "aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]' ; aws sts get-caller-identity --output text --query 'Account' ; [ (aws sts get-caller-identity --output text --query 'Account') = \"845151661675\" ] && echo \"draios-demo\" "

# Git
alias glog "git log --oneline --graph --decorate"
alias gcsm "git commit -s -S -m"
alias gc "git commit -m" 

# Other
alias sf 'say "process has finished"'
alias w3 "/usr/local/bin/watch -n3"
alias ek 'eksctl'