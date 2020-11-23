Auth = {}

function Auth:new(project_id)

	local obj = {}
	obj.session = {}
	obj.session.ID_TOKEN = nil 				-- for Anonymous signup
	obj.session.ACCESS_TOKEN = nil		-- for Auth Service Account
	obj.session.PROJECT_ID = project_id -- for Project ID
	--
	-- Auth by Service Account of Firebase,
	-- more secured than anonymous signup.
	--
	function obj:auth_service_account(path, exp_time, callback)
		token = nil
		local serv = {}
		if path and type(path) == 'string' then
			local private_key = sys.load_resource(path)
			if not private_key then error(string.format('Can\'t open file %s', path)) end 
			serv = cjson.decode(private_key) -- saving private_key data to this table
		else
			error('Empty or wrong path format.')
		end
		-- LIBRARY: 
		local json    = cjson
		local base64  = require 'main.services.firebase.libs.base64'
		--
		-- URL for Google OAuth v2
		--
		local url = 'https://www.googleapis.com/oauth2/v4/token'
		--
		-- Really important:
		-- https://firebase.google.com/docs/database/rest/auth#generate_an_access_token
		--
		local scopes = { 
			'https://www.googleapis.com/auth/firebase.database',
			'https://www.googleapis.com/auth/firebase.messaging',
			'https://www.googleapis.com/auth/identitytoolkit',
			'https://www.googleapis.com/auth/userinfo.email'
		}
		local header = {
			alg = 'RS256',
			typ = 'JWT'
		}
		local payloads = {
			iss = serv.client_email or session.CLIENT_EMAIL,
			scope = table.concat(scopes, ' '),
			aud = url,
			exp = os.time() + exp_time,
			iat = os.time(),
		}
		local signature = nil
		local key = serv.private_key or session.PRIVATE_KEY
		--
		-- ensure { headers . payloads } is base64url :
		--
		header = assert(base64.encode(json.encode(header)))
		payloads = assert(base64.encode(json.encode(payloads)))
		signature = assert(rsa.sign_pkey(header .. '.' .. payloads, key))
		local jwt = header .. '.' .. payloads .. '.' .. signature
		--
		-- into assertions:
		--
		local assertions = {
			assertion   = jwt,
			grant_type  = 'urn:ietf:params:oauth:grant-type:jwt-bearer'
		}
		--
		-- Take this simple and easy, inspired from clean node.js implementation:
		-- https://www.mmbyte.com/article/62717.html
		--
		http.request(url, 'POST', function(self,_,res)
			if res.status == 200 then
				local result = cjson.decode(res.response)
				-- for k,v in pairs(result) do print(k .. " -- " .. v) end 
				obj.session.ACCESS_TOKEN = result.access_token
				print("database -- Granted Access. Expire in " 
					.. math.floor(result.expires_in/60) .. " minutes")
				callback(obj.session) -- because this is what auth do.
			else
				print("database -- " .. res.status .. ": " .. cjson.decode(res.response).error_description)
			end
		end,
		nil, cjson.encode(assertions), nil)
	end
	--
	-- Sample curl to test :
	--
	-- curl 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=API_KEY' \
	-- -H 'Content-Type: application/json' --data-binary '{"returnSecureToken":true}'
	--
	function obj:auth_by_apikey(api_key, callback)
		access_token = nil -- clean up to avoid mistaken between 2 type of auth.
		local token_url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' .. api_key
		local headers = {
			['Content-Type'] = 'application/json'
		}
		local post_data = { ["returnSecureToken"] = true }

		local req_token = http.request(token_url, 'POST', function(self,_,res)
			print("database -- got res: " .. res.response)
			token = cjson.decode(res.response)["idToken"]
			if token then 
				-- print("database -- token=" .. token)
				obj.session.ID_TOKEN = token
				callback(token)
			else
				print("database -- token: nil")
			end
		end,
		headers, cjson.encode(post_data), nil)
	end


	setmetatable(obj, self)
	self.__index = self
	return obj
end

return Auth