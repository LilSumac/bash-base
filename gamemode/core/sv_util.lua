-- Various utility functions for the server.
bash.util = bash.util or {};

--
-- bash util Functions
--
function bash.util.sendLoadProgress(ply, msg, done)
	if !checkply(ply) or !msg then return; end
	done = done or false;
	
	local progress = vnet.CreatePacket("util_progress");
	progress:String(msg);
	progress:Bool(done);
	progress:AddTargets(ply);
	progress:Send();
end

--
-- Network Strings
--
util.AddNetworkString("util_progress");