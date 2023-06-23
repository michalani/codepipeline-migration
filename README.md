# codepipeline-migration
A terraform code for migration of codepipeline from polling to event based solution

Amazon is moving away from polling pipelines, this terraform solutions showcases how to implement this change directly in terraform.
```
Hello,

You are receiving this message because you have one or more polling pipelines in your account. A polling pipeline is defined as a pipeline that has at least one source action configured to poll for changes. The AWS CodePipeline team will be disabling polling in inactive pipelines effective May 25, 2023. An inactive pipeline is defined as one that has not had a pipeline execution started in the last 30 days. Inactive pipelines that only use Amazon EventBridge rule, or AWS CodeStar Connections, or webhooks to trigger the pipeline will not be affected. Additionally, any active pipeline will also not be affected.

We recommend that you update to use Amazon EventBridge, or AWS CodeStar Connections, or webhooks as the trigger mechanism for your source. Follow the instructions in the documentation[1] for making this change. Changing your pipeline from polling to event based will improve performance for pipeline executions by ensuring they respond to source changes quicker.

If you have questions about this change, the AWS Support Team is available on re:Post [2] and via Premium Support [3].

[1] https://docs.aws.amazon.com/codepipeline/latest/userguide/update-change-detection.html

[2] https://repost.aws/tags/TAD_CcYa8ASIKYqZ_uXiwwgA/aws-codepipeline

[3] https://support.console.aws.amazon.com/support
```

The above architecture works by relaying on you having 2 buckets 1st bucket for source and 2nd bucket for deployment to, the source bucket is declared within the template, while the deployed to bucket is not as you likely already have an existing bucket you wish to deploy to, feel free to create one to use with this architecture.

References:
*=================*
[1] Migrate polling pipelines with an S3 source and CloudTrail trail (CLI) - https://docs.aws.amazon.com/codepipeline/latest/userguide/update-change-detection.html#update-change-detection-cli-S3 
[2] Migrate polling pipelines with an S3 source and CloudTrail trail (AWS CloudFormation template). - https://docs.aws.amazon.com/codepipeline/latest/userguide/update-change-detection.html#update-change-detection-cfn-s3 
[3] CodePipeline pipeline structure reference - Default settings for the PollForSourceChanges parameter - https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#PollForSourceChanges-defaults 
[4] Migrate polling pipelines to use event-based change detection - Viewing polling pipelines in your account - https://docs.aws.amazon.com/codepipeline/latest/userguide/update-change-detection.html#update-change-detection-view-polling 

