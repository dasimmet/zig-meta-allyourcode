const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const bs = b.addExecutable(.{
        .name = "bootstrap",
        .target = target,
        .optimize = optimize,
    });
    bs.linkLibC();
    bs.linkLibCpp();
    addMacros(b, bs);

    const generated_headers = ConfigHeaders.build(b);
    bs.addIncludePath(generated_headers);
    bs.addIncludePath(generated_headers.path(b, "cmsys"));
    bs.addIncludePath(b.path("Source"));
    bs.addIncludePath(b.path("Source/LexerParser"));
    bs.addIncludePath(b.path("Utilities"));
    bs.addIncludePath(b.path("Utilities/cmjsoncpp/include"));
    bs.addIncludePath(b.path("Utilities/cmlibrhash/librhash"));
    bs.addIncludePath(b.path("Utilities/std"));

    bs.addCSourceFiles(.{
        .files = LIBRHASH_C_SOURCES,
        .root = b.path("Utilities/cmlibrhash"),
        .flags = &.{"-DNO_IMPORT_EXPORT"},
    });
    bs.addCSourceFiles(.{
        .files = CMAKE_CXX_SOURCES,
        .root = b.path("Source"),
    });
    b.installArtifact(bs);
    const run = b.addRunArtifact(bs);
    b.step("run", "run").dependOn(&run.step);

    const libuv = LibUV.build(b, .{
        .target = target,
        .optimize = optimize,
        .generated_headers = generated_headers,
    });
    bs.linkLibrary(libuv);
    b.installArtifact(libuv);
}

pub fn addMacros(b: *std.Build, comp: *std.Build.Step.Compile) void {
    // kwsys
    comp.defineCMacro("KWSYS_STRING_C", null);
    comp.defineCMacro("KWSYS_NAMESPACE", "cmsys");
    // cmake
    // comp.defineCMacro("_FILE_OFFSET_BITS", "64");
    comp.defineCMacro("CMAKE_BOOTSTRAP", null);
    comp.defineCMacro("CMAKE_BOOTSTRAP_MAKEFILES", null);
    comp.defineCMacro(
        "CMAKE_BOOTSTRAP_BINARY_DIR",
        std.mem.join(
            b.allocator,
            "",
            &.{ "\"", b.install_path, "\"" },
        ) catch @panic("OOM"),
    );
    comp.defineCMacro(
        "CMAKE_BOOTSTRAP_SOURCE_DIR",
        std.mem.join(
            b.allocator,
            "",
            &.{ "\"", b.install_path, "\"" },
        ) catch @panic("OOM"),
    );
    comp.defineCMacro("CMake_HAVE_CXX_MAKE_UNIQUE", "1");
    comp.defineCMacro("CMake_HAVE_CXX_FILESYSTEM", "1");
}

pub const LibUV = struct {
    const Self = @This();
    pub fn build(b: *std.Build, opt: anytype) *std.Build.Step.Compile {
        const libuv = b.addStaticLibrary(.{
            .name = "uv",
            .target = opt.target,
            .optimize = opt.optimize,
        });
        libuv.linkLibC();
        addMacros(b, libuv);
        libuv.addCSourceFiles(.{
            .files = LibUV.C_SOURCES,
            .root = b.path("Utilities/cmlibuv/src"),
            .flags = &.{"-D_GNU_SOURCE"},
        });
        libuv.addIncludePath(opt.generated_headers);
        inline for (Self.IncludePaths) |p| {
            libuv.addIncludePath(b.path(p));
        }
        return libuv;
    }
    pub const IncludePaths = &.{
        "Utilities/cmlibuv/include",
        "Utilities/cmlibuv/src",
        "Utilities/cmlibuv/src/unix",
    };
    pub const C_SOURCES = &.{
        "strscpy.c",
        "strtok.c",
        "timer.c",
        "uv-common.c",
        "unix/cmake-bootstrap.c",
        "unix/core.c",
        "unix/fs.c",
        "unix/loop.c",
        "unix/loop-watcher.c",
        "unix/no-fsevents.c",
        "unix/pipe.c",
        "unix/poll.c",
        "unix/posix-hrtime.c",
        "unix/posix-poll.c",
        "unix/process.c",
        "unix/signal.c",
        "unix/stream.c",
        "unix/tcp.c",
        "unix/tty.c",
    };
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
    "cm_fileno.cxx",
    "cmAddCompileDefinitionsCommand.cxx",
    "cmAddCustomCommandCommand.cxx",
    "cmAddCustomTargetCommand.cxx",
    "cmAddDefinitionsCommand.cxx",
    "cmAddDependenciesCommand.cxx",
    "cmAddExecutableCommand.cxx",
    "cmAddLibraryCommand.cxx",
    "cmAddSubDirectoryCommand.cxx",
    "cmAddTestCommand.cxx",
    "cmake.cxx",
    "cmakemain.cxx",
    "cmArgumentParser.cxx",
    "cmBinUtilsLinker.cxx",
    "cmBinUtilsLinuxELFGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsLinuxELFLinker.cxx",
    "cmBinUtilsLinuxELFObjdumpGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsMacOSMachOGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsMacOSMachOLinker.cxx",
    "cmBinUtilsMacOSMachOOToolGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsWindowsPEDumpbinGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsWindowsPEGetRuntimeDependenciesTool.cxx",
    "cmBinUtilsWindowsPELinker.cxx",
    "cmBinUtilsWindowsPEObjdumpGetRuntimeDependenciesTool.cxx",
    "cmBlockCommand.cxx",
    "cmBreakCommand.cxx",
    "cmBuildCommand.cxx",
    "cmCacheManager.cxx",
    "cmCMakeLanguageCommand.cxx",
    "cmCMakeMinimumRequired.cxx",
    "cmCMakePath.cxx",
    "cmCMakePathCommand.cxx",
    "cmCMakePolicyCommand.cxx",
    "cmcmd.cxx",
    "cmCommand.cxx",
    "cmCommandArgumentParserHelper.cxx",
    "cmCommands.cxx",
    "cmCommonTargetGenerator.cxx",
    "cmComputeComponentGraph.cxx",
    "cmComputeLinkDepends.cxx",
    "cmComputeLinkInformation.cxx",
    "cmComputeTargetDepends.cxx",
    "cmConditionEvaluator.cxx",
    "cmConfigureFileCommand.cxx",
    "cmConsoleBuf.cxx",
    "cmContinueCommand.cxx",
    "cmCoreTryCompile.cxx",
    "cmCPackPropertiesGenerator.cxx",
    "cmCreateTestSourceList.cxx",
    "cmCryptoHash.cxx",
    "cmCustomCommand.cxx",
    "cmCustomCommandGenerator.cxx",
    "cmCustomCommandLines.cxx",
    "cmCxxModuleMapper.cxx",
    "cmCxxModuleUsageEffects.cxx",
    "cmDefinePropertyCommand.cxx",
    "cmDefinitions.cxx",
    "cmDepends.cxx",
    "cmDependsC.cxx",
    "cmDependsCompiler.cxx",
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
    "cmFileCommand_ReadMacho.cxx",
    "cmFileCommand.cxx",
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
    "cmFSPermissions.cxx",
    "cmFunctionBlocker.cxx",
    "cmFunctionCommand.cxx",
    "cmGccDepfileLexerHelper.cxx",
    "cmGccDepfileReader.cxx",
    "cmGeneratedFileStream.cxx",
    "cmGeneratorExpression.cxx",
    "cmGeneratorExpressionContext.cxx",
    "cmGeneratorExpressionDAGChecker.cxx",
    "cmGeneratorExpressionEvaluationFile.cxx",
    "cmGeneratorExpressionEvaluator.cxx",
    "cmGeneratorExpressionLexer.cxx",
    "cmGeneratorExpressionNode.cxx",
    "cmGeneratorExpressionParser.cxx",
    "cmGeneratorTarget_CompatibleInterface.cxx",
    "cmGeneratorTarget_IncludeDirectories.cxx",
    "cmGeneratorTarget_Link.cxx",
    "cmGeneratorTarget_LinkDirectories.cxx",
    "cmGeneratorTarget_Options.cxx",
    "cmGeneratorTarget_Sources.cxx",
    "cmGeneratorTarget_TargetPropertyEntry.cxx",
    "cmGeneratorTarget_TransitiveProperty.cxx",
    "cmGeneratorTarget.cxx",
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
    "cmGlobalUnixMakefileGenerator3.cxx",
    "cmGlobVerificationManager.cxx",
    "cmHexFileConverter.cxx",
    "cmIfCommand.cxx",
    "cmImportedCxxModuleInfo.cxx",
    "cmIncludeCommand.cxx",
    "cmIncludeDirectoryCommand.cxx",
    "cmIncludeGuardCommand.cxx",
    "cmIncludeRegularExpressionCommand.cxx",
    "cmInstallCommand.cxx",
    "cmInstallCommandArguments.cxx",
    "cmInstallCxxModuleBmiGenerator.cxx",
    "cmInstallDirectoryGenerator.cxx",
    "cmInstalledFile.cxx",
    "cmInstallExportGenerator.cxx",
    "cmInstallFilesCommand.cxx",
    "cmInstallFileSetGenerator.cxx",
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
    "cmJSONHelpers.cxx",
    "cmJSONState.cxx",
    "cmLDConfigLDConfigTool.cxx",
    "cmLDConfigTool.cxx",
    "cmLinkDirectoriesCommand.cxx",
    "cmLinkItem.cxx",
    "cmLinkItemGraphVisitor.cxx",
    "cmLinkLineComputer.cxx",
    "cmLinkLineDeviceComputer.cxx",
    "cmList.cxx",
    "cmListCommand.cxx",
    "cmListFileCache.cxx",
    "cmLocalCommonGenerator.cxx",
    "cmLocalGenerator.cxx",
    "cmLocalUnixMakefileGenerator3.cxx",
    "cmMacroCommand.cxx",
    "cmMakeDirectoryCommand.cxx",
    "cmMakefile.cxx",
    "cmMakefileExecutableTargetGenerator.cxx",
    "cmMakefileLibraryTargetGenerator.cxx",
    "cmMakefileTargetGenerator.cxx",
    "cmMakefileUtilityTargetGenerator.cxx",
    "cmMarkAsAdvancedCommand.cxx",
    "cmMathCommand.cxx",
    "cmMessageCommand.cxx",
    "cmMessenger.cxx",
    "cmMSVC60LinkLineComputer.cxx",
    "cmNewLineStyle.cxx",
    "cmOptionCommand.cxx",
    "cmOrderDirectories.cxx",
    "cmOSXBundleGenerator.cxx",
    "cmOutputConverter.cxx",
    "cmParseArgumentsCommand.cxx",
    "cmPathLabel.cxx",
    "cmPlaceholderExpander.cxx",
    "cmPlistParser.cxx",
    "cmPolicies.cxx",
    "cmProcessOutput.cxx",
    "cmProcessTools.cxx",
    "cmProjectCommand.cxx",
    "cmPropertyDefinition.cxx",
    "cmPropertyMap.cxx",
    "cmReturnCommand.cxx",
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
    "cmStringCommand.cxx",
    "cmStringReplaceHelper.cxx",
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
    "cmValue.cxx",
    "cmVersion.cxx",
    "cmWhileCommand.cxx",
    "cmWindowsRegistry.cxx",
    "cmWorkingDirectory.cxx",
    "cmXcFramework.cxx",
};

pub const ConfigHeaders = struct {
    pub const Options = struct {
        _FILE_OFFSET_BITS: u16 = 64,
        CMAKE_BIN_DIR: []const u8 = "/bootstrap-not-installed",
        CMAKE_DATA_DIR: []const u8 = "/bootstrap-not-installed",
        CMake_DEFAULT_RECURSION_LIMIT: u16 = 400,
        CMAKE_DOC_DIR: []const u8 = "DOC",
        CMake_VERSION: []const u8 = "0.0.0-bootstrap",
        CMake_VERSION_IS_DIRTY: u16 = 1,
        CMake_VERSION_MAJOR: u16 = 0,
        CMake_VERSION_MINOR: u16 = 0,
        CMake_VERSION_PATCH: u16 = 0,
        CMake_VERSION_SUFFIX: []const u8 = "bootstrap",
        CURL_CA_BUNDLE: []const u8 = "",
        CURL_CA_PATH: []const u8 = "",
        KWSYS_BUILD_SHARED: u16 = 0,
        KWSYS_CXX_HAS_ENVIRON_IN_STDLIB_H: u16 = 0,
        KWSYS_CXX_HAS_EXT_STDIO_FILEBUF_H: u16 = 0,
        KWSYS_CXX_HAS_SETENV: u16 = 0,
        KWSYS_CXX_HAS_UNSETENV: u16 = 0,
        KWSYS_CXX_HAS_UTIMENSAT: u16 = 0,
        KWSYS_CXX_HAS_UTIMES: u16 = 0,
        KWSYS_ENCODING_DEFAULT_CODEPAGE: []const u8 = "CP_UTF8",
        KWSYS_LFS_AVAILABLE: u16 = 0,
        KWSYS_LFS_REQUESTED: u16 = 0,
        KWSYS_NAME_IS_KWSYS: u16 = 0,
        KWSYS_NAMESPACE: []const u8 = "cmsys",
        KWSYS_STL_HAS_WSTRING: u16 = 0,
        KWSYS_SYSTEMTOOLS_USE_TRANSLATION_MAP: u16 = 1,
    };

    pub fn build(b: *std.Build) std.Build.LazyPath {
        const generated_headers = b.addWriteFiles();
        for (configHeaders(b)) |h| {
            _ = generated_headers.addCopyFile(h.getOutput(), h.include_path);
        }
        return .{
            .generated = .{
                .file = &generated_headers.generated_directory,
            },
        };
    }
    pub fn configHeaders(b: *std.Build) []*std.Build.Step.ConfigHeader {
        var opts = Options{};
        inline for (@typeInfo(Options).Struct.fields) |f| {
            if (b.option(f.type, f.name, f.name ++ " - cmake config header")) |opt| {
                @field(opts, f.name) = opt;
            }
        }
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
            }, opts)) catch @panic("OOM");
        }
        return acc.toOwnedSlice() catch @panic("OOM");
    }
};
