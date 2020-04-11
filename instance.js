const plugin = require('lib/plugin');

class InstancePlugin extends plugin.BaseInstancePlugin {
	async init() {
		console.log("Cluster_admin plugin loaded");
	}
}

module.exports = {
	InstancePlugin,
}