hexchat.register("WhoisOnJoinMessage", "0.1", "runs whois on join")


pending = {}
data = {}

-- custom whois function -- adds nickname and context to pending and runs whois
local function cmd_whois(word, eol)
	local nick = word[2]
	local target = word[3]
	if not target then
		target = nick
	end
	table.insert(pending,
			{
				nick = nick, 
				server = hexchat.get_info"server",
				ctx = hexchat.get_context(),
				nameline = nil
			}
		)
	hexchat.command(("QUOTE WHOIS %s %s"):format(nick, target))
	return hexchat.EAT_ALL
end
local function join_cmd_whois(word)
	local nick = word[1]
	target = nick
	table.insert(pending,
			{
				nick = nick, 
				server = hexchat.get_info"server",
				ctx = hexchat.get_context(),
				nameline = ""
			}
		)
	hexchat.command(("QUOTE WHOIS %s %s"):format(nick, target))
	return hexchat.EAT_ALL
end

-- get context of saved whois query
local function pending_ctx(nick, server)
	for _, item in ipairs(pending) do
		if hexchat.nickcmp(item.nick, nick) == 0 and hexchat.nickcmp(item.server, server) == 0 then
			return item.ctx
		end
	end
end

-- handle whois events, save output and eat ouput if recorded in pending
local inside = false
local function handle_whois(event, word)
	if inside then
		return hexchat.EAT_NONE
	end
	local ctx = pending_ctx(word[1], hexchat.get_info"server")
	if not ctx then
		return hexchat.EAT_NONE
	end
	inside = true
	--ctx:emit_print(event, (unpack or table.unpack)(word))
	--ctx:print((event))
	--ctx:print((unpack or table.unpack)(word))
	inside = false
	if event == "WhoIs Name Line" then
		local j = 0
		for i, v in ipairs(pending) do
			if v.ctx == ctx then
				v.nameline = word
				--ctx:print((unpack or table.unpack)(word))
				--ctx:print(v.nameline[1])
				--ctx:print(v.nameline[2])
				--ctx:print(v.nameline[3])
				--ctx:print(v.nameline[4])
				break
			end
		end
	end
	if event == "WhoIs End" then
		local j = 0
		for i, v in ipairs(pending) do
			if v.ctx == ctx then
				local nick = v.nick
				--local nickfqdn = "test"
				local nickfqdn = v.nameline[2] .. "@" .. v.nameline[3]
				local additional_info = v.nameline[4]		
		
				ctx:emit_print("Join", nick, "2", nickfqdn .. " [".. additional_info .."]", "4", "customjoin")
				--ctx:print("User joined...t1:")
				--ctx:print(v.nameline[1])
				--ctx:print("t2:")
				--ctx:print(v.nameline[2])
				--ctx:print("t3:")
				--ctx:print(v.nameline[3])
				--ctx:print("t4:")
				--ctx:print(v.nameline[4])
				j = i
				break
			end
		end
		table.remove(pending, j)
	end
	return hexchat.EAT_HEXCHAT
end

local function handle_join(word)
	-- run whois on join and eat message
	
	--check if nick is already in ctx table
	local ctx = pending_ctx(word[1], hexchat.get_info"server")
	if not ctx then
		join_cmd_whois(word)
		return hexchat.EAT_HEXCHAT
	end
	return hexchat.EAT_NONE
end




--hook into whois2 command (for testing)
hexchat.hook_command("WHOIS2", cmd_whois)
--hook into whois events
local events = {
	"WhoIs Authenticated",
	"WhoIs Away Line",
	"WhoIs Channel/Oper Line",
	"WhoIs End",
	"WhoIs Identified",
	"WhoIs Idle Line with Signon",
	"WhoIs Idle Line",
	"WhoIs Name Line",
	"WhoIs Real Host",
	"WhoIs Server Line",
	"WhoIs Special",
}
for _, event in pairs(events) do
	hexchat.hook_print(event, function(word)return handle_whois(event, word) end)
end
-- hook into join messages
hexchat.hook_print("Join", handle_join)




		--local j = 0
		--for i, v in ipairs(pending) do
		--	if v.ctx == ctx then
		--		j = i
		--		break
		--	end
		--end
		--table.remove(pending, j)