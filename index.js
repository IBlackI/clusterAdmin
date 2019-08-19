const needle = require("needle");
const fs = require("fs-extra")

const pluginConfig = require("./config");
const COMPRESS_LUA = false;

module.exports = class remoteCommands {
	constructor(mergedConfig, messageInterface, extras){
		this.messageInterface = messageInterface;
		this.config = mergedConfig;
		this.socket = extras.socket;
		this.instances = {};		
		
		(async ()=>{
			let instanceID = this.config.unique.toString();
			let name = await this.getInstanceName(instanceID);
			this.instance = {name: name, instanceID: instanceID, ip: this.config.publicIP, port: this.config.factorioPort};
			this.socket.on("hello", () => this.socket.emit("registerClusterAdmin", this.instance));
			let hotpatchInstallStatus = await this.checkHotpatchInstallation();
			this.hotpatchStatus = hotpatchInstallStatus;
			this.messageInterface("Hotpach installation status: "+hotpatchInstallStatus);

			if(hotpatchInstallStatus){
				let mainCode = await this.getSafeLua("sharedPlugins/clusterAdmin/lua/control.lua");
				let players = await this.getSafeLua("sharedPlugins/clusterAdmin/lua/cluster_admin_players.lua");
				let camera = await this.getSafeLua("sharedPlugins/clusterAdmin/lua/cluster_admin_camera.lua");
				let spectate = await this.getSafeLua("sharedPlugins/clusterAdmin/lua/cluster_admin_spectate.lua");
				let code = mainCode + players + camera + spectate;
				if(mainCode) var returnValue = await messageInterface(`/silent-command remote.call('hotpatch', 'update', '${pluginConfig.name}', '${pluginConfig.version}', '${code}')`);
				if(returnValue) console.log(returnValue);
				this.messageInterface(`/c remote.call('cluster_admin', 'clearPlayers')`);
			}
			
		})().catch(e => console.log(e));
		
		this.socket.on("clusterAdminServers", (data) => {
			for(let id in data) {
				if (id != this.instance.instanceID) {
					this.messageInterface(`/c remote.call('cluster_admin', 'addServer', '${data[id].name}', '${data[id].ip}', '${data[id].port}')`);
				}
			}
		});
		
		this.socket.on("clusterAdminPlayers", (data) => {
			for(let id in data) {
				let player = data[id]
				if (player.instance != this.instance.name) {
					this.messageInterface(`/c remote.call('cluster_admin', 'addPlayer', '${player.player}', '${player.instance}')`);
				}
			}
		});
		
		this.socket.on("clusterAdminServerRemove", (data) => {
			this.messageInterface(`/c remote.call('cluster_admin', 'removeServer', '${data.name}')`);	
		});
		
		this.socket.on("clusterAdminServerAdd", (data) => {
			if (data.name != this.instance.name) {
				this.messageInterface(`/c remote.call('cluster_admin', 'addServer', '${data.name}', '${data.ip}', '${data.port}')`);
			}
		});
		
		this.socket.on("clusterAdminPlayerJoin", (data) => {
			if (data.instance != this.instance.name) {
				this.messageInterface(`/c remote.call('cluster_admin', 'addPlayer', '${data.player}', '${data.instance}')`);
			}
		});
		
		this.socket.on("clusterAdminPlayerLeft", (data) => {
			if (data.instance != this.instance.name) {
				this.messageInterface(`/c remote.call('cluster_admin', 'removePlayer', '${data.player}')`);
			}
		});
		
		this.socket.on("clusterAdminRunCommand", (data) => {
			this.messageInterface(data.command);
		});
		
	}
	async factorioOutput(data){
		try{
			let lines = data.split("\n");
			lines.forEach(data => {
				if(data.includes("[JOIN]")
					&& data.includes(" joined the game")
					&& !data.includes("[COMMAND]")
					&& !data.includes("[CHAT]")
				){
					let parts = data.split(" ");
					if(parts[2] == "[JOIN]"){
						this.socket.emit("clusterAdminReportPlayerJoin", {player:parts[3], instance:this.instance.name});
					}
				} else if(data.includes("[LEAVE]")
					&& data.includes(" left the game")
					&& !data.includes("[COMMAND]")
					&& !data.includes("[CHAT]")
				){
					let parts = data.split(" ");
					if(parts[2] == "[LEAVE]"){
						this.socket.emit("clusterAdminReportPlayerLeave", {player:parts[3], instance:this.instance.name});
					}
				}  else if(data.includes("[CLUSTER_ADMIN]")
					&& data.includes("[KICK]")
					&& !data.includes("[COMMAND]")
					&& !data.includes("[CHAT]")
				){
					let parts = data.split(" ");
					this.socket.emit("clusterAdminSendRunCommand", {command: "/kick " + parts[2]});
				}  else if(data.includes("[CLUSTER_ADMIN]")
					&& data.includes("[BAN]")
					&& !data.includes("[COMMAND]")
					&& !data.includes("[CHAT]")
				){
					let parts = data.split(" ");
					this.socket.emit("clusterAdminSendRunCommand", {command: "/ban " + parts[2]});
				} else if(data.includes("[KICK]")
					&& data.includes(" was kicked by ")
					&& !data.includes("[COMMAND]")
					&& !data.includes("[CHAT]")
				){
					let parts = data.split(" ");
					this.socket.emit("clusterAdminUnexpectedQuit", parts[3]);
					this.messageInterface(`/c remote.call('cluster_admin', 'removePlayer', '${parts[3]}')`);
				} else if(data.includes("[BAN]")
					&& data.includes(" was banned by ")
					&& !data.includes("[COMMAND]")
					&& !data.includes("[CHAT]")
				){
					let parts = data.split(" ");
					this.socket.emit("clusterAdminUnexpectedQuit", parts[3]);
					this.messageInterface(`/c remote.call('cluster_admin', 'removePlayer', '${parts[3]}')`);
				}
			});
		} catch(e){console.log(e)}
	}
	async getSafeLua(filePath){
		return new Promise((resolve, reject) => {
			fs.readFile(filePath, "utf8", (err, contents) => {
				if(err){
					reject(err);
				} else {
                    // split content into lines
					contents = contents.split(/\r?\n/);

					// join those lines after making them safe again
					contents = contents.reduce((acc, val) => {
                        val = val.replace(/\\/g ,'\\\\');
                        // remove leading and trailing spaces
					    val = val.trim();
                        // escape single quotes
					    val = val.replace(/'/g ,'\\\'');

					    // remove single line comments
                        let singleLineCommentPosition = val.indexOf("--");
                        let multiLineCommentPosition = val.indexOf("--[[");

						if(multiLineCommentPosition === -1 && singleLineCommentPosition !== -1) {
							val = val.substr(0, singleLineCommentPosition);
						}

                        return acc + val + '\\n';
					}, ""); // need the "" or it will not process the first row, potentially leaving a single line comment in that disables the whole code
					if(COMPRESS_LUA) contents = require("luamin").minify(contents);
					
					resolve(contents);
				}
			});
		});
	}
	async checkHotpatchInstallation(){
		let yn = await this.messageInterface("/silent-command if remote.interfaces['hotpatch'] then rcon.print('true') else rcon.print('false') end");
		yn = yn.replace(/(\r\n\t|\n|\r\t)/gm, "");
		if(yn == "true"){
			return true;
		} else if(yn == "false"){
			return false;
		}
	}
	getInstanceName(instanceID){
		return new Promise((resolve, reject) => {
			let instance = this.instances[instanceID];
			if(!instance){
				needle.get(this.config.masterIP+":"+this.config.masterPort+ '/api/slaves', { compressed: true }, (err, response) => {
					if(err || response.statusCode != 200) {
						console.log("Unable to get JSON master/api/slaves, master might be unaccessible");
					} else if (response && response.body) {	
						if(Buffer.isBuffer(response.body)) {console.log(response.body.toString("utf-8")); throw new Error();}
							try {
								for (let index in response.body)
									this.instances[index] = response.body[index].instanceName;
							} catch (e){
								console.log(e);
								return null;
							}
						instance = this.instances[instanceID] 							
						if (!instance) instance = instanceID;  //somehow the master doesn't know the instance	
						resolve(instance);
					}
				});
			} else {
				resolve(instance);
			}
		});
	}
}
