# Table of content
- [Lab 1: Hypedword Cloud - 5'](./01_hypeword_cloud/)
- [Lab 2: AWS Account & Org Management - 45'](./02_management/)
- [Lab 3: Identity, Access and Security - 60'](./03_iam_security/)
- [Lab 4: Storage and Data - 45'](./04_storage_data/)
- [Lab 5: Computation on AWS](./05_computation/)
- [Lab 6: Networking & Interfaces](./06_interfaces_networks/)
- [Lab 7: Dataengineering and analytics](./07_analytics/)
- [Lab 8: Quick Intro to A.I. on AWS](./08_ai/)
- [Lab 9: DevOps in and to AWS](./09_devops/)

The labs start with the basics (getting started) and moving through core concepts like account management, data storage, computation, identity and access management, networking and interface and finally reaching more advanced topics like data analytics, a.i. and devops.

## Sources

- [AWS Service documentation](https://docs.aws.amazon.com/)
- [AWS Terraform porvider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Target group

### Who is this training for?
- People who know another cloud and want to adapt their knowhow to AWS
- Engineers that want to pick-up cloud engineering / architecting know how for the first time
- IT / Solution Architects with a profound technical understanding

### Who is this training <ins>**partially**</ins> for?
- IT / Business Managers or other groups interessted in the bussiness aspects of clouds (Chapter 1 and 2)
- IT Engineers that with only interest in their respective field (Chapter 1 and the corresponding chapter of their field of work)
- People with (some) AWS Knowhow (The chapters they might have some knowledge gaps)

### Who is this training <ins>**not**</ins> for?
- People with no technical skills or missing skills in one of the disciplines mentioned in the prerequisites, hoping only to adapt and fill those knowledge-gaps
- People that are not interested in AWS or attend to prove that their favourite cloud / onprem way is the best
- People on AWS professional level - you will be bored

## Prerequisites

- A proper Know-How of at least some IT basics:
   - You know at least one modernly used coding language (e.g. Golang, Python, JS/TS, Java, .Net and so on)
   - You know the basic of networking in IT (what a subnet is, concepts like CIDR, public & private ip's + networks, routing, dns and so on)
   - You can use a bash console or any other linux related terminal for basic navigation
   - You understand the basic schemas for relational databases and know when to use a database and when to use files + filebased storage
   - You have some basic knowledge of VM's and virutalization
   - You know different kinds of interfaces like REST-API, Queues, maybe even heard of advanced integration / streaming toolings like Kafka
   - You know the basics of DevOps and CICD Pipelines and best case are able to create your own CICD Pipeline on Gitlab or Github with Actions (or any version control of your choise) and so on.
- If you have some knowledge gaps from the topics above, we expect you to prepare them carefully beforehand. Otherwise you will not understand critical core topics.
- Prepared all the tasks you had for the preparation like installing the access to the labs, created necessary accounts, installed all the tools mentioned

## Repository Build-Up:

```plaintext
/labs
 ├──xx_labname
 │    ├── README.md -> Your lab
 │    ├── *.tf -> For the people that rather do it with Terraform than with the console: Sometimes just templates, sometimes tasks
/case-studies
 ├──xx_studyname -> All the files you need. No guide this time!
/solutions
 ├── labs -> All the solutions from todays hands-on workshops
 ├── case-studies -> All the solutions for tomorrows workshops
```