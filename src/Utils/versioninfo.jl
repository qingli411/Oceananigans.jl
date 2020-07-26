using Pkg
using InteractiveUtils
using CUDA
using Oceananigans.Architectures

function versioninfo_with_gpu()
    s = sprint(versioninfo)
    @hascuda begin
        gpu_name = CuCurrentContext() |> device |> name
        s = s * "  GPU: $gpu_name\n"
    end
    return s
end

function oceananigans_versioninfo()
    project = Pkg.project()

    # If Oceananigans is listed as a dependency in a Project.toml
    # (or in the base Julia env)
    if "Oceananigans" in keys(project.dependencies)
        uuid = project.dependencies["Oceananigans"]
        pkg_info = Pkg.dependencies()[uuid]
        s = "Oceananigans v$(pkg_info.version)"
        s *= isnothing(pkg_info.git_revision) ? " #$(pkg_info.git_revision)" : ""
        return s
    end

    # If we're using the Oceananigans development environment,
    # i.e. running from the git repository. Really we should not
    # use untagged versions for real science. It's not as reproducible.
    if "Oceananigans" == project.name
        return "Oceananigans v$(project.version) (DEVELOPMENT)"
    end

    @warn "Could not determine Oceananigans version info."

    return nothing
end
