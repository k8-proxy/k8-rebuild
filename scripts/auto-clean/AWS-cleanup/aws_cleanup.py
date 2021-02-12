import os
import boto3
from dotenv import load_dotenv
import datetime

load_dotenv()

class DeleteAwsEc2:
    def __init__(self,aws_access_key_id,aws_secret_access_key):
        self.aws_access_key_id=aws_access_key_id
        self.aws_secret_access_key=aws_secret_access_key

    def get_regions(self):
        regions=[]
        ec2 = boto3.client('ec2', aws_access_key_id=self.aws_access_key_id,
                           aws_secret_access_key=self.aws_secret_access_key,)

        regions_json=ec2.describe_regions()['Regions']
        for i in regions_json:
            regions.append(i['RegionName'])
        return regions

    def list_vms(self):
        regions = self.get_regions()
        output_list=[]
        for region in regions:
            ec2 = boto3.resource('ec2', region_name=region, aws_access_key_id=self.aws_access_key_id,
                                 aws_secret_access_key=self.aws_secret_access_key,
                                 )
            print(f"Region: {region}")
            for i in ec2.instances.all():
                print("Id: {0}\tState: {1}\tLaunched: {2}\t".format(i.id, i.state['Name'], i.launch_time))
                if i.tags:
                    for tag in i.tags:
                        print(f"{tag['Key']} : {tag['Value']}")
                print("\n")
                dict={'Id':i.id,'instance_id':i.instance_id,'State':i.state['Name'],'Launched':'i.launch_time'}
                output_list.append(dict)

        return output_list

    def delete_vms(self):

        delete_tag = os.environ.get("delete_tag",None)
        delete_value = os.environ.get("delete_value",None)
        dont_delete_tag = os.environ.get("dont_delete_tag",None)
        dont_delete_value = os.environ.get("dont_delete_value",None)
        expire_days_no= os.environ.get("expire_days_no",None)
        if not expire_days_no:
            expire_days_no=9999
        else:
            expire_days_no=int(expire_days_no)

        delete_instance_list = []

        current_time = datetime.datetime.now()

        regions=self.get_regions()

        for region in regions:
            ec2 = boto3.resource('ec2', region_name=region, aws_access_key_id=self.aws_access_key_id,
                                 aws_secret_access_key=self.aws_secret_access_key,
                                 )

            print(f"Region: {region}")

            for i in ec2.instances.all():
                lt = i.launch_time
                diff = current_time - lt.replace(tzinfo=None)

                if i.tags:
                    flag=False

                    for tag in i.tags:
                        print(tag)
                        if tag["Key"] == delete_tag and tag["Value"] == delete_value and i.state["Name"]!="terminated"  :
                            flag=True
                            delete_instance_list.append(i.instance_id)

                        elif tag["Key"] == dont_delete_tag and tag["Value"] == dont_delete_value:
                            flag=False

                            if i.instance_id in delete_instance_list:
                                delete_instance_list.remove(i.instance_id)
                                print("Removed from delete list")
                                print("\n")
                                break

                        elif diff.days>expire_days_no and i.state["Name"]!="terminated":
                            flag=True
                            print("added")
                            delete_instance_list.append(i.instance_id)

                    if flag:
                        print("Added to delete_instance_list")
                        print("Id: {0}\tState: {1}\tLaunched: {2}\t".format(i.id, i.state['Name'], i.launch_time))

            if delete_instance_list:
                print(f" {region} ")
                ec2.instances.filter(InstanceIds=delete_instance_list).terminate()
                print(f"Terminated instances : {delete_instance_list}")
                delete_instance_list = []

            else:
                print(f"No ec2 instance is deleted in region {region}")

            print("\n")

if __name__ == '__main__':
    access_key=os.environ.get("access_key",None)
    secret_key=os.environ.get("secret_key",None)

    delete_vm_script=DeleteAwsEc2(aws_access_key_id=access_key,aws_secret_access_key=secret_key)
    delete_vm_script.delete_vms()


