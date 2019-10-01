resource "aws_iam_policy" "jenkins_policy" {
  name        = "jenkins-ec2-policy"
  description = "Jenkins access to EC2 creation"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ec2scheduled.amazonaws.com",
                        "elasticloadbalancing.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "transitgateway.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role" "jenkins_role" {
  name = "Jenkins_Access"
  description = "Jenkins access to EC2 creation"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "JenkinsRole"
  }
}

resource "aws_iam_policy_attachment" "jenkins_policy_attach" {
  name       = "jenkins-policy-attachment"
  roles      = ["${aws_iam_role.jenkins_role.name}"]
  policy_arn = "${aws_iam_policy.jenkins_policy.arn}"
}

resource "aws_iam_instance_profile" "jenkins_iam_profile" {
  name  = "jenkins_iam_profile"
  role = "${aws_iam_role.jenkins_role.name}"
}