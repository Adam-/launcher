/*
 * Copyright (c) 2024, YvesW <https://github.com/YvesW>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
package net.runelite.launcher;

import java.awt.Color;
import javax.swing.SwingUtilities;
import lombok.extern.slf4j.Slf4j;
import static net.runelite.launcher.Launcher.nativesLoaded;

@Slf4j
public class FilePermissionManager
{
	// this is set to RUNASADMIN
	private static final String COMPAT_KEY = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\Layers";

	static void fixJagexLauncherLogin()
	{
		if (!nativesLoaded)
		{
			log.debug("Launcher natives were not loaded. Skipping Jagex Launcher login check.");
			return;
		}

		ProcessHandle current = ProcessHandle.current();

		if (!isRunningFromJagexLauncher() || !isProcessElevated(current.pid()) || isJagexLauncherElevated())
		{
			// not problematic if not running without the Jagex Launcher, if not running elevated,
			// or if both the Jagex Launcher and RL Launcher are running with elevated permissions
			return;
		}

		log.error("RuneLite is running with elevated permissions, but the Jagex launcher is not. Privileged processes " +
			"can't have environment variables passed to them from unprivileged processes. This will cause you to be " +
			"unable to login. Either run RuneLite as a regular user, or run the Jagex launcher as an administrator.");

		// attempt to fix this by removing the compatibility settings
		String command = current.info().command().orElse(null);
		boolean regEdited = false;
		if (command != null)
		{
			regEdited |= regDeleteValue("HKLM", COMPAT_KEY, command); // all users
			regEdited |= regDeleteValue("HKCU", COMPAT_KEY, command); // current user
		}

		if (regEdited)
		{
			log.info("Application compatibility settings have been unset for {}", command);
		}

		showErrorDialog(regEdited);
	}

	private static boolean isRunningFromJagexLauncher()
	{
		// alternatively get the children or descendants of JagexLauncher.exe
		ProcessHandle parent = ProcessHandle.current().parent().orElse(null);
		if (parent != null)
		{
			return parent.info().command().orElse("").contains("JagexLauncher.exe");
		}
		return false;
	}

	private static boolean isJagexLauncherElevated()
	{
		if (!isRunningFromJagexLauncher())
		{
			return false;
		}

		ProcessHandle parent = ProcessHandle.current().parent().orElse(null);
		if (parent != null)
		{
			boolean result = isProcessElevated(parent.pid());
//			log.info("Jagex Launcher is running with elevated permissions: " + result);
			return result;
		}
		return false;
	}

	private static void showErrorDialog(boolean patched)
	{
		String command = ProcessHandle.current().info().command().orElse("RuneLite.exe");
		var sb = new StringBuilder();
		sb.append("Running RuneLite as an administrator is incompatible with the Jagex launcher.");
		if (patched)
		{
			sb.append(" RuneLite has attempted to fix this problem by changing the compatibility settings of ").append(command);
			sb.append(" Try running RuneLite again.");
		}
		sb.append(" If the problem persists, either run the Jagex launcher as administrator, or change the ")
			.append(command).append(" compatibility settings to not run as administrator");

		final var message = sb.toString();
		SwingUtilities.invokeLater(() ->
			new FatalErrorDialog(message)
				.open());
		System.exit(-1);
	}

	private static native boolean isProcessElevated(long pid);

	// Requires elevated permissions. Current valid inputs for key are: "HKCU" and "HKLM"
	private static native boolean regDeleteValue(String key, String subKey, String value);
}
