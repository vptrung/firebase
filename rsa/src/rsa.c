#define EXTENSION_NAME rsa
#define LIB_NAME "rsa"
#define MODULE_NAME "rsa"

#define DLIB_LOG_DOMAIN LIB_NAME

#include <dmsdk/sdk.h>
#include <dmsdk/dlib/crypt.h>
#include <stdlib.h>
#include <string>

static int sign_pkey(lua_State* L) {
	// USAGE: 
	// unsigned char * RS256SignKey( unsigned char * message, unsigned char * private_key )
	//
	unsigned char * message = (unsigned char*)lua_tostring(L, 1);
	unsigned char * private_key = (unsigned char*)lua_tostring(L, 2);
	unsigned char * result = dmCrypt::RS256SignKey( message, private_key );
	// RESULT:
	lua_pushstring(L, (char*)result);
	
	return 1;
}

static const luaL_reg Module_methods[] =
{
	{"sign_pkey", sign_pkey},
	{0, 0}
};

static void LuaInit(lua_State* L)
{
	int top = lua_gettop(L);
	luaL_register(L, MODULE_NAME, Module_methods);

	lua_pop(L, 1);
	assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeRSA(dmExtension::AppParams* params)
{
	return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeRSA(dmExtension::Params* params)
{
	LuaInit(params->m_L);
	return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeRSA(dmExtension::AppParams* params)
{
	return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeRSA(dmExtension::Params* params)
{
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(EXTENSION_NAME, LIB_NAME, AppInitializeRSA, AppFinalizeRSA, InitializeRSA, 0, 0, FinalizeRSA)