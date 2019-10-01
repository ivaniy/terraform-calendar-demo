# data "template_file" "mbpl_01_job" {
#   template = "${file("${path.module}/templates/mbpl.job.groovy.tpl")}"
#   vars = {
#     jobName = "MBPL-PullRequest"
#     jobScript = "Jenkinsfile" // must be templated
#     gitRepo = "https://github.com/ivaniy/ruby-calendar.git" // must be templated
#     gitRepoName = "ruby-calendar"  // must be templated
#     credentialsId = "GitHubUserToken" // must be templated
#     repoOwner     = "ivaniy" // must be templated
#     includes = "feature*" // must be templated
#     excludes = ""
#     githubApiUrl = "https://api.github.com"
#     pull_request_strategy = true
#     branch_discover_strategy = 0
#   }
# }