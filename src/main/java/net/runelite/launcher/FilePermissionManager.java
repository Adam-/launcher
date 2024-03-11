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
import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JOptionPane;
import javax.swing.UIManager;
import lombok.extern.slf4j.Slf4j;
import static net.runelite.launcher.Launcher.nativesLoaded;

@Slf4j
public class FilePermissionManager
{
	private static final Color DARKER_GRAY_COLOR = new Color(30, 30, 30);

	static void fixJagexLauncherLogin()
	{
		if (!nativesLoaded)
		{
			log.debug("Launcher natives were not loaded. Skipping Jagex Launcher login check.");
			return;
		}

		if (isNotJagexLauncherChild() || !isRunningElevated() || isJagexLauncherElevated())
		{
			// not problematic if not running without the Jagex Launcher, if not running elevated,
			// or if both the Jagex Launcher and RL Launcher are running with elevated permissions
			return;
		}

		log.info("RuneLite is running with elevated permissions, while the Jagex Launcher is not.");
		log.info("Deleting compatibility registry keys.");
		deleteRegCompatKey("HKLM"); // all users
		deleteRegCompatKey("HKCU"); // current user

		okOptionPaneCompat();
	}

	private static boolean isNotJagexLauncherChild()
	{
		// alternatively get the children or descendants of JagexLauncher.exe
		ProcessHandle parent = ProcessHandle.current().parent().orElse(null);
		if (parent != null)
		{
			return !parent.info().command().orElse("-").contains("JagexLauncher.exe");
		}
		return true;
	}

	private static boolean isRunningElevated()
	{
		return isProcessElevated(ProcessHandle.current().pid());
	}

	private static native boolean isProcessElevated(long pid);

	private static boolean isJagexLauncherElevated()
	{
		if (isNotJagexLauncherChild())
		{
			return false;
		}

		ProcessHandle parent = ProcessHandle.current().parent().orElse(null);
		if (parent != null)
		{
			boolean result = isProcessElevated(parent.pid());
			log.info("Jagex Launcher is running with elevated permissions: " + result);
			return result;
		}
		return false;
	}

	private static void deleteRegCompatKey(String rootKey)
	{
		String subKey = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\Layers";
		ProcessHandle.current().info().command().ifPresent(value -> regDeleteValue(rootKey, subKey, value));
	}

	// Requires elevated permissions. Current valid inputs for key are: "HKCU" and "HKLM"
	private static native boolean regDeleteValue(String key, String subKey, String value);

	private static void okOptionPaneCompat()
	{
		try (var in = FilePermissionManager.class.getResourceAsStream("runelite_128.png"))
		{
			assert in != null;
			ImageIcon icon = new ImageIcon(ImageIO.read(in));
			icon = new ImageIcon(icon.getImage().getScaledInstance(64, 64, java.awt.Image.SCALE_SMOOTH));
			UIManager.put("OptionPane.background", DARKER_GRAY_COLOR);
			UIManager.put("Panel.background", DARKER_GRAY_COLOR);
			UIManager.put("OptionPane.messageForeground", Color.WHITE);
			String title = "RuneLite - Compatibility settings problems detected";
			String message = "Running RuneLite with elevated permissions causes login problems when using the Jagex Launcher.\n"
				+ "RuneLite has attempted to remedy the problem. Please relaunch RuneLite via the Jagex Launcher.";

			String[] options = {"Ok"};
			JOptionPane.showOptionDialog(null,
				message,
				title,
				JOptionPane.DEFAULT_OPTION,
				JOptionPane.INFORMATION_MESSAGE,
				icon,
				options,
				null);
		}
		catch (Exception ex)
		{
			log.debug("Jagex Launcher suggestion: error showing JOptionPane.", ex);
		}
		System.exit(0);
	}
}
