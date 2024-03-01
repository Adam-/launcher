#include <Windows.h>
#include <jni.h>

extern "C" JNIEXPORT jboolean JNICALL Java_net_runelite_launcher_FilePermissionManager_isRunningElevated(JNIEnv *env, jclass clazz, jlong pid) {
	BOOL fRet = false;
	HANDLE hToken = nullptr;
	HANDLE handle = OpenProcess(PROCESS_ALL_ACCESS, TRUE, pid);
	// alternatively use GetCurrentProcess() instead if you'd only want to check the current process
	if (OpenProcessToken(handle, TOKEN_QUERY, &hToken)) {
		TOKEN_ELEVATION Elevation;
		DWORD cbSize = sizeof(TOKEN_ELEVATION);
		if (GetTokenInformation(hToken, TokenElevation, &Elevation, sizeof(Elevation), &cbSize)) {
			fRet = Elevation.TokenIsElevated;
		}
	}
	CloseHandle(handle);
	if (hToken) {
		CloseHandle(hToken);
	}
	bool result = fRet == 1 ? true : false;
	return result;
}