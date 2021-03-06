module Rules.Setup (setupRules) where

import qualified System.Info

import Base
import CmdLineFlag
import Rules.Actions
import Rules.Generators.GhcAutoconfH

setupRules :: Rules ()
setupRules = do
    [configFile, "settings", configH] &%> \[cfg, settings, cfgH] -> do
        need [ settings <.> "in", cfgH <.> "in", "configure" ]
        case cmdSetup of
            RunSetup configureArgs -> do
                -- We cannot use windowsHost here due to a cyclic dependency
                when (System.Info.os == "mingw32") $ do
                    putBuild "| Checking for Windows tarballs..."
                    quietly $ cmd [ "bash"
                                  , "mk/get-win32-tarballs.sh"
                                  , "download"
                                  , System.Info.arch ]
                runConfigure "." [] [configureArgs]
            SkipSetup -> unlessM (doesFileExist cfg) $
                putError $ "Configuration file " ++ cfg ++ " is missing."
                    ++ "\nRun the configure script either manually or via the "
                    ++ "build system by passing --setup[=CONFIGURE_ARGS] flag."

    ["configure", configH <.> "in"] &%> \_ -> do
        need ["configure.ac"]
        case cmdSetup of
            RunSetup _ -> do
                putBuild "| Running boot..."
                quietly $ cmd (EchoStdout False) "perl boot"
            SkipSetup -> unlessM (doesFileExist "configure") $
                putError $ "The configure script is missing."
                    ++ "\nRun the boot script either manually or via the "
                    ++ "build system by passing --setup[=CONFIGURE_ARGS] flag."
