Database = {}

function Database:new(session)
	--
	-- saving info 
	--
	local obj = {}
	obj.session = session
	
	local function base_request(session, path, callback, data, method, order)
		--
		if not (session.ID_TOKEN or session.ACCESS_TOKEN) then 
			print(session.ACCESS_TOKEN)
			print("database -- nil token")
			return 
		end
		local token = session.ID_TOKEN and '?auth=' .. session.ID_TOKEN or '?access_token=' .. session.ACCESS_TOKEN

		local url 
		
		if order then 
			local order_args = '&orderBy=\"' .. order ..'\"' --.. '&print=pretty'
			url = 'https://' .. session.PROJECT_ID .. '.firebaseio.com' .. path ..  '.json' .. token .. order_args
			
			print("request url: ", url) 
			
		else
			url = 'https://' .. session.PROJECT_ID .. '.firebaseio.com' .. path ..  '.json' .. token
		end

		--
		http.request(url, method, 
			function(self,_, response) 
				callback(response) end, 
			nil, cjson.encode(data), nil)
	end
	--
	-- GET
	--
	function obj:get(path, callback, order)
		base_request(self.session, path, callback, nil, 'GET', order)
	end
	--
	-- PUT
	--
	function obj:put(path, callback, data)
		base_request(self.session, path, callback, data, 'PUT', nil)
	end
	--
	-- POST
	--
	function obj:post(path, callback, post_data)
		base_request(self.session, path, callback, post_data, 'POST', nil)
	end
	--
	-- PATCH
	--
	function obj:patch(path, callback, post_data)
		base_request(self.session, path, callback, post_data, 'PATCH', nil)
	end
	--
	-- DELETE
	--
	function obj:delete(path, callback)
		base_request(self.session, path, callback, nil, 'DELETE', nil)
	end
	-- 
	-- assign obj -> Database
	--
	setmetatable(obj, self)
	self.__index = self
	return obj
end

return Database