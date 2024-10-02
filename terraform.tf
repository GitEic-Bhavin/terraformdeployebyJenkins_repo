# create S3 Bucket

provider "aws" {
  regionn = "ap-south-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-bhavin"
  acl    = "private"

  tags = {

    Name = "my-bucket-bhavin"
    owner = "bhavin.bhavsar@einfochips.com"
    DM = "Sachin Koshti"
    Department = "PES"
    End_Date = "1 Oct 2024"

  }
#   depends_on = [ aws_iam_policy.s3_policy ]

}

# Create S3 read policy for public access
# resource "aws_s3_bucket_policy" "public-policy" {
#     bucket = aws_s3_bucket.my_bucket.id
    
#     policy = <<EOF
# {

#     "Version": "2012-10-17",
#     "Statement": [
#         {
#         "Sid": "PublicReadGetObject",
#         "Effect": "Allow",
#         "Principal": "*",
#         "Action": "s3:GetObject",
#         "Resource": [
#             "arn:aws:s3:::${aws_s3_bucket.my_bucket.id}",
#             "${aws_s3_bucket.my_bucket.arn}/*"
#         ]
#         }
#     ]
# }
# EOF
# }

# Create S3 read policy for public by Trun on Enable ACL
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "example3" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
    
  }
}

# Make Public Using ACL Enable
resource "aws_s3_bucket_acl" "make_public" {
 
    depends_on = [ aws_s3_bucket_ownership_controls.example3 ]

    bucket = aws_s3_bucket.my_bucket.id
    acl = "public-read"
  
}

resource "aws_s3_bucket_object" "my_object_1" {
    
  bucket = aws_s3_bucket.my_bucket.id
  key    = "Shiva.jpg"  # The name of the object
  source = "/home/einfochips/Downloads/Shiva.jpg"  # Local path to the file
  acl    = "public-read"  # Set the ACL to public-read
}
# create Role name for service EC2
resource "aws_iam_role" "ec2-role" {
    name = "EC2RoleforS3-bhavin"
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
}

# Create EC2 IAM Profile
resource "aws_iam_instance_profile" "ec2-role-profile" {
    name = "EC2RoleforS3-bhavin"
    role = aws_iam_role.ec2-role.name
  
}

# Create S3 policy
resource "aws_iam_policy" "s3_policy" {
    name = "s3-policy-bhavin"
    description = "S3 read access by EC2"

    policy = jsonencode({
        Version: "2012-10-17"
        Statement = [
            {
                Action = [
                    "s3:GetObject",
                    "s3:ListBucket"
                ]
                Effect = "Allow",
                Resource = [
                    # aws_s3_bucket.my-bucket.arn
                    "${aws_s3_bucket.my_bucket.arn}/*"
                ]
            },
        ]
    })
  
}

# attache s3 policy to ec2 role
resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
    role = aws_iam_role.ec2-role.name

    policy_arn = aws_iam_policy.s3_policy.arn
  
}

###############################################
data "aws_vpc" "default" {
    id = "vpc-3973fe50"
}

# To use My IP as CIDR block
data "http" "myip" {
  url = "https://ipv4.icanhazip.com/"
}

# Create & Attach IAM EC2 Role to Instance
resource "aws_instance" "master" {
    ami = "ami-0522ab6e1ddcc7055"
    instance_type = "t2.micro"
    iam_instance_profile = aws_iam_instance_profile.ec2-role-profile.name
    vpc_security_group_ids = [aws_security_group.master_sg.id]
    # subnet_id = var.pub_sub_id
  
    key_name = "bhavin-tf-key-${terraform.workspace}"

    tags = {
        Name = "bhavin-ec2-tf"
        owner = "bhavin.bhavsar@einfochips.com"
        DM = "Sachin Koshti"
        Department = "PES"
        End_Date = "1 Oct 2024"

    }

}


resource "aws_security_group" "master_sg" {
    name = "Bhavin-SG-tf"
    vpc_id = data.aws_vpc.default.id
    # subnet_id     = var.pub_sub_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]

    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

# OutBound Rule
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
tags = {
        Name = "Bhavin-SG-tf"
        owner = "bhavin.bhavsar@einfochips.com"
        DM = "Sachin Koshti"
        Department = "PES"
        End_Date = "1 Oct 2024"

    }
}

# Generate SSH Key
resource "aws_key_pair" "tf-key-pair" {
    key_name = "bhavin-tf-key-${terraform.workspace}"
    public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
    algorithm = "RSA"
    rsa_bits = 4096
}
resource "local_file" "tf-key" {
    content = tls_private_key.rsa.private_key_pem
    filename = "bhavin-tf-key-${terraform.workspace}.pem"
    file_permission = 0400
}


