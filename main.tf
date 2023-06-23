# variables for the project
variable "output_bucket" {
  type = string
  default = "versionedbucket1sample1"#<-CHANGEME (DEPLOYED TO BUCKET)
}
variable "output_bucket_arn" {
  type = string
  default = "arn:aws:s3:::versionedbucket1sample1"<-CHANGEME (DEPLOYED TO BUCKET)

}

# https://docs.aws.amazon.com/codepipeline/latest/userguide/update-change-detection.html#update-change-detection-S3-event 
# sample migration ported into terraform based on the above document

# 1. create trust policy
data "aws_iam_policy_document" "trustpolicyforEB" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com "]
    }

    actions = ["sts:AssumeRole"]
  }
}

# 2. create event bridge rule
resource "aws_iam_role" "Role-for-MyRule" {
  name               = "Role-for-MyRule"
  assume_role_policy = data.aws _iam_policy_document.trustpolicyforEB.json
}

# 3. create a trigger policy for event brdige
data "aws_iam_policy_document" "CodePipeline-Permissions-Policy-For-EB" {
  statement {
    effect = "Allow"

    actions = [
      "codepipeline:StartPipelineExecution",
    ]

    resources = [
      aws_codepipeline.codepipeline.arn
    ]
  }
}

# 4. apply the policy to event brdige role
resource "aws_iam_role_policy" "EB-Role-Policy" {
  name   = "EB-Role-Policy"
  role   = aws_iam_role.Role-for-MyRule.id
  policy = data.aws _iam_policy_document.CodePipeline-Permissions-Policy-For-EB.json
}



# Important event pattern to based the events on
resource "aws_cloudwatch_event_rule" "EnabledS3SourceRule" {
  role_arn = aws_iam_role.Role-for-MyRule.arn
  description   = "Object create events on bucket s3://${aws_s3_bucket.codepipeline_bucket.id}"
  event_pattern = <<EOF
{
  "detail-type": [
    "Object Created"
  ],
  "source": [
    "aws.s3"
  ],
  "detail": {
    "bucket": {
      "name": ["test-bucket-sample-gnu3b"]<-CHANGEME (SOURCE BUCKET)
    },
    "object": {
      "key": [{
        "prefix": "test-"
      }]
    }
  }
}
EOF
}


# 6. set the event target for eventbridge to the codepipeline
resource "aws_cloudwatch_event_target" "EnabledS3SourceRuleTargets" {
  target_id = "codepipeline-AppPipeline"
  rule      = aws_cloudwatch_event_rule.EnabledS3SourceRule.name
  arn = aws_codepipeline.codepipeline.arn
  role_arn = aws_iam_role.Role-for-MyRule.arn
}
# aws events put-targets --rule EnabledS3SourceRule --targets Id=codepipeline-AppPipeline,Arn=arn:aws:codepipeline:us-west-2:80398EXAMPLE:TestPipeline

#-------------------------  ------------------------- Sample CodePipeline Code ------------------------- ------------------------- 
resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline1"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket = aws_s3_bucket.codepipeline_bucket.id
        S3ObjectKey       = "sample"
        PollForSourceChanges = "false"#<------ HERE set this change on Terraform to ensure your S3 bucket is set to EventBased
      }
    }
  }


  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
    #   output_artifacts = ["deploy_output"]
      input_artifacts = ["source_output"]
      configuration = {
        BucketName = var.output_bucket
        Extract = false
        ObjectKey = "sampleoutput"
        # PollForSourceChanges = "false"#<------ HERE set this change on Terraform
      }
    }
  }
}


resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "test-bucket-sample-gnu3b"#CHANGEME (SOURCE BUCKET)
}

resource "aws_s3_bucket_versioning" "codepipeline_bucket_versioning" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.codepipeline_bucket.id
  eventbridge = true #Important change on your SOURCE s3 bucket
}

# resource "aws_s3_bucket_acl" "codepipeline_bucket_acl" {
#   bucket = aws_s3_bucket.codepipeline_bucket.id
#   acl    = "private"
# }

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com "]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-sample-test-role"
  assume_role_policy = data.aws _iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
      var.output_bucket_arn,
      "${var.output_bucket_arn}/*"
      
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws _iam_policy_document.codepipeline_policy.json
}
