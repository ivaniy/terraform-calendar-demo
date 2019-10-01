#!groovy

// imports
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl;
import hudson.util.Secret
import jenkins.model.Jenkins

// parameters
def jenkinsSecretTextParameters = [
  description:  '${description}',
  id:           '${id}',
  secret:       Secret.fromString('${secret}'),  // must be template
]

// get Jenkins instance
Jenkins jenkins = Jenkins.getInstance()

// get credentials domain
def domain = Domain.global()

def credentials = new StringCredentialsImpl(
	CredentialsScope.GLOBAL, 
	jenkinsSecretTextParameters.id, 
	jenkinsSecretTextParameters.description, 
	jenkinsSecretTextParameters.secret)

//SystemCredentialsProvider.instance.store.addCredentials(Domain.global(), credentials)

// get credentials store
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// add credential to store
store.addCredentials(domain, credentials)

// save to disk
jenkins.save()



