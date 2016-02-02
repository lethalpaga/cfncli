Feature: Cloudformation stack creation
  In order to create a stack in CloudFormation
  As an automated process
  I want to have a simple CLI command with a return code

  Scenario: Successful creation
    Given a Clouformation template in S3
    When the stack is created successfully
    Then the return code is 0

  Scenario: Failed creation
    Given a Clouformation template in S3
    When the stack is created unsuccessfully
    Then the return code is different from 0
