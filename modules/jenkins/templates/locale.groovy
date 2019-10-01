def pluginWrapper = jenkins.model.Jenkins.instance.getPluginManager().getPlugin('locale')
def plugin = pluginWrapper.getPlugin()

plugin.setSystemLocale('English')
plugin.setIgnoreAcceptLanguage(true)