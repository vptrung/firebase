-- local messaging = firebase_messaging:new(session)
-- messaging:send( -- We need recipient to full-fill
-- {
-- 	["message"]= {
-- 		["token"] = '/topics/all',-- <-- this shit is now only obstacle to target certains devices
-- 		["notification"]= {
-- 			["title"]= "FCM Message",
-- 			["body"]= "This is an FCM Message"
-- 		}
-- 	}
-- }, function(res)
-- 	print("sent")
-- end)
-- 
-- messaging:take('topics/all', function(res)
-- 	print("taken")
-- 	print(res.response)
-- end)
-- 

Messaging = {}

function Messaging:new(session)
	local obj = {}
	local session = session

	function obj:request(method, path, data, callback)

		local headers = {}
		local source 

		headers.authorization = session.ID_TOKEN and 
		   string.format('Firebase %s', session.ID_TOKEN)
		or string.format('Bearer %s', session.ACCESS_TOKEN) 

		if method == 'POST' then
			if not type(data) == 'table' then print('data -- Incorrect data as ' .. type(data)) end
			headers['content-type']    = 'application/json'
			source = cjson.encode(data)
		end

		local url = string.format('https://fcm.googleapis.com/v1/projects/%s/messages%s', session.PROJECT_ID, path)
		-- print(url)
		http.request(url, method, function(self,_,res)
			-- print(url)
			local c = res.status
			if c == 200 or c == 204 then
				if callback then callback(res.response) end
				print(res.response) -- Logging
			end
			if c == 401 or c == 403 or c == 400 then
				print("messaging -- can't send message: " .. res.response)
			end
		end, headers, source, option)
	end

	function obj:send(message, callback)
		return obj:request('POST', ':send', message, callback)
	end

	function obj:take(message_id, callback)
		return obj:request('GET', '/' .. tostring(message_id), nil, callback)
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

return Messaging
