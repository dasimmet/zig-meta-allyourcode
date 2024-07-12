const std = @import("std");

// (
//     rm -r build/bootstrap*
//     mkdir -p build/bootstrap;cd build/bootstrap/;CC="zig cc" CXX="zig c++" MAKEFLAGS="-j8" ../../configure 2>&1 > ../bootstrap.log)

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bs = b.addExecutable(.{
        .name = "bootstrap",
        .target = target,
        .optimize = optimize,
    });
    bs.bundle_compiler_rt = true;
    bs.linkLibC();
    bs.linkLibCpp();
    // librhash
    bs.defineCMacro("NO_IMPORT_EXPORT", null);
    // kwsys
    bs.defineCMacro("_GNU_SOURCE", null);
    bs.defineCMacro("KWSYS_STRING_C", null);
    bs.defineCMacro("KWSYS_NAMESPACE", "cmsys");
    // cmake
    bs.defineCMacro("_FILE_OFFSET_BITS", "64");
    bs.defineCMacro("CMAKE_BOOTSTRAP_BINARY_DIR", b.install_path);
    bs.defineCMacro("CMAKE_BOOTSTRAP_SOURCE_DIR", b.pathFromRoot(""));
    bs.defineCMacro("CMAKE_BOOTSTRAP", null);
    bs.defineCMacro("CMake_HAVE_CXX_MAKE_UNIQUE", "1");
    bs.defineCMacro("CMake_HAVE_CXX_FILESYSTEM", "1");

    const generated_headers = cmBootstrapHeaders(b);
    bs.addIncludePath(generated_headers);
    bs.addIncludePath(b.path("build/bootstrap/Bootstrap.cmk"));
    bs.addIncludePath(b.path("Utilities"));
    bs.addIncludePath(b.path("Utilities/std"));
    bs.addIncludePath(b.path("Utilities/cmlibuv/src"));
    bs.addIncludePath(b.path("Utilities/cmlibuv/include"));
    bs.addIncludePath(b.path("Utilities/cmlibrhash/librhash"));
    bs.addIncludePath(b.path("Source"));
    bs.addIncludePath(b.path("Source/LexerParser"));

    bs.addCSourceFiles(.{
        .files = LIBUV_C_SOURCES,
        .root = b.path("Utilities/cmlibuv"),
    });
    bs.addCSourceFiles(.{
        .files = LIBRHASH_C_SOURCES,
        .root = b.path("Utilities/cmlibrhash"),
    });
    bs.addCSourceFiles(.{
        .files = CMAKE_CXX_SOURCES,
        .root = b.path("Source"),
    });
    b.installArtifact(bs);
    const run = b.addRunArtifact(bs);
    b.step("run", "run").dependOn(&run.step);
}

const LIBUV_C_SOURCES = &.{
    "src/strscpy.c",
    "src/strtok.c",
    "src/timer.c",
    "src/uv-common.c",
    "src/unix/cmake-bootstrap.c",
    "src/unix/core.c",
    "src/unix/fs.c",
    "src/unix/loop.c",
    "src/unix/loop-watcher.c",
    "src/unix/no-fsevents.c",
    "src/unix/pipe.c",
    "src/unix/poll.c",
    "src/unix/posix-hrtime.c",
    "src/unix/posix-poll.c",
    "src/unix/process.c",
    "src/unix/signal.c",
    "src/unix/stream.c",
    "src/unix/tcp.c",
    "src/unix/tty.c",
};

const LIBRHASH_C_SOURCES = &.{
    "librhash/algorithms.c",
    "librhash/byte_order.c",
    "librhash/hex.c",
    "librhash/md5.c",
    "librhash/rhash.c",
    "librhash/sha1.c",
    "librhash/sha256.c",
    "librhash/sha3.c",
    "librhash/sha512.c",
    "librhash/util.c",
};

const CMAKE_CXX_SOURCES = &.{
    "cmAddCompileDefinitionsCommand.cxx",
    "cmAddCustomCommandCommand.cxx",
    "cmAddCustomTargetCommand.cxx",
    "cmAddDefinitionsCommand.cxx",
    "cmAddDependenciesCommand.cxx",
    "cmAddExecutableCommand.cxx",
    "cmAddLibraryCommand.cxx",
    "cmAddSubDirectoryCommand.cxx",
    "cmAddTestCommand.cxx",
    "cmArgumentParser.cxx",
    "cmBinUtilsLinker.cxx",
    "cmBinUtilsLinuxELFGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsLinuxELFLinker.cxx",
    "cmBinUtilsLinuxELFObjdumpGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsMacOSMachOGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsMacOSMachOLinker.cxx",
    "cmBinUtilsMacOSMachOOToolGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsWindowsPEGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsWindowsPEDumpbinGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsWindowsPELinker.cxx",
    "cmBinUtilsWindowsPEObjdumpGetRuntimeDependenciesTool.cxx",
    "cmBlockCommand.cxx",
    "cmBreakCommand.cxx",
    "cmBuildCommand.cxx",
    "cmCMakeLanguageCommand.cxx",
    "cmCMakeMinimumRequired.cxx",
    "cmList.cxx",
    "cmCMakePath.cxx",
    "cmCMakePathCommand.cxx",
    "cmCMakePolicyCommand.cxx",
    "cmCPackPropertiesGenerator.cxx",
    "cmCacheManager.cxx",
    "cmCommand.cxx",
    "cmCommandArgumentParserHelper.cxx",
    "cmCommands.cxx",
    "cmCommonTargetGenerator.cxx",
    "cmComputeComponentGraph.cxx",
    "cmComputeLinkDepends.cxx",
    "cmComputeLinkInformation.cxx",
    "cmComputeTargetDepends.cxx",
    "cmConsoleBuf.cxx",
    "cmConditionEvaluator.cxx",
    "cmConfigureFileCommand.cxx",
    "cmContinueCommand.cxx",
    "cmCoreTryCompile.cxx",
    "cmCreateTestSourceList.cxx",
    "cmCryptoHash.cxx",
    "cmCustomCommand.cxx",
    "cmCustomCommandGenerator.cxx",
    "cmCustomCommandLines.cxx",
    "cmCxxModuleMapper.cxx",
    "cmCxxModuleUsageEffects.cxx",
    "cmDefinePropertyCommand.cxx",
    "cmDefinitions.cxx",
    "cmDocumentationFormatter.cxx",
    "cmELF.cxx",
    "cmEnableLanguageCommand.cxx",
    "cmEnableTestingCommand.cxx",
    "cmEvaluatedTargetProperty.cxx",
    "cmExecProgramCommand.cxx",
    "cmExecuteProcessCommand.cxx",
    "cmExpandedCommandArgument.cxx",
    "cmExperimental.cxx",
    "cmExportBuildFileGenerator.cxx",
    "cmExportFileGenerator.cxx",
    "cmExportInstallFileGenerator.cxx",
    "cmExportSet.cxx",
    "cmExportTryCompileFileGenerator.cxx",
    "cmExprParserHelper.cxx",
    "cmExternalMakefileProjectGenerator.cxx",
    "cmFileCommand.cxx",
    "cmFileCommand_ReadMacho.cxx",
    "cmFileCopier.cxx",
    "cmFileInstaller.cxx",
    "cmFileSet.cxx",
    "cmFileTime.cxx",
    "cmFileTimeCache.cxx",
    "cmFileTimes.cxx",
    "cmFindBase.cxx",
    "cmFindCommon.cxx",
    "cmFindFileCommand.cxx",
    "cmFindLibraryCommand.cxx",
    "cmFindPackageCommand.cxx",
    "cmFindPackageStack.cxx",
    "cmFindPathCommand.cxx",
    "cmFindProgramCommand.cxx",
    "cmForEachCommand.cxx",
    "cmFunctionBlocker.cxx",
    "cmFunctionCommand.cxx",
    "cmFSPermissions.cxx",
    "cmGeneratedFileStream.cxx",
    "cmGeneratorExpression.cxx",
    "cmGeneratorExpressionContext.cxx",
    "cmGeneratorExpressionDAGChecker.cxx",
    "cmGeneratorExpressionEvaluationFile.cxx",
    "cmGeneratorExpressionEvaluator.cxx",
    "cmGeneratorExpressionLexer.cxx",
    "cmGeneratorExpressionNode.cxx",
    "cmGeneratorExpressionParser.cxx",
    "cmGeneratorTarget.cxx",
    "cmGeneratorTarget_CompatibleInterface.cxx",
    "cmGeneratorTarget_IncludeDirectories.cxx",
    "cmGeneratorTarget_Link.cxx",
    "cmGeneratorTarget_LinkDirectories.cxx",
    "cmGeneratorTarget_Options.cxx",
    "cmGeneratorTarget_Sources.cxx",
    "cmGeneratorTarget_TargetPropertyEntry.cxx",
    "cmGeneratorTarget_TransitiveProperty.cxx",
    "cmGetCMakePropertyCommand.cxx",
    "cmGetDirectoryPropertyCommand.cxx",
    "cmGetFilenameComponentCommand.cxx",
    "cmGetPipes.cxx",
    "cmGetPropertyCommand.cxx",
    "cmGetSourceFilePropertyCommand.cxx",
    "cmGetTargetPropertyCommand.cxx",
    "cmGetTestPropertyCommand.cxx",
    "cmGlobalCommonGenerator.cxx",
    "cmGlobalGenerator.cxx",
    "cmGlobVerificationManager.cxx",
    "cmHexFileConverter.cxx",
    "cmIfCommand.cxx",
    "cmImportedCxxModuleInfo.cxx",
    "cmIncludeCommand.cxx",
    "cmIncludeGuardCommand.cxx",
    "cmIncludeDirectoryCommand.cxx",
    "cmIncludeRegularExpressionCommand.cxx",
    "cmInstallCommand.cxx",
    "cmInstallCommandArguments.cxx",
    "cmInstallCxxModuleBmiGenerator.cxx",
    "cmInstallDirectoryGenerator.cxx",
    "cmInstallExportGenerator.cxx",
    "cmInstallFileSetGenerator.cxx",
    "cmInstallFilesCommand.cxx",
    "cmInstallFilesGenerator.cxx",
    "cmInstallGenerator.cxx",
    "cmInstallGetRuntimeDependenciesGenerator.cxx",
    "cmInstallImportedRuntimeArtifactsGenerator.cxx",
    "cmInstallRuntimeDependencySet.cxx",
    "cmInstallRuntimeDependencySetGenerator.cxx",
    "cmInstallScriptGenerator.cxx",
    "cmInstallSubdirectoryGenerator.cxx",
    "cmInstallTargetGenerator.cxx",
    "cmInstallTargetsCommand.cxx",
    "cmInstalledFile.cxx",
    "cmJSONHelpers.cxx",
    "cmJSONState.cxx",
    "cmLDConfigLDConfigTool.cxx",
    "cmLDConfigTool.cxx",
    "cmLinkDirectoriesCommand.cxx",
    "cmLinkItem.cxx",
    "cmLinkItemGraphVisitor.cxx",
    "cmLinkLineComputer.cxx",
    "cmLinkLineDeviceComputer.cxx",
    "cmListCommand.cxx",
    "cmListFileCache.cxx",
    "cmLocalCommonGenerator.cxx",
    "cmLocalGenerator.cxx",
    "cmMSVC60LinkLineComputer.cxx",
    "cmMacroCommand.cxx",
    "cmMakeDirectoryCommand.cxx",
    "cmMakefile.cxx",
    "cmMarkAsAdvancedCommand.cxx",
    "cmMathCommand.cxx",
    "cmMessageCommand.cxx",
    "cmMessenger.cxx",
    "cmNewLineStyle.cxx",
    "cmOSXBundleGenerator.cxx",
    "cmOptionCommand.cxx",
    "cmOrderDirectories.cxx",
    "cmOutputConverter.cxx",
    "cmParseArgumentsCommand.cxx",
    "cmPathLabel.cxx",
    "cmPolicies.cxx",
    "cmProcessOutput.cxx",
    "cmProjectCommand.cxx",
    "cmValue.cxx",
    "cmPropertyDefinition.cxx",
    "cmPropertyMap.cxx",
    "cmGccDepfileLexerHelper.cxx",
    "cmGccDepfileReader.cxx",
    "cmReturnCommand.cxx",
    "cmPlaceholderExpander.cxx",
    "cmPlistParser.cxx",
    "cmRulePlaceholderExpander.cxx",
    "cmRuntimeDependencyArchive.cxx",
    "cmScriptGenerator.cxx",
    "cmSearchPath.cxx",
    "cmSeparateArgumentsCommand.cxx",
    "cmSetCommand.cxx",
    "cmSetDirectoryPropertiesCommand.cxx",
    "cmSetPropertyCommand.cxx",
    "cmSetSourceFilesPropertiesCommand.cxx",
    "cmSetTargetPropertiesCommand.cxx",
    "cmSetTestsPropertiesCommand.cxx",
    "cmSiteNameCommand.cxx",
    "cmSourceFile.cxx",
    "cmSourceFileLocation.cxx",
    "cmStandardLevelResolver.cxx",
    "cmState.cxx",
    "cmStateDirectory.cxx",
    "cmStateSnapshot.cxx",
    "cmString.cxx",
    "cmStringAlgorithms.cxx",
    "cmStringReplaceHelper.cxx",
    "cmStringCommand.cxx",
    "cmSubcommandTable.cxx",
    "cmSubdirCommand.cxx",
    "cmSystemTools.cxx",
    "cmTarget.cxx",
    "cmTargetCompileDefinitionsCommand.cxx",
    "cmTargetCompileFeaturesCommand.cxx",
    "cmTargetCompileOptionsCommand.cxx",
    "cmTargetIncludeDirectoriesCommand.cxx",
    "cmTargetLinkLibrariesCommand.cxx",
    "cmTargetLinkOptionsCommand.cxx",
    "cmTargetPrecompileHeadersCommand.cxx",
    "cmTargetPropCommandBase.cxx",
    "cmTargetPropertyComputer.cxx",
    "cmTargetSourcesCommand.cxx",
    "cmTargetTraceDependencies.cxx",
    "cmTest.cxx",
    "cmTestGenerator.cxx",
    "cmTimestamp.cxx",
    "cmTransformDepfile.cxx",
    "cmTryCompileCommand.cxx",
    "cmTryRunCommand.cxx",
    "cmUnsetCommand.cxx",
    "cmUVHandlePtr.cxx",
    "cmUVProcessChain.cxx",
    "cmVersion.cxx",
    "cmWhileCommand.cxx",
    "cmWindowsRegistry.cxx",
    "cmWorkingDirectory.cxx",
    "cmXcFramework.cxx",
    "cmake.cxx",
    "cmakemain.cxx",
    "cmcmd.cxx",
    "cm_fileno.cxx",
};

pub fn cmBootstrapHeaders(b: *std.Build) std.Build.LazyPath {
    const generated_headers = b.addWriteFiles();
    for (kwSysConfig.configHeaders(b)) |h| {
        _ = generated_headers.addCopyFile(h.getOutput(), h.include_path);
    }
    return .{
        .generated = .{
            .file = &generated_headers.generated_directory,
        },
    };
}

pub const kwSysConfig = struct {
    pub const defaults = .{
        .CMAKE_BIN_DIR = "/bootstrap-not-installed",
        .CMAKE_DATA_DIR = "/bootstrap-not-installed",
        .CMake_DEFAULT_RECURSION_LIMIT = 400,
        .CMAKE_DOC_DIR = "DOC",
        .CMake_VERSION = "0.0.0-bootstrap",
        .CMake_VERSION_IS_DIRTY = 1,
        .CMake_VERSION_MAJOR = 0,
        .CMake_VERSION_MINOR = 0,
        .CMake_VERSION_PATCH = 0,
        .CMake_VERSION_SUFFIX = "bootstrap",
        .CURL_CA_BUNDLE = "",
        .CURL_CA_PATH = "",
        .KWSYS_BUILD_SHARED = 0,
        .KWSYS_CXX_HAS_ENVIRON_IN_STDLIB_H = 0,
        .KWSYS_CXX_HAS_EXT_STDIO_FILEBUF_H = 0,
        .KWSYS_CXX_HAS_SETENV = 0,
        .KWSYS_CXX_HAS_UNSETENV = 0,
        .KWSYS_CXX_HAS_UTIMENSAT = 0,
        .KWSYS_CXX_HAS_UTIMES = 0,
        .KWSYS_ENCODING_DEFAULT_CODEPAGE = "CP_UTF8",
        .KWSYS_LFS_AVAILABLE = 0,
        .KWSYS_LFS_REQUESTED = 0,
        .KWSYS_NAME_IS_KWSYS = 0,
        .KWSYS_NAMESPACE = "cmsys",
        .KWSYS_STL_HAS_WSTRING = 0,
        .KWSYS_SYSTEMTOOLS_USE_TRANSLATION_MAP = 1,
    };
    pub fn configHeaders(b: *std.Build) []*std.Build.Step.ConfigHeader {
        var acc = std.ArrayList(*std.Build.Step.ConfigHeader).init(b.allocator);
        inline for (.{
            .{ "Source/cmConfigure.cmake.h.in", "cmConfigure.h" },
            .{ "Source/cmVersionConfig.h.in", "cmVersionConfig.h" },
            .{ "Source/kwsys/Base64.h.in", "cmsys/Base64.h" },
            .{ "Source/kwsys/CommandLineArguments.hxx.in", "cmsys/CommandLineArguments.hxx" },
            .{ "Source/kwsys/Configure.h.in", "cmsys/Configure.h" },
            .{ "Source/kwsys/Configure.hxx.in", "cmsys/Configure.hxx" },
            .{ "Source/kwsys/ConsoleBuf.hxx.in", "cmsys/ConsoleBuf.hxx" },
            .{ "Source/kwsys/Directory.hxx.in", "cmsys/Directory.hxx" },
            .{ "Source/kwsys/Encoding.h.in", "cmsys/Encoding.h" },
            .{ "Source/kwsys/Encoding.hxx.in", "cmsys/Encoding.hxx" },
            .{ "Source/kwsys/FStream.hxx.in", "cmsys/FStream.hxx" },
            .{ "Source/kwsys/Glob.hxx.in", "cmsys/Glob.hxx" },
            .{ "Source/kwsys/MD5.h.in", "cmsys/MD5.h" },
            .{ "Source/kwsys/Process.h.in", "cmsys/Process.h" },
            .{ "Source/kwsys/RegularExpression.hxx.in", "cmsys/RegularExpression.hxx" },
            .{ "Source/kwsys/Status.hxx.in", "cmsys/Status.hxx" },
            .{ "Source/kwsys/String.h.in", "cmsys/String.h" },
            .{ "Source/kwsys/System.h.in", "cmsys/System.h" },
            .{ "Source/kwsys/SystemInformation.hxx.in", "cmsys/SystemInformation.hxx" },
            .{ "Source/kwsys/SystemTools.hxx.in", "cmsys/SystemTools.hxx" },
            .{ "Source/kwsys/Terminal.h.in", "cmsys/Terminal.h" },
            .{ "Utilities/cmThirdParty.h.in", "cmThirdParty.h" },
            .{ "Utilities/std/cmSTL.hxx.in", "cmSTL.hxx" },
            // .{ "Source/kwsys/DynamicLoader.hxx.in", "cmsys/DynamicLoader.hxx" },
            // .{ "Source/kwsys/testSystemTools.h.in", "cmsys/testSystemTools.h" },
        }) |tpl| {
            acc.append(b.addConfigHeader(.{
                .include_path = tpl[1],
                .style = .{ .cmake = b.path(tpl[0]) },
            }, defaults)) catch @panic("OOM");
        }
        return acc.toOwnedSlice() catch @panic("OOM");
    }
};
