# Automate cleaning EC2 instances on AWS using Ansible

The Following steps will show how to remove one or multi ec2 instances using **remove.yml** playbook 

* First, you need ansible to be installed on your machine

```bash
echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
sudo apt install python3
sudo apt install python3-pip -y
pip3 install --user ansible
```

* Close your terminal and reopen it again, Then install boto & boto3 which is Amazon Web Services (AWS) SDK for Python

```bash
sudo pip3 install boto boto3
```

* Now, we need to define 3 environment variable which are our aws credentials (Access keyID & Secret access key) and aws region we are targeting (please note environment variable are valid only on runtime, meaning that you will need to define it again if you reboot )

```bash
export AWS_DEFAULT_REGION=<PLEASE DEFINE YOUR TARGET REGION>
export AWS_ACCESS_KEY_ID=<PLEASE ADD YOUR ACCESS KEY ID>
export AWS_SECRET_ACCESS_KEY=<PLEASE ADD YOUR SECRET ACCESS KEY>
```

* Last step is to open **remove.yml** file and define the delete tag, which accordingly any instances with that tag will be terminated (please note terminating an aws ec2 instance is irreversible).

```bash
    vars:
      delete_tag: <PLEASE DEFINE YOUR DELETE TAG>
```

* Now, run the playbook using the following command

```bash
ansible-playbook remove.yml
```

* It will print the play recap where the changed value identifies how many instances where affected (the following example shows I had one instance been deleted)

```tex
PLAY RECAP *************************************************************************************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```



## Adding tags to ec2 instances

* from the console select the instances you want to modify and press on **Tags**

![image](https://user-images.githubusercontent.com/58347752/104305469-638ec400-54d5-11eb-9e48-cbad91347952.png)



* Identify the delete tag under the **Key** box (Please care to make it unusual tag)

![image](https://user-images.githubusercontent.com/58347752/104305658-a05abb00-54d5-11eb-94d9-8fe1a29c144d.png)