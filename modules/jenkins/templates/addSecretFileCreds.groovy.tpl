#!groovy

// imports
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl;
import hudson.util.Secret
import jenkins.model.Jenkins
import java.nio.file.*;

// parameters
def jenkinsSecretFileParameters = [
  description:  '${description}',
  id:           '${id}',
  private_key:  '''${private_key}''', 
  file_name:    '${file_name}' 
]

def secretBytes = SecretBytes.fromBytes(jenkinsSecretFileParameters.private_key.getBytes())

// get Jenkins instance
Jenkins jenkins = Jenkins.getInstance()

// get credentials domain
def domain = Domain.global()


def credentials = new FileCredentialsImpl(
	CredentialsScope.GLOBAL, 
	jenkinsSecretFileParameters.id, 
	jenkinsSecretFileParameters.description, 
	jenkinsSecretFileParameters.file_name,
	jenkinsSecretFileParameters.secretBytes)

//SystemCredentialsProvider.instance.store.addCredentials(Domain.global(), credentials)

// get credentials store
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// add credential to store
store.addCredentials(domain, credentials)

// save to disk
jenkins.save()



