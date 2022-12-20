# SmartFeed

### Why do we need a sentiment analyzer?
Online users today express a great deal of information since social media has such a big impact on our lives. Users rely on social media to share their opinions on whatever topic they want, from unimportant things like the weather to contentious issues like politics and war. It's interesting to see how various individuals can react differently to the same topic. Some people may be enthusiastic about it, while others may find it offensive, and some people may be wholly uninterested in it or utterly uninformed of it. Because of this, it's critical to be able to discern the underlying sentiment the information that is now being posted online.

For this project, we have built an application that analyzes underlying sentiments behind tweets from Twitter.

### Application Introduction
Data is extracted from Twitter and AWS Comprehend is used to identify the underlying sentiment behind these tweets. 
- The user can choose to view tweets from a variety of predefined topics such as soccer, food, Hollywood, etc. 
- He can also look up a topic that interests him by subscribing to that topic.
- The user only needs to select the topics they want to view the sentiments for from a dropdown menu, and they may also choose whether they want to see tweets for positive, negative, or all sentiments.
- The most recent tweets on the chosen topic will be shown together with their details.

### Technologies used
- Front End: 
- Languages: Python, HTML, CSS, JS
- Framework: Django
- Static file storage: S3
- Hosting: EC2
- IAC: Terraform
- Data Source: Twitter
- Database: MySQL - RDS
- Scheduled Refresh: Eventbridge-Lambda configuration
- Queuing: API Gateway with SQS-Lambda configuration
- Sentiment Analysis: Lambda with Amazon Comprehend (NLP Service)
- Application monitoring: Cloudwatch

### Challenges we ran into
- Even though there were only 5 of us using it, our EC2 would crash after a while owing to server overload. To mitigate this we had to use a larger instance.
- Since our team mostly comprises of data science/ML developers and enthusiasts, we struggled a bit with the front-end side of things.

### Accomplishments
- Successfully scraped Twitter’s data and can display the tweets based on a specified category.
- Learned how AWS technologies are integrated together effectively.

### What's next for SmartFeed
We aim to scrape information from other social networking sites, including Reddit. This will enable us to scale up our project and cover more ground for more accurate findings.

## Program Setup and Execution
* Download the **terraform.zip** file from the submission folder or access the files from the terraform folder in our repository by navigating to the terraform folder<br>
***cd terraform***

* Open the **variables.tf** file and update the value in default for the below 5 variables<br>
  <kbd><img height="512" alt="image" src="https://user-images.githubusercontent.com/89811190/205367906-f92c6e14-5580-418e-9c34-10586e2872ea.png"></kbd>
  
  1. ACCESS_KEY
  2. SECRET_KEY
  3. TOKEN
  4. EC2_KEY:
     * Enter the EC2 Key Pair name for this variable. 
     * This can be found in AWS Console -> EC2 -> Key Pairs 
     * For example, as per the image, the value for this field is **SI_ACADEMY_KEY**
     <kbd><img width="512" alt="image" src="https://user-images.githubusercontent.com/89811190/205367984-cb514d05-d9f5-4d35-bf24-858ff3c2b1e7.png"></kbd>

  5. IAM_ROLE_ARN:
     * This would be the ARN for LabRole in IAM 
     * Navigate to AWS Console and search for IAM. 
     * Click on Roles and search for LabRole 
     * Enter the ARN of LabRole in variables.tf file

* Once you're in the terraform folder, execute ***terraform init*** to initialize terraform<br>
  <kbd><img width="363" alt="image" src="https://user-images.githubusercontent.com/89811190/205368003-a56f4ffd-acb3-4ed8-af52-d05fce43c568.png"></kbd>

* Execute ***terraform apply*** to create the infrastructure. 
  * Types ***yes*** to confirm that you want to create the resources mentioned in the script. 
  * The script will run for around 12 minutes to create all the mentioned resources.
  <kbd><img width="512" alt="image" src="https://user-images.githubusercontent.com/89811190/205368034-cf2c2fcf-63ba-408e-a53b-d365696ec821.png"></kbd>

  
* Once the script is finished, do not close the terminal as it outputs some values that are needed for completing the setup.
  <kbd><img width="400" alt="image" src="https://user-images.githubusercontent.com/89811190/205376401-79a4b9cb-c114-4a27-8241-f0a6aa013f27.png"></kbd>
 
* Navigate to the AWS Console and search for **CloudShell**. 
* Copy the connection string from the terminal and use it to connect to the EC2 instance in CloudShell. 

* Run command ***env*** on CloudShell 
  * Check if EC2 is initialized completely 
  * All user data should be populated
  
* Go to smart_feed directory by running ***cd smart_feed/***
  <kbd><img width="285" alt="image" src="https://user-images.githubusercontent.com/89811190/205368192-d92532d5-0ca6-4350-9837-7580c0e45d2e.png"></kbd>

* Execute the command below to run the application. <br>
***python3 manage.py runserver 0:8000*** 
* You would see something like this after you execute the command
  <kbd><img width="579" alt="image" src="https://user-images.githubusercontent.com/89811190/205368242-9d4205a6-b5a7-4f6b-8bf6-e88a1d297a4e.png"></kbd>

* Access the application by using the link mentioned in the terminal output.<br>
  For example, in this image, the link is **http://44.199.214.206:8000/**<br>
  <kbd><img width="460" alt="image" src="https://user-images.githubusercontent.com/89811190/205376710-9be39ced-6b2c-45d9-a0da-93a0bb99d3ce.png"></kbd>

* ***Test the application!***
* Cleanup:
  * Execute ***terraform destroy*** on the terminal to destroy the infrastructure. 
  * Provide confirmation by entering ***yes*** if asked.
  <kbd><img width="612" alt="image" src="https://user-images.githubusercontent.com/89811190/205368366-d1807c29-f326-4780-8799-2fa4e3819d03.png"></kbd>
  
  <kbd><img width="679" alt="image" src="https://user-images.githubusercontent.com/89811190/205368380-8464b1e5-351e-477a-8a90-5cf1235a080c.png"></kbd>

## Application Flow
* Existing users can log in by entering their username and password.
  <img width="1440" alt="image" src="https://user-images.githubusercontent.com/89811190/205361462-5d5ab602-8936-47f2-bbb7-d40e685c9f2f.png">

* New users can register by creating an account. The user needs to enter his details here in order to create an account.
  <img width="1440" alt="image" src="https://user-images.githubusercontent.com/89811190/205361519-f90e3643-174d-4409-8ee6-521500e6fffd.png">

* Once logged in, the user is led to the topics subscription page to subscribe to topics
We’re offering 10 topics that have already been scraped and whose tweets are already present in the database. User can subscribe to them by ticking the respective checkboxes and clicking on "Submit".
If the user wants to get analysis for a new topic, they can request for it by typing in the text box and clicking on "Submit". 
The user can enter multiple topics by clicking on "Add another topic".
  <img width="1440" alt="image" src="https://user-images.githubusercontent.com/89811190/205362223-c102ff74-dee5-4176-aeee-b6713d898d86.png">

* To view tweets and sentiment for a topic the user has subscribed to, they can navigate to the ‘View sentiments’ page and choose the topic and sentiment they wish to view tweets for from the dropdown menu.
  <img width="1440" alt="image" src="https://user-images.githubusercontent.com/89811190/205362743-a2db0eb4-fefd-41ae-8821-d93949045c18.png">

* In the end, the users can see the requested tweets with the sentiment they selected.
  <img width="1440" alt="image" src="https://user-images.githubusercontent.com/89811190/205362811-fab80574-6698-46d7-89f9-3f06a3e40ef3.png">
