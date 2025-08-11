resource "aws_amplify_app" "retail_frontend" {
  name       = "${var.project_name}-retail-frontend"
  repository = "https://github.com/shyamkulkarni/aws-eks-infra"

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - cd eks-decoupled/frontend
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: eks-decoupled/frontend/build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  environment_variables = {
    REACT_APP_API_URL = "https://${aws_lb.retail_api.dns_name}"
  }

  tags = var.tags
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.retail_frontend.id
  branch_name = "main"

  framework = "React"
  stage     = "PRODUCTION"

  environment_variables = {
    REACT_APP_API_URL = "https://${aws_lb.retail_api.dns_name}"
  }
}

resource "aws_amplify_domain_association" "retail_frontend" {
  app_id      = aws_amplify_app.retail_frontend.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "retail"
  }
}