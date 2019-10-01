import com.amazonaws.services.ec2.model.InstanceType
import com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import hudson.model.*
import hudson.plugins.ec2.AmazonEC2Cloud
import hudson.plugins.ec2.ConnectionStrategy
import hudson.plugins.ec2.AMITypeData
import hudson.plugins.ec2.EC2Tag
import hudson.plugins.ec2.SlaveTemplate
import hudson.plugins.ec2.SpotConfiguration
import hudson.plugins.ec2.UnixData
import jenkins.model.Jenkins


def amiType = new UnixData('', '', '', '22')
// parameters
def SlaveTemplateParameters = [
  ami:                      '${ami}',   // must be templated
  zone:                     '${aws_az}',    // must be templated
  spotConfiguration:        null,
  securityGroups:           '${securityGroups}',         // must be templated
  remoteFS:                 '/home/ubuntu/jenkins',  // must be templated
  type:                     InstanceType.fromValue('t2.micro'), // must be templated
  ebsOptimized:             false,
  labelString:              'Ruby',      // default was aws.ec2.us.east.jenkins.slave
  mode:                     Node.Mode.NORMAL,
  description:              'Master Image',    // must be templated
  initScript:               '',
  tmpDir:                   '',
  userData:                 '',
  numExecutors:             '1',           // must be templated  
  remoteAdmin:              'ubuntu',      // must be templated
  amiType:                  new UnixData('', '', '', '22'),
  jvmopts:                  '',
  stopOnTerminate:          false,               // must be templated
  subnetId:                 '${subnetId}',  // must be templated
  tags:                     [new EC2Tag('Name', 'Jenkins Ruby Slave')], // must be templated
  idleTerminationMinutes:   '30',              // must be templated
  minimumNumberOfInstances: 0,
  instanceCapStr:           '2',      // must be templated 2147483647
  iamInstanceProfile:       '',
  deleteRootOnTermination:  true,
  useEphemeralDevices:      false,
  useDedicatedTenancy:      false,
  launchTimeoutStr:         '',
  associatePublicIp:        false,       // must be templated where is setted public and private networks
  customDeviceMapping:      '',
  connectBySSHProcess:      false,            
  monitoring:               false,
  t2Unlimited:              false,
  connectionStrategy:       ConnectionStrategy.backwardsCompatible(
    false, // boolean usePrivateDnsName
    false, // boolean connectUsingPublicIp, 
    false),// boolean associatePublicIp  
  maxTotalUses:             -1  
]

def AmazonEC2CloudParameters = [
  cloudName:      'AWS',   // must be templated
  credentialsId:  '',      // default was setuped
  instanceCapStr: '5',    // must be templated # quantity of max avaiable instances !!!
  privateKey:     '''${private_key}''', //must be templated
  region: '${aws_region}',  //must be templated
  useInstanceProfileForCredentials: false  
]
 
def AWSCredentialsImplParameters = [
//  id:           'jenkins-aws-key',
//  description:  'Jenkins AWS IAM key',
//  accessKey:    '01234567890123456789',
//  secretKey:    '01345645657987987987987987987987987987'
]
 
// https://github.com/jenkinsci/aws-credentials-plugin/blob/aws-credentials-1.23/src/main/java/com/cloudbees/jenkins/plugins/awscredentials/AWSCredentialsImpl.java
// AWSCredentialsImpl aWSCredentialsImpl = new AWSCredentialsImpl(
//   CredentialsScope.GLOBAL,
//   AWSCredentialsImplParameters.id,
//   AWSCredentialsImplParameters.accessKey,
//   AWSCredentialsImplParameters.secretKey,
//   AWSCredentialsImplParameters.description
// )
 
// https://github.com/jenkinsci/ec2-plugin/blob/master/src/main/java/hudson/plugins/ec2/SlaveTemplate.java
// public SlaveTemplate(
//   String ami, 
//   String zone, 
//   SpotConfiguration spotConfig, 
//   String securityGroups, 
//   String remoteFS,
//   InstanceType type, 
//   boolean ebsOptimized,
//   String labelString, 
//   Node.Mode mode, 
//   String description, 
//   String initScript,
//   String tmpDir, 
//   String userData, 
//   String numExecutors, 
//   String remoteAdmin, 
//   AMITypeData amiType, 
//   String jvmopts,
//   boolean stopOnTerminate, 
//   String subnetId, 
//   List<EC2Tag> tags, 
//   String idleTerminationMinutes, 
//   int minimumNumberOfInstances,
//   String instanceCapStr, 
//   String iamInstanceProfile, 
//   boolean deleteRootOnTermination,
//   boolean useEphemeralDevices, 
//   boolean useDedicatedTenancy, 
//   String launchTimeoutStr, 
//   boolean associatePublicIp,
//   String customDeviceMapping, 
//   boolean connectBySSHProcess, 
//   boolean monitoring,
//   boolean t2Unlimited, 
//   ConnectionStrategy connectionStrategy, 
//   int maxTotalUses)

SlaveTemplate slaveTemplate1 = new SlaveTemplate(
  SlaveTemplateParameters.ami,
  SlaveTemplateParameters.zone,
  SlaveTemplateParameters.spotConfiguration,
  SlaveTemplateParameters.securityGroups,
  SlaveTemplateParameters.remoteFS,
  SlaveTemplateParameters.type,
  SlaveTemplateParameters.ebsOptimized,
  SlaveTemplateParameters.labelString,
  SlaveTemplateParameters.mode,
  SlaveTemplateParameters.description,
  SlaveTemplateParameters.initScript,
  SlaveTemplateParameters.tmpDir,
  SlaveTemplateParameters.userData,
  SlaveTemplateParameters.numExecutors,
  SlaveTemplateParameters.remoteAdmin,
  SlaveTemplateParameters.amiType,
  SlaveTemplateParameters.jvmopts,
  SlaveTemplateParameters.stopOnTerminate,
  SlaveTemplateParameters.subnetId,
  SlaveTemplateParameters.tags,
  SlaveTemplateParameters.idleTerminationMinutes,
  SlaveTemplateParameters.minimumNumberOfInstances,
  SlaveTemplateParameters.instanceCapStr,
  SlaveTemplateParameters.iamInstanceProfile,
  SlaveTemplateParameters.deleteRootOnTermination,
  SlaveTemplateParameters.useEphemeralDevices,
  SlaveTemplateParameters.useDedicatedTenancy,
  SlaveTemplateParameters.launchTimeoutStr,
  SlaveTemplateParameters.associatePublicIp,
  SlaveTemplateParameters.customDeviceMapping,
  SlaveTemplateParameters.connectBySSHProcess,
  SlaveTemplateParameters.monitoring,
  SlaveTemplateParameters.t2Unlimited,
  SlaveTemplateParameters.connectionStrategy,
  SlaveTemplateParameters.maxTotalUses
)


// https://github.com/jenkinsci/ec2-plugin/blob/master/src/main/java/hudson/plugins/ec2/AmazonEC2Cloud.java
// public AmazonEC2Cloud(
//   String cloudName, 
//   boolean useInstanceProfileForCredentials, 
//   String credentialsId, 
//   String region, 
//   String privateKey, 
//   String instanceCapStr, 
//   List<? extends SlaveTemplate> templates, 
//   String roleArn, 
//   String roleSessionName)

AmazonEC2Cloud amazonEC2Cloud = new AmazonEC2Cloud(
  AmazonEC2CloudParameters.cloudName,
  AmazonEC2CloudParameters.useInstanceProfileForCredentials,
  AmazonEC2CloudParameters.credentialsId,
  AmazonEC2CloudParameters.region,
  AmazonEC2CloudParameters.privateKey,
  AmazonEC2CloudParameters.instanceCapStr,
  [slaveTemplate1],
  '',
  ''
)
 
// get Jenkins instance
Jenkins jenkins = Jenkins.getInstance()
 
// get credentials domain
def domain = Domain.global()
 
// get credentials store
def store = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
 
// add credential to store
//store.addCredentials(domain, aWSCredentialsImpl)
 
// add cloud configuration to Jenkins
jenkins.clouds.add(amazonEC2Cloud)
 
// save current Jenkins state to disk
jenkins.save()