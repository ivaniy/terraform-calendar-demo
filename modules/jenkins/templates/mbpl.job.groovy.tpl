/* Adds a multibranch pipeline job to jenkins
The internet doesn't seem to like this approach. Apparently I should use the DSL plugin.
The Jenkins internal API is what we are using here, and it works just fine except docs
are hard to come by.
I manually configured the job as I wanted, then ran: 
java -jar jenkins-cli.jar -auth admin:secret -s https://localhost:8443/ -noCertificateCheck get-job Cloudy-cron > /tmp/Cloudy-cron.xml
The output of that is used to work out what Java stuff I needed to create here.
*/

import hudson.util.PersistedList
import hudson.model.*
import jenkins.model.Jenkins
import jenkins.branch.*
import jenkins.plugins.git.*
import jenkins.scm.impl.trait.*
import jenkins.scm.api.trait.SCMSourceTrait
import org.jenkinsci.plugins.workflow.multibranch.*
import com.cloudbees.hudson.plugins.folder.*
import com.cloudbees.hudson.plugins.folder.computed.*
import org.jenkinsci.plugins.github_branch_source.*

// Bring some values in from ansible using the jenkins_script modules wierd "args" approach (these are not gstrings)
//String folderName = "folderName"
String jobName = '${jobName}'
String jobScript = '${jobScript}'
String gitRepo = '${gitRepo}'
String gitRepoName = '${gitRepoName}'
String credentialsId = '${credentialsId}'
String repoOwner = '${repoOwner}'
String includes = '${includes}'
String excludes = '${excludes}'
String githubApiUrl = '${githubApiUrl}'
String id = null
String remote = gitRepo
int branch_discover_strategy = ${branch_discover_strategy}
int pull_request_strategy = ${pull_request_strategy}

Jenkins jenkins = Jenkins.instance // saves some typing

// Get the folder where this job should be
//def folder = jenkins.getItem(folderName)
// Create the folder if it doesn't exist
//if (folder == null) {
//  folder = jenkins.createProject(Folder.class, folderName)
//}

// Multibranch creation/update
WorkflowMultiBranchProject mbp
Item item = jenkins.getItem(jobName)
if ( item != null ) {
  // Update case
  mbp = (WorkflowMultiBranchProject) item
} else {
  // Create case
  mbp = jenkins.createProject(WorkflowMultiBranchProject.class, jobName)
}

// Configure the script this MBP uses
mbp.getProjectFactory().setScriptPath(jobScript)

// Add git repo
//boolean ignoreOnPushNotifications = false
GitHubSCMSource gitSCMSource = new GitHubSCMSource(id, githubApiUrl, credentialsId, credentialsId, repoOwner, gitRepoName)

List<SCMSourceTrait> sourceTraits = new ArrayList<>();

if ( pull_request_strategy != 0 ) {
	OriginPullRequestDiscoveryTrait originPullRequestDiscoveryTrait = new OriginPullRequestDiscoveryTrait(pull_request_strategy)  
	// No 2 - implement Behaviours Discover pull requests from origin "The current PR revision"
	// gitSCMSource.setTraits([originPullRequestDiscoveryTrait])
    sourceTraits.add(originPullRequestDiscoveryTrait)
}


if ( branch_discover_strategy != 0 ) { 
	BranchDiscoveryTrait branchDiscoveryTrait = new BranchDiscoveryTrait(branch_discover_strategy) 
	//No 1 - implement Behaviours Discover branches Strategy "Exclude branches that are also field as PRs"
	//No 2 - implement Behaviours Discover branches Strategy "Only branches that are also field as PRs"
    //gitSCMSource.setTraits([branchDiscoveryTrait, wildcardSCMHeadFilterTrait])
    sourceTraits.add(branchDiscoveryTrait)
}

if ( includes != '' || excludes != ''  ) { 
    WildcardSCMHeadFilterTrait  wildcardSCMHeadFilterTrait = new  WildcardSCMHeadFilterTrait(includes, excludes)
    sourceTraits.add(wildcardSCMHeadFilterTrait)   
}

gitSCMSource.setTraits(sourceTraits)


BranchSource branchSource = new BranchSource(gitSCMSource)
branchSource.setStrategy(null)

DefaultOrphanedItemStrategy defaultOrphanedItemStrategy = new DefaultOrphanedItemStrategy(
	true,  // enabled
	10,   // days to keep
	20    // num to keep
	)
mbp.setOrphanedItemStrategy(defaultOrphanedItemStrategy)

// // Disable triggering build
// NoTriggerBranchProperty noTriggerBranchProperty = new NoTriggerBranchProperty()

// // Can be used later to not trigger/trigger some set of branches
// NamedExceptionsBranchPropertyStrategy.Named nebrs_n = new NamedExceptionsBranchPropertyStrategy.Named("change-this", noTriggerBranchProperty)

// // Add an example exception
// BranchProperty defaultBranchProperty = null;
// //NamedExceptionsBranchPropertyStrategy.Named nebrs_n = new NamedExceptionsBranchPropertyStrategy.Named("", defaultBranchProperty)
// NamedExceptionsBranchPropertyStrategy.Named[] nebpsa = [ nebrs_n ]

// BranchProperty[] bpa =  [] //[noTriggerBranchProperty]
// NamedExceptionsBranchPropertyStrategy nebps = new NamedExceptionsBranchPropertyStrategy(bpa, nebpsa)

// branchSource.setStrategy(nebps)

// Remove and replace?
PersistedList sources = mbp.getSourcesList()
sources.clear()
sources.add(branchSource)