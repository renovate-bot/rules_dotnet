load("@io_bazel_rules_dotnet//dotnet/private:common.bzl", "executable_extension", "bat_extension", "paths")


def _detect_net_framework(ctx, version):
  system = ctx.which("System.dll")
  if not system:
    defpath = ctx.path("C:/Program Files (x86)/Reference Assemblies/Microsoft/Framework/.NETFramework/v" + version)
    if defpath.exists:
      return defpath
    else:
      fail("Failed to find .net " + version + " in default location " + defpath)
  

  return ""



def _net_download_sdk_impl(ctx):
  if ctx.os.name != 'windows':
    fail("Unsupported operating system: " + ctx.os.name)

  host = "net_windows_amd64"

  sdks = ctx.attr.sdks
  if host not in sdks: fail("Unsupported host {}".format(host))
  filename, sha256 = ctx.attr.sdks[host]
  _sdk_build_file(ctx)
  _remote_sdk(ctx, [filename], ctx.attr.strip_prefix, sha256)

  ctx.symlink("net/tools", "mcs_bin")
  ctx.symlink("net/tools", "mono_bin")

  lib = _detect_net_framework(ctx, ctx.attr.version)

  ctx.symlink(lib, "lib")


net_download_sdk = repository_rule(
    _net_download_sdk_impl,
    attrs = {
        "sdks": attr.string_list_dict(),
        "urls": attr.string_list(),
        "version": attr.string(),
        "strip_prefix": attr.string(default = ""),
    },
)

"""See /dotnet/toolchains.rst#dotnet-sdk for full documentation."""

def _remote_sdk(ctx, urls, strip_prefix, sha256):
  ctx.download_and_extract(
      url = urls,
      stripPrefix = strip_prefix,
      sha256 = sha256,
      output="net",
  )
  
def _sdk_build_file(ctx):
  ctx.file("ROOT")
  ctx.template("BUILD.bazel",
      Label("@io_bazel_rules_dotnet//dotnet/private:BUILD.sdk.bazel"),
      executable = False,
  )

