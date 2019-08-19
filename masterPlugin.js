const fs = require("fs");

class masterPlugin {
	constructor({config, pluginConfig, path, socketio, express}){
		this.config = config;
		this.pluginConfig = pluginConfig;
		this.pluginPath = path;
		this.io = socketio;
		this.express = express;

		this.clients = {};
		this.players = {};

		this.io.on("connection", socket => {

			socket.on("registerClusterAdmin", data => {
				console.log("Registered instance " + data.name);
				data.socket = socket;
                this.clients[data.instanceID] = data;
				socket.emit("clusterAdminServers", JSON.parse(JSON.stringify(this.clients, this.replacer)));
				socket.emit("clusterAdminPlayers", this.players);
				this.broadcast("clusterAdminServerAdd", JSON.parse(JSON.stringify(data, this.replacer)));
			});

            socket.on("disconnect", data => {
                for(let id in this.clients) {
                    if(this.clients[id].socket.id == socket.id) {
						let name = this.clients[id].name
                        console.log("Lost connection to instance: " + name);
						delete this.clients[id];
						this.broadcast("clusterAdminServerRemove", {name:name});
						for(let p in this.players) {
							if(this.players[p] == name) {
								this.broadcast("clusterAdminPlayerLeave", {player:p, instance:name});
								delete this.players[p];
							}
						}
                    }
                }
            });
			
			socket.on("clusterAdminReportPlayerJoin", data => {
				console.log(data.player + " Joined " + data.instance);
				this.players[data.player] = data.instance;
				this.broadcast("clusterAdminPlayerJoin", data);
			});
			
			socket.on("clusterAdminReportPlayerLeave", data => {
				console.log(data.player + " left " + data.instance);
				delete this.players[data.player];
				this.broadcast("clusterAdminPlayerLeft", data);
			});
			
			socket.on("clusterAdminSendRunCommand", data => {
				this.broadcast("clusterAdminRunCommand", data);
			});
			
			socket.on("clusterAdminUnexpectedQuit", data => {
				if(this.players[data]) {
					delete this.players[data];
					this.broadcast("clusterAdminPlayerLeft", {player:data, instance:"none"});
				}
			});

		});

	}
	
	replacer(key, value) {
		switch(key) {
			case 'socket':
				return undefined;
			default:
				return value;
		}
	}
	
	broadcast(eventName, data) {
		console.log(eventName + " : " + JSON.stringify(data));
		for(let id in this.clients) {
			this.clients[id].socket.emit(eventName, data);
		}
	}
}
module.exports = masterPlugin;
